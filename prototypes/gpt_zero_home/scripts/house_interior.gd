extends Node2D
## Actual reusable indoor scene, not a screenshot.
## Visual/COLLISION/waypoint markers are separated for future AI world execution.
## The browser observer can only LOOK inside: never move a resident by clicking.

const DAY_FLOOR: Texture2D = preload("res://art/house_interior_day.svg")
const DUSK_FLOOR: Texture2D = preload("res://art/house_interior_dusk.svg")

func set_dusk(value: bool) -> void:
    var floor_sprite := get_node_or_null("RoomBase") as Sprite2D
    if floor_sprite != null:
        floor_sprite.texture = DUSK_FLOOR if value else DAY_FLOOR

func marker_position(zone: String) -> Vector2:
    var names := {
        "house_entry": "HouseEntry",
        "window_corner": "WindowCorner",
        "writing_desk": "WritingDesk",
        "bookcase": "Bookcase",
        "rest_corner": "RestCorner"
    }
    if not names.has(zone):
        return Vector2(-999.0, -999.0)
    var marker := get_node_or_null("Waypoints/" + str(names[zone])) as Marker2D
    return marker.position if marker != null else Vector2(-999.0, -999.0)

func has_indoor_collision() -> bool:
    var walls := get_node_or_null("Collision/Walls") as StaticBody2D
    return walls != null and walls.get_child_count() >= 5
