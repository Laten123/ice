extends SceneTree
## Exercise both the touch UI callbacks and the responsive layout without a desktop.

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/home.tscn")
    if scene == null:
        printerr("SMOKE_FAIL: no scene")
        quit(1)
        return
    var home = scene.instantiate()
    root.add_child(home)
    await process_frame
    if home.get_node_or_null("OriginalSceneArtwork") == null:
        printerr("SMOKE_FAIL: no artwork")
        quit(1)
        return
    var controls: HBoxContainer = home.get_node_or_null("TouchControls") as HBoxContainer
    var day: Button = home.get_node_or_null("TouchControls/MorningButton") as Button
    var dusk: Button = home.get_node_or_null("TouchControls/DuskButton") as Button
    if controls == null or day == null or dusk == null:
        printerr("SMOKE_FAIL: missing touch controls")
        quit(1)
        return

    # Test real signal wiring (not only direct state mutation).
    dusk.pressed.emit()
    if not home.is_dusk:
        printerr("SMOKE_FAIL: touch dusk button")
        quit(1)
        return
    day.pressed.emit()
    if home.is_dusk:
        printerr("SMOKE_FAIL: touch morning button")
        quit(1)
        return

    var viewports := [
        Vector2(390, 844), # portrait phone
        Vector2(360, 740), # narrow phone
        Vector2(853, 384), # landscape phone
        Vector2(1280, 720) # desktop
    ]
    for view in viewports:
        home._apply_layout(view)
        var p: Vector2 = controls.position
        var extent: Vector2 = controls.size
        if p.x < 0.0 or p.y < 0.0 or p.x + extent.x > view.x + 1.0 or p.y + extent.y > view.y + 1.0:
            printerr("SMOKE_FAIL: touch controls outside viewport ", view, " ", p, " ", extent)
            quit(1)
            return
        if day.custom_minimum_size.y < 48.0 or dusk.custom_minimum_size.y < 48.0:
            printerr("SMOKE_FAIL: touch targets too small ", view)
            quit(1)
            return
        var ratio: float = float(home.scenery.size.x) / float(home.scenery.size.y)
        if absf(ratio - 1.6) > 0.001:
            printerr("SMOKE_FAIL: artwork distorted at ", view)
            quit(1)
            return
        if view.y > view.x * 1.15 and not home.hint_label.visible:
            printerr("SMOKE_FAIL: missing portrait swipe hint ", view)
            quit(1)
            return
        print("LAYOUT_OK ", view, " touch=", p, " extent=", extent)

    print("SMOKE_OK: responsive phone/desktop layout and visible touch actions")
    quit(0)
