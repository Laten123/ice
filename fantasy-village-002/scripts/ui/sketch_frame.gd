class_name FvSketchFrame
extends Control
## Hand-drawn placeholder frame. The wobble is deterministic so screenshots and
## layout tests stay reproducible; it is decoration only, not an asset loader.

@export var line_color := Color("22201d")
@export var fill_color := Color("fbfaf6")
@export var line_width := 3.0

var _phase := 1.7


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if size.x < 12.0 or size.y < 12.0:
		return
	draw_rect(Rect2(Vector2(3, 4), size - Vector2(6, 6)), Color(0.1, 0.09, 0.08, 0.08))
	draw_rect(Rect2(Vector2.ZERO, size), fill_color)
	var inset := line_width + 3.0
	var top_left := Vector2(inset, inset)
	var top_right := Vector2(size.x - inset, inset)
	var bottom_right := Vector2(size.x - inset, size.y - inset)
	var bottom_left := Vector2(inset, size.y - inset)
	draw_polyline(_edge(top_left, top_right, 0.0), line_color, line_width, true)
	draw_polyline(_edge(top_right, bottom_right, 2.1), line_color, line_width, true)
	draw_polyline(_edge(bottom_right, bottom_left, 4.2), line_color, line_width, true)
	draw_polyline(_edge(bottom_left, top_left, 6.3), line_color, line_width, true)


func _edge(from: Vector2, to: Vector2, phase: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var normal := (to - from).normalized().orthogonal()
	var steps := 12
	for index in range(steps + 1):
		var t := float(index) / float(steps)
		var wobble := sin(t * PI * 3.0 + _phase + phase) * 1.15 \
			+ sin(t * PI * 7.0 + _phase * 2.0 + phase) * 0.55
		points.append(from.lerp(to, t) + normal * wobble)
	return points
