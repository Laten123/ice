class_name ResidentAgent
extends RefCounted
## Minimal resident state and obstacle-aware walking. No UI or AI service calls.

const GRID_SIZE: float = 16.0
const WALK_SPEED: float = 55.0
const FOOT_RADIUS: float = 5.0

var id: String = ""
var display_name: String = ""
var role: String = ""
var description: String = ""
var color: Color = Color.WHITE
var position: Vector2 = Vector2.ZERO
var target: Vector2 = Vector2.ZERO
var waypoints: Array[Vector2] = []
var moving: bool = false
var autonomous: bool = false
var idle_time: float = 0.0


func configure(data: Dictionary) -> void:
	id = str(data.get("id", ""))
	display_name = str(data.get("name", data.get("display_name", id)))
	role = str(data.get("role", "居民"))
	description = str(data.get("description", "占位居民。"))
	color = data.get("color", Color.WHITE)
	position = data.get("position", Vector2.ZERO)
	target = position
	autonomous = bool(data.get("autonomous", false))
	idle_time = float(data.get("idle_time", 0.0))
	waypoints.clear()
	moving = false


func set_destination(destination: Vector2, obstacles: Array[Rect2], bounds: Rect2) -> bool:
	# Keep a rejected click from replacing a resident's existing valid route.
	if not bounds.has_point(destination) or not bounds.has_point(position):
		return false
	for obstacle: Rect2 in obstacles:
		if obstacle.grow(FOOT_RADIUS).has_point(destination):
			return false

	var grid := AStarGrid2D.new()
	var grid_width: int = int(ceil(bounds.size.x / GRID_SIZE))
	var grid_height: int = int(ceil(bounds.size.y / GRID_SIZE))
	grid.region = Rect2i(0, 0, grid_width, grid_height)
	grid.cell_size = Vector2.ONE * GRID_SIZE
	grid.offset = bounds.position + Vector2.ONE * GRID_SIZE * 0.5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	grid.update()
	for y: int in range(grid_height):
		for x: int in range(grid_width):
			var cell := Vector2i(x, y)
			var cell_rect := Rect2(bounds.position + Vector2(x, y) * GRID_SIZE,
				Vector2.ONE * GRID_SIZE)
			var blocked: bool = not bounds.encloses(cell_rect)
			for obstacle: Rect2 in obstacles:
				if cell_rect.intersects(obstacle.grow(FOOT_RADIUS)):
					blocked = true
					break
			grid.set_point_solid(cell, blocked)

	var start := Vector2i(floor((position.x - bounds.position.x) / GRID_SIZE),
		floor((position.y - bounds.position.y) / GRID_SIZE))
	var finish := Vector2i(floor((destination.x - bounds.position.x) / GRID_SIZE),
		floor((destination.y - bounds.position.y) / GRID_SIZE))
	if not grid.is_in_boundsv(start) or not grid.is_in_boundsv(finish):
		return false
	if grid.is_point_solid(start) or grid.is_point_solid(finish):
		return false
	var path: PackedVector2Array = grid.get_point_path(start, finish)
	if path.is_empty():
		return false

	waypoints.clear()
	# The first center keeps the initial short segment inside its safe cell.
	for point: Vector2 in path:
		if position.distance_to(point) > 0.5:
			waypoints.append(point)
	if waypoints.is_empty() or waypoints.back().distance_to(destination) > 0.5:
		waypoints.append(destination)
	target = destination
	moving = not waypoints.is_empty()
	idle_time = 0.0
	return true


func tick(delta: float) -> bool:
	if not moving:
		return false
	var remaining: float = WALK_SPEED * maxf(delta, 0.0)
	var previous: Vector2 = position
	while remaining > 0.0 and not waypoints.is_empty():
		var next_point: Vector2 = waypoints.front()
		var distance: float = position.distance_to(next_point)
		if distance <= remaining:
			position = next_point
			waypoints.pop_front()
			remaining -= distance
		else:
			position = position.move_toward(next_point, remaining)
			remaining = 0.0
	moving = not waypoints.is_empty()
	return not position.is_equal_approx(previous)


func get_info() -> Dictionary:
	return {
		"id": id,
		"name": display_name,
		"kind": "resident",
		"role": role,
		"description": description,
		"status": "正在散步" if moving else "悠闲地休息",
		"position": position,
		"target": target,
		"autonomous": autonomous,
		"color": color,
	}
