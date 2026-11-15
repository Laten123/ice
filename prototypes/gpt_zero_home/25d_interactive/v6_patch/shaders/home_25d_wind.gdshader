shader_type canvas_item;
// V5: the APPROVED still image remains the only texture source.
// Displace a few pixels INSIDE the leafy crown, never the house/trunk/anchors.
// No separate, complete foreground occlusion or tree rig is claimed.

uniform float wind_time = 0.0;
uniform float wind_on : hint_range(0.0, 1.0) = 1.0;
uniform float twilight : hint_range(0.0, 1.0) = 0.0;
uniform bool is_interior = false;

float ellipse_falloff(vec2 point, vec2 center, vec2 radius) {
    float d = length((point - center) / radius);
    return 1.0 - smoothstep(0.66, 0.94, d);
}

void fragment() {
    vec2 coords = UV / TEXTURE_PIXEL_SIZE;
    vec2 sample_uv = UV;
    vec4 original = texture(TEXTURE, UV);
    if (!is_interior && wind_on > 0.0) {
        // Inner foliage ONLY: deliberately stay away from the crown silhouette,
        // old tree trunk, roof edge and hanging lamp (no double-exposure ghosts).
        float inner_crown = ellipse_falloff(coords, vec2(433.0, 178.0), vec2(223.0, 141.0));
        inner_crown = max(inner_crown, ellipse_falloff(coords, vec2(518.0, 69.0), vec2(161.0, 76.0)));
        float foliage = smoothstep(0.015, 0.18, original.g - original.r);
        foliage *= 1.0 - smoothstep(0.28, 0.48, original.b);
        float wave = sin(wind_time * 0.77 + coords.y * 0.031) * 1.7;
        wave += sin(wind_time * 0.39 - coords.y * 0.018) * 0.65;
        sample_uv.x -= wave * inner_crown * foliage * wind_on * TEXTURE_PIXEL_SIZE.x;
    }
    vec4 scene_color = texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0)));

    // Gradual cool twilight and retained warm timber: a scene-aware colour
    // transform rather than uniformly lowering the whole bitmap's brightness.
    vec3 dusk_rgb = scene_color.rgb;
    if (is_interior) {
        dusk_rgb *= vec3(0.86, 0.81, 0.93);
        dusk_rgb += vec3(0.020, 0.006, 0.015);
    } else {
        dusk_rgb *= vec3(0.80, 0.84, 0.98);
        float is_warm = smoothstep(0.06, 0.21, scene_color.r - scene_color.b);
        dusk_rgb += vec3(0.035, 0.016, 0.006) * is_warm;
        float sky = 1.0 - smoothstep(105.0, 340.0, coords.y);
        dusk_rgb = mix(dusk_rgb, scene_color.rgb * vec3(0.82, 0.81, 1.08), sky * 0.43);
    }
    // Local emissive masks protect actual warm window glass from the blue
    // twilight transform. No whole-house saturation or blanket filter.
    vec2 win1 = (coords - vec2(914.0, 277.0)) / vec2(43.0, 45.0);
    vec2 win2 = (coords - vec2(867.0, 471.0)) / vec2(60.0, 71.0);
    vec2 win3 = (coords - vec2(1205.0, 400.0)) / vec2(69.0, 77.0);
    float exterior_window = max(1.0 - smoothstep(0.75, 0.99, length(win1)),
                                max(1.0 - smoothstep(0.75, 0.99, length(win2)),
                                    1.0 - smoothstep(0.75, 0.99, length(win3))));
    float interior_lamp = ellipse_falloff(coords, vec2(797.0, 210.0), vec2(52.0, 57.0));
    float lit_mask = is_interior ? interior_lamp : exterior_window;
    float ember = smoothstep(0.10, 0.29, scene_color.r - scene_color.b);
    vec3 emissive = min(scene_color.rgb * vec3(1.06, 1.04, 0.96) + vec3(0.045, 0.02, 0.0), vec3(1.0));
    dusk_rgb = mix(dusk_rgb, emissive, lit_mask * ember * 0.88);
    COLOR = vec4(mix(scene_color.rgb, dusk_rgb, twilight), scene_color.a);
}