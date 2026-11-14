extends SceneTree
## Screenshot capture from the real standalone Godot scene using a virtual display.

func _initialize() -> void:
    call_deferred("_run_capture")

func _run_capture() -> void:
    var home = load("res://scenes/home.tscn").instantiate()
    root.add_child(home)
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img = root.get_texture().get_image()
    if img == null or img.get_width() < 300:
        printerr("CAPTURE_FAIL: no valid rendered image")
        quit(1)
        return
    var day_target = ProjectSettings.globalize_path("res://preview-morning.png")
    var res1 = img.save_png(day_target)
    print("CAPTURE_MORNING ", day_target, " code=", res1)
    home._set_time(true)
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var dusk_target = ProjectSettings.globalize_path("res://preview-dusk.png")
    var res2 = root.get_texture().get_image().save_png(dusk_target)
    print("CAPTURE_DUSK ", dusk_target, " code=", res2)
    quit(0 if res1 == OK and res2 == OK else 1)
