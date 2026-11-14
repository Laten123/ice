extends RefCounted
## A small, hand-audited walkable graph for AI residents.
## The owner/viewer never commands the graph directly. Positions are SVG art coordinates.
## Do not claim arbitrary navigability: this is a fixed-scene prototype.

const ZONES := {
    "porch": Vector2(608, 408),
    "front_path": Vector2(633, 440),
    "garden": Vector2(720, 519),
    "river_path": Vector2(517, 450),
    "tree_path": Vector2(442, 437),
    "book_corner": Vector2(406, 408),
    "tea_table": Vector2(359, 472),
    "riverbank": Vector2(282, 491),
    "window_view": Vector2(519, 401)
}

# Stable public place IDs in DeepSeek's P1 HTTP gateway.
# Internal SVG/scene waypoints may be renamed without changing resident APIs.
# "fallen_log" is RESERVED until its art, walkable approach and sit pose exist.
# It must NOT be advertised as a usable location yet.
const API_TO_INTERNAL := {
    "door": "porch",
    "path": "front_path",
    "garden": "garden",
    "riverside": "river_path",
    "old_tree": "tree_path",
    "book_corner": "book_corner",
    "stone_table": "tea_table",
    "riverbank": "riverbank",
    "window": "window_view"
}

const INTERNAL_TO_API := {
    "porch": "door",
    "front_path": "path",
    "garden": "garden",
    "river_path": "riverside",
    "tree_path": "old_tree",
    "book_corner": "book_corner",
    "tea_table": "stone_table",
    "riverbank": "riverbank",
    "window_view": "window"
}

# Authoritative Python P1 weighted adjacency, as reported by DeepSeek.
# Costs are server travel weights; they are NOT screen-distance promises.
# The viewer NEVER asks this graph to decide a resident's movements.
const BACKEND_EDGES := [
    ["door", "path", 80],
    ["path", "garden", 120],
    ["garden", "window", 60],
    ["path", "old_tree", 140],
    ["path", "book_corner", 160],
    ["old_tree", "book_corner", 90],
    ["book_corner", "stone_table", 40],
    ["stone_table", "riverside", 60],
    ["stone_table", "riverbank", 80],
    ["riverside", "riverbank", 100]
]

var _pathfinder: AStar2D = AStar2D.new()
var _indices: Dictionary = {}

func _init() -> void:
    var index: int = 1
    for zone_name in ZONES.keys():
        _indices[zone_name] = index
        _pathfinder.add_point(index, ZONES[zone_name])
        index += 1
    for edge in BACKEND_EDGES:
        var left: String = API_TO_INTERNAL[edge[0]]
        var right: String = API_TO_INTERNAL[edge[1]]
        _pathfinder.connect_points(_indices[left], _indices[right], true)

func to_internal_zone(zone_name: String) -> String:
    # Internal aliases remain for existing local script fixtures only.
    # External service should always use API_TO_INTERNAL keys.
    if API_TO_INTERNAL.has(zone_name):
        return API_TO_INTERNAL[zone_name]
    if ZONES.has(zone_name):
        return zone_name
    return ""

func to_api_zone(zone_name: String) -> String:
    var internal_name: String = to_internal_zone(zone_name)
    if INTERNAL_TO_API.has(internal_name):
        return INTERNAL_TO_API[internal_name]
    return ""

func available_zones() -> Array[String]:
    var names: Array[String] = []
    for zone_name in API_TO_INTERNAL.keys():
        names.append(str(zone_name))
    names.sort()
    return names

func is_known_zone(zone_name: String) -> bool:
    return not to_internal_zone(zone_name).is_empty()

func zone_position(zone_name: String) -> Vector2:
    var internal_name: String = to_internal_zone(zone_name)
    if internal_name.is_empty():
        return Vector2.INF
    return ZONES[internal_name]

func backend_edge_weight(from_zone: String, to_zone: String) -> int:
    # For protocol regression checks only. Returns -1 if no server edge.
    var first: String = to_api_zone(from_zone)
    var second: String = to_api_zone(to_zone)
    for edge in BACKEND_EDGES:
        if (edge[0] == first and edge[1] == second) or (edge[1] == first and edge[0] == second):
            return int(edge[2])
    return -1

func backend_weighted_route(from_zone: String, to_zone: String) -> Array[String]:
    # Diagnostic reference only. The Python server stays authoritative.
    var first: String = to_api_zone(from_zone)
    var last: String = to_api_zone(to_zone)
    var result: Array[String] = []
    if first.is_empty() or last.is_empty():
        return result
    var frontier: Array[String] = [first]
    var best: Dictionary = {first: 0}
    var previous: Dictionary = {}
    var visited: Dictionary = {}
    while not frontier.is_empty():
        var current: String = frontier[0]
        var current_cost: int = int(best[current])
        for option in frontier:
            if int(best[option]) < current_cost:
                current = option
                current_cost = int(best[option])
        frontier.erase(current)
        if current == last:
            break
        if visited.has(current):
            continue
        visited[current] = true
        for edge in BACKEND_EDGES:
            var neighbor: String = ""
            if edge[0] == current:
                neighbor = str(edge[1])
            elif edge[1] == current:
                neighbor = str(edge[0])
            if neighbor.is_empty() or visited.has(neighbor):
                continue
            var proposal: int = current_cost + int(edge[2])
            if not best.has(neighbor) or proposal < int(best[neighbor]):
                best[neighbor] = proposal
                previous[neighbor] = current
                if not frontier.has(neighbor):
                    frontier.append(neighbor)
    if not best.has(last):
        return result
    var cursor: String = last
    result.push_front(cursor)
    while cursor != first:
        if not previous.has(cursor):
            return []
        cursor = previous[cursor]
        result.push_front(cursor)
    return result

func route_between(from_zone: String, to_zone: String) -> PackedVector2Array:
    var from_internal: String = to_internal_zone(from_zone)
    var to_internal: String = to_internal_zone(to_zone)
    if from_internal.is_empty() or to_internal.is_empty():
        return PackedVector2Array()
    return _pathfinder.get_point_path(_indices[from_internal], _indices[to_internal])

func nearest_zone(point: Vector2) -> String:
    var nearest_name: String = "porch"
    var best_distance: float = INF
    for zone_name in ZONES.keys():
        var dist: float = point.distance_squared_to(ZONES[zone_name])
        if dist < best_distance:
            best_distance = dist
            nearest_name = zone_name
    return nearest_name
