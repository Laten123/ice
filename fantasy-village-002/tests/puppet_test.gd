extends SceneTree
const Validator=preload("res://scripts/puppet/validator.gd")
const Player=preload("res://scripts/puppet/player.gd")
const Lib=preload("res://scripts/puppet/library.gd")
var checks=0;var failures=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
	else:print("PASS: "+label)
func _init() -> void:call_deferred("run")
func run() -> void:
	for name in ["forest","moon"]:
		var result=Validator.load_skin("res://skins/"+name)
		print(name," ",result.get("errors",[])," ",result.get("warnings",[]))
		check(result.ok,"Layered skin validates: "+name)
		if not result.ok:continue
		var player=Player.new();root.add_child(player);player.set_process(false);player.set_skin(result.skin)
		for action in Lib.actions():
			var def=Lib.actions()[action]
			if not def.get("implemented",false):check(not player.select(action,"front"),"Unimplemented action rejected");continue
			for dir in def.directions:
				check(player.select(action,dir),name+" shared "+action+":"+dir)
				for frame in range(def.frames.size()):player.seek(frame);check(player.current_image()!=null,"Rendered native frame")
		player.select("open_book","front",false);player.advance(10);check(player.action_id=="idle","Completion restores idle")
		player.select("read","front");player.interrupt();check(player.action_id=="idle","Interruption restores idle")
		player.free()
	print("RESULT: %d/%d puppet checks passed"%[checks-failures,checks]);quit(0 if failures==0 else 1)
