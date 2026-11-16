extends RefCounted
const V=preload("res://scripts/puppet/validator.gd")
const Lib=preload("res://scripts/puppet/library.gd")
const Render=preload("res://scripts/puppet/renderer.gd")
const APNG=preload("res://scripts/puppet/apng.gd")
const LIMIT=8388608
var base="user://resident_skins"
func _init(directory: String="user://resident_skins") -> void:base=directory;DirAccess.make_dir_recursive_absolute(base)
static func write(path: String,data: PackedByteArray) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file=FileAccess.open(path,FileAccess.WRITE)
	if file==null:return false
	file.store_buffer(data);return true
static func json_write(path: String,value) -> bool:return write(path,JSON.stringify(value,"\t",true).to_utf8_buffer())
static func payload_hash(skin: Dictionary) -> String:
	return Lib.content_hash(skin)

func catalog() -> Array:
	var result=["res://skins/forest","res://skins/moon"]
	var file=base.path_join("index.json")
	if FileAccess.file_exists(file):
		var data=JSON.parse_string(FileAccess.get_file_as_string(file))
		if data is Array:
			for path in data:
				if path is String and path.begins_with(base+"/") and FileAccess.file_exists(path.path_join("skin.json")):result.append(path)
	return result
func remember(root: String) -> void:
	var paths=[]
	for path in catalog():
		if path.begins_with(base+"/"):paths.append(path)
	if root not in paths:paths.append(root)
	json_write(base.path_join("index.json"),paths)
func save_draft(skin: Dictionary,title: String,author: String,recolor: bool=true) -> Dictionary:
	var m=skin.manifest.duplicate(true);m.skin_id="draft."+str(Time.get_ticks_usec())+"."+str(randi()%9999);m.display_name=title.strip_edges();m.author=author.strip_edges();m.content_hash=""
	m.modifications.append("Created in Resident Skin Studio; source attribution retained; clothing palette edited." if recolor else "Created as editable Studio draft; source attribution retained.")
	var root=base.path_join(m.skin_id)
	for path in skin.images:
		var im=skin.images[path].duplicate()
		if recolor and ("torso" in path or "arm_" in path):
			for y in range(im.get_height()):
				for x in range(im.get_width()):
					var c=im.get_pixel(x,y)
					if c.a>0 and not(c.r>.7 and c.g>.45):im.set_pixel(x,y,Color.from_hsv(fmod(c.h+.19,1),maxf(c.s,.4),c.v,c.a))
		write(root.path_join(path),im.save_png_to_buffer())
	json_write(root.path_join("skin.json"),m);write(root.path_join("LICENSE.txt"),(m.license+"\n"+m.license_url+"\n"+m.attribution+"\n"+m.source).to_utf8_buffer())
	remember(root);return V.load_skin(root)
func export_skin(skin: Dictionary,path: String,reviewed: bool=false) -> Dictionary:
	var result=V.load_skin(skin.root)
	if not result.ok:return result
	if payload_hash(skin)!=payload_hash(result.skin):return {"ok":false,"errors":["请先保存并重新校验修改"]}
	if not reviewed:return {"ok":false,"errors":["导出前须确认人工美术与许可证检查；元数据不等于授权"]}
	var m=skin.manifest.duplicate(true);m.content_hash=payload_hash(skin)
	var zip=ZIPPacker.new();DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if zip.open(path)!=OK:return {"ok":false,"errors":["无法创建导出包"]}
	zip.start_file("skin.json");zip.write_file(JSON.stringify(m,"\t",true).to_utf8_buffer());zip.close_file()
	for relative in skin.images:
		zip.start_file(relative);zip.write_file(skin.images[relative].save_png_to_buffer());zip.close_file()
	for pair in [["LICENSE.txt",m.license+"\n"+m.license_url+"\n"+m.attribution+"\n"+m.source],["validation.json",JSON.stringify({"status":result.status,"errors":result.errors,"warnings":result.warnings,"manual_review_acknowledged":true,"automatic_review_is_not_copyright_clearance":true})]]:
		zip.start_file(pair[0]);zip.write_file(pair[1].to_utf8_buffer());zip.close_file()
	zip.close();return {"ok":true,"path":path,"hash":m.content_hash}
static func inspect_zip(bytes: PackedByteArray) -> Dictionary:
	if bytes.size()<22 or bytes.size()>LIMIT:return {"ok":false,"errors":["ZIP大小超限或损坏"]}
	var end=-1
	for i in range(bytes.size()-22,maxi(-1,bytes.size()-65558),-1):
		if bytes.decode_u32(i)==0x06054b50:end=i;break
	if end<0:return {"ok":false,"errors":["ZIP目录缺失"]}
	var count=bytes.decode_u16(end+10);var pos=bytes.decode_u32(end+16);var total=0;var names=[]
	if count==0 or count>128 or bytes.decode_u16(end+4)!=0 or bytes.decode_u16(end+6)!=0:return {"ok":false,"errors":["ZIP条目过多/分卷不支持"]}
	for i in range(count):
		if pos+46>bytes.size() or bytes.decode_u32(pos)!=0x02014b50:return {"ok":false,"errors":["ZIP目录损坏"]}
		var size=bytes.decode_u32(pos+24);var length=bytes.decode_u16(pos+28);var next=pos+46+length+bytes.decode_u16(pos+30)+bytes.decode_u16(pos+32)
		if next>bytes.size() or size>LIMIT:return {"ok":false,"errors":["ZIP解压大小超限"]}
		var name=bytes.slice(pos+46,pos+46+length).get_string_from_utf8();var test=name.trim_suffix("/")
		if not V.safe_path(test) or name.to_lower() in names.map(func(p):return p.to_lower()) or ((bytes.decode_u32(pos+38)>>16)&0xf000)==0xa000:return {"ok":false,"errors":["禁止ZIP路径/重复条目/符号链接"]}
		if not name.ends_with("/") and name.get_extension().to_lower() not in ["png","json","txt","md"]:return {"ok":false,"errors":["ZIP含可执行或非资源文件"]}
		if bytes.decode_u16(pos+8)&1 or bytes.decode_u16(pos+10) not in [0,8]:return {"ok":false,"errors":["不支持加密/压缩格式"]}
		total+=size;names.append(name);pos=next
	if total>LIMIT or "skin.json" not in names:return {"ok":false,"errors":["ZIP超限或缺少skin.json"]}
	return {"ok":true,"files":names}
func import_zip(bytes: PackedByteArray) -> Dictionary:
	var inspected=inspect_zip(bytes)
	if not inspected.ok:return inspected
	var token=bytes.hex_encode().sha256_text();var zip_path=base.path_join(token+".zip");write(zip_path,bytes)
	var zip=ZIPReader.new()
	if zip.open(zip_path)!=OK:return {"ok":false,"errors":["ZIP不能读取"]}
	var root=base.path_join(token)
	for name in inspected.files:
		if not name.ends_with("/"):
			var data=zip.read_file(name)
			if data.size()>LIMIT:zip.close();return {"ok":false,"errors":["ZIP异常大小"]}
			write(root.path_join(name),data)
	zip.close();DirAccess.remove_absolute(zip_path)
	var result=V.load_skin(root)
	if result.ok:
		var expected=result.skin.manifest.content_hash
		if expected!="" and expected!=payload_hash(result.skin):return {"ok":false,"errors":["内容哈希不匹配"]}
		remember(root)
	return result
func import_dir(path: String) -> Dictionary:
	var result=V.load_skin(path)
	if not result.ok:return result
	# Copy only validated images, never execute or install input scripts.
	var root=base.path_join("import."+payload_hash(result.skin))
	for rel in result.skin.images:write(root.path_join(rel),result.skin.images[rel].save_png_to_buffer())
	json_write(root.path_join("skin.json"),result.skin.manifest);write(root.path_join("LICENSE.txt"),(result.skin.manifest.attribution+"\n"+result.skin.manifest.license_url).to_utf8_buffer());remember(root)
	return V.load_skin(root)
func export_atlas(skin: Dictionary,path: String) -> Dictionary:
	var zip=ZIPPacker.new();DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if zip.open(path)!=OK:return {"ok":false}
	var metadata={"rig_version":"1.0","skin_id":skin.manifest.skin_id,"frame_size":[48,48],"origin":[24,40],"filter":"nearest","actions":{}}
	for action in skin.manifest.actions:
		var def=Lib.actions()[action]
		if not def.get("implemented",false):continue
		var im=Image.create(48*def.frames.size(),48*def.directions.size(),false,Image.FORMAT_RGBA8)
		for row in range(def.directions.size()):
			for col in range(def.frames.size()):im.blit_rect(Render.frame(skin,action,def.directions[row],col),Rect2i(0,0,48,48),Vector2i(col*48,row*48))
		zip.start_file(action+".png");zip.write_file(im.save_png_to_buffer());zip.close_file()
		metadata.actions[action]={"rows":def.directions,"frames":def.frames.size(),"fps":def.fps,"loop":def.loop}
	zip.start_file("atlas.json");zip.write_file(JSON.stringify(metadata,"\t").to_utf8_buffer());zip.close_file();zip.close();return {"ok":true,"path":path}
func export_preview(skin: Dictionary,action: String,direction: String,path: String) -> Dictionary:
	var frames=[]
	for i in range(Lib.actions()[action].frames.size()):frames.append(Render.frame(skin,action,direction,i))
	write(path,APNG.encode(frames,int(Lib.actions()[action].fps)))
	var sheet=Image.create(192,48,false,Image.FORMAT_RGBA8)
	for i in range(4):sheet.blit_rect(Render.frame(skin,"idle",Lib.rig().directions[i],0),Rect2i(0,0,48,48),Vector2i(i*48,0))
	write(path.get_basename()+"-directions.png",sheet.save_png_to_buffer())
	return {"ok":true,"path":path,"png":path.get_basename()+"-directions.png"}
