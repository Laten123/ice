extends RefCounted
## Compact First Home parcel policy for the READ-ONLY observer and test contract.
## Python server MUST independently enforce lot ownership/build/visit rights.
## Never treat a decorative preview as new free playable land.

const FORMAL := "formal"
const SHOWCASE := "demo"
const LOT_ART_BOUNDS := Rect2(0.0, 0.0, 960.0, 600.0)
const EXTERIOR := "exterior"
const INTERIOR := "interior"

# Inhabitants can only live and host guests within the ONE existing home parcel.
# These are existing P1/V2 locations, not a broader public world.
const FORMAL_EXTERIOR_ZONES := [
    "door", "path", "garden", "riverside", "old_tree",
    "book_corner", "stone_table", "riverbank", "window", "stump"
]
const FORMAL_INTERIOR_ZONES := [
    "house_entry", "window_corner", "writing_desk", "bookcase", "rest_corner"
]

static func valid_profile(profile: String) -> bool:
    return profile == FORMAL or profile == SHOWCASE

static func is_inside_first_lot(position: Vector2) -> bool:
    return LOT_ART_BOUNDS.has_point(position)

static func is_existing_location(scene: String, zone: String) -> bool:
    if scene == EXTERIOR:
        return FORMAL_EXTERIOR_ZONES.has(zone)
    if scene == INTERIOR:
        return FORMAL_INTERIOR_ZONES.has(zone)
    return false

static func can_show_noninteractive_demo_surroundings(profile: String) -> bool:
    # This only grants permission to draw *decorative* showcase surroundings.
    # It NEVER adds land, build rights, inventory, residents or API locations.
    return profile == SHOWCASE

static func can_create_unowned_extra_lot(_profile: String) -> bool:
    # NEVER client-authorize a free lot. Paid/assigned lots are a future
    # authenticated server transaction and cannot be conjured by demo mode.
    return false
