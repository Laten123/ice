extends SceneTree
const State = preload("res://scripts/state/app_state.gd")
const Home = preload("res://scripts/world/home_plot.gd")
const Community = preload("res://scripts/ui/community_screen.gd")
var home: Node2D
var manifest: Array = []
var out := "res://docs/round3/previews/"
func _init() -> void:call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var err := image.save_png(out+name+".png")
	assert(err==OK)
	manifest.append({"image":name+".png","region":home.bound.region if is_instance_valid(home) else "ui","action":home.get_bound_action() if is_instance_valid(home) else "ui","phase":home.phase if is_instance_valid(home) else "ui","observer_inside":home.interior_visible if is_instance_valid(home) else false})
	print("CAPTURE "+name)
func seek(action: String, region: String, wanted_phase: String="hold") -> bool:
	for i in range(18000):
		home._process(1.0/30)
		if home.get_bound_action()==action and home.bound.region==region and home.phase==wanted_phase:return true
	return false
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.content_scale_size=Vector2i.ZERO
	DisplayServer.window_set_size(Vector2i(1248,816))
	root.size=Vector2i(1248,816)
	var state := State.new()
	state.create_identity("林间")
	home=Home.new();home.setup(state);root.add_child(home);home.scale=Vector2(3,3);home.set_process(false)
	await process_frame
	await capture("outdoor")
	assert(seek("read","outside"));await capture("outdoor-reading")
	assert(seek("enter","outside","portal"));await capture("enter-house")
	for i in range(18):
		home._process(.1)
		if home.bound.region=="inside":home.enter_house()
		await create_timer(.1).timeout;await capture("entering-%03d"%i)
	assert(seek("read","inside"));home.enter_house();await capture("indoor-reading")
	for i in range(25):
		home._process(.1);await create_timer(.1).timeout;await capture("reading-%03d"%i)
	assert(seek("rest","inside"));await capture("indoor-rest")
	for i in range(25):
		home._process(.1);await create_timer(.1).timeout;await capture("resting-%03d"%i)
	assert(seek("interact","inside"));await capture("indoor-tea")
	assert(seek("exit","inside","portal"));await capture("exit-house")
	for i in range(18):
		home._process(.1)
		if home.bound.region=="outside":home.exit_house()
		await create_timer(.1).timeout;await capture("leaving-%03d"%i)
	home.exit_house();home.presentation.clock=25;await process_frame;await capture("night")
	home.presentation.clock=0
	home.exit_house()
	# Real renderer playback, not a composited or interpolated source GIF.
	for i in range(40):
		home._process(.1)
		await create_timer(.1).timeout
		await capture("animation-%03d"%i)
	home.queue_free();await process_frame
	var community := Community.new();community.setup(state)
	var app = load("res://scripts/app.gd").new();app._setup_theme();community.theme=app.theme;app.free()
	root.add_child(community)
	DisplayServer.window_set_size(Vector2i(480,800));root.size=Vector2i(480,800);community.size=Vector2(480,800);community._layout()
	await capture("portrait")
	DisplayServer.window_set_size(Vector2i(844,390));root.size=Vector2i(844,390);community.size=Vector2(844,390);community._layout()
	await capture("landscape")
	var file := FileAccess.open(out+"capture-manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t"));file.close()
	quit()
