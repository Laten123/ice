extends Resource
## Replaceable art contract. Regions are in one unscaled direction frame.
## Animation and resident identity never live in this resource.

@export var atlas: Texture2D
@export var frame_size := Vector2i(24, 32)
@export var directions: Array[String] = ["front", "left", "right", "back"]
@export var pixel_scale := 2.0
@export var skin_color := Color("#e1cea3")
@export var eye_color := Color("#335846")
@export var blink_enabled := true
@export var joint_positions: Dictionary = {
    "pelvis": Vector2.ZERO, "neck": Vector2(0, -12),
    "left_hip": Vector2(-4, -4), "left_knee": Vector2(0, 2),
    "right_hip": Vector2(4, -4), "right_knee": Vector2(0, 2),
    "left_shoulder": Vector2(-7, -11), "left_elbow": Vector2(0, 2),
    "right_shoulder": Vector2(8, -11), "right_elbow": Vector2(0, 2)
}
@export var part_offsets: Dictionary = {
    "head": Vector2(-9, -18), "torso": Vector2(-5, -11),
    "left_upper_arm": Vector2(-2, 0), "left_forearm": Vector2(-2, 0),
    "right_upper_arm": Vector2(-2, 0), "right_forearm": Vector2(-2, 0),
    "left_thigh": Vector2(-2, 0), "left_calf": Vector2(-2, 0),
    "right_thigh": Vector2(-2, 0), "right_calf": Vector2(-2, 0)
}
@export var regions: Dictionary = {
    "head": Rect2(3, 0, 19, 19), "torso": Rect2(7, 19, 11, 8),
    "left_upper_arm": Rect2(3, 19, 4, 2), "left_forearm": Rect2(3, 21, 4, 3),
    "right_upper_arm": Rect2(18, 19, 4, 2), "right_forearm": Rect2(18, 21, 4, 3),
    "left_thigh": Rect2(6, 26, 5, 2), "left_calf": Rect2(6, 28, 5, 2),
    "right_thigh": Rect2(14, 26, 5, 2), "right_calf": Rect2(14, 28, 5, 2)
}

func valid() -> bool:
    if atlas == null or pixel_scale <= 0.0 or frame_size.x <= 0 or frame_size.y <= 0:
        return false
    if directions.size() != 4 or atlas.get_width() < frame_size.x * 4 or atlas.get_height() < frame_size.y:
        return false
    for facing in ["front", "left", "right", "back"]:
        if not directions.has(facing):
            return false
    for joint in ["pelvis", "neck", "left_hip", "left_knee", "right_hip", "right_knee", "left_shoulder", "left_elbow", "right_shoulder", "right_elbow"]:
        if not joint_positions.get(joint) is Vector2:
            return false
    for part in ["head", "torso", "left_upper_arm", "left_forearm", "right_upper_arm", "right_forearm", "left_thigh", "left_calf", "right_thigh", "right_calf"]:
        if not regions.has(part) or not regions[part] is Rect2:
            return false
        if not part_offsets.get(part) is Vector2:
            return false
        var rect: Rect2 = regions[part]
        if not rect.has_area() or not Rect2(Vector2.ZERO, Vector2(frame_size)).encloses(rect):
            return false
    return true

func texture_for(part: String, facing: String) -> AtlasTexture:
    var texture := AtlasTexture.new()
    texture.atlas = atlas
    var region: Rect2 = regions[part]
    region.position.x += maxi(0, directions.find(facing)) * frame_size.x
    texture.region = region
    texture.filter_clip = true
    return texture
