extends RefCounted
## Original indexed pixel art stored as text-safe RLE/base64.
## Drawn on a fixed 480x300 source grid; nearest-neighbor upscales to 960x600.
## No external shaders, fonts, data, model actions or SVG dependencies.

const SOURCE_WIDTH := 480
const SOURCE_HEIGHT := 300
const PIXELS := SOURCE_WIDTH * SOURCE_HEIGHT
const BYTE_COUNT := PIXELS * 4

static func decode_texture(colors: Array, rle64: String, dusk: bool) -> ImageTexture:
    if colors.is_empty() or colors.size() > 256:
        push_error("PixelV3: invalid palette")
        return null
    var raw: PackedByteArray = Marshalls.base64_to_raw(rle64)
    if raw.is_empty() or raw.size() % 2 != 0 or raw.size() > PIXELS * 2:
        push_error("PixelV3: invalid RLE input")
        return null
    var palette: Array[Color] = []
    for c in colors:
        var color := Color(str(c))
        if dusk:
            # Same geometry, a restrained violet dusk. Preserve readability.
            color = Color(
                clampf(color.r * 0.76 + 0.09, 0.0, 1.0),
                clampf(color.g * 0.69 + 0.055, 0.0, 1.0),
                clampf(color.b * 0.76 + 0.12, 0.0, 1.0),
                color.a
            )
        palette.append(color)
    var rgba := PackedByteArray()
    rgba.resize(BYTE_COUNT)
    var at: int = 0
    for i in range(0, raw.size(), 2):
        var count: int = int(raw[i])
        var entry: int = int(raw[i + 1])
        if count <= 0 or entry >= palette.size() or at + count > PIXELS:
            push_error("PixelV3: invalid RLE run or palette")
            return null
        var c: Color = palette[entry]
        var cr: int = roundi(c.r * 255.0)
        var cg: int = roundi(c.g * 255.0)
        var cb: int = roundi(c.b * 255.0)
        var ca: int = roundi(c.a * 255.0)
        for _j in range(count):
            var o: int = at * 4
            rgba[o] = cr
            rgba[o + 1] = cg
            rgba[o + 2] = cb
            rgba[o + 3] = ca
            at += 1
    if at != PIXELS:
        push_error("PixelV3: incomplete canvas")
        return null
    var img := Image.create_from_data(SOURCE_WIDTH, SOURCE_HEIGHT, false, Image.FORMAT_RGBA8, rgba)
    return ImageTexture.create_from_image(img)
