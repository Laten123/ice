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
    if not ResourceLoader.exists("res://art/objects/stump_plain_32x32.png"):
        _fail("Owner's required tree stump PNG missing")
        return
    if ResourceLoader.exists("res://art/characters/cirno.png"):
        _fail("Unlicensed existing-media character asset must not ship")
        return
    var obj = load("res://art/objects/stump_plain_32x32.png") as Texture2D
    if obj == null or obj.get_width() != 32 or obj.get_height() != 32:
        _fail("The tree stump must be a 32x32 native sprite")
        return
    print("FANTASIA_ART_GODOT_OK: wooden buttons + title + owner's 32x32 stump are importable")
    quit(0)
