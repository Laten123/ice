extends SceneTree
## Real-engine capture for desktop, phone landscape, phone portrait.

func _initialize() -> void:
    call_deferred("_run_capture")

func _save_view(home: Control, desired_size: Vector2i, dusk: bool, filename: String) -> bool:
    DisplayServer.window_set_size(desired_size)
    home._set_time(dusk)
    # Window resizing is asynchronous. Give the controls and renderer time to reflow.
    await process_frame
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    if image == null or image.get_width() < 200:
        printerr("CAPTURE_FAIL: no framebuffer for ", filename)
        return false
    var output_file := ProjectSettings.globalize_path("res://" + filename)
    var code: Error = image.save_png(output_file)
    print("CAPTURE_VIEW ", filename,
        " requested=", desired_size,
        " window=", DisplayServer.window_get_size(),
        " logical_scene=", home.size,
        " image=", image.get_size(),
        " result=", code)
    return code == OK

func _run_capture() -> void:
    var home: Control = load("res://scenes/home.tscn").instantiate()
    root.add_child(home)
    await process_frame
    var all_passed := true
    all_passed = await _save_view(home, Vector2i(960, 600), false, "preview-morning.png") and all_passed
    all_passed = await _save_view(home, Vector2i(960, 600), true, "preview-dusk.png") and all_passed
    all_passed = await _save_view(home, Vector2i(853, 384), false, "preview-phone-landscape.png") and all_passed
    all_passed = await _save_view(home, Vector2i(390, 844), true, "preview-phone-portrait.png") and all_passed
    quit(0 if all_passed else 1)
