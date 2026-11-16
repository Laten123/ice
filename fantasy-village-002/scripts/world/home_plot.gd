class_name FvHomePlot
extends Node2D
## Phase B home plot: 26x17 tiles, one owner_resident and one bound AI.
## Scene capability only. Decisions come from ResidentController; this node
## executes movement, affordance occupancy and action state.

signal resident_inspected(info: Dictionary)
signal resident_status_changed()
signal notice(text: String)
signal interior_changed(is_open: bool)

const Data = preload("res://data/home_data.gd")
const Atlas = preload("res://scripts/world/kenney_atlas.gd")
const Agent = preload("res://scripts/world/resident_agent.gd")
const Action = preload("res://scripts/world/resident_action_state.gd")
const Controller = preload("res://scripts/world/resident_controller.gd")
const MockController = preload("res://scripts/world/mock_life_controller.gd")
const Registry = preload("res://scripts/world/plot_registry.gd")

const TILE := 16
const SIZE := Vector2(416, 272)
const TEXTURE_PATH_TOWN := "res://assets/vendor/kenney/tiny_town.png"
const TEXTURE_PATH_FARM := "res://assets/vendor/kenney/tiny_farm.png"

var state = null
var town_atlas: Atlas
var farm_atlas: Atlas
var ground_texture: ImageTexture
var props: Array[Dictionary] = []
var affordances: Array[Dictionary] = []
var owner_resident: Agent
var bound: Agent
var owner_action: Action
var bound_action: Action
var controller: Controller
var registry
var font: Font
var interior_visible := false
var marker := Vector2.ZERO
var marker_remaining := 0.0

var _pending: Dictionary = {}
var _active: Dictionary = {}
var _selected_uuid := ""


func setup(app_state) -> void:
	state = app_state


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	town_atlas = Atlas.new()
	farm_atlas = Atlas.new()
	if not town_atlas.load_atlas(TEXTURE_PATH_TOWN) or not farm_atlas.load_atlas(TEXTURE_PATH_FARM):
		push_error("HomePlot cannot load Kenney atlases")
	_build_ground()
	_build_world()
	queue_redraw()


func _process(delta: float) -> void:
	owner_resident.tick(delta)
	if owner_action.current == Action.WALK and not owner_resident.moving:
		owner_action.reset()
	bound.tick(delta)
	if bound_action.current == Action.WALK and not bound.moving:
		bound_action.reset()
	_tick_bound(delta)
	marker_remaining = maxf(0.0, marker_remaining - delta)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_pointer(get_global_transform_with_canvas().affine_inverse() * event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_handle_pointer(get_global_transform_with_canvas().affine_inverse() * event.position)


func _handle_pointer(point: Vector2) -> void:
	if not Rect2(Vector2.ZERO, SIZE).has_point(point):
		return
	if interior_visible:
		_handle_interior_pointer(point)
		return
	get_viewport().set_input_as_handled()
	var hit := _resident_at(point)
	if not hit.is_empty():
		_selected_uuid = str(hit.get("uuid", ""))
		resident_inspected.emit(hit)
		return
	for prop: Dictionary in props:
		if (prop.get("hit_rect", Rect2()) as Rect2).has_point(point):
			notice.emit(str(prop.get("name", "物件")) + "：这是 AI 可以使用的生活设施。")
			if str(prop.get("interaction", "")) == "enter_house":
				enter_house()
			return
	move_owner_to(point)


func move_owner_to(point: Vector2) -> bool:
	if not owner_resident.set_destination(point, get_obstacles(), Data.WALK_BOUNDS):
		return false
	owner_action.begin(Action.WALK, "", 0.0)
	marker = owner_resident.target
	marker_remaining = 1.2
	resident_status_changed.emit()
	return true


func enter_house() -> void:
	interior_visible = true
	interior_changed.emit(true)
	queue_redraw()


func exit_house() -> void:
	interior_visible = false
	interior_changed.emit(false)
	queue_redraw()


func set_bound_color(color: Color) -> void:
	if bound != null:
		bound.color = color
		queue_redraw()


func get_residents() -> Array:
	return [get_owner_info(), get_bound_info()]


func get_owner_info() -> Dictionary:
	return _info_for(owner_resident, "主人", false, owner_action)


func get_bound_info() -> Dictionary:
	return _info_for(bound, "绑定模型", true, bound_action)


func get_resident_info(uuid: String) -> Dictionary:
	if owner_resident != null and owner_resident.uuid == uuid:
		return get_owner_info()
	if bound != null and bound.uuid == uuid:
		return get_bound_info()
	return {}


func get_affordance(id: String) -> Dictionary:
	for affordance: Dictionary in affordances:
		if str(affordance.get("id", "")) == id:
			return affordance
	return {}


func can_reserve_affordance(id: String, resident_uuid: String) -> bool:
	var affordance := get_affordance(id)
	if affordance.is_empty() or not bool(affordance.get("enabled", true)):
		return false
	var occupied := str(affordance.get("occupied_by", ""))
	return occupied.is_empty() or occupied == resident_uuid


func reserve_affordance(id: String, resident_uuid: String) -> bool:
	if not can_reserve_affordance(id, resident_uuid):
		return false
	get_affordance(id)["occupied_by"] = resident_uuid
	return true


func release_affordance(id: String, resident_uuid: String) -> void:
	var affordance := get_affordance(id)
	if not affordance.is_empty() and str(affordance.get("occupied_by", "")) == resident_uuid:
		affordance["occupied_by"] = ""


func is_interior_visible() -> bool:
	return interior_visible


func get_bound_action() -> String:
	return bound_action.current if bound_action != null else Action.IDLE


func get_obstacles() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for prop: Dictionary in props:
		if prop.has("obstacle"):
			result.append(prop["obstacle"] as Rect2)
	return result


func _build_world() -> void:
	props = Data.props()
	affordances = Data.affordances()
	for affordance: Dictionary in affordances:
		affordance["occupied_by"] = ""
		affordance["enabled"] = true
	owner_resident = Agent.new()
	owner_resident.configure({
		"id": "owner", "uuid": state.account.uuid,
		"name": state.account.display_name, "role": "主人",
		"description": "家园的主人。", "position": Data.OWNER_START,
		"color": Color("eaa76b"), "status": "online", "autonomous": false,
	})
	bound = Agent.new()
	bound.configure({
		"id": "bound_ai", "uuid": state.bound_resident.uuid,
		"model_uuid": state.bound_resident.model.model_uuid,
		"model_name": state.bound_resident.model.display_name,
		"name": state.bound_resident.display_name, "role": "绑定模型",
		"description": "和你绑定的 AI 居民。", "position": Data.BOUND_START,
		"color": Color("84aeda"), "status": "online", "autonomous": true,
	})
	owner_action = Action.new()
	bound_action = Action.new()
	controller = MockController.new()
	registry = Registry.new(state)


func _build_ground() -> void:
	var image := Image.create(int(SIZE.x), int(SIZE.y), false, Image.FORMAT_RGBA8)
	image.fill(Color("9fc780"))
	for y in range(Data.ROWS):
		for x in range(Data.COLS):
			town_atlas.blit_tile(image, 1, Vector2i(x * TILE, y * TILE))
	# Path from the house door to the bottom gate.
	for y in range(7, Data.ROWS):
		for x in range(11, 13):
			town_atlas.blit_tile(image, 39, Vector2i(x * TILE, y * TILE))
	# Garden soil and crops.
	for y in range(8, 11):
		for x in range(17, 22):
			farm_atlas.blit_tile(image, 24 + (x + y) % 2, Vector2i(x * TILE, y * TILE))
	for crop: Dictionary in Data.crops():
		var cell: Vector2i = crop["cell"]
		farm_atlas.blit_tile(image, int(crop["index"]), cell * TILE)
	# A few deterministic flower decorations.
	for cell in [Vector2i(3, 3), Vector2i(23, 14), Vector2i(1, 15), Vector2i(24, 2)]:
		town_atlas.blit_tile(image, 2, cell * TILE)
	# Fence boundary; leave a two-cell gate at the bottom centre.
	for x in range(Data.COLS):
		town_atlas.blit_tile(image, 45, Vector2i(x * TILE, 0))
		if x < 11 or x > 12:
			town_atlas.blit_tile(image, 45, Vector2i(x * TILE, (Data.ROWS - 1) * TILE))
	for y in range(1, Data.ROWS - 1):
		town_atlas.blit_tile(image, 56, Vector2i(0, y * TILE))
		town_atlas.blit_tile(image, 56, Vector2i((Data.COLS - 1) * TILE, y * TILE))
	ground_texture = ImageTexture.create_from_image(image)


func _tick_bound(delta: float) -> void:
	if not _active.is_empty():
		_active["remaining"] = float(_active.get("remaining", 0.0)) - delta
		if float(_active["remaining"]) <= 0.0:
			_finish_action()
		return
	if not _pending.is_empty():
		if bound.moving:
			return
		_start_action(_pending)
		return
	if bound.moving:
		return
	var intent: Dictionary = controller.decide({
		"busy": false,
		"state": bound_action.current,
		"interior": interior_visible,
		"resident_uuid": bound.uuid,
	})
	if not intent.is_empty():
		_begin_intent(intent)


func _begin_intent(intent: Dictionary) -> void:
	var affordance := get_affordance(str(intent.get("affordance", "")))
	if affordance.is_empty():
		return
	var action := str(intent.get("action", "interact"))
	if action == "exit" or (action == "rest" and interior_visible):
		_pending = intent.duplicate(true)
		_start_action(_pending)
		return
	var approach: Vector2 = affordance["approach"]
	if bound.position.distance_to(approach) < 2.0:
		_pending = intent.duplicate(true)
		_start_action(_pending)
		return
	if bound.set_destination(approach, get_obstacles(), Data.WALK_BOUNDS):
		bound_action.begin(Action.WALK, str(affordance["id"]), 0.0)
		_pending = intent.duplicate(true)
	else:
		push_warning("HomePlot: cannot reach affordance " + str(affordance["id"]))


func _start_action(intent: Dictionary) -> void:
	var affordance := get_affordance(str(intent.get("affordance", "")))
	if affordance.is_empty():
		_pending = {}
		return
	var action := str(intent.get("action", "interact"))
	var duration := float(intent.get("duration", affordance.get("duration", 2.0)))
	if not reserve_affordance(str(affordance["id"]), bound.uuid):
		_pending = {}
		return
	bound.moving = false
	bound.waypoints.clear()
	_pending = {}
	match action:
		"enter":
			interior_visible = true
			interior_changed.emit(true)
			bound_action.begin(Action.ENTER, str(affordance["id"]), duration)
		"exit":
			interior_visible = false
			interior_changed.emit(false)
			bound.position = affordance["approach"]
			bound_action.begin(Action.EXIT, str(affordance["id"]), duration)
		"rest":
			bound_action.begin(Action.REST, str(affordance["id"]), duration)
		"sit":
			bound.position = affordance["position"]
			bound_action.begin(Action.SIT, str(affordance["id"]), duration)
		"observe":
			bound.position = affordance["approach"]
			bound_action.begin(Action.INTERACT, str(affordance["id"]), duration)
		_:
			bound_action.begin(Action.INTERACT, str(affordance["id"]), duration)
	_active = intent.duplicate(true)
	_active["remaining"] = duration
	resident_status_changed.emit()


func _finish_action() -> void:
	var finished := bound_action.current
	var finished_id := bound_action.affordance_id
	bound_action.reset()
	_active = {}
	_selected_uuid = ""
	var affordance := get_affordance(finished_id)
	release_affordance(finished_id, bound.uuid)
	if finished == Action.ENTER and not affordance.is_empty():
		bound.position = affordance["approach"]
	elif finished == Action.SIT and not affordance.is_empty():
		# Standing up must leave the seat obstacle before the next path query.
		bound.position = affordance["approach"]
	resident_status_changed.emit()


func _info_for(agent: Agent, role: String, is_bound: bool, action: Action) -> Dictionary:
	return {
		"id": agent.id,
		"name": agent.display_name,
		"kind": "resident",
		"role": role,
		"description": agent.description,
		"uuid": agent.uuid,
		"model_uuid": agent.model_uuid,
		"model_name": agent.model_name,
		"bound": is_bound,
		"presence": agent.status,
		"status": action.current,
		"action": action.current,
		"position": agent.position,
		"color": agent.color,
	}


func _resident_at(point: Vector2) -> Dictionary:
	for agent: Agent in [owner_resident, bound]:
		if agent == null:
			continue
		if Rect2(agent.position - Vector2(16, 40), Vector2(32, 44)).has_point(point):
			return _info_for(agent, "主人" if agent == owner_resident else "绑定模型",
				agent == bound, owner_action if agent == owner_resident else bound_action)
	return {}


func _handle_interior_pointer(point: Vector2) -> void:
	get_viewport().set_input_as_handled()
	if Rect2(152, 204, 112, 32).has_point(point):
		exit_house()
	elif Rect2(100, 70, 64, 64).has_point(point):
		notice.emit("床铺：小晴会自己回来休息。")


func _draw() -> void:
	if ground_texture != null:
		draw_texture_rect(ground_texture, Rect2(Vector2.ZERO, SIZE), false)
	if marker_remaining > 0.0:
		var color := Color("edf6ce")
		color.a = marker_remaining / 1.2
		draw_arc(marker, 10, 0, TAU, 16, color, 2)
	var renderables: Array = []
	for prop: Dictionary in props:
		renderables.append({"y": _prop_sort_y(prop), "prop": prop})
	if not interior_visible:
		renderables.append({"y": owner_resident.position.y, "agent": owner_resident, "info": get_owner_info()})
		renderables.append({"y": bound.position.y, "agent": bound, "info": get_bound_info()})
	renderables.sort_custom(func(a, b): return float(a["y"]) < float(b["y"]))
	for entry in renderables:
		if entry.has("prop"):
			_draw_prop(entry["prop"])
		else:
			_draw_resident(entry["agent"], entry["info"])
	if interior_visible:
		_draw_interior()


func _prop_sort_y(prop: Dictionary) -> float:
	if str(prop.get("kind", "")) == "house":
		return (prop["base"] as Vector2).y + 5 * TILE
	return (prop["base"] as Vector2).y


func _draw_prop(prop: Dictionary) -> void:
	var base: Vector2 = prop["base"]
	if str(prop.get("kind", "")) == "house":
		for tile: Dictionary in prop["tiles"]:
			var atlas: Atlas = town_atlas if str(tile["source"]) == "town" else farm_atlas
			draw_texture_rect_region(atlas.texture,
				Rect2(base + Vector2(tile["cell"] as Vector2i) * TILE, Vector2(TILE, TILE)),
				atlas.region(int(tile["index"])))
		return
	var scale_value := int(prop.get("scale", 1))
	for tile: Dictionary in prop["tiles"]:
		var atlas: Atlas = town_atlas if str(tile["source"]) == "town" else farm_atlas
		var tile_size := Vector2(TILE, TILE) * scale_value
		var top_left := base - Vector2(tile_size.x / 2.0, tile_size.y)
		draw_texture_rect_region(atlas.texture,
			Rect2(top_left + Vector2(tile["cell"] as Vector2i) * tile_size, tile_size),
			atlas.region(int(tile["index"])))


func _draw_resident(agent: Agent, info: Dictionary) -> void:
	var position := agent.position.round()
	_draw_shadow(position + Vector2(0, 2), Vector2(14, 4), Color(0.2, 0.3, 0.2, 0.18))
	var index := 108 if agent == owner_resident else 109
	var tint: Color = info.get("color", Color.WHITE)
	draw_texture_rect_region(farm_atlas.texture,
		Rect2(position - Vector2(16, 32), Vector2(32, 32)),
		farm_atlas.region(index), tint)
	if _selected_uuid == agent.uuid:
		draw_arc(position, 18, 0, TAU, 20, Color("fff3c0"), 2)
	_draw_tag(agent.display_name, position + Vector2(0, 4), info)


func _draw_tag(text: String, center: Vector2, info: Dictionary) -> void:
	var label_font := font if font != null else ThemeDB.fallback_font
	var width := label_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 12
	draw_rect(Rect2(center - Vector2(width / 2.0, 14), Vector2(width, 18)), Color("fff8df"))
	draw_string(label_font, center + Vector2(-width / 2.0 + 6, 0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("425b4d"))
	if str(info.get("action", "idle")) != "idle":
		draw_string(label_font, center + Vector2(-width / 2.0 + 6, 13),
			str(info["action"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("6f5a8f"))


func _draw_interior() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.1, 0.09, 0.08, 0.55))
	var room := Rect2(72, 36, 272, 196)
	draw_rect(room, Color("d6a56c"))
	for line_y in range(1, 12):
		draw_line(Vector2(room.position.x, room.position.y + line_y * TILE),
			Vector2(room.end.x, room.position.y + line_y * TILE), Color("bd8757"), 1)
	draw_rect(Rect2(room.position + Vector2(36, 90), Vector2(92, 52)), Color("a45f5f"))
	draw_rect(Rect2(room.position + Vector2(40, 94), Vector2(84, 44)), Color("c47a72"))
	draw_rect(room, Color("5a3b2e"), false, 3)
	# Furniture: bed, table, chair.
	draw_texture_rect_region(farm_atlas.texture, Rect2(100, 70, 64, 64),
		farm_atlas.region(97), Color.WHITE)
	draw_texture_rect_region(farm_atlas.texture, Rect2(196, 88, 48, 48),
		farm_atlas.region(96), Color.WHITE)
	draw_texture_rect_region(farm_atlas.texture, Rect2(208, 140, 32, 32),
		farm_atlas.region(98), Color.WHITE)
	var label_font := font if font != null else ThemeDB.fallback_font
	draw_string(label_font, Vector2(108, 66), "床", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("5a3b2e"))
	draw_string(label_font, Vector2(198, 84), "桌", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("5a3b2e"))
	draw_string(label_font, Vector2(88, 26), "小屋内 · 小晴在生活",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("fff8df"))
	var exit_rect := Rect2(152, 204, 112, 32)
	draw_rect(exit_rect, Color("fbfaf6"))
	draw_rect(exit_rect, Color("22201d"), false, 2)
	draw_string(label_font, Vector2(184, 226), "出口", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("22201d"))


func _draw_shadow(center: Vector2, radius: Vector2, color: Color) -> void:
	draw_rect(Rect2(center - Vector2(radius.x, radius.y * 0.55), Vector2(radius.x * 2, radius.y * 1.1)), color)
