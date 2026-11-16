extends Control
const Player=preload("res://scripts/puppet/player.gd")
const Fixtures=preload("res://scripts/puppet/fixtures.gd")
const Lib=preload("res://scripts/puppet/library.gd")
var puppet=Player.new()
var zoom=4
var grid=false
var joints=false
var bounds=false
var garden=false
var fixture="blank"
var sprites=[]
var scene_root=Node2D.new()
var door: Sprite2D
var gizmos=preload("res://scripts/puppet/gizmos.gd").new()
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE;clip_contents=true
	add_child(scene_root);scene_root.add_child(puppet);puppet.z_index=5
	gizmos.stage=self;gizmos.z_index=100;add_child(gizmos)
func set_fixture(kind: String) -> void:
	fixture=kind
	for sprite in sprites:sprite.free()
	sprites.clear();door=null
	for layer in Fixtures.layers(kind):
		var sprite=Sprite2D.new();sprite.centered=false;sprite.texture=ImageTexture.create_from_image(Lib.png(layer.path));sprite.position=layer.position;sprite.z_index=10 if layer.foreground else 0;scene_root.add_child(sprite);sprites.append(sprite)
		if kind=="door":door=sprite
func _process(_delta: float) -> void:
	custom_minimum_size=Vector2(maxf(300,120*zoom),maxf(280,130*zoom))
	scene_root.position=Vector2(size.x/2,size.y*.55).round();scene_root.scale=Vector2.ONE*zoom
	var def=Lib.actions().get(puppet.action_id,{})
	puppet.position=Fixtures.preview_offset(fixture,puppet.action_id,float(puppet.frame)/maxf(1,def.get("frames",[]).size()-1)).round()
	if door!=null:door.texture=ImageTexture.create_from_image(Fixtures.door_image(Fixtures.openness(puppet.action_id,puppet.frame)))
	queue_redraw();gizmos.queue_redraw()
func _draw() -> void:
	if garden:draw_rect(Rect2(Vector2.ZERO,size),Color("a9b982"))
	else:
		for y in range(0,int(size.y),16):
			for x in range(0,int(size.x),16):draw_rect(Rect2(x,y,16,16),Color("e9e8e3") if (x/16+y/16)%2==0 else Color("d8d8d2"))
