extends Node2D
## Appearance-only sprite. It has no pathfinding, no movement intents,
## no network credentials, and NO API for controlling the world.
## Public server snapshots are the ONLY source of resident positions.
## Do not locally lerp between distant zones: doing so can visually cross walls.

var resident_id: String = ""
var public_name: String = ""
var activity: String = "stay"
var target_position: Vector2 = Vector2.ZERO
var main_color: Color = Color("#74859a")
var hair_color: Color = Color("#53607b")
var facing_right: bool = true
var initialized: bool = false
var remaining_zones: Array[String] = []
var path_progress: float = 0.0

func configure(identity: String, display_name: String, tint: Color, hair: Color) -> void:
    resident_id = identity
    public_name = display_name
    main_color = tint
    hair_color = hair

func show_public_state(display_name: String, scene_position: Vector2, state_name: String, public_remaining: Array[String] = [], public_progress: float = 0.0) -> void:
    public_name = display_name
    activity = state_name
    remaining_zones = public_remaining.duplicate()
    path_progress = public_progress
    target_position = scene_position
    # Server zone is authoritative: only step to a new trusted waypoint when
    # a new public snapshot confirms that zone. No client-side route simulation.
    if initialized and scene_position != position:
        facing_right = scene_position.x >= position.x
    position = scene_position
    initialized = true
    queue_redraw()

func _draw() -> void:
    if not initialized:
        return
    # An 18x30 hard-edged pixel resident, shaded to share the new landscape.
    # There is deliberately NO local walking tween: server zone is authority.
    draw_rect(Rect2(-10, -1, 20, 3), Color("#47624e", 0.35))
    draw_rect(Rect2(-8, 1, 16, 2), Color("#314a3c", 0.36))
    var sitting: bool = activity == "sit" or activity == "rest"
    var body_low: float = -14.0 if sitting else -20.0
    draw_rect(Rect2(-10, body_low - 1, 20, 16), Color("#3c3937"))
    draw_rect(Rect2(-8, body_low, 16, 13), main_color.darkened(0.21))
    draw_rect(Rect2(-6, body_low + 1, 11, 8), main_color)
    draw_rect(Rect2(-7, body_low + 9, 14, 2), main_color.lightened(0.19))
    draw_rect(Rect2(-11, body_low + 2, 3, 9), main_color.darkened(0.35))
    draw_rect(Rect2(8, body_low + 2, 3, 9), main_color.darkened(0.3))
    if sitting:
        draw_rect(Rect2(-10, -4, 20, 5), main_color.darkened(0.2))
        draw_rect(Rect2(-9, -1, 8, 3), Color("#4e4542"))
        draw_rect(Rect2(2, -1, 7, 3), Color("#4e4542"))
    else:
        draw_rect(Rect2(-8, -6, 6, 8), Color("#574d45"))
        draw_rect(Rect2(2, -6, 6, 8), Color("#574d45"))
        draw_rect(Rect2(-8, 0, 6, 2), Color("#3d3938"))
        draw_rect(Rect2(2, 0, 6, 2), Color("#3d3938"))
    var head_low: float = -30.0 if sitting else -36.0
    draw_rect(Rect2(-9, head_low + 4, 18, 14), Color("#4c3c37"))
    draw_rect(Rect2(-7, head_low + 6, 14, 10), Color("#e1b99a"))
    draw_rect(Rect2(-6, head_low + 6, 12, 5), Color("#f1d5b5"))
    draw_rect(Rect2(-10, head_low + 1, 20, 9), hair_color.darkened(0.3))
    draw_rect(Rect2(-9, head_low, 18, 7), hair_color)
    draw_rect(Rect2(-7, head_low + 1, 9, 2), hair_color.lightened(0.15))
    draw_rect(Rect2(-9, head_low + 7, 3, 7), hair_color.darkened(0.12))
    draw_rect(Rect2(7, head_low + 7, 3, 7), hair_color.darkened(0.12))
    var eye_x: float = 3.0 if facing_right else -5.0
    draw_rect(Rect2(eye_x, head_low + 11, 2, 2), Color("#473b3b"))
    draw_rect(Rect2(-eye_x - 2.0, head_low + 11, 2, 2), Color("#473b3b"))
    if activity == "read":
        # Only after the server reports read; this is not a client-issued task.
        draw_rect(Rect2(0, body_low + 7, 14, 9), Color("#6d513f"))
        draw_rect(Rect2(2, body_low + 8, 5, 7), Color("#e9d8af"))
        draw_rect(Rect2(8, body_low + 8, 5, 7), Color("#f4e6c4"))
        draw_rect(Rect2(7, body_low + 8, 1, 7), Color("#9d7953"))
    elif activity == "rest":
        draw_rect(Rect2(-7, head_low + 17, 15, 2), Color("#d7b38f"))
