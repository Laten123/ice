class_name FvCommunityScreen
extends Control
## 002 community shell: binding bar, home plot, world channel and owner dock.
## The scene only displays the home; private chat and identity remain outside it.

const HomePlot = preload("res://scripts/world/home_plot.gd")
const BindingBar = preload("res://scripts/ui/binding_bar.gd")
const WorldChannel = preload("res://scripts/ui/world_channel.gd")
const OwnerDock = preload("res://scripts/ui/owner_dock.gd")
const AppState = preload("res://scripts/state/app_state.gd")
const MockService = preload("res://scripts/services/mock_community_service.gd")

const INK := Color("22201d")
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
const HOME_SIZE := Vector2(416, 272)
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
var home: HomePlot
var channel: WorldChannel
var dock: OwnerDock
var _private_history: Array[String] = []
var _material_index := 0
var _profile_uuid := ""
var _built := false


func setup(app_state: AppState) -> void:
	state = app_state


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	_built = true
	_layout()
	home.resident_inspected.connect(_on_entity_selected)
	home.resident_status_changed.connect(_on_resident_status)
	home.notice.connect(_on_notice)
	home.interior_changed.connect(_on_interior_changed)
	_private_history = [state.bound_resident.display_name + "：你回来啦，我刚好在院子里。"]
	dock.set_history(_private_history)
	_profile_uuid = state.bound_resident.uuid
	var bound_info: Dictionary = home.get_bound_info()
	dock.set_selected(bound_info)
	top_bar.set_model_color(bound_info.get("color", Color("84aeda")))


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

	home = HomePlot.new()
	home.name = "HomePlot"
	home.setup(state)
	home.font = theme.default_font if theme != null else null
	map_clip.add_child(home)

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
	_place(map_clip, 4, 4, map_panel.size.x - 8, map_panel.size.y - 8)
	var inside := home.is_interior_visible()
	var focus_size := Vector2(224,176) if inside else HOME_SIZE
	var focus_origin := Vector2(96,48) if inside else Vector2.ZERO
	var fit := minf(map_clip.size.x / focus_size.x, map_clip.size.y / focus_size.y)
	var scale_value := floorf(fit) if fit >= (2.0 if inside else 1.0) else fit
	home.scale = Vector2.ONE * scale_value
	home.position = (map_clip.size - focus_size * scale_value) / 2.0 - focus_origin * scale_value


func _place(control: Control, x: float, y: float, width: float, height: float) -> void:
	control.position = Vector2(x, y)
	control.size = Vector2(maxf(40.0, width), maxf(40.0, height))


func _on_entity_selected(info: Dictionary) -> void:
	dock.set_selected(info)
	_profile_uuid = str(info.get("uuid", ""))
	dock.set_history(_private_history)


func _on_resident_status() -> void:
	if dock == null:
		return
	var info: Dictionary = home.get_resident_info(_profile_uuid)
	if info.is_empty():
		info = home.get_bound_info()
	dock.set_selected(info)


func _on_notice(text: String) -> void:
	if dock != null:
		dock.show_notice(text)


func _on_interior_changed(is_open: bool) -> void:
	_layout()
	if dock != null:
		dock.show_notice("进入小屋" if is_open else "回到小院")


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
	var studio=preload("res://scripts/ui/resident_skin_studio.gd").new()
	add_child(studio)
	studio.skin_applied.connect(func(path):
		if home.set_bound_skin(path):dock.show_notice("皮肤已应用；居民身份与模型绑定保持不变")
		else:dock.show_notice("皮肤应用失败，请检查校验结果")
	)


func _on_material() -> void:
	_material_index = (_material_index + 1) % MATERIALS.size()
	var color: Color = MATERIALS[_material_index]
	home.set_bound_color(color)
	top_bar.set_model_color(color)
	dock.show_notice("材质已同步，UUID 不变")


func _map_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = MAP_FILL
	box.border_color = INK
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	return box
