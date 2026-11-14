extends Control
## Independent three-quarter-view home. Both touch and desktop input are first-class.
## The portrait layout becomes a draggable scenic panorama instead of squashing art.

const DAY_SCENE: Texture2D = preload("res://art/home_day.svg")
const DUSK_SCENE: Texture2D = preload("res://art/home_dusk.svg")
const ART_SIZE := Vector2(960.0, 600.0)
const MOBILE_LAYOUT_WIDTH := 540.0

var is_dusk := false
var scenery: TextureRect
var day_button: Button
var dusk_button: Button
var status_label: Label
var hint_label: Label
var title_panel: PanelContainer
var title_label: Label
var subtitle_label: Label
var controls: HBoxContainer
var pan_x := 0.0
var is_portrait := false
var scene_width := 960.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    clip_contents = true
    _build_scenery()
    _build_ui()
    _set_time(false)
    resized.connect(_refresh_layout)
    get_viewport().size_changed.connect(_refresh_layout)
    _refresh_layout()

func _build_scenery() -> void:
    scenery = TextureRect.new()
    scenery.name = "OriginalSceneArtwork"
    scenery.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    scenery.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    scenery.stretch_mode = TextureRect.STRETCH_SCALE
    scenery.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(scenery)

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.13, 0.19, 0.18, 0.86)
    style.set_corner_radius_all(12)
    style.content_margin_left = 14
    style.content_margin_top = 9
    style.content_margin_right = 14
    style.content_margin_bottom = 9
    return style

func _make_time_button(node_name: String, label_text: String, dusk: bool) -> Button:
    var result := Button.new()
    result.name = node_name
    result.text = label_text
    result.focus_mode = Control.FOCUS_NONE
    result.mouse_filter = Control.MOUSE_FILTER_STOP
    result.pressed.connect(func(): _set_time(dusk))
    result.add_theme_font_size_override("font_size", 18)
    return result

func _build_ui() -> void:
    title_panel = PanelContainer.new()
    title_panel.name = "TitlePanel"
    title_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    title_panel.add_theme_stylebox_override("panel", _panel_style())
    add_child(title_panel)

    var header := VBoxContainer.new()
    title_panel.add_child(header)
    title_label = Label.new()
    title_label.text = "幻想乡 · 初代家园"
    title_label.add_theme_font_size_override("font_size", 23)
    title_label.add_theme_color_override("font_color", Color("#fff5db"))
    header.add_child(title_label)

    subtitle_label = Label.new()
    subtitle_label.text = "独立原创样板 · 斜视生活场景"
    subtitle_label.add_theme_font_size_override("font_size", 13)
    subtitle_label.add_theme_color_override("font_color", Color("#e4e6ca"))
    header.add_child(subtitle_label)

    controls = HBoxContainer.new()
    controls.name = "TouchControls"
    controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    controls.add_theme_constant_override("separation", 8)
    add_child(controls)

    day_button = _make_time_button("MorningButton", "上午", false)
    dusk_button = _make_time_button("DuskButton", "黄昏", true)
    controls.add_child(day_button)
    controls.add_child(dusk_button)

    status_label = Label.new()
    status_label.name = "Status"
    status_label.add_theme_font_size_override("font_size", 14)
    status_label.add_theme_color_override("font_color", Color("#fff5db"))
    status_label.add_theme_color_override("font_shadow_color", Color("#132526"))
    status_label.add_theme_constant_override("shadow_offset_x", 1)
    status_label.add_theme_constant_override("shadow_offset_y", 2)
    add_child(status_label)

    hint_label = Label.new()
    hint_label.name = "TouchHint"
    hint_label.text = "左右滑动探索河岸与木屋"
    hint_label.add_theme_font_size_override("font_size", 14)
    hint_label.add_theme_color_override("font_color", Color("#f5ebcf"))
    hint_label.add_theme_color_override("font_shadow_color", Color("#132526"))
    hint_label.add_theme_constant_override("shadow_offset_y", 2)
    add_child(hint_label)

func _refresh_layout() -> void:
    _apply_layout(size)

func _apply_layout(view: Vector2) -> void:
    if scenery == null or view.x <= 1.0 or view.y <= 1.0:
        return
    var margin := 12.0
    is_portrait = view.x < MOBILE_LAYOUT_WIDTH or view.y > view.x * 1.15
    var narrow := view.x < 700.0

    # On narrow screens the controls remain large, reachable and visible.
    var btn_width := clampf((view.x - margin * 2.0 - 8.0) / 2.0, 110.0, 170.0)
    var btn_height := 58.0 if is_portrait else 50.0
    day_button.custom_minimum_size = Vector2(btn_width, btn_height)
    dusk_button.custom_minimum_size = Vector2(btn_width, btn_height)
    var buttons_width := btn_width * 2.0 + 8.0
    controls.size = Vector2(buttons_width, btn_height)

    if is_portrait:
        controls.position = Vector2((view.x - buttons_width) * 0.5, view.y - btn_height - 18.0)
        title_panel.position = Vector2(margin, 12.0)
        title_panel.size = Vector2(view.x - margin * 2.0, 74.0)
        title_label.add_theme_font_size_override("font_size", 20)
        subtitle_label.add_theme_font_size_override("font_size", 12)
        status_label.position = Vector2(margin + 5.0, view.y - btn_height - 72.0)
        hint_label.visible = true
        hint_label.position = Vector2(margin + 5.0, view.y - btn_height - 104.0)

        # Show a readable section of the art, with horizontal swipe to explore.
        # The artwork retains its aspect ratio, and no buildings are distorted.
        var available_height := maxf(160.0, view.y - 205.0)
        var scale_factor := available_height / ART_SIZE.y
        var render_size := ART_SIZE * scale_factor
        scene_width = render_size.x
        scenery.size = render_size
        _position_scenery(view)
    else:
        controls.position = Vector2(view.x - buttons_width - margin, view.y - btn_height - margin)
        title_panel.position = Vector2(16, 14)
        title_panel.size = Vector2(minf(340, view.x - 32.0), 74)
        title_label.add_theme_font_size_override("font_size", 23)
        subtitle_label.add_theme_font_size_override("font_size", 13)
        status_label.position = Vector2(18, view.y - 32)
        hint_label.visible = false
        # Landscape and desktop keep the entire scene visible.
        var scale_factor := minf(view.x / ART_SIZE.x, view.y / ART_SIZE.y)
        var render_size := ART_SIZE * scale_factor
        scene_width = render_size.x
        scenery.size = render_size
        pan_x = 0.0
        _position_scenery(view)

    # UI layout is checked against the viewport size in tests on both shapes.
    if narrow:
        title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _position_scenery(view: Vector2) -> void:
    var half_overflow := maxf(0.0, (scene_width - view.x) * 0.5)
    pan_x = clampf(pan_x, -half_overflow, half_overflow)
    scenery.position = Vector2(
        (view.x - scenery.size.x) * 0.5 + pan_x,
        (view.y - scenery.size.y) * 0.5
    )

func _gui_input(event: InputEvent) -> void:
    if not is_portrait:
        return
    if event is InputEventScreenDrag:
        pan_x += event.relative.x
        _position_scenery(size)
        accept_event()
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        pan_x += event.relative.x
        _position_scenery(size)
        accept_event()

func _set_time(dusk: bool) -> void:
    is_dusk = dusk
    scenery.texture = DUSK_SCENE if dusk else DAY_SCENE
    day_button.disabled = not dusk
    dusk_button.disabled = dusk
    status_label.text = "黄昏 · 小冰喜欢的暖光" if dusk else "上午 · 深寻喜欢的清明"
    print("FIRST_HOME_READY time=", "dusk" if dusk else "morning")

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_1:
            _set_time(false)
        elif event.keycode == KEY_2:
            _set_time(true)
        elif event.keycode == KEY_T or event.keycode == KEY_SPACE:
            _set_time(not is_dusk)
        else:
            return
        get_viewport().set_input_as_handled()
