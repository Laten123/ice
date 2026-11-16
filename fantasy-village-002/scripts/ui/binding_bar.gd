class_name FvBindingBar
extends Control
const AppState = preload("res://scripts/state/app_state.gd")
## Top bar from the 002 sketch: model portrait, presence + model UUID, and the
## number of models in the community. Values come from AppState only.

const Avatar = preload("res://scripts/ui/avatar.gd")
const INK := Color("22201d")
const MUTED := Color("6f6a63")
const PAPER := Color("fbfaf6")
const ONLINE := Color("4f7d5c")
const AWAY := Color("a0713a")

var state: AppState = null
var portrait: Control
var name_label: Label
var status_label: Label
var uuid_label: Label
var count_label: Label
var model_color := Color("84aeda")
var _built := false


func setup(app_state: AppState) -> void:
	state = app_state
	if _built:
		refresh()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	_built = true
	refresh()
	resized.connect(_layout)


func _build() -> void:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _paper_box())
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	portrait = Avatar.new()
	portrait.custom_minimum_size = Vector2(42, 42)
	portrait.tint = model_color
	add_child(portrait)

	name_label = _label(self, "", 18, INK)
	status_label = _label(self, "", 12, ONLINE)
	uuid_label = _label(self, "", 10, MUTED)
	count_label = _label(self, "", 12, MUTED)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _layout() -> void:
	if not _built or size.x < 20.0:
		return
	portrait.position = Vector2(12, 14)
	portrait.size = Vector2(42, 42)
	name_label.position = Vector2(66, 6)
	name_label.size = Vector2(maxf(80, size.x - 220), 26)
	status_label.position = Vector2(66, 31)
	status_label.size = Vector2(96, 18)
	uuid_label.position = Vector2(66, 50)
	uuid_label.size = Vector2(maxf(80, size.x - 190), 16)
	count_label.position = Vector2(size.x - 146, 8)
	count_label.size = Vector2(134, 18)


func refresh() -> void:
	if not _built or state == null or not state.has_identity():
		return
	var resident := state.bound_resident
	name_label.text = resident.display_name
	status_label.text = "● " + resident.status_label()
	status_label.add_theme_color_override("font_color",
		ONLINE if resident.status == "online" else (AWAY if resident.status == "away" else MUTED))
	uuid_label.text = "模型 UUID  " + AppState.short_uuid(resident.model.model_uuid)
	count_label.text = "社区内模型 %d" % state.model_count()


func set_model_color(color: Color) -> void:
	model_color = color
	if portrait != null:
		portrait.tint = model_color
		portrait.queue_redraw()


func _paper_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PAPER
	box.border_color = INK
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	box.shadow_color = Color(0.1, 0.09, 0.08, 0.07)
	box.shadow_size = 3
	box.shadow_offset = Vector2(1, 2)
	return box


func _label(parent: Node, text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
