extends RefCounted
const V=preload("res://scripts/puppet/validator.gd")
const Store=preload("res://scripts/puppet/store.gd")
const PATH="user://resident_appearance_v1.json"
static func bindings() -> Dictionary:
	if not FileAccess.file_exists(PATH):return {}
	var data=JSON.parse_string(FileAccess.get_file_as_string(PATH));return data if data is Dictionary else {}
static func set_skin(uuid: String,path: String) -> bool:
	if not(path.begins_with("res://skins/") or path.begins_with("user://resident_skins/")):return false
	var result=V.load_skin(path)
	if not result.ok:return false
	var data=bindings();data[uuid]={"path":path,"hash":Store.payload_hash(result.skin)};return Store.json_write(PATH,data)
static func get_skin(uuid: String) -> String:
	var entry=bindings().get(uuid,{})
	if not entry is Dictionary:return ""
	var path=entry.get("path","")
	if not path is String or not(path.begins_with("res://skins/") or path.begins_with("user://resident_skins/")):return ""
	var result=V.load_skin(path)
	return path if result.ok and Store.payload_hash(result.skin)==entry.get("hash","") else ""
