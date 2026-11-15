extends Node2D
## Actual reusable indoor scene, not a screenshot.
## Visual/COLLISION/waypoint markers are separated for future AI world execution.
## The browser observer can only LOOK inside: never move a resident by clicking.

const DAY_FLOOR: Texture2D = preload("res://art/house_interior_day.svg")
const DUSK_FLOOR: Texture2D = preload("res://art/house_interior_dusk.svg")
const PixelInteriorV3 = preload("res://scripts/pixel_interior_v3.gd")

var pixel_room: Sprite2D
var pixel_room_day: Texture2D
var pixel_room_dusk: Texture2D

func _ready() -> void:
    # Preserve the five existing markers and all wall/furniture collision nodes.
    # Pixel art is a replaceable visual layer, not a second navigable world.
    pixel_room_day = PixelInteriorV3.create_texture(false)
    pixel_room_dusk = PixelInteriorV3.create_texture(true)
    pixel_room = Sprite2D.new()
    pixel_room.name = "CompactPixelInteriorV3"
    pixel_room.centered = false
    pixel_room.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    pixel_room.texture = pixel_room_day
    pixel_room.scale = Vector2(2.0, 2.0)
    # Godot visual art still uses the original 960x600 anchor coordinates.
    add_child(pixel_room)
    get_node("RoomBase").visible = false
    get_node("Furniture").visible = false

func set_dusk(value: bool) -> void:
    var floor_sprite := get_node_or_null("RoomBase") as Sprite2D
    if floor_sprite != null:
        floor_sprite.texture = DUSK_FLOOR if value else DAY_FLOOR
    if pixel_room != null:
        pixel_room.texture = pixel_room_dusk if value else pixel_room_day

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
