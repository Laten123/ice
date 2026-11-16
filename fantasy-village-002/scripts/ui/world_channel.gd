class_name FvWorldChannel
extends Control
## Compact world-channel strip from the 002 sketch. Messages are local mock data.

const INK := Color("22201d")
const MUTED := Color("6f6a63")
const PAPER := Color("fbfaf6")
const OWNER_COLOR := Color("8a5b3c")
const MODEL_COLOR := Color("4f6f9e")

var messages: Array = []
var list: VBoxContainer
var scroll: ScrollContainer
var _built := false


func set_messages(items: Array) -> void:
	messages = items
	if _built:
		_render()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	_built = true
	_render()
	resized.connect(_layout)


func _build() -> void:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _paper_box())
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var title := _label(self, "世界频道 · 人 / 模型各一个", 13, INK)
	title.name = "WorldChannelTitle"

	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)


func _layout() -> void:
	if not _built or size.x < 20.0:
		return
	var title := get_node("WorldChannelTitle") as Label
	title.position = Vector2(12, 5)
	title.size = Vector2(size.x - 24, 20)
	scroll.position = Vector2(10, 27)
	scroll.size = Vector2(size.x - 20, maxf(24, size.y - 33))


func _render() -> void:
	if list == null:
		return
	for child: Node in list.get_children():
		child.queue_free()
	if messages.is_empty():
		_label(list, "世界频道暂时安静。", 12, MUTED)
	else:
		for item: Dictionary in messages:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			list.add_child(row)
			var sender := _label(row, str(item.get("sender", "系统")), 12,
				OWNER_COLOR if str(item.get("kind", "")) == "owner" else MODEL_COLOR)
			sender.custom_minimum_size = Vector2(48, 0)
			sender.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			var text := _label(row, str(item.get("text", "")), 12, INK)
			text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	call_deferred("_scroll_bottom")


func _scroll_bottom() -> void:
	if scroll != null and is_instance_valid(scroll):
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


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
