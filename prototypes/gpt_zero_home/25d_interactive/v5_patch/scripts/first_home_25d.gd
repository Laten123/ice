extends Control
## 《幻想乡》初代家园：可交互的 2.5D 视觉土地。
## Stable server P1/V2 place IDs. Human taps inspect, never control real AI.
## "离线测试" is an explicit, local-only mock resident, not an actual AI.

const Points = preload("res://scripts/home_25d_points.gd")
const Markers = preload("res://scripts/home_25d_markers.gd")
const Resident = preload("res://scripts/home_25d_resident.gd")
const Atmosphere = preload("res://scripts/home_25d_atmosphere.gd")
const ENVIRONMENT_SHADER = preload("res://shaders/home_25d_wind.gdshader")
const OUTDOOR_ART: Texture2D = preload("res://art/home_25d_exterior.png")
const INDOOR_ART: Texture2D = preload("res://art/home_25d_interior.png")
const CJK_FONT_PATH := "res://art/fonts/NotoSansSC-VF.ttf"
const MAX_PUBLIC_RESIDENTS := 24
const MAX_SNAPSHOT_BYTES := 65536
const VALID_STATES := ["stay", "move", "sit", "rest", "read", "decline"]
const ALLOWED_SNAPSHOT_FIELDS := ["schema_version", "world_id", "revision", "residents"]
const ALLOWED_PERSON_FIELDS := ["resident_id", "name", "scene_id", "zone", "activity", "action", "path_progress", "pos"]
const ALLOWED_PATH_FIELDS := ["from", "to", "remaining", "progress"]

@export var use_same_origin_public_feed := false
@export_range(1.0, 20.0, 0.5) var poll_interval := 2.0

var current_scene := "exterior"
var selected_point := ""
var is_dusk := false
var show_hotspots := false
var offline_test_mode := false
var test_scene := "exterior"
var test_zone := "stone_table"
var test_busy := false
var last_revision := -1
var public_actor_states: Dictionary = {}
var public_actors: Dictionary = {}
var public_feed_url := ""
var fetching := false
var zoom := 1.0
var pan := Vector2.ZERO
var touch_dragged := false
var map_factor := 1.0
var map_origin := Vector2.ZERO

var map_frame: Control
var map_art: TextureRect
var marker_layer
var ambient_layer: Node2D
var atmosphere_material: ShaderMaterial
var public_layer: Node2D
var test_layer: Node2D
var test_actor
var title_label: Label
var network_label: Label
var prompt_label: Label
var details_label: Label
var mode_button: Button
var room_button: Button
var light_button: Button
var hotspots_button: Button
var activity_choice: OptionButton
var activity_button: Button
var info_background: ColorRect
var request: HTTPRequest
var timer: Timer

func _ready() -> void:
    clip_contents = true
    mouse_filter = Control.MOUSE_FILTER_STOP
    _make_visuals()
    _make_controls()
    _apply_optional_font()
    resized.connect(_layout)
    get_viewport().size_changed.connect(_layout)
    _set_scene(Points.EXTERIOR)
    _select_point("stone_table")
    _layout()
    if use_same_origin_public_feed and OS.has_feature("web"):
        var origin = JavaScriptBridge.eval("window.location.origin")
        if typeof(origin) == TYPE_STRING:
            start_public_feed(str(origin) + "/public/world")

func _process(_delta: float) -> void:
    if atmosphere_material == null or ambient_layer == null:
        return
    atmosphere_material.set_shader_parameter("wind_time", ambient_layer.clock)
    atmosphere_material.set_shader_parameter("twilight", ambient_layer.twilight)
    atmosphere_material.set_shader_parameter("wind_on", 1.0 if ambient_layer.motion_enabled else 0.0)

func _make_visuals() -> void:
    var backdrop := ColorRect.new()
    backdrop.name = "Backdrop"
    backdrop.color = Color("#283e38")
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(backdrop)

    map_frame = Control.new()
    map_frame.name = "IslandViewport"
    map_frame.clip_contents = true
    map_frame.mouse_filter = Control.MOUSE_FILTER_STOP
    map_frame.gui_input.connect(_on_map_input)
    add_child(map_frame)

    map_art = TextureRect.new()
    map_art.name = "Approved25DArtwork"
    map_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    map_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    map_art.stretch_mode = TextureRect.STRETCH_SCALE
    map_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    map_frame.add_child(map_art)
    atmosphere_material = ShaderMaterial.new()
    atmosphere_material.shader = ENVIRONMENT_SHADER
    map_art.material = atmosphere_material

    ambient_layer = Atmosphere.new()
    ambient_layer.name = "DecorativeAmbientOnly"
    map_frame.add_child(ambient_layer)

    public_layer = Node2D.new()
    public_layer.name = "ConfirmedPublicResidents"
    map_frame.add_child(public_layer)

    test_layer = Node2D.new()
    test_layer.name = "OfflineTestResidentLayer"
    map_frame.add_child(test_layer)
    test_actor = Resident.new()
    test_actor.name = "EXPLICIT_OFFLINE_TEST_RESIDENT"
    test_actor.configure(true)
    test_actor.visible = false
    test_layer.add_child(test_actor)

    marker_layer = Markers.new()
    marker_layer.name = "InteractionAnchors"
    map_frame.add_child(marker_layer)

func _make_controls() -> void:
    title_label = _label("幻想乡 · 初代家园", 23, Color("#fff0cf"))
    title_label.name = "HomeTitle"
    add_child(title_label)

    network_label = _label("本地预览 · 尚未接入公开居民", 14, Color("#bfddc5"))
    network_label.name = "PublicStateStatus"
    add_child(network_label)

    room_button = _button("看室内")
    room_button.name = "ObserveOtherRoom"
    room_button.pressed.connect(_toggle_scene)
    add_child(room_button)

    light_button = _button("黄昏")
    light_button.name = "PreviewDusk"
    light_button.pressed.connect(_toggle_dusk)
    add_child(light_button)

    hotspots_button = _button("显示点位")
    hotspots_button.name = "HotspotHints"
    hotspots_button.pressed.connect(_toggle_hotspots)
    add_child(hotspots_button)

    mode_button = _button("测试：关")
    mode_button.name = "OfflineTestMode"
    mode_button.pressed.connect(_toggle_offline_test)
    add_child(mode_button)

    info_background = ColorRect.new()
    info_background.name = "InteractionDetailsBackground"
    info_background.color = Color(0.16, 0.23, 0.20, 0.96)
    info_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(info_background)

    prompt_label = _label("轻触地图查看地点", 20, Color("#ffdcaa"))
    prompt_label.name = "SelectedPoint"
    add_child(prompt_label)

    details_label = _label("房屋可观察；居民是否活动由服务端决定。", 15, Color("#f3e6cf"))
    details_label.name = "SelectedPointInfo"
    details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    add_child(details_label)

    activity_choice = OptionButton.new()
    activity_choice.name = "TestActionChoice"
    activity_choice.visible = false
    add_child(activity_choice)
    activity_button = _button("执行测试")
    activity_button.name = "TestActionOnly"
    activity_button.pressed.connect(_perform_test_activity)
    activity_button.visible = false
    add_child(activity_button)

    request = HTTPRequest.new()
    request.name = "TokenFreePublicSnapshot"
    request.accept_gzip = false
    request.timeout = 8.0
    request.request_completed.connect(_on_public_response)
    add_child(request)
    timer = Timer.new()
    timer.name = "PublicPollingClock"
    timer.wait_time = maxf(1.0, poll_interval)
    timer.timeout.connect(_get_public_snapshot)
    add_child(timer)

func _label(caption: String, font_size: int, fg: Color) -> Label:
    var result := Label.new()
    result.text = caption
    result.mouse_filter = Control.MOUSE_FILTER_IGNORE
    result.add_theme_font_size_override("font_size", font_size)
    result.add_theme_color_override("font_color", fg)
    return result

func _button(caption: String) -> Button:
    var result := Button.new()
    result.text = caption
    result.focus_mode = Control.FOCUS_NONE
    result.add_theme_font_size_override("font_size", 16)
    result.add_theme_color_override("font_color", Color("#fff1d7"))
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#76543e")
    style.border_color = Color("#b68d59")
    style.set_border_width_all(2)
    style.set_corner_radius_all(5)
    style.content_margin_left = 9
    style.content_margin_right = 9
    style.content_margin_top = 6
    style.content_margin_bottom = 6
    result.add_theme_stylebox_override("normal", style)
    result.add_theme_stylebox_override("hover", style)
    return result

func _apply_optional_font() -> void:
    if not ResourceLoader.exists(CJK_FONT_PATH):
        return
    var font = ResourceLoader.load(CJK_FONT_PATH)
    if not font is Font:
        return
    for widget in [title_label, network_label, prompt_label, details_label, room_button, light_button, hotspots_button, mode_button, activity_choice, activity_button]:
        widget.add_theme_font_override("font", font)

func _layout() -> void:
    if map_frame == null or size.x < 240 or size.y < 240:
        return
    var margin := 12.0
    var is_tall := size.y > size.x * 1.13
    var toolbar_y := 105.0 if is_tall else 54.0
    var info_height := 132.0 if not is_tall else 176.0
    var map_h := maxf(190.0, size.y - toolbar_y - info_height - 16.0)
    map_frame.position = Vector2(0, toolbar_y)
    map_frame.size = Vector2(size.x, map_h)
    info_background.position = Vector2(0, toolbar_y + map_h)
    info_background.size = Vector2(size.x, size.y - info_background.position.y)
    title_label.position = Vector2(margin, 7)
    title_label.size = Vector2(size.x - margin * 2 if is_tall else size.x * 0.47, 30)
    network_label.position = Vector2(margin, 32)
    network_label.size = Vector2(size.x - margin * 2, 21)

    var bwidth := minf(114.0, maxf(68.0, size.x * 0.21))
    var controls_y := 62.0 if is_tall else 8.0
    if is_tall:
        bwidth = (size.x - margin * 2.0) / 3.0
    room_button.position = Vector2(size.x - bwidth * 3 - 8.0, controls_y)
    light_button.position = Vector2(size.x - bwidth * 2 - 5.0, controls_y)
    hotspots_button.position = Vector2(size.x - bwidth, controls_y)
    for btn in [room_button, light_button, hotspots_button]:
        btn.size = Vector2(bwidth - 5, 36)

    prompt_label.position = Vector2(margin, info_background.position.y + 10)
    prompt_label.size = Vector2(size.x - margin * 2, 28)
    details_label.position = Vector2(margin, info_background.position.y + 42)
    details_label.size = Vector2(size.x - margin * 2, 43 if not is_tall else 62)
    var bottom_y := size.y - 47.0
    mode_button.position = Vector2(margin, bottom_y)
    var mode_width := minf(145.0, size.x * 0.29)
    var picker_width := minf(120.0, size.x * 0.22)
    var action_width := minf(133.0, size.x * 0.30)
    mode_button.size = Vector2(mode_width, 38)
    activity_choice.position = Vector2(size.x - picker_width - action_width - margin - 7.0, bottom_y)
    activity_choice.size = Vector2(picker_width, 38)
    activity_button.position = Vector2(size.x - action_width - margin, bottom_y)
    activity_button.size = Vector2(action_width, 38)
    _position_art()

func _position_art() -> void:
    if map_frame == null or map_art == null:
        return
    if map_frame.size.x < 20.0 or map_frame.size.y < 20.0:
        return
    var image_size := Points.image_size(current_scene)
    var preferred_fit := minf(map_frame.size.x / image_size.x, map_frame.size.y / image_size.y)
    var portrait := size.y > size.x * 1.13
    if portrait:
        preferred_fit = maxf(preferred_fit, map_frame.size.y / image_size.y)
    map_factor = preferred_fit * zoom
    var drawn_size := image_size * map_factor
    var free_space := map_frame.size - drawn_size
    var min_pan := Vector2(minf(0.0, free_space.x * 0.5), minf(0.0, free_space.y * 0.5))
    var max_pan := -min_pan
    pan.x = clampf(pan.x, min_pan.x, max_pan.x)
    pan.y = clampf(pan.y, min_pan.y, max_pan.y)
    map_origin = free_space * 0.5 + pan
    map_art.position = map_origin
    map_art.size = drawn_size
    for layer in [ambient_layer, public_layer, test_layer, marker_layer]:
        layer.scale = Vector2(map_factor, map_factor)
        layer.position = map_origin
    # test_actor and public residents have image-space coordinates inside
    # their parent; test_actor itself must be nested in a scaled layer.
    _update_public_actor_visibility()
    marker_layer.update_markers(current_scene, selected_point, show_hotspots)

func _set_scene(next_scene: String) -> bool:
    if not Points.known_scene(next_scene):
        return false
    current_scene = next_scene
    selected_point = ""
    map_art.texture = INDOOR_ART if next_scene == Points.INTERIOR else OUTDOOR_ART
    # Color and inner-tree movement are now implemented in a local shader.
    map_art.modulate = Color.WHITE
    atmosphere_material.set_shader_parameter("is_interior", next_scene == Points.INTERIOR)
    ambient_layer.configure(next_scene, is_dusk)
    room_button.text = "看院子" if next_scene == Points.INTERIOR else "看室内"
    title_label.text = "幻想乡 · 木屋内部" if next_scene == Points.INTERIOR else "幻想乡 · 初代家园"
    test_actor.visible = offline_test_mode and current_scene == test_scene
    _position_art()
    _update_public_actor_visibility()
    _select_point("house_entry" if next_scene == Points.INTERIOR else "stone_table")
    return true

func _toggle_scene() -> void:
    # HUMAN changes only the observed camera; real residents stay where server says.
    _set_scene(Points.EXTERIOR if current_scene == Points.INTERIOR else Points.INTERIOR)

func _toggle_dusk() -> void:
    is_dusk = not is_dusk
    ambient_layer.set_dusk(is_dusk)
    light_button.text = "上午" if is_dusk else "黄昏"

func _toggle_hotspots() -> void:
    show_hotspots = not show_hotspots
    hotspots_button.text = "隐藏点位" if show_hotspots else "显示点位"
    marker_layer.update_markers(current_scene, selected_point, show_hotspots)

func _on_map_input(event: InputEvent) -> void:
    if event is InputEventScreenDrag:
        pan += event.relative
        touch_dragged = true
        _position_art()
        map_frame.accept_event()
    elif event is InputEventScreenTouch and event.pressed:
        touch_dragged = false
    elif event is InputEventScreenTouch and not event.pressed:
        if not touch_dragged:
            _tap_at(event.position)
        touch_dragged = false
        map_frame.accept_event()
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        pan += event.relative
        touch_dragged = true
        _position_art()
        map_frame.accept_event()
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            zoom = minf(2.2, zoom * 1.12)
            _position_art()
            map_frame.accept_event()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            zoom = maxf(0.8, zoom / 1.12)
            _position_art()
            map_frame.accept_event()
        elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            touch_dragged = false
        elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
            if not touch_dragged:
                _tap_at(event.position)
            touch_dragged = false
            map_frame.accept_event()

func _tap_at(local_screen: Vector2) -> void:
    var image_point := (local_screen - map_origin) / map_factor
    var threshold := maxf(40.0, 24.0 / map_factor)
    var best := threshold
    var matched := ""
    for key in Points.point_map(current_scene).keys():
        var item_pos: Vector2 = Points.point_position(current_scene, str(key))
        var dist := item_pos.distance_to(image_point)
        if dist < best:
            best = dist
            matched = str(key)
    if not matched.is_empty():
        _select_point(matched)

func _select_point(point_id: String) -> void:
    if not Points.known_place(current_scene, point_id):
        return
    selected_point = point_id
    var data: Dictionary = Points.point_data(current_scene, point_id)
    prompt_label.text = "📍 " + str(data["label"])
    var allowed := PackedStringArray()
    for action in data["activities"]:
        allowed.append(str(action))
    details_label.text = str(data["info"]) + "  · 可用动作：" + " / ".join(allowed)
    marker_layer.update_markers(current_scene, selected_point, show_hotspots)
    activity_choice.clear()
    if data.has("transition"):
        activity_choice.add_item("进入" if data["transition"] == "enter_house" else "出去")
        activity_choice.set_item_metadata(0, data["transition"])
    else:
        for activity in data["activities"]:
            var item_index: int = activity_choice.item_count
            activity_choice.add_item({"sit": "坐下", "read": "阅读", "rest": "休息", "stay": "停留"}.get(activity, activity))
            activity_choice.set_item_metadata(item_index, activity)

func _toggle_offline_test() -> void:
    offline_test_mode = not offline_test_mode
    mode_button.text = "测试：开" if offline_test_mode else "测试：关"
    activity_choice.visible = offline_test_mode
    activity_button.visible = offline_test_mode
    if offline_test_mode:
        # This is an isolated deterministic test avatar, never a real model.
        test_scene = current_scene
        test_zone = "stone_table" if current_scene == Points.EXTERIOR else "house_entry"
        test_actor.position = Points.point_position(test_scene, test_zone)
        test_actor.set_activity("stay")
        details_label.text = "测试居民（非 AI）：请点地图上的活动点，再执行离线动作。"
    test_actor.visible = offline_test_mode and current_scene == test_scene

func _perform_test_activity() -> void:
    if not offline_test_mode or test_busy or selected_point.is_empty() or activity_choice.item_count == 0:
        return
    if current_scene != test_scene:
        details_label.text = "离线测试居民在另一场景。请切换观察视角后继续。"
        return
    var requested: String = str(activity_choice.get_item_metadata(activity_choice.selected))
    if requested == "enter_house" or requested == "exit_house":
        await _run_test_transition(requested)
        return
    if not Points.valid_activity(current_scene, selected_point, requested):
        details_label.text = "该点不允许此活动。"
        return
    await _walk_test_resident(selected_point)
    test_actor.set_activity(requested)
    details_label.text = "【离线模拟，非真实 AI】测试居民在「" + str(Points.point_data(current_scene, selected_point)["label"]) + "」执行 " + requested + "。"

func _walk_test_resident(point_id: String) -> void:
    if current_scene != test_scene:
        return
    var route: Array[String] = Points.test_route(test_scene, test_zone, point_id)
    if route.is_empty():
        return
    test_busy = true
    test_actor.set_activity("move")
    # Only the isolated TEST RESIDENT animates. Public AI never interpolates.
    for i in range(1, route.size()):
        var stops: Array[Vector2] = Points.test_corridor(test_scene, route[i - 1], route[i])
        stops.append(Points.point_position(test_scene, route[i]))
        for next_location in stops:
            var distance := test_actor.position.distance_to(next_location)
            var tween := create_tween()
            tween.tween_property(test_actor, "position", next_location, clampf(distance / 230.0, 0.25, 1.7))
            await tween.finished
        test_zone = route[i]
    test_busy = false

func _run_test_transition(intent: String) -> void:
    if intent == "enter_house" and test_scene == Points.EXTERIOR and selected_point == "door":
        await _walk_test_resident("door")
        test_scene = Points.INTERIOR
        test_zone = "house_entry"
        _set_scene(test_scene)
        test_actor.position = Points.point_position(test_scene, test_zone)
        test_actor.visible = true
        details_label.text = "【离线模拟】测试居民进入木屋。真实 AI 的进门仍由 V2 服务端确认。"
    elif intent == "exit_house" and test_scene == Points.INTERIOR and selected_point == "house_entry":
        await _walk_test_resident("house_entry")
        test_scene = Points.EXTERIOR
        test_zone = "door"
        _set_scene(test_scene)
        test_actor.position = Points.point_position(test_scene, test_zone)
        test_actor.visible = true
        details_label.text = "【离线模拟】测试居民返回院子。"

func _update_public_actor_visibility() -> void:
    for identity in public_actors.keys():
        public_actors[identity].visible = public_actor_states.has(identity) and public_actor_states[identity]["scene_id"] == current_scene

func apply_public_snapshot(packet: Dictionary) -> bool:
    # Treat public feed as UNTRUSTED. Reject unknown fields and private content.
    for key in packet.keys():
        if not ALLOWED_SNAPSHOT_FIELDS.has(str(key)):
            return false
    if int(packet.get("schema_version", -1)) != 1 or str(packet.get("world_id", "")) != Points.WORLD_ID:
        return false
    if typeof(packet.get("revision", null)) != TYPE_INT:
        return false
    var next_revision: int = packet["revision"]
    if next_revision < 0 or next_revision <= last_revision:
        return false
    if typeof(packet.get("residents", null)) != TYPE_ARRAY:
        return false
    if packet["residents"].size() > MAX_PUBLIC_RESIDENTS:
        return false
    var parsed: Dictionary = {}
    for raw in packet["residents"]:
        if typeof(raw) != TYPE_DICTIONARY:
            return false
        for k in raw.keys():
            if not ALLOWED_PERSON_FIELDS.has(str(k)):
                return false
        var identity: String = str(raw.get("resident_id", ""))
        var display_name: String = str(raw.get("name", ""))
        var zone: String = str(raw.get("zone", ""))
        var scene_id: String = str(raw.get("scene_id", Points.EXTERIOR))
        var state: String = str(raw.get("activity", raw.get("action", "stay")))
        state = {"idle": "stay", "moving": "move", "sitting": "sit", "reading": "read", "resting": "rest", "declined": "decline"}.get(state, state)
        if identity.is_empty() or identity.length() > 96 or display_name.is_empty() or display_name.length() > 32:
            return false
        if display_name.contains("\n") or display_name.contains("\r") or parsed.has(identity):
            return false
        if not Points.known_place(scene_id, zone) or not VALID_STATES.has(state):
            return false
        if raw.has("path_progress"):
            if state != "move" or typeof(raw["path_progress"]) != TYPE_DICTIONARY:
                return false
            var route: Dictionary = raw["path_progress"]
            for k in route.keys():
                if not ALLOWED_PATH_FIELDS.has(str(k)):
                    return false
            if str(route.get("from", "")) != zone:
                return false
            if typeof(route.get("remaining", null)) != TYPE_ARRAY or route["remaining"].is_empty() or route["remaining"].size() > 24:
                return false
            if str(route.get("to", "")) != str(route["remaining"][0]):
                return false
            for part in route["remaining"]:
                if typeof(part) != TYPE_STRING or not Points.known_place(scene_id, str(part)):
                    return false
            var progress = route.get("progress", null)
            if typeof(progress) != TYPE_INT and typeof(progress) != TYPE_FLOAT:
                return false
            if not (float(progress) >= 0.0 and float(progress) <= 1.0):
                return false
        parsed[identity] = {"name": display_name, "scene_id": scene_id, "zone": zone, "activity": state}
    # Commit all-or-nothing after validation.
    for identity in public_actors.keys():
        if not parsed.has(identity):
            public_actors[identity].queue_free()
            public_actors.erase(identity)
    public_actor_states = parsed
    for identity in parsed.keys():
        if not public_actors.has(identity):
            var avatar: Variant = Resident.new()
            var color: Color = Color("#8eaad2") if public_actors.size() % 2 == 0 else Color("#d9a6bf")
            avatar.configure(false, color, Color("#3d4c64"))
            public_layer.add_child(avatar)
            public_actors[identity] = avatar
        var state: Dictionary = parsed[identity]
        public_actors[identity].position = Points.point_position(state["scene_id"], state["zone"])
        public_actors[identity].set_activity(state["activity"])
    last_revision = next_revision
    _update_public_actor_visibility()
    network_label.text = "PUBLIC · " + str(parsed.size()) + " 位获准公开的居民 · 版本 " + str(next_revision)
    return true

func start_public_feed(url: String) -> bool:
    # Never use authenticated /observation. No tokens, cookies or mutation.
    if not url.begins_with("https://") or url.contains("@") or url.contains("?") or url.contains("#") or not url.ends_with("/public/world"):
        return false
    public_feed_url = url
    timer.wait_time = maxf(1.0, poll_interval)
    timer.start()
    _get_public_snapshot()
    return true

func _get_public_snapshot() -> void:
    if fetching or public_feed_url.is_empty():
        return
    fetching = true
    var error: Error = request.request(public_feed_url, PackedStringArray(["Accept-Encoding: identity"]), HTTPClient.METHOD_GET)
    if error != OK:
        fetching = false
        network_label.text = "公开世界连接暂不可用"

func _on_public_response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    fetching = false
    if result != HTTPRequest.RESULT_SUCCESS or code != 200 or body.size() > MAX_SNAPSHOT_BYTES:
        network_label.text = "公开世界暂不可用"
        return
    var data = JSON.parse_string(body.get_string_from_utf8())
    if typeof(data) != TYPE_DICTIONARY or not apply_public_snapshot(data):
        network_label.text = "公开世界数据格式不匹配"