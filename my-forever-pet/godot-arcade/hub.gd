extends Control
const GAMES=["Star Catch","Flappy Pet","Cloud Jump","Find My Pet","Pet Dash 3D"]
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
func button(parent:Node,value:String,fn:Callable)->Button:
	var b=Button.new(); b.text=value; b.custom_minimum_size=Vector2(0,48); b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size",18)
	b.add_theme_stylebox_override("normal",style(Color("#263b64"),Color("#c29852")))
	b.add_theme_stylebox_override("pressed",style(Color("#426d90"),Color("#ffe2a0")))
	b.pressed.connect(fn); parent.add_child(b); return b
func row(parent:Node)->HBoxContainer:
	var h=HBoxContainer.new(); h.add_theme_constant_override("separation",8); parent.add_child(h); return h
func panel(parent:Node)->VBoxContainer:
	var p=PanelContainer.new(); p.add_theme_stylebox_override("panel",style(Color("#162747"),Color("#5876a1"))); parent.add_child(p)
	var v=VBoxContainer.new(); v.add_theme_constant_override("separation",7); p.add_child(v); return v
func make_ui():
	var backdrop=ColorRect.new(); backdrop.color=Color("#0c1832"); backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(backdrop)
	var margin=MarginContainer.new(); margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT); margin.add_theme_constant_override("margin_left",15); margin.add_theme_constant_override("margin_right",15); margin.add_theme_constant_override("margin_top",12); margin.add_theme_constant_override("margin_bottom",12); add_child(margin)
	var layout=VBoxContainer.new(); layout.add_theme_constant_override("separation",9); margin.add_child(layout)
	var head=row(layout); label(head,"FOREVER PET",22).size_flags_horizontal=Control.SIZE_EXPAND_FILL; clock_label=label(head,"00:00",15); clock_label.custom_minimum_size.x=58; clock_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var identity=row(layout); title_label=label(identity,"",24); title_label.size_flags_horizontal=SIZE_EXPAND_FILL; info=label(identity,"",14); info.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	visual=Control.new(); visual.custom_minimum_size.y=348; visual.size_flags_vertical=SIZE_EXPAND_FILL; layout.add_child(visual)
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
	room_tag=Label.new(); room_tag.add_theme_font_size_override("font_size",18); room_tag.position=Vector2(12,9); visual.add_child(room_tag)
	outfit_label=Label.new(); outfit_label.add_theme_font_size_override("font_size",14); outfit_label.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE); outfit_label.offset_top=-31; outfit_label.offset_bottom=-3; outfit_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; visual.add_child(outfit_label)
	var touch=Button.new(); touch.flat=true; touch.set_anchors_and_offsets_preset(PRESET_FULL_RECT); touch.pressed.connect(func(): live_stage.tap(); perform("hatch" if store.s.stage==0 else "bond")); visual.add_child(touch)
	egg_art=TextureRect.new(); egg_art.texture=tex("res://assets/premium_egg.png"); egg_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; egg_art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; egg_art.set_anchors_and_offsets_preset(PRESET_CENTER); egg_art.offset_left=-75; egg_art.offset_right=75; egg_art.offset_top=-80; egg_art.offset_bottom=70; egg_art.mouse_filter=MOUSE_FILTER_IGNORE; visual.add_child(egg_art)
	hotspot_layer=Control.new(); hotspot_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT); hotspot_layer.mouse_filter=MOUSE_FILTER_IGNORE; visual.add_child(hotspot_layer)
	var meter_shell=panel(layout)
	var meters=row(meter_shell)
	var colors=[Color("#e9ad53"),Color("#ed83b3"),Color("#6fcbd3"),Color("#ac9ceb")]
	for i in range(4):
		var column=VBoxContainer.new(); column.size_flags_horizontal=SIZE_EXPAND_FILL; meters.add_child(column)
		var name=label(column,["FOOD","MOOD","ENERGY","BOND"][i],12); name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var value=label(column,"100%",16); value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; status_values.append(value)
		var p=ProgressBar.new(); p.custom_minimum_size.y=9; p.show_percentage=false
		p.add_theme_stylebox_override("background",style(Color("#0a1530"),Color("#4e6181"),5))
		var fill_style=StyleBoxFlat.new(); fill_style.bg_color=colors[i]; fill_style.set_corner_radius_all(5)
		p.add_theme_stylebox_override("fill",fill_style); column.add_child(p); stats.append(p)
	notice=label(layout,"Tap your pet or an object",13)
	notice.clip_text=true
	section_scroll=ScrollContainer.new(); section_scroll.custom_minimum_size.y=172; section_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; layout.add_child(section_scroll)
	body=VBoxContainer.new(); body.size_flags_horizontal=SIZE_EXPAND_FILL; section_scroll.add_child(body)
	actions=body
	var n=row(layout)
	for tab in ["Home","Care","Rooms","Arcade"]:
		var b=button(n,tab,func(): select(tab)); nav_buttons[tab]=b; b.custom_minimum_size.y=45
	var n2=row(layout)
	for tab in ["Shop","Journal","World","Cell"]:
		var b=button(n2,tab,func(): select(tab)); nav_buttons[tab]=b; b.custom_minimum_size.y=42
	select("Home")
func perform(id:String,i:int=0):
	notice.text="Done!" if store.action(id,i) else "Unavailable — check needs, cost or requirements."
	refresh()
	if section=="Shop": select("Shop")
func add_action(name:String,id:String,i:int=0): button(actions,name,func(): perform(id,i))
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
	label(copy,name,18)
	var d=label(copy,detail,13)
	d.modulate=Color("#c9d9d4")
	var b=button(h,action_text,fn)
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
		nav_buttons[key].add_theme_stylebox_override("normal",style(Color("#496e99") if key==tab else Color("#263b64"),Color("#ffe2a0") if key==tab else Color("#8e7652"),12))
	if is_instance_valid(section_scroll): section_scroll.scroll_vertical=0
	current_room=""
	if is_instance_valid(hotspot_layer): update_room_scene()
	for child in actions.get_children(): actions.remove_child(child); child.queue_free()
	label(actions,tab.to_upper(),18)
	var s:Dictionary=store.s
	match tab:
		"Home":
			if s.stage==0:
				add_action("Hatch egg","hatch")
				for i in range(3): add_action(store.FIELDS[i],"field",i)
			else:
				add_action("Pet / cuddle","bond"); add_action("Feed free grain","food",3); add_action("Daily gift • 20 coins","daily")
				var edit=LineEdit.new(); edit.placeholder_text="Name your pet"; edit.text=s.name; edit.max_length=24; actions.add_child(edit)
				button(actions,"Save name",func(): store.s.name=edit.text.strip_edges(); store.save_game(); refresh())
		"Care":
			for i in range(4): add_action(store.FOODS[i]+" • "+str(store.FOOD_COST[i])+" coins","food",i)
			for a in [["Pet / cuddle","bond"],["Play","play"],["Train","train"],["Praise","praise"],["Clean habitat","clean"],["Nap / wake","sleep"],["Toggle auto sleep","auto"],["Cook • 2 materials","cook"],["Bath","bath"],["Snack","snack"],["Medicine","medicine"]]: add_action(a[0],a[1])
		"Rooms":
			for room_name in ["Kitchen","Bathroom","Bedroom","Toy room","Garden","Potion lab"]: button(actions,room_name,func(): room(room_name))
		"Arcade":
			for i in range(5): button(actions,GAMES[i]+"   ›",func(): launch_game(i))
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
			add_action("Daily gift","daily")
			for i in range(3): add_action(["Bond quest","Clean quest","Expedition quest"][i]+" • 15 coins","quest",i)
			add_action("Craft crystal • 3 materials","craft"); add_action("Secret evolution","secret")
			button(actions,"Petpedia • 24 forms",show_collection)
		"World":
			for i in range(3): add_action("Habitat: "+store.FIELDS[i],"field",i)
			for i in range(3): add_action(["Meadow • 10 min","Coral ruins • 20 min","Starlight islands • 30 min"][i],"trip",i)
			add_action("Collect expedition rewards","loot"); add_action("Playdate (local)","friend")
			button(actions,"Start next generation",func():
				var confirm=ConfirmationDialog.new(); confirm.dialog_text="Begin a new egg generation?"; add_child(confirm); confirm.confirmed.connect(func(): perform("breed")); confirm.popup_centered())
		"Cell":
			label(actions,"Inspect growth cells and treat illness.",17); add_action("Treat one sick cell","cell")
func room(name:String):
	current_room=name
	refresh()
	for child in actions.get_children(): actions.remove_child(child); child.queue_free()
	label(actions,name,22)
	match name:
		"Kitchen":
			for i in range(4): add_action(store.FOODS[i],"food",i)
			add_action("Cook","cook"); add_action("Snack","snack")
		"Bathroom": add_action("Soap","soap"); add_action("Rinse","rinse"); add_action("Toilet","toilet")
		"Bedroom":
			add_action("Lamp / sleep","lamp")
			for i in range(3): add_action(["Cozy","Ocean","Starlight"][i],"theme",i)
		"Toy room": add_action("Play with toys","toy"); button(actions,"Arcade",func(): select("Arcade"))
		"Garden": add_action("Plant • 5 coins","plant"); add_action("Harvest","harvest")
		"Potion lab": add_action("Medicine","medicine"); add_action("Craft crystal","craft")
	button(actions,"Back to rooms",func(): select("Rooms"))
func show_collection():
	for child in actions.get_children(): actions.remove_child(child); child.queue_free()
	label(actions,"PETPEDIA",22)
	for i in range(24):
		var known=(int(store.s.collection)&(1<<i))!=0
		var card=panel(actions)
		var h=row(card)
		var icon=TextureRect.new()
		icon.texture=tex("res://assets/pet_%d.png"%i)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size=Vector2(64,64)
		icon.modulate=Color.WHITE if known else Color("#142331")
		h.add_child(icon)
		label(h,store.SPECIES[i] if known else "??? • "+store.FIELDS[int((i%12)/4)]+" / "+store.FOODS[i%4]+(" / secret" if i>=12 else ""),16)
	button(actions,"Back",func(): select("Journal"))
func launch_game(i:int):
	if not store.begin_arcade(i): notice.text="Your pet needs rest or is busy."; return
	get_tree().change_scene_to_file("res://main.tscn" if i==4 else "res://pet_arcade.tscn")
func refresh():
	store.advance(store.now())
	var s:Dictionary=store.s
	title_label.text=store.pet_name()+"  ·  Lv "+str(store.level())
	info.text="%d coins  |  %d gems"%[s.coins,s.crystals]
	clock_label.text=Time.get_time_string_from_system().substr(0,5)
	for i in range(4):
		stats[i].value=[s.hunger*20,s.happy*10,s.energy,s.bond][i]
		status_values[i].text="%d%%"%int(stats[i].value)
	var hour=int(Time.get_datetime_dict_from_system().hour)
	var night=hour<5 or hour>=19
	var path="res://assets/home_night.jpg" if night else "res://assets/home_day.jpg"
	room_tag.text=current_room if not current_room.is_empty() else "Your home"
	bg.modulate=[Color.WHITE,Color("#c2dcff"),Color("#d3c1ff")][int(s.theme)]
	var outfit_names:Array[String]=[]
	for item in s.worn:
		if item>0: outfit_names.append(store.CLOTHES[int(item)-1])
	outfit_label.text=" · ".join(outfit_names)
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
	face.visible=false
	egg_visual.visible=s.stage==0 and egg_art.texture==null
	egg_art.visible=s.stage==0 and egg_art.texture!=null
	face.text="– ᴗ –" if store.asleep(store.now()) else "• ︿ •" if s.germs>0 or s.hunger<=1 else "• ᴗ •"
	if rendered_stage!=int(s.stage):
		rendered_stage=int(s.stage)
		if section=="Home": select("Home")
	if section=="Cell": notice.text="Cells %d/4 • Sick cells %d • Age %dh"%[s.cells[int(s.field)],s.germs,int(s.age/3600)]
func update_room_scene():
	var next_key=str(ROOMS.get(current_room,""))
	if next_key==room_key: return
	room_key=next_key
	for child in hotspot_layer.get_children(): hotspot_layer.remove_child(child); child.queue_free()
	if room_key.is_empty() or not room_layout.has(room_key): return
	var data:Dictionary=room_layout[room_key]
	for key in data:
		if key=="pet" or key=="world_pet": continue
		var b=Button.new(); b.text=str(key).capitalize(); b.custom_minimum_size=Vector2(64,30); b.add_theme_font_size_override("font_size",12)
		b.add_theme_stylebox_override("normal",style(Color("#172b3bd9"),Color("#ffd591"),12))
		b.set_meta("point",Vector2(float(data[key][0]),float(data[key][1])))
		b.pressed.connect(func():
			if key=="arcade": select("Arcade")
			elif key=="food": select("Care")
			else: perform(str(key)))
		hotspot_layer.add_child(b)
	position_hotspots()
func position_hotspots():
	if not is_instance_valid(hotspot_layer): return
	for child in hotspot_layer.get_children():
		var point:Vector2=child.get_meta("point")
		child.position=visual.size*point-child.custom_minimum_size/2
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
	make_ui(); refresh()
	store.s.coins=500
	assert(store.action("clothes",0))
	refresh()
	assert(wear_layers[0].visible and wear_layers[0].texture!=null)
	assert(store.action("wear",0))
	refresh()
	assert(not wear_layers[0].visible)
	assert(store.action("buy",0) and store.action("use",0))
	refresh()
	assert(wear_layers[4].visible and wear_layers[4].texture!=null)
	for tab in ["Care","Rooms","Arcade","Shop","Journal","World","Cell","Home"]: select(tab)
	for name in ROOMS:
		room(name)
		assert(bg.texture!=null and live_stage.room_node!=null and hotspot_layer.get_child_count()>=2,"room art/hotspots missing: "+name)
	select("Home")
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
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image=get_viewport().get_texture().get_image()
	assert(image.save_png(path)==OK)
func capture_home():
	store.s=store.defaults(); store.s.auto_sleep=false
	store.s.stage=4; store.s.coins=250; store.s.name="Mosskit"
	make_ui(); refresh()
	await capture_frame("/tmp/forever-home.png")
	for name in ROOMS:
		select("Rooms")
		room(name)
		await capture_frame("/tmp/forever-"+ROOMS[name]+".png")
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
