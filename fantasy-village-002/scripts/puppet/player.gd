extends AnimatedSprite2D
const Lib=preload("res://scripts/puppet/library.gd")
const Render=preload("res://scripts/puppet/renderer.gd")
signal action_completed(action_id: String)
signal state_restored(reason: String)
var skin: Dictionary={}
var action_id="idle"
var direction="front"
var playing=true
var looped=true
var speed=1.0
var elapsed=0.0
var last_event=""
func _init() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	offset=Vector2(0,-16) # 48/2 - 40; logical foot stays at node origin.
func set_skin(value: Dictionary) -> void:
	skin=value;refresh()
func select(action: String,dir: String,loop_override=null) -> bool:
	var def=Lib.actions().get(action,{})
	if not def.get("implemented",false) or dir not in def.directions or action not in skin.manifest.actions:return false
	action_id=action;direction=dir;elapsed=0;playing=true;looped=def.loop if loop_override==null else bool(loop_override);refresh();return true
func refresh() -> void:
	if skin.is_empty():return
	var key=action_id+":"+direction
	if not skin.cache.has(key):skin.cache[key]=Render.textures(skin,action_id,direction)
	sprite_frames=SpriteFrames.new();sprite_frames.set_animation_loop("default",false)
	for tex in skin.cache[key]:sprite_frames.add_frame("default",tex)
	animation="default";frame=0;pause()
func seek(index: int) -> void:
	frame=clampi(index,0,sprite_frames.get_frame_count("default")-1);elapsed=float(frame)/Lib.actions()[action_id].fps;playing=false
func interrupt() -> void:
	last_event="中断后恢复待机；持物已清除";select("idle",direction,true);state_restored.emit("interrupted")
func _process(delta: float) -> void:advance(delta)
func advance(delta: float) -> void:
	if not playing or skin.is_empty():return
	elapsed+=delta*speed
	var def=Lib.actions()[action_id];var count=def.frames.size();var i=int(elapsed*def.fps)
	if i>=count and not looped:
		var completed=action_id
		select("idle",direction,true);last_event=completed+" 完成→待机；持物已清除"
		action_completed.emit(completed);state_restored.emit("completed");return
	frame=posmod(i,count)
func current_image() -> Image:return Render.frame(skin,action_id,direction,frame)
