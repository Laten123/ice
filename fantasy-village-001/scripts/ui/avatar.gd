extends Control
## Code-drawn placeholder portrait. No image asset is loaded.

var tint := Color("a899ce")
var is_owner := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var unit := minf(size.x, size.y) / 24.0
	var origin := (size - Vector2.ONE * unit * 24.0) / 2.0
	var skin := Color("ffe5c0")
	var hair := Color("554a67") if is_owner else tint.darkened(0.45)
	var pieces := [
		[Rect2(5, 3, 14, 14), hair], [Rect2(7, 6, 10, 11), skin],
		[Rect2(5, 3, 14, 5), hair], [Rect2(5, 7, 3, 7), hair],
		[Rect2(10, 10, 1, 2), Color("403e4e")], [Rect2(15, 10, 1, 2), Color("403e4e")],
		[Rect2(11, 14, 3, 1), Color("d08882")], [Rect2(5, 18, 14, 6), tint],
		[Rect2(10, 17, 5, 3), skin], [Rect2(4, 21, 2, 3), tint.darkened(0.15)],
		[Rect2(18, 21, 2, 3), tint.darkened(0.15)]
	]
	for piece in pieces:
		var rect: Rect2 = piece[0]
		draw_rect(Rect2(origin + rect.position * unit, rect.size * unit), piece[1])
