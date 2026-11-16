class_name ResidentActionState
extends RefCounted
## Action state belongs to the resident, not to the model binding or sprite.

const IDLE := "idle"
const WALK := "walk"
const SIT := "sit"
const READ := "read"
const REST := "rest"
const ENTER := "enter"
const EXIT := "exit"
const INTERACT := "interact"

var current := IDLE
var affordance_id := ""
var remaining := 0.0


func begin(action: String, target_id: String = "", duration: float = 0.0) -> void:
	current = action
	affordance_id = target_id
	remaining = maxf(0.0, duration)


func reset() -> void:
	current = IDLE
	affordance_id = ""
	remaining = 0.0


func is_busy() -> bool:
	return current != IDLE and current != WALK


func label() -> String:
	return current
