extends RefCounted
## First Home ground material pass 1. Real pixel raster at 480x300.
## Displayed at x2 in the existing 960x600 art coordinates with NEAREST.
## No SVG gradients, no API actions, no resident position changes.
## One deterministic, cached texture for each preview lighting state.

const PIXEL_SIZE := Vector2i(480, 300)
const SCALE := 2
const TOP_LAND_Y := 105

static func _hash(x: int, y: int, salt: int = 0) -> int:
    var v: int = x * 73856093 ^ y * 19349663 ^ salt * 83492791
    v = (v ^ (v >> 13)) * 1274126177
    return absi(v ^ (v >> 16))

static func _line(y: int, y0: int, y1: int, x0: float, x1: float) -> float:
    return lerpf(x0, x1, clampf(float(y - y0) / float(y1 - y0), 0.0, 1.0))

static func _bank_x(y: int) -> float:
    # Preserve the original C-shaped shoreline, in HALF scene coordinates.
    # No per-pixel allocations: this is evaluated ~200k times per export.
    if y < 118:
        return _line(y, 105, 118, 0.0, 38.0)
    if y < 140:
        return _line(y, 118, 140, 38.0, 62.0)
    if y < 165:
        return _line(y, 140, 165, 62.0, 68.0)
    if y < 193:
        return _line(y, 165, 193, 68.0, 85.0)
    if y < 225:
        return _line(y, 193, 225, 85.0, 110.0)
    if y < 253:
        return _line(y, 225, 253, 110.0, 133.0)
    if y < 276:
        return _line(y, 253, 276, 133.0, 151.0)
    return _line(y, 276, 300, 151.0, 174.0)

static func _road_x(y: int) -> float:
    # Keep the original door-to-yard path, in HALF scene coordinates.
    if y < 206:
        return _line(y, 189, 206, 300.0, 303.0)
    if y < 225:
        return _line(y, 206, 225, 303.0, 315.0)
    if y < 239:
        return _line(y, 225, 239, 315.0, 326.0)
    if y < 251:
        return 326.0
    if y < 268:
        return _line(y, 251, 268, 326.0, 345.0)
    if y < 284:
        return _line(y, 268, 284, 345.0, 353.0)
    return _line(y, 284, 300, 353.0, 362.0)

static func _surface(x: int, y: int) -> int:
    # 0 deep water / 1 foam / 2 stony bank / 3 grass / 4 road edging / 5 road
    if y < TOP_LAND_Y:
        return -1
    var bank: float = _bank_x(y)
    var coastline: float = bank + float((_hash(y / 4, 0, 22) % 5) - 2)
    if float(x) < coastline - 7.0:
        return 0
    if float(x) < coastline - 3.0:
        return 1
    if float(x) < coastline + 4.0:
        return 2
    if y >= 190:
        var road_center: float = _road_x(y)
        var offset: float = absf(float(x) - road_center)
        var edge_jitter: float = float((_hash(y / 3, 0, 46) % 7) - 3)
        if offset < 15.0 + edge_jitter:
            return 5
        if offset < 18.0 + edge_jitter:
            return 4
    return 3

static func _put(img: Image, x: int, y: int, color: Color) -> void:
    if x >= 0 and y >= 0 and x < PIXEL_SIZE.x and y < PIXEL_SIZE.y:
        img.set_pixel(x, y, color)

static func _draw_clump(img: Image, x: int, y: int, shade: Color, light: Color) -> void:
    # Pixel-art three-blade grass: 1px cells, no interpolation, no antialias.
    _put(img, x + 1, y, light)
    _put(img, x + 1, y + 1, shade)
    _put(img, x, y + 2, shade)
    _put(img, x + 2, y + 2, shade)
    _put(img, x + 1, y + 3, shade)

static func create_texture(dusk: bool = false) -> ImageTexture:
    var img := Image.create(PIXEL_SIZE.x, PIXEL_SIZE.y, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))

    var grass := [Color("#77a966"), Color("#80ae69"), Color("#85b36e"), Color("#6a9a5d"), Color("#91b879")]
    var road := [Color("#c9a477"), Color("#d8b487"), Color("#e0bd91"), Color("#bc976d")]
    var water := [Color("#286078"), Color("#2e6d83"), Color("#397b8d"), Color("#22576e")]
    var foam := [Color("#67a3a4"), Color("#94bdb0"), Color("#75aaac")]
    var bank := [Color("#b4a888"), Color("#d4c09b"), Color("#8d9278"), Color("#90a27b")]
    var road_edge := [Color("#997c58"), Color("#a98c65"), Color("#b29469")]

    # The sky and remote trees stay in the legacy SVG until their own phase.
    for y in range(TOP_LAND_Y, PIXEL_SIZE.y):
        for x in range(PIXEL_SIZE.x):
            var region: int = _surface(x, y)
            var hash_value: int = _hash(x / 4, y / 4, 11)
            var c: Color
            match region:
                0:
                    var band: int = (y / 7 + hash_value % 3) % water.size()
                    c = water[band]
                1:
                    c = foam[hash_value % foam.size()]
                2:
                    c = bank[hash_value % bank.size()]
                4:
                    c = road_edge[hash_value % road_edge.size()]
                5:
                    c = road[(hash_value + x / 10) % road.size()]
                _:
                    var tile_hash: int = _hash(x / 16, y / 16, 19)
                    c = grass[(tile_hash + hash_value % 3) % grass.size()]
            img.set_pixel(x, y, c)

    # Intentionally sparse, hand-sized clusters instead of stochastic noise.
    for gy in range(7, 19):
        for gx in range(30):
            var h: int = _hash(gx, gy, 73)
            if h % 5 == 0:
                continue
            var cx: int = gx * 16 + 2 + h % 11
            var cy: int = gy * 16 + 2 + (h / 31) % 9
            if _surface(cx, cy) != 3:
                continue
            _draw_clump(img, cx, cy, Color("#527d4f"), Color("#a0bf79"))
            if h % 13 == 1:
                var petal: Color = Color("#f2e9c9") if h % 2 == 0 else Color("#e8b9c7")
                _put(img, cx + 5, cy, petal)
                _put(img, cx + 4, cy + 1, Color("#f4d78a"))
                _put(img, cx + 6, cy + 1, petal)

    # Keep water reflections horizontal and readable at mobile zoom.
    for gy in range(11, 38):
        for gx in range(19):
            var h: int = _hash(gx, gy, 109)
            if h % 3 == 0:
                continue
            var xx: int = gx * 11 + h % 8
            var yy: int = gy * 8 + (h / 17) % 5
            if _surface(xx, yy) == 0 and _surface(xx + 4, yy) == 0:
                var reflection: Color = Color("#9cc5ba") if h % 4 == 0 else Color("#5895a1")
                for dx in range(2 + h % 4):
                    _put(img, xx + dx, yy, reflection)
                if h % 5 == 0:
                    _put(img, xx + 1, yy + 2, Color("#3b7d91"))

    # Path pebbles are cropped to the road and are not decorative fake waypoints.
    for gy in range(24, 39):
        for gx in range(37, 47):
            var h: int = _hash(gx, gy, 139)
            var xx: int = gx * 10 + h % 7
            var yy: int = gy * 8 + (h / 13) % 5
            if _surface(xx, yy) != 5 or h % 3 == 0:
                continue
            var stone: Color = Color("#efcf9e") if h % 2 == 0 else Color("#aa8867")
            _put(img, xx, yy, stone)
            _put(img, xx + 1, yy, stone)
            if h % 4 == 0:
                _put(img, xx, yy + 1, Color("#d5ad7d"))

    if dusk:
        # Keep the SAME topology and pixels; only shift the palette at dusk.
        for y in range(TOP_LAND_Y, PIXEL_SIZE.y):
            for x in range(PIXEL_SIZE.x):
                var c: Color = img.get_pixel(x, y)
                var cool: float = 0.08 if _surface(x, y) < 2 else 0.0
                img.set_pixel(x, y, Color(
                    clampf(c.r * 0.85 + 0.035, 0.0, 1.0),
                    clampf(c.g * 0.78 + 0.005, 0.0, 1.0),
                    clampf(c.b * (0.84 + cool) + 0.055, 0.0, 1.0),
                    c.a
                ))

    return ImageTexture.create_from_image(img)
