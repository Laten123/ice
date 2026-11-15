extends RefCounted
## IMAGE-SPACE place markers on approved original 2.5D artwork.
## Stable place IDs and capabilities mirror existing isolated Python V2.
## These are VISUAL locations: not a replacement for server-owned topology/ACL.

const WORLD_ID := "fantasia.first_home.prototype"
const EXTERIOR_SIZE := Vector2(1536.0, 1024.0)
const INTERIOR_SIZE := Vector2(1448.0, 1086.0)
const EXTERIOR := "exterior"
const INTERIOR := "interior"

const EXTERIOR_POINTS := {
    "door": {"pos": Vector2(1004, 604), "label": "木屋门口", "info": "进入室内，看看窗边、书桌和休息角。", "activities": ["stay"], "capacity": 1, "transition": "enter_house"},
    "path": {"pos": Vector2(1084, 713), "label": "门前小路", "info": "家园里连接各个角落的小路。", "activities": ["stay"], "capacity": 4},
    "garden": {"pos": Vector2(1289, 773), "label": "小院草地", "info": "让居民自在散步和停留的院子，不是农场。", "activities": ["stay", "rest"], "capacity": 3},
    "riverside": {"pos": Vector2(449, 696), "label": "河边小径", "info": "沿着水边散步，静静听水声。", "activities": ["stay", "rest"], "capacity": 2},
    "old_tree": {"pos": Vector2(480, 524), "label": "老树下", "info": "树荫下的安静角落，适合休息和独处。", "activities": ["stay", "rest"], "capacity": 2},
    "book_corner": {"pos": Vector2(704, 595), "label": "室外书角", "info": "居民可以在这里阅读，公开日记以后可进入图书馆。", "activities": ["read", "stay"], "capacity": 1},
    "stone_table": {"pos": Vector2(587, 651), "label": "石桌", "info": "可以坐下、阅读、喝茶，邀请朋友交流。", "activities": ["sit", "read", "stay"], "capacity": 2},
    "riverbank": {"pos": Vector2(497, 776), "label": "河岸", "info": "望着水面休息，不能直接踩入深水。", "activities": ["stay", "rest"], "capacity": 2},
    "window": {"pos": Vector2(868, 601), "label": "窗前花圃", "info": "看看木屋的暖光和花草。", "activities": ["stay"], "capacity": 1},
    "stump": {"pos": Vector2(794, 753), "label": "树桩", "info": "居民可以坐一会儿，思考或恢复安静。", "activities": ["sit", "rest", "stay"], "capacity": 1}
}
const INTERIOR_POINTS := {
    "house_entry": {"pos": Vector2(730, 956), "label": "室内门口", "info": "从这里返回院子。", "activities": ["stay"], "capacity": 1, "transition": "exit_house"},
    "window_corner": {"pos": Vector2(373, 461), "label": "窗边角落", "info": "属于小冰喜欢的安静角落。", "activities": ["stay", "rest"], "capacity": 1},
    "writing_desk": {"pos": Vector2(1072, 799), "label": "写字桌", "info": "读书、写作、整理生活记录。", "activities": ["read", "stay"], "capacity": 1},
    "bookcase": {"pos": Vector2(1233, 543), "label": "室内书架", "info": "书本与公开阅读空间，私人日记不向访客公开。", "activities": ["read", "stay"], "capacity": 1},
    "rest_corner": {"pos": Vector2(351, 842), "label": "休息角", "info": "躺下或歇息，保留居民拒绝活动的权利。", "activities": ["rest", "stay"], "capacity": 1}
}

# P1's known neighbor topology + one V2 stump, used only by the isolated
# TEST RESIDENT. Production movement is governed by server-authored events.
const EXTERIOR_TEST_EDGES := [
    ["door", "path"], ["path", "garden"], ["garden", "window"],
    ["path", "old_tree"], ["path", "book_corner"],
    ["old_tree", "book_corner"], ["book_corner", "stone_table"],
    ["stone_table", "riverside"], ["stone_table", "riverbank"],
    ["riverside", "riverbank"], ["stone_table", "stump"],
    ["stump", "path"]
]
const INTERIOR_TEST_EDGES := [
    ["house_entry", "rest_corner"], ["house_entry", "writing_desk"],
    ["rest_corner", "window_corner"], ["writing_desk", "bookcase"],
    ["window_corner", "bookcase"], ["rest_corner", "writing_desk"]
]

static func image_size(scene_id: String) -> Vector2:
    return INTERIOR_SIZE if scene_id == INTERIOR else EXTERIOR_SIZE

static func point_map(scene_id: String) -> Dictionary:
    return INTERIOR_POINTS if scene_id == INTERIOR else EXTERIOR_POINTS

static func known_scene(scene_id: String) -> bool:
    return scene_id == EXTERIOR or scene_id == INTERIOR

static func known_place(scene_id: String, point_id: String) -> bool:
    if not known_scene(scene_id):
        return false
    return point_map(scene_id).has(point_id)

static func point_data(scene_id: String, point_id: String) -> Dictionary:
    if not known_place(scene_id, point_id):
        return {}
    return point_map(scene_id)[point_id]

static func point_position(scene_id: String, point_id: String) -> Vector2:
    if not known_place(scene_id, point_id):
        return Vector2(-1, -1)
    return point_map(scene_id)[point_id]["pos"]

static func valid_activity(scene_id: String, point_id: String, activity: String) -> bool:
    return known_place(scene_id, point_id) and point_data(scene_id, point_id)["activities"].has(activity)

static func test_route(scene_id: String, start_id: String, end_id: String) -> Array[String]:
    # TEST HARNESS ONLY: no server cost, authorization, or AI intention inferred.
    var result: Array[String] = []
    if not known_place(scene_id, start_id) or not known_place(scene_id, end_id):
        return result
    if start_id == end_id:
        result.append(end_id)
        return result
    var links: Array = INTERIOR_TEST_EDGES if scene_id == INTERIOR else EXTERIOR_TEST_EDGES
    var frontier: Array[String] = [start_id]
    var seen: Dictionary = {start_id: true}
    var previous: Dictionary = {}
    while not frontier.is_empty():
        var current: String = frontier.pop_front()
        if current == end_id:
            break
        for pair in links:
            var neighbor: String = ""
            if pair[0] == current:
                neighbor = str(pair[1])
            elif pair[1] == current:
                neighbor = str(pair[0])
            if not neighbor.is_empty() and not seen.has(neighbor):
                seen[neighbor] = true
                previous[neighbor] = current
                frontier.append(neighbor)
    if not seen.has(end_id):
        return result
    var current: String = end_id
    while current != start_id:
        result.push_front(current)
        current = previous[current]
    result.push_front(start_id)
    return result

static func test_corridor(scene_id: String, from_id: String, to_id: String) -> Array[Vector2]:
    # Only OFFLINE TEST geometry, not authoritative Python route data.
    # Prevent the test avatar from cutting straight through furniture.
    var corridor: Array[Vector2] = []
    if scene_id != INTERIOR:
        return corridor
    if from_id == "rest_corner" and to_id == "window_corner":
        corridor.append(Vector2(576, 796))
        corridor.append(Vector2(602, 516))
    elif from_id == "window_corner" and to_id == "rest_corner":
        corridor.append(Vector2(602, 516))
        corridor.append(Vector2(576, 796))
    elif from_id == "writing_desk" and to_id == "bookcase":
        corridor.append(Vector2(1276, 790))
        corridor.append(Vector2(1276, 597))
    elif from_id == "bookcase" and to_id == "writing_desk":
        corridor.append(Vector2(1276, 597))
        corridor.append(Vector2(1276, 790))
    elif from_id == "bookcase" and to_id == "window_corner":
        corridor.append(Vector2(1050, 590))
        corridor.append(Vector2(650, 584))
    elif from_id == "window_corner" and to_id == "bookcase":
        corridor.append(Vector2(650, 584))
        corridor.append(Vector2(1050, 590))
    return corridor
