extends Control
## Presentation only. World state and placeholder behavior stay in CommunityWorld.

const WorldScript = preload("res://scripts/world/community_world.gd")
const Avatar = preload("res://scripts/ui/avatar.gd")
const PlaceholderFont = preload("res://assets/ui/placeholder_ui.otf")
const INK := Color("39344c")
const MUTED := Color("847e91")
const PURPLE := Color("8672b6")
const EDGE := Color("e7e1ed")

var world: Node2D
var selected_title: Label
var selected_description: Label
var selected_status: Label
var dialogue_label: Label
var talk_button: Button
var info_avatar: Control
var selected_kind: Label
var info_hint: Label
var ui_font: Font
var header: Panel
var intro: Control
var map_panel: Panel
var map_clip: Control
var info_panel: Panel
var dock: Panel
var footer: Label
var avatar_buttons: Array[Button] = []
var current_info: Dictionary = {}
var _layout_pending := false

func _ready() -> void:
	# Let the world receive clicks on uncovered ground; child panels still consume UI clicks.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# User-approved temporary glyph subset keeps Chinese readable in Web exports.
	ui_font = PlaceholderFont
	var app_theme := Theme.new()
	app_theme.default_font = ui_font
	app_theme.default_font_size = 18
	app_theme.set_color("font_color", "Label", INK)
	app_theme.set_color("font_color", "Button", INK)
	app_theme.set_color("font_hover_color", "Button", PURPLE)
	app_theme.set_color("font_focus_color", "Button", PURPLE)
	app_theme.set_stylebox("normal", "Button", _box(Color("f7f3fb"), EDGE, 12))
	app_theme.set_stylebox("hover", "Button", _box(Color("eee7f8"), Color("b8a5d5"), 12))
	app_theme.set_stylebox("pressed", "Button", _box(Color("e3d8f1"), PURPLE, 12))
	app_theme.set_stylebox("focus", "Button", _box(Color.TRANSPARENT, PURPLE, 12, 2))
	theme = app_theme
	_build_header()
	_build_scene()
	_build_info()
	_build_dock()
	footer = _label(self, "点击角色或物品查看信息 · 点击空地移动当前居民", 14, MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world.entity_selected.connect(_show_info)
	world.placeholder_dialogue.connect(_on_dialogue)
	world.resident_status_changed.connect(_refresh_status)
	world.select_resident("owner")
	_layout()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready() and not _layout_pending:
		_layout_pending = true
		call_deferred("_layout")

func _box(fill: Color, border: Color, radius: int, border_width: int = 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 14
	box.content_margin_right = 14
	return box

func _panel(parent: Node, fill: Color, border: Color = EDGE, radius: int = 18) -> Panel:
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", _box(fill, border, radius))
	parent.add_child(panel)
	return panel

func _label(parent: Node, text_value: String, font_size: int, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _place(control: Control, x: float, y: float, width: float, height: float) -> void:
	control.position = Vector2(x, y)
	control.size = Vector2(width, height)

func _build_header() -> void:
	header = _panel(self, Color("fffdf9"))
	var logo := _panel(header, Color("eae2f5"), Color("eae2f5"), 12)
	logo.name = "Logo"
	_place(logo, 16, 14, 44, 44)
	var mark := _label(logo, "乡", 26, PURPLE)
	_place(mark, 0, 2, 44, 40)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title := _label(header, "幻想乡", 26)
	title.name = "CommunityTitle"
	_place(title, 73, 8, 160, 38)
	var subtitle := _label(header, "F A N T A S Y   V I L L A G E", 10, MUTED)
	_place(subtitle, 74, 42, 200, 20)
	var status := _label(header, "●  3 位居民   /   本地模拟", 16, Color("608c78"))
	status.name = "CommunityStatus"
	var version := _label(header, "001  项目骨架", 13, MUTED)
	version.name = "Version"
	intro = Control.new()
	intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(intro)
	var title_line := _label(intro, "今天，也在这里相遇。", 28)
	title_line.name = "Greeting"
	_place(title_line, 0, 0, 600, 40)
	var caption := _label(intro, "在小小的社区里，看看大家正在做什么。", 16, MUTED)
	_place(caption, 1, 43, 650, 25)

func _build_scene() -> void:
	map_panel = _panel(self, Color("e4edd8"), Color("c9d8bb"))
	map_clip = Control.new()
	map_clip.clip_contents = true
	map_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_panel.add_child(map_clip)
	world = WorldScript.new()
	world.name = "CommunityWorld"
	world.font = ui_font
	map_clip.add_child(world)

func _build_info() -> void:
	info_panel = _panel(self, Color("fffdf9"))
	var overline := _label(info_panel, "此刻，社区里", 14, MUTED)
	overline.name = "InfoOverline"
	info_avatar = Avatar.new()
	info_avatar.name = "InfoAvatar"
	info_panel.add_child(info_avatar)
	selected_kind = _label(info_panel, "社区主人", 13, PURPLE)
	selected_title = _label(info_panel, "林间", 25)
	selected_title.name = "SelectedTitle"
	selected_status = _label(info_panel, "自在地生活", 15, Color("608c78"))
	selected_description = _label(info_panel, "", 16, MUTED)
	selected_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_description.name = "SelectedDescription"
	talk_button = Button.new()
	talk_button.text = "打个招呼  →"
	talk_button.pressed.connect(_greet_selected)
	info_panel.add_child(talk_button)
	info_hint = _label(info_panel, "生活片段 · 占位对话", 13, PURPLE)
	dialogue_label = _label(info_panel, "小晴：今天的阳光真好呀。\n阿澈：一起在社区走走吧！", 15)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.name = "Dialogue"

func _build_dock() -> void:
	dock = _panel(self, Color("fffdf9"))
	var title := _label(dock, "社区居民", 15, MUTED)
	_place(title, 18, 9, 180, 24)
	var hint := _label(dock, "点击头像，切换移动角色", 13, MUTED)
	hint.name = "DockHint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var residents: Array = world.get_residents()
	for info in residents:
		var button := Button.new()
		button.name = "Resident_" + str(info.id)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = ""
		button.pressed.connect(world.select_resident.bind(str(info.id)))
		dock.add_child(button)
		var portrait := Avatar.new()
		portrait.name = "Portrait"
		portrait.tint = info.get("color", PURPLE)
		portrait.is_owner = str(info.id) == "owner"
		button.add_child(portrait)
		var name_label := _label(button, str(info.name), 18)
		name_label.name = "ResidentName"
		var role := _label(button, "主人 · 你" if str(info.id) == "owner" else "AI 模型 · 占位", 12, MUTED)
		role.name = "ResidentRole"
		avatar_buttons.append(button)

func _layout() -> void:
	_layout_pending = false
	if not is_instance_valid(dock):
		return
	var view := get_viewport_rect().size
	var narrow := view.x < 800
	var pad := 16.0 if narrow else 28.0
	var width := view.x - pad * 2.0
	_place(header, pad, 16, width, 74)
	var status := header.get_node("CommunityStatus") as Label
	var version := header.get_node("Version") as Label
	if narrow:
		status.text = "● 本地模拟"
		_place(status, width - 117, 15, 105, 26)
		_place(version, width - 122, 42, 110, 20)
	else:
		status.text = "●  3 位居民   /   本地模拟"
		_place(status, width - 375, 23, 240, 26)
		_place(version, width - 125, 26, 112, 22)
	_place(intro, pad + 2, 108, width, 68)
	(intro.get_node("Greeting") as Label).add_theme_font_size_override("font_size", 25 if narrow else 28)
	var content_top := 192.0
	var content_bottom := view.y - 158.0
	if narrow:
		var map_height := width * 540.0 / 960.0
		_place(map_panel, pad, content_top, width, map_height)
		_place(info_panel, pad, content_top + map_height + 12, width, content_bottom - content_top - map_height - 12)
	else:
		_place(map_panel, pad, content_top, width - 284, content_bottom - content_top)
		_place(info_panel, view.x - pad - 268, content_top, 268, content_bottom - content_top)
	_place(map_clip, 6, 6, map_panel.size.x - 12, map_panel.size.y - 12)
	var map_scale := minf(map_clip.size.x / 960.0, map_clip.size.y / 540.0)
	world.scale = Vector2.ONE * map_scale
	world.position = (map_clip.size - Vector2(960, 540) * map_scale) / 2.0
	_layout_info(narrow)
	_place(dock, pad, view.y - 140, width, 108)
	var dock_hint := dock.get_node("DockHint") as Label
	_place(dock_hint, width - 260, 11, 242, 22)
	for index in avatar_buttons.size():
		var button := avatar_buttons[index]
		var card_width := (width - 48.0) / 3.0
		_place(button, 14 + index * (card_width + 10), 39, card_width, 56)
		_place(button.get_node("Portrait"), 8, 7, 38, 42)
		_place(button.get_node("ResidentName"), 54, 6, card_width - 58, 27)
		_place(button.get_node("ResidentRole"), 54, 31, card_width - 58, 18)
		(button.get_node("ResidentName") as Label).add_theme_font_size_override("font_size", 16 if narrow else 18)
		if narrow:
			(button.get_node("ResidentRole") as Label).text = "主人" if index == 0 else "AI 占位"
		else:
			(button.get_node("ResidentRole") as Label).text = "主人 · 你" if index == 0 else "AI 模型 · 占位"
	_place(footer, pad, view.y - 27, width, 22)
	footer.add_theme_font_size_override("font_size", 12 if narrow else 14)

func _layout_info(narrow: bool) -> void:
	var width := info_panel.size.x
	var height := info_panel.size.y
	_place(info_panel.get_node("InfoOverline"), 18, 13, width - 36, 23)
	info_hint.visible = true
	if narrow:
		var compact := height < 240
		if compact:
			_place(info_panel.get_node("InfoOverline"), 18, 5, width - 36, 20)
			info_hint.visible = false
		_place(info_avatar, 18, 33 if compact else 46, 48, 46 if compact else 54)
		_place(selected_kind, 78, 29 if compact else 43, width - 100, 19)
		_place(selected_title, 77, 48 if compact else 62, width - 170, 33)
		_place(selected_status, width - 158, 55 if compact else 72, 140, 25)
		_place(selected_description, 18, 88 if compact else 109, width - 36, 42 if compact else 48)
		_place(talk_button, 18, 140 if compact else 163, 140, 36 if compact else 40)
		_place(info_hint, 180, 126 if compact else 160, width - 198, 20)
		_place(dialogue_label, 180, 135 if compact else 185, width - 198, maxf(49, height - (137 if compact else 195)))
	else:
		_place(info_avatar, 18, 49, 54, 62)
		_place(selected_kind, 85, 48, width - 100, 20)
		_place(selected_title, 84, 71, width - 100, 37)
		_place(selected_status, 18, 129, width - 36, 27)
		_place(selected_description, 18, 168, width - 36, 72)
		_place(talk_button, 18, 254, width - 36, 44)
		_place(info_hint, 18, 320, width - 36, 22)
		_place(dialogue_label, 18, 350, width - 36, maxf(66, height - 362))

func _show_info(info: Dictionary) -> void:
	current_info = info
	selected_title.text = str(info.get("name", "未命名"))
	selected_description.text = str(info.get("description", "占位场景物品。"))
	selected_status.text = "● " + str(info.get("status", "社区物品"))
	var entity_id := str(info.get("id", ""))
	var is_resident := entity_id in ["owner", "ai_1", "ai_2"]
	selected_kind.text = "社区主人" if entity_id == "owner" else ("AI 居民 · 本地占位" if is_resident else "场景物品 · 占位")
	info_avatar.visible = is_resident
	info_avatar.tint = info.get("color", PURPLE)
	info_avatar.is_owner = entity_id == "owner"
	info_avatar.queue_redraw()
	talk_button.disabled = not is_resident
	talk_button.text = "打个招呼  →" if is_resident else "点击空地可继续移动"
	for button in avatar_buttons:
		var selected := button.name == "Resident_" + entity_id
		button.add_theme_stylebox_override("normal", _box(Color("eee7f8") if selected else Color("faf8fc"), PURPLE if selected else EDGE, 10))

func _refresh_status() -> void:
	if is_instance_valid(world):
		var info: Dictionary = world.get_selected_info()
		if not info.is_empty():
			_show_info(info)

func _greet_selected() -> void:
	world.request_dialogue(str(current_info.get("id", "owner")))

func _on_dialogue(speaker: String, line: String) -> void:
	dialogue_label.text = speaker + "：" + line
