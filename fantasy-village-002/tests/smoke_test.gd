extends SceneTree
const AppState = preload("res://scripts/state/app_state.gd")
const Identity = preload("res://scripts/models/identity.gd")
## 002 behavioral suite.
## Run with Godot 4.6.3:
##   godot --headless --path . --script res://tests/smoke_test.gd
## The suite checks identity rules, the login -> community flow, the sketch
## regions, placeholder interactions and the untouched walking behavior.

const TEST_SAVE := "user://fv002_test_profile.json"

var failures: Array[String] = []
var checks: int = 0


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
	print("002 smoke test — Godot ", Engine.get_version_info().get("string", "unknown"))
	_cleanup()
	_test_identity()
	_test_walking_regression()
	await _test_login_and_community()
	_cleanup()
	print("RESULT: ", checks - failures.size(), "/", checks, " checks passed")
	quit(0 if failures.is_empty() else 1)


func _cleanup() -> void:
	var absolute := ProjectSettings.globalize_path(TEST_SAVE)
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(absolute)


func _test_identity() -> void:
	var state := AppState.new()
	state.save_path = TEST_SAVE
	_check(not state.has_identity(), "A fresh local state has no identity")
	_check(state.create_identity("林间"), "A valid account name creates a local identity")
	_check(state.has_identity(), "The created state reports an identity")
	_check(_is_uuid(state.account.uuid), "The account UUID is a UUID v4")
	_check(_is_uuid(state.bound_resident.uuid), "The resident UUID is a UUID v4")
	_check(_is_uuid(state.bound_resident.model.model_uuid), "The model UUID is a UUID v4")
	_check(state.bound_resident.uuid != state.bound_resident.model.model_uuid,
		"Resident UUID and model UUID are independent")
	_check(state.land.resident_uuid == state.bound_resident.uuid,
		"The one land points at the one bound resident")
	_check(state.land.account_uuid == state.account.uuid, "The one land belongs to the account")
	_check(state.model_count() == 2, "The community contains the bound model and one neighbor")
	var bound_count := 0
	for resident: Identity.Resident in state.community_models:
		if resident.bound:
			bound_count += 1
	_check(bound_count == 1, "Exactly one resident is bound to the account")
	var resident_uuid := state.bound_resident.uuid
	var replacement := Identity.ModelBinding.new(
		"11111111-2222-4333-8444-555555555555", "local-fantasy-0.2", "小晴 0.2", true)
	_check(state.set_model_binding(replacement), "A model binding can be replaced")
	_check(state.bound_resident.uuid == resident_uuid, "Replacing the model keeps the resident UUID")
	_check(state.bound_resident.model.model_uuid != resident_uuid,
		"The replacement model has its own UUID")
	_check(state.save_identity(), "A valid identity can be persisted")
	var loaded := AppState.new()
	loaded.save_path = TEST_SAVE
	_check(loaded.load_identity(), "A persisted identity can be loaded")
	_check(loaded.account.uuid == state.account.uuid, "Loading preserves the account UUID")
	_check(loaded.bound_resident.uuid == resident_uuid, "Loading preserves the resident UUID")
	_check(loaded.bound_resident.model.display_name == "小晴 0.2",
		"Loading preserves the replaced model binding")
	_check(loaded.model_count() == 2, "Loading preserves the community model count")
	var base := _profile_snapshot(loaded)
	var duplicate_bound := base.duplicate(true)
	duplicate_bound["community_models"][1]["bound"] = true
	_expect_rejected(duplicate_bound, "A profile with two bound residents is rejected")

	var duplicate_model := base.duplicate(true)
	duplicate_model["community_models"][1]["model"]["model_uuid"] = \
		duplicate_model["community_models"][0]["model"]["model_uuid"]
	_expect_rejected(duplicate_model, "A profile with a duplicate model UUID is rejected")

	var duplicate_resident := base.duplicate(true)
	duplicate_resident["community_models"][1]["uuid"] = \
		duplicate_resident["community_models"][0]["uuid"]
	_expect_rejected(duplicate_resident, "A profile with a duplicate resident UUID is rejected")

	var missing_bound := base.duplicate(true)
	missing_bound["community_models"].remove_at(0)
	_expect_rejected(missing_bound, "A profile whose bound resident is absent is rejected")

	var empty_model := base.duplicate(true)
	empty_model["bound_resident"]["model"]["model_uuid"] = ""
	_expect_rejected(empty_model, "A profile with an empty bound model UUID is rejected")

	var wrong_land := base.duplicate(true)
	wrong_land["land"]["resident_uuid"] = wrong_land["community_models"][1]["uuid"]
	_expect_rejected(wrong_land, "A profile whose land points at another resident is rejected")

	var model_mismatch := base.duplicate(true)
	model_mismatch["community_models"][0]["model"]["model_uuid"] = \
		"22222222-3333-4444-8555-666666666666"
	_expect_rejected(model_mismatch, "A profile with a bound/community model mismatch is rejected")

	var missing_account := base.duplicate(true)
	missing_account.erase("account")
	_expect_rejected(missing_account, "A profile without an account section is rejected")

	var old_version := base.duplicate(true)
	old_version["version"] = 1
	_expect_rejected(old_version, "A profile with an unsupported version is rejected")

	var broken_file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	broken_file.store_string("{")
	broken_file.close()
	var broken := AppState.new()
	broken.save_path = TEST_SAVE
	_check(not broken.load_identity(), "Malformed JSON is rejected")
	_check(not broken.has_identity(), "Malformed JSON leaves no partial identity")
	_cleanup()


func _test_walking_regression() -> void:
	var agent_script: Script = load("res://scripts/world/resident_agent.gd")
	_check(agent_script != null, "The resident walking script still loads")
	if agent_script == null:
		return
	var resident: RefCounted = agent_script.new()
	resident.configure({"id": "test", "name": "Test resident", "position": Vector2(80, 400)})
	var bounds := Rect2(16, 16, 928, 508)
	var obstacles: Array[Rect2] = [Rect2(400, 300, 160, 160)]
	var destination := Vector2(880, 400)
	_check(resident.set_destination(destination, obstacles, bounds),
		"A route can cross the map around a building")
	var safe := true
	for _step: int in range(1800):
		resident.tick(1.0 / 60.0)
		if not bounds.has_point(resident.position):
			safe = false
		for obstacle: Rect2 in obstacles:
			if obstacle.grow(resident.FOOT_RADIUS).has_point(resident.position):
				safe = false
		if not resident.moving:
			break
	_check(safe, "The walk stays inside bounds and outside obstacles")
	_check(resident.position.distance_to(destination) < 0.1 and not resident.moving,
		"The walk reaches its destination and stops")


func _test_login_and_community() -> void:
	var scene: PackedScene = load("res://scenes/app.tscn")
	_check(scene != null, "The 002 app scene loads")
	if scene == null:
		return
	var app = scene.instantiate()
	_check(app.get_script() != null, "The app scene has its script")
	if app.get_script() == null:
		app.free()
		return
	app.state.save_path = TEST_SAVE
	root.add_child(app)
	await process_frame
	await process_frame
	await process_frame
	_check(app.font_loaded, "The packaged 002 UI font is imported and loaded")
	_check(app.login_screen != null, "The app starts on the login screen")
	if app.login_screen == null:
		app.queue_free()
		return
	var login_text := _collect_text(app.login_screen)
	_check(login_text.contains("幻想乡"), "The login screen shows the community title")
	_check(login_text.contains("AI 的交流社区"), "The login screen shows the subtitle")
	_check(login_text.contains("以主人身份进入"), "The login screen presents the owner entry")
	_check(app.login_screen.primary_button.disabled,
		"The entry button is disabled while the account name is empty")
	app.login_screen.account_input.text = "林间"
	app.login_screen.account_input.text_changed.emit("林间")
	_check(not app.login_screen.primary_button.disabled,
		"Typing a name enables the entry button")
	app.login_screen.primary_button.pressed.emit()
	await process_frame
	await process_frame
	_check(app.community_screen != null, "Submitting the login opens the community screen")
	if app.community_screen == null:
		app.queue_free()
		return
	_check(app.state.has_identity(), "The login created the local identity")
	_check(FileAccess.file_exists(TEST_SAVE), "The login persisted the local identity")

	var community = app.community_screen
	_check(community.top_bar != null and community.map_panel != null
		and community.channel != null and community.dock != null,
		"The community screen has the four sketch regions")
	var top_text := _collect_text(community.top_bar)
	_check(top_text.contains("小晴"), "The top bar shows the bound model name")
	_check(top_text.contains("模型 UUID"), "The top bar shows the model UUID label")
	_check(top_text.contains("社区内模型 2"), "The top bar shows the community model count")
	var channel_text := _collect_text(community.channel)
	_check(channel_text.contains("世界频道"), "The world channel section is visible")
	_check(community.channel.messages.size() == 2, "The world channel seeds one owner and one model message")
	_check(_collect_text(community.dock).contains("林间"), "The owner dock shows the owner name")
	_check(_collect_text(community.dock).contains("主人 UUID"), "The owner dock shows the owner UUID")

	var residents: Array = community.world.get_residents()
	_check(residents.size() == 3, "The map keeps owner + bound model + neighbor")
	var bound_uuid := str(app.state.bound_resident.uuid)
	var found_bound := false
	for info: Dictionary in residents:
		if str(info.get("uuid", "")) == bound_uuid:
			found_bound = bool(info.get("bound", false))
	_check(found_bound, "The map resident carries the bound resident UUID")

	community.world.select_resident("ai_2")
	_check(community.dock.selected_name.text.contains("阿澈"),
		"Selecting a neighbor updates the read-only model profile")
	_check(community.dock.selected_status.text.contains("仅查看"),
		"A visitor profile is explicitly read-only")
	_check(community.dock.input.visible,
		"Selecting a visitor keeps the bound private chat input visible")
	_check(community.dock.chat_title.text.contains("小晴"),
		"Private chat stays bound to the account resident")
	_check(community.dock.history_label.text.contains("小晴："),
		"Selecting a visitor does not replace the private chat history")
	community.world.select_resident("ai_1")
	_check(community.dock.selected_name.text.contains("小晴"),
		"Selecting the bound model updates its profile")
	_check(community.dock.input.visible, "The bound private chat remains visible")

	var old_color: Color = community.world.get_resident_by_uuid(bound_uuid).color
	community.dock.material_button.pressed.emit()
	var world_color: Color = community.world.get_resident_by_uuid(bound_uuid).color
	_check(world_color != old_color,
		"Material switch changes the placeholder appearance")
	_check(community.top_bar.portrait.tint == world_color,
		"Material switch keeps the top avatar in sync with the world resident")
	_check(community.world.get_resident_by_uuid(bound_uuid).uuid == bound_uuid,
		"Material switch does not change the resident UUID")
	community.dock.workshop_button.pressed.emit()
	_check(not community.dock.notice_label.text.is_empty(),
		"The workshop button gives an explicit placeholder notice")

	_check(not community.track_button.visible,
		"The tracking button is hidden while the model is at home")
	community.set_bound_presence("away")
	_check(community.track_button.visible,
		"The tracking button appears when the bound model is away")
	_check(str(community.world.get_resident_by_uuid(bound_uuid).status) == "away",
		"The world resident follows the away presence state")
	_check(community.top_bar.portrait.tint == world_color,
		"A presence refresh keeps the material appearance in sync")
	community.track_button.pressed.emit()
	_check(community.dock.notice_label.text.contains("追踪"),
		"Tracking gives an explicit placeholder notice")
	community.set_bound_presence("online")
	_check(not community.track_button.visible,
		"The tracking button disappears when the model returns")

	community.dock.input.text = "你好"
	community.dock.send_button.pressed.emit()
	_check(community.dock.input.text.is_empty(), "Sending clears the private input")
	_check(community.dock.history_label.text.contains("我：你好"),
		"The private dialog shows the sent message")
	_check(community.dock.history_label.text.contains("小晴："),
		"The private dialog shows the local placeholder reply")

	var owner = community.world.get_resident_by_uuid(str(app.state.account.uuid))
	_check(owner != null, "The owner resident carries the account UUID")
	if owner != null:
		community.world.select_resident("owner")
		var start: Vector2 = owner.position
		community.world._handle_pointer(Vector2(500, 450))
		_check(owner.moving, "Clicking empty ground still starts owner movement")
		community.world._process(1.0)
		_check(owner.position.distance_to(start) > 1.0,
			"The owner changes position after the ground click")

	community.size = Vector2(480, 800)
	community._layout()
	var top_rect: Rect2 = community.top_bar.get_rect()
	var map_rect: Rect2 = community.map_panel.get_rect()
	var channel_rect: Rect2 = community.channel.get_rect()
	var dock_rect: Rect2 = community.dock.get_rect()
	_check(map_rect.position.y >= top_rect.end.y, "The portrait map sits below the top bar")
	_check(channel_rect.position.y >= map_rect.end.y, "The portrait world channel sits below the map")
	_check(dock_rect.position.y >= channel_rect.end.y, "The portrait owner dock sits below the world channel")
	_check(dock_rect.end.y <= 800.0, "The portrait dock fits inside the 480x800 viewport")
	_check(top_rect.position.x >= 0.0 and top_rect.end.x <= 480.0,
		"The portrait top bar fits the viewport width")

	community.size = Vector2(844, 390)
	community._layout()
	top_rect = community.top_bar.get_rect()
	map_rect = community.map_panel.get_rect()
	channel_rect = community.channel.get_rect()
	dock_rect = community.dock.get_rect()
	_check(channel_rect.position.x >= map_rect.end.x,
		"The landscape channel sits to the right of the map")
	_check(dock_rect.position.x >= map_rect.end.x,
		"The landscape owner dock sits to the right of the map")
	_check(dock_rect.position.y >= channel_rect.end.y,
		"The landscape dock sits below the world channel")
	_check(map_rect.size.y >= 240.0,
		"The landscape map is not squeezed below 240 pixels")
	_check(dock_rect.end.y <= 390.0, "The landscape dock fits inside the 844x390 viewport")

	app.queue_free()
	await process_frame


func _profile_snapshot(state: AppState) -> Dictionary:
	return {
		"version": 2,
		"account": state.account.to_dict(),
		"land": state.land.to_dict(),
		"bound_resident": state.bound_resident.to_dict(),
		"community_models": [
			state.bound_resident.to_dict(),
			state.community_models[1].to_dict(),
		],
	}


func _expect_rejected(data: Dictionary, label: String) -> void:
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	var candidate := AppState.new()
	candidate.save_path = TEST_SAVE
	_check(not candidate.load_identity(), label)
	_check(not candidate.has_identity(), label + " leaves no partial identity")


func _is_uuid(value: String) -> bool:
	var parts := value.split("-")
	if parts.size() != 5:
		return false
	var lengths := [8, 4, 4, 4, 12]
	for index in range(5):
		if parts[index].length() != lengths[index]:
			return false
	return true


func _collect_text(node: Node) -> String:
	var text := ""
	if node is Label or node is Button or node is LineEdit or node is RichTextLabel:
		text += str(node.text) + "\n"
	for child: Node in node.get_children():
		text += _collect_text(child)
	return text
