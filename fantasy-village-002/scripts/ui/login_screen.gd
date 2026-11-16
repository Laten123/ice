class_name FvLoginScreen
extends Control
const AppState = preload("res://scripts/state/app_state.gd")
## 002 login screen. It creates or reuses the local identity and never talks to
## an account server. The paper/sketch styling is placeholder art.

signal submitted(display_name: String, create_new: bool)

const Avatar = preload("res://scripts/ui/avatar.gd")
const SketchFrame = preload("res://scripts/ui/sketch_frame.gd")
const INK := Color("22201d")
const MUTED := Color("6f6a63")
const PAPER := Color("fbfaf6")
const BACKGROUND := Color("efeeea")
const ACCENT := Color("6f5a8f")
const ONLINE := Color("4f7d5c")
const ERROR := Color("a4443f")

var state: AppState = null
var account_input: LineEdit
var primary_button: Button
var secondary_button: Button
var error_label: Label
var model_name: Label
var model_status: Label
var model_uuid: Label
var portrait: Control
var column: VBoxContainer
var is_new := true
var _built := false


func setup(app_state: AppState) -> void:
	state = app_state
	if _built:
		_refresh()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	_built = true
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _built:
		_update_width()


func _build() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)

	var title_frame := SketchFrame.new()
	title_frame.custom_minimum_size = Vector2(0, 148)
	column.add_child(title_frame)
	var title := _label(title_frame, "幻想乡", 46, INK)
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var subtitle := _label(column, "AI 的交流社区", 17, MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _paper_box())
	column.add_child(card)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22 if side != "top" else 18)
	card.add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 9)
	margin.add_child(body)

	_label(body, "以主人身份进入", 13, MUTED)
	_label(body, "账号名称", 13, INK)
	account_input = LineEdit.new()
	account_input.placeholder_text = "输入你的名字"
	account_input.max_length = 12
	account_input.custom_minimum_size = Vector2(0, 46)
	account_input.add_theme_font_size_override("font_size", 17)
	account_input.text_changed.connect(_on_text_changed)
	account_input.text_submitted.connect(func(_text: String) -> void: _submit())
	body.add_child(account_input)

	var preview := HBoxContainer.new()
	preview.add_theme_constant_override("separation", 12)
	body.add_child(preview)
	portrait = Avatar.new()
	portrait.custom_minimum_size = Vector2(46, 46)
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait.tint = Color("84aeda")
	preview.add_child(portrait)
	var preview_text := VBoxContainer.new()
	preview_text.add_theme_constant_override("separation", 1)
	preview_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.add_child(preview_text)
	model_name = _label(preview_text, "小晴", 17, INK)
	model_status = _label(preview_text, "在线", 12, ONLINE)
	model_uuid = _label(preview_text, "", 11, MUTED)
	model_uuid.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var divider := ColorRect.new()
	divider.color = Color("ddd8ce")
	divider.custom_minimum_size = Vector2(0, 1)
	body.add_child(divider)

	primary_button = Button.new()
	primary_button.text = "进入幻想乡"
	primary_button.custom_minimum_size = Vector2(0, 46)
	primary_button.add_theme_font_size_override("font_size", 17)
	primary_button.pressed.connect(_submit)
	body.add_child(primary_button)

	secondary_button = Button.new()
	secondary_button.text = "随机一个名字"
	secondary_button.custom_minimum_size = Vector2(0, 36)
	secondary_button.add_theme_font_size_override("font_size", 14)
	secondary_button.pressed.connect(_random_name)
	body.add_child(secondary_button)

	error_label = _label(body, "", 12, ERROR)
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	error_label.visible = false

	_label(body, "一个账号 · 一块土地 · 一个绑定模型", 12, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(body, "当前为本地模拟，尚未连接真实模型", 11, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var footer := _label(column, "002 · 登录页界面原型", 11, MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_update_width()


func _update_width() -> void:
	if column == null:
		return
	var available := size.x - 40.0
	if available <= 0.0:
		available = 420.0
	column.custom_minimum_size.x = clampf(available, 320.0, 440.0)


func _refresh() -> void:
	if state == null or account_input == null:
		return
	is_new = not state.has_identity()
	primary_button.disabled = true
	error_label.visible = false
	if is_new:
		account_input.text = ""
		primary_button.text = "进入幻想乡"
		secondary_button.visible = true
		model_name.text = "首次进入将绑定「小晴」"
		model_status.text = "本地占位模型"
		model_status.add_theme_color_override("font_color", MUTED)
		model_uuid.text = "创建后生成居民 UUID 与模型 UUID"
		portrait.tint = Color("84aeda")
	else:
		account_input.text = state.account.display_name
		primary_button.text = "回到幻想乡"
		primary_button.disabled = false
		secondary_button.visible = false
		var resident := state.bound_resident
		model_name.text = resident.display_name
		model_status.text = resident.status_label() + " · 本地占位模型"
		model_status.add_theme_color_override("font_color",
			ONLINE if resident.status == "online" else MUTED)
		model_uuid.text = "模型 UUID " + state.short_uuid(resident.model.model_uuid)
		portrait.tint = Color("84aeda")
	portrait.queue_redraw()


func _on_text_changed(new_text: String) -> void:
	if primary_button == null:
		return
	primary_button.disabled = new_text.strip_edges().is_empty()
	if error_label != null:
		error_label.visible = false


func _random_name() -> void:
	var names := ["林间", "小雨", "阿青", "南枝"]
	account_input.text = names[randi() % names.size()]
	account_input.caret_column = account_input.text.length()
	primary_button.disabled = false
	account_input.grab_focus()


func _submit() -> void:
	var cleaned := account_input.text.strip_edges()
	if cleaned.is_empty():
		_show_error("请输入账号名称。")
		return
	if cleaned.length() > 12:
		_show_error("账号名称最多 12 个字。")
		return
	error_label.visible = false
	submitted.emit(cleaned, is_new)


func _show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = true


func _paper_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PAPER
	box.border_color = INK
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	box.shadow_color = Color(0.1, 0.09, 0.08, 0.08)
	box.shadow_size = 4
	box.shadow_offset = Vector2(2, 3)
	return box


func _label(parent: Node, text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
