extends Node2D
## Appearance-only sprite. It has no pathfinding, no movement intents,
## no network credentials, and NO API for controlling the world.
const VISUAL_SPEED := 5.0

var resident_id: String = ""
var public_name: String = ""
var activity: String = "stay"
var target_position: Vector2 = Vector2.ZERO
var main_color: Color = Color("#74859a")
var hair_color: Color = Color("#53607b")
var facing_right: bool = true
var initialized: bool = false
var walk_phase: float = 0.0

func configure(identity: String, display_name: String, tint: Color, hair: Color) -> void:
    resident_id = identity
    public_name = display_name
    main_color = tint
    hair_color = hair

func show_public_state(display_name: String, scene_position: Vector2, state_name: String) -> void:
    public_name = display_name
    activity = state_name
    target_position = scene_position
    if not initialized:
        position = scene_position
        initialized = true
    queue_redraw()

func _process(delta: float) -> void:
    if not initialized:
        return
    var difference: Vector2 = target_position - position
    if difference.length() > 0.4:
        facing_right = difference.x >= 0.0
        position = position.lerp(target_position, clampf(delta * VISUAL_SPEED, 0.0, 1.0))
        walk_phase += delta * 8.0
        queue_redraw()
    elif position != target_position:
        position = target_position
        queue_redraw()

func _draw() -> void:
    if not initialized:
        return
    var bob: float = sin(walk_phase) if position.distance_to(target_position) > 1.0 else 0.0
    draw_colored_polygon(
        PackedVector2Array([Vector2(-12, 1), Vector2(-8, -2), Vector2(8, -2), Vector2(12, 1), Vector2(8, 4), Vector2(-8, 4)]),
        Color(0.10, 0.18, 0.15, 0.50)
    )
    draw_rect(Rect2(-10, -22 + bob, 20, 17), main_color)
    draw_rect(Rect2(-8, -26 + bob, 16, 10), Color("#f1d8bd"))
    draw_rect(Rect2(-10, -33 + bob, 20, 9), hair_color)
    draw_rect(Rect2(-8, -9 + bob, 6, 9), Color("#564e4d"))
    draw_rect(Rect2(2, -9 + bob, 6, 9), Color("#564e4d"))
    var eye_x: float = 3.0 if facing_right else -5.0
    draw_rect(Rect2(eye_x, -23 + bob, 3, 3), Color("#413a3f"))
    if activity == "read":
        draw_rect(Rect2(2, -13, 12, 9), Color("#e7d09c"))
    elif activity == "sit" or activity == "rest":
        draw_rect(Rect2(-10, -7, 20, 5), main_color.darkened(0.1))
