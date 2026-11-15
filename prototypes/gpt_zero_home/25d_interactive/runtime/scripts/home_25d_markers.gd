extends Node2D
## Visual hints only, drawn in image pixels above the background artwork.
const Points = preload("res://scripts/home_25d_points.gd")
var scene_id := "exterior"
var selected_id := ""
var show_all := true

func update_markers(next_scene: String, selected: String, visible_points: bool) -> void:
    scene_id = next_scene
    selected_id = selected
    show_all = visible_points
    queue_redraw()

func _draw() -> void:
    var points: Dictionary = Points.point_map(scene_id)
    if show_all:
        for key in points.keys():
            var data: Dictionary = points[key]
            var p: Vector2 = data["pos"]
            var size := 18.0 if str(key) == selected_id else 12.0
            draw_circle(p, size + 5.0, Color(0.15, 0.21, 0.16, 0.5))
            draw_circle(p, size, Color(1.0, 0.86, 0.54, 0.76))
            draw_arc(p, size + 8.0, 0, TAU, 20, Color(0.98, 0.95, 0.78, 0.66), 3.0, true)
    elif not selected_id.is_empty() and points.has(selected_id):
        var target: Vector2 = points[selected_id]["pos"]
        draw_arc(target, 29.0, 0.0, TAU, 32, Color("#ffe1a0"), 5.0, true)
        draw_circle(target, 6.0, Color("#ffedbf"))
