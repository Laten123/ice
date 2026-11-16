class_name ResidentController
extends RefCounted
## Decision-only interface. Implementations must not mutate scene nodes or
## animations; HomePlot executes the returned intent.

func decide(_context: Dictionary) -> Dictionary:
	return {}
