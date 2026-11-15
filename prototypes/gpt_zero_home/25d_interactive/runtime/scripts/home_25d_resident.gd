extends Node2D
## Image-space foot anchor + replaceable pixel skin + local pose joints.
## Poses never change a resident's location, scene, intent or permissions.
signal door_animation_finished(kind: String)

const DEFAULT_SKIN = preload("res://art/characters/woodland_test_skin.tres")
const Face = preload("res://scripts/home_25d_face.gd")
const ACTIVITIES := ["stay", "move", "sit", "read", "rest", "decline"]
const DOOR_DURATION := 0.42
const STRIDE_DISTANCE := 42.0

var skin = DEFAULT_SKIN
var display_activity := "stay"
var test_actor := false
var facing := "front"
var clock := 0.0
var walk_phase := 0.0
var sit_blend := 0.0
var rest_blend := 0.0
var read_blend := 0.0
var transition_kind := ""
var transition_progress := 0.0
var joints: Dictionary = {}
var sprites: Dictionary = {}
var body: Node2D
var book: Node2D
var eyes: Node2D
var previous_position := Vector2.ZERO
var track_position := false

func configure(test: bool, _tint: Color = Color.WHITE, _hair: Color = Color.WHITE) -> void:
    test_actor = test
    queue_redraw()

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _build_joints()
    apply_skin(skin)
    reset_motion_tracking()
    _pose()

func _joint(key: String, parent: Node2D, point: Vector2) -> Node2D:
    var joint := Node2D.new()
    joint.name = key.to_pascal_case()
    joint.position = point
    parent.add_child(joint)
    joints[key] = joint
    return joint

func _part(key: String, parent: Node2D, point: Vector2) -> void:
    var sprite := Sprite2D.new()
    sprite.name = key.to_pascal_case() + "Pixels"
    sprite.centered = false
    sprite.position = point
    parent.add_child(sprite)
    sprites[key] = sprite

func _build_joints() -> void:
    body = _joint("pelvis", self, Vector2.ZERO)
    var left_hip := _joint("left_hip", body, Vector2(-4, -4))
    _part("left_thigh", left_hip, Vector2(-2, 0))
    var left_knee := _joint("left_knee", left_hip, Vector2(0, 2))
    _part("left_calf", left_knee, Vector2(-2, 0))
    var right_hip := _joint("right_hip", body, Vector2(4, -4))
    _part("right_thigh", right_hip, Vector2(-2, 0))
    var right_knee := _joint("right_knee", right_hip, Vector2(0, 2))
    _part("right_calf", right_knee, Vector2(-2, 0))
    _part("torso", body, Vector2(-5, -11))
    for side in ["left", "right"]:
        var shoulder := _joint(side + "_shoulder", body, Vector2(-7 if side == "left" else 8, -11))
        _part(side + "_upper_arm", shoulder, Vector2(-2, 0))
        var elbow := _joint(side + "_elbow", shoulder, Vector2(0, 2))
        _part(side + "_forearm", elbow, Vector2(-2, 0))
    var neck := _joint("neck", body, Vector2(0, -12))
    _part("head", neck, Vector2(-9, -18))
    eyes = Face.new()
    eyes.name = "ClosedEyes"
    neck.add_child(eyes)
    book = Node2D.new()
    book.name = "ReadingBook"
    book.position = Vector2(0, -8)
    body.add_child(book)
    book.draw.connect(_draw_book)

func apply_skin(next_skin) -> bool:
    if next_skin == null or not next_skin.has_method("valid") or not next_skin.valid():
        return false
    skin = next_skin
    if body != null:
        body.scale = Vector2.ONE * skin.pixel_scale
        eyes.skin_color = skin.skin_color
        eyes.eye_color = skin.eye_color
        for key in joints:
            joints[key].position = skin.joint_positions[key]
        for part in sprites:
            sprites[part].position = skin.part_offsets[part]
        _refresh_direction()
    return true

func face_direction(vector: Vector2) -> void:
    if vector.length_squared() < 0.001:
        return
    var next: String
    if absf(vector.x) > absf(vector.y):
        next = "right" if vector.x > 0.0 else "left"
    else:
        next = "front" if vector.y > 0.0 else "back"
    if next != facing:
        facing = next
        if body != null:
            _refresh_direction()

func _refresh_direction() -> void:
    for part in sprites:
        sprites[part].texture = skin.texture_for(part, facing)
    eyes.facing = facing
    eyes.queue_redraw()

func set_activity(value: String) -> bool:
    if not ACTIVITIES.has(value):
        return false
    if display_activity != value:
        display_activity = value
        clock = 0.0
    return true

func reset_motion_tracking() -> void:
    previous_position = position
    track_position = true
    walk_phase = 0.0

func start_door_animation(kind: String) -> bool:
    if kind not in ["enter_house", "exit_house"] or not transition_kind.is_empty():
        return false
    transition_kind = kind
    transition_progress = 0.0
    set_activity("move")
    _pose()
    return true

func finish_door_animation() -> void:
    transition_kind = ""
    transition_progress = 0.0
    set_activity("stay")
    reset_motion_tracking()
    _pose()

func _process(delta: float) -> void:
    var travelled: float = position.distance_to(previous_position) if track_position else 0.0
    if travelled > 0.01 and travelled < 100.0:
        face_direction(position - previous_position)
    previous_position = position
    track_position = true
    advance_animation(delta, travelled if travelled < 100.0 else 0.0)

func advance_animation(delta: float, travelled: float = 0.0) -> void:
    var dt := maxf(0.0, delta)
    clock += dt
    if display_activity == "move":
        walk_phase = fposmod(walk_phase + maxf(0.0, travelled) / STRIDE_DISTANCE, 1.0)
    sit_blend = move_toward(sit_blend, 1.0 if display_activity == "sit" else 0.0, dt / 0.28)
    rest_blend = move_toward(rest_blend, 1.0 if display_activity == "rest" else 0.0, dt / 0.5)
    read_blend = move_toward(read_blend, 1.0 if display_activity == "read" else 0.0, dt / 0.28)
    if not transition_kind.is_empty() and transition_progress < 1.0:
        transition_progress = minf(1.0, transition_progress + dt / DOOR_DURATION)
        if transition_progress >= 1.0:
            door_animation_finished.emit(transition_kind)
    if body != null:
        _pose()
    queue_redraw()

func _pose() -> void:
    # Eight discrete gait samples keep nearest-filtered pixel edges crisp.
    var stride := sin(floor(walk_phase * 8.0) / 8.0 * TAU) if display_activity == "move" else 0.0
    var breath := roundf(sin(clock * 1.5) * 0.55) if display_activity != "move" else -absf(roundf(stride))
    body.position = Vector2(roundf(rest_blend * 18.0), roundf(sit_blend * 5.0 - rest_blend * 4.0 + breath) * skin.pixel_scale)
    body.rotation = -PI * 0.47 * rest_blend
    joints["left_hip"].rotation = stride * 0.38 - sit_blend * 1.0
    joints["right_hip"].rotation = -stride * 0.38 + sit_blend * 1.0
    joints["left_knee"].rotation = maxf(0.0, -stride) * 0.30 + sit_blend * 1.0
    joints["right_knee"].rotation = -maxf(0.0, stride) * 0.30 - sit_blend * 1.0
    joints["left_shoulder"].rotation = -stride * 0.28 - read_blend * 0.65
    joints["right_shoulder"].rotation = stride * 0.28 + read_blend * 0.65
    joints["left_elbow"].rotation = -read_blend * 0.55
    joints["right_elbow"].rotation = read_blend * 0.55
    joints["neck"].rotation = sin(clock * 0.47) * 0.025 + read_blend * 0.07
    eyes.visible = skin.blink_enabled and (rest_blend > 0.6 or fposmod(clock, 4.6) > 4.43)
    book.visible = read_blend > 0.5
    book.queue_redraw()
    var fade := 1.0
    var portal_scale := 1.0
    if transition_kind == "enter_house":
        fade = 1.0 - transition_progress
        portal_scale = 1.0 - transition_progress * 0.12
    elif transition_kind == "exit_house":
        fade = transition_progress
        portal_scale = 0.88 + transition_progress * 0.12
    body.modulate.a = fade
    body.scale = Vector2.ONE * skin.pixel_scale * portal_scale

func _draw_book() -> void:
    book.draw_rect(Rect2(-7, -1, 14, 9), Color("#60452f"))
    book.draw_rect(Rect2(-6, 0, 5, 6), Color("#e9d3a1"))
    book.draw_rect(Rect2(0, 0, 6, 6), Color("#fff0bd"))
    for line in range(3):
        book.draw_rect(Rect2(-5, 1 + line * 2, 3, 1), Color("#b3956a"))
        book.draw_rect(Rect2(1, 1 + line * 2, 4, 1), Color("#b3956a"))
    if fposmod(clock, 6.0) > 5.5:
        var page := int(fposmod(clock, 6.0) * 12.0) % 6
        book.draw_rect(Rect2(5 - page, -1, 2, 7), Color("#fff4d4"))

func _draw() -> void:
    var width := lerpf(24.0, 52.0, rest_blend)
    draw_rect(Rect2(-width * 0.5, -2, width, 4), Color(0.10, 0.19, 0.13, 0.23))
    if test_actor:
        # Discrete gold badge identifies the local fixture without a nametag.
        draw_rect(Rect2(-3, 5, 6, 3), Color("#f3cb78"))
