class_name FvHomePlot
extends Node2D
## Capability executor. Controller chooses intent; presentation only reads actor state.
signal resident_inspected(info: Dictionary)
signal resident_status_changed()
signal notice(text: String)
signal interior_changed(is_open: bool)
const Data = preload("res://data/home_data.gd")
const Agent = preload("res://scripts/world/resident_agent.gd")
const Action = preload("res://scripts/world/resident_action_state.gd")
const Controller = preload("res://scripts/world/resident_controller.gd")
const MockController = preload("res://scripts/world/mock_life_controller.gd")
const Registry = preload("res://scripts/world/plot_registry.gd")
const Presentation = preload("res://scripts/world/home_presentation.gd")
const SIZE := Vector2(416,272)
var state = null
var props: Array[Dictionary] = []
var affordances: Array[Dictionary] = []
var owner_resident: Agent
var bound: Agent
var owner_action: Action
var bound_action: Action
var controller: Controller
var registry
var font: Font
var interior_visible := false # Observer view, never the AI's physical region.
var presentation: Node2D
var phase := "idle"
var _pending: Dictionary = {}
var _active: Dictionary = {}
var _selected_uuid := ""
var _elapsed := 0.0
var _origin := Vector2.ZERO
var _wait := 0.0
var _owner_portal: Dictionary = {}

func setup(app_state) -> void:
	state = app_state

func _ready() -> void:
	_build_world()
	presentation = Presentation.new()
	add_child(presentation)
	_sync()

func _process(delta: float) -> void:
	owner_resident.tick(delta)
	_tick_owner_portal(delta)
	if owner_action.current == Action.WALK and not owner_resident.moving:owner_action.reset()
	bound.tick(delta)
	_tick_bound(delta)
	_sync()

func _sync() -> void:
	if not is_instance_valid(presentation):return
	presentation.set_view(interior_visible)
	var motion := "idle_%d" % bound.facing
	if bound.moving:motion = "walk_%d" % bound.facing
	elif phase == "lower":motion = "rest" if bound_action.current == Action.REST else "sit_down"
	elif phase in ["open_book","close_book"]:motion = phase
	elif phase == "rise":motion = "rest" if bound_action.current == Action.REST else "stand_up"
	elif phase == "hold" and _active.get("action", "") != "observe":
		motion = "rest" if bound_action.current == Action.REST else ("tea" if bound_action.current == Action.INTERACT else "read")
	elif phase in ["approach_seat","leave_seat","portal"]:motion = "walk_%d" % bound.facing
	presentation.sync_actor("bound",bound.region,bound.position,motion,bound.color)
	presentation.sync_actor("owner",owner_resident.region,owner_resident.position,"walk_%d"%owner_resident.facing if owner_resident.moving or not _owner_portal.is_empty() else "idle_%d"%owner_resident.facing,owner_resident.color)

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_handle_pointer(get_global_transform_with_canvas().affine_inverse()*event.position)

func _handle_pointer(point: Vector2) -> void:
	if not Rect2(Vector2.ZERO,SIZE).has_point(point):return
	get_viewport().set_input_as_handled()
	var region := "inside" if interior_visible else "outside"
	var local := point - Vector2(96,48) if interior_visible else point
	for agent: Agent in [owner_resident,bound]:
		if agent.region == region and Rect2(agent.position-Vector2(10,24),Vector2(20,28)).has_point(local):
			_selected_uuid = agent.uuid
			resident_inspected.emit(get_resident_info(agent.uuid))
			return
	if interior_visible and Rect2(96,153,32,23).has_point(local):
		if owner_resident.region == "inside":move_owner_through_door()
		else:exit_house()
		return
	if not interior_visible and Rect2(184,113,40,33).has_point(local):
		move_owner_through_door()
		return
	for prop: Dictionary in props:
		if prop.get("region","outside") == region and (prop.get("hit_rect",prop.get("obstacle",Rect2())) as Rect2).has_point(local):
			notice.emit(str(prop.get("name",prop.id))+"：这是居民可使用的生活设施。")
			return
	move_owner_to(local)

func move_owner_to(point: Vector2) -> bool:
	var region := "inside" if interior_visible else "outside"
	if owner_resident.region != region:
		notice.emit("主人在另一处；通过房门进入或离开。")
		return false
	if not owner_resident.set_destination(point,get_obstacles(region),bounds(region)):return false
	owner_action.begin(Action.WALK)
	return true

func enter_house() -> void:
	# Observer can look inside without teleporting or changing the resident.
	interior_visible = true
	interior_changed.emit(true)
	if presentation != null:presentation.set_view(true)

func exit_house() -> void:
	interior_visible = false
	interior_changed.emit(false)
	if presentation != null:presentation.set_view(false)

func move_owner_through_door() -> bool:
	if not _owner_portal.is_empty():return false
	var approach := Vector2(200,168) if owner_resident.region == "outside" else Vector2(104,152)
	if not owner_resident.set_destination(approach,get_obstacles(owner_resident.region),bounds(owner_resident.region)):return false
	_owner_portal = {"elapsed":0.0,"start":approach}
	owner_action.begin(Action.WALK)
	return true

func _tick_owner_portal(delta: float) -> void:
	if _owner_portal.is_empty() or owner_resident.moving:return
	_owner_portal.elapsed += delta
	var entering := owner_resident.region == "outside"
	owner_action.begin(Action.ENTER if entering else Action.EXIT)
	owner_resident.facing = 3 if entering else 0
	owner_resident.position = (_owner_portal.start as Vector2).lerp(Vector2(200,136) if entering else Vector2(104,168),minf(_owner_portal.elapsed/.8,1))
	if _owner_portal.elapsed >= .8:
		owner_resident.region = "inside" if entering else "outside"
		owner_resident.position = Vector2(104,152) if entering else Vector2(200,168)
		_owner_portal = {}
		owner_action.reset()
		if entering:enter_house()
		else:exit_house()

func set_bound_color(color: Color) -> void:
	bound.color = color
	_sync()
func get_residents() -> Array:
	return [get_owner_info(),get_bound_info()]
func get_owner_info() -> Dictionary:
	return _info_for(owner_resident,"主人",false,owner_action)
func get_bound_info() -> Dictionary:
	return _info_for(bound,"绑定模型",true,bound_action)
func get_resident_info(uuid: String) -> Dictionary:
	if owner_resident.uuid == uuid:return get_owner_info()
	if bound.uuid == uuid:return get_bound_info()
	return {}
func is_interior_visible() -> bool:
	return interior_visible
func get_bound_action() -> String:
	return bound_action.current
func bounds(region: String) -> Rect2:
	return Data.INTERIOR_BOUNDS if region == "inside" else Data.WALK_BOUNDS
func get_obstacles(region: String = "outside") -> Array[Rect2]:
	var result: Array[Rect2] = []
	for prop: Dictionary in props:
		if prop.get("region","outside") == region and prop.has("obstacle"):result.append(prop.obstacle)
	return result
func get_affordance(id: String) -> Dictionary:
	for f: Dictionary in affordances:
		if f.id == id:return f
	return {}
func can_reserve_affordance(id: String, uuid: String) -> bool:
	var f := get_affordance(id)
	return not f.is_empty() and bool(f.get("enabled",false)) and (str(f.get("occupied_by","")) in ["",uuid])
func reserve_affordance(id: String, uuid: String) -> bool:
	if uuid != bound.uuid or not can_reserve_affordance(id,uuid):return false
	get_affordance(id)["occupied_by"] = uuid
	return true
func release_affordance(id: String, uuid: String) -> void:
	var f := get_affordance(id)
	if not f.is_empty() and f.get("occupied_by","") == uuid:f["occupied_by"] = ""

func _tick_bound(delta: float) -> void:
	if _wait > 0:
		_wait -= delta
		return
	if not _active.is_empty():
		_elapsed += delta
		var f := get_affordance(str(_active.affordance))
		var duration := float(_active.get("duration",3.0))
		match phase:
			"portal":
				bound.position = _origin.lerp(Vector2(200,136) if bound.region == "outside" else Vector2(104,168),minf(_elapsed/.8,1))
				if _elapsed >= .8:
					bound.region = "inside" if bound.region == "outside" else "outside"
					bound.position = Vector2(104,152) if bound.region == "inside" else Vector2(200,168)
					_finish_action()
			"approach_seat":
				bound.position = _origin.lerp(f.position,minf(_elapsed/.75,1))
				if _elapsed >= .75:_phase("lower")
			"lower":
				if _elapsed >= .5:
					if bound_action.current == Action.SIT:bound_action.begin(Action.READ,f.id,duration)
					_phase("open_book" if bound_action.current in [Action.READ,Action.SIT] else "hold")
			"open_book":
				if _elapsed >= .5:_phase("hold")
			"close_book":
				if _elapsed >= .5:_phase("rise")
			"hold":
				if _elapsed >= duration:_phase("close_book" if bound_action.current == Action.READ else "rise")
			"rise":
				if _elapsed >= .5:_phase("leave_seat")
			"leave_seat":
				bound.position = _origin.lerp(f.approach,minf(_elapsed/.75,1))
				if _elapsed >= .75:_finish_action()
		return
	if not _pending.is_empty():
		if not bound.moving:_start_action(_pending)
		return
	if bound.moving:return
	var intent: Dictionary = controller.decide({"busy":false,"state":bound_action.current,"interior":bound.region=="inside","resident_uuid":bound.uuid})
	if not intent.is_empty():_begin_intent(intent)

func _begin_intent(intent: Dictionary) -> void:
	var f := get_affordance(str(intent.get("affordance","")))
	if f.is_empty() or not reserve_affordance(f.id,bound.uuid):
		_wait = .5
		return
	var action := str(intent.get("action","interact"))
	var region := "inside" if action == "exit" else str(f.region)
	if region != bound.region:
		release_affordance(f.id,bound.uuid)
		_wait = .5
		return
	var destination: Vector2 = Vector2(104,152) if action == "exit" else f.approach
	_pending = intent.duplicate(true)
	if bound.position.distance_to(destination) < 1:
		_start_action(_pending)
	elif bound.set_destination(destination,get_obstacles(bound.region),bounds(bound.region)):
		bound_action.begin(Action.WALK,f.id)
	else:
		_pending = {}
		release_affordance(f.id,bound.uuid)
		_wait = .5

func _phase(next: String) -> void:
	phase = next
	_elapsed = 0
	_origin = bound.position

func _start_action(intent: Dictionary) -> void:
	_active = intent.duplicate(true)
	_pending = {}
	var f := get_affordance(str(intent.affordance))
	var action := str(intent.get("action","interact"))
	bound_action.begin(Action.INTERACT if action == "observe" else action,f.id,float(intent.get("duration",3)))
	bound.facing = 3 if action == "enter" else 0
	if action in ["enter","exit"]:_phase("portal")
	elif action == "observe":_phase("hold")
	else:_phase("approach_seat")
	resident_status_changed.emit()

func _finish_action() -> void:
	release_affordance(bound_action.affordance_id,bound.uuid)
	bound_action.reset()
	_active = {}
	_pending = {}
	_phase("idle")
	resident_status_changed.emit()
func _build_world() -> void:
	props = Data.props()
	affordances = Data.affordances()
	for affordance: Dictionary in affordances:
		affordance["occupied_by"] = ""
		affordance["enabled"] = true
	owner_resident = Agent.new()
	owner_resident.configure({
		"id": "owner", "uuid": state.account.uuid,
		"name": state.account.display_name, "role": "主人",
		"description": "家园的主人。", "position": Data.OWNER_START,
		"color": Color("eaa76b"), "status": "online", "autonomous": false,
	})
	bound = Agent.new()
	bound.configure({
		"id": "bound_ai", "uuid": state.bound_resident.uuid,
		"model_uuid": state.bound_resident.model.model_uuid,
		"model_name": state.bound_resident.model.display_name,
		"name": state.bound_resident.display_name, "role": "绑定模型",
		"description": "和你绑定的 AI 居民。", "position": Data.BOUND_START,
		"color": Color("84aeda"), "status": "online", "autonomous": true,
	})
	owner_action = Action.new()
	bound_action = Action.new()
	controller = MockController.new()
	registry = Registry.new(state)


func _info_for(agent: Agent, role: String, is_bound: bool, action: Action) -> Dictionary:
	return {
		"id": agent.id,
		"region": agent.region,
		"phase": phase,
		"name": agent.display_name,
		"kind": "resident",
		"role": role,
		"description": agent.description,
		"uuid": agent.uuid,
		"model_uuid": agent.model_uuid,
		"model_name": agent.model_name,
		"bound": is_bound,
		"presence": agent.status,
		"status": action.current,
		"action": action.current,
		"position": agent.position,
		"color": agent.color,
	}
