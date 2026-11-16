class_name HomeData
extends RefCounted
const TILE := 16
const COLS := 26
const ROWS := 17
const WORLD_SIZE := Vector2(416,272)
const WALK_BOUNDS := Rect2(0,0,416,272)
const INTERIOR_BOUNDS := Rect2(16,16,192,144)
const OWNER_START := Vector2(232,184)
const BOUND_START := Vector2(136,216)
static func props() -> Array[Dictionary]:
	return [
		{"id":"house","name":"林间小屋","kind":"house","region":"outside","hit_rect":Rect2(140,28,143,114),"obstacle":Rect2(140,92,144,24),"interaction":"enter_house"},
		{"id":"house_left","region":"outside","obstacle":Rect2(140,115,44,29)},
		{"id":"house_right","region":"outside","obstacle":Rect2(224,115,60,29)},
		{"id":"pond","name":"池塘","region":"outside","hit_rect":Rect2(40,208,64,48),"obstacle":Rect2(40,208,64,48)},
		{"id":"tree_west","region":"outside","obstacle":Rect2(45,65,16,16)},
		{"id":"tree_east","region":"outside","obstacle":Rect2(350,78,16,16)},
		{"id":"tree_back","region":"outside","obstacle":Rect2(91,103,16,16)},
		{"id":"tree_front","region":"outside","obstacle":Rect2(376,149,16,16)},
		{"id":"bench","name":"阅读长椅","region":"outside","hit_rect":Rect2(79,178,31,15),"obstacle":Rect2(79,178,31,15)},
		{"id":"bed","region":"inside","obstacle":Rect2(23,35,53,60)},
		{"id":"bookcase","region":"inside","obstacle":Rect2(169,24,32,49)},
		{"id":"desk","region":"inside","obstacle":Rect2(105,34,36,30)},
		{"id":"chair","region":"inside","obstacle":Rect2(114,63,19,23)},
		{"id":"tea_table","region":"inside","obstacle":Rect2(165,108,32,25)},
		{"id":"tea_chair","region":"inside","obstacle":Rect2(137,122,19,23)},
	]
static func affordances() -> Array[Dictionary]:
	return [
		{"id":"bench","name":"树下阅读","region":"outside","action":"sit","position":Vector2(94,190),"approach":Vector2(136,216),"duration":4.0,"capacity":1,"permission":"bound"},
		{"id":"house","name":"房门","region":"outside","action":"enter","position":Vector2(200,136),"approach":Vector2(200,168),"duration":.8,"capacity":1,"permission":"bound"},
		{"id":"bed","name":"床铺","region":"inside","action":"rest","position":Vector2(51,63),"approach":Vector2(88,120),"duration":6.0,"capacity":1,"permission":"bound"},
		{"id":"reading","name":"室内阅读","region":"inside","action":"read","position":Vector2(123,83),"approach":Vector2(120,104),"duration":4.0,"capacity":1,"permission":"bound"},
		{"id":"table","name":"茶桌","region":"inside","action":"interact","position":Vector2(146,142),"approach":Vector2(120,152),"duration":3.0,"capacity":1,"permission":"bound"},
		{"id":"garden","name":"菜地","region":"outside","action":"observe","position":Vector2(296,216),"approach":Vector2(280,232),"duration":2.0,"capacity":1,"permission":"bound"},
	]
static func crops() -> Array[Dictionary]:
	return []
