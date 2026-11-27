extends Control
const GAMES=["Star Catch","Flappy Pet","Cloud Jump","Find My Pet","Pet Dash 3D"]
const GameIcons=preload("res://game_icons.gd")
const PixelArt=preload("res://pixel_pet_art.gd")
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
var pet_touch:Button
var pet_status:Label
var life_tab="Care"
var shop_tab="Accessories"
var swipe_dirty=true
var hint_label:Label
var quest_claim:Button
var life_tabs=["Care","Journal","Cell","Care Quest","Today"]
var wellness_cta:Button
var growth_cta:Button
var recommended_cta:Button
var recommended_destination="Care"
const Research=preload("res://research_data.gd")
var hunt_region=0
var hunt_message=""
var daily_cta:Button
var care_cta:Button
var wallpaper_cta:Button
var wallpaper_active=false
var wallpaper_status_check=0.0
var wallpaper_preview:Control
var wallpaper_pet:TextureRect
var wallpaper_preview_status:Label
var reward_row:HBoxContainer
var reward_audio:AudioStreamPlayer
var action_controls:Array[Button]=[]
var reward_sounds:Dictionary={}
var collection_filter="All"
var collection_feature=0
var collection_grid:GridContainer
var family_grid:VBoxContainer
const FAMILIES=["Sprout","Cat","Dog","Dragon","Fish","Alien","Dinosaur","Jelly","Bird","Fairy","Rabbit","Owl"]
func family_name(i:int)->String: return FAMILIES[i%12] if i<24 else ["Devil","Ghost","Robot","Mushroom"][i-24]
const ACTION_COLORS={"bond":"#e967a5","food":"#e5a44d","clean":"#4abce9","play":"#ae78ed","sleep":"#6e91e8","daily":"#ecb15c"}
var context_labels:Dictionary={}
var context_bars:Dictionary={}
var cell_tiles:Array[Button]=[]
const ACTION_ART={"bond":"premium_egg.png","food":"premium_snack.png","daily":"premium_coin.png","clean":"item_3.png","play":"premium_star.png","sleep":"item_4.png","lamp":"item_4.png","hatch":"premium_egg.png","soap":"premium_medicine.png","rinse":"item_3.png","toilet":"item_3.png","cook":"premium_snack.png","snack":"premium_snack.png","plant":"item_5.png","harvest":"premium_crystal.png","toy":"premium_star.png","medicine":"premium_medicine.png","craft":"premium_crystal.png"}
const NAV_ART={"Home":"item_4.png","Care":"premium_snack.png","Rooms":"item_3.png","Arcade":"premium_star.png","Shop":"premium_coin.png","Journal":"premium_crystal.png","World":"pet_0.png","Cell":"premium_medicine.png"}
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
var pixel_assets:Dictionary={}
const ROOMS={"Kitchen":"room_kitchen","Bathroom":"room_bathroom","Bedroom":"room_bedroom","Toy room":"room_toy","Garden":"room_garden","Potion lab":"room_lab"}
func tex(path:String)->Texture2D:
	if path=="res://assets/pet_0.png" or path=="res://assets/pet_sleep_0.png": return PixelArt.portrait(path)
	if not assets.has(path) and ResourceLoader.exists(path): assets[path]=load(path)
	return assets.get(path) as Texture2D
# Cache pixel portraits once; never resize or recolor on every refresh.
func pixel_portrait(path:String)->Texture2D:
	var pixel:=PixelArt.portrait(path)
	return pixel if pixel!=null else tex(path)
var stats:Array[ProgressBar]=[]
var notice:Label
var last_stage_rect=Rect2()
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
	if args.has("--home-touch-test"):
		call_deferred("test_touch")
		return
	make_ui()
	if store.arcade_return:
		store.arcade_return=false;select("Arcade")
	refresh()
	var t=Timer.new(); t.wait_time=1; t.timeout.connect(refresh); add_child(t); t.start()
	var controls_timer=Timer.new(); controls_timer.wait_time=.20; controls_timer.timeout.connect(update_action_controls); add_child(controls_timer); controls_timer.start()
func style(color:Color,border:Color,r:int=16)->StyleBoxFlat:
	var b=StyleBoxFlat.new(); b.bg_color=color; b.border_color=border; b.set_border_width_all(1); b.set_corner_radius_all(r); b.shadow_color=Color("#09132960"); b.shadow_size=2
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
func bar_skin(tint:Color,edge:Color)->StyleBoxFlat:
	var key="bar"+str(tint)+str(edge)
	if skin_cache.has(key): return skin_cache[key]
	var b=StyleBoxFlat.new(); b.bg_color=tint; b.set_corner_radius_all(7)
	skin_cache[key]=b
	return b
func menu_skin(color:Color,edge:Color)->StyleBoxFlat:
	var key="menu"+str(color)+str(edge)
	if skin_cache.has(key): return skin_cache[key]
	var b=StyleBoxFlat.new(); b.bg_color=color; b.border_color=edge; b.set_border_width_all(1); b.set_corner_radius_all(14)
	b.content_margin_left=12; b.content_margin_right=12; b.content_margin_top=9; b.content_margin_bottom=9
	skin_cache[key]=b
	return b
func button(parent:Node,value:String,fn:Callable)->Button:
	var b=Button.new(); b.text=value; b.custom_minimum_size=Vector2(0,48); b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	b.mouse_filter=MOUSE_FILTER_PASS
	b.action_mode=BaseButton.ACTION_MODE_BUTTON_RELEASE
	b.add_theme_font_size_override("font_size",18)
	b.add_theme_stylebox_override("normal",menu_skin(Color("#283847"),Color("#425766")))
	b.add_theme_stylebox_override("pressed",menu_skin(Color("#3c5964"),Color("#b6e3d4")))
	b.add_theme_stylebox_override("hover",menu_skin(Color("#344859"),Color("#718e99")))
	b.add_theme_stylebox_override("disabled",menu_skin(Color("#1e2733"),Color("#34414e")))
	b.add_theme_color_override("font_disabled_color",Color("#b9afc5"))
	b.focus_mode=FOCUS_NONE
	b.pressed.connect(fn); parent.add_child(b); return b
func row(parent:Node)->HBoxContainer:
	var h=HBoxContainer.new(); h.mouse_filter=MOUSE_FILTER_PASS; h.add_theme_constant_override("separation",8); parent.add_child(h); return h
func panel(parent:Node)->VBoxContainer:
	var p=PanelContainer.new(); p.size_flags_horizontal=SIZE_EXPAND_FILL; p.mouse_filter=MOUSE_FILTER_PASS; p.add_theme_stylebox_override("panel",style(Color("#202737"),Color("#374455"),14)); parent.add_child(p)
	var v=VBoxContainer.new(); v.mouse_filter=MOUSE_FILTER_PASS; v.add_theme_constant_override("separation",7); p.add_child(v); return v
func enable_swipe(container:ScrollContainer):
	container.scroll_deadzone=12
	container.mouse_filter=MOUSE_FILTER_STOP
	container.get_v_scroll_bar().custom_minimum_size.x=3
	container.get_h_scroll_bar().custom_minimum_size.y=3
func swipe_children(node:Node):
	# Every intermediate Control must propagate the press and drag to ScrollContainer.
	if node is Control and not node is ScrollBar and not node is ScrollContainer and not node is LineEdit:
		if node.has_meta("direct_field_input"): node.mouse_filter=MOUSE_FILTER_STOP
		elif node is BaseButton or node is Container: node.mouse_filter=MOUSE_FILTER_PASS
		else: node.mouse_filter=MOUSE_FILTER_IGNORE
	for child in node.get_children(): swipe_children(child)
func make_ui():
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var backdrop=ColorRect.new(); backdrop.color=Color("#101722"); backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(backdrop)
	var margin=MarginContainer.new(); margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT); margin.add_theme_constant_override("margin_left",8); margin.add_theme_constant_override("margin_right",8); margin.add_theme_constant_override("margin_top",7); margin.add_theme_constant_override("margin_bottom",7); margin.mouse_filter=MOUSE_FILTER_IGNORE; add_child(margin)
	var layout=VBoxContainer.new(); layout.mouse_filter=MOUSE_FILTER_IGNORE; layout.add_theme_constant_override("separation",5); margin.add_child(layout)
	var brand=row(layout)
	var logo=label(brand,"My Forever Pet",23); logo.size_flags_horizontal=SIZE_EXPAND_FILL; logo.add_theme_color_override("font_color",Color("#eaf4f7")); logo.add_theme_constant_override("outline_size",0)
	wallpaper_cta=button(brand,"Wallpaper",func(): select("Wallpaper")); wallpaper_cta.size_flags_horizontal=SIZE_SHRINK_END; wallpaper_cta.custom_minimum_size=Vector2(112,36); wallpaper_cta.add_theme_font_size_override("font_size",14); wallpaper_cta.icon=GameIcons.texture("Wallpaper"); wallpaper_cta.expand_icon=true; wallpaper_cta.add_theme_constant_override("icon_max_width",24); wallpaper_cta.add_theme_stylebox_override("normal",menu_skin(Color("#7046a4"),Color("#e5b7ff")))
	var settings=button(brand,"⚙",func(): select("Settings")); settings.size_flags_horizontal=SIZE_SHRINK_END; settings.custom_minimum_size=Vector2(43,34)
	var header=panel(layout)
	var head=row(header)
	identity_art=TextureRect.new(); identity_art.custom_minimum_size=Vector2(48,48); identity_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; identity_art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; head.add_child(identity_art)
	var identity=VBoxContainer.new(); identity.size_flags_horizontal=SIZE_EXPAND_FILL; identity.add_theme_constant_override("separation",2); head.add_child(identity)
	title_label=label(identity,"Mosky",21); title_label.clip_text=true
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
	pet_touch=Button.new(); pet_touch.flat=true; pet_touch.focus_mode=FOCUS_NONE; pet_touch.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND; pet_touch.pressed.connect(func(): perform("hatch" if store.s.stage==0 else "bond")); visual.add_child(pet_touch)
	egg_art=TextureRect.new(); egg_art.texture=tex("res://assets/premium_egg.png"); egg_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; egg_art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; egg_art.set_anchors_and_offsets_preset(PRESET_CENTER); egg_art.offset_left=-75; egg_art.offset_right=75; egg_art.offset_top=-80; egg_art.offset_bottom=70; egg_art.mouse_filter=MOUSE_FILTER_IGNORE; visual.add_child(egg_art)
	hotspot_layer=Control.new(); hotspot_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT); hotspot_layer.mouse_filter=MOUSE_FILTER_IGNORE; visual.add_child(hotspot_layer)
	feedback_layer=Control.new(); feedback_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT); feedback_layer.mouse_filter=MOUSE_FILTER_IGNORE; visual.add_child(feedback_layer)
	pet_status=Label.new(); pet_status.mouse_filter=MOUSE_FILTER_IGNORE; pet_status.add_theme_font_size_override("font_size",15); pet_status.add_theme_color_override("font_outline_color",Color("#211633")); pet_status.add_theme_constant_override("outline_size",5); visual.add_child(pet_status)
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
	notice=label(layout,"",13)
	notice.clip_text=false
	notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_color_override("font_color",Color("#f2d3a0"))
	notice.hide()
	section_scroll=ScrollContainer.new(); section_scroll.custom_minimum_size.y=88; section_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; layout.add_child(section_scroll)
	enable_swipe(section_scroll)
	body=VBoxContainer.new(); body.mouse_filter=MOUSE_FILTER_PASS; body.size_flags_horizontal=SIZE_EXPAND_FILL; section_scroll.add_child(body)
	actions=body
	reward_row=row(layout); reward_row.add_theme_constant_override("separation",5)
	wellness_cta=button(reward_row,"Care",func(): select("Care")); wellness_cta.custom_minimum_size.y=43; wellness_cta.add_theme_font_size_override("font_size",14); wellness_cta.icon=GameIcons.texture("clean"); wellness_cta.expand_icon=true; wellness_cta.add_theme_constant_override("icon_max_width",22)
	daily_cta=button(reward_row,"Daily Gift",func(): perform("daily")); daily_cta.custom_minimum_size.y=43; daily_cta.add_theme_font_size_override("font_size",14); daily_cta.icon=GameIcons.texture("daily"); daily_cta.expand_icon=true; daily_cta.add_theme_constant_override("icon_max_width",36); daily_cta.add_theme_stylebox_override("normal",skin(Color("#7747a8"),Color("#ffd38c")))
	care_cta=button(reward_row,"Today",func(): select("Today")); care_cta.custom_minimum_size.y=43; care_cta.add_theme_font_size_override("font_size",15); care_cta.icon=GameIcons.texture("bond"); care_cta.expand_icon=true; care_cta.add_theme_constant_override("icon_max_width",22)
	growth_cta=button(reward_row,"Growth",func(): select("Journal")); growth_cta.custom_minimum_size.y=43; growth_cta.add_theme_font_size_override("font_size",14); growth_cta.icon=GameIcons.texture("Journal"); growth_cta.expand_icon=true; growth_cta.add_theme_constant_override("icon_max_width",22)
	reward_audio=AudioStreamPlayer.new(); reward_audio.volume_db=-16; add_child(reward_audio)
	room_scroll=ScrollContainer.new(); room_scroll.custom_minimum_size.y=64; room_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; room_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO; layout.add_child(room_scroll)
	enable_swipe(room_scroll)
	room_strip=row(room_scroll); room_strip.size_flags_horizontal=SIZE_EXPAND_FILL
	room_strip.add_theme_constant_override("separation",5)
	for name in ["Bedroom","Kitchen","Bathroom","Toy room","Garden","Potion lab"]:
		var b=art_tile(room_strip,name,"res://assets/"+ROOMS[name]+".jpg",func(): room(name),59,12)
		b.custom_minimum_size.x=80
		room_tiles[name]=b
	swipe_children(room_strip)
	var dock_shell=panel(layout)
	menu_dock=row(dock_shell); menu_dock.add_theme_constant_override("separation",2)
	for tab in ["Home","Pets","World","Arcade","Shop","Wallpaper"]: nav_tile(menu_dock,tab)
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
	var art="premium_crystal.png" if tab=="Life" else str(NAV_ART.get(tab,"premium_star.png"))
	var b=art_tile(parent,tab,"res://assets/"+art,func(): select(tab),56,12,"bond" if tab=="Pets" else "More" if tab=="Life" else tab)
	b.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	nav_buttons[tab]=b
func reset_actions(columns:int=0):
	context_labels.clear(); context_bars.clear(); cell_tiles.clear(); action_controls.clear(); swipe_dirty=true
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
	register_action(b,id,i)
func register_action(b:Button,id:String,i:int):
	b.set_meta("action_id",id); b.set_meta("action_arg",i); b.set_meta("original_label",b.tooltip_text if not b.tooltip_text.is_empty() else b.text)
	b.add_theme_stylebox_override("disabled",menu_skin(Color("#282238"),Color("#574b68")))
	action_controls.append(b)
func update_action_controls():
	if is_instance_valid(hotspot_layer):
		for b in hotspot_layer.get_children():
			if b.has_meta("hotspot_action"):
				var block:String=store.action_block(str(b.get_meta("hotspot_action")))
				b.disabled=not block.is_empty(); b.tooltip_text=block
	for b in action_controls:
		if not is_instance_valid(b): continue
		var id:String=b.get_meta("action_id"); var i:int=b.get_meta("action_arg")
		var reason:String=store.action_block(id,i)
		var caption:String=b.get_meta("original_label")
		if id in ["sleep","lamp"]: caption="Wake" if store.asleep(store.now()) else "Sleep"
		if id=="auto": caption="Auto sleep: ON" if store.s.auto_sleep else "Auto sleep: OFF"
		if id=="harvest" and store.s.garden_at>store.now(): caption=time_text(store.garden_remaining(store.now()))
		if id=="field": caption=store.FIELDS[i]+(" ✓" if int(store.s.habitat)==i else "")
		if id in ["bond","play","toy","train","praise"] and reason=="Give your pet a moment": caption="Wait %.1fs"%maxf(0,1.5-(store.now()-store.s.interaction_at))
		b.disabled=not reason.is_empty(); b.tooltip_text=reason if b.disabled else caption
		b.modulate=Color("#d0c9dd") if b.disabled else Color.WHITE
		if b.has_meta("hint"):
			var hint=b.get_meta("hint") as Label
			if is_instance_valid(hint):
				hint.text=str(b.get_meta("detail")) if reason.is_empty() else reason
				hint.modulate=Color("#cbbde0") if reason.is_empty() else Color("#f2c590")
		if b.has_meta("short_cta") and id not in ["sleep","lamp","auto"]: caption=str(b.get_meta("original_label"))
		if b.get_child_count()>0 and b.get_child(0) is VBoxContainer:
			var title=b.get_child(0).get_child(1)
			title.text=caption
		else: b.text=caption
func paint_action(b:Button,id:String):
	var tint=Color(ACTION_COLORS.get(id,"#9271d9"))
	b.add_theme_stylebox_override("normal",skin(tint.darkened(.55),tint.lightened(.40)))
	b.add_theme_stylebox_override("pressed",skin(tint.darkened(.30),tint.lightened(.58),true))
func perform(id:String,i:int=0):
	var before:Dictionary=store.s.duplicate(true)
	var old_care:int=store.care_count()
	var old_level:int=store.level()
	var ok:bool=store.action(id,i)
	if ok:
		var changes:Array[String]=[]
		for key in ["coins","hunger","happy","energy","bond","xp","hygiene","materials","crystals"]:
			var d=int(store.s[key])-int(before[key])
			if d!=0: changes.append(("%+d "%d)+str({"hunger":"food","happy":"mood","xp":"XP"}.get(key,key)))
		notice.text="  •  ".join(changes) if not changes.is_empty() else "Done!"
		if store.care_count()>old_care: notice.text+="  •  Care %d/4"%mini(4,store.care_count())
		if store.level()>old_level: notice.text+="  •  LEVEL UP!"
		var new_companion=-1
		if id=="care_claim":
			for species_id in range(24,28):
				if (int(before.collection)&(1<<species_id))==0 and (int(store.s.collection)&(1<<species_id))!=0:
					new_companion=species_id;break
			if new_companion>=24:notice.text="NEW COMPANION: "+store.SPECIES[new_companion]
		if id=="field": notice.text="Habitat preference: "+store.FIELDS[i] if store.s.stage==0 else "Habitat preference: "+store.FIELDS[i]+" • Same pet"
		if id=="care_claim": show_care_reward(new_companion)
		play_reward(id=="care_claim" or store.level()>old_level or store.care_count()>old_care)
	else:
		notice.text=reason_for(id,i)
	refresh()
	notice.visible=not visual.visible
	if ok: live_stage.react(id,store.asleep(store.now()))
	update_action_controls()
	if visual.visible: show_feedback(notice.text,id)
	if section=="Shop": select("Shop")
	if section=="World" and id in ["field","trip","loot","friend","breed"]: update_context()
	if section=="Care Quest": select("Care Quest")
	if section=="Today": select("Today")
	if section=="Pets" and id=="form": show_collection()
	if section=="Family" and id=="form": select("Family")
func show_care_reward(unlocked:int):
	var popup=AcceptDialog.new()
	popup.title="Care chest unlocked!"
	popup.ok_button_text="Collect & continue"
	popup.add_theme_stylebox_override("panel",skin(Color("#51316d"),Color("#ffd48a")))
	var content=VBoxContainer.new(); content.add_theme_constant_override("separation",12); popup.add_child(content)
	var image=TextureRect.new(); image.texture=pixel_portrait("res://assets/pet_%d.png"%unlocked) if unlocked>=24 else GameIcons.texture("daily")
	image.custom_minimum_size=Vector2(260,220); image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; content.add_child(image)
	var heading=label(content,store.SPECIES[unlocked]+" unlocked!" if unlocked>=24 else "Care adventure complete!",23); heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var reward=label(content,"+25 coins    +2 materials    +15 XP",17); reward.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	if unlocked>=24:
		var b=button(content,"View new companion",func(): popup.queue_free(); collection_feature=unlocked; select("Pets")); b.custom_minimum_size.y=48
	popup.confirmed.connect(popup.queue_free)
	popup.canceled.connect(popup.queue_free)
	add_child(popup); popup.popup_centered(Vector2i(340,390))
func play_reward(big:bool):
	if not is_instance_valid(reward_audio): return
	if reward_sounds.has(big):
		reward_audio.stream=reward_sounds[big]; reward_audio.play(); return
	var sample_rate=22050
	var count=4410 if big else 2205
	var bytes=PackedByteArray(); bytes.resize(count*2)
	for j in range(count):
		var t=float(j)/sample_rate
		var freq=660.0 if not big else 523.25 if t<.065 else 659.25 if t<.13 else 783.99
		var env=sin(PI*float(j)/count)*exp(-t*3)
		bytes.encode_s16(j*2,int(sin(TAU*freq*t)*env*9000))
	var audio=AudioStreamWAV.new(); audio.format=AudioStreamWAV.FORMAT_16_BITS; audio.mix_rate=sample_rate; audio.data=bytes
	reward_sounds[big]=audio
	reward_audio.stream=audio; reward_audio.play()
func reason_for(id:String,i:int)->String:
	var block:String=store.action_block(id,i)
	if not block.is_empty(): return block
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
	if live_stage.camera_safe.has_area():
		p.offset_top=live_stage.camera_safe.position.y+22; p.offset_bottom=p.offset_top+48
	feedback_layer.add_child(p)
	var l=label(p,message,16); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.mouse_filter=MOUSE_FILTER_IGNORE
	p.modulate.a=0.0
	var tw=p.create_tween()
	tw.tween_property(p,"modulate:a",1.0,.13)
	tw.tween_interval(1.1)
	tw.tween_property(p,"modulate:a",0.0,0.35)
	tw.tween_callback(p.queue_free)
func add_action(name:String,id:String,i:int=0):
	if is_instance_valid(action_grid): quick(name,id,i)
	else: register_action(button(actions,name,func(): perform(id,i)),id,i)
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
	if tab in ["Life","More"]: tab="Care"
	if tab in life_tabs: life_tab=tab
	if tab!=section and is_instance_valid(notice): notice.text=""; notice.hide()
	section=tab
	for key in nav_buttons:
		nav_buttons[key].add_theme_stylebox_override("normal",menu_skin(Color("#365449"),Color("#9acdb6")) if key==tab or (key=="Pets" and tab=="Family") or (key=="World" and tab=="Habitat") or (key=="Home" and (tab=="Rooms" or tab in life_tabs)) else StyleBoxEmpty.new())
	if is_instance_valid(section_scroll):
		section_scroll.scroll_vertical=0
		var full_menu=tab!="Home"
		notice.visible=full_menu and not notice.text.is_empty()
		section_scroll.custom_minimum_size.y=88
		visual.visible=not full_menu
		stage_space.visible=not full_menu
		reward_row.visible=not full_menu
		room_scroll.visible=not full_menu
		meter_panel.visible=not full_menu
		section_scroll.size_flags_vertical=SIZE_EXPAND_FILL if full_menu else SIZE_FILL
	current_room=""
	if is_instance_valid(hotspot_layer):
		update_room_scene()
		room_tag.text="Your home"
		live_stage.set_room("room_bedroom")
	reset_actions(5 if tab=="Home" and store.s.stage>0 else 4 if tab=="Home" else 0)
	if tab in life_tabs and tab!="Today": life_header(tab)
	elif tab not in ["Home","Pets","Family","Shop","Rooms","Arcade","Wallpaper","World","Habitat","Today"]: label(actions,tab.to_upper(),22)
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
		"Family":
			build_family()
		"Care Quest":
			build_care_quest()
		"Today":
			build_today()
		"Settings":
			var profile=panel(actions); label(profile,"Your companion",22)
			var edit=LineEdit.new(); edit.text="Mosky"; edit.editable=false; profile.add_child(edit)
			action_card(actions,"Auto sleep","Rest automatically at night.","sleep","auto",0,"Toggle")
		"Wallpaper":
			build_wallpaper()
		"Care":
			build_care(false)
		"Rooms":
			section_heading(actions,"Your home","Six rooms, six ways to care for your companion.")
			var grid=GridContainer.new(); grid.columns=2; grid.add_theme_constant_override("h_separation",7); grid.add_theme_constant_override("v_separation",7); actions.add_child(grid)
			for entry in [["Bedroom","Rest, wake and lighting"],["Kitchen","Feed and cook"],["Bathroom","Wash and toilet"],["Toy room","Play and arcade"],["Garden","Plant, grow and harvest"],["Potion lab","Medicine and crafting"]]:
				room_link(grid,entry[0],entry[1],entry[0])
		"Arcade":
			build_arcade()
		"Shop":
			build_shop()
		"Journal":
			var growth=context_card("growth","Growth journey")
			context_meter(growth,"growth",Color("#b08bf0"))
			label(growth,"Care for Mosky as it grows. Its identity never changes.",14).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			context_card("quests","Daily quests")
			for i in range(3): action_card(actions,["Bond quest","Clean quest","Expedition quest"][i],["Show affection to your companion.","Clean a dirty habitat.","Complete an expedition."][i],"daily","quest",i,"Claim 15")
			action_card(actions,"Craft a crystal","Exchange three materials for one crystal.","craft","craft",0,"Craft")
			button(actions,"View collection ›",func(): select("Pets"))
		"World":
			build_world()
		"Habitat":
			build_habitat()
		"Cell":
			build_care(true)

	update_context()
func build_wallpaper():
	section_heading(actions,"Live wallpaper","Take your companion everywhere. Set it directly on your Android home screen.")
	var s:Dictionary=store.s
	var room_index=clampi(int(s.wallpaper_room),0,5)
	var card=panel(actions)
	var aspect=AspectRatioContainer.new(); aspect.ratio=9.0/16.0; aspect.stretch_mode=AspectRatioContainer.STRETCH_FIT; aspect.custom_minimum_size.y=320; card.add_child(aspect)
	var preview=Control.new(); preview.clip_contents=true; aspect.add_child(preview); wallpaper_preview=preview
	var base_color=ColorRect.new(); base_color.color=Color("#45305f"); base_color.set_anchors_and_offsets_preset(PRESET_FULL_RECT); base_color.mouse_filter=MOUSE_FILTER_IGNORE; preview.add_child(base_color)
	var back=TextureRect.new(); back.texture=tex("res://assets/"+store.WALL_ROOMS[room_index]+".jpg"); back.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; back.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; back.set_anchors_and_offsets_preset(PRESET_FULL_RECT); preview.add_child(back)
	if s.wallpaper_minimal: back.hide()
	var pet=TextureRect.new(); pet.texture=pixel_portrait("res://assets/premium_egg.png" if s.stage==0 else ("res://assets/pet_sleep_%d.png" if store.asleep(store.now()) else "res://assets/pet_%d.png")%store.species()); pet.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; pet.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; preview.add_child(pet); wallpaper_pet=pet
	wallpaper_preview_status=Label.new(); wallpaper_preview_status.add_theme_font_size_override("font_size",11); wallpaper_preview_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; wallpaper_preview_status.add_theme_constant_override("outline_size",4); wallpaper_preview_status.add_theme_color_override("font_outline_color",Color("#241739")); preview.add_child(wallpaper_preview_status)
	preview.resized.connect(layout_wallpaper_preview)
	layout_wallpaper_preview.call_deferred()
	var title=label(card,store.pet_name()+" • Live wallpaper",21)
	var plugin=store.wallpaper_plugin()
	var available:bool=plugin!=null
	var status=label(card,"Active on your home screen" if available and plugin.isActive() else "Ready to set" if available else "Available in the Android wallpaper build",14); status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var apply=button(card,"Customize Android wallpaper ›" if available and plugin.isActive() else "Set live wallpaper ›",func():
		if store.wallpaper_sync() and plugin.openPicker(): status.text="Choose Apply in the Android wallpaper preview."
		else: status.text="Wallpaper preview could not open. Check Android wallpaper support.")
	apply.custom_minimum_size.y=56; apply.icon=GameIcons.texture("Wallpaper"); apply.expand_icon=true; apply.add_theme_constant_override("icon_max_width",32)
	apply.disabled=not available
	apply.add_theme_stylebox_override("normal",menu_skin(Color("#7950ad"),Color("#e9c5ff")))
	section_heading(actions,"Position & size","Keep your companion clear of your app icons.")
	for entry in [["wallpaper_x","Horizontal",["Left","Center","Right"]],["wallpaper_y","Vertical",["Top","Middle","Bottom"]],["wallpaper_size","Pet size",["Small","Medium","Large"]]]:
		var key:String=entry[0]
		label(actions,entry[1],15)
		var options=row(actions)
		for i in range(3):
			var choice=button(options,entry[2][i],func(): s[key]=i; store.save_game(); layout_wallpaper_preview(); update_wallpaper_choices())
			choice.custom_minimum_size.y=42; choice.add_theme_font_size_override("font_size",14); choice.set_meta("wall_key",key); choice.set_meta("wall_value",i)
	update_wallpaper_choices()
	section_heading(actions,"Personalize","Settings apply to the live wallpaper as well as this preview.")
	var rooms=GridContainer.new(); rooms.columns=3; actions.add_child(rooms)
	for j in range(6):
		var b=art_tile(rooms,["Bedroom","Kitchen","Bathroom","Toy room","Garden","Potion lab"][j]+(" ✓" if j==room_index else ""),"res://assets/"+store.WALL_ROOMS[j]+".jpg",func(): s.wallpaper_room=j; store.save_game(); select("Wallpaper"),74,13)
	for entry in [["wallpaper_minimal","Minimal background"],["wallpaper_battery","Battery saver"],["wallpaper_status","Show pet status"]]:
		var key:String=entry[0]
		button(actions,entry[1]+(": ON" if s[key] else ": OFF"),func(): s[key]=not s[key]; store.save_game(); select("Wallpaper"))
	var help=panel(actions)
	label(help,"How to interact",20)
	var desc=label(help,"Tap your pet for a reaction. Double-tap queues a cuddle; swipe up on the pet queues a free grain meal. Queued care is applied once when you return to the game, if your pet needs it. Android launchers may intercept some gestures.",14); desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
func layout_wallpaper_preview():
	if not is_instance_valid(wallpaper_preview) or not is_instance_valid(wallpaper_pet): return
	var s:Dictionary=store.s
	var dims:Vector2=wallpaper_preview.size
	if dims.x<=0 or dims.y<=0: return
	var u=minf(dims.x,dims.y)
	var extent=u*(.75 if s.stage<=1 else 1.0)*[.42,.60,.76][clampi(int(s.wallpaper_size),0,2)]
	var x=clampf(dims.x*[.25,.5,.75][clampi(int(s.wallpaper_x),0,2)],extent*.55,dims.x-extent*.55)
	var y=clampf(dims.y*[.26,.47,.68][clampi(int(s.wallpaper_y),0,2)],extent*.56,dims.y-extent*.60-u*.09)
	wallpaper_pet.size=Vector2.ONE*extent; wallpaper_pet.position=Vector2(x,y)-wallpaper_pet.size*.5
	wallpaper_pet.texture=pixel_portrait("res://assets/premium_egg.png" if s.stage==0 else ("res://assets/pet_sleep_%d.png" if store.asleep(store.now()) else "res://assets/pet_%d.png")%store.species())
	if is_instance_valid(wallpaper_preview_status):
		wallpaper_preview_status.visible=bool(s.wallpaper_status)
		wallpaper_preview_status.text=store.pet_name()+"\n"+store.care_priority()
		wallpaper_preview_status.size=Vector2(u*.70,30)
		wallpaper_preview_status.position=Vector2(clampf(x,u*.35,dims.x-u*.35)-u*.35,minf(dims.y-u*.075,y+extent*.55+u*.035)-12)
func update_wallpaper_choices():
	for choice in actions.find_children("*","Button",true,false):
		if choice.has_meta("wall_key"):
			var selected=int(store.s[choice.get_meta("wall_key")])==int(choice.get_meta("wall_value"))
			choice.add_theme_stylebox_override("normal",menu_skin(Color("#7850ad") if selected else Color("#27203e"),Color("#e4bdff") if selected else Color("#5c4c75")))
func build_today():
	var at:float=store.now()
	store.arcade_daily_sync(at)
	var complete:Array=store.today_status(at)
	var count:int=store.today_count(at)
	section_heading(actions,"Today","Your daily activities in one place. Complete at your own pace; no streak penalties.")
	var summary=panel(actions)
	label(summary,"Daily adventure · %d/4"%count,22).modulate=Color("#ffd38d")
	var progress=ProgressBar.new();progress.max_value=4;progress.value=count;progress.show_percentage=false;progress.custom_minimum_size.y=13;summary.add_child(progress)
	var claimed=store.s.today_claim_day==store.date_key(at)
	label(summary,"Adventure bonus: 35 coins · 1 crystal · 15 XP",14).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var reward=button(summary,"Collected ✓" if claimed else "Claim adventure bonus" if count==4 else "Complete today's activities",func():
		if store.today_claim():play_reward(true);select("Today");refresh())
	reward.disabled=claimed or count<4 or store.s.stage==0
	reward.add_theme_stylebox_override("normal",menu_skin(Color("#77522d"),Color("#f5d28a")))
	var titles=["Daily gift","Care adventure","Arcade challenge","Field research"]
	var details=["20 coins + material","%d/4 different care activities · chest"%mini(4,store.care_count()),"%s · score %d/%d"%[GAMES[store.arcade_daily_mode()],mini(store.arcade_daily_target(),int(store.s.arcade_daily_best)),store.arcade_daily_target()],"Claim one regional field contract"]
	var icons=["daily","bond","Arcade","World"]
	var destinations=["Home","Care Quest","Arcade","World"]
	for i in range(4):
		var card=panel(actions);var line=row(card)
		var art=TextureRect.new();art.texture=GameIcons.texture(icons[i]);art.custom_minimum_size=Vector2(42,42);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;line.add_child(art)
		var copy=VBoxContainer.new();copy.size_flags_horizontal=SIZE_EXPAND_FILL;line.add_child(copy)
		label(copy,titles[i],18).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		label(copy,details[i],13).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var b=button(line,"Done ✓" if complete[i] else "Claim" if i==0 else "Go ›",func():
			if i==0:perform("daily")
			else:select(destinations[i]))
		b.size_flags_horizontal=SIZE_SHRINK_CENTER;b.custom_minimum_size=Vector2(78,44);b.add_theme_font_size_override("font_size",14)
		b.disabled=complete[i] or store.s.stage==0
		if complete[i]:card.modulate=Color("#c5edce")
	button(actions,"‹ Return home",func():select("Home"))
	swipe_children(actions)
func build_care_quest():
	var quest=context_card("care_quest","Daily care adventure")
	context_meter(quest,"care_quest",Color("#e6aa65"))
	var next:int=store.next_special()
	if next>=24:
		var hero=panel(actions); var line=row(hero)
		var art=TextureRect.new(); art.texture=pixel_portrait("res://assets/pet_%d.png"%next); art.custom_minimum_size=Vector2(124,118); art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; line.add_child(art)
		var copy=VBoxContainer.new(); copy.size_flags_horizontal=SIZE_EXPAND_FILL; line.add_child(copy)
		label(copy,"NEXT COMPANION",12).modulate=Color("#ffd08a")
		label(copy,store.SPECIES[next],23).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		label(copy,"Complete 4 different care activities and claim your chest.",14).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var claim=action_card(actions,"Care chest","25 coins · 2 materials · 15 XP","daily","care_claim",0,"Claim")
	claim.add_theme_stylebox_override("normal",menu_skin(Color("#80512f"),Color("#f5cb86")))
	section_heading(actions,"Activities","Any four different activities count. There is no need to complete all six.")
	for j in range(6):
		var done=(int(store.s.care_mask)&(1<<j))!=0
		var destination=["Home","Kitchen","Bathroom","Toy room","Home","Garden"][j]
		var card=panel(actions); var line=row(card)
		var art=TextureRect.new(); art.texture=GameIcons.texture(["bond","food","clean","play","clean","daily"][j]); art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.custom_minimum_size=Vector2(37,37); line.add_child(art)
		var copy=VBoxContainer.new(); copy.size_flags_horizontal=SIZE_EXPAND_FILL; line.add_child(copy)
		label(copy,store.CARE_NAMES[j],16)
		var detail=label(copy,["Cuddle or praise your pet.","Feed any food or snack when hungry.","Wash, rinse or use the toilet.","Play, train or use a toy.","Clean actual waste in your habitat.","Plant a seed and harvest when ready."][j],13); detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var btn=button(line,"Done ✓" if done else "Go ›",func():
			if destination=="Home": select("Home")
			else: room(destination))
		btn.size_flags_horizontal=SIZE_SHRINK_CENTER; btn.custom_minimum_size=Vector2(76,40); btn.add_theme_font_size_override("font_size",14); btn.disabled=done
		if done: detail.modulate=Color("#a6e8bc")
func build_shop():
	section_heading(actions,"Pet boutique","Outfits, furniture and supplies.")
	var funds=label(actions,"Wallet: %d coins · %d crystals"%[store.s.coins,store.s.crystals],16); funds.modulate=Color("#ffd38d")
	var tabs=row(actions)
	for name in ["Accessories","Furniture","Wardrobe","Supplies"]:
		var b=button(tabs,name,func(): shop_tab=name; select("Shop")); b.add_theme_font_size_override("font_size",12); b.custom_minimum_size.y=42
		b.add_theme_stylebox_override("normal",menu_skin(Color("#7850ad") if shop_tab==name else Color("#27203e"),Color("#e4bdff") if shop_tab==name else Color("#5c4c75")))
	var grid=GridContainer.new(); grid.columns=2; grid.add_theme_constant_override("h_separation",7); grid.add_theme_constant_override("v_separation",7); actions.add_child(grid)
	var s:Dictionary=store.s
	if shop_tab in ["Accessories","Furniture"]:
		for i in range(0,3) if shop_tab=="Accessories" else range(3,store.ITEMS.size()):
			var owned=(int(s.owned)&(1<<i))!=0
			var active=s.equipped==i+1 or s.installation==i+1
			shop_tile(grid,store.ITEMS[i],("Wearing" if i<3 else "Installed") if active else "Owned" if owned else "%d coins"%store.PRICES[i],["Pet accessory","Pet accessory","Pet accessory","Bathroom furniture","Bedroom furniture","Garden furniture"][i],"res://assets/item_%d.png"%i,"Remove" if active else "Use" if owned else "Buy","use" if owned else "buy",i)
	elif shop_tab=="Wardrobe":
		for i in range(store.CLOTHES.size()):
			var owned=(int(s.wardrobe)&(1<<i))!=0
			var active=s.worn.has(i+1)
			shop_tile(grid,store.CLOTHES[i],"Wearing" if active else "Owned" if owned else "%d coins"%store.COST[i],"Wearable outfit","res://assets/clothes_%d.png"%i,"Remove" if active else "Wear" if owned else "Buy","wear" if owned else "clothes",i)
	else:
		shop_tile(grid,"Medicine","12 coins · %d owned"%s.medicine,"Treats sick cells.","res://assets/premium_medicine.png","Buy","supply",0)
		shop_tile(grid,"Snack","5 coins · %d owned"%s.snacks,"Feeds and improves mood.","res://assets/premium_snack.png","Buy","supply",1)
func shop_tile(parent:Node,name:String,cost:String,detail:String,path:String,cta:String,id:String,arg:int):
	var card=panel(parent)
	var art=TextureRect.new(); art.texture=tex(path); art.custom_minimum_size.y=104; art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; card.add_child(art)
	var title=label(card,name,17); title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var price=label(card,cost,15); price.modulate=Color("#ffd38d")
	var hint=label(card,detail,12); hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var b=button(card,cta,func(): perform(id,arg)); b.custom_minimum_size.y=42; b.add_theme_font_size_override("font_size",15)
	b.set_meta("hint",hint); b.set_meta("detail",detail); b.set_meta("short_cta",true); register_action(b,id,arg)
func build_arcade():
	section_heading(actions,"Arcade","Five games · Earn coins, beat records and collect medals.")
	store.arcade_daily_sync(store.now())
	var daily=panel(actions)
	var mode:int=store.arcade_daily_mode()
	label(daily,"DAILY CHALLENGE",12).modulate=Color("#f7d39a")
	label(daily,GAMES[mode],21)
	var goal:int=store.arcade_daily_target()
	label(daily,"Score %d · Reward 25 coins + material"%goal,14).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var progress=ProgressBar.new();progress.max_value=goal;progress.value=mini(goal,int(store.s.arcade_daily_best));progress.custom_minimum_size.y=10;progress.show_percentage=false;daily.add_child(progress)
	label(daily,"%d / %d"%[mini(goal,int(store.s.arcade_daily_best)),goal],13)
	var ready=int(store.s.arcade_daily_best)>=goal
	var claimed:bool=store.s.arcade_daily_claimed
	var cta=button(daily,"Collected ✓" if claimed else "Claim bonus" if ready else "Play challenge ›",func():
		if ready:
			if store.arcade_claim_daily():play_reward(true);select("Arcade");refresh()
		else:launch_game(mode))
	cta.disabled=claimed or (not ready and not store.arcade_block(mode).is_empty())
	cta.add_theme_stylebox_override("normal",menu_skin(Color("#77522d"),Color("#f5d28a")))
	if not store.arcade_last_result.is_empty():
		var result=store.arcade_last_result
		var last=panel(actions)
		label(last,("NEW RECORD · " if result.record else "LAST RUN · ")+GAMES[int(result.mode)],15).modulate=Color("#bde9c9")
		label(last,"%d score · +%d coins"%[result.score,result.reward],19)
		store.arcade_last_result={}
	var hero=panel(actions)
	var art=TextureRect.new(); art.texture=tex("res://assets/sky-panorama.png"); art.custom_minimum_size.y=135; art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; hero.add_child(art)
	label(hero,"PET DASH 3D",24).modulate=Color("#f7d39a")
	label(hero,"Sky kingdom · Best %d"%int(store.s.best[4]),15)
	arcade_medals_row(hero,4)
	var b=button(hero,"Play ›",func(): launch_game(4)); b.add_theme_stylebox_override("normal",menu_skin(Color("#7950ad"),Color("#e9c5ff")))
	var reason:String=store.arcade_block(4); b.disabled=not reason.is_empty()
	if not reason.is_empty(): label(hero,reason,14).modulate=Color("#f2c590")
	var grid=GridContainer.new(); grid.columns=2; grid.add_theme_constant_override("h_separation",7); grid.add_theme_constant_override("v_separation",7); actions.add_child(grid)
	for i in range(4):
		var card=panel(grid)
		var thumb=TextureRect.new(); thumb.texture=tex("res://assets/arcade_"+["star","flappy","cloud","find"][i]+".jpg"); thumb.custom_minimum_size.y=95; thumb.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; thumb.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; card.add_child(thumb)
		label(card,GAMES[i],18).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		label(card,["Build a combo","Fly through gates","Climb the sky","Spot your pet"][i],13).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		label(card,"Best %d"%int(store.s.best[i]),13).modulate=Color("#e4bcff")
		arcade_medals_row(card,i)
		var play=button(card,"Play ›",func(): launch_game(i)); play.disabled=not store.arcade_block(i).is_empty()
func arcade_medals_row(parent:Node,mode:int):
	var achieved:int=store.arcade_medal_level(mode)
	var claimed:int=clampi(int(store.s.arcade_medals[mode]),0,3)
	var medal=row(parent)
	for tier in range(3):
		var icon=TextureRect.new();icon.texture=GameIcons.texture("daily");icon.custom_minimum_size=Vector2(24,24);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate=[Color("#c88b60"),Color("#c2d6e7"),Color("#ffd271")][tier] if tier<achieved else Color("#59536c")
		medal.add_child(icon)
	label(medal,"%d/3"%achieved,12)
	if claimed<achieved:
		var b=button(parent,"Claim medal ›",func():
			if store.arcade_claim_medal(mode):play_reward(true);select("Arcade");refresh())
		b.custom_minimum_size.y=38;b.add_theme_font_size_override("font_size",13)
	elif achieved<3:
		label(parent,"Next medal: %d"%int(store.MEDALS[mode][achieved]),12).modulate=Color("#d0bfe6")
	else:label(parent,"All medals earned",12).modulate=Color("#bde9c9")
func life_header(tab:String):
	var title=label(actions,"Care & growth",23)
	title.add_theme_color_override("font_color",Color("#f4d9ff"))
	
	var tabs=row(actions); tabs.add_theme_constant_override("separation",5)
	for entry in [["Wellness","Care"],["Growth","Journal"],["Daily care","Care Quest"]]:
		var active=tab==entry[1] or (entry[1]=="Care" and tab=="Cell")
		var b=button(tabs,entry[0],func(): select(entry[1])); b.custom_minimum_size.y=42; b.add_theme_font_size_override("font_size",16)
		b.add_theme_stylebox_override("normal",menu_skin(Color("#7850ad") if active else Color("#27203e"),Color("#e4bdff") if active else Color("#5c4c75")))
func section_heading(parent:Node,title:String,subtitle:String=""):
	var l=label(parent,title,21); l.add_theme_color_override("font_color",Color("#e6ccff"))
	if not subtitle.is_empty():
		var sub=label(parent,subtitle,14); sub.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; sub.modulate=Color("#c4b7d8")
func action_card(parent:Node,name:String,detail:String,icon_key:String,id:String,arg:int=0,cta:String="Do"):
	var shell=panel(parent)
	var line=row(shell)
	var art=TextureRect.new(); art.texture=GameIcons.texture(icon_key)
	if art.texture==null: art.texture=tex("res://assets/"+str(ACTION_ART.get(icon_key,"premium_star.png")))
	art.custom_minimum_size=Vector2(46,46); art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; line.add_child(art)
	var copy=VBoxContainer.new(); copy.size_flags_horizontal=SIZE_EXPAND_FILL; copy.add_theme_constant_override("separation",2); line.add_child(copy)
	label(copy,name,17).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var hint=label(copy,detail,13); hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; hint.modulate=Color("#ccbfe0")
	var btn=button(line,cta,func(): perform(id,arg)); btn.custom_minimum_size=Vector2(85,46); btn.size_flags_horizontal=SIZE_SHRINK_CENTER; btn.add_theme_font_size_override("font_size",14)
	btn.add_theme_stylebox_override("normal",menu_skin(Color("#61428a"),Color("#c59de5")))
	btn.set_meta("hint",hint); btn.set_meta("detail",detail); btn.set_meta("short_cta",true)
	register_action(btn,id,arg)
	return btn
func room_link(parent:Node,name:String,detail:String,room_name:String):
	var shell=panel(parent)
	var art=TextureRect.new(); art.texture=tex("res://assets/"+ROOMS[room_name]+".jpg"); art.custom_minimum_size.y=88; art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; shell.add_child(art)
	label(shell,name,17)
	var sub=label(shell,detail,13); sub.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; sub.modulate=Color("#d1c5e4")
	var b=button(shell,"Enter ›",func(): room(room_name)); b.add_theme_font_size_override("font_size",15)
func build_care(show_lab:bool):
	var care=context_card("care","Wellness")
	context_meter(care,"hygiene",Color("#55c8d3"))
	context_meter(care,"toilet",Color("#8ecb96"))
	var next=button(care,"Daily care adventure ›",func(): select("Care Quest"))
	next.add_theme_stylebox_override("normal",menu_skin(Color("#76502f"),Color("#f7cd8a")))
	section_heading(actions,"Care rooms","Choose a room for a real interaction with your pet.")
	var grid=GridContainer.new(); grid.columns=2; grid.add_theme_constant_override("h_separation",7); grid.add_theme_constant_override("v_separation",7); actions.add_child(grid)
	room_link(grid,"Kitchen","Food and snacks.","Kitchen")
	room_link(grid,"Bathroom","Wash and toilet.","Bathroom")
	room_link(grid,"Toy room","Play and have fun.","Toy room")
	room_link(grid,"Bedroom","Rest and wake up.","Bedroom")
	section_heading(actions,"Bond & training","Spend time together to prepare for secret evolution.")
	action_card(actions,"Cuddle","Build affection and bond.","bond","bond",0,"Cuddle")
	action_card(actions,"Train","Uses 4 energy; improves training.","play","train",0,"Train")
	action_card(actions,"Clean habitat","Earn coins and expedition fuel from waste.","clean","clean",0,"Clean")
	section_heading(actions,"Health lab","Treat sick cells when your pet is unwell.")
	var cells=context_card("cells","Cell health")
	var cell_grid=GridContainer.new(); cell_grid.columns=3; cells.add_child(cell_grid)
	for i in range(6):
		var cell=art_tile(cell_grid,"Healthy","res://assets/premium_crystal.png",func(): perform("cell"),68,13)
		cell_tiles.append(cell)
	if show_lab: section_scroll.set_deferred("scroll_vertical",maxi(0,section_scroll.get_v_scroll_bar().max_value-section_scroll.size.y))
	action_card(actions,"Medicine","Cures all sick cells; buy supplies in Shop.","medicine","medicine",0,"Use")
func build_world():
	section_heading(actions,"Explore the world","Explore 3D territories and dungeons with Mosky. Recover treasure and earn explorer ranks.")
	for i in range(3):
		var shell=panel(actions); var line=row(shell)
		var art=TextureRect.new(); art.texture=tex("res://assets/"+["room_garden.jpg","arcade_find.jpg","sky-panorama.png"][i]); art.custom_minimum_size=Vector2(148,125); art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; line.add_child(art)
		var copy=VBoxContainer.new(); copy.size_flags_horizontal=SIZE_EXPAND_FILL; line.add_child(copy)
		label(copy,Research.REGIONS[i],21).modulate=Research.TINTS[i]
		label(copy,Research.SUB[i],13).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		label(copy,"Explorer Rank %d/5"%store.research_rank(i),14).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var text="Explore ›"
		var go=button(copy,text,func(): hunt_region=i; hunt_message=""; select("Habitat"))
		go.add_theme_stylebox_override("normal",menu_skin(Research.TINTS[i].darkened(.55),Research.TINTS[i]))
	
	var exp=context_card("expedition","Supply expeditions")
	context_meter(exp,"expedition",Color("#65b4ed"))
	label(exp,"Optional timed trips earn materials and coins after Kid stage.",13).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	for i in range(3):action_card(actions,Research.REGIONS[i],"%d min · Lv %d · %d fuel"%[10+i*10,1+i*2,i],"daily","trip",i,"Send")
	action_card(actions,"Expedition treasure","Collect after the trip returns.","daily","loot",0,"Collect")
func field_contract(parent:Node,r:int):
	var shell=panel(parent)
	var head=row(shell)
	label(head,Research.REGIONS[r],17).size_flags_horizontal=SIZE_EXPAND_FILL
	label(head,"%d/3"%int(store.s.research_daily[r]),16).modulate=Research.TINTS[r]
	var bar=ProgressBar.new(); bar.show_percentage=false; bar.max_value=3; bar.value=store.s.research_daily[r]; bar.custom_minimum_size.y=9; shell.add_child(bar)
	var claimed=(int(store.s.research_claimed)&(1<<r))!=0
	var ready=int(store.s.research_daily[r])>=3
	var b=button(shell,"Collected ✓" if claimed else "Claim 25 coins + materials" if ready else "Survey local traces ›",func():
		if ready:
			if store.research_claim(r): play_reward(true); select(section)
		else: open_patrol(r))
	b.disabled=claimed
	b.custom_minimum_size.y=44
func open_patrol(r:int):
	hunt_region=r
	section="Habitat"
	open_active_field(r,true)
func sanctuary_cards(parent:Node,r:int):
	section_heading(parent,"Hidden sanctuaries","Rank up to unlock explorable ruins. Find three relic fragments in each.")
	for tier in range(3):
		var shell=panel(parent); var line=row(shell)
		var icon=TextureRect.new(); icon.texture=tex("res://assets/premium_crystal.png"); icon.custom_minimum_size=Vector2(44,44); icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; line.add_child(icon)
		var copy=VBoxContainer.new(); copy.size_flags_horizontal=SIZE_EXPAND_FILL; line.add_child(copy)
		label(copy,Research.SANCTUARIES[r][tier],18).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var block:String=store.sanctuary_block(r,tier)
		var done=(int(store.s.sanctuary_mask)&Research.sanctuary_bit(r,tier))!=0
		label(copy,block if not block.is_empty() else "+%d coins · %d crystals"%[Research.sanctuary_reward(tier),1+tier],13).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var b=button(line,"Done ✓" if done else "Enter ›" if block.is_empty() else "Locked",func(): open_sanctuary(r,tier))
		b.disabled=not block.is_empty(); b.size_flags_horizontal=SIZE_SHRINK_CENTER; b.custom_minimum_size=Vector2(86,44)
func open_sanctuary(r:int,tier:int):
	var block:String=store.sanctuary_block(r,tier)
	if not block.is_empty():hunt_message=block;select("Habitat");return
	reset_actions()
	section_heading(actions,Research.SANCTUARIES[r][tier],"Walk by tapping or dragging on the terrain. Follow the glimmers; nearby relics become visible.")
	var field=preload("res://sanctuary_field.gd").new()
	actions.add_child(field)
	var mask=int(store.s.sanctuary_progress[r*3+tier])
	field.setup(r,tier,mask,pixel_portrait("res://assets/pet_0.png"))
	var count=0
	for i in range(3):
		if (mask&(1<<i))!=0:count+=1
	var counter=label(actions,"Relic fragments %d/3 · Treasure recovery: %d energy"%[count,Research.sanctuary_cost(tier)],15)
	counter.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var feedback=label(actions,"Explore the terrain to reveal glimmers.",14);feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	field.recovered.connect(func(index:int):
		var result:Dictionary=store.sanctuary_collect(r,tier,index)
		hunt_message=str(result.get("message",""))
		if result.get("complete",false):
			play_reward(true);select("Habitat")
		elif result.get("ok",false):
			play_reward(false);field.mask=int(store.s.sanctuary_progress[r*3+tier]);field.locked=false
			var found=0
			for j in range(3):
				if (field.mask&(1<<j))!=0:found+=1
			counter.text="Relic fragments %d/3 · Treasure recovery: %d energy"%[found,Research.sanctuary_cost(tier)]
			feedback.text=hunt_message; feedback.modulate=Color("#f8d788")
		else:select("Habitat"))
	button(actions,"‹ Return to habitat",func(): select("Habitat"))
	swipe_children(actions);field.mouse_filter=MOUSE_FILTER_STOP
	section_scroll.scroll_vertical=0
func build_habitat():
	var r=hunt_region
	var back=row(actions)
	button(back,"‹ World",func():select("World")).custom_minimum_size.y=42
	var hero=panel(actions)
	var art=TextureRect.new();art.texture=tex("res://assets/"+["room_garden.jpg","arcade_find.jpg","sky-panorama.png"][r]);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;art.custom_minimum_size.y=145;hero.add_child(art)
	label(hero,Research.REGIONS[r],26).modulate=Research.TINTS[r]
	label(hero,"Explorer rank %d · Treasure expedition"%store.research_rank(r),14)
	var go=button(hero,"ENTER MYSTERY DUNGEON",func():open_active_field(r,false))
	go.custom_minimum_size.y=60
	go.disabled=not store.available() or store.s.energy<3 or store.s.germs>0 or store.s.hunger<1
	var roam=button(hero,"EXPLORE OPEN TERRITORY",func():open_active_field(r,false,true))
	roam.custom_minimum_size.y=52;roam.disabled=go.disabled
	if not hunt_message.is_empty():label(hero,hunt_message,15).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var options=row(actions)
	button(options,"Local survey",func():open_field_options(r,false)).custom_minimum_size.y=50
	button(options,"Sanctuaries",func():open_field_options(r,true)).custom_minimum_size.y=50
	swipe_children(actions)
func build_field_guide(r:int):
	hunt_region=r;select("Habitat")
func open_field_options(r:int,sanctuaries:bool):
	reset_actions()
	button(actions,"‹ Back to territory",func():select("Habitat"))
	if sanctuaries:sanctuary_cards(actions,r)
	else:field_contract(actions,r)
	swipe_children(actions);section_scroll.scroll_vertical=0
func open_active_field(r:int,patrol:bool,legacy:bool=false):
	var session:Dictionary=store.field_begin(r,patrol,not legacy)
	if session.is_empty():hunt_message="Cannot explore right now. Check energy and rank.";select("Habitat");return
	var field=preload("res://wild_field.gd").new() if legacy else preload("res://dungeon_view.gd").new()
	add_child(field);field.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	if legacy:field.setup(r,int(session.id),int(session.step),bool(session.finale),patrol,int(session.seed),store.species())
	else:field.setup(r,int(session.id),int(session.step),bool(session.finale),patrol,int(session.seed),store.species(),session.get("training",{}))
	# Stop rendering the home pet while the full-screen field is active.
	live_stage.hide()
	field.canceled.connect(func():store.field_cancel();field.hide();field.queue_free();live_stage.show();select.call_deferred("Habitat"))
	field.ended.connect(func(success:bool,completed:int,elapsed:float):
		var result:Dictionary=store.field_finish(success,completed,elapsed,field.run.hits,0 if legacy else field.run.coins,0 if legacy else field.run.materials,[] if legacy else field.run.earned_ev)
		field.hide();field.queue_free()
		live_stage.show()
		finish_hunt.call_deferred(result))
func open_research_trial(r:int,id:int,step:int,site:int):
	reset_actions()
	section_heading(actions,Research.REGIONS[r],Research.SITES[r][site]+" · recover the fresh trace")
	var trial=preload("res://research_trial.gd").new(); panel(actions).add_child(trial); trial.setup(r,id,step)
	if store.research_skill_ready(r): trial.add_skill(func(): return store.research_use_skill(r))
	trial.resolved.connect(func(answer:Array,phase:float): finish_hunt(store.research_survey(r,site,id,step,answer,phase)))
	button(actions,"‹ Return to map",func(): select("Habitat"))
	swipe_children(actions)
	section_scroll.scroll_vertical=0
func hunt_action(kind:String,choice:int):
	finish_hunt(store.research_action(kind,hunt_region,choice))
func finish_hunt(result:Dictionary):
	hunt_message=str(result.get("message",""))
	if result.get("unlocked",false):
		play_reward(true)
		select("Habitat")
		var popup=AcceptDialog.new(); popup.title="DISCOVERY COMPLETE"; popup.ok_button_text="Continue exploring"
		var content=VBoxContainer.new();content.add_theme_constant_override("separation",10);popup.add_child(content)
		var id=int(result.species)
		var tier=0 if id<12 else 1 if id<24 else 2
		var rarity=label(content,["COMMON DISCOVERY","RARE DISCOVERY","MYSTIC DISCOVERY"][tier],15);rarity.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;rarity.modulate=[Color("#a7e9af"),Color("#8fd9ff"),Color("#e1b4ff")][tier]
		var image=TextureRect.new(); image.texture=pixel_portrait("res://assets/pet_%d.png"%id); image.custom_minimum_size=Vector2(250,200); image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; content.add_child(image)
		label(content,store.SPECIES[id],24).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var rewards=panel(content)
		var reward_line=row(rewards)
		label(reward_line,"+%d coins"%int(result.coins),17).size_flags_horizontal=SIZE_EXPAND_FILL
		label(reward_line,"+%d XP"%int(result.get("xp",25)),17)
		var materials_line=row(rewards)
		label(materials_line,"+%d materials"%int(result.get("materials",2)),15).size_flags_horizontal=SIZE_EXPAND_FILL
		var crystals=int(result.get("crystals",1 if id>=12 else 0))
		if crystals>0:label(materials_line,"+%d crystals"%crystals,15)
		if result.get("flawless",false):
			var perfect=label(content,"FLAWLESS · No hazard hits",15);perfect.modulate=Color("#f5d78c");perfect.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		button(content,"Meet in collection ›",func(): popup.queue_free(); collection_feature=id; select("Pets"))
		popup.confirmed.connect(popup.queue_free); popup.canceled.connect(popup.queue_free); add_child(popup); popup.popup_centered(Vector2i(390,450))
	else:
		if result.get("correct",false):play_reward(false)
		select("Habitat")
		if result.get("correct",false) and result.get("dungeon",false):
			var summary=AcceptDialog.new();summary.title="EXPEDITION CLEARED";summary.ok_button_text="Continue adventure"
			var content=VBoxContainer.new();content.add_theme_constant_override("separation",12);summary.add_child(content)
			var portrait_art=TextureRect.new();portrait_art.texture=pixel_portrait("res://assets/pet_%d.png"%store.species());portrait_art.custom_minimum_size=Vector2(220,160);portrait_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait_art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;content.add_child(portrait_art)
			label(content,"%d floors cleared"%int(result.floors),25).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			if result.get("evidence",0)>0:label(content,"+%d research evidence"%int(result.evidence),19).modulate=Color("#b9ebc0")
			label(content,"+%d coins   ·   +%d XP"%[int(result.coins),int(result.xp)],19)
			label(content,"+%d crafting materials"%int(result.materials),17)
			if result.get("flawless",false):label(content,"FLAWLESS CLEAR",16).modulate=Color("#ffe3a0")
			var note=label(content,hunt_message,15);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			summary.confirmed.connect(summary.queue_free);summary.canceled.connect(summary.queue_free);add_child(summary);summary.popup_centered(Vector2i(385,430))
func room(name:String):
	if name!=current_room: notice.text=""
	for key in nav_buttons:
		nav_buttons[key].add_theme_stylebox_override("normal",menu_skin(Color("#365449"),Color("#9acdb6")) if key=="Home" else StyleBoxEmpty.new())
	section_scroll.scroll_vertical=0
	visual.show()
	stage_space.show()
	reward_row.hide()
	room_scroll.show()
	meter_panel.show()
	section_scroll.size_flags_vertical=SIZE_FILL
	section_scroll.custom_minimum_size.y=128 if name in ["Kitchen","Bedroom","Garden"] else 72
	notice.hide()
	section="Rooms"
	current_room=name
	refresh()
	reset_actions(4 if name in ["Kitchen","Bedroom"] else 3)
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
	var kind=family_name(i)
	if kind in ["Devil","Ghost","Mushroom"]: return "Mystic"
	if kind=="Robot": return "Alien"
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
func pets_tabs(parent:Node,current:String):
	var tabs=row(parent)
	for name in ["Family","Collection"]:
		var b=button(tabs,name+("  ✓" if name==current else ""),func(): select("Family" if name=="Family" else "Pets"))
		b.custom_minimum_size.y=43; b.add_theme_font_size_override("font_size",16)
		b.add_theme_stylebox_override("normal",menu_skin(Color("#7850ad") if name==current else Color("#27203e"),Color("#e4bdff") if name==current else Color("#5c4c75")))
func build_family():
	pets_tabs(actions,"Family")
	var slots:Array=store.family_slots()
	section_heading(actions,"Your companions","Mosky is your only companion.")
	family_grid=VBoxContainer.new(); family_grid.add_theme_constant_override("separation",8); actions.add_child(family_grid)
	for slot_value in slots:
		var slot:int=slot_value
		var p:Dictionary=store.companion_profile(slot)
		if p.is_empty():continue
		var active=slot==int(store.s.form)
		var id:int=store.original_species() if slot==-1 else slot
		var shell=panel(family_grid)
		var line=row(shell)
		var art=TextureRect.new(); art.texture=pixel_portrait("res://assets/premium_egg.png" if int(p.stage)==0 else "res://assets/pet_%d.png"%id); art.custom_minimum_size=Vector2(94,114);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;line.add_child(art)
		var copy=VBoxContainer.new();copy.size_flags_horizontal=SIZE_EXPAND_FILL;line.add_child(copy)
		label(copy,store.family_name_for(slot),20).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		label(copy,("Original" if slot==-1 else store.SPECIES[id])+" · Lv %d"%(1+int(p.companion_xp/50)),13).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		label(copy,("ACTIVE · " if active else "RESTING · ")+store.family_status(slot),13).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		for entry in [["Food",float(p.hunger)*20,Color("#ffba60")],["Energy",float(p.energy),Color("#63dfff")],["Bond",float(p.bond),Color("#bf8aff")]]:
			var meter=row(copy)
			var name=label(meter,entry[0],11);name.custom_minimum_size.x=48
			var bar=ProgressBar.new();bar.show_percentage=false;bar.value=entry[1];bar.custom_minimum_size.y=8;bar.size_flags_horizontal=SIZE_EXPAND_FILL
			bar.add_theme_stylebox_override("background",bar_skin(Color("#121a35"),Color("#65739c")));bar.add_theme_stylebox_override("fill",bar_skin(entry[2].darkened(.15),entry[2]));meter.add_child(bar)
		var controls=row(shell)
		var go=button(controls,"Care now" if active else "Switch & care",func():
			if active or store.action("form",slot):select("Home");refresh())
		go.disabled=not active and not store.action_block("form",slot).is_empty()
		go.custom_minimum_size.y=44;go.add_theme_font_size_override("font_size",15)
	button(actions,"Explore with Mosky ›",func():select("World"))
	swipe_children(actions)
func rename_family(slot:int):
	var popup=ConfirmationDialog.new();popup.title="Name your companion";popup.ok_button_text="Save name"
	var edit=LineEdit.new();edit.placeholder_text="Companion name";edit.text=str(store.companion_profile(slot).get("name",""));edit.max_length=24;edit.custom_minimum_size=Vector2(260,46);popup.add_child(edit)
	popup.confirmed.connect(func():store.rename_companion(slot,edit.text);select("Family");refresh();popup.queue_free())
	popup.canceled.connect(popup.queue_free);add_child(popup);popup.popup_centered(Vector2i(320,150))
func show_collection():
	reset_actions()
	collection_feature=0
	pets_tabs(actions,"Collection")
	section_heading(actions,"Pet roster","One companion. One identity. All adventures with Mosky.")
	collection_grid=GridContainer.new();collection_grid.columns=1;actions.add_child(collection_grid)
	var card=panel(collection_grid)
	var art=TextureRect.new();art.texture=pixel_portrait("res://assets/pet_0.png");art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;art.custom_minimum_size.y=220;art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;card.add_child(art)
	label(card,"Mosky",26).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label(card,"YOUR COMPANION · Lv %d"%store.companion_level(),14).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	button(card,"♥ Favorited" if store.favorite(0) else "♡ Favorite",func():store.toggle_favorite(0);show_collection())
	button(card,"Combat training · EVs ›",func():show_training())
	button(card,"Care for Mosky ›",func():select("Home"))
	swipe_children(actions)
func show_training():
	reset_actions()
	button(actions,"‹ Pet roster",func():show_collection())
	var profile:Dictionary=store.training_profile()
	section_heading(actions,"Combat training","Defeat creatures to earn stat-specific EVs, then invest them here.")
	var top=panel(actions)
	label(top,"Mosky · Lv %d · %s"%[profile.level,profile.nature_name],22)
	label(top,"Grass · "+str(profile.nature_trait),15)
	label(top,str(profile.nature_summary),16).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button(top,"Moves & loadout ›",func():show_move_training())
	var total:int=0
	for n in profile.ev:total+=int(n)
	label(top,"Allocated %d / 510 · IVs disabled"%total,16)
	var names:Array=["HP","Attack","Defense","Sp. Attack","Sp. Defense","Speed"]
	for i in range(6):
		var card=panel(actions)
		var h=row(card)
		var copy=VBoxContainer.new();copy.size_flags_horizontal=SIZE_EXPAND_FILL;h.add_child(copy)
		var stat_label=label(copy,"%s · %d"%[names[i],profile.stats[i]],18)
		if i==int(profile.nature_pair[0]):stat_label.modulate=Color("#a7e9af");stat_label.text+="  ↑10%"
		elif i==int(profile.nature_pair[1]):stat_label.modulate=Color("#ffac99");stat_label.text+="  ↓10%"
		label(copy,"EV %d/252 · Available %d"%[profile.ev[i],profile.bank[i]],14)
		var plus=button(h,"+1",func():store.allocate_ev(i,1);show_training())
		plus.disabled=int(profile.bank[i])==0 or int(profile.ev[i])>=252 or total>=510
		var batch=button(h,"+4",func():store.allocate_ev(i,4);show_training())
		batch.disabled=plus.disabled
	swipe_children(actions)
	section_scroll.scroll_vertical=0
func show_move_training():
	reset_actions()
	button(actions,"‹ Combat training",func():show_training())
	var profile:Dictionary=store.training_profile()
	var rules=preload("res://dungeon_rules.gd")
	section_heading(actions,"Move library","Moves unlock at their required level. Equip up to four before entering a dungeon.")
	for id in rules.MOVE_LIBRARY:
		var move:Dictionary=rules.MOVE_LIBRARY[id]
		if not move.type in profile.types:continue
		var card=panel(actions)
		label(card,str(move.name)+" · Lv "+str(move.learn_level),19)
		label(card,"%s · %s · %d tiles · Power %d · PP %d · Acc %.1f%%"%[move.category.capitalize(),move.pattern,move.reach,move.power,move.pp,rules.reference_accuracy(move)],14).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var unlocked:bool=int(profile.level)>=int(move.learn_level)
		if not unlocked:
			label(card,"Locked · level "+str(move.learn_level),15)
			continue
		var line=row(card)
		for slot in range(4):
			var b=button(line,"Slot %d"%(slot+1),func():store.equip_move(slot,id);show_move_training())
			if slot<profile.moves.size() and profile.moves[slot]==id:b.text="✓ %d"%(slot+1)
	swipe_children(actions)
	section_scroll.scroll_vertical=0
func launch_game(i:int):
	if not store.begin_arcade(i): notice.text=store.arcade_block(i); notice.show(); return
	get_tree().change_scene_to_file("res://main.tscn" if i==4 else "res://pet_arcade.tscn")
func refresh():
	if section=="Wallpaper": layout_wallpaper_preview()
	if is_instance_valid(wallpaper_cta) and store.now()-wallpaper_status_check>3.0:
		wallpaper_status_check=store.now()
		var plugin=store.wallpaper_plugin()
		wallpaper_active=plugin!=null and plugin.isActive()
		wallpaper_cta.text="Wallpaper ON" if wallpaper_active else "Wallpaper"
	store.advance(store.now())
	var s:Dictionary=store.s
	title_label.text=store.pet_name()+"  ·  Lv "+str(store.companion_level())
	identity_art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	identity_art.texture=pixel_portrait("res://assets/premium_egg.png" if s.stage==0 else "res://assets/pet_%d.png"%store.species())
	xp_bar.value=fposmod(float(s.companion_xp),50)*2
	info.text="%d coins  |  %d gems"%[s.coins,s.crystals]
	clock_label.text="Account Lv %d · "%store.level()+Time.get_time_string_from_system().substr(0,5)
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
		daily_cta.text="Claimed" if s.daily_day==store.date_key(store.now()) else "Gift"
		care_cta.text="Bonus!" if store.today_count(store.now())==4 and s.today_claim_day!=store.date_key(store.now()) else "Today %d/4"%store.today_count(store.now())
		wellness_cta.text="Treat!" if s.germs>0 else "Care"
		wellness_cta.add_theme_stylebox_override("normal",menu_skin(Color("#854455") if s.germs>0 else Color("#34244f"),Color("#ffc0cb") if s.germs>0 else Color("#765c9a")))
		growth_cta.text=store.STAGES[int(s.stage)]
		care_cta.add_theme_stylebox_override("normal",skin(Color("#8b5134") if store.care_ready() else Color("#51316d"),Color("#ffd48a") if store.care_ready() else Color("#dc9fed")))
	if not current_room.is_empty(): path="res://assets/"+str(ROOMS.get(current_room,"room_bedroom"))+".jpg"
	bg.texture=tex(path)
	update_room_scene()
	var pp="res://assets/pet_%d.png"%store.species()
	portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.texture=pixel_portrait(pp)
	portrait.modulate=Color("#9ba9c7") if store.asleep(store.now()) else Color.WHITE
	portrait.scale=Vector2.ONE*(0.64 if s.stage<2 else 0.85 if s.stage==2 else 1.0)
	portrait.visible=false
	sync_wearables()
	live_stage.set_room(str(ROOMS.get(current_room,"room_bedroom")))
	live_stage.set_pet(store.species(),int(s.stage))
	live_stage.set_night(night)
	live_stage.set_sleeping(store.asleep(store.now()))
	live_stage.set_mood(PixelArt.Parts.mood(float(s.happy),float(s.energy),float(s.hunger),int(s.germs)))
	pet_status.text="Tap to hatch Mosky" if s.stage==0 else room_hint()
	live_stage.set_room_lighting(int(s.theme))
	live_stage.set_installation(int(s.installation))
	live_stage.set_crop(float(s.garden_at),store.now())
	live_stage.dress(s.worn,int(s.equipped))
	if live_stage.incompatible_wearables>0: outfit_label.text="Shoes stay in your wardrobe for aquatic pets"
	position_hotspots()
	face.visible=false
	egg_visual.hide()
	egg_art.hide()
	face.text="– ᴗ –" if store.asleep(store.now()) else "• ︿ •" if s.germs>0 or s.hunger<=1 else "• ᴗ •"
	if rendered_stage!=int(s.stage):
		rendered_stage=int(s.stage)
		if section=="Home": select("Home")
	update_context()
func room_hint()->String:
	var s:Dictionary=store.s
	if store.asleep(store.now()) or s.trip_end>store.now(): return store.care_priority()+" • "+home_hint()
	match current_room:
		"Kitchen": return "Full • Come back when hungry" if s.hunger>=5 else "Choose a meal • Grain is free"
		"Bathroom": return "Clean & fresh" if s.hygiene>=100 and s.toilet>=100 else "Soap then rinse • Toilet when needed"
		"Garden": return "Plant a seed for 5 coins" if s.garden_at==0 else "Ready to harvest!" if store.garden_remaining(store.now())==0 else "Crop growing • "+time_text(store.garden_remaining(store.now()))
		"Bedroom": return "Rest restores energy • Themes change lighting"
		"Potion lab": return "Medicine treats illness • Craft with 3 materials"
		"Toy room": return "Play increases mood • Arcade earns coins"
	return store.care_priority()+" • "+home_hint()
func home_hint()->String:
	var s:Dictionary=store.s
	if s.trip_end>store.now(): return "World › Expeditions"
	if store.asleep(store.now()): return "Tap Wake"
	if s.germs>0: return "Care › Wellness"
	if s.hunger<5: return "Kitchen"
	if s.hygiene<100 or s.toilet<100: return "Bathroom"
	if s.waste>0: return "Tap Clean"
	if s.energy<30: return "Bedroom"
	return "Care quest %d/4"%mini(4,store.care_count())
func set_context(key:String,message:String,progress:float=-1.0):
	if context_labels.has(key) and is_instance_valid(context_labels[key]): context_labels[key].text=message
	if progress>=0 and context_bars.has(key) and is_instance_valid(context_bars[key]): context_bars[key].value=clampf(progress,0,100)
func update_context():
	if swipe_dirty:
		swipe_children(actions); swipe_dirty=false
	update_action_controls()
	var s:Dictionary=store.s
	var now:float=store.now()
	set_context("care_quest","%d / 4 different activities • %d chests earned"%[mini(4,store.care_count()),s.care_claims],mini(100,store.care_count()*25))
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
	var msg="Ready to explore • Fuel %d • Prefers %s"%[s.fuel,store.FIELDS[int(s.habitat)]]
	if s.stage<2: msg="Expeditions unlock at Kid stage. Grow your pet first."
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
		if key not in ["arcade","food"]: b.set_meta("hotspot_action",str(key))
	position_hotspots()
func position_hotspots():
	if not is_instance_valid(hotspot_layer): return
	var safe=Rect2(Vector2(8,8),visual.size-Vector2(16,16))
	if is_instance_valid(stage_space) and stage_space.size.y>100:
		safe=safe.intersection(Rect2(stage_space.global_position-visual.global_position+Vector2(8,8),stage_space.size-Vector2(16,16)))
	if safe.size.x<80 or safe.size.y<80: return
	if is_instance_valid(live_stage) and visual.visible:
		live_stage.frame_pet(safe)
		var hit:Rect2=live_stage.projected_pet.grow(12).intersection(safe)
		if hit.has_area(): pet_touch.position=hit.position; pet_touch.size=hit.size
		room_tag.position=Vector2(safe.position.x,safe.position.y+3)
		if is_instance_valid(pet_status):
			pet_status.position=Vector2(safe.position.x,safe.position.y+29)
			pet_status.visible=visual.visible
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
func find_button(node:Node,value:String)->Button:
	if node is Button and node.text==value: return node
	for child in node.get_children():
		var found=find_button(child,value)
		if found!=null: return found
	return null
func test_mouse_motion(at:Vector2,relative:Vector2,held:bool):
	var ev=InputEventMouseMotion.new()
	ev.position=at; ev.global_position=at; ev.relative=relative; ev.button_mask=MOUSE_BUTTON_MASK_LEFT if held else 0
	get_viewport().push_input(ev,true)
func test_mouse_button(at:Vector2,down:bool):
	var ev=InputEventMouseButton.new()
	ev.position=at; ev.global_position=at; ev.button_index=MOUSE_BUTTON_LEFT; ev.pressed=down; ev.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
	get_viewport().push_input(ev,true)
func test_drag(start:Vector2,delta:Vector2):
	test_mouse_motion(start,Vector2.ZERO,false); test_mouse_button(start,true)
	await get_tree().process_frame
	var previous=start
	for i in range(1,7):
		var next=start+delta*(float(i)/6)
		test_mouse_motion(next,next-previous,true); previous=next
		await get_tree().process_frame
	test_mouse_button(previous,false)
	await get_tree().process_frame
func test_touch():
	Input.emulate_touch_from_mouse=true
	assert(DisplayServer.is_touchscreen_available())
	store.s=store.defaults(); store.s.stage=4; store.s.auto_sleep=false; store.s.coins=1000
	make_ui(); refresh(); select("Pets")
	for i in range(5): await get_tree().process_frame
	var favorite_button=find_button(actions,"♡ Favorite")
	assert(favorite_button!=null)
	var initial_fav:int=store.s.favorites
	var start=favorite_button.get_global_rect().get_center()
	test_mouse_motion(start,Vector2.ZERO,false);test_mouse_button(start,true);await get_tree().process_frame;test_mouse_button(start,false)
	await get_tree().process_frame
	assert(store.s.favorites!=initial_fav,"Tap activates Mosky favorite")
	select("Home")
	for i in range(5):await get_tree().process_frame
	var before_room=current_room
	var tile=room_tiles.values()[0] as Button
	await test_drag(tile.get_global_rect().get_center(),Vector2(-165,0))
	assert(current_room==before_room,"Horizontal swipe must not activate a room")
	select("World")
	hunt_region=0;select("Habitat");open_active_field(0,false)
	for i in range(8):await get_tree().process_frame
	var field:Control
	for child in get_children():
		if child.get_script()==preload("res://dungeon_view.gd"):field=child
	assert(is_instance_valid(field),"production dungeon opened")
	assert(field.companion_id==store.species(),"active pet in dungeon")
	assert(field.area.size.x>100 and field.area.size.y>100)
	field.set_process(false)
	field.run.enemies.clear()
	var pickup:Vector2i
	for d in field.run.DIR:
		if field.run.loot.get(field.run.player+d,"")=="coin":pickup=field.run.player+d;break
	var screen_pos=field.camera.unproject_position(field.pos(pickup))*field.area.size/Vector2(field.viewport.size)
	assert(Rect2(Vector2.ZERO,field.area.size).has_point(screen_pos))
	var press=InputEventScreenTouch.new();press.index=0;press.pressed=true;press.position=screen_pos
	field.touch(press)
	assert(not field.path.is_empty(),"native touch maps to dungeon tile")
	field._process(.2)
	assert(field.run.coins==3 and not field.run.loot.has(pickup),"production pickup collected once")
	field.leave()
	await get_tree().process_frame
	assert(store.field_session.is_empty(),"cancel clears session")
	print("FOREVER_PET_TOUCH_PASS vertical horizontal tap no-accidental-action dungeon-coordinate pickup")
	get_tree().quit()
func test_home():
	store.legacy_catalog=true # Explicit archived-rule regression fixture; production remains single-pet.
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
	store.s=saved.duplicate(true)
	# Test the actual store settlement, including replay and invalid timing.
	store.s.stage=2;store.s.energy=100;store.s.hunger=5;store.s.germs=0
	store.s.collection=1;store.s.research_target[0]=1
	var field_case:Dictionary=store.field_begin(0,false)
	assert(not field_case.is_empty(),"field starts for common trail")
	var field_wallet:int=store.s.coins
	var invalid:Dictionary=store.field_finish(true,int(field_case.required),.1,0)
	assert(not invalid.get("correct",false) and store.s.coins==field_wallet,"impossible timing cannot pay")
	field_case=store.field_begin(0,false)
	assert(not field_case.is_empty())
	var clean:Dictionary=store.field_finish(true,int(field_case.required),8.0,0)
	assert(clean.get("correct",false) and store.s.coins==field_wallet+9,"clean trail earns bonus")
	assert(not store.field_finish(true,int(field_case.required),8.0,0).get("ok",false),"no repeated settlement")
	store.s.research_rank_xp[2]=90;store.s.research_target[2]=24
	store.s.research_evidence[24]=Research.needed(24)
	field_case=store.field_begin(2,false)
	assert(not field_case.is_empty() and field_case.finale)
	var before_crystals:int=store.s.crystals
	var before_materials:int=store.s.materials
	var discovery:Dictionary=store.field_finish(true,int(field_case.required),20.0,0)
	assert(discovery.get("unlocked",false) and discovery.coins==100 and discovery.xp==50)
	assert(store.s.crystals==before_crystals+2 and store.s.materials==before_materials+4)
	assert((int(store.s.collection)&(1<<24))!=0)
	store.legacy_catalog=false;store.s=saved;store.enforce_mosky()
	assert(store.ROSTER==["Mosky"] and store.species()==0 and not store.action("form",1))
	make_ui(); refresh()
	live_stage.set_pet(0,0); assert(live_stage.egg_body!=null and live_stage.bare_bounds.has_volume())
	live_stage.set_pet(store.species(),int(store.s.stage))
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
	assert(live_stage.stretch_shrink==1 and live_stage.view.msaa_3d==Viewport.MSAA_2X)
	assert(is_instance_valid(live_stage.pixel_pet) and live_stage.pixel_pet.visible)
	assert(live_stage.pixel_pet.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST)
	assert(live_stage.pixel_pet.texture.get_width()<=64 and live_stage.pixel_pet.texture.get_height()<=64)
	for child in live_stage.awake_body.find_children("*","MeshInstance3D",true,false):
		assert((child.layers & live_stage.camera.cull_mask)==0,"3D pet must not be visible in the room camera")
	assert(is_finite(live_stage.sole_offset) and live_stage.grounded_error()<0.001)
	for species in range(store.ROSTER.size()):
		live_stage.set_pet(species,4)
		assert(live_stage.avatar.get_child_count()>0 and is_finite(live_stage.sole_offset))
		assert(is_instance_valid(live_stage.sleep_face))
		assert(is_instance_valid(live_stage.pixel_pet) and live_stage.pixel_pet.texture!=null)
		live_stage.set_sleeping(true); assert(live_stage.sleep_face.visible)
		assert(live_stage.pixel_pet.texture==live_stage.pixel_sleep)
		if species==0: assert(not live_stage.awake_body.visible)
		else:
			assert(live_stage.awake_eyes.size()>0)
			for eye in live_stage.awake_eyes: assert(not eye.visible)
		live_stage.set_sleeping(false); assert(not live_stage.sleep_face.visible)
		assert(live_stage.pixel_pet.texture==live_stage.pixel_idle)
		if species==0: assert(live_stage.awake_body.visible)
		else:
			for eye in live_stage.awake_eyes: assert(eye.visible)
		assert(live_stage.grounded_error()<0.001)
	live_stage.set_pet(0,4)
	for tab in ["Care","Rooms","Arcade","Shop","Journal","World","Cell","More","Home"]: select(tab)
	assert(nav_buttons.has("Wallpaper") and wallpaper_cta.is_visible_in_tree())
	nav_buttons["Wallpaper"].pressed.emit(); assert(section=="Wallpaper" and find_button(actions,"Set live wallpaper ›")!=null)
	select("Home"); wallpaper_cta.pressed.emit(); assert(section=="Wallpaper")
	select("Home")
	assert(nav_buttons.size()==6 and room_tiles.size()==6 and action_grid.get_child_count()==5)
	assert(nav_buttons.has("World") and not nav_buttons.has("Life"))
	nav_buttons["World"].pressed.emit(); assert(section=="World")
	select("Home"); wellness_cta.pressed.emit(); assert(section=="Care")
	select("Home"); growth_cta.pressed.emit(); assert(section=="Journal")
	select("Home"); care_cta.pressed.emit(); assert(section=="Today" and find_button(actions,"Complete today's activities")!=null)
	select("Home")
	select("Family"); assert(family_grid.get_child_count()==store.family_slots().size())
	select("Pets"); assert(collection_grid.get_child_count()==1)
	assert(not store.toggle_favorite(3)); assert(store.toggle_favorite(0)); show_collection(); assert(collection_grid.get_child_count()==1)
	collection_filter="All"; select("Home")
	for name in ROOMS:
		room(name)
		assert(bg.texture!=null and live_stage.room_node!=null and hotspot_layer.get_child_count()>=2,"room art/hotspots missing: "+name)
		assert(room_scroll.visible and meter_panel.visible and visual.visible)
		assert(action_grid.get_child_count()>=3)
	room("Garden")
	live_stage.set_crop(0,store.now()); assert(live_stage.crop_stage==0 and live_stage.garden_crop.get_child_count()==0)
	live_stage.set_crop(store.now()+1200,store.now()); assert(live_stage.crop_stage==1 and live_stage.garden_crop.get_child_count()>0)
	live_stage.set_crop(store.now()-1,store.now()); assert(live_stage.crop_stage==4 and live_stage.garden_crop.get_child_count()>60)
	select("Home")
	store.s.interaction_at=0.0
	var before_bond:int=store.s.bond
	var cuddle:Button=action_grid.get_child(0)
	cuddle.pressed.emit()
	assert(store.s.bond==before_bond+1 and live_stage.fx_nodes.size()==5)
	live_stage.touch_bounce=0.0
	live_stage.react("food",false)
	assert(live_stage.fx_nodes.size()==5 and live_stage.reaction_kind=="food" and is_instance_valid(live_stage.reaction_prop))
	live_stage.react("play",false); assert(is_instance_valid(live_stage.reaction_prop) and live_stage.reaction_length>1.5)
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
		if live_stage.active_stage>0 and live_stage.camera_safe.has_area():
			var r:Rect2=live_stage.projected_pet
			var s:Rect2=live_stage.camera_safe.grow(4)
			print("PET_FRAME ",path," pet=",r," safe=",s," enclosed=",s.encloses(r))
	var image=get_viewport().get_texture().get_image()
	assert(image.save_png(path)==OK)
func capture_home():
	store.s=store.defaults(); store.s.auto_sleep=false
	store.s.stage=4; store.s.coins=250; store.s.name="Mosky"
	make_ui(); refresh()
	await capture_frame("/tmp/forever-home.png")
	store.s.sleep_until=store.now()+60; refresh()
	await capture_frame("/tmp/forever-sleep-mosskit.png")
	store.s.sleep_until=0; refresh()
	for species in range(store.ROSTER.size()):
		store.s.form=-1
		if species>=24: store.s.collection=int(store.s.collection)|(1<<species); store.s.form=species
		else: store.s.variant=int(species/12); store.s.field=int((species%12)/4); store.s.body=species%4
		store.s.name="Mosky"
		refresh()
		await capture_frame("/tmp/forever-species-%02d.png"%species)
		if species in [3,5,24,25]:
			store.s.sleep_until=store.now()+60; refresh()
			await capture_frame("/tmp/forever-sleep-%02d.png"%species)
			store.s.sleep_until=0; refresh()
	store.s.form=-1; store.s.variant=0; store.s.field=0; store.s.body=0; store.s.name="Mosky"; refresh()
	for name in ROOMS:
		select("Rooms")
		room(name)
		await capture_frame("/tmp/forever-"+ROOMS[name]+".png")
	select("Care"); await capture_frame("/tmp/forever-care.png")
	select("Today"); await capture_frame("/tmp/forever-today.png")
	select("World"); await capture_frame("/tmp/forever-world.png")
	for r in range(3):
		hunt_region=r; select("Habitat"); await capture_frame("/tmp/forever-habitat-%d.png"%r)
		open_active_field(r,false,true); await capture_frame("/tmp/forever-wild-%d.png"%r)
		var wild_view:Control
		for child in get_children():
			if child.get_script()==preload("res://wild_field.gd"):wild_view=child
		assert(is_instance_valid(wild_view),"capture requires actual wild field")
		wild_view.run.move_to(wild_view.run.signal_position())
		assert(wild_view.run.scan(),"capture requires a working scan")
		await capture_frame("/tmp/forever-wild-scan-%d.png"%r)
		assert(wild_view.compass_arrow.visible and wild_view.trace.visible,"scan visuals must render")
		store.field_cancel()
		for child in get_children():
			if child.get_script()==preload("res://wild_field.gd"):child.queue_free()
		live_stage.show()
		await get_tree().process_frame
	for r in range(3):
		hunt_region=r;select("Habitat");open_active_field(r,false)
		var dungeon:Control
		for child in get_children():
			if child.get_script()==preload("res://dungeon_view.gd"):dungeon=child
		assert(is_instance_valid(dungeon))
		await capture_frame("/tmp/forever-dungeon-%d.png"%r)
		store.field_cancel();dungeon.hide();dungeon.queue_free();live_stage.show()
		await get_tree().process_frame
	hunt_region=0
	var target:int=store.research_target(0); store.s.research_evidence[target]=Research.needed(target)
	select("Habitat"); await capture_frame("/tmp/forever-encounter.png")
	for r in range(3):
		store.s.research_rank_xp[r]=30; hunt_region=r; select("Habitat"); open_sanctuary(r,0)
		await capture_frame("/tmp/forever-sanctuary-%d.png"%r)
	select("Journal"); await capture_frame("/tmp/forever-growth.png")
	select("Pets")
	await capture_frame("/tmp/forever-collection.png")
	select("Family"); await capture_frame("/tmp/forever-family.png")
	select("Pets")
	collection_filter="All"
	select("Shop")
	await capture_frame("/tmp/forever-shop.png")
	select("Wallpaper"); await capture_frame("/tmp/forever-wallpaper.png")
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
