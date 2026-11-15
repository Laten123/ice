extends RefCounted
## Compact STARTER HOME rendering policy for the READ-ONLY observer.
## Fantasia is an archipelago of DISCONNECTED islands, not a continuous map.
## Other independently allocated islands MAY be free or have other terms.
## Python server alone enforces island access, land grants, visit/transfer rights.
## Demo artwork is never a free, newly allocated island.

const FORMAL := "formal"
const SHOWCASE := "demo"
const LOT_ART_BOUNDS := Rect2(0.0, 0.0, 960.0, 600.0)
# These names are policy descriptors, NOT implemented transit endpoints.
const WORLD_LAYOUT := "disconnected_islands"
const INTER_ISLAND_TRAVEL := "instant"
const STARTER_HOME_SCOPE := "first_home_only"
const EXTERIOR := "exterior"
const INTERIOR := "interior"

# This module restricts the CURRENT starter-home observer only, NOT the future
# number of islands in Fantasia. Public free islands and separate private islands
# may be introduced with distinct island IDs and server-authorized grants.
# These are the existing P1/V2 locations of this one starter home.
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

static func world_may_offer_other_free_islands() -> bool:
    # Free public or separately assigned islands ARE allowed by world policy.
    # This does not turn the current home island into a larger free parcel.
    return true

static func islands_are_connected_by_land() -> bool:
    # No shared overworld grid or walkable bridge between plots.
    return false

static func observer_can_instant_travel_to_another_island() -> bool:
    # A human's read-only viewer never sends a resident's travel intent.
    return false

static func can_create_unowned_extra_lot(_profile: String) -> bool:
    # No observer or demo can manufacture land, whether free or paid.
    # Future free islands are allocated by the authenticated world service.
    return false
