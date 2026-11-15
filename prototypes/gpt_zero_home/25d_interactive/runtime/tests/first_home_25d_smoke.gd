extends SceneTree
## Smoke test: real art, visual anchors, interactive inspection, room switch,
## server-owned public snapshots, privacy and explicit offline test mode.
const HomeScene = preload("res://scenes/first_home_25d.tscn")
const Points = preload("res://scripts/home_25d_points.gd")

func _initialize() -> void:
    call_deferred("_test")

func _fail(message: String) -> void:
    printerr("HOME_25D_FAIL: ", message)
    quit(1)

func _test() -> void:
    var view = HomeScene.instantiate()
    root.add_child(view)
    await process_frame
    if view.map_art.texture == null or view.map_art.texture.get_size() != Points.EXTERIOR_SIZE:
        _fail("the actual approved 2.5D outdoor image is not imported")
        return
    if Points.EXTERIOR_POINTS.size() != 10 or Points.INTERIOR_POINTS.size() != 5:
        _fail("existing starter-home point list changed")
        return
    if Points.point_position("exterior", "door") == Points.point_position("exterior", "stump"):
        _fail("real door and stump use the same visual anchor")
        return
    if Points.test_route("exterior", "stone_table", "door").size() < 2:
        _fail("isolated test resident has no actual yard route")
        return
    if Points.test_route("interior", "house_entry", "writing_desk").is_empty():
        _fail("isolated test resident has no writing-desk route")
        return
    view._select_point("stump")
    if view.selected_point != "stump" or view.prompt_label.text.is_empty():
        _fail("touch/select point does not update information")
        return
    if not view._set_scene("interior") or view.map_art.texture.get_size() != Points.INTERIOR_SIZE:
        _fail("observer cannot enter the actual illustrated indoor scene")
        return
    if not view._set_scene("exterior"):
        _fail("observer cannot return outside")
        return
    if view.start_public_feed("http://127.0.0.1:8200/observation"):
        _fail("observer accepted a resident-auth or insecure endpoint")
        return
    var good := {"schema_version": 1, "world_id": Points.WORLD_ID, "revision": 1,
        "residents": [{"resident_id": "path-test", "name": "测试居民", "scene_id": "exterior",
        "zone": "stone_table", "activity": "stay"}]}
    if not view.apply_public_snapshot(good) or view.public_actors.size() != 1:
        _fail("public test resident does not appear on real 2.5D artwork")
        return
    if view.public_actors["path-test"].position != Points.point_position("exterior", "stone_table"):
        _fail("server zone is not mapped to the new stone-table position")
        return
    var forbidden: Dictionary = good.duplicate(true)
    forbidden["revision"] = 2
    forbidden["residents"][0]["token"] = "never expose me"
    if view.apply_public_snapshot(forbidden):
        _fail("private resident field was accepted")
        return
    forbidden = good.duplicate(true)
    forbidden["revision"] = 2
    forbidden["residents"][0]["zone"] = "boat"
    if view.apply_public_snapshot(forbidden):
        _fail("decorative boat was made a public navigable zone")
        return
    forbidden = good.duplicate(true)
    forbidden["revision"] = 2
    forbidden["residents"][0]["scene_id"] = "other_island"
    if view.apply_public_snapshot(forbidden):
        _fail("unauthorized new island was silently created")
        return
    var clear := {"schema_version": 1, "world_id": Points.WORLD_ID, "revision": 2, "residents": []}
    if not view.apply_public_snapshot(clear) or not view.public_actors.is_empty():
        _fail("revoked consent did not remove the public actor")
        return
    view._toggle_offline_test()
    if not view.offline_test_mode or not view.test_actor.visible:
        _fail("explicit offline test mode did not start")
        return
    if view.public_actors.size() != 0:
        _fail("offline test mode fabricated a public AI resident")
        return
    view._toggle_offline_test()
    if view.test_actor.visible:
        _fail("offline test actor remained visible after mode exit")
        return
    print("FIRST_HOME_25D_OK: original 2.5D art, touch points, indoor/outdoor, real zone mapping, read-only public ACL, offline-only resident")
    quit(0)
