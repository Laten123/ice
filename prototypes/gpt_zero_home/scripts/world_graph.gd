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

func is_known_zone(zone_name: String) -> bool:
    return ZONES.has(zone_name)

func zone_position(zone_name: String) -> Vector2:
    if not is_known_zone(zone_name):
        return Vector2.INF
    return ZONES[zone_name]

func route_between(from_zone: String, to_zone: String) -> PackedVector2Array:
    if not is_known_zone(from_zone) or not is_known_zone(to_zone):
        return PackedVector2Array()
    return _pathfinder.get_point_path(_indices[from_zone], _indices[to_zone])

func nearest_zone(point: Vector2) -> String:
    var nearest_name: String = "porch"
    var best_distance: float = INF
    for zone_name in ZONES.keys():
        var dist: float = point.distance_squared_to(ZONES[zone_name])
        if dist < best_distance:
            best_distance = dist
            nearest_name = zone_name
    return nearest_name
