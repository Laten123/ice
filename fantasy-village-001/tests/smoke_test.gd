extends SceneTree
## Run with Godot 4.6.3: godot --headless --path . --script res://tests/smoke_test.gd
## This suite checks behavior, including path traversal, rather than screenshots.

var failures: Array[String] = []
var checks: int = 0
var dialogue_events: Array[Dictionary] = []
var selection_events: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", message)
	else:
		failures.append(message)
		printerr("FAIL: ", message)


func _run() -> void:
	print("001 smoke test — Godot ", Engine.get_version_info().get("string", "unknown"))
	_test_resident_walking()
	await _test_world()
	await _test_main_scene()
	print("RESULT: ", checks - failures.size(), "/", checks, " checks passed")
	quit(0 if failures.is_empty() else 1)


func _test_resident_walking() -> void:
	var agent_script: Script = load("res://scripts/world/resident_agent.gd")
	if agent_script == null:
		_check(false, "ResidentAgent script loads")
		return
	var resident: RefCounted = agent_script.new()
	resident.configure({"id": "test", "name": "Test resident", "position": Vector2(80, 400)})
	var bounds := Rect2(16, 16, 928, 508)
	var obstacles: Array[Rect2] = [Rect2(400, 300, 160, 160)]
	var destination := Vector2(880, 400)
	_check(resident.set_destination(destination, obstacles, bounds), "A route can cross the map around a building")
	var original_target: Vector2 = resident.target
	_check(not resident.set_destination(Vector2(-20, 400), obstacles, bounds), "An out-of-bounds move is rejected")
	_check(resident.target == original_target, "A rejected move preserves the current valid route")
	_check(not resident.set_destination(Vector2(480, 350), obstacles, bounds), "A move inside a building is rejected")
	var safe: bool = true
	var moved: bool = false
	for _step: int in range(1800):
		moved = resident.tick(1.0 / 60.0) or moved
		if not bounds.has_point(resident.position):
			safe = false
		for obstacle: Rect2 in obstacles:
			if obstacle.grow(resident.FOOT_RADIUS).has_point(resident.position):
				safe = false
		if not resident.moving:
			break
	_check(moved, "Walking changes a resident's position")
	_check(safe, "The entire walk stays inside bounds and outside building footprints")
	_check(resident.position.distance_to(destination) < 0.1 and not resident.moving, "Walking reaches the requested destination and stops")
	var stopped_position: Vector2 = resident.position
	resident.tick(1.0)
	_check(resident.position == stopped_position, "A stopped resident remains still")


func _test_world() -> void:
	# Filled with the public world contract once the scene is ready.
	var world_script: Script = load("res://scripts/world/community_world.gd")
	if world_script == null:
		_check(false, "CommunityWorld script loads")
		return
	var world: Node2D = world_script.new()
	root.add_child(world)
	await process_frame
	world.set_process(false)
	world.entity_selected.connect(func(info: Dictionary) -> void: selection_events.append(info))
	world.placeholder_dialogue.connect(func(speaker: String, line: String) -> void:
		dialogue_events.append({"speaker": speaker, "line": line}))
	var residents: Array = world.get_residents()
	_check(residents.size() == 3, "The community starts with an owner and two AI placeholders")
	var resident_ids: Array[String] = []
	for info: Dictionary in residents:
		resident_ids.append(str(info.get("id", "")))
	_check(resident_ids.has("owner") and resident_ids.has("ai_1") and resident_ids.has("ai_2"), "Resident IDs support the owner and both model avatars")
	for id: String in ["owner", "ai_1", "ai_2"]:
		world.select_resident(id)
		var info: Dictionary = world.get_selected_info()
		_check(info.get("id", "") == id and not str(info.get("description", "")).is_empty(), "Selecting " + id + " returns its information")
	_check(selection_events.size() >= 3, "Resident selection emits information for the UI")
	world.request_dialogue("ai_1")
	_check(not dialogue_events.is_empty(), "Greeting an AI emits a local placeholder dialogue")
	if not dialogue_events.is_empty():
		_check(not str(dialogue_events.back().get("speaker", "")).is_empty() and not str(dialogue_events.back().get("line", "")).is_empty(), "Dialogue contains a speaker and a nonempty line")
	# Touch coordinates arrive in viewport space, including any map scale/offset.
	world.position = Vector2(64, 32)
	world.scale = Vector2(0.5, 0.5)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = world.get_global_transform_with_canvas() * Vector2(233, 145)
	world._unhandled_input(touch)
	var object_info: Dictionary = world.get_selected_info()
	_check(object_info.get("id", "") == "home", "A touch selects a house through the map's scale and offset")
	_check(not str(object_info.get("description", "")).is_empty(), "A selected object exposes a description")
	_check(world.active_resident_id == "ai_2", "Inspecting an object preserves the active moving resident")
	world._handle_pointer(Vector2(-5, 100))
	_check(world.get_selected_info().get("id", "") == "home", "A pointer outside the scene leaves selection unchanged")
	world.select_resident("owner")
	var owner = world.residents[0]
	var owner_start: Vector2 = owner.position
	var ai_start: Dictionary = {}
	for resident in world.residents:
		if resident.autonomous:
			ai_start[resident.id] = resident.position
	var ambient_before: int = dialogue_events.size()
	world._handle_pointer(Vector2(500, 450))
	_check(owner.moving, "Clicking empty ground starts the active resident walking")
	var safe: bool = true
	var world_obstacles: Array[Rect2] = world.get_obstacles()
	for _step: int in range(1800):
		world._process(1.0 / 60.0)
		for resident in world.residents:
			if not world.WALK_BOUNDS.has_point(resident.position):
				safe = false
			for obstacle: Rect2 in world_obstacles:
				if obstacle.grow(resident.FOOT_RADIUS).has_point(resident.position):
					safe = false
	_check(owner.position.distance_to(owner_start) > 10.0 and owner.position.distance_to(Vector2(500, 450)) < 0.1, "The scene's ground click moves the owner to its destination")
	_check(safe, "Residents remain inside scene bounds and outside object footprints during simulation")
	var autonomous_moved: bool = true
	for resident in world.residents:
		if resident.autonomous and resident.position.distance_to(ai_start[resident.id]) < 1.0:
			autonomous_moved = false
	_check(autonomous_moved, "Both AI placeholders walk autonomously")
	_check(dialogue_events.size() >= ambient_before + 2, "The AI placeholders exchange scheduled local dialogue")
	world.queue_free()
	await process_frame


func _test_main_scene() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	if main_scene == null:
		_check(false, "The main scene loads")
		return
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.world.set_process(false)
	_check(main.is_inside_tree(), "The playable main scene starts")
	_check(main.get_script() != null, "The main scene has its application script")
	var text: String = _collect_ui_text(main)
	_check(text.contains("幻想乡"), "The top bar displays the community name")
	_check(main.avatar_buttons.size() == 3, "The bottom dock has the owner and two AI avatars")
	main.avatar_buttons[1].pressed.emit()
	_check(main.world.selected_id == "ai_1" and main.selected_title.text == "小晴", "Clicking an AI avatar updates world selection and the information card")
	main.talk_button.pressed.emit()
	_check(main.dialogue_label.text.begins_with("小晴："), "The greeting button displays the selected resident's placeholder line")
	main.world._handle_pointer(Vector2(233, 145))
	_check(main.selected_title.text == "林间的小屋" and main.talk_button.disabled, "Clicking a house updates its information and disables resident dialogue")
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = main.world.get_global_transform_with_canvas() * (main.world.residents[2].position - Vector2(0, 22))
	main.world._unhandled_input(touch)
	_check(main.world.selected_id == "ai_2" and main.selected_title.text == "阿澈", "A touch on a resident updates the integrated information card")
	# Send actual Viewport events through GUI filtering. Calling world methods alone
	# would miss a full-screen Control accidentally consuming scene input.
	_dispatch_click(main.world.get_global_transform_with_canvas() * Vector2(233, 145))
	_check(main.selected_title.text == "林间的小屋", "A real viewport mouse click reaches the world through the GUI")
	_dispatch_click(main.avatar_buttons[0].get_global_rect().get_center())
	_check(main.world.selected_id == "owner", "A real viewport click activates the owner avatar button")
	_dispatch_click(main.world.get_global_transform_with_canvas() * Vector2(500, 450))
	_check(main.world.residents[0].moving and main.world.residents[0].target.is_equal_approx(Vector2(500, 450)), "A real viewport ground click starts owner movement")
	main.world._process(1.0)
	_check(main.world.residents[0].position.distance_to(Vector2(438, 367)) > 1.0, "The owner changes position after a dispatched ground click")
	var viewport_touch := InputEventScreenTouch.new()
	viewport_touch.index = 0
	viewport_touch.pressed = true
	viewport_touch.position = main.world.get_global_transform_with_canvas() * (main.world.residents[2].position - Vector2(0, 22))
	root.push_input(viewport_touch, true)
	_check(main.world.selected_id == "ai_2" and main.selected_title.text == "阿澈", "A real viewport touch reaches the resident through the GUI")
	var touch_release := InputEventScreenTouch.new()
	touch_release.index = 0
	touch_release.position = viewport_touch.position
	touch_release.pressed = false
	root.push_input(touch_release, true)
	var original_size: Vector2i = root.size
	root.size = Vector2i(480, 800)
	await process_frame
	await process_frame
	main._layout()
	var panel_bounds := Rect2(Vector2.ZERO, main.info_panel.size)
	var children_fit: bool = true
	for child: Node in main.info_panel.get_children():
		if child is Control and child.visible and not panel_bounds.encloses(child.get_rect()):
			children_fit = false
			printerr("Small layout overflow: ", child.name, " ", child.get_rect(), " in ", panel_bounds)
	_check(main.get_viewport_rect().size.is_equal_approx(Vector2(480, 800)), "The compact layout test uses a 480 by 800 viewport")
	_check(children_fit, "Visible information-card controls fit inside the panel at 480 by 800")
	_check(main.info_panel.get_rect().end.y <= main.dock.position.y, "The compact information card stays above the avatar dock")
	main.queue_free()
	await process_frame
	root.size = original_size
	await process_frame


func _dispatch_click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = point
	click.global_position = point
	click.pressed = true
	root.push_input(click, true)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = point
	release.global_position = point
	release.pressed = false
	root.push_input(release, true)


func _collect_ui_text(node: Node) -> String:
	var text: String = ""
	if node is Label or node is Button or node is RichTextLabel:
		text += str(node.text) + "\n"
	for child: Node in node.get_children():
		text += _collect_ui_text(child)
	return text
