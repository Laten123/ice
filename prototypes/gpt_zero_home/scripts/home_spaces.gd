extends RefCounted
## First-home spatial contract for Godot's READ-ONLY viewer.
## Backend decisions, resident consent, actions, and room entry are Python-owned.
## Positions below describe drawn world anchors, not authoritative pathfinding.

const EXTERIOR := "exterior"
const INTERIOR := "interior"

const INTERIOR_POSITIONS := {
    "house_entry": Vector2(483.0, 500.0),
    "window_corner": Vector2(254.0, 291.0),
    "writing_desk": Vector2(650.0, 480.0),
    "bookcase": Vector2(704.0, 273.0),
    "rest_corner": Vector2(397.0, 415.0)
}

# Functional intentions to implement/verify in the Python world, NOT clickable
# commands emitted by this observer. Initial P1 supports only a subset.
const INTERACTION_POINTS := {
    "door": {"scene": EXTERIOR, "capacity": 1, "activities": ["stay"], "transition": "enter_house"},
    "stone_table": {"scene": EXTERIOR, "capacity": 2, "activities": ["sit", "read", "stay"]},
    "riverbank": {"scene": EXTERIOR, "capacity": 2, "activities": ["stay", "rest"]},
    "book_corner": {"scene": EXTERIOR, "capacity": 1, "activities": ["read", "stay"]},
    "old_tree": {"scene": EXTERIOR, "capacity": 2, "activities": ["stay", "rest"]},
    "house_entry": {"scene": INTERIOR, "capacity": 1, "activities": ["stay"], "transition": "exit_house"},
    "window_corner": {"scene": INTERIOR, "capacity": 1, "activities": ["stay", "rest"]},
    "writing_desk": {"scene": INTERIOR, "capacity": 1, "activities": ["read", "stay"]},
    "bookcase": {"scene": INTERIOR, "capacity": 1, "activities": ["read", "stay"]},
    "rest_corner": {"scene": INTERIOR, "capacity": 1, "activities": ["rest", "stay"]}
}

# The owner's real visible tree stump is deliberately NOT a public travel node.
# Keep the visual object until the backend implements collision, approach,
# availability, and a genuinely voluntary sit/rest action.
const DEFERRED_INTERACTIONS := {
    "fallen_log": {"scene": EXTERIOR, "purpose": "quiet place to sit", "state": "visual_only"},
    "boat": {"scene": EXTERIOR, "purpose": "riverside scenery", "state": "visual_only"}
}

static func valid_scene(scene_id: String) -> bool:
    return scene_id == EXTERIOR or scene_id == INTERIOR

static func valid_interior_zone(zone: String) -> bool:
    return INTERIOR_POSITIONS.has(zone)

static func scene_for_point(point_id: String) -> String:
    if INTERIOR_POSITIONS.has(point_id):
        return INTERIOR
    if INTERACTION_POINTS.has(point_id):
        return str(INTERACTION_POINTS[point_id]["scene"])
    return ""

static func indoor_position(zone: String) -> Vector2:
    if not INTERIOR_POSITIONS.has(zone):
        return Vector2(-999.0, -999.0)
    return INTERIOR_POSITIONS[zone]

static func declared_activity(point_id: String, activity: String) -> bool:
    if not INTERACTION_POINTS.has(point_id):
        return false
    return INTERACTION_POINTS[point_id]["activities"].has(activity)
