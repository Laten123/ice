extends SceneTree
func _init():
	var names := ["path-c", "path-n", "path-e", "path-s", "path-w", "path-ne", "path-nw", "path-se", "path-sw", "path-inner-ne", "path-inner-nw", "path-inner-se", "path-inner-sw"]
	var img := Image.create(16 * names.size(), 16, false, Image.FORMAT_RGBA8)
	for i in names.size():
		var p = "res://tiles/tile-" + names[i] + ".png"
		if ResourceLoader.exists(p):
			var t = load(p)
			var im = t.get_image()
			im.convert(Image.FORMAT_RGBA8)
			img.blit_rect(im, Rect2i(0, 0, 16, 16), Vector2i(i * 16, 0))
		else:
			print("MISSING: ", names[i])
	img.save_png("/root/fantasia/atlas_test.png")
	print("ATLAS SAVED size=", img.get_size())
	quit()
