extends Node2D
## Depth-sorted pixel cutouts: the same master pixels can cover an actor.
## Cutouts remain still; no clean plate or moving tree silhouette is claimed.
const DEFINITION_PATH := "res://data/environment_layer_manifest.json"
const SHADER = preload("res://shaders/home_25d_wind.gdshader")

var definitions: Array = []
var occluders: Dictionary = {}
var materials: Array[ShaderMaterial] = []
var water_material: ShaderMaterial
var water_surface: Sprite2D
var current_scene := "exterior"

func _ready() -> void:
    y_sort_enabled = true
    var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DEFINITION_PATH))
    definitions = manifest["occluders"]
    for item in definitions:
        var sprite := Sprite2D.new()
        sprite.name = str(item["id"]).to_pascal_case()
        sprite.texture = load("res://" + str(item["texture"]))
        sprite.centered = false
        sprite.position = Vector2(0, float(item["depth"]))
        var origin := Vector2(item["origin"][0], item["origin"][1])
        sprite.offset = origin - sprite.position
        var mat := ShaderMaterial.new()
        mat.shader = SHADER
        mat.set_shader_parameter("source_origin", origin)
        mat.set_shader_parameter("is_interior", item["scene"] == "interior")
        sprite.material = mat
        # Match base-image filtering to avoid a second sharp edge on the still.
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        materials.append(mat)
        occluders[item["id"]] = sprite
        add_child(sprite)
    water_surface = Sprite2D.new()
    water_surface.name = "IndependentRiverSurface"
    water_surface.centered = false
    water_surface.texture = load("res://" + str(manifest["water_texture"]))
    water_surface.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    water_material = ShaderMaterial.new()
    water_material.shader = SHADER
    water_material.set_shader_parameter("water_only", true)
    water_surface.material = water_material

func configure(scene_id: String) -> void:
    current_scene = scene_id
    for item in definitions:
        occluders[item["id"]].visible = item["scene"] == scene_id
    if water_surface != null:
        water_surface.visible = scene_id == "exterior"

func sync_atmosphere(clock: float, twilight: float, motion: bool) -> void:
    var active: Array[ShaderMaterial] = materials.duplicate()
    active.append(water_material)
    for mat in active:
        mat.set_shader_parameter("wind_time", clock)
        mat.set_shader_parameter("twilight", twilight)
        mat.set_shader_parameter("wind_on", 1.0 if motion else 0.0)
