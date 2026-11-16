extends SceneTree
const State = preload("res://scripts/state/app_state.gd")
const Home = preload("res://scripts/world/home_plot.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+label)
	else:print("PASS: "+label)
func _init() -> void:call_deferred("run")
func run() -> void:
	var state := State.new()
	state.create_identity("回归测试")
	var home := Home.new()
	home.setup(state)
	root.add_child(home)
	await process_frame
	home.set_process(false)
	check(home.presentation.z_index>=10,"Ground stays above UI panel in nested community view")
	check(home.presentation.exterior.get_child(0) is TileMapLayer,"Outdoor uses TileMapLayer")
	check(home.presentation.interior.get_child(0) is TileMapLayer,"Indoor has independent TileMapLayer")
	check(home.get_obstacles("inside").size()>=5,"Indoor furniture has collision footprints")
	check(not home.owner_resident.set_destination(Vector2(65,228),home.get_obstacles(),home.bounds("outside")),"Pond rejects movement destination")
	home.owner_resident.region="inside"
	home.owner_resident.position=Vector2(104,152)
	check(not home.owner_resident.set_destination(Vector2(45,65),home.get_obstacles("inside"),home.bounds("inside")),"Bed rejects walking through furniture")
	check(home.owner_resident.set_destination(Vector2(88,120),home.get_obstacles("inside"),home.bounds("inside")),"Indoor route reaches bed approach")
	var indoor_safe := true
	for i in range(180):
		home.owner_resident.tick(1.0/60)
		for obstacle: Rect2 in home.get_obstacles("inside"):
			if obstacle.has_point(home.owner_resident.position):indoor_safe=false
	check(indoor_safe,"Entire indoor walk stays outside furniture")
	home.owner_resident.region="outside"
	home.owner_resident.position=Vector2(232,184)
	home.owner_resident.moving=false
	home.owner_resident.waypoints.clear()
	check(home.move_owner_through_door(),"Owner can path to outdoor door")
	for i in range(600):home._process(1.0/60)
	check(home.owner_resident.region=="inside" and home.interior_visible,"Owner crosses door and observes indoor view")
	check(home.move_owner_through_door(),"Owner can path to indoor door")
	for i in range(600):home._process(1.0/60)
	check(home.owner_resident.region=="outside" and not home.interior_visible,"Owner leaves room via doorway")
	var initial: Vector2=home.bound.position
	var initial_region: String=home.bound.region
	home.enter_house()
	home.exit_house()
	check(home.bound.position==initial and home.bound.region==initial_region,"Observer view changes do not teleport AI")
	var old_target: Vector2=home.bound.target
	home.move_owner_to(Vector2(296,248))
	check(home.bound.target==old_target,"Owner movement never changes AI destination")
	var seen := {}
	var inside_seen := false
	var continuity := true
	var walk_safe := true
	var living := {}
	for i in range(10800):
		home._process(1.0/60)
		seen[home.get_bound_action()]=true
		living[home.bound.region+":"+home.phase]=true
		if home.bound.region=="inside":
			inside_seen=true
			var pos: Vector2=home.bound.position
			var action: String=home.get_bound_action()
			home.enter_house();home.exit_house()
			continuity=continuity and home.bound.position==pos and home.get_bound_action()==action
		if home.bound.moving:
			for obstacle: Rect2 in home.get_obstacles(home.bound.region):
				if obstacle.grow(home.bound.FOOT_RADIUS).has_point(home.bound.position):walk_safe=false
	for action in ["sit","read","rest","enter","exit","interact"]:check(seen.has(action),"Controller reaches "+action)
	check(inside_seen,"AI actually enters independent indoor region")
	check(continuity,"Observer switching preserves current indoor action and position")
	check(walk_safe,"AI walks around pond and furniture in both regions")
	check(living.has("inside:hold") and living.has("outside:hold"),"Life activities execute in both regions")
	home.enter_house();home._sync()
	var actor: AnimatedSprite2D=home.presentation.actors.bound
	check(actor.get_parent()==home.presentation.interior if home.bound.region=="inside" else actor.get_parent()==home.presentation.exterior,"Sprite parent follows physical region")
	for direction in range(4):
		check(home.presentation.frames.get_frame_count("walk_%d"%direction)==6,"Six native walking frames direction %d"%direction)
		check(home.presentation.frames.get_frame_count("idle_%d"%direction)==2,"Idle/blink frames direction %d"%direction)
	for motion in ["read","rest","sit_down","stand_up","tea"]:
		check(home.presentation.frames.get_frame_count(motion)>=3,"Reusable visible frames for "+motion)
	var f: SpriteFrames=home.presentation.frames
	check(f.get_frame_texture("read",0).get_image().get_data()!=f.get_frame_texture("read",1).get_image().get_data(),"Reading actually changes page pixels")
	check(f.get_frame_texture("rest",0).get_image().get_data()!=f.get_frame_texture("rest",2).get_image().get_data(),"Rest has visible breathing frames")
	home.release_affordance("bench",home.bound.uuid)
	check(home.reserve_affordance("bench",home.bound.uuid),"Facility reservation succeeds")
	check(not home.reserve_affordance("bench","forged-resident"),"Another identity cannot take occupied facility")
	home.release_affordance("bench",home.bound.uuid)
	check(home.get_affordance("bench").occupied_by=="","Facility releases after use")
	home._finish_action()
	home.get_affordance("bench").occupied_by="another-local-actor"
	var before: Vector2=home.bound.position
	home._begin_intent({"affordance":"bench","action":"sit"})
	check(home._pending.is_empty() and home._active.is_empty() and home.bound.position==before,"Occupied facility is skipped without teleporting or stealing")
	home.get_affordance("bench").occupied_by=""
	var registry=home.registry
	var target: Dictionary=registry.query_public_plots()[1]
	check(not registry.request_visit("",target.plot_uuid).ok,"Empty requesting identity rejected")
	check(not registry.request_visit(target.resident_uuid,target.plot_uuid).ok,"Forged neighbor request rejected")
	var request: Dictionary=registry.request_visit(home.bound.uuid,target.plot_uuid)
	check(request.ok,"Authenticated resident can request a visit")
	check(registry.request_visit(home.bound.uuid,target.plot_uuid).request.id==request.request.id,"Duplicate pending visit is idempotent")
	check(not registry.respond_visit(request.request.id,target.resident_uuid,true).ok,"Target UUID alone cannot impersonate authenticated owner")
	var own: Dictionary=registry.find_home()
	var own_request: Dictionary=registry.request_visit(home.bound.uuid,own.plot_uuid)
	check(registry.respond_visit(own_request.request.id,state.account.uuid,true).ok,"Authenticated owner can approve owned land")
	check(not registry.respond_visit(own_request.request.id,state.account.uuid,false).ok,"Resolved approval cannot be changed a second time")
	var public_plot: Dictionary=registry.get_public_plot(own.plot_uuid)
	check(not public_plot.has("private_chat") and not public_plot.has("memory"),"Public view contains no chat or memory")
	var community = load("res://scripts/ui/community_screen.gd").new()
	community.setup(state);root.add_child(community)
	for dimensions in [Vector2(360,800),Vector2(480,800),Vector2(844,390)]:
		community.size=dimensions;community._layout()
		var shown: Vector2=community.HOME_SIZE * community.home.scale
		check(shown.x<=community.map_clip.size.x+.01 and shown.y<=community.map_clip.size.y+.01,"Full plot fits viewport %s"%dimensions)
	community.queue_free()
	home.queue_free();await process_frame
	print("RESULT: %d/%d home v3 checks passed"%[checks-failures,checks])
	quit(0 if failures==0 else 1)
