extends Control
const GAMES=["Star Catch","Flappy Pet","Cloud Jump","Find My Pet","Pet Dash 3D"]
var store:Node
var title_label:Label
var info:Label
var portrait:TextureRect
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
	make_ui()
	refresh()
	var t=Timer.new(); t.wait_time=1; t.timeout.connect(refresh); add_child(t); t.start()
func style(color:Color,border:Color,r:int=16)->StyleBoxFlat:
	var b=StyleBoxFlat.new(); b.bg_color=color; b.border_color=border; b.set_border_width_all(1); b.set_corner_radius_all(r)
	b.content_margin_left=12; b.content_margin_right=12; b.content_margin_top=8; b.content_margin_bottom=8
	return b
func label(parent:Node,value:String,sz:int=18)->Label:
	var l=Label.new(); l.text=value; l.add_theme_font_size_override("font_size",sz); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; parent.add_child(l); return l
func button(parent:Node,value:String,fn:Callable)->Button:
	var b=Button.new(); b.text=value; b.custom_minimum_size=Vector2(0,48); b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size",18)
	b.add_theme_stylebox_override("normal",style(Color("#283c50"),Color("#516b79")))
	b.add_theme_stylebox_override("pressed",style(Color("#537d75"),Color("#bde3ae")))
	b.pressed.connect(fn); parent.add_child(b); return b
func row(parent:Node)->HBoxContainer:
	var h=HBoxContainer.new(); h.add_theme_constant_override("separation",8); parent.add_child(h); return h
func panel(parent:Node)->VBoxContainer:
	var p=PanelContainer.new(); p.add_theme_stylebox_override("panel",style(Color("#172b3b"),Color("#405c69"))); parent.add_child(p)
	var v=VBoxContainer.new(); v.add_theme_constant_override("separation",7); p.add_child(v); return v
func make_ui():
	var backdrop=ColorRect.new(); backdrop.color=Color("#0e202b"); backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(backdrop)
	var margin=MarginContainer.new(); margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT); margin.add_theme_constant_override("margin_left",15); margin.add_theme_constant_override("margin_right",15); margin.add_theme_constant_override("margin_top",12); margin.add_theme_constant_override("margin_bottom",12); add_child(margin)
	var layout=VBoxContainer.new(); layout.add_theme_constant_override("separation",9); margin.add_child(layout)
	var head=row(layout); label(head,"MY FOREVER PET",23).size_flags_horizontal=Control.SIZE_EXPAND_FILL; clock_label=label(head,"",14)
	title_label=label(layout,"",24)
	info=label(layout,"",15)
	visual=Control.new(); visual.custom_minimum_size.y=340; layout.add_child(visual)
	visual.resized.connect(position_hotspots)
	if FileAccess.file_exists("res://assets/room_layout.json"):
		var raw=JSON.parse_string(FileAccess.get_file_as_string("res://assets/room_layout.json"))
		if raw is Dictionary: room_layout=raw
	bg=TextureRect.new(); bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT); bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; bg.stretch_mode=TextureRect.STRETCH_SCALE; visual.add_child(bg)
	var fallback=ColorRect.new(); fallback.color=Color("#436c6b"); fallback.set_anchors_and_offsets_preset(PRESET_FULL_RECT); visual.add_child(fallback); visual.move_child(fallback,0)
	portrait=TextureRect.new(); portrait.set_anchors_and_offsets_preset(PRESET_CENTER); portrait.offset_left=-105; portrait.offset_right=105; portrait.offset_top=-95; portrait.offset_bottom=115; portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; visual.add_child(portrait)
	egg_visual=Label.new(); egg_visual.text="◉"; egg_visual.add_theme_font_size_override("font_size",120); egg_visual.add_theme_color_override("font_color",Color("#ffe8b9")); egg_visual.set_anchors_and_offsets_preset(PRESET_CENTER); egg_visual.offset_left=-65; egg_visual.offset_top=-90; visual.add_child(egg_visual)
	face=Label.new(); face.text="• ᴗ •"; face.add_theme_font_size_override("font_size",29); face.add_theme_color_override("font_color",Color("#28202c")); face.set_anchors_and_offsets_preset(PRESET_CENTER); face.offset_left=-39; face.offset_top=-7; visual.add_child(face)
	room_tag=Label.new(); room_tag.add_theme_font_size_override("font_size",18); room_tag.position=Vector2(12,9); visual.add_child(room_tag)
	outfit_label=Label.new(); outfit_label.add_theme_font_size_override("font_size",14); outfit_label.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE); outfit_label.offset_top=-31; outfit_label.offset_bottom=-3; outfit_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; visual.add_child(outfit_label)
	var touch=Button.new(); touch.flat=true; touch.set_anchors_and_offsets_preset(PRESET_FULL_RECT); touch.pressed.connect(func(): perform("hatch" if store.s.stage==0 else "bond")); visual.add_child(touch)
	egg_art=TextureRect.new(); egg_art.texture=tex("res://assets/premium_egg.png"); egg_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; egg_art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; egg_art.set_anchors_and_offsets_preset(PRESET_CENTER); egg_art.offset_left=-75; egg_art.offset_right=75; egg_art.offset_top=-80; egg_art.offset_bottom=70; egg_art.mouse_filter=MOUSE_FILTER_IGNORE; visual.add_child(egg_art)
	hotspot_layer=Control.new(); hotspot_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT); hotspot_layer.mouse_filter=MOUSE_FILTER_IGNORE; visual.add_child(hotspot_layer)
	var meters=panel(layout)
	for name in ["Food","Mood","Energy","Bond"]:
		var h=row(meters); var l=label(h,name,15); l.custom_minimum_size.x=78
		var p=ProgressBar.new(); p.custom_minimum_size.y=13; p.size_flags_horizontal=Control.SIZE_EXPAND_FILL; p.show_percentage=false; p.add_theme_stylebox_override("background",style(Color("#0c1b25"),Color("#344a52"),7)); p.add_theme_stylebox_override("fill",style(Color("#8ec8a2"),Color("#8ec8a2"),7)); h.add_child(p); stats.append(p)
	notice=label(layout,"Choose an activity",14)
	var scroll=ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; layout.add_child(scroll)
	body=VBoxContainer.new(); body.size_flags_horizontal=Control.SIZE_EXPAND_FILL; scroll.add_child(body)
	actions=body
	var n=row(layout)
	for tab in ["Home","Care","Rooms","Arcade"]: button(n,tab,func(): select(tab))
	var n2=row(layout)
	for tab in ["Shop","Journal","World","Cell"]: button(n2,tab,func(): select(tab))
	select("Home")
func perform(id:String,i:int=0):
	notice.text="Done!" if store.action(id,i) else "Unavailable — check needs, cost or requirements."
	refresh()
	if section=="Shop": select("Shop")
func add_action(name:String,id:String,i:int=0): button(actions,name,func(): perform(id,i))
func select(tab:String):
	section=tab
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
			for i in range(store.ITEMS.size()):
				add_action(store.ITEMS[i]+" • "+str(store.PRICES[i])+" coins" if (int(s.owned)&(1<<i))==0 else store.ITEMS[i]+" • Equip / remove","buy" if (int(s.owned)&(1<<i))==0 else "use",i)
			for i in range(store.CLOTHES.size()): add_action(store.CLOTHES[i]+" • "+str(store.COST[i])+" coins" if (int(s.wardrobe)&(1<<i))==0 else store.CLOTHES[i]+" • Wear / remove","clothes" if (int(s.wardrobe)&(1<<i))==0 else "wear",i)
			add_action("Medicine • 12 coins","supply",0); add_action("Snack • 5 coins","supply",1)
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
		label(actions,store.SPECIES[i] if known else "??? • "+store.FIELDS[int((i%12)/4)]+" / "+store.FOODS[i%4]+(" / secret" if i>=12 else ""),16)
	button(actions,"Back",func(): select("Journal"))
func launch_game(i:int):
	if not store.begin_arcade(i): notice.text="Your pet needs rest or is busy."; return
	get_tree().change_scene_to_file("res://main.tscn" if i==4 else "res://pet_arcade.tscn")
func refresh():
	store.advance(store.now())
	var s:Dictionary=store.s
	title_label.text=store.pet_name()+"  ·  Lv "+str(store.level())
	info.text="%s / %s  •  %d coins  •  %d crystals  •  %d materials"%[store.STAGES[int(s.stage)],store.FIELDS[int(s.field)],s.coins,s.crystals,s.materials]
	clock_label.text=Time.get_time_string_from_system().substr(0,5)
	for i in range(4): stats[i].value=[s.hunger*20,s.happy*10,s.energy,s.bond][i]
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
	var pp="res://assets/pet_%d.png"%(store.species()%12)
	portrait.texture=tex(pp)
	portrait.modulate=Color("#d7c5ff") if s.variant==1 else Color.WHITE
	portrait.scale=Vector2.ONE*(0.64 if s.stage<2 else 0.85 if s.stage==2 else 1.0)
	portrait.visible=s.stage>0
	face.visible=s.stage>0
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
		if key=="pet": continue
		var b=Button.new(); b.text=str(key).capitalize(); b.custom_minimum_size=Vector2(82,36); b.add_theme_font_size_override("font_size",13)
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
	assert(store.begin_arcade(0)); assert(store.finish_arcade(5,5.0)==10); assert(store.finish_arcade(5,5.0)==0)
	make_ui(); refresh()
	for tab in ["Care","Rooms","Arcade","Shop","Journal","World","Cell","Home"]: select(tab)
	for name in ROOMS:
		room(name)
		assert(bg.texture!=null and hotspot_layer.get_child_count()>=2,"room art/hotspots missing: "+name)
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
		if mode==1: assert(game.pipes.size()==4)
		if mode==2: assert(game.platforms.size()==7)
		if mode==3: assert(game.crowd.size()==72)
		store.finish_arcade(0,0.0)
		remove_child(game); game.free()
	print("FOREVER_PET_HUB_PASS")
	get_tree().quit()
