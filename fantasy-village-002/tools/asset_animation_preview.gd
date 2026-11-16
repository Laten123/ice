extends SceneTree
## Renders selected CC0/CC-BY animation frames inside Godot 4.6.3.
## This is a tooling preview, not a game scene and not part of the home code.

const OUT := "/tmp/godot-anim-frames"
var viewport: SubViewport
var anim: AnimatedSprite2D

func _init() -> void:
	call_deferred("_run")

func _load_png(path: String) -> Image:
	var bytes := FileAccess.get_file_as_bytes(path)
	var image := Image.new()
	var err := image.load_png_from_buffer(bytes)
	if err != OK:
		push_error("Cannot load " + path)
	return image

func _texture(image: Image) -> ImageTexture:
	return ImageTexture.create_from_image(image)

func _frames_for_strip(strip: Image, frame_width: int, count: int) -> Array:
	var atlas_tex := _texture(strip)
	var frames := []
	for i in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = atlas_tex
		atlas.region = Rect2(i * frame_width, 0, frame_width, strip.get_height())
		frames.append(atlas)
	return frames

func _frames_for_files(dir_path: String, prefix: String) -> Array:
	var frames := []
	var names: Array = Array(DirAccess.get_files_at(dir_path))
	names.sort_custom(func(a, b): return int(a.get_basename().rsplit("_", true, 1)[-1]) < int(b.get_basename().rsplit("_", true, 1)[-1]))
	for name in names:
		if name.begins_with(prefix) and name.ends_with(".png"):
			frames.append(_texture(_load_png(dir_path.path_join(name))))
	return frames

func _render(name: String, frames: Array, scale_value: float) -> void:
	var sf := SpriteFrames.new()
	sf.set_animation_speed("default", 1.0)
	sf.set_animation_loop("default", true)
	for tex in frames:
		sf.add_frame("default", tex, 1.0)
	anim.sprite_frames = sf
	anim.animation = "default"
	anim.speed_scale = 0.0
	anim.scale = Vector2.ONE * scale_value
	for i in range(frames.size()):
		anim.frame = i
		await process_frame
		await process_frame
		var image := viewport.get_texture().get_image()
		var err := image.save_png(OUT.path_join("%s_%02d.png" % [name, i]))
		if err != OK:
			push_error("save failed " + name)
	print("rendered %s frames=%d" % [name, frames.size()])

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	viewport = SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background := ColorRect.new()
	background.color = Color("2b2926")
	background.size = Vector2(256, 256)
	viewport.add_child(background)
	anim = AnimatedSprite2D.new()
	anim.centered = true
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim.position = Vector2(128, 128)
	viewport.add_child(anim)

	var water := _load_png("res://assets/vendor/animations/animated-flowing-water/water_strip13.png")
	await _render("water", _frames_for_strip(water, 16, 13), 8.0)
	var tree := _load_png("res://assets/vendor/animations/animated-tree-and-water/tree_water_sheet.png")
	var tree_frames := []
	for i in range(3):
		tree_frames.append(_texture(tree.get_region(Rect2i(i * 32, 0, 32, 32))))
	await _render("tree", tree_frames, 6.0)
	await _render("smoke", _frames_for_files("res://assets/vendor/animations/fire-smoke/SmokeLarge_13x1", "Smoke_Large_"), 4.0)
	await _render("fire", _frames_for_files("res://assets/vendor/animations/fire-smoke/FirePlume_17x1", "Fire_Plume_"), 6.0)
	quit(0)
