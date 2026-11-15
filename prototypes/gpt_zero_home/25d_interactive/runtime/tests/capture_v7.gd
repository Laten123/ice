extends SceneTree
## Run with a real renderer (CI uses Xvfb), never --headless.
## Produces in-engine previews and checks nested Y-sort and water boundaries.
const Scene = preload("res://scenes/first_home_25d.tscn")
const Actor = preload("res://scripts/home_25d_resident.gd")
var view
var fixtures: Array[Node2D] = []
var output := ""

func _initialize() -> void:
    call_deferred("_run")

func fail(reason: String) -> void:
    printerr("V7_RENDER_FAIL: " + reason)
    quit(1)

func color_distance(a: Color, b: Color) -> float:
    return maxf(absf(a.r-b.r), maxf(absf(a.g-b.g), absf(a.b-b.b)))

func frame() -> Image:
    await process_frame
    await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func stage(scene_id: String) -> void:
    for actor in fixtures:
        actor.queue_free()
    fixtures.clear()
    var dimensions: Vector2 = view.Points.image_size(scene_id)
    root.size = Vector2i(dimensions)
    await process_frame
    view._set_scene(scene_id)
    for child in view.get_children():
        if child is CanvasItem:
            child.visible = child == view.map_frame
    view.map_frame.position = Vector2.ZERO
    view.map_frame.size = dimensions
    view.map_art.position = Vector2.ZERO
    view.map_art.size = dimensions
    for layer in [view.water_layer, view.ambient_layer, view.depth_layer, view.marker_layer]:
        layer.position = Vector2.ZERO
        layer.scale = Vector2.ONE
    view.marker_layer.visible = false
    view.ambient_layer.set_motion(false)
    view.ambient_layer.clock = 0.0
    view.ambient_layer.twilight = 0.0
    view._process(0.0)

func fixture(point: Vector2, action: String, direction: Vector2 = Vector2.DOWN) -> Node2D:
    var actor = Actor.new()
    actor.configure(true)
    view.test_layer.add_child(actor)
    actor.position = point
    actor.set_process(false)
    actor.face_direction(direction)
    actor.set_activity(action)
    actor.advance_animation(0.8, 5.25 if action == "move" else 0.0)
    fixtures.append(actor)
    return actor

func save(image: Image, name: String) -> void:
    if image.save_png(output.path_join(name)) != OK:
        fail("could not save " + name)

func _run() -> void:
    output = OS.get_environment("FANTASIA_CAPTURE_DIR")
    if output.is_empty():
        output = ProjectSettings.globalize_path("user://v7-captures")
    DirAccess.make_dir_recursive_absolute(output)
    root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
    view = Scene.instantiate()
    root.add_child(view)
    await process_frame
    view.set_process(false)
    view.ambient_layer.set_process(false)
    await stage("exterior")
    view.ambient_layer.visible = false
    view.water_layer.visible = false
    var actor = fixture(Vector2(570, 610), "stay")
    var table: Sprite2D = view.depth_layer.occluders["stone_table"]
    var behind := await frame()
    var sample := Vector2i(570, 578)
    var source: Image = view.OUTDOOR_ART.get_image()
    if color_distance(behind.get_pixelv(sample), source.get_pixelv(sample)) > 0.04:
        fail("table did not occlude an actor behind it")
        return
    # Move only the sort origin, keeping the exact texture pixels in place.
    table.position.y -= 40.0
    table.offset.y += 40.0
    var in_front := await frame()
    if color_distance(in_front.get_pixelv(sample), behind.get_pixelv(sample)) < 0.1:
        fail("nested actor did not appear in front when its depth changed")
        return
    save(behind, "occlusion-behind.png")
    save(in_front, "occlusion-front.png")
    table.position.y += 40.0
    table.offset.y -= 40.0
    actor.queue_free()
    fixtures.clear()
    await process_frame
    view.water_layer.visible = true
    # Freeze the master/foreground shaders; only the extracted river may vary.
    var water: ShaderMaterial = view.depth_layer.water_material
    water.set_shader_parameter("wind_on", 1.0)
    water.set_shader_parameter("wind_time", 0.0)
    var water_before := await frame()
    water.set_shader_parameter("wind_time", 1.9)
    var water_after := await frame()
    var mask: Image = view.water_layer.texture.get_image()
    var inside := 0
    var outside := 0
    for y in range(0, 1024, 4):
        for x in range(0, 1536, 4):
            if color_distance(water_before.get_pixel(x,y), water_after.get_pixel(x,y)) > 0.01:
                if mask.get_pixel(x,y).a > 0.99:
                    inside += 1
                else:
                    outside += 1
    if inside < 100 or outside != 0:
        fail("river shader changed no water or leaked outside its mask: %s/%s" % [inside, outside])
        return
    await stage("exterior")
    view.ambient_layer.visible = true
    fixture(Vector2(470, 548), "stay", Vector2.RIGHT)
    fixture(Vector2(587, 651), "read")
    fixture(Vector2(794, 753), "sit")
    fixture(Vector2(1250, 772), "move", Vector2.LEFT)
    save(await frame(), "v7-exterior.png")
    view.ambient_layer.twilight = 1.0
    view._process(0.0)
    save(await frame(), "v7-dusk.png")
    await stage("interior")
    fixture(Vector2(373, 461), "stay")
    fixture(Vector2(1072, 799), "read")
    fixture(Vector2(351, 842), "rest")
    save(await frame(), "v7-interior.png")
    print("V7_RENDER_OK: actual nested foreground occlusion; %s water samples moved, zero outside; 3 in-engine scene previews at %s" % [inside, output])
    quit(0)
