class_name HomeData
extends RefCounted
## Layout data for the 26x17 home plot. Coordinates are tile cells unless noted.
## The tile indices refer to the packed Kenney atlases (12 columns, 16px).

const TILE := 16
const COLS := 26
const ROWS := 17
const WORLD_SIZE := Vector2(COLS * TILE, ROWS * TILE)
const WALK_BOUNDS := Rect2(8, 20, 400, 244)

const OWNER_START := Vector2(11 * TILE + 8, 10 * TILE)
const BOUND_START := Vector2(16 * TILE, 11 * TILE)


static func affordances() -> Array[Dictionary]:
	return [
		{
			"id": "bench", "name": "木长椅", "action": "sit",
			"position": Vector2(5 * TILE + 16, 12 * TILE + 16),
			"approach": Vector2(6 * TILE, 15 * TILE),
			"duration": 5.0, "capacity": 1, "permission": "bound",
		},
		{
			"id": "house", "name": "小屋门", "action": "enter",
			"position": Vector2(11 * TILE + 16, 7 * TILE),
			"approach": Vector2(11 * TILE + 16, 9 * TILE),
			"duration": 0.6, "capacity": 1, "permission": "bound",
		},
		{
			"id": "bed", "name": "床铺", "action": "rest",
			"position": Vector2(13 * TILE, 9 * TILE),
			"approach": Vector2(12 * TILE, 10 * TILE),
			"duration": 6.0, "capacity": 1, "permission": "bound",
		},
		{
			"id": "garden", "name": "菜地", "action": "observe",
			"position": Vector2(19 * TILE, 10 * TILE),
			"approach": Vector2(19 * TILE, 11 * TILE),
			"duration": 4.0, "capacity": 1, "permission": "bound",
		},
		{
			"id": "table", "name": "小桌", "action": "interact",
			"position": Vector2(15 * TILE + 16, 8 * TILE),
			"approach": Vector2(14 * TILE, 9 * TILE),
			"duration": 2.0, "capacity": 1, "permission": "bound",
		},
	]


static func props() -> Array[Dictionary]:
	var house_tiles: Array[Dictionary] = []
	var rows := [
		[52, 53, 54, 53, 52, 53],
		[64, 65, 66, 65, 64, 65],
		[72, 73, 72, 73, 72, 73],
		[72, 73, 72, 73, 72, 73],
		[72, 73, 86, 87, 73, 72],
	]
	for row in range(rows.size()):
		for column in range(rows[row].size()):
			house_tiles.append({
				"source": "town", "index": rows[row][column],
				"cell": Vector2i(column, row),
			})
	return [
		{
			"id": "house", "name": "小屋", "kind": "house",
			"base": Vector2(9 * TILE, 2 * TILE), "tiles": house_tiles,
			"hit_rect": Rect2(9 * TILE, 2 * TILE, 6 * TILE, 5 * TILE),
			"obstacle": Rect2(9 * TILE, 5 * TILE, 6 * TILE, 2 * TILE),
			"interaction": "enter_house",
		},
		{
			"id": "tree_west", "name": "向阳树", "kind": "tree",
			"base": Vector2(2 * TILE, 9 * TILE),
			"tiles": [{"source": "farm", "index": 26, "cell": Vector2i.ZERO}],
			"hit_rect": Rect2(2 * TILE, 7 * TILE, 32, 32),
			"obstacle": Rect2(2 * TILE + 8, 8 * TILE, 16, 16),
			"scale": 2,
		},
		{
			"id": "tree_east", "name": "微风树", "kind": "tree",
			"base": Vector2(22 * TILE, 5 * TILE),
			"tiles": [{"source": "farm", "index": 26, "cell": Vector2i.ZERO}],
			"hit_rect": Rect2(22 * TILE, 3 * TILE, 32, 32),
			"obstacle": Rect2(22 * TILE + 8, 4 * TILE, 16, 16),
			"scale": 2,
		},
		{
			"id": "bench", "name": "木长椅", "kind": "bench",
			"base": Vector2(5 * TILE, 13 * TILE),
			"tiles": [{"source": "farm", "index": 96, "cell": Vector2i.ZERO}],
			"hit_rect": Rect2(5 * TILE, 12 * TILE, 32, 24),
			"obstacle": Rect2(5 * TILE, 13 * TILE, 32, 12),
			"scale": 2,
		},
		{
			"id": "table", "name": "小桌", "kind": "table",
			"base": Vector2(15 * TILE, 9 * TILE),
			"tiles": [{"source": "farm", "index": 97, "cell": Vector2i.ZERO}],
			"hit_rect": Rect2(15 * TILE, 7 * TILE, 32, 32),
			"obstacle": Rect2(15 * TILE, 8 * TILE, 32, 12),
			"scale": 2,
		},
	]


static func crops() -> Array[Dictionary]:
	return [
		{"cell": Vector2i(17, 8), "index": 17},
		{"cell": Vector2i(18, 8), "index": 20},
		{"cell": Vector2i(19, 8), "index": 32},
		{"cell": Vector2i(20, 8), "index": 44},
		{"cell": Vector2i(21, 8), "index": 17},
		{"cell": Vector2i(17, 9), "index": 20},
		{"cell": Vector2i(18, 9), "index": 17},
		{"cell": Vector2i(19, 9), "index": 44},
		{"cell": Vector2i(20, 9), "index": 32},
		{"cell": Vector2i(21, 9), "index": 20},
	]
