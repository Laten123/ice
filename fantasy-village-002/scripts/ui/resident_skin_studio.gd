extends Control
const V=preload("res://scripts/puppet/validator.gd")
const Store=preload("res://scripts/puppet/store.gd")
const Lib=preload("res://scripts/puppet/library.gd")
const Stage=preload("res://scripts/puppet/stage.gd")
signal skin_applied(path: String)
var store=Store.new()
var skin: Dictionary={}
var report: Dictionary={}
var stage=Stage.new()
var selected_action="idle"
var selected_direction="front"
var skin_select=OptionButton.new()
var direction_select=OptionButton.new()
var action_select=OptionButton.new()
var fixture_select=OptionButton.new()
var zoom_select=OptionButton.new()
var loop_control=CheckButton.new()
var review=CheckBox.new()
var status=Label.new()
var validation=Label.new()
var title_input=LineEdit.new()
var author_input=LineEdit.new()
var path_input=LineEdit.new()
var grid=GridContainer.new()
var preview_scroll=ScrollContainer.new()
var controls_scroll=ScrollContainer.new()
var controls=VBoxContainer.new()
var _web_callback
var _ready_done=false
func _ready() -> void:
	name="ResidentSkinStudio";z_index=1000;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg=ColorRect.new();bg.color=Color("f1efe7");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bg)
	var margin=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,10)
	add_child(margin);var box=VBoxContainer.new();margin.add_child(box)
	var head=HBoxContainer.new();box.add_child(head)
	var label=Label.new();label.text="居民换皮工作台";label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(label)
	button(head,"返回家园",func():queue_free(),"CloseStudio").size_flags_horizontal=Control.SIZE_SHRINK_END
	grid.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(grid)
	preview_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;preview_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;grid.add_child(preview_scroll)
	stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stage.size_flags_vertical=Control.SIZE_EXPAND_FILL;preview_scroll.add_child(stage)
	controls_scroll.custom_minimum_size.x=300;controls_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;controls_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;grid.add_child(controls_scroll)
	controls.size_flags_horizontal=Control.SIZE_EXPAND_FILL;controls.add_theme_constant_override("separation",7);controls_scroll.add_child(controls)
	label_field("皮肤",skin_select,"SkinSelect");skin_select.item_selected.connect(func(i):load_path(skin_select.get_item_metadata(i)))
	label_field("方向",direction_select,"DirectionSelect")
	for d in ["正面","左侧","右侧","背面"]:direction_select.add_item(d)
	direction_select.item_selected.connect(func(i):selected_direction=Lib.rig().directions[i];choose_action())
	label_field("动作（不支持的朝向不会回退）",action_select,"ActionSelect")
	for id in Lib.actions():action_select.add_item(Lib.actions()[id].label);action_select.set_item_metadata(action_select.item_count-1,id)
	action_select.item_selected.connect(func(i):selected_action=action_select.get_item_metadata(i);choose_action(true))
	label_field("设施：共享家园锚点与遮挡",fixture_select,"FixtureSelect")
	for fixture in ["自动","空白","长椅","书桌","床铺","房门","茶座"]:fixture_select.add_item(fixture)
	fixture_select.item_selected.connect(func(_i):set_fixture())
	label_field("最近邻放大",zoom_select,"ZoomSelect")
	for n in [1,2,4,8]:zoom_select.add_item(str(n)+"×")
	zoom_select.select(2);zoom_select.item_selected.connect(func(i):stage.zoom=[1,2,4,8][i];center_preview())
	var row=HBoxContainer.new();controls.add_child(row)
	button(row,"播放",func():stage.puppet.playing=true,"Play")
	button(row,"暂停",func():stage.puppet.playing=false,"Pause")
	button(row,"重播",func():choose_action(),"Restart")
	row=HBoxContainer.new();controls.add_child(row)
	button(row,"上一帧",func():step(-1),"PreviousFrame");button(row,"下一帧",func():step(1),"NextFrame")
	button(controls,"中断并恢复待机",func():stage.puppet.interrupt(),"Interrupt")
	loop_control.text="循环播放 / 关闭则单次恢复";loop_control.custom_minimum_size.y=44;loop_control.button_pressed=true;controls.add_child(loop_control);loop_control.toggled.connect(func(value):stage.puppet.looped=value)
	var speed=HSlider.new();speed.min_value=.25;speed.max_value=3;speed.step=.25;speed.value=1;speed.custom_minimum_size.y=44;speed.name="Speed";controls.add_child(speed);speed.value_changed.connect(func(value):stage.puppet.speed=value)
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;controls.add_child(status)
	for pair in [["像素网格","grid"],["关节与锚点","joints"],["脚底与碰撞范围","bounds"],["模拟家园背景 / 关闭为透明棋盘","garden"]]:
		var toggle=CheckButton.new();toggle.text=pair[0];toggle.custom_minimum_size.y=44;controls.add_child(toggle);toggle.toggled.connect(func(value):stage.set(pair[1],value))
	label_field("新皮肤名称",title_input,"SkinName");label_field("制作者（原作署名始终保留）",author_input,"SkinAuthor")
	button(controls,"新建皮肤（复制部件并更换服装配色）",new_skin,"NewSkin")
	button(controls,"保存草稿与元数据",save_draft,"SaveDraft")
	label_field("项目本地目录（桌面）",path_input,"ImportPath");path_input.text="res://skins/forest"
	var local=button(controls,"导入目录（桌面）",func():accept_import(store.import_dir(path_input.text)),"ImportDirectory");local.disabled=OS.has_feature("web")
	button(controls,"选择 ZIP 导入（支持浏览器）",choose_zip,"ImportZIP")
	button(controls,"重新校验",validate_current,"ValidateSkin")
	validation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;validation.custom_minimum_size.y=150;controls.add_child(validation)
	review.text="我已人工检查美术和许可证；元数据不等于授权";review.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;review.custom_minimum_size.y=52;controls.add_child(review)
	button(controls,"导出标准皮肤 ZIP",func():export_current("skin"),"ExportSkin")
	button(controls,"导出全部动作图集 ZIP",func():export_current("atlas"),"ExportAtlas")
	button(controls,"导出当前动作 APNG",func():export_current("preview"),"ExportPreview")
	button(controls,"导出角色四方向 PNG",func():export_current("portrait"),"ExportPortrait")
	button(controls,"应用到已有居民（身份与聊天不变）",apply_skin,"ApplySkin")
	_ready_done=true;refresh_catalog();load_path("res://skins/forest");layout();resized.connect(layout)
func button(parent: Node,text: String,fn: Callable,id: String) -> Button:
	var b=Button.new();b.text=text;b.name=id;b.custom_minimum_size.y=44;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(b);b.pressed.connect(fn);return b
func label_field(text: String,control: Control,id: String) -> void:
	var label=Label.new();label.text=text;controls.add_child(label);control.name=id;control.custom_minimum_size.y=44;controls.add_child(control)
func layout() -> void:
	if not _ready_done:return
	grid.columns=2 if size.x>=720 else 1
	preview_scroll.custom_minimum_size=Vector2(300,280 if size.x>=720 else minf(340,size.y*.42));center_preview()
func center_preview() -> void:
	for i in range(3):await get_tree().process_frame
	if not is_inside_tree():return
	preview_scroll.scroll_horizontal=maxi(0,int((stage.size.x-preview_scroll.size.x)/2))
	preview_scroll.scroll_vertical=maxi(0,int(stage.size.y*.55-preview_scroll.size.y*.68))
func refresh_catalog(selected: String="") -> void:
	skin_select.clear()
	for path in store.catalog():
		var m=JSON.parse_string(FileAccess.get_file_as_string(path.path_join("skin.json")))
		if not m is Dictionary:continue
		skin_select.add_item(m.get("display_name",path));skin_select.set_item_metadata(skin_select.item_count-1,path)
		if path==selected:skin_select.select(skin_select.item_count-1)
func load_path(path: String) -> void:
	accept_import(V.load_skin(path))
func accept_import(value: Dictionary) -> void:
	report=value;review.button_pressed=false
	if not value.ok:show_report();return
	skin=value.skin;stage.puppet.set_skin(skin);title_input.text=skin.manifest.display_name;author_input.text=skin.manifest.author;refresh_catalog(skin.root);choose_action();show_report()
func choose_action(auto_fixture: bool=false) -> void:
	if skin.is_empty():return
	var def=Lib.actions().get(selected_action,{})
	for i in range(action_select.item_count):
		if action_select.get_item_metadata(i)==selected_action:action_select.select(i)
	direction_select.select(Lib.rig().directions.find(selected_direction))
	if auto_fixture and def.get("implemented",false):loop_control.button_pressed=bool(def.loop)
	if not stage.puppet.select(selected_action,selected_direction,loop_control.button_pressed):
		stage.puppet.interrupt();stage.puppet.playing=false;stage.puppet.visible=false;validation.text="动作未实现或方向不支持。支持方向："+str(def.get("directions",[]));return
	stage.puppet.visible=true
	if auto_fixture:fixture_select.select(0)
	set_fixture();center_preview()
func set_fixture() -> void:
	var kinds=["auto","blank","bench","desk","bed","door","tea"]
	var kind=kinds[fixture_select.selected]
	stage.set_fixture(Lib.actions().get(selected_action,{}).get("fixture","blank") if kind=="auto" else kind)
func step(delta: int) -> void:
	if stage.puppet.action_id!=selected_action:
		if not stage.puppet.select(selected_action,selected_direction,false):return
	stage.puppet.seek(stage.puppet.frame+delta)
func new_skin() -> void:
	if skin.is_empty():return
	accept_import(store.save_draft(skin,title_input.text+"·新皮肤",author_input.text,true))
func save_draft() -> void:
	if skin.is_empty():return
	if not skin.root.begins_with("user://"):
		validation.text="内置素材只读，请先新建皮肤。";return
	skin.manifest.display_name=title_input.text;skin.manifest.author=author_input.text;skin.manifest.content_hash="";Store.json_write(skin.root.path_join("skin.json"),skin.manifest);validate_current()
func validate_current() -> void:
	if skin.is_empty():return
	report=V.load_skin(skin.root);show_report()
func show_report() -> void:
	validation.text="自动校验："+str(report.get("status","error"))+"\n错误："+str(report.get("errors",[]))+"\n警告："+str(report.get("warnings",[]))+"\n授权状态：仅有来源元数据，仍需人工核验。"
func apply_skin() -> void:
	validate_current()
	if report.get("ok",false):skin_applied.emit(skin.root);validation.text+="\n已应用；居民UUID、模型及聊天未修改。"
func choose_zip() -> void:
	if OS.has_feature("web"):
		_web_callback=JavaScriptBridge.create_callback(func(args):accept_import(store.import_zip(Marshalls.base64_to_raw(str(args[0])))))
		JavaScriptBridge.get_interface("window").fvSkinImport=_web_callback
		JavaScriptBridge.eval("const p=document.createElement('input');p.type='file';p.accept='.zip';p.onchange=async()=>{let f=p.files[0];if(!f||f.size>8388608)return;let a=new Uint8Array(await f.arrayBuffer()),s='';for(let i=0;i<a.length;i+=8192)s+=String.fromCharCode(...a.subarray(i,i+8192));window.fvSkinImport(btoa(s));};p.click();")
	else:
		var dialog=FileDialog.new();dialog.access=FileDialog.ACCESS_FILESYSTEM;dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE;dialog.filters=PackedStringArray(["*.zip ; Resident Skin"]);add_child(dialog);dialog.file_selected.connect(func(path):accept_import(store.import_zip(FileAccess.get_file_as_bytes(path)));dialog.queue_free());dialog.popup_centered_ratio(.8)
func download(path: String,mime: String) -> void:
	if OS.has_feature("web"):JavaScriptBridge.download_buffer(FileAccess.get_file_as_bytes(path),path.get_file(),mime)
func export_current(kind: String) -> void:
	if kind=="preview" and not stage.puppet.visible:validation.text="不支持的动作/方向不能导出";return
	validate_current()
	if not report.get("ok",false) or not review.button_pressed:validation.text+="\n导出已阻止：请先校验并确认人工审查。";return
	var path="user://studio_exports/"+skin.manifest.skin_id+"-"+kind+(".apng" if kind in ["preview","portrait"] else ".zip")
	var result=store.export_skin(skin,path,true) if kind=="skin" else store.export_atlas(skin,path) if kind=="atlas" else store.export_preview(skin,stage.puppet.action_id,stage.puppet.direction,path)
	if result.ok:
		if kind=="portrait":download(result.png,"image/png")
		else:download(path,"image/apng" if kind=="preview" else "application/zip")
		validation.text+="\n已导出："+ProjectSettings.globalize_path(result.get("png",path) if kind=="portrait" else path)
func _process(_delta: float) -> void:
	if not _ready_done or skin.is_empty():return
	if not stage.puppet.visible:status.text="未播放：动作未实现或方向不支持";return
	status.text="当前 %s / %s · 帧 %d/%d · %.2f×\n%s"%[stage.puppet.action_id,stage.puppet.direction,stage.puppet.frame+1,stage.puppet.sprite_frames.get_frame_count("default"),stage.puppet.speed,stage.puppet.last_event]
