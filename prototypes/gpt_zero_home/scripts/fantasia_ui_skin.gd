extends RefCounted
## Fantasia original wooden UI skin. It is entirely visual: no AI intent,
## no resident credentials and no changes to the read-only observation API.
## The separate, downloadable ZIP contains the PNGs under art/ui/.

const BASE := "res://art/ui/"

static func has_skin() -> bool:
    return ResourceLoader.exists(BASE + "button_day_normal.png") and ResourceLoader.exists(BASE + "button_dusk_normal.png")

static func _box(path: String) -> StyleBoxTexture:
    var style := StyleBoxTexture.new()
    style.texture = load(BASE + path) as Texture2D
    style.texture_margin_left = 26.0
    style.texture_margin_right = 26.0
    style.texture_margin_top = 18.0
    style.texture_margin_bottom = 18.0
    style.content_margin_left = 12.0
    style.content_margin_right = 12.0
    style.content_margin_top = 9.0
    style.content_margin_bottom = 9.0
    return style

static func skin_button(button: Button, family: String) -> void:
    if not has_skin():
        return
    for state in ["normal", "hover", "pressed", "disabled"]:
        var tex_path: String = "button_%s_%s.png" % [family, state]
        if ResourceLoader.exists(BASE + tex_path):
            button.add_theme_stylebox_override(state, _box(tex_path))
    var focus_path: String = "button_%s_hover.png" % family
    if ResourceLoader.exists(BASE + focus_path):
        button.add_theme_stylebox_override("focus", _box(focus_path))
    button.add_theme_color_override("font_color", Color("#fff2d2"))
    button.add_theme_color_override("font_hover_color", Color("#ffffff"))
    button.add_theme_color_override("font_pressed_color", Color("#fff4da"))
    button.add_theme_color_override("font_disabled_color", Color("#c1afa1"))
    button.add_theme_color_override("font_outline_color", Color("#452b28"))
    button.add_theme_constant_override("outline_size", 2)

static func skin_title(header: PanelContainer) -> void:
    var title_texture := BASE + "title_floral.png"
    if not ResourceLoader.exists(title_texture):
        return
    var skin := StyleBoxTexture.new()
    skin.texture = load(title_texture) as Texture2D
    skin.texture_margin_left = 45.0
    skin.texture_margin_right = 45.0
    skin.texture_margin_top = 23.0
    skin.texture_margin_bottom = 23.0
    skin.content_margin_left = 14.0
    skin.content_margin_right = 14.0
    skin.content_margin_top = 10.0
    skin.content_margin_bottom = 10.0
    header.add_theme_stylebox_override("panel", skin)

static func install(day_button: Button, dusk_button: Button) -> void:
    skin_button(day_button, "day")
    skin_button(dusk_button, "dusk")
