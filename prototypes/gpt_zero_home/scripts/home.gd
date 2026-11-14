extends Control
## 从零制作的三分之四视角家园展示，未使用旧项目的任何代码或素材。
## Pure environment prototype: character illustration is not a live AI connection.

const DAY_SCENE: Texture2D = preload("res://art/home_day.svg")
const DUSK_SCENE: Texture2D = preload("res://art/home_dusk.svg")

var is_dusk := false
var scenery: TextureRect
var change_button: Button
var status_label: Label

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    _build_scenery()
    _build_ui()
    _set_time(false)

func _build_scenery() -> void:
    scenery = TextureRect.new()
    scenery.name = "OriginalSceneArtwork"
    scenery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scenery.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    scenery.stretch_mode = TextureRect.STRETCH_SCALE
    scenery.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(scenery)

func _build_ui() -> void:
    var title_back := PanelContainer.new()
    title_back.position = Vector2(18, 16)
    title_back.custom_minimum_size = Vector2(334, 77)
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.14, 0.20, 0.19, 0.79)
    panel_style.set_corner_radius_all(11)
    panel_style.content_margin_left = 15
    panel_style.content_margin_top = 10
    panel_style.content_margin_right = 15
    panel_style.content_margin_bottom = 10
    title_back.add_theme_stylebox_override("panel", panel_style)
    add_child(title_back)

    var title_box := VBoxContainer.new()
    title_back.add_child(title_box)

    var title := Label.new()
    title.text = "幻想乡 · 初代家园"
    title.add_theme_font_size_override("font_size", 23)
    title.add_theme_color_override("font_color", Color("#fff5db"))
    title_box.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "独立原创样板 · 45°斜视生活场景"
    subtitle.add_theme_font_size_override("font_size", 13)
    subtitle.add_theme_color_override("font_color", Color("#e4e6ca"))
    title_box.add_child(subtitle)

    change_button = Button.new()
    change_button.name = "TimeToggle"
    change_button.text = "切换至黄昏  [T]"
    change_button.position = Vector2(737, 26)
    change_button.custom_minimum_size = Vector2(202, 44)
    change_button.pressed.connect(_on_toggle_time)
    add_child(change_button)

    var footer_bg := PanelContainer.new()
    footer_bg.position = Vector2(16, 558)
    footer_bg.custom_minimum_size = Vector2(475, 30)
    var footer_style := StyleBoxFlat.new()
    footer_style.bg_color = Color(0.10, 0.15, 0.14, 0.78)
    footer_style.set_corner_radius_all(7)
    footer_style.content_margin_left = 11
    footer_style.content_margin_right = 11
    footer_style.content_margin_top = 5
    footer_style.content_margin_bottom = 5
    footer_bg.add_theme_stylebox_override("panel", footer_style)
    add_child(footer_bg)
    status_label = Label.new()
    status_label.add_theme_font_size_override("font_size", 12)
    status_label.add_theme_color_override("font_color", Color("#f4e8ca"))
    footer_bg.add_child(status_label)

func _on_toggle_time() -> void:
    _set_time(not is_dusk)

func _set_time(dusk: bool) -> void:
    is_dusk = dusk
    scenery.texture = DUSK_SCENE if dusk else DAY_SCENE
    change_button.text = "切换至上午  [T]" if dusk else "切换至黄昏  [T]"
    status_label.text = "黄昏 · 小冰喜欢的暖光" if dusk else "上午 · 深寻喜欢的清明"
    print("FIRST_HOME_READY time=", "dusk" if dusk else "morning")

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_T or event.keycode == KEY_SPACE:
            _on_toggle_time()
            get_viewport().set_input_as_handled()
