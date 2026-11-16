extends RefCounted
const Lib=preload("res://scripts/puppet/library.gd")
static func frame(skin: Dictionary,action: String,direction: String,index: int) -> Image:
	var def=Lib.actions().get(action,{})
	if not def.get("implemented",false) or direction not in def.directions:return null
	var data=def.frames[posmod(index,def.frames.size())]
	var facing=direction
	if action=="turn":
		var ring=["front","left","back","right"]
		facing=ring[posmod(ring.find(direction)+int(data.facing_step),4)]
	var result=Image.create(48,48,false,Image.FORMAT_RGBA8)
	var correction=skin.manifest.correctives.get(action,{}).get(facing,[])
	if not correction.is_empty():return skin.images[correction[posmod(index,correction.size())]].duplicate()
	for part in skin.manifest.occlusion:
		if part=="book":
			if data.book!="none":
				var left=Lib.v(skin.manifest.held_anchors.left);var right=Lib.v(skin.manifest.held_anchors.right)
				var at=(left+right)/2-Vector2i(8,4)+Lib.v(data.offsets.get("torso",[0,0]))+Lib.v(data.offsets.get("book",[0,0]))
				book(result,at,data.book,int(data.page))
			continue
		if not skin.manifest.parts[facing].has(part):continue
		var entry=skin.manifest.parts[facing][part]
		var offset=Lib.v(Lib.rig().joints[part])-Lib.v(entry.anchor)+Lib.v(data.offsets.get(part,[0,0]))
		var im=skin.images[entry.path]
		result.blend_rect(im,Rect2i(Vector2i.ZERO,im.get_size()),offset)
		if part=="hair" and data.expression!="none":
			var path=skin.manifest.expressions.get(facing,{}).get(data.expression,"")
			if skin.images.has(path):result.blend_rect(skin.images[path],Rect2i(0,0,48,48),Lib.v(data.offsets.get("head",[0,0])))
	return result
static func book(im: Image,at: Vector2i,kind: String,page: int) -> void:
	var width=16 if kind=="open" else 9
	im.fill_rect(Rect2i(at,Vector2i(width,7)),Color("70533d"))
	im.fill_rect(Rect2i(at+Vector2i.ONE,Vector2i(width-2,5)),Color("eeddb0"))
	if kind=="open":
		im.fill_rect(Rect2i(at+Vector2i(7,0),Vector2i(1,6)),Color("ac9164"))
		for y in range(1,5):im.set_pixelv(at+Vector2i(8+((page+y)%4),y),Color("c8b184"))
static func textures(skin: Dictionary,action: String,direction: String) -> Array:
	var out=[]
	for i in range(Lib.actions()[action].frames.size()):out.append(ImageTexture.create_from_image(frame(skin,action,direction,i)))
	return out
