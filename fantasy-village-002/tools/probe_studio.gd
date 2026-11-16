extends SceneTree
func _init() -> void:call_deferred("run")
func run() -> void:
	var app=load("res://scripts/app.gd").new();app._setup_theme()
	var studio=load("res://scripts/ui/resident_skin_studio.gd").new();studio.theme=app.theme;app.free();root.add_child(studio)
	await process_frame
	print("STUDIO READY ",studio.skin.get("root","FAILED"));studio.queue_free();await process_frame;quit()
