extends Control
## Read-only Godot WEB viewer for a server-authoritative Python world.
## NO resident/admin token, NO action submission, NO editable world authority.
## The public snapshot feed is opt-in and MUST contain only ACL-filtered data.

const DAY_SCENE: Texture2D = preload("res://art/home_day.svg")
const DUSK_SCENE: Texture2D = preload("res://art/home_dusk.svg")
const WalkGraph = preload("res://scripts/world_graph.gd")
const ObserverSprite = preload("res://scripts/observer_sprite.gd")

const ART_SIZE := Vector2(960.0, 600.0)
const PUBLIC_WORLD_ID := "fantasia.first_home.prototype"
const VALID_ACTIONS := ["stay", "move", "sit", "read", "rest", "decline"]
const ALLOWED_PACKET_KEYS := ["schema_version", "world_id", "residents", "revision"]
const ALLOWED_RESIDENT_KEYS := ["resident_id", "name", "zone", "activity", "pos", "action", "path_progress"]
const ALLOWED_PATH_KEYS := ["remaining", "progress"]
const MAX_PUBLIC_WAYPOINTS := 24
const MAX_RESPONSE_BYTES := 65536
const MAX_PUBLIC_RESIDENTS := 32
const PALETTE := [
    [Color("#74859a"), Color("#53607b")],
    [Color("#d6c1d2"), Color("#aecbd1")],
    [Color("#a6bd91"), Color("#587b59")]
]

# Blank means no network connection. Must point ONLY to a separately authorized
# public-state feed: /observation (X-Resident-Token) is FORBIDDEN here.
@export var public_feed_url: String = ""
@export_range(1.0, 30.0, 0.5) var poll_seconds: float = 2.0

var graph
var art: TextureRect
var actor_layer: Node2D
var actors: Dictionary = {}
var status: Label
var title_label: Label
var hint: Label
var buttons: HBoxContainer
var day_button: Button
var dusk_button: Button
var transport: HTTPRequest
var fetch_clock: Timer
var is_dusk := false
var is_portrait := false
var pan_x := 0.0
var last_revision: int = -1
var have_public_snapshot := false
var fetching := false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    clip_contents = true
    graph = WalkGraph.new()
    _build_visuals()
    _set_time(false)
    resized.connect(_refresh_layout)
    get_viewport().size_changed.connect(_refresh_layout)
    _refresh_layout()
    # No requests unless a PUBLIC HTTPS feed is explicitly configured.
    if not public_feed_url.is_empty():
        start_public_feed(public_feed_url)

func _build_visuals() -> void:
    art = TextureRect.new()
    art.name = "PublicSceneArtwork"
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_SCALE
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(art)

    actor_layer = Node2D.new()
    actor_layer.name = "PublicResidentVisuals"
    add_child(actor_layer)

    var header := PanelContainer.new()
    header.name = "ViewerTitle"
    header.mouse_filter = Control.MOUSE_FILTER_IGNORE
    header.add_theme_stylebox_override("panel", _panel_style())
    add_child(header)
    title_label = Label.new()
    title_label.text = "幻想乡 · 初代家园｜观察"
    title_label.add_theme_font_size_override("font_size", 20)
    title_label.add_theme_color_override("font_color", Color("#fff5df"))
    header.add_child(title_label)

    status = Label.new()
    status.name = "PublicOnlyStatus"
    status.text = "尚未连接公开世界快照 · 不显示模拟 AI 行动"
    status.mouse_filter = Control.MOUSE_FILTER_IGNORE
    status.add_theme_font_size_override("font_size", 14)
    status.add_theme_color_override("font_color", Color("#fff8e9"))
    status.add_theme_color_override("font_shadow_color", Color("#1a3532"))
    status.add_theme_constant_override("shadow_offset_y", 2)
    add_child(status)

    hint = Label.new()
    hint.name = "PanHint"
    hint.text = "滑动查看家园 · 不能操纵居民"
    hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hint.add_theme_font_size_override("font_size", 13)
    hint.add_theme_color_override("font_color", Color("#fff8e9"))
    add_child(hint)

    buttons = HBoxContainer.new()
    buttons.name = "ViewerLightingOnly"
    buttons.add_theme_constant_override("separation", 8)
    add_child(buttons)
    day_button = _time_button("MorningPreview", "上午（预览）", false)
    dusk_button = _time_button("DuskPreview", "黄昏（预览）", true)
    buttons.add_child(day_button)
    buttons.add_child(dusk_button)

    transport = HTTPRequest.new()
    transport.name = "PublicSnapshotHTTPRequest"
    transport.timeout = 8.0
    transport.request_completed.connect(_on_public_response)
    add_child(transport)
    fetch_clock = Timer.new()
    fetch_clock.name = "PublicSnapshotClock"
    fetch_clock.one_shot = false
    fetch_clock.wait_time = poll_seconds
    fetch_clock.timeout.connect(_fetch_public_snapshot)
    add_child(fetch_clock)

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.12, 0.18, 0.17, 0.82)
    style.set_corner_radius_all(10)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    return style

func _time_button(button_name: String, label_text: String, dusk: bool) -> Button:
    var result := Button.new()
    result.name = button_name
    result.text = label_text
    result.toggle_mode = true
    result.focus_mode = Control.FOCUS_NONE
    result.pressed.connect(func(): _set_time(dusk))
    result.add_theme_font_size_override("font_size", 16)
    return result

func _set_time(dusk: bool) -> void:
    is_dusk = dusk
    art.texture = DUSK_SCENE if dusk else DAY_SCENE
    day_button.button_pressed = not dusk
    dusk_button.button_pressed = dusk

func _refresh_layout() -> void:
    _apply_layout(size)

func _apply_layout(view: Vector2) -> void:
    if art == null or view.x < 50.0 or view.y < 100.0:
        return
    is_portrait = view.y > view.x * 1.15
    var physical_height: float = float(get_window().size.y)
    if physical_height < 240.0:
        physical_height = view.y
    var logical_per_pixel: float = view.y / physical_height
    var margin: float = 14.0 * logical_per_pixel
    var button_width: float = minf((view.x - margin * 2.0 - 8.0) * 0.5, 155.0 * logical_per_pixel)
    var button_height: float = maxf(56.0, 52.0 * logical_per_pixel)
    for b in [day_button, dusk_button]:
        b.custom_minimum_size = Vector2(button_width, button_height)
        b.add_theme_font_size_override("font_size", int(round(15.0 * logical_per_pixel)))
    var total_width := button_width * 2.0 + 8.0
    buttons.size = Vector2(total_width, button_height)
    if is_portrait:
        buttons.position = Vector2((view.x - total_width) * 0.5, view.y - button_height - 22.0 * logical_per_pixel)
        var factor: float = maxf(160.0, view.y - 178.0 * logical_per_pixel) / ART_SIZE.y
        art.size = ART_SIZE * factor
        hint.visible = true
        hint.position = Vector2(margin, buttons.position.y - 84.0 * logical_per_pixel)
        status.position = Vector2(margin, 104.0 * logical_per_pixel)
    else:
        buttons.position = Vector2(view.x - total_width - margin, view.y - button_height - margin)
        var factor: float = minf(view.x / ART_SIZE.x, view.y / ART_SIZE.y)
        art.size = ART_SIZE * factor
        hint.visible = false
        status.position = Vector2(margin, view.y - 92.0 * logical_per_pixel)
        pan_x = 0.0
    var title_box: Control = get_node("ViewerTitle")
    title_box.position = Vector2(margin, 12.0 * logical_per_pixel)
    title_box.size = Vector2(minf(view.x - margin * 2.0, 360.0 * logical_per_pixel), 54.0 * logical_per_pixel)
    title_label.add_theme_font_size_override("font_size", int(round(20.0 * logical_per_pixel)))
    status.add_theme_font_size_override("font_size", int(round(13.0 * logical_per_pixel)))
    status.size = Vector2(view.x - margin * 2.0, 70.0 * logical_per_pixel)
    hint.size = Vector2(view.x - margin * 2.0, 32.0 * logical_per_pixel)
    _position_art(view)

func _position_art(view: Vector2) -> void:
    var overflow: float = maxf(0.0, (art.size.x - view.x) * 0.5)
    pan_x = clampf(pan_x, -overflow, overflow)
    art.position = Vector2((view.x - art.size.x) * 0.5 + pan_x, (view.y - art.size.y) * 0.5)
    actor_layer.position = art.position
    actor_layer.scale = art.size / ART_SIZE

func _gui_input(event: InputEvent) -> void:
    if not is_portrait:
        return
    if event is InputEventScreenDrag:
        pan_x += event.relative.x
        _position_art(size)
        accept_event()
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        pan_x += event.relative.x
        _position_art(size)
        accept_event()

func _safe_activity(raw: String) -> String:
    var aliases := {
        "idle": "stay", "moving": "move", "sitting": "sit",
        "reading": "read", "resting": "rest", "declined": "decline"
    }
    return str(aliases.get(raw, raw))

func apply_public_snapshot(packet: Dictionary) -> bool:
    # Fail closed and update as a whole, so malformed JSON cannot partially
    # change the on-screen world. Never print the raw packet.
    if packet.get("schema_version") != 1 or packet.get("world_id") != PUBLIC_WORLD_ID:
        return false
    for k in packet.keys():
        if not ALLOWED_PACKET_KEYS.has(str(k)):
            return false
    if not packet.has("residents") or typeof(packet["residents"]) != TYPE_ARRAY:
        return false
    var people: Array = packet["residents"]
    if people.size() > MAX_PUBLIC_RESIDENTS:
        return false
    var new_revision: int = last_revision
    if packet.has("revision"):
        # Godot JSON numbers may be parsed as floating point even when the
        # wire JSON spells an integer (e.g. "revision": 1).
        var raw_revision = packet["revision"]
        if typeof(raw_revision) != TYPE_INT and typeof(raw_revision) != TYPE_FLOAT:
            return false
        if float(raw_revision) < 0.0 or float(raw_revision) > 2147483647.0:
            return false
        if float(int(raw_revision)) != float(raw_revision):
            return false
        new_revision = int(raw_revision)
        if last_revision >= 0 and new_revision < last_revision:
            return false

    var parsed: Array[Dictionary] = []
    var seen_ids: Dictionary = {}
    var valid_places: Array[String] = graph.available_zones()
    for raw in people:
        if typeof(raw) != TYPE_DICTIONARY:
            return false
        for k in raw.keys():
            if not ALLOWED_RESIDENT_KEYS.has(str(k)):
                return false
        var id_raw = raw.get("resident_id", null)
        var name_raw = raw.get("name", null)
        var zone_raw = raw.get("zone", raw.get("pos", null))
        var action_raw = raw.get("activity", raw.get("action", null))
        if typeof(id_raw) != TYPE_STRING or typeof(name_raw) != TYPE_STRING or typeof(zone_raw) != TYPE_STRING or typeof(action_raw) != TYPE_STRING:
            return false
        var identity: String = id_raw
        var display_name: String = name_raw
        var scene_zone: String = zone_raw
        var state_name: String = _safe_activity(action_raw)
        if identity.is_empty() or identity.length() > 96 or display_name.is_empty() or display_name.length() > 32:
            return false
        if display_name.contains("\n") or display_name.contains("\r") or seen_ids.has(identity):
            return false
        if not valid_places.has(scene_zone) or not VALID_ACTIONS.has(state_name):
            return false

        var remaining: Array[String] = []
        var progress: float = 0.0
        if raw.has("path_progress"):
            if state_name != "move" or typeof(raw["path_progress"]) != TYPE_DICTIONARY:
                return false
            var route_data: Dictionary = raw["path_progress"]
            for key in route_data.keys():
                if not ALLOWED_PATH_KEYS.has(str(key)):
                    return false
            if not route_data.has("remaining") or typeof(route_data["remaining"]) != TYPE_ARRAY:
                return false
            var route_parts: Array = route_data["remaining"]
            if route_parts.size() > MAX_PUBLIC_WAYPOINTS:
                return false
            for part in route_parts:
                if typeof(part) != TYPE_STRING or not valid_places.has(part):
                    return false
                remaining.append(part)
            if not route_data.has("progress"):
                return false
            var raw_progress = route_data["progress"]
            if typeof(raw_progress) != TYPE_INT and typeof(raw_progress) != TYPE_FLOAT:
                return false
            progress = float(raw_progress)
            # Reject NaN and infinities through bounded comparisons.
            if not (progress >= 0.0 and progress <= 1.0):
                return false

        # Important: P1 v3's "progress" has not been defined as a specific
        # (from, to) edge fraction. Store and display route metadata, but DO
        # NOT use it to invent fractional positions or skip trusted waypoints.
        parsed.append({
            "resident_id": identity, "name": display_name, "zone": scene_zone,
            "activity": state_name, "remaining": remaining, "progress": progress
        })
        seen_ids[identity] = true

    for old_id in actors.keys():
        if not seen_ids.has(old_id):
            actors[old_id].queue_free()
            actors.erase(old_id)
    for person in parsed:
        var identity: String = person["resident_id"]
        if not actors.has(identity):
            var avatar = ObserverSprite.new()
            avatar.name = "PublicAvatar_" + str(actors.size())
            var palette_index: int = int(actors.size()) % PALETTE.size()
            avatar.configure(identity, person["name"], PALETTE[palette_index][0], PALETTE[palette_index][1])
            actor_layer.add_child(avatar)
            actors[identity] = avatar
        actors[identity].show_public_state(person["name"], graph.zone_position(person["zone"]), person["activity"], person["remaining"], person["progress"])
    have_public_snapshot = true
    last_revision = new_revision
    _update_status(parsed)
    return true

func _update_status(people: Array[Dictionary]) -> void:
    var output := PackedStringArray()
    for person in people:
        var activity_name: String = {
            "stay": "停留", "move": "行走", "sit": "坐着",
            "read": "阅读", "rest": "休息", "decline": "谢绝活动"
        }.get(person["activity"], person["activity"])
        var suffix := ""
        if person["activity"] == "move" and person["remaining"].size() > 0:
            suffix = " · 剩余路点 " + str(person["remaining"].size())
        output.append(str(person["name"]) + " · " + activity_name + suffix)
    if output.is_empty():
        status.text = "这里暂时没有公开活动"
    else:
        status.text = "\n".join(output) + "\n（公开状态｜只读）"

func start_public_feed(url: String) -> bool:
    # The resident-authenticated /observation endpoint MUST NOT be used here.
    # Only a separately created PUBLIC HTTPS snapshot endpoint is suitable.
    # Only the specifically designed token-free public endpoint is allowed.
    # Do not point a browser at 127.0.0.1:8200 (it would mean the PHONE).
    if not url.begins_with("https://") or url.contains("@") or url.contains("#") or url.contains("?"):
        return false
    if not url.ends_with("/public/world"):
        return false
    public_feed_url = url
    fetch_clock.wait_time = maxf(1.0, poll_seconds)
    fetch_clock.start()
    _fetch_public_snapshot()
    return true

func _fetch_public_snapshot() -> void:
    if fetching or public_feed_url.is_empty():
        return
    fetching = true
    # No cookies, resident tokens, admin keys, Authorization or custom headers.
    var error: Error = transport.request(public_feed_url, [], HTTPClient.METHOD_GET)
    if error != OK:
        fetching = false
        status.text = "公开世界快照暂不可用"

func _on_public_response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    fetching = false
    if result != HTTPRequest.RESULT_SUCCESS or code != 200 or body.size() > MAX_RESPONSE_BYTES:
        status.text = "公开世界快照暂不可用"
        return
    var decoded = JSON.parse_string(body.get_string_from_utf8())
    if typeof(decoded) != TYPE_DICTIONARY or not apply_public_snapshot(decoded):
        status.text = "公开世界数据格式不匹配"

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_1:
            _set_time(false)
        elif event.keycode == KEY_2:
            _set_time(true)
        elif event.keycode == KEY_T:
            _set_time(not is_dusk)
        else:
            return
        get_viewport().set_input_as_handled()
