extends Node2D
## Animated placeholder resident, driven only by accepted intents.
## Deliberately NO WASD, mouse-to-move, or owner override of resident decisions.

signal state_changed(resident_id: String, public_state: String)

const WALK_SPEED := 40.0
const VALID_ACTIONS := ["move", "stay", "rest", "read", "sit", "decline"]
const POSE_ZONES := {
    "read": ["book_corner", "tea_table", "window_view"],
    "sit": ["tea_table", "window_view"],
    "rest": ["porch", "window_view", "tree_path", "garden"]
}

var resident_id: String = ""
var public_name: String = ""
var main_color: Color = Color("#789ab7")
var hair_color: Color = Color("#52617e")
var graph: RefCounted
var zone: String = "porch"
var target_zone: String = "porch"
var state: String = "stay"
var route: PackedVector2Array = PackedVector2Array()
var route_index: int = 0
var walk_phase: float = 0.0
var facing_right: bool = true

func configure(uuid: String, label: String, body_tint: Color, head_tint: Color, initial_zone: String, world_graph: RefCounted) -> void:
    resident_id = uuid
    public_name = label
    main_color = body_tint
    hair_color = head_tint
    graph = world_graph
    zone = initial_zone
    target_zone = initial_zone
    position = graph.zone_position(zone)
    name = label

func accept_intent(intent: Dictionary) -> bool:
    var action: String = str(intent.get("action", ""))
    if not VALID_ACTIONS.has(action):
        return false
    if action == "move":
        var destination: String = str(intent.get("target", ""))
        if not graph.is_known_zone(destination):
            return false
        # If already partway through a route, first return to the nearest safe waypoint.
        var start: String = graph.nearest_zone(position)
        var new_route: PackedVector2Array = graph.route_between(start, destination)
        if new_route.is_empty():
            return false
        route = new_route
        route_index = 0
        target_zone = destination
        state = "move"
    elif action in POSE_ZONES:
        # Reading/tea is an action at a suitable location, not a teleport.
        var nearest: String = graph.nearest_zone(position)
        if not POSE_ZONES[action].has(nearest) or position.distance_to(graph.zone_position(nearest)) > 16.0:
            return false
        route = PackedVector2Array()
        zone = nearest
        state = action
    else:
        # "decline" and "stay" are final and are NOT automatically retried.
        route = PackedVector2Array()
        zone = graph.nearest_zone(position)
        state = action
    state_changed.emit(resident_id, state)
    queue_redraw()
    return true

func _process(delta: float) -> void:
    if state != "move":
        return
    if route_index >= route.size():
        _arrive()
        return
    var next_point: Vector2 = route[route_index]
    var movement: Vector2 = next_point - position
    if movement.length() < 1.0:
        position = next_point
        route_index += 1
        if route_index >= route.size():
            _arrive()
        return
    facing_right = movement.x >= 0.0
    var step: float = minf(WALK_SPEED * delta, movement.length())
    position += movement.normalized() * step
    walk_phase += delta * 9.0
    queue_redraw()

func _arrive() -> void:
    position = graph.zone_position(target_zone)
    zone = target_zone
    route = PackedVector2Array()
    route_index = 0
    state = "stay"
    state_changed.emit(resident_id, state)
    queue_redraw()

func _draw() -> void:
    # Original procedural placeholder. Final resident sprites must be reauthored.
    var bob: float = sin(walk_phase) * 1.2 if state == "move" else 0.0
    draw_ellipse(Vector2(0, 1), Vector2(12, 3.5), Color(0.11, 0.20, 0.16, 0.45))
    var body: Rect2 = Rect2(-10, -22 + bob, 20, 17)
    draw_rect(body, main_color)
    draw_rect(Rect2(-8, -26 + bob, 16, 10), Color("#efd5ba"))
    draw_rect(Rect2(-10, -33 + bob, 20, 9), hair_color)
    draw_rect(Rect2(-9, -14 + bob, 4, 12), main_color.darkened(0.26))
    draw_rect(Rect2(5, -14 + bob, 4, 12), main_color.darkened(0.26))
    draw_rect(Rect2(-7, -9 + bob, 5, 9), Color("#58524d"))
    draw_rect(Rect2(2, -9 + bob, 5, 9), Color("#58524d"))
    var eye_x: float = 3.0 if facing_right else -5.0
    draw_rect(Rect2(eye_x, -23 + bob, 3, 3), Color("#413a3f"))
    if state == "read":
        draw_rect(Rect2(2, -13, 12, 9), Color("#ead4a1"))
        draw_line(Vector2(8, -13), Vector2(8, -5), Color("#ad8e67"), 1)
    elif state == "sit" or state == "rest":
        draw_rect(Rect2(-10, -7, 20, 5), main_color.darkened(0.1))
