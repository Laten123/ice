extends SceneTree
## Run only AFTER extracting the separate PNG art pack into the Godot project.
## Does not connect to the Python server and does not create AI intents.
const FantasiaUiSkin = preload("res://scripts/fantasia_ui_skin.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    printerr("FANTASIA_ART_FAIL: ", message)
    quit(1)

func _run() -> void:
    if not FantasiaUiSkin.has_skin():
        _fail("Art PNGs are not installed at res://art/ui/ yet")
        return
    var day := Button.new()
    var dusk := Button.new()
    root.add_child(day)
    root.add_child(dusk)
    FantasiaUiSkin.install(day, dusk)
    for button in [day, dusk]:
        if not button.get_theme_stylebox("normal") is StyleBoxTexture:
            _fail("Wooden Button missing normal texture state")
            return
        if not button.get_theme_stylebox("pressed") is StyleBoxTexture:
            _fail("Wooden Button missing pressed texture state")
            return
    var title := PanelContainer.new()
    root.add_child(title)
    FantasiaUiSkin.skin_title(title)
    if not title.get_theme_stylebox("panel") is StyleBoxTexture:
        _fail("Wooden title plaque missing")
        return
    if not ResourceLoader.exists("res://art/objects/stump_scene.svg"):
        _fail("V2.1 scene-matched stump artwork missing")
        return
    if ResourceLoader.exists("res://art/characters/cirno.png"):
        _fail("Unlicensed existing-media character asset must not ship")
        return
    var obj = load("res://art/objects/stump_scene.svg") as Texture2D
    if obj == null or obj.get_width() != 80 or obj.get_height() != 64:
        _fail("V2.1 stump SVG failed import at the authored size")
        return
    print("FANTASIA_ART_GODOT_OK: wooden buttons + title + palette-matched stump SVG are importable")
    quit(0)
