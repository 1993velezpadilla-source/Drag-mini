extends Control
const PixelArt=preload("res://pixel_pet_art.gd")
const Rules=preload("res://dungeon_rules.gd")
const Data=preload("res://research_data.gd")
signal ended(success:bool,completed:int,elapsed:float)
signal canceled
var run=Rules.new()
var viewport:SubViewport
var camera:Camera3D
var world:Node3D
var geometry:Node3D
var actors:Node3D
var pet:Node3D
var area:Control
var hp_bar:ProgressBar
var hp_text:Label
var relic_text:Label
var map_zoom:Button
var map_expanded=false
var hud_base:VBoxContainer
var title_text:Label
var status_text:Label
var stats:Label
var map:Control
var attack_button:Button
var power_button:Button
var heal_button:Button
var stairs_button:Button
var companion_id=0
var region=0
var elapsed=0.0
var tick=0.0
var path:Array[Vector2i]=[]
var notified=false
var palette:Array=[]
var floor_surface_signature=""
var meshes:Dictionary={}
var mats:Dictionary={}
var active_floor=0
var facing=Vector2i.DOWN
var aim_button:Button
var special_button:Button
var move_buttons:Array[Button]=[]
var actor_nodes:Dictionary={}
var enemy_shadow_material:StandardMaterial3D
var enemy_shadow_mesh:QuadMesh
const COMBAT_FX_STYLES={"basic_strike":["slash","#fff3c9","#e8a25c",0.26],"briar_arc":["leap","#b4e579","#4c8d48",0.42],"spore_cloud":["cloud","#f4d68a","#879b49",0.72],"horn_ram":["leap","#f0d2a0","#a77c44",0.35],"leaf_dart":["dart","#b7ed7b","#438b45",0.42],"tusk_sweep":["slash","#f9e0ba","#aa744e",0.35],"vine_snap":["whip","#bfe874","#3f8e4b",0.54],"rolling_moss":["roll","#bdcb82","#536b45",0.5],"feather_fan":["fan","#fff1c3","#b5a773",0.48],"antler_arc":["slash","#e4c89e","#a58454",0.4],"timber_shock":["wave","#ecba69","#8d6842",0.62],"royal_spores":["cloud","#ffdca5","#ca79a3",0.78],"reef_bite":["slash","#d2f5ef","#5ba8b2",0.3],"jelly_pulse":["wave","#b8f8ff","#9c7ce0",0.48],"shell_impact":["wave","#d1e8a4","#739a77",0.44],"bubble_burst":["bubble","#c7fbff","#50b7dc",0.64],"electric_lash":["lightning","#e8fbff","#4b9af8",0.42],"double_pincer":["slash","#ffe2a5","#ef826f",0.36],"tentacle_snare":["whip","#ffd3ea","#bd648c",0.6],"fin_slice":["dart","#dbf4f5","#6ca9db",0.43],"spiral_current":["spiral","#d8fff0","#56b6b8",0.52],"abyss_grasp":["whip","#f9b9ee","#8458b3",0.62],"tidal_jaws":["wave","#e9f7ff","#4287bb",0.55],"star_kick":["slash","#f5e8ff","#a29cf0",0.3],"lunar_dust":["cloud","#eee8ff","#b7a2ed",0.64],"prism_shatter":["shards","#effaff","#7cb9ff",0.55],"nova_bolt":["flame","#fff2a0","#ff784a",0.62],"orbit_lash":["spiral","#dfd0ff","#9663ee",0.52],"comet_drop":["leap","#fff1bb","#e1a3ff",0.48],"gravity_web":["web","#e4d7ff","#9f71e8",0.64],"sonic_cone":["fan","#f9d7ff","#a66be6",0.48],"moon_claw":["slash","#eee5ff","#a58bdc",0.38],"meteor_fist":["meteor","#fff0ba","#ff8d55",0.62],"celestial_verdict":["beam","#fff6d0","#d99bff",0.66]}
const FX_PARTICLE_CAP=144
const FX_WARNING_CAP=80
var combat_particles:Array[Sprite3D]=[]
var combat_warnings:Array[MeshInstance3D]=[]
var combat_bursts:Array[Dictionary]=[]
var combat_textures:Dictionary={}
var fx_arc_mesh:ImmediateMesh
var fx_arc_material:StandardMaterial3D
var fx_audio:Array[AudioStreamPlayer3D]=[]
var fx_audio_cache:Dictionary={}
var fx_audio_counter:Dictionary={}
var fx_audio_cursor:int=0
var fx_arc_segments:int=0
var player_cast_duration:float=.28
var player_cast_mode:String="contact"
var player_impact_delay:float=0.0
var fx_reactions:Array[Dictionary]=[]
var fx_ground_shake:float=0.0
var fx_geometry_count:int=0
const FX_FRAME_COUNT=12
const FX_FRAME_SIZE=48
var combat_fx_root:Node3D
var combat_warn_mat:StandardMaterial3D
var enemy_event_turn:int=-1
var enemy_event_floor:int=-1
var feedback:Label
var feedback_time=0.0
var previous_event=0
var actor_created=0
var previous_attack=0
var attack_time=0.0
var attack_direction=Vector3.ZERO
var attack_fx:MeshInstance3D
var destination_fx:MeshInstance3D
var hp_previous=0
var hit_time=0.0
var pet_pose:Node3D
var floor_ornaments:Array[Vector3]=[]
var wall_decorations=0
var floor_banner:Label
var banner_time=0.0
var floor_label:Label
var last_floor_seen=0
var terrain_texture:ImageTexture
var terrain_normal:ImageTexture
var terrain_mats:Dictionary={}
var rock_modules=0
var landmark_count=0
var detail_count=0
var span_count=0
var corner_count=0
var terrace_count=0
var exterior_surface:MeshInstance3D
var exterior_vertex_count=0
var landscape_ridge_weights:Dictionary={}
var landscape_links:Array[Vector4i]=[]
const LANDSCAPE_LINK_CAP=32
var exterior_max_height=0.0
var exterior_groups:Array[Vector2i]=[]
var exterior_vistas:Array[Vector2i]=[]
var habitat_tall:Array[Vector2i]=[]
var habitat_large:Array[Vector2i]=[]
var vista_large:Array[Vector2i]=[]
var scenic_bounds:Array[AABB]=[]
var vista_focus_points:Array[Vector3]=[]
var habitat_variant_counts:Array[int]=[0,0,0]
var astral_cloud_bounds:Array[AABB]=[]
const ASTRAL_CLOUD_CAP=24
const DUNGEON_CAMERA_OFFSET=Vector3(0,7.6,11.3)
const DUNGEON_CAMERA_WIDTH=10.4
var habitat_low:Array[Vector2i]=[]
var habitat_ground_candidates:Array[Vector2i]=[]
var exterior_static_batches=0
var landmark_cells:Array[Vector2i]=[]
var exterior_distances:Dictionary={}
var exterior_life:Array[MultiMeshInstance3D]=[]
var exterior_life_parts:Array=[]
var exterior_life_centers:Array[Vector3]=[]
var exterior_clock=0.0
var floor_surface:MeshInstance3D
var threshold_count=0
var threshold_cells:Dictionary={}
var room_lights:Array[OmniLight3D]=[]
var floor_detail_count=0
var floor_detail_bounds:Dictionary={}
var terrace_cells:Dictionary={}
var reward_fx:Node3D
var reward_age=0.0
var reward_pool:Array[MeshInstance3D]=[]
var scene_cache:Dictionary={}
var rock_mesh_cache:Dictionary={}
var floor_build_usec=0
# Living-world FX are bounded, batched, independent of gameplay RNG.
const AMBIENT_COUNT=24
const MOTE_COUNT=12
const TRAIL_COUNT=16
var ambient_batches:Array[MultiMeshInstance3D]=[]
var ambient_origins:Array[Vector3]=[]
var ambient_ages:PackedFloat32Array=[]
var ambient_rng=RandomNumberGenerator.new()
var ambient_clock=0.0
var trail_batch:MultiMeshInstance3D
var trail_origins:Array[Vector3]=[]
var trail_ages:PackedFloat32Array=[]
var trail_angles:PackedFloat32Array=[]
var trail_cursor=0
var trail_emitted=0
var caustic_overlay:MeshInstance3D
var forest_light_overlay:MeshInstance3D
var astral_sigils:MultiMeshInstance3D
var astral_sigil_cells:Array[Vector2i]=[]
var biome_light_materials:Array[ShaderMaterial]=[]
var exterior_motion_materials:Dictionary={}
var exterior_motion_batches=0
func setup(r:int,id:int,step:int,finale:bool,patrol:bool,seed_id:int,companion:int,training:Dictionary={}):
	region=r;companion_id=0
	run.setup(r,id,step,finale,patrol,seed_id,0)
	if not training.is_empty():run.configure_training(training)
	hp_previous=run.hp
	palette=[ [Color("#37574b"),Color("#58775a"),Color("#17392f"),Color("#f4c77b")], [Color("#244c64"),Color("#39748a"),Color("#123449"),Color("#7ce8e4")], [Color("#414264"),Color("#62678b"),Color("#282c50"),Color("#dbb8ff")] ][r]
	build_terrain_textures()
	build_ui()
	build_floor()
	update_hud()
func style(bg:Color,border:Color,radius:int=14)->StyleBoxFlat:
	var s=StyleBoxFlat.new();s.bg_color=bg;s.border_color=border;s.set_border_width_all(2);s.set_corner_radius_all(radius)
	s.content_margin_left=10;s.content_margin_right=10;s.content_margin_top=7;s.content_margin_bottom=7
	return s
func label(parent:Node,value:String,size_value:int,color:Color=Color.WHITE)->Label:
	var l=Label.new();l.text=value;l.add_theme_font_size_override("font_size",size_value);l.modulate=color;parent.add_child(l);return l
func action_icon(kind:String)->Texture2D:
	var symbol=""
	match kind:
		"Strike":symbol='<path d="M5 4L20 19M4 20L19 5M2 7L7 2M17 22L22 17M2 17L7 22M17 2L22 7" stroke="#ffe7a9" stroke-width="3" stroke-linecap="round"/>'
		"Skill":symbol='<path d="M13 1L4 14H11L9 23L21 9H13Z" fill="#ead2ff" stroke="#b995ff"/>'
		"Coin":symbol='<circle cx="12" cy="12" r="10" fill="#e9a43c" stroke="#ffe7a1" stroke-width="2"/><circle cx="12" cy="12" r="6" fill="none" stroke="#b87821" stroke-width="1.5"/><path d="M15 8H10L8 11L14 13L15 16H9" fill="none" stroke="#fff0b0" stroke-width="1.6"/>'
		"Relic":symbol='<path d="M12 2L21 8L18 19L12 23L5 19L3 8Z" fill="#a46af1" stroke="#f1caff" stroke-width="1.4"/><path d="M12 2L9 9L12 23L16 9Z" fill="#dab7ff"/>'
		"Rooms":symbol='<path d="M4 21V11A8 8 0 0 1 20 11V21H16V11A4 4 0 0 0 8 11V21Z" fill="#c4b08b" stroke="#fff0c6"/>'
		"Forest":symbol='<path d="M12 21Q12 8 21 3Q24 15 12 16M11 15Q2 15 2 5Q13 6 11 15" fill="#9acc76" stroke="#c9ec9d" stroke-width="1.2"/>'
		"Reef":symbol='<path d="M12 22V5M12 15L5 10V5M12 11L19 6V2M12 18L21 14" fill="none" stroke="#ff9b9b" stroke-width="3" stroke-linecap="round"/>'
		"Star":symbol='<path d="M12 1L15 9L23 12L15 15L12 23L9 15L1 12L9 9Z" fill="#ffe3a0" stroke="#fff6d2"/>'
		"Berry":symbol='<circle cx="8" cy="14" r="6" fill="#f66d79"/><circle cx="16" cy="15" r="6" fill="#d83a61"/><path d="M12 10Q6 0 18 2Q19 8 12 10Z" fill="#a1df74"/>'
	var image=Image.new()
	image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24">'+symbol+'</svg>')
	return ImageTexture.create_from_image(image)
func hud_icon(parent:Node,kind:String,side:int=18)->TextureRect:
	var item=TextureRect.new();item.texture=action_icon(kind);item.custom_minimum_size=Vector2(side,side)
	item.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;item.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.mouse_filter=MOUSE_FILTER_IGNORE;parent.add_child(item);return item
func button(parent:Node,value:String,action:Callable,accent:bool=false)->Button:
	var b=Button.new();b.text=value;b.custom_minimum_size.y=62;b.size_flags_horizontal=SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size",17)
	var action_color=Color("#28744e") if value=="Strike" else Color("#663d9a") if value=="Skill" else Color("#213d50") if value=="Berry" else Color("#183249")
	var frame=style(action_color,Color("#d6b877"),18);frame.shadow_color=Color("#090f18bb");frame.shadow_size=4;frame.shadow_offset=Vector2(0,3)
	frame.border_width_bottom=3
	b.add_theme_stylebox_override("normal",frame)
	b.add_theme_stylebox_override("hover",style(action_color.lightened(.14),Color("#ffe4a0"),18))
	if value in ["Strike","Skill","Berry"]:
		b.icon=action_icon(value);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",27)
	b.add_theme_stylebox_override("pressed",style(Color("#496b81"),Color("#f6e2a6")))
	b.add_theme_stylebox_override("disabled",style(Color("#202b36"),Color("#34404e")))
	b.add_theme_color_override("font_disabled_color",Color("#8393a3"))
	b.pressed.connect(action);parent.add_child(b);return b
func build_ui():
	var base=VBoxContainer.new();hud_base=base;add_child(base);base.set_anchors_and_offsets_preset(PRESET_FULL_RECT);base.add_theme_constant_override("separation",0)
	var header=PanelContainer.new();header.add_theme_stylebox_override("panel",style(Color("#102739"),Color("#e2c081"),20));base.add_child(header)
	var h=HBoxContainer.new();header.add_child(h)
	var back=button(h,"‹",leave);back.tooltip_text="Leave expedition";back.size_flags_horizontal=SIZE_SHRINK_BEGIN;back.custom_minimum_size.x=45;back.add_theme_font_size_override("font_size",28)
	var portrait=TextureRect.new();portrait.custom_minimum_size=Vector2(56,64);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var portrait_path="res://assets/pet_%d.png"%companion_id
	portrait.texture=PixelArt.portrait(portrait_path);portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	h.add_child(portrait)
	var info=VBoxContainer.new();info.size_flags_horizontal=SIZE_EXPAND_FILL;h.add_child(info)
	var heading=HBoxContainer.new();heading.add_theme_constant_override("separation",5);info.add_child(heading)
	hud_icon(heading,["Forest","Reef","Star"][region],22)
	title_text=label(heading,"",20,Color("#ffe9bd"));title_text.size_flags_horizontal=SIZE_EXPAND_FILL;title_text.clip_text=true
	hp_bar=ProgressBar.new();hp_bar.max_value=run.max_hp;hp_bar.custom_minimum_size.y=25;hp_bar.show_percentage=false;info.add_child(hp_bar)
	var life_fill=style(Color("#36b77e"),Color("#a5f5bf"),12);life_fill.set_border_width_all(1)
	hp_bar.add_theme_stylebox_override("fill",life_fill)
	hp_bar.add_theme_stylebox_override("background",style(Color("#0b1825"),Color("#638d86"),12))
	hp_text=label(hp_bar,"",16,Color.WHITE);hp_text.set_anchors_and_offsets_preset(PRESET_FULL_RECT);hp_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hp_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;hp_text.mouse_filter=MOUSE_FILTER_IGNORE
	hp_text.add_theme_color_override("font_outline_color",Color("#143d30"));hp_text.add_theme_constant_override("outline_size",3)
	var resources=HBoxContainer.new();resources.add_theme_constant_override("separation",5);info.add_child(resources)
	hud_icon(resources,"Coin",17);stats=label(resources,"",14,Color("#f6e3bc"))
	hud_icon(resources,"Relic",17);relic_text=label(resources,"",14,Color("#f1dcff"))
	hud_icon(resources,"Rooms",17);floor_label=label(resources,"",14,Color("#cce9ec"))
	area=Control.new();area.size_flags_vertical=SIZE_EXPAND_FILL;area.clip_contents=true;base.add_child(area)
	var holder=SubViewportContainer.new();holder.stretch=true;holder.stretch_shrink=1;holder.mouse_filter=MOUSE_FILTER_IGNORE;area.add_child(holder);holder.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	viewport=SubViewport.new();viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;holder.add_child(viewport)
	world=Node3D.new();viewport.add_child(world)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=palette[2].darkened(.55);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=[Color("#c7d4bc"),Color("#a0cbdc"),Color("#b4afd9")][region];env.environment.ambient_light_energy=[.29,.36,.32][region];world.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-35,0);sun.light_color=[Color("#fff0bd"),Color("#a6e5ff"),Color("#dccbff")][region];sun.light_energy=[1.02,.90,.95][region];sun.shadow_enabled=true;world.add_child(sun)
	var fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-35,145,0);fill.light_color=palette[3];fill.light_energy=.23;fill.shadow_enabled=false;world.add_child(fill)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.keep_aspect=Camera3D.KEEP_WIDTH;camera.size=DUNGEON_CAMERA_WIDTH;world.add_child(camera);camera.current=true
	var input=Control.new();area.add_child(input);input.set_anchors_and_offsets_preset(PRESET_FULL_RECT);input.mouse_filter=MOUSE_FILTER_STOP;input.gui_input.connect(touch)
	map=Control.new();map.mouse_filter=MOUSE_FILTER_IGNORE;area.add_child(map);map.position=Vector2(10,10);map.size=Vector2(146,112);map.draw.connect(draw_map)
	map_zoom=Button.new();map_zoom.text="+";map_zoom.tooltip_text="Expand explored map";map_zoom.custom_minimum_size=Vector2(32,32);map_zoom.size=Vector2(32,32)
	map_zoom.add_theme_font_size_override("font_size",22);map_zoom.add_theme_stylebox_override("normal",style(Color("#142d40"),Color("#e2c081"),10))
	map_zoom.add_theme_stylebox_override("pressed",style(Color("#365364"),Color("#fff0ba"),10))
	area.add_child(map_zoom);map_zoom.position=map.position+Vector2(map.size.x-37,5);map_zoom.pressed.connect(toggle_map)
	feedback=Label.new();feedback.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;feedback.add_theme_font_size_override("font_size",24);feedback.add_theme_color_override("font_outline_color",Color("#142535"));feedback.add_theme_constant_override("outline_size",7);feedback.mouse_filter=MOUSE_FILTER_IGNORE;area.add_child(feedback);feedback.hide()
	floor_banner=Label.new();floor_banner.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;floor_banner.add_theme_font_size_override("font_size",25);floor_banner.add_theme_color_override("font_outline_color",Color("#142535"));floor_banner.add_theme_constant_override("outline_size",8);floor_banner.mouse_filter=MOUSE_FILTER_IGNORE;area.add_child(floor_banner);floor_banner.hide()
	var footer=PanelContainer.new();footer.add_theme_stylebox_override("panel",style(Color("#102739"),Color("#e2c081"),20));base.add_child(footer)
	var v=VBoxContainer.new();v.add_theme_constant_override("separation",6);footer.add_child(v)
	status_text=label(v,"",16,Color("#ffe1a4"));status_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status_text.custom_minimum_size.y=22;status_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var a=HBoxContainer.new();a.add_theme_constant_override("separation",8);v.add_child(a)
	attack_button=button(a,"Strike",func():path.clear();run.attack(false,facing);sync(),true)
	power_button=button(a,"Skill",func():path.clear();run.attack(true,facing);sync())
	heal_button=button(a,"Berry",func():path.clear();run.heal();sync())
	var tactical=HBoxContainer.new();tactical.add_theme_constant_override("separation",8);v.add_child(tactical)
	aim_button=button(tactical,"Aim ↓",func():rotate_combat_aim())
	special_button=button(tactical,"Leaf Dart",func():path.clear();run.attack(true,facing,1);sync())
	if not run.equipped_moves.is_empty():
		power_button.hide();special_button.hide()
		var skills=GridContainer.new();skills.columns=2;v.add_child(skills)
		for id in run.equipped_moves:
			var b=button(skills,str(Rules.MOVE_LIBRARY[id].name),func():path.clear();run.cast_move(id,facing);sync())
			b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			move_buttons.append(b)
	stairs_button=button(v,"Descend",func():path.clear();run.descend();sync(),true)
func leave():
	if notified:return
	notified=true
	call_deferred("emit_cancel")
func emit_cancel():
	canceled.emit()
func pos(p:Vector2i)->Vector3:
	return Vector3(p.x*1.4,0,p.y*1.4)
func mat(c:Color)->StandardMaterial3D:
	if not mats.has(c):
		var m=StandardMaterial3D.new();m.albedo_color=c;m.roughness=.8;mats[c]=m
	return mats[c]
func build_terrain_textures():
	# Periodic hand-laid paving: irregular joints and regional surface accents.
	var size_px=128
	var img=Image.create(size_px,size_px,false,Image.FORMAT_RGBA8)
	var normals=Image.create(size_px,size_px,false,Image.FORMAT_RGBA8)
	var noise=FastNoiseLite.new();noise.seed=146+region*97;noise.frequency=.045;noise.fractal_octaves=3
	var heights:PackedFloat32Array=[];heights.resize(size_px*size_px)
	for y in range(size_px):
		for x in range(size_px):
			var u=float(x)/size_px;var w=float(y)/size_px
			var h0=lerpf(noise.get_noise_2d(x,y),noise.get_noise_2d(x-size_px,y),u)
			var h1=lerpf(noise.get_noise_2d(x,y-size_px),noise.get_noise_2d(x-size_px,y-size_px),u)
			var h=lerpf(h0,h1,w)
			var color:Color
			var relief=0.0
			if region==0:
				# Mossy woodland soil: broad irregular patches, flecks of leaf litter, no brick grid.
				var patch=smoothstep(-.52,.52,h)
				var fine=float(posmod(x*73+y*137+x*y*19,101))/100.0
				var grain=.5+.5*sin(u*TAU*19.0+sin(w*TAU*13.0)*2.0)
				color=Color(.65,.59,.42).lerp(Color(.73,.77,.52),patch)
				color=color.lerp(Color(.58,.65,.39),smoothstep(.26,.55,h)*.22)
				color=color.darkened((grain*.035+fine*.045))
				relief=h*.048+grain*.006+fine*.005
			elif region==1:
				# Seabed sandstone: crossing ripples and light caustics, no masonry.
				var ripple=sin(w*TAU*8.0+sin(u*TAU*2.0)*1.45+sin((u+w)*TAU)*1.2)
				var secondary=sin((u-w)*TAU*5.0+sin(w*TAU*2.0)*1.4)
				var fine=float(posmod(x*103+y*59+x*y*17,113))/112.0
				var ridge=smoothstep(.24,.95,ripple)*.75+smoothstep(.64,.99,secondary)*.25
				# Sandy beds use warm mineral grains and cool troughs; caustics
				# remain in the separate animated lighting overlay.
				color=Color(.50,.65,.69).lerp(Color(.87,.92,.78),clampf(.50+h*.72+ridge*.28,0.0,1.0))
				color=color.darkened(fine*.055)
				relief=h*.055+ridge*.048+fine*.004
			else:
				# Astral ruin: broken rectangular slabs and restrained brass tracery.
				var py=w*2.0+sin(u*TAU)*.045
				var px=u*2.0+floorf(py)*.5+sin(w*TAU*2.0)*.04
				var edge=minf(minf(fposmod(px,1.0),1.0-fposmod(px,1.0)),minf(fposmod(py,1.0),1.0-fposmod(py,1.0)))
				var stone=smoothstep(.012,.045,edge)
				var shade=.71+.13*sin(floorf(px)*2.1+floorf(py)*1.7)+h*.23
				color=Color(.28,.26,.38).lerp(Color(shade,shade,shade),stone)
				var line=1.0-smoothstep(.008,.022,absf(edge-.10))
				color=color.lerp(Color(.82,.65,.37),line*.19)
				relief=stone*.12+h*.07
			img.set_pixel(x,y,color)
			heights[y*size_px+x]=relief
	# Periodic authored leaf stamps: organic pointed shapes with a midrib,
	# not a repeated sine-wave pattern. Wrap both axes for seamless mipmaps.
	if region==0:stamp_woodland_litter(img,heights,size_px)
	for y in range(size_px):
		for x in range(size_px):
			var dx=heights[y*size_px+posmod(x+1,size_px)]-heights[y*size_px+posmod(x-1,size_px)]
			var dy=heights[posmod(y+1,size_px)*size_px+x]-heights[posmod(y-1,size_px)*size_px+x]
			var n=Vector3(-dx*2.6,-dy*2.6,1).normalized()
			normals.set_pixel(x,y,Color(n.x*.5+.5,n.y*.5+.5,n.z*.5+.5,1))
	img.generate_mipmaps();normals.generate_mipmaps()
	terrain_texture=ImageTexture.create_from_image(img);terrain_normal=ImageTexture.create_from_image(normals)
	floor_surface_signature=img.get_data().hex_encode().sha256_text()
func stamp_woodland_litter(img:Image,heights:PackedFloat32Array,size_px:int):
	var rng=RandomNumberGenerator.new();rng.seed=48381
	for i in range(54):
		var cx=rng.randi_range(0,size_px-1);var cy=rng.randi_range(0,size_px-1)
		var angle=rng.randf_range(0,TAU)
		var axis=Vector2(cos(angle),sin(angle));var across=Vector2(-axis.y,axis.x)
		var length=rng.randf_range(2.5,5.6);var width=rng.randf_range(1.0,2.2)
		var tint=Color(.66,.37,.15).lerp(Color(.89,.67,.27),rng.randf())
		for dy in range(-7,8):
			for dx in range(-7,8):
				var offset=Vector2(dx,dy)
				var along=offset.dot(axis)/length;var side=offset.dot(across)/width
				var silhouette=absf(along)+side*side
				if silhouette>=1.0:continue
				var x=posmod(cx+dx,size_px);var y=posmod(cy+dy,size_px)
				var alpha=(1.0-smoothstep(.65,1.0,silhouette))*.75
				var vein=1.0-smoothstep(.06,.33,absf(side))
				img.set_pixel(x,y,img.get_pixel(x,y).lerp(tint.lightened(vein*.18),alpha))
				heights[y*size_px+x]+=.018*alpha
func terrain_mat(c:Color)->StandardMaterial3D:
	if terrain_mats.has(c):return terrain_mats[c]
	var m=StandardMaterial3D.new();m.albedo_color=c;m.albedo_texture=terrain_texture;m.roughness=.84
	m.normal_enabled=true;m.normal_texture=terrain_normal;m.normal_scale=.42
	m.uv1_triplanar=true;m.uv1_world_triplanar=true;m.uv1_scale=Vector3.ONE*(.26 if region==0 else .32 if region==1 else .43)
	terrain_mats[c]=m
	return m
func mesh(kind:String)->Mesh:
	if not meshes.has(kind):
		match kind:
			"box":meshes[kind]=BoxMesh.new()
			"gem":meshes[kind]=PrismMesh.new()
			"orb":meshes[kind]=SphereMesh.new()
			"ring":meshes[kind]=TorusMesh.new()
	return meshes[kind]
func shape(parent:Node3D,kind:String,p:Vector3,scale_value:Vector3,c:Color)->MeshInstance3D:
	var o=MeshInstance3D.new();o.mesh=mesh(kind);o.material_override=mat(c);parent.add_child(o);o.position=p;o.scale=scale_value
	return o
func model(parent:Node3D,id:int)->Node3D:
	var node=Node3D.new();parent.add_child(node)
	if PixelArt.world_sprite(node,id)!=null:
		node.scale=Vector3.ONE*.70
		return node
	var file="res://assets/mosskit.glb" if id==0 else "res://assets/creatures/species_%02d.glb"%id
	if ResourceLoader.exists(file):
		var scene=cached_scene(file)
		if scene!=null:node.add_child(scene.instantiate())
		if id==0 and ResourceLoader.exists("res://assets/foot.glb"):
			for side in [-1,1]:
				var foot=(load("res://assets/foot.glb") as PackedScene).instantiate() as Node3D
				node.add_child(foot);foot.position=Vector3(side*.37,.20,.16);foot.rotation.y=PI
	else:shape(node,"orb",Vector3(0,.55,0),Vector3(.8,1,.8),Data.TINTS[id%3])
	node.scale=Vector3.ONE*.70
	return node
func cached_scene(file:String)->PackedScene:
	if not scene_cache.has(file):scene_cache[file]=load(file) as PackedScene if ResourceLoader.exists(file) else null
	return scene_cache[file]
func prop(parent:Node3D,name_value:String,at:Vector3)->Node3D:
	var file="res://assets/"+name_value+".glb"
	var scene=cached_scene(file)
	if scene==null:return null
	var ob=scene.instantiate() as Node3D
	if ob==null:return null
	parent.add_child(ob);ob.position=at
	return ob
func batch(parent:Node3D,points:Array[Vector3],kind:String,sz:Vector3,c:Color,textured:bool=false):
	if points.is_empty():return
	var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh(kind);mm.instance_count=points.size()
	for i in range(points.size()):mm.set_instance_transform(i,Transform3D(Basis.from_scale(sz),points[i]))
	var instance=MultiMeshInstance3D.new();instance.multimesh=mm;instance.material_override=terrain_mat(c) if textured else mat(c);parent.add_child(instance)
func boundary_detail(points:Array[Vector3]):
	# Batch shared Blender submeshes, rather than allocating a full scene per tile.
	var file="res://assets/"+["dungeon_forest_wall","dungeon_reef_wall","dungeon_star_wall"][region]+".glb"
	if not ResourceLoader.exists(file):return
	var scene=load(file) as PackedScene
	if scene==null:return
	var template=scene.instantiate() as Node3D
	if template==null:return
	var chosen:Array[Vector3]=[]
	for i in range(points.size()):
		if posmod(i*13+run.floor_number*3,5)==0:chosen.append(points[i]-Vector3(0,.44,0))
	if chosen.is_empty():template.free();return
	geometry.add_child(template)
	var inverse=template.global_transform.affine_inverse()
	for child in template.find_children("*","MeshInstance3D",true,false):
		var source=child as MeshInstance3D
		if source.mesh==null:continue
		var local_transform=inverse*source.global_transform
		var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=source.mesh;mm.instance_count=chosen.size()
		for i in range(chosen.size()):
			mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,chosen[i]+Vector3(0,.54,0))*local_transform)
		var instance=MultiMeshInstance3D.new();instance.multimesh=mm;geometry.add_child(instance)
		instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	template.free();wall_decorations=chosen.size()
func rock_parts(file:String)->Array:
	if rock_mesh_cache.has(file):return rock_mesh_cache[file]
	var parts:Array=[]
	var scene=cached_scene(file)
	if scene==null:return parts
	var template=scene.instantiate() as Node3D
	if template==null:return parts
	geometry.add_child(template)
	var inverse=template.global_transform.affine_inverse()
	for child in template.find_children("*","MeshInstance3D",true,false):
		var source=child as MeshInstance3D
		if source.mesh!=null:parts.append({"mesh":source.mesh,"transform":inverse*source.global_transform})
	template.free()
	rock_mesh_cache[file]=parts
	return parts
func batch_parts(parts:Array,placements:Array[Transform3D],shadows:bool=true,animate_exterior:bool=false):
	if placements.is_empty():return
	for part in parts:
		var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=part.mesh;mm.instance_count=placements.size()
		for i in range(placements.size()):mm.set_instance_transform(i,placements[i]*part.transform)
		var instance=MultiMeshInstance3D.new();instance.multimesh=mm;geometry.add_child(instance)
		if not shadows:instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if animate_exterior and part.mesh.get_surface_count()==1:
			var original:Material=part.mesh.surface_get_material(0)
			var animated=exterior_motion_material(original)
			if animated!=null:
				instance.material_override=animated
				exterior_motion_batches+=1
func natural_boundary(points:Array[Vector3])->bool:
	rock_modules=0;span_count=0;corner_count=0
	var prefix="res://assets/dungeon_"+["forest","reef","star"][region]
	var variants:Array=[]
	for variant in range(3):
		var parts=rock_parts(prefix+"_rock_"+str(variant)+".glb")
		if parts.is_empty():return false
		variants.append(parts)
	var spans=rock_parts(prefix+"_span.glb")
	var available:Dictionary={}
	for p in points:available[Vector2i(roundi(p.x/1.4),roundi(p.z/1.4))]=true
	var consumed:Dictionary={}
	var corners=rock_parts(prefix+"_corner.glb")
	var turns:Array[Transform3D]=[]
	if not corners.is_empty():
		for q in available:
			var openings:Array[Vector2i]=[]
			for d in Rules.DIR:
				if run.cells.has(q+d):openings.append(d)
			if openings.size()!=2 or openings[0]+openings[1]==Vector2i.ZERO:continue
			var inward=Vector2(openings[0]+openings[1])
			var angle=atan2(inward.x,inward.y)-PI*.25
			turns.append(Transform3D(Basis(Vector3.UP,angle),pos(q)))
			consumed[q]=true;corner_count+=1
		batch_parts(corners,turns)
	var placements:Array[Transform3D]=[]
	# Pair straight wall cells that face the same open space. Do not span corridors.
	if not spans.is_empty():
		for q in available:
			if consumed.has(q):continue
			if posmod(q.x*31+q.y*17+run.floor_number,9)==0:continue
			for d in [Vector2i.RIGHT,Vector2i.DOWN]:
				var other:Vector2i=q+d
				if not available.has(other) or consumed.has(other):continue
				var normal=Vector2i(-d.y,d.x)
				var forward=run.cells.has(q+normal) and run.cells.has(other+normal)
				var backward=run.cells.has(q-normal) and run.cells.has(other-normal)
				if not forward and not backward:continue
				var inward=normal if forward else -normal
				var angle=atan2(float(inward.x),float(inward.y))
				var middle=(pos(q)+pos(other))*.5
				var wall_height=1.10 if inward.y>0 else .76 if inward.y<0 else .94
				placements.append(Transform3D(Basis(Vector3.UP,angle).scaled(Vector3(1.0,wall_height,1.0)),middle))
				consumed[q]=true;consumed[other]=true;span_count+=1
				break
		batch_parts(spans,placements)
	for variant in range(3):
		var singles:Array[Transform3D]=[]
		for q in available:
			if consumed.has(q):continue
			if posmod(q.x*19+q.y*7+run.floor_number,3)!=variant:continue
			var inward=Vector2i.ZERO
			for d in Rules.DIR:
				if run.cells.has(q+d):inward+=d
			var angle=atan2(float(inward.x),float(inward.y)) if inward!=Vector2i.ZERO else float(posmod(q.x*3+q.y*5,4))*PI*.5
			var scale_value=Vector3(1.0,.82+.15*float(posmod(q.x*13+q.y,5))/4.0,1.0)
			singles.append(Transform3D(Basis(Vector3.UP,angle).scaled(scale_value),pos(q)))
		batch_parts(variants[variant],singles)
		rock_modules+=singles.size()
	rock_modules+=span_count*2+corner_count
	return rock_modules==points.size()
func backdrop_landmarks(wall_cells:Dictionary):
	landmark_count=0;landmark_cells.clear()
	var prefix="dungeon_"+["forest","reef","star"][region]+"_landmark"
	var used:Array[Vector2i]=[]
	# A hero silhouette for each room, located on a safe boundary cell.
	# The far edge is preferred; side edges prevent missing decoration when a corridor crosses it.
	for room in run.rooms:
		var candidates:Array[Vector2i]=[]
		for x in range(room.position.x,room.end.x):
			candidates.append(Vector2i(x,room.position.y-2))
		for y in range(room.position.y,room.end.y):
			candidates.append(Vector2i(room.position.x-2,y))
			candidates.append(Vector2i(room.end.x+1,y))
		for x in range(room.position.x,room.end.x):
			candidates.append(Vector2i(x,room.end.y+1))
		for q in candidates:
			if run.cells.has(q):continue
			var safe=true
			for dy in range(-1,2):
				for dx in range(-1,2):
					if run.cells.has(q+Vector2i(dx,dy)):safe=false
			for other in used:
				if run.distance(q,other)<4:safe=false
			if not safe:continue
			var ob=prop(geometry,prefix,pos(q)+Vector3(0,-.38,0))
			if ob!=null:
				ob.rotation.y=float(posmod(q.x*7+q.y*13,7)-3)*.12
				used.append(q);landmark_cells.append(q);landmark_count+=1
			break
func room_detail(wall_cells:Dictionary):
	detail_count=0
	var file="res://assets/dungeon_"+["forest","reef","star"][region]+"_detail.glb"
	var parts=rock_parts(file)
	if parts.is_empty():return
	var points:Array[Vector3]=[]
	for q in wall_cells:
		if posmod(q.x*29+q.y*43+run.floor_number*7,5)!=0:continue
		for d in Rules.DIR:
			var next:Vector2i=q+d
			if not run.cells.has(next) or run.loot.has(next) or next==run.player or next==run.stairs:continue
			# Offset onto the non-walkable side, so scenery never blocks a tile.
			points.append(pos(q)+Vector3(d.x*.29,.13,d.y*.29))
			break
	if points.is_empty():return
	for part in parts:
		var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=part.mesh;mm.instance_count=points.size()
		for i in range(points.size()):
			mm.set_instance_transform(i,Transform3D(Basis(Vector3.UP,i*.79).scaled(Vector3.ONE*.82),points[i])*part.transform)
		var inst=MultiMeshInstance3D.new();inst.multimesh=mm;geometry.add_child(inst);inst.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	detail_count=points.size()
func exterior_chunks(placements:Array[Transform3D])->Dictionary:
	# Keep every authored transform exactly once. A whole-floor MultiMesh cannot
	# cull its distant instances individually; compact world-space groups can.
	var chunks:Dictionary={}
	for placement in placements:
		var key=Vector2i(floori(placement.origin.x/8.4),floori(placement.origin.z/8.4))
		if not chunks.has(key):
			var group:Array[Transform3D]=[]
			chunks[key]=group
		chunks[key].append(placement)
	return chunks
func exterior_motion_material(original:Material)->ShaderMaterial:
	if not original is StandardMaterial3D:return null
	var name=original.resource_name.to_lower()
	var kind=""
	if name.contains("woodland turquoise stream"):kind="stream"
	elif name.contains("cascade pale highlights"):kind="foam"
	elif name.contains("sea grass"):kind="kelp"
	if kind.is_empty():return null
	if exterior_motion_materials.has(kind):return exterior_motion_materials[kind]
	var shader=Shader.new()
	if kind=="kelp":
		shader.code="""shader_type spatial;
render_mode cull_disabled;
uniform float scene_time=0.0;
uniform vec4 base_color:source_color=vec4(0.1,0.35,0.2,1.0);
varying float leaf_height;
void vertex(){
 leaf_height=clamp((VERTEX.y-0.26)/1.7,0.0,1.0);
 vec3 world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float sway=leaf_height*leaf_height;
 VERTEX.x+=sin(scene_time*1.45+world_pos.z*0.85)*0.10*sway;
 VERTEX.z+=cos(scene_time*1.1+world_pos.x*0.73)*0.065*sway;
}
void fragment(){
 ALBEDO=base_color.rgb*(0.85+leaf_height*0.55);
 ROUGHNESS=0.73;
}"""
	else:
		shader.code="""shader_type spatial;
render_mode cull_disabled;
uniform float scene_time=0.0;
uniform vec4 base_color:source_color=vec4(0.1,0.6,0.7,1.0);
uniform bool is_foam=false;
varying vec3 local_p;
void vertex(){local_p=VERTEX;}
void fragment(){
 float flow=local_p.z*20.0-local_p.y*7.0-scene_time*5.2;
 float ripple=0.5+0.5*sin(flow+0.65*sin(local_p.x*34.0));
 float filaments=pow(0.5+0.5*sin(local_p.x*37.0+sin(flow*0.36)),5.0);
 float shimmer=0.30*ripple+0.70*filaments;
 ALBEDO=base_color.rgb*(0.76+shimmer*0.37);
 ROUGHNESS=0.24+0.20*(1.0-ripple);
 EMISSION=base_color.rgb*shimmer*(is_foam?0.28:0.12);
}"""
	var material=ShaderMaterial.new();material.shader=shader
	material.set_shader_parameter("base_color",original.albedo_color)
	if kind!="kelp":material.set_shader_parameter("is_foam",kind=="foam")
	exterior_motion_materials[kind]=material
	return material
func batch_exterior_parts(parts:Array,placements:Array[Transform3D]):
	for chunk in exterior_chunks(placements).values():
		batch_parts(parts,chunk,false,true)
		exterior_static_batches+=parts.size()
func build_exterior_world(wall_cells:Dictionary):
	# Multi-source BFS provides exact distance bands in O(cells + exterior area).
	# No decoration is added to the gameplay graph.
	exterior_static_batches=0;exterior_motion_batches=0;exterior_motion_materials.clear()
	exterior_groups.clear();exterior_vistas.clear();habitat_tall.clear();habitat_large.clear();vista_large.clear();scenic_bounds.clear();vista_focus_points.clear();habitat_variant_counts.assign([0,0,0]);habitat_low.clear();habitat_ground_candidates.clear();exterior_distances.clear();exterior_life.clear();exterior_life_parts.clear();exterior_life_centers.clear();exterior_clock=0.0
	var queue:Array[Vector2i]=[]
	for q in run.cells:
		exterior_distances[q]=0;queue.append(q)
	var cursor=0
	while cursor<queue.size():
		var q=queue[cursor];cursor+=1
		var distance:int=exterior_distances[q]
		if distance>=9:continue
		for d in Rules.DIR:
			var next:Vector2i=q+d
			if exterior_distances.has(next):continue
			exterior_distances[next]=distance+1;queue.append(next)
	var prefix="res://assets/dungeon_"+["forest","reef","star"][region]
	var parts=rock_parts(prefix+"_exterior.glb")
	if parts.is_empty():return
	var placements:Array[Transform3D]=[]
	var vista_parts=rock_parts(prefix+"_vista.glb")
	var vista_placements:Array[Transform3D]=[]
	# Score each possible scenic anchor in the actual orthographic camera
	# plane, rather than blindly choosing a side outside the narrow viewport.
	# The placement remains deterministic and independent of gameplay RNG.
	for room in run.rooms:
		if vista_parts.is_empty() or exterior_vistas.size()>=12:break
		var middle:Vector2i=room.get_center()
		var choices:Array[Vector2i]=[]
		for offset in [0,-1,1,-2,2]:
			choices.append(Vector2i(middle.x+offset,room.end.y+2))
			choices.append(Vector2i(middle.x+offset,room.position.y-3))
			choices.append(Vector2i(room.position.x-3,middle.y+offset))
			choices.append(Vector2i(room.end.x+2,middle.y+offset))
		for offset in [0,-1,1,-2,2]:
			choices.append(Vector2i(middle.x+offset,room.end.y+1))
			choices.append(Vector2i(middle.x+offset,room.position.y-2))
			choices.append(Vector2i(room.position.x-2,middle.y+offset))
			choices.append(Vector2i(room.end.x+1,middle.y+offset))
		var best_score=-INF
		var best_cell=Vector2i.ZERO
		var best_transform=Transform3D.IDENTITY
		var best_bounds=AABB()
		var best_large=false
		for q in choices:
			if not exterior_clearance(q):continue
			var center=pos(q)+Vector3(0,-.42,0)
			var angle=float(posmod(q.x*7+q.y*11,5)-2)*.14
			var large=habitat_wide_clearance(q)
			var vista_scale=Vector3(1.42,1.58,1.35) if large else Vector3(.89,1.12,.89)
			var placement=Transform3D(Basis(Vector3.UP,angle).scaled(vista_scale),center)
			var bounds=measure_scenery(vista_parts,placement)
			if not scenery_clear_of_floor(bounds):
				large=false
				placement=Transform3D(Basis(Vector3.UP,angle).scaled(Vector3(.89,1.12,.89)),center)
				bounds=measure_scenery(vista_parts,placement)
			if not scenery_clear_of_floor(bounds):continue
			var score=score_vista(bounds,pos(middle))
			if score>best_score:
				best_score=score;best_cell=q;best_transform=placement;best_bounds=bounds;best_large=large
		if best_score>-INF:
			vista_placements.append(best_transform);scenic_bounds.append(best_bounds)
			exterior_vistas.append(best_cell);exterior_groups.append(best_cell)
			vista_focus_points.append(best_bounds.position+best_bounds.size*Vector3(.5,.65,.5))
			if best_large:vista_large.append(best_cell)
	batch_exterior_parts(vista_parts,vista_placements)
	# Reserve the large scenic silhouettes before medium and low vegetation.
	build_habitat_layers(prefix,queue,wall_cells)
	# Interleave the sides of each room instead of filling far-away rooms first.
	var candidates:Array[Vector2i]=[]
	# Distribute the first layer across all rooms before filling any one room.
	# Prioritize front/back silhouette anchors, followed by the side edges.
	for offset in [0,-2,2,-4,4]:
		for room in run.rooms:
			var middle:Vector2i=room.get_center()
			candidates.append(Vector2i(middle.x+offset,room.position.y-2))
			candidates.append(Vector2i(middle.x+offset,room.end.y+1))
			candidates.append(Vector2i(room.position.x-2,middle.y+offset))
			candidates.append(Vector2i(room.end.x+1,middle.y+offset))
	for q in queue:
		if exterior_distances[q] in [2,3,4] and posmod(q.x*11+q.y*7,3)==0:candidates.append(q)
	for q in candidates:
		if exterior_groups.size()>=40:break
		if not exterior_clearance(q):continue
		var angle=float(posmod(q.x*11+q.y*17,12))*TAU/12.0
		# The reef fans and astral arches are front-facing compositions.
		# Keep their authored face legible instead of randomly turning them edge-on.
		if region!=0:angle=float(posmod(q.x*11+q.y*17,7)-3)*.16
		var scale_value=.78+.40*float(posmod(q.x*13+q.y*7,9))/8.0
		var center=pos(q)+Vector3(0,-.45,0)
		var placement=Transform3D(Basis(Vector3.UP,angle).scaled(Vector3.ONE*scale_value),center)
		var bounds=measure_scenery(parts,placement)
		if not scenery_clear_of_floor(bounds):continue
		placements.append(placement);scenic_bounds.append(bounds)
		exterior_groups.append(q)
		if exterior_life_centers.size()<12:exterior_life_centers.append(center)
	batch_exterior_parts(parts,placements)
	if exterior_life_centers.is_empty():
		for q in exterior_vistas:
			if exterior_life_centers.size()>=12:break
			exterior_life_centers.append(pos(q)+Vector3(0,-.12,1.0))
	exterior_life_parts=rock_parts(prefix+"_life.glb")
	if exterior_life_centers.is_empty():return
	for part in exterior_life_parts:
		var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=part.mesh;mm.instance_count=exterior_life_centers.size()
		var inst=MultiMeshInstance3D.new();inst.multimesh=mm;geometry.add_child(inst);inst.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		exterior_life.append(inst)
	update_exterior_world(0.0)
func build_habitat_layers(prefix:String,queue:Array[Vector2i],wall_cells:Dictionary):
	var tall_parts=rock_parts(prefix+"_habitat.glb")
	var low_parts=rock_parts(prefix+"_understory.glb")
	if tall_parts.is_empty() or low_parts.is_empty():return
	var tall_placements:Array[Transform3D]=[]
	var crystal_placements:Array[Transform3D]=[]
	var ruin_placements:Array[Transform3D]=[]
	var crystal_parts:Array=rock_parts(prefix+"_crystal_habitat.glb") if region==2 else []
	var ruin_parts:Array=rock_parts(prefix+"_ruin_habitat.glb") if region==2 else []
	habitat_ground_candidates.assign(queue)
	# Favor exterior behind rooms and sides. Tall assets farther from walkable
	# tiles protect the camera's foreground view. No gameplay cells are edited.
	var candidates:Array[Vector2i]=[]
	for offset in [0,-3,3]:
		for room in run.rooms:
			var m:Vector2i=room.get_center()
			candidates.append(Vector2i(m.x+offset,room.position.y-3))
			candidates.append(Vector2i(room.position.x-3,m.y+offset))
			candidates.append(Vector2i(room.end.x+2,m.y+offset))
			# Tall foreground silhouettes are set back to protect the pet's camera view.
			candidates.append(Vector2i(m.x+offset,room.end.y+3))
	# Interleave wider landscape bands so distant rooms are not starved by BFS order.
	for band in [4,5,6,7,8,9]:
		for q in queue:
			if exterior_distances[q]==band:candidates.append(q)
	for q in candidates:
		if habitat_tall.size()>=36:break
		if exterior_distances.get(q,99)<3 or exterior_distances.get(q,99)>9:continue
		var safe=true
		for dy in range(-1,2):
			for dx in range(-1,2):
				if run.cells.has(q+Vector2i(dx,dy)):safe=false
		for old in exterior_groups:
			if Vector2(old-q).length_squared()<(9.0 if vista_large.has(old) else 5.0):safe=false;break
		for old in landmark_cells:
			if Vector2(old-q).length_squared()<5.0:safe=false;break
		for old in habitat_tall:
			if Vector2(old-q).length_squared()<(12.0 if habitat_large.has(old) else 6.0):safe=false;break
		if not safe:continue
		var angle=float(posmod(q.x*7+q.y*11,7)-3)*.15
		# Cycle actual silhouette families; spatial scale still comes from seed.
		var variant=habitat_tall.size()%3 if region==2 and not crystal_parts.is_empty() and not ruin_parts.is_empty() else 0
		var selected_parts:Array=crystal_parts if variant==1 else ruin_parts if variant==2 else tall_parts
		if variant!=0:angle=float(posmod(q.x*11+q.y*7,12))*TAU/12.0
		var large=habitat_wide_clearance(q)
		var scale_value=(1.32+.31*float(posmod(q.x*13+q.y*7,9))/8.0) if large else (.87+.17*float(posmod(q.x*13+q.y*7,9))/8.0)
		var height_factor=1.05+.43*float(posmod(q.x*17+q.y*3,11))/10.0
		if not large:height_factor=minf(height_factor,1.28)
		# A suspended star garden may be elevated only in a wide safe exterior
		# footprint. Keep the authored model inside the same GLB audit limits.
		var elevation=(.52 if large else -.12) if region==2 else -.42
		var center=pos(q)+Vector3(0,elevation,0)
		var placement=Transform3D(Basis(Vector3.UP,angle).scaled(Vector3(scale_value,scale_value*height_factor,scale_value)),center)
		var bounds=measure_scenery(selected_parts,placement)
		if not scenery_clear_of_floor(bounds):
			large=false
			placement=Transform3D(Basis(Vector3.UP,angle).scaled(Vector3(.88,1.10,.88)),center)
			bounds=measure_scenery(selected_parts,placement)
		if not scenery_clear_of_floor(bounds):continue
		# Do not trade a visible waterfall for a large foreground tree.
		if obscures_vista_or_room(bounds):
			large=false
			var reduced_center=pos(q)+Vector3(0,-.42,0)
			placement=Transform3D(Basis(Vector3.UP,angle).scaled(Vector3(.82,.72,.82)),reduced_center)
			bounds=measure_scenery(selected_parts,placement)
			if not scenery_clear_of_floor(bounds) or obscures_vista_or_room(bounds):continue
		if variant==1:crystal_placements.append(placement)
		elif variant==2:ruin_placements.append(placement)
		else:tall_placements.append(placement)
		habitat_variant_counts[variant]+=1
		scenic_bounds.append(bounds)
		habitat_tall.append(q)
		if large:habitat_large.append(q)
	batch_exterior_parts(tall_parts,tall_placements)
	batch_exterior_parts(crystal_parts,crystal_placements)
	batch_exterior_parts(ruin_parts,ruin_placements)
func fill_habitat_understory(wall_cells:Dictionary):
	if habitat_ground_candidates.is_empty():return
	var prefix="res://assets/dungeon_"+["forest","reef","star"][region]
	var low_parts=rock_parts(prefix+"_understory.glb")
	if low_parts.is_empty():return
	var low_placements:Array[Transform3D]=[]
	# Fill the actual remaining terrain, after reserving large models and terraces.
	for distance in [2,3,4,5,6,7,8,9]:
		for q in habitat_ground_candidates:
			if habitat_low.size()>=150:break
			if exterior_distances[q]!=distance or wall_cells.has(q) or terrace_cells.has(q):continue
			var safe=true
			for old in exterior_groups:
				if Vector2(old-q).length_squared()<(3.5 if vista_large.has(old) else 1.6):safe=false;break
			for old in habitat_tall:
				if Vector2(old-q).length_squared()<(3.5 if habitat_large.has(old) else 2.2):safe=false;break
			for old in landmark_cells:
				if Vector2(old-q).length_squared()<2.0:safe=false;break
			for old in habitat_low:
				if Vector2(old-q).length_squared()<2.0:safe=false;break
			if not safe:continue
			var angle=float(posmod(q.x*11+q.y*17,12))*TAU/12.0
			var scale_value=.76+.34*float(posmod(q.x*7+q.y*13,9))/8.0
			var placement=Transform3D(Basis(Vector3.UP,angle).scaled(Vector3.ONE*scale_value),pos(q)+Vector3(0,-.51,0))
			var bounds=measure_scenery(low_parts,placement)
			if not scenery_clear_of_floor(bounds):continue
			low_placements.append(placement);scenic_bounds.append(bounds)
			habitat_low.append(q)
	batch_exterior_parts(low_parts,low_placements)
	print("DUNGEON_HABITAT region=",region," tall=",habitat_tall.size()," understory=",habitat_low.size()," large_habitat=",habitat_large.size()," large_vistas=",vista_large.size())
func score_vista(bounds:AABB,focus:Vector3)->float:
	# With a fixed X camera axis, horizontal crop is exact. The vertical
	# preference is soft because the viewport's portrait ratio can change.
	var center=bounds.get_center()
	var delta=center-focus
	var half_width=DUNGEON_CAMERA_WIDTH*.5
	var overlap=maxf(0.0,minf(bounds.end.x,focus.x+half_width)-maxf(bounds.position.x,focus.x-half_width))
	var visible=overlap/maxf(bounds.size.x,.01)
	var camera_up=Vector3(0,DUNGEON_CAMERA_OFFSET.z,-DUNGEON_CAMERA_OFFSET.y).normalized()
	var screen_y=delta.dot(camera_up)
	var side_preference=1.0-absf(absf(delta.x)-2.8)/half_width
	# Reward a readable off-center landmark, not a centered foreground obstruction.
	var front_penalty=maxf(0.0,delta.z-1.0)*.10
	return visible*5.0+side_preference-absf(screen_y-1.6)*.23-front_penalty
func camera_ray_blocked(bounds:AABB,target:Vector3)->bool:
	# Orthographic sight lines are parallel at every player location.
	# Only test forward from the target toward the camera.
	return bounds.intersects_segment(target+DUNGEON_CAMERA_OFFSET.normalized()*.12,target+DUNGEON_CAMERA_OFFSET)!=null
func obscures_vista_or_room(bounds:AABB)->bool:
	for target in vista_focus_points:
		if camera_ray_blocked(bounds,target):return true
	for room in run.rooms:
		var target=pos(room.get_center())+Vector3(0,.65,0)
		if camera_ray_blocked(bounds,target):return true
	return false
func measure_scenery(parts:Array,placement:Transform3D)->AABB:
	# Use the imported GLB's real mesh bounds, including authored offsets,
	# scale and yaw. A cell-center check alone cannot detect overhanging cliffs.
	var result=AABB()
	var first=true
	for part in parts:
		var local_transform:Transform3D=part.transform
		var local_mesh:Mesh=part.mesh
		var bounds:AABB=(placement*local_transform)*local_mesh.get_aabb()
		result=bounds if first else result.merge(bounds)
		first=false
	return result
func scenery_clear_of_floor(bounds:AABB)->bool:
	# Conservative 4 cm safety margin on each side of the 1.4-unit tile.
	var low=Vector2i(floori((bounds.position.x+.66)/1.4),floori((bounds.position.z+.66)/1.4))
	var high=Vector2i(floori((bounds.end.x+.74)/1.4),floori((bounds.end.z+.74)/1.4))
	for y in range(low.y,high.y+1):
		for x in range(low.x,high.x+1):
			if run.cells.has(Vector2i(x,y)):return false
	return true
func habitat_wide_clearance(q:Vector2i)->bool:
	for dy in range(-2,3):
		for dx in range(-2,3):
			if run.cells.has(q+Vector2i(dx,dy)):return false
	for old in habitat_tall:
		if Vector2(old-q).length_squared()<12.0:return false
	for old in exterior_groups:
		if Vector2(old-q).length_squared()<12.0:return false
	for old in landmark_cells:
		if Vector2(old-q).length_squared()<9.0:return false
	return true
func exterior_clearance(q:Vector2i)->bool:
	if exterior_distances.get(q,99)<2 or exterior_distances.get(q,99)>6:return false
	for dy in range(-1,2):
		for dx in range(-1,2):
			if run.cells.has(q+Vector2i(dx,dy)):return false
	for old in exterior_groups:
		if Vector2(old-q).length_squared()<(9.0 if vista_large.has(old) else 5.0):return false
	for old in habitat_tall:
		if Vector2(old-q).length_squared()<(9.0 if habitat_large.has(old) else 5.0):return false
	for old in landmark_cells:
		if Vector2(old-q).length_squared()<4.0:return false
	return true
func update_exterior_world(dt:float):
	exterior_clock+=clampf(dt,0.0,.25)
	for material in exterior_motion_materials.values():material.set_shader_parameter("scene_time",exterior_clock)
	if exterior_life.is_empty():return
	for i in range(exterior_life_centers.size()):
		var phase=exterior_clock*(.70 if region==1 else .46)+float(i)*2.399
		var radius=.55 if region==0 else .80
		var center=exterior_life_centers[i]
		var height=1.1+.26*sin(phase*1.6) if region==0 else .83+.18*sin(phase) if region==1 else 1.25+.23*sin(phase)
		var point=center+Vector3(cos(phase)*radius,height,sin(phase)*radius)
		var basis=Basis(Vector3.UP,-phase-PI*.5)
		if region==0:basis=basis*Basis(Vector3.RIGHT,sin(exterior_clock*8.0+i)*.26)
		for k in range(exterior_life.size()):
			exterior_life[k].multimesh.set_instance_transform(i,Transform3D(basis,point)*exterior_life_parts[k].transform)
func landscape_terraces(wall_cells:Dictionary):
	terrace_count=0;terrace_cells.clear()
	var parts=rock_parts("res://assets/dungeon_"+["forest","reef","star"][region]+"_terrace.glb")
	if parts.is_empty():return
	var candidates:Dictionary={}
	# Only consider areas near a wall, keeping the exterior draw distance bounded.
	for wall in wall_cells:
		for dy in range(-4,5):
			for dx in range(-4,5):
				var q:Vector2i=wall+Vector2i(dx,dy)
				if posmod(q.x,2)==0 and posmod(q.y,2)==0:candidates[q]=true
	var placements:Array[Transform3D]=[]
	for q in candidates:
		if placements.size()>=24:break
		if posmod(q.x*13+q.y*11+run.floor_number,5)==0 and not placements.is_empty():continue
		var safe=true
		for dy in range(2):
			for dx in range(2):
				var tile:Vector2i=q+Vector2i(dx,dy)
				if run.cells.has(tile) or wall_cells.has(tile):safe=false
				for group in exterior_groups:
					if Vector2(tile-group).length_squared()<(5.0 if vista_large.has(group) else 3.0):safe=false
				for landmark in landmark_cells:
					if Vector2(tile-landmark).length_squared()<2.0:safe=false
				for tall in habitat_tall:
					if Vector2(tile-tall).length_squared()<(5.0 if habitat_large.has(tall) else 3.0):safe=false
		if not safe:continue
		for dy in range(2):
			for dx in range(2):terrace_cells[q+Vector2i(dx,dy)]=true
		var center_point=pos(q)+Vector3(.7,-.53,.7)
		var angle=float(posmod(q.x*7+q.y*11,4))*PI*.5
		placements.append(Transform3D(Basis(Vector3.UP,angle).scaled(Vector3(.88,.90,.88)),center_point))
	batch_exterior_parts(parts,placements);terrace_count=placements.size()
func interior_floor_detail():
	floor_detail_count=0;floor_detail_bounds.clear()
	var parts=rock_parts("res://assets/dungeon_"+["forest","reef","star"][region]+"_floor_detail.glb")
	if parts.is_empty():return
	var placements:Array[Transform3D]=[]
	for room in run.rooms:
		var candidates:Array[Vector2i]=[]
		for y in range(room.position.y,room.end.y):
			for x in range(room.position.x,room.end.x):
				var q=Vector2i(x,y)
				if not run.cells.has(q) or q==run.player or q==run.stairs or q==run.relic or q==room.position:continue
				if run.loot.has(q) or run.traps.has(q) or threshold_cells.has(q) or run.enemy_at(q)>=0:continue
				var wall_side=false
				for d in Rules.DIR:
					if not run.cells.has(q+d):wall_side=true
					# Leave doorways and the adjacent approach tiles readable.
					if threshold_cells.has(q+d):
						wall_side=false;break
				if wall_side:candidates.append(q)
		# Seeded ranking avoids a left-to-right bias and keeps room centers open.
		candidates.sort_custom(func(a:Vector2i,b:Vector2i):
			return posmod(a.x*73+a.y*137+run.floor_number*31,997)<posmod(b.x*73+b.y*137+run.floor_number*31,997))
		var used=0
		var room_cap=2 if region==2 else 5
		for q in candidates:
			if used>=room_cap or placements.size()>=48:break
			var close=false
			for old in floor_detail_bounds:
				if Vector2(q-old).length_squared()<2.0:close=true;break
			if close:continue
			var edge_dir=Vector2i.ZERO
			for d in Rules.DIR:
				if not run.cells.has(q+d):edge_dir=d;break
			var angle=float(posmod(q.x*3+q.y*11,8))*PI*.25
			var size_value=.60+.22*float(posmod(q.x*17+q.y*13,7))/6.0
			var center=pos(q)+Vector3(edge_dir.x*.18,.005,edge_dir.y*.18)
			var placement=Transform3D(Basis(Vector3.UP,angle).scaled(Vector3(size_value,.55,size_value)),center)
			var bounds=measure_scenery(parts,placement)
			if not floor_detail_fits(q,bounds):continue
			placements.append(placement);floor_detail_bounds[q]=bounds;used+=1
	batch_parts(parts,placements,false);floor_detail_count=placements.size()
func floor_detail_fits(q:Vector2i,bounds:AABB)->bool:
	# Actual transformed mesh footprint must remain inside a single tile
	# and below the pet's movement silhouette. Decorative, never collision.
	var center=pos(q)
	return bounds.position.x>=center.x-.66 and bounds.end.x<=center.x+.66 and bounds.position.z>=center.z-.66 and bounds.end.z<=center.z+.66 and bounds.position.y>=-.04 and bounds.end.y<=.22
func passage_thresholds():
	threshold_count=0;threshold_cells.clear()
	var parts=rock_parts("res://assets/dungeon_"+["forest","reef","star"][region]+"_threshold.glb")
	if parts.is_empty():return
	var placements:Array[Transform3D]=[]
	for room in run.rooms:
		for y in range(room.position.y,room.end.y):
			for x in range(room.position.x,room.end.x):
				var q=Vector2i(x,y)
				if not run.cells.has(q):continue
				for d in Rules.DIR:
					var passage:Vector2i=q+d
					if room.has_point(passage) or not run.cells.has(passage) or threshold_cells.has(passage):continue
					var across=Vector2i(-d.y,d.x)
					# Only decorate narrow entrances, never an open room or wide junction.
					if run.cells.has(passage+across) or run.cells.has(passage-across):continue
					if run.loot.has(passage) or passage==run.stairs or run.traps.has(passage):continue
					threshold_cells[passage]=true
					var angle=atan2(float(-d.x),float(-d.y))
					placements.append(Transform3D(Basis(Vector3.UP,angle),pos(passage)))
	batch_parts(parts,placements,false);threshold_count=placements.size()
func room_lighting():
	# A small, fixed pool: only the player's nearest two rooms cast accent light.
	room_lights.clear()
	for i in range(2):
		var light=OmniLight3D.new();geometry.add_child(light)
		light.light_color=[Color("#ffd59a"),Color("#75dfd3"),Color("#bfadff")][region]
		light.light_energy=.45 if i==0 else .30
		light.omni_range=5.0;light.omni_attenuation=1.4;light.shadow_enabled=false
		room_lights.append(light)
	update_room_lights()
func update_room_lights():
	var candidates:Array[Vector2i]=[]
	for room in run.rooms:
		var q:Vector2i=room.get_center();candidates.append(q)
	candidates.sort_custom(func(a:Vector2i,b:Vector2i):return run.distance(a,run.player)<run.distance(b,run.player))
	for i in range(room_lights.size()):
		room_lights[i].visible=i<candidates.size()
		if i<candidates.size():room_lights[i].position=pos(candidates[i])+Vector3(-1.1,2.6,-1.0)
func floor_name()->String:
	return ["Ancient passages","Treasure chamber","Monster den","Restorative grotto","Forgotten ruins"][run.floor_kind]
func build_landscape_connections():
	landscape_ridge_weights.clear();landscape_links.clear()
	if region==2:return
	# Link neighboring authored formations with continuous terrain shoulders.
	# Reject paths that would cross a room or its boundary. No gameplay RNG
	# or collision is touched and no extra draw calls are needed.
	var anchors:Array[Vector2i]=[]
	for q in exterior_groups+habitat_tall:
		if not anchors.has(q):anchors.append(q)
	var pairs:Dictionary={}
	for a in anchors:
		if landscape_links.size()>=LANDSCAPE_LINK_CAP:break
		var best=Vector2i.ZERO
		var best_distance=65.0
		var found=false
		for b in anchors:
			var d=Vector2(a-b).length_squared()
			if d<4.0 or d>=best_distance:continue
			if pairs.has(Vector4i(a.x,a.y,b.x,b.y)) or pairs.has(Vector4i(b.x,b.y,a.x,a.y)):continue
			if not landscape_path_clear(a,b):continue
			best=b;best_distance=d;found=true
		if not found:continue
		var key=Vector4i(a.x,a.y,best.x,best.y)
		pairs[key]=true;landscape_links.append(key)
		var steps=maxi(1,ceili(sqrt(best_distance)*3.0))
		for i in range(steps+1):
			var point=Vector2(a).lerp(Vector2(best),float(i)/float(steps))
			var center=Vector2i(roundi(point.x),roundi(point.y))
			for dy in range(-2,3):
				for dx in range(-2,3):
					var q=center+Vector2i(dx,dy)
					if exterior_distances.get(q,0)<2:continue
					var weight=1.0-smoothstep(.35,2.0,Vector2(q).distance_to(point))
					if weight>.001:
						landscape_ridge_weights[q]=maxf(landscape_ridge_weights.get(q,0.0),weight)
func landscape_path_clear(a:Vector2i,b:Vector2i)->bool:
	var steps=maxi(1,ceili(Vector2(a-b).length()*3.0))
	for i in range(steps+1):
		var p=Vector2(a).lerp(Vector2(b),float(i)/float(steps))
		if exterior_distances.get(Vector2i(roundi(p.x),roundi(p.y)),0)<2:return false
	return true
func build_exterior_surface():
	build_landscape_connections()
	# The procedural terrain is a connected landscape, not a flat colored void.
	# All scenery models remain the original Blender GLBs. The terrain never
	# rises to walkable height or changes the gameplay grid.
	var low=Vector2i(999,999);var high=Vector2i(-999,-999)
	for p in run.cells:
		low=Vector2i(mini(low.x,p.x),mini(low.y,p.y));high=Vector2i(maxi(high.x,p.x),maxi(high.y,p.y))
	# The lowered landscape must extend beyond the farthest camera ray.
	# Extra distant terrain is inexpensive compared with another GLB cluster.
	low-=Vector2i(12,18);high+=Vector2i(12,12)
	var width=high.x-low.x+1;var depth=high.y-low.y+1
	var noise=FastNoiseLite.new();noise.seed=run.seed_value+region*901+run.floor_number*37;noise.frequency=.19;noise.fractal_octaves=3
	var vertices=PackedVector3Array();var normals=PackedVector3Array();var colors=PackedColorArray();var indices=PackedInt32Array();var uvs=PackedVector2Array()
	var heights=PackedFloat32Array();heights.resize(width*depth)
	exterior_max_height=-1.0
	var deep:Color=[Color("#344c2b"),Color("#235063"),Color("#24243e")][region]
	var raised:Color=[Color("#788052"),Color("#6b9696"),Color("#5c537f")][region]
	var distant:Color=[Color("#132c26"),Color("#102c56"),Color("#292851")][region]
	var broad=FastNoiseLite.new();broad.seed=noise.seed+991;broad.frequency=.075
	for y in range(depth):
		for x in range(width):
			var q=low+Vector2i(x,y)
			var near=run.cells.has(q)
			for d in Rules.DIR:
				if run.cells.has(q+d):near=true
			var n=noise.get_noise_2d(q.x,q.y)
			var h=-.64 if near else -.57+.21*n
			var distance:int=exterior_distances.get(q,10)
			var depth_factor=smoothstep(3.0,9.0,float(distance))
			# Preserve support beneath placed Blender scenery; lower only the
			# unobstructed landscape. The playable floor is untouched.
			var support=0.0
			# Large habitat can extend into the ninth distance band. Preserve
			# a connected foundation beyond its footprint.
			if distance<=9 or exterior_distances.has(q+Vector2i(3,0)) or exterior_distances.has(q-Vector2i(3,0)) or exterior_distances.has(q+Vector2i(0,3)) or exterior_distances.has(q-Vector2i(0,3)):
				for group in exterior_groups:
					support=maxf(support,1.0-smoothstep(1.0,3.1 if vista_large.has(group) else 2.5,Vector2(q-group).length()))
				for landmark in landmark_cells:
					support=maxf(support,1.0-smoothstep(1.0,2.5,Vector2(q-landmark).length()))
			for group in habitat_tall:
				if Vector2(q-group).length_squared()<(6.0 if habitat_large.has(group) else 3.0):support=1.0;break
			if habitat_low.has(q) or terrace_cells.has(q):support=1.0
			var ridge:float=landscape_ridge_weights.get(q,0.0)
			if not near:
				# Broad ridges, basins and cloud valleys behind the actual scenery.
				var relief=broad.get_noise_2d(q.x,q.y)
				h-=depth_factor*(1.0-support)*([.40,1.10,2.35][region]+.48*relief)
				h+=minf(.24,depth_factor*(1.0-support)*maxf(0.0,relief)*.40)
				# Blend broad mossy banks or limestone shelves between the
				# actual rock/tree anchors, without raising the walkable floor.
				if region<2:
					var shoulder=-.47+.09*n
					h=lerpf(h,shoulder,ridge*.86*(1.0-support*.65))
					h-=depth_factor*(1.0-maxf(support,ridge))*(.22 if region==0 else .43)
				h=minf(h,-.35)
			heights[y*width+x]=h;exterior_max_height=maxf(exterior_max_height,h)
			vertices.append(Vector3(q.x*1.4,h,q.y*1.4));uvs.append(Vector2(q))
			var color=deep.lerp(raised,clampf(.43+n*.57,0.0,1.0))
			# Biome-scale patches are sampled in world space, not per room.
			var sediment=broad.get_noise_2d(q.x+31.0,q.y-19.0)
			if region==0:
				color=color.lerp(Color("#8a7950"),smoothstep(.04,.55,sediment)*.48*(1.0-support*.45))
			elif region==1:
				color=color.lerp(Color("#9bb5a2"),smoothstep(-.05,.53,sediment)*.55*(1.0-depth_factor*.75))
			if region==0:
				color=color.lerp(Color("#75844b"),ridge*.44)
			elif region==1:
				color=color.lerp(Color("#719b8d"),ridge*.55)
			color=color.lerp(distant,depth_factor*.75*(1.0-ridge*.50))
			var cloud=broad.get_noise_2d(q.x,q.y)
			if region==2:color=color.lerp(Color("#8070a8"),smoothstep(-.05,.55,cloud)*depth_factor*.42)
			# Baked contact shadow under the actual authored placement centers.
			color=color.darkened(support*.18)
			# Alpha is a cloud-coverage weight, never transparency: keep rock
			# foundations clear while giving the space between islands depth.
			if region==2:color.a=(1.0-support)*smoothstep(1.0,4.0,float(distance))
			colors.append(color)
	for y in range(depth):
		for x in range(width):
			var left=heights[y*width+maxi(0,x-1)];var right=heights[y*width+mini(width-1,x+1)]
			var front=heights[maxi(0,y-1)*width+x];var back=heights[mini(depth-1,y+1)*width+x]
			normals.append(Vector3(left-right,2.8,front-back).normalized())
			if x<width-1 and y<depth-1:
				var i=y*width+x
				indices.append_array(PackedInt32Array([i,i+1,i+width+1,i,i+width+1,i+width]))
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_INDEX]=indices
	var surface=ArrayMesh.new();surface.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	exterior_surface=MeshInstance3D.new();exterior_surface.mesh=surface
	var material=terrain_mat(Color.WHITE).duplicate() as StandardMaterial3D
	material.vertex_color_use_as_albedo=true
	# Exterior soil and sand read at a broader scale than the walkable floor.
	if region<2:
		material.uv1_scale=Vector3.ONE*(.15 if region==0 else .21)
		material.normal_scale=.30
	if region==2:material.albedo_texture=null;material.normal_enabled=false
	exterior_surface.material_override=star_cloud_material() if region==2 else material
	geometry.add_child(exterior_surface)
	exterior_surface.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	exterior_vertex_count=vertices.size()
	print("DUNGEON_LANDSCAPE_CONNECTIONS region=",region," links=",landscape_links.size()," ridge_vertices=",landscape_ridge_weights.size())
func build_astral_cloud_banks():
	astral_cloud_bounds.clear()
	if region!=2:return
	var parts=rock_parts("res://assets/dungeon_star_cloud_habitat.glb")
	if parts.is_empty():return
	var placements:Array[Transform3D]=[]
	# Interleave near and far bands: a cloud bank must remain below the
	# playable plane and may not cross the actual footprint of any island.
	for distance in [3,5,4,6,7,8,9]:
		for q in exterior_distances:
			if placements.size()>=ASTRAL_CLOUD_CAP:break
			if exterior_distances[q]!=distance:continue
			if posmod(q.x*11+q.y*19+run.floor_number,4)!=0:continue
			var wide=.93+.42*float(posmod(q.x*17+q.y*7,9))/8.0
			var y=-1.30-.16*float(distance-3)
			var placement=Transform3D(Basis(Vector3.UP,float(posmod(q.x*7+q.y*13,12))*TAU/12.0).scaled(Vector3(wide,.72,wide*.92)),pos(q)+Vector3(0,y,0))
			var bounds=measure_scenery(parts,placement)
			if bounds.end.y>-.35 or not scenery_clear_of_floor(bounds):continue
			var clear=true
			for other in scenic_bounds:
				if other.grow(.12).intersects(bounds):clear=false;break
			if not clear:continue
			for other in astral_cloud_bounds:
				if other.grow(.30).intersects(bounds):clear=false;break
			if not clear:continue
			placements.append(placement);astral_cloud_bounds.append(bounds)
	batch_exterior_parts(parts,placements)
	print("ASTRAL_CLOUD_BANKS ",astral_cloud_bounds.size())
func star_cloud_material()->ShaderMaterial:
	# Opaque, two-scale painted cloud field on the depressed exterior terrain.
	# No extra draw calls, alpha sorting, textures or particle overdraw.
	var shader=Shader.new()
	shader.code="""shader_type spatial;
render_mode cull_disabled;
varying vec3 cloud_pos;
varying vec4 ground_tint;
float hash21(vec2 p){
 p=fract(p*vec2(123.34,456.21));p+=dot(p,p+45.32);
 return fract(p.x*p.y);
}
float noise2(vec2 p){
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
void vertex(){
 cloud_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 ground_tint=COLOR;
}
void fragment(){
 vec2 p=cloud_pos.xz*vec2(0.23,0.31);
 float broad=noise2(p*0.55);
 float folds=noise2(p+vec2(broad*1.8,broad*0.8));
 float detail=noise2(p*2.25+vec2(3.2,1.7));
 float cloud=smoothstep(0.32,0.79,0.53*broad+0.35*folds+0.12*detail);
 float rim=smoothstep(0.45,0.82,cloud);
 vec3 shade=mix(vec3(0.085,0.10,0.24),vec3(0.32,0.36,0.62),cloud);
 shade=mix(shade,vec3(0.66,0.65,0.88),rim*0.85);
 ALBEDO=mix(ground_tint.rgb,shade,ground_tint.a*0.86);
 EMISSION=shade*ground_tint.a*0.10;
 ROUGHNESS=0.95;
}"""
	var material=ShaderMaterial.new()
	material.shader=shader
	return material
func floor_vertex_color(point:Vector2)->Color:
	# Contact shading at the wall-foot: continuous per-vertex gradient,
	# independent of the tile pattern or the lighting renderer.
	var cell=Vector2i(floori(point.x+.5),floori(point.y+.5))
	var distance=1.5
	for dy in range(-1,2):
		for dx in range(-1,2):
			var q=cell+Vector2i(dx,dy)
			if run.cells.has(q):continue
			var delta=(point-Vector2(q)).abs()-Vector2(.5,.5)
			distance=minf(distance,Vector2(maxf(delta.x,0.0),maxf(delta.y,0.0)).length())
	var factor=smoothstep(0.0,.82,distance)
	var edge:Color=[Color("#99937b"),Color("#82979f"),Color("#93879f")][region]
	return edge.lerp(Color.WHITE,.28+.72*factor)
func build_walkable_surface(ground:Color):
	# One indexed surface with shared vertices and soft border shading.
	var surface_tool=SurfaceTool.new();surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices:Dictionary={}
	for p in run.cells:
		for y in range(2):
			for x in range(2):
				var origin:Vector2i=p*2+Vector2i(x-1,y-1)
				var corners=[origin,origin+Vector2i.RIGHT,origin+Vector2i(1,1),origin+Vector2i.DOWN]
				var ids:PackedInt32Array=[]
				for key in corners:
					if not vertices.has(key):
						var point=Vector2(key)*.5
						surface_tool.set_normal(Vector3.UP)
						surface_tool.set_color(floor_vertex_color(point))
						surface_tool.set_uv(point)
						surface_tool.add_vertex(Vector3(point.x*1.4,-.01,point.y*1.4))
						vertices[key]=vertices.size()
					ids.append(vertices[key])
				for k in [0,1,2,0,2,3]:surface_tool.add_index(ids[k])
	var surface=surface_tool.commit()
	floor_surface=MeshInstance3D.new();floor_surface.mesh=surface
	var material=terrain_mat(ground).duplicate() as StandardMaterial3D
	material.vertex_color_use_as_albedo=true
	floor_surface.material_override=material;geometry.add_child(floor_surface)
func ambient_material(c:Color)->StandardMaterial3D:
	var m=StandardMaterial3D.new()
	m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo=true
	m.cull_mode=BaseMaterial3D.CULL_DISABLED
	m.albedo_color=c
	return m
func ambient_leaf()->ArrayMesh:
	# Lightweight curved particle geometry, not a static scenery asset.
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points=[Vector3(-.5,0,0),Vector3(-.12,.09,-.27),Vector3(.5,0,0),Vector3(-.12,.09,.27),Vector3(0,.16,0)]
	for i in [0,1,4,1,2,4,2,3,4,3,0,4]:
		st.add_vertex(points[i])
	st.generate_normals()
	return st.commit()
func ambient_batch(mesh_value:Mesh,count:int,material:Material)->MultiMeshInstance3D:
	var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;mm.mesh=mesh_value;mm.instance_count=count
	var inst=MultiMeshInstance3D.new();inst.multimesh=mm;inst.material_override=material
	inst.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;geometry.add_child(inst)
	return inst
func ambient_spawn(i:int,initial:bool=false):
	var center=pos(run.player)
	var spread=Vector3(ambient_rng.randf_range(-5.5,5.5),0,ambient_rng.randf_range(-6.0,5.0))
	ambient_origins[i]=center+spread
	ambient_ages[i]=ambient_rng.randf_range(0.0,4.5) if initial else 0.0
func build_living_ambient():
	ambient_batches.clear();ambient_origins.clear();ambient_ages.clear();ambient_clock=0.0
	ambient_rng.seed=run.seed_value+run.floor_number*1709+region*101
	ambient_origins.resize(AMBIENT_COUNT+MOTE_COUNT);ambient_ages.resize(AMBIENT_COUNT+MOTE_COUNT)
	for i in range(ambient_origins.size()):ambient_spawn(i,true)
	var primary:Mesh
	if region==0:primary=ambient_leaf()
	elif region==1:
		var bubble=TorusMesh.new();bubble.inner_radius=.42;bubble.outer_radius=.50;bubble.rings=12;bubble.ring_segments=8;primary=bubble
	else:
		var crystal=PrismMesh.new();primary=crystal
	var tint:Color=[Color("#d7b65b"),Color("#b5f3ff"),Color("#d6c4ff")][region]
	ambient_batches.append(ambient_batch(primary,AMBIENT_COUNT,ambient_material(tint)))
	var mote=SphereMesh.new();mote.radial_segments=8;mote.rings=4
	ambient_batches.append(ambient_batch(mote,MOTE_COUNT,ambient_material([Color("#ffe38b"),Color("#a4e9ee"),Color("#e6d7ff")][region])))
	var plane=PlaneMesh.new();plane.size=Vector2(.44,.44)
	var trace_mat=ambient_material(Color.WHITE)
	var svg=''
	if region==1:
		svg='<circle cx="32" cy="32" r="25" fill="none" stroke="#b8eced" stroke-opacity=".8" stroke-width="3"/><circle cx="32" cy="32" r="15" fill="none" stroke="#e4ffff" stroke-opacity=".5" stroke-width="2"/>'
	else:
		var ink='#69553b' if region==0 else '#d6b9fb'
		svg='<g fill="'+ink+'"><ellipse cx="32" cy="39" rx="12" ry="10"/><ellipse cx="17" cy="24" rx="5" ry="7" transform="rotate(-20 17 24)"/><ellipse cx="27" cy="17" rx="5" ry="7"/><ellipse cx="39" cy="17" rx="5" ry="7"/><ellipse cx="49" cy="24" rx="5" ry="7" transform="rotate(20 49 24)"/></g>'
	var image=Image.new();image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">'+svg+'</svg>')
	trace_mat.albedo_texture=ImageTexture.create_from_image(image)
	trail_batch=ambient_batch(plane,TRAIL_COUNT,trace_mat)
	trail_origins.clear();trail_ages.clear();trail_angles.clear();trail_cursor=0;trail_emitted=0
	trail_origins.resize(TRAIL_COUNT);trail_ages.resize(TRAIL_COUNT);trail_angles.resize(TRAIL_COUNT)
	trail_ages.fill(99.0)
	build_biome_light()
	update_living_ambient(0.0)
func light_overlay(shader_source:String)->MeshInstance3D:
	var shader=Shader.new();shader.code=shader_source
	var sm=ShaderMaterial.new();sm.shader=shader;biome_light_materials.append(sm)
	var overlay=MeshInstance3D.new();overlay.mesh=floor_surface.mesh;overlay.material_override=sm
	overlay.position.y=.022;overlay.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;geometry.add_child(overlay)
	return overlay
func build_biome_light():
	caustic_overlay=null;forest_light_overlay=null;astral_sigils=null;astral_sigil_cells.clear();biome_light_materials.clear()
	if region==0:
		# World-space moving canopy light, softly broken into leaf-like patches.
		# One pass on the existing indexed floor, no lights or extra particles.
		forest_light_overlay=light_overlay("""shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform float scene_time=0.0;
varying vec2 p;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz;}
void fragment(){
 vec2 q=p+vec2(sin(scene_time*0.24),cos(scene_time*0.19))*0.18;
 float n=sin(q.x*1.57+q.y*0.71)+sin(q.y*2.13-q.x*0.84)+0.48*sin(q.x*4.12+q.y*3.41);
 float shafts=smoothstep(0.15,1.25,sin(q.x*0.46+q.y*0.81)+0.32*sin(q.x*1.24-q.y*0.6));
 float sun=smoothstep(0.36,1.37,n)*shafts;
 float shadow=(1.0-smoothstep(-1.36,-0.13,n))*0.21;
 ALBEDO=mix(vec3(0.09,0.20,0.12),vec3(1.0,0.88,0.46),sun);
 ALPHA=max(shadow,sun*0.32);
}""")
	elif region==1:
		# Animated nearest/second-nearest cellular edges. A single bounded 3x3
		# neighborhood gives intersecting organic caustic filaments rather than stripes.
		caustic_overlay=light_overlay("""shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform float scene_time=0.0;
varying vec2 p;
vec2 hash2(vec2 a){
 return fract(sin(vec2(dot(a,vec2(127.1,311.7)),dot(a,vec2(269.5,183.3))))*43758.5453);
}
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz;}
void fragment(){
 vec2 q=p*0.92;
 q+=vec2(0.24*sin(p.y*1.7+sin(p.x*0.8)+scene_time*0.5),0.22*cos(p.x*1.6+sin(p.y*1.1)-scene_time*0.41));
 vec2 cell=floor(q);vec2 f=fract(q);
 float first=9.0;float second=9.0;
 for(int y=-1;y<=1;y++){
  for(int x=-1;x<=1;x++){
   vec2 g=vec2(float(x),float(y));vec2 r=hash2(cell+g);
   vec2 feature=0.5+0.30*sin(scene_time*0.67+r*6.283185);
   vec2 offset=g+feature-f;float d=dot(offset,offset);
   if(d<first){second=first;first=d;}else{second=min(second,d);}
  }
 }
 float edge=max(sqrt(second)-sqrt(first),0.0);
 float core=1.0-smoothstep(0.008,0.065,edge);
 float halo=1.0-smoothstep(0.025,0.19,edge);
 float flicker=0.45+0.55*pow(0.5+0.5*sin(p.x*2.3+p.y*1.9+sin(p.y*3.2)+scene_time*1.1),2.0);
 float light_pool=0.48+0.52*smoothstep(-0.8,0.8,sin(p.x*0.63-p.y*0.81+scene_time*0.23));
 ALBEDO=mix(vec3(0.27,0.72,0.80),vec3(0.88,0.98,0.68),flicker);
 ALPHA=(core*0.15+halo*0.08)*flicker*light_pool;
}""")
	else:
		# Flat gold-inlaid constellation seal, one per sufficiently large room.
		# A procedural material on real world geometry, never a screenshot overlay.
		var shader=Shader.new();shader.code="""shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform float scene_time=0.0;
float line(float d,float width){return 1.0-smoothstep(width,width+0.008,d);}
void fragment(){
 vec2 p=UV*2.0-1.0;float r=length(p);float a=atan(p.y,p.x);
 float rings=max(line(abs(r-0.84),0.009),line(abs(r-0.68),0.007));
 float star_radius=0.30+0.32*pow(abs(cos(a*4.0)),5.0);
 float spokes=line(abs(r-star_radius),0.010);
 float ticks=line(abs(sin(a*12.0)),0.055)*smoothstep(0.69,0.72,r)*(1.0-smoothstep(0.79,0.81,r));
 float center=line(abs(r-0.17),0.008);
 float ink=max(max(rings,spokes),max(ticks,center));
 float pulse=0.82+0.18*sin(scene_time*1.5+a*4.0+r*8.0);
 ALBEDO=mix(vec3(0.72,0.39,0.12),vec3(1.0,0.83,0.40),pulse);
 ALPHA=ink*0.88*(1.0-smoothstep(0.90,0.96,r));
}"""
		var material=ShaderMaterial.new();material.shader=shader;biome_light_materials.append(material)
		var plane=PlaneMesh.new();plane.size=Vector2.ONE
		var transforms:Array[Transform3D]=[]
		for room in run.rooms:
			if mini(room.size.x,room.size.y)<3:continue
			var q:Vector2i=room.get_center()
			var diameter=minf(3.5,float(mini(room.size.x,room.size.y))*1.4-.65)
			astral_sigil_cells.append(q)
			transforms.append(Transform3D(Basis.from_scale(Vector3(diameter,1,diameter)),pos(q)+Vector3(0,.018,0)))
		if not transforms.is_empty():
			astral_sigils=ambient_batch(plane,transforms.size(),material)
			for i in range(transforms.size()):astral_sigils.multimesh.set_instance_transform(i,transforms[i])
func emit_trail(tile:Vector2i,dir:Vector2i):
	if not run.cells.has(tile):return
	var side=-1.0 if trail_cursor%2==0 else 1.0
	trail_origins[trail_cursor]=pos(tile)+Vector3(-dir.y*side*.12,.035,dir.x*side*.12)
	trail_angles[trail_cursor]=atan2(float(dir.x),float(dir.y))
	trail_ages[trail_cursor]=0.0;trail_cursor=(trail_cursor+1)%TRAIL_COUNT;trail_emitted+=1
func update_living_ambient(dt:float):
	if ambient_batches.size()!=2 or not is_instance_valid(trail_batch):return
	var delta=clampf(dt,0.0,.25)
	ambient_clock+=delta
	for material in biome_light_materials:material.set_shader_parameter("scene_time",ambient_clock)
	for i in range(ambient_origins.size()):
		ambient_ages[i]+=delta
		var mote=i>=AMBIENT_COUNT
		var duration=5.5+float(i%5)*.37
		if ambient_ages[i]>=duration or ambient_origins[i].distance_to(pos(run.player))>9.0:ambient_spawn(i)
		var age=ambient_ages[i];var phase=age/duration;var seed=float(i)*2.399
		var fade=minf(1.0,minf(phase*7.0,(1.0-phase)*6.0))
		var offset=Vector3(sin(age*.71+seed)*.46,0,cos(age*.57+seed)*.36)
		var size=.12+.035*float(i%4)
		var basis:Basis
		if mote:
			offset.y=.55+.30*sin(age*.8+seed)+phase*.40
			size=.035+.014*float(i%3);fade*=.48+.52*absf(sin(ambient_clock*1.4+seed))
			basis=Basis.from_scale(Vector3.ONE*size)
		elif region==0:
			offset.y=3.3-phase*3.15
			basis=Basis.from_euler(Vector3(age*.8+seed,age*.6,seed+sin(age)*.6)).scaled(Vector3.ONE*size*1.7)
		elif region==1:
			offset.y=.10+phase*3.0
			basis=Basis(Vector3.RIGHT,PI*.30).scaled(Vector3.ONE*size*(.75+phase*.6))
		else:
			offset.y=.3+phase*2.6
			basis=Basis.from_euler(Vector3(age*.4,seed+age*.6,age*.3)).scaled(Vector3(size*.4,size,size*.4))
		var batch_index=1 if mote else 0
		var index=i-AMBIENT_COUNT if mote else i
		var mm=ambient_batches[batch_index].multimesh
		mm.set_instance_transform(index,Transform3D(basis,ambient_origins[i]+offset))
		mm.set_instance_color(index,Color(1,1,1,fade*(.82 if region==0 and not mote else .70)))
	var life=1.7 if region==1 else 3.2
	for i in range(TRAIL_COUNT):
		trail_ages[i]=minf(99.0,trail_ages[i]+delta)
		var fade=clampf(1.0-trail_ages[i]/life,0.0,1.0)
		var scale_value=(.55+trail_ages[i]*.28) if region==1 else .78
		if fade<=0.0:scale_value=.001
		trail_batch.multimesh.set_instance_transform(i,Transform3D(Basis(Vector3.UP,trail_angles[i]).scaled(Vector3.ONE*scale_value),trail_origins[i]))
		trail_batch.multimesh.set_instance_color(i,Color(1,1,1,fade*.58))
func build_floor():
	var start_usec=Time.get_ticks_usec()
	if is_instance_valid(geometry):geometry.hide();geometry.queue_free()
	if is_instance_valid(actors):actors.hide();actors.queue_free()
	geometry=Node3D.new();world.add_child(geometry);actors=Node3D.new();world.add_child(actors);actor_nodes.clear()
	combat_fx_setup(geometry)
	var walls:Array[Vector3]=[]
	floor_ornaments.clear()
	var seen:Dictionary={}
	for p in run.cells:
		var q:Vector2i=p
		if posmod(q.x*37+q.y*19+run.floor_number*13,11)==0:floor_ornaments.append(pos(q)+Vector3(0,.003,0))
		for d in Rules.DIR:
			var next:Vector2i=q+d
			if not run.cells.has(next) and not seen.has(next):
				seen[next]=true;walls.append(pos(next)+Vector3(0,.44,0))
	var ground:Color=[Color("#8a9274"),Color("#76929a"),Color("#77709a")][region]
	build_walkable_surface(ground)
	build_living_ambient()
	# Recess foundation below the walkable surface, so squared pedestals do not protrude around authored rocks.
	var foundation:Array[Vector3]=[]
	for p in walls:foundation.append(p-Vector3(0,.59,0))
	batch(geometry,foundation,"box",Vector3(1.18,.24,1.18),palette[2].darkened(.12),false)
	wall_decorations=0
	var scenery_points:Array[Vector3]=[]
	var scenery_seen:Dictionary={}
	for cell in seen:
		for direction in Rules.DIR:
			var q:Vector2i=cell+direction
			if run.cells.has(q) or seen.has(q) or scenery_seen.has(q):continue
			scenery_seen[q]=true
			# Legacy isolated clusters are only a fallback. The full habitat
			# already supplies distinct low cover and would otherwise overlap.
			if not ResourceLoader.exists("res://assets/dungeon_"+["forest","reef","star"][region]+"_understory.glb") and posmod(q.x*17+q.y*31+run.floor_number,4)==0:
				scenery_points.append(pos(q)+Vector3(0,-.45,0))
	var cluster_file="res://assets/dungeon_"+["forest","reef","star"][region]+"_cluster.glb"
	for part in rock_parts(cluster_file):
		if scenery_points.is_empty():break
		var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=part.mesh;mm.instance_count=scenery_points.size()
		for i in range(scenery_points.size()):
			var scale_value=.85+float(posmod(i*7,5))*.13
			var transform=Transform3D(Basis(Vector3.UP,float(i%8)*PI*.25).scaled(Vector3.ONE*scale_value),scenery_points[i])
			mm.set_instance_transform(i,transform*part.transform)
		var batch_instance=MultiMeshInstance3D.new();batch_instance.multimesh=mm;geometry.add_child(batch_instance)
		batch_instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	backdrop_landmarks(seen)
	build_exterior_world(seen)
	landscape_terraces(seen)
	fill_habitat_understory(seen)
	build_exterior_surface()
	build_astral_cloud_banks()
	if not natural_boundary(walls):
		batch(geometry,walls,"box",Vector3(1.4,.88,1.4),palette[2],true)
		boundary_detail(walls)
	room_detail(seen)
	passage_thresholds()
	interior_floor_detail()
	room_lighting()
	var dais=prop(geometry,"dungeon_"+["forest","reef","star"][region]+"_dais",pos(run.relic)+Vector3(0,-.025,0))
	if dais!=null:dais.rotation.y=PI*.25
	for i in range(run.rooms.size()):
		var p=pos(run.rooms[i].position)+Vector3(-.52,0,-.52)
		if prop(geometry,["dungeon_forest_shrine","dungeon_reef_shrine","dungeon_star_shrine"][region],p)==null:
			shape(geometry,"gem" if region!=0 else "orb",p+Vector3(0,.45,0),Vector3(.38,.88,.38),palette[3])
			shape(geometry,"box",p+Vector3(0,.11,0),Vector3(.62,.18,.62),palette[2])
	pet=Node3D.new();geometry.add_child(pet);pet.position=pos(run.player)
	pet_pose=model(pet,companion_id);pet_pose.scale*=1.28
	# Sprite orientation is driven by actual movement, not the GLB basis.
	pet_pose.rotation.y=0.0
	pet.rotation.y=atan2(float(facing.x),float(facing.y))
	attack_fx=shape(geometry,"ring",Vector3.ZERO,Vector3.ONE,Color("#ffdfa0"));attack_fx.hide();attack_fx.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fxmat=StandardMaterial3D.new();fxmat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;fxmat.albedo_color=Color("#ffe6a3");attack_fx.material_override=fxmat
	destination_fx=shape(geometry,"ring",Vector3.ZERO,Vector3(.68,.08,.68),Color("#a0e6db"));destination_fx.hide();destination_fx.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	reward_pool.clear();reward_age=0.0
	reward_fx=Node3D.new();geometry.add_child(reward_fx);reward_fx.hide()
	var sparkle_mat=StandardMaterial3D.new();sparkle_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;sparkle_mat.albedo_color=Color("#ffe5a0")
	for i in range(12):
		var spark=shape(reward_fx,"gem",Vector3.ZERO,Vector3(.065,.15,.065),Color("#ffe5a0"));spark.material_override=sparkle_mat;spark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;reward_pool.append(spark)
	active_floor=run.floor_revision
	banner_time=1.65;floor_banner.text="B%d  ·  %s"%[run.floor_number,floor_name()];floor_banner.show()
	floor_banner.size=Vector2(area.size.x,45);floor_banner.position=Vector2(0,area.size.y*.12)
	var focus=pet.position+Vector3(0,.18,-.48)
	camera.position=focus+DUNGEON_CAMERA_OFFSET+Vector3(sin(elapsed*61.0)*fx_ground_shake,0,cos(elapsed*73.0)*fx_ground_shake*.45);camera.look_at(focus)
	PixelArt.animate_world_sprite(pet_pose,Vector2(facing),false,0.0,"idle",region==1)
	refresh_actors()
	floor_build_usec=Time.get_ticks_usec()-start_usec
	print("DUNGEON_FLOOR_BUILD region=",region," floor=",run.floor_number," usec=",floor_build_usec," rocks=",rock_modules," cached_rock_sets=",rock_mesh_cache.size()," landmarks=",landmark_count," details=",detail_count," paired_spans=",span_count," corners=",corner_count," terraces=",terrace_count," floor_details=",floor_detail_count," thresholds=",threshold_count," exterior_vertices=",exterior_vertex_count," exterior_groups=",exterior_groups.size()," exterior_static_batches=",exterior_static_batches," exterior_life=",exterior_life_centers.size())
func actor_for(key:String,at:Vector3)->Node3D:
	if actor_nodes.has(key):return actor_nodes[key]
	var n=Node3D.new();actors.add_child(n);n.position=at;actor_nodes[key]=n;actor_created+=1
	return n
# Preview species use the same nearest-filtered 2.5D billboards as Mosky.
# Missing/unapproved species keep their legacy construct until replacement art exists.
func add_enemy_contact_shadow(actor:Node3D,species:String)->void:
	if enemy_shadow_material==null:
		var image:=Image.create(32,32,false,Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		for y in range(32):
			for x in range(32):
				var distance:=Vector2((x-15.5)/15.0,(y-15.5)/15.0).length()
				var opacity:float=.38*(1.0-smoothstep(.28,1.0,distance))
				image.set_pixel(x,y,Color(.025,.018,.055,opacity))
		enemy_shadow_material=StandardMaterial3D.new()
		enemy_shadow_material.albedo_texture=ImageTexture.create_from_image(image)
		enemy_shadow_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		enemy_shadow_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		enemy_shadow_material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR
		enemy_shadow_material.cull_mode=BaseMaterial3D.CULL_DISABLED
		enemy_shadow_mesh=QuadMesh.new()
		enemy_shadow_mesh.size=Vector2(1.1,.85)
	var shadow:=MeshInstance3D.new()
	shadow.name="EnemyContactShadow"
	shadow.mesh=enemy_shadow_mesh
	shadow.material_override=enemy_shadow_material
	shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.rotation.x=-PI*.5
	shadow.position.y=.035
	if species in ["eelstrix","marrowray","coralcrab","shellguard"]:shadow.scale=Vector3(1.15,.8,1.0)
	actor.add_child(shadow)
func attach_enemy_pixel(actor:Node3D,species:String)->bool:
	var tex:=PixelArt.enemy_pixel_texture(species,0,"idle",0)
	if tex==null:return false
	var sprite:=Sprite3D.new()
	sprite.name="EnemyPixel"
	sprite.texture=tex
	sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded=false
	sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var boss:bool=species in ["fungal_monarch","tidal_sovereign","celestial_guardian"]
	var size_multiplier:float=1.45 if boss else 1.0
	sprite.pixel_size=1.25*size_multiplier/48.0
	sprite.position.y=.54*size_multiplier
	actor.set_meta("enemy_size_multiplier",size_multiplier)
	add_enemy_contact_shadow(actor,species)
	actor.add_child(sprite)
	actor.set_meta("species",species)
	actor.set_meta("enemy_facing",0)
	actor.set_meta("enemy_phase","idle")
	actor.set_meta("enemy_clock",0.0)
	actor.set_meta("enemy_duration",0.0)
	# In standalone terrain tests the shader file may not be copied.
	var shader_path:="res://volnox_pixel_life.gdshader"
	if ResourceLoader.exists(shader_path):
		var material:=ShaderMaterial.new()
		material.shader=load(shader_path) as Shader
		material.set_shader_parameter("sprite_tex",tex)
		material.set_shader_parameter("biome_tint",[Color("#d5e6b5"),Color("#9be3e8"),Color("#c3c5ff")][region])
		material.set_shader_parameter("pulse_offset",float(actor.get_instance_id()%17)*.3)
		material.set_shader_parameter("region",region)
		sprite.material_override=material
	return true
func enemy_pose(actor:Node3D,state:String,seconds:float,direction:Vector2=Vector2.ZERO)->void:
	if not actor.has_meta("species"):return
	actor.set_meta("enemy_phase",state)
	actor.set_meta("enemy_clock",0.0)
	actor.set_meta("enemy_duration",seconds)
	actor.set_meta("enemy_facing",PixelArt.direction_for(direction,int(actor.get_meta("enemy_facing",0))))
func update_enemy_pixel(actor:Node3D,dt:float,motion:Vector3)->void:
	var sprite:=actor.get_node_or_null("EnemyPixel") as Sprite3D
	if sprite==null:return
	var state:String=actor.get_meta("enemy_phase","idle")
	var clock:float=float(actor.get_meta("enemy_clock",0.0))+dt
	var duration:float=float(actor.get_meta("enemy_duration",0.0))
	if state=="defeat" and clock>=duration:
		actor.hide();actor.queue_free();return
	if state in ["attack","hurt","windup"] and clock>=duration:
		state="recover" if state=="attack" else "idle"
		duration=.12 if state=="recover" else 0.0
		clock=0.0
	elif state=="recover" and clock>=duration:
		state="idle";clock=0.0
	if state in ["idle","walk"]:
		var next_state:="walk" if motion.length_squared()>.002 else "idle"
		if next_state!=state:clock=0.0
		state=next_state
		if state=="walk":actor.set_meta("enemy_facing",PixelArt.direction_for(Vector2(motion.x,motion.z),int(actor.get_meta("enemy_facing",0))))
	actor.set_meta("enemy_phase",state);actor.set_meta("enemy_clock",clock);actor.set_meta("enemy_duration",duration)
	var frame:int=posmod(int(clock*12.0),4) if state=="walk" else mini(1,int(clock*9.0)) if state=="attack" else 0
	var species:String=str(actor.get_meta("species"))
	var facing_index:int=int(actor.get_meta("enemy_facing",0))
	var hovering:bool=species in ["nova_wisp","leafwisp","lunamoth","jellymancer","marrowray","nebulwing","bubblewisp","sylphowl","leviathorn","astro_golem","celestial_guardian","tidal_sovereign"]
	var rise:float=.13+.04*sin(elapsed*3.0+float(actor.get_instance_id()%11)) if hovering and state!="defeat" else 0.0
	var size_multiplier:float=float(actor.get_meta("enemy_size_multiplier",1.0))
	sprite.position.y=.54*size_multiplier+rise
	var shadow:=actor.get_node_or_null("EnemyContactShadow") as MeshInstance3D
	if shadow!=null:
		var footprint:float=size_multiplier*(1.0-rise*.65)
		shadow.scale=Vector3(footprint*(1.15 if species in ["eelstrix","marrowray","coralcrab","shellguard"] else 1.0),footprint*.8,1.0)
	var tex:=PixelArt.enemy_pixel_texture(species,facing_index,state,frame)
	if tex!=null and sprite.texture!=tex:sprite.texture=tex
	if sprite.material_override is ShaderMaterial:
		var material:=sprite.material_override as ShaderMaterial
		material.set_shader_parameter("sprite_tex",sprite.texture)
		material.set_shader_parameter("hit_flash",.32 if state=="hurt" else 0.0)
		material.set_shader_parameter("world_phase",elapsed)
	else:sprite.modulate=Color("#ffb5c6") if state=="hurt" else Color.WHITE
# Lightweight reusable pixel VFX: no per-frame node allocation, no camera-facing 3D creatures.
func combat_fx_setup(parent:Node3D)->void:
	combat_particles.clear();combat_warnings.clear();combat_bursts.clear();fx_reactions.clear();fx_ground_shake=0.0
	combat_fx_root=Node3D.new();parent.add_child(combat_fx_root)
	fx_arc_mesh=ImmediateMesh.new()
	fx_arc_material=StandardMaterial3D.new()
	fx_arc_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	fx_arc_material.vertex_color_use_as_albedo=true
	fx_arc_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	fx_arc_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	var arc_node:=MeshInstance3D.new();arc_node.mesh=fx_arc_mesh;arc_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;combat_fx_root.add_child(arc_node)
	fx_audio.clear();fx_audio_cursor=0
	for i in range(12):
		var sound:=AudioStreamPlayer3D.new();sound.unit_size=4.0;sound.max_distance=24.0;sound.volume_db=-12.0
		combat_fx_root.add_child(sound);fx_audio.append(sound)
	var quad:=QuadMesh.new();quad.size=Vector2(1.22,1.22)
	combat_warn_mat=StandardMaterial3D.new()
	combat_warn_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	combat_warn_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	var warn_img:=Image.create(16,16,false,Image.FORMAT_RGBA8);warn_img.fill(Color.TRANSPARENT)
	for y in range(16):
		for x in range(16):
			var edge:bool=x in [0,1,14,15] or y in [0,1,14,15]
			if edge or posmod(x+y,5)==0:warn_img.set_pixel(x,y,Color(1,.32,.18,.65 if edge else .16))
	combat_warn_mat.albedo_texture=ImageTexture.create_from_image(warn_img)
	combat_warn_mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	for i in range(FX_WARNING_CAP):
		var q:=MeshInstance3D.new();q.mesh=quad;q.material_override=combat_warn_mat
		q.rotation.x=-PI*.5;q.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		combat_fx_root.add_child(q);q.hide();combat_warnings.append(q)
	for i in range(FX_PARTICLE_CAP):
		var particle:=Sprite3D.new()
		particle.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		particle.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		particle.shaded=false;particle.pixel_size=.032
		particle.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		combat_fx_root.add_child(particle);particle.hide();combat_particles.append(particle)
func combat_pixel_texture(mode:String,light:Color,dark:Color)->ImageTexture:
	var key:=mode+str(light)+str(dark)
	if combat_textures.has(key):return combat_textures[key]
	var im:=Image.create(16,16,false,Image.FORMAT_RGBA8);im.fill(Color.TRANSPARENT)
	for y in range(16):
		for x in range(16):
			var v:=Vector2(x-7.5,y-7.5)
			var r:float=v.length()
			var fill:bool=false
			var inner:bool=false
			match mode:
				"bubble","wave","spiral":
					fill=r>=4.5 and r<=7.0
					inner=fill and v.x+v.y<0
				"slash","fan":
					fill=absf(v.y-v.x*.65)<2.0 and absf(v.x)<7.0
					inner=fill and absf(v.y-v.x*.65)<.85
				"dart","shards":
					fill=absf(v.x)+absf(v.y)*.55<5.5
					inner=absf(v.x+1.0)+absf(v.y)*.65<2.5
				"whip","lightning":
					var center:float=sin(v.x*.65)*2.3
					fill=absf(v.y-center)<2.0 and absf(v.x)<7.0
					inner=fill and absf(v.y-center)<.9
				"web":
					fill=r<7.0 and (absf(v.x)<1.0 or absf(v.y)<1.0 or absf(absf(v.x)-absf(v.y))<1.0 or absf(r-5.0)<.7)
					inner=r<2.0
				"flame","meteor","beam":
					fill=absf(v.x)<(7.0-absf(v.y)*.65) and absf(v.y)<7.0
					inner=fill and absf(v.x+1.0)<3.0 and absf(v.y+1.0)<4.0
				"cloud":
					fill=r<6.8 and posmod(x*7+y*11,7)!=0
					inner=r<3.0
				_:
					fill=absf(v.x)+absf(v.y)<7.5
					inner=absf(v.x+1.0)+absf(v.y+1.0)<4.0
			if fill:im.set_pixel(x,y,light if inner else dark)
	var texture:=ImageTexture.create_from_image(im)
	combat_textures[key]=texture
	return texture
func combat_style(id:String)->Array:
	if Rules.MOVE_LIBRARY.has(id):
		var move:Dictionary=Rules.MOVE_LIBRARY[id]
		return [move.mode,move.light,move.dark,move.duration]
	if id.begins_with("alt_"):
		var species:=id.trim_prefix("alt_")
		if Rules.SECONDARY_SKILLS.has(species):
			var main:Array=Rules.SIGNATURE_SKILLS[species]
			var original:Array=COMBAT_FX_STYLES[main[6]]
			var alt:Array=Rules.SECONDARY_SKILLS[species]
			return [alt[6],original[1],original[2],.34]
	return COMBAT_FX_STYLES.get(id,COMBAT_FX_STYLES.basic_strike)
# Original hand-keyed pixel geometry. Every frame is a separate texture and is
# cached by attack ID, rather than changing only the scale of one static stamp.
func fx_line(im:Image,a:Vector2,b:Vector2,width:float,color:Color)->void:
	var steps:int=maxi(1,ceili(a.distance_to(b)*2.0))
	for i in range(steps+1):
		var p:=a.lerp(b,float(i)/steps)
		for y in range(maxi(0,floori(p.y-width)),mini(im.get_height(),ceili(p.y+width+1))):
			for x in range(maxi(0,floori(p.x-width)),mini(im.get_width(),ceili(p.x+width+1))):
				if Vector2(x,y).distance_to(p)<=width:im.set_pixel(x,y,color)
func fx_disc(im:Image,center:Vector2,radius:float,color:Color,inner:float=0.0)->void:
	for y in range(maxi(0,floori(center.y-radius)),mini(im.get_height(),ceili(center.y+radius+1))):
		for x in range(maxi(0,floori(center.x-radius)),mini(im.get_width(),ceili(center.x+radius+1))):
			var d:=Vector2(x,y).distance_to(center)
			if d<=radius and d>=inner:im.set_pixel(x,y,color)
func combat_animation_mode(id:String,mode:String)->String:
	match id:
		"vine_snap","alt_grovetitan":return "vine"
		"bubble_burst":return "bubble_beam"
		"alt_bubblewisp":return "foam"
		"timber_shock","shell_impact","alt_nebulwing":return "quake"
		"nova_bolt":return "fire_stream"
		"alt_nova_wisp":return "fire_ring"
		"gravity_web","alt_voidspider":return "silk"
		"celestial_verdict":return "radiant"
	return mode
func combat_frame_image(id:String,frame:int)->Image:
	var style:Array=combat_style(id)
	var mode:String=combat_animation_mode(id,str(style[0]))
	var light:=Color(style[1]);var dark:=Color(style[2]);var edge:=dark.darkened(.52)
	var im:=Image.create(FX_FRAME_SIZE,FX_FRAME_SIZE,false,Image.FORMAT_RGBA8);im.fill(Color.TRANSPARENT)
	var t:float=float(posmod(frame,FX_FRAME_COUNT))/float(FX_FRAME_COUNT-1)
	if mode=="lightning":
		electric_sprite(im,id,frame,str(combat_profile(id).role));return im
	var center:=Vector2(24,24)
	match mode:
		"vine":
			var reach:float=sin(t*PI*.9)*.75+.25
			var last:=Vector2(4,25)
			for i in range(1,19):
				var f:float=float(i)/18.0
				var q:=Vector2(4+39*f*reach,24+sin(f*TAU*1.25-t*5.0)*7.0*f)
				fx_line(im,last,q,3.0,edge);fx_line(im,last,q,2.0,dark);fx_line(im,last-Vector2(0,1),q-Vector2(0,1),.8,light)
				if i%5==0:
					var leaf:=q+Vector2(-3,-6 if i%2==0 else 6)
					fx_line(im,q,leaf,2.0,dark);fx_line(im,q,leaf,1.0,light)
				last=q
			if frame>=6:fx_disc(im,last,2.0,light)
		"bubble_beam","foam","bubble":
			for i in range(5):
				var p:=Vector2(8+fposmod(float(i)*9.0+t*28.0,33.0),24+sin(float(i)*2.4+t*4.0)*8.0)
				var radius:float=3.0+float(i%3)
				fx_disc(im,p,radius,edge);fx_disc(im,p,radius-1.0,dark);fx_disc(im,p,radius-2.0,Color(.17,.54,.72,.65))
				fx_disc(im,p-Vector2(1,2),1.3,light);fx_disc(im,p+Vector2(1,2),.8,Color.WHITE)
				if frame>=8 and i%2==0:
					fx_disc(im,p,radius+2.0,light,radius+1.0)
		"quake":
			var spread:float=5.0+t*16.0
			for i in range(8):
				var angle:float=float(i)*TAU/8.0
				var p:=center+Vector2(cos(angle),sin(angle)*.7)*spread
				var q:=center+Vector2(cos(angle+.18),sin(angle+.18)*.7)*spread*.48
				fx_line(im,center,q,1.3,edge);fx_line(im,q,p,1.6,dark)
				fx_line(im,q-Vector2(0,1),p-Vector2(0,1),.7,light)
				var rock:=p-Vector2(0,sin(t*PI)*float(4+i%4))
				fx_disc(im,rock,2.0+float(i%2),edge);fx_disc(im,rock-Vector2(0,1),1.5,light)
		"fire_stream","fire_ring","flame":
			for i in range(8):
				var f:float=float(i)/7.0
				var p:=Vector2(6+f*35,24+sin(f*9.0-t*TAU)*3.5)
				if mode=="fire_ring":p=center+Vector2(cos(f*TAU+t*2.0),sin(f*TAU+t*2.0))*(8.0+t*10.0)
				var radius:float=2.0+f*5.0
				fx_disc(im,p,radius,edge);fx_disc(im,p-Vector2(0,1),radius-1.0,dark)
				fx_disc(im,p-Vector2(1,1),radius*.60,light)
				fx_line(im,p,p-Vector2(3+f*4,5+sin(t*TAU+f*5)*3),radius*.42,dark)
				if i%2==0:fx_disc(im,p-Vector2(0,8),1.0,light)
		"silk","web":
			var radius:float=4.0+t*17.0
			for i in range(8):
				var angle:float=float(i)*TAU/8.0
				var next_angle:float=float(i+1)*TAU/8.0
				var p:=center+Vector2(cos(angle),sin(angle))*radius
				fx_line(im,center,p,1.0,light)
				for ring in [0.38,0.72,1.0]:
					var q:=center+Vector2(cos(next_angle),sin(next_angle))*radius*float(ring)
					fx_line(im,center.lerp(p,float(ring)),q,.8,dark if i%2==0 else light)
		"lightning":
			var last:=Vector2(3,24)
			for i in range(1,9):
				var q:=Vector2(3+i*5,24+float(posmod(i*17+frame*7,15)-7))
				fx_line(im,last,q,2.5,dark);fx_line(im,last,q,1.0,light)
				if i%3==0:fx_line(im,q,q+Vector2(-4,8),.7,light)
				last=q
		"radiant","beam":
			var w:float=2.0+sin(t*PI)*6.0
			fx_line(im,Vector2(4,24),Vector2(43,24),w,dark);fx_line(im,Vector2(4,24),Vector2(43,24),w*.45,light)
			for i in range(4):
				var p:=Vector2(8+fposmod(float(i)*11+t*30,34.0),24)
				fx_line(im,p-Vector2(0,w+3),p+Vector2(0,w+3),.9,light)
		"cloud":
			for i in range(7):
				var angle:float=float(i)*2.399+t
				var p:=center+Vector2(cos(angle),sin(angle))*(5.0+t*13.0)
				fx_disc(im,p,4.0+sin(t*PI)*3.0,dark);fx_disc(im,p-Vector2(1,2),2.0,light)
		"slash","fan":
			for i in range(3):
				var last:=center+Vector2(-14,10-i*6)
				for j in range(1,10):
					var f:float=float(j)/9.0
					var q:=center+Vector2(-14+28*f,10-i*6-sin(f*PI)*12-t*3)
					fx_line(im,last,q,2.0,dark);fx_line(im,last,q,.8,light);last=q
		"wave","spiral":
			for i in range(3):
				var radius:float=3.0+fposmod(t*16.0+i*5.0,17.0)
				fx_disc(im,center,radius,dark,maxf(0.0,radius-2.0));fx_disc(im,center,radius-1.0,light,maxf(0.0,radius-2.0))
		_:
			# Projectile families retain distinct palettes and frame-dependent tails.
			var p:=center+Vector2(sin(t*TAU)*3.0,cos(t*TAU)*2.0)
			for i in range(4):
				var q:=p-Vector2(float(i)*4.0, sin(t*TAU+i)*3.0)
				fx_disc(im,q,5.0-float(i),dark);fx_disc(im,q-Vector2(1,1),maxf(1.0,3.0-float(i)*.5),light)
	return im
func combat_animated_texture(id:String,frame:int)->ImageTexture:
	var key:="animated:"+id+":"+str(posmod(frame,FX_FRAME_COUNT))
	if not combat_textures.has(key):combat_textures[key]=ImageTexture.create_from_image(combat_frame_image(id,frame))
	return combat_textures[key] as ImageTexture
# Presentation contracts are independent of damage rules. Each attack has a
# caster motion, source socket, launch point, target reaction and sound phases.
func combat_profile(id:String)->Dictionary:
	var style:Array=combat_style(id)
	var mode:String=combat_animation_mode(id,str(style[0]))
	var reach:int=1
	var pattern:String="front"
	var element:String="normal"
	if Rules.MOVE_LIBRARY.has(id):
		var move:Dictionary=Rules.MOVE_LIBRARY[id]
		reach=int(move.reach);pattern=str(move.pattern);element=str(move.type)
	else:
		for species in Rules.SIGNATURE_SKILLS:
			var skill:Array=Rules.SIGNATURE_SKILLS[species]
			if id==skill[6] or id=="alt_"+species:
				var info:Array=Rules.ENEMY_TRAINING[species]
				var alt:bool=id.begins_with("alt_")
				reach=int(Rules.SECONDARY_SKILLS[species][0] if alt else skill[0])
				pattern=str(Rules.SECONDARY_SKILLS[species][1] if alt else Rules.ATTACK_PATTERNS[species])
				element=str(info[2] if alt else info[1]);break
	var role:String="contact" if mode in ["slash","leap","roll"] else "ground" if mode=="quake" else "cast" if mode in ["cloud","web","silk","wave","spiral"] else "projectile"
	if mode in ["vine","whip"]:role="lash"
	if mode=="lightning":role="electric_area" if pattern in ["cross","radius","fan","room"] else "electric_contact" if reach==1 else "electric_arc"
	if Rules.MOVE_LIBRARY.has(id):
		if Rules.MOVE_LIBRARY[id].has("drain_fraction"):role="drain"
		elif Rules.MOVE_LIBRARY[id].has("heal_fraction"):role="heal"
	var impact:float=.48 if role in ["contact","electric_contact"] else .64 if role in ["projectile","lash","electric_arc"] else .40
	return {"mode":mode,"role":role,"element":element,"pattern":pattern,"range":reach,"duration":float(style[3]),"impact":impact,"socket":"ground" if role=="ground" else "head" if role=="projectile" else "center"}
func electric_sprite(im:Image,id:String,frame:int,role:String)->void:
	var cyan:=Color("#40cfff")
	var violet:=Color("#5969ed")
	var gold:=Color("#ffe96b")
	var white:=Color("#fffef2")
	var center:=Vector2(24,24)
	var paths:Array=[]
	if role=="electric_contact" or role=="electric_area":
		var rays:int=5 if role=="electric_contact" else 8
		for i in range(rays):
			var angle:float=float(i)*TAU/rays+float(frame%3)*.17
			var path:Array=[center]
			for j in range(1,5):
				var length:float=float(j)*(3.0 if role=="electric_contact" else 4.8)
				var tangent:=Vector2(-sin(angle),cos(angle))*float(posmod(i*13+j*17+frame*11,9)-4)
				path.append(center+Vector2(cos(angle),sin(angle))*length+tangent)
			paths.append(path)
	else:
		var path:Array=[Vector2(2,24)]
		for i in range(1,10):path.append(Vector2(2+i*4.7,24+float(posmod(i*19+frame*13,21)-10)))
		paths.append(path)
	for path in paths:
		for i in range(1,path.size()):
			var a:Vector2=path[i-1];var b:Vector2=path[i]
			fx_line(im,a,b,3.0,Color(violet,.45))
			fx_line(im,a,b,1.8,cyan)
			fx_line(im,a,b,.95,gold)
			fx_line(im,a,b,.48,white)
			if i%2==0:
				var fork:=b+Vector2(float(posmod(frame+i*5,13)-6),-8.0 if i%4==0 else 8.0)
				var bend:=b.lerp(fork,.5)+Vector2(3,-2)
				fx_line(im,b,bend,1.1,cyan);fx_line(im,bend,fork,.6,white)
				fx_disc(im,fork,1.0,gold)
	if role!="electric_arc":fx_disc(im,center,2.0+float(frame%3),white)
# Connected world-space ribbons: jitter is deterministic and changes at 24 Hz.
func arc_segment(a:Vector3,b:Vector3,width:float,col:Color)->void:
	var direction:=b-a
	if direction.length_squared()<.000001:return
	var side:=direction.cross(Vector3(0,.8,.6)).normalized()*width
	if side.length_squared()<.000001:side=Vector3.RIGHT*width
	for q in [a-side,a+side,b+side,a-side,b+side,b-side]:
		fx_arc_mesh.surface_set_color(col);fx_arc_mesh.surface_add_vertex(q)
	fx_arc_segments+=1
func electric_world_arc(points:Array,t:float,role:String,tiles:Array)->void:
	var frame:int=int(t*36.0)
	var paths:Array=[]
	if role=="electric_area":
		for tile in tiles:
			var target:Vector3=tile
			paths.append([points[0],target+Vector3(0,.4,0)])
	elif role=="electric_contact":
		paths.append([points[0],points[-1]])
		for i in range(5):
			var angle:float=float(i)*TAU/5.0+float(frame%3)*.2
			paths.append([points[-1],points[-1]+Vector3(cos(angle)*.55,sin(angle)*.38,sin(angle)*.44)])
	else:paths.append(points)
	for path in paths:
		for k in range(path.size()-1):
			var start:Vector3=path[k];var end:Vector3=path[k+1]
			var last:=start
			var side:Vector3=(end-start).cross(Vector3.UP).normalized()
			for j in range(1,10):
				if fx_arc_segments>=1000:return
				var f:float=float(j)/9.0
				var q:=start.lerp(end,f)
				if j<9:q+=side*float(posmod(j*19+k*7+frame*13,19)-9)*.038+Vector3.UP*float(posmod(j*11+frame*7,17)-8)*.045
				arc_segment(last,q,.072,Color(.18,.47,1.0,.36))
				arc_segment(last,q,.035,Color("#4edbff"))
				arc_segment(last,q,.016,Color("#fffbd3"))
				if j%3==0 and j<9:
					var sign_side:float=1.0 if posmod(j+k+frame,2)==0 else -1.0
					var fork:=q+side*sign_side*.18+Vector3.UP*.13+(end-start)*.12
					var tip:=fork+side*sign_side*.16-Vector3.UP*.07+(end-start)*.08
					arc_segment(q,fork,.021,Color("#65dfff"));arc_segment(q,fork,.009,Color.WHITE)
					arc_segment(fork,tip,.011,Color("#a8f2ff"))
				last=q
# Original synthesis; no game audio is copied. Each move ID, phase and variant
# determines a distinct waveform. A 12-voice positional pool avoids allocations.
func combat_sound(id:String,phase:String,variant:int)->AudioStreamWAV:
	var key:=id+":"+phase+":"+str(variant)
	if fx_audio_cache.has(key):return fx_audio_cache[key]
	var profile:=combat_profile(id)
	var element:String=profile.element
	var role:String=profile.role
	var seed_value:int=posmod(hash(key),2147483647)
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var duration:float=.19 if phase=="impact" else minf(.42,float(profile.duration)*.62)
	if role=="ground":duration+=.11
	var rate:int=22050
	var samples:int=int(duration*rate)
	var data:=PackedByteArray();data.resize(samples*2)
	var last_noise:float=0.0
	var pitch:float=1.0+float(seed_value%23-11)*.012+float(variant-1)*.06
	for i in range(samples):
		var t:float=float(i)/rate;var p:float=float(i)/samples
		var noise:float=rng.randf_range(-1.0,1.0)
		last_noise=lerpf(last_noise,noise,.18)
		var envelope:float=minf(1.0,p*22.0)*pow(1.0-p,1.7)
		var wave:float=0.0
		match element:
			"electric":
				var gate:float=.30+.70*float(posmod(int(t*170.0)+seed_value%13,5)<3)
				wave=(noise*.47+sin(TAU*pitch*(210.0*t+3500.0*t*t))*.31+sin(TAU*1220.0*t*pitch)*.17)*gate
			"water":
				wave=sin(TAU*pitch*(310.0*t+720.0*t*t)+sin(TAU*37.0*t)*2.5)*.48+last_noise*.23
				wave*=.45+.55*absf(sin(TAU*13.0*t))
			"fire":
				wave=last_noise*.85+noise*.19+sin(TAU*78.0*t*pitch)*.14
				wave*=.65+.35*absf(sin(t*TAU*19.0))
			"grass","bug":
				wave=(noise-last_noise)*.43+sin(TAU*pitch*(680.0*t-620.0*t*t))*.22
			"ground","rock","steel":
				wave=sin(TAU*pitch*(94.0*t-85.0*t*t))*.62+last_noise*.55
				if element=="steel":wave+=sin(TAU*1080.0*t*pitch)*.24
			"ice":
				wave=sin(TAU*1480.0*t*pitch)*.26+sin(TAU*2230.0*t)*.17+noise*.27
			"psychic","fairy","ghost","dragon","dark":
				wave=sin(TAU*pitch*(420.0*t+120.0*t*t)+sin(TAU*21.0*t)*1.8)*.40+sin(TAU*880.0*t*pitch)*.18+last_noise*.14
			"poison":
				wave=sin(TAU*pitch*(170.0*t+300.0*t*t)+sin(TAU*33.0*t)*3.0)*.42+last_noise*.33
			_:
				wave=last_noise*.53+sin(TAU*pitch*(185.0*t-155.0*t*t))*.43
		if phase=="impact":wave=wave*.68+sin(TAU*95.0*t*pitch)*.24+noise*.15
		var pcm:int=roundi(clampf(wave*envelope*.72,-.95,.95)*32767.0)
		data.encode_s16(i*2,pcm)
	var audio:=AudioStreamWAV.new();audio.format=AudioStreamWAV.FORMAT_16_BITS;audio.mix_rate=rate;audio.stereo=false;audio.data=data
	if fx_audio_cache.size()>=192:fx_audio_cache.erase(fx_audio_cache.keys()[0])
	fx_audio_cache[key]=audio
	return audio
func play_combat_sound(id:String,phase:String,at:Vector3)->void:
	if fx_audio.is_empty():return
	var key:=id+":"+phase
	var variant:int=posmod(int(fx_audio_counter.get(key,-1))+1,3)
	fx_audio_counter[key]=variant
	var player_audio:=fx_audio[fx_audio_cursor];fx_audio_cursor=posmod(fx_audio_cursor+1,fx_audio.size())
	player_audio.stop();player_audio.position=at;player_audio.stream=combat_sound(id,phase,variant);player_audio.play()
func combat_fx_spawn(event:Dictionary)->void:
	if not is_instance_valid(combat_fx_root):return
	var id:String=str(event.get("fx","basic_strike"))
	var style:Array=combat_style(id)
	var profile:=combat_profile(id)
	var source:Vector2i=event.get("from",Vector2i.ZERO)
	var target:Vector2i=event.get("to",source)
	var height:float=.13 if profile.socket=="ground" else .66 if profile.socket=="head" else .45
	var waypoints:Array=[pos(source)+Vector3(0,height,0)]
	for cell in event.get("path",[target]):waypoints.append(pos(cell)+Vector3(0,.45,0))
	if waypoints.size()<2:waypoints.append(pos(target)+Vector3(0,.45,0))
	var tiles:Array=[]
	for cell in event.get("tiles",[target]):tiles.append(pos(cell)+Vector3(0,.12,0))
	if tiles.is_empty():tiles.append(pos(target)+Vector3(0,.12,0))
	if combat_bursts.size()>=10:combat_bursts.pop_front()
	combat_bursts.append({"id":id,"mode":style[0],"profile":profile,"target_player":event.get("target_player",false),"damage":event.get("damage",0),"impacted":false,"age":0.0,"duration":float(style[3]),"points":waypoints,"tiles":tiles,"texture":combat_animated_texture(id,0)})
	play_combat_sound(id,"launch",waypoints[0])
func combat_path_sample(points:Array,t:float)->Vector3:
	var index:float=clampf(t,0.0,.9999)*float(points.size()-1)
	var a:int=floori(index)
	var start:Vector3=points[a]
	return start.lerp(points[a+1],index-float(a))
# World-space anatomy of a lash: one continuous extending/retracting stem, not
# repeated thumbnail sprites. Leaves and tendrils follow the actual curve.
func vine_world_lash(points:Array,t:float,profile:Dictionary,id:String)->void:
	var style:Array=combat_style(id)
	var light:=Color(style[1]);var dark:=Color(style[2]);var outline:=dark.darkened(.55)
	var reach:float=clampf(t/.46,0.0,1.0) if t<.62 else clampf((1.0-t)/.38,0.0,1.0)
	var last:Vector3=points[0]
	var steps:int=mini(42,maxi(12,points.size()*9))
	for j in range(1,steps+1):
		if fx_arc_segments>1000:return
		var f:float=float(j)/steps
		var q:=combat_path_sample(points,f*reach)
		var next:=combat_path_sample(points,minf(1.0,f*reach+.025))
		var lateral:Vector3=(next-last).cross(Vector3.UP).normalized()
		q+=lateral*sin(f*TAU*1.2-t*8.0)*.14*f*reach
		q.y+=sin(f*PI)*.25*reach
		var width:float=lerpf(.095,.026,f)
		arc_segment(last,q,width,outline)
		arc_segment(last,q,width*.70,dark)
		arc_segment(last+Vector3.UP*.018,q+Vector3.UP*.018,width*.25,light)
		if j%6==0 and profile.element=="grass":
			var leaf:=q+lateral*(.16 if j%12==0 else -.16)+Vector3.UP*.10
			arc_segment(q,leaf,.055,dark);arc_segment(q,leaf,.023,light)
		last=q
# Ground cracks stay flush with the tile surface. Debris sprites are independent.
func quake_world_tiles(tiles:Array,t:float,id:String)->void:
	var style:Array=combat_style(id)
	var light:=Color(style[1]);var dark:=Color(style[2])
	var growth:float=clampf(t*2.0,0.0,1.0)
	for center_value in tiles:
		var center:Vector3=center_value
		center.y=.035
		for i in range(5):
			if fx_arc_segments>1000:return
			var angle:float=float(i)*TAU/5.0+float(posmod(hash(str(center)),17))*.12
			var direction:=Vector3(cos(angle),0,sin(angle))
			var bend:=center+direction*.32*growth+Vector3(-direction.z,0,direction.x)*.12*growth
			var tip:=center+direction*.61*growth
			arc_segment(center,bend,.047,dark.darkened(.65))
			arc_segment(bend,tip,.035,dark.darkened(.65))
			arc_segment(bend+Vector3.UP*.009,tip+Vector3.UP*.009,.011,light)
func queue_enemy_reaction(actor:Node3D,defeated:bool,delay:float)->void:
	if not is_instance_valid(actor):return
	actor.set_meta("pending_impact",true)
	fx_reactions.append({"actor":actor,"delay":delay,"defeated":defeated})
func update_combat_reactions(dt:float)->void:
	for i in range(fx_reactions.size()-1,-1,-1):
		var reaction:Dictionary=fx_reactions[i]
		reaction.delay-=dt
		if float(reaction.delay)>0.0:continue
		var actor:Node3D=reaction.actor
		if is_instance_valid(actor):
			actor.set_meta("pending_impact",false)
			enemy_pose(actor,"defeat" if reaction.defeated else "hurt",.32 if reaction.defeated else .20)
			if reaction.defeated:
				actor.get_node("HP").hide();actor.get_node("Warning").hide()
		fx_reactions.remove_at(i)
func combat_fx_update(dt:float)->void:
	var used:int=0
	update_combat_reactions(dt)
	fx_ground_shake=maxf(0.0,fx_ground_shake-dt*3.0)
	fx_arc_segments=0
	if is_instance_valid(fx_arc_mesh):fx_arc_mesh.clear_surfaces()
	var arcs_started:bool=false
	for k in range(combat_bursts.size()-1,-1,-1):
		var burst:Dictionary=combat_bursts[k]
		burst.age+=dt
		var t:float=float(burst.age)/float(burst.duration)
		var profile:Dictionary=burst.profile
		if not burst.impacted and t>=float(profile.impact):
			burst.impacted=true;play_combat_sound(str(burst.id),"impact",burst.points[-1])
			if str(profile.role)=="ground":fx_ground_shake=.22
			if burst.get("target_player",false) and int(burst.get("damage",0))>0:hit_time=.24
		if t>=1.0:
			combat_bursts.remove_at(k);continue
		var mode:String=burst.mode
		var frame:int=clampi(int(t*FX_FRAME_COUNT),0,FX_FRAME_COUNT-1)
		var animated:=combat_animated_texture(str(burst.id),frame)
		var points:Array=burst.points
		var tiles:Array=burst.tiles
		if str(profile.role).begins_with("electric") and t>.08 and t<.91:
			if not arcs_started:fx_arc_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,fx_arc_material);arcs_started=true
			electric_world_arc(points,t,str(profile.role),tiles)
		elif str(profile.role) in ["lash","ground"] and t>.03:
			if not arcs_started:fx_arc_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,fx_arc_material);arcs_started=true
			if profile.role=="lash":vine_world_lash(points,t,profile,str(burst.id))
			else:quake_world_tiles(tiles,t,str(burst.id))
		var count:int=mini(26,6+tiles.size()*2) if mode in ["cloud","wave","fan","web","shards","beam"] else 14
		if mode in ["flame","whip"]:count=22
		if str(profile.role).begins_with("electric"):count=4
		if profile.role=="lash":count=3
		if profile.role=="ground":count=mini(18,tiles.size()*3)
		for j in range(count):
			if used>=combat_particles.size():break
			var particle:=combat_particles[used];used+=1
			var f:float=float(j)/maxi(1,count-1)
			var angle:float=f*TAU+float(j)*2.399
			var q:Vector3
			var size:float=.55
			match str(profile.mode):
				"vine","whip":
					q=combat_path_sample(points,minf(1.0,t*2.2));q.y+=.15*sin(angle);size=.22
				"quake":
					q=tiles[j%tiles.size()];q+=Vector3(cos(angle)*t*.32,sin(t*PI)*.65,sin(angle)*t*.32);size=.29
				"lightning","beam","radiant":
					var reach:float=minf(1.0,t*3.5)
					q=combat_path_sample(points,f*reach)
					q.y+=sin(f*PI*4.0-t*14.0)*(.10 if mode=="beam" else .24)
					size=.48 if mode!="beam" else .78
				"flame","fire_stream":
					var travel:float=clampf(t*1.8-f*.65,0.0,1.0)
					q=combat_path_sample(points,travel)
					q+=Vector3(cos(angle)*travel*.20,sin(angle+t*7.0)*travel*.22, sin(angle)*travel*.20)
					size=.45+travel*.70
				"dart","bubble","bubble_beam","roll","spiral","meteor","leap":
					var travel:float=clampf(t*1.8-f*.5,0.0,1.0)
					q=combat_path_sample(points,travel)
					if mode in ["meteor","leap"]:q.y+=sin(travel*PI)*(.85 if mode=="meteor" else .55)
					if mode=="spiral":q+=Vector3(cos(angle+t*12.0)*.20,sin(angle+t*12.0)*.30,sin(angle+t*12.0)*.20)
					if str(profile.mode) in ["bubble","bubble_beam"]:q.y+=f*.3
					size=.9 if j==0 else .40+f*.25
				"slash":
					q=points[-1]
					q+=Vector3(cos(angle)*.48*sin(t*PI),sin(angle)*.27,sin(angle)*.48*sin(t*PI))
					size=.65
				_:
					q=tiles[j%tiles.size()]
					var radius:float=.12+t*.48
					q+=Vector3(cos(angle)*radius,.18+sin(t*PI)*(.5 if mode=="cloud" else .2),sin(angle)*radius)
					size=.65 if mode!="web" else .85
			# Drained energy travels from victim back to caster; healing stays on caster.
			if profile.role=="drain" and t>=.40:
				var back:float=clampf((t-.40)*2.0-f*.22,0.0,1.0)
				q=combat_path_sample(points,1.0-back)+Vector3(cos(angle)*.10,.15+sin(back*PI)*.35,sin(angle)*.10)
				size=.32+f*.18
			elif profile.role=="heal":
				var radius:float=.12+sin(t*PI)*.38
				q=points[0]+Vector3(cos(angle)*radius,.12+t*.65,sin(angle)*radius)
				size=.36
			particle.position=q
			particle.texture=animated
			particle.scale=Vector3.ONE*size*(1.0-t*.38)*.40
			particle.modulate=Color(1,1,1,clampf((1.0-t)*3.5,0.0,1.0))
			particle.show()
	if arcs_started:fx_arc_mesh.surface_end()
	for j in range(used,combat_particles.size()):combat_particles[j].hide()
func combat_update_warnings()->void:
	var used:int=0
	for enemy in run.enemies:
		if not run.revealed.has(enemy.pos):continue
		for q in run.warning_tiles(enemy):
			if used>=combat_warnings.size():break
			combat_warnings[used].position=pos(q)+Vector3(0,.045,0)
			combat_warnings[used].show();used+=1
	for j in range(used,combat_warnings.size()):combat_warnings[j].hide()
func consume_enemy_actions()->void:
	if enemy_event_floor==run.floor_revision and enemy_event_turn==run.turns:return
	enemy_event_floor=run.floor_revision;enemy_event_turn=run.turns
	for event in run.enemy_actions:
		var key:="enemy:"+str(event.uid)
		if not actor_nodes.has(key):continue
		var actor:Node3D=actor_nodes[key]
		var direction:=Vector2(event.get("aim",event.to-event.from))
		match str(event.phase):
			"attack":
				var profile:=combat_profile(str(event.get("fx","basic_strike")))
				enemy_pose(actor,"attack",float(profile.duration),direction)
				event["target_player"]=true
				combat_fx_spawn(event)
			"windup":enemy_pose(actor,"windup",.18,direction)
			"cancel":enemy_pose(actor,"idle",0.0,direction)
			"move":
				if actor.has_meta("species"):
					actor.set_meta("enemy_facing",PixelArt.direction_for(direction,int(actor.get_meta("enemy_facing",0))))
func refresh_actors():
	var desired:Dictionary={}
	for p in run.loot:
		if not run.revealed.has(p):continue
		var key="loot:"+str(p);desired[key]=true
		if actor_nodes.has(key):continue
		var root=actor_for(key,pos(p))
		var kind:String=run.loot[p]
		var c=Color("#ffd277") if kind=="coin" else Color("#f2a8c0") if kind=="potion" else Color("#76ffdc") if kind=="spring" else palette[3]
		if kind=="spring":
			if prop(root,"dungeon_spring",Vector3.ZERO)!=null:continue
			shape(root,"ring",Vector3(0,.06,0),Vector3(.66,.13,.66),c);shape(root,"orb",Vector3(0,.24,0),Vector3(.62,.29,.62),c);continue
		if kind=="relic" and prop(root,"dungeon_chest",Vector3.ZERO)!=null:continue
		if kind=="coin" and prop(root,"dungeon_coin",Vector3.ZERO)!=null:
			root.set_meta("float_item",true);continue
		if kind=="potion" and prop(root,"dungeon_berry",Vector3(0,.12,0))!=null:
			root.set_meta("float_item",true);continue
		if kind=="material" and prop(root,"dungeon_material",Vector3(0,.12,0))!=null:
			root.set_meta("float_item",true);continue
		var item=shape(root,"gem",Vector3(0,.36,0),Vector3(.38,.6,.38),c);item.rotation.y=.7
		root.set_meta("float_item",true)
	for i in range(run.enemies.size()):
		var enemy:Dictionary=run.enemies[i]
		var p:Vector2i=enemy.pos
		if not run.revealed.has(p):continue
		var key="enemy:"+str(enemy.get("uid",i));desired[key]=true
		var kind:int=enemy.kind
		var root=actor_for(key,pos(p))
		root.set_meta("target",pos(p))
		if root.get_child_count()==0:
			if not attach_enemy_pixel(root,str(enemy.get("species",""))):
				# Explicit fallback for species that have not been authored yet.
				var ob=shape(root,"gem",Vector3(0,.6,0),Vector3(.62,1.15,.62),Data.TINTS[region].darkened(.25));ob.rotation.y=PI*.25
				shape(root,"orb",Vector3(0,.83,.36),Vector3(.18,.18,.12),Color("#ffb776"))
				if kind==3:ob.scale*=1.45
			var height=1.9 if kind==3 else 1.42
			shape(root,"box",Vector3(0,height,0),Vector3(.75,.09,.12),Color("#212835"))
			var bar=shape(root,"box",Vector3(0,height+.015,.012),Vector3(.72,.075,.13),Color("#ee7c83"));bar.name="HP"
			var marker=shape(root,"ring",Vector3(0,.06,0),Vector3(.74,.12,.74),Color("#ffb25d"));marker.name="Warning"
		if int(enemy.hp)<int(root.get_meta("enemy_hp",enemy.hp)):
			var profile:=combat_profile(run.player_attack_fx)
			queue_enemy_reaction(root,false,float(profile.duration)*float(profile.impact))
		root.set_meta("enemy_hp",int(enemy.hp))
		var bar=root.get_node("HP") as Node3D
		bar.scale.x=.72*clampf(float(enemy.hp)/float(enemy.get("max_hp",enemy.hp)),0,1)
		root.get_node("Warning").visible=enemy.get("windup",false)
		var status_label:=root.get_node_or_null("Status") as Label3D
		if status_label==null:
			status_label=Label3D.new();status_label.name="Status";status_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
			status_label.font_size=28;status_label.outline_size=6;status_label.pixel_size=.006
			status_label.position=Vector3(0,2.15 if kind==3 else 1.68,0);root.add_child(status_label)
		status_label.text=run.enemy_status_text(enemy);status_label.visible=not status_label.text.is_empty()
	for p in run.traps:
		if not run.revealed.has(p):continue
		var key="trap:"+str(p);desired[key]=true
		if not actor_nodes.has(key):shape(actor_for(key,pos(p)),"ring",Vector3(0,.04,0),Vector3(.5,.06,.5),Color("#b9788b"))
	if run.revealed.has(run.stairs):
		var key="stairs";desired[key]=true
		if not actor_nodes.has(key):
			var root=actor_for(key,pos(run.stairs))
			if prop(root,"dungeon_stairs",Vector3.ZERO)==null:
				for i in range(3):shape(root,"box",Vector3(0,.08+float(i)*.12,float(i)*.20-.2),Vector3(.95,.16,.32),palette[2])
			var glow=shape(root,"ring",Vector3(0,.08,0),Vector3(.7,.12,.7),Color("#e9d28c"));glow.name="Ready"
		actor_nodes[key].get_node("Ready").visible=run.secured
	for key in actor_nodes.keys():
		if not desired.has(key):
			var n:Node3D=actor_nodes[key]
			if n.has_meta("species") and key.begins_with("enemy:"):
				# Only retain an actual defeated enemy, not an actor leaving visibility.
				var still_alive:=false
				for enemy in run.enemies:
					if key=="enemy:"+str(enemy.get("uid",-1)):still_alive=true;break
				if not still_alive:
					if str(n.get_meta("enemy_phase"))!="defeat" and not n.get_meta("pending_impact",false):
						var profile:=combat_profile(run.player_attack_fx)
						queue_enemy_reaction(n,true,float(profile.duration)*float(profile.impact))
					continue
			n.hide();n.queue_free();actor_nodes.erase(key)
	consume_enemy_actions()
	combat_update_warnings()
func toggle_map():
	map_expanded=not map_expanded
	var width=minf(area.size.x-20,300) if map_expanded else 146.0
	var height=minf(area.size.y*.46,260) if map_expanded else 112.0
	map.size=Vector2(width,height)
	map_zoom.position=map.position+Vector2(map.size.x-37,5)
	map_zoom.text="−" if map_expanded else "+"
	map_zoom.tooltip_text="Collapse explored map" if map_expanded else "Expand explored map"
	map.queue_redraw()
func draw_map():
	map.draw_style_box(style(Color("#102637ee"),Color("#dfc084"),15),Rect2(Vector2.ZERO,map.size))
	var extent=Vector2i.ONE
	for p in run.cells:extent=Vector2i(maxi(extent.x,p.x+1),maxi(extent.y,p.y+1))
	var unit=minf((map.size.x-20.0)/extent.x,(map.size.y-44.0)/extent.y)
	var offset=(map.size-Vector2(extent)*unit)*.5+Vector2(0,10)
	for p in run.revealed:
		map.draw_rect(Rect2(Vector2(p)*unit+offset,Vector2.ONE*maxf(1.0,unit-.7)),Color("#759b9f"))
	for p in run.loot:
		if run.revealed.has(p):map.draw_circle((Vector2(p)+Vector2(.5,.5))*unit+offset,maxf(1.0,unit*.24),Color("#ffcf72"))
	for enemy in run.enemies:
		if run.revealed.has(enemy.pos):map.draw_circle((Vector2(enemy.pos)+Vector2(.5,.5))*unit+offset,maxf(1.2,unit*.3),Color("#f58b90"))
	if run.revealed.has(run.stairs):map.draw_rect(Rect2(Vector2(run.stairs)*unit+offset,Vector2.ONE*unit),Color("#f8d18b"))
	var player_point=(Vector2(run.player)+Vector2(.5,.5))*unit+offset
	map.draw_circle(player_point,maxf(4.0,unit*.85),Color("#73e4cc55"))
	map.draw_circle(player_point,maxf(2.0,unit*.5),Color("#d5fff0"))
func rotate_combat_aim()->void:
	path.clear()
	facing=Rules.DIR[posmod(Rules.DIR.find(facing)+1,4)]
	update_hud()
func touch(event:InputEvent):
	if notified or run.finished:return
	if map_expanded and (event is InputEventScreenTouch or event is InputEventMouseButton):
		if Rect2(map.position,map.size).has_point(event.position):return
	if event is InputEventScreenTouch and event.index!=0:return
	if not ((event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and event.device!=-1)):return
	if area.size.x<=0 or viewport.size.x<=0:return
	var screen=event.position*Vector2(viewport.size)/area.size
	var origin=camera.project_ray_origin(screen);var ray=camera.project_ray_normal(screen)
	if absf(ray.y)<.001:return
	var hit=origin+ray*(-origin.y/ray.y)
	var target=Vector2i(roundi(hit.x/1.4),roundi(hit.z/1.4))
	if target==run.player:return
	if run.enemy_at(target)>=0 and run.revealed.has(target):
		var delta:Vector2i=target-run.player
		facing=Vector2i(signi(delta.x),0) if absi(delta.x)>absi(delta.y) else Vector2i(0,signi(delta.y))
		path.clear()
		if run.distance(run.player,target)==1:run.attack(false,facing)
		sync();return
	path=run.route(run.player,target,true)
	tick=0.0
func sync():
	if run.floor_revision!=active_floor:build_floor()
	else:refresh_actors()
	update_hud()
	if run.attack_serial!=previous_attack:
		previous_attack=run.attack_serial
		var profile:=combat_profile(run.player_attack_fx)
		player_cast_duration=float(profile.duration);player_cast_mode=str(profile.role);attack_time=player_cast_duration
		player_impact_delay=player_cast_duration*float(profile.impact)
		attack_direction=(pos(run.attack_target)-pos(run.player)).normalized()
		attack_fx.position=pos(run.attack_target)+Vector3(0,.24,0);attack_fx.show()
		combat_fx_spawn({"fx":run.player_attack_fx,"from":run.player,"to":run.attack_target,"tiles":run.player_attack_cells,"path":run.player_attack_path})
	if run.hp<hp_previous and run.enemy_actions.is_empty():hit_time=.24
	hp_previous=run.hp
	if previous_event!=run.event_serial:
		previous_event=run.event_serial;feedback.text=run.last_event;feedback_time=1.0;feedback.show()
		feedback.size=Vector2(area.size.x,42);feedback.position=Vector2(0,area.size.y*.29)
		if run.last_event.begins_with("+") or run.last_event.contains("defeated") or run.last_event.contains("secured") or run.last_event.contains("berry"):
			reward_age=.65;reward_fx.position=pos(run.player);reward_fx.show()
	if run.finished and not notified:
		notified=true
		# Deferred settlement prevents destroying/rebuilding the UI inside a button callback.
		call_deferred("emit_result")
func emit_result():
	ended.emit(run.success,run.floor_count if run.success else run.floor_number-1,maxf(2.0,elapsed))
func update_hud():
	title_text.text="%s  ·  B%d/%d"%[Data.REGIONS[region],run.floor_number,run.floor_count]
	hp_bar.value=run.hp
	hp_text.text="HP %d/%d"%[run.hp,run.max_hp]
	floor_label.text="%d/%d rooms"%[run.explored_rooms.size(),run.rooms.size()]
	stats.text=str(run.coins)
	relic_text.text="%d/%d"%[1 if run.secured else 0,1]
	hp_bar.modulate=Color("#ff9b9b") if run.hp*3<run.max_hp else Color.WHITE
	status_text.text=run.message if run.charged_move_id.is_empty() else str(Rules.MOVE_LIBRARY[run.charged_move_id].name)+" · Ready to release"
	var stage_text:String=run.stage_summary(run.player_stages,run.player_halves)
	if not stage_text.is_empty():status_text.text+=" · "+stage_text
	if run.travel_speed()>1:status_text.text+=" · MOVE ×%d"%run.travel_speed()
	if run.shield_turns>0:status_text.text+=" · "+run.shield_kind.capitalize()+" "+str(run.shield_turns)
	var boon_text:String=run.boon_summary()
	if not boon_text.is_empty():status_text.text+=" · "+boon_text
	var weather_text:String=run.weather_summary()
	if not weather_text.is_empty():status_text.text+=" · "+weather_text
	if is_instance_valid(aim_button):aim_button.text="Aim "+["↑","→","↓","←"][maxi(0,Rules.DIR.find(facing))]
	if is_instance_valid(special_button):special_button.disabled=run.energy<2
	for i in range(move_buttons.size()):
		var id:String=run.equipped_moves[i]
		var move:Dictionary=Rules.MOVE_LIBRARY[id]
		move_buttons[i].text="%s · %d/%d"%[move.name,run.move_pp[id],move.pp]
		if id==run.charged_move_id:move_buttons[i].text="Release "+str(move.name)
		move_buttons[i].disabled=not run.charged_move_id.is_empty() and id!=run.charged_move_id or (run.charged_move_id.is_empty() and int(run.move_pp[id])<=0)
	power_button.text="%s %d/8"%[["Burst","Bolt","Drain"][run.skill_kind],run.energy];power_button.disabled=run.energy<2
	heal_button.text="Berry ×%d"%run.potions;heal_button.disabled=run.potions==0 or run.hp==run.max_hp
	stairs_button.text="Descend ›" if run.floor_number<run.floor_count else "Complete expedition"
	stairs_button.disabled=not run.secured or run.player!=run.stairs
	stairs_button.visible=run.secured and run.player==run.stairs
	map.queue_redraw()
func _process(dt:float):
	if notified or not is_instance_valid(pet):return
	elapsed+=dt;tick-=dt
	combat_fx_update(dt)
	update_living_ambient(dt)
	update_exterior_world(dt)
	if reward_age>0.0:
		reward_age=maxf(0.0,reward_age-dt)
		var progress=1.0-reward_age/.65
		for i in range(reward_pool.size()):
			var angle=float(i)*TAU/reward_pool.size()+progress*.6
			var radius=.25+progress*.9
			reward_pool[i].position=Vector3(cos(angle)*radius,.22+sin(progress*PI)*.9,sin(angle)*radius)
			reward_pool[i].scale=Vector3(.065,.15,.065)*(1.0-progress*.85)
		reward_fx.visible=reward_age>0.0
	banner_time=maxf(0.0,banner_time-dt)
	floor_banner.visible=banner_time>0.0
	if floor_banner.visible:
		floor_banner.size=Vector2(area.size.x,45);floor_banner.position=Vector2(0,area.size.y*.12);floor_banner.modulate.a=minf(1.0,banner_time*3.0)
	feedback_time=maxf(0.0,feedback_time-dt)
	feedback.visible=feedback_time>0.0
	if feedback.visible:
		feedback.size=Vector2(area.size.x,42);feedback.position=Vector2(0,area.size.y*.29-(1.0-feedback_time)*24.0);feedback.modulate.a=minf(1.0,feedback_time*4.0)
	for key in actor_nodes.keys():
		var n:Node3D=actor_nodes[key]
		if not is_instance_valid(n) or n.is_queued_for_deletion():
			actor_nodes.erase(key);continue
		if n.has_meta("target"):
			var target_position:Vector3=n.get_meta("target")
			var delta_position:=target_position-n.position
			n.position=n.position.lerp(target_position,1.0-exp(-dt*15.0))
			update_enemy_pixel(n,dt,delta_position)
		elif n.has_meta("float_item"):
			n.position.y=.12+.07*sin(elapsed*4.0+n.position.x);n.rotation.y=elapsed*1.8
	if tick<=0 and not path.is_empty() and not run.finished:
		var next:Vector2i=path.pop_front()
		facing=next-run.player
		var before=run.player
		var damage_before:int=run.hits
		if run.move(next):
			if before!=run.player:
				emit_trail(before,run.player-before)
				update_room_lights()
			if before==run.player or run.hits>damage_before:path.clear()
			sync()
		else:path.clear()
		tick=.16
	var target=pos(run.player)
	var travel:Vector3=target-pet.position
	pet.position=pet.position.lerp(target,1.0-exp(-dt*18.0))
	destination_fx.visible=not path.is_empty()
	if destination_fx.visible:destination_fx.position=pos(path[-1])+Vector3(0,.06,0)
	attack_time=maxf(0.0,attack_time-dt);hit_time=maxf(0.0,hit_time-dt)
	player_impact_delay=maxf(0.0,player_impact_delay-dt)
	var moving:bool=travel.length()>.045
	var motion:=Vector2(travel.x,travel.z) if moving else Vector2(facing)
	pet_pose.position=Vector3.ZERO
	pet_pose.rotation.z=0.0
	pet_pose.visible=not run.charge_phase in ["underground","vanish"]
	if run.charge_phase=="airborne":pet_pose.position.y=.95+sin(elapsed*8.0)*.06
	elif run.charge_phase=="gather":pet_pose.position.y=.03+.04*sin(elapsed*12.0)
	if attack_time>0.0:
		var phase=sin(PI*attack_time/maxf(.01,player_cast_duration))
		var lunge:float=.40 if player_cast_mode in ["contact","electric_contact"] else .13 if player_cast_mode=="lash" else -.08
		pet_pose.position+=pet.basis.inverse()*attack_direction*phase*lunge
		attack_fx.visible=player_impact_delay<=0.0;attack_fx.scale=Vector3(1.1-phase*.42,.13,1.1-phase*.42)
	else:attack_fx.hide()
	if hit_time>0.0:pet_pose.rotation.z+=sin(hit_time*45.0)*.10
	if attack_time>0.0:motion=Vector2(attack_direction.x,attack_direction.z)
	var pose:String="hurt" if hit_time>0.0 else "attack" if attack_time>0.0 else "reward" if reward_age>0.0 and not moving else "idle"
	pet_pose.set_meta("pet_mood","weak" if run.hp*3<run.max_hp else "healthy")
	PixelArt.animate_world_sprite(pet_pose,motion,moving,dt,pose,region==1)
	var focus=pet.position+Vector3(0,.18,-.48)
	camera.position=focus+DUNGEON_CAMERA_OFFSET;camera.look_at(focus)
