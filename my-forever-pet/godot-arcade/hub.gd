extends Control
const GAMES=["Star Catch","Flappy Pet","Cloud Jump","Find My Pet","Pet Dash 3D"]
const GameIcons=preload("res://game_icons.gd")
var store:Node
var title_label:Label
var info:Label
var portrait:TextureRect
var live_stage:SubViewportContainer
var nav_buttons:Dictionary={}
var section_scroll:ScrollContainer
var status_values:Array[Label]=[]
var stage_title:Label
var action_grid:GridContainer
var last_menu_width=0.0
var meter_panel:Control
var room_strip:HBoxContainer
var identity_art:TextureRect
var xp_bar:ProgressBar
var menu_dock:HBoxContainer
var skin_cache:Dictionary={}
var room_tiles:Dictionary={}
var feedback_layer:Control
var feedback_serial=0
var room_scroll:ScrollContainer
var stage_space:Control
var daily_cta:Button
var collection_filter="All"
var collection_feature=3
var collection_grid:GridContainer
const FAMILIES=["Sprout","Cat","Dog","Dragon","Fish","Alien","Dinosaur","Jelly","Bird","Fairy","Rabbit","Owl"]
const ACTION_COLORS={"bond":"#e967a5","food":"#e5a44d","clean":"#4abce9","play":"#ae78ed","sleep":"#6e91e8","daily":"#ecb15c"}
var context_labels:Dictionary={}
var context_bars:Dictionary={}
var cell_tiles:Array[Button]=[]
const ACTION_ART={"bond":"premium_egg.png","food":"premium_snack.png","daily":"premium_coin.png","clean":"item_3.png","play":"premium_star.png","sleep":"item_4.png","lamp":"item_4.png","hatch":"premium_egg.png","soap":"premium_medicine.png","rinse":"item_3.png","toilet":"item_3.png","cook":"premium_snack.png","snack":"premium_snack.png","plant":"item_5.png","harvest":"premium_crystal.png","toy":"premium_star.png","medicine":"premium_medicine.png","craft":"premium_crystal.png"}
const NAV_ART={"Home":"item_4.png","Care":"premium_snack.png","Rooms":"item_3.png","Arcade":"premium_star.png","Shop":"premium_coin.png","Journal":"premium_crystal.png","World":"pet_8.png","Cell":"premium_medicine.png"}
var wear_layers:Array[TextureRect]=[]
var last_wear_key=""
var wardrobe_card:Button
var pet_bob_time=0.0
var bg:TextureRect
var actions:VBoxContainer
var section="Home"
var current_room=""
var rendered_stage=-1
var egg_visual:Label
var face:Label
var room_tag:Label
var outfit_label:Label
var egg_art:TextureRect
var visual:Control
var hotspot_layer:Control
var room_layout:Dictionary={}
var room_key=""
var assets:Dictionary={}
const ROOMS={"Kitchen":"room_kitchen","Bathroom":"room_bathroom","Bedroom":"room_bedroom","Toy room":"room_toy","Garden":"room_garden","Potion lab":"room_lab"}
func tex(path:String)->Texture2D:
	if not assets.has(path) and ResourceLoader.exists(path): assets[path]=load(path)
	return assets.get(path) as Texture2D
var stats:Array[ProgressBar]=[]
var notice:Label
var clock_label:Label
var body:VBoxContainer
func _ready():
	var args=OS.get_cmdline_user_args()
	for flag in ["--test","--soak","--capture","--lane-only","--unassisted"]:
		if args.has(flag):
			get_tree().call_deferred("change_scene_to_file","res://main.tscn")
			return
	store=get_node("/root/PetStore")
	if args.has("--home-test"):
		call_deferred("test_home")
		return
	if args.has("--home-capture"):
		call_deferred("capture_home")
		return
	make_ui()
	refresh()
	var t=Timer.new(); t.wait_time=1; t.timeout.connect(refresh); add_child(t); t.start()
func style(color:Color,border:Color,r:int=16)->StyleBoxFlat:
	var b=StyleBoxFlat.new(); b.bg_color=color; b.border_color=border; b.set_border_width_all(2); b.set_corner_radius_all(r); b.shadow_color=Color("#09132980"); b.shadow_size=3
	b.content_margin_left=12; b.content_margin_right=12; b.content_margin_top=8; b.content_margin_bottom=8
	return b
func label(parent:Node,value:String,sz:int=18)->Label:
	var l=Label.new(); l.text=value; l.add_theme_font_size_override("font_size",sz); l.autowrap_mode=TextServer.AUTOWRAP_OFF; parent.add_child(l); return l
# Reusable 9-slice game skin: real curved bevel, gloss, tinted rim and shadow.
# Generated locally in Godot, no flattened concept image or AI asset.
func skin(tint:Color,edge:Color,pressed:bool=false)->StyleBoxTexture:
	var key=str(tint)+str(edge)+str(pressed)
	if skin_cache.has(key): return skin_cache[key]
	var im=Image.create(96,96,false,Image.FORMAT_RGBA8)
	for y in range(96):
		for x in range(96):
			var q=Vector2(absf(x-47.5)-27.0,absf(y-46.5)-27.0)
			var d=q.max(Vector2.ZERO).length()+minf(maxf(q.x,q.y),0.0)-16.0
			var t=float(y)/95.0
			var c=tint.lightened(.21*(1-t)).darkened(.28*t)
			var sheen=exp(-pow((t-.14)*6,2))*.13
			c=c.lightened(sheen)
			if d>-1.8:
				c=edge.lightened(.27*(1-t))
			elif d>-4:
				c=edge.lerp(tint,.40)
			else:
				c=c.lightened(exp(-absf(d+5)*.33)*.10)
			if pressed: c=c.darkened(.17)
			if d>0:
				c=edge
				c.a=exp(-d*.65)*.5
			else: c.a=1
			im.set_pixel(x,y,c)
	var s=StyleBoxTexture.new()
	s.texture=ImageTexture.create_from_image(im)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		s.set_texture_margin(side,22)
		s.set_content_margin(side,8)
	skin_cache[key]=s
	return s
func bar_skin(tint:Color,edge:Color)->StyleBoxTexture:
	var key="bar"+str(tint)+str(edge)
	if skin_cache.has(key): return skin_cache[key]
	var b=skin(tint,edge).duplicate() as StyleBoxTexture
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		b.set_texture_margin(side,4)
		b.set_content_margin(side,0)
	skin_cache[key]=b
	return b
func button(parent:Node,value:String,fn:Callable)->Button:
	var b=Button.new(); b.text=value; b.custom_minimum_size=Vector2(0,48); b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size",18)
	b.add_theme_stylebox_override("normal",skin(Color("#222b56"),Color("#777fd0")))
	b.add_theme_stylebox_override("pressed",skin(Color("#473b78"),Color("#a3dfff"),true))
	b.add_theme_stylebox_override("hover",skin(Color("#344575"),Color("#9fdcff")))
	b.focus_mode=FOCUS_NONE
	b.pressed.connect(fn); parent.add_child(b); return b
func row(parent:Node)->HBoxContainer:
	var h=HBoxContainer.new(); h.add_theme_constant_override("separation",8); parent.add_child(h); return h
func panel(parent:Node)->VBoxContainer:
	var p=PanelContainer.new(); p.add_theme_stylebox_override("panel",style(Color("#251d47ef"),Color("#9583d2"),21)); parent.add_child(p)
	var v=VBoxContainer.new(); v.add_theme_constant_override("separation",7); p.add_child(v); return v
func make_ui():
	var backdrop=ColorRect.new(); backdrop.color=Color("#110e29"); backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(backdrop)
	var margin=MarginContainer.new(); margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT); margin.add_theme_constant_override("margin_left",8); margin.add_theme_constant_override("margin_right",8); margin.add_theme_constant_override("margin_top",7); margin.add_theme_constant_override("margin_bottom",7); margin.mouse_filter=MOUSE_FILTER_IGNORE; add_child(margin)
	var layout=VBoxContainer.new(); layout.mouse_filter=MOUSE_FILTER_IGNORE; layout.add_theme_constant_override("separation",5); margin.add_child(layout)
	var brand=row(layout)
	var logo=label(brand,"My Forever Pet",23); logo.size_flags_horizontal=SIZE_EXPAND_FILL; logo.add_theme_color_override("font_color",Color("#f3d8ff")); logo.add_theme_color_override("font_outline_color",Color("#63369a")); logo.add_theme_constant_override("outline_size",6)
	var settings=button(brand,"⚙",func(): select("More")); settings.size_flags_horizontal=SIZE_SHRINK_END; settings.custom_minimum_size=Vector2(43,34)
	var header=panel(layout)
	var head=row(header)
	identity_art=TextureRect.new(); identity_art.custom_minimum_size=Vector2(48,48); identity_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; identity_art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; head.add_child(identity_art)
	var identity=VBoxContainer.new(); identity.size_flags_horizontal=SIZE_EXPAND_FILL; identity.add_theme_constant_override("separation",2); head.add_child(identity)
	title_label=label(identity,"Mosskit",21); title_label.clip_text=true
	xp_bar=ProgressBar.new(); xp_bar.show_percentage=false; xp_bar.custom_minimum_size.y=8; xp_bar.max_value=100
	xp_bar.add_theme_stylebox_override("background",bar_skin(Color("#101530"),Color("#5e6caa")))
	xp_bar.add_theme_stylebox_override("fill",bar_skin(Color("#9465e5"),Color("#c9a7ff")))
	identity.add_child(xp_bar)
	var currency=VBoxContainer.new(); currency.add_theme_constant_override("separation",2); head.add_child(currency)
	info=label(currency,"0 coins | 0 gems",15); info.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	clock_label=label(currency,"00:00",12); clock_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	stage_space=Control.new(); stage_space.custom_minimum_size.y=240; stage_space.size_flags_vertical=SIZE_EXPAND_FILL; stage_space.mouse_filter=MOUSE_FILTER_IGNORE; layout.add_child(stage_space)
	stage_space.resized.connect(position_hotspots)
	visual=Control.new(); visual.clip_contents=true; visual.set_anchors_and_offsets_preset(PRESET_FULL_RECT); visual.anchor_top=.11; visual.anchor_bottom=.86; add_child(visual); move_child(visual,1)
	visual.resized.connect(position_hotspots)
	if FileAccess.file_exists("res://assets/room_layout.json"):
		var raw=JSON.parse_string(FileAccess.get_file_as_string("res://assets/room_layout.json"))
		if raw is Dictionary: room_layout=raw
	bg=TextureRect.new(); bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT); bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; bg.stretch_mode=TextureRect.STRETCH_SCALE; visual.add_child(bg)
	var fallback=ColorRect.new(); fallback.color=Color("#436c6b"); fallback.set_anchors_and_offsets_preset(PRESET_FULL_RECT); visual.add_child(fallback); visual.move_child(fallback,0)
	live_stage=preload("res://live_pet_stage.gd").new(); live_stage.set_anchors_and_offsets_preset(PRESET_FULL_RECT); visual.add_child(live_stage)
	portrait=TextureRect.new(); portrait.set_anchors_and_offsets_preset(PRESET_CENTER); portrait.offset_left=-105; portrait.offset_right=105; portrait.offset_top=-95; portrait.offset_bottom=115; portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; visual.add_child(portrait)
	portrait.mouse_filter=MOUSE_FILTER_IGNORE
	for slot in range(5):
		var layer=TextureRect.new()
		layer.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		layer.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		layer.mouse_filter=MOUSE_FILTER_IGNORE
		portrait.add_child(layer)
		wear_layers.append(layer)
	egg_visual=Label.new(); egg_visual.text="◉"; egg_visual.add_theme_font_size_override("font_size",120); egg_visual.add_theme_color_override("font_color",Color("#ffe8b9")); egg_visual.set_anchors_and_offsets_preset(PRESET_CENTER); egg_visual.offset_left=-65; egg_visual.offset_top=-90; visual.add_child(egg_visual)
	face=Label.new(); face.text="• ᴗ •"; face.add_theme_font_size_override("font_size",29); face.add_theme_color_override("font_color",Color("#28202c")); face.set_anchors_and_offsets_preset(PRESET_CENTER); face.offset_left=-39; face.offset_top=-7; visual.add_child(face)
	room_tag=Label.new(); room_tag.add_theme_font_size_override("font_size",18); room_tag.position=Vector2(14,118); room_tag.add_theme_color_override("font_outline_color",Color("#15213e")); room_tag.add_theme_constant_override("outline_size",5); room_tag.mouse_filter=MOUSE_FILTER_IGNORE; visual.add_child(room_tag)
	outfit_label=Label.new(); outfit_label.add_theme_font_size_override("font_size",14); outfit_label.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE); outfit_label.offset_top=-31; outfit_label.offset_bottom=-3; outfit_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; visual.add_child(outfit_label)
	var touch=Button.new(); touch.flat=true; touch.focus_mode=FOCUS_NONE; touch.set_anchors_and_offsets_preset(PRESET_FULL_RECT); touch.pressed.connect(func(): live_stage.tap(); perform("hatch" if store.s.stage==0 else "bond")); visual.add_child(touch)
	egg_art=TextureRect.new(); egg_art.texture=tex("res://assets/premium_egg.png"); egg_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; egg_art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; egg_art.set_anchors_and_offsets_preset(PRESET_CENTER); egg_art.offset_left=-75; egg_art.offset_right=75; egg_art.offset_top=-80; egg_art.offset_bottom=70; egg_art.mouse_filter=MOUSE_FILTER_IGNORE; visual.add_child(egg_art)
	hotspot_layer=Control.new(); hotspot_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT); hotspot_layer.mouse_filter=MOUSE_FILTER_IGNORE; visual.add_child(hotspot_layer)
	feedback_layer=Control.new(); feedback_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT); feedback_layer.mouse_filter=MOUSE_FILTER_IGNORE; visual.add_child(feedback_layer)
	var meter_shell=panel(layout)
	meter_panel=meter_shell.get_parent()
	layout.move_child(meter_panel,2)
	var meters=row(meter_shell)
	var colors=[Color("#ffba60"),Color("#ff79b4"),Color("#63dfff"),Color("#bf8aff")]
	for i in range(4):
		var column=VBoxContainer.new(); column.size_flags_horizontal=SIZE_EXPAND_FILL; column.add_theme_constant_override("separation",1); meters.add_child(column)
		var top=row(column); top.add_theme_constant_override("separation",3)
		var emblem=TextureRect.new(); emblem.texture=GameIcons.texture(["food","mood","energy","bond"][i]); emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; emblem.custom_minimum_size=Vector2(28,28); top.add_child(emblem)
		var values=VBoxContainer.new(); values.size_flags_horizontal=SIZE_EXPAND_FILL; values.add_theme_constant_override("separation",0); top.add_child(values)
		var name=label(values,["Food","Mood","Energy","Bond"][i],11); name.modulate=colors[i].lightened(.3)
		var value=label(values,"100%",17); status_values.append(value)
		var p=ProgressBar.new(); p.custom_minimum_size.y=4; p.show_percentage=false
		var track=StyleBoxFlat.new(); track.bg_color=Color("#362c51"); track.set_corner_radius_all(4)
		var filled=StyleBoxFlat.new(); filled.bg_color=colors[i]; filled.set_corner_radius_all(4)
		p.add_theme_stylebox_override("background",track); p.add_theme_stylebox_override("fill",filled); column.add_child(p); stats.append(p)
	notice=label(layout,"Tap your pet or an object",13)
	notice.clip_text=true
	section_scroll=ScrollContainer.new(); section_scroll.custom_minimum_size.y=88; section_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; layout.add_child(section_scroll)
	body=VBoxContainer.new(); body.size_flags_horizontal=SIZE_EXPAND_FILL; section_scroll.add_child(body)
	actions=body
	daily_cta=button(layout,"Daily Reward   ›",func(): perform("daily")); daily_cta.custom_minimum_size.y=43; daily_cta.icon=GameIcons.texture("daily"); daily_cta.expand_icon=true; daily_cta.add_theme_constant_override("icon_max_width",36); daily_cta.add_theme_stylebox_override("normal",skin(Color("#7747a8"),Color("#ffd38c")))
	room_scroll=ScrollContainer.new(); room_scroll.custom_minimum_size.y=64; room_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; room_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO; layout.add_child(room_scroll)
	room_strip=row(room_scroll); room_strip.size_flags_horizontal=SIZE_EXPAND_FILL
	room_strip.add_theme_constant_override("separation",5)
	for name in ["Bedroom","Kitchen","Bathroom","Toy room","Garden","Potion lab"]:
		var b=art_tile(room_strip,name,"res://assets/"+ROOMS[name]+".jpg",func(): room(name),59,12)
		b.custom_minimum_size.x=80
		room_tiles[name]=b
	var dock_shell=panel(layout)
	menu_dock=row(dock_shell); menu_dock.add_theme_constant_override("separation",2)
	for tab in ["Home","Pets","Rooms","Arcade","Shop","More"]: nav_tile(menu_dock,tab)
	select("Home")
func art_tile(parent:Node,name:String,path:String,fn:Callable,h:int=66,font:int=13,icon_key:String="")->Button:
	var b=button(parent,"",fn)
	b.custom_minimum_size=Vector2(0,h)
	b.size_flags_horizontal=SIZE_EXPAND_FILL
	b.tooltip_text=name
	var v=VBoxContainer.new(); v.set_anchors_and_offsets_preset(PRESET_FULL_RECT); v.offset_left=4; v.offset_right=-4; v.offset_top=4; v.offset_bottom=-4; v.mouse_filter=MOUSE_FILTER_IGNORE; v.add_theme_constant_override("separation",1); b.add_child(v)
	var image=TextureRect.new(); image.texture=GameIcons.texture(icon_key) if not icon_key.is_empty() else null
	if image.texture==null: image.texture=tex(path)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; image.size_flags_vertical=SIZE_EXPAND_FILL; image.mouse_filter=MOUSE_FILTER_IGNORE; v.add_child(image)
	var l=label(v,name,font); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; l.clip_text=true; l.mouse_filter=MOUSE_FILTER_IGNORE
	return b
func nav_tile(parent:Node,tab:String):
	var art="premium_crystal.png" if tab=="More" else str(NAV_ART.get(tab,"premium_star.png"))
	var b=art_tile(parent,tab,"res://assets/"+art,func(): select(tab),61,12,"bond" if tab=="Pets" else tab)
	b.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	nav_buttons[tab]=b
func reset_actions(columns:int=0):
	context_labels.clear(); context_bars.clear(); cell_tiles.clear()
	for child in actions.get_children(): actions.remove_child(child); child.queue_free()
	action_grid=null
	if columns>0:
		action_grid=GridContainer.new()
		action_grid.columns=columns
		action_grid.add_theme_constant_override("h_separation",6)
		action_grid.add_theme_constant_override("v_separation",5)
		actions.add_child(action_grid)
func time_text(seconds:int)->String:
	if seconds>=3600: return "%dh %02dm"%[int(seconds/3600),int(seconds/60)%60]
	return "%02d:%02d"%[int(seconds/60),seconds%60]
func context_card(key:String,title:String)->VBoxContainer:
	var shell=panel(actions)
	label(shell,title,20)
	var value=label(shell,"",15); value.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	context_labels[key]=value
	return shell
func context_meter(parent:Node,key:String,color:Color):
	var p=ProgressBar.new(); p.custom_minimum_size.y=14; p.show_percentage=false
	p.add_theme_stylebox_override("background",bar_skin(Color("#121a35"),Color("#65739c")))
	p.add_theme_stylebox_override("fill",bar_skin(color.darkened(.15),color.lightened(.3)))
	parent.add_child(p); context_bars[key]=p
func quick(name:String,id:String,i:int=0):
	var path="res://assets/"+str(ACTION_ART.get(id,"premium_star.png"))
	var b=art_tile(action_grid,name,path,func(): perform(id,i),82 if section=="Home" else 66,13,id)
	if section=="Home": paint_action(b,id)
func paint_action(b:Button,id:String):
	var tint=Color(ACTION_COLORS.get(id,"#9271d9"))
	b.add_theme_stylebox_override("normal",skin(tint.darkened(.55),tint.lightened(.40)))
	b.add_theme_stylebox_override("pressed",skin(tint.darkened(.30),tint.lightened(.58),true))
func perform(id:String,i:int=0):
	var before:Dictionary=store.s.duplicate(true)
	var ok:bool=store.action(id,i)
	if ok:
		var changes:Array[String]=[]
		for key in ["coins","hunger","happy","energy","bond","xp","hygiene","materials","crystals"]:
			var d=int(store.s[key])-int(before[key])
			if d!=0: changes.append(("%+d "%d)+str({"hunger":"food","happy":"mood","xp":"XP"}.get(key,key)))
		notice.text="  •  ".join(changes) if not changes.is_empty() else "Done!"
	else:
		notice.text=reason_for(id,i)
	refresh()
	if ok:
		live_stage.react(id,store.asleep(store.now()))
		if visual.visible: show_feedback(notice.text,id)
	if section=="Shop": select("Shop")
func reason_for(id:String,i:int)->String:
	var s:Dictionary=store.s
	if s.stage==0: return "Hatch your egg first"
	if id=="daily": return "Daily gift already collected"
	if id=="clean" and s.waste==0: return "Your room is already clean"
	if id in ["food","cook"] and s.hunger>=5: return "Your pet is full"
	if id=="food" and i>=0 and i<4 and s.coins<store.FOOD_COST[i]: return "Not enough coins"
	if id=="plant" and s.garden_at>0: return "Your crop is growing"
	if id=="harvest": return "The crop is not ready yet"
	if id=="cell" and s.germs==0: return "All cells are healthy"
	if id=="soap" and s.hygiene>=100: return "Your pet is already clean"
	if id=="rinse" and s.soap==0: return "Apply soap first"
	if store.asleep(store.now()): return "Your pet is resting"
	if s.trip_end>store.now(): return "Your pet is on an expedition"
	return "Check the activity requirements"
func show_feedback(message:String,id:String):
	if not is_instance_valid(feedback_layer): return
	feedback_serial+=1
	for child in feedback_layer.get_children(): child.queue_free()
	var p=PanelContainer.new()
	p.mouse_filter=MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel",skin(Color("#36265d"),Color("#c6acff")))
	p.set_anchors_and_offsets_preset(PRESET_CENTER_TOP)
	p.offset_left=-170; p.offset_right=170; p.offset_top=40; p.offset_bottom=80
	feedback_layer.add_child(p)
	var l=label(p,message,16); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.mouse_filter=MOUSE_FILTER_IGNORE
	var tw=p.create_tween()
	tw.tween_interval(0.9)
	tw.tween_property(p,"modulate:a",0.0,0.35)
	tw.tween_callback(p.queue_free)
func add_action(name:String,id:String,i:int=0):
	if is_instance_valid(action_grid): quick(name,id,i)
	else: button(actions,name,func(): perform(id,i))
func showcase_card(name:String,detail:String,path:String,fn:Callable):
	var shell=panel(actions)
	var h=row(shell)
	var image=TextureRect.new()
	image.texture=tex(path)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.custom_minimum_size=Vector2(122,86)
	h.add_child(image)
	var copy=VBoxContainer.new()
	copy.size_flags_horizontal=SIZE_EXPAND_FILL
	h.add_child(copy)
	var title=label(copy,name,19); title.clip_text=true
	var caption=label(copy,detail,14); caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	caption.modulate=Color("#c6d4ee")
	var play=button(copy,"ENTER  ›",fn); play.custom_minimum_size.y=42
func product_card(name:String,detail:String,asset_path:String,action_text:String,fn:Callable,enabled:bool=true):
	var shell=panel(actions)
	var h=row(shell)
	var thumb=TextureRect.new()
	thumb.texture=tex(asset_path)
	thumb.custom_minimum_size=Vector2(72,72)
	thumb.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(thumb)
	var copy=VBoxContainer.new()
	copy.size_flags_horizontal=SIZE_EXPAND_FILL
	h.add_child(copy)
	var product_name=label(copy,name,18); product_name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var d=label(copy,detail,13); d.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	d.modulate=Color("#c9d9d4")
	var b=button(h,action_text,fn)
	b.add_theme_font_size_override("font_size",14)
	b.size_flags_horizontal=SIZE_SHRINK_CENTER
	b.custom_minimum_size.x=100
	b.disabled=not enabled
	return b
func sync_wearables():
	var s:Dictionary=store.s
	var key=str(s.stage)+":"+str(s.worn)+":"+str(s.equipped)+":"+str(store.species())
	if key==last_wear_key: return
	last_wear_key=key
	var rectangles=[Rect2(50,-15,110,78),Rect2(62,63,86,48),Rect2(48,112,114,85),Rect2(55,168,100,55),Rect2(69,-12,72,53)]
	for i in range(5):
		var layer=wear_layers[i]
		var item=int(s.worn[i]) if i<4 else int(s.equipped)
		layer.visible=s.stage>0 and item>0
		layer.texture=tex("res://assets/"+("clothes_" if i<4 else "item_")+str(item-1)+".png") if item>0 else null
		layer.position=rectangles[i].position
		layer.size=rectangles[i].size
		if i==4 and item==2: layer.position=Vector2(116,32)
func _process(delta:float):
	if not is_instance_valid(portrait) or not portrait.visible: return
	pet_bob_time+=delta
	portrait.pivot_offset=portrait.size*0.5
	portrait.rotation=sin(pet_bob_time*1.8)*0.014
	var base_scale=0.78 if store.s.stage==1 else 0.91 if store.s.stage==2 else 1.0
	var breathe=1.0+sin(pet_bob_time*2.5)*0.018
	portrait.scale=Vector2(base_scale/breathe,base_scale*breathe)
func select(tab:String):
	section=tab
	for key in nav_buttons:
		nav_buttons[key].add_theme_stylebox_override("normal",skin(Color("#6738a8"),Color("#e6bcff")) if key==tab else StyleBoxEmpty.new())
	if is_instance_valid(section_scroll):
		section_scroll.scroll_vertical=0
		var full_menu=tab!="Home"
		visual.visible=not full_menu
		stage_space.visible=not full_menu
		daily_cta.visible=not full_menu
		room_scroll.visible=not full_menu
		meter_panel.visible=not full_menu
		section_scroll.size_flags_vertical=SIZE_EXPAND_FILL if full_menu else SIZE_FILL
	current_room=""
	if is_instance_valid(hotspot_layer):
		update_room_scene()
		room_tag.text="Your home"
		live_stage.set_room("room_bedroom")
	reset_actions(5 if tab=="Home" and store.s.stage>0 else 3 if tab=="Home" else 0)
	if tab!="Home": label(actions,tab.to_upper(),22)
	var s:Dictionary=store.s
	match tab:
		"Home":
			if s.stage==0:
				add_action("Hatch egg","hatch")
				for i in range(3): add_action(store.FIELDS[i],"field",i)
			else:
				add_action("Cuddle","bond")
				paint_action(art_tile(action_grid,"Feed","res://assets/premium_snack.png",func(): room("Kitchen"),82,13,"food"),"food")
				add_action("Clean","clean")
				add_action("Play","play")
				add_action("Sleep","sleep")
		"Pets":
			show_collection()
		"More":
			for tab_name in ["Care","Journal","World","Cell"]:
				showcase_card(tab_name,["Care & feeding","Quests & collection","Explore & playdates","Growth & health"][["Care","Journal","World","Cell"].find(tab_name)],"res://assets/"+NAV_ART[tab_name],func(): select(tab_name))
			var edit=LineEdit.new(); edit.placeholder_text="Name your pet"; edit.text=s.name; edit.max_length=24; actions.add_child(edit)
			button(actions,"Save name",func(): store.s.name=edit.text.strip_edges(); store.save_game(); refresh())
		"Care":
			var care=context_card("care","Pet wellness")
			context_meter(care,"hygiene",Color("#55c8d3"))
			context_meter(care,"toilet",Color("#8ecb96"))
			for i in range(4): add_action(store.FOODS[i]+" • "+str(store.FOOD_COST[i])+" coins","food",i)
			for a in [["Pet / cuddle","bond"],["Play","play"],["Train","train"],["Praise","praise"],["Clean habitat","clean"],["Nap / wake","sleep"],["Toggle auto sleep","auto"],["Cook • 2 materials","cook"],["Bath","bath"],["Snack","snack"],["Medicine","medicine"]]: add_action(a[0],a[1])
		"Rooms":
			for room_name in ROOMS:
				showcase_card(room_name,"Enter room","res://assets/"+ROOMS[room_name]+".jpg",func(): room(room_name))
		"Arcade":
			for i in [4,0,1,2,3]:
				var image="res://assets/arcade_"+["star","flappy","cloud","find","star"][i]+".jpg"
				if i==4: image="res://assets/sky-panorama.png"
				showcase_card(GAMES[i],["Build a combo","Fly through gates","Climb the sky","Spot your companion","Run the sky kingdom"][i],image,func(): launch_game(i))
		"Shop":
			label(actions,"Furniture & accessories",20)
			for i in range(store.ITEMS.size()):
				var owned=(int(s.owned)&(1<<i))!=0
				var active=s.equipped==i+1 or s.installation==i+1
				product_card(store.ITEMS[i],"Equipped" if active else "Owned" if owned else "%d coins"%store.PRICES[i],"res://assets/item_%d.png"%i,"Remove" if active else "Use" if owned else "Buy",func(): perform("use" if owned else "buy",i),owned or s.coins>=store.PRICES[i])
			label(actions,"Wardrobe",20)
			for i in range(store.CLOTHES.size()):
				var owned=(int(s.wardrobe)&(1<<i))!=0
				var active=s.worn.has(i+1)
				product_card(store.CLOTHES[i],"Wearing" if active else "Owned" if owned else "%d coins"%store.COST[i],"res://assets/clothes_%d.png"%i,"Remove" if active else "Wear" if owned else "Buy",func(): perform("wear" if owned else "clothes",i),owned or s.coins>=store.COST[i])
			label(actions,"Supplies",20)
			product_card("Medicine","12 coins • %d owned"%s.medicine,"res://assets/premium_medicine.png","Buy",func(): perform("supply",0),s.coins>=12)
			product_card("Snack","5 coins • %d owned"%s.snacks,"res://assets/premium_snack.png","Buy",func(): perform("supply",1),s.coins>=5)
		"Journal":
			var growth=context_card("growth","Growth journey")
			context_meter(growth,"growth",Color("#b08bf0"))
			context_card("quests","Daily quests")
			add_action("Daily gift","daily")
			for i in range(3): add_action(["Bond quest","Clean quest","Expedition quest"][i]+" • 15 coins","quest",i)
			add_action("Craft crystal • 3 materials","craft"); add_action("Secret evolution","secret")
			button(actions,"Petpedia • 24 forms",show_collection)
		"World":
			var expedition=context_card("expedition","Expedition status")
			context_meter(expedition,"expedition",Color("#65b4ed"))
			context_card("friend","Friendship & family")
			for i in range(3): add_action("Habitat: "+store.FIELDS[i],"field",i)
			for i in range(3): add_action(["Meadow • 10 min","Coral ruins • 20 min","Starlight islands • 30 min"][i],"trip",i)
			add_action("Collect expedition rewards","loot"); add_action("Playdate (local)","friend")
			button(actions,"Start next generation",func():
				var confirm=ConfirmationDialog.new(); confirm.dialog_text="Begin a new egg generation?"; add_child(confirm); confirm.confirmed.connect(func(): perform("breed")); confirm.popup_centered())
		"Cell":
			var growth=context_card("growth","Cell development")
			context_meter(growth,"growth",Color("#af8bff"))
			context_card("cells","Health laboratory")
			var grid=GridContainer.new(); grid.columns=3; actions.add_child(grid)
			for i in range(6):
				var cell=art_tile(grid,"Healthy","res://assets/premium_crystal.png",func(): perform("cell"),95,16)
				cell_tiles.append(cell)
			add_action("Treat one sick cell","cell")
	update_context()
func room(name:String):
	for key in nav_buttons:
		nav_buttons[key].add_theme_stylebox_override("normal",skin(Color("#6738a8"),Color("#e6bcff")) if key=="Rooms" else StyleBoxEmpty.new())
	section_scroll.scroll_vertical=0
	visual.show()
	stage_space.show()
	daily_cta.hide()
	room_scroll.show()
	meter_panel.show()
	section_scroll.size_flags_vertical=SIZE_FILL
	section="Rooms"
	current_room=name
	refresh()
	reset_actions(3)
	match name:
		"Kitchen":
			for i in range(4): add_action(store.FOODS[i],"food",i)
			add_action("Cook","cook"); add_action("Snack","snack")
		"Bathroom": add_action("Soap","soap"); add_action("Rinse","rinse"); add_action("Toilet","toilet")
		"Bedroom":
			add_action("Lamp / sleep","lamp")
			for i in range(3): add_action(["Cozy","Ocean","Starlight"][i],"theme",i)
		"Toy room": add_action("Play with toys","toy"); art_tile(action_grid,"Arcade","res://assets/premium_star.png",func(): select("Arcade"),66,13,"Arcade")
		"Garden": add_action("Plant • 5 coins","plant"); add_action("Harvest","harvest")
		"Potion lab": add_action("Medicine","medicine"); add_action("Craft crystal","craft")
	art_tile(action_grid,"All rooms","res://assets/item_4.png",func(): select("Rooms"),66,13,"Rooms")
	if name=="Garden":
		var garden=context_card("garden","Garden crop")
		context_meter(garden,"garden",Color("#90cb70"))
	update_context()
func species_category(i:int)->String:
	var kind=FAMILIES[i%12]
	if kind=="Alien": return "Alien"
	if kind in ["Fish","Jelly"]: return "Water"
	if kind in ["Bird","Owl","Dragon"]: return "Sky"
	if kind in ["Fairy","Sprout"]: return "Mystic"
	return "Land"
func species_color(i:int)->Color:
	return Color({"Alien":"#a873e9","Water":"#4a9ed5","Sky":"#697de0","Mystic":"#bd76bc","Land":"#77b889"}[species_category(i)])
func update_feature(i:int):
	collection_feature=i
	show_collection()
	section_scroll.scroll_vertical=0
func show_collection():
	reset_actions()
	var title=label(actions,"PET COLLECTION",25)
	title.add_theme_color_override("font_color",Color("#f5d6ff"))
	var discovered=0
	for i in range(24):
		if (int(store.s.collection)&(1<<i))!=0: discovered+=1
	label(actions,"%d / 24 discovered  •  Tap a creature to inspect"%discovered,14).modulate=Color("#d0bedf")
	var featured=panel(actions)
	var hero=row(featured)
	var portrait_art=TextureRect.new(); portrait_art.texture=tex("res://assets/pet_%d.png"%collection_feature); portrait_art.custom_minimum_size=Vector2(144,188); portrait_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; portrait_art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; hero.add_child(portrait_art)
	var copy=VBoxContainer.new(); copy.size_flags_horizontal=SIZE_EXPAND_FILL; hero.add_child(copy)
	label(copy,"FEATURED SPECIES",12).modulate=Color("#ffce86")
	var family=label(copy,FAMILIES[collection_feature%12],25); family.clip_text=true
	var species=label(copy,store.SPECIES[collection_feature],16); species.clip_text=true
	label(copy,species_category(collection_feature)+"  •  "+("Secret evolution" if collection_feature>=12 else "Standard form"),12).modulate=species_color(collection_feature).lightened(.35)
	var desc=label(copy,"Discovered" if (int(store.s.collection)&(1<<collection_feature))!=0 else "Discover through growth and evolution.",14); desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var favorite_button=button(copy,"♥ Favorited" if store.favorite(collection_feature) else "♡ Favorite",func(): store.toggle_favorite(collection_feature); show_collection())
	favorite_button.add_theme_font_size_override("font_size",14)
	var growth_button=button(copy,"Growth journal",func(): select("Journal")); growth_button.add_theme_font_size_override("font_size",14)
	var filter_scroll=ScrollContainer.new(); filter_scroll.custom_minimum_size.y=44; filter_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; actions.add_child(filter_scroll)
	var filter=row(filter_scroll); filter.size_flags_horizontal=SIZE_EXPAND_FILL
	for key in ["All","Land","Sky","Water","Alien","Mystic","Favorites"]:
		var b=button(filter,key,func(): collection_filter=key; show_collection())
		b.add_theme_font_size_override("font_size",12); b.custom_minimum_size=Vector2(64,40)
		if key==collection_filter: b.add_theme_stylebox_override("normal",skin(Color("#926332"),Color("#ffe0a1")))
	collection_grid=GridContainer.new(); collection_grid.columns=3 if size.x>=450 else 2; collection_grid.add_theme_constant_override("h_separation",6); collection_grid.add_theme_constant_override("v_separation",6); actions.add_child(collection_grid)
	for i in range(24):
		var category=species_category(i)
		if collection_filter=="Favorites" and not store.favorite(i): continue
		if collection_filter not in ["All","Favorites"] and category!=collection_filter: continue
		var known=(int(store.s.collection)&(1<<i))!=0
		var tint=species_color(i)
		var b=button(collection_grid,"",func(): update_feature(i))
		b.custom_minimum_size=Vector2(0,182)
		b.add_theme_stylebox_override("normal",skin(tint.darkened(.70),Color("#ffce89") if i==collection_feature else tint.lightened(.25)))
		var v=VBoxContainer.new(); v.set_anchors_and_offsets_preset(PRESET_FULL_RECT); v.offset_left=7; v.offset_right=-7; v.offset_top=6; v.offset_bottom=-7; v.mouse_filter=MOUSE_FILTER_IGNORE; v.add_theme_constant_override("separation",2); b.add_child(v)
		var flags=label(v,("♥  " if store.favorite(i) else "")+("SECRET" if i>=12 else category.to_upper()),10); flags.mouse_filter=MOUSE_FILTER_IGNORE; flags.modulate=tint.lightened(.5)
		var art=TextureRect.new(); art.texture=tex("res://assets/pet_%d.png"%i); art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.size_flags_vertical=SIZE_EXPAND_FILL; art.mouse_filter=MOUSE_FILTER_IGNORE; v.add_child(art)
		var name=label(v,store.SPECIES[i],14); name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; name.clip_text=true; name.mouse_filter=MOUSE_FILTER_IGNORE
		var status=label(v,"Discovered" if known else "Undiscovered",11); status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; status.mouse_filter=MOUSE_FILTER_IGNORE; status.modulate=Color("#9ce2b5") if known else Color("#c7b9db")
	if collection_grid.get_child_count()==0: label(actions,"No favorites yet. Open a species and tap Favorite.",16).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
func launch_game(i:int):
	if not store.begin_arcade(i): notice.text="Your pet needs rest or is busy."; return
	get_tree().change_scene_to_file("res://main.tscn" if i==4 else "res://pet_arcade.tscn")
func refresh():
	store.advance(store.now())
	var s:Dictionary=store.s
	title_label.text=store.pet_name()+"  ·  Lv "+str(store.level())
	identity_art.texture=tex("res://assets/premium_egg.png" if s.stage==0 else "res://assets/pet_%d.png"%store.species())
	xp_bar.value=fposmod(float(s.xp),100)
	info.text="%d coins  |  %d gems"%[s.coins,s.crystals]
	clock_label.text=Time.get_time_string_from_system().substr(0,5)
	for i in range(4):
		stats[i].value=[s.hunger*20,s.happy*10,s.energy,s.bond][i]
		status_values[i].text="%d%%"%int(stats[i].value)
	var hour=int(Time.get_datetime_dict_from_system().hour)
	var night=hour<5 or hour>=19
	var path="res://assets/home_night.jpg" if night else "res://assets/home_day.jpg"
	room_tag.text=current_room if not current_room.is_empty() else "Your home"
	for name in room_tiles:
		room_tiles[name].add_theme_stylebox_override("normal",skin(Color("#374a7b") if name==current_room or (name=="Bedroom" and current_room.is_empty()) else Color("#222b56"),Color("#ffd793") if name==current_room or (name=="Bedroom" and current_room.is_empty()) else Color("#777fd0")))
	bg.modulate=[Color.WHITE,Color("#c2dcff"),Color("#d3c1ff")][int(s.theme)]
	var outfit_names:Array[String]=[]
	for item in s.worn:
		if item>0: outfit_names.append(store.CLOTHES[int(item)-1])
	outfit_label.text=""
	if is_instance_valid(daily_cta):
		daily_cta.disabled=s.stage==0 or s.daily_day==store.date_key(store.now())
		daily_cta.text="Daily reward collected" if daily_cta.disabled else "Daily Reward   ›"
	if not current_room.is_empty(): path="res://assets/"+str(ROOMS.get(current_room,"room_bedroom"))+".jpg"
	bg.texture=tex(path)
	update_room_scene()
	var pp="res://assets/pet_%d.png"%store.species()
	if s.stage==1 or s.stage==2: pp="res://assets/growth_%d_%d.png"%[s.field,s.stage]
	portrait.texture=tex(pp)
	portrait.modulate=Color("#9ba9c7") if store.asleep(store.now()) else Color.WHITE
	portrait.scale=Vector2.ONE*(0.64 if s.stage<2 else 0.85 if s.stage==2 else 1.0)
	portrait.visible=false
	sync_wearables()
	live_stage.set_room(str(ROOMS.get(current_room,"room_bedroom")))
	live_stage.set_pet(store.species(),int(s.stage))
	live_stage.set_night(night)
	live_stage.set_sleeping(store.asleep(store.now()))
	live_stage.dress(s.worn,int(s.equipped))
	if live_stage.incompatible_wearables>0: outfit_label.text="Shoes stay in your wardrobe for aquatic pets"
	position_hotspots()
	face.visible=false
	egg_visual.visible=s.stage==0 and egg_art.texture==null
	egg_art.visible=s.stage==0 and egg_art.texture!=null
	face.text="– ᴗ –" if store.asleep(store.now()) else "• ︿ •" if s.germs>0 or s.hunger<=1 else "• ᴗ •"
	if rendered_stage!=int(s.stage):
		rendered_stage=int(s.stage)
		if section=="Home": select("Home")
	update_context()
func set_context(key:String,message:String,progress:float=-1.0):
	if context_labels.has(key) and is_instance_valid(context_labels[key]): context_labels[key].text=message
	if progress>=0 and context_bars.has(key) and is_instance_valid(context_bars[key]): context_bars[key].value=clampf(progress,0,100)
func update_context():
	var s:Dictionary=store.s
	var now:float=store.now()
	set_context("care","%s\nHygiene %d%%  •  Bathroom %d%%  •  Waste %d/6  •  Medicine %d"%[store.care_priority(),s.hygiene,s.toilet,s.waste,s.medicine])
	for key in ["hygiene","toilet"]:
		if context_bars.has(key): context_bars[key].value=s[key]
	var next="Fully evolved" if s.stage==4 else "Next: "+store.STAGES[mini(4,int(s.stage)+1)]+"  •  "+time_text(store.growth_remaining()) if s.stage>0 else "Choose a habitat and hatch"
	set_context("growth",store.STAGES[int(s.stage)]+"  •  "+next,store.growth_progress()*100)
	var quest_names=["Bond","Clean","Expedition"]
	var lines:Array[String]=[]
	for i in range(3):
		var bit=1<<i
		lines.append(quest_names[i]+": "+("Claimed" if (int(s.claimed)&bit)!=0 else "Ready +15 coins" if (int(s.quests)&bit)!=0 else "In progress"))
	set_context("quests","\n".join(lines))
	var remaining:int=store.expedition_remaining(now)
	var duration=(10+int(s.destination)*10)*60
	var msg="Ready to explore • Fuel %d"%s.fuel
	if remaining>0: msg="Exploring • returns in "+time_text(remaining)
	elif s.pending[0]>0: msg="Rewards ready • %d coins, %d materials, %d crystals"%[s.pending[0],s.pending[1],s.pending[2]]
	set_context("expedition",msg,100*(1-float(remaining)/duration) if remaining>0 else 100 if s.pending[0]>0 else 0)
	set_context("friend","Friendship %d/4 • Generation %d\nAdult + friendship 4 unlocks next generation."%[s.friendship,s.generation])
	var garden_time:int=store.garden_remaining(now)
	set_context("garden","Plant a seed for 5 coins" if s.garden_at==0 else "Ready to harvest!" if garden_time==0 else "Growing • "+time_text(garden_time),0 if s.garden_at==0 else 100*(1-float(garden_time)/1200))
	set_context("cells","%s • %d sick cells • Growth %d/4"%[store.care_priority(),s.germs,s.cells[int(s.field)]])
	for i in range(cell_tiles.size()):
		var b=cell_tiles[i]
		if not is_instance_valid(b): continue
		var sick=i<int(s.germs)
		b.disabled=not sick
		b.modulate=Color("#ff9baa") if sick else Color("#9edcc1")
		b.tooltip_text="Treat sick cell" if sick else "Healthy cell"
		var v=b.get_child(0)
		v.get_child(1).text="Treat" if sick else "Healthy"
func update_room_scene():
	var next_key=str(ROOMS.get(current_room,""))
	if next_key==room_key: return
	room_key=next_key
	for child in hotspot_layer.get_children(): hotspot_layer.remove_child(child); child.queue_free()
	if room_key.is_empty() or not room_layout.has(room_key): return
	var data:Dictionary=room_layout[room_key]
	for key in data:
		if key in ["pet","world_pet","world_targets"]: continue
		var b=Button.new(); b.text=str(key).capitalize(); b.custom_minimum_size=Vector2(64,30); b.add_theme_font_size_override("font_size",12)
		b.add_theme_stylebox_override("normal",style(Color("#172b3bd9"),Color("#ffd591"),12))
		b.set_meta("point",Vector2(float(data[key][0]),float(data[key][1])))
		if data.has("world_targets") and data.world_targets.has(key):
			var p:Array=data.world_targets[key]
			b.set_meta("world_point",Vector3(float(p[0]),float(p[1]),float(p[2])))
		b.pressed.connect(func():
			if key=="arcade": select("Arcade")
			elif key=="food": select("Care")
			else: perform(str(key)))
		hotspot_layer.add_child(b)
	position_hotspots()
func position_hotspots():
	if not is_instance_valid(hotspot_layer): return
	var safe=Rect2(Vector2(8,8),visual.size-Vector2(16,16))
	if is_instance_valid(stage_space) and stage_space.size.y>100:
		safe=safe.intersection(Rect2(stage_space.global_position-visual.global_position+Vector2(8,8),stage_space.size-Vector2(16,16)))
	if safe.size.x<80 or safe.size.y<80: return
	var occupied:Array[Rect2]=[]
	for child in hotspot_layer.get_children():
		var point:Vector2=child.get_meta("point")
		var center=visual.size*point
		if child.has_meta("world_point") and is_instance_valid(live_stage): center=live_stage.screen_point(child.get_meta("world_point"))
		var dims:Vector2=child.get_combined_minimum_size().max(child.custom_minimum_size)
		child.size=dims
		var limit=(safe.end-dims).max(safe.position)
		var at=(center-dims/2).clamp(safe.position,limit)
		for attempt in range(8):
			var candidate=Rect2(at,dims).grow(3)
			var overlap=false
			for taken in occupied:
				if candidate.intersects(taken): overlap=true; break
			if not overlap: break
			at.y=clampf(at.y+dims.y+8,safe.position.y,limit.y)
			if attempt==3: at.x=clampf(at.x+dims.x+8,safe.position.x,limit.x); at.y=clampf(center.y-dims.y/2,safe.position.y,limit.y)
		child.position=at
		occupied.append(Rect2(at,dims).grow(3))
func test_home():
	store.s=store.defaults(); store.s.auto_sleep=false
	assert(store.action("hatch")); assert(store.s.coins==100)
	store.s.hunger=3; assert(store.action("food",3)); assert(store.s.hunger==4)
	assert(store.action("daily")); assert(not store.action("daily"))
	assert(not store.begin_arcade(-1)); assert(not store.begin_arcade(5))
	assert(store.begin_arcade(0)); assert(store.finish_arcade(5,5.0)==10); assert(store.finish_arcade(5,5.0)==0)
	var wallet=store.s.coins
	assert(store.begin_arcade(4)); assert(store.finish_arcade(999,0.1,20)==0)
	assert(store.s.coins==wallet and store.s.snacks==0)
	assert(store.begin_arcade(4)); assert(store.finish_arcade(10,5.0)==30)
	assert(store.finish_arcade(10,5.0)==0)
	for variant in range(2):
		for field in range(3):
			for body in range(4):
				store.s.variant=variant; store.s.field=field; store.s.body=body
				assert(store.species()==variant*12+field*4+body)
	store.s.variant=0; store.s.field=0; store.s.body=0
	var saved:Dictionary=store.s.duplicate(true)
	store.s.stage=1; store.s.cells=[0,0,0]; store.s.cell_clock=0.0; store.s.last=store.now()-3601
	store.advance(store.now()); assert(store.s.stage==2)
	store.s.hygiene=20; assert(store.action("soap")); assert(store.action("rinse")); assert(store.s.hygiene==55)
	assert(store.action("bath")); assert(not store.action("bath"))
	store.s.germs=3; assert(store.action("cell")); assert(store.s.germs==2)
	store.s.coins=500; assert(store.action("plant")); assert(not store.action("harvest"))
	store.s.garden_at=store.now()-1; assert(store.action("harvest")); assert(not store.action("harvest"))
	store.s.germs=0; store.s.hunger=5; store.s.energy=100; assert(store.action("trip",0)); assert(not store.available())
	store.s.trip_end=store.now()-1; store.advance(store.now()+1); assert(store.s.pending[0]>0)
	assert(store.action("loot")); assert(not store.action("loot"))
	store.s=saved
	make_ui(); refresh()
	select("Cell"); store.s.germs=2; update_context(); assert(not cell_tiles[0].disabled and cell_tiles[2].disabled)
	cell_tiles[0].pressed.emit(); assert(store.s.germs==1 and cell_tiles[1].disabled)
	store.s.germs=0; select("Home")
	store.s.coins=500
	assert(store.action("clothes",0))
	refresh()
	assert(wear_layers[0].visible and wear_layers[0].texture!=null and live_stage.wardrobe_nodes.size()==1)
	assert(store.action("wear",0))
	refresh()
	assert(not wear_layers[0].visible and live_stage.wardrobe_nodes.is_empty())
	assert(store.action("buy",0) and store.action("use",0))
	refresh()
	assert(wear_layers[4].visible and wear_layers[4].texture!=null and live_stage.wardrobe_nodes.size()==1)
	assert(live_stage.feet.size()==2 and live_stage.avatar.get_child_count()>=3)
	assert(is_finite(live_stage.sole_offset) and live_stage.grounded_error()<0.001)
	for species in range(24):
		live_stage.set_pet(species,4)
		assert(live_stage.avatar.get_child_count()>0 and is_finite(live_stage.sole_offset))
		assert(live_stage.grounded_error()<0.001)
	live_stage.set_pet(0,4)
	for tab in ["Care","Rooms","Arcade","Shop","Journal","World","Cell","More","Home"]: select(tab)
	assert(nav_buttons.size()==6 and room_tiles.size()==6 and action_grid.get_child_count()==5)
	select("Pets"); assert(collection_grid.get_child_count()==24)
	assert(store.toggle_favorite(3)); collection_filter="Favorites"; show_collection(); assert(collection_grid.get_child_count()==1)
	collection_filter="Alien"; show_collection(); assert(collection_grid.get_child_count()==2)
	collection_filter="All"; select("Home")
	for name in ROOMS:
		room(name)
		assert(bg.texture!=null and live_stage.room_node!=null and hotspot_layer.get_child_count()>=2,"room art/hotspots missing: "+name)
		assert(room_scroll.visible and meter_panel.visible and visual.visible)
		assert(action_grid.get_child_count()>=3)
	select("Home")
	store.s.interaction_at=0.0
	var before_bond:int=store.s.bond
	var cuddle:Button=action_grid.get_child(0)
	cuddle.pressed.emit()
	assert(store.s.bond==before_bond+1 and live_stage.fx_nodes.size()==5)
	live_stage.touch_bounce=0.0
	live_stage.react("food",false)
	assert(live_stage.fx_nodes.size()==5 and live_stage.reaction_kind=="food")
	# Boot each actual arcade scene and run its first physics step in-process.
	for mode in range(4):
		assert(store.begin_arcade(mode))
		var game=load("res://pet_arcade.tscn").instantiate()
		add_child(game)
		game.set_physics_process(false)
		game.size=Vector2(540,960)
		game.started=true
		game._physics_process(1.0/60.0)
		assert(game.elapsed>0.0 and not game.over)
		if mode==0:
			var p=game.board_rect().position+game.target*game.board_rect().size/game.WORLD
			game.begin_press(p); game.end_press(p)
			assert(game.score==1 and game.combo==1)
		if mode==1:
			assert(game.pipes.size()==4 and game.round_limit()==0)
			game.elapsed=61; game.pos.y=340; game.velocity.y=0; game._physics_process(1.0/60)
			assert(not game.over)
		if mode==2:
			assert(game.platforms.size()==7 and game.round_limit()==0)
			game.pos=Vector2(game.platforms[0].x,game.platforms[0].y-24)
			game.velocity.y=100; game._physics_process(1.0/60)
			var first_score=game.score
			assert(first_score==1)
			game.pos=Vector2(game.platforms[0].x,game.platforms[0].y-24)
			game.velocity.y=100; game._physics_process(1.0/60)
			assert(game.score==first_score)
		if mode==3:
			assert(game.crowd.size()==72)
			var target=game.crowd_point(game.crowd[game.target_index])
			var p=game.board_rect().position+target*game.board_rect().size/game.WORLD
			game.begin_press(p); game.end_press(p)
			assert(game.score==1 and game.wrong==0)
		store.finish_arcade(0,0.0)
		remove_child(game); game.free()
	print("FOREVER_PET_HUB_PASS")
	get_tree().quit()

func capture_frame(path:String):
	# Wait for container sizing and a complete SubViewport render, not a stale frame.
	for frame in range(3):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
	if visual.visible:
		position_hotspots()
		await RenderingServer.frame_post_draw
	var image=get_viewport().get_texture().get_image()
	assert(image.save_png(path)==OK)
func capture_home():
	store.s=store.defaults(); store.s.auto_sleep=false
	store.s.stage=4; store.s.coins=250; store.s.name="Mosskit"
	make_ui(); refresh()
	await capture_frame("/tmp/forever-home.png")
	for species in range(24):
		store.s.variant=int(species/12); store.s.field=int((species%12)/4); store.s.body=species%4; store.s.name=store.SPECIES[species]
		refresh()
		await capture_frame("/tmp/forever-species-%02d.png"%species)
	store.s.variant=0; store.s.field=0; store.s.body=0; store.s.name="Mosskit"; refresh()
	for name in ROOMS:
		select("Rooms")
		room(name)
		await capture_frame("/tmp/forever-"+ROOMS[name]+".png")
	select("Pets")
	await capture_frame("/tmp/forever-collection.png")
	collection_filter="Alien"; show_collection()
	await capture_frame("/tmp/forever-collection-alien.png")
	collection_filter="All"
	select("Shop")
	await capture_frame("/tmp/forever-shop.png")
	store.s.wardrobe=255; store.s.worn=[1,2,3,5]; refresh()
	select("Home")
	await capture_frame("/tmp/forever-wardrobe.png")
	select("Arcade")
	await capture_frame("/tmp/forever-arcade-menu.png")
	for i in range(4):
		assert(store.begin_arcade(i))
		var game=load("res://pet_arcade.tscn").instantiate()
		add_child(game)
		game.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		game.set_physics_process(false)
		await capture_frame("/tmp/forever-game-%d.png"%i)
		store.finish_arcade(0,0)
		remove_child(game); game.free()
	print("FOREVER_PET_CAPTURE_PASS")
	get_tree().quit()
