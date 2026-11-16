class_name CommunityWorld
extends Node2D
## Small, self-contained village. Drawing is deliberately procedural placeholder art.
## Main UI consumes signals; no network, real AI, inventory, or persistence lives here.

signal entity_selected(info: Dictionary)
signal resident_status_changed()
signal placeholder_dialogue(speaker: String, line: String)

const Data = preload("res://data/community_data.gd")
const Agent = preload("res://scripts/world/resident_agent.gd")
const WORLD_SIZE := Vector2(960, 540)
const WALK_BOUNDS := Rect2(35, 58, 890, 445)

var residents: Array = []
var objects: Array[Dictionary] = []
var selected_id := "owner"
var active_resident_id := "owner"
var font: Font
var dialogue_elapsed := 0.0
var dialogue_index := 0
var bubble_text := ""
var bubble_speaker_id := ""
var bubble_remaining := 0.0
var marker := Vector2.ZERO
var marker_remaining := 0.0
var _rng := RandomNumberGenerator.new()
var _status_elapsed := 0.0
## Optional 002 identity. set before add_child() so _ready can seed UUIDs.
var identity_state = null

func apply_identity(state) -> void:
	identity_state = state

func _ready() -> void:
	_rng.seed = 20261116
	objects = Data.objects()
	for config in Data.residents(identity_state):
		var resident = Agent.new()
		resident.configure(config)
		resident.idle_time = 2.0 + residents.size() * 2.5
		residents.append(resident)
	queue_redraw()

func _process(delta: float) -> void:
	for resident in residents:
		if not resident.is_present():
			continue
		resident.tick(delta)
		if resident.autonomous and not resident.moving:
			resident.idle_time -= delta
			if resident.idle_time <= 0.0:
				var destination := Vector2(_rng.randf_range(340, 780), _rng.randf_range(240, 455))
				resident.set_destination(destination, get_obstacles(), WALK_BOUNDS)
				resident.idle_time = _rng.randf_range(4, 8)
	dialogue_elapsed += delta
	if dialogue_elapsed >= 11.0:
		dialogue_elapsed = 0.0
		_emit_ambient_dialogue()
	bubble_remaining = maxf(0.0, bubble_remaining - delta)
	marker_remaining = maxf(0.0, marker_remaining - delta)
	_status_elapsed += delta
	if _status_elapsed >= 0.4:
		_status_elapsed = 0.0
		resident_status_changed.emit()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_pointer(get_global_transform_with_canvas().affine_inverse() * event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_handle_pointer(get_global_transform_with_canvas().affine_inverse() * event.position)

func _handle_pointer(point: Vector2) -> void:
	if not Rect2(Vector2.ZERO, WORLD_SIZE).has_point(point):
		return
	get_viewport().set_input_as_handled()
	# Inspect foreground residents first, then props from the foreground backwards.
	var ordered := residents.duplicate()
	ordered.sort_custom(func(a, b): return a.position.y > b.position.y)
	for resident in ordered:
		if not resident.is_present():
			continue
		if Rect2(resident.position - Vector2(22, 49), Vector2(44, 64)).has_point(point):
			select_resident(resident.id)
			return
	for index in range(objects.size() - 1, -1, -1):
		var item := objects[index]
		if item.hit_rect.has_point(point):
			selected_id = item.id
			entity_selected.emit(get_selected_info())
			return
	move_selected_to(point)

func select_resident(id: String) -> void:
	for resident in residents:
		if resident.id == id:
			selected_id = id
			active_resident_id = id
			entity_selected.emit(get_selected_info())
			return

func set_resident_status(id: String, status: String) -> void:
	for resident in residents:
		if resident.id == id:
			resident.status = status
			if status != "online":
				resident.moving = false
				resident.waypoints.clear()
			queue_redraw()
			return

func get_resident_by_uuid(uuid: String):
	for resident in residents:
		if resident.uuid == uuid:
			return resident
	return null

func move_selected_to(point: Vector2) -> void:
	for resident in residents:
		if resident.id == active_resident_id:
			if resident.set_destination(point, get_obstacles(), WALK_BOUNDS):
				marker = resident.target
				marker_remaining = 1.4
				resident.idle_time = 5.0
				resident_status_changed.emit()
			return

func get_residents() -> Array:
	var result: Array = []
	for resident in residents:
		var info: Dictionary = resident.get_info()
		info["color"] = resident.color
		info["position"] = resident.position
		info["role"] = resident.role
		result.append(info)
	return result

func get_selected_info() -> Dictionary:
	for resident in residents:
		if resident.id == selected_id:
			return resident.get_info()
	for item in objects:
		if item.id == selected_id:
			return {"id": item.id, "name": item.name, "kind": item.kind, "description": item.description, "status": item.status}
	return {}

func get_obstacles() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for item in objects:
		result.append(item.obstacle.grow(9.0))
	return result

func request_placeholder_dialogue() -> void:
	request_dialogue(active_resident_id)

func request_dialogue(id: String) -> void:
	if not id in ["owner", "ai_1", "ai_2"]:
		return
	var speaker_id := id
	var speaker := "林间"
	var line := "你好，欢迎来到我们的幻想乡。"
	if speaker_id == "ai_1":
		speaker = "小晴"
		line = "今天的阳光真好，一起散散步吧。"
	elif speaker_id == "ai_2":
		speaker = "阿澈"
		line = "我正在认识这个小小的社区。"
	_show_dialogue(speaker_id, speaker, line)

func _emit_ambient_dialogue() -> void:
	var lines := [
		["ai_1", "小晴", "阿澈，今天的阳光真好。"],
		["ai_2", "阿澈", "是呀，一起在广场走走吧。"],
		["ai_1", "小晴", "向阳树下很舒服呢。"],
		["ai_2", "阿澈", "欢迎新朋友来到幻想乡。"],
	]
	var entry: Array = lines[dialogue_index % lines.size()]
	dialogue_index += 1
	_show_dialogue(entry[0], entry[1], entry[2])

func _show_dialogue(id: String, speaker: String, line: String) -> void:
	bubble_speaker_id = id
	bubble_text = line
	bubble_remaining = 5.0
	placeholder_dialogue.emit(speaker, line)

func _draw() -> void:
	_draw_ground()
	if marker_remaining > 0.0:
		var c := Color("edf6ce")
		c.a = marker_remaining / 1.4
		draw_arc(marker, 12, 0, TAU, 16, c, 2)
		draw_line(marker + Vector2(-5, 0), marker + Vector2(5, 0), c, 2)
		draw_line(marker + Vector2(0, -5), marker + Vector2(0, 5), c, 2)
	# Sort props and residents together so their feet determine occlusion.
	var renderables: Array = []
	for item in objects:
		renderables.append({"y": item.position.y, "object": item})
	for resident in residents:
		renderables.append({"y": resident.position.y, "resident": resident})
	renderables.sort_custom(func(a, b): return a.y < b.y)
	for element in renderables:
		if element.has("object"):
			_draw_object(element.object)
		else:
			_draw_resident(element.resident)
	_draw_bubble()

func _draw_ground() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("9fc780"))
	# Broad paths frame a compact open social space.
	draw_rect(Rect2(0, 242, 960, 103), Color("d8c99f"))
	draw_rect(Rect2(389, 174, 169, 366), Color("d8c99f"))
	draw_rect(Rect2(145, 214, 173, 78), Color("d8c99f"))
	draw_rect(Rect2(637, 205, 169, 86), Color("d8c99f"))
	draw_rect(Rect2(352, 256, 266, 151), Color("e4d8b6"))
	# Discrete deterministic marks read as pixel terrain without importing a texture.
	for i in range(85):
		var p := Vector2((i * 137 + 31) % 926 + 12, (i * 73 + 17) % 496 + 18)
		if _on_path(p):
			draw_rect(Rect2(p, Vector2(7, 2)), Color("c8ba93"))
		else:
			draw_rect(Rect2(p, Vector2(2, 5)), Color("8ab76e"))
			draw_rect(Rect2(p + Vector2(4, 2), Vector2(2, 3)), Color("8ab76e"))
	for x in range(354, 617, 33):
		draw_line(Vector2(x, 260), Vector2(x, 402), Color("d8cbaa"), 1)
	for y in range(260, 405, 28):
		draw_line(Vector2(355, y), Vector2(616, y), Color("d8cbaa"), 1)
	# Uninteractive boundary dressing is part of the ground, not an extra system.
	_draw_fence(24, 41, 21)
	_draw_fence(581, 41, 15)
	_draw_fence(25, 484, 8)
	_draw_fence(735, 484, 8)
	_draw_flower_bed(Vector2(170, 365), 4)
	_draw_flower_bed(Vector2(760, 370), 3)
	_draw_flower_bed(Vector2(325, 106), 2)
	_draw_flower_bed(Vector2(598, 104), 2)
	# Lower-left lawn stepping stones are a readable depth cue.
	for p in [Vector2(262, 398), Vector2(296, 419), Vector2(331, 438)]:
		draw_rect(Rect2(p, Vector2(24, 13)), Color("afba97"))
		draw_rect(Rect2(p, Vector2(24, 3)), Color("d3d7b7"))

func _on_path(p: Vector2) -> bool:
	return Rect2(0, 242, 960, 103).has_point(p) or Rect2(389, 174, 169, 366).has_point(p) or Rect2(145, 214, 173, 78).has_point(p) or Rect2(637, 205, 169, 86).has_point(p) or Rect2(352, 256, 266, 151).has_point(p)

func _draw_fence(x: int, y: int, count: int) -> void:
	var length := count * 24
	draw_rect(Rect2(x, y + 8, length, 5), Color("bda882"))
	draw_rect(Rect2(x, y + 19, length, 5), Color("bda882"))
	for i in range(count + 1):
		draw_rect(Rect2(x + i * 24, y, 6, 31), Color("e9ddbd"))
		draw_rect(Rect2(x + i * 24, y, 6, 3), Color("f6edcf"))

func _draw_flower_bed(p: Vector2, count: int) -> void:
	for i in range(count):
		var at := p + Vector2(i * 14, (i % 2) * 6)
		draw_rect(Rect2(at + Vector2(0, 5), Vector2(3, 8)), Color("5c9961"))
		var petal := Color("f6d789") if i % 2 == 0 else Color("edb4ab")
		draw_rect(Rect2(at - Vector2(2, 0), Vector2(7, 6)), petal)
		draw_rect(Rect2(at + Vector2(0, 2), Vector2(3, 2)), Color("fff4c3"))

func _draw_object(item: Dictionary) -> void:
	var p: Vector2 = item.position
	var chosen: bool = selected_id == item.id
	if chosen:
		draw_ellipse_placeholder(p + Vector2(0, 1), Vector2(47, 10), Color("f9edbb"))
	match item.style:
		"house": _draw_house(p, item.color)
		"tree": _draw_tree(p)
		"bench": _draw_bench(p)
		"notice": _draw_notice(p)
	if chosen:
		_draw_tag(item.name, p + Vector2(0, 22), Color("40564c"), Color("fff7dc"))

func _draw_house(p: Vector2, roof: Color) -> void:
	draw_ellipse_placeholder(p + Vector2(4, 3), Vector2(86, 12), Color(0.24, 0.37, 0.25, 0.16))
	draw_rect(Rect2(p - Vector2(67, 63), Vector2(138, 70)), Color("e9d7ac"))
	draw_rect(Rect2(p - Vector2(67, 63), Vector2(138, 8)), Color("c5b28e"))
	draw_rect(Rect2(p + Vector2(-67, 0), Vector2(138, 8)), Color("b6a181"))
	draw_rect(Rect2(p + Vector2(38, -106), Vector2(16, 34)), Color("d4c39f"))
	draw_rect(Rect2(p + Vector2(35, -107), Vector2(22, 5)), Color("f3e7cc"))
	var vertices := PackedVector2Array([p + Vector2(-85, -64), p + Vector2(-63, -100), p + Vector2(54, -100), p + Vector2(84, -64)])
	draw_colored_polygon(vertices, roof)
	draw_rect(Rect2(p + Vector2(-85, -64), Vector2(169, 7)), roof.darkened(0.16))
	for row in range(3):
		var y := -91 + row * 10
		draw_line(p + Vector2(-63 - row * 6, y), p + Vector2(59 + row * 7, y), roof.lightened(0.12), 2)
	for x in [-43, 34]:
		draw_rect(Rect2(p + Vector2(x - 4, -43), Vector2(31, 29)), Color("c0a67e"))
		draw_rect(Rect2(p + Vector2(x, -39), Vector2(23, 21)), Color("a5c9ca"))
		draw_rect(Rect2(p + Vector2(x + 2, -37), Vector2(8, 17)), Color("cee2d7"))
		draw_rect(Rect2(p + Vector2(x + 10, -39), Vector2(3, 22)), Color("faf0cb"))
		draw_rect(Rect2(p + Vector2(x, -30), Vector2(23, 3)), Color("faf0cb"))
	draw_rect(Rect2(p + Vector2(-11, -41), Vector2(27, 47)), Color("a98265"))
	draw_rect(Rect2(p + Vector2(-8, -37), Vector2(21, 41)), Color("bb9877"))
	draw_rect(Rect2(p + Vector2(7, -19), Vector2(3, 3)), Color("f3d995"))
	draw_rect(Rect2(p + Vector2(-16, 6), Vector2(38, 6)), Color("eadcc1"))
	_draw_flower_bed(p + Vector2(-61, 11), 2)

func _draw_tree(p: Vector2) -> void:
	draw_ellipse_placeholder(p + Vector2(4, 2), Vector2(47, 10), Color(0.22, 0.37, 0.2, 0.2))
	draw_rect(Rect2(p + Vector2(-10, -50), Vector2(21, 52)), Color("987757"))
	draw_rect(Rect2(p + Vector2(-6, -41), Vector2(5, 39)), Color("b59365"))
	# Square-edged canopy blocks keep this explicitly pixel placeholder art.
	draw_rect(Rect2(p + Vector2(-46, -81), Vector2(93, 39)), Color("558c63"))
	draw_rect(Rect2(p + Vector2(-35, -101), Vector2(69, 62)), Color("689f69"))
	draw_rect(Rect2(p + Vector2(-22, -112), Vector2(45, 65)), Color("7bae73"))
	draw_rect(Rect2(p + Vector2(-43, -82), Vector2(35, 29)), Color("82b775"))
	draw_rect(Rect2(p + Vector2(-25, -103), Vector2(43, 24)), Color("94c17b"))
	draw_rect(Rect2(p + Vector2(12, -77), Vector2(29, 20)), Color("74aa6d"))
	draw_rect(Rect2(p + Vector2(-34, -76), Vector2(8, 6)), Color("afd38c"))
	draw_rect(Rect2(p + Vector2(-11, -99), Vector2(11, 5)), Color("afd38c"))
	draw_rect(Rect2(p + Vector2(20, -58), Vector2(9, 5)), Color("8aba75"))

func _draw_bench(p: Vector2) -> void:
	draw_ellipse_placeholder(p + Vector2(0, 5), Vector2(53, 7), Color(0.24, 0.37, 0.25, 0.15))
	for x in [-38, 33]:
		draw_rect(Rect2(p + Vector2(x, -29), Vector2(6, 34)), Color("657b67"))
	draw_rect(Rect2(p + Vector2(-48, -37), Vector2(96, 9)), Color("ba9769"))
	draw_rect(Rect2(p + Vector2(-48, -24), Vector2(96, 9)), Color("caaa7b"))
	draw_rect(Rect2(p + Vector2(-49, -10), Vector2(98, 10)), Color("ddbc88"))
	draw_rect(Rect2(p + Vector2(-49, -1), Vector2(98, 4)), Color("a88862"))

func _draw_notice(p: Vector2) -> void:
	draw_rect(Rect2(p + Vector2(-20, -25), Vector2(6, 27)), Color("9c7e59"))
	draw_rect(Rect2(p + Vector2(14, -25), Vector2(6, 27)), Color("9c7e59"))
	draw_rect(Rect2(p + Vector2(-29, -55), Vector2(58, 36)), Color("a6875e"))
	draw_rect(Rect2(p + Vector2(-24, -50), Vector2(48, 26)), Color("f3e8bc"))
	draw_rect(Rect2(p + Vector2(-14, -43), Vector2(29, 3)), Color("b9ab7f"))
	draw_rect(Rect2(p + Vector2(-14, -35), Vector2(21, 3)), Color("b9ab7f"))
	draw_rect(Rect2(p + Vector2(-31, -59), Vector2(62, 5)), Color("7d9465"))

func _draw_resident(resident) -> void:
	if not resident.is_present():
		return
	var p: Vector2 = resident.position.round()
	var selected: bool = selected_id == resident.id
	draw_ellipse_placeholder(p + Vector2(0, 2), Vector2(17, 5), Color(0.24, 0.32, 0.22, 0.2))
	if selected:
		draw_arc(p, 21, 0, TAU, 16, Color("fff3c0"), 3)
	var step := 0
	if resident.moving:
		step = 2 if int(Time.get_ticks_msec() / 170) % 2 == 0 else -2
	# 4px chunks: shoes, legs, tunic, face, and hair; no borrowed sprite assets.
	draw_rect(Rect2(p + Vector2(-10, -7 + step), Vector2(8, 8)), Color("5f625d"))
	draw_rect(Rect2(p + Vector2(3, -7 - step), Vector2(8, 8)), Color("5f625d"))
	draw_rect(Rect2(p + Vector2(-10, -19), Vector2(21, 13)), resident.color.darkened(0.16))
	draw_rect(Rect2(p + Vector2(-13, -30), Vector2(27, 16)), resident.color)
	draw_rect(Rect2(p + Vector2(-17, -27), Vector2(5, 13)), Color("f0c9a1"))
	draw_rect(Rect2(p + Vector2(14, -27), Vector2(5, 13)), Color("f0c9a1"))
	draw_rect(Rect2(p + Vector2(-10, -45), Vector2(22, 19)), Color("f6d7b5"))
	var hair := Color("765b4a")
	if resident.id == "ai_1": hair = Color("536d88")
	if resident.id == "ai_2": hair = Color("77648b")
	draw_rect(Rect2(p + Vector2(-12, -48), Vector2(25, 8)), hair)
	draw_rect(Rect2(p + Vector2(-12, -43), Vector2(5, 14)), hair)
	draw_rect(Rect2(p + Vector2(8, -43), Vector2(5, 9)), hair)
	draw_rect(Rect2(p + Vector2(-4, -36), Vector2(3, 3)), Color("52605c"))
	draw_rect(Rect2(p + Vector2(5, -36), Vector2(3, 3)), Color("52605c"))
	if resident.id == "ai_1":
		draw_rect(Rect2(p + Vector2(-16, -45), Vector2(6, 8)), Color("f2da8f"))
	_draw_tag(resident.display_name, p + Vector2(0, 20), Color("425b4d"), Color("fff8df") if selected else Color("e7edd0"))

func _draw_tag(text: String, center: Vector2, text_color: Color, background: Color) -> void:
	var label_font := font if font != null else ThemeDB.fallback_font
	var width := label_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 16
	draw_rect(Rect2(center - Vector2(width / 2, 13), Vector2(width, 20)), background)
	draw_string(label_font, center + Vector2(-width / 2 + 8, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, text_color)

func _draw_bubble() -> void:
	if bubble_remaining <= 0.0:
		return
	var speaker_position := Vector2.ZERO
	for resident in residents:
		if resident.id == bubble_speaker_id:
			speaker_position = resident.position
	var label_font := font if font != null else ThemeDB.fallback_font
	var text_width := label_font.get_string_size(bubble_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var width := text_width + 24
	var center_x := clampf(speaker_position.x, width / 2 + 6, 954 - width / 2)
	var box := Rect2(center_x - width / 2, speaker_position.y - 93, width, 30)
	draw_rect(Rect2(box.position + Vector2(2, 3), box.size), Color(0.2, 0.3, 0.2, 0.15))
	draw_rect(box, Color("fff9e7"))
	draw_rect(Rect2(Vector2(speaker_position.x - 4, box.end.y), Vector2(8, 6)), Color("fff9e7"))
	draw_string(label_font, box.position + Vector2(12, 20), bubble_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("465c51"))

func draw_ellipse_placeholder(center: Vector2, radius: Vector2, color: Color) -> void:
	# Three horizontal strips suggest a soft elliptical pixel shadow.
	draw_rect(Rect2(center - Vector2(radius.x * 0.72, radius.y), Vector2(radius.x * 1.44, radius.y * 2)), color)
	draw_rect(Rect2(center - Vector2(radius.x, radius.y * 0.55), Vector2(radius.x * 2, radius.y * 1.1)), color)
