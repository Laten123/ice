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

static func content_hash(skin: Dictionary) -> String:
	var m=skin.manifest.duplicate(true);m.content_hash=""
	var hash=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(JSON.stringify(m,"",true).to_utf8_buffer())
	var paths=skin.images.keys();paths.sort()
	for path in paths:hash.update(path.to_utf8_buffer());hash.update(skin.images[path].save_png_to_buffer())
	return hash.finish().hex_encode()
