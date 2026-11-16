extends SceneTree
const V=preload("res://scripts/puppet/validator.gd")
const Stage=preload("res://scripts/puppet/stage.gd")
func _init() -> void:call_deferred("run")
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,640);DisplayServer.window_set_size(root.size)
	for row in range(2):
		var skin=V.load_skin("res://skins/"+["forest","moon"][row]).skin
		for col in range(4):
			var stage=Stage.new();stage.position=Vector2(col*320,row*320);stage.size=Vector2(320,320);stage.zoom=2;root.add_child(stage)
			stage.puppet.set_skin(skin);stage.set_fixture(["bench","desk","bed","door"][col]);stage.puppet.select(["sit_idle","read","sleep","open_door"][col],"front");stage.puppet.seek(3)
			var label=Label.new();label.text=skin.manifest.skin_id+" / "+stage.puppet.action_id;label.position=stage.position+Vector2(10,10);label.modulate=Color("292d35");root.add_child(label)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/puppet/previews/B-shared-fixtures.png");quit()
