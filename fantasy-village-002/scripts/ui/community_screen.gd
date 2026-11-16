class_name FvCommunityScreen
extends Control
## 002 community screen from the second sketch:
## top binding bar -> community map -> world channel -> owner dock.
## Placeholder art and local mock services only; no real model connection.

const WorldScript = preload("res://scripts/world/community_world.gd")
const BindingBar = preload("res://scripts/ui/binding_bar.gd")
const WorldChannel = preload("res://scripts/ui/world_channel.gd")
const OwnerDock = preload("res://scripts/ui/owner_dock.gd")
const AppState = preload("res://scripts/state/app_state.gd")
const MockService = preload("res://scripts/services/mock_community_service.gd")

const INK := Color("22201d")
const MUTED := Color("6f6a63")
const PAPER := Color("fbfaf6")
const MAP_FILL := Color("e4edd8")
const PAD_NARROW := 12.0
const PAD_WIDE := 20.0
const TOPBAR_H := 72.0
const TOPBAR_H_WIDE := 68.0
const DOCK_H := 204.0
const DOCK_H_WIDE := 190.0
const CHANNEL_H := 106.0
const RIGHT_COL_W := 360.0
const GAP := 8.0
const MATERIALS := [
	Color("84aeda"),
	Color("8fbf9a"),
	Color("d9a36f"),
	Color("b59bcf"),
]

var state: AppState = null
var top_bar: BindingBar
var map_panel: Panel
var map_clip: Control
var world: Node2D
var track_button: Button
var channel: WorldChannel
var dock: OwnerDock
var _private_history: Array[String] = []
var _material_index := 0
var _built := false


func setup(app_state: AppState) -> void:
	state = app_state


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	_built = true
	_layout()
	world.entity_selected.connect(_on_entity_selected)
	world.resident_status_changed.connect(_on_world_status)
	world.select_resident("ai_1")
	_private_history = [state.bound_resident.display_name + "：你回来啦，我刚好在广场。"]
	dock.set_history(_private_history)
	var bound_agent = world.get_resident_by_uuid(state.bound_resident.uuid)
	if bound_agent != null:
		top_bar.set_model_color(bound_agent.color)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _built:
		_layout()


func _build() -> void:
	var background := ColorRect.new()
	background.color = Color("efeeea")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	map_panel = Panel.new()
	map_panel.name = "MapPanel"
	map_panel.add_theme_stylebox_override("panel", _map_box())
	map_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_panel)
	map_clip = Control.new()
	map_clip.name = "MapClip"
	map_clip.clip_contents = true
	map_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_panel.add_child(map_clip)

	world = WorldScript.new()
	world.name = "CommunityWorld"
	world.apply_identity(state)
	world.font = theme.default_font if theme != null else null
	map_clip.add_child(world)

	track_button = Button.new()
	track_button.name = "TrackButton"
	track_button.text = "模型出门了 · 点击追踪位置"
	track_button.add_theme_font_size_override("font_size", 12)
	track_button.visible = false
	track_button.pressed.connect(_on_track)
	map_panel.add_child(track_button)

	top_bar = BindingBar.new()
	top_bar.name = "BindingBar"
	top_bar.setup(state)
	add_child(top_bar)

	channel = WorldChannel.new()
	channel.name = "WorldChannel"
	channel.set_messages(MockService.world_messages(state))
	add_child(channel)

	dock = OwnerDock.new()
	dock.name = "OwnerDock"
	dock.setup(state)
	dock.message_sent.connect(_on_private_message)
	dock.workshop_requested.connect(_on_workshop)
	dock.material_requested.connect(_on_material)
	add_child(dock)


func _layout() -> void:
	if not _built:
		return
	var view := size
	if view.x <= 0.0 or view.y <= 0.0:
		view = get_viewport_rect().size
	var narrow := view.x < 760.0
	if narrow:
		_place(top_bar, PAD_NARROW, 12, view.x - PAD_NARROW * 2.0, TOPBAR_H)
		_place(dock, PAD_NARROW, view.y - 12.0 - DOCK_H,
			view.x - PAD_NARROW * 2.0, DOCK_H)
		_place(channel, PAD_NARROW, dock.position.y - GAP - CHANNEL_H,
			view.x - PAD_NARROW * 2.0, CHANNEL_H)
		_place(map_panel, PAD_NARROW, top_bar.position.y + top_bar.size.y + GAP,
			view.x - PAD_NARROW * 2.0,
			channel.position.y - GAP - (top_bar.position.y + top_bar.size.y + GAP))
	else:
		_place(top_bar, PAD_WIDE, 12, view.x - PAD_WIDE * 2.0, TOPBAR_H_WIDE)
		var body_top := top_bar.position.y + top_bar.size.y + 10.0
		var body_bottom := view.y - 12.0
		var right_x := view.x - PAD_WIDE - RIGHT_COL_W
		_place(map_panel, PAD_WIDE, body_top,
			right_x - GAP - PAD_WIDE, body_bottom - body_top)
		_place(dock, right_x, body_bottom - DOCK_H_WIDE, RIGHT_COL_W, DOCK_H_WIDE)
		_place(channel, right_x, body_top, RIGHT_COL_W,
			dock.position.y - GAP - body_top)
	_place(map_clip, 6, 6, map_panel.size.x - 12, map_panel.size.y - 12)
	var scale_value := minf(map_clip.size.x / 960.0, map_clip.size.y / 540.0)
	world.scale = Vector2.ONE * scale_value
	world.position = (map_clip.size - Vector2(960, 540) * scale_value) / 2.0
	track_button.position = Vector2(maxf(8.0, (map_panel.size.x - 232.0) / 2.0),
		map_panel.size.y - 50.0)
	track_button.size = Vector2(232, 40)


func _place(control: Control, x: float, y: float, width: float, height: float) -> void:
	control.position = Vector2(x, y)
	control.size = Vector2(maxf(40.0, width), maxf(40.0, height))


func _on_entity_selected(info: Dictionary) -> void:
	if str(info.get("kind", "")) != "resident":
		dock.show_notice("查看：" + str(info.get("name", "场景物品")))
		return
	dock.set_selected(info)
	dock.set_history(_private_history)


func _on_world_status() -> void:
	if dock == null or not _built:
		return
	var info: Dictionary = world.get_selected_info()
	if str(info.get("kind", "")) == "resident":
		dock.set_selected(info)


func _on_private_message(text: String) -> void:
	if state == null or state.bound_resident == null:
		return
	_private_history.append("我：" + text)
	var reply := MockService.private_reply(text, state.bound_resident)
	_private_history.append(state.bound_resident.display_name + "：" + reply)
	while _private_history.size() > 8:
		_private_history.pop_front()
	dock.set_history(_private_history)
	dock.show_notice("本地占位回复")


func _on_workshop() -> void:
	dock.show_notice("创意工坊 003 开放")


func _on_material() -> void:
	_material_index = (_material_index + 1) % MATERIALS.size()
	var color: Color = MATERIALS[_material_index]
	var resident = world.get_resident_by_uuid(state.bound_resident.uuid)
	if resident != null:
		resident.color = color
		world.queue_redraw()
	if top_bar != null:
		top_bar.set_model_color(color)
	dock.show_notice("材质已同步，UUID 不变")


func _on_track() -> void:
	dock.show_notice("追踪请求已记录（占位）")


func set_bound_presence(status: String) -> void:
	if state == null or not state.has_identity():
		return
	state.bound_resident.status = status
	world.set_resident_status("ai_1", status)
	track_button.visible = status == "away"
	top_bar.refresh()
	var info: Dictionary = world.get_selected_info()
	if str(info.get("kind", "")) == "resident":
		dock.set_selected(info)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		set_bound_presence("online" if state.bound_resident.status == "away" else "away")


func _map_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = MAP_FILL
	box.border_color = INK
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	return box
