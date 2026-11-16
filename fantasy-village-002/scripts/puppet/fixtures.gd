extends RefCounted
const Data=preload("res://data/home_data.gd")
const Lib=preload("res://scripts/puppet/library.gd")
const PATH="res://assets/derived/home_v3/"
static func definition(kind: String) -> Dictionary:
	var id={"bench":"bench","desk":"reading","bed":"bed","door":"house","tea":"table"}.get(kind,"")
	for f in Data.affordances():
		if f.id==id:return f
	return {"position":Vector2.ZERO,"approach":Vector2.ZERO}
static func layers(kind: String) -> Array:
	var origin=definition(kind).position
	var items=[]
	match kind:
		"bench":items=[["bench",Vector2(79,178),false],["bench_front",Vector2(79,188),true]]
		"desk":items=[["desk",Vector2(105,34),false],["chair",Vector2(114,63),false],["chair_front",Vector2(114,79),true]]
		"bed":items=[["bed",Vector2(23,35),false],["@blanket",Vector2(27,52),true]]
		"tea":items=[["tea_table",Vector2(165,108),false],["chair",Vector2(137,122),false],["chair_front",Vector2(137,138),true]]
		"door":items=[["@door",Vector2(184,105),false]]
	var result=[]
	for item in items:
		var path="res://assets/derived/puppet/"+item[0].trim_prefix("@")+".png" if item[0].begins_with("@") else PATH+item[0]+".png"
		result.append({"path":path,"position":item[1]-origin,"foreground":item[2]})
	return result
static func door_image(open_weight: float) -> Image:
	var source=Lib.png("res://assets/derived/puppet/door.png")
	var im=source.duplicate()
	im.fill_rect(Rect2i(3,3,26,32),Color("342c28"))
	var width=maxi(2,roundi(26*(1-clampf(open_weight,0,1))))
	# Pixel hinge: copy original columns without interpolating/recoloring pixels.
	for y in range(3,35):
		for x in range(width):im.set_pixel(x+3,y,source.get_pixel(3+mini(25,int(float(x)*26/width)),y))
	return im
static func openness(action: String,frame: int) -> float:
	if action=="open_door":return float(frame)/5
	if action=="close_door":return 1-float(frame)/5
	return 1.0 if action in ["enter_house","exit_house"] else 0.0
static func preview_offset(kind: String,action: String,t: float) -> Vector2:
	var f=definition(kind);var approach=f.approach-f.position
	if action=="approach_bed":return approach*(1-t)
	if action=="get_up":return approach*maxf(0,(t-.5)*2)
	if kind=="door":
		if action=="enter_house":return Vector2(0,16*(1-t))
		if action=="exit_house":return Vector2(0,16*t)
		return Vector2(0,16)
	return Vector2.ZERO

static var _door_textures: Dictionary={}
static func door_texture(weight: float) -> Texture2D:
	var index=clampi(roundi(weight*5),0,5)
	if not _door_textures.has(index):_door_textures[index]=ImageTexture.create_from_image(door_image(float(index)/5))
	return _door_textures[index]
