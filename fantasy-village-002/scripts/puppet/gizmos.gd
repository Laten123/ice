extends Node2D
var stage
func _draw() -> void:
	if stage==null:return
	var origin=Vector2(stage.size.x/2,stage.size.y*.55).round()+stage.puppet.position*stage.zoom
	var zoom=stage.zoom
	if stage.grid:
		for x in range(-24,25):draw_line(origin+Vector2(x*zoom,-40*zoom),origin+Vector2(x*zoom,8*zoom),Color(0,0,0,.15))
		for y in range(-40,9):draw_line(origin+Vector2(-24*zoom,y*zoom),origin+Vector2(24*zoom,y*zoom),Color(0,0,0,.15))
	if stage.bounds:
		draw_line(origin+Vector2(-24*zoom,0),origin+Vector2(24*zoom,0),Color("ab526a"),2);draw_circle(origin,5*zoom,Color("d66b42"),false,2)
	if stage.joints:
		var lib=load("res://scripts/puppet/library.gd")
		var pose=lib.actions()[stage.puppet.action_id].frames[stage.puppet.frame];var points={}
		for key in lib.rig().joints:
			var p=lib.v(lib.rig().joints[key])+lib.v(pose.offsets.get(key,[0,0]))
			points[key]=origin+(Vector2(p)-Vector2(24,40))*zoom
		for key in points:
			if key!="torso":draw_line(points.torso,points[key],Color("317aa6"),1)
			draw_circle(points[key],3,Color("315da6"))
