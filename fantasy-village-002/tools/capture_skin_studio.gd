extends SceneTree
var studio
func _init() -> void:call_deferred("run")
func shot(name: String) -> void:
	for i in range(6):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/puppet/previews/"+name+".png")
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,800);DisplayServer.window_set_size(root.size)
	var app=load("res://scripts/app.gd").new();app._setup_theme()
	studio=load("res://scripts/ui/resident_skin_studio.gd").new();studio.theme=app.theme;app.free();root.add_child(studio)
	studio.load_path("res://skins/moon");studio.selected_action="read";studio.choose_action(true);studio.stage.zoom=8;studio.zoom_select.select(3);studio.stage.bounds=true;studio.stage.joints=true;studio.stage.grid=true;studio.center_preview()
	await shot("D-studio-landscape")
	studio.controls_scroll.scroll_vertical=1200;await shot("D-import-export")
	root.size=Vector2i(360,800);DisplayServer.window_set_size(root.size);studio.size=Vector2(360,800);studio.stage.zoom=4;studio.zoom_select.select(2);studio.stage.grid=false;studio.stage.joints=false;studio.stage.bounds=false;studio.controls_scroll.scroll_vertical=0;studio.layout()
	await shot("D-studio-portrait")
	quit()
