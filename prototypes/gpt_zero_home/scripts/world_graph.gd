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

const EDGES := [
    ["porch", "front_path"],
    ["front_path", "garden"],
    ["front_path", "river_path"],
    ["river_path", "tree_path"],
    ["tree_path", "book_corner"],
    ["book_corner", "tea_table"],
    ["tea_table", "riverbank"],
    ["river_path", "window_view"],
    ["window_view", "porch"]
]

var _pathfinder: AStar2D = AStar2D.new()
var _indices: Dictionary = {}

func _init() -> void:
    var index: int = 1
    for zone_name in ZONES.keys():
        _indices[zone_name] = index
        _pathfinder.add_point(index, ZONES[zone_name])
        index += 1
    for edge in EDGES:
        _pathfinder.connect_points(_indices[edge[0]], _indices[edge[1]], true)

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
