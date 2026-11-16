extends SceneTree
func _init() -> void: call_deferred("_run")
func _walk(dir: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir)
	if d == null: return
	for f in d.get_files(): out.append(dir.path_join(f))
	for sub in d.get_directories(): _walk(dir.path_join(sub), out)
func _run() -> void:
	var paths: Array[String] = []
	_walk("res://assets/vendor", paths)
	var png_ok := 0; var png_bad := 0; var alpha_png := 0; var audio_ok := 0; var audio_bad := 0
	for path in paths:
		if path.ends_with(".png"):
			var img := Image.new(); var err := img.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
			if err == OK:
				png_ok += 1
				if img.detect_alpha() != Image.ALPHA_NONE: alpha_png += 1
			else:
				png_bad += 1; push_error("PNG failed: " + path)
		elif path.ends_with(".ogg"):
			var stream = AudioStreamOggVorbis.load_from_file(path)
			if stream != null and stream.get_length() > 0.0: audio_ok += 1
			else: audio_bad += 1; push_error("OGG failed: " + path)
	print("ASSET_PROBE png_ok=%d png_bad=%d alpha_png=%d audio_ok=%d audio_bad=%d" % [png_ok, png_bad, alpha_png, audio_ok, audio_bad])
	quit(0 if png_bad == 0 and audio_bad == 0 else 1)
