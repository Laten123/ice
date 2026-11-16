extends SceneTree
const Lib=preload("res://scripts/puppet/library.gd")
func _init() -> void:
	var skeleton=Skeleton2D.new();var bone=Bone2D.new();skeleton.add_child(bone)
	bone.rotation=PI/8;bone.position=Vector2(.5,.5)
	assert(not bone.transform.x.is_equal_approx(bone.transform.x.round()))
	assert(Lib.rig().collision_radius==5 and Lib.v(Lib.rig().foot_origin)==Vector2i(24,40))
	print("PASS: Skeleton2D supports fractional/rotated transforms; integer layered rig fixes native pixel/foot coordinates. No skeletal deformation selected.")
	skeleton.free();quit()
