extends RefCounted
const Lib=preload("res://scripts/puppet/library.gd")
const Render=preload("res://scripts/puppet/renderer.gd")
const REQUIRED=["head","hair","torso","arm_l","arm_r","leg_l","leg_r"]
const ALLOWED=["schema_version","skin_id","version","display_name","author","author_id","source","license","license_url","attribution","rig_version","canvas","foot_origin","pixel_scale","filter","directions","parts","expressions","optional_clothing","correctives","occlusion","held_anchors","actions","unsupported","modifications","content_hash","thumbnail"]
static func safe_path(path: String) -> bool:
	if path.is_empty() or path.length()>180 or path.begins_with("/") or "\\" in path or ":" in path:return false
	for part in path.split("/"):
		if part in ["",".",".."]:return false
	for c in path:
		if c not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-. /":return false
	return true
static func files(root: String,relative: String="",out: Array=[],depth: int=0) -> Array:
	if depth>5 or out.size()>128:out.append("!limit");return out
	var d=DirAccess.open(root.path_join(relative))
	if d==null:return ["!directory"]
	d.list_dir_begin();var name=d.get_next()
	while name!="" and out.size()<=128:
		var path=relative.path_join(name)
		if not name.ends_with(".import") and not name.ends_with(".uid"):
			if d.is_link(name):out.append("!symlink")
			elif d.current_is_dir():files(root,path,out,depth+1)
			else:out.append(path)
		name=d.get_next()
	d.list_dir_end();return out
static func point(value) -> bool:
	if not value is Array or value.size()!=2:return false
	for n in value:
		if not (n is int or n is float) or n!=int(n):return false
	return true
static func load_skin(root: String) -> Dictionary:
	var errors=[];var warnings=[];var images={}
	var parent=DirAccess.open(root.get_base_dir())
	if parent!=null and parent.is_link(root.get_file()):return {"ok":false,"errors":["禁止符号链接皮肤目录"],"warnings":warnings}
	var list=files(root,"",[])
	for path in list:
		if not safe_path(path) or path.get_extension().to_lower() not in ["png","json","txt","md"]:errors.append("禁止文件/路径："+path)
	if list.size()>128:errors.append("文件数超限")
	if not errors.is_empty():return {"ok":false,"errors":errors,"warnings":warnings}
	var bytes_total=0
	for path in list:
		var item=FileAccess.open(root.path_join(path),FileAccess.READ)
		if item!=null:bytes_total+=item.get_length()
	if bytes_total>8388608:return {"ok":false,"errors":["皮肤目录总大小超限"],"warnings":warnings}
	var file=FileAccess.open(root.path_join("skin.json"),FileAccess.READ)
	var m=null
	if file!=null and file.get_length()<=262144:m=JSON.parse_string(file.get_as_text())
	if not m is Dictionary:return {"ok":false,"errors":["清单不是有效JSON对象或过大"],"warnings":warnings}
	for key in m:
		if key not in ALLOWED:errors.append("未授权清单字段："+str(key))
	for field in ["skin_id","version","display_name","author","author_id","source","license","license_url","attribution"]:
		if not m.get(field) is String or m[field].strip_edges().is_empty():errors.append("缺少元数据："+field)
		elif m[field].length()>2048:errors.append("元数据过长："+field)
	if not safe_path(str(m.get("skin_id",""))) or "/" in str(m.get("skin_id","")) or str(m.get("skin_id","")).length()>64:errors.append("skin_id必须为安全标识符")
	if m.get("schema_version")!=1 or m.get("rig_version")!="1.0":errors.append("不兼容的皮肤或骨架版本")
	if not point(m.get("canvas")) or Lib.v(m.canvas)!=Vector2i(48,48):errors.append("画布必须48×48")
	if not point(m.get("foot_origin")) or Lib.v(m.foot_origin)!=Vector2i(24,40):errors.append("脚底原点必须(24,40)")
	if m.get("pixel_scale")!=1 or m.get("filter")!="nearest":errors.append("必须原生整数像素及最近邻过滤")
	for field in ["parts","expressions","optional_clothing","correctives","held_anchors","unsupported"]:
		if not m.get(field) is Dictionary:errors.append("字段必须为对象："+field)
	for field in ["directions","actions","occlusion","modifications"]:
		if not m.get(field) is Array:errors.append("字段必须为数组："+field)
	if not errors.is_empty():return {"ok":false,"errors":errors,"warnings":warnings}
	var paths=[]
	for dir in Lib.rig().directions:
		if dir not in m.directions or not m.parts.get(dir) is Dictionary:
			errors.append("缺少方向："+dir);continue
		for part in REQUIRED:
			var e=m.parts[dir].get(part,{})
			if not e is Dictionary or not e.get("path") is String or not e.get("anchor") is Array or e.anchor.size()!=2:
				errors.append("缺少部件/锚点："+dir+":"+part);continue
			for n in e.anchor:
				if not (n is float or n is int) or n!=int(n) or n<0 or n>=48:errors.append("锚点越界/非整数："+dir+":"+part)
			if e.path not in paths:paths.append(e.path)
		if not m.expressions.get(dir,{}) is Dictionary:errors.append("表情方向格式错误");continue
		for exp in m.expressions.get(dir,{}):paths.append(m.expressions[dir][exp])
		if dir!="back":
			for exp in ["blink","sleep"]:
				if not m.expressions[dir].has(exp):errors.append("缺少表情："+dir+":"+exp)
	for action in m.correctives:
		if not Lib.actions().has(action):errors.append("未知修形动作："+action);continue
		if not m.correctives[action] is Dictionary:errors.append("修形必须为方向对象");continue
		for dir in m.correctives[action]:
			if dir not in Lib.actions()[action].directions:errors.append("修形方向不兼容");continue
			var sequence=m.correctives[action][dir]
			if not sequence is Array or sequence.size()!=Lib.actions()[action].get("frames",[]).size():errors.append("修形帧数错误");continue
			for path in sequence:paths.append(path)
	for slot in m.optional_clothing:
		if slot not in ["headwear","outerwear"] or not m.optional_clothing[slot] is Dictionary:errors.append("未知服饰槽");continue
		for dir in Lib.rig().directions:
			var e=m.optional_clothing[slot].get(dir,{})
			if not e is Dictionary or not e.get("path") is String or not e.get("anchor") is Array or e.anchor.size()!=2 or e.get("bind") not in REQUIRED:errors.append("服饰绑定不完整");continue
			paths.append(e.path)
			for n in e.anchor:
				if not (n is float or n is int) or n!=int(n) or n<0 or n>=48:errors.append("服饰锚点错误")
	for hand in ["left","right"]:
		var p=m.held_anchors.get(hand,[])
		if not p is Array or p.size()!=2:errors.append("缺少持物手锚点："+hand)
		else:
			for n in p:
				if not (n is float or n is int) or n!=int(n) or n<1 or n>46:errors.append("持物锚点无效")
	for hand in ["left","right"]:
		var p=m.held_anchors.get(hand,[])
		if p is Array and p.size()==2 and (p[0] is float or p[0] is int) and (p[1] is float or p[1] is int):
			if Vector2(Lib.v(p)).distance_to(Vector2(20,32) if hand=="left" else Vector2(28,32))>4:errors.append("持物锚点与手部接缝不匹配")
	var order=[]
	for p in m.occlusion:
		if (p not in REQUIRED+["book"] and not m.optional_clothing.has(p)) or p in order:errors.append("无效/重复遮挡层")
		order.append(p)
	for p in REQUIRED+["book"]+m.optional_clothing.keys():
		if p not in order:errors.append("缺少遮挡层："+p)
	for action in Lib.actions():
		var def=Lib.actions()[action]
		if not def.get("implemented",false):continue
		if action not in m.actions:errors.append("缺少P0动作兼容声明："+action)
	if m.license not in ["CC-BY-4.0","CC0-1.0","MIT","OFL-1.1"]:warnings.append("许可证非内置识别项，需要人工检查授权")
	if not m.source.begins_with("https://"):warnings.append("来源不是可核验的HTTPS链接；授权未核实")
	for path in paths:
		if not path is String or not safe_path(path) or path.get_extension().to_lower()!="png":errors.append("无效PNG路径");continue
		var file_path=root.path_join(path)
		if FileAccess.file_exists(file_path):
			var handle=FileAccess.open(file_path,FileAccess.READ)
			if handle==null:errors.append("PNG无法打开");continue
			if handle.get_length()>1048576:errors.append("PNG文件过大："+path);continue
			var header=handle.get_buffer(24)
			if header.size()!=24 or header.slice(0,8)!=PackedByteArray([137,80,78,71,13,10,26,10]) or ((int(header[16])<<24)|(int(header[17])<<16)|(int(header[18])<<8)|header[19])!=48 or ((int(header[20])<<24)|(int(header[21])<<16)|(int(header[22])<<8)|header[23])!=48:errors.append("PNG头或尺寸错误："+path);continue
		var im=Lib.png(file_path)
		if im==null:errors.append("无法读取PNG："+path);continue
		if im.get_size()!=Vector2i(48,48):errors.append("尺寸错误："+path);continue
		im.convert(Image.FORMAT_RGBA8);images[path]=im
		var partial=false;var edge=false
		for y in range(48):
			for x in range(48):
				var a=im.get_pixel(x,y).a8
				if a not in [0,255]:partial=true
				if a>0 and (x==0 or x==47 or y==0 or y==47):edge=true
		if partial:errors.append("非预期半透明："+path)
		if edge:errors.append("缺少透明边缘："+path)
	if not errors.is_empty():return {"ok":false,"errors":errors,"warnings":warnings}
	var skin={"root":root,"manifest":m,"images":images,"cache":{}}
	for dir in Lib.rig().directions:
		for part in REQUIRED:
			var e=m.parts[dir][part];var at=Lib.v(e.anchor);var nearby=false
			for y in range(maxi(0,at.y-3),mini(48,at.y+4)):
				for x in range(maxi(0,at.x-3),mini(48,at.x+4)):
					if images[e.path].get_pixel(x,y).a>0:nearby=true
			if not nearby:errors.append("部件锚点附近无像素/接缝风险："+dir+":"+part)
		var im=Render.frame(skin,"idle",dir,0);var rect=im.get_used_rect()
		if rect.end.y!=40:errors.append("脚底基准不一致："+dir)
		if rect.size.x>34 or rect.size.y>34:errors.append("部件异常分离："+dir)
		# Detect disconnected major regions, not only metadata dimensions.
		var occupied={}
		for y in range(48):
			for x in range(48):
				if im.get_pixel(x,y).a>0:occupied[Vector2i(x,y)]=true
		var total=occupied.size();var largest=0
		while not occupied.is_empty():
			var queue=[occupied.keys()[0]];occupied.erase(queue[0]);var count=0
			while not queue.is_empty():
				var p=queue.pop_back();count+=1
				for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					var q=p+delta
					if occupied.has(q):occupied.erase(q);queue.append(q)
			largest=maxi(largest,count)
		if total>0 and float(largest)/total<.8:warnings.append("明显断裂/不连通："+dir)
	# Integer template offsets and bounded inter-frame changes; large jumps must not hide in skin data.
	for action in m.actions:
		if not Lib.actions().has(action):warnings.append("未知动作声明："+str(action));continue
		var def=Lib.actions()[action]
		if not def.get("implemented",false):continue
		for dir in def.directions:
			var previous=Vector2.ZERO
			for i in range(def.frames.size()):
				var r=Render.frame(skin,action,dir,i).get_used_rect()
				var center=Vector2(r.get_center())
				if i>0 and center.distance_to(previous)>7:warnings.append("动作帧异常抖动："+action+":"+dir)
				previous=center
	var report={"ok":errors.is_empty(),"status":"error" if not errors.is_empty() else "warning" if not warnings.is_empty() else "pass","errors":errors,"warnings":warnings,"license_status":"metadata_present_not_legal_verification","skin":skin}
	return report
