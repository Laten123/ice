extends RefCounted
static func be(n: int) -> PackedByteArray:return PackedByteArray([(n>>24)&255,(n>>16)&255,(n>>8)&255,n&255])
static func crc(data: PackedByteArray) -> int:
	var value=0xffffffff
	for b in data:
		value^=b
		for i in range(8):value=((value>>1)^0xedb88320) if value&1 else value>>1
	return (value^0xffffffff)&0xffffffff
static func chunk(kind: String,data: PackedByteArray) -> PackedByteArray:
	var body=kind.to_ascii_buffer()+data
	return be(data.size())+body+be(crc(body))
static func encode(frames: Array,fps: int) -> PackedByteArray:
	if frames.is_empty():return PackedByteArray()
	var out=PackedByteArray([137,80,78,71,13,10,26,10]);var sequence=0
	for i in range(frames.size()):
		var png=frames[i].save_png_to_buffer();var pos=8;var pixels=PackedByteArray();var ihdr=PackedByteArray()
		while pos+12<=png.size():
			var length=(int(png[pos])<<24)|(int(png[pos+1])<<16)|(int(png[pos+2])<<8)|int(png[pos+3]);var kind=png.slice(pos+4,pos+8).get_string_from_ascii()
			if kind=="IHDR":ihdr=png.slice(pos+8,pos+8+length)
			if kind=="IDAT":pixels.append_array(png.slice(pos+8,pos+8+length))
			pos+=12+length
		if i==0:out+=chunk("IHDR",ihdr);out+=chunk("acTL",be(frames.size())+be(0))
		var control=be(sequence)+be(frames[i].get_width())+be(frames[i].get_height())+be(0)+be(0)+PackedByteArray([0,1,0,clampi(fps,1,60),0,0]);sequence+=1
		out+=chunk("fcTL",control)
		if i==0:out+=chunk("IDAT",pixels)
		else:out+=chunk("fdAT",be(sequence)+pixels);sequence+=1
	return out+chunk("IEND",PackedByteArray())
