class_name FvOwnerDock
extends Control
const AppState = preload("res://scripts/state/app_state.gd")
const MockService = preload("res://scripts/services/mock_community_service.gd")
## Bottom owner strip from the 002 sketch: owner identity, workshop/material
## actions, a read-only model profile and the private chat with the bound
## resident. Selecting another model never replaces or hides the private chat.

signal message_sent(text: String)
signal workshop_requested()
signal material_requested()

const Avatar = preload("res://scripts/ui/avatar.gd")
const INK := Color("22201d")
const MUTED := Color("6f6a63")
const PAPER := Color("fbfaf6")
const ACCENT := Color("6f5a8f")
const ONLINE := Color("4f7d5c")

var state: AppState = null
var owner_avatar: Control
var owner_name: Label
var owner_status: Label
var owner_uuid: Label
var selected_name: Label
var selected_status: Label
var selected_meta: Label
var chat_title: Label
var chat_divider: ColorRect
var history_label: Label
var notice_label: Label
var input: LineEdit
var send_button: Button
var workshop_button: Button
var material_button: Button
var _built := false
var _history: Array[String] = []


func setup(app_state: AppState) -> void:
	state = app_state
	if _built:
		refresh_owner()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	_built = true
	refresh_owner()
	resized.connect(_layout)
	_layout()


func _build() -> void:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _paper_box())
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	owner_avatar = Avatar.new()
	owner_avatar.tint = Color("eaa76b")
	owner_avatar.is_owner = true
	add_child(owner_avatar)
	owner_name = _label(self, "", 15, INK)
	owner_status = _label(self, "", 11, ONLINE)
	owner_uuid = _label(self, "", 9, MUTED)

	workshop_button = _button(self, "创意工坊")
	workshop_button.pressed.connect(func() -> void: workshop_requested.emit())
	material_button = _button(self, "材质切换")
	material_button.pressed.connect(func() -> void: material_requested.emit())
	notice_label = _label(self, "", 9, ACCENT)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	notice_label.clip_text = true
	notice_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	var divider := ColorRect.new()
	divider.color = Color("ddd8ce")
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.name = "DockDivider"
	add_child(divider)

	selected_name = _label(self, "模型资料", 14, INK)
	selected_status = _label(self, "点击地图上的模型查看资料", 11, MUTED)
	selected_meta = _label(self, "", 9, MUTED)
	chat_divider = ColorRect.new()
	chat_divider.color = Color("ddd8ce")
	chat_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(chat_divider)
	chat_title = _label(self, "与绑定模型的对话", 12, ACCENT)
	history_label = _label(self, "", 11, MUTED)
	history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	input = LineEdit.new()
	input.placeholder_text = "和绑定的模型说点什么"
	input.max_length = 60
	input.custom_minimum_size = Vector2(0, 34)
	input.add_theme_font_size_override("font_size", 13)
	input.text_submitted.connect(func(_text: String) -> void: _send())
	add_child(input)

	send_button = _button(self, "发送")
	send_button.pressed.connect(_send)


func refresh_owner() -> void:
	if not _built or state == null or not state.has_identity():
		return
	owner_name.text = state.account.display_name
	owner_status.text = "● 在线"
	owner_uuid.text = "主人 UUID  " + AppState.short_uuid(state.account.uuid)
	owner_avatar.queue_redraw()
	var bound_name := state.bound_resident.display_name
	chat_title.text = "与 " + bound_name + " 的对话"
	input.placeholder_text = "和 " + bound_name + " 说点什么"


func set_selected(info: Dictionary) -> void:
	if not _built:
		return
	if info.is_empty():
		selected_name.text = "模型资料"
		selected_status.text = "点击地图上的模型查看资料"
		selected_meta.text = ""
		return
	var bound := bool(info.get("bound", false))
	var display_name := str(info.get("name", "模型"))
	selected_name.text = "模型资料 · " + display_name
	var presence := str(info.get("presence", "online"))
	if bound:
		selected_status.text = "已绑定 · " + MockService.status_label(presence)
		selected_status.add_theme_color_override("font_color",
			ONLINE if presence == "online" else ACCENT)
	else:
		selected_status.text = "非自己的模型 · 仅查看"
		selected_status.add_theme_color_override("font_color", MUTED)
	selected_meta.text = "居民 " + AppState.short_uuid(str(info.get("uuid", ""))) \
		+ "  ·  模型 " + AppState.short_uuid(str(info.get("model_uuid", "")))


func set_history(lines: Array) -> void:
	_history.clear()
	for line: Variant in lines:
		_history.append(str(line))
	if not _built:
		return
	if _history.is_empty():
		history_label.text = "还没有对话。"
	else:
		var text := ""
		for index in range(maxi(0, _history.size() - 2), _history.size()):
			if not text.is_empty():
				text += "\n"
			text += _history[index]
		history_label.text = text


func show_notice(text: String) -> void:
	if _built:
		notice_label.text = text


func _send() -> void:
	var text := input.text.strip_edges()
	if text.is_empty():
		return
	input.text = ""
	message_sent.emit(text)


func _layout() -> void:
	if not _built or size.x < 20.0:
		return
	var compact := size.y < 176.0
	var owner_width := maxf(70.0, size.x - 250.0)
	owner_avatar.position = Vector2(10, 8)
	owner_avatar.size = Vector2(36, 36)
	owner_name.position = Vector2(52, 5)
	owner_name.size = Vector2(owner_width, 20)
	owner_status.position = Vector2(52, 25)
	owner_status.size = Vector2(owner_width, 16)
	owner_uuid.position = Vector2(52, 41)
	owner_uuid.size = Vector2(owner_width, 14)
	workshop_button.position = Vector2(size.x - 186, 8)
	workshop_button.size = Vector2(86, 30)
	material_button.position = Vector2(size.x - 94, 8)
	material_button.size = Vector2(84, 30)
	notice_label.position = Vector2(size.x - 188, 41)
	notice_label.size = Vector2(178, 14)

	var divider := get_node("DockDivider") as ColorRect
	divider.position = Vector2(10, 56)
	divider.size = Vector2(size.x - 20, 1)

	selected_name.position = Vector2(10, 60)
	selected_name.size = Vector2(size.x - 20, 20)
	selected_status.position = Vector2(10, 78)
	selected_status.size = Vector2(size.x - 20, 16)
	selected_meta.position = Vector2(10, 92)
	selected_meta.size = Vector2(size.x - 20, 13)
	var input_top := size.y - 42
	chat_divider.position = Vector2(10, 106)
	chat_divider.size = Vector2(size.x - 20, 1)
	chat_title.position = Vector2(10, 110)
	chat_title.size = Vector2(size.x - 20, 16)
	if compact:
		history_label.visible = false
	else:
		history_label.visible = true
		history_label.position = Vector2(10, 127)
		history_label.size = Vector2(size.x - 20, maxf(14.0, input_top - 129.0))
	input.position = Vector2(10, input_top)
	input.size = Vector2(size.x - 100, 34)
	send_button.position = Vector2(size.x - 88, input_top + 1)
	send_button.size = Vector2(78, 33)


func _button(parent: Node, text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.add_theme_font_size_override("font_size", 12)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(button)
	return button


func _paper_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PAPER
	box.border_color = INK
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	return box


func _label(parent: Node, text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
