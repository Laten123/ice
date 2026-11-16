extends RefCounted
static var _rig: Dictionary = {}
static var _actions: Dictionary = {}
static func rig() -> Dictionary:
	if _rig.is_empty():_rig=JSON.parse_string(FileAccess.get_file_as_string("res://data/puppet/rig.json"))
	return _rig
static func actions() -> Dictionary:
	if _actions.is_empty():_actions=JSON.parse_string(FileAccess.get_file_as_string("res://data/puppet/actions.json")).actions
	return _actions
static func png(path: String) -> Image:
	if FileAccess.file_exists(path):
		var im=Image.new()
		if im.load_png_from_buffer(FileAccess.get_file_as_bytes(path))==OK:return im
	elif ResourceLoader.exists(path):
		var tex=load(path)
		if tex is Texture2D:return tex.get_image()
	return null
static func v(p) -> Vector2i:return Vector2i(int(p[0]),int(p[1]))
