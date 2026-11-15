extends SceneTree
## Godot room geometry + observer-only scene switches.
## Explicitly simulated PUBLIC packets. No model, token or private world access.
const VIEWER = preload("res://scenes/public_viewer.tscn")
const INTERIOR = preload("res://scenes/house_interior.tscn")
const HomeSpaces = preload("res://scripts/home_spaces.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    printerr("HOUSE_ROOM_FAIL: ", message)
    quit(1)

func _run() -> void:
    var room = INTERIOR.instantiate()
    root.add_child(room)
    await process_frame
    if not room.has_indoor_collision():
        _fail("actual indoor scene has no wall colliders")
        return
    for zone in HomeSpaces.INTERIOR_POSITIONS.keys():
        if not HomeSpaces.valid_interior_zone(zone):
            _fail("missing indoor waypoint: " + zone)
            return
        if room.marker_position(zone) != HomeSpaces.indoor_position(zone):
            _fail("room marker / public position mismatch: " + zone)
            return
    if HomeSpaces.valid_interior_zone("fallen_log") or HomeSpaces.INTERACTION_POINTS.has("fallen_log"):
        _fail("owner's stump must remain visual-only until server feature is implemented")
        return
    if HomeSpaces.declared_activity("door", "enter_house"):
        _fail("client exposed house entry as an action")
        return
    if HomeSpaces.declared_activity("window_corner", "move"):
        _fail("room declarations must not cause client-driven movement")
        return
    room.set_dusk(true)
    if room.get_node("RoomBase").texture != room.DUSK_FLOOR:
        _fail("room did not switch to dusk palette")
        return
    room.queue_free()

    var view = VIEWER.instantiate()
    root.add_child(view)
    await process_frame
    if view.observed_scene != "exterior" or view.interior_view.visible or not view.art.visible:
        _fail("the home must initially show the public exterior")
        return
    if view.room_button.text != "看室内":
        _fail("missing actual room observer button")
        return
    var outdoor = {
        "schema_version": 1,
        "world_id": "fantasia.first_home.prototype",
        "revision": 1,
        "residents": [
            {"resident_id": "path-test", "name": "测试居民", "zone": "stone_table", "activity": "stay"}
        ]
    }
    if not view.apply_public_snapshot(outdoor):
        _fail("old P1 snapshot no longer accepted")
        return
    var actor = view.actors["path-test"]
    if not actor.visible:
        _fail("public outdoor resident unexpectedly invisible")
        return
    if not view.show_observed_scene("interior"):
        _fail("observer cannot open house")
        return
    if not view.interior_view.visible or view.art.visible or actor.visible:
        _fail("house camera leaked outdoor resident or did not switch scenes")
        return
    if view.room_button.text != "看院子":
        _fail("room observer button does not return to yard")
        return
    if view.last_revision != 1 or view.actors.size() != 1 or not view.public_feed_url.is_empty():
        _fail("room observation modified world revision, people or network state")
        return
    var indoors = {
        "schema_version": 1,
        "world_id": "fantasia.first_home.prototype",
        "revision": 2,
        "residents": [{
            "resident_id": "path-test",
            "name": "测试居民",
            "scene_id": "interior",
            "zone": "house_entry",
            "activity": "stay"
        }]
    }
    if not view.apply_public_snapshot(indoors):
        _fail("valid public indoor authoritative packet rejected")
        return
    if not actor.visible or actor.position != HomeSpaces.indoor_position("house_entry"):
        _fail("server-confirmed indoor resident not in correct room position")
        return
    if not view.show_observed_scene("exterior"):
        _fail("viewer cannot return to outside")
        return
    if actor.visible or not view.art.visible or view.interior_view.visible:
        _fail("interior residents leaked into exterior view")
        return
    # A private, forged or mismatched location must never be visualized.
    var forged: Dictionary = indoors.duplicate(true)
    forged["revision"] = 3
    forged["residents"][0]["zone"] = "riverbank"
    if view.apply_public_snapshot(forged):
        _fail("indoor scene accepted an outdoor zone")
        return
    forged = indoors.duplicate(true)
    forged["revision"] = 3
    forged["residents"][0]["scene_id"] = "bedroom_private"
    if view.apply_public_snapshot(forged):
        _fail("unknown/private scene accepted")
        return
    forged = indoors.duplicate(true)
    forged["revision"] = 3
    forged["residents"][0]["path_progress"] = {
        "from": "house_entry", "to": "window_corner",
        "remaining": ["window_corner"], "progress": 0.0
    }
    forged["residents"][0]["activity"] = "move"
    if not view.apply_public_snapshot(forged):
        _fail("valid server-supplied indoor moving segment rejected")
        return
    var old: Vector2 = actor.position
    await process_frame
    await process_frame
    if actor.position != old:
        _fail("room observer simulated movement without server updates")
        return
    forged = indoors.duplicate(true)
    forged["revision"] = 4
    forged["residents"] = []
    if not view.apply_public_snapshot(forged) or view.actors.has("path-test"):
        _fail("withdrawn indoor public consent did not remove resident")
        return
    if view.has_method("enter_house") or view.has_method("dispatch_intent"):
        _fail("client should not execute authenticated resident house entry")
        return
    print("HOUSE_ROOM_OK: real layered room, colliders, 5 anchors, public indoor opt-in, camera-only switch")
    quit(0)
