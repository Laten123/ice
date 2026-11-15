extends SceneTree
## V3 all-material pixel pass + ONE compact plot contract.
## Uses isolated public-only fixtures. Never sends any authenticated intent.
const VIEWER = preload("res://scenes/public_viewer.tscn")
const ROOM = preload("res://scenes/house_interior.tscn")
const DEMO = preload("res://scenes/public_viewer_demo.tscn")
const HomeScope = preload("res://scripts/home_scope.gd")
const HomeSpaces = preload("res://scripts/home_spaces.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    printerr("PIXEL_HOME_V3_FAIL: ", reason)
    quit(1)

func _run() -> void:
    var view = VIEWER.instantiate()
    root.add_child(view)
    await process_frame
    if view.presentation_mode != "formal":
        _fail("formal is not the default profile")
        return
    if HomeScope.LOT_ART_BOUNDS.size != Vector2(960, 600):
        _fail("the first home gained unintended land")
        return
    if HomeScope.can_create_unowned_extra_lot("formal") or HomeScope.can_create_unowned_extra_lot("demo"):
        _fail("client can mint a free unowned plot")
        return
    if HomeScope.can_show_noninteractive_demo_surroundings("formal"):
        _fail("formal version has demo scenery enabled")
        return
    if HomeScope.FORMAL_EXTERIOR_ZONES.size() != 10 or HomeScope.FORMAL_INTERIOR_ZONES.size() != 5:
        _fail("formal zone list was expanded unexpectedly")
        return
    if HomeScope.is_existing_location("exterior", "outer_meadow"):
        _fail("an extra free parcel leaked into home scope")
        return
    if HomeScope.is_existing_location("interior", "guest_private_room"):
        _fail("an undeclared private room leaked to public observer")
        return

    if view.pixel_exterior == null or view.pixel_exterior_day == null:
        _fail("new real pixel home artwork is not loaded")
        return
    if view.pixel_exterior.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
        _fail("the completed pixel scene is blurred")
        return
    if view.pixel_exterior_day.get_size() != Vector2(480, 300):
        _fail("exterior no longer has native 480x300 raster")
        return
    if not view.pixel_exterior.visible:
        _fail("formal exterior pixel scene is hidden")
        return
    if view.stump_visual == null or view.stump_visual.texture == null:
        _fail("the original pixel stump was removed")
        return
    if view.stump_visual.texture.resource_path != "res://art/objects/stump_plain_32x32.png":
        _fail("the original pixel stump style was silently changed")
        return

    var first_snapshot: Dictionary = {
        "schema_version": 1,
        "world_id": "fantasia.first_home.prototype",
        "revision": 301,
        "residents": [{
            "resident_id": "path-test",
            "name": "公开测试居民",
            "scene_id": "exterior",
            "zone": "stone_table",
            "activity": "stay"
        }]
    }
    if not view.apply_public_snapshot(first_snapshot):
        _fail("old public stone-table observation no longer works")
        return
    if not view.actors.has("path-test"):
        _fail("pixel art is not compatible with resident overlays")
        return
    var before_position: Vector2 = view.actors["path-test"].position

    view._set_time(true)
    if view.pixel_exterior.texture != view.pixel_exterior_dusk:
        _fail("dusk did not update the pixel scene")
        return
    if view.actors["path-test"].position != before_position:
        _fail("a visual lighting switch moved a real resident")
        return

    view.show_observed_scene("interior")
    if view.pixel_exterior.visible or not view.interior_view.visible:
        _fail("the pixel exterior leaked into the interior")
        return
    var room = view.interior_view
    if room.pixel_room == null or room.pixel_room.texture.get_size() != Vector2(480, 300):
        _fail("pixel interior is not an actual 480x300 texture")
        return
    if not room.has_indoor_collision():
        _fail("indoor physics was removed during the art pass")
        return
    for zone in HomeScope.FORMAL_INTERIOR_ZONES:
        if room.marker_position(zone) != HomeSpaces.indoor_position(zone):
            _fail("interior marker moved: " + str(zone))
            return
    if room.pixel_room.texture != room.pixel_room_dusk:
        _fail("interior dusk pixel palette is not selected")
        return
    view.show_observed_scene("exterior")
    if not view.pixel_exterior.visible or view.interior_view.visible:
        _fail("the new courtyard does not return after looking inside")
        return

    # The authenticated world has no permission to add an extra public zone.
    var forged: Dictionary = first_snapshot.duplicate(true)
    forged["revision"] = 302
    forged["residents"][0]["zone"] = "outer_meadow"
    if view.apply_public_snapshot(forged):
        _fail("the viewer accepted an extra demo/paid land point as free")
        return

    var demo = DEMO.instantiate()
    root.add_child(demo)
    await process_frame
    if demo.presentation_mode != "demo":
        _fail("separate visual-only demo profile missing")
        return
    if not HomeScope.can_show_noninteractive_demo_surroundings(demo.presentation_mode):
        _fail("noninteractive scenery cannot be shown in demo")
        return
    if HomeScope.can_create_unowned_extra_lot(demo.presentation_mode):
        _fail("demo profile granted a free plot")
        return
    if demo.apply_public_snapshot(forged):
        _fail("demo view expanded the public activity topology")
        return

    print("PIXEL_HOME_V3_OK: compact formal plot, pixel indoor/outdoor, stump, all 5 anchors, night, demo isolation")
    quit(0)
