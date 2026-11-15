extends Node2D
## V5 decorative atmosphere for the approved 2.5D stills (image-space px).
## No AI commands, movement intent, land allocation, network or personal data.
## Selective foliage pixel sway is on the image's ShaderMaterial, not here.

var current_scene := "exterior"
var dusk := false
var twilight := 0.0
var motion_enabled := true
var clock := 0.0
var draw_accum := 0.0

const LEAF_COUNT := 20
const LAMP_ANCHORS := [
    Vector3(608.0, 379.0, 72.0),  # hanging lantern under the old tree
    Vector3(1081.0, 452.0, 88.0), # cottage door lantern
    Vector3(1218.0, 670.0, 82.0), # path fence lantern
    Vector3(575.0, 544.0, 67.0),  # stone table candle
    Vector3(911.0, 277.0, 94.0),  # attic window
    Vector3(868.0, 479.0, 91.0),  # front window
    Vector3(1204.0, 404.0, 103.0) # side window
]

func configure(scene_name: String, dusk_time: bool) -> void:
    current_scene = scene_name
    dusk = dusk_time
    queue_redraw()

func set_dusk(value: bool) -> void:
    dusk = value
    queue_redraw()

func set_motion(value: bool) -> void:
    motion_enabled = value
    queue_redraw()

func _process(delta: float) -> void:
    if not visible:
        return
    var dt: float = minf(delta, 0.1)
    var target: float = 1.0 if dusk else 0.0
    # A full dusk/sunrise transition takes ~2.8 seconds; also works if motion
    # is disabled, because changing the time of day is not a particle effect.
    twilight = move_toward(twilight, target, dt / 2.8)
    if motion_enabled:
        clock += dt
    if motion_enabled or absf(twilight - target) > 0.0001:
        draw_accum += dt
        if draw_accum >= 0.04:
            draw_accum = 0.0
            queue_redraw()

func _halo(pos: Vector2, radius: float, strength: float, source_color: Color) -> void:
    if strength <= 0.0001:
        return
    for step in range(8, 0, -1):
        var part: float = float(step) / 8.0
        var color := source_color
        color.a = strength * (1.0 - part) * 0.18
        draw_circle(pos, radius * part, color)

func _oval(center: Vector2, size: Vector2, color: Color) -> void:
    var shape := PackedVector2Array()
    for i in range(20):
        var angle: float = TAU * float(i) / 20.0
        shape.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y))
    draw_colored_polygon(shape, color)

func _draw() -> void:
    if current_scene == "interior":
        _draw_room()
    else:
        _draw_yard()

func _draw_room() -> void:
    var t: float = clock
    var evening: float = twilight
    # Cool light through the window and warm lamp spill come from distinct
    # sources: there is no uniform brightness overlay over the whole room.
    _halo(Vector2(374.0, 282.0), 234.0, 0.15 * evening, Color("#b2c9f2"))
    _halo(Vector2(824.0, 247.0), 214.0, 0.08 + evening * 0.36 + sin(t * 1.7) * 0.005, Color("#ffd39c"))
    _halo(Vector2(1084.0, 677.0), 166.0, evening * 0.12, Color("#ffda9e"))

    # Narrow, moving sunlight on the timber floor; no furniture displacement.
    var sun: float = 1.0 - evening
    var beam := Color("#ffe7ad")
    beam.a = sun * 0.033
    var beam_shift: float = sin(t * 0.34) * 5.0 if motion_enabled else 0.0
    var shafts := PackedVector2Array([
        Vector2(233.0 + beam_shift, 370.0), Vector2(326.0 + beam_shift, 370.0),
        Vector2(432.0 + beam_shift, 767.0), Vector2(360.0 + beam_shift, 767.0)
    ])
    draw_colored_polygon(shafts, beam)

    # Houseplants cast a barely visible moving shadow in the warm lamp pool.
    var sw: float = sin(t * 0.48) * 5.0 if motion_enabled else 0.0
    _oval(Vector2(1275.0 + sw, 855.0), Vector2(19.0, 5.0), Color(0.12, 0.20, 0.14, 0.07))
    # Dust motes are not resident sprites and do not pass through the UI.
    if motion_enabled:
        for i in range(9):
            var drift: float = fposmod(t * (3.4 + float(i % 4)) + float(i * 47), 490.0)
            var xx: float = 220.0 + float(i * 83 % 390) + sin(t * 0.5 + i) * 12.0
            var yy: float = 660.0 - drift
            var light := Color("#fff3d2")
            light.a = (0.08 + 0.09 * evening) * maxf(0.0, sin(PI * drift / 490.0))
            draw_circle(Vector2(xx, yy), 2.0, light)

func _draw_yard() -> void:
    var t: float = clock
    var evening: float = twilight
    var wind: float = sin(t * 0.73) * 0.62 + sin(t * 0.31) * 0.38

    # Leaf-shadow parallax responds to the same wind as the selective
    # foliage shader, while roots, stone table and collision positions stay put.
    for i in range(12):
        var cx: float = 293.0 + float(i * 43 % 330)
        var cy: float = 445.0 + float(i * 41 % 182)
        var shift: float = wind * (3.0 + float(i % 4) * 2.5)
        _oval(Vector2(cx + shift, cy), Vector2(13.0 + float(i % 3) * 7.0, 3.0 + float(i % 2) * 2.0), Color(0.13, 0.29, 0.18, 0.025))

    # Warm lights do not appear uniformly: intensity rises smoothly at dusk.
    for i in range(LAMP_ANCHORS.size()):
        var lamp: Vector3 = LAMP_ANCHORS[i]
        var flicker: float = 1.0 + sin(t * 1.19 + float(i) * 1.61) * 0.038
        var strength: float = (0.055 + evening * 0.38) * flicker
        var sway: float = sin(t * 0.61) * 2.4 if i == 0 and motion_enabled else 0.0
        _halo(Vector2(lamp.x + sway, lamp.y), lamp.z * (1.0 + evening * 0.45), strength, Color("#ffd69b"))
    # Firefly glints become visible only at dusk and avoid overwhelming the yard.
    if evening > 0.17 and motion_enabled:
        for i in range(7):
            var flick: float = maxf(0.0, sin(t * (1.1 + float(i) * 0.09) + float(i) * 2.3))
            var pos := Vector2(310.0 + float(i * 141 % 1000) + sin(t * 0.43 + i) * 8.0, 440.0 + float(i * 67 % 337) + sin(t * 0.37 + i) * 7.0)
            _halo(pos, 17.0, evening * flick * 0.12, Color("#fff1af"))

    # Uneven, layered smoke streams from the EXISTING chimney. Compact pixel
    # puffs are shaded and decay; no huge featureless translucent circles.
    if motion_enabled:
        for i in range(10):
            var age: float = fposmod(t * (0.135 + float(i % 3) * 0.008) + float(i) / 10.0, 1.0)
            var centre := Vector2(1149.0 + age * 35.0 + sin(t * 0.42 + i) * 6.0, 117.0 - age * 151.0)
            var opacity: float = maxf(0.0, 1.0 - age) * 0.22
            var puff := Color("#f2e8e5")
            puff.a = opacity
            _oval(centre, Vector2(9.0 + age * 9.0, 7.0 + age * 10.0), puff)
            _oval(centre + Vector2(-5.0, 2.0), Vector2(6.0 + age * 5.0, 6.0 + age * 4.0), Color(0.64, 0.64, 0.75, opacity * 0.34))

        # Falling leaves vary in position, speed and spin. Tiny overlapping
        # square pixels keep the familiar chunky illustrated art direction.
        for i in range(LEAF_COUNT):
            var life: float = fposmod(t * (8.0 + float(i % 7) * 3.0) + float(i * 107), 770.0) / 770.0
            var px: float = 190.0 + float(i * 137 % 540) + sin(t * 0.64 + float(i) * 2.17) * (10.0 + float(i % 4) * 3.0) + life * 55.0
            var py: float = 37.0 + life * 731.0
            var leaf := Color("#dbe689") if i % 5 != 0 else Color("#efabcb")
            leaf.a = minf(minf(life * 8.0, (1.0 - life) * 7.0), 1.0) * 0.73
            draw_rect(Rect2(px, py, 3.0 + float(i % 3), 3.0), leaf)

    # Water is independently alive while dock, boats and shoreline are static.
    # These hand-audited windows avoid drawing over the cliff edge or garden.
    if motion_enabled:
        for i in range(26):
            var rx: float = 13.0 + float(i * 67 % 343)
            var ry: float = 374.0 + float(i * 127 % 639)
            var safe: bool = (rx < 100.0 and ry > 410.0) or (rx < 190.0 and ry > 875.0) or (rx < 350.0 and ry > 1004.0)
            if not safe:
                continue
            var ripple := Color("#b8e4f3") if evening < 0.5 else Color("#eac6df")
            ripple.a = 0.13 + (sin(t * 0.95 + i) + 1.0) * 0.045
            var wobble: float = sin(t * 0.65 + float(i) * 1.3) * 5.0
            draw_line(Vector2(rx + wobble, ry), Vector2(rx + 14.0 + wobble, ry), ripple, 2.0)

    # Soft distant mountain-to-sky colour changes are done in the art shader.
    # Do not draw a full-screen dark rectangle: V4 dusk looked like a filter.