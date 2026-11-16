extends SceneTree
const V=preload("res://scripts/puppet/validator.gd")
const R=preload("res://scripts/puppet/renderer.gd")
const Store=preload("res://scripts/puppet/store.gd")
func _init() -> void:
	var result=V.load_skin("res://skins/moon")
	if not result.ok:printerr(result.errors);quit(1);return
	var skin=result.skin;skin.manifest.correctives={};skin.manifest.correctives.sleep={"front":[]}
	# Bake with exact shared renderer, avoiding a second action implementation.
	var temporary=skin.manifest.correctives;skin.manifest.correctives={}
	for i in range(4):
		var path="parts/sleep-front-%d.png"%i
		Store.write(skin.root.path_join(path),R.frame(skin,"sleep","front",i).save_png_to_buffer());temporary.sleep.front.append(path)
	skin.manifest.correctives=temporary;Store.json_write(skin.root.path_join("skin.json"),skin.manifest)
	print("PASS: four corrective frames baked by shared renderer");quit()
