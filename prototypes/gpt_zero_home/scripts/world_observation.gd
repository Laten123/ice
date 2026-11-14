extends RefCounted
## Read-only observations of the PUBLIC world. No private diary, prompts,
## reasoning, tokens, owner instructions, or per-agent hidden memory.
## The producer does not choose actions or assign goals.

const WORLD_ID := "fantasia.first_home.prototype"
const SCHEMA_VERSION := 1

var residents: Dictionary = {}
var graph

func configure(actors: Dictionary, walk_graph: RefCounted) -> void:
    residents = actors
    graph = walk_graph

func public_snapshot() -> Dictionary:
    var visible_people: Array[Dictionary] = []
    var identifiers: Array = residents.keys()
    identifiers.sort()
    for resident_id in identifiers:
        var actor = residents[resident_id]
        # For real residents, visible profiles must pass explicit ACL checks.
        # These two test actors have no private attributes.
        visible_people.append({
            "resident_id": str(resident_id),
            "name": actor.public_name,
            "zone": graph.to_api_zone(graph.nearest_zone(actor.position)),
            "activity": actor.state
        })
    return {
        "schema_version": SCHEMA_VERSION,
        "world_id": WORLD_ID,
        "residents": visible_people
    }

func observation_for_verified_resident(verified_resident_id: String) -> Dictionary:
    ## The server, not a viewer's JSON, MUST provide this verified identity.
    ## This is an adapter boundary, not a deployed auth system.
    if not residents.has(verified_resident_id):
        return {}
    var actor = residents[verified_resident_id]
    var other_residents: Array[Dictionary] = []
    for info in public_snapshot()["residents"]:
        if info["resident_id"] != verified_resident_id:
            other_residents.append(info)

    var locations: Array[String] = graph.available_zones()

    return {
        "schema_version": SCHEMA_VERSION,
        "world_id": WORLD_ID,
        "self": {
            "resident_id": verified_resident_id,
            "zone": graph.to_api_zone(graph.nearest_zone(actor.position)),
            "activity": actor.state
        },
        "world": {
            "available_locations": locations,
            "public_residents": other_residents
        },
        "available_actions": ["move", "sit", "read", "rest", "stay", "decline"],
        "limits": {
            "actions_are_optional": true,
            "no_mandatory_tasks": true,
            "no_private_memory_access": true
        }
    }
