extends SceneTree
const Studio=preload("res://scripts/ui/resident_skin_studio.gd")
const Lib=preload("res://scripts/puppet/library.gd")
var checks=0;var failures=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
	else:print("PASS: "+label)
func _init() -> void:call_deferred("run")
func run() -> void:
	var studio=Studio.new();root.add_child(studio);await process_frame
	studio.store=load("res://scripts/puppet/store.gd").new("user://studio-test-"+str(Time.get_ticks_usec()))
	for size in [Vector2i(480,800),Vector2i(844,390),Vector2i(360,800)]:
		root.size=size;studio.size=size;studio.layout();await process_frame
		check(studio.grid.columns==(2 if size.x>=720 else 1),"Responsive studio columns "+str(size))
		check(studio.preview_scroll.size.y>=275,"Preview remains large enough for touch")
	studio.selected_action="walk";studio.choose_action();studio.stage.puppet.advance(.3);var f=studio.stage.puppet.frame
	studio.stage.puppet.playing=false;studio.stage.puppet.advance(1);check(studio.stage.puppet.frame==f,"Pause holds actual shared player")
	studio.step(1);check(not studio.stage.puppet.playing and studio.stage.puppet.frame==f+1,"Frame forward")
	studio.step(-1);check(studio.stage.puppet.frame==f,"Frame backward")
	for dir in Lib.rig().directions:
		studio.selected_direction=dir;studio.choose_action();check(studio.stage.puppet.direction==dir,"Direction uses native independent parts")
	studio.selected_action="read";studio.selected_direction="back";studio.choose_action();check(not studio.stage.puppet.visible,"Unsupported direction hides actor instead of wrong-facing fallback")
	studio.selected_action="dance";studio.choose_action();check(not studio.stage.puppet.visible,"P1 is not fake playback")
	studio.selected_action="idle";studio.selected_direction="front";studio.choose_action()
	studio.new_skin();check(studio.skin.root.begins_with("user://"),"New skin is editable draft, not hardcoded actor")
	var imported_id=studio.skin.manifest.skin_id;studio.review.button_pressed=true;studio.export_current("skin")
	var path="user://studio_exports/"+imported_id+"-skin.zip";check(FileAccess.file_exists(path),"UI export creates real package")
	var clean=load("res://scripts/puppet/store.gd").new(studio.store.base+"-clean");studio.accept_import(clean.import_zip(FileAccess.get_file_as_bytes(path)))
	check(studio.skin.manifest.skin_id==imported_id,"UI accepts clean imported skin")
	var applied=[];studio.skin_applied.connect(func(p):applied.append(p));studio.apply_skin();check(applied.size()==1,"Imported new skin reaches apply signal")
	studio.queue_free();await process_frame;print("RESULT: %d/%d studio checks passed"%[checks-failures,checks]);quit(0 if failures==0 else 1)
