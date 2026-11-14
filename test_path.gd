extends SceneTree
func _init():
	for n in ["path-c", "path-w", "path-e", "path-n", "path-s", "path-inner-nw"]:
		var p = "res://tiles/tile-" + n + ".png"
		var ex = ResourceLoader.exists(p)
		var t = null
		if ex:
			t = load(p)
		print(n, " exists=", ex, " loaded=", t != null, " size=", (t.get_size() if t else "NULL"))
	quit()
