extends Node2D
## Decorative 2.5D atmosphere, anchored to the approved image-space coordinates.
## No resident commands, pathing, public/secret data, network use or land expansion.
## This V1 animates dappled canopy light, leaves, lanterns, smoke and reflections;
## it does NOT claim to have a separately rigged/physically swaying tree crown.

var current_scene := "exterior"
var dusk := false
var motion_enabled := true
var clock := 0.0
var draw_accum := 0.0

const LEAF_COUNT := 16
const EXTERIOR_LAMPS := [
    Vector3(608.0, 380.0, 77.0),
    Vector3(1080.0, 454.0, 78.0),
    Vector3(1220.0, 673.0, 78.0),
    Vector3(571.0, 542.0, 57.0),
    Vector3(912.0, 280.0, 88.0),
    Vector3(870.0, 474.0, 85.0),
    Vector3(1204.0, 410.0, 88.0)
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
    if not motion_enabled or not visible:
        return
    clock += minf(delta, 0.1)
    draw_accum += delta
    if draw_accum >= 0.05:
        draw_accum = 0.0
        queue_redraw()

func _glow(pos: Vector2, radius: float, amount: float, tint: Color) -> void:
    # Small translucent stepped halos: restrained enough for pixel backgrounds.
    for i in range(5, 0, -1):
        var t := float(i) / 5.0
        var color := tint
        color.a = amount * (1.0 - t + 0.20) * 0.23
        draw_circle(pos, radius * t, color)

func _draw() -> void:
    var t := clock
    if current_scene == "interior":
        if dusk:
            _glow(Vector2(790, 230), 210.0, 0.27 + sin(t * 1.3) * 0.01, Color("#ffd69d"))
            _glow(Vector2(345, 250), 210.0, 0.15, Color("#9db9e0"))
        else:
            _glow(Vector2(797, 240), 110.0, 0.08, Color("#ffe3aa"))
        # A gentle changing plant shadow; furniture and collisions remain fixed.
        var sw := sin(t * 0.5) * 4.0
        draw_rect(Rect2(1273.0 + sw, 850.0, 16.0, 3.0), Color(0.18, 0.30, 0.21, 0.07))
        return

    if dusk:
        # Evening color shift favors sky and open water; warm house light is
        # separate from the blue-violet ambient wash, not one brightness slider.
        for i in range(8):
            var y := float(i) * 33.0
            var shade := Color("#75668b")
            shade.a = 0.045 - float(i) * 0.003
            draw_rect(Rect2(0.0, y, 1536.0, 34.0), shade)
        draw_rect(Rect2(0, 730, 1536, 294), Color(0.17, 0.18, 0.33, 0.075))

    for i in range(EXTERIOR_LAMPS.size()):
        var l: Vector3 = EXTERIOR_LAMPS[i]
        var strength := 0.30 if dusk else 0.065
        strength *= 1.0 + sin(t * 1.45 + float(i) * 1.3) * 0.07
        _glow(Vector2(l.x, l.y), l.z * (1.20 if dusk else 0.85), strength, Color("#ffd18c"))

    # Original chimney's animated smoke trail (image-space coordinates).
    for i in range(8):
        var phase := fposmod(t * 0.19 + float(i) / 8.0, 1.0)
        var smoke_pos := Vector2(1148.0 + phase * 35.0 + sin(t * 0.6 + i) * 6.0, 112.0 - phase * 150.0)
        var smoke_color := Color("#f7e8e4")
        smoke_color.a = (1.0 - phase) * 0.14
        draw_circle(smoke_pos, 7.0 + phase * 17.0, smoke_color)

    # Subtle changing foliage highlights, without moving tree trunk or anchors.
    for i in range(13):
        var x := 235.0 + float(i * 61 % 464) + sin(t * 0.67 + i) * 6.0
        var y := 47.0 + float(i * 53 % 236)
        draw_rect(Rect2(x, y, 5.0 + float(i % 3) * 3.0, 3.0), Color(0.87, 0.87, 0.47, 0.29))

    for i in range(LEAF_COUNT):
        var speed := 10.0 + float(i % 6) * 4.0
        var phase := fposmod(t * speed + float(i * 87), 780.0) / 780.0
        var x := 190.0 + float(i * 131 % 535) + sin(t * 0.65 + float(i) * 2.37) * (11.0 + float(i % 4) * 5.0) + phase * 92.0
        var y := 35.0 + phase * 730.0
        var leaf := Color("#d4db7b") if i % 4 != 0 else Color("#efb1cb")
        leaf.a = minf(1.0, minf(phase * 9.0, (1.0 - phase) * 9.0)) * 0.82
        draw_rect(Rect2(x, y, 4.0, 3.0), leaf)
        draw_rect(Rect2(x + 2.0, y + 2.0, 2.0, 2.0), leaf)

    # Open water only: avoid drawing reflection over stone table / grass.
    for i in range(18):
        var rx := 20.0 + float(i * 73 % 387)
        var ry := 370.0 + float(i * 97 % 615)
        var shoreline_y := 530.0 if rx < 150.0 else (770.0 if rx < 280.0 else 975.0)
        if ry < shoreline_y:
            continue
        var ripple_color := Color("#b6e2f0") if not dusk else Color("#e3c6dc")
        ripple_color.a = 0.19 + sin(t * 0.9 + i) * 0.055
        draw_line(Vector2(rx + sin(t * 0.75 + i) * 5.0, ry), Vector2(rx + 20.0, ry), ripple_color, 2.0)

    if dusk:
        for i in range(6):
            var px := 370.0 + float(i * 191 % 1020) + sin(t * 0.41 + i) * 9.0
            var py := 455.0 + float(i * 83 % 390) + sin(t * 0.55 + i) * 7.0
            var opacity := maxf(0.0, sin(t * (1.25 + i * 0.09) + i)) * 0.12
            _glow(Vector2(px, py), 16.0, opacity, Color("#fff1a2"))