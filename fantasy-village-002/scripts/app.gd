extends Control
## 002 application shell: local identity -> login screen -> community screen.
## No backend, account server or real model is contacted.

const LoginScreen = preload("res://scripts/ui/login_screen.gd")
const CommunityScreen = preload("res://scripts/ui/community_screen.gd")
const AppState = preload("res://scripts/state/app_state.gd")
const INK := Color("22201d")
const MUTED := Color("6f6a63")
const PAPER := Color("fbfaf6")
const ACCENT := Color("6f5a8f")
const EDGE := Color("cfc9bd")

var state := AppState.new()
var ui_font: Font
var font_loaded := false
var login_screen: LoginScreen
var community_screen: CommunityScreen


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_theme()
	state.load_identity()
	_show_login()


func _setup_theme() -> void:
	# 直接读取打包的字体文件，不依赖编辑器导入缓存。
	# 本机 arm64 容器执行 --import 会崩溃；运行时加载在桌面、无头测试和 Web
	# 导出中行为一致，导出预设会把原始 otf 一并打包。
	var font_file := FontFile.new()
	var error := font_file.load_dynamic_font("res://assets/ui/placeholder_ui.otf")
	if error == OK and font_file.has_char("幻".unicode_at(0)):
		ui_font = font_file
		font_loaded = true
	else:
		ui_font = ThemeDB.fallback_font
		font_loaded = false
		push_error("002 UI font is missing or unreadable: res://assets/ui/placeholder_ui.otf")
	var app_theme := Theme.new()
	app_theme.default_font = ui_font
	app_theme.default_font_size = 15
	app_theme.set_color("font_color", "Label", INK)
	app_theme.set_color("font_color", "Button", INK)
	app_theme.set_color("font_hover_color", "Button", ACCENT)
	app_theme.set_color("font_pressed_color", "Button", ACCENT)
	app_theme.set_color("font_disabled_color", "Button", MUTED)
	app_theme.set_color("font_color", "LineEdit", INK)
	app_theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	app_theme.set_stylebox("normal", "Button", _box(PAPER, INK, 8, 2))
	app_theme.set_stylebox("hover", "Button", _box(Color("f1ecf7"), ACCENT, 8, 2))
	app_theme.set_stylebox("pressed", "Button", _box(Color("e6def1"), ACCENT, 8, 2))
	app_theme.set_stylebox("disabled", "Button", _box(Color("eceae5"), EDGE, 8, 1))
	app_theme.set_stylebox("focus", "Button", _box(Color.TRANSPARENT, ACCENT, 8, 2))
	app_theme.set_stylebox("normal", "LineEdit", _box(PAPER, INK, 8, 2))
	app_theme.set_stylebox("focus", "LineEdit", _box(PAPER, ACCENT, 8, 2))
	theme = app_theme


func _show_login() -> void:
	_clear_screens()
	login_screen = LoginScreen.new()
	login_screen.name = "LoginScreen"
	login_screen.setup(state)
	login_screen.submitted.connect(_on_login_submitted)
	add_child(login_screen)
	login_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _show_community() -> void:
	_clear_screens()
	community_screen = CommunityScreen.new()
	community_screen.name = "CommunityScreen"
	community_screen.setup(state)
	add_child(community_screen)
	community_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _on_login_submitted(display_name: String, create_new: bool) -> void:
	if not state.has_identity():
		if not state.create_identity(display_name):
			push_error("Cannot create local 002 identity")
			return
		if not state.save_identity():
			push_error("Cannot persist local 002 identity")
			return
	_show_community()


func _clear_screens() -> void:
	if login_screen != null and is_instance_valid(login_screen):
		login_screen.queue_free()
		login_screen = null
	if community_screen != null and is_instance_valid(community_screen):
		community_screen.queue_free()
		community_screen = null


func _box(fill: Color, border: Color, radius: int, border_width: int = 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box
