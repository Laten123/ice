extends SceneTree
const Home=preload("res://scripts/world/home_plot.gd")
const State=preload("res://scripts/state/app_state.gd")
var home
func _init() -> void:call_deferred("run")
func shot(name: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/puppet/previews/"+name+".png")
func seek(action: String,region: String,phase: String="hold") -> bool:
	for i in range(15000):
		home._process(1.0/30)
		if home.get_bound_action()==action and home.bound.region==region and home.phase==phase:return true
	return false
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1248,816);DisplayServer.window_set_size(root.size)
	for name in ["forest","moon"]:
		var state=State.new();state.create_identity("木偶预览");home=Home.new();home.setup(state);root.add_child(home);home.scale=Vector2(3,3);home.set_process(false);home.set_bound_skin("res://skins/"+name,false)
		await shot("E-"+name+"-outdoor")
		assert(seek("read","inside"));home.enter_house();await shot("E-"+name+"-reading")
		assert(seek("rest","inside"));await shot("E-"+name+"-sleep")
		if name=="moon":
			assert(seek("exit","inside","open_portal"))
			for i in range(30):
				home._process(.1)
				if home.bound.region=="outside":home.exit_house()
				await create_timer(.1).timeout;await shot("life-%03d"%i)
		home.queue_free();await process_frame
	quit()
