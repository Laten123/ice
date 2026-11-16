class_name HomePresentation
extends Node2D
## Rendering adapter only: state/controller own identity, regions and decisions.
const Puppet=preload("res://scripts/puppet/player.gd")
const Validator=preload("res://scripts/puppet/validator.gd")
const Render=preload("res://scripts/puppet/renderer.gd")
const Fixtures=preload("res://scripts/puppet/fixtures.gd")
var default_skin: Dictionary={}
var door_sprite: Sprite2D
const PATH := "res://assets/derived/home_v3/"
var exterior: Node2D
var interior: Node2D
var actors: Dictionary = {}
var textures: Dictionary = {}
var night_lights: Array[CanvasItem] = []
var clock := 45.0 # Begin in daylight; accelerated local day/night cycle is 90 seconds.
var night_weight := 0.0
var frames: SpriteFrames

func tex(id: String) -> Texture2D:
	if not textures.has(id):
		var path := PATH + id + ".png"
		if FileAccess.file_exists(path):
			var image := Image.new()
			var err := image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
			assert(err == OK, "Unreadable art " + id)
			textures[id] = ImageTexture.create_from_image(image)
		else:
			# Exported PNGs are remapped to .ctex; source-only headless runs use raw PNGs.
			textures[id] = load(path) as Texture2D
		assert(textures[id] != null, "Missing art " + id)
	return textures[id]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 10 # Keep negative ground layers above the enclosing UI panel.
	exterior = Node2D.new()
	interior = Node2D.new()
	add_child(exterior)
	add_child(interior)
	exterior.y_sort_enabled = true
	interior.y_sort_enabled = true
	interior.position = Vector2(96, 48)
	ground(exterior, "exterior_ground", Vector2i(26,17))
	ground(interior, "interior_ground", Vector2i(14,11))
	prop(exterior,"house",Vector2(140,28),114)
	door_sprite=Sprite2D.new();door_sprite.centered=false;door_sprite.position=Vector2(184,142);door_sprite.offset=Vector2(0,-37);door_sprite.texture=Fixtures.door_texture(0);exterior.add_child(door_sprite)
	prop(exterior,"chimney",Vector2(238,37),18,2)
	animated(exterior,"Smoke","smoke",6,5,Vector2(232,0),false)
	animated(exterior,"Pond","water",13,6,Vector2(40,208),false)
	for p in [Vector2(24,17),Vector2(70,55),Vector2(327,30),Vector2(355,101)]:
		animated(exterior,"Tree","tree",4,1.6,p,true)
	for p in [Vector2(123,152),Vector2(280,155)]:
		animated(exterior,"Flowers","flowers",4,2,p,false)
	prop(exterior,"bench",Vector2(79,178),15,-1)
	prop(exterior,"bench_front",Vector2(79,188),5)
	for p in [Vector2(35,209),Vector2(92,239),Vector2(58,247)]:prop(exterior,"rock",p,11)
	prop(interior,"bed",Vector2(23,35),60,-1)
	var blanket=Sprite2D.new();blanket.centered=false;blanket.texture=ImageTexture.create_from_image(preload("res://scripts/puppet/library.gd").png("res://assets/derived/puppet/blanket.png"));blanket.position=Vector2(27,95);blanket.offset=Vector2(0,-43);interior.add_child(blanket)
	prop(interior,"bookcase",Vector2(169,24),49)
	prop(interior,"desk",Vector2(105,34),30)
	prop(interior,"chair",Vector2(114,63),23,-1)
	prop(interior,"chair_front",Vector2(114,79),7)
	prop(interior,"rug",Vector2(85,94),36,-2)
	prop(interior,"lamp",Vector2(78,35),29)
	prop(interior,"window",Vector2(88,0),28)
	prop(interior,"tea_table",Vector2(165,108),25)
	prop(interior,"chair",Vector2(137,122),23,-1)
	prop(interior,"chair_front",Vector2(137,138),7)
	prop(interior,"plant",Vector2(190,139),25)
	# Warm night windows and lamp are separate local lighting overlays, never UI modulation.
	for rect in [Rect2(159,108,23,7),Rect2(222,108,23,7)]:
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([rect.position, rect.position+Vector2(rect.size.x,0), rect.end,rect.position+Vector2(0,rect.size.y)])
		poly.color = Color(1,.78,.35,.85)
		poly.z_index = 4
		exterior.add_child(poly)
		night_lights.append(poly)
	var light := Polygon2D.new()
	light.polygon = PackedVector2Array([Vector2(81,48),Vector2(95,48),Vector2(120,88),Vector2(64,88)])
	light.color = Color(1,.87,.5,.17)
	light.z_index = -1
	interior.add_child(light)
	night_lights.append(light)
	default_skin=Validator.load_skin("res://skins/forest").skin
	frames=SpriteFrames.new() # Compatibility inspection aliases use the same runtime renderer.
	for direction in range(4):
		for action in ["walk","idle"]:alias_frames(action+"_%d"%direction,action,["front","left","right","back"][direction])
	for pair in [["sit","sit_idle"],["read","read"],["rest","sleep"],["tea","tea"],["sit_down","sit_down"],["stand_up","stand_up"],["open_book","open_book"],["close_book","close_book"]]:alias_frames(pair[0],pair[1],"front")
	interior.visible = false

func ground(parent: Node2D, id: String, dimensions: Vector2i) -> void:
	var layer := TileMapLayer.new()
	layer.z_index = -10
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(16,16)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = tex(id)
	atlas.texture_region_size = Vector2i(16,16)
	for y in range(dimensions.y):
		for x in range(dimensions.x):atlas.create_tile(Vector2i(x,y))
	tiles.add_source(atlas,0)
	layer.tile_set = tiles
	parent.add_child(layer)
	for y in range(dimensions.y):
		for x in range(dimensions.x):layer.set_cell(Vector2i(x,y),0,Vector2i(x,y))

func prop(parent: Node2D,id: String,top: Vector2,foot: float,z: int=0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex(id)
	sprite.centered = false
	sprite.position = top + Vector2(0,foot)
	sprite.offset = Vector2(0,-foot)
	sprite.z_index = z
	parent.add_child(sprite)
	return sprite

func add_frames(target: SpriteFrames,name: String,prefix: String,count: int,fps: float,loop: bool) -> void:
	target.add_animation(name)
	target.set_animation_speed(name,fps)
	target.set_animation_loop(name,loop)
	for i in range(count):target.add_frame(name,tex(prefix+"_%d"%i))

func animated(parent: Node2D, name: String,prefix: String,count: int,fps: float,p: Vector2,sort: bool) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.name = name
	sprite.sprite_frames = SpriteFrames.new()
	add_frames(sprite.sprite_frames,"loop",prefix,count,fps,true)
	sprite.centered = false
	sprite.position = p
	if sort:
		sprite.position.y += 64
		sprite.offset.y = -64
	else:sprite.z_index = -3 if prefix == "water" else 2
	parent.add_child(sprite)
	sprite.play("loop")
	return sprite

func alias_frames(alias: String,action: String,direction: String) -> void:
	frames.add_animation(alias)
	for texture in Render.textures(default_skin,action,direction):frames.add_frame(alias,texture)
func set_actor_skin(id: String,path: String) -> bool:
	var result=Validator.load_skin(path)
	if not result.ok or not actors.has(id):return false
	actors[id].set_skin(result.skin)
	return true
func sync_actor(id: String, region: String, pos: Vector2, motion: String, _tint: Color) -> void:
	if not actors.has(id):
		var a=Puppet.new();a.set_skin(default_skin);actors[id]=a;exterior.add_child(a)
	var actor=actors[id]
	var destination=interior if region=="inside" else exterior
	if actor.get_parent()!=destination:actor.reparent(destination,false)
	actor.position=pos.round();actor.modulate=Color.WHITE
	var dir="front"
	if motion.right(2) in ["_0","_1","_2","_3"]:
		dir=["front","left","right","back"][int(motion.right(1))];motion=motion.left(-2)
	motion={"rest":"sleep","sit":"sit_idle"}.get(motion,motion)
	actor.request(motion,dir)
func set_door(weight: float) -> void:
	door_sprite.texture=Fixtures.door_texture(weight)

func set_view(inside: bool) -> void:
	exterior.visible = not inside
	interior.visible = inside

func _process(delta: float) -> void:
	clock += delta
	night_weight = clampf((sin(clock * TAU / 90.0)-.25)*1.8,0,1)
	modulate = Color.WHITE.lerp(Color(.43,.5,.68),night_weight)
	for light in night_lights:light.visible = night_weight > .25
