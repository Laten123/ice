extends Node2D
## 固定随机：同一格子每次运行选同一变体（不依赖 RNG 顺序）
static func get_variant_index(cell: Vector2i, variant_count: int) -> int:
	if variant_count <= 1:
		return 0
	var value: int = ((cell.x * 73856093) ^ (cell.y * 19349663))
	return posmod(value, variant_count)
## 幻想乡 —— 真素材版

const TILE := 16
const MAP_W := 36
const MAP_H := 24
const SCALE := 3

var time := 0.0
var player: CharacterBody2D
var camera: Camera2D
var cam_follow := false
var ai_intent_timer := 0.0
var ai_busy := false
var player_idle_until := 0.0
var npc_idle_until := 0.0
var npc_intent := ""
var player_intent := ""
var tree_test_mode := ""   # 树验证模式：collision / walk / double
var player_spr: Sprite2D
var player_target := Vector2.ZERO
var player_auto := true   # AI 自主模式（非玩家控制）
var player_facing := 0
var player_frame := 0
var player_anim_t := 0.0
var npc: Sprite2D
var npc_pos := Vector2.ZERO
var npc_target := Vector2.ZERO
var npc_frame := 0
var npc_anim_t := 0.0
var npc_facing := 0
var layer: TileMapLayer
var decor: Node2D
var world: Node2D   # YSort 容器（装饰/建筑/角色统一排序）
var canopy_layer: Node2D   # 树冠层（世界坐标，z_index 高，不参与 YSort）

# 素材
var grass_tex: Array = []
var path_tex: Texture2D

var ai_provider: Node
var bubble_player: Label
var bubble_npc: Label
var last_msg_ts := 0.0
var last_poll := 0.0
const AI_API := "http://127.0.0.1:8000"

func _ready() -> void:
	print("幻想乡启动（真素材）")
	y_sort_enabled = true

	# AI 接口层
	ai_provider = load("res://scripts/ai_provider.gd").new()
	add_child(ai_provider)
	_load_assets()
	_build_map()
	_build_background()
	# YSort 容器：装饰/建筑/角色按 y 排序（前后穿行）
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	# 树冠层（世界坐标，z_index 高，不参与 YSort）
	canopy_layer = Node2D.new()
	canopy_layer.z_index = 20
	add_child(canopy_layer)
	_build_decor()
	_build_path()
	_build_house(Vector2(15, 9))
	_build_player()
	_build_camera()
	_build_lighting()
	_build_ui()
	_build_zoom_buttons()
	_spawn_fireflies()
	# 树验证模式
	tree_test_mode = OS.get_environment("FANTASIA_TREE_TEST")
	if tree_test_mode != "":
		player_auto = false
		if tree_test_mode == "collision":
			player.position = Vector2(18, 18) * TILE * SCALE   # 树前1格
		elif tree_test_mode == "walk":
			player.position = Vector2(18, 21) * TILE * SCALE
		elif tree_test_mode == "double":
			_build_tree_layered(Vector2(16, 17))
			player.position = Vector2(17, 20) * TILE * SCALE
		camera.position = player.position
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		print("headless OK tiles=", MAP_W * MAP_H)
		# 后端连通测试
		var http := HTTPRequest.new()
		add_child(http)
		http.request("http://127.0.0.1:8000/api/health")
		var res = await http.request_completed
		print("[后端] HTTP ", res[1], " 响应: ", res[3].get_string_from_utf8().substr(0, 100))
		# 世界保存测试：POST 到后端
		var st := save_world_state()
		print("[存档] player=", st["player"], " npc=", st["npc"])
		var http2 := HTTPRequest.new()
		add_child(http2)
		var headers := ["Content-Type: application/json"]
		http2.request("http://127.0.0.1:8000/api/world", headers, HTTPClient.METHOD_POST, JSON.stringify({"id": "default", "name": "幻想乡", "data": st}))
		var res2 = await http2.request_completed
		print("[存档] 保存到后端 HTTP ", res2[1])
		# 读回验证
		var http3 := HTTPRequest.new()
		add_child(http3)
		http3.request("http://127.0.0.1:8000/api/world")
		var res3 = await http3.request_completed
		var body3: String = res3[3].get_string_from_utf8()
		print("[存档] 读回: ", body3.substr(0, 200))
		get_tree().quit(0)
	elif OS.get_environment("FANTASIA_SHOT") == "1":
		for i in 5:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.save_png("/root/fantasia/shot.png")
		print("截图已保存")
		get_tree().quit(0)

## AI 意图驱动：向 AI 服务请求"想做什么"（异步，不阻塞）
func _request_ai_intent(who: String) -> void:
	if ai_busy:
		return
	ai_busy = true
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, _headers, body):
		ai_busy = false
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			push_warning("[AI] Request failed: result=%s code=%s" % [result, code])
			return
		var data = JSON.parse_string(body.get_string_from_utf8())
		if not (data is Dictionary) or not data.get("ok", false):
			return
		var intent := String(data.get("intent", ""))
		if not intent.is_empty():
			apply_ai_intent(who, intent)
	)
	var state := "深寻正在初始土地散步" if who == "shenxun" else "小冰在房子附近"
	var err := http.request("https://47.97.177.2:8080/api/ai/intent",
		["Content-Type: text/plain"], HTTPClient.METHOD_POST, state)
	if err != OK:
		ai_busy = false
		http.queue_free()
		push_warning("[AI] Could not send request: %s" % err)

## 把手动意图映射为世界目标点
func apply_ai_intent(who: String, intent: String) -> void:
	print("[AI] ", Time.get_time_string_from_system(), " ", who, " 意图: ", intent)
	if who == "shenxun":
		player_intent = intent
	else:
		npc_intent = intent
	var target := Vector2.ZERO
	if "房子" in intent or "家" in intent:
		target = Vector2(15, 12) * TILE * SCALE
	elif "树" in intent:
		target = Vector2(20, 16) * TILE * SCALE
	elif "河边" in intent or "河" in intent:
		target = Vector2(10, 14) * TILE * SCALE
	elif "小冰" in intent or "聊天" in intent:
		target = npc_pos if who == "shenxun" else player.position
	elif "散步" in intent or "走走" in intent or "路" in intent:
		target = Vector2(randf_range(6, 30), randf_range(10, 20)) * TILE * SCALE
	elif "发呆" in intent or "休息" in intent:
		# Rest is an action, not a failure to select a destination.
		if who == "shenxun":
			player_target = Vector2.ZERO
			player_idle_until = time + 15.0
		else:
			npc_target = npc_pos
			npc_idle_until = time + 15.0
		return
	if target != Vector2.ZERO:
		if who == "shenxun":
			player_target = target
			player_idle_until = time
		else:
			npc_target = target
			npc_idle_until = time

func _load_assets() -> void:
	for i in 3:
		grass_tex.append(load("res://tiles/tile-grass-%d.png" % (i + 1)))
	path_tex = load("res://tiles/tile-path-c.png")

func _build_map() -> void:
	# 用 3 种草地瓦片拼 atlas
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var src := TileSetAtlasSource.new()
	var img := Image.create(TILE * 3, TILE, false, Image.FORMAT_RGBA8)
	for i in 3:
		var t: Texture2D = grass_tex[i]
		var im := t.get_image()
		im.convert(Image.FORMAT_RGBA8)
		img.blit_rect(im, Rect2i(0, 0, TILE, TILE), Vector2i(i * TILE, 0))
	src.texture = ImageTexture.create_from_image(img)
	for i in 3:
		src.create_tile(Vector2i(i, 0))
	ts.add_source(src, 0)

	layer = TileMapLayer.new()
	layer.tile_set = ts
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.scale = Vector2(SCALE, SCALE)
	add_child(layer)

	for y in MAP_H:
		for x in MAP_W:
			var cell := Vector2i(x, y)
			var t := get_variant_index(cell, 3)
			layer.set_cell(cell, 0, Vector2i(t, 0))

var clouds: Array = []

func _build_clouds(cl: CanvasLayer) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	for i in 4:
		var c := Sprite2D.new()
		var img := Image.create(120, 30, false, Image.FORMAT_RGBA8)
		for y in 30:
			for x in 120:
				var d := Vector2((x - 60) / 60.0, (y - 15) / 15.0).length()
				if d < 1.0 and rng.randf() > 0.15:
					img.set_pixel(x, y, Color(1, 1, 1, 0.75))
		c.texture = ImageTexture.create_from_image(img)
		c.position = Vector2(100 + i * 320, 30 + rng.randi_range(0, 50))
		c.set_meta("speed", 4.0 + rng.randf() * 3.0)
		cl.add_child(c)
		clouds.append(c)

func _build_background() -> void:
	# 背景层（CanvasLayer，固定在屏幕顶部，视差感）
	var cl := CanvasLayer.new()
	cl.layer = 1
	add_child(cl)
	# 天空渐变
	var sky := Sprite2D.new()
	var simg := Image.create(1280, 200, false, Image.FORMAT_RGBA8)
	for y in 200:
		for x in 1280:
			var k := y / 200.0
			simg.set_pixel(x, y, Color(0.25 + k * 0.4, 0.5 + k * 0.3, 0.8 + k * 0.1))
	sky.texture = ImageTexture.create_from_image(simg)
	sky.position = Vector2(640, 30)
	sky.z_index = -100
	cl.add_child(sky)
	print("背景: cl children=", cl.get_child_count(), " sky_pos=", sky.position, " tex=", sky.texture != null)
	# 远山（两层波浪）
	for layer in 2:
		var mtn := Sprite2D.new()
		var mimg := Image.create(1280, 120, false, Image.FORMAT_RGBA8)
		var rng := RandomNumberGenerator.new()
		rng.seed = 11 + layer
		for x in 1280:
			var h := int(60 + sin(x * 0.006 + layer * 2.5) * 25 + rng.randf() * 15)
			for y in 120:
				if y > 120 - h:
					var c := Color(0.32, 0.5, 0.35) if layer == 0 else Color(0.22, 0.38, 0.28)
					mimg.set_pixel(x, y, c)
		mtn.texture = ImageTexture.create_from_image(mimg)
		mtn.position = Vector2(640, 80 + layer * 30)
		mtn.z_index = -90 + layer
		cl.add_child(mtn)
	# 云朵
	_build_clouds(cl)

func _build_path() -> void:
	# 道路自动拼接：中心 path-c + 边缘 path-n/e/s/w + 拐角
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var src := TileSetAtlasSource.new()
	# 把所有 path 瓦片拼成 atlas（16 块）
	var names := ["path-c", "path-n", "path-e", "path-s", "path-w", "path-ne", "path-nw", "path-se", "path-sw", "path-inner-ne", "path-inner-nw", "path-inner-se", "path-inner-sw"]
	var img := Image.create(TILE * names.size(), TILE, false, Image.FORMAT_RGBA8)
	var idx := {}
	for i in names.size():
		idx[names[i]] = i
		var pt: Texture2D = null
		if ResourceLoader.exists("res://tiles/tile-" + names[i] + ".png"):
			pt = load("res://tiles/tile-" + names[i] + ".png")
		if pt:
			var im := pt.get_image()
			im.convert(Image.FORMAT_RGBA8)
			img.blit_rect(im, Rect2i(0, 0, TILE, TILE), Vector2i(i * TILE, 0))
	src.texture = ImageTexture.create_from_image(img)
	for i in names.size():
		src.create_tile(Vector2i(i, 0))
	ts.add_source(src, 0)
	var path_layer := TileMapLayer.new()
	path_layer.tile_set = ts
	path_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	path_layer.scale = Vector2(SCALE, SCALE)
	add_child(path_layer)

	# 道路坐标（2 格宽，从房子门口往下）
	# 竖直道路（2 格宽，13-21 行，17-18 列）
	var road_cells := []
	for y in range(13, 22):
		road_cells.append(Vector2i(17, y))
		road_cells.append(Vector2i(18, y))
	for cell in road_cells:
		var x: int = cell.x
		var y: int = cell.y
		var name := "path-c"
		if y == 13:
			name = "path-n"
		elif y == 21:
			name = "path-s"
		elif x == 17:
			name = "path-w"
		elif x == 18:
			name = "path-e"
		path_layer.set_cell(cell, 0, Vector2i(idx.get(name, 0), 0))

var occupied := {}

func _place_ok(tx: int, ty: int) -> bool:
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if occupied.has(Vector2i(tx + dx, ty + dy)):
				return false
	return true

## 分层树样板：树干（Y-Sort+碰撞）+ 树冠（上层遮挡）+ 阴影
func _build_tree_layered(pos: Vector2) -> void:
	var oak: Texture2D = load("res://objects/oak.png")
	# 树干（参与 Y-Sort，基准=树根）
	var trunk := Sprite2D.new()
	trunk.texture = oak
	trunk.scale = Vector2(SCALE, SCALE)
	trunk.region_enabled = true
	trunk.region_rect = Rect2(0, 40, 32, 8)
	trunk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	trunk.position = pos * TILE * Vector2(SCALE, SCALE) - Vector2(0, 8 * SCALE / 2)   # 树干中心（底部贴树根）
	world.add_child(trunk)
	# 树干碰撞
	var body := StaticBody2D.new()
	body.position = pos * TILE * Vector2(SCALE, SCALE) + Vector2(0, 2)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 12)
	col.shape = rect
	body.add_child(col)
	world.add_child(body)
	# 地面阴影（椭圆，树根下）
	var shadow := Sprite2D.new()
	var simg := Image.create(24, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 24:
			var dx := (x - 12.0) / 12.0
			var dy := (y - 4.0) / 3.5
			var d := sqrt(dx * dx + dy * dy)
			simg.set_pixel(x, y, Color(0, 0, 0, clampf(1.0 - d, 0.0, 1.0) * 0.28))
	shadow.texture = ImageTexture.create_from_image(simg)
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shadow.scale = Vector2(SCALE * 0.8, SCALE * 0.8)
	shadow.position = pos * TILE * Vector2(SCALE, SCALE) + Vector2(0, 2)
	world.add_child(shadow)
	# 树冠（上层，遮挡人物）
	var canopy := Sprite2D.new()
	canopy.texture = oak
	canopy.region_enabled = true
	canopy.region_rect = Rect2(0, 0, 32, 40)
	canopy.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canopy.scale = Vector2(SCALE, SCALE)
	canopy.position = pos * TILE * Vector2(SCALE, SCALE) - Vector2(0, 28 * SCALE)   # 树冠中心（原图 y20，树根减 28px）
	canopy_layer.add_child(canopy)

func _build_decor() -> void:
	decor = Node2D.new()
	decor.scale = Vector2(SCALE, SCALE)
	world.add_child(decor)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# 房子占位（先占住房子区域）
	for dx in range(24, 33):
		for dy in range(19, 26):
			occupied[Vector2i(dx, dy)] = true
	var oak: Texture2D = load("res://objects/oak.png")
	var flowers: Texture2D = load("res://props/flowers.png")
	var rock: Texture2D = load("res://props/rock.png")
	var bush: Texture2D = load("res://props/bush.png")
	# 树（position=树根，y_sort 按此）
	for i in 18:
		var tx := 0; var ty := 0
		for tries in 30:
			tx = rng.randi_range(2, MAP_W - 3); ty = rng.randi_range(2, MAP_H - 3)
			if _place_ok(tx, ty): break
		occupied[Vector2i(tx, ty)] = true
		if i == 0:
			# 第一棵：分层样板——放在玩家正下方（18,17）便于测试
			print("[样板树] pos=18,17 world=", Vector2(18, 17) * TILE * SCALE)
			_build_tree_layered(Vector2(18, 17))
			occupied[Vector2i(18, 17)] = true
			continue
		var s := Sprite2D.new()
		s.texture = oak
		s.position = Vector2(tx, ty) * TILE + Vector2(8, 8)
		decor.add_child(s)
		trees.append(s)
		# 树碰撞
		var tbody := StaticBody2D.new()
		tbody.position = s.position * Vector2(SCALE, SCALE)
		var tcol := CollisionShape2D.new()
		var trect := RectangleShape2D.new()
		trect.size = Vector2(16, 12)
		tcol.shape = trect
		tbody.add_child(tcol)
		add_child(tbody)
	# 花
	for i in 30:
		var tx := 0; var ty := 0
		for tries in 30:
			tx = rng.randi_range(2, MAP_W - 3); ty = rng.randi_range(2, MAP_H - 3)
			if _place_ok(tx, ty): break
		occupied[Vector2i(tx, ty)] = true
		var s := Sprite2D.new()
		s.texture = flowers
		s.position = Vector2(tx, ty) * TILE
		decor.add_child(s)
	# 石头
	for i in 10:
		var tx := 0; var ty := 0
		for tries in 30:
			tx = rng.randi_range(2, MAP_W - 3); ty = rng.randi_range(2, MAP_H - 3)
			if _place_ok(tx, ty): break
		occupied[Vector2i(tx, ty)] = true
		var s := Sprite2D.new()
		s.texture = rock
		s.position = Vector2(tx, ty) * TILE
		decor.add_child(s)
	# 灌木
	for i in 12:
		var tx := 0; var ty := 0
		for tries in 30:
			tx = rng.randi_range(2, MAP_W - 3); ty = rng.randi_range(2, MAP_H - 3)
			if _place_ok(tx, ty): break
		occupied[Vector2i(tx, ty)] = true
		var s := Sprite2D.new()
		s.texture = bush
		s.position = Vector2(tx, ty) * TILE
		decor.add_child(s)


func _build_house(tile_pos: Vector2) -> void:
	# 用 SDXL 生成的星露谷风房子贴图
	var house := Node2D.new()
	house.scale = Vector2(SCALE, SCALE)
	var base := tile_pos * TILE
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/house.png")
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.position = base + Vector2(0, 0)
	house.add_child(spr)
	# 房子碰撞（StaticBody2D）
	var body := StaticBody2D.new()
	# House sprite is scaled by SCALE; collider must use world coordinates.
	body.position = base * SCALE + Vector2(0, 45)
	var bshape := CollisionShape2D.new()
	var brect := RectangleShape2D.new()
	brect.size = Vector2(100, 45)
	bshape.shape = brect
	body.add_child(bshape)
	add_child(body)
	add_child(house)

func _build_player() -> void:
	player = CharacterBody2D.new()
	player.position = Vector2(TILE * 18 * SCALE, TILE * 14 * SCALE)
	player_target = player.position + Vector2(60, 0)
	player_spr = Sprite2D.new()
	player_spr.texture = load("res://assets/shenxun_walk.png")
	player_spr.region_enabled = true
	player_spr.region_rect = Rect2(0, 0, 24, 24)
	player_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_spr.scale = Vector2(2.0, 2.0)
	player.add_child(player_spr)
	# 碰撞体（不穿模）
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 14)  # 脚下碰撞（16x16 精灵的脚部）
	col.shape = shape
	col.position = Vector2(0, 8)
	player.add_child(col)
	# 脚下阴影
	var sh := Sprite2D.new()
	var shimg := Image.create(16, 6, false, Image.FORMAT_RGBA8)
	for y in 6:
		for x in 16:
			var dx := (x - 8.0) / 8.0
			var dy := (y - 3.0) / 3.0
			var d := sqrt(dx * dx + dy * dy)
			shimg.set_pixel(x, y, Color(0, 0, 0, clampf(1.0 - d, 0.0, 1.0) * 0.35))
	sh.texture = ImageTexture.create_from_image(shimg)
	sh.position = Vector2(0, 20)
	sh.scale = Vector2(SCALE, SCALE)
	player.add_child(sh)
	add_child(player)
	# 小冰
	npc = Sprite2D.new()
	npc.texture = load("res://assets/xiaobing_walk.png")
	npc.region_enabled = true
	npc.region_rect = Rect2(0, 0, 24, 24)
	npc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	npc.scale = Vector2(2.0, 2.0)
	npc_pos = Vector2(TILE * 22 * SCALE, TILE * 14 * SCALE)
	npc_target = npc_pos
	npc.position = npc_pos
	world.add_child(npc)
	var nsh := Sprite2D.new()
	var nshimg := Image.create(16, 6, false, Image.FORMAT_RGBA8)
	for y in 6:
		for x in 16:
			var dx := (x - 8.0) / 8.0
			var dy := (y - 3.0) / 3.0
			var d := sqrt(dx * dx + dy * dy)
			nshimg.set_pixel(x, y, Color(0, 0, 0, clampf(1.0 - d, 0.0, 1.0) * 0.35))
	nsh.texture = ImageTexture.create_from_image(nshimg)
	nsh.position = Vector2(0, 20)
	nsh.scale = Vector2(SCALE, SCALE)
	npc.add_child(nsh)

var label: Label

func _build_lighting() -> void:
	# 环境光（黄昏暖色）
	var modulate := CanvasModulate.new()
	modulate.color = Color(0.85, 0.8, 0.75)
	add_child(modulate)
	# 房子门口灯
	var lamp := PointLight2D.new()
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d := Vector2(x - 32, y - 32).length() / 32.0
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 0.8, 0.4, a))
	lamp.texture = ImageTexture.create_from_image(img)
	lamp.position = Vector2(TILE * 28 * SCALE, TILE * 22 * SCALE)
	lamp.energy = 1.5
	lights.append(lamp)
	add_child(lamp)

func _build_zoom_buttons() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 6
	add_child(cl)
	for pair in [["+", 1.2], ["-", 1/1.2]]:
		var b := Button.new()
		b.text = pair[0]
		b.custom_minimum_size = Vector2(48, 48)
		b.add_theme_font_size_override("font_size", 24)
		b.position = Vector2(1200 if pair[0] == "+" else 1200, 60 if pair[0] == "+" else 120)
		var factor: float = pair[1]
		b.pressed.connect(func():
			camera.zoom = (camera.zoom * factor).clamp(Vector2(0.6, 0.6), Vector2(4, 4)))
		cl.add_child(b)

func _build_ui() -> void:
	label = Label.new()
	label.position = Vector2(40, 30)
	label.add_theme_font_size_override("font_size", 22)
	label.text = "幻想乡 · AI 自主生活（旁观模式）"
	add_child(label)
	# 角色对话气泡（屏幕空间的 CanvasLayer）
	var cl := CanvasLayer.new()
	cl.layer = 5
	add_child(cl)
	bubble_player = Label.new()
	bubble_player.add_theme_font_size_override("font_size", 18)
	bubble_player.add_theme_color_override("font_color", Color.WHITE)
	bubble_player.add_theme_stylebox_override("normal", _bubble_style())
	bubble_player.visible = false
	cl.add_child(bubble_player)
	bubble_npc = Label.new()
	bubble_npc.add_theme_font_size_override("font_size", 18)
	bubble_npc.add_theme_color_override("font_color", Color.WHITE)
	bubble_npc.add_theme_stylebox_override("normal", _bubble_style())
	bubble_npc.visible = false
	cl.add_child(bubble_npc)

func _bubble_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.15, 0.2, 0.85)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb

func _build_camera() -> void:
	camera = Camera2D.new()
	camera.position = player.position
	camera.zoom = Vector2(2, 2)
	add_child(camera)
	camera.make_current()

## 世界状态保存（玩家/NPC 位置 + 地图种子）
func save_world_state() -> Dictionary:
	return {
		"map_seed": 42,
		"player": {"x": player.position.x, "y": player.position.y},
		"npc": {"x": npc_pos.x, "y": npc_pos.y},
		"saved_at": Time.get_unix_time_from_system()
	}

## 应用世界状态（加载时恢复位置）
func apply_world_state(st: Dictionary) -> void:
	if st.has("player"):
		player.position = Vector2(st["player"]["x"], st["player"]["y"])
	if st.has("npc"):
		npc_pos = Vector2(st["npc"]["x"], st["npc"]["y"])
		npc.position = npc_pos

var dragging := false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		camera.position -= event.relative / (camera.zoom * 2.5)
	elif event is InputEventScreenTouch:
		dragging = event.pressed
	elif event is InputEventScreenDrag:
		camera.position -= event.relative / (camera.zoom * 2.5)
	elif event is InputEventMagnifyGesture:
		camera.zoom = (camera.zoom * event.factor).clamp(Vector2(0.5, 0.5), Vector2(4, 4))
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom = (camera.zoom * 1.1).clamp(Vector2(0.5, 0.5), Vector2(4, 4))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom = (camera.zoom / 1.1).clamp(Vector2(0.5, 0.5), Vector2(4, 4))
	# 边界限制（不跑出地图）
	var max_x := MAP_W * TILE * SCALE
	var max_y := MAP_H * TILE * SCALE
	camera.position = camera.position.clamp(Vector2(0, 0), Vector2(max_x, max_y))

# Physics movement is separate from rendering and network polling.
func _physics_process(delta: float) -> void:
	if player == null:
		return
	if tree_test_mode != "":
		var test_target := Vector2(18, 14) * TILE * SCALE
		if tree_test_mode == "double":
			test_target = Vector2(17, 14) * TILE * SCALE
		var test_dir := (test_target - player.position).normalized()
		player.velocity = test_dir * 400.0 if player.position.distance_to(test_target) > 10.0 else Vector2.ZERO
		player.move_and_slide()
		return

	var dir := Vector2.ZERO
	if player_auto:
		if player_target != Vector2.ZERO and player.position.distance_to(player_target) < 14.0:
			player_target = Vector2.ZERO
			player_idle_until = time + randf_range(2.0, 5.0)
		if player_target == Vector2.ZERO and time >= player_idle_until:
			player_target = Vector2(
				randf_range(150.0, MAP_W * TILE * SCALE - 150.0),
				randf_range(150.0, MAP_H * TILE * SCALE - 150.0)
			)
		if player_target != Vector2.ZERO:
			dir = (player_target - player.position).normalized()
	else:
		if Input.is_action_pressed("ui_right"): dir.x += 1
		if Input.is_action_pressed("ui_left"): dir.x -= 1
		if Input.is_action_pressed("ui_down"): dir.y += 1
		if Input.is_action_pressed("ui_up"): dir.y -= 1
		dir = dir.normalized()

	player.velocity = dir * (45.0 if player_auto else 300.0)
	player.move_and_slide()
	if dir != Vector2.ZERO:
		if abs(dir.x) > abs(dir.y):
			player_facing = 1 if dir.x < 0 else 2
		else:
			player_facing = 3 if dir.y < 0 else 0
		player_anim_t += delta
		if player_anim_t >= 0.12:
			player_anim_t = 0.0
			player_frame = (player_frame + 1) % 6
	else:
		player_frame = 0
	player_spr.region_rect = Rect2(player_frame * 24, 0, 24, 24)

func _process(delta: float) -> void:
	time += delta
	if player == null or tree_test_mode != "":
		return
	# One AI call per 120 seconds; requests remain asynchronous.
	ai_intent_timer += delta
	if ai_intent_timer >= 120.0:
		ai_intent_timer = 0.0
		_request_ai_intent("shenxun")
	_process_npc(delta)
	_animate_world(delta)
	if time - last_poll > 10.0:
		last_poll = time
		_poll_ai_messages()
	if label != null:
		var dist := player.position.distance_to(npc_pos)
		if dist < 120.0:
			label.text = "小冰：你来啦～（她在等你）"
		else:
			label.text = "幻想乡 · AI 自主生活（旁观模式）"

var trees: Array = []
var lights: Array = []
var fireflies: Array = []

func _animate_world(delta: float) -> void:
	var t := time
	# 树摆动
	for i in trees.size():
		var tr: Sprite2D = trees[i]
		tr.rotation = sin(t * 1.2 + i * 1.7) * 0.015
	# 灯光脉动
	for l in lights:
		l.energy = 1.2 + sin(t * 2.0) * 0.3
	# 萤火虫
	for f in fireflies:
		f.position = Vector2(
			f.position.x + sin(t * 1.5 + f.get_meta("seed", 0.0)) * 8.0 * delta,
			f.position.y + cos(t * 1.1 + f.get_meta("seed", 0.0)) * 5.0 * delta)
		# 循环边界
		var p: Vector2 = f.position
		if p.x < 100: p.x = 1900
		if p.x > 1900: p.x = 100
		if p.y < 100: p.y = 1000
		if p.y > 1000: p.y = 100
		f.position = p
		f.modulate.a = 0.4 + 0.5 * abs(sin(t * 3.0 + f.get_meta("seed", 0.0)))

func _spawn_fireflies() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 6:
		var f := Sprite2D.new()
		var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		for y in 4:
			for x in 4:
				var d := Vector2(x - 2, y - 2).length() / 2.0
				img.set_pixel(x, y, Color(1.0, 0.9, 0.4, clampf(1.0 - d, 0.0, 1.0)))
		f.texture = ImageTexture.create_from_image(img)
		f.position = Vector2(rng.randi_range(200, 1800), rng.randi_range(200, 900))
		f.set_meta("seed", rng.randf() * 6.28)
		add_child(f)
		fireflies.append(f)

func _poll_ai_messages() -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request(AI_API + "/api/messages")
	var res = await http.request_completed
	if res[1] != 200:
		http.queue_free()
		return
	var body: String = res[3].get_string_from_utf8()
	http.queue_free()
	var parsed = JSON.parse_string(body)
	if parsed == null or not parsed.has("messages"):
		return
	var msgs: Array = parsed["messages"]
	if msgs.is_empty():
		return
	var last: Dictionary = msgs[msgs.size() - 1]
	if last["ts"] <= last_msg_ts:
		return
	last_msg_ts = last["ts"]
	var sender: String = last.get("sender", "")
	var text: String = last.get("text", "")
	# 屏幕定位（简化：固定位置）
	if sender == "shenxun":
		bubble_player.text = "深寻：" + text
		bubble_player.visible = true
		bubble_player.position = Vector2(80, 500)
	else:
		bubble_npc.text = "小冰：" + text
		bubble_npc.visible = true
		bubble_npc.position = Vector2(600, 500)

func _process_npc(delta: float) -> void:
	if npc == null: return
	if npc_pos.distance_to(npc_target) < 8:
		# 小冰在房子附近活动（12-26 列，10-20 行）
		npc_target = Vector2(randf_range(12, 26), randf_range(10, 20)) * TILE * SCALE
		# 偶尔停下发呆（30% 概率）
		if randf() < 0.3:
			npc_target = npc_pos
	var dir := (npc_target - npc_pos).normalized()
	npc_pos += dir * 35.0 * delta
	npc.position = npc_pos
	if abs(dir.x) > abs(dir.y):
		npc_facing = 1 if dir.x < 0 else 2
	else:
		npc_facing = 3 if dir.y < 0 else 0
	npc_anim_t += delta
	if npc_anim_t > 0.15:
		npc_anim_t = 0.0
		npc_frame = (npc_frame + 1) % 3
	npc.region_rect = Rect2((npc_frame % 6) * 24, 0, 24, 24)
