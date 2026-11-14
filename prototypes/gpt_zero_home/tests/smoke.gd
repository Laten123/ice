extends SceneTree

func _initialize() -> void:
    var source = load("res://scenes/home.tscn")
    if source == null:
        printerr("SMOKE_FAIL: no scene")
        quit(1)
        return
    var home = source.instantiate()
    if home == null:
        printerr("SMOKE_FAIL: cannot instantiate scene")
        quit(1)
        return
    get_root().add_child(home)
    await process_frame
    if home.get_node_or_null("OriginalSceneArtwork") == null:
        printerr("SMOKE_FAIL: artwork not present")
        quit(1)
        return
    if home.get_node_or_null("TimeToggle") == null:
        printerr("SMOKE_FAIL: switch missing")
        quit(1)
        return
    home._on_toggle_time()
    if not home.is_dusk:
        printerr("SMOKE_FAIL: dusk did not activate")
        quit(1)
        return
    home._on_toggle_time()
    if home.is_dusk:
        printerr("SMOKE_FAIL: morning did not restore")
        quit(1)
        return
    print("SMOKE_OK: original home scene and morning/dusk switch")
    quit(0)
