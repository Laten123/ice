extends SceneTree
const State=preload("res://scripts/state/app_state.gd")
const Community=preload("res://scripts/ui/community_screen.gd")
const Home=preload("res://scripts/world/home_plot.gd")
const Store=preload("res://scripts/puppet/store.gd")
var checks=0;var failures=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
	else:print("PASS: "+label)
func _init() -> void:call_deferred("run")
func run() -> void:
	var state=State.new();state.create_identity("换皮测试");state.save_path="user://skin-home-profile-"+str(Time.get_ticks_usec())+".json";state.save_identity()
	var original=FileAccess.get_file_as_bytes(state.save_path);var uuid=state.bound_resident.uuid;var model=state.bound_resident.model.model_uuid;var land=state.land.uuid
	var community=Community.new();community.setup(state);root.add_child(community);await process_frame
	community.home.set_process(false);community._private_history.append("本地私聊保留测试");var history=community._private_history.duplicate()
	community._on_workshop();await process_frame
	var studio=community.get_node("ResidentSkinStudio")
	studio.store=Store.new("user://resident_skins/home-test-"+str(Time.get_ticks_usec()))
	studio.new_skin();check(studio.skin.root.begins_with("user://"),"New skin created through real studio")
	var id=studio.skin.manifest.skin_id;var package=studio.store.base.path_join("roundtrip.zip")
	check(studio.store.export_skin(studio.skin,package,true).ok,"New draft exports")
	var fresh=Store.new(studio.store.base+"-fresh");studio.accept_import(fresh.import_zip(FileAccess.get_file_as_bytes(package)));check(studio.skin.manifest.skin_id==id,"Clean package accepted by workbench")
	var before_pos=community.home.bound.position;var before_action=community.home.get_bound_action();studio.apply_skin()
	check(community.home.presentation.actors.bound.skin.manifest.skin_id==id,"Imported skin actually applied to home actor")
	check(community.home.bound.position==before_pos and community.home.get_bound_action()==before_action,"Apply preserves resident movement and action state")
	check(state.bound_resident.uuid==uuid and state.bound_resident.model.model_uuid==model and state.land.uuid==land,"UUID, model and land unchanged")
	check(FileAccess.get_file_as_bytes(state.save_path)==original,"Identity save bytes unchanged by skin workflow")
	check(community._private_history==history,"Private chat unchanged while studio is open")
	var reload=Home.new();reload.setup(state);root.add_child(reload);reload.set_process(false)
	check(reload.presentation.actors.bound.skin.manifest.skin_id==id,"Separate appearance binding survives home reload")
	var phases={};var regions={};var compared={}
	for i in range(10000):
		var home=community.home;home._process(1.0/60)
		for actor in home.presentation.actors.values():actor.advance(1.0/60)
		phases[home.phase]=true;regions[home.bound.region]=true
		if home.phase=="hold" and home.bound.region=="inside" and home.get_bound_action() in ["read","rest"]:
			var actor=home.presentation.actors.bound;studio.stage.puppet.select(actor.action_id,actor.direction);studio.stage.puppet.seek(actor.frame)
			check(studio.stage.puppet.current_image().get_data()==actor.current_image().get_data(),"Studio and home render exactly the same "+actor.action_id) if not compared.has(actor.action_id) else null
			compared[actor.action_id]=true
	for phase in ["open_portal","portal","close_portal","take_book","open_book","close_book","put_book","get_up"]:check(phases.has(phase),"Home executes shared stage "+phase)
	check(regions.has("inside") and regions.has("outside"),"Autonomous resident crosses actual regions")
	check(compared.has("read") and compared.has("sleep"),"Both reading and sleeping actually observed in home")
	community.queue_free();reload.queue_free();await process_frame
	print("RESULT: %d/%d skin home checks passed"%[checks-failures,checks]);quit(0 if failures==0 else 1)
