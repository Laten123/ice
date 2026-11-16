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
var garden_tiles: Dictionary={}
var checker: Texture2D
var door: Sprite2D
var gizmos=preload("res://scripts/puppet/gizmos.gd").new()
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE;clip_contents=true
	texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	var tile=Image.create(32,32,false,Image.FORMAT_RGBA8);tile.fill(Color("e9e8e3"));tile.fill_rect(Rect2i(16,0,16,16),Color("d8d8d2"));tile.fill_rect(Rect2i(0,16,16,16),Color("d8d8d2"));checker=ImageTexture.create_from_image(tile)
	add_child(scene_root);scene_root.add_child(puppet);scene_root.y_sort_enabled=true;puppet.z_index=5
	gizmos.stage=self;gizmos.z_index=100;add_child(gizmos)
func set_fixture(kind: String) -> void:
	fixture=kind
	puppet.z_index=0 if kind=="door" else 5
	for sprite in sprites:sprite.free()
	sprites.clear();door=null
	for layer in Fixtures.layers(kind):
		var sprite=Sprite2D.new();sprite.centered=false;sprite.texture=ImageTexture.create_from_image(Lib.png(layer.path));sprite.position=layer.position;sprite.z_index=10 if layer.foreground else 0;scene_root.add_child(sprite);sprites.append(sprite)
		if kind=="door":door=sprite;sprite.position.y+=37;sprite.offset.y=-37
func _process(_delta: float) -> void:
	custom_minimum_size=Vector2(maxf(300,120*zoom),maxf(280,130*zoom))
	scene_root.position=Vector2(size.x/2,size.y*.55).round();scene_root.scale=Vector2.ONE*zoom
	var def=Lib.actions().get(puppet.action_id,{})
	puppet.position=Fixtures.preview_offset(fixture,puppet.action_id,float(puppet.frame)/maxf(1,def.get("frames",[]).size()-1)).round()
	if door!=null:door.texture=Fixtures.door_texture(Fixtures.openness(puppet.action_id,puppet.frame))
	queue_redraw();gizmos.queue_redraw()
func _draw() -> void:
	if garden:
		if not garden_tiles.has(zoom):
			var grass=Lib.png("res://assets/derived/home_v3/exterior_ground.png").get_region(Rect2i(0,128,64,64));grass.resize(64*zoom,64*zoom,Image.INTERPOLATE_NEAREST);garden_tiles[zoom]=ImageTexture.create_from_image(grass)
		draw_texture_rect(garden_tiles[zoom],Rect2(Vector2.ZERO,size),true)
	elif checker!=null:draw_texture_rect(checker,Rect2(Vector2.ZERO,size),true)
