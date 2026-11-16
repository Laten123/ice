class_name MockLifeController
extends "res://scripts/world/resident_controller.gd"
## Local test double for Phase B. It proves the scene can support autonomous
## life; it must never be treated as the future model decision layer.

const PLAN := [
	{"affordance": "bench", "action": "sit", "duration": 5.0},
	{"affordance": "house", "action": "enter", "duration": 0.6},
	{"affordance": "reading", "action": "read", "duration": 3.0},
	{"affordance": "bed", "action": "rest", "duration": 6.0},
	{"affordance": "table", "action": "interact", "duration": 3.0},
	{"affordance": "house", "action": "exit", "duration": 0.5},
	{"affordance": "garden", "action": "observe", "duration": 4.0},
]

var _index := 0


func decide(context: Dictionary) -> Dictionary:
	if bool(context.get("busy", false)):
		return {}
	var step: Dictionary = PLAN[_index % PLAN.size()].duplicate(true)
	_index += 1
	return step
