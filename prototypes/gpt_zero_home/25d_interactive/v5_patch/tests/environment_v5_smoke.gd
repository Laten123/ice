extends SceneTree
## Godot 4.6.3 V5 environment regression; no online residents or network.
const VIEW = preload("res://scenes/first_home_25d.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    printerr("ENVIRONMENT_V5_FAIL: " + reason)
    quit(1)

func _run() -> void:
    var view = VIEW.instantiate()
    root.add_child(view)
    await process_frame
    if view.show_hotspots or view.offline_test_mode or view.use_same_origin_public_feed:
        _fail("markers/AI must remain disabled on default offline screen")
        return
    if view.atmosphere_material == null or not view.map_art.material is ShaderMaterial:
        _fail("approved original illustration is missing dynamic tree shader")
        return
    if view.map_art.modulate != Color.WHITE:
        _fail("old abrupt full-image purple dimming returned")
        return
    var original_position: Vector2 = view.map_origin
    view._toggle_dusk()
    view.ambient_layer._process(0.5)
    view._process(0.1)
    if not view.is_dusk or view.ambient_layer.twilight <= 0.0 or view.ambient_layer.twilight >= 1.0:
        _fail("V5 time of day must have a real transition")
        return
    if not view.ambient_layer.dusk:
        _fail("scene atmosphere did not receive the new time state")
        return
    if view.map_origin != original_position:
        _fail("light effect moved the entire land/interaction coordinate system")
        return
    view._set_scene("interior")
    if view.current_scene != "interior" or not view.atmosphere_material.get_shader_parameter("is_interior"):
        _fail("the foliage-only shader was not disabled indoors")
        return
    view.ambient_layer.set_motion(false)
    var before_clock: float = view.ambient_layer.clock
    view.ambient_layer._process(0.2)
    if before_clock != view.ambient_layer.clock:
        _fail("pausing decoration did not freeze wind and particles")
        return
    view._toggle_dusk()
    view.ambient_layer._process(0.1)
    if view.ambient_layer.twilight <= 0.0:
        _fail("light transition froze when ambient motion stopped")
        return
    print("ENVIRONMENT_V5_GODOT_OK: foliage shader, independent transition, fixed zones, indoor guard, no real residents")
    quit(0)