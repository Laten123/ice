extends RefCounted
## Fantasia plain-pixel-wood UI V2.
## All visible buttons/title are generated from small in-memory textures.
## This intentionally ignores the old ornate PNGs; no server changes and
## no extra downloads. Residents remain autonomous and public observer read-only.

const WOOD := Color("#996845")
const WOOD_HOVER := Color("#ad7954")
const WOOD_PRESS := Color("#7e513a")
const WOOD_DISABLED := Color("#777169")
const EDGE := Color("#3d2c25")
const TEXT := Color("#fff0d3")

static func has_skin() -> bool:
    # The plain wooden skin is always available; old ornate files are ignored.
    return true

static func _wood_texture(base: Color, active: bool = false) -> Texture2D:
    var w := 112
    var h := 42
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color.TRANSPARENT)
    for y in range(2, h - 2):
        for x in range(2, w - 2):
            # Four clipped square corners, no flowers, gemstones or gilding.
            if (x < 6 or x > w - 7) and (y < 6 or y > h - 7):
                continue
            var rim: bool = x < 5 or x >= w - 5 or y < 5 or y >= h - 5
            var inner: bool = x == 5 or x == w - 6 or y == 5 or y == h - 6
            var shade: Color = base
            if rim:
                shade = EDGE
            elif inner:
                shade = base.lightened(0.19) if not active else base.darkened(0.20)
            elif y == 12 or y == 29:
                shade = base.darkened(0.07)
            elif y == 13 or y == 30:
                shade = base.lightened(0.045)
            elif y < 10:
                shade = base.lightened(0.085)
            elif y > h - 11:
                shade = base.darkened(0.08)
            # Quiet, short grain lines. No noisy textures over small labels.
            if not rim and not inner and (y == 18 or y == 24) and (x % 31 >= 6 and x % 31 <= 17):
                shade = shade.darkened(0.055)
            img.set_pixel(x, y, shade)
    # Tiny neutral peg heads (not bright gold ornaments).
    for x in [10, w - 11]:
        for y in [10, h - 11]:
            img.set_pixel(x, y, Color("#c6a07b"))
            img.set_pixel(x + 1, y, Color("#77533d"))
    return ImageTexture.create_from_image(img)

static func _plank(base: Color, pressed: bool = false) -> StyleBoxTexture:
    var style := StyleBoxTexture.new()
    style.texture = _wood_texture(base, pressed)
    style.texture_margin_left = 12.0
    style.texture_margin_right = 12.0
    style.texture_margin_top = 10.0
    style.texture_margin_bottom = 10.0
    style.content_margin_left = 11.0
    style.content_margin_right = 11.0
    style.content_margin_top = 8.0
    style.content_margin_bottom = 8.0
    return style

static func skin_button(button: Button, _family: String) -> void:
    button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    button.add_theme_stylebox_override("normal", _plank(WOOD))
    button.add_theme_stylebox_override("hover", _plank(WOOD_HOVER))
    button.add_theme_stylebox_override("pressed", _plank(WOOD_PRESS, true))
    button.add_theme_stylebox_override("disabled", _plank(WOOD_DISABLED))
    button.add_theme_stylebox_override("focus", _plank(WOOD_HOVER))
    button.add_theme_color_override("font_color", TEXT)
    button.add_theme_color_override("font_hover_color", Color("#ffffff"))
    button.add_theme_color_override("font_pressed_color", TEXT)
    button.add_theme_color_override("font_disabled_color", Color("#d0c5ba"))
    button.add_theme_color_override("font_outline_color", Color("#432e25"))
    button.add_theme_constant_override("outline_size", 1)

static func skin_title(header: PanelContainer) -> void:
    header.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    var plank := _plank(Color("#745039"))
    plank.content_margin_left = 14.0
    plank.content_margin_right = 14.0
    plank.content_margin_top = 9.0
    plank.content_margin_bottom = 9.0
    header.add_theme_stylebox_override("panel", plank)

static func install(day_button: Button, dusk_button: Button) -> void:
    skin_button(day_button, "day")
    skin_button(dusk_button, "dusk")
