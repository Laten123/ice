extends SceneTree
## Native pixel-ground smoke test for the first home.
## Deliberately uses no token, gateway, player input, or synthetic activity.
const Viewer = preload("res://scenes/public_viewer.tscn")
const OfflineHome = preload("res://scenes/home.tscn")
const Ground = preload("res://scripts/pixel_ground.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(why: String) -> void:
    printerr("PIXEL_GROUND_FAIL: ", why)
    quit(1)

func _run() -> void:
    var view = Viewer.instantiate()
    root.add_child(view)
    await process_frame

    if view.terrain == null or view.terrain.name != "PixelTerrainV1":
        _fail("real pixel terrain layer was not added")
        return
    if view.terrain.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
        _fail("pixel material is blurred instead of nearest-neighbor")
        return
    if view.terrain_day.get_size() != Vector2(480, 300):
        _fail("pixel canvas does not have native half-resolution grid")
        return
    var image: Image = view.terrain_day.get_image()
    if image.get_pixel(30, 40).a > 0.01:
        _fail("pixel ground incorrectly covers sky and distant background")
        return
    if image.get_pixel(440, 230).a < 0.99:
        _fail("grass was not rendered as opaque pixel terrain")
        return
    if Ground._surface(10, 250) != 0 or Ground._surface(130, 250) != 2:
        _fail("river and shore no longer align with existing coastline")
        return
    if Ground._surface(430, 250) != 3 or Ground._surface(326, 245) != 5:
        _fail("grass or house path no longer matches the old layout")
        return
    # Same source pixels, alternate dusk palette; never change geometry.
    var day_texture: Texture2D = view.terrain.texture
    view._set_time(true)
    if not view.is_dusk or view.terrain.texture != view.terrain_dusk:
        _fail("dusk lighting did not switch pixel ground")
        return
    if day_texture == view.terrain.texture:
        _fail("day and dusk pixel layers share the wrong texture")
        return
    if view.public_feed_url != "" or view.have_public_snapshot:
        _fail("art loading contacted the public world or fabricated residents")
        return
    if not view.show_observed_scene("interior") or view.terrain.visible:
        _fail("outdoor pixel terrain covered the indoor room")
        return
    if not view.show_observed_scene("exterior") or not view.terrain.visible:
        _fail("outdoor pixel terrain did not reappear")
        return
    # Pixel art must follow exactly the same responsive art rectangle.
    view._apply_layout(Vector2(390, 844))
    if view.terrain.position != view.art.position or view.terrain.size != view.art.size:
        _fail("portrait layout drifted from original interactive anchors")
        return
    view._apply_layout(Vector2(853, 384))
    if view.terrain.position != view.art.position or view.terrain.size != view.art.size:
        _fail("landscape layout drifted from original interactive anchors")
        return

    # Previous offline sandbox loads the same ground-underlay after
    # removing old SVG-only surfaces; its simulated intent system is unchanged.
    var offline = OfflineHome.instantiate()
    root.add_child(offline)
    await process_frame
    if offline.terrain == null or offline.terrain.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
        _fail("offline resident-test home lost its pixel terrain")
        return
    offline._apply_layout(Vector2(853, 384))
    if offline.terrain.position != offline.scenery.position or offline.terrain.size != offline.scenery.size:
        _fail("offline resident-test art and terrain are misaligned")
        return
    offline._set_time(true)
    if offline.terrain.texture != offline.terrain_dusk:
        _fail("offline resident-test dusk ground did not switch")
        return
    offline.queue_free()

    print("PIXEL_GROUND_OK: native 480x300 pixels, river/grass/path geometry, dusk, read-only, responsive")
    quit(0)
