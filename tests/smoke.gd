extends SceneTree
# Run with: godot --headless --path . --script res://tests/smoke.gd
const WorldScript = preload("res://scripts/main.gd")

func _initialize() -> void:
	var sample := [Vector2i(0, 0), Vector2i(4, 7), Vector2i(-3, 11)]
	for cell in sample:
		var value: int = WorldScript.get_variant_index(cell, 3)
		if value < 0 or value >= 3:
			printerr("SMOKE_FAIL invalid grass variant at ", cell)
			quit(1)
			return
		if value != WorldScript.get_variant_index(cell, 3):
			printerr("SMOKE_FAIL grass variant is not deterministic at ", cell)
			quit(1)
			return

	var scene: PackedScene = load("res://scenes/main.tscn")
	if scene == null:
		printerr("SMOKE_FAIL main scene missing")
		quit(1)
		return
	var instance := scene.instantiate()
	if instance == null:
		printerr("SMOKE_FAIL main scene instantiation")
		quit(1)
		return
	instance.free()
	print("SMOKE_OK: scene and deterministic grass variants")
	quit(0)
