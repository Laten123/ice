extends SceneTree
const V=preload("res://scripts/puppet/validator.gd")
const P=preload("res://scripts/puppet/player.gd")
func _init() -> void:call_deferred("run")
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(960,560);DisplayServer.window_set_size(root.size)
	for row in range(2):
		var skin=V.load_skin("res://skins/"+["forest","moon"][row]).skin
		for col in range(4):
			var p=P.new();root.add_child(p);p.set_skin(skin);p.select("idle",["front","left","right","back"][col]);p.seek(0);p.scale=Vector2(6,6);p.position=Vector2(120+240*col,230+260*row)
			var l=Label.new();l.text=["forest","moon"][row]+" / "+p.direction;l.position=p.position+Vector2(-70,12);root.add_child(l)
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/puppet/previews/A-native-directions.png")
	quit()
