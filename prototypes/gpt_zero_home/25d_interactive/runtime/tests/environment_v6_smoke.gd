extends SceneTree
## V6 actual 4.6.3 Godot regression: visual-only secondary layers.
const VIEW = preload("res://scenes/first_home_25d.tscn")
const PLATE = preload("res://art/layers/tree_lantern_clean_plate.png")
const LAMP = preload("res://art/layers/tree_lantern_sprite.png")
const Points = preload("res://scripts/home_25d_points.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    printerr("ENVIRONMENT_V6_FAIL: " + reason)
    quit(1)

func _run() -> void:
    if PLATE.get_width() != 77 or PLATE.get_height() != 104:
        _fail("lantern clean plate has wrong pixel dimensions")
        return
    if LAMP.get_width() != 72 or LAMP.get_height() != 85:
        _fail("independent lantern cutout has wrong dimensions")
        return
    var view = VIEW.instantiate()
    root.add_child(view)
    await process_frame
    var layer = view.ambient_layer
    if layer == null or layer.LANTERN_SPRITE != LAMP:
        _fail("lantern sprite resource not installed in the actual scene")
        return
    if layer.SHORE_SHIMMERS.size() < 12:
        _fail("no sufficient shoreline water-only motion anchors")
        return
    if view.show_hotspots or view.offline_test_mode or view.use_same_origin_public_feed:
        _fail("visual update must not expose debug markers or fake real residents")
        return
    layer.set_motion(true)
    layer._process(0.07)
    if layer.clock <= 0.0:
        _fail("decorative clock did not advance")
        return
    var old_scene: String = view.current_scene
    var old_position: Vector2 = Points.point_position("exterior", "stone_table")
    view._toggle_dusk()
    layer._process(0.2)
    view._process(0.1)
    if layer.twilight <= 0.0 or layer.twilight >= 1.0:
        _fail("dusk must remain gradual")
        return
    if Points.point_position("exterior", "stone_table") != old_position:
        _fail("decorative sprite moved public activity anchors")
        return
    layer.set_motion(false)
    var frozen: float = layer.clock
    layer._process(0.2)
    if layer.clock != frozen:
        _fail("decorative motion continues after switch off")
        return
    view._set_scene("interior")
    if view.current_scene == old_scene or layer.current_scene != "interior":
        _fail("room change did not isolate exterior effects")
        return
    print("ENVIRONMENT_V6_GODOT_OK: independent lantern, water, window emissive, static activity anchors, interior isolation")
    quit(0)