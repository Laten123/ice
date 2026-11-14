extends SceneTree
## Contract test derived from DeepSeek's P1 HTTP gateway report.
## Validates the Godot-side location mapping and trust boundary; no HTTP server
## or real resident token is present in this test.

const SHEN := "00000000-0000-4000-8000-000000000001"
const PUBLIC_IDS := [
    "door", "path", "garden", "riverside", "old_tree", "book_corner",
    "stone_table", "riverbank", "window"
]

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    printerr("P1_CONTRACT_FAIL: ", message)
    quit(1)

func _run() -> void:
    var home = load("res://scenes/home.tscn").instantiate()
    root.add_child(home)
    await process_frame
    home.scripted_replay.stop_playback()

    var graph = home.walk_graph
    var public_locations: Array[String] = graph.available_zones()
    for place in PUBLIC_IDS:
        if not graph.is_known_zone(place) or not public_locations.has(place):
            _fail("gateway place is missing from path graph: " + place)
            return
        if graph.zone_position(place) == Vector2.INF:
            _fail("API destination has no scene position: " + place)
            return
    if public_locations.size() != PUBLIC_IDS.size():
        _fail("public locations unexpectedly expose a legacy internal name")
        return
    if public_locations.has("tea_table") or public_locations.has("porch"):
        _fail("legacy scene location leaked to API observation")
        return

    # The log is meaningful to the design but must not be fake-walkable while
    # there is no authored log/seat and no validated walkable approach.
    if graph.is_known_zone("fallen_log") or public_locations.has("fallen_log"):
        _fail("unfinished fallen_log was advertised as available")
        return

    var observation: Dictionary = home.observation_for_verified_resident(SHEN)
    var observable: Array = observation["world"]["available_locations"]
    if not observable.has("stone_table") or observable.has("tea_table"):
        _fail("observation used non-canonical place IDs")
        return
    for person in home.public_snapshot()["residents"]:
        if not public_locations.has(person["zone"]):
            _fail("public state used an invalid API zone")
            return

    var move: Dictionary = home.gateway.dispatch_verified({
        "event_id": "p1-canonical-stone-table",
        "resident_id": SHEN, # injected by a trusted internal worker ONLY
        "action": "move",
        "target": "stone_table"
    }, SHEN)
    if move["status"] != "accepted":
        _fail("canonical P1 move rejected by Godot")
        return

    var actor = home.residents[SHEN]
    for i in range(190):
        actor._process(0.1)
        if actor.state != "move":
            break
    if actor.position.distance_to(graph.zone_position("stone_table")) > 1.5:
        _fail("resident never reached canonical stone_table")
        return
    var completed := false
    for receipt in home.public_event_log:
        if receipt.get("event_id") == "p1-canonical-stone-table" and receipt.get("status") == "completed":
            completed = true
    if not completed:
        _fail("P1 canonical move lacked completion receipt")
        return

    var unavailable: Dictionary = home.gateway.dispatch_verified({
        "event_id": "p1-unbuilt-log",
        "resident_id": SHEN,
        "action": "move",
        "target": "fallen_log"
    }, SHEN)
    if unavailable["status"] != "rejected":
        _fail("unfinished fallen_log accepted as navigable")
        return

    print("P1_CONTRACT_OK: backend place IDs, canonical observations, arrival receipt, unfinished scene exclusions")
    quit(0)
