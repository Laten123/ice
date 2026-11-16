class_name PlotRegistry
extends RefCounted
## Local demo land index. Phase C uses the same read APIs for the human map and
## for future AI queries; no private chat, memory or interior data is exposed.

const Access = ["self", "open", "request", "closed"]

var plots: Array[Dictionary] = []
var visit_requests: Array[Dictionary] = []
var _next_request := 1
var _authenticated_owner := ""
var _authenticated_resident := ""


func _init(state = null) -> void:
	plots = _build_demo_plots(state)
	if state != null and state.has_identity():
		_authenticated_owner = state.account.uuid
		_authenticated_resident = state.bound_resident.uuid


func query_public_plots(_requester_uuid: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for plot: Dictionary in plots:
		result.append(_public_copy(plot))
	return result


func get_public_plot(plot_uuid: String) -> Dictionary:
	var plot := find_plot(plot_uuid)
	return _public_copy(plot) if not plot.is_empty() else {}


func find_plot(plot_uuid: String) -> Dictionary:
	for plot: Dictionary in plots:
		if str(plot.get("plot_uuid", "")) == plot_uuid:
			return plot
	return {}


func find_home() -> Dictionary:
	for plot: Dictionary in plots:
		if bool(plot.get("is_home", false)):
			return plot
	return {}


func request_visit(from_resident_uuid: String, plot_uuid: String, message: String = "") -> Dictionary:
	if from_resident_uuid.is_empty() or from_resident_uuid != _authenticated_resident:
		return {"ok":false,"reason":"not_authenticated"}
	for previous: Dictionary in visit_requests:
		if previous.from_resident_uuid == from_resident_uuid and previous.plot_uuid == plot_uuid and previous.status == "pending":
			return {"ok":true,"request":previous.duplicate(true)}
	var plot := find_plot(plot_uuid)
	if plot.is_empty() or str(plot.get("access", "")) == "closed":
		return {"ok": false, "reason": "closed"}
	var request := {
		"id": "visit_%d" % _next_request,
		"from_resident_uuid": from_resident_uuid,
		"plot_uuid": plot_uuid,
		"message": message.strip_edges(),
		"status": "pending",
	}
	_next_request += 1
	visit_requests.append(request)
	return {"ok": true, "request": request.duplicate(true)}


func respond_visit(request_id: String, actor_uuid: String, accept: bool) -> Dictionary:
	for request: Dictionary in visit_requests:
		if str(request.get("id", "")) != request_id:
			continue
		if actor_uuid.is_empty() or actor_uuid not in [_authenticated_owner,_authenticated_resident]:
			return {"ok":false,"reason":"not_authenticated"}
		if str(request.get("status","")) != "pending":
			return {"ok":false,"reason":"already_resolved"}
		var plot := find_plot(str(request.get("plot_uuid", "")))
		if plot.is_empty():
			return {"ok": false, "reason": "missing_plot"}
		if actor_uuid != str(plot.get("resident_uuid", "")) \
				and actor_uuid != str(plot.get("owner_uuid", "")):
			return {"ok": false, "reason": "not_authorized"}
		request["status"] = "accepted" if accept else "declined"
		return {"ok": true, "request": request.duplicate(true)}
	return {"ok": false, "reason": "missing_request"}


func can_enter(plot_uuid: String, resident_uuid: String) -> bool:
	var plot := find_plot(plot_uuid)
	if plot.is_empty():
		return false
	if resident_uuid == str(plot.get("resident_uuid", "")) \
			or resident_uuid == str(plot.get("owner_uuid", "")):
		return true
	match str(plot.get("access", "closed")):
		"open":
			return true
		"request":
			for request: Dictionary in visit_requests:
				if str(request.get("plot_uuid", "")) == plot_uuid \
						and str(request.get("from_resident_uuid", "")) == resident_uuid \
						and str(request.get("status", "")) == "accepted":
					return true
			return false
		_:
			return false


func return_home(resident_uuid: String) -> Dictionary:
	for plot: Dictionary in plots:
		if str(plot.get("resident_uuid", "")) == resident_uuid:
			return {"ok": true, "plot_uuid": str(plot.get("plot_uuid", ""))}
	return {"ok": false, "reason": "no_home"}


func _public_copy(plot: Dictionary) -> Dictionary:
	if plot.is_empty():
		return {}
	var keys := [
		"plot_uuid", "resident_uuid", "model_uuid", "owner_uuid",
		"owner_name", "resident_name", "plot_name", "description",
		"world_position", "access", "thumbnail", "demo", "is_home",
	]
	var copy := {}
	for key: String in keys:
		if plot.has(key):
			copy[key] = plot[key]
	return copy


func _build_demo_plots(state) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if state != null and state.has_identity():
		list.append({
			"plot_uuid": state.land.uuid,
			"resident_uuid": state.bound_resident.uuid,
			"model_uuid": state.bound_resident.model.model_uuid,
			"owner_uuid": state.account.uuid,
			"owner_name": state.account.display_name,
			"resident_name": state.bound_resident.display_name,
			"plot_name": state.land.name,
			"description": "主人与绑定 AI 的独立家园。",
			"world_position": Vector2(800, 600),
			"access": "self",
			"thumbnail": "home",
			"demo": false,
			"is_home": true,
		})
	list.append(_demo_plot("阿澈", "a1b2c3d4-0001-4000-8000-000000000001",
		"b1c2d3e4-0001-4000-8000-000000000011", "c1d2e3f4-0001-4000-8000-000000000021",
		"阿澈的家园", "一栋安静的小屋，院子里有一棵大树。", Vector2(500, 420), "request"))
	list.append(_demo_plot("小满", "a1b2c3d4-0002-4000-8000-000000000002",
		"b1c2d3e4-0002-4000-8000-000000000012", "c1d2e3f4-0002-4000-8000-000000000022",
		"小满的家园", "种了很多花的小院子。", Vector2(1080, 360), "open"))
	list.append(_demo_plot("青禾", "a1b2c3d4-0003-4000-8000-000000000003",
		"b1c2d3e4-0003-4000-8000-000000000013", "c1d2e3f4-0003-4000-8000-000000000023",
		"青禾的家园", "暂时闭门整理中的土地。", Vector2(1180, 760), "closed"))
	list.append(_demo_plot("南枝", "a1b2c3d4-0004-4000-8000-000000000004",
		"b1c2d3e4-0004-4000-8000-000000000014", "c1d2e3f4-0004-4000-8000-000000000024",
		"南枝的家园", "需要先递上拜访请求。", Vector2(560, 920), "request"))
	list.append(_demo_plot("阿岚", "a1b2c3d4-0005-4000-8000-000000000005",
		"b1c2d3e4-0005-4000-8000-000000000015", "c1d2e3f4-0005-4000-8000-000000000025",
		"阿岚的家园", "门口总放着一张空长椅。", Vector2(980, 960), "open"))
	return list


func _demo_plot(resident_name: String, plot_uuid: String, resident_uuid: String,
		model_uuid: String, plot_name: String, description: String,
		position: Vector2, access: String) -> Dictionary:
	return {
		"plot_uuid": plot_uuid,
		"resident_uuid": resident_uuid,
		"model_uuid": model_uuid,
		"owner_uuid": "",
		"owner_name": "本地演示",
		"resident_name": resident_name,
		"plot_name": plot_name,
		"description": description,
		"world_position": position,
		"access": access,
		"thumbnail": "demo",
		"demo": true,
		"is_home": false,
	}
