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

    var updated: Dictionary = packet.duplicate(true)
    updated["revision"] = 2
    updated["residents"][0]["zone"] = "riverbank"
    updated["residents"][0]["action"] = "moving"
    updated["residents"][0].erase("activity")
    if not view.apply_public_snapshot(updated):
        _fail("second public snapshot rejected")
        return
    if first.activity != "move" or first.target_position != view.graph.zone_position("riverbank"):
        _fail("next server snapshot was not reflected visually")
        return

    print("PUBLIC_VIEWER_OK: token-free, no commands, phone/desktop layout, canonical P1 snapshots, reject private fields")
    quit(0)
