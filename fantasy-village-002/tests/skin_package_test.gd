extends SceneTree
const Store=preload("res://scripts/puppet/store.gd")
const V=preload("res://scripts/puppet/validator.gd")
var checks=0;var failures=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
	else:print("PASS: "+label)
func _init() -> void:
	var store=Store.new("user://package-test-"+str(Time.get_ticks_usec()))
	var result=V.load_skin("res://skins/forest");check(result.ok,"Base validates")
	var draft=store.save_draft(result.skin,"新居民","Studio test",true);check(draft.ok,"Create new actual PNG skin draft")
	if not draft.ok:print(draft);quit(1);return
	var out=store.base.path_join("export.zip")
	check(not store.export_skin(draft.skin,out,false).ok,"Human review acknowledgement required")
	check(store.export_skin(draft.skin,out,true).ok,"Export validated skin")
	var fresh=Store.new(store.base+"-clean")
	var imported=fresh.import_zip(FileAccess.get_file_as_bytes(out));print(imported.get("errors",[]))
	check(imported.ok,"Clean environment reimports actual exported zip")
	if imported.ok:check(imported.skin.manifest.skin_id==draft.skin.manifest.skin_id,"Reimport retains new skin ID")
	check(not V.safe_path("../private.json") and not V.safe_path("res://private.json"),"Reject traversal and absolute resource path")
	check(not Store.inspect_zip(PackedByteArray([1,2,3])).ok,"Reject malformed ZIP")
	check(store.export_atlas(draft.skin,store.base.path_join("atlas.zip")).ok,"Export actual action atlases")
	check(store.export_preview(draft.skin,"walk","front",store.base.path_join("walk.apng")).ok,"Export APNG and direction PNG")
	Store.write("res://docs/puppet/previews/C-walk.apng",FileAccess.get_file_as_bytes(store.base.path_join("walk.apng")))
	Store.write("res://docs/puppet/previews/C-directions.png",FileAccess.get_file_as_bytes(store.base.path_join("walk-directions.png")))
	var original=draft.skin.manifest.duplicate(true)
	for mutation in ["part","anchor","fractional","version","canvas","direction","action","permissions","held","clothing","expression"]:
		var m=original.duplicate(true)
		match mutation:
			"part":m.parts.front.erase("arm_l")
			"anchor":m.parts.front.head.anchor=[99,0]
			"fractional":m.foot_origin=[24.5,40]
			"version":m.rig_version="2.0"
			"canvas":m.canvas=[48.5,48]
			"direction":m.parts.erase("back")
			"action":m.actions.erase("sleep")
			"permissions":m.permissions=["private_memory","credentials"]
			"held":m.held_anchors.right=[45,45]
			"clothing":m.optional_clothing={"script":{}}
			"expression":m.expressions.front.erase("blink")
		Store.json_write(draft.skin.root.path_join("skin.json"),m)
		check(not V.load_skin(draft.skin.root).ok,"Validator rejects "+mutation)
	Store.json_write(draft.skin.root.path_join("skin.json"),original)
	var part_path=draft.skin.root.path_join(original.parts.front.torso.path)
	var saved=FileAccess.get_file_as_bytes(part_path)
	var im=Image.new();im.load_png_from_buffer(saved);im.set_pixel(24,32,Color(1,1,1,.5));Store.write(part_path,im.save_png_to_buffer())
	check(not V.load_skin(draft.skin.root).ok,"Detect non-binary alpha")
	im.load_png_from_buffer(saved);im.set_pixel(0,0,Color.WHITE);Store.write(part_path,im.save_png_to_buffer())
	check(not V.load_skin(draft.skin.root).ok,"Detect missing transparent border")
	Store.write(part_path,saved)
	Store.write(draft.skin.root.path_join("evil.gd"),"extends Node".to_utf8_buffer())
	check(not V.load_skin(draft.skin.root).ok,"Reject executable source even if unreferenced")
	DirAccess.remove_absolute(draft.skin.root.path_join("evil.gd"))
	check(not Store.inspect_zip(unsafe_zip("../skin.json",1)).ok,"ZIP traversal blocked before extraction")
	check(not Store.inspect_zip(unsafe_zip("evil.gd",1)).ok,"ZIP executable blocked before extraction")
	check(not Store.inspect_zip(unsafe_zip("skin.json",9000000)).ok,"ZIP bomb declared size blocked")
	var tamper_path=store.base.path_join("tampered.zip");var reader=ZIPReader.new();reader.open(out)
	var writer=ZIPPacker.new();writer.open(tamper_path)
	for name in reader.get_files():
		var bytes=reader.read_file(name)
		if name=="skin.json":
			var m=JSON.parse_string(bytes.get_string_from_utf8());m.display_name="Tampered";bytes=JSON.stringify(m).to_utf8_buffer()
		writer.start_file(name);writer.write_file(bytes);writer.close_file()
	writer.close();reader.close()
	check(not fresh.import_zip(FileAccess.get_file_as_bytes(tamper_path)).ok,"Content hash detects altered package")
	print("RESULT: %d/%d package checks passed"%[checks-failures,checks]);quit(0 if failures==0 else 1)

func unsafe_zip(name: String,size: int) -> PackedByteArray:
	var header=PackedByteArray();header.resize(46);header.encode_u32(0,0x02014b50);header.encode_u32(24,size);header.encode_u16(28,name.length())
	var data=header+name.to_utf8_buffer();var end=PackedByteArray();end.resize(22);end.encode_u32(0,0x06054b50);end.encode_u16(10,1);end.encode_u32(12,data.size());end.encode_u32(16,0)
	return data+end
