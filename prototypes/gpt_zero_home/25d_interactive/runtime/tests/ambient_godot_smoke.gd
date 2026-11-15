extends SceneTree
## A visual-logic smoke test; do not confuse with Android device acceptance.
const Scene = preload("res://scenes/first_home_25d.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    printerr("AMBIENT_GODOT_FAIL: " + reason)
    quit(1)

func _run() -> void:
    var view = Scene.instantiate()
    root.add_child(view)
    await process_frame
    if view.show_hotspots:
        _fail("interaction circles must default to hidden")
        return
    if view.ambient_layer == null:
        _fail("environment-only atmosphere not attached to art")
        return
    if view.ambient_layer.get_parent() != view.map_frame:
        _fail("environment layer not linked to responsive scene image")
        return
    if view.ambient_layer.position != view.map_origin:
        _fail("effects and original art have different image-space origin")
        return
    view._toggle_dusk()
    if not view.is_dusk or not view.ambient_layer.dusk:
        _fail("dusk did not change atmosphere beyond modulate")
        return
    view._set_scene("interior")
    if view.ambient_layer.current_scene != "interior":
        _fail("indoor atmosphere not updated during room switch")
        return
    view._toggle_hotspots()
    if not view.show_hotspots:
        _fail("visitor cannot reveal point markers on demand")
        return
    if view.offline_test_mode or view.use_same_origin_public_feed:
        _fail("default environment loaded an unauthorized AI or online resident")
        return
    print("AMBIENT_GODOT_OK: no default dots, dusk lighting, decorative indoor/outdoor atmosphere, no forced AI")
    quit(0)