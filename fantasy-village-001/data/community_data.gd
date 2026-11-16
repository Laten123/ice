class_name CommunityData
extends RefCounted
## Initial residents and scene props for milestone 001. All visuals are placeholders.

static func residents() -> Array[Dictionary]:
	return [
		{"id": "owner", "name": "林间", "role": "主人", "description": "社区的主人。点击空地，带我在幻想乡走走。", "color": Color("eaa76b"), "position": Vector2(438, 367), "autonomous": false},
		{"id": "ai_1", "name": "小晴", "role": "AI-01", "description": "喜欢晒太阳的 AI 居民。目前只会散步与说预设台词。", "color": Color("84aeda"), "position": Vector2(515, 290), "autonomous": true},
		{"id": "ai_2", "name": "阿澈", "role": "AI-02", "description": "喜欢观察社区的 AI 居民。目前只会散步与说预设台词。", "color": Color("b59bcf"), "position": Vector2(630, 317), "autonomous": true},
	]

static func objects() -> Array[Dictionary]:
	return [
		{"id": "home", "name": "林间的小屋", "kind": "房屋", "description": "一间阳光充足的小屋。当前仅为场景占位，暂不能进入。", "status": "静静伫立", "position": Vector2(233, 185), "hit_rect": Rect2(151, 81, 166, 139), "obstacle": Rect2(166, 137, 139, 78), "style": "house", "color": Color("d48877")},
		{"id": "community_house", "name": "居民小屋", "kind": "房屋", "description": "AI 居民的小屋。当前只有外观占位，没有室内系统。", "status": "静静伫立", "position": Vector2(718, 175), "hit_rect": Rect2(639, 69, 164, 142), "obstacle": Rect2(651, 128, 138, 78), "style": "house", "color": Color("809bbd")},
		{"id": "notice", "name": "社区告示牌", "kind": "物品", "description": "欢迎来到幻想乡！点击居民查看信息，点击空地让选中的居民移动。", "status": "欢迎来访", "position": Vector2(467, 173), "hit_rect": Rect2(440, 119, 54, 60), "obstacle": Rect2(448, 157, 38, 23), "style": "notice"},
		{"id": "tree_west", "name": "向阳树", "kind": "树木", "description": "一棵明亮的占位树。树荫下很适合发呆。", "status": "枝叶茂盛", "position": Vector2(104, 350), "hit_rect": Rect2(56, 239, 97, 117), "obstacle": Rect2(92, 327, 25, 28), "style": "tree"},
		{"id": "tree_east", "name": "微风树", "kind": "树木", "description": "一棵安静的占位树，和社区一起等待未来的故事。", "status": "枝叶茂盛", "position": Vector2(853, 354), "hit_rect": Rect2(805, 243, 97, 117), "obstacle": Rect2(841, 331, 25, 28), "style": "tree"},
		{"id": "bench", "name": "木长椅", "kind": "物品", "description": "广场边的一张占位长椅。暂未提供坐下或休息系统。", "status": "空闲中", "position": Vector2(645, 420), "hit_rect": Rect2(596, 381, 99, 47), "obstacle": Rect2(596, 401, 99, 23), "style": "bench"},
	]
