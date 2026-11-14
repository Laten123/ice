extends SceneTree
## No model tokens or privileged input. This tests a PUBLIC observer only.
const VIEWER_SCENE = preload("res://scenes/public_viewer.tscn")
const FIXTURE_PATH := "res://tests/fixtures/public_world_v2.json"

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    printerr("PUBLIC_VIEWER_FAIL: ", message)
    quit(1)

func _run() -> void:
    if str(ProjectSettings.get_setting("application/run/main_scene")) != "res://scenes/public_viewer.tscn":
        _fail("the default Godot scene is not the read-only observer")
        return
    var view = VIEWER_SCENE.instantiate()
    root.add_child(view)
    await process_frame
    if view.public_feed_url != "" or view.fetching:
        _fail("viewer must not contact a server on first launch")
        return
    if view.get_node_or_null("PublicResidentVisuals") == null:
        _fail("missing visual-only resident layer")
        return
    if view.get_node_or_null("PublicSnapshotHTTPRequest") == null:
        _fail("missing public-only request adapter")
        return
    if view.has_method("dispatch_verified") or view.has_method("accept_intent"):
        _fail("viewer has an action or command method")
        return
    if view.start_public_feed("http://127.0.0.1:8200/observation"):
        _fail("viewer accepted plain HTTP or resident-auth observation endpoint")
        return
    if view.start_public_feed("https://example.org/observation"):
        _fail("viewer accepted a resident-only API endpoint")
        return

    var file = FileAccess.open(FIXTURE_PATH, FileAccess.READ)
    if file == null:
        _fail("public fixture not found")
        return
    var packet = JSON.parse_string(file.get_as_text())
    if typeof(packet) != TYPE_DICTIONARY:
        _fail("fixture is invalid JSON")
        return
    if not view.apply_public_snapshot(packet):
        _fail("valid public fixture rejected")
        return
    if view.actors.size() != 2 or not view.have_public_snapshot:
        _fail("public avatars not shown")
        return
    var first = view.actors["00000000-0000-4000-8000-000000000001"]
    var before: Vector2 = first.position
    if first.activity != "sit":
        _fail("visual-only activity was lost")
        return
    if before.distance_to(view.graph.zone_position("stone_table")) > 0.5:
        _fail("canonical public P1 location was not mapped")
        return

    view._set_time(true)
    if not view.is_dusk or first.position != before:
        _fail("viewer lighting preview affected resident location")
        return
    for viewport in [Vector2(853, 384), Vector2(390, 844), Vector2(1280, 720)]:
        view._apply_layout(viewport)
        if view.buttons.position.x < 0.0 or view.buttons.position.y < 0.0 or             view.buttons.position.x + view.buttons.size.x > viewport.x + 1.0 or             view.buttons.position.y + view.buttons.size.y > viewport.y + 1.0:
            _fail("observation controls do not fit " + str(viewport))
            return

    var invalid: Dictionary = packet.duplicate(true)
    invalid["residents"][0]["token"] = "should-never-appear"
    if view.apply_public_snapshot(invalid) or view.actors.size() != 2:
        _fail("private field was accepted into observation")
        return
    invalid = packet.duplicate(true)
    invalid["residents"][0]["zone"] = "fallen_log"
    if view.apply_public_snapshot(invalid):
        _fail("unfinished location was displayed as navigable")
        return
    invalid = packet.duplicate(true)
    invalid["revision"] = -1
    if view.apply_public_snapshot(invalid):
        _fail("stale revision rolled back state")
        return
    invalid = packet.duplicate(true)
    invalid["residents"][0]["resident_id"] = invalid["residents"][1]["resident_id"]
    if view.apply_public_snapshot(invalid):
        _fail("duplicate resident IDs accepted")
        return

    # P1 v2 moving packets contain a route and fraction; without a precise
    # definition of its segment the renderer MUST NOT make up coordinates.
    var route_packet: Dictionary = packet.duplicate(true)
    route_packet["revision"] = 2
    route_packet["residents"][0]["zone"] = "door"
    route_packet["residents"][0]["activity"] = "move"
    route_packet["residents"][0]["path_progress"] = {
        "from": "door",
        "to": "path",
        "remaining": ["path", "book_corner", "stone_table"],
        "progress": 0.0
    }
    if not view.apply_public_snapshot(route_packet):
        _fail("valid P1 v3 path_progress rejected")
        return
    if first.position != view.graph.zone_position("door") or first.remaining_zones.size() != 3:
        _fail("P1 v2 route display failed")
        return
    await process_frame
    await process_frame
    if first.position != view.graph.zone_position("door"):
        _fail("viewer invented motion without a newer authoritative snapshot")
        return

    var second_hop: Dictionary = route_packet.duplicate(true)
    second_hop["revision"] = 3
    second_hop["residents"][0]["zone"] = "path"
    second_hop["residents"][0]["path_progress"] = {
        "from": "path",
        "to": "book_corner",
        "remaining": ["book_corner", "stone_table"],
        "progress": 0.25
    }
    if not view.apply_public_snapshot(second_hop):
        _fail("second P1 v2 path update rejected")
        return
    if first.position != view.graph.zone_position("path") or first.remaining_zones.size() != 2:
        _fail("viewer failed to advance exactly to the server-confirmed waypoint")
        return
    await process_frame
    await process_frame
    if first.position != view.graph.zone_position("path"):
        _fail("viewer interpolated toward an unconfirmed waypoint")
        return

    var bad_route: Dictionary = second_hop.duplicate(true)
    bad_route["revision"] = 4
    bad_route["residents"][0]["path_progress"]["remaining"] = ["fallen_log"]
    if view.apply_public_snapshot(bad_route):
        _fail("unfinished or forged waypoint accepted")
        return
    bad_route = second_hop.duplicate(true)
    bad_route["revision"] = 4
    bad_route["residents"][0]["path_progress"]["progress"] = 1.3
    if view.apply_public_snapshot(bad_route):
        _fail("out-of-range segment progress accepted")
        return
    bad_route = second_hop.duplicate(true)
    bad_route["revision"] = 4
    bad_route["residents"][0]["path_progress"]["secret_token"] = "nope"
    if view.apply_public_snapshot(bad_route):
        _fail("unapproved route metadata accepted")
        return

    bad_route = second_hop.duplicate(true)
    bad_route["revision"] = 4
    bad_route["residents"][0]["path_progress"]["from"] = "riverbank"
    if view.apply_public_snapshot(bad_route):
        _fail("from waypoint did not match authoritative current zone")
        return
    bad_route = second_hop.duplicate(true)
    bad_route["revision"] = 4
    bad_route["residents"][0]["path_progress"]["to"] = "old_tree"
    if view.apply_public_snapshot(bad_route):
        _fail("to waypoint did not match the first remaining node")
        return
    bad_route = second_hop.duplicate(true)
    bad_route["revision"] = 4
    bad_route["residents"][0]["path_progress"].erase("from")
    if view.apply_public_snapshot(bad_route):
        _fail("missing route segment origin accepted")
        return

    var updated: Dictionary = packet.duplicate(true)
    updated["revision"] = 4
    updated["residents"][0]["zone"] = "riverbank"
    updated["residents"][0]["action"] = "moving"
    updated["residents"][0].erase("activity")
    if not view.apply_public_snapshot(updated):
        _fail("second public snapshot rejected")
        return
    if first.activity != "move" or first.target_position != view.graph.zone_position("riverbank"):
        _fail("next server snapshot was not reflected visually")
        return

    print("PUBLIC_VIEWER_OK: token-free, viewer-only, mobile layout, P1 from/to route validation, server-confirmed waypoint movement")
    quit(0)
