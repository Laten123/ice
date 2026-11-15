extends SceneTree
## Actual rig and controller behavior, including interruption while awaiting.
const Actor = preload("res://scripts/home_25d_resident.gd")
const Scene = preload("res://scenes/first_home_25d.tscn")
const Points = preload("res://scripts/home_25d_points.gd")
var completions := 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, reason: String) -> bool:
    if not ok:
        printerr("RESIDENT_V7_FAIL: " + reason)
        quit(1)
    return ok

func _run() -> void:
    var actor = Actor.new()
    actor.configure(true)
    root.add_child(actor)
    actor.set_process(false)
    actor.position = Vector2(587, 651)
    var anchor: Vector2 = actor.position
    if not check(actor.joints.size() == 10 and actor.sprites.size() == 10, "missing actual pose joints or sprite parts"): return
    if not check(actor.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "pixel skin is blurred"): return
    for direction in [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]:
        actor.face_direction(direction)
        var index: int = actor.skin.directions.find(actor.facing)
        if not check(actor.sprites["head"].texture.region.position.x == 3 + index * 24, "direction did not select its own atlas frame"): return
    actor.face_direction(Vector2.DOWN)
    actor.set_activity("move")
    actor.advance_animation(0.12, 5.25)
    var first_leg: float = actor.joints["left_hip"].rotation
    actor.advance_animation(0.12, 21)
    if not check(first_leg * actor.joints["left_hip"].rotation < 0.0, "walk is still a sliding static portrait"): return
    if not check(actor.joints["left_shoulder"].rotation * actor.joints["left_hip"].rotation < 0.0, "walk arms do not oppose the legs"): return
    actor.set_activity("sit")
    actor.advance_animation(1.0)
    if not check(actor.sit_blend == 1.0 and absf(actor.joints["left_knee"].rotation) > 0.9, "sit has no bent knee pose"): return
    actor.set_activity("read")
    actor.advance_animation(1.0)
    if not check(actor.book.visible and absf(actor.joints["right_elbow"].rotation) > 0.5, "reading has no book/hand pose"): return
    actor.set_activity("rest")
    actor.advance_animation(1.0)
    if not check(absf(actor.body.rotation) > 1.4 and actor.eyes.visible and not actor.book.visible, "rest did not recline or release the book"): return
    actor.set_activity("stay")
    actor.advance_animation(1.0)
    if not check(actor.body.rotation == 0.0 and not actor.book.visible, "idle did not restore upright pose"): return
    actor.advance_animation(3.5)
    if not check(actor.eyes.visible, "idle has no blink"): return
    if not check(not actor.set_activity("invented_action"), "unknown activity accepted"): return
    if not check(not actor.apply_skin(Resource.new()), "invalid skin accepted"): return
    actor.door_animation_finished.connect(func(_kind): completions += 1)
    actor.start_door_animation("enter_house")
    actor.advance_animation(Actor.DOOR_DURATION)
    actor.advance_animation(Actor.DOOR_DURATION)
    if not check(actor.body.modulate.a == 0.0 and completions == 1, "door fade/completion not stable"): return
    actor.finish_door_animation()
    actor.start_door_animation("exit_house")
    if not check(actor.body.modulate.a == 0.0, "emergence does not start behind the doorway"): return
    actor.advance_animation(Actor.DOOR_DURATION)
    actor.finish_door_animation()
    if not check(actor.position == anchor and actor.body.modulate.a == 1.0, "local animation changed the location anchor"): return
    actor.queue_free()

    var view = Scene.instantiate()
    root.add_child(view)
    await process_frame
    if not check(view.depth_layer.y_sort_enabled and view.public_layer.y_sort_enabled and view.test_layer.y_sort_enabled, "actors and foreground do not share depth sorting"): return
    if not check(view.depth_layer.occluders["stone_table"].visible and not view.depth_layer.occluders["room_desk"].visible, "foreground scene isolation failed"): return
    view._toggle_offline_test()
    Engine.time_scale = 12.0
    view._select_point("door")
    view._perform_test_activity()
    view._select_point("garden")
    var timeout := 0.0
    while view.test_busy and timeout < 30.0:
        await process_frame
        timeout += view.get_process_delta_time()
    if not check(view.test_scene == "interior" and view.test_zone == "house_entry" and not view.test_busy, "captured door request failed after point selection changed"): return
    if not check(view.test_actor.display_activity == "stay" and view.test_actor.transition_kind.is_empty(), "door animation did not settle"): return
    if not check(not view.water_layer.visible and view.depth_layer.occluders["room_desk"].visible, "outdoor layers leaked indoors"): return
    view._select_point("house_entry")
    await view._perform_test_activity()
    if not check(view.test_scene == "exterior" and view.test_zone == "door", "exit-house flow failed"): return
    view._select_point("riverbank")
    view._perform_test_activity()
    await create_timer(0.08).timeout
    view._toggle_offline_test()
    var cancelled_at: Vector2 = view.test_actor.position
    await create_timer(0.8).timeout
    if not check(view.test_actor.position == cancelled_at and not view.test_actor.visible and not view.test_busy, "cancelled movement still updated the actor"): return
    view._toggle_offline_test()
    if not check(view.test_actor.position == Points.point_position("exterior", "stone_table") and view.test_actor.display_activity == "stay", "restarting the fixture retained old motion"): return
    var packet := {"schema_version":1, "world_id":Points.WORLD_ID, "revision":1,
        "residents":[{"resident_id":"fixture", "name":"公开测试", "scene_id":"exterior", "zone":"stump", "activity":"read"}]}
    if not check(view.apply_public_snapshot(packet), "public snapshot regression"): return
    var public_actor = view.public_actors["fixture"]
    var public_anchor: Vector2 = public_actor.position
    public_actor.advance_animation(1.0, 40.0)
    if not check(public_actor.position == public_anchor and not view.use_same_origin_public_feed and view.public_feed_url.is_empty(), "pose created a public movement or online connection"): return
    Engine.time_scale = 1.0
    print("RESIDENT_V7_GODOT_OK: four directions, articulated walk/sit/idle/read/rest, portal clips, depth layers, captured requests and cancellation, local-only")
    quit(0)
