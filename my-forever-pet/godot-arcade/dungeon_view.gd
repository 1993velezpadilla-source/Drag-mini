extends Control
const PixelArt=preload("res://pixel_pet_art.gd")
const Rules=preload("res://dungeon_rules.gd")
const Data=preload("res://research_data.gd")
signal ended(success:bool,completed:int,elapsed:float)
signal canceled
var run=Rules.new()
# Internal combat laboratory. No developer controls are instantiated in public release builds.
const DEV_PAGE_SIZE:int=4
var dungeon_footer:PanelContainer
var hold_info:RichTextLabel
var hold_action:Callable
var hold_move:Dictionary={}
var hold_origin:Vector2
var hold_active:bool=false
var hold_release_pending:bool=false
var hold_visible:bool=false
var hold_age:float=0.0
var hold_is_dev:bool=false
var aim_preview:Control
var dev_settings_panel:PanelContainer
var dev_panel:PanelContainer
var dev_bubble:PanelContainer
var dev_search:LineEdit
var dev_element:OptionButton
var dev_category:OptionButton
var dev_grid:GridContainer
var dev_page_label:Label
var dev_prev:Button
var dev_next:Button
var dev_detail:RichTextLabel
var dev_browser:VBoxContainer
var dev_info_mode:bool=false
var dev_selected_label:Label
var dev_source:OptionButton
var dev_result:Label
var dev_aim:Button
var dev_fx_only:CheckButton
var dev_page:int=0
var dev_catalog:Dictionary={}
var dev_selected:String=""
var dev_dragging:bool=false
var dev_drag_moved:bool=false
var dev_drag_distance:float=0.0
var dev_drag_index:int=-1
var dev_target_uid:int=10000

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
var fx_cast_particle_limit:int=FX_PARTICLE_CAP
# Android-only automatic presentation budget; never changes simulation clocks.
var fx_performance_tier:int=0
var fx_frame_average:float=1.0/60.0
var fx_pressure_age:float=0.0
var fx_recovery_age:float=0.0
var fx_performance_grace:float=1.5
const LIVING_PARTICLE_CAP=64
const FX_WARNING_CAP=80
var combat_particles:Array[Sprite3D]=[]
var combat_warnings:Array[MeshInstance3D]=[]
const CAST_TEXT_CAP:int=16
var cast_text_pool:Array[Label3D]=[]
var cast_text_age:Array[float]=[]
var cast_text_origin:Array[Vector3]=[]
var cast_text_cursor:int=0
const RESPONSE_TEXT_CAP:int=64
var response_text_queue:Array[Dictionary]=[]
const COMBAT_BURST_CAP:int=10
const RETIRED_IMPACT_CAP:int=128
var combat_bursts:Array[Dictionary]=[]
var retired_impacts:Array[Dictionary]=[]
const DELAYED_COMBAT_FX_CAP:int=24
var delayed_combat_fx:Array[Dictionary]=[]
const FX_SECONDARY_TEXTURE_CAP:int=768
var combat_textures:Dictionary={}
var combat_texture_order:Array[String]=[]
# Keep transient animation frames separate from permanent static FX textures.
const FX_ANIMATED_CACHE_CAP=384
var fx_animated_cache:Dictionary={}
var fx_animated_order:Array[String]=[]
var fx_arc_mesh:ImmediateMesh
var fx_arc_material:StandardMaterial3D
var fx_audio:Array[AudioStreamPlayer3D]=[]
var fx_audio_cache:Dictionary={}
var fx_audio_counter:Dictionary={}
var fx_audio_cursor:int=0
var fx_arc_segments:int=0
var player_cast_duration:float=.28
var player_cast_waves:Array[float]=[]
var player_cast_mode:String="contact"
var player_cast_motion:String="contact"
var player_cast_impact:float=.48
var player_tile_cast:Dictionary={}
# Full tile movement is reserved for body-travel attacks, not ranged projectiles.
const TILE_CAST_AIR=["eos_100","eos_153","eos_205","eos_204","eos_206","eos_235","eos_158","eos_541","eos_518"]
const TILE_CAST_GROUND=["eos_052","eos_132","eos_139","eos_140","eos_154","eos_190","eos_203","eos_300","eos_348","eos_354","eos_432","eos_451","eos_455","eos_498","eos_502","eos_510","eos_517","eos_533","eos_002","eos_105"]
var player_impact_delay:float=0.0
var fx_reactions:Array[Dictionary]=[]
var fx_ground_shake:float=0.0
var fx_contact_camera:Vector3=Vector3.ZERO
var fx_contact_camera_age:float=1.0
var fx_geometry_count:int=0
const FX_FRAME_COUNT=12
const FX_FRAME_SIZE=48
var combat_fx_root:Node3D
const FX_LIGHT_CAP:int=2
const FX_HALO_CAP:int=8
var fx_lights:Array[OmniLight3D]=[]
var fx_halos:Array[MeshInstance3D]=[]
var fx_halo_materials:Array[ShaderMaterial]=[]
var cinematic_halo_shader:Shader
var fx_lights_used:int=0
var fx_light_scores:Array[float]=[]
var fx_halos_used:int=0
const FX_TRAIL_VERTEX_CAP:int=960
const FX_RESIDUE_CAP:int=6
var fx_trail_mesh:ImmediateMesh
var fx_trail_material:StandardMaterial3D
var fx_trail_vertices:int=0
var fx_trail_started:bool=false
var fx_residues:Array[Dictionary]=[]
const FX_REACTION_SPARK_CAP:int=12
var fx_reaction_sparks:Array[Dictionary]=[]
var combat_warn_mat:StandardMaterial3D
var enemy_event_turn:int=-1
var enemy_event_floor:int=-1
var feedback:Label
var feedback_time=0.0
var previous_event=0
var actor_created=0
var previous_attack=0
var attack_time=0.0
var visual_charge_phase:String=""
var release_charge_phase:String=""
var attack_direction=Vector3.ZERO
var attack_fx:MeshInstance3D
var destination_fx:MeshInstance3D
var hp_previous=0
var hit_time=0.0
var player_hit_direction:=Vector3.ZERO
var pet_pose:Node3D
var disguise_actor:Node3D
var disguise_species:String=""
var form_age:float=0.0
var form_root:Node3D
var form_sparks:Array[MeshInstance3D]=[]
var form_ring:MeshInstance3D
var form_light:OmniLight3D
var form_material:StandardMaterial3D
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
var interaction_kind:String=""
var interaction_duration:float=.65
var interaction_priority:int=0
var seen_creatures:Dictionary={}
var interaction_material:StandardMaterial3D
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
func lab_button(parent:Node,title:String,action:Callable)->Button:
	var b:=Button.new()
	b.text=title;b.custom_minimum_size.y=38;b.size_flags_horizontal=SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size",14)
	b.add_theme_stylebox_override("normal",style(Color("#213647"),Color("#456478"),9))
	b.add_theme_stylebox_override("pressed",style(Color("#365e68"),Color("#95e8cc"),9))
	b.pressed.connect(action);parent.add_child(b)
	return b

func lab_build_settings(parent:Node)->void:
	var gear:=lab_button(parent,"⚙",func():
		if is_instance_valid(dev_settings_panel):
			dev_settings_panel.visible=not dev_settings_panel.visible
			lab_layout())
	gear.tooltip_text="Dungeon settings";gear.custom_minimum_size.x=42;gear.size_flags_horizontal=SIZE_SHRINK_END

func lab_settings_overlay()->void:
	dev_settings_panel=PanelContainer.new()
	dev_settings_panel.add_theme_stylebox_override("panel",style(Color("#102739"),Color("#8baeb6"),12))
	add_child(dev_settings_panel);dev_settings_panel.z_index=20
	var stack:=VBoxContainer.new();dev_settings_panel.add_child(stack)
	label(stack,"Dungeon settings",16,Color("#c6e8dd"))
	lab_button(stack,"Map size",func():toggle_map();dev_settings_panel.hide())
	if Rules.dev_tools_available():
		lab_button(stack,"DEV · Combat Lab",lab_open)
	lab_button(stack,"Close",func():dev_settings_panel.hide())
	dev_settings_panel.hide()
	resized.connect(lab_layout)

func lab_layout()->void:
	if is_instance_valid(dev_settings_panel):
		dev_settings_panel.position=Vector2(maxf(4,size.x-220),74)
		dev_settings_panel.size=Vector2(214,0)
	if is_instance_valid(dev_bubble):
		dev_bubble.position=Vector2(clampf(dev_bubble.position.x,0,maxf(0,size.x-dev_bubble.size.x)),clampf(dev_bubble.position.y,0,maxf(0,size.y-dev_bubble.size.y)))

func lab_open()->void:
	if not run.dev_sandbox and not run.enable_dev_sandbox():return
	path.clear()
	dev_settings_panel.hide()
	if not is_instance_valid(dev_panel):lab_build_panel()
	dev_bubble.hide();dungeon_footer.hide();dev_panel.show()
	lab_layout();update_hud()

func lab_build_catalog()->void:
	dev_catalog.clear()
	for id in Rules.MOVE_LIBRARY:dev_catalog[id]=Rules.dev_move_record(id)
	for id in Rules.DEV_NATIVE_MOVES:dev_catalog[id]=Rules.dev_move_record(id)

func lab_build_panel()->void:
	lab_build_catalog()
	dev_panel=PanelContainer.new()
	dev_panel.add_theme_stylebox_override("panel",style(Color("#10232df5"),Color("#91cbb5"),16))
	hud_base.add_child(dev_panel)
	hud_base.move_child(dev_panel,dungeon_footer.get_index())
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",5);dev_panel.add_child(stack)
	var header:=HBoxContainer.new();stack.add_child(header)
	var heading:=label(header,"DEV · Combat Lab",20,Color("#aff3ce"));heading.size_flags_horizontal=SIZE_EXPAND_FILL
	var minimize:=lab_button(header,"−",lab_minimize);minimize.size_flags_horizontal=SIZE_SHRINK_END;minimize.custom_minimum_size.x=48;minimize.tooltip_text="Minimize to floating DEV bubble"
	heading.text="DEV · Combat Lab  ∞"
	dev_browser=VBoxContainer.new();dev_browser.add_theme_constant_override("separation",4);stack.add_child(dev_browser)
	dev_search=LineEdit.new();dev_search.placeholder_text="Search name, reference or ID";dev_search.custom_minimum_size.y=36;dev_browser.add_child(dev_search)
	dev_search.text_changed.connect(func(_value:String):dev_page=0;lab_refresh())
	var filters:=HBoxContainer.new();dev_browser.add_child(filters)
	dev_element=OptionButton.new();dev_element.size_flags_horizontal=SIZE_EXPAND_FILL;filters.add_child(dev_element);dev_element.add_item("All elements")
	var elements:Array=[]
	for id in dev_catalog:
		var element:String=str(dev_catalog[id].type)
		if not element in elements:elements.append(element)
	elements.sort()
	for element in elements:dev_element.add_item(str(element).capitalize())
	dev_category=OptionButton.new();dev_category.size_flags_horizontal=SIZE_EXPAND_FILL;filters.add_child(dev_category)
	for category in ["All categories","Physical","Special","Status"]:dev_category.add_item(category)
	dev_source=OptionButton.new();dev_source.size_flags_horizontal=SIZE_EXPAND_FILL;filters.add_child(dev_source)
	for source in ["All sources","EoS","Kindra"]:dev_source.add_item(source)
	dev_source.item_selected.connect(func(_index:int):dev_page=0;lab_refresh())
	dev_element.item_selected.connect(func(_index:int):dev_page=0;lab_refresh())
	dev_category.item_selected.connect(func(_index:int):dev_page=0;lab_refresh())
	dev_grid=GridContainer.new();dev_grid.columns=2;dev_grid.add_theme_constant_override("h_separation",5);dev_grid.add_theme_constant_override("v_separation",4);dev_browser.add_child(dev_grid)
	var pager:=HBoxContainer.new();dev_browser.add_child(pager)
	dev_prev=lab_button(pager,"‹ Prev",func():dev_page-=1;lab_refresh())
	dev_page_label=label(pager,"",14,Color("#d2e8e3"));dev_page_label.size_flags_horizontal=SIZE_EXPAND_FILL;dev_page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;dev_page_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	dev_next=lab_button(pager,"Next ›",func():dev_page+=1;lab_refresh())
	dev_detail=RichTextLabel.new();dev_detail.custom_minimum_size.y=96;dev_detail.scroll_active=true;dev_detail.bbcode_enabled=false;dev_detail.add_theme_font_size_override("normal_font_size",14);stack.add_child(dev_detail)
	dev_detail.text="Select a move. Hold and drag to aim.";dev_detail.hide()
	dev_selected_label=label(stack,"Select a move · tap to cast",13,Color("#c6e8dd"));dev_selected_label.clip_text=true
	var controls:=HBoxContainer.new();stack.add_child(controls)
	dev_aim=lab_button(controls,"Aim ↓",func():rotate_combat_aim();lab_update_aim())
	lab_button(controls,"Moves / Info",lab_toggle_info)
	lab_button(controls,"Target +",lab_spawn_target)
	lab_button(controls,"Next floor",func():path.clear();run.dev_next_floor();sync();dev_result.text="Endless floor B%d"%run.floor_number)
	var tools_row:=HBoxContainer.new();stack.add_child(tools_row)
	dev_fx_only=CheckButton.new();dev_fx_only.text="FX only";tools_row.add_child(dev_fx_only)
	lab_button(tools_row,"Injure",func():run.hp=maxi(1,run.max_hp/2);update_hud();dev_result.text="Healing fixture: HP at 50%")
	lab_button(tools_row,"Clear targets",func():run.enemies.clear();sync();dev_result.text="Targets cleared")
	dev_result=label(stack,"Ready · tap a move",13,Color("#a7e9bf"));dev_result.clip_text=true
	lab_button(stack,"Exit sandbox · discard rewards",leave)
	dev_bubble=PanelContainer.new()
	dev_bubble.add_theme_stylebox_override("panel",style(Color("#1c6359"),Color("#b1f5d7"),32))
	dev_bubble.custom_minimum_size=Vector2(64,64);dev_bubble.size=Vector2(64,64)
	add_child(dev_bubble);dev_bubble.z_index=25;dev_bubble.position=Vector2(maxf(0,size.x-76),maxf(0,size.y*.43))
	var bubble_label:=label(dev_bubble,"DEV",18,Color.WHITE);bubble_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;bubble_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;bubble_label.mouse_filter=MOUSE_FILTER_IGNORE
	dev_bubble.gui_input.connect(lab_bubble_input);dev_bubble.hide()
	lab_update_aim();lab_refresh()

func lab_filtered_ids()->Array[String]:
	var ids:Array[String]=[]
	var query:String=dev_search.text.strip_edges().to_lower() if is_instance_valid(dev_search) else ""
	var element:String=dev_element.get_item_text(dev_element.selected).to_lower() if is_instance_valid(dev_element) and dev_element.selected>0 else ""
	var category:String=dev_category.get_item_text(dev_category.selected).to_lower() if is_instance_valid(dev_category) and dev_category.selected>0 else ""
	for id in dev_catalog:
		var move:Dictionary=dev_catalog[id]
		if is_instance_valid(dev_source) and dev_source.selected==1 and not move.has("reference_id"):continue
		if is_instance_valid(dev_source) and dev_source.selected==2 and move.has("reference_id"):continue
		if not element.is_empty() and str(move.type)!=element:continue
		if not category.is_empty() and str(move.category)!=category:continue
		if not query.is_empty() and not query in (str(move.name)+" "+str(move.get("reference_key","")).replace("_"," ")+" "+str(id)).to_lower():continue
		ids.append(str(id))
	ids.sort_custom(func(a:String,b:String)->bool:return str(dev_catalog[a].name).naturalnocasecmp_to(str(dev_catalog[b].name))<0)
	return ids

func lab_refresh()->void:
	var ids:=lab_filtered_ids()
	var pages:int=maxi(1,ceili(float(ids.size())/DEV_PAGE_SIZE))
	dev_page=clampi(dev_page,0,pages-1)
	for child in dev_grid.get_children():
		dev_grid.remove_child(child);child.queue_free()
	for index in range(DEV_PAGE_SIZE):
		var at:int=dev_page*DEV_PAGE_SIZE+index
		if at>=ids.size():
			var spacer:=Control.new();spacer.custom_minimum_size.y=34;spacer.size_flags_horizontal=SIZE_EXPAND_FILL;dev_grid.add_child(spacer);continue
		var id:String=ids[at]
		var move:Dictionary=dev_catalog[id]
		var b:=lab_button(dev_grid,str(move.name),func():pass)
		bind_attack_gesture(b,move,lab_cast.bind(id),true)
		b.custom_minimum_size.y=34;b.clip_text=true;b.tooltip_text=str(move.name)+" · "+str(move.type).capitalize()+" · "+str(move.category).capitalize()
	dev_page_label.text="%d/%d · %d moves"%[dev_page+1,pages,ids.size()]
	dev_prev.disabled=dev_page<=0;dev_next.disabled=dev_page>=pages-1

func lab_accuracy(value:Variant)->String:
	if value==null:return "Not recorded"
	return "Bypass (%s)"%str(value) if int(value)>100 else "%d%%"%int(value)

func lab_toggle_info()->void:
	dev_info_mode=not dev_info_mode
	dev_browser.visible=not dev_info_mode
	dev_detail.custom_minimum_size.y=164 if dev_info_mode else 96
	dev_detail.visible=dev_info_mode

func lab_move_info(id:String)->String:
	var m:Dictionary=dev_catalog[id]
	var source:String="EoS reference · prototype" if m.has("reference_id") else "Kindra original"
	var pp:String="Free" if int(m.pp)==0 else str(m.pp)
	var text_value:String="%s · %s / %s\n%s\nPower %s   PP %s   Crit %s%%\nACC 1: %s   ACC 2: %s\nRange: %s · Reach %s · Hits %s\n"%[m.name,str(m.type).capitalize(),str(m.category).capitalize(),source,str(m.power),pp,str(m.reference_crit),lab_accuracy(m.acc1),lab_accuracy(m.acc2),str(m.get("reference_range",m.pattern)),str(m.reach),str(m.reference_strikes)]
	if m.has("reference_key"):text_value+="Reference: %s (#%s)\n"%[str(m.reference_key).replace("_"," "),str(m.reference_id)]
	text_value+="\nWHAT IT DOES\n"+str(m.what_it_does)+"\n\nTARGET\n"+str(m.target_rule)+"\nCONDITION\n"+str(m.condition_text)+"\n"
	if m.has("balance"):text_value+=str(m.balance)+"\n"
	text_value+="Status: "+str(m.get("inflict_status",m.get("boon_kind",m.get("shield_kind","None")))).replace("_"," ")+"\n"
	text_value+="Weather: "+("Dependent" if m.get("weather_heal",false) else str(m.get("weather_set","No explicit requirement")))+"\n"
	if int(m.power)>0:text_value+="Damage: calculated per target; actual HP loss appears after cast.\n"
	else:text_value+="Damage: no ordinary base power; see effect or fixed-damage rule below.\n"
	if m.has("heal_fraction"):text_value+="Healing: %s%% max HP\n"%str(float(m.heal_fraction)*100.0)
	if m.has("charge_phase"):text_value+="Two turns: "+str(m.charge_phase)+"; tap again to release.\n"
	if m.get("sleep_reactive",false):text_value+="Condition: triggers when attacked asleep. DEV stages a sleep + incoming-hit test with an adjacent target.\n"
	for key in ["special_rule","inflict_status","status_chance","stat_changes","stat_transfer","boon_kind","shield_kind","drain_fraction","recoil_fraction","hit_min","hit_max","weather","trap_kind","reserve_action","native_effect","effect_amount","fixed_damage","heal_fixed","weather_heal","release_multiplier","blast_radius","speed_change","reserve_attack","random_cast","charge_defense","self_confuse","memento","typeless"]:
		if m.has(key):text_value+=str(key).replace("_"," ").capitalize()+": "+str(m[key])+"\n"
	return text_value.strip_edges()

func lab_update_aim()->void:
	if is_instance_valid(dev_aim):dev_aim.text="Aim "+["↑","↗","→","↘","↓","↙","←","↖"][maxi(0,Rules.DIR8.find(facing))]

func lab_spawn_target()->void:
	for direction in [facing]+Rules.DIR8:
		var tile:Vector2i=run.player+direction
		if not run.step_clear(run.player,direction) or run.enemy_at(tile)>=0 or run.ally_at(tile)>=0:continue
		run.enemies.append(run.make_enemy(tile,100,0,dev_target_uid));dev_target_uid+=1
		run.reveal();facing=direction;sync();lab_update_aim();dev_result.text="Test target spawned · 100 HP";return
	dev_result.text="No free adjacent tile"

func lab_preview(id:String)->void:
	var profile:=combat_profile(id)
	var origin:Vector2i=run.player
	var footprint:Dictionary=run.attack_footprint(origin,facing,str(profile.pattern),int(profile.range),true)
	var target:Vector2i=origin
	var target_path:Array=[origin]
	if str(profile.pattern)!="self":
		var farthest:int=-1
		for tile in footprint:
			if run.distance(origin,tile)>farthest:
				farthest=run.distance(origin,tile);target=tile;target_path=footprint[tile]
		if target==origin:target=origin+facing;target_path=[target]
		for enemy in run.enemies:
			if footprint.has(enemy.pos):
				target=enemy.pos;target_path=footprint[target];break
	var tiles:Array=footprint.keys() if str(profile.pattern) in ["fan","radius","cross","room","floor"] else [target]
	var event:Dictionary={"fx":id,"from":origin,"to":target,"path":target_path,"tiles":tiles}
	release_charge_phase="";begin_player_cast_pose(event);combat_fx_spawn(event)

func lab_cast(id:String)->void:
	if not run.dev_sandbox or not dev_catalog.has(id):return
	# Starting another explicit FX preview is allowed; real casts finish their return first.
	if tile_cast_active() and not dev_fx_only.button_pressed:dev_result.text="Returning to origin · wait for landing";return
	path.clear();dev_selected=id;dev_detail.text=lab_move_info(id)
	dev_selected_label.text=str(dev_catalog[id].name)+" · "+str(dev_catalog[id].category).capitalize()+" · "+str(dev_catalog[id].type).capitalize()
	if dev_fx_only.button_pressed:
		lab_preview(id)
		dev_result.text="FX preview · "+str(dev_catalog[id].name)
	else:
		var used:bool=run.dev_cast_move(id,facing)
		var outcome:String=run.dev_cast_outcome
		if used:
			var total:int=0
			for amount in run.last_move_damage:total+=int(amount)
			outcome+=" · Damage %d · Heal %d · Hits %d/%d"%[total,run.last_move_healed,run.last_move_hits,run.last_move_attempts]
		sync()
		dev_result.text=("Cast · " if used else "Blocked · ")+outcome
		dev_detail.text=lab_move_info(id)+"\n\nLAST TEST\n"+dev_result.text
	lab_update_aim()

func lab_minimize()->void:
	dev_panel.hide();dungeon_footer.show();dev_bubble.show();lab_layout()

func lab_bubble_input(event:InputEvent)->void:
	if event is InputEventScreenTouch:
		if event.pressed and not dev_dragging:
			dev_dragging=true;dev_drag_index=event.index;dev_drag_moved=false;dev_drag_distance=0.0
		elif not event.pressed and dev_dragging and dev_drag_index==event.index:
			lab_end_drag()
	elif event is InputEventScreenDrag and dev_dragging and event.index==dev_drag_index:
		lab_drag(event.relative)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.device!=-1:
		if event.pressed:
			dev_dragging=true;dev_drag_index=-1;dev_drag_moved=false;dev_drag_distance=0.0
		elif dev_dragging and dev_drag_index==-1:lab_end_drag()
	elif event is InputEventMouseMotion and dev_dragging and dev_drag_index==-1:
		lab_drag(event.relative)
	dev_bubble.accept_event()

func lab_drag(relative:Vector2)->void:
	dev_drag_distance+=relative.length()
	if dev_drag_distance>6.0:dev_drag_moved=true
	if dev_drag_moved:dev_bubble.position+=relative;lab_layout()

func lab_end_drag()->void:
	dev_dragging=false;dev_drag_index=-1
	if not dev_drag_moved:
		dev_bubble.hide()
		dungeon_footer.hide();dev_panel.show();lab_layout()

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
	lab_build_settings(h)
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
	var footer=PanelContainer.new();dungeon_footer=footer;footer.add_theme_stylebox_override("panel",style(Color("#102739"),Color("#e2c081"),20));base.add_child(footer)
	var v=VBoxContainer.new();v.add_theme_constant_override("separation",6);footer.add_child(v)
	status_text=label(v,"",16,Color("#ffe1a4"));status_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status_text.custom_minimum_size.y=22;status_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var a=HBoxContainer.new();a.add_theme_constant_override("separation",8);v.add_child(a)
	attack_button=button(a,"Strike",func():pass,true)
	bind_attack_gesture(attack_button,{"name":"Strike","type":"normal","category":"physical","pattern":"front","reach":1,"power":6},func():path.clear();run.attack(false,facing);sync())
	power_button=button(a,"Skill",func():pass)
	bind_attack_gesture(power_button,{"name":"Skill","type":"variable","category":"special" if run.skill_kind==1 else "physical","pattern":"line" if run.skill_kind==1 else "front","reach":2 if run.skill_kind==1 else 1,"power":10},func():path.clear();run.attack(true,facing);sync())
	heal_button=button(a,"Berry",func():path.clear();run.heal();sync())
	var tactical=HBoxContainer.new();tactical.add_theme_constant_override("separation",8);v.add_child(tactical)
	aim_button=button(tactical,"Aim ↓",func():rotate_combat_aim())
	special_button=button(tactical,"Leaf Dart",func():pass)
	bind_attack_gesture(special_button,{"name":"Leaf Dart","type":"grass","category":"special","pattern":"line","reach":2,"power":10},func():path.clear();run.attack(true,facing,1);sync())
	if not run.equipped_moves.is_empty():
		power_button.hide();special_button.hide()
		var skills=GridContainer.new();skills.columns=2;v.add_child(skills)
		for id in run.equipped_moves:
			var b=button(skills,str(Rules.MOVE_LIBRARY[id].name),func():pass)
			bind_attack_gesture(b,Rules.MOVE_LIBRARY[id],func():path.clear();run.cast_move(id,facing);sync())
			b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			move_buttons.append(b)
	stairs_button=button(v,"Descend",func():path.clear();run.descend();sync(),true)
	hold_info=RichTextLabel.new();hold_info.custom_minimum_size.y=78;hold_info.add_theme_font_size_override("normal_font_size",14);hold_info.scroll_active=true;hold_info.mouse_filter=MOUSE_FILTER_IGNORE
	hud_base.add_child(hold_info);hud_base.move_child(hold_info,dungeon_footer.get_index());hold_info.hide()
	aim_preview=Control.new();area.add_child(aim_preview);aim_preview.set_anchors_and_offsets_preset(PRESET_FULL_RECT);aim_preview.mouse_filter=MOUSE_FILTER_IGNORE;aim_preview.draw.connect(draw_aim_preview)
	lab_settings_overlay()
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
uniform vec4 combat_pulse=vec4(0.0);
uniform vec4 combat_response=vec4(0.0);
uniform vec4 combat_tint:source_color=vec4(1.0);
varying float leaf_height;
varying float local_reaction;
void vertex(){
 leaf_height=clamp((VERTEX.y-0.26)/1.7,0.0,1.0);
 vec3 world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float sway=leaf_height*leaf_height;
 VERTEX.x+=sin(scene_time*1.45+world_pos.z*0.85)*0.10*sway;
 VERTEX.z+=cos(scene_time*1.1+world_pos.x*0.73)*0.065*sway;
 vec2 delta=world_pos.xz-combat_pulse.xy;
 float falloff=1.0-smoothstep(0.0,max(combat_response.x,0.01),length(delta));
 local_reaction=falloff*combat_pulse.w;
 float push=local_reaction*combat_response.y*sway;
 // Convert the world-space impulse back into each instance's local axes.
 vec3 local_push=inverse(mat3(MODEL_MATRIX))*vec3(delta.x,0.0,delta.y);
 VERTEX+=local_push*(push*0.30/max(length(delta),0.2));
}
void fragment(){
 ALBEDO=mix(base_color.rgb*(0.85+leaf_height*0.55),combat_tint.rgb,clamp(local_reaction*combat_response.w*0.55,0.0,0.35));
 ROUGHNESS=0.73;
}"""
	else:
		shader.code="""shader_type spatial;
render_mode cull_disabled;
uniform float scene_time=0.0;
uniform vec4 base_color:source_color=vec4(0.1,0.6,0.7,1.0);
uniform bool is_foam=false;
uniform vec4 combat_pulse=vec4(0.0);
uniform vec4 combat_response=vec4(0.0);
uniform vec4 combat_tint:source_color=vec4(1.0);
varying vec3 local_p;
varying vec2 world_xz;
void vertex(){local_p=VERTEX;world_xz=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz;}
void fragment(){
 float flow=local_p.z*20.0-local_p.y*7.0-scene_time*5.2;
 float ripple=0.5+0.5*sin(flow+0.65*sin(local_p.x*34.0));
 float filaments=pow(0.5+0.5*sin(local_p.x*37.0+sin(flow*0.36)),5.0);
 float shimmer=0.30*ripple+0.70*filaments;
 float distance_to_hit=length(world_xz-combat_pulse.xy);
 float reach=max(combat_response.x,0.01);
 float local_hit=combat_pulse.w*(1.0-smoothstep(reach*0.72,reach,distance_to_hit));
 float ring=1.0-smoothstep(0.07,0.26,abs(distance_to_hit-combat_pulse.z*reach));
 shimmer+=ring*local_hit*combat_response.z*0.6;
 ALBEDO=mix(base_color.rgb*(0.76+shimmer*0.37),combat_tint.rgb,clamp(local_hit*combat_response.w*0.60,0.0,0.40));
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
# Radius, vegetation displacement, water ripple, surface tint strength.
# Local reactions are visual and never modify dungeon terrain or collisions.
const ELEMENT_ENVIRONMENT_RESPONSE={
	"normal":Vector4(1.8,.42,.45,.06),"fire":Vector4(2.5,.55,.36,.45),
	"water":Vector4(3.2,.70,1.0,.16),"electric":Vector4(2.4,.28,.70,.38),
	"grass":Vector4(2.0,-.22,.16,.30),"ice":Vector4(2.3,.12,.22,.46),
	"fighting":Vector4(2.4,.90,.68,.10),"poison":Vector4(2.0,.10,.18,.48),
	"ground":Vector4(2.8,.83,.72,.24),"flying":Vector4(3.2,1.0,.72,.10),
	"psychic":Vector4(2.4,-.40,.45,.35),"bug":Vector4(1.6,.24,.12,.18),
	"rock":Vector4(2.6,.75,.78,.18),"ghost":Vector4(2.1,-.28,.22,.36),
	"dragon":Vector4(3.0,.80,.65,.40),"dark":Vector4(2.0,-.32,.28,.32),
	"steel":Vector4(1.9,.48,.50,.14),"fairy":Vector4(2.2,-.16,.30,.32)}
func environmental_response_sample(element:String,phase:float,terrain_only:bool=false)->Vector4:
	var profile:Vector4=ELEMENT_ENVIRONMENT_RESPONSE.get(element,ELEMENT_ENVIRONMENT_RESPONSE.normal)
	var t:float=clampf(phase,0.0,1.0)
	var strength:float=pow(1.0-t,1.5)*(.45 if terrain_only else 1.0)
	return Vector4(profile.x,profile.y*strength,profile.z*strength,profile.w*strength)

func exterior_response_pick(residues:Array)->Dictionary:
	var best:Dictionary={}
	var score:float=0.0
	for mark in residues:
		var phase:float=clampf(float(mark.age)/maxf(.001,float(mark.life)),0.0,1.0)
		if phase>=1.0:continue
		var response:=environmental_response_sample(str(mark.element),phase,bool(mark.terrain_only))
		var weight:float=maxf(absf(response.y),maxf(response.z,response.w))
		if weight<=score:continue
		score=weight
		var at:Vector3=mark.at
		best={"pulse":Vector4(at.x,at.z,phase,1.0),"response":response,"tint":Color(mark.color)}
	return best

func update_exterior_world(dt:float):
	exterior_clock+=clampf(dt,0.0,.25)
	# Select the strongest live local reaction, not the last visited tile.
	var reaction:=exterior_response_pick(fx_residues)
	var pulse:Vector4=reaction.get("pulse",Vector4.ZERO)
	var response:Vector4=reaction.get("response",Vector4.ZERO)
	var tint:Color=reaction.get("tint",Color.WHITE)
	for material in exterior_motion_materials.values():
		material.set_shader_parameter("scene_time",exterior_clock)
		set_fx_uniform(material,"combat_pulse",pulse)
		set_fx_uniform(material,"combat_response",response)
		set_fx_uniform(material,"combat_tint",tint)
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
	# Initialize invisible trail slots once, rather than rewriting them forever.
	for i in range(TRAIL_COUNT):
		trail_batch.multimesh.set_instance_transform(i,Transform3D(Basis.from_scale(Vector3.ONE*.001),Vector3.ZERO))
		trail_batch.multimesh.set_instance_color(i,Color(1,1,1,0))
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
	var player_center:=pos(run.player)
	for i in range(ambient_origins.size()):
		ambient_ages[i]+=delta
		var mote=i>=AMBIENT_COUNT
		var duration=5.5+float(i%5)*.37
		if ambient_ages[i]>=duration or ambient_origins[i].distance_squared_to(player_center)>81.0:ambient_spawn(i)
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
		if trail_ages[i]>=life:continue
		trail_ages[i]=minf(99.0,trail_ages[i]+delta)
		var fade=clampf(1.0-trail_ages[i]/life,0.0,1.0)
		var scale_value=(.55+trail_ages[i]*.28) if region==1 else .78
		if fade<=0.0:scale_value=.001;trail_ages[i]=99.0
		trail_batch.multimesh.set_instance_transform(i,Transform3D(Basis(Vector3.UP,trail_angles[i]).scaled(Vector3.ONE*scale_value),trail_origins[i]))
		trail_batch.multimesh.set_instance_color(i,Color(1,1,1,fade*.58))
func build_floor():
	var start_usec=Time.get_ticks_usec()
	fx_performance_grace=1.5;fx_pressure_age=0.0;fx_recovery_age=0.0
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
	add_enemy_contact_shadow(pet,"")
	disguise_actor=null;disguise_species="";form_age=0.0
	setup_form_effects()
	visual_charge_phase="";release_charge_phase=""
	player_tile_cast.clear()
	attack_time=0.0;hit_time=0.0;player_impact_delay=0.0
	# Sprite orientation is driven by actual movement, not the GLB basis.
	pet_pose.rotation.y=0.0
	pet.rotation.y=atan2(float(facing.x),float(facing.y))
	attack_fx=shape(geometry,"ring",Vector3.ZERO,Vector3.ONE,Color("#ffdfa0"));attack_fx.hide();attack_fx.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fxmat=StandardMaterial3D.new();fxmat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;fxmat.albedo_color=Color("#ffe6a3");attack_fx.material_override=fxmat
	destination_fx=shape(geometry,"ring",Vector3.ZERO,Vector3(.68,.08,.68),Color("#a0e6db"));destination_fx.hide();destination_fx.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	reward_pool.clear();reward_age=0.0;interaction_kind="";interaction_priority=0;seen_creatures.clear()
	reward_fx=Node3D.new();geometry.add_child(reward_fx);reward_fx.hide()
	var sparkle_mat=StandardMaterial3D.new();sparkle_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;sparkle_mat.albedo_color=Color("#ffe5a0")
	interaction_material=sparkle_mat
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
	if actor_nodes.has(key):
		if is_instance_valid(actor_nodes[key]) and not actor_nodes[key].is_queued_for_deletion():return actor_nodes[key]
		actor_nodes.erase(key)
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
# Shared actor movement. Does not modify logical tiles, hitboxes or species pixels.
# Anatomical motion is selected by role and explicit contact icon metadata.
# Special aerial, underground, rolling and tile routes retain priority.
func cast_motion_kind(id:String,profile:Dictionary)->String:
	var role:String=str(profile.role)
	if role in ["air_sky","air_fly","air_bounce","fight_jumpkick","fight_highkick","water_fall","normal_body","normal_climb","ghost_force"]:return "aerial"
	if role in ["fight_hammer","normal_stomp","normal_slam","normal_megakick"]:return "down"
	if role in ["normal_spin","normal_thrash","normal_flail","normal_struggle","normal_frustration","fight_roundkick","dragon_twister","rock_polish","status_dance"]:return "spin"
	if role in ["electric_dash","fire_wheel","fire_blitz","water_jet","ice_ball","earth_rush","rock_roll","air_brave","dragon_rush","normal_extreme","normal_quick","normal_tackle","normal_takedown","normal_edge","normal_giga","normal_headbutt","normal_skull","normal_feint","steel_head","steel_gyro","ghost_sneak","dark_faint","dark_sucker","fight_mach","bug_turn"]:return "rush"
	if role in ["lash","grass_vine","grass_whip","grass_needle","normal_wrap","normal_bind","normal_constrict","ghost_lick"]:return "lash"
	var anatomy:=directed_contact_kind(id,role)
	if anatomy in ["fang","crunch","claw","pincer"]:return anatomy
	if anatomy.begins_with("fist"):return "uppercut" if anatomy=="fist_upper" else "punch"
	if anatomy.begins_with("kick"):return "lowkick" if anatomy=="kick_low" else "kick"
	if role in ["air_wing","steel_wing","air_peck","air_pluck","air_drill"]:return "wing"
	if role in ["water_tail","poison_tail","steel_tail","status_tail"]:return "tail"
	if role in ["normal_horn","normal_drill","bug_horn","bug_fury","normal_furyattack"]:return "horn"
	if role in ["electric_contact","electric_fist","electric_fang","electric_spark","fire_kick","fire_punch","fire_fang","water_clamp","water_hammer","water_dive","water_tail","grass_blade","grass_wood","ice_punch","ice_fang","earth_club","earth_dig","rock_smash","air_peck","air_drill","air_pluck","air_wing","poison_fang","poison_jab","poison_cross","bug_horn","bug_fury","bug_cross","bug_bite","bug_leech","psi_cut","psi_zen","ghost_punch","ghost_claw","dragon_claw","dark_crunch","dark_bite","dark_slash","steel_claw","steel_wing","steel_bullet","normal_cut","normal_slash","normal_scratch","normal_crushclaw","normal_furyswipes","normal_false","normal_superfang","normal_hyperfang","normal_vice","normal_guillotine","normal_grip","normal_slap","normal_pound","normal_megapunch","normal_comet","normal_double","normal_dizzy","normal_horn","normal_drill","normal_furyattack","normal_strength","normal_return","normal_endeavor","normal_facade","normal_salt","normal_fake","normal_last"]:return "contact"
	if role.begins_with("fight_") and role not in ["fight_aura","fight_blast","fight_vacuum","fight_bulk","fight_detect","fight_counter","fight_revenge","fight_vital"]:return "contact"
	if Rules.MOVE_LIBRARY.has(id):
		var move:Dictionary=Rules.MOVE_LIBRARY[id]
		if str(move.get("pattern",""))=="self":return "focus"
		if str(move.get("category",""))=="status":return "gesture"
	if role in ["contact","electric_short"]:return "contact"
	return "cast"

# Anticipation, acceleration, contact and follow-through share the authored
# impact clock. No extra turn delay and no change to the tile-cast route.
func attack_direction_sample(progress:float,impact:float)->Vector3:
	var t:float=clampf(progress,0.0,1.0)
	var peak:float=clampf(impact,.12,.88)
	var windup_end:float=peak*.34
	var anticipation:float=pow(sin(PI*t/windup_end),2.0) if t<windup_end else 0.0
	var drive:float=0.0
	var follow:float=0.0
	if t>=windup_end and t<=peak:
		drive=smoothstep(windup_end,peak,t)
	elif t>peak:
		var recovery:float=(t-peak)/(1.0-peak)
		drive=1.0-smoothstep(0.0,1.0,recovery)
		follow=pow(sin(recovery*PI),2.0)*(1.0-recovery)
	return Vector3(anticipation,drive,follow)

func cast_motion_offset(kind:String,progress:float,impact:float)->Vector3:
	var t:float=clampf(progress,0.0,1.0)
	var peak:float=clampf(impact,.12,.88)
	var cue:=attack_direction_sample(t,peak)
	var recoil:float=pow(sin(t*PI),2.0)
	match kind:
		"rush":return Vector3(.64*cue.y-.14*cue.x,.05*recoil,0)
		"contact":return Vector3(.40*cue.y-.09*cue.x,.06*recoil,0)
		"fang":return Vector3(.36*cue.y-.09*cue.x,.035*recoil,0)
		"crunch":return Vector3(.48*cue.y-.13*cue.x,.025*recoil,.035*cue.z)
		"claw":return Vector3(.33*cue.y-.08*cue.x,.09*recoil,.12*cue.y-.10*cue.x)
		"pincer":return Vector3(.27*cue.y-.05*cue.x,.025*recoil,-.06*cue.z)
		"punch":return Vector3(.46*cue.y-.12*cue.x,.035*recoil,0)
		"uppercut":return Vector3(.34*cue.y-.09*cue.x,.19*cue.y,0)
		"kick":return Vector3(.31*cue.y-.10*cue.x,.12*cue.y,.06*cue.z)
		"lowkick":return Vector3(.29*cue.y-.08*cue.x,.015*recoil,.08*cue.y)
		"wing":return Vector3(.20*cue.y-.06*cue.x,.12*recoil,.10*cue.y)
		"tail":return Vector3(.10*cue.y-.06*cue.x,.03*recoil,.15*cue.y-.10*cue.x)
		"horn":return Vector3(.53*cue.y-.11*cue.x,.025*recoil,0)
		"lash":return Vector3(.13*cue.y-.08*cue.x,.025*recoil,.07*cue.z)
		"aerial":
			var flight:float=pow(sin(PI*t/peak),2.0) if t<peak else 0.0
			return Vector3(.36*cue.y-.06*cue.x,.60*flight,0)
		"down":return Vector3(.20*cue.y-.04*cue.x,.30*pow(sin(minf(1.0,t/peak)*PI),2.0),0)
		"spin":return Vector3(.10*cue.y,.07*recoil,.13*sin(t*TAU)*recoil)
		"focus":return Vector3(0,.08*recoil,0)
		"gesture":return Vector3(.04*cue.y,.05*recoil,.04*sin(t*TAU)*recoil)
		_:return Vector3(-.10*cue.x+.045*cue.y,.04*recoil,0)

func cast_offset_world(offset:Vector3,direction:Vector3)->Vector3:
	var forward:=Vector3(direction.x,0,direction.z).normalized()
	if forward.length_squared()<.0001:forward=Vector3(0,0,1)
	var side:=Vector3(-forward.z,0,forward.x)
	return forward*offset.x+Vector3.UP*offset.y+side*offset.z

func enemy_pose(actor:Node3D,state:String,seconds:float,direction:Vector2=Vector2.ZERO)->void:
	if not actor.has_meta("species"):return
	actor.set_meta("enemy_phase",state)
	actor.remove_meta("enemy_tile_cast")
	actor.remove_meta("enemy_cast_waves")
	actor.set_meta("enemy_clock",0.0)
	actor.set_meta("enemy_duration",seconds)
	actor.set_meta("enemy_facing",PixelArt.direction8_for(direction,int(actor.get_meta("enemy_facing",0))))
	if state=="attack":actor.set_meta("enemy_cast_direction",Vector3(direction.x,0,direction.y))
# Contact shadows follow horizontal body displacement, never the airborne height.
func enemy_shadow_sample(body_offset:Vector3,hover:float,parent_lift:float,size_multiplier:float,wide:bool)->Dictionary:
	var altitude:float=maxf(0.0,hover+body_offset.y+parent_lift)
	var footprint:float=size_multiplier*clampf(1.0-altitude*.65,.42,1.0)
	return {"position":Vector3(body_offset.x,.035-parent_lift,body_offset.z),"scale":Vector3(footprint*(1.15 if wide else 1.0),footprint*.8,1.0)}

# Idle movement stays under a few pixels and uses each creature's silhouette.
# x: breathing frequency, y: compression amplitude, z: lateral drift, w: hover bob.
func creature_idle_profile(species:String)->Vector4:
	match species:
		"coralcrab","thornbeetle","shellguard","crystarok":return Vector4(.48,.009,.005,0.0)
		"grovetitan","abyss_colossus","astro_golem","fungal_monarch":return Vector4(.32,.013,.004,.012)
		"lunamoth","nebulwing","sylphowl","celestial_guardian":return Vector4(1.15,.014,.018,.045)
		"eelstrix","orbitserpent","leviathorn","vinesnap":return Vector4(.75,.019,.027,.026)
		"marrowray","tidal_sovereign","reef_pup","anemoneye":return Vector4(.66,.021,.018,.030)
		"nova_wisp","leafwisp","bubblewisp","jellymancer":return Vector4(.85,.037,.022,.052)
		"bramble_pup","starlit_pup","hollow_stag","lunar_prowler","rootgnawer","voidspider","mossmite":return Vector4(.68,.020,.007,0.0)
		"comet_hare":return Vector4(1.0,.025,.009,0.0)
		"sporeling":return Vector4(.58,.030,.012,0.0)
		_:return Vector4(.62,.018,.006,0.0)

func creature_idle_sample(species:String,seconds:float,seed:float,weight:float,hovering:bool)->Vector3:
	var p:=creature_idle_profile(species)
	var phase:float=seconds*TAU*p.x+seed
	var w:float=clampf(weight,0.0,1.0)
	return Vector3(1.0+sin(phase)*p.y*w,sin(phase*.63+seed)*p.z*w,sin(phase*.72)*p.w*w if hovering else 0.0)

# Independent blink cadence, including a rare second blink. Absolute phase
# prevents locomotion changes or an interrupted attack resetting the clock.
func creature_appendage_sample(species:String,seconds:float,seed:int)->int:
	var phase_offset:float=float(posmod(seed,97))*.173
	var clock:float=maxf(0.0,seconds)+phase_offset
	if species in ["reef_pup","tidal_sovereign","anemoneye","abyss_colossus","jellymancer","celestial_guardian","eelstrix","marrowray","orbitserpent","leviathorn","nova_wisp","leafwisp","bubblewisp","astro_golem"]:
		var frequency:float=1.4 if species=="celestial_guardian" else .55 if species in ["astro_golem","orbitserpent"] else .85
		return [0,1,0,2][posmod(floori(clock*frequency*4.0),4)]
	var period:float=2.2+float(posmod(seed,11))*.19
	if species in ["grovetitan","crystarok","shellguard","fungal_monarch"]:period+=1.5
	var phase:float=fposmod(clock,period)
	if phase<.18:return 1
	if phase<.36:return 2
	return 0

func creature_blink_sample(seconds:float,seed:int,species:String)->bool:
	var period:float=3.1+float(posmod(seed,17))*.13
	if species in ["grovetitan","astro_golem","crystarok","shellguard","abyss_colossus"]:period+=1.3
	if species in ["comet_hare","bramble_pup","starlit_pup"]:period-=.45
	var phase:float=fposmod(seconds+float(posmod(seed,97))*.127,period)
	var cycle:int=floori((seconds+float(posmod(seed,97))*.127)/period)
	return phase<.135 or (posmod(cycle+seed,5)==0 and phase>.255 and phase<.365)

# Presentation-only health envelope. The gameplay HP remains authoritative.
func creature_condition_sample(actor:Node3D,hp_ratio:float,dt:float,enabled:bool)->Vector3:
	var target:float=clampf((.45-hp_ratio)/.30,0.0,1.0) if enabled else float(actor.get_meta("native_fatigue",0.0))
	var fatigue:float=move_toward(float(actor.get_meta("native_fatigue",0.0)),target,maxf(0.0,dt)*3.0)
	actor.set_meta("native_fatigue",fatigue)
	var phase:float=elapsed*TAU*1.05+float(actor.get_instance_id()%31)*.31
	return Vector3(1.0-fatigue*(.075+.023*sin(phase)),fatigue*.014*sin(phase*.5),fatigue)

func update_enemy_pixel(actor:Node3D,dt:float,motion:Vector3,body_dt:float=-1.0)->void:
	var sprite:=actor.get_node_or_null("EnemyPixel") as Sprite3D
	if sprite==null:return
	var state:String=actor.get_meta("enemy_phase","idle")
	var clock:float=float(actor.get_meta("enemy_clock",0.0))+dt
	var duration:float=float(actor.get_meta("enemy_duration",0.0))
	if state=="defeat" and clock>=duration:
		actor.hide();actor.queue_free();return
	if state in ["attack","hurt","windup"] and clock>=duration:
		clock=maxf(0.0,clock-duration)
		state="recover" if state=="attack" else "idle"
		duration=.12 if state=="recover" else 0.0
	if state=="recover" and clock>=duration:
		clock=maxf(0.0,clock-duration)
		state="idle";duration=0.0
	if state in ["idle","walk"]:
		var next_state:="walk" if motion.length_squared()>.002 else "idle"
		if next_state!=state:clock=0.0
		state=next_state
		if state=="walk":actor.set_meta("enemy_facing",PixelArt.direction8_for(Vector2(motion.x,motion.z),int(actor.get_meta("enemy_facing",0))))
	actor.set_meta("enemy_phase",state);actor.set_meta("enemy_clock",clock);actor.set_meta("enemy_duration",duration)
	var frame:int=posmod(int(clock*12.0),4) if state=="walk" else mini(1,int(clock*9.0)) if state=="attack" else 0
	var species:String=str(actor.get_meta("species"))
	var facing_index:int=int(actor.get_meta("enemy_facing",0))
	sprite.visible=true
	var hovering:bool=species in ["nova_wisp","leafwisp","lunamoth","jellymancer","marrowray","nebulwing","bubblewisp","sylphowl","leviathorn","astro_golem","celestial_guardian","tidal_sovereign"]
	var real_dt:float=maxf(0.0,dt if body_dt<0.0 else body_dt)
	var idle_weight:float=float(actor.get_meta("native_idle_weight",0.0))
	# Never layer idle deformation on a strike, hurt or defeat frame.
	idle_weight=move_toward(idle_weight,1.0,real_dt*5.0) if state=="idle" else 0.0
	actor.set_meta("native_idle_weight",idle_weight)
	var idle_seed:float=float(actor.get_instance_id()%97)*TAU/97.0
	var idle_sample:=creature_idle_sample(species,elapsed,idle_seed,idle_weight,hovering)
	var fatigue:=creature_condition_sample(actor,float(actor.get_meta("native_hp_ratio",1.0)),real_dt,not bool(actor.get_meta("pending_impact",false)))
	var rise:float=.13+.04*sin(elapsed*3.0+float(actor.get_instance_id()%11)) if hovering and state!="defeat" else 0.0
	rise+=idle_sample.z
	var size_multiplier:float=float(actor.get_meta("enemy_size_multiplier",1.0))
	sprite.position=Vector3(0,.54*size_multiplier+rise,0)
	var body_offset:=Vector3.ZERO
	var hit_flash:float=0.0
	var defeat_fade:float=1.0
	# Same continuous body clock as the companion; preserve the authored ground anchor.
	var cast_body_progress:float=caster_wave_progress(clock,duration,float(actor.get_meta("enemy_cast_impact",.48)),actor.get_meta("enemy_cast_waves",[])) if state=="attack" else 0.0
	sprite.scale=Vector3.ONE
	if state=="idle":
		sprite.scale=Vector3(1.0/idle_sample.x,idle_sample.x,1.0)
		sprite.position.y+=.54*size_multiplier*(idle_sample.x-1.0)
		body_offset.x=idle_sample.y*size_multiplier
		sprite.position.x+=body_offset.x
	if state=="attack":
		var body:Dictionary=PixelArt.attack_body_sample(cast_body_progress,float(actor.get_meta("enemy_cast_impact",.48)),str(actor.get_meta("enemy_cast_motion","contact")),species)
		var stretch:float=float(body.stretch)
		sprite.scale=Vector3(1.0/stretch,stretch,1.0)
		sprite.position.y+=.54*size_multiplier*(stretch-1.0)+float(body.lift)
	if state=="attack" and not actor.get_meta("companion_disguise",false):
		var cast_dir:Vector3=actor.get_meta("enemy_cast_direction",Vector3(0,0,1))
		var offset:=cast_motion_offset(str(actor.get_meta("enemy_cast_motion","contact")),cast_body_progress,float(actor.get_meta("enemy_cast_impact",.48)))
		body_offset=actor.basis.inverse()*cast_offset_world(PixelArt.creature_cast_offset(offset,species),cast_dir)
		if actor.has_meta("enemy_tile_cast"):
			var route:Dictionary=actor.get_meta("enemy_tile_cast")
			var sample:=tile_cast_sample(route.points,str(route.kind),clock/maxf(.01,duration),float(actor.get_meta("enemy_cast_impact",.48)))
			body_offset=actor.global_basis.inverse()*(Vector3(sample.position)-actor.global_position)
			sprite.visible=bool(sample.visible)
			var heading:Vector3=sample.motion
			facing_index=PixelArt.direction8_for(Vector2(heading.x,heading.z),facing_index)
		sprite.position+=body_offset
	if state=="hurt":
		var reaction:=creature_hit_sample(clock/maxf(.01,duration),species)
		hit_flash=float(reaction.flash)
		var squash:float=float(reaction.squash)
		sprite.scale=Vector3(1.0/squash,squash,1.0)
		sprite.position.y+=.54*size_multiplier*(squash-1.0)
		# A transformed companion already receives displacement and lift on its root.
		if not actor.get_meta("companion_disguise",false):
			var hit_dir:Vector3=actor.get_meta("enemy_hit_direction",Vector3.ZERO)
			var forward:Vector3=hit_dir.normalized()
			var lateral:=Vector3(-forward.z,0.0,forward.x)
			body_offset=actor.basis.inverse()*(forward*.32*float(reaction.recoil)+lateral*float(reaction.sway)+Vector3.UP*float(reaction.lift))
			sprite.position+=body_offset
	if state=="defeat":
		# Use the existing terminal cell, then collapse towards the ground.
		# Keep a short readable hold before shrinking out of the scene.
		var fall:float=smoothstep(.24,1.0,clampf(clock/maxf(.01,duration),0.0,1.0))
		var collapse:float=lerpf(1.0,.12,fall)
		sprite.scale=Vector3(lerpf(1.0,.32,fall),collapse,1.0)
		sprite.position.y=.54*size_multiplier*collapse
		defeat_fade=1.0-fall
	var shadow:=actor.get_node_or_null("EnemyContactShadow") as MeshInstance3D
	if shadow!=null:
		var parent_lift:float=actor.position.y if actor.get_meta("companion_disguise",false) else 0.0
		var shadow_sample:=enemy_shadow_sample(body_offset,rise,parent_lift,size_multiplier,species in ["eelstrix","marrowray","coralcrab","shellguard"])
		shadow.position=shadow_sample.position
		shadow.scale=shadow_sample.scale*defeat_fade
		shadow.visible=sprite.visible
	var visual_state:String=state
	# The phase continues through combat even when the strike sprite takes priority.
	# This avoids freezing the wing/fin cycle every time an enemy attacks.
	var locomotion_clock:float=fposmod(float(actor.get_meta("native_locomotion_clock",idle_seed))+real_dt,4.0)
	actor.set_meta("native_locomotion_clock",locomotion_clock)
	if state in ["idle","walk"]:
		var locomotion:Dictionary=PixelArt.enemy_locomotion_sample(species,state,locomotion_clock if PixelArt.NATIVE_HOVER_CYCLES.has(species) else clock)
		visual_state=str(locomotion.pose);frame=int(locomotion.frame)
	if state=="attack":
		var sample:Dictionary=PixelArt.attack_pose_sample(cast_body_progress,float(actor.get_meta("enemy_cast_impact",.48)))
		visual_state="windup" if sample.phase=="windup" else "recover" if sample.phase=="recover" else "attack"
		frame=int(sample.frame)
		actor.set_meta("enemy_visual_phase",sample.phase)
	else:actor.set_meta("enemy_visual_phase",state)
	var statuses:Array=actor.get_meta("living_statuses",[])
	var living:=living_body_sample(actor,statuses,dt if body_dt<0.0 else body_dt,state in ["idle","walk","recover"])
	if float(living.sleep)>.66 and state in ["idle","walk","recover"]:
		# Dedicated living sleep cell, never the terminal defeat silhouette.
		visual_state="sleep";frame=0
	if state in ["idle","walk","recover"] and bool(living.active):
		var stretch:float=float(living.stretch)
		sprite.scale=Vector3(float(living.width),stretch,1.0)
		sprite.position.y=lerpf(.54*size_multiplier+rise,.54*size_multiplier*stretch,float(living.sleep))+.54*size_multiplier*(stretch-1.0)*(1.0-float(living.sleep))
		# Ailments own the silhouette; do not add healthy idle drift to a sleeping body.
		sprite.position.x=float(living.sway)*size_multiplier
		if shadow!=null:
			shadow.position.x=sprite.position.x
			shadow.scale.x*=1.0+float(living.sleep)*.24
			shadow.scale.y*=1.0+float(living.sleep)*.13
	# Persistent alert posture follows the real windup flag, even after the
	# short anticipatory event has expired. Never override attacks or ailments.
	var alert:bool=state in ["idle","windup"] and bool(actor.get_meta("native_alert",false)) and not bool(living.active)
	if alert:
		visual_state="windup";frame=0
		var ready:float=1.0-.055*(.6+.4*sin(elapsed*TAU*2.0))
		sprite.scale=Vector3(1.0/ready,ready,1.0)
		sprite.position.y=.54*size_multiplier*ready+rise
	elif state in ["idle","walk"] and not bool(living.active) and not bool(actor.get_meta("pending_impact",false)):
		# Multiply the existing gait/breathing scale, rather than replacing it.
		var body_height:float=.54*size_multiplier
		var previous_y:float=sprite.scale.y
		sprite.scale.x/=fatigue.x
		sprite.scale.y*=fatigue.x
		sprite.position.y+=body_height*(sprite.scale.y-previous_y)
		sprite.position.x+=fatigue.y*size_multiplier
		if shadow!=null:shadow.position.x=sprite.position.x
	var can_blink:bool=not alert and not bool(actor.get_meta("pending_defeat",false)) and state in ["idle","walk"] and visual_state in ["idle","walk"] and float(living.sleep)<.1 and not ("freeze" in statuses or "sleep" in statuses or "nightmare" in statuses)
	var blink:bool=can_blink and (creature_blink_sample(elapsed,actor.get_instance_id(),species) or (fatigue.z>.75 and fposmod(elapsed+idle_seed,1.7)<.22))
	# Short asynchronous gestures for land creatures; aquatic appendages cycle.
	var appendage:int=0
	# Return to a neutral cell before allowing an independent idle gesture.
	if state=="idle" and idle_weight>=.8 and can_blink and fatigue.z<.65 and not bool(living.active) and species in PixelArt.ENEMY_IDLE_APPENDAGES:
		appendage=creature_appendage_sample(species,elapsed,actor.get_instance_id())
	# Strike-only anatomical cells follow the same authoritative impact time.
	# Hurt, sleep, defeat and recovery keep their existing priority.
	var anatomy:String="all"
	if state=="attack" and visual_state=="attack" and species in PixelArt.ENEMY_COMBAT_APPENDAGES:
		anatomy=PixelArt.combat_anatomy_slot(species,str(actor.get_meta("enemy_cast_motion","contact")))
		if not anatomy.is_empty():appendage=PixelArt.combat_appendage_stage(cast_body_progress,float(actor.get_meta("enemy_cast_impact",.48)))
	if appendage==0 or visual_state!="attack":anatomy="all"
	# Most rendered frames keep the same authored cell. Avoid repeated string
	# formatting and texture-cache queries until one of its discrete inputs changes.
	var cell_signature:=Vector4i(facing_index,frame,int(blink),appendage)
	var texture_changed:bool=false
	if str(actor.get_meta("native_cell_pose",""))!=visual_state or actor.get_meta("native_cell_signature",Vector4i(-1,-1,-1,-1))!=cell_signature or str(actor.get_meta("native_cell_anatomy",""))!=anatomy:
		var tex:=PixelArt.enemy_pixel_texture(species,facing_index,visual_state,frame,blink,appendage,anatomy)
		if tex!=null:
			texture_changed=sprite.texture!=tex
			if texture_changed:sprite.texture=tex
			actor.set_meta("native_cell_pose",visual_state)
			actor.set_meta("native_cell_signature",cell_signature)
			actor.set_meta("native_cell_anatomy",anatomy)
	if sprite.material_override is ShaderMaterial:
		var material:=sprite.material_override as ShaderMaterial
		if texture_changed:material.set_shader_parameter("sprite_tex",sprite.texture)
		set_fx_uniform(material,"hit_flash",hit_flash)
		# Forest shader does not read world_phase; reef and astral remain animated.
		if region!=0:material.set_shader_parameter("world_phase",elapsed)
		var biome:Color=[Color("#d5e6b5"),Color("#9be3e8"),Color("#c3c5ff")][region]
		set_fx_uniform(material,"biome_tint",biome.lerp(living.tint,float(living.tint_weight)))
		set_fx_uniform(material,"ambient_strength",.15+.38*float(living.tint_weight))
	else:
		var base_tint:Color=Color.WHITE.lerp(living.tint,float(living.tint_weight))
		sprite.modulate=base_tint.lerp(Color("#ffb5c6"),hit_flash) if state=="hurt" else base_tint
# Lightweight reusable pixel VFX: no per-frame node allocation, no camera-facing 3D creatures.
func combat_fx_setup(parent:Node3D)->void:
	for sound in fx_audio:
		if is_instance_valid(sound):sound.stop()
	response_slots.clear()
	combat_particles.clear();combat_warnings.clear();combat_bursts.clear();retired_impacts.clear();delayed_combat_fx.clear();fx_reactions.clear();fx_ground_shake=0.0;fx_contact_camera=Vector3.ZERO;fx_contact_camera_age=1.0
	combat_fx_root=Node3D.new();parent.add_child(combat_fx_root)
	setup_cinematic_lighting()
	setup_ultra_combat_layers()
	cast_text_pool.clear();cast_text_age.clear();cast_text_origin.clear();cast_text_cursor=0;response_text_queue.clear()
	for i in range(CAST_TEXT_CAP):
		var tag:=Label3D.new();tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		tag.font_size=38;tag.outline_size=9;tag.pixel_size=.006;tag.no_depth_test=true
		combat_fx_root.add_child(tag);tag.hide();cast_text_pool.append(tag);cast_text_age.append(0.0);cast_text_origin.append(Vector3.ZERO)
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
	for i in range(FX_PARTICLE_CAP+LIVING_PARTICLE_CAP):
		var particle:=Sprite3D.new()
		particle.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		particle.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		particle.shaded=false;particle.pixel_size=.032
		particle.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		combat_fx_root.add_child(particle);particle.hide();combat_particles.append(particle)
# Native spatial shader works in the existing GL Compatibility renderer.
# Additive light is a separate world-space layer; pixel sprites stay nearest-filtered.
# Material IDs are shared by a single pooled shader, not a shader per move.
const ELEMENT_MATERIAL={"normal":0,"fire":1,"water":2,"electric":3,"grass":4,"ice":5,"ground":6,"rock":6,"fighting":0,"flying":7,"poison":8,"bug":4,"psychic":9,"ghost":10,"dragon":1,"dark":10,"steel":11,"fairy":9}
func elemental_material_profile(element:String)->Vector3:
	var family:int=int(ELEMENT_MATERIAL.get(element,0))
	match family:
		1:return Vector3(family,.88,1.12)
		2:return Vector3(family,.66,.44)
		3:return Vector3(family,.95,1.20)
		4:return Vector3(family,.60,.28)
		5:return Vector3(family,.84,.74)
		6:return Vector3(family,.42,.10)
		7:return Vector3(family,.55,.22)
		8:return Vector3(family,.68,.34)
		9:return Vector3(family,.83,.90)
		10:return Vector3(family,.75,.52)
		11:return Vector3(family,.80,.64)
		_:return Vector3(0,.68,.42)

func setup_cinematic_lighting()->void:
	fx_lights.clear();fx_halos.clear();fx_halo_materials.clear()
	fx_lights_used=0;fx_halos_used=0;fx_light_scores.clear()
	if cinematic_halo_shader==null:
		cinematic_halo_shader=Shader.new()
		cinematic_halo_shader.code="""
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float ring_mix : hint_range(0.0, 1.0) = 0.0;
uniform float phase = 0.0;
uniform int material_family = 0;
uniform float material_opacity = 1.0;
uniform int distortion_family = 0;
uniform float distortion_strength = 0.0;
uniform float distortion_frequency = 1.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float original_radius = length(p);
	// Warp only the local effect field, not the screen or creature sprites.
	float edge = 1.0-smoothstep(0.68,1.0,original_radius);
	float angle0 = atan(p.y,p.x);
	float wave = phase*6.2831853;
	float amount = distortion_strength*edge;
	if (distortion_family == 1) {
		p.x += sin(p.y*distortion_frequency-wave*1.6)*amount;
		p.y += sin(p.x*distortion_frequency*0.65+wave)*amount*0.30;
	} else if (distortion_family == 2) {
		p += p/max(original_radius,0.08)*sin(original_radius*distortion_frequency-wave)*amount;
	} else if (distortion_family == 3) {
		float twist = amount*sin(original_radius*distortion_frequency-wave)*2.0;
		p = mat2(vec2(cos(twist),sin(twist)),vec2(-sin(twist),cos(twist)))*p;
	} else if (distortion_family == 4) {
		p *= 1.0+amount*cos(angle0*distortion_frequency+wave*1.5);
	} else if (distortion_family == 5) {
		p.x += sin(p.y*distortion_frequency+wave)*amount*0.7;
		p.y -= cos(p.x*distortion_frequency-wave)*amount*0.5;
	} else if (distortion_family == 6) {
		p *= 1.0-amount*sin(original_radius*distortion_frequency+wave);
	}
	float r = length(p);
	float halo = pow(max(0.0, 1.0-r), 2.7);
	float radius = mix(0.22, 0.82, phase);
	float d = (r-radius)/0.10;
	float e = (r-radius*0.72)/0.055;
	float ring = exp(-d*d) * (1.0-smoothstep(0.85, 1.0, r));
	float echo = exp(-e*e) * 0.24;
	float a = mix(halo, ring*0.68+echo, ring_mix);
	// Every family changes the light distribution as well as the hue.
	float angle = atan(p.y, p.x);
	float envelope = 1.0-smoothstep(0.82,1.0,r);
	float bands = 0.5+0.5*cos(r*28.0-phase*9.0);
	float detail = 1.0;
	float core = 0.0;
	if (material_family == 1) {
		detail = 0.55+0.45*sin(angle*5.0+r*12.0-phase*7.0);
		core = pow(max(0.0,1.0-r),5.0);
	} else if (material_family == 2) {
		detail = 0.36+0.64*pow(bands,3.0);
		core = pow(bands,7.0)*0.32;
	} else if (material_family == 3) {
		detail = 0.42+0.58*pow(abs(cos(angle*5.0+r*8.0+phase*15.0)),5.0);
		core = pow(max(0.0,1.0-r),3.0);
	} else if (material_family == 4) {
		detail = 0.48+0.52*pow(abs(cos(angle*3.0-phase*2.0)),2.0);
	} else if (material_family == 5) {
		detail = 0.34+0.66*pow(abs(cos(angle*3.0)),8.0);
		core = pow(abs(cos(angle*3.0)),16.0)*0.55;
	} else if (material_family == 6) {
		detail = 0.52+0.48*sin(angle*7.0+r*17.0);
	} else if (material_family == 7) {
		detail = 0.25+0.75*pow(abs(sin(angle*2.0+r*9.0-phase*5.0)),4.0);
	} else if (material_family == 8) {
		detail = 0.48+0.52*sin(angle*5.0+r*8.0+phase*3.0);
	} else if (material_family == 9) {
		detail = 0.40+0.60*pow(abs(cos(angle*4.0+phase*2.0)),4.0);
		core = pow(max(0.0,1.0-r),4.0)*0.7;
	} else if (material_family == 10) {
		detail = 0.24+0.76*pow(abs(sin(angle*2.0-r*10.0+phase*7.0)),2.0);
	} else if (material_family == 11) {
		detail = 0.40+0.60*pow(abs(cos(angle*2.0-phase*3.0)),8.0);
		core = detail*0.42;
	}
	ALBEDO = mix(tint.rgb, vec3(1.0), clamp(core,0.0,0.75));
	ALPHA = clamp(a * intensity * detail * envelope * material_opacity * (1.0-smoothstep(0.90,1.0,original_radius)), 0.0, 0.75);
}
"""
	var quad:=QuadMesh.new();quad.size=Vector2(1.0,1.0)
	for i in range(FX_HALO_CAP):
		var halo:=MeshInstance3D.new()
		var mat:=ShaderMaterial.new();mat.shader=cinematic_halo_shader
		halo.mesh=quad;halo.material_override=mat
		halo.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		combat_fx_root.add_child(halo);halo.hide()
		fx_halos.append(halo);fx_halo_materials.append(mat)
	for i in range(FX_LIGHT_CAP):
		var light:=OmniLight3D.new()
		light.shadow_enabled=false;light.omni_range=2.5;light.omni_attenuation=1.5
		light.light_energy=0.0
		combat_fx_root.add_child(light);light.hide();fx_lights.append(light)

# One batched ImmediateMesh for all animated ribbons, no new nodes per attack.
func setup_ultra_combat_layers()->void:
	fx_residues.clear();fx_reaction_sparks.clear()
	fx_trail_vertices=0;fx_trail_started=false
	fx_trail_mesh=ImmediateMesh.new()
	fx_trail_material=StandardMaterial3D.new()
	fx_trail_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	fx_trail_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	fx_trail_material.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
	fx_trail_material.vertex_color_use_as_albedo=true
	fx_trail_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	fx_trail_material.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
	var ribbons:=MeshInstance3D.new()
	ribbons.mesh=fx_trail_mesh
	ribbons.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	combat_fx_root.add_child(ribbons)

func ultra_trail_segment(a:Vector3,b:Vector3,wa:float,wb:float,ca:Color,cb:Color)->void:
	if not is_instance_valid(fx_trail_mesh) or fx_trail_vertices+6>FX_TRAIL_VERTEX_CAP:return
	var direction:Vector3=b-a
	if direction.length_squared()<.000001:return
	var view:Vector3=camera.global_basis.z if is_instance_valid(camera) else Vector3(0,.8,.6)
	var side:Vector3=direction.cross(view).normalized()
	if side.length_squared()<.000001:side=Vector3.RIGHT
	if not fx_trail_started:
		fx_trail_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,fx_trail_material)
		fx_trail_started=true
	var vertices:Array[Vector3]=[a-side*wa,a+side*wa,b+side*wb,a-side*wa,b+side*wb,b-side*wb]
	for i in range(6):
		fx_trail_mesh.surface_set_color(ca if i in [0,1,3] else cb)
		fx_trail_mesh.surface_add_vertex(vertices[i])
	fx_trail_vertices+=6

func ultra_attack_ribbons(burst:Dictionary,t:float)->void:
	var points:Array=burst.points
	if points.size()<2:return
	var profile:Dictionary=burst.profile
	var role:String=str(profile.role)
	var id:String=str(burst.id)
	var cue_key:String=id if AUTHORED_STAGE_FX.has(id) else role
	if not AUTHORED_STAGE_FX.has(cue_key):return
	var cue:Array=AUTHORED_STAGE_FX[cue_key]
	var kind:String=str(cue[0])
	if not kind in ["stream","cone","dash","wave","helix","wheel","arc","whip","drain","sweep","fall","rise","eruption"]:return
	var peak:float=clampf(float(profile.impact),.01,.99)
	if kind=="drain" and t<peak:return
	if kind!="drain" and t>peak+.10:return
	var progress:float=clampf(t/peak,0.0,1.0)
	if kind=="drain":progress=clampf((t-peak)/(1.0-peak),0.0,1.0)
	var envelope:float=sin(progress*PI)
	if envelope<.02:return
	var style:Array=combat_style(id)
	var inner:=Color(str(style[1]))
	var outer:=Color(str(style[2]))
	var source:Vector3=points[0]
	var target:Vector3=points[-1]
	var forward:=Vector3(target.x-source.x,0,target.z-source.z).normalized()
	if forward.length_squared()<.0001:forward=Vector3.FORWARD
	var side:=Vector3(-forward.z,0,forward.x)
	var spread:float=float(cue[3])
	var height:float=float(cue[4])
	var width:float=clampf(.027+spread*.065,.03,.105)
	var previous:=Vector3.ZERO
	var last_width:float=0.0
	var last_alpha:float=0.0
	for i in range(13):
		var f:float=float(i)/12.0
		var p:float=clampf(progress-(1.0-f)*.38,0.0,1.0)
		var q:Vector3=combat_path_sample(points,1.0-p if kind=="drain" else p)
		match kind:
			"arc":q.y+=height*sin(p*PI)
			"fall":q=target+Vector3.UP*height*(1.0-p)
			"rise","eruption":q=(source if kind=="rise" else target)+Vector3.UP*height*p
			"helix","wheel":q+=side*cos(p*TAU*2.0)*spread*.55+Vector3.UP*sin(p*TAU*2.0)*height*.48
			"whip":q+=side*sin(p*TAU*1.6-progress*3.0)*spread
			"sweep":q=target+(forward*cos(p*PI)+side*sin(p*PI))*spread+Vector3.UP*height*sin(p*PI)
			"wave":q+=side*sin(p*TAU*2.0)*spread*.30+Vector3.UP*height*sin(p*PI)
			"cone":q+=side*sin(p*TAU)*spread*p*.35
		var w:float=width*sin(f*PI*.85)
		var alpha:float=envelope*f*.56
		if i>0:
			ultra_trail_segment(previous,q,last_width*2.1,w*2.1,Color(outer,last_alpha*.42),Color(outer,alpha*.42))
			ultra_trail_segment(previous,q,last_width,w,Color(inner,last_alpha),Color(inner,alpha))
		previous=q;last_width=w;last_alpha=alpha

# Impact residue is independent of the cast lifetime, but only confirmed
# outcomes get a material trace. Bounded and discarded with the floor.
# Material response uses the recorded wave and the actual walkable cell.
# Reef is seabed sandstone, not a new water collision type.
const SURFACE_REACTION_MODES={"fire":"ember","water":"bubble","ice":"crystal","ground":"shards","rock":"shards","poison":"venom_splash","electric":"lightning","grass":"leaf","dragon":"ember","steel":"crystal","normal":"smoke","fighting":"smoke","flying":"slash","bug":"leaf","psychic":"status_swirl","ghost":"smoke","dark":"slash","fairy":"impact_star"}
# Dedicated ground silhouettes, independent of the airborne move particles.
const SURFACE_STAMP={"fire":"scorch","dragon":"scorch","water":"ripple","ice":"frost","ground":"crack","rock":"crack","poison":"puddle","electric":"static","grass":"sprout","steel":"scratch","normal":"dust","fighting":"crack","flying":"wind","bug":"sprout","psychic":"sigil","ghost":"wisp","dark":"scratch","fairy":"sigil"}
func surface_stamp_sample(element:String,progress:float)->Vector3:
	var t:float=clampf(progress,0.0,1.0)
	var expand:float=.65+t*.55
	var opacity:float=pow(1.0-t,1.2)
	var accent:float=sin(t*PI)*(1.0-t)
	match element:
		"fire","dragon","ground","rock","steel","fighting","dark":
			expand=.95+.20*smoothstep(0.0,.22,t)
		"ice","grass","bug":
			expand=.48+.70*smoothstep(0.0,.60,t)
		"water","flying":
			expand=.40+t*1.35
		"electric":
			opacity=pow(1.0-t,2.0)*(.7+.3*cos(t*TAU*3.0))
	return Vector3(expand,opacity,accent)

# Constant palette per element: avoid generating unique texture variants per move.
func surface_stamp_palette(element:String)->Array[Color]:
	match element:
		"fire","dragon":return [Color("#9b512e"),Color("#342823")]
		"water":return [Color("#d5ffff"),Color("#429bad")]
		"ice":return [Color("#ebffff"),Color("#8cbdeb")]
		"ground","rock","fighting":return [Color("#9a7e62"),Color("#4b3e38")]
		"steel","dark":return [Color("#a5a9b8"),Color("#444451")]
		"poison":return [Color("#ca86ef"),Color("#703680")]
		"electric":return [Color("#fff8b5"),Color("#d8a54f")]
		"grass","bug":return [Color("#b4df80"),Color("#527c45")]
		"ghost":return [Color("#d6b6fa"),Color("#67527f")]
		"psychic","fairy":return [Color("#f5c7ef"),Color("#a16bc6")]
		_:return [Color("#e7e4d4"),Color("#9e9c8f")]

const SURFACE_TERRAIN_ELEMENTS=["fire","water","ice","ground","rock","poison","electric","grass","dragon","steel","flying"]
func impact_surface_palette()->Array[Color]:
	match region:
		0:return [Color("#c6c18b"),Color("#6e6745")]
		1:return [Color("#b9ddd5"),Color("#587e8a")]
		_:return [Color("#c5b8e4"),Color("#65577f")]

func queue_surface_residue(tile:Vector2i,element:String,style:Array,terrain_only:bool,age:float)->void:
	if run==null or not run.cells.has(tile):return
	var life:float=.65 if element in ["fire","electric","dragon","normal","fighting","flying"] else .90
	if element in ["fire","dragon","ice","ground","rock","poison","steel"]:life=1.25
	if terrain_only:life*=.72
	if age>=life:return
	var at:Vector3=pos(tile)+Vector3.UP*.065
	var edge:=Vector2i.ZERO
	for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		if not run.cells.has(tile+direction):
			edge=direction;break
	var row:Dictionary={"at":at,"tile":tile,"element":element,"color":Color(str(style[1])),"dark":Color(str(style[2])),"age":age,"life":life,"edge":edge,"detail":floor_detail_bounds.has(tile),"terrain_only":terrain_only,"biome":region}
	# Refresh repeated contacts rather than evicting other affected tiles.
	for i in range(fx_residues.size()-1,-1,-1):
		if fx_residues[i].get("tile")==tile and fx_residues[i].element==element:
			fx_residues.remove_at(i);break
	if fx_residues.size()>=FX_RESIDUE_CAP:fx_residues.pop_front()
	fx_residues.append(row)

func ultra_impact_residue(burst:Dictionary,wave:Dictionary,first:bool,age:float)->void:
	var element:String=str(burst.profile.element)
	var id:String=str(burst.id)
	var record:Dictionary=Rules.MOVE_LIBRARY.get(id,Rules.DEV_NATIVE_MOVES.get(id,{}))
	if str(record.get("category",""))=="status" or not SURFACE_REACTION_MODES.has(element):return
	var style:Array=combat_style(id)
	for tile in wave:
		if int(wave[tile].get("damage",0))>0:
			queue_surface_residue(tile,element,style,false,age)
	if not first:return
	var target:Vector3=burst.points[-1]
	var cell:=Vector2i(roundi(target.x/1.4),roundi(target.z/1.4))
	var results:Dictionary=burst.get("results",{})
	# A miss or blocked actor is not an empty tile. No false damage accents.
	if results.has(cell):return
	if results.is_empty() and int(burst.get("damage",0))>0:
		queue_surface_residue(cell,element,style,false,age)
	elif element in SURFACE_TERRAIN_ELEMENTS:
		queue_surface_residue(cell,element,style,true,age)

# A hit response belongs to the confirmed impact, not the launch frame.
func queue_ultra_reaction(at:Vector3,direction:Vector3,terminal:bool)->void:
	if fx_reaction_sparks.size()>=FX_REACTION_SPARK_CAP:fx_reaction_sparks.pop_front()
	var forward:=Vector3(direction.x,0,direction.z).normalized()
	if forward.length_squared()<.0001:forward=Vector3.FORWARD
	fx_reaction_sparks.append({"at":at,"dir":forward,"age":0.0,"life":.46 if terminal else .24,"terminal":terminal})

func ultra_reaction_particles(dt:float,used:int)->int:
	for i in range(fx_reaction_sparks.size()-1,-1,-1):
		var row:Dictionary=fx_reaction_sparks[i]
		row.age+=dt
		var t:float=float(row.age)/float(row.life)
		if t>=1.0:
			fx_reaction_sparks.remove_at(i);continue
		var at:Vector3=row.at
		var forward:Vector3=row.dir
		var side:=Vector3(-forward.z,0,forward.x)
		var terminal:bool=row.terminal
		var count:int=8 if terminal else 5
		var fade:float=(1.0-t)*(1.0-t)
		for j in range(count):
			var f:float=float(j)/maxi(1,count-1)
			var distance:float=t*(.65 if terminal else .40)
			var q:Vector3=at+forward*distance+side*(f-.5)*distance*1.8+Vector3.UP*(sin(t*PI)*(.45 if terminal else .24)+.08*sin(f*TAU))
			used=environment_particle(used,q,"impact_star" if j%2==0 else "slash",Color("#fff1d1"),Color("#dd8b75"),.25+float(j%3)*.06,fade*.92)
		if terminal:
			cinematic_halo(Vector3(at.x,.065,at.z),Color("#ffcc91"),.8+t*.72,fade*.25,t,true)
	return used

# Impact body motion is normalized by the actual reaction clock. No logical
# movement or damage values are modified.
# Anatomy groups follow the authored creature silhouettes, not their elements.
# Parameters: recoil, compression, vertical motion, lateral sway/tilt.
func creature_hit_profile(species:String)->Vector4:
	match species:
		"coralcrab","thornbeetle","shellguard","crystarok":return Vector4(.48,.38,.20,.30)
		"grovetitan","abyss_colossus","astro_golem","fungal_monarch":return Vector4(.34,.55,.12,.22)
		"lunamoth","nebulwing","sylphowl","celestial_guardian":return Vector4(1.08,.55,1.65,1.15)
		"eelstrix","orbitserpent","leviathorn","vinesnap":return Vector4(.88,.70,.42,1.50)
		"marrowray","tidal_sovereign","reef_pup","anemoneye":return Vector4(.84,.74,.82,.88)
		"nova_wisp","leafwisp","bubblewisp","jellymancer":return Vector4(1.15,1.32,1.28,.95)
		"bramble_pup","starlit_pup","hollow_stag","lunar_prowler","rootgnawer","voidspider","mossmite":return Vector4(.86,.84,.50,.50)
		"comet_hare":return Vector4(1.12,1.12,1.40,.65)
		"sporeling":return Vector4(.95,1.25,.80,.68)
		_:return Vector4(1.0,1.0,1.0,.65)

func creature_hit_sample(progress:float,species:String)->Dictionary:
	var base:=premium_hit_sample(progress)
	var p:=creature_hit_profile(species)
	var t:float=clampf(progress,0.0,1.0)
	var envelope:float=sin(t*PI)*sin(t*PI)
	base.recoil=float(base.recoil)*p.x
	base.squash=1.0+(float(base.squash)-1.0)*p.y
	base.lift=float(base.lift)*p.z
	base.tilt=float(base.tilt)*p.w
	base["sway"]=sin(t*TAU)*envelope*.065*p.w
	return base

func premium_hit_sample(progress:float)->Dictionary:
	var t:float=clampf(progress,0.0,1.0)
	# Fast contact, then damped elastic recovery; exact neutral endpoints.
	var envelope:float=sin(t*PI)*sin(t*PI)
	var recoil:float=sin(t*PI)*pow(1.0-t,.65)
	var squash:float=1.0-.21*sin(t*PI*1.7)*pow(1.0-t,1.4)
	var flash:float=.66*pow(1.0-t,3.0)
	return {"recoil":recoil,"squash":squash,"flash":flash,"lift":envelope*.09,"tilt":sin(t*TAU*2.0)*envelope*.09}

func ultra_update_residues(dt:float,used:int)->int:
	for i in range(fx_residues.size()-1,-1,-1):
		var mark:Dictionary=fx_residues[i]
		mark.age+=dt
		var t:float=float(mark.age)/float(mark.life)
		if t>=1.0:
			fx_residues.remove_at(i);continue
		var fade:float=pow(1.0-t,1.4)
		var at:Vector3=mark.at
		var element:String=str(mark.element)
		var mode:String=str(SURFACE_REACTION_MODES.get(element,"shock_ring"))
		var terrain_only:bool=bool(mark.terrain_only)
		var strength:float=.55 if terrain_only else 1.0
		var surface:Array[Color]=impact_surface_palette()
		# A ground stamp is drawn before secondary debris; stays inside its tile.
		var sample:=surface_stamp_sample(element,t)
		var ink:=surface_stamp_palette(element)
		used=environment_particle(used,at,"surface_"+str(SURFACE_STAMP.get(element,"dust")),ink[0],ink[1],sample.x,sample.y*.82*strength,true)
		var count:int=residue_particle_count()
		var terminal_cue:Array=ELEMENT_DISSIPATION.get(element,ELEMENT_DISSIPATION.normal)
		for j in range(count):
			var terminal:=elemental_dissipation_sample(element,t,j)
			var offset:=elemental_dissipation_offset(element,t,j,count)
			offset=offset.rotated(Vector3.UP,float(i)*.37)*.58
			offset.y=maxf(.035,offset.y+.08)
			used=environment_particle(used,at+offset,str(terminal_cue[0]),mark.color,mark.dark,(.34+float(j%2)*.07)*terminal.z,terminal.w*.68*strength)
		# Surface material accent: moss litter, seabed sediment or mineral dust.
		# All positions stay within the 1.4-unit walkable tile.
		var biome:int=int(mark.biome)
		var dust_mode:String="leaf" if biome==0 and (bool(mark.detail) or element in ["grass","flying"]) else "smoke" if biome!=2 else "shards"
		if used<fx_cast_particle_limit and (fx_performance_tier==0 or t<.42):
			var drift:Vector3=Vector3(.30*t,.08+sin(t*PI)*.18,-.23*t)
			used=environment_particle(used,at+drift,dust_mode,surface[0],surface[1],.34,fade*.58*strength)
		var edge:Vector2i=mark.edge
		if edge!=Vector2i.ZERO and element in ["ground","rock","fighting","steel","water","flying"] and fx_performance_tier<2:
			var side:=Vector3(edge.x,0,edge.y)
			used=environment_particle(used,at+side*.55+Vector3.UP*(.12+sin(t*PI)*.24),dust_mode,surface[0],surface[1],.32,fade*.55*strength)
		if fx_performance_tier==0 and element in ["fire","dragon","ice","water","poison"] and t>.10:
			var plume:String="smoke" if element in ["fire","dragon","ice"] else "drop" if element=="water" else "cloud"
			var rise:Vector3=Vector3(.14*t,.12+t*.65,-.10*t)
			used=environment_particle(used,at+rise,plume,ink[0],ink[1],.38+t*.36,sample.z*.68*strength)
		# Reflect elemental light on the actual floor and nearby geometry.
		if fx_performance_tier==0 or (fx_performance_tier==1 and t<.55):
			cinematic_halo(at,mark.color,.85+t*.55,fade*.18*strength,t,true,element)
		if t<.28 and not terrain_only and element in ["fire","electric","dragon","fairy"] and fx_performance_tier==0:
			var lighting:=elemental_light_sample(element,t,"residue")
			cinematic_light(at+Vector3.UP*.28,mark.color,lighting.x,lighting.y*.70,lighting.z,0)
	return used

# Exact value caching only: no quantization, no temporal stepping.
# Shared by body and transformation writers so the last GPU value is authoritative.
func set_fx_uniform(material:ShaderMaterial,parameter:StringName,value:Variant)->void:
	var key:StringName=StringName("fx_uniform_"+str(parameter))
	if material.has_meta(key) and material.get_meta(key)==value:return
	material.set_shader_parameter(parameter,value)
	material.set_meta(key,value)

# family: 1 heat shimmer, 2 pressure/ripple, 3 vortex, 4 crystalline
# facets, 5 directional shear, 6 inward dimensional contraction.
const ELEMENT_DISTORTION={
	"normal":Vector3(2,.050,11),"fire":Vector3(1,.125,15),
	"water":Vector3(2,.110,17),"electric":Vector3(5,.095,23),
	"grass":Vector3(5,.040,7),"ice":Vector3(4,.080,6),
	"fighting":Vector3(2,.105,9),"poison":Vector3(1,.075,8),
	"ground":Vector3(2,.085,8),"flying":Vector3(5,.105,11),
	"psychic":Vector3(3,.140,10),"bug":Vector3(4,.035,9),
	"rock":Vector3(4,.060,5),"ghost":Vector3(6,.120,12),
	"dragon":Vector3(3,.125,7),"dark":Vector3(6,.105,9),
	"steel":Vector3(4,.055,4),"fairy":Vector3(3,.065,13)}
func elemental_distortion_sample(element:String,phase:float,stage:String,tier:int)->Vector3:
	var cue:Vector3=ELEMENT_DISTORTION.get(element,ELEMENT_DISTORTION.normal)
	if tier>=2 or stage=="none":return Vector3.ZERO
	var t:float=clampf(phase,0.0,1.0)
	var envelope:float=sin(t*PI) if stage=="launch" else pow(1.0-t,1.8)
	var strength:float=cue.y*maxf(0.0,envelope)*(.55 if tier==1 else 1.0)
	return Vector3(cue.x,strength,cue.z)

func cinematic_halo(at:Vector3,color:Color,extent:float,opacity:float,phase:float,ground:bool,element:String="normal",distortion_stage:String="none")->void:
	if fx_halos_used>=fx_halos.size() or opacity<=.012:return
	var index:int=fx_halos_used;fx_halos_used+=1
	var halo:MeshInstance3D=fx_halos[index]
	var mat:ShaderMaterial=fx_halo_materials[index]
	halo.position=at
	halo.rotation=Vector3(-PI*.5,0,0) if ground else Vector3.ZERO
	if not ground and is_instance_valid(camera):halo.global_basis=camera.global_basis.orthonormalized()
	halo.scale=Vector3.ONE*extent
	set_fx_uniform(mat,"tint",color)
	mat.set_shader_parameter("intensity",opacity)
	mat.set_shader_parameter("phase",phase)
	set_fx_uniform(mat,"ring_mix",1.0 if ground else 0.0)
	var material:=elemental_material_profile(element)
	set_fx_uniform(mat,"material_family",int(material.x) if fx_performance_tier<2 else 0)
	set_fx_uniform(mat,"material_opacity",material.y)
	var distortion:=elemental_distortion_sample(element,phase,distortion_stage,fx_performance_tier)
	set_fx_uniform(mat,"distortion_family",int(distortion.x))
	set_fx_uniform(mat,"distortion_strength",distortion.y)
	set_fx_uniform(mat,"distortion_frequency",distortion.z)
	if not halo.visible:halo.show()

# Per-element response: energy, reach, falloff, temporal modulation.
const ELEMENT_LIGHT_PROFILE={
	"normal":[.34,1.45,2.4,"pulse"],"fire":[1.05,2.45,1.4,"flicker"],
	"water":[.40,2.1,1.9,"ripple"],"electric":[1.18,2.65,2.1,"spark"],
	"grass":[.30,1.65,1.8,"soft"],"ice":[.76,2.2,2.0,"glint"],
	"fighting":[.42,1.55,2.5,"pulse"],"poison":[.34,1.8,1.5,"soft"],
	"ground":[.12,1.25,2.7,"pulse"],"flying":[.25,2.2,1.8,"ripple"],
	"psychic":[.86,2.35,1.5,"ripple"],"bug":[.24,1.45,2.2,"glint"],
	"rock":[.16,1.35,2.8,"pulse"],"ghost":[.58,1.9,1.25,"soft"],
	"dragon":[1.10,2.55,1.45,"flicker"],"dark":[.30,1.5,2.3,"soft"],
	"steel":[.62,1.85,2.6,"glint"],"fairy":[.88,2.15,1.6,"glint"]}
# x=energy, y=range, z=attenuation. No full-screen exposure changes.
func elemental_light_sample(element:String,phase:float,stage:String,wide:bool=false)->Vector3:
	var cue:Array=ELEMENT_LIGHT_PROFILE.get(element,ELEMENT_LIGHT_PROFILE.normal)
	var t:float=clampf(phase,0.0,1.0)
	var envelope:float=sin(t*PI)*.60 if stage=="launch" else pow(1.0-t,2.0)
	if stage=="residue":envelope*=.26
	var modulation:float=1.0
	match str(cue[3]):
		"flicker":modulation=.86+.14*cos(t*TAU*2.0)
		"spark":modulation=.82+.18*cos(t*TAU*3.0)
		"ripple":modulation=.80+.20*cos(t*TAU)
		"glint":modulation=.88+.12*cos(t*TAU*1.5)
		"soft":modulation=.90+.10*cos(t*PI)
	var energy:float=float(cue[0])*envelope*modulation
	var radius:float=float(cue[1])*(1.18 if wide else 1.0)
	return Vector3(clampf(energy,0.0,1.2),radius,float(cue[2]))

# Priority bands are disjoint: confirmed impact > travel > residue.
# Within a band, retain the strongest lights instead of whichever cast is
# visited first. No more OmniLight3D nodes are allocated.
func cinematic_light_slot(scores:Array[float],capacity:int,score:float)->int:
	if capacity<=0:return -1
	if scores.size()<capacity:return scores.size()
	var weakest:int=0
	for i in range(1,scores.size()):
		if scores[i]<scores[weakest]:weakest=i
	return weakest if score>scores[weakest] else -1

func cinematic_light(at:Vector3,color:Color,energy:float,extent:float,attenuation:float=1.5,priority:int=1)->void:
	if energy<=.02:return
	var capacity:int=mini(fx_lights.size(),1) if fx_performance_tier==2 else fx_lights.size()
	var score:float=float(clampi(priority,0,3))*2.0+clampf(energy,0.0,1.2)
	var index:int=cinematic_light_slot(fx_light_scores,capacity,score)
	if index<0:return
	if index==fx_light_scores.size():fx_light_scores.append(score)
	else:fx_light_scores[index]=score
	fx_lights_used=fx_light_scores.size()
	var light:OmniLight3D=fx_lights[index]
	light.position=at
	if light.light_color!=color:light.light_color=color
	if light.omni_range!=extent:light.omni_range=extent
	if light.omni_attenuation!=attenuation:light.omni_attenuation=attenuation
	light.light_energy=energy
	if not light.visible:light.show()

# A single impact resolver shared by halos, residues and finish choreography.
# Empty terrain may still receive environmental effects, never a damage flash.
func resolve_element_impact(burst:Dictionary)->Dictionary:
	var points:Array=burst.points
	var target:Vector3=points[-1]
	var tile:=Vector2i(roundi(target.x/1.4),roundi(target.z/1.4))
	var results:Dictionary=burst.get("results",{})
	var row:Dictionary=results.get(tile,{})
	if int(row.get("damage",0))+int(row.get("effects",0))+int(row.get("heal",0))>0:
		return {"kind":"confirmed","target":target,"tile":tile,"damage":int(row.get("damage",0))}
	var nearest:float=INF
	var selected:Vector2i=tile
	var selected_row:Dictionary={}
	for other in results:
		var hit:Dictionary=results[other]
		if int(hit.get("damage",0))+int(hit.get("effects",0))+int(hit.get("heal",0))<=0:continue
		var distance:float=Vector2(Vector2i(other)-tile).length_squared()
		if distance<nearest:
			nearest=distance;selected=other;selected_row=hit
	if not selected_row.is_empty():
		return {"kind":"confirmed","target":pos(selected)+Vector3(0,target.y,0),"tile":selected,"damage":int(selected_row.get("damage",0))}
	if row.is_empty() and results.is_empty() and int(burst.get("damage",0))>0:
		return {"kind":"confirmed","target":target,"tile":tile,"damage":int(burst.damage)}
	return {"kind":"terrain" if row.is_empty() else "miss","target":target,"tile":tile,"damage":0}

# Explicit cinematic accents are presentation-only; no rule power thresholds
# or timing changes. Include authored two-turn actions and guardian signatures.
const ULTIMATE_ACCENTS=["eos_455","eos_075","eos_524","eos_100","eos_149","eos_477","eos_533","eos_064","eos_238","eos_110","eos_468","eos_440","eos_113","eos_511","eos_518","eos_001","eos_278","eos_470","eos_498","eos_157","eos_239","eos_242","eos_272","eos_453","eos_537","eos_151","eos_041","eos_270","eos_435","eos_494","eos_538","eos_060","eos_348","eos_008","eos_153","eos_205","royal_spores","tidal_jaws","celestial_verdict","abyss_grasp","timber_shock"]

func ultimate_envelope(progress:float)->Vector2:
	var p:float=clampf(progress,0.0,1.0)
	return Vector2(sin(p*PI),pow(1.0-p,2.0))

func ultimate_accent_fx(burst:Dictionary,t:float,used:int)->int:
	var id:String=str(burst.id)
	if not id in ULTIMATE_ACCENTS:return used
	var profile:Dictionary=burst.profile
	var points:Array=burst.points
	if points.is_empty():return used
	var peak:float=clampf(float(profile.impact),.01,.99)
	var style:Array=combat_style(id)
	var light:=Color(style[1]);var dark:=Color(style[2])
	var element:String=str(profile.element)
	var material:String=str(ELEMENT_FINISH_MODE.get(element,"impact_star"))
	if t<peak:
		var p:float=t/peak
		var envelope:=ultimate_envelope(p)
		var source:Vector3=points[0]
		# Inward spiral converges at the caster, not on an unhit enemy.
		for i in range(3):
			var a:float=float(i)*TAU/3.0+p*TAU
			var radius:float=.70*(1.0-p)+.12
			var q:=source+Vector3(cos(a)*radius,.08+p*.34,sin(a)*radius)
			used=environment_particle(used,q,material,light,dark,.30,envelope.x*.9)
		return used
	var resolved:=resolve_element_impact(burst)
	if resolved.kind!="confirmed" or int(resolved.damage)<=0:return used
	var age:float=clampf((t-peak)/(1.0-peak),0.0,1.0)
	var sample:=ultimate_envelope(age)
	var target:Vector3=resolved.target
	# Different ground materials; no extra fullscreen flash or camera seizure.
	var ground_mode:String="earth_hole" if element=="ground" else "venom_splash" if element=="poison" else "shock_ring"
	used=environment_particle(used,Vector3(target.x,.055,target.z),ground_mode,light,dark,.72+age*1.45,sample.y*.85,true)
	for i in range(3):
		var a:float=float(i)*TAU/3.0+age*1.5
		var q:=target+Vector3(cos(a)*age*.72,sample.x*.48,sin(a)*age*.72)
		used=environment_particle(used,q,material,light,dark,.30+sample.y*.18,sample.y)
	return used

func cinematic_cast_enhancement(burst:Dictionary,t:float)->void:
	var points:Array=burst.points
	if points.is_empty():return
	var profile:Dictionary=burst.profile
	var style:Array=combat_style(str(burst.id))
	var color:=Color(str(style[1])).lerp(Color(str(style[2])),.34)
	var element:String=str(profile.element)
	var record:Dictionary=Rules.MOVE_LIBRARY.get(str(burst.id),Rules.DEV_NATIVE_MOVES.get(str(burst.id),{}))
	var status:bool=str(record.get("category",""))=="status"
	var luminous:bool=element in ["electric","fire","ice","psychic","ghost","dragon","fairy","steel"]
	var peak:float=clampf(float(profile.impact),.01,.99)
	var target:Vector3=points[-1]
	var source:Vector3=points[0]
	var resolved:=resolve_element_impact(impact_visual_view(burst))
	var miss:bool=resolved.kind!="confirmed"
	var wide:bool=profile.pattern in ["room","floor","radius","cross","fan"]
	var strength:float=.7 if luminous else .40
	if status:strength*=.62
	var ultimate:bool=str(burst.id) in ULTIMATE_ACCENTS
	if ultimate:strength=minf(.95,strength*1.3)
	if t<peak:
		var progress:float=t/peak
		var at:=combat_path_sample(points,progress)
		if status:at=source.lerp(target,progress*.6)
		var envelope:float=sin(progress*PI)
		cinematic_halo(at,color,.95 if luminous else .65,strength*envelope*.52,progress,false,element,"none" if status else "launch")
		if luminous:
			var lighting:=elemental_light_sample(element,progress,"launch")
			cinematic_light(at+Vector3.UP*.25,color,lighting.x*(.62 if status else 1.0),lighting.y,lighting.z,1)
	elif not miss:
		target=resolved.target
		var after:float=impact_visual_phase(burst,t)
		var fade:float=pow(1.0-after,2.0)
		var extent:float=(2.0 if wide else 1.25)*(1.18 if ultimate else 1.0)
		cinematic_halo(target,color,extent*(.82+after*.5),strength*fade*.8,after,false,element,"none" if status else "impact")
		if not status and (fx_performance_tier<2 or after<.55):
			cinematic_halo(Vector3(target.x,.06,target.z),color,extent*(.84+after*.9),strength*fade*.62,after,true,element,"impact")
		var lighting:=elemental_light_sample(element,after,"impact",wide)
		var critical:bool=not critical_impact_tiles(burst).is_empty()
		var energy:float=minf(1.2,lighting.x*(1.12 if ultimate else 1.0)*(1.12 if critical else 1.0)*(.62 if status else 1.0))
		cinematic_light(target+Vector3.UP*.4,color,energy,lighting.y,lighting.z,3 if critical else 2)

# Contact silhouette is independent of the elemental animation and is only
# drawn on a confirmed damaging tile. IDs are explicit, not translated names.
const CONTACT_ICON_KIND={"lib_electric_1":"fang","lib_dragon_3":"fang","lib_dark_1":"fang","eos_063":"fang","eos_198":"fang","eos_452":"fang","eos_461":"fang","eos_522":"fang","eos_529":"fang","eos_020":"fang","alt_vinesnap":"fang","reef_bite":"fang","alt_eelstrix":"fang","alt_orbitserpent":"fang","eos_062":"crunch","eos_261":"crunch","tidal_jaws":"crunch","lib_ghost_1":"claw","lib_dragon_1":"claw","eos_208":"claw","eos_260":"claw","eos_275":"claw","eos_325":"claw","eos_476":"claw","alt_bramble_pup":"claw","alt_sylphowl":"claw","moon_claw":"claw","alt_thornbeetle":"pincer","double_pincer":"pincer","lib_fighting_3":"fist","eos_065":"fist","eos_075":"fist","eos_126":"fist","eos_136":"fist","eos_246":"fist","eos_264":"fist","eos_292":"fist","eos_300":"fist","eos_322":"fist","eos_344":"fist","eos_500":"fist","eos_510":"fist","eos_515":"fist","meteor_fist":"fist","lib_fighting_2":"kick","eos_092":"kick","eos_204":"kick","eos_206":"kick","eos_276":"kick","eos_303":"kick","eos_321":"kick","eos_222":"kick","eos_210":"kick","star_kick":"kick","alt_comet_hare":"kick"}

# Authored anatomical variants; not a hash or recoloring of a single boot.
const CONTACT_KICK_ROLES={"fight_lowkick":"kick_low","fight_jumpkick":"kick_jump","fight_highkick":"kick_high","fight_roundkick":"kick_round","fight_double":"kick_double","fight_triple":"kick_triple","fire_kick":"kick_blaze","normal_megakick":"kick_heavy"}
const CONTACT_PUNCH_ROLES={"fight_uppercut":"fist_upper","fight_dynamic":"fist_heavy","fight_mach":"fist_fast","fire_punch":"fist_blaze","ice_punch":"fist_ice","electric_fist":"fist_electric","ghost_punch":"fist_ghost","normal_megapunch":"fist_heavy"}
func directed_contact_kind(id:String,role:String)->String:
	var kind:String=str(CONTACT_ICON_KIND.get(id,""))
	if kind=="kick":return str(CONTACT_KICK_ROLES.get(role,"kick"))
	if kind=="fist":return str(CONTACT_PUNCH_ROLES.get(role,"fist"))
	return kind

func contact_icon_image(kind:String,stage:int,light:Color,dark:Color)->Image:
	var im:=Image.create(48,48,false,Image.FORMAT_RGBA8);im.fill(Color.TRANSPARENT)
	var ink:=dark.darkened(.55)
	var bright:=light.lerp(Color.WHITE,.45)
	var c:=Vector2(24,24)
	match kind:
		"fang","crunch":
			var heavy:bool=kind=="crunch"
			var gap:float=[9.0,3.0,6.0][clampi(stage,0,2)]
			var width:float=19.0 if heavy else 15.0
			var teeth:int=7 if heavy else 5
			for side in [-1,1]:
				var sign_value:float=float(side)
				var last:=c+Vector2(-width,sign_value*(gap+5.0))
				for i in range(teeth):
					var x:float=lerpf(-width,width,float(i)/float(teeth-1))
					var y:float=sign_value*(gap+absf(x/width)*5.0)
					var p:=c+Vector2(x,y)
					fx_line(im,last,p,3.4,ink);fx_line(im,last,p,1.8,dark)
					var length:float=6.0 if i in [0,teeth-1] else 4.0 if heavy else 3.0
					fx_line(im,p,p-Vector2(0,sign_value*length),2.0,ink)
					fx_line(im,p,p-Vector2(0,sign_value*length),1.1,bright)
					last=p
		"claw":
			for i in range(3):
				var p:=c+Vector2(float(i-1)*9,0)
				var end:=p+Vector2(9,14)
				fx_line(im,p-Vector2(8,14),end,2.6,ink)
				fx_line(im,p-Vector2(8,14),end,1.4,light)
				fx_line(im,p-Vector2(6,11),end-Vector2(1,2),.7,bright)
		"pincer":
			for side in [-1,1]:
				var p:=c+Vector2(float(side)*(11.0+float(stage)*2.0),0)
				fight_arc(im,p,10.0,PI*.55 if side>0 else -PI*.45,PI*1.1,bright,ink,3.0)
		"fist","fist_upper","fist_heavy","fist_fast","fist_blaze","fist_ice","fist_electric","fist_ghost":
			var angle:float=0.0
			var center:=c
			var radius:float=13.0
			match kind:
				"fist_upper":angle=-PI*.5;center.y+=5.0-float(stage)*5.0
				"fist_heavy":radius=16.0
				"fist_fast":center.x+=float(stage)*3.0-3.0;radius=11.0
				"fist_blaze":angle=-.23
				"fist_ice":angle=.22
				"fist_electric":angle=-.10;center.x+=2.0
				"fist_ghost":angle=.45
			fight_fist(im,center,angle,radius,bright,ink)
			for i in range(3):
				var q:=center+Vector2(-20.0,float(i-1)*8.0).rotated(angle)
				fx_line(im,q,q+Vector2(6+stage,0).rotated(angle),1.1,light)
		"kick","kick_low","kick_jump","kick_high","kick_round","kick_double","kick_triple","kick_blaze","kick_heavy":
			# Side-view leg and boot, with separate bent, extended and recoil poses.
			var angle:float=0.0
			var center:=c
			var weight:float=1.0
			match kind:
				"kick_low":angle=.32;center.y+=7.0
				"kick_jump":angle=-.38;center.y-=3.0
				"kick_high":angle=-.85;center.y-=4.0
				"kick_round":angle=-.28+float(stage)*.25
				"kick_double":angle=-.18;center.y-=1.0
				"kick_triple":angle=.16;center.y+=2.0
				"kick_blaze":angle=-.48;weight=1.10
				"kick_heavy":weight=1.20
			var bend:float=[.62,1.0,.78][clampi(stage,0,2)]
			var hip:=center+Vector2(-16,-11).rotated(angle)
			var knee:=center+Vector2(-7,-6).rotated(angle)
			var ankle:=center+Vector2(6*bend,6).rotated(angle)
			var toe:=center+Vector2(17*bend,6).rotated(angle)
			fx_line(im,hip,knee,6.0*weight,ink)
			fx_line(im,knee,ankle,6.0*weight,ink)
			fx_line(im,ankle,toe,7.0*weight,ink)
			fx_line(im,hip,knee,3.6*weight,dark)
			fx_line(im,knee,ankle,3.6*weight,light)
			fx_line(im,ankle,toe,4.0*weight,bright)
			var sole:=Vector2(0,2.8*weight).rotated(angle)
			fx_line(im,ankle+sole,toe+sole,1.1,dark)
			if stage==1:
				for j in range(2):
					var speed_line:=Vector2(-5,10+float(j)*3.0).rotated(angle)
					fx_line(im,center+speed_line,center+speed_line+Vector2(10,0).rotated(angle),1.0,light)
	return im

# Static micro-material shading is baked into cached particle textures.
# Keep contact glyphs and status icons untouched for readability.
func particle_material_family(mode:String)->int:
	if mode in ["flame","ember","projectile_flame_stream","projectile_flame_burst","projectile_dragon_stream","projectile_ember_dart","impact_combustion","impact_flare"]:return 1
	if mode in ["bubble","drop","wave","projectile_bubble","projectile_bubble_train","projectile_water_jet","projectile_water_pulse","impact_splash","impact_surge","impact_bubble_pop"]:return 2
	if mode in ["lightning","projectile_charged_orb","projectile_charged_pulse","projectile_arc_beam","impact_discharge"]:return 3
	if mode in ["leaf","web","projectile_leaf_blade","projectile_seed_orb","projectile_seed_train","projectile_seed_bomb","impact_bloom"]:return 4
	if mode in ["crystal","projectile_ice_needle","projectile_frost_beam","impact_frost","impact_shatter"]:return 5
	if mode in ["shards","earth_hole","projectile_earth_bomb","projectile_rock_bomb","projectile_rock_dart","projectile_mud_dart","impact_fracture","impact_eruption"]:return 6
	if mode in ["slash","projectile_wind_blade","impact_shear"]:return 7
	if mode in ["venom_splash","projectile_venom_blob","projectile_venom_bomb","projectile_ink_blob","impact_splatter"]:return 8
	if mode in ["spiral","projectile_prism_beam","projectile_prism_pulse","projectile_star_dart","impact_radiance"]:return 9
	if mode in ["cloud","smoke","projectile_spectral_orb","projectile_mist_orb","projectile_shadow_pulse","impact_wisp","impact_implosion"]:return 10
	if mode in ["projectile_metal_beam","projectile_metal_needle","projectile_metal_dart","projectile_magnet_orb"]:return 11
	return 0

func particle_material_pixel(family:int,v:Vector2,inner:bool,light:Color,dark:Color)->Color:
	var base:Color=light if inner else dark
	var r:float=v.length()
	var specular:float=clampf(1.0-absf(v.x+v.y+2.0)*.36,0.0,1.0)
	match family:
		1:
			base=base.lerp(Color.WHITE,.34 if inner else .05)
			base.a*=clampf(1.05-v.y*.025,.72,1.0)
		2:
			base=base.lerp(Color.WHITE,specular*.48)
			base.a*=.85 if inner else .52+specular*.33
		3:base=base.lerp(Color.WHITE,.58 if inner else .12)
		4:base=base.lerp(light,.28 if v.y<0.0 else .04)
		5:
			base=base.lerp(Color.WHITE,specular*.65)
			base.a*=.78+specular*.22
		6:base=base.darkened(.18 if posmod(roundi(v.x)+roundi(v.y)*3,5)==0 else .0)
		7:base.a*=.82 if inner else .48
		8:
			base=base.lerp(light,specular*.28)
			base.a*=.88
		9:base=base.lerp(Color.WHITE,specular*.52)
		10:base.a*=clampf(.91-r*.055,.40,.91)
		11:base=base.lerp(Color.WHITE,specular*.76)
	return base

# Secondary textures retain a fixed working set during long Combat Lab sessions.
# Visible Sprite3D nodes retain references even when a cache key is evicted.
func cache_combat_particle(key:String,texture:ImageTexture)->void:
	if combat_textures.has(key):return
	if combat_texture_order.size()>=FX_SECONDARY_TEXTURE_CAP:
		combat_textures.erase(combat_texture_order.pop_front())
	combat_textures[key]=texture
	combat_texture_order.append(key)

func combat_pixel_texture(mode:String,light:Color,dark:Color)->ImageTexture:
	var key:=mode+str(light)+str(dark)
	if combat_textures.has(key):return combat_textures[key]
	if mode.begins_with("contact:"):
		var parts:=mode.split(":")
		var icon:=ImageTexture.create_from_image(contact_icon_image(parts[1],int(parts[2]),light,dark))
		cache_combat_particle(key,icon)
		return icon
	var im:=Image.create(16,16,false,Image.FORMAT_RGBA8);im.fill(Color.TRANSPARENT)
	var material_family:int=particle_material_family(mode)
	for y in range(16):
		for x in range(16):
			var v:=Vector2(x-7.5,y-7.5)
			var r:float=v.length()
			var fill:bool=false
			var inner:bool=false
			match mode:
				"critical_flash":
					# Four tapered rays, diagonal glints, and a bright compact core.
					var ax:float=absf(v.x);var ay:float=absf(v.y)
					fill=(ax<maxf(.55,2.6-ay*.34) and ay<7.0) or (ay<maxf(.55,2.6-ax*.34) and ax<7.0) or (absf(ax-ay)<.75 and ax+ay<8.0)
					inner=(ax+ay<3.5) or (minf(ax,ay)<.7 and maxf(ax,ay)<5.0)
				"status_plus":
					fill=(absf(v.x)<2.0 and absf(v.y)<6.5) or (absf(v.y)<2.0 and absf(v.x)<6.5)
					inner=absf(v.x)<.9 or absf(v.y)<.9
				"status_shield":
					var width:float=6.0 if v.y<0.0 else 6.0-v.y*.65
					fill=absf(v.x)<width and absf(v.y)<6.5
					inner=fill and absf(v.x)<width-1.5 and absf(v.y)<5.0
				"status_up","status_down":
					var yy:float=v.y if mode=="status_up" else -v.y
					fill=absf(yy+4.0-absf(v.x))<1.5 and absf(v.x)<6.0 or (absf(v.x)<1.5 and yy>=-3.0 and yy<6.5)
					inner=absf(v.x)<.8 or absf(yy+4.0-absf(v.x))<.7
				"status_sleep":
					fill=(absf(v.y+5.0)<1.2 or absf(v.y-5.0)<1.2 or absf(v.x+v.y)<1.4) and absf(v.x)<5.5 and absf(v.y)<6.0
					inner=fill and absf(v.x+v.y)<.8
				"status_swirl":
					fill=absf(r-(3.5+atan2(v.y,v.x)*.8))<1.3 or r<1.5
					inner=r<3.0
				"status_curse":
					fill=r<7.0 and (absf(r-5.5)<1.4 or absf(absf(v.x)-absf(v.y))<1.1)
					inner=r<3.0
				"status_heart":
					fill=(v-Vector2(-3,-2)).length()<3.6 or (v-Vector2(3,-2)).length()<3.6 or (v.y>=-1.0 and absf(v.x)<6.5-v.y*.9 and v.y<7.0)
					inner=fill and v.x<0.0 and v.y<1.5
				"status_bind":
					fill=(absf(v.y+3.0)<1.3 or absf(v.y-3.0)<1.3) and absf(v.x)<7.0 or absf(v.x)<1.0 and absf(v.y)<6.5
					inner=absf(v.x)<.6 or absf(absf(v.y)-3.0)<.6
				"status_exchange":
					fill=absf(v.y+3.0)<1.1 and absf(v.x)<6.5 or absf(v.y-3.0)<1.1 and absf(v.x)<6.5 or absf(v.y+3.0+absf(v.x-5.0))<1.1 and v.x>2.0 or absf(v.y-3.0-absf(v.x+5.0))<1.1 and v.x< -2.0
					inner=fill and absf(v.x)<4.0
				"impact_detonation","impact_force","impact_radiance":
					var rays:float=absf(sin(atan2(v.y,v.x)*(6.0 if mode=="impact_detonation" else 4.0)))
					fill=r<2.9 or (r<7.2 and rays*r<1.15)
					inner=r<2.1 or (fill and r<4.4)
				"impact_combustion","impact_flare":
					fill=r<6.0+sin(atan2(v.y,v.x)*5.0)*.9 and (r<4.0 or v.y<3.0)
					inner=fill and r<3.4
				"impact_splash","impact_surge","impact_splatter":
					fill=r<3.1 or (r<7.1 and absf(sin(atan2(v.y,v.x)*5.0))*r<.85)
					inner=fill and v.x+v.y<1.0
				"impact_shatter","impact_fracture","impact_eruption","impact_frost":
					var a:float=atan2(v.y,v.x)
					fill=r<7.0 and (absf(sin(a*3.0))*r<1.0 or (r>3.0 and absf(cos(a*5.0))*r<.65))
					inner=fill and (r<3.4 or v.y<0.0)
				"impact_discharge":
					fill=r<7.2 and (absf(v.y-sin(v.x*1.6)*2.5)<1.0 or absf(v.x+sin(v.y*1.2)*2.7)<1.0)
					inner=fill and r<3.5
				"impact_implosion","impact_vortex","impact_wisp":
					var a:float=atan2(v.y,v.x)
					fill=r<7.0 and absf(r-(4.0+a*.85))<1.2
					inner=fill and r<4.4
				"impact_bloom":
					fill=r<6.5 and (r<2.3 or absf(cos(atan2(v.y,v.x)*3.0))>.65)
					inner=r<3.2
				"impact_shear":
					fill=r<7.2 and (absf(v.y-v.x*.7)<.9 or absf(v.y+v.x*.7)<.8)
					inner=fill and r<3.0
				"impact_shockwave","impact_ripple","impact_bubble_pop":
					fill=absf(r-6.2)<.85 or absf(r-3.6)<.75
					inner=fill and v.x+v.y<0.0
				"projectile_spectral_orb","projectile_mist_orb":
					fill=r<6.5+sin(atan2(v.y,v.x)*5.0)*.85;inner=r<3.7 and (v.x+v.y<1.5 or mode=="projectile_spectral_orb")
				"projectile_charged_orb","projectile_weather_orb":
					fill=r<5.0 or (r<7.3 and absf(sin(atan2(v.y,v.x)*4.0))*r<1.2)
					inner=r<3.1
				"projectile_seed_orb","projectile_seed_train","projectile_seed_bomb":
					fill=absf(v.x)*.85+absf(v.y-v.x*.28)*1.15<5.9
					inner=fill and absf(v.y-v.x*.28)<1.1
				"projectile_force_orb","projectile_aura_orb","projectile_magnet_orb":
					fill=r<6.7 and (r>4.6 or absf(v.x)+absf(v.y)<4.4)
					inner=r<2.8 or (fill and v.x+v.y< -3)
				"projectile_aurora_beam","projectile_frost_beam","projectile_prism_beam","projectile_signal_beam","projectile_arc_beam","projectile_metal_beam","projectile_water_jet":
					var a:float=sin(v.x*.8)*1.4 if mode=="projectile_arc_beam" else 0.0
					var width:float=2.7 if mode=="projectile_water_jet" else 1.8
					fill=absf(v.y-a)<width+.6*cos(v.x*.8) and absf(v.x)<7.3
					inner=fill and absf(v.y-a)<.85
					if mode=="projectile_frost_beam":fill=fill or (absf(v.x)<6.0 and absf(v.y)<5.5 and posmod(x+y,7)==0)
					if mode=="projectile_prism_beam":fill=fill or absf(v.y-v.x*.55)<.8
				"projectile_flame_stream","projectile_flame_burst","projectile_dragon_stream","projectile_ember_dart":
					var tail:float=7.0-absf(v.x)
					fill=absf(v.y-sin(v.x*.75)*1.5)<tail*.60+.65
					inner=fill and absf(v.y)<1.8 and v.x> -3.0
				"projectile_bubble_train":
					var a:float=(v-Vector2(-3,2)).length();var b:float=(v-Vector2(3,-2)).length()
					fill=absf(a-3.2)<.8 or absf(b-3.1)<.8
					inner=fill and v.y<1.0
				"projectile_ice_needle","projectile_metal_needle","projectile_thorn_needle","projectile_twin_needle","projectile_metal_dart":
					var off:float=absf(v.y)-2.1 if mode=="projectile_twin_needle" else v.y
					fill=absf(off)<(7.4-absf(v.x))*.32+.5
					inner=fill and absf(off)<.7
				"projectile_wind_blade","projectile_leaf_blade":
					fill=absf(v.y-(v.x*v.x*.10-2.8))<1.25 and absf(v.x)<7.2
					inner=fill and v.y<2.0
					if mode=="projectile_leaf_blade":fill=fill or (absf(v.y-v.x*.32)<.8 and absf(v.x)<5.0)
				"projectile_egg_bomb","projectile_venom_bomb","projectile_venom_blob","projectile_earth_bomb","projectile_rock_bomb","projectile_ink_blob","projectile_rock_dart","projectile_mud_dart":
					var a:float=atan2(v.y,v.x)
					var edge:float=5.8+sin(a*5.0)*.9
					if mode=="projectile_egg_bomb":edge=5.5+v.y*.13
					if mode in ["projectile_ink_blob","projectile_venom_blob"]:edge+=sin(a*7.0)*.75
					fill=r<edge
					inner=fill and (v.x+v.y< -2.0 or (r<3.0 and posmod(x*3+y*7,5)==0))
				"projectile_prism_pulse","projectile_shadow_pulse","projectile_charged_pulse","projectile_water_pulse","projectile_dragon_pulse","projectile_vacuum_pulse","projectile_sonic_ring":
					var ring:float=r if mode!="projectile_vacuum_pulse" else absf(v.x)+absf(v.y)*.7
					fill=absf(ring-6.0)<.95 or absf(ring-3.3)<.8
					inner=fill and (v.x+v.y<0.0 or mode=="projectile_charged_pulse")
				"projectile_star_dart":
					fill=r<7.0 and (absf(v.x)<1.0 or absf(v.y)<1.0 or absf(absf(v.x)-absf(v.y))<.65)
					inner=r<2.2
				"projectile_orb":
					fill=r<7.0;inner=r<4.5 or (r>5.5 and v.x+v.y<0)
				"projectile_beam":
					fill=absf(v.y)<3.5 and absf(v.x)<7.5;inner=absf(v.y)<1.5
				"projectile_stream":
					fill=absf(v.y)<(7.3-absf(v.x))*.75+1.0;inner=absf(v.y)<2.0 and v.x> -4.0
				"projectile_bubble":
					fill=r<7.0 and (r>4.4 or (v.x< -1.0 and v.y< -1.0));inner=r>5.1 and v.x+v.y<0.0
				"projectile_needle":
					fill=absf(v.y)<(7.5-absf(v.x))*.29+.6;inner=absf(v.y)<.9 and v.x> -5.0
				"projectile_bomb":
					fill=r<6.4 and (r<4.8 or posmod(x+y,3)!=0);inner=r<3.2 or (v.x<0 and v.y< -2.0 and r<5.5)
				"projectile_pulse":
					fill=absf(r-6.1)<1.0 or absf(r-3.4)<.8;inner=v.x+v.y<0
				"projectile_dart":
					fill=absf(v.y)<(7.5-absf(v.x))*.48+.5;inner=absf(v.y)<1.2 and v.x> -3.0
				"surface_scorch":
					var a:float=atan2(v.y,v.x)
					fill=r<5.5+sin(a*5.0)*.8+cos(a*9.0)*.55
					inner=fill and r>3.2 and posmod(x*3+y*7,5)==0
				"surface_ripple":
					fill=absf(r-6.0)<.8 or absf(r-3.4)<.65
					inner=fill and v.x+v.y<1.0
				"surface_frost":
					var a:float=atan2(v.y,v.x)
					var spoke:float=absf(sin(a*3.0))
					fill=r<6.9 and (spoke*r<.75 or (r>2.8 and absf(sin(a*6.0))*r<.55))
					inner=fill and r<4.7
				"surface_crack":
					var a:float=atan2(v.y,v.x)+.22*sin(r*1.4)
					fill=r<7.0 and (absf(sin(a*3.0))*r<.8 or (r>3.8 and absf(cos(a*5.0))*r<.45))
					inner=fill and r>4.0
				"surface_puddle":
					fill=r<4.8+sin(atan2(v.y,v.x)*5.0)*1.05 or (r<7.1 and posmod(x*7+y*3,23)==0)
					inner=fill and v.x+v.y< -1.0
				"surface_static":
					fill=r<6.9 and (absf(v.y-sin(v.x*1.7)*2.1)<.85 or absf(v.x+sin(v.y*1.5)*2.0)<.75)
					inner=fill and r<4.0
				"surface_sprout":
					fill=r<6.8 and (absf(v.x)<.75 or (absf(absf(v.x)-2.8)+absf(v.y+absf(v.x)*.65)<2.4))
					inner=fill and v.y<.5
				"surface_scratch":
					fill=r<7.0 and (absf(v.y-v.x*.55+2.4)<.75 or absf(v.y-v.x*.55-2.4)<.75)
					inner=fill and v.x<1.0
				"surface_wind":
					fill=r<7.2 and r>2.0 and absf(r-(4.8+atan2(v.y,v.x)*.55))<.8
					inner=fill and v.y<0.0
				"surface_sigil":
					fill=r<7.0 and (absf(r-6.1)<.7 or absf(absf(v.x)+absf(v.y)-5.2)<.7)
					inner=fill and r<4.5
				"surface_wisp":
					fill=r<6.8 and absf(r-(3.3+atan2(v.y,v.x)*.9))<1.0
					inner=fill and r<3.5
				"surface_dust":
					fill=r<6.8 and posmod(x*7+y*11,7)<2
					inner=fill and r<3.5
				"venom_splash":
					fill=(r<4.0 or (r<7.2 and sin(atan2(v.y,v.x)*5.0)>.40) or (r>5.8 and posmod(x*3+y*7,13)==0))
					inner=r<2.8 or (fill and v.x+v.y<-2.5)
				"crystal":
					fill=absf(v.x-v.y*.22)*1.5+absf(v.y)*.60<5.2
					inner=fill and v.x<v.y*.22 and absf(v.y)<4.8
				"shock_ring":
					fill=(r>5.0 and r<7.3) or (r>3.4 and r<4.1)
					inner=fill and (r>6.1 or v.y<0.0)
				"smoke":
					fill=(v-Vector2(-2,1)).length()<4.6 or (v-Vector2(2,-2)).length()<4.0 or (v-Vector2(3,2)).length()<3.0
					inner=fill and (v-Vector2(-2,-1)).length()<2.8
				"earth_hole":
					fill=r<7.0
					inner=r>4.5 and r<6.4
				"impact_star":
					fill=r<6.9 and (absf(v.x)<1.2 or absf(v.y)<1.2 or absf(absf(v.x)-absf(v.y))<.9 or r<2.6)
					inner=r<2.8
				"ember":
					fill=absf(v.x)+absf(v.y)*.62<4.3
					inner=absf(v.x)+absf(v.y)*.65<2.3
				"leaf":
					fill=absf(v.x-v.y*.6)*1.1+absf(v.y)*.6<4.6
					inner=absf(v.x-v.y*.6)<1.0
				"drop":
					fill=r<3.9 or (v.y<0 and absf(v.x)<(7.0+v.y)*.46)
					inner=r<2.0 and v.x<0
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
			if fill:im.set_pixel(x,y,particle_material_pixel(material_family,v,inner,light,dark))
	var texture:=ImageTexture.create_from_image(im)
	cache_combat_particle(key,texture)
	return texture
var combat_style_cache:Dictionary={}
func combat_style(id:String)->Array:
	if not combat_style_cache.has(id):combat_style_cache[id]=build_combat_style(id)
	return combat_style_cache[id]

func build_combat_style(id:String)->Array:
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
# Original pixel flame silhouettes. Each choreography has its own shape and motion.
func fire_lobe(im:Image,p:Vector2,r:float,t:float,hot:Color,outer:Color)->void:
	var tip:=p+Vector2(sin(t*TAU)*r*.45,-r*1.65)
	fx_line(im,p,tip,r*.9,outer.darkened(.35))
	fx_disc(im,p,r,outer.darkened(.35))
	fx_disc(im,p-Vector2(0,1),r*.76,outer)
	fx_line(im,p,tip,r*.42,outer)
	fx_disc(im,p-Vector2(0,1),r*.40,hot)

func fire_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var hot:=Color("#fff0a1");var outer:=Color("#f66a24")
	var center:=Vector2(24,26)
	if role=="fire_sacred":hot=Color("#fff9dc");outer=Color("#f9c65a")
	if role=="fire_wisp":hot=Color("#f0c9ff");outer=Color("#a464df")
	match role:
		"fire_overheat","fire_blastburn":
			var rings:int=2 if role=="fire_overheat" else 3
			for ring in range(rings):
				var radius:float=4.0+t*float(7+ring*5)
				for i in range(7):
					var a:float=float(i)*TAU/7.0+float(ring)*.36+t*.8
					fire_lobe(im,center+Vector2(cos(a),sin(a)*.65)*radius,3.0+float(ring),t+float(i)*.1,hot,outer)
		"fire_wheel":
			for i in range(10):
				var a:float=float(i)*TAU/10.0+t*TAU
				fire_lobe(im,center+Vector2(cos(a),sin(a))*14.0,3.0,t+float(i)*.1,hot,outer)
			fx_disc(im,center,8.0,hot,6.0)
		"fire_breath":
			for i in range(8):
				var f:float=float(i)/7.0
				fire_lobe(im,Vector2(5+f*37,27+sin(f*9-t*TAU)*2.8),2.0+f*5.0,t+f,hot,outer)
		"fire_sacred":
			for i in range(6):
				var a:float=float(i)*TAU/6.0+t
				fire_lobe(im,center+Vector2(cos(a),sin(a))*11.0,4.0,t,hot,outer)
			fx_disc(im,center,6.0+sin(t*PI)*3.0,hot)
		"fire_blast":
			for i in range(5):
				var a:float=float(i)*TAU/5.0-PI*.5+t*.35
				var d:=Vector2(cos(a),sin(a))
				fx_line(im,center,center+d*(10.0+t*10.0),7.0,outer)
				fire_lobe(im,center+d*(10.0+t*10.0),4.0,t,hot,outer)
			fx_disc(im,center,7.0,hot)
		"fire_heatwave":
			for i in range(4):
				var y:float=14.0+float(i)*7.0
				for j in range(1,10):
					var x:float=4.0+float(j)*4.0
					fx_line(im,Vector2(x-4.0,y+sin(float(j-1)*.8+t*TAU)*3.0),Vector2(x,y+sin(float(j)*.8+t*TAU)*3.0),2.0,outer if i%2==0 else hot)
		"fire_ember","fire_wisp":
			var count:int=4 if role=="fire_ember" else 3
			for i in range(count):
				var q:=Vector2(9+float(i)*9.0+sin(t*TAU)*2.0,24+sin(float(i)*2.1+t*TAU)*5.0)
				fire_lobe(im,q,2.0+float(i%2),t,hot,outer)
		"fire_kick","fire_punch","fire_fang":
			if role=="fire_fang":
				for i in range(3):
					var x:float=13.0+float(i)*11.0
					var bite:float=sin(t*PI)*7.0
					fx_line(im,Vector2(x,8+bite),Vector2(x+3,21+bite),3.5,outer)
					fx_line(im,Vector2(x,40-bite),Vector2(x+3,27-bite),3.5,hot)
			elif role=="fire_kick":
				for i in range(7):
					var a:float=-PI*.8+float(i)*.38+t*.6
					fire_lobe(im,center+Vector2(cos(a),sin(a))*15.0,3.0,t,hot,outer)
			else:
				fx_line(im,Vector2(3,25),Vector2(28,25),8.0,outer)
				fire_lobe(im,Vector2(31+sin(t*PI)*4.0,25),9.0,t,hot,outer)
		"fire_eruption","fire_plume":
			var count:int=7 if role=="fire_eruption" else 4
			for i in range(count):
				var f:float=float(i)/maxi(1,count-1)
				var q:=Vector2(8+f*32,36-sin(t*PI)*float(10+i%3*6))
				fire_lobe(im,q,3.0+float(i%3),t+f,hot,outer)
		"fire_vortex","fire_magma":
			var count:int=12 if role=="fire_magma" else 8
			for i in range(count):
				var f:float=float(i)/float(count)
				var a:float=f*TAU*1.4+t*TAU
				var radius:float=7.0+f*12.0
				fire_lobe(im,center+Vector2(cos(a)*radius,sin(a)*radius*.55-f*9.0),3.0 if role=="fire_vortex" else 5.0,t+f,hot,outer)
		"fire_blitz":
			for i in range(7):
				var f:float=float(i)/6.0
				fire_lobe(im,Vector2(5+f*33,26+sin(f*8+t*TAU)*4.0),2.0+f*7.0,t+f,hot,outer)
			fx_disc(im,Vector2(35,26),6.0,hot)
		"fire_sun":
			var r:float=7.0+t*6.0
			fx_disc(im,Vector2(24,19),r,outer);fx_disc(im,Vector2(24,19),r-2.0,hot)
			for i in range(8):
				var a:float=float(i)*TAU/8.0+t*.25
				var d:=Vector2(cos(a),sin(a))
				fx_line(im,Vector2(24,19)+d*(r+2),Vector2(24,19)+d*(r+6),2.0,outer)

func water_drop(im:Image,q:Vector2,r:float,light:Color,dark:Color)->void:
	fx_disc(im,q,r,dark)
	fx_disc(im,q-Vector2(0,1),r*.72,light)
	fx_disc(im,q-Vector2(r*.22,r*.32),maxf(1.0,r*.21),Color("#eaffff"))

func water_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var center:=Vector2(24,24)
	var light:=Color("#73e6fa");var dark:=Color("#1768aa")
	if role=="water_ink":light=Color("#777e9d");dark=Color("#24233e")
	if role=="water_mud":light=Color("#d2ae70");dark=Color("#745135")
	match role:
		"water_bubble","water_bubblebeam":
			var count:int=5 if role=="water_bubble" else 9
			for i in range(count):
				var x:float=5.0+fposmod(float(i)*7.5+t*25.0,38.0)
				var y:float=24.0+sin(float(i)*2.4+t*TAU)*(7.0 if count==5 else 3.0)
				var radius:float=3.0+float(i%3)
				fx_disc(im,Vector2(x,y),radius,dark)
				fx_disc(im,Vector2(x,y),radius-1.0,light,radius-2.0)
				fx_disc(im,Vector2(x-1,y-2),1.0,Color.WHITE)
		"water_ink":
			for i in range(9):
				var a:float=float(i)*TAU/9.0+t
				water_drop(im,center+Vector2(cos(a),sin(a))*(4.0+t*16.0),3.0+float(i%3),light,dark)
			fx_disc(im,center,6.0,dark)
		"water_whirlpool","water_ring","water_shell":
			for ring in range(3):
				var radius:float=6.0+float(ring)*6.0
				var last:=center+Vector2(radius,0)
				for j in range(1,25):
					var a:float=float(j)*TAU/24.0+t*TAU
					var q:=center+Vector2(cos(a)*radius,sin(a)*radius*(.42 if role=="water_whirlpool" else .72))
					if role=="water_shell":q.y-=sin(float(ring)*PI*.5)*6.0
					if j>1:fx_line(im,last,q,2.4,dark);fx_line(im,last,q,1.0,light)
					last=q
				var orbit:float=t*TAU+float(ring)*2.1
				water_drop(im,center+Vector2(cos(orbit)*radius,sin(orbit)*radius*.65),2.0,light,dark)
			if role=="water_shell":fx_disc(im,center,8.0,dark,6.0)
		"water_clamp","water_hammer","water_tail":
			if role=="water_clamp":
				var close:float=sin(t*PI)*9.0
				for sign_y in [-1.0,1.0]:
					fx_line(im,Vector2(8,24+sign_y*15),Vector2(28,24+sign_y*(15-close)),5.0,dark)
					fx_line(im,Vector2(28,24+sign_y*(15-close)),Vector2(39,24+sign_y*3),3.0,light)
			elif role=="water_hammer":
				var a:float=-1.1+t*2.1
				var q:=center+Vector2(cos(a),sin(a))*13.0
				fx_line(im,Vector2(7,36),q,5.0,dark);water_drop(im,q,9.0,light,dark)
			else:
				for i in range(12):
					var a:float=-2.3+float(i)*.27+t*.7
					water_drop(im,center+Vector2(cos(a),sin(a))*16.0,2.0+float(i)*.3,light,dark)
		"water_spout","water_fall","water_dive":
			for i in range(6):
				var x:float=8.0+float(i)*6.0
				var y:float=39.0-sin(t*PI)*float(13+i%3*7) if role=="water_spout" else 5.0+fposmod(t*33.0+float(i)*7.0,33.0) if role=="water_fall" else 24.0+sin(t*TAU)*12.0
				fx_line(im,Vector2(x,39 if role!="water_fall" else 2),Vector2(x,y),3.0,dark)
				water_drop(im,Vector2(x,y),3.0,light,dark)
			if role=="water_dive":fx_disc(im,Vector2(24,35),10.0+t*7.0,light,8.0+t*7.0)
		"water_mud","water_surf":
			for j in range(1,15):
				var x:float=2.0+float(j)*3.0
				var y:float=30.0-sin(float(j)*.33+t*TAU)*(7.0 if role=="water_mud" else 12.0)
				fx_line(im,Vector2(x,40),Vector2(x,y),4.0,dark)
				water_drop(im,Vector2(x,y),3.0,light,dark)
		"water_cannon","water_pump","water_gun","water_jet","water_brine":
			var width:float=6.0 if role=="water_cannon" else 4.0 if role=="water_pump" else 1.8 if role=="water_gun" else 3.0
			for i in range(9):
				var f:float=float(i)/8.0
				var q:=Vector2(4+40*f,24+sin(f*10.0-t*TAU)*(1.0 if role=="water_cannon" else 4.0))
				water_drop(im,q,width*(.55+f*.65),light,dark)
				if role=="water_brine":fx_disc(im,q+Vector2(1,7 if i%2==0 else -7),1.2,Color.WHITE)
			if role=="water_jet":fx_line(im,Vector2(3,32),Vector2(41,18),2.0,light)
		"water_pulse":
			for i in range(3):
				var x:float=8.0+float(i)*12.0+sin(t*TAU)*2.0
				for j in range(1,13):
					var a:float=-PI*.5+float(j)*PI/12.0
					var b:float=a-PI/12.0
					fx_line(im,Vector2(x+cos(b)*5,sin(b)*15+24),Vector2(x+cos(a)*5,sin(a)*15+24),2.8,light)
		"water_rain","water_mist":
			for i in range(11):
				var x:float=4.0+float(posmod(i*17,40))
				var y:float=4.0+fposmod(float(i)*11.0+t*36.0,38.0)
				if role=="water_rain":fx_line(im,Vector2(x,y),Vector2(x-2,y+6),1.4,light)
				else:fx_disc(im,Vector2(x,y),4.0+sin(t*PI)*3.0,Color(light,.55))
# Plant effects share only drawing primitives, not completed move frames.
func grass_leaf(im:Image,center:Vector2,angle:float,length:float,light:Color,dark:Color)->void:
	var direction:=Vector2(cos(angle),sin(angle))
	var tip:=center+direction*length
	var side:=Vector2(-direction.y,direction.x)
	for n in range(1,7):
		var f:float=float(n)/7.0
		var q:=center+direction*length*f
		var w:float=sin(f*PI)*length*.24
		fx_line(im,q-side*w,q+side*w,1.5,dark)
		fx_line(im,q,q+side*w,1.0,light)
	fx_line(im,center,tip,1.0,light)

func grass_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var center:=Vector2(24,24)
	var light:=Color("#b9ef77");var dark:=Color("#287b46")
	match role:
		"grass_absorb","grass_mega","grass_giga":
			var strength:int=1 if role=="grass_absorb" else 2 if role=="grass_mega" else 3
			for i in range(strength+2):
				var f:float=fposmod(float(i)/float(strength+2)+t,1.0)
				var q:=Vector2(42.0-36.0*f,24.0+sin(f*TAU+float(i))*float(2+strength*2))
				fx_disc(im,q,2.0+float(strength),dark)
				fx_disc(im,q,1.0+float(strength),light)
				if strength==3:grass_leaf(im,q,PI+f,.9+float(strength)*2.0,light,dark)
		"grass_vine","grass_whip","grass_needle":
			var count:int=2 if role=="grass_whip" else 1
			for k in range(count):
				var last:=Vector2(3,24+float(k)*5)
				for j in range(1,19):
					var f:float=float(j)/18.0
					var q:=Vector2(3+f*(12.0+sin(t*PI)*29.0),24+sin(f*TAU*1.5-t*TAU)*float(3+count*2)+float(k)*5)
					fx_line(im,last,q,4.0 if count==2 else 2.8,dark);fx_line(im,last,q,1.2,light)
					if j%4==0:
						if role=="grass_needle":fx_line(im,q,q+Vector2(-3,-8 if j%8==0 else 8),2.0,light)
						else:grass_leaf(im,q,-1.8 if j%8==0 else 1.8,6.0,light,dark)
					last=q
		"grass_solar":
			var radius:float=5.0+sin(t*PI)*5.0
			fx_disc(im,Vector2(7,24),radius,Color("#ffe886"))
			fx_line(im,Vector2(7,24),Vector2(44,24),radius*.85,Color("#f9d34e"))
			fx_line(im,Vector2(7,24),Vector2(44,24),radius*.40,Color.WHITE)
		"grass_frenzy","grass_roots","grass_knot":
			var count:int=5 if role=="grass_frenzy" else 3 if role=="grass_roots" else 2
			for i in range(count):
				var x:float=7.0+float(i)*34.0/float(count-1)
				var last:=Vector2(x,43)
				for j in range(1,12):
					var f:float=float(j)/11.0
					var q:=Vector2(x+sin(f*TAU*1.3+t*TAU)*float(3+i%2*2),43.0-f*(13+sin(t*PI)*23.0))
					fx_line(im,last,q,3.4,dark);fx_line(im,last,q,1.2,light)
					if j%3==0:grass_leaf(im,q,PI if i%2==0 else 0.0,7.0,light,dark)
					last=q
			if role=="grass_knot":fx_disc(im,center,8.0+t*3.0,light,6.0+t*3.0)
		"grass_razor","grass_magic","grass_storm","grass_blade","grass_petal":
			var count:int=4 if role=="grass_razor" else 5 if role=="grass_magic" else 10 if role=="grass_storm" else 3 if role=="grass_blade" else 8
			for i in range(count):
				var f:float=float(i)/float(count)
				var angle:float=f*TAU+t*TAU
				var q:=Vector2(4+fposmod(f*40+t*31.0,38.0),24+sin(angle)*11.0)
				if role in ["grass_storm","grass_petal"]:q=center+Vector2(cos(angle),sin(angle))*(5.0+f*16.0)
				if role=="grass_blade":q=center+Vector2(cos(angle*.5),sin(angle*.5))*10.0
				if role=="grass_petal":
					fx_disc(im,q,3.5,Color("#df7fa9"));fx_disc(im,q-Vector2(1,1),2.0,Color("#ffd1e1"))
				else:
					var tint:Color=Color("#8fe8d7").lerp(Color("#f1a1df"),f) if role=="grass_magic" else light
					grass_leaf(im,q,angle,13.0 if role=="grass_blade" else 8.0,tint,dark)
		"grass_wood":
			var tip:=Vector2(10+sin(t*PI)*28,14+sin(t*PI)*19)
			fx_line(im,Vector2(6,42),tip,7.0,Color("#765033"))
			fx_line(im,tip+Vector2(-8,-5),tip+Vector2(7,5),12.0,Color("#976641"))
			grass_leaf(im,tip,-PI*.5,10.0,light,dark)
		"grass_energy","grass_flare","grass_bomb","grass_bullet","grass_leech","grass_worry":
			var count:int=7 if role=="grass_bullet" else 8 if role=="grass_flare" else 3 if role=="grass_leech" else 1
			for i in range(count):
				var angle:float=float(i)*TAU/float(count)+t*TAU
				var q:=Vector2(5+fposmod(float(i)*9+t*32.0,37.0),24+sin(angle)*5.0)
				if role=="grass_flare":q=center+Vector2(cos(angle),sin(angle))*(4.0+t*15.0)
				if count==1:q=Vector2(10+28*t,24)
				var radius:float=9.0 if role=="grass_energy" else 7.0 if role=="grass_bomb" else 5.0 if role=="grass_worry" else 3.0
				fx_disc(im,q,radius,dark)
				fx_disc(im,q-Vector2(1,1),radius*.67,light)
				if role=="grass_energy":fx_disc(im,q,radius+3.0,light,radius+2.0)
				elif role=="grass_bomb":grass_leaf(im,q,-PI*.5,9.0,light,dark)
				elif role=="grass_leech":fx_line(im,q,q+Vector2(4,7),1.0,dark)
				elif role=="grass_worry":fx_disc(im,q,2.0,Color("#fff2a3"))
		"grass_spore","grass_sleep","grass_stun","grass_cotton","grass_aroma":
			var count:int=17 if role=="grass_spore" else 12 if role=="grass_sleep" else 10 if role=="grass_stun" else 6 if role=="grass_cotton" else 9
			if role=="grass_sleep":light=Color("#c6b9e9")
			if role=="grass_stun":light=Color("#e6cc65")
			if role=="grass_cotton":light=Color("#e7f4db")
			if role=="grass_aroma":light=Color("#f4b4cd")
			for i in range(count):
				var a:float=float(i)*2.399+t*1.4
				var q:=center+Vector2(cos(a),sin(a))*(4.0+t*14.0)*(.4+float(i%5)*.15)
				var radius:float=5.0 if role=="grass_cotton" else 2.0+float(i%2)
				fx_disc(im,q,radius,dark);fx_disc(im,q-Vector2(1,1),radius*.7,light)
				if role=="grass_aroma":grass_leaf(im,q,a,6.0,light,dark)
		"grass_synthesis":
			for i in range(8):
				var a:float=float(i)*TAU/8.0+t*.5
				var d:=Vector2(cos(a),sin(a))
				fx_line(im,center+d*(5.0+t*5.0),center+d*(12.0+t*7.0),2.5,Color("#fff2a3"))
			fx_disc(im,center,7.0+sin(t*PI)*4.0,light)
		"grass_whistle":
			for i in range(4):
				var q:=Vector2(5+fposmod(float(i)*10+t*26.0,36.0),24+sin(float(i)*2.2+t*TAU)*9.0)
				fx_disc(im,q,3.0,light);fx_line(im,q,q-Vector2(0,9),1.7,dark);fx_line(im,q-Vector2(0,9),q+Vector2(5,-6),1.5,light)

func ice_crystal(im:Image,p:Vector2,a:float,r:float,light:Color,dark:Color)->void:
	var d:=Vector2(cos(a),sin(a))
	var side:=Vector2(-d.y,d.x)
	fx_line(im,p-d*r*.55,p+d*r,3.5,dark)
	fx_line(im,p-side*r*.34,p+d*r,2.0,light)
	fx_line(im,p+side*r*.34,p+d*r,1.5,Color.WHITE)
	fx_disc(im,p,2.0,light)

func ice_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var center:=Vector2(24,24)
	var light:=Color("#bdf6ff");var dark:=Color("#426ab7")
	match role:
		"ice_aurora","ice_beam":
			for i in range(3):
				var prev:=Vector2(3,24+float(i-1)*4)
				for j in range(1,11):
					var x:float=3.0+float(j)*4.1
					var q:=Vector2(x,24+float(i-1)*4+sin(float(j)*.8+t*TAU)*(4.0 if role=="ice_aurora" else .9))
					var tint:Color=Color("#79e7db").lerp(Color("#d9aaff"),float(i)*.5) if role=="ice_aurora" else light
					fx_line(im,prev,q,4.0,dark);fx_line(im,prev,q,2.0,tint);prev=q
			if role=="ice_beam":
				for i in range(5):ice_crystal(im,Vector2(6+fposmod(float(i)*9+t*30,36),24),PI*.5,6.0,light,dark)
		"ice_wind","ice_powder","ice_blizzard","ice_haze","ice_mist":
			var count:int=8 if role=="ice_wind" else 16 if role=="ice_powder" else 24 if role=="ice_blizzard" else 11 if role=="ice_haze" else 6
			for i in range(count):
				var x:float=4.0+fposmod(float(i)*13+t*38,40.0)
				var y:float=7.0+float(posmod(i*17,34))+sin(t*TAU+float(i))*3.0
				var q:=Vector2(x,y)
				if role=="ice_haze" or role=="ice_mist":
					fx_disc(im,q,5.0+float(i%3),Color("#7583a6" if role=="ice_haze" else "#d5f5f8",.48))
				elif role=="ice_blizzard":
					ice_crystal(im,q,-.4,4.0+float(i%3),light,dark)
					fx_line(im,q-Vector2(9,3),q,1.2,light)
				else:
					fx_disc(im,q,1.4+float(i%2),light)
					if role=="ice_wind":fx_line(im,q-Vector2(7,1),q,1.1,dark)
		"ice_punch":
			var q:=Vector2(24+sin(t*PI)*10,24)
			fx_line(im,Vector2(4,24),q,7.0,dark);fx_disc(im,q,10.0,light)
			for i in range(5):ice_crystal(im,q,float(i)*TAU/5.0,9.0,dark,Color("#638ccb"))
		"ice_fang":
			var close:float=sin(t*PI)*7.0
			for i in range(3):
				var x:float=12.0+float(i)*12.0
				ice_crystal(im,Vector2(x,8+close),PI*.5,10.0,light,dark)
				ice_crystal(im,Vector2(x,40-close),-PI*.5,10.0,light,dark)
		"ice_shard","ice_spear":
			var count:int=1 if role=="ice_shard" else 5
			for i in range(count):
				var q:=Vector2(9+fposmod(t*31.0+float(i)*10.0,30.0),24+sin(float(i)*2+t*TAU)*5.0)
				ice_crystal(im,q,0.0,13.0 if count==1 else 8.0,light,dark)
		"ice_ball":
			var q:=Vector2(9+28*t,25)
			var radius:float=8.0+sin(t*PI)*3.0
			fx_disc(im,q,radius,dark);fx_disc(im,q,radius-2.0,light)
			for i in range(6):ice_crystal(im,q,float(i)*TAU/6.0+t*TAU,6.0,light,dark)
		"ice_hail":
			for i in range(9):
				var q:=Vector2(5+float(posmod(i*13,38)),3+fposmod(float(i)*11+t*40,42))
				fx_line(im,q-Vector2(0,7),q,1.0,light);ice_crystal(im,q,PI*.5,4.0,light,dark)
		"ice_cold":
			for i in range(8):ice_crystal(im,center,float(i)*TAU/8.0,5.0+sin(t*PI)*17.0,light,dark)
			fx_disc(im,center,7.0,Color.WHITE)
		"ice_avalanche":
			for i in range(7):
				var q:=Vector2(6+float(i)*6,8+fposmod(float(i)*7+t*36,31))
				ice_crystal(im,q,PI*.5,6.0+float(i%3),light,dark)

func earth_rock(im:Image,q:Vector2,r:float,light:Color,dark:Color)->void:
	fx_line(im,q+Vector2(-r,r*.3),q+Vector2(-r*.45,-r),r*.85,dark)
	fx_line(im,q+Vector2(-r*.45,-r),q+Vector2(r*.8,-r*.5),r*.85,dark)
	fx_line(im,q+Vector2(r*.8,-r*.5),q+Vector2(r*.6,r*.7),r,dark)
	fx_line(im,q+Vector2(-r*.6,-r*.4),q+Vector2(r*.4,r*.2),r*.65,light)

func earth_bone(im:Image,q:Vector2,a:float,length:float,light:Color,dark:Color)->void:
	var d:=Vector2(cos(a),sin(a))
	var n:=Vector2(-d.y,d.x)
	var start:=q-d*length*.5
	var end:=q+d*length*.5
	fx_line(im,start,end,5.0,dark);fx_line(im,start,end,3.0,light)
	for tip in [start,end]:
		fx_disc(im,tip+n*2.5,3.5,dark);fx_disc(im,tip-n*2.5,3.5,dark)
		fx_disc(im,tip+n*2.5,2.2,light);fx_disc(im,tip-n*2.5,2.2,light)

func earth_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var center:=Vector2(24,27)
	var light:=Color("#d8b47d");var dark:=Color("#76503d")
	match role:
		"earth_dig":
			for i in range(10):
				var a:float=float(i)*TAU/10.0
				var q:=center+Vector2(cos(a)*15.0,sin(a)*5.0)
				earth_rock(im,q+Vector2(0,-sin(t*PI)*float(4+i%4*3)),3.0,light,dark)
			fx_disc(im,center,8.0,Color("#352e2d"),5.0)
		"earth_tomb":
			for i in range(14):
				var f:float=float(i)/14.0
				var a:float=f*TAU*1.8+t*TAU
				var q:=center+Vector2(cos(a)*(5.0+f*13.0),sin(a)*(5.0+f*13.0)*.45-f*10.0)
				fx_disc(im,q,2.4+f*2.0,Color("#c9a66a"));fx_disc(im,q,1.3,light)
		"earth_slap","earth_dust","earth_mudcoat":
			var count:int=8 if role=="earth_slap" else 17 if role=="earth_dust" else 12
			for i in range(count):
				var f:float=float(i)/float(count)
				var a:float=f*TAU+t*1.7
				var q:=Vector2(5+fposmod(f*40+t*24.0,38.0),24+sin(a)*10.0)
				if role=="earth_mudcoat":q=center+Vector2(cos(a)*14,sin(a)*8)
				fx_disc(im,q,3.0 if role=="earth_slap" else 1.3 if role=="earth_dust" else 4.0,dark if role!="earth_dust" else light)
				if role!="earth_dust":fx_disc(im,q-Vector2(1,1),1.6,light)
		"earth_shot","earth_bomb":
			var q:=Vector2(9+28*t,24-sin(t*PI)*(11.0 if role=="earth_bomb" else 2.5))
			var r:float=7.0 if role=="earth_bomb" else 4.5
			fx_disc(im,q,r,dark);fx_disc(im,q-Vector2(1,2),r*.65,light)
			for i in range(5):
				var a:float=float(i)*TAU/5.0
				fx_disc(im,q+Vector2(cos(a),sin(a))*(r+2.0+t*3.0),1.8,dark)
		"earth_club","earth_rush","earth_return":
			var ivory:=Color("#f3e9cd");var shade:=Color("#8c785c")
			if role=="earth_club":
				earth_bone(im,center,-1.6+t*2.8,28.0,ivory,shade)
			elif role=="earth_rush":
				for i in range(3):earth_bone(im,Vector2(10+float(i)*13,23+sin(t*TAU+float(i))*8),-.8+t*1.8,16.0,ivory,shade)
			else:
				earth_bone(im,Vector2(8+sin(t*PI)*31,22),t*TAU*2.0,24.0,ivory,shade)
		"earth_power":
			for i in range(7):
				var x:float=5.0+float(i)*6
				var rise:float=sin(t*PI)*float(9+i%3*8)
				fx_line(im,Vector2(x,43),Vector2(x,43-rise),5.5,Color("#ad7440"))
				earth_rock(im,Vector2(x,40-rise),4.0,Color("#ffdc92"),dark)
		"earth_fissure":
			var last:=Vector2(4,40)
			for i in range(1,10):
				var q:=Vector2(4+float(i)*4.3,40-float(i)*3.3+sin(float(i)*2.7)*4)
				fx_line(im,last,q,3.0+t*5.0,Color("#352b2a"));fx_line(im,last+Vector2(0,3),q+Vector2(0,3),1.4,light);last=q
		"earth_spikes":
			for i in range(7):
				var x:float=7.0+float(i%4)*11.0
				var y:float=33.0+float(i/4)*5.0
				fx_line(im,Vector2(x-3,y),Vector2(x,y-6-t*11),3.0,dark)
				fx_line(im,Vector2(x+3,y),Vector2(x,y-6-t*11),1.5,light)
		"earth_quake","earth_magnitude":
			var count:int=8 if role=="earth_quake" else 5
			for i in range(count):
				var a:float=float(i)*TAU/float(count)+(.2 if role=="earth_magnitude" else 0.0)
				var d:=Vector2(cos(a),sin(a)*.65)
				var q:=center+d*(5.0+t*17.0)
				fx_line(im,center,center+d*7+Vector2(-2,1),2.0,dark)
				fx_line(im,center+d*7+Vector2(-2,1),q,2.7,dark)
				earth_rock(im,q-Vector2(0,sin(t*PI)*float(3+i%3*3)),3.0,light,dark)
			if role=="earth_magnitude":fx_disc(im,center,4.0+t*9.0,light,3.0+t*9.0)

# Rock silhouettes use angular mineral facets instead of the softer earth palette.
func mineral(im:Image,q:Vector2,r:float,a:float,light:Color,dark:Color)->void:
	var corners:Array[Vector2]=[]
	for i in range(6):
		var theta:float=float(i)*TAU/6.0+a
		var length:float=r*(.82+float(i%3)*.09)
		corners.append(q+Vector2(cos(theta),sin(theta))*length)
	for i in range(6):
		var v:Vector2=corners[i]
		var w:Vector2=corners[(i+1)%6]
		for k in range(1,6):
			var f:float=float(k)/6.0
			fx_line(im,q,v.lerp(w,f),r*.28,dark.lightened(.08*float(i%3)))
		fx_line(im,v,w,1.3,dark.darkened(.38))
	fx_line(im,corners[3],corners[4],1.4,light)
	fx_line(im,corners[4],q-Vector2(1,1),1.0,light)

func rock_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var center:=Vector2(24,24)
	var light:=Color("#c3b5a3");var dark:=Color("#655d60")
	match role:
		"rock_throw":
			var q:=Vector2(9+28*t,29-sin(t*PI)*16.0)
			mineral(im,q,8.0,t*TAU,light,dark)
		"rock_slide":
			for i in range(7):
				var q:=Vector2(6+float(i)*6,4+fposmod(float(i)*8+t*38,39))
				mineral(im,q,4.0+float(i%3),t*3.0+float(i),light,dark)
		"rock_tomb":
			for i in range(5):
				var a:float=float(i)*TAU/5.0
				var q:=center+Vector2(cos(a)*14,sin(a)*8)+Vector2(0,-(1.0-t)*14.0)
				mineral(im,q,6.0,0.3+float(i),light,dark)
		"rock_ancient":
			for i in range(5):
				var a:float=float(i)*TAU/5.0+t*TAU
				var q:=center+Vector2(cos(a)*14,sin(a)*14)
				mineral(im,q,5.0,a,Color("#e9d7a6"),Color("#806852"))
			fx_disc(im,center,4.0+t*3.0,Color("#f4dca1"))
		"rock_wrecker":
			var q:=Vector2(10+27*t,24)
			mineral(im,q,13.0,t*2.0,light,dark)
			for i in range(4):fx_line(im,q-Vector2(18,float(i-2)*4),q-Vector2(10,float(i-2)*4),1.0,light)
		"rock_edge":
			for i in range(5):
				var x:float=7.0+float(i)*8.0
				ice_crystal(im,Vector2(x,37-sin(t*PI)*8.0),-PI*.5,8.0+float(i%3)*3,light,dark)
		"rock_gem":
			for i in range(3):
				var q:=Vector2(8+fposmod(float(i)*13+t*33,33),24+sin(float(i)*2+t*TAU)*6)
				mineral(im,q,7.0,PI*.25,Color("#e9faff"),Color("#55a8bb"))
				fx_line(im,q-Vector2(8,0),q+Vector2(8,0),1.0,Color.WHITE)
				fx_line(im,q-Vector2(0,8),q+Vector2(0,8),1.0,Color.WHITE)
		"rock_smash":
			var q:=Vector2(12+sin(t*PI)*20,24)
			mineral(im,q,11.0,-.5+t,light,dark)
			for i in range(5):
				var a:float=float(i)*TAU/5.0
				fx_line(im,q+Vector2(cos(a),sin(a))*12,q+Vector2(cos(a),sin(a))*(14+t*7),2.0,light)
		"rock_blast":
			for i in range(5):
				var q:=Vector2(5+fposmod(float(i)*9+t*33,38),24+sin(float(i)*2+t*TAU)*8)
				mineral(im,q,4.0,float(i)+t*TAU,light,dark)
		"rock_roll":
			var q:=Vector2(10+28*t,29)
			mineral(im,q,10.0,t*TAU*2.0,light,dark)
			for i in range(4):fx_disc(im,q-Vector2(10+float(i)*4,-3),2.0,Color("#9f8a77",.65))
		"rock_polish":
			mineral(im,center,12.0,t*.6,Color("#f7f2db"),Color("#8d8d95"))
			for i in range(4):
				var a:float=float(i)*TAU/4.0+t*TAU
				var q:=center+Vector2(cos(a),sin(a))*15.0
				fx_line(im,q-Vector2(3,0),q+Vector2(3,0),1.5,Color.WHITE)
				fx_line(im,q-Vector2(0,3),q+Vector2(0,3),1.5,Color.WHITE)
		"rock_storm":
			for i in range(22):
				var x:float=3.0+fposmod(float(i)*11+t*42,42)
				var y:float=6.0+float(posmod(i*13,35))
				fx_line(im,Vector2(x-5,y+2),Vector2(x,y),1.3,Color("#d3b77a"))
				if i%4==0:mineral(im,Vector2(x,y),2.5,t,light,dark)
		"rock_trap":
			for i in range(6):
				var a:float=float(i)*TAU/6.0
				var q:=center+Vector2(cos(a)*13,sin(a)*7)+Vector2(0,8*(1.0-t))
				mineral(im,q,5.0,a,light,dark)
			fx_disc(im,center,11.0,Color("#998e7a",.65),10.0)

# Original hand-to-hand effect primitives. These are contact silhouettes, not
# species-specific skeleton animations. The trajectory stays in the actual hit tiles.
func fight_arc(im:Image,c:Vector2,r:float,start:float,sweep:float,light:Color,dark:Color,width:float)->void:
	var last:=c+Vector2(cos(start),sin(start))*r
	for j in range(1,17):
		var a:float=start+sweep*float(j)/16.0
		var q:=c+Vector2(cos(a),sin(a))*r
		fx_line(im,last,q,width,dark)
		fx_line(im,last,q,width*.42,light)
		last=q

func fight_burst(im:Image,c:Vector2,r:float,rays:int,t:float,light:Color,dark:Color)->void:
	for j in range(rays):
		var a:float=float(j)*TAU/float(rays)+t*.45
		var d:=Vector2(cos(a),sin(a))
		fx_line(im,c+d*r*.25,c+d*r,3.0,dark)
		fx_line(im,c+d*r*.35,c+d*r*.85,1.1,light)

func fight_fist(im:Image,c:Vector2,a:float,r:float,light:Color,dark:Color)->void:
	var d:=Vector2(cos(a),sin(a))
	var n:=Vector2(-d.y,d.x)
	fx_line(im,c-d*r*1.35,c,r*.85,dark)
	fx_disc(im,c,r,dark)
	for j in range(4):
		var p:=c+d*r*.55+n*float(j-1.5)*r*.40
		fx_disc(im,p,r*.36,light)
	fx_disc(im,c-d*r*.45+n*r*.45,r*.4,light)

func fight_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var c:=Vector2(24,24)
	var light:=Color("#fff2c0");var dark:=Color("#c66146")
	match role:
		"fight_chop","fight_cross","fight_break","fight_stonebreak":
			var offset:float=sin(t*PI)*5.0
			var p:=c+Vector2(offset,0)
			fx_line(im,p-Vector2(13,14),p+Vector2(12,13),5.0,dark)
			fx_line(im,p-Vector2(13,14),p+Vector2(12,13),2.0,light)
			if role=="fight_cross":
				fx_line(im,p+Vector2(-13,14),p+Vector2(13,-14),5.0,dark)
				fx_line(im,p+Vector2(-13,14),p+Vector2(13,-14),2.0,light)
			elif role in ["fight_break","fight_stonebreak"]:
				for i in range(5 if role=="fight_break" else 8):
					var a:float=float(i)*2.399
					earth_rock(im,c+Vector2(cos(a),sin(a))*(5.0+t*15.0),3.0 if role=="fight_break" else 4.0,Color("#d1b491"),Color("#795c52"))
		"fight_focus","fight_dynamic","fight_mach","fight_palm","fight_drain","fight_slap","fight_hammer","fight_uppercut":
			var q:=Vector2(11+sin(t*PI)*21,24)
			var a:float=0.0
			var r:float=7.0
			match role:
				"fight_focus":r=10.0;dark=Color("#d18a2f")
				"fight_dynamic":r=9.0;dark=Color("#a64b5a")
				"fight_mach":r=5.0;dark=Color("#df9775")
				"fight_palm":r=8.0
				"fight_drain":light=Color("#d7f6a2");dark=Color("#598751")
				"fight_slap":a=.7+t*1.1;r=6.0
				"fight_hammer":a=1.4;q=Vector2(24,8+sin(t*PI)*24);r=10.0
				"fight_uppercut":a=-PI*.5;q=Vector2(24,37-sin(t*PI)*23);r=8.0
			fight_fist(im,q,a,r,light,dark)
			if role=="fight_palm" or role=="fight_slap":
				for i in range(4):fx_line(im,q+Vector2(2,float(i-2)*3),q+Vector2(10,float(i-2)*4),2.0,light)
			elif role=="fight_mach":
				for i in range(3):fx_line(im,q-Vector2(16,float(i-1)*5),q-Vector2(6,float(i-1)*5),1.6,light)
			elif role=="fight_drain":
				for i in range(4):fx_disc(im,Vector2(39-fposmod(t*32+float(i)*8,32),34+sin(float(i)+t*TAU)*4),2.5,light)
			else:fight_burst(im,q,10.0+sin(t*PI)*9.0,5 if role=="fight_dynamic" else 4,t,light,dark)
		"fight_lowkick","fight_jumpkick","fight_highkick","fight_roundkick","fight_double","fight_triple":
			var count:int=2 if role=="fight_double" else 3 if role=="fight_triple" else 1
			var base:float=PI*.16 if role=="fight_lowkick" else -PI*.7 if role=="fight_highkick" else -PI*.33 if role=="fight_jumpkick" else t*TAU if role=="fight_roundkick" else -PI*.15
			for i in range(count):
				var a:float=base+t*1.3+float(i)*.65
				var q:=c+Vector2(0,9 if role=="fight_lowkick" else -7 if role=="fight_highkick" else 0)
				fight_arc(im,q,12.0+float(i)*3,a,1.65 if role!="fight_roundkick" else 4.2,light,dark,4.0)
				var tip:=q+Vector2(cos(a+1.4),sin(a+1.4))*13.0
				fx_line(im,tip,tip+Vector2(5,2),5.0,dark);fx_line(im,tip,tip+Vector2(5,2),2.0,light)
		"fight_close","fight_thrust","fight_super":
			var count:int=6 if role=="fight_close" else 4 if role=="fight_thrust" else 3
			for i in range(count):
				var f:float=fposmod(t*1.7+float(i)/float(count),1.0)
				var a:float=0.0 if role=="fight_thrust" else float(i)*TAU/float(count)
				var q:=c+Vector2(cos(a)*12.0,sin(a)*11.0)*(1.0-f)
				fight_fist(im,q,a+PI if role!="fight_thrust" else 0.0,4.0 if role!="fight_super" else 7.0,light,dark)
			if role=="fight_super":fight_burst(im,c,18.0,8,t,light,dark)
		"fight_blast","fight_aura","fight_vacuum":
			if role=="fight_vacuum":
				for i in range(3):fight_arc(im,Vector2(8+float(i)*11+sin(t*TAU)*3,24),13.0,-PI*.43,PI*.86,Color("#dff9ff"),Color("#6d9bab"),3.0)
			else:
				var q:=Vector2(9+27*t,24)
				var radius:float=9.0+sin(t*PI)*4.0 if role=="fight_blast" else 7.0+sin(t*PI)*3.0
				var outer:=Color("#c27b58") if role=="fight_blast" else Color("#3567bf")
				var inner:=Color("#fff1be") if role=="fight_blast" else Color("#bcefff")
				fx_disc(im,q,radius,outer);fx_disc(im,q,radius*.72,inner)
				fight_arc(im,q,radius+3.0,t*TAU,PI*1.5,inner,outer,2.0)
				if role=="fight_blast":fight_burst(im,q,16.0,7,t,inner,outer)
		"fight_submission","fight_toss","fight_vital":
			var a:float=t*TAU if role=="fight_submission" else -PI*.5+t*PI if role=="fight_toss" else PI*.2+t*PI
			fight_arc(im,c,15.0,a,PI*1.4,light,dark,4.0)
			fight_fist(im,c+Vector2(cos(a)*9,sin(a)*9),a,5.0,light,dark)
			fight_fist(im,c-Vector2(cos(a)*9,sin(a)*9),a+PI,4.0,light,dark)
			if role=="fight_toss":fx_line(im,Vector2(24,39),Vector2(24,39-sin(t*PI)*29),2.0,light)
		"fight_bulk","fight_detect","fight_counter","fight_revenge","fight_reversal":
			var tint:=Color("#ffa87b") if role=="fight_revenge" else Color("#d6e8ff") if role=="fight_detect" else light
			var radius:float=5.0+t*15.0
			if role=="fight_bulk":
				for i in range(3):fight_arc(im,c,6.0+float(i)*5+t*3.0,PI,PI*2.0,tint,dark,2.0)
			elif role=="fight_detect":
				fight_arc(im,c,radius,-PI*.5,TAU,tint,Color("#638db5"),2.8)
				fx_line(im,Vector2(14,24),Vector2(34,24),1.2,tint)
			elif role=="fight_counter":
				fight_arc(im,c,radius,0,PI,tint,dark,3.0);fight_arc(im,c,radius,PI,PI,tint,dark,1.8)
				fight_burst(im,c,8.0+t*9.0,4,t,tint,dark)
			elif role=="fight_revenge":
				fight_burst(im,c,8.0+t*13.0,10,t,tint,Color("#a54142"))
			else:
				fight_arc(im,c,15.0,t*TAU,-PI*1.5,tint,dark,3.5);fight_fist(im,Vector2(36-24*t,24),PI,6.0,tint,dark)

# Original feather and moving air silhouettes, separated from creature anatomy.
func air_feather(im:Image,q:Vector2,a:float,r:float,light:Color,dark:Color)->void:
	var d:=Vector2(cos(a),sin(a))
	var side:=Vector2(-d.y,d.x)
	for j in range(1,9):
		var f:float=float(j)/9.0
		var at:=q+d*r*f
		var w:float=sin(f*PI)*r*.24
		fx_line(im,at,at+side*w-d*r*.17,1.6,light)
		fx_line(im,at,at-side*w-d*r*.17,1.6,dark)
	fx_line(im,q,q+d*r,1.0,light)

func air_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var c:=Vector2(24,24)
	var light:=Color("#e5f9ff");var dark:=Color("#719bb4")
	match role:
		"air_cutter","air_slash","air_ace":
			var count:int=3 if role=="air_cutter" else 1 if role=="air_slash" else 2
			for i in range(count):
				var q:=Vector2(12+sin(t*PI)*19,24+float(i)*6-float(count-1)*3)
				var a:float=-PI*.75+t*.7+float(i)*.35
				fight_arc(im,q,13.0 if role=="air_slash" else 9.0,a,PI*1.25,light,dark,5.0 if role=="air_slash" else 3.0)
				if role=="air_ace":fx_line(im,q-Vector2(17,7),q+Vector2(6,1),1.2,light)
		"air_gust","air_tailwind","air_defog","air_blast":
			var count:int=5 if role=="air_gust" else 3 if role=="air_tailwind" else 8 if role=="air_defog" else 7
			for i in range(count):
				var f:float=float(i)/float(count)
				var y:float=7.0+f*35.0
				var prev:=Vector2(3,y)
				for j in range(1,12):
					var x:float=3.0+float(j)*3.8
					var q:=Vector2(x,y+sin(float(j)*.65+t*TAU+f*4.0)*(3.0 if role!="air_blast" else 1.5))
					fx_line(im,prev,q,3.2 if role=="air_blast" else 1.6,dark)
					fx_line(im,prev,q,1.0,light);prev=q
			if role=="air_blast":fight_arc(im,Vector2(29,24),14.0,-PI*.45,PI*.9,light,dark,3.0)
			elif role=="air_tailwind":air_feather(im,Vector2(10+sin(t*PI)*15,31),-.6,13.0,light,dark)
			elif role=="air_defog":
				for i in range(5):fx_disc(im,Vector2(6+float(i)*8,12+sin(t*TAU+float(i))*8),4.0*(1.0-t),Color(light,.4))
		"air_sky","air_fly","air_bounce","air_brave":
			var q:=Vector2(8+31*t,33-sin(t*PI)*(20.0 if role=="air_fly" else 12.0 if role=="air_bounce" else 17.0))
			var tint:=Color("#ffbf72") if role=="air_brave" else Color("#c9e6ff") if role=="air_sky" else light
			var shade:=Color("#d66b4a") if role=="air_brave" else dark
			if role=="air_sky":q=Vector2(25,4+34*t)
			if role=="air_bounce":q=Vector2(24,34-absf(sin(t*TAU))*23)
			for i in range(5):
				var f:float=float(i)/5.0
				var at:=q-Vector2(f*16.0,f*7.0)
				fx_disc(im,at,8.0*(1.0-f*.7),shade)
				fx_disc(im,at,5.0*(1.0-f*.7),tint)
			air_feather(im,q,-2.5,13.0,tint,shade)
			air_feather(im,q,2.5,13.0,tint,shade)
			if role=="air_brave":fight_burst(im,q,14.0,7,t,tint,shade)
		"air_peck","air_drill","air_pluck":
			var q:=Vector2(10+sin(t*PI)*22,24)
			var count:int=3 if role=="air_drill" else 1
			for i in range(count):
				var at:=q-Vector2(float(i)*7,sin(t*TAU+float(i))*4.0)
				fx_line(im,at+Vector2(-9,-5),at+Vector2(8,0),3.6,dark)
				fx_line(im,at+Vector2(-9,5),at+Vector2(8,0),2.2,light)
			if role=="air_pluck":air_feather(im,q+Vector2(3,-9),-2.0+t,15.0,Color("#ffe0a0"),dark)
		"air_wing","air_feather","air_roost":
			var count:int=2 if role=="air_wing" else 9 if role=="air_feather" else 5
			for i in range(count):
				var a:float=float(i)*TAU/float(count)+t*2.5
				var q:=c+Vector2(cos(a),sin(a))*float(7+i%3*4)
				if role=="air_wing":q=Vector2(23+float(i*2-1)*5,24)
				if role=="air_roost":q=Vector2(8+float(i)*7,30+sin(t*PI)*5)
				air_feather(im,q,a,17.0 if role=="air_wing" else 10.0,light,dark)
			if role=="air_roost":fx_disc(im,Vector2(24,34),12.0+t*3.0,Color("#a1e6c2"),11.0+t*3.0)
		"air_chatter":
			for i in range(6):
				var a:float=float(i)*TAU/6.0+t
				var q:=c+Vector2(cos(a),sin(a))*(6.0+t*13.0)
				fx_disc(im,q,2.5,Color("#e4d5ff"))
				fx_line(im,q,q-Vector2(0,8),1.4,dark)
				fx_line(im,q-Vector2(0,8),q+Vector2(4,-5),1.4,light)
		"air_mirror":
			var radius:float=10.0+sin(t*PI)*5.0
			fx_disc(im,c,radius,Color("#92d6eb",.65))
			fx_disc(im,c,radius,light,radius-2.0)
			fx_line(im,c-Vector2(7,6),c+Vector2(5,-10),2.2,Color.WHITE)
			for i in range(3):
				var a:float=float(i)*TAU/3.0+t*TAU
				var q:=c+Vector2(cos(a),sin(a))*(radius+4.0)
				fx_line(im,q-Vector2(3,0),q+Vector2(3,0),1.0,light)
				fx_line(im,q-Vector2(0,3),q+Vector2(0,3),1.0,light)

# Original poison FX: differentiated silhouettes and trajectories, not ROM sprites.
func poison_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var c:=Vector2(24,24)
	var light:=Color("#d8a2ff");var dark:=Color("#773d9d");var acid:=Color("#b5ee65")
	match role:
		"poison_smog","poison_gas","poison_powder":
			var count:int=7 if role=="poison_smog" else 5 if role=="poison_gas" else 18
			for i in range(count):
				var a:float=float(i)*TAU/float(count)+t*2.1
				var q:=c+Vector2(cos(a),sin(a))*(6.0+t*12.0)
				if role=="poison_gas":q=Vector2(8+float(i)*7,29-sin(t*PI+float(i)) * 7.0)
				if role=="poison_powder":q=Vector2(5+float(i%6)*7,5+float(i/6)*11+t*5.0)
				var r:float=6.0 if role=="poison_smog" else 8.0 if role=="poison_gas" else 1.5
				fx_disc(im,q,r,Color(dark,.68))
				fx_disc(im,q-Vector2(1,2),r*.57,Color(light,.8))
		"poison_toxic":
			for i in range(3):
				var r:float=6.0+float(i)*5.0+sin(t*TAU)*2.0
				fx_disc(im,c,r,Color(dark,.8),r-1.7)
			fx_line(im,c-Vector2(5,6),c+Vector2(5,6),3.2,acid)
			fx_line(im,c+Vector2(-5,6),c+Vector2(5,-6),3.2,acid)
		"poison_fang":
			var gap:float=10.0-sin(t*PI)*7.0
			for i in [-1,1]:
				var q:=c+Vector2(0,gap*float(i))
				fx_line(im,q+Vector2(-9,0),q+Vector2(-5,-float(i)*7),4.0,light)
				fx_line(im,q+Vector2(9,0),q+Vector2(5,-float(i)*7),4.0,light)
			fx_disc(im,c,2.0+t*3.0,acid)
		"poison_sting","poison_jab":
			var q:=Vector2(8+30*t,24)
			var count:int=3 if role=="poison_sting" else 1
			for i in range(count):
				var at:=q-Vector2(float(i)*7,float(i-1)*7)
				fx_line(im,at-Vector2(13,0),at,2.0 if role=="poison_sting" else 7.0,dark)
				fx_line(im,at-Vector2(6,0),at+Vector2(4,0),1.5 if role=="poison_sting" else 3.0,acid)
		"poison_armor":
			for i in range(6):
				var a:float=float(i)*TAU/6.0+t*TAU
				var b:float=a+TAU/6.0
				var r:float=15.0+sin(t*PI)*3.0
				fx_line(im,c+Vector2(cos(a),sin(a))*r,c+Vector2(cos(b),sin(b))*r,4.0,dark)
				fx_disc(im,c+Vector2(cos(a),sin(a))*r,2.0,light)
		"poison_sludge","poison_bomb","poison_gunk":
			var q:=Vector2(7+32*t,24)
			if role=="poison_bomb":q.y-=sin(t*PI)*14.0
			var r:float=6.0 if role=="poison_sludge" else 9.0 if role=="poison_bomb" else 12.0
			fx_disc(im,q,r,dark)
			fx_disc(im,q-Vector2(2,3),r*.62,light)
			for i in range(5 if role=="poison_gunk" else 3):
				var a:float=float(i)*TAU/5.0+t
				var at:=q+Vector2(cos(a),sin(a))*r*1.2
				fx_disc(im,at,2.0 if role!="poison_gunk" else 3.5,acid if role=="poison_bomb" else dark)
		"poison_tail","poison_cross":
			fight_arc(im,c,14.0,-PI+t*1.8,PI*1.2,light,dark,4.0)
			if role=="poison_cross":
				fx_line(im,c+Vector2(-13,-13),c+Vector2(13,13),3.5,acid)
				fx_line(im,c+Vector2(-13,13),c+Vector2(13,-13),3.5,light)
			else:fx_disc(im,c+Vector2(cos(t*TAU),sin(t*TAU))*14.0,3.0,acid)
		"poison_acid","poison_gastro":
			for i in range(6):
				var q:=Vector2(6+float(i)*6+sin(t*TAU+float(i))*3.0,24+sin(float(i)*1.7+t*5.0)*8.0)
				fx_line(im,q-Vector2(3,4),q+Vector2(2,4),2.5,acid if role=="poison_acid" else light)
				fx_disc(im,q+Vector2(2,4),2.0,dark)
			if role=="poison_gastro":fx_disc(im,c,11.0+t*4.0,Color(dark,.8),9.0+t*4.0)
		"poison_spikes":
			for i in range(5):
				var q:=Vector2(6+float(i)*8,32+float(i%2)*5)
				var h:float=5.0+sin(t*PI)*10.0
				fx_line(im,q-Vector2(3,0),q-Vector2(0,h),3.0,dark)
				fx_line(im,q+Vector2(3,0),q-Vector2(0,h),2.0,acid)

# Original insect FX. Flight paths are based on affected tiles, not camera orientation.
func bug_wing(im:Image,q:Vector2,a:float,r:float,light:Color,dark:Color)->void:
	var dir:=Vector2(cos(a),sin(a))
	var side:=Vector2(-dir.y,dir.x)
	for sign_value in [-1,1]:
		var wing:=q+side*float(sign_value)*r*.62
		fx_disc(im,wing,r*.57,Color(light,.72))
		fx_line(im,q,wing+dir*r*.45,1.4,dark)
	fx_line(im,q-dir*r*.5,q+dir*r*.5,2.0,dark)

func bug_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var c:=Vector2(24,24)
	var light:=Color("#e1ed91");var dark:=Color("#647b35");var silk:=Color("#f4f2e4")
	match role:
		"bug_string":
			var prev:=Vector2(3,24)
			for j in range(1,16):
				var f:float=float(j)/15.0
				var q:=Vector2(3+40*f*t,24+sin(f*TAU*2.0-t*TAU)*5.0*f)
				fx_line(im,prev,q,3.0,dark);fx_line(im,prev,q,1.5,silk);prev=q
		"bug_web":
			var r:float=9.0+11.0*t
			for i in range(8):
				var a:float=float(i)*TAU/8.0
				var b:float=a+TAU/8.0
				var dir:=Vector2(cos(a),sin(a))
				fx_line(im,c,c+dir*r,1.6,silk)
				for j in range(1,4):
					var scale_value:float=r*float(j)/3.0
					fx_line(im,c+dir*scale_value,c+Vector2(cos(b),sin(b))*scale_value,1.2,light)
		"bug_leech","bug_bite":
			var gap:float=13.0-sin(t*PI)*9.0
			for i in [-1,1]:
				var q:=c+Vector2(float(i)*gap,0)
				fx_line(im,q+Vector2(0,-9),q+Vector2(-float(i)*7,-3),4.0,dark)
				fx_line(im,q+Vector2(0,9),q+Vector2(-float(i)*7,3),3.0,light)
			if role=="bug_leech":
				for i in range(5):fx_disc(im,Vector2(35-27*t-float(i)*3.0,24+sin(t*TAU+float(i))*5.0),2.2,Color("#f6db73"))
			else:fight_burst(im,c,6.0+t*9.0,5,t,light,dark)
		"bug_silver":
			for i in range(6):
				var q:=Vector2(4+float(i)*7,12+sin(t*TAU+float(i))*9.0)
				fight_arc(im,q,8.0,-PI*.5,PI,Color("#f1ffff"),Color("#7eb0af"),2.4)
				fx_disc(im,q+Vector2(2,15),1.5,silk)
		"bug_signal":
			for i in range(3):
				var prev:=Vector2(2,20+float(i)*4)
				for j in range(1,15):
					var f:float=float(j)/14.0
					var q:=Vector2(2+43*f,24+sin(f*TAU*2.0+t*TAU+float(i)*2.1)*6.0)
					fx_line(im,prev,q,3.0,[Color("#fa829d"),Color("#7edbe4"),light][i]);prev=q
		"bug_twin","bug_pin","bug_horn":
			var count:int=2 if role=="bug_twin" else 5 if role=="bug_pin" else 1
			for i in range(count):
				var q:=Vector2(7+32*t-float(i%3)*5,24+float(i)*6-float(count-1)*3)
				var length:float=19.0 if role=="bug_horn" else 10.0
				fx_line(im,q-Vector2(length,-3),q+Vector2(4,0),6.0 if role=="bug_horn" else 2.6,dark)
				fx_line(im,q-Vector2(length,3),q+Vector2(4,0),2.2,light)
		"bug_fury","bug_cross":
			var count:int=3 if role=="bug_fury" else 2
			for i in range(count):
				var a:float=-PI*.8+float(i)*1.4+t*.5
				fight_arc(im,c+Vector2(float(i-1)*4,0),13.0,a,PI*.9,light,dark,4.0)
			if role=="bug_cross":
				fx_line(im,c-Vector2(12,12),c+Vector2(12,12),2.0,silk)
				fx_line(im,c+Vector2(-12,12),c+Vector2(12,-12),2.0,light)
		"bug_glow":
			var q:=Vector2(24,30)
			for i in range(3):
				var r:float=4.0+float(i)*4+sin(t*PI)*4.0
				fx_disc(im,q,r,Color("#ffd86d",.8),r-1.2)
			fight_burst(im,q,16.0,7,t,silk,light)
		"bug_heal","bug_attack","bug_defend":
			var count:int=4 if role=="bug_heal" else 8 if role=="bug_attack" else 6
			for i in range(count):
				var a:float=float(i)*TAU/float(count)+t*TAU
				var r:float=9.0+t*11.0 if role=="bug_attack" else 15.0 if role=="bug_defend" else 10.0
				var q:=c+Vector2(cos(a),sin(a))*r
				bug_wing(im,q,a,5.0 if role=="bug_attack" else 4.0,light,dark)
			if role=="bug_heal":
				fx_line(im,c-Vector2(0,6),c+Vector2(0,6),3.0,Color("#8ef5b1"))
				fx_line(im,c-Vector2(6,0),c+Vector2(6,0),3.0,Color("#8ef5b1"))
			elif role=="bug_defend":fx_disc(im,c,11.0,Color(dark,.9),9.0)
		"bug_turn":
			fight_arc(im,c,15.0,-PI+t*TAU,PI*1.6,light,dark,4.0)
			var q:=c+Vector2(cos(t*TAU),sin(t*TAU))*14.0
			bug_wing(im,q,t*TAU+PI*.5,6.0,light,dark)
		"bug_buzz":
			for i in range(4):
				var r:float=5.0+float(i)*5.0+sin(t*TAU+float(i))*2.0
				fx_disc(im,c,r,Color(light,.78),r-1.4)
			bug_wing(im,c,t*TAU,7.0,silk,dark)

# Original mental energy, spatial and support glyphs; no source art is used.
func psi_ring(im:Image,c:Vector2,r:float,light:Color,dark:Color)->void:
	fx_disc(im,c,r,dark,maxf(0.0,r-3.0))
	fx_disc(im,c,r-1.0,light,maxf(0.0,r-2.0))

func psi_polygon(im:Image,c:Vector2,r:float,n:int,a:float,light:Color,dark:Color)->void:
	for i in range(n):
		var b:float=a+float(i)*TAU/float(n)
		var next:float=b+TAU/float(n)
		var p:=c+Vector2(cos(b),sin(b))*r
		var q:=c+Vector2(cos(next),sin(next))*r
		fx_line(im,p,q,3.0,dark);fx_line(im,p,q,1.0,light)

func psi_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var c:=Vector2(24,24)
	var light:=Color("#ffb8f2");var dark:=Color("#794bb4");var cyan:=Color("#99edff");var gold:=Color("#ffe0a0")
	match role:
		"psi_beam","psi_wave":
			var count:int=3 if role=="psi_beam" else 5
			for i in range(count):
				if role=="psi_beam":
					var prev:=Vector2(2,24+float(i-1)*4)
					for j in range(1,17):
						var f:float=float(j)/16.0
						var q:=Vector2(2+43*f,24+sin(f*TAU*2.0-t*TAU+float(i)*2.1)*6.0)
						fx_line(im,prev,q,2.8,[light,cyan,gold][i]);prev=q
				else:
					var q:=Vector2(5+float(i)*9+t*3.0,24)
					fight_arc(im,q,6.0+float(i)*2.0,-PI*.5,PI,light,dark,2.8)
		"psi_psychic","psi_boost","psi_extra","psi_confusion":
			var count:int=4 if role=="psi_psychic" else 8 if role=="psi_boost" else 3 if role=="psi_extra" else 5
			for i in range(count):
				var a:float=float(i)*TAU/float(count)+t*TAU
				var r:float=5.0+sin(t*PI)*13.0
				var q:=c+Vector2(cos(a),sin(a))*r
				if role=="psi_extra":psi_polygon(im,q,7.0,3,a,cyan,dark)
				elif role=="psi_confusion":fight_arc(im,q,6.0,a,PI*1.5,gold,dark,2.5)
				elif role=="psi_boost":fx_line(im,c,q,4.0,light);fx_disc(im,q,3.0,cyan)
				else:psi_ring(im,q,5.0,light,dark)
			if role=="psi_boost":fight_burst(im,c,20.0,10,t,gold,dark)
		"psi_hypnosis","psi_eye":
			var r:float=8.0+sin(t*PI)*4.0
			if role=="psi_hypnosis":
				for i in range(3):fight_arc(im,c,r+float(i)*4.0,t*TAU+float(i),PI*1.6,light,dark,2.0)
			else:
				fight_arc(im,c,15.0,-PI*.85,PI*.7,cyan,dark,3.0)
				fight_arc(im,c,15.0,PI*.15,PI*.7,cyan,dark,3.0)
				fx_disc(im,c+Vector2(sin(t*TAU)*3.0,0),6.0,gold);fx_disc(im,c+Vector2(sin(t*TAU)*3.0,0),2.5,dark)
		"psi_skill","psi_trick","psi_role","psi_guard","psi_shift","psi_heart","psi_power","psi_powertrick":
			var variant:int=["psi_skill","psi_trick","psi_role","psi_guard","psi_shift","psi_heart","psi_power","psi_powertrick"].find(role)
			var left:=Vector2(12,24);var right:=Vector2(36,24)
			var q:=Vector2(12+24*t,24-sin(t*PI)*8.0)
			var other:=Vector2(36-24*t,24+sin(t*PI)*8.0)
			var sides:int=3+variant%5
			psi_polygon(im,left,6.0,sides,t,light,dark)
			psi_polygon(im,right,6.0,sides,-t,cyan,dark)
			if role=="psi_heart":
				fx_disc(im,q+Vector2(-2,-2),3.0,light);fx_disc(im,q+Vector2(2,-2),3.0,light)
				fx_line(im,q+Vector2(-4,-1),q+Vector2(0,5),3.0,light);fx_line(im,q+Vector2(4,-1),q+Vector2(0,5),3.0,light)
			elif role=="psi_guard":psi_polygon(im,q,6.0,5,PI*.5,cyan,dark)
			elif role=="psi_role":psi_ring(im,q,6.0,gold,dark);fx_disc(im,q,2.0,light)
			elif role=="psi_power":fight_burst(im,q,8.0,5,t,gold,dark)
			elif role=="psi_shift":fight_arc(im,q,6.0,t*TAU,PI*1.5,light,dark,2.5)
			elif role=="psi_trick":psi_polygon(im,q,5.0,4,t*PI,gold,dark)
			elif role=="psi_powertrick":fx_line(im,q-Vector2(5,4),q+Vector2(5,4),4.0,gold)
			else:fx_disc(im,q,4.0,light)
			fx_disc(im,other,2.0+float(variant%3),cyan)
		"psi_barrier","psi_screen","psi_magic","psi_mirror","psi_reflect","psi_imprison","psi_block":
			var r:float=12.0+sin(t*PI)*4.0
			if role=="psi_barrier":psi_polygon(im,c,r,6,PI*.5,cyan,dark)
			elif role=="psi_screen":
				for i in range(4):fx_line(im,Vector2(8+float(i)*8,10+t*4),Vector2(8+float(i)*8,36-t*4),2.5,gold)
				psi_polygon(im,c,r,4,PI*.25,light,dark)
			elif role=="psi_magic":
				psi_ring(im,c,r,light,dark);fight_burst(im,c,r+5.0,8,t,gold,dark)
			elif role=="psi_mirror":
				psi_polygon(im,c,r,8,PI/8.0,cyan,dark);fx_line(im,Vector2(15,33),Vector2(31,14+t*6),3.5,cyan)
			elif role=="psi_reflect":
				fight_arc(im,c,r,-PI*.55,PI*1.1,cyan,dark,5.0);fight_arc(im,c,r-5.0,-PI*.55,PI*1.1,light,dark,2.0)
			elif role=="psi_imprison":
				psi_polygon(im,c,r,4,PI*.25,light,dark)
				for i in range(3):fx_line(im,Vector2(16+float(i)*8,10+t*4),Vector2(16+float(i)*8,37-t*4),3.0,dark)
			else:
				psi_ring(im,c,r,gold,dark);fx_line(im,c-Vector2(r*.7,r*.7),c+Vector2(r*.7,r*.7),4.0,Color("#ed788a"))
		"psi_cosmic","psi_future","psi_lunar","psi_wish":
			var count:int=7 if role=="psi_cosmic" else 4 if role=="psi_future" else 5 if role=="psi_lunar" else 9
			for i in range(count):
				var a:float=float(i)*TAU/float(count)+t*2.5
				var q:=c+Vector2(cos(a),sin(a))*(8.0+t*11.0)
				fight_burst(im,q,3.0+float(i%2),4,t,gold,dark)
			if role=="psi_cosmic":psi_ring(im,c,9.0+t*3,cyan,dark)
			elif role=="psi_future":
				psi_ring(im,c,12.0,light,dark);fx_line(im,c,c+Vector2(cos(t*TAU),sin(t*TAU))*9.0,2.0,cyan)
			elif role=="psi_lunar":fight_arc(im,c,11.0,-PI*.7,PI*1.4,gold,dark,5.0)
			else:
				fx_line(im,c-Vector2(0,6),c+Vector2(0,6),3.0,cyan);fx_line(im,c-Vector2(6,0),c+Vector2(6,0),3.0,cyan)
		"psi_agility","psi_amnesia","psi_rest","psi_calm","psi_meditate","psi_kinesis":
			if role=="psi_agility":
				for i in range(4):fight_arc(im,Vector2(8+float(i)*9,24+sin(t*TAU+float(i))*5.0),9.0,-PI*.5,PI,cyan,dark,2.8)
			elif role=="psi_amnesia":
				for i in range(5):fx_disc(im,Vector2(12+float(i)*6,24-sin(t*PI+float(i)) * 9.0),3.0+float(i%3),Color(light,.8))
			elif role=="psi_rest":
				for i in range(3):
					var q:=Vector2(10+float(i)*10,35-t*18.0-float(i)*6)
					fx_line(im,q,q+Vector2(7,0),1.8,cyan);fx_line(im,q+Vector2(7,0),q+Vector2(0,6),1.8,cyan);fx_line(im,q+Vector2(0,6),q+Vector2(7,6),1.8,cyan)
			elif role=="psi_calm":
				for i in range(3):psi_ring(im,c,7.0+float(i)*5.0+sin(t*PI)*2.0,cyan,dark)
			elif role=="psi_meditate":
				psi_polygon(im,c,14.0,8,t*PI,light,dark);psi_polygon(im,c,8.0,4,-t*PI,gold,dark)
			else:
				var q:=Vector2(13+sin(t*TAU)*5,24)
				fx_line(im,q-Vector2(0,12),q+Vector2(8,8),4.0,cyan);fight_arc(im,q,15.0,t*TAU,PI,light,dark,2.2)
		"psi_teleport","psi_gravity","psi_room":
			if role=="psi_teleport":
				for i in range(6):
					var a:float=float(i)*TAU/6.0+t*TAU
					var q:=c+Vector2(cos(a),sin(a))*(20.0*(1.0-t)+2.0)
					fx_line(im,q,q+Vector2(0,-7),2.2,cyan)
				psi_ring(im,c,5.0+sin(t*PI)*11.0,light,dark)
			elif role=="psi_gravity":
				for i in range(5):
					var q:=Vector2(7+float(i)*8,5+t*28.0)
					fx_line(im,q-Vector2(0,9),q,3.0,dark);fx_line(im,q-Vector2(4,5),q,2.0,cyan);fx_line(im,q+Vector2(4,-5),q,2.0,cyan)
			else:
				for i in range(3):psi_polygon(im,c,7.0+float(i)*6.0,4,t*PI*.5+float(i)*.2,light,dark)
		"psi_mist","psi_luster","psi_cut","psi_zen","psi_dream":
			var q:=Vector2(8+30*t,24)
			if role=="psi_mist":
				fx_disc(im,q,8.0,dark);fx_disc(im,q,5.0,cyan)
				for i in range(5):fx_disc(im,q-Vector2(float(i)*4,sin(t*TAU+float(i))*6),3.0,Color(light,.6))
			elif role=="psi_luster":fight_burst(im,q,16.0,12,t,gold,dark);fx_disc(im,q,5.0,cyan)
			elif role=="psi_cut":fight_arc(im,q,14.0,-PI*.65+t,PI*1.3,light,dark,5.0)
			elif role=="psi_zen":
				fx_disc(im,q,11.0,dark);fx_disc(im,q+Vector2(3,-1),7.0,cyan);fight_burst(im,q,15.0,5,t,light,dark)
			else:
				for i in range(6):fx_disc(im,Vector2(39-31*t-float(i)*3,24+sin(t*TAU+float(i))*6),2.5,Color("#c6a9ff"))
				fight_arc(im,c,10.0,-PI+t,PI*1.2,light,dark,3.0)

# Original spectral FX: shadow trails, target-local curses and contact silhouettes.
func ghost_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var c:=Vector2(24,24)
	var light:=Color("#c9b9ff");var dark:=Color("#40305f");var glow:=Color("#91dfd4");var ink:=Color("#242037")
	match role:
		"ghost_nightmare":
			for i in range(5):
				var a:float=float(i)*TAU/5.0+t*2.0
				var q:=c+Vector2(cos(a),sin(a))*(7.0+sin(t*PI)*7.0)
				fx_disc(im,q,7.0,Color(dark,.82))
				fx_line(im,q+Vector2(-3,-1),q+Vector2(-1,2),1.8,light)
				fx_line(im,q+Vector2(3,-1),q+Vector2(1,2),1.8,light)
			fight_arc(im,c,18.0,-PI+t,PI*1.3,light,dark,2.8)
		"ghost_confuse":
			var prev:=Vector2(2,24)
			for j in range(1,18):
				var f:float=float(j)/17.0
				var q:=Vector2(2+43*f,24+sin(f*TAU*2.0-t*TAU)*8.0)
				fx_line(im,prev,q,5.0,dark);fx_line(im,prev,q,1.6,glow);prev=q
			fx_disc(im,prev,3.0,light)
		"ghost_spite","ghost_grudge":
			var count:int=4 if role=="ghost_spite" else 7
			for i in range(count):
				var a:float=float(i)*TAU/float(count)+t*2.5
				var q:=c+Vector2(cos(a),sin(a))*(6.0+11.0*t)
				fx_line(im,q,q+Vector2(0,-8.0),3.0,dark)
				fx_disc(im,q+Vector2(0,-8),2.5,glow if role=="ghost_spite" else light)
			if role=="ghost_grudge":psi_polygon(im,c,12.0+t*3.0,5,t*PI,light,dark)
			else:fx_line(im,c-Vector2(5,5),c+Vector2(5,5),2.5,ink)
		"ghost_astonish":
			var q:=c+Vector2(0,-sin(t*PI)*7.0)
			fight_burst(im,q,10.0+t*10.0,8,t,light,dark)
			fx_line(im,q-Vector2(0,9),q+Vector2(0,2),4.0,glow)
			fx_disc(im,q+Vector2(0,7),2.5,glow)
		"ghost_lick":
			var prev:=Vector2(4,26)
			for i in range(1,13):
				var f:float=float(i)/12.0
				var q:=Vector2(4+35*f*sin(t*PI),26+sin(f*PI*1.5+t*TAU)*5.0)
				fx_line(im,prev,q,6.0,dark);fx_line(im,prev,q,3.5,Color("#d782bc"));prev=q
			fx_disc(im,prev,3.0,light)
		"ghost_punch","ghost_ball":
			var q:=Vector2(6+32*t,24)
			if role=="ghost_ball":
				fx_disc(im,q,10.0,ink);fx_disc(im,q,7.0,dark)
				fight_arc(im,q,12.0,t*TAU,PI*1.5,light,glow,2.0)
			else:
				fx_disc(im,q,8.5,dark)
				for i in range(4):fx_disc(im,q+Vector2(6,float(i-2)*4.0),3.0,light)
				fx_line(im,q-Vector2(12,0),q-Vector2(5,0),7.0,ink)
			for i in range(4):fx_disc(im,q-Vector2(float(i+1)*5,sin(t*TAU+float(i))*4.0),3.0,Color(dark,.6))
		"ghost_shade":
			for i in range(4):
				var r:float=5.0+float(i)*5.0+sin(t*PI)*3.0
				psi_ring(im,c,r,light,ink)
			fx_disc(im,c,5.0+sin(t*PI)*2.0,dark)
		"ghost_bond":
			for i in range(6):
				var q:=Vector2(5+float(i)*7,24+sin(t*TAU+float(i)*.8)*6.0)
				psi_polygon(im,q,5.0,6,float(i%2)*PI*.5,glow,dark)
			fx_disc(im,Vector2(5,24),3.0,light);fx_disc(im,Vector2(43,24),3.0,light)
		"ghost_wind":
			for i in range(6):
				var q:=Vector2(4+float(i)*7,13+sin(t*TAU+float(i))*10.0)
				fight_arc(im,q,9.0,-PI*.6+t,PI*1.15,glow,dark,3.0)
				fx_disc(im,q+Vector2(2,11),2.0,light)
		"ghost_sneak":
			var q:=Vector2(4+39*t,34)
			for i in range(6):
				var at:=q-Vector2(float(i)*5,0)
				fx_disc(im,at,4.0,Color(ink,1.0-float(i)*.13))
			fx_line(im,q,q-Vector2(0,sin(t*PI)*19.0),4.0,light)
		"ghost_claw":
			for i in range(3):
				var q:=c+Vector2(float(i-1)*6,float(i-1)*3)
				fight_arc(im,q,14.0,-PI*.8+t*1.2,PI*1.05,light,dark,3.8)
		"ghost_force":
			var r:float=16.0-9.0*sin(t*PI)
			for i in range(2):fight_arc(im,c,r+float(i)*3.0,t*TAU+float(i)*PI,PI*1.5,light,ink,4.0)
			var q:=Vector2(24,6+32*t)
			fx_disc(im,q,7.0,Color(dark,.9));fight_burst(im,q,11.0,6,t,glow,ink)

# Original draconic pixel effects and directional elemental energy.
func dragon_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var c:=Vector2(24,24)
	var light:=Color("#b8a4ff");var dark:=Color("#55429b");var cyan:=Color("#87f1e8");var gold:=Color("#ffc580")
	match role:
		"dragon_rage":
			for i in range(7):
				var a:float=float(i)*TAU/7.0+t*2.0
				var q:=c+Vector2(cos(a),sin(a))*(7.0+sin(t*PI)*12.0)
				fx_line(im,c,q,5.0,dark);fx_line(im,c,q,2.0,gold)
				fx_disc(im,q,3.0,light)
		"dragon_twister":
			for i in range(6):
				var y:float=7.0+float(i)*6.0
				var r:float=4.0+float(5-i)*2.2
				fight_arc(im,Vector2(24,y),r,t*TAU+float(i)*.5,PI*1.55,cyan,dark,2.7)
		"dragon_claw":
			for i in range(3):
				var q:=c+Vector2(float(i-1)*7,float(i-1)*4)
				fight_arc(im,q,15.0,-PI*.85+t*1.4,PI*1.1,light,dark,4.5)
		"dragon_flame","dragon_breath":
			var count:int=5 if role=="dragon_flame" else 8
			for i in range(count):
				var q:=Vector2(4+float(i)*5+4*t,24+sin(t*TAU+float(i))*(3.0+float(i)*.8))
				var r:float=3.0+float(i)*.65
				fx_disc(im,q,r,dark)
				fx_disc(im,q,r*.62,gold if role=="dragon_flame" else cyan)
				if role=="dragon_breath":fx_line(im,q,q-Vector2(7,0),1.6,light)
		"dragon_dance":
			for i in range(6):
				var a:float=float(i)*TAU/6.0+t*TAU
				var q:=c+Vector2(cos(a),sin(a))*(10.0+sin(t*PI)*5.0)
				fight_arc(im,q,6.0,a,PI*1.4,cyan,dark,2.6)
				fx_disc(im,q+Vector2(0,-4),2.0,gold)
		"dragon_rend":
			var q:=c+Vector2(sin(t*PI)*4.0,0)
			fx_line(im,q-Vector2(19,17),q+Vector2(18,16),8.0,dark)
			fx_line(im,q-Vector2(19,17),q+Vector2(18,16),2.8,cyan)
			for i in range(5):
				var at:=q+Vector2(float(i-2)*7,float(i-2)*6)
				fx_line(im,at,at+Vector2(6,-7),2.0,light)
		"dragon_time":
			var r:float=13.0+sin(t*PI)*4.0
			psi_ring(im,c,r,cyan,dark)
			for i in range(12):
				var a:float=float(i)*TAU/12.0
				fx_disc(im,c+Vector2(cos(a),sin(a))*r,1.3,light)
			fx_line(im,c,c+Vector2(cos(t*TAU),sin(t*TAU))*r*.82,2.5,gold)
			fx_line(im,c,c+Vector2(cos(t*PI),sin(t*PI))*r*.55,2.5,cyan)
		"dragon_rush":
			var q:=Vector2(7+32*t,24)
			for i in range(5):fx_disc(im,q-Vector2(float(i)*5,0),8.0-float(i),Color(dark,1.0-float(i)*.15))
			fx_line(im,q+Vector2(-10,-11),q+Vector2(12,0),5.0,light)
			fx_line(im,q+Vector2(-10,11),q+Vector2(12,0),5.0,cyan)
		"dragon_meteor":
			for i in range(4):
				var q:=Vector2(8+float(i)*10,3+30*clampf(t*1.4-float(i)*.10,0.0,1.0))
				fx_line(im,q-Vector2(7,13),q,6.0,dark)
				fx_line(im,q-Vector2(7,13),q,3.0,gold)
				fx_disc(im,q,5.5,light);fx_disc(im,q,3.0,gold)
		"dragon_pulse":
			for i in range(4):
				var q:=Vector2(5+float(i)*9+3*t,24)
				fight_arc(im,q,7.0+float(i)*2.0,-PI*.5,PI,cyan,dark,4.0)
				fx_disc(im,q,2.0,light)

# Original dark-type FX, with separate contact, deceptive and room-scale silhouettes.
func dark_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var c:=Vector2(24,24)
	var ink:=Color("#211b35");var shade:=Color("#633e76");var light:=Color("#db9ad8");var red:=Color("#ff887f");var gold:=Color("#efcc8c")
	match role:
		"dark_torment":
			for i in range(4):
				var a:float=float(i)*TAU/4.0+t*TAU
				var q:=c+Vector2(cos(a),sin(a))*12.0
				fight_arc(im,q,7.0,a,PI*1.4,red,ink,3.0)
			fx_disc(im,c,4.0+sin(t*PI)*3.0,shade)
		"dark_tears":
			for i in range(5):
				var q:=Vector2(9+float(i)*7,8+25*clampf(t*1.4-float(i)*.12,0.0,1.0))
				fx_line(im,q-Vector2(0,5),q,2.0,Color("#94c5ef"))
				fx_disc(im,q,2.5,Color("#c2ecff"))
		"dark_pursuit":
			for i in range(3):
				var q:=Vector2(9+float(i)*11+sin(t*PI)*4.0,24)
				fx_line(im,q-Vector2(6,7),q+Vector2(5,0),3.0,light)
				fx_line(im,q+Vector2(-6,7),q+Vector2(5,0),3.0,shade)
		"dark_memento":
			for i in range(8):
				var a:float=float(i)*TAU/8.0+t
				var q:=c+Vector2(cos(a),sin(a))*(4.0+15.0*t)
				fx_disc(im,q,5.0*(1.0-t)+1.0,Color(shade,.8))
				fx_line(im,q,q+Vector2(0,7),2.0,ink)
		"dark_flatter":
			for i in range(3):
				var q:=Vector2(12+float(i)*12,30-sin(t*PI+float(i)*.5)*12.0)
				fx_disc(im,q+Vector2(-2,-2),3.0,light);fx_disc(im,q+Vector2(2,-2),3.0,light)
				fx_line(im,q-Vector2(4,0),q+Vector2(0,5),3.0,red)
				fx_line(im,q+Vector2(4,0),q+Vector2(0,5),3.0,red)
			fight_burst(im,c,12.0,4,t,gold,shade)
		"dark_crunch","dark_bite":
			var gap:float=12.0-sin(t*PI)*8.0
			var count:int=6 if role=="dark_crunch" else 3
			for i in range(count):
				var x:float=7.0+float(i)*34.0/float(count-1)
				fx_line(im,Vector2(x,24-gap),Vector2(x+2,24-gap+7),4.0,ink)
				fx_line(im,Vector2(x,24+gap),Vector2(x-2,24+gap-7),3.0,gold)
			if role=="dark_crunch":fight_burst(im,c,10.0+t*6.0,7,t,red,shade)
		"dark_faint":
			var q:=Vector2(6+36*t,24)
			for i in range(6):fx_disc(im,q-Vector2(float(i)*5,sin(float(i)+t*TAU)*4),5.0,Color(ink,1.0-float(i)*.14))
			fx_line(im,q-Vector2(4,8),q+Vector2(6,0),3.0,light)
		"dark_taunt":
			fight_burst(im,c,14.0+sin(t*PI)*5.0,6,t,red,shade)
			fx_line(im,Vector2(24,12+3*t),Vector2(24,25+3*t),4.0,gold)
			fx_disc(im,Vector2(24,32+3*t),2.5,gold)
		"dark_thief","dark_snatch","dark_switch":
			var q:=Vector2(36-24*t,24-sin(t*PI)*11.0)
			psi_polygon(im,q,6.0,4,t*PI,gold,shade)
			fight_arc(im,c,14.0,t*TAU,PI*1.15,light,ink,3.0)
			if role=="dark_snatch":
				fx_line(im,q,q+Vector2(-9,5),5.0,shade)
				fight_burst(im,q,9.0,5,t,red,ink)
			elif role=="dark_switch":
				var p:=Vector2(12+24*t,24+sin(t*PI)*11.0)
				psi_polygon(im,p,5.0,3,-t*PI,red,ink)
			else:fx_line(im,q,q+Vector2(10,0),2.0,gold)
		"dark_knock","dark_fling":
			var q:=Vector2(8+32*t,24-sin(t*PI)*(12.0 if role=="dark_fling" else 5.0))
			psi_polygon(im,q,7.0,5,t*TAU,gold,ink)
			if role=="dark_knock":fight_burst(im,c,12.0+t*6.0,6,t,light,shade)
			else:fx_line(im,q,q-Vector2(12,6),3.0,shade)
		"dark_beat":
			for i in range(5):
				var a:float=float(i)*TAU/5.0+t*TAU
				var q:=c+Vector2(cos(a),sin(a))*(18.0-10.0*t)
				fx_disc(im,q,5.0,ink)
				fx_disc(im,q+Vector2(1,-2),2.0,light)
		"dark_pulse","dark_void":
			var count:int=4 if role=="dark_pulse" else 6
			for i in range(count):
				var r:float=4.0+float(i)*3.0+sin(t*PI)*4.0
				psi_ring(im,c,r,light if role=="dark_pulse" else shade,ink)
			if role=="dark_void":fx_disc(im,c,9.0+sin(t*PI)*6.0,ink)
			else:fight_burst(im,c,18.0,8,t,red,shade)
		"dark_punish","dark_payback","dark_assure","dark_sucker":
			var count:int=7 if role=="dark_punish" else 5 if role=="dark_payback" else 3 if role=="dark_assure" else 4
			var q:=c if role!="dark_sucker" else Vector2(7+32*t,24)
			fight_burst(im,q,9.0+sin(t*PI)*10.0,count,t,red if role=="dark_punish" else gold,ink)
			if role=="dark_payback":fight_arc(im,q,16.0,t*TAU,PI*1.4,light,shade,4.0)
			elif role=="dark_assure":psi_polygon(im,q,8.0+t*4.0,4,t*PI,light,ink)
			elif role=="dark_sucker":
				fx_disc(im,q,7.0,shade)
				for i in range(3):fx_disc(im,q+Vector2(5,float(i-1)*4),2.8,light)
			else:fx_disc(im,q,4.0+t*3.0,red)
		"dark_embargo":
			psi_polygon(im,c,12.0+sin(t*PI)*4.0,4,PI*.25,gold,ink)
			psi_ring(im,c,18.0,light,shade)
			fx_line(im,c-Vector2(10,10),c+Vector2(10,10),4.0,red)
		"dark_slash":
			for i in range(2):
				fight_arc(im,c+Vector2(float(i)*6,0),15.0,-PI*.8+t*1.7,PI*1.15,light,ink,5.0)
		"dark_plot":
			for i in range(3):
				var q:=Vector2(12+float(i)*12,30-sin(t*PI+float(i)*.7)*13.0)
				fx_disc(im,q,4.0+float(i),shade)
				fx_disc(im,q+Vector2(0,-2),1.6,light)
			fight_arc(im,c,16.0,t*TAU,PI*1.25,gold,ink,2.6)

# Original metal FX: faceted reflections, heavy contact, magnetic and radiant energy.
func steel_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var c:=Vector2(24,24)
	var chrome:=Color("#e4edf2");var iron:=Color("#73869b");var dark:=Color("#364557");var cyan:=Color("#a8eaff");var gold:=Color("#ffe39c")
	match role:
		"steel_tail":
			var q:=c+Vector2(0,4)
			fight_arc(im,q,17.0,-PI+t*1.8,PI*1.3,chrome,dark,7.0)
			var a:float=-PI+t*1.8+PI*1.3
			psi_polygon(im,q+Vector2(cos(a),sin(a))*17.0,5.0,5,a,chrome,iron)
		"steel_sound":
			for i in range(5):
				var q:=Vector2(4+float(i)*9+4*t,24)
				fight_arc(im,q,6.0+float(i)*2.5,-PI*.55,PI*1.1,chrome,iron,2.4)
				fx_disc(im,q,1.8,cyan)
		"steel_meteor":
			var q:=Vector2(7+32*t,24)
			for i in range(4):
				fx_line(im,q-Vector2(float(i)*5.0+6,7),q-Vector2(float(i)*5.0,0),3.0,gold)
			psi_polygon(im,q,10.0,5,t*PI,chrome,dark)
			fight_burst(im,q,14.0,5,t,gold,iron)
		"steel_defense":
			for i in range(6):
				var a:float=float(i)*TAU/6.0+t*TAU*.5
				var q:=c+Vector2(cos(a),sin(a))*(10.0+sin(t*PI)*5.0)
				psi_polygon(im,q,6.0,6,a,chrome,dark)
				fx_line(im,q-Vector2(3,3),q+Vector2(2,-3),2.0,cyan)
		"steel_wing":
			for i in [-1,1]:
				var q:=c+Vector2(float(i)*5.0,0)
				for j in range(4):
					var f:float=float(j)/3.0
					var a:float=float(i)*(0.5+t*1.1+f*.4)
					var p:=q+Vector2(float(i)*f*12.0,f*5.0)
					fx_line(im,p,p+Vector2(float(i)*cos(a)*12.0,-sin(a)*12.0*float(i)),4.0,iron)
					fx_line(im,p,p+Vector2(float(i)*cos(a)*10.0,-sin(a)*10.0*float(i)),1.6,chrome)
		"steel_doom":
			var r:float=5.0+sin(t*PI)*12.0
			psi_ring(im,c,r,gold,dark)
			for i in range(8):
				var a:float=float(i)*TAU/8.0+t
				var q:=c+Vector2(cos(a),sin(a))*(20.0-10.0*t)
				fx_line(im,q,q+Vector2(0,-7.0),2.3,chrome)
			fight_burst(im,c,r,4,t,cyan,iron)
		"steel_claw":
			for i in range(3):
				var q:=c+Vector2(float(i-1)*7,float(i-1)*4)
				fight_arc(im,q,14.0,-PI*.8+t*1.2,PI*1.05,chrome,dark,4.2)
				fx_disc(im,q+Vector2(sin(t*PI)*8.0,0),1.5,gold)
		"steel_head":
			var q:=Vector2(8+30*t,24)
			psi_polygon(im,q,10.0,6,PI*.5,chrome,dark)
			fx_line(im,q-Vector2(7,-3),q+Vector2(7,-3),4.0,iron)
			fight_burst(im,q,13.0,6,t,gold,dark)
		"steel_gyro":
			var q:=Vector2(8+32*t,24)
			fx_disc(im,q,10.0,dark);fx_disc(im,q,7.0,iron)
			for i in range(3):
				fight_arc(im,q,12.0,t*TAU*2.0+float(i)*TAU/3.0,PI*.6,chrome,cyan,3.2)
		"steel_bullet":
			for i in range(3):
				var q:=Vector2(5+35*t-float(i)*7,20+float(i)*4)
				fx_line(im,q-Vector2(9,0),q,4.0,iron)
				fx_disc(im,q,3.5,chrome)
				fx_line(im,q-Vector2(15,0),q-Vector2(6,0),1.4,gold)
		"steel_magnet":
			var q:=Vector2(7+32*t,24-sin(t*PI)*9.0)
			fx_disc(im,q,7.5,dark);fx_disc(im,q,4.5,chrome)
			for i in range(4):
				var a:float=float(i)*TAU/4.0+t*TAU
				var p:=q+Vector2(cos(a),sin(a))*10.0
				fx_disc(im,p,2.8,Color("#e88883") if i%2==0 else cyan)
				fight_arc(im,q,12.0,a,PI*.4,chrome,iron,1.8)
		"steel_mirror":
			var q:=Vector2(8+32*t,24)
			psi_polygon(im,q,9.0,4,t*PI,chrome,iron)
			fx_line(im,q-Vector2(5,5),q+Vector2(4,4),3.0,cyan)
			for i in range(4):fx_disc(im,q-Vector2(float(i+1)*6,sin(t*TAU+float(i))*5.0),2.0,chrome)
		"steel_burst":
			for i in range(9):
				var a:float=float(i)*TAU/9.0+t
				var q:=c+Vector2(cos(a),sin(a))*(5.0+15.0*t)
				psi_polygon(im,q,3.5,3,a,chrome,dark)
				fx_line(im,c,q,1.8,gold)
			psi_ring(im,c,6.0+sin(t*PI)*7.0,cyan,iron)
		"steel_flash":
			var q:=Vector2(4+38*t,24)
			fx_line(im,Vector2(2,24),q,10.0,iron)
			fx_line(im,Vector2(2,24),q,6.0,cyan)
			fx_line(im,Vector2(2,24),q,2.2,chrome)
			fight_burst(im,q,9.0+sin(t*PI)*5.0,6,t,chrome,gold)

# Original neutral contact FX. Variations encode attack form rather than species anatomy.
func normal_contact_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var c:=Vector2(24,24)
	var light:=Color("#fff0cf");var dark:=Color("#8a705f");var red:=Color("#e69374");var gold:=Color("#f3c779")
	match role:
		"normal_cut","normal_slash","normal_scratch","normal_crushclaw","normal_furyswipes","normal_false":
			var v:int=["normal_cut","normal_slash","normal_scratch","normal_crushclaw","normal_furyswipes","normal_false"].find(role)
			var count:int=[1,2,3,4,5,1][v]
			for i in range(count):
				var q:=c+Vector2(float(i)*5.0-float(count-1)*2.5,float(i%2)*5.0)
				fight_arc(im,q,11.0+float(v)*1.1,-PI*.8+t*(1.0+float(v)*.13),PI*(.75+float(v)*.12),gold if v==5 else light,dark,2.5+float(v)*.5)
			if v==5:fx_disc(im,c+Vector2(9*sin(t*PI),4),2.0,light)
		"normal_superfang","normal_hyperfang","normal_vice","normal_guillotine","normal_grip":
			var v:int=["normal_superfang","normal_hyperfang","normal_vice","normal_guillotine","normal_grip"].find(role)
			var gap:float=13.0-sin(t*PI)*(7.0+float(v)*.7)
			for i in [-1,1]:
				var q:=c+Vector2(0,float(i)*gap)
				if v<=1:
					for j in range(3+v*2):
						var p:=q+Vector2(float(j-1)*7.0-float(v)*5.0,0)
						fx_line(im,p,p+Vector2(2,-float(i)*8),4.0,light)
				elif v==3:
					fx_line(im,q-Vector2(15,0),q+Vector2(15,0),5.0,dark)
					fx_line(im,q-Vector2(15,-float(i)*2),q+Vector2(15,float(i)*2),2.0,light)
				else:
					fight_arc(im,q,13.0,0.0 if i<0 else PI,PI,light,dark,4.0+float(v)*.5)
			if v==1 or v==4:fight_burst(im,c,8.0+t*9.0,6+v,t,red,dark)
		"normal_constrict","normal_bind","normal_wrap":
			var v:int=["normal_constrict","normal_bind","normal_wrap"].find(role)
			for i in range(3+v):
				var q:=c+Vector2(0,float(i)*6.0-float(2+v)*3.0)
				fight_arc(im,q,15.0-sin(t*PI)*(4.0+float(v)),t*TAU+float(i)*.7,PI*1.7,light,dark,2.5+float(v))
		"normal_slap","normal_pound","normal_megapunch","normal_comet","normal_double","normal_dizzy":
			var v:int=["normal_slap","normal_pound","normal_megapunch","normal_comet","normal_double","normal_dizzy"].find(role)
			var count:int=[4,1,1,5,2,3][v]
			for i in range(count):
				var q:=Vector2(8+30*clampf(t*1.3-float(i)*.13,0.0,1.0),24+float(i%3-1)*6.0)
				var r:float=6.0+float(v==2)*5.0
				fx_disc(im,q,r,dark);fx_disc(im,q+Vector2(2,-1),r*.65,light)
				for j in range(3):fx_disc(im,q+Vector2(r*.7,float(j-1)*r*.5),r*.32,gold)
				if v==0:fx_line(im,q-Vector2(3,-7),q+Vector2(3,7),2.0,red)
				elif v==5:fight_arc(im,q,9.0,t*TAU,PI*1.25,gold,dark,2.0)
		"normal_horn","normal_drill","normal_furyattack":
			var v:int=["normal_horn","normal_drill","normal_furyattack"].find(role)
			for i in range(1+v*2):
				var q:=Vector2(7+33*t-float(i)*5.0,24+sin(float(i)+t*TAU)*float(v)*4.0)
				fx_line(im,q-Vector2(13,6),q+Vector2(5,0),4.0,dark)
				fx_line(im,q-Vector2(13,-6),q+Vector2(5,0),2.0,light)
				if v==1:fight_arc(im,q,8.0,t*TAU*2.0,PI*1.5,gold,dark,2.0)
		"normal_stomp","normal_megakick","normal_slam","normal_body","normal_climb":
			var v:int=["normal_stomp","normal_megakick","normal_slam","normal_body","normal_climb"].find(role)
			var q:=Vector2(24+sin(t*PI)*float(v)*3.0,6+31*t)
			psi_polygon(im,q,8.0+float(v),4+v%3,t*float(v),light,dark)
			fight_burst(im,Vector2(24,36),6.0+t*12.0,5+v,t,gold,dark)
			if v==1:fx_line(im,q-Vector2(12,6),q+Vector2(8,0),5.0,red)
			if v==4:
				for i in range(3):fx_line(im,q+Vector2(float(i-1)*7,4),q+Vector2(float(i-1)*7-4,12),2.0,light)
		"normal_spin","normal_thrash","normal_flail","normal_struggle","normal_frustration":
			var v:int=["normal_spin","normal_thrash","normal_flail","normal_struggle","normal_frustration"].find(role)
			for i in range(2+v):
				var a:float=t*TAU+float(i)*TAU/float(2+v)
				var q:=c+Vector2(cos(a),sin(a))*(7.0+float(v)*2.0)
				fight_arc(im,q,9.0+float(v),a,PI*(1.4-float(v)*.15),light,red if v==4 else dark,3.0)
				if v>=2:fx_disc(im,q,2.0,gold)
		"normal_extreme","normal_quick","normal_tackle","normal_takedown","normal_edge","normal_giga","normal_headbutt","normal_skull","normal_feint":
			var v:int=["normal_extreme","normal_quick","normal_tackle","normal_takedown","normal_edge","normal_giga","normal_headbutt","normal_skull","normal_feint"].find(role)
			var q:=Vector2(6+33*t,24-sin(t*PI)*float(v%3)*3.0)
			var r:float=5.0+float(v%5)*1.5
			for i in range(2+v%4):
				var p:=q-Vector2(float(i+1)*5.0,float(i%2)*3.0)
				fx_line(im,p-Vector2(9,0),p,2.0+float(v%3),dark)
			psi_polygon(im,q,r,3+v%5,t*float(v)*.3,light,red if v==4 or v==5 else dark)
			if v>=5:fight_burst(im,q,r+4.0,4+v%4,t,gold,dark)
		"normal_return","normal_strength","normal_bide","normal_endeavor","normal_facade","normal_salt","normal_fake","normal_last":
			var v:int=["normal_return","normal_strength","normal_bide","normal_endeavor","normal_facade","normal_salt","normal_fake","normal_last"].find(role)
			var q:=c+Vector2(sin(t*PI)*float(v%4)*4.0,0)
			fight_burst(im,q,9.0+sin(t*PI)*(9.0+float(v%3)),4+v,t,gold if v%2==0 else red,dark)
			if v==0:psi_ring(im,q,7.0+t*5.0,light,dark)
			elif v==1:psi_polygon(im,q,9.0,6,t,light,dark)
			elif v==2:psi_ring(im,q,15.0,red,dark)
			elif v==3:fx_line(im,q-Vector2(9,0),q+Vector2(9,0),3.0,light)
			elif v==4:psi_polygon(im,q,8.0,4,PI*.25,red,dark)
			elif v==5:
				for i in range(7):fx_disc(im,q+Vector2(float(i%3-1)*5,float(i/3-1)*5),1.5,light)
			elif v==6:fx_line(im,q-Vector2(8,7),q+Vector2(8,7),4.0,light)
			else:psi_polygon(im,q,11.0,5,t*TAU,light,gold)

# Original neutral special FX and the three typeless reference moves.
func neutral_special_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var c:=Vector2(24,24)
	var light:=Color("#fff2cf");var dark:=Color("#8e7787");var cyan:=Color("#a8dfed");var gold:=Color("#ffd178");var red:=Color("#ed8763")
	match role:
		"neutral_snore","neutral_sonic","neutral_voice":
			var v:int=["neutral_snore","neutral_sonic","neutral_voice"].find(role)
			for i in range(3+v*2):
				var q:=Vector2(5+float(i)*6.0+3.0*t,24+sin(t*TAU+float(i))*float(v==0)*5.0)
				fight_arc(im,q,5.0+float(i)*1.8,-PI*.5,PI,cyan if v==1 else light,dark,2.0+float(v))
			if v==0:fx_disc(im,Vector2(12+7*t,14),3.0,cyan)
		"neutral_razor","neutral_wide","neutral_vacuum":
			var v:int=["neutral_razor","neutral_wide","neutral_vacuum"].find(role)
			for i in range(2+v):
				var q:=c+Vector2(float(i)*6.0-float(1+v)*3.0,0)
				fight_arc(im,q,13.0+float(v)*2.0,-PI*.8+t*1.4+float(i)*.25,PI*(1.0+float(v)*.2),cyan, dark,3.0+float(v))
			if v==2:psi_ring(im,c,18.0+sin(t*PI)*2.0,light,dark)
		"neutral_self","neutral_explosion":
			var big:bool=role=="neutral_explosion"
			var r:float=4.0+sin(t*PI*.85)*(19.0 if big else 13.0)
			for i in range(10 if big else 6):
				var a:float=float(i)*TAU/float(10 if big else 6)+t
				var q:=c+Vector2(cos(a),sin(a))*r
				fx_disc(im,q,6.0 if big else 4.0,red)
				fx_disc(im,q,3.5 if big else 2.5,gold)
			fight_burst(im,c,r,12 if big else 6,t,light,red)
		"neutral_weather","neutral_hidden","neutral_secret","neutral_gift":
			var v:int=["neutral_weather","neutral_hidden","neutral_secret","neutral_gift"].find(role)
			var q:=Vector2(7+32*t,24)
			var palette:Array[Color]=[cyan,red,gold,Color("#a4de8a")]
			if v==0:
				fx_disc(im,q,9.0,dark)
				for i in range(4):
					var a:float=float(i)*TAU/4.0+t*TAU
					fx_disc(im,q+Vector2(cos(a),sin(a))*5.0,3.0,palette[i])
			elif v==1:
				for i in range(5):
					var a:float=float(i)*TAU/5.0+t*TAU
					psi_polygon(im,q+Vector2(cos(a),sin(a))*9.0,4.0,3,a,palette[i%4],dark)
			elif v==2:
				psi_polygon(im,q,10.0,6,t*PI,gold,dark);fight_burst(im,q,15.0,6,t,light,cyan)
			else:
				psi_polygon(im,q,8.0,5,t*PI,palette[3],dark)
				for i in range(4):fx_disc(im,q+Vector2(float(i-2)*5,sin(t*TAU+float(i))*6),2.0,palette[i])
		"neutral_swift","neutral_barrage","neutral_spike":
			var v:int=["neutral_swift","neutral_barrage","neutral_spike"].find(role)
			for i in range(5):
				var q:=Vector2(5+36*clampf(t*1.4-float(i)*.10,0.0,1.0),24+float(i-2)*6.0)
				if v==0:fight_burst(im,q,5.0,5,t,gold,dark)
				elif v==1:
					fx_disc(im,q,5.0,dark);fx_disc(im,q+Vector2(1,-1),3.0,light)
				else:
					fx_line(im,q-Vector2(9,3),q+Vector2(5,0),3.2,dark);fx_line(im,q-Vector2(9,-3),q+Vector2(5,0),1.8,cyan)
		"neutral_egg","neutral_present","neutral_trump","neutral_pay":
			var v:int=["neutral_egg","neutral_present","neutral_trump","neutral_pay"].find(role)
			var q:=Vector2(7+32*t,28-sin(t*PI)*(14.0 if v<2 else 7.0))
			if v==0:
				fx_disc(im,q,7.0,dark);fx_disc(im,q+Vector2(0,-3),5.0,light)
			elif v==1:
				psi_polygon(im,q,8.0,4,PI*.25,red,dark)
				fx_line(im,q-Vector2(6,0),q+Vector2(6,0),2.5,gold)
				fx_line(im,q-Vector2(0,6),q+Vector2(0,6),2.5,gold)
			elif v==2:
				for i in range(3):
					var p:=q+Vector2(float(i-1)*6.0,sin(t*PI+float(i))*5.0)
					psi_polygon(im,p,6.0,4,t*PI+float(i)*.3,light,dark)
			else:
				for i in range(4):
					var p:=q+Vector2(float(i-1)*5.0,sin(t*TAU+float(i))*6.0)
					psi_ring(im,p,4.5,gold,dark)
		"neutral_tri":
			for i in range(3):
				var a:float=float(i)*TAU/3.0+t*TAU
				var q:=c+Vector2(cos(a),sin(a))*(8.0+sin(t*PI)*6.0)
				fx_disc(im,q,6.0,[red,cyan,gold][i])
				fx_line(im,c,q,2.0,light)
		"neutral_beam":
			var q:=Vector2(3+42*t,24)
			fx_line(im,Vector2(2,24),q,13.0,dark)
			fx_line(im,Vector2(2,24),q,8.0,gold)
			fx_line(im,Vector2(2,24),q,3.0,light)
			fight_burst(im,q,12.0,8,t,red,dark)
		"neutral_spit":
			for i in range(6):
				var q:=Vector2(5+33*clampf(t*1.4-float(i)*.10,0.0,1.0),24+sin(t*TAU+float(i))*6.0)
				fx_disc(im,q,3.0+float(i%3),cyan);fx_disc(im,q+Vector2(1,-1),1.5,light)
		"neutral_covet":
			var q:=Vector2(36-24*t,24-sin(t*PI)*9.0)
			fx_disc(im,q+Vector2(-3,-3),4.0,red);fx_disc(im,q+Vector2(3,-3),4.0,red)
			fx_line(im,q-Vector2(6,0),q+Vector2(0,7),4.0,red);fx_line(im,q+Vector2(6,0),q+Vector2(0,7),4.0,red)
			psi_polygon(im,q+Vector2(9,5),4.0,4,t*PI,gold,dark)
		"neutral_wring":
			for i in range(5):
				var q:=c+Vector2(0,float(i-2)*6.0)
				fight_arc(im,q,15.0-sin(t*PI)*7.0,t*TAU+float(i)*.9,PI*1.5,light,dark,3.8)
			fight_burst(im,c,6.0+sin(t*PI)*6.0,4,t,red,dark)

# Original neutral support FX, scoped to the actual recipient tiles.
func support_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var c:=Vector2(24,24)
	var mint:=Color("#a7efbe");var gold:=Color("#ffe297");var light:=Color("#f7f4da");var dark:=Color("#648c86");var rose:=Color("#e68f9d")
	match role:
		"support_sun","support_moon","support_wish","support_lucky":
			var v:int=["support_sun","support_moon","support_wish","support_lucky"].find(role)
			var q:=Vector2(24,19+sin(t*PI)*4.0)
			if v==0:
				fx_disc(im,q,8.0,gold);fight_burst(im,q,15.0,12,t,light,gold)
			elif v==1:
				fight_arc(im,q,10.0,-PI*.75,PI*1.5,light,dark,5.0)
			elif v==2:fight_burst(im,q,10.0+sin(t*PI)*5.0,5,t,gold,dark)
			else:
				for i in range(4):fx_disc(im,q+Vector2(float(i%2*2-1)*4,float(i/2)*8-4),4.0,mint)
			for i in range(4+v):
				var a:float=float(i)*TAU/float(4+v)+t
				fx_disc(im,c+Vector2(cos(a)*17.0,sin(a)*7.0+11.0),1.8,gold if v!=1 else mint)
		"support_recover","support_slack","support_swallow","support_refresh","support_egg","support_milk":
			var v:int=["support_recover","support_slack","support_swallow","support_refresh","support_egg","support_milk"].find(role)
			for i in range(4+v):
				var a:float=float(i)*TAU/float(4+v)+t*2.0
				var q:=c+Vector2(cos(a)*12.0,sin(a)*6.0+10.0-16.0*t)
				fx_disc(im,q,2.0+float(v%2),mint)
				if v==3:fx_line(im,q,q-Vector2(0,5),1.5,light)
			var p:=c+Vector2(0,-sin(t*PI)*5.0)
			if v==0:
				fx_line(im,p-Vector2(0,7),p+Vector2(0,7),4.0,light)
				fx_line(im,p-Vector2(7,0),p+Vector2(7,0),4.0,light)
			elif v==1:psi_ring(im,p,10.0+sin(t*PI)*3.0,mint,dark)
			elif v==2:
				fight_arc(im,p,10.0,t*TAU,PI*1.6,gold,dark,3.0)
				fx_disc(im,p,4.0+sin(t*PI)*3.0,mint)
			elif v==3:fight_burst(im,p,11.0,6,t,light,mint)
			elif v==4:
				fx_disc(im,p,8.0,dark);fx_disc(im,p-Vector2(0,2),6.0,light)
				fx_line(im,p-Vector2(5,0),p+Vector2(5,0),1.5,mint)
			else:
				psi_polygon(im,p,9.0,4,PI*.25,light,dark)
				fx_line(im,p-Vector2(3,8),p+Vector2(3,-8),4.0,mint)
		"support_rage","support_focus","support_growth","support_stock","support_drum","support_howl":
			var v:int=["support_rage","support_focus","support_growth","support_stock","support_drum","support_howl"].find(role)
			for i in range(4+v):
				var a:float=float(i)*TAU/float(4+v)+t*TAU
				var q:=c+Vector2(cos(a),sin(a))*(6.0+sin(t*PI)*12.0)
				fx_line(im,c,q,2.0+float(v%3),rose if v==0 or v==4 else gold)
				fx_disc(im,q,2.0,mint if v==2 else light)
			if v==0:fight_burst(im,c,12.0,5,t,rose,dark)
			elif v==1:psi_ring(im,c,10.0,gold,dark)
			elif v==2:
				fx_line(im,c+Vector2(0,10),c-Vector2(0,10),4.0,mint)
				fx_line(im,c-Vector2(6,2),c-Vector2(0,10),3.0,mint)
				fx_line(im,c+Vector2(6,-2),c-Vector2(0,10),3.0,mint)
			elif v==3:
				for i in range(3):fx_disc(im,c+Vector2(float(i-1)*6,0),3.5,gold)
			elif v==4:
				psi_ring(im,c,9.0+sin(t*TAU)*2.0,rose,dark)
			else:fight_arc(im,c,13.0,-PI*.75,PI*1.5,light,dark,3.0)
		"support_sharpen","support_swords","support_harden","support_curl","support_protect","support_safeguard","support_endure":
			var v:int=["support_sharpen","support_swords","support_harden","support_curl","support_protect","support_safeguard","support_endure"].find(role)
			var r:float=10.0+sin(t*PI)*5.0
			if v<2:
				for i in range(2+v):
					var a:float=float(i)*TAU/float(2+v)+t*TAU
					var q:=c+Vector2(cos(a),sin(a))*r
					fx_line(im,q-Vector2(0,7),q+Vector2(0,7),3.0,light)
					if v==1:fx_line(im,q-Vector2(4,3),q+Vector2(4,3),2.0,gold)
			elif v==2:psi_polygon(im,c,r,6,t*PI,light,dark)
			elif v==3:
				for i in range(3):fight_arc(im,c,r-float(i)*3.0,t*TAU,PI*1.6,mint,dark,3.0)
			elif v==4:
				psi_polygon(im,c,r,5,PI*.5,light,dark);psi_ring(im,c,r+4.0,mint,dark)
			elif v==5:
				for i in range(3):psi_ring(im,c,r+float(i)*3.0,mint,dark)
			else:
				psi_polygon(im,c,r,4,PI*.25,gold,dark);fight_burst(im,c,r+4.0,4,t,light,rose)
		"support_double","support_minimize":
			var v:int=0 if role=="support_double" else 1
			for i in range(3):
				var q:=c+Vector2(float(i-1)*(10.0 if v==0 else 5.0)*sin(t*PI),0)
				var r:float=7.0 if v==0 else 9.0*(1.0-t)+2.0
				psi_polygon(im,q,r,5,t*PI,light if i==1 else mint,dark)
		"support_mind","support_lock","support_follow":
			var v:int=["support_mind","support_lock","support_follow"].find(role)
			var r:float=17.0-7.0*t
			if v==0:
				fight_arc(im,c,r,-PI*.8,PI*.6,mint,dark,3.0)
				fight_arc(im,c,r,PI*.2,PI*.6,mint,dark,3.0);fx_disc(im,c,5.0,gold)
			elif v==1:
				for i in range(4):
					var a:float=float(i)*TAU/4.0
					var q:=c+Vector2(cos(a),sin(a))*r
					fx_line(im,q,q-Vector2(cos(a),sin(a))*6.0,3.0,gold)
				psi_ring(im,c,r,light,dark)
			else:
				for i in range(3):
					var q:=Vector2(24,8+float(i)*10+sin(t*PI)*4.0)
					fx_line(im,q+Vector2(-5,5),q,3.0,mint);fx_line(im,q+Vector2(5,5),q,3.0,mint)
		"support_pain","support_psych","support_help":
			var v:int=["support_pain","support_psych","support_help"].find(role)
			var p:=Vector2(8+32*t,24-sin(t*PI)*9.0)
			var q:=Vector2(40-32*t,24+sin(t*PI)*9.0)
			fx_disc(im,p,4.0,gold);fx_disc(im,q,4.0,mint)
			if v==0:fx_line(im,p,q,2.5,rose)
			elif v==1:psi_polygon(im,p,7.0,4,t*PI,light,dark)
			else:fight_burst(im,p,9.0,5,t,light,dark)
		"support_bell":
			var q:=c+Vector2(sin(t*TAU)*4.0,-3)
			psi_polygon(im,q,8.0,5,PI*.5,gold,dark)
			fx_disc(im,q+Vector2(0,7),2.0,light)
			for i in range(3):fight_arc(im,q,11.0+float(i)*4.0,t*PI,PI,light,mint,2.0)
		"support_acu":
			for i in range(7):
				var a:float=float(i)*TAU/7.0+t*TAU
				var q:=c+Vector2(cos(a),sin(a))*(13.0-6.0*sin(t*PI))
				fx_line(im,q,c,1.6,dark);fx_disc(im,q,2.8,gold)
			fx_disc(im,c,3.0+sin(t*PI)*3.0,mint)

# Original status glyphs and spatial effects; body animation remains independent.
func status_kind(role:String)->Array:
	match role:
		"status_yawn","status_talk":return ["sleep",["status_yawn","status_talk"].find(role)]
		"status_lovely","status_charm","status_kiss","status_attract","status_captivate":return ["heart",["status_lovely","status_charm","status_kiss","status_attract","status_captivate"].find(role)]
		"status_scent","status_smoke","status_odor":return ["cloud",["status_scent","status_smoke","status_odor"].find(role)]
		"status_screech","status_sing","status_uproar","status_supersonic","status_growl","status_roar","status_perish":return ["sound",["status_screech","status_sing","status_uproar","status_supersonic","status_growl","status_roar","status_perish"].find(role)]
		"status_mean","status_scary","status_leer","status_glare","status_foresight":return ["eyes",["status_mean","status_scary","status_leer","status_glare","status_foresight"].find(role)]
		"status_encore","status_disable","status_block","status_curse","status_sub":return ["lock",["status_encore","status_disable","status_block","status_curse","status_sub"].find(role)]
		"status_convert","status_convert2","status_transform","status_camo":return ["shift",["status_convert","status_convert2","status_transform","status_camo"].find(role)]
		"status_nature","status_sketch","status_assist","status_mimic","status_metronome","status_first","status_copycat":return ["copy",["status_nature","status_sketch","status_assist","status_mimic","status_metronome","status_first","status_copycat"].find(role)]
		"status_swagger","status_tickle","status_tail","status_dance":return ["motion",["status_swagger","status_tickle","status_tail","status_dance"].find(role)]
		"status_baton","status_recycle":return ["item",["status_baton","status_recycle"].find(role)]
		"status_splash","status_whirl","status_flash":return ["space",["status_splash","status_whirl","status_flash"].find(role)]
	return ["unknown",0]

func status_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var c:=Vector2(24,24)
	var light:=Color("#fff1d9");var dark:=Color("#765d91");var cyan:=Color("#a6e1e9");var gold:=Color("#f8cb76");var rose:=Color("#f28ca9")
	var kind:Array=status_kind(role)
	var v:int=int(kind[1])
	match str(kind[0]):
		"sleep":
			for i in range(3+v):
				var q:=Vector2(8+float(i)*8,30-sin(t*PI+float(i)*.6)*10.0)
				if v==0:
					fx_line(im,q,q+Vector2(7,0),1.8,cyan);fx_line(im,q+Vector2(7,0),q+Vector2(0,6),1.8,cyan);fx_line(im,q+Vector2(0,6),q+Vector2(7,6),1.8,cyan)
				else:fx_disc(im,q,2.5+float(i%2),cyan)
			if v==1:psi_ring(im,c,10.0+sin(t*PI)*3.0,light,dark)
		"heart":
			for i in range(2+v):
				var q:=Vector2(8+float(i)*6.0+3.0*t,28-sin(t*PI+float(i)*.5)*10.0)
				var r:float=3.0+float(v%3)
				fx_disc(im,q+Vector2(-r*.5,-r*.5),r,rose);fx_disc(im,q+Vector2(r*.5,-r*.5),r,rose)
				fx_line(im,q-Vector2(r,0),q+Vector2(0,r*1.5),r,rose);fx_line(im,q+Vector2(r,0),q+Vector2(0,r*1.5),r,rose)
				if v%2==1:fx_disc(im,q-Vector2(1,3),1.5,light)
			if v==3:psi_ring(im,c,15.0+sin(t*PI)*3.0,rose,dark)
			elif v==4:fight_burst(im,c,18.0,6,t,gold,dark)
		"cloud":
			for i in range(5+v*3):
				var a:float=float(i)*TAU/float(5+v*3)+t*2.0
				var q:=c+Vector2(cos(a),sin(a))*(5.0+13.0*t)
				var r:float=8.0 if v==1 else 4.0
				fx_disc(im,q,r,Color(dark,.7) if v==1 else Color(cyan,.7) if v==2 else Color(rose,.7))
				fx_disc(im,q-Vector2(1,2),r*.55,light)
				if v==2:fx_line(im,q,q+Vector2(4,-4),1.5,gold)
		"sound":
			if v==1 or v==6:
				for i in range(4 if v==1 else 7):
					var q:=Vector2(5+float(i)*6,30-sin(t*TAU+float(i)*.7)*9.0)
					fx_disc(im,q,2.5,rose if v==1 else dark)
					fx_line(im,q,q-Vector2(0,9),1.8,light);fx_line(im,q-Vector2(0,9),q+Vector2(5,-6),1.8,gold if v==1 else dark)
				if v==6:psi_ring(im,c,15.0+sin(t*PI)*3.0,rose,dark)
			else:
				for i in range(3+v%4):
					var q:=Vector2(5+float(i)*7+4*t,24+sin(t*TAU+float(i))*float(v%3)*2.0)
					fight_arc(im,q,6.0+float(i)*1.8,-PI*.5,PI,cyan if v==3 else gold,dark,2.0+float(v%3))
				if v==0:fight_burst(im,c,14.0,6,t,rose,dark)
				if v==5:fx_disc(im,Vector2(11+5*t,24),5.0,rose)
		"eyes":
			var r:float=11.0+sin(t*PI)*4.0
			for i in [-1,1]:
				var q:=c+Vector2(float(i)*9.0,0)
				fight_arc(im,q,7.0,-PI*.8,PI*.6,light,dark,2.7);fight_arc(im,q,7.0,PI*.2,PI*.6,light,dark,2.0)
				fx_disc(im,q+Vector2(sin(t*TAU)*2.0,0),2.0+float(v%3),rose if v<4 else cyan)
			if v==0:fx_line(im,c-Vector2(14,10),c+Vector2(14,10),2.0,dark)
			elif v==1:fight_burst(im,c,r+4.0,8,t,rose,dark)
			elif v==2:fx_line(im,c-Vector2(15,3),c+Vector2(15,3),1.8,gold)
			elif v==3:psi_polygon(im,c,r,4,PI*.25,gold,dark)
			else:psi_ring(im,c,r+4.0,cyan,dark)
		"lock":
			var r:float=10.0+sin(t*PI)*5.0
			if v==0:
				fight_arc(im,c,r,t*TAU,PI*1.7,gold,dark,3.0);fx_line(im,c+Vector2(4,-12),c+Vector2(10,-5),3.0,light)
			elif v==1:
				psi_ring(im,c,r,rose,dark);fx_line(im,c-Vector2(10,10),c+Vector2(10,10),3.8,rose)
			elif v==2:
				psi_polygon(im,c,r,4,PI*.25,light,dark)
				for i in range(3):fx_line(im,Vector2(16+float(i)*8,10+3*t),Vector2(16+float(i)*8,37-3*t),2.8,dark)
			elif v==3:
				psi_polygon(im,c,r,5,t*PI,rose,dark);fight_burst(im,c,r+4.0,5,t,dark,rose)
			else:
				var q:=c+Vector2(sin(t*PI)*8.0,0)
				psi_polygon(im,q,9.0,5,PI*.5,cyan,dark)
				fx_disc(im,q+Vector2(-3,-1),1.6,light);fx_disc(im,q+Vector2(3,-1),1.6,light)
		"shift":
			var palette:Array[Color]=[rose,cyan,gold,Color("#a1d18c")]
			for i in range(4+v):
				var a:float=float(i)*TAU/float(4+v)+t*TAU
				var q:=c+Vector2(cos(a),sin(a))*(8.0+sin(t*PI)*8.0)
				psi_polygon(im,q,4.0+float(v),3+v,a,palette[i%4],dark)
			if v==0:psi_ring(im,c,8.0+sin(t*PI)*5.0,cyan,dark)
			elif v==1:psi_polygon(im,c,10.0,6,-t*TAU,gold,dark)
			elif v==2:psi_polygon(im,c,8.0+sin(t*PI)*6.0,3+int(t*4.0),t*PI,light,dark)
			else:
				for i in range(4):fx_disc(im,c+Vector2(float(i%2)*8-4,float(i/2)*8-4),3.0,Color(palette[3],.8))
		"copy":
			var q:=Vector2(9+30*t,24-sin(t*PI)*7.0)
			if v==0:
				for i in range(5):
					var a:float=float(i)*TAU/5.0+t
					psi_polygon(im,q+Vector2(cos(a),sin(a))*8.0,4.0,3,a,Color("#a1d18c"),dark)
			elif v==1:
				fx_line(im,q-Vector2(6,8),q+Vector2(7,7),3.0,gold);fx_line(im,q+Vector2(7,7),q+Vector2(2,7),2.0,light)
			elif v==2:fight_burst(im,q,11.0,5,t,cyan,dark)
			elif v==3 or v==6:
				psi_polygon(im,q,7.0,4+v%3,t*PI,cyan,dark);psi_polygon(im,Vector2(48-q.x,29),5.0,4+v%3,-t*PI,rose,dark)
				if v==6:psi_ring(im,q,10.0,light,dark)
			elif v==4:
				fx_line(im,c+Vector2(0,11),c+Vector2(sin(t*TAU)*12,-12),3.0,gold)
				fx_disc(im,c+Vector2(sin(t*TAU)*12,-12),3.0,light)
			else:
				for i in range(3):fx_line(im,q-Vector2(10,float(i-1)*5),q+Vector2(5,float(i-1)*5),2.0,gold)
			if v!=4:fx_disc(im,q,1.7,gold)
		"motion":
			for i in range(3+v):
				var a:float=float(i)*TAU/float(3+v)+t*TAU
				var q:=c+Vector2(cos(a),sin(a))*(8.0+sin(t*PI)*7.0)
				fight_arc(im,q,6.0+float(v),a,PI*1.2,gold if v%2==0 else rose,dark,2.2)
				if v!=2:fx_disc(im,q,2.0,cyan)
			if v==0:psi_polygon(im,c,8.0,5,t*PI,gold,dark)
			elif v==2:fx_line(im,c,c+Vector2(sin(t*TAU)*14,9),4.0,rose)
		"item":
			var q:=Vector2(8+32*t,24-sin(t*PI)*10.0)
			if v==0:
				fx_line(im,q-Vector2(5,-5),q+Vector2(5,-5),4.0,gold);fx_disc(im,q+Vector2(5,-5),3.0,light)
			else:
				for i in range(3):
					var a:float=t*TAU+float(i)*TAU/3.0
					fight_arc(im,c,13.0,a,PI*.6,cyan,dark,3.2)
				psi_polygon(im,q,5.0,4,t*PI,gold,dark)
		"space":
			if v==0:
				var q:=Vector2(24,33-absf(sin(t*TAU))*20.0)
				fx_disc(im,q,5.0,light)
				for i in range(5):fx_disc(im,Vector2(8+float(i)*8,36-sin(t*PI)*float(i%3)*5),2.0,cyan)
			elif v==1:
				for i in range(5):fight_arc(im,Vector2(24,7+float(i)*8),5.0+float(4-i)*2.5,t*TAU+float(i)*.4,PI*1.5,cyan,dark,2.8)
			else:
				fx_disc(im,c,4.0+sin(t*PI)*7.0,light);fight_burst(im,c,10.0+sin(t*PI)*11.0,12,t,light,gold)

# Fairy magic has its own material vocabulary: iridescent stars, prism rays,
# crescents and luminous dust rather than recolored generic physical sparks.
func fairy_star(im:Image,at:Vector2,r:float,tint:Color)->void:
	fx_line(im,at-Vector2(r,0),at+Vector2(r,0),.8,tint)
	fx_line(im,at-Vector2(0,r),at+Vector2(0,r),.8,tint)
	fx_disc(im,at,1.4,Color("#fffbe8"))

func fairy_sprite(im:Image,role:String,frame:int)->void:
	var t:float=float(frame)/11.0
	var c:=Vector2(24,24)
	var pink:=Color("#ffacde");var violet:=Color("#a78af5");var gold:=Color("#ffe5a4")
	var pearl:=Color("#fff7ef")
	match role:
		"fairy_glimmer":
			var q:=Vector2(8+30*t,24)
			for i in range(5):
				fairy_star(im,q-Vector2(float(i)*5,sin(t*TAU+i)*4),maxf(1.5,5.5-float(i)),pink if i%2==0 else gold)
		"fairy_halo","fairy_dust":
			for i in range(9):
				var a:float=float(i)*TAU/9.0+t*3.0
				var radius:float=8.0+12.0*sin(t*PI)
				var q:=c+Vector2(cos(a),sin(a))*radius
				fairy_star(im,q,2.5+float(i%3),gold if i%2==0 else pink)
			if role=="fairy_halo":fx_disc(im,c,14.0+sin(t*PI)*4.0,violet,12.0+sin(t*PI)*4.0)
		"fairy_prism","fairy_verdict":
			var q:=Vector2(11+24*t,24) if role=="fairy_prism" else c
			for i in range(6 if role=="fairy_prism" else 8):
				var a:float=float(i)*TAU/(6.0 if role=="fairy_prism" else 8.0)+t
				var tip:=q+Vector2(cos(a),sin(a))*(7.0+12.0*sin(t*PI))
				fx_line(im,q,tip,2.6,violet)
				fx_line(im,q,tip,.9,pearl)
				fairy_star(im,tip,2.5,gold)
			fx_disc(im,q,3.5,pink)
		"fairy_kick","fairy_blade":
			var a:float=-PI*.8+t*PI
			fight_arc(im,c,15.0,a,1.8,pink,violet,3.2)
			var q:=c+Vector2(cos(a+1.5),sin(a+1.5))*14.0
			fairy_star(im,q,5.5,gold)
			if role=="fairy_kick":
				fx_line(im,q-Vector2(6,5),q+Vector2(2,3),3.1,violet)
				fx_line(im,q+Vector2(2,3),q+Vector2(7,3),2.1,pearl)
		"fairy_comet":
			var q:=Vector2(8+30*t,8+26*t)
			fx_line(im,q-Vector2(12,11),q,4.0,violet)
			fx_line(im,q-Vector2(10,9),q,2.0,pink)
			fairy_star(im,q,7.0,gold)
		_:fairy_star(im,c,8.0,pearl)

# These sixty native casts were identified by the V15.0 exact-frame audit.
# Recompose the shared base artwork with the native move's authored stage.
const NATIVE_IDENTITY_CASTS=["lib_electric_2","lib_steel_3","lib_ground_3","lib_water_3","lib_steel_2","lib_bug_2","lib_ground_2","lib_water_1","lib_ghost_3","lib_fighting_2","lib_poison_1","lib_ice_1","lib_fairy_1","lib_rock_2","lib_dragon_1","lib_ghost_1","lib_psychic_3","lib_psychic_2","lib_water_2","lib_steel_1","lib_dragon_3","lib_dark_1","lib_fire_3","lib_electric_3","lib_normal_1","lib_bug_1","lib_dark_3","lib_dragon_2","alt_sylphowl","lib_electric_1","alt_leviathorn","alt_astro_golem","lib_poison_3","lib_flying_2","lib_flying_1","alt_tidal_sovereign","lib_ground_1","lib_fighting_3","alt_mossmite","lib_ghost_2","alt_voidspider","lib_psychic_1","lib_bug_3","lib_grass_3","lib_grass_2","lib_fire_2","alt_bubblewisp","alt_fungal_monarch","lib_dark_2","lib_ice_2","lib_poison_2","lib_rock_3","lib_rock_1","lib_grass_1","lib_ice_3","alt_crystarok","lib_flying_3","lib_fighting_1","lib_fire_1","lib_normal_3"]
# Accent cadence follows the same contact fraction as the world animation.
# X: secondary intensity, Y: primary size, Z: trailing dissipation.
func native_polish_sample(progress:float,impact:float)->Vector3:
	var t:float=clampf(progress,0.0,1.0)
	var peak:float=clampf(impact,.12,.88)
	var rise:float=smoothstep(0.0,peak,t)
	var after:float=clampf((t-peak)/(1.0-peak),0.0,1.0)
	var fade:float=1.0-smoothstep(.0,1.0,after)
	return Vector3(.20+.80*rise*fade,36.0+6.0*rise*fade,fade)

func native_identity_frame(id:String,frame:int,base:Image)->Image:
	var im:=Image.create(FX_FRAME_SIZE,FX_FRAME_SIZE,false,Image.FORMAT_RGBA8)
	im.fill(Color.TRANSPARENT)
	var cue:Array=AUTHORED_STAGE_FX[id]
	var style:Array=combat_style(id)
	var light:=Color(style[1]);var dark:=Color(style[2])
	var mode:String=str(cue[0])
	var material:String=str(cue[1])
	var t:float=float(posmod(frame,FX_FRAME_COUNT))/float(FX_FRAME_COUNT-1)
	var peak:float=clampf(float(combat_profile(id).impact),.12,.88)
	var drive:float=clampf(t/peak,0.0,1.0)
	var release:float=clampf((t-peak)/(1.0-peak),0.0,1.0)
	var envelope:float=sin(t*PI)
	var c:=Vector2(24,24)
	var extent:float=clampf(float(cue[3])*12.0,3.0,13.0)
	var height:float=clampf(float(cue[4])*8.0,1.0,12.0)
	var polish:=native_polish_sample(t,peak)
	var size_px:int=clampi(roundi(polish.y),36,42)
	base.resize(size_px,size_px,Image.INTERPOLATE_NEAREST)
	var center:=c
	match mode:
		"stream","cone","dash","wave":center.x+=lerpf(-3.0,3.0,drive)
		"fall":center.y-=height*.30*(1.0-drive)
		"eruption","rise":center.y-=height*.30*envelope
		"ground":center.y+=3.0
		"arc":center.y-=height*.45*sin(drive*PI)
		"sweep":center.x+=sin(t*TAU)*2.0
	var offset:=Vector2i(center-Vector2.ONE*float(size_px)*.5)
	# Keep the primary silhouette in a separate layer; supporting motes must
	# not erase its pixels or become equally prominent.
	var accents:=Image.create(FX_FRAME_SIZE,FX_FRAME_SIZE,false,Image.FORMAT_RGBA8)
	accents.fill(Color.TRANSPARENT)
	# Semantic material silhouettes: these remain tiny compared with the main art.
	var amount:int=clampi(int(cue[2])-2,3,8)
	for i in range(amount):
		var f:float=float(i)/maxi(1,amount-1)
		var angle:float=f*TAU
		var p:=c
		var direction:=Vector2(cos(angle),sin(angle))
		match mode:
			"stream","dash":p=Vector2(4.0+39.0*f,24.0+sin(f*TAU-t*TAU)*height*.34)
			"cone":p=Vector2(6.0+35.0*f,24.0+(-1.0 if i%2==0 else 1.0)*extent*f)
			"wave":p=c+Vector2((f-.5)*38.0,sin(f*TAU-t*TAU)*height)
			"fall":p=c+Vector2((f-.5)*30.0,-20.0+drive*35.0-f*4.0)
			"rise","eruption":p=c+Vector2(direction.x*extent,14.0-drive*25.0+f*4.0)
			"ground":p=c+Vector2(direction.x*(7.0+extent*drive),9.0+direction.y*extent*.35)
			"pincer":p=c+Vector2((-1.0 if i%2==0 else 1.0)*(19.0-extent*drive),-11.0+22.0*f)
			"whip":p=c+Vector2((f-.5)*38.0,sin(f*TAU*1.5-t*5.0)*extent)
			"arc":p=c+Vector2((f-.5)*32.0,-sin(f*PI)*height-4.0*envelope)
			"sweep":p=c+Vector2(cos(angle*.7+t*2.0),sin(angle*.7+t*2.0))*(12.0+extent*.5)
			"coil","wheel","helix":p=c+direction.rotated(t*TAU)*(12.0+extent*.5)
			"burst","contact":p=c+direction*(5.0+extent*(.4+release))
			_:p=c+direction*(12.0+extent*.45)
		p.x=clampf(p.x,3.0,44.0);p.y=clampf(p.y,3.0,44.0)
		var r:float=.8+.85*polish.x
		match material:
			"bubble","drop","venom_splash":fx_disc(accents,p,r+1.0,dark,r);fx_disc(accents,p-Vector2(.7,.7),.75,light)
			"crystal","shards","dart":fx_line(accents,p-Vector2(0,2),p+Vector2(2,1),1.25,dark);fx_line(accents,p-Vector2(0,2),p+Vector2(1,0),.65,light)
			"leaf","whip","web":fx_line(accents,p-Vector2(2,1),p+Vector2(2,-1),1.15,dark);fx_line(accents,p-Vector2(1,0),p+Vector2(1,-1),.65,light)
			"lightning":fx_line(accents,p-Vector2(2,1),p,1.0,dark);fx_line(accents,p,p+Vector2(1,2),.8,light)
			"ember","flame","smoke","cloud":fx_disc(accents,p,r+1.0,dark);fx_disc(accents,p-Vector2(0,1),r*.65,light)
			"slash","shock_ring":fx_line(accents,p-direction*2.4,p+direction*2.4,.9,light)
			"earth_hole":fx_line(accents,p-Vector2(2,0),p+Vector2(2,0),1.0,dark)
			_:fx_disc(accents,p,r,dark);fx_disc(accents,p,.7,light)
	# Softly attenuate the cached accent alpha (one-time texture generation).
	# Drawing the original base last keeps its anatomy crisp at 48 pixels.
	for y in range(FX_FRAME_SIZE):
		for x in range(FX_FRAME_SIZE):
			var pixel:=accents.get_pixel(x,y)
			if pixel.a<=0.0:continue
			pixel.a*=.36+.57*polish.x
			accents.set_pixel(x,y,pixel)
	im.blit_rect(accents,Rect2i(Vector2i.ZERO,accents.get_size()),Vector2i.ZERO)
	im.blend_rect(base,Rect2i(Vector2i.ZERO,base.get_size()),offset)
	return im

# V16.7: individually remastered after reviewing actual Godot PNG strips.
const VISUAL_REMASTER_MOVES=["eos_504","eos_308","eos_135","eos_142","eos_047","eos_250","eos_299","eos_329","eos_262","eos_279","eos_101","eos_199","eos_251","eos_486","eos_462","eos_018","eos_507","eos_175","eos_254","eos_097","eos_163","eos_320","eos_033","eos_166","eos_228","eos_004","eos_252","eos_330","eos_465","eos_138","eos_021","eos_501","eos_053","eos_157","eos_064","eos_188","eos_240","eos_255","eos_342","eos_539","eos_041","eos_278","eos_538","eos_239","eos_193","eos_272","eos_519","eos_494","eos_292","eos_065","eos_276","eos_208","eos_522","eos_452","eos_433","eos_087","eos_063","eos_062","eos_476","eos_127","eos_451","eos_436","eos_491","eos_046","eos_109","eos_234","eos_107","eos_463","eos_133","eos_317","eos_111","eos_331","eos_345","eos_270","eos_042","eos_344","eos_461","eos_180","eos_535","eos_150","eos_118","eos_484","eos_008","eos_131","eos_030","eos_481","eos_028","eos_073","lib_ground_1","eos_057","eos_036","eos_442","eos_153","eos_205","eos_100","eos_518","eos_178","eos_200","eos_495","eos_280","eos_197","eos_332","eos_147","eos_485","eos_459","eos_151","eos_537","eos_443","eos_336","eos_182","eos_253","eos_441","eos_076","lib_grass_1","eos_001","eos_325","eos_103","eos_536","eos_510","eos_431","eos_475","eos_523","eos_080","eos_082","eos_114","eos_323","eos_470","eos_502","eos_529","eos_530","eos_460","eos_520","eos_449","eos_288","eos_164","eos_306","eos_023","eos_086","eos_346","lib_fairy_1","lib_fairy_2","lib_fairy_3","eos_341","eos_498","eos_343","eos_091","eos_162","eos_435","lib_dragon_1","lib_dragon_2","lib_dragon_3","eos_092","eos_204","eos_206","eos_303","eos_222","eos_210","lib_fighting_2","eos_136","eos_075","eos_300","eos_246","eos_430","eos_440","eos_500","eos_508","eos_454","eos_479","eos_243","eos_068","eos_090","lib_fighting_1","lib_fighting_3","eos_072","eos_077","eos_116","eos_531","eos_265","eos_305","eos_051","eos_170","eos_340","eos_007","eos_029","lib_electric_1","lib_electric_2","lib_electric_3","eos_129","eos_144","eos_189","eos_354","eos_489","eos_521","eos_192","eos_128","eos_493","lib_fire_1","lib_fire_2","lib_fire_3","eos_052","eos_149","eos_230","eos_291","eos_517","eos_524","eos_223","lib_water_1","lib_water_2","lib_water_3","eos_016","eos_032","eos_044","eos_069","eos_113","eos_156","eos_158","eos_159","eos_219","eos_310","eos_432","eos_469","eos_070","eos_012","eos_307","eos_434","lib_grass_2","lib_grass_3","eos_221","eos_238","eos_297","eos_458","eos_468","eos_511","eos_079","eos_231","eos_124","eos_351","eos_015","eos_094","eos_084","eos_233","lib_ice_1","lib_ice_2","lib_ice_3","eos_002","eos_088","eos_130","eos_014","lib_poison_1","lib_poison_2","lib_poison_3","eos_198","eos_283","eos_196","eos_202","eos_496","eos_438","lib_ground_2","lib_ground_3","eos_143","eos_213","eos_289","eos_285","eos_290","eos_212","eos_295","eos_296","lib_rock_1","lib_rock_2","lib_rock_3","eos_093","eos_453","eos_512","eos_533","eos_350","eos_105","eos_540","eos_141","eos_480","lib_flying_1","lib_flying_2","lib_flying_3","eos_174","eos_179","eos_211","eos_353","eos_446","eos_490","eos_444","eos_267","eos_509","eos_456","eos_040","lib_bug_1","lib_bug_2","lib_bug_3","lib_psychic_1","lib_psychic_2","lib_psychic_3","eos_110","eos_309","eos_335","eos_473","eos_099","eos_146","eos_215","eos_258","eos_319","eos_333","eos_095","eos_316","eos_338","eos_259","eos_108","eos_187","eos_266","eos_448","eos_506","eos_513","eos_514","eos_232","eos_464","eos_478","eos_528","eos_450","eos_298","eos_499","eos_209","eos_137","eos_220","eos_439","eos_526","lib_ghost_1","lib_ghost_2","lib_ghost_3","eos_120","eos_126","eos_437","eos_477","eos_013","eos_216","eos_005","eos_313","eos_035","eos_049"]
func visual_remaster_frame(id:String,frame:int)->Image:
	var im:=Image.create(48,48,false,Image.FORMAT_RGBA8)
	im.fill(Color.TRANSPARENT)
	var t:float=float(posmod(frame,FX_FRAME_COUNT))/float(FX_FRAME_COUNT-1)
	var peak:float=clampf(float(combat_profile(id).impact),.12,.88)
	var drive:float=smoothstep(0.0,peak,t)
	var fade:float=1.0-smoothstep(peak,1.0,t)
	var pulse:float=sin(t*PI)
	var style:Array=combat_style(id)
	var light:=Color(style[1]);var dark:=Color(style[2])
	var pale:=light.lerp(Color.WHITE,.65)
	match id:
		"eos_308":
			# Water Gun: connected narrow jet, foamy head and trailing droplets.
			var head:=Vector2(12+23*drive,24+sin(t*TAU)*2.5)
			var tail:=Vector2(maxf(4.0,head.x-21.0*fade),25)
			for j in range(1,12):
				var a:=tail.lerp(head,float(j-1)/11.0)
				var b:=tail.lerp(head,float(j)/11.0)
				a.y+=sin(float(j-1)*.7-t*TAU)*1.8
				b.y+=sin(float(j)*.7-t*TAU)*1.8
				fx_line(im,a,b,2.1+float(j)*.12,Color("#176aa2"))
				fx_line(im,a,b,1.0+float(j)*.10,Color("#66d7f9"))
			water_drop(im,head,3.7+2.0*pulse,pale,Color("#2e8dbd"))
			for j in range(4):
				var q:=head+Vector2(-float(j)*3.5,(-1.0 if j%2==0 else 1.0)*(5.0+t*4.0))
				fx_disc(im,q,1.6,Color("#9fe9ff"))
		"eos_135":
			# Absorb: green energy drawn from the right toward the caster.
			var travel:float=smoothstep(peak,1.0,t)
			for j in range(4):
				var f:float=clampf(drive*.35+travel*.65+float(j)*.12,0.0,1.0)
				var q:=Vector2(40-32*f,24+sin(f*TAU+float(j))*5.0)
				fx_line(im,q,q+Vector2(6,2*sin(t*TAU+float(j))),2.0,dark)
				fx_disc(im,q,3.2,Color("#4fc04d"))
				fx_disc(im,q-Vector2(1,1),1.6,Color("#d5ff9d"))
			fx_disc(im,Vector2(8,24),5.0+5.0*travel,Color(light,.60),3.5+5.0*travel)
		"eos_142":
			# Sand Attack: broad low cone of dusty grains rather than a sine wave.
			for j in range(15):
				var f:float=float(j)/14.0
				var q:=Vector2(8+30*f*drive,29+sin(float(j)*2.4+t*3.0)*(2.0+10.0*f))
				fx_disc(im,q,2.0+f*2.1,Color("#8f6b43",.75*fade+.15))
				fx_disc(im,q-Vector2(1,1),1.3+f*.7,Color("#e8c78d",.8*fade+.15))
			for j in range(5):fx_line(im,Vector2(8,31),Vector2(11+25*drive,22+float(j)*3.5),.75,Color("#c8a36a",.25+.3*fade))
		"eos_047":
			# Will-O-Wisp: violet ghost flame lobes, curling tails and hot cores.
			for j in range(3):
				var q:=Vector2(11+12*float(j),27+sin(t*TAU+float(j)*2.0)*4.0)
				var r:float=3.7+1.5*pulse
				fire_lobe(im,q,r,t+float(j)*.16,Color("#f6d2ff"),Color("#a35be7"))
				fx_line(im,q+Vector2(0,2),q+Vector2(-4-3*fade,8),1.2,Color("#7746bb",.7))
				fx_disc(im,q+Vector2(4,-8),1.1,Color("#efd0ff"))
		"eos_504":
			# Worry Seed: large asymmetric seed and nervous orbital motes.
			var q:=Vector2(10+26*drive,24-6*sin(drive*PI))
			fx_line(im,q+Vector2(-3,4),q+Vector2(3,-4),5.0,Color("#315b35"))
			fx_line(im,q+Vector2(-2,3),q+Vector2(2,-3),3.7,Color("#9cca51"))
			fx_line(im,q+Vector2(-3,2),q+Vector2(2,-3),1.1,Color("#e4ffab"))
			grass_leaf(im,q+Vector2(0,-5),-1.1+t*.6,7.0,light,dark)
			for j in range(4):
				var a:float=float(j)*TAU/4.0+t*TAU
				fx_disc(im,q+Vector2(cos(a),sin(a))*8.5,1.5,Color("#d5f88a",.9))
		"eos_250":
			# Pound: weighty blunt strike with a short gold compression burst.
			var q:=Vector2(11+21*drive,24)
			fx_line(im,q-Vector2(11*fade,0),q,3.0,Color("#ae7953",.75))
			fx_disc(im,q,6.0+2.0*pulse,Color("#76503a"))
			fx_disc(im,q+Vector2(2,-1),4.9,Color("#edba76"))
			fx_disc(im,q+Vector2(3,-2),2.5,Color("#fff0c4"))
			if t>=peak:
				for j in range(5):
					var a:float=-PI*.8+float(j)*PI*.4
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,q+axis*6.0,q+axis*(8.0+8.0*(1.0-fade)),1.3,Color("#ffd895",fade))
		"eos_299":
			# Mud Shot: dense uneven clay projectile, splatter and granular tail.
			var q:=Vector2(10+24*drive,25-3*sin(drive*PI))
			fx_line(im,q-Vector2(9*fade,0),q,3.0,Color("#65422f",.9))
			fx_disc(im,q,6.0,Color("#704631"))
			fx_disc(im,q-Vector2(1,2),4.1,Color("#b6804c"))
			for j in range(6):
				var a:float=float(j)*TAU/6.0+t
				var mote:=q+Vector2(cos(a),sin(a))*(7.0+4.0*(1.0-fade))
				fx_disc(im,mote,1.5+float(j%2),Color("#9b633c",.3+.7*fade))
		"eos_329":
			# Leech Seed: seed pods, roots and a green sprouting silhouette.
			for j in range(3):
				var q:=Vector2(11+12*float(j),22+sin(t*TAU+float(j))*4.0)
				fx_disc(im,q,4.4,Color("#325c35"))
				fx_disc(im,q-Vector2(1,1),2.9,Color("#a5df56"))
				fx_line(im,q+Vector2(0,2),q+Vector2(0,8+5*drive),1.4,Color("#468a39"))
				fx_line(im,q+Vector2(0,7),q+Vector2(-4,12),1.0,Color("#70ab44"))
				grass_leaf(im,q+Vector2(0,-3),-1.4+float(j)*.3,6.0,light,dark)
		"eos_262":
			# Ember: separate incandescent cinders with flickering flame tails.
			for j in range(4):
				var f:float=clampf(drive*.85+float(j)*.08,0.0,1.0)
				var q:=Vector2(8+30*f,24+sin(float(j)*2.4+t*TAU)*6.0)
				var r:float=2.4+1.8*pulse+float(j%2)
				fx_line(im,q-Vector2(5.0+4.0*fade,2),q,2.1,Color("#9d3218",.8*fade+.12))
				fire_lobe(im,q,r,t+float(j)*.19,Color("#fff2a4"),Color("#f05a24"))
				fx_disc(im,q+Vector2(-5,-5),1.3,Color("#ffc35b",.25+.65*fade))
		"eos_279":
			# Sludge: heavy toxic mass, uneven lobes and a splattering impact.
			var q:=Vector2(10+24*drive,25-5*sin(drive*PI))
			fx_line(im,q-Vector2(9*fade,0),q,3.0,Color("#51215e",.8))
			for j in range(5):
				var a:float=float(j)*TAU/5.0+t*2.0
				var axis:=Vector2(cos(a),sin(a))
				fx_disc(im,q+axis*(3.6+5.0*(1.0-fade)),4.1,Color("#51215e",.35+.65*fade))
				fx_disc(im,q+axis*(3.0+5.0*(1.0-fade))-Vector2(1,1),2.6,Color("#ad57bf",.35+.65*fade))
			fx_disc(im,q-Vector2(2,3),2.5,Color("#e9a8ee",.7))
			if t>=peak:
				for j in range(7):
					var a:float=float(j)*TAU/7.0
					fx_disc(im,q+Vector2(cos(a),sin(a))*(8+8*(1.0-fade)),1.7,Color("#a96bca",fade))
		"eos_101":
			# Powder Snow: turbulent cloud of fine flakes with crystalline silhouettes.
			for j in range(14):
				var f:float=float(j)/13.0
				var q:=Vector2(7+34*f*drive,24+sin(float(j)*2.7+t*5.0)*(4.0+9.0*f))
				fx_disc(im,q,3.0+2.1*f,Color("#659fc6",.23+.28*fade))
				if j%3==0:
					ice_crystal(im,q,t*2.0+float(j),3.4+f,Color("#e6fbff",.4+.6*fade),Color("#8ed3f6",.35+.6*fade))
				else:
					fx_disc(im,q-Vector2(1,1),1.3,Color("#eafaff",.5+.5*fade))
		"eos_199":
			# Poison Powder: expanding violet cloud with irregular drifting granules.
			for j in range(18):
				var f:float=float(j)/17.0
				var q:=Vector2(7+33*f*drive,24+sin(float(j)*2.33+t*4.0)*(3.0+12.0*f))
				fx_disc(im,q,2.8+f*2.1,Color("#6b347e",.18+.32*fade))
				fx_disc(im,q-Vector2(1,1),1.3+float(j%3)*.45,Color("#d389db",.25+.65*fade))
				if j%4==0:fx_disc(im,q+Vector2(1,-3),1.0,Color("#f9c9f0",.75*fade))
		"eos_251":
			# Razor Leaf: sharp, individually tumbling blades with cutting wakes.
			for j in range(4):
				var f:float=clampf(drive*.78+float(j)*.12,0.0,1.0)
				var q:=Vector2(8+30*f,24+sin(float(j)*2.3+t*4.0)*9.0)
				var a:float=-.55+sin(t*TAU+float(j))*1.1
				fx_line(im,q-Vector2(7*fade,2),q,1.4,Color("#3c8d49",.7*fade+.1))
				grass_leaf(im,q,a,10.0+2*pulse,Color("#a8ec65"),Color("#286e42"))
				fx_line(im,q,q+Vector2(cos(a),sin(a))*5.0,1.0,Color("#e6ffc2",.85))
		"eos_486":
			# Seed Bomb: solid striped seed, arcing flight and explosive husk fragments.
			var q:=Vector2(10+25*drive,27-10*sin(drive*PI))
			fx_disc(im,q,7.0,Color("#35502b"))
			fx_disc(im,q-Vector2(1,1),5.3,Color("#90b94b"))
			for j in range(3):
				fx_line(im,q+Vector2(-4+float(j)*3,-4),q+Vector2(-2+float(j)*3,4),1.1,Color("#496e37"))
			fx_disc(im,q-Vector2(2,3),2.0,Color("#d6f395"))
			if t>=peak:
				for j in range(8):
					var a:float=float(j)*TAU/8.0
					var axis:=Vector2(cos(a),sin(a))
					var mote:=q+axis*(7+8*(1.0-fade))
					grass_leaf(im,mote,a,4.5,Color("#cae88a",fade),Color("#567c36",fade))
					fx_line(im,q+axis*6,mote,1.1,Color("#d9f28d",fade))
		"eos_462":
			# Ice Shard: pointed faceted ice projectile with sharp fracture streaks.
			var q:=Vector2(11+25*drive,24)
			fx_line(im,q-Vector2(12*fade,0),q+Vector2(5,0),2.2,Color("#4d9bd4",.75))
			for j in range(7):
				var x:float=float(j)-4.0
				var w:float=3.7*(1.0-absf(x)/5.0)
				fx_line(im,q+Vector2(x,-w),q+Vector2(x,w),1.2,Color("#4096c8"))
				fx_line(im,q+Vector2(x,-w*.65),q+Vector2(x,0),1.0,Color("#d5f7ff"))
			fx_line(im,q+Vector2(-2,0),q+Vector2(8,0),1.2,Color("#efffff"))
			if t>=peak:
				for j in range(5):
					var a:float=float(j)*TAU/5.0
					var axis:=Vector2(cos(a),sin(a))
					var mote:=q+axis*(7+5*(1.0-fade))
					fx_line(im,mote,mote+axis*4,1.4,Color("#bcefff",fade))
		"eos_018":
			# Cut: sweeping crescent edge with a bright leading bevel.
			var center:=Vector2(24,25)
			var sweep:float=-1.3+2.4*drive
			for j in range(1,14):
				var f:float=float(j)/13.0
				var a:float=sweep-1.5+f*1.5
				var prev:float=a-1.5/13.0
				var radius:float=15.0+2.0*pulse
				var u:=center+Vector2(cos(prev),sin(prev))*radius
				var v:=center+Vector2(cos(a),sin(a))*radius
				fx_line(im,u,v,2.0+3.0*f,Color("#8c775e",.45+.55*fade))
				fx_line(im,u,v,1.0+1.4*f,Color("#fff2d7",.5+.5*fade))
			if t>=peak:
				var q:=center+Vector2(cos(sweep),sin(sweep))*16.0
				for j in range(3):
					var axis:=Vector2(cos(sweep+float(j-1)*.65),sin(sweep+float(j-1)*.65))
					fx_line(im,q,q+axis*(4+4*(1.0-fade)),1.3,Color("#fff3d1",fade))
		"eos_507":
			# Force Palm: open hand silhouette, concentrated aura, outward shock ring.
			var q:=Vector2(10+22*drive,24)
			fx_line(im,q-Vector2(12*fade,0),q,3.5,Color("#da593b",.75*fade+.1))
			fx_line(im,q-Vector2(5,0),q+Vector2(2,0),6.5,Color("#763c2d"))
			fx_line(im,q-Vector2(4,0),q+Vector2(2,0),5.2,Color("#ffc083"))
			for j in range(4):
				var y:float=-5.4+float(j)*3.0
				fx_line(im,q+Vector2(0,y),q+Vector2(6.5-float(j%2),y-.4),2.3,Color("#fff1cb"))
			fx_line(im,q+Vector2(-2,3),q+Vector2(1,8),2.6,Color("#ffdcaa"))
			if t>=peak:
				var radius:float=7.0+10.0*(1.0-fade)
				fx_disc(im,q+Vector2(3,0),radius,Color("#ffc36c",fade),radius-1.7)
				for j in range(6):
					var a:float=float(j)*TAU/6.0
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,q+axis*radius,q+axis*(radius+4.0),1.2,Color("#fff4bc",fade))
		"eos_175":
			# Rapid Palms: staggered hand strikes rather than one static fist.
			for j in range(3):
				var f:float=clampf(drive*1.2-float(j)*.13,0.0,1.0)
				var q:=Vector2(8+24*f,24+float(j-1)*7.0)
				var opacity:float=(.48+.24*float(j))*fade+.12
				fx_line(im,q-Vector2(9*fade,0),q,2.0,Color("#dc5f46",opacity))
				fx_line(im,q-Vector2(3,0),q+Vector2(1,0),4.8,Color("#a75239",opacity))
				for k in range(4):
					var y:float=-3.6+float(k)*2.3
					fx_line(im,q+Vector2(0,y),q+Vector2(4.5,y),1.5,Color("#ffe0ab",opacity))
				fx_line(im,q+Vector2(-1,2),q+Vector2(1,5),1.8,Color("#ffc68d",opacity))
				if t>=peak:
					fx_line(im,q+Vector2(6,-3),q+Vector2(10,-6),1.2,Color("#fff2c3",fade))
					fx_line(im,q+Vector2(6,3),q+Vector2(10,6),1.2,Color("#fff2c3",fade))
		"eos_254":
			# Bouncing Step: ground compression, airborne arc, harmless landing dust.
			var bounce:float=absf(sin(t*PI*2.0))
			var q:=Vector2(24,33-22*bounce)
			fx_line(im,Vector2(16-4*bounce,37),Vector2(32+4*bounce,37),1.3,Color("#c8ae85",.35+.35*(1.0-bounce)))
			fx_disc(im,q,4.7,Color("#c4935a"))
			fx_disc(im,q-Vector2(1,2),3.4,Color("#fff1cc"))
			for j in range(4):
				var x:float=float(j-2)*4.0
				fx_line(im,q+Vector2(x,6),q+Vector2(x,9+5*bounce),1.0,Color("#b3e9ec",.35+.55*bounce))
			for j in range(6):
				var a:float=PI+float(j)*PI/5.0
				var mote:=Vector2(24,36)+Vector2(cos(a)*12,sin(a)*5)*(1.0-bounce)
				fx_disc(im,mote,1.6,Color("#dec3a1",.8*(1.0-bounce)))
		"eos_097":
			# Icy Wind: layered curved gusts carrying snow and sharp ice crystals.
			for j in range(3):
				for k in range(1,11):
					var f:float=float(k)/10.0
					var g:float=float(k-1)/10.0
					var base_y:float=14.0+float(j)*10.0
					var a:=Vector2(5+36*g*drive,base_y+sin(g*TAU+t*5.0+float(j))*3.2)
					var v:=Vector2(5+36*f*drive,base_y+sin(f*TAU+t*5.0+float(j))*3.2)
					fx_line(im,a,v,1.8,Color("#4c9dcb",.45+.4*fade))
					fx_line(im,a-Vector2(0,1),v-Vector2(0,1),.85,Color("#dcfaff",.5+.5*fade))
			for j in range(7):
				var f:float=float(j)/6.0
				var q:=Vector2(8+32*f*drive,24+sin(float(j)*2.4+t*5.0)*12.0)
				ice_crystal(im,q,t+float(j),2.5+float(j%2),Color("#f1fcff"),Color("#86c9ee"))
		"eos_163":
			# Seed Volley: discrete striped seed projectiles in a timed burst.
			for j in range(5):
				var f:float=clampf(drive*1.3-float(j)*.14,0.0,1.0)
				var q:=Vector2(7+33*f,24+sin(float(j)*2.1)*5.0)
				fx_line(im,q-Vector2(7*fade,0),q,1.6,Color("#619b3b",.55*fade+.12))
				fx_line(im,q-Vector2(2,1),q+Vector2(2,1),3.4,Color("#365b29"))
				fx_line(im,q-Vector2(1,1),q+Vector2(1,0),2.1,Color("#c6e66c"))
				fx_disc(im,q+Vector2(1,-1),1.0,Color("#f2ffb9"))
				if t>=peak:
					fx_disc(im,q+Vector2(4,3),1.2,Color("#d7f39a",fade))
		"eos_320":
			# Mega Drain: two braided return streams and a growing caster-side aura.
			var travel:float=smoothstep(peak,1.0,t)
			for j in range(2):
				for k in range(1,13):
					var a:float=float(k-1)/12.0
					var f:float=float(k)/12.0
					var u:=Vector2(39-30*a,24+sin(a*TAU+t*TAU+float(j)*PI)*(6+2*travel))
					var v:=Vector2(39-30*f,24+sin(f*TAU+t*TAU+float(j)*PI)*(6+2*travel))
					fx_line(im,u,v,2.2,Color("#34874d",.35+.5*pulse))
					fx_line(im,u,v,1.0,Color("#b4ff87",.55+.4*pulse))
			for j in range(5):
				var f:float=fposmod(travel+float(j)*.2,1.0)
				var q:=Vector2(39-30*f,24+sin(f*TAU+t*TAU)*7.0)
				fx_disc(im,q,2.8,Color("#77dd51"))
				fx_disc(im,q-Vector2(1,1),1.5,Color("#ebffad"))
			var radius:float=4.0+7.0*travel
			fx_disc(im,Vector2(9,24),radius,Color("#affd78",.75*pulse),maxf(0.0,radius-1.6))
		"eos_033":
			# Sorrow Veil: falling teardrops with a dark violet emotional aura.
			var q:=Vector2(25,17)
			for j in range(7):
				var a:float=float(j)*TAU/7.0+t
				var mote:=q+Vector2(cos(a)*13,sin(a)*9)
				fx_disc(im,mote,2.0,Color("#634e94",.25+.45*pulse))
			for j in range(4):
				var f:float=fposmod(t+float(j)*.23,1.0)
				var d:=Vector2(13+float(j)*7.0,10+27*f)
				fx_line(im,d-Vector2(0,4),d,1.4,Color("#548cb4",.75))
				water_drop(im,d,2.8,Color("#d3f2ff"),Color("#527baf"))
				fx_disc(im,d-Vector2(1,1),1.0,Color("#ffffff",.85))
		"eos_166":
			# Egg Bomb: ivory egg, cracking shell and a radial burst.
			var q:=Vector2(10+25*drive,28-13*sin(drive*PI))
			fx_line(im,q-Vector2(0,3),q+Vector2(0,3),6.7,Color("#a98a70"))
			fx_line(im,q-Vector2(0,3),q+Vector2(0,2),5.2,Color("#fff0cf"))
			fx_disc(im,q-Vector2(2,3),2.1,Color("#fffbed"))
			if t>=peak:
				fx_line(im,q-Vector2(2,5),q+Vector2(1,-1),1.0,Color("#826d61"))
				fx_line(im,q+Vector2(1,-1),q-Vector2(2,1),1.0,Color("#826d61"))
				fx_line(im,q-Vector2(2,1),q+Vector2(2,5),1.0,Color("#826d61"))
				for j in range(7):
					var a:float=float(j)*TAU/7.0
					var axis:=Vector2(cos(a),sin(a))
					var mote:=q+axis*(6+9*(1.0-fade))
					fx_line(im,mote,mote+axis*3.0,2.0,Color("#fff0cf",fade))
					fx_disc(im,mote,1.2,Color("#ffd17e",fade))
		"eos_228":
			# Pay Day: minted coins turn edge-on in flight, then scatter.
			for j in range(5):
				var f:float=clampf(drive*1.25-float(j)*.12,0.0,1.0)
				var q:=Vector2(7+31*f,26-9*sin(f*PI)+float(j%2)*6.0)
				var w:float=1.2+3.0*absf(cos(t*TAU*1.5+float(j)))
				fx_line(im,q-Vector2(0,3),q+Vector2(0,3),w,Color("#966021"))
				fx_line(im,q-Vector2(0,3),q+Vector2(0,3),maxf(1.0,w-1.0),Color("#f9cb55"))
				fx_line(im,q-Vector2(0,2),q+Vector2(0,1),.85,Color("#fff6bb"))
				if t>=peak:
					var a:float=float(j)*TAU/5.0
					var mote:=q+Vector2(cos(a),sin(a))*(5+7*(1.0-fade))
					fairy_star(im,mote,2.2,Color("#ffe6a2",fade))
		"eos_004":
			# Dream Charm: distinct lip-print, floating pink hearts and sleep motes.
			var q:=Vector2(13+20*drive,24)
			fx_line(im,q-Vector2(7,0),q-Vector2(2,3),2.4,Color("#d64b79"))
			fx_line(im,q-Vector2(2,3),q+Vector2(0,-1),2.4,Color("#ff8bad"))
			fx_line(im,q+Vector2(0,-1),q+Vector2(3,-3),2.4,Color("#ff8bad"))
			fx_line(im,q+Vector2(3,-3),q+Vector2(7,0),2.4,Color("#d64b79"))
			fx_line(im,q-Vector2(7,0),q+Vector2(0,4),2.8,Color("#e95c8b"))
			fx_line(im,q+Vector2(0,4),q+Vector2(7,0),2.8,Color("#ff9fb9"))
			fx_line(im,q-Vector2(4,0),q+Vector2(4,0),.8,Color("#722d56"))
			for j in range(4):
				var a:float=float(j)*TAU/4.0+t*2.0
				var h:=q+Vector2(cos(a),sin(a))*(8+6*pulse)
				fx_disc(im,h-Vector2(1.4,1),1.8,Color("#ffb7d6",.35+.6*pulse))
				fx_disc(im,h+Vector2(1.4,-1),1.8,Color("#ffb7d6",.35+.6*pulse))
				fx_line(im,h-Vector2(2,0),h+Vector2(0,3),1.6,Color("#f07ca8",.35+.6*pulse))
				fx_line(im,h+Vector2(2,0),h+Vector2(0,3),1.6,Color("#f07ca8",.35+.6*pulse))
			if t>=peak:
				for j in range(2):
					var z:=Vector2(28+float(j)*7,15-8*(1.0-fade)-float(j)*3)
					fx_line(im,z,z+Vector2(4,0),1.0,Color("#e6c9ff",fade))
					fx_line(im,z+Vector2(4,0),z+Vector2(0,4),1.0,Color("#e6c9ff",fade))
					fx_line(im,z+Vector2(0,4),z+Vector2(4,4),1.0,Color("#e6c9ff",fade))
		"eos_252":
			# Relay Step: luminous baton transfers between two swap gates.
			for j in range(2):
				var gate:=Vector2(10+28*float(j),24)
				for k in range(1,15):
					var a:float=float(k-1)*TAU/14.0
					var v:float=float(k)*TAU/14.0
					fx_line(im,gate+Vector2(cos(a)*5,sin(a)*11),gate+Vector2(cos(v)*5,sin(v)*11),1.3,Color("#c6eaff",.25+.65*pulse))
			var q:=Vector2(10+28*drive,24-8*sin(drive*PI))
			fx_line(im,q-Vector2(4,4),q+Vector2(4,4),3.8,Color("#9c683a"))
			fx_line(im,q-Vector2(4,4),q+Vector2(4,4),2.6,Color("#ffd477"))
			fx_disc(im,q-Vector2(4,4),2.6,Color("#fff8c7"))
			for j in range(3):
				var x:float=13+float(j)*9
				var y:float=30+2*sin(t*TAU+float(j))
				fx_line(im,Vector2(x,y),Vector2(x-3,y-3),1.1,Color("#93dffc",.35+.55*pulse))
				fx_line(im,Vector2(x,y),Vector2(x-3,y+3),1.1,Color("#93dffc",.35+.55*pulse))
		"eos_330":
			# Chance Invocation: pendulum gestures above a colorful random-cast halo.
			var pivot:=Vector2(24,30)
			var angle:float=sin(t*TAU*2.0)*.85
			var axis:=Vector2(sin(angle),-cos(angle))
			fx_line(im,pivot,pivot+axis*14.0,4.0,Color("#946638"))
			fx_line(im,pivot,pivot+axis*14.0,2.8,Color("#ffd87d"))
			fx_disc(im,pivot+axis*15.0,2.8,Color("#fff3cb"))
			var colors:Array[Color]=[Color("#ef805f"),Color("#80d7ed"),Color("#c1ed7d"),Color("#cda1ff")]
			for j in range(4):
				var a:float=float(j)*TAU/4.0+t*TAU
				var q:=Vector2(24,20)+Vector2(cos(a)*15,sin(a)*12)
				fairy_star(im,q,2.4+1.1*pulse,Color(colors[j],.4+.6*pulse))
			if t>=peak:
				var radius:float=8+11*(1.0-fade)
				fx_disc(im,Vector2(24,24),radius,Color("#fff1bc",.8*fade),radius-1.1)
		"eos_465":
			# First Echo (Me First): mirrored echo travels ahead of the caster's mark.
			for j in range(2):
				var q:=Vector2(12+24*drive-float(j)*9,24+float(j)*5)
				var tint:=Color("#ffe4a6",.9 if j==0 else .42)
				fx_line(im,q+Vector2(-4,-5),q+Vector2(3,0),2.0,tint)
				fx_line(im,q+Vector2(3,0),q+Vector2(-4,5),2.0,tint)
				fx_line(im,q-Vector2(8,0),q-Vector2(1,0),1.2,tint)
			var a_center:=Vector2(9,14)
			var b_center:=Vector2(35,14)
			fx_disc(im,a_center,4.0,Color("#a0c8ee",.5+.5*pulse),2.6)
			fx_disc(im,b_center,4.0,Color("#fcd286",.5+.5*pulse),2.6)
			fx_line(im,b_center,a_center,1.0,Color("#e2dcff",.4+.5*pulse))
			var q:=b_center.lerp(a_center,drive)
			fairy_star(im,q,3.0,Color("#ffffff",.9))
		"eos_138":
			# Living Inscription: a luminous stylus draws a rune onto an unfolding page.
			var page:=Vector2(26,26)
			var w:float=5+9*drive
			for j in range(-8,9):
				fx_line(im,page+Vector2(-w,float(j)),page+Vector2(w,float(j)),.8,Color("#c6ad78",.65+.25*pulse))
				fx_line(im,page+Vector2(-w+1,float(j)),page+Vector2(w-1,float(j)),.8,Color("#fff1cd",.85))
			var points:Array[Vector2]=[Vector2(17,29),Vector2(22,21),Vector2(26,28),Vector2(31,20),Vector2(35,27)]
			var count:float=drive*4.0
			for j in range(4):
				var portion:float=clampf(count-float(j),0.0,1.0)
				if portion>0.0:
					fx_line(im,points[j],points[j].lerp(points[j+1],portion),1.6,Color("#795da2"))
			var index:int=mini(3,int(count))
			var tip:=points[index].lerp(points[index+1],clampf(count-float(index),0.0,1.0))
			fx_line(im,tip,tip+Vector2(5,-10),3.0,Color("#9e6d42"))
			fx_line(im,tip,tip+Vector2(5,-10),1.6,Color("#ffd18a"))
			fairy_star(im,tip,2.3,Color("#f3baff"))
		"eos_021":
			# Shared Vitality: paired health orbs equalize through a bidirectional link.
			var left:=Vector2(10,24)
			var right:=Vector2(38,24)
			var balance:float=smoothstep(peak,1.0,t)
			var l_radius:float=7.0-2.0*balance
			var r_radius:float=3.0+2.0*balance
			fx_disc(im,left,l_radius,Color("#ca627d"))
			fx_disc(im,left-Vector2(1,1),l_radius-1.5,Color("#ffd0d8"))
			fx_disc(im,right,r_radius,Color("#5b9c79"))
			fx_disc(im,right-Vector2(1,1),maxf(1.0,r_radius-1.5),Color("#b9f8ce"))
			for j in range(3):
				var f:float=fposmod(t+float(j)/3.0,1.0)
				var q:=left.lerp(right,f)
				q.y-=5*sin(f*PI)
				fx_disc(im,q,1.8,Color("#ffc2ce",.85))
				var v:=right.lerp(left,f)
				v.y+=5*sin(f*PI)
				fx_disc(im,v,1.8,Color("#a4f2ba",.85))
			fx_line(im,Vector2(15,24),Vector2(33,24),1.0,Color("#eae5b8",.4+.5*pulse))
		"eos_501":
			# Mud Bomb: oversized clay mass with coarse ridges and erupting ground splatter.
			var q:=Vector2(11+23*drive,28-12*sin(drive*PI))
			fx_line(im,q-Vector2(9*fade,1),q,3.6,Color("#65432e",.65*fade+.15))
			var radius:float=6.4+1.5*pulse
			fx_disc(im,q,radius,Color("#63412d"))
			fx_disc(im,q-Vector2(1,1),radius-1.5,Color("#a97646"))
			fx_line(im,q-Vector2(4,1),q+Vector2(1,-4),1.4,Color("#dfb37a"))
			for j in range(6):
				var a:float=float(j)*TAU/6.0+t*2.0
				var mote:=q+Vector2(cos(a),sin(a))*(radius-1.0)
				fx_disc(im,mote,1.7,Color("#805333"))
			if t>=peak:
				for j in range(9):
					var a:float=PI+float(j)*PI/8.0
					var axis:=Vector2(cos(a),sin(a))
					var mote:=q+Vector2(0,4)+axis*(8+9*(1.0-fade))
					fx_disc(im,mote,2.3,Color("#ae7848",fade))
					fx_line(im,q+Vector2(0,3),mote,1.1,Color("#805335",.65*fade))
				fx_line(im,q+Vector2(-11,7),q+Vector2(11,7),2.0,Color("#b98a59",fade))
		"eos_053":
			# Flamethrower: connected expanding flame jet with hot core and cinders.
			var head:=Vector2(9+28*drive,24)
			var tail:=Vector2(maxf(5.0,head.x-29.0*fade),24)
			for j in range(1,11):
				var f:float=float(j)/10.0
				var g:float=float(j-1)/10.0
				var a:=tail.lerp(head,g)+Vector2(0,sin(g*TAU-t*8.0)*2)
				var v:=tail.lerp(head,f)+Vector2(0,sin(f*TAU-t*8.0)*2)
				fx_line(im,a,v,2.0+5.0*f,Color("#a72d14",.8+.2*fade))
				fx_line(im,a,v,1.5+3.4*f,Color("#fa681c"))
				fx_line(im,a,v,.8+1.7*f,Color("#fff1a1"))
			for j in range(4):
				var q:=head+Vector2(-float(j)*3.0,sin(float(j)*2.4+t*TAU)*(4.0+2.0*pulse))
				fire_lobe(im,q,3.8+2.5*pulse,t+float(j)*.19,Color("#fff5b3"),Color("#ff7626"))
			for j in range(6):
				var q:=head+Vector2(-float(j)*4.0,(-1.0 if j%2==0 else 1.0)*(6+float(j%3)*3))
				fx_disc(im,q,1.2,Color("#ffc75d",.25+.65*fade))
		"eos_157":
			# Fire Blast: contracting ignition, five-pronged fire seal, explosive expansion.
			var q:=Vector2(13+13*drive,24)
			var radius:float=4.0+9.0*drive+3.0*(1.0-fade)
			fx_disc(im,q,5.5+2.5*pulse,Color("#a63016",.45+.55*fade))
			fx_disc(im,q,3.8+2.0*pulse,Color("#ff982c"))
			for j in range(5):
				var a:float=-PI/2.0+float(j)*TAU/5.0
				var axis:=Vector2(cos(a),sin(a))
				var tip:=q+axis*radius
				fx_line(im,q,tip,3.6,Color("#c4411b",.5+.5*fade))
				fx_line(im,q,tip,1.8,Color("#ffd267",.5+.5*fade))
				fire_lobe(im,tip,3.3+2.0*pulse,t+float(j)*.13,Color("#fff3a3"),Color("#ef4d1b"))
				if t>=peak:
					fx_disc(im,q+axis*(radius+4.0),1.5,Color("#ffd17a",fade))
			fx_disc(im,q,2.7,Color("#fff9d5"))
		"eos_064":
			# Thunder: overhead branching strike, white flash, ground electricity.
			var impact_point:=Vector2(24,36)
			var fall:float=clampf(t/maxf(peak,.01),0.0,1.0)
			var previous:=Vector2(22,3)
			for j in range(1,9):
				var f:float=float(j)/8.0
				if f<=fall+.13:
					var q:=Vector2(24+sin(float(j)*2.9+t*19.0)*5.2*(1.0-f),3+33*f)
					fx_line(im,previous,q,3.5,Color("#428bfa",.45+.55*fade))
					fx_line(im,previous,q,1.8,Color("#fcf99d",.5+.5*fade))
					fx_line(im,previous,q,.8,Color("#ffffff",.6+.4*fade))
					if j%2==0:
						fx_line(im,q,q+Vector2((-1.0 if j%4==0 else 1.0)*9,5),1.0,Color("#8ddcff",fade))
					previous=q
			if t>=peak:
				var radius:float=4+13*(1.0-fade)
				fx_disc(im,impact_point,4.8,Color("#fff9d0",fade))
				for j in range(6):
					var a:float=PI+float(j)*PI/5.0
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,impact_point+axis*3,impact_point+axis*radius,1.4,Color("#fff39a",fade))
					fx_disc(im,impact_point+axis*radius,1.2,Color("#a8e5ff",fade))
		"eos_188":
			# Thunder Shock: short traveling jagged spark, no overhead strike.
			var head:=Vector2(9+27*drive,24)
			var tail:=Vector2(maxf(4.0,head.x-21.0*fade),24)
			var previous:=tail
			for j in range(1,8):
				var f:float=float(j)/7.0
				var q:=tail.lerp(head,f)+Vector2(0,(-1.0 if j%2==0 else 1.0)*(2.0+2.4*pulse)*sin(f*PI))
				fx_line(im,previous,q,2.2,Color("#4b9bf1",.6+.4*fade))
				fx_line(im,previous,q,1.0,Color("#fffaad"))
				if j%3==0:fx_line(im,q,q+Vector2(-3,(-1.0 if j%2==0 else 1.0)*5),.9,Color("#c5edff",fade))
				previous=q
			fx_disc(im,head,3.2,Color("#7bcfff",.6+.4*fade))
			fx_disc(im,head,1.8,Color("#fffbd1"))
			if t>=peak:
				for j in range(4):
					var a:float=float(j)*TAU/4.0+t
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,head+axis*3,head+axis*(6+5*(1.0-fade)),1.0,Color("#fff2a1",fade))
		"eos_240":
			# Hydro Pump: broad pressurized connected torrent, white foam and spray.
			var head:=Vector2(10+26*drive,24)
			var tail:=Vector2(maxf(4.0,head.x-29.0*fade),24)
			for j in range(1,13):
				var f:float=float(j)/12.0
				var g:float=float(j-1)/12.0
				var a:=tail.lerp(head,g)+Vector2(0,sin(g*TAU-t*9.0)*2.2)
				var v:=tail.lerp(head,f)+Vector2(0,sin(f*TAU-t*9.0)*2.2)
				fx_line(im,a,v,3.8+6.0*f,Color("#176396"))
				fx_line(im,a,v,2.6+4.0*f,Color("#38bce9"))
				fx_line(im,a-Vector2(0,1),v-Vector2(0,1),1.1+1.5*f,Color("#d9faff"))
			for j in range(5):
				var q:=head+Vector2(-float(j)*2.5,sin(float(j)*2.2+t*TAU)*5.5)
				water_drop(im,q,3.0+2*pulse,Color("#c9f7ff"),Color("#2998d1"))
			for j in range(8):
				var a:float=-PI*.65+float(j)*PI*1.3/7.0
				var axis:=Vector2(cos(a),sin(a))
				var q:=head+axis*(4+6*pulse+3*(1.0-fade))
				fx_disc(im,q,1.3+float(j%2)*.5,Color("#bcefff",.3+.7*fade))
		"eos_255":
			# Bubblebeam: staggered transparent spheres, refraction and popping rims.
			for j in range(5):
				var f:float=clampf(drive*1.27-float(j)*.13,0.0,1.0)
				var q:=Vector2(7+29*f,24+sin(float(j)*2.4+t*TAU)*5.5)
				var radius:float=2.8+float(j%3)*1.1+1.1*pulse
				fx_disc(im,q,radius,Color("#2a92d6",.4+.3*fade),radius-1.3)
				fx_disc(im,q,radius-1.3,Color("#74d7fa",.19+.12*fade))
				fx_disc(im,q-Vector2(radius*.4,radius*.4),1.2,Color("#f2ffff"))
				fx_disc(im,q+Vector2(radius*.4,radius*.35),.9,Color("#a9f3ff"))
				if t>=peak:
					for k in range(3):
						var a:float=float(k)*TAU/3.0+t
						fx_disc(im,q+Vector2(cos(a),sin(a))*(radius+5*(1.0-fade)),1.0,Color("#ddfbff",fade))
		"eos_342":
			# Dragonbreath: layered violet and teal flame stream with draconic wisps.
			var head:=Vector2(11+24*drive,24)
			var tail:=Vector2(maxf(5.0,head.x-25.0*fade),24)
			for j in range(1,12):
				var f:float=float(j)/11.0
				var g:float=float(j-1)/11.0
				var a:=tail.lerp(head,g)+Vector2(0,sin(g*TAU-t*6.0)*3.0)
				var v:=tail.lerp(head,f)+Vector2(0,sin(f*TAU-t*6.0)*3.0)
				fx_line(im,a,v,2.4+4.0*f,Color("#49357e"))
				fx_line(im,a,v,1.5+3.0*f,Color("#9f6edf"))
				fx_line(im,a,v,.8+1.2*f,Color("#b5fff0"))
			for j in range(4):
				var q:=head+Vector2(-float(j)*3.0,sin(t*TAU+float(j)*2.0)*5.0)
				fire_lobe(im,q,3.4+1.8*pulse,t+float(j)*.15,Color("#bbfff0"),Color("#9156d6"))
				fx_disc(im,q+Vector2(-4,-5),1.1,Color("#a0e5d5",.4+.6*fade))
		"eos_539":
			# Dragon Pulse: traveling energy wavefronts with bright compressed centers.
			for j in range(3):
				var f:float=clampf(drive*1.25-float(j)*.20,0.0,1.0)
				var q:=Vector2(9+25*f,24)
				var radius:float=4.0+7.0*f
				for k in range(1,15):
					var a:float=float(k-1)*TAU/14.0
					var v:float=float(k)*TAU/14.0
					var u:=q+Vector2(cos(a)*radius*.42,sin(a)*radius)
					var w:=q+Vector2(cos(v)*radius*.42,sin(v)*radius)
					fx_line(im,u,w,2.2,Color("#6542b1",.6+.4*fade))
					fx_line(im,u,w,.9,Color("#b9f8ff",.6+.4*fade))
				fx_disc(im,q,2.0+1.2*pulse,Color("#d2c6ff",.6+.4*fade))
			if t>=peak:
				var q:=Vector2(34,24)
				for j in range(6):
					var a:float=float(j)*TAU/6.0
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,q+axis*4,q+axis*(8+6*(1.0-fade)),1.2,Color("#9ae5ee",fade))
		"eos_041":
			# Overheat: white-hot central sphere and turbulent solar corona.
			var c:=Vector2(24,24)
			var radius:float=3.0+13.0*drive+3.0*(1.0-fade)
			fx_disc(im,c,radius,Color("#a52c18",.7*fade+.15))
			fx_disc(im,c,radius*.74,Color("#ff7226",.85*fade+.12))
			fx_disc(im,c,radius*.48,Color("#ffdc72",.85*fade+.12))
			fx_disc(im,c,radius*.24,Color("#fffce0",.9*fade+.1))
			for j in range(8):
				var a:float=float(j)*TAU/8.0+t*2.2
				var axis:=Vector2(cos(a),sin(a))
				var q:=c+axis*radius*.86
				fire_lobe(im,q,2.5+2.8*pulse,t+float(j)*.1,Color("#fff5ae",fade),Color("#ef501c",fade))
				if t>=peak:
					fx_line(im,c+axis*radius,c+axis*(radius+4),1.2,Color("#ffd281",fade))
		"eos_278":
			# Eruption: split ground vents, rising magma pillars and falling rock fragments.
			for j in range(3):
				var x:float=11.0+float(j)*13.0
				var local:float=clampf(drive*1.3-float(j)*.1,0.0,1.0)
				var h:float=4.0+25.0*local*fade
				var foot:=Vector2(x,39)
				fx_line(im,foot+Vector2(-5,1),foot+Vector2(5,1),2.1,Color("#873820",fade))
				fx_line(im,foot,foot-Vector2(0,h),5.5,Color("#a52d17",fade))
				fx_line(im,foot,foot-Vector2(0,h),3.4,Color("#ff7928",fade))
				fx_line(im,foot,foot-Vector2(0,h),1.4,Color("#fff1a5",fade))
				fire_lobe(im,foot-Vector2(0,h),3.0+2*pulse,t+float(j)*.18,Color("#fff0a3",fade),Color("#ed481b",fade))
				for k in range(2):
					var f:float=fposmod(t+float(k)*.35+float(j)*.12,1.0)
					var q:=foot+Vector2((-1.0 if k==0 else 1.0)*6*f,-22*sin(f*PI))
					earth_rock(im,q,2.2,Color("#f39a4b",fade),Color("#5f3526",fade))
		"eos_538":
			# Draco Meteor: staggered diagonal descent, glowing meteor cores and impact craters.
			for j in range(5):
				var f:float=clampf(t*1.45-float(j)*.12,0.0,1.0)
				var landing:=Vector2(9+float(j%3)*14,35-float(j/3)*8)
				var q:=landing+Vector2(-10,-31)*(1.0-f)
				var a:float=1.0-smoothstep(.78,1.0,f)
				fx_line(im,q-Vector2(5,12)*a,q,4.6,Color("#6947bf",a))
				fx_line(im,q-Vector2(4,8)*a,q,2.6,Color("#e58df3",a))
				fx_disc(im,q,4.7,Color("#7144b1",a))
				fx_disc(im,q,3.2,Color("#f6a552",a))
				fx_disc(im,q-Vector2(1,1),1.8,Color("#fff4c7",a))
				if f>=.78:
					var burst:float=clampf((f-.78)/.22,0.0,1.0)
					var radius:float=3+7*burst
					fx_disc(im,landing,radius,Color("#f3b3f4",1.0-burst),maxf(0.0,radius-1.4))
					for k in range(4):
						var angle:float=PI+float(k)*PI/3.0
						var axis:=Vector2(cos(angle),sin(angle))
						fx_line(im,landing+axis*3,landing+axis*(radius+4),1.2,Color("#ffe9af",1.0-burst))
		"eos_239":
			# Hydro Cannon: compression chamber followed by a dense high-pressure beam.
			var c:=Vector2(8,24)
			var head:=Vector2(10+29*drive,24)
			var width:float=3.0+5.0*pulse
			fx_disc(im,c,4.0+3.0*pulse,Color("#1a73b2",fade))
			fx_disc(im,c,2.5+2.0*pulse,Color("#d2fbff",fade))
			if drive>.1:
				var tail:=Vector2(maxf(5.0,head.x-34.0*fade),24)
				fx_line(im,tail,head,width+3,Color("#175d99",fade))
				fx_line(im,tail,head,width,Color("#42c8f8",fade))
				fx_line(im,tail,head,width*.48,Color("#f0ffff",fade))
				for j in range(5):
					var q:=tail.lerp(head,float(j)/4.0)
					fx_line(im,q+Vector2(-2,-width),q+Vector2(2,width),1.2,Color("#90eaff",fade))
				for j in range(7):
					var a:float=-PI*.7+float(j)*PI*1.4/6.0
					var axis:=Vector2(cos(a),sin(a))
					var q:=head+axis*(5+8*(1.0-fade))
					water_drop(im,q,1.8+1.2*pulse,Color("#d8fbff",fade),Color("#328cd1",fade))
		"eos_193":
			# Zap Cannon: charged electric sphere and independently flickering branches.
			var q:=Vector2(9+26*drive,24)
			var radius:float=4.5+4.0*pulse
			fx_disc(im,q,radius,Color("#286ccc",fade))
			fx_disc(im,q,radius*.72,Color("#52c6f2",fade))
			fx_disc(im,q,radius*.43,Color("#fff899",fade))
			fx_disc(im,q,radius*.22,Color("#ffffff",fade))
			for j in range(7):
				var a:float=float(j)*TAU/7.0+t*3
				var axis:=Vector2(cos(a),sin(a))
				var u:=q+axis*radius
				var v:=u+axis*3+Vector2(-axis.y,axis.x)*sin(t*20+float(j))*3
				var w:=q+axis*(radius+5+5*(1.0-fade))
				fx_line(im,u,v,2.0,Color("#91eaff",fade))
				fx_line(im,v,w,1.1,Color("#fff3a1",fade))
			if t>=peak:
				var ring:float=radius+4+6*(1.0-fade)
				fx_disc(im,q,ring,Color("#d9fbff",fade),ring-1.2)
		"eos_272":
			# Blast Burn: expanding concentric flame front rather than a static fire cluster.
			var c:=Vector2(24,24)
			var radius:float=4.0+15.0*drive+2.0*(1.0-fade)
			fx_disc(im,c,radius,Color("#b13c17",.7*fade),maxf(0.0,radius-4))
			fx_disc(im,c,radius-1.0,Color("#ffbd43",fade),maxf(0.0,radius-2.6))
			for j in range(10):
				var a:float=float(j)*TAU/10.0+t*.8
				var axis:=Vector2(cos(a),sin(a))
				var q:=c+axis*(radius-2.0)
				fire_lobe(im,q,2.7+2.1*pulse,t+float(j)*.12,Color("#fff0a0",fade),Color("#f2541d",fade))
				fx_line(im,c+axis*radius*.45,q,1.2,Color("#ffb347",fade*pulse))
			if t>=peak:
				fx_disc(im,c,5.0,Color("#fff3c3",fade))
		"eos_519":
			# Lava Plume: broad low molten pool with staggered bubbling arcs.
			var c:=Vector2(24,35)
			var span:float=5.0+15.0*drive
			for j in range(-3,4):
				var y:float=float(j)
				var w:float=span*(1.0-absf(y)/6.0)
				fx_line(im,c+Vector2(-w,y),c+Vector2(w,y),1.4,Color("#ad391e",fade))
				fx_line(im,c+Vector2(-w*.85,y),c+Vector2(w*.85,y),.9,Color("#ff882c",fade))
			for j in range(6):
				var f:float=fposmod(t+float(j)*.16,1.0)
				var q:=c+Vector2((float(j)-2.5)*span*.35+sin(f*TAU)*3,-(8+float(j%3)*5)*sin(f*PI))
				fx_line(im,Vector2(q.x,35),q,2.1,Color("#ef5d20",fade*.8))
				fx_disc(im,q,2.5+float(j%2),Color("#ffbf4a",fade))
				fx_disc(im,q-Vector2(1,1),1.2,Color("#fff4bb",fade))
		"eos_494":
			# Roar of Time: rotating clock seal, time fracture and room-scale shock ring.
			var c:=Vector2(24,24)
			var radius:float=9.0+5.0*drive
			fx_disc(im,c,radius,Color("#6551b9",fade),radius-2.2)
			fx_disc(im,c,radius-1.0,Color("#a8ddff",fade),radius-1.9)
			for j in range(12):
				var a:float=float(j)*TAU/12.0-PI/2
				var axis:=Vector2(cos(a),sin(a))
				fx_line(im,c+axis*(radius-4),c+axis*(radius-1),1.2,Color("#c5eaff",fade))
			var a:float=t*TAU*2.0-PI/2
			var axis:=Vector2(cos(a),sin(a))
			var slow_axis:=Vector2(cos(a*.3),sin(a*.3))
			fx_line(im,c,c+axis*(radius-3),1.6,Color("#fff2b9",fade))
			fx_line(im,c,c+slow_axis*(radius*.55),2.0,Color("#d6c0ff",fade))
			fx_disc(im,c,2.3,Color("#efffff",fade))
			if t>=peak:
				var ring:float=radius+6*(1.0-fade)
				fx_disc(im,c,ring,Color("#b9f2ff",fade),ring-1.0)
				for j in range(6):
					var angle:float=float(j)*TAU/6.0+t
					var v:=Vector2(cos(angle),sin(angle))
					var q:=c+v*(radius*.8)
					fx_line(im,q,q+v*(5+4*(1.0-fade)),1.3,Color("#d8c7ff",fade))
		"eos_292":
			# Fire Punch: readable four-knuckle fist surrounded by a trailing flame.
			var q:=Vector2(11+22*drive,24)
			for j in range(4):
				var v:=q+Vector2(-4-float(j)*3.5,sin(t*TAU+float(j)*2.0)*4.0)
				fire_lobe(im,v,3.2+1.6*pulse,t+float(j)*.2,Color("#ffe7a1",fade),Color("#e8471b",fade))
			fight_fist(im,q,0.0,6.6,Color("#ffdc96"),Color("#9b3a23"))
			if t>=peak:
				for j in range(7):
					var a:float=float(j)*TAU/7.0
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,q+axis*7,q+axis*(10+7*(1.0-fade)),1.5,Color("#ffcb65",fade))
		"eos_065":
			# Thunderpunch: a charged fist, distinct branching arcs and knuckle flash.
			var q:=Vector2(11+22*drive,24)
			for j in range(5):
				var a:float=float(j)*TAU/5.0+t*2.1
				var axis:=Vector2(cos(a),sin(a))
				var u:=q+axis*6.0
				var v:=q+axis*10.0+Vector2(-axis.y,axis.x)*sin(t*19+float(j))*3
				var w:=q+axis*(12+4*pulse)
				fx_line(im,u,v,2.0,Color("#478fe8",fade))
				fx_line(im,v,w,1.2,Color("#fff4a1",fade))
			fx_line(im,q-Vector2(12*fade,0),q,2.2,Color("#86d9ff",fade))
			fight_fist(im,q,0.0,6.2,Color("#fff1a4"),Color("#927834"))
			if t>=peak:
				var radius:float=7+9*(1.0-fade)
				fx_disc(im,q,radius,Color("#c4f6ff",fade),radius-1.2)
		"eos_276":
			# Blaze Kick: bent leg unfolds into a recognizable extended foot.
			var hip:=Vector2(13+8*drive,28)
			var knee:=hip+Vector2(4+5*drive,-8+6*drive)
			var heel:=knee+Vector2(3+6*drive,7-8*drive)
			var toe:=heel+Vector2(5,-3)
			fx_line(im,hip,knee,6.2,Color("#813b28"))
			fx_line(im,knee,heel,5.4,Color("#813b28"))
			fx_line(im,heel,toe,5.4,Color("#813b28"))
			fx_line(im,hip,knee,4.1,Color("#ffba74"))
			fx_line(im,knee,heel,3.6,Color("#ffe0a1"))
			fx_line(im,heel,toe,3.4,Color("#fff2bf"))
			for j in range(3):
				var q:=heel-Vector2(float(j)*4,3*sin(t*TAU+float(j)))
				fire_lobe(im,q,3.0+1.7*pulse,t+float(j)*.2,Color("#fff3a0",fade),Color("#e94a21",fade))
			fight_arc(im,hip,17.0,-1.7,1.7*drive+.2,Color("#ffe4a1",fade),Color("#f05b20",fade),2.6)
		"eos_208":
			# Dragon Claw: three long hooked claw slashes with violet energy and teal edges.
			for j in range(3):
				var c:=Vector2(16+10*drive+float(j)*3,15+float(j)*7)
				var prev:=c-Vector2(9,-6)
				for k in range(1,9):
					var f:float=float(k)/8.0
					var q:=c+Vector2(-9+22*f,6-13*sin(f*PI*.65))
					fx_line(im,prev,q,3.6*(1.0-f)+1.0,Color("#60419d",fade))
					fx_line(im,prev,q,2.0*(1.0-f)+.6,Color("#b8ffe9",fade))
					prev=q
				if t>=peak:
					fx_disc(im,prev+Vector2(3,2),1.6,Color("#dbc3ff",fade))
		"eos_522","eos_452":
			# Elemental fangs: opposing jaws physically close; elemental accents differ.
			var fire:bool=id=="eos_522"
			var c:=Vector2(16+15*drive,24)
			var opening:float=10.0-7.5*drive+4.5*(1.0-fade)
			var outer:=Color("#b73b20") if fire else Color("#336fc6")
			var tooth:=Color("#fff1c2") if fire else Color("#fff9bd")
			for side in [-1,1]:
				var sy:float=float(side)
				var left:=c+Vector2(-10,sy*(opening-2))
				var mid:=c+Vector2(0,sy*(opening+2))
				var right:=c+Vector2(10,sy*(opening-2))
				fx_line(im,left,mid,4.3,outer)
				fx_line(im,mid,right,4.3,outer)
				for j in range(4):
					var x:float=-7+float(j)*4.6
					var base:=c+Vector2(x,sy*(opening+1-absf(x)*.24))
					var tip:=base-Vector2(0,sy*(5.0 if j==0 or j==3 else 3.6))
					fx_line(im,base,tip,2.4,outer)
					fx_line(im,base,tip,1.5,tooth)
				for j in range(3):
					var q:=c+Vector2(-8+float(j)*8,sy*(opening+5))
					if fire:
						fire_lobe(im,q,2.3+1.1*pulse,t+float(j)*.15,Color("#ffec9d",fade),Color("#f34c20",fade))
					else:
						fx_line(im,q,q+Vector2(3,sy*4),1.4,Color("#9eeaff",fade))
						fx_line(im,q+Vector2(3,sy*4),q+Vector2(6,sy*2),1.1,Color("#fff9a1",fade))
			if t>=peak:
				var radius:float=5+10*(1.0-fade)
				fx_disc(im,c,radius,Color("#ffba65",fade) if fire else Color("#b9f5ff",fade),radius-1.2)
		"eos_433":
			# Aqua Tail: curved tapering tail with a broad water fin and splash.
			var c:=Vector2(17,25)
			var sweep:float=-2.0+2.7*drive
			var prev:=c
			for j in range(1,12):
				var f:float=float(j)/11.0
				var a:float=sweep+f*1.25
				var q:=c+Vector2(cos(a),sin(a))*(20*f)
				fx_line(im,prev,q,5.8*(1.0-f)+1.7,Color("#216fa7"))
				fx_line(im,prev,q,3.4*(1.0-f)+1.2,Color("#73e3f8"))
				prev=q
			var axis:=Vector2(cos(sweep+1.25),sin(sweep+1.25))
			var normal:=Vector2(-axis.y,axis.x)
			fx_line(im,prev,prev-axis*5+normal*5,3.7,Color("#a7edff"))
			fx_line(im,prev,prev-axis*5-normal*5,3.7,Color("#a7edff"))
			fight_arc(im,c,20.0,sweep-.5,1.4,Color("#c9f8ff",fade),Color("#238dbd",fade),2.2)
			for j in range(6):
				var a:float=sweep+float(j)*.32
				var q:=c+Vector2(cos(a),sin(a))*(19+5*pulse)
				fx_disc(im,q,1.5,Color("#d4faff",fade))
		"eos_087":
			# Crabhammer: heavy crab pincer swings downward into a water splash.
			var q:=Vector2(12+19*drive,12+17*drive)
			var arm:=q-Vector2(8,8)
			fx_line(im,arm,q,6.0,Color("#91482e"))
			fx_line(im,arm,q,4.0,Color("#e88a56"))
			fx_disc(im,q,7.2,Color("#953d2d"))
			fx_disc(im,q-Vector2(1,1),5.7,Color("#f6a471"))
			var opening:float=5.8-3.0*drive
			for side in [-1,1]:
				var sy:float=float(side)
				var base:=q+Vector2(3,sy*3)
				var bend:=q+Vector2(9,sy*opening)
				var tip:=q+Vector2(12,sy*2)
				fx_line(im,base,bend,4.3,Color("#963e2b"))
				fx_line(im,bend,tip,3.6,Color("#963e2b"))
				fx_line(im,base,bend,2.8,Color("#ffd0a2"))
				fx_line(im,bend,tip,2.1,Color("#fca775"))
			if t>=peak:
				for j in range(7):
					var a:float=PI+float(j)*PI/6.0
					var axis:=Vector2(cos(a),sin(a))
					var v:=q+Vector2(1,8)+axis*(6+10*(1.0-fade))
					water_drop(im,v,2.0,Color("#d8faff",fade),Color("#298bcd",fade))
		"eos_063","eos_062":
			# Bite snaps once; Crunch has a broader, heavier jaw and sustained compression.
			var heavy:bool=id=="eos_062"
			var c:=Vector2(24+3*drive,24)
			var jaw_width:float=16.0 if heavy else 11.0
			var count:int=7 if heavy else 5
			var gap:float=lerpf(11.0 if heavy else 8.0,2.0,drive)
			gap+= (2.0 if heavy else 6.0)*(1.0-fade)
			var ink:=Color("#35203e")
			var rim:=Color("#a85b76") if heavy else Color("#8c708a")
			var ivory:=Color("#ffe0b0") if heavy else Color("#fff0d3")
			for side in [-1,1]:
				var sy:float=float(side)
				var prev:=c+Vector2(-jaw_width,sy*(gap+4))
				for j in range(count):
					var x:float=lerpf(-jaw_width,jaw_width,float(j)/float(count-1))
					var q:=c+Vector2(x,sy*(gap+4*absf(x/jaw_width)))
					fx_line(im,prev,q,5.2 if heavy else 3.6,ink)
					fx_line(im,prev,q,2.7 if heavy else 1.7,rim)
					var length:float=(7.0 if heavy else 5.0) if j in [0,count-1] else (4.8 if heavy else 3.3)
					var tip:=q+Vector2(-x*.12,-sy*length)
					fx_line(im,q,tip,3.0 if heavy else 2.2,ink)
					fx_line(im,q,tip,1.7 if heavy else 1.2,ivory)
					prev=q
			if t>=peak:
				for j in range(8 if heavy else 4):
					var a:float=float(j)*TAU/float(8 if heavy else 4)
					var axis:=Vector2(cos(a),sin(a))
					var radius:float=(9.0 if heavy else 5.0)+(8.0 if heavy else 5.0)*(1.0-fade)
					fx_line(im,c+axis*radius*.5,c+axis*radius,1.8 if heavy else 1.1,Color("#ff827b" if heavy else "#e8c7ac",fade))
					if heavy:fx_disc(im,c+axis*(radius+3),1.5,Color("#9351a7",fade))
		"eos_476":
			# Shadow Claw: tapered spectral talons with detached ghostly wisps.
			for j in range(3):
				var c:=Vector2(14+9*drive+float(j)*5,13+float(j)*8)
				var prev:=c+Vector2(-7,8)
				for k in range(1,11):
					var f:float=float(k)/10.0
					var q:=c+Vector2(-7+20*f,8-19*sin(f*PI*.72))
					fx_line(im,prev,q,4.3*(1.0-f)+1.1,Color("#302042",fade))
					fx_line(im,prev,q,2.5*(1.0-f)+.7,Color("#b999f2",fade))
					prev=q
				for k in range(3):
					var q:=c+Vector2(-4+float(k)*4,9+sin(t*TAU+float(k))*3)
					fire_lobe(im,q,1.6+1.0*pulse,t+float(k)*.2,Color("#b7eee2",fade),Color("#7250aa",fade))
		"eos_127":
			# Shadow Ball: opaque dark core with orbiting wisps and a fracture at impact.
			var c:=Vector2(10+24*drive,24)
			var radius:float=5.0+4.0*pulse
			fx_line(im,c-Vector2(13*fade,0),c,4.5,Color("#342143",.7*fade))
			fx_disc(im,c,radius,Color("#503171",fade))
			fx_disc(im,c,radius-1.8,Color("#21162e",fade))
			fx_disc(im,c-Vector2(2,2),radius*.42,Color("#8a62c3",fade))
			for j in range(4):
				var a:float=float(j)*TAU/4.0+t*TAU
				var q:=c+Vector2(cos(a),sin(a))*(radius+3.0)
				fire_lobe(im,q,2.1,t+float(j)*.21,Color("#b7f1dc",fade),Color("#8b61bf",fade))
			if t>=peak:
				for j in range(6):
					var a:float=float(j)*TAU/6.0+t
					var axis:=Vector2(cos(a),sin(a))
					var q:=c+axis*(radius+8*(1.0-fade))
					fx_line(im,q,q+axis*3,1.4,Color("#d2b4ff",fade))
		"eos_451":
			# Shadow Sneak: flat shadow crawls along the ground then rises into a spectral strike.
			var c:=Vector2(7+27*drive,35)
			for j in range(6):
				var q:=c-Vector2(float(j)*4.2,0)
				fx_line(im,q-Vector2(3,0),q+Vector2(3,0),3.4-float(j)*.35,Color("#211a31",(.9-float(j)*.11)*fade))
			var rise:float=sin(t*PI)*17.0
			var tip:=c-Vector2(0,rise)
			fx_line(im,c,tip,5.3,Color("#332344",fade))
			fx_line(im,c,tip,2.4,Color("#805eaa",fade))
			fx_line(im,tip,tip+Vector2(5,-5),3.4,Color("#aa8fdb",fade))
			fx_disc(im,tip+Vector2(-1,1),1.2,Color("#c5f8e6",fade))
			if t>=peak:
				fx_disc(im,c,6+6*(1.0-fade),Color("#9872c8",fade),5+6*(1.0-fade))
		"eos_436":
			# Dark Pulse: jagged concentric shock fronts and a deep violet center.
			var c:=Vector2(24,24)
			for j in range(3):
				var radius:float=3.0+float(j)*5.0+8.0*drive
				var prev:=c+Vector2(radius,0)
				for k in range(1,25):
					var a:float=float(k)*TAU/24.0
					var r:float=radius+sin(a*8+t*TAU)*1.4
					var q:=c+Vector2(cos(a),sin(a))*r
					fx_line(im,prev,q,2.9,Color("#382040",fade))
					fx_line(im,prev,q,1.1,Color("#c583c7",fade))
					prev=q
			fx_disc(im,c,4.2+2*pulse,Color("#24132f",fade))
			for j in range(7):
				var a:float=float(j)*TAU/7.0+t*2.0
				var axis:=Vector2(cos(a),sin(a))
				fx_disc(im,c+axis*(8+10*drive),1.5,Color("#ef9fae",fade))
		"eos_491":
			# Night Slash: one long fast black crescent, with a crimson cutting edge.
			var c:=Vector2(24,24)
			var sweep:float=-2.0+2.3*drive
			fight_arc(im,c,16.5,sweep-1.6,1.75,Color("#e9a1c9",fade),Color("#2a172f",fade),6.1)
			fight_arc(im,c,18.5,sweep-1.15,1.2,Color("#ffc3bd",fade),Color("#86445b",fade),1.5)
			if t>=peak:
				for j in range(5):
					var a:float=sweep+float(j-2)*.32
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,c+axis*15,c+axis*(19+3*(1.0-fade)),1.3,Color("#e58fb0",fade))
		"eos_046":
			# Astonish: sudden spectral face with startled burst and recoil motes.
			var c:=Vector2(24,26-6*pulse)
			var radius:float=5.0+7.0*drive
			fx_disc(im,c,radius,Color("#332449",fade))
			fx_disc(im,c-Vector2(0,2),radius*.8,Color("#7655a7",fade))
			for side in [-1,1]:
				var x:float=float(side)*radius*.40
				var q:=c+Vector2(x,-radius*.25)
				fx_disc(im,q,2.5,Color("#d4ffed",fade))
				fx_disc(im,q+Vector2(0,1),1.1,Color("#251a36",fade))
			fx_disc(im,c+Vector2(0,radius*.35),2.4,Color("#281a3b",fade))
			if t>=peak:
				for j in range(8):
					var a:float=float(j)*TAU/8.0
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,c+axis*(radius+2),c+axis*(radius+6+4*(1.0-fade)),1.7,Color("#d4befd",fade))
		"eos_109":
			# Psychic: enclosing telekinetic field compresses around a luminous core.
			var c:=Vector2(24,24)
			var radius:float=18.0-10.0*drive+7.0*(1.0-fade)
			for j in range(3):
				var a:float=t*TAU+float(j)*TAU/3.0
				fight_arc(im,c,radius+float(j)*2,a,PI*1.45,Color("#f6baff",fade),Color("#7149b1",fade),2.6)
				var q:=c+Vector2(cos(a),sin(a))*radius
				fairy_star(im,q,2.2+1.5*pulse,Color("#baf6ff",fade))
			fx_disc(im,c,3.0+5.0*drive,Color("#6a42b0",fade))
			fx_disc(im,c,2.0+3.0*drive,Color("#fce0ff",fade))
			if t>=peak:
				for j in range(6):
					var a:float=float(j)*TAU/6.0
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,c+axis*radius,c+axis*(radius+5),1.4,Color("#e4b6ff",fade))
		"eos_234":
			# Confusion: eccentric spirals wobble in opposite directions.
			var c:=Vector2(24,24)
			for j in range(2):
				var prev:=c+Vector2(float(j*2-1)*2,0)
				for k in range(1,25):
					var f:float=float(k)/24.0
					var a:float=f*TAU*1.8*(1.0 if j==0 else -1.0)+t*TAU+float(j)*PI
					var radius:float=2.0+16.0*f*drive
					var q:=c+Vector2(cos(a)*radius,sin(a)*radius*.82)
					fx_line(im,prev,q,2.6,Color("#6e418f",fade))
					fx_line(im,prev,q,1.1,Color("#ffd58d" if j==0 else "#f0a1ff",fade))
					prev=q
				fairy_star(im,prev,2.5,Color("#fff1bd",fade))
		"eos_107":
			# Psybeam: connected prismatic beam with a white core and traveling wave bands.
			var head:=Vector2(8+31*drive,24)
			var tail:=Vector2(maxf(4.0,head.x-30.0*fade),24)
			fx_line(im,tail,head,5.0,Color("#7f46c2",fade))
			fx_line(im,tail,head,2.5,Color("#fff5ff",fade))
			var colors:Array[Color]=[Color("#ff9cc8"),Color("#8feaff"),Color("#ffe59d")]
			for j in range(3):
				var prev:=tail
				for k in range(1,15):
					var f:float=float(k)/14.0
					var q:=tail.lerp(head,f)+Vector2(0,sin(f*TAU*1.7-t*TAU+float(j)*TAU/3.0)*(3+3*pulse))
					fx_line(im,prev,q,1.8,Color(colors[j],fade))
					prev=q
			fairy_star(im,head,3.0+2.0*pulse,Color("#fff8ff",fade))
		"eos_463":
			# Psycho Cut: curved psychic blade with a thin brilliant cutting edge.
			var c:=Vector2(13+17*drive,24)
			var sweep:float=-2.0+1.25*drive
			fight_arc(im,c,14.5,sweep,PI*1.15,Color("#ffb1fa",fade),Color("#6740a8",fade),6.0)
			fight_arc(im,c,16.5,sweep+.2,PI*.96,Color("#fff4ff",fade),Color("#b37feb",fade),1.7)
			for j in range(5):
				var a:float=sweep+float(j)*.7
				var q:=c+Vector2(cos(a),sin(a))*(17+4*(1.0-fade))
				fx_disc(im,q,1.2,Color("#f1baff",fade))
		"eos_133":
			# Extrasensory: shifting concentric triangular sensory prisms converge.
			var c:=Vector2(24,24)
			for j in range(3):
				var radius:float=17.0-float(j)*5.0+3.0*pulse
				var a:float=t*TAU*(1.0 if j%2==0 else -1.0)+float(j)*.6
				psi_polygon(im,c,radius,3,a,Color("#b6f5ff",fade),Color("#7958c0",fade))
				var q:=c+Vector2(cos(a),sin(a))*radius
				fairy_star(im,q,2.2,Color("#ffe9c0",fade))
			fx_disc(im,c,3.5+2*pulse,Color("#e8d7ff",fade))
		"eos_317":
			# Foresight Pulse: prophetic eye opens inside a segmented celestial dial.
			var c:=Vector2(24,24)
			var radius:float=13.0+4.0*pulse
			for j in range(8):
				var a:float=float(j)*TAU/8.0+t*.5
				fight_arc(im,c,radius,a,.47,Color("#c6a7fa",fade),Color("#60449c",fade),1.9)
			var aperture:float=2.0+5.5*drive
			for j in range(2):
				var sy:float=-1.0 if j==0 else 1.0
				var prev:=c-Vector2(10,0)
				for k in range(1,15):
					var f:float=float(k)/14.0
					var q:=c+Vector2(-10+20*f,sy*sin(f*PI)*aperture)
					fx_line(im,prev,q,1.8,Color("#e8d7ff",fade))
					prev=q
			fx_disc(im,c,3.4,Color("#8edaf7",fade))
			fx_disc(im,c,1.4,Color("#392657",fade))
			for j in range(4):
				var a:float=float(j)*TAU/4.0+t
				fairy_star(im,c+Vector2(cos(a),sin(a))*(radius+4),2.0,Color("#fff0b3",fade))
		"eos_111":
			# Dream Gaze: slow hypnotic eye with an expanding continuous spiral.
			var c:=Vector2(24,24)
			var prev:=c
			for j in range(1,45):
				var f:float=float(j)/44.0
				var a:float=f*TAU*2.7-t*TAU
				var radius:float=1.0+18.0*f*drive
				var q:=c+Vector2(cos(a),sin(a))*radius
				fx_line(im,prev,q,2.7,Color("#7650a4",fade))
				fx_line(im,prev,q,1.1,Color("#f5b9e8",fade))
				prev=q
			if t>=peak:
				for j in range(3):
					var z:=Vector2(11+float(j)*10,16-8*(1.0-fade)-float(j)*3)
					fx_line(im,z,z+Vector2(4,0),1.0,Color("#c4ecff",fade))
					fx_line(im,z+Vector2(4,0),z+Vector2(0,4),1.0,Color("#c4ecff",fade))
					fx_line(im,z+Vector2(0,4),z+Vector2(4,4),1.0,Color("#c4ecff",fade))
		"eos_331":
			# Dream Eater: dream wisps flow from victim to caster and form a lunar aura.
			var travel:float=smoothstep(peak,1.0,t)
			for j in range(5):
				var f:float=clampf(drive*.30+travel*.70+float(j)*.13,0.0,1.0)
				var q:=Vector2(39-29*f,24+sin(f*TAU+float(j)*1.7)*7.0)
				fx_line(im,q,q+Vector2(5,-2),2.1,Color("#7952a8",fade))
				fire_lobe(im,q,2.6+1.1*pulse,t+float(j)*.15,Color("#e8cfff",fade),Color("#a386db",fade))
				fairy_star(im,q+Vector2(2,-4),1.7,Color("#aef2f8",fade))
			var c:=Vector2(10,24)
			fight_arc(im,c,5.0+6.0*travel,-PI*.7,PI*1.4,Color("#e7d0ff",fade),Color("#7a59b9",fade),3.0)
		"eos_345":
			# Ice Beam: straight concentrated freezing ray with moving crystalline facets.
			var head:=Vector2(9+29*drive,24)
			var tail:=Vector2(maxf(4.0,head.x-30.0*fade),24)
			fx_line(im,tail,head,6.0,Color("#335baf",fade))
			fx_line(im,tail,head,4.0,Color("#68c9f1",fade))
			fx_line(im,tail,head,1.8,Color("#f2ffff",fade))
			for j in range(5):
				var f:float=fposmod(t*1.4+float(j)*.2,1.0)
				var q:=tail.lerp(head,f)
				ice_crystal(im,q,0.0,3.5+1.5*pulse,Color("#d5faff",fade),Color("#569ad9",fade))
			if t>=peak:
				for j in range(6):
					var a:float=float(j)*TAU/6.0
					var q:=head+Vector2(cos(a),sin(a))*(5.0+8.0*(1.0-fade))
					ice_crystal(im,q,a,3.0,Color("#e1ffff",fade),Color("#78b8e7",fade))
		"eos_270":
			# Blizzard: broad moving snow front with layered gale streaks and snowflakes.
			for j in range(4):
				var y:float=8.0+float(j)*10.0
				var prev:=Vector2(3,y)
				for k in range(1,12):
					var f:float=float(k)/11.0
					var q:=Vector2(3+41*f,y+sin(f*TAU+t*TAU+float(j))*3.5)
					fx_line(im,prev,q,4.0,Color("#6fafd5",.23*pulse))
					fx_line(im,prev,q,1.2,Color("#c3eeff",.65*pulse))
					prev=q
			for j in range(18):
				var f:float=fposmod(t*1.2+float(j)*.139,1.0)
				var q:=Vector2(3+42*f,5+float(posmod(j*17,38))+sin(t*TAU+float(j))*2)
				fx_line(im,q-Vector2(7,2),q,1.0,Color("#c8eaff",pulse))
				if j%3==0:
					ice_crystal(im,q,t+float(j),3.0+float(j%2),Color("#f1ffff",pulse),Color("#7ebce5",pulse))
				else:fx_disc(im,q,1.2+float(j%2)*.5,Color("#e6fbff",pulse))
		"eos_042":
			# Aurora Beam: flowing colored ribbons separated from the hard Ice Beam.
			var head:=Vector2(9+29*drive,24)
			var tail:=Vector2(maxf(4.0,head.x-32.0*fade),24)
			var colors:Array[Color]=[Color("#84f8e0"),Color("#a5c7ff"),Color("#efb5ff")]
			for j in range(3):
				var prev:=tail+Vector2(0,float(j-1)*4)
				for k in range(1,16):
					var f:float=float(k)/15.0
					var q:=tail.lerp(head,f)+Vector2(0,float(j-1)*4+sin(f*TAU*1.4-t*TAU+float(j)*1.7)*5.0*sin(f*PI))
					fx_line(im,prev,q,3.3,Color("#405d9b",fade*.75))
					fx_line(im,prev,q,1.8,Color(colors[j],fade))
					prev=q
				fairy_star(im,prev,2.5,Color(colors[j],fade))
		"eos_344":
			# Ice Punch: visible knuckles encased in crystalline frost.
			var q:=Vector2(10+23*drive,24)
			fx_line(im,q-Vector2(13*fade,0),q,3.4,Color("#7cbfe7",fade))
			fight_fist(im,q,0.0,6.5,Color("#e1f8ff",fade),Color("#4676b5",fade))
			for j in range(5):
				var a:float=float(j)*TAU/5.0
				var axis:=Vector2(cos(a),sin(a))
				ice_crystal(im,q+axis*5.5,a,3.4,Color("#c6f8ff",fade),Color("#6ba2d4",fade))
				if t>=peak:
					var v:=q+axis*(8+8*(1.0-fade))
					fx_line(im,q+axis*6,v,1.3,Color("#e5ffff",fade))
					ice_crystal(im,v,a,2.2,Color("#e5ffff",fade),Color("#6da8d9",fade))
		"eos_461":
			# Ice Fang: closing icy jaws, long pointed crystalline teeth and frost burst.
			var c:=Vector2(17+13*drive,24)
			var opening:float=10.0-7.6*drive+4.0*(1.0-fade)
			for side in [-1,1]:
				var sy:float=float(side)
				var prev:=c+Vector2(-12,sy*(opening+3))
				for j in range(5):
					var x:float=-12+float(j)*6.0
					var q:=c+Vector2(x,sy*(opening+absf(x)*.20))
					fx_line(im,prev,q,4.2,Color("#4169a5",fade))
					fx_line(im,prev,q,2.4,Color("#a0d9f9",fade))
					var length:float=7.0 if j in [0,4] else 4.5
					var tip:=q+Vector2(0,-sy*length)
					fx_line(im,q,tip,2.8,Color("#72b4e0",fade))
					fx_line(im,q,tip,1.4,Color("#efffff",fade))
					prev=q
			if t>=peak:
				for j in range(6):
					var a:float=float(j)*TAU/6.0
					var q:=c+Vector2(cos(a),sin(a))*(6+9*(1.0-fade))
					ice_crystal(im,q,a,2.8,Color("#d9ffff",fade),Color("#70b7e4",fade))
		"eos_180":
			# Icicle Volley: sequential pointed ice darts, not a continuous beam.
			for j in range(5):
				var f:float=clampf(drive*1.28-float(j)*.13,0.0,1.0)
				var q:=Vector2(7+29*f,24+sin(float(j)*2.1)*7)
				fx_line(im,q-Vector2(7*fade,0),q,1.5,Color("#7cc9eb",fade))
				var tip:=q+Vector2(7,0)
				for k in range(-3,4):
					var v:=q+Vector2(-4,float(k))
					fx_line(im,v,tip,1.1,Color("#699fd5",fade))
				fx_line(im,q-Vector2(4,1.5),tip,1.3,Color("#dffbff",fade))
				if t>=peak:
					fx_disc(im,tip+Vector2(2,-3),1.2,Color("#e4ffff",fade))
		"eos_535":
			# Frozen Retort: defensive frost buildup, then an icefall counterstrike.
			var c:=Vector2(24,34)
			var buildup:float=clampf(t/maxf(peak,.01),0.0,1.0)
			for j in range(5):
				var x:float=8.0+float(j)*8.0
				var q:=Vector2(x,34-22*buildup)
				ice_crystal(im,q,-PI*.5,4.0+float(j%3)*1.5,Color("#ddfaff",fade),Color("#6d9ed4",fade))
				if t>=peak:
					var v:=q+Vector2(0,22*(1.0-fade))
					fx_line(im,v-Vector2(0,8),v,2.4,Color("#a1def6",fade))
					ice_crystal(im,v,PI*.5,5.0,Color("#e7fcff",fade),Color("#4f87c5",fade))
			if t>=peak:
				fx_line(im,c-Vector2(17,0),c+Vector2(17,0),2.4,Color("#c1efff",fade))
				for j in range(7):
					var q:=c+Vector2(float(j-3)*5,-4-8*sin(float(j)*PI/6.0)*(1.0-fade))
					fx_disc(im,q,1.7,Color("#b4e6f9",fade))
		"eos_150":
			# Absolute Frost: crystallizing central frost seal and radial freeze fracture.
			var c:=Vector2(24,24)
			var radius:float=4.0+15.0*drive
			fx_disc(im,c,radius,Color("#76b8e4",.35*fade),maxf(0.0,radius-2))
			for j in range(6):
				var a:float=float(j)*TAU/6.0
				var axis:=Vector2(cos(a),sin(a))
				var normal:=Vector2(-axis.y,axis.x)
				var tip:=c+axis*radius
				fx_line(im,c,tip,3.3,Color("#437cbf",fade))
				fx_line(im,c,tip,1.5,Color("#e4ffff",fade))
				for k in range(2):
					var q:=c+axis*radius*(.48+float(k)*.28)
					fx_line(im,q,q-axis*3+normal*4,1.4,Color("#b4e8ff",fade))
					fx_line(im,q,q-axis*3-normal*4,1.4,Color("#b4e8ff",fade))
				if t>=peak:
					var q:=tip+axis*(4*(1.0-fade))
					ice_crystal(im,q,a,2.5,Color("#ffffff",fade),Color("#82b9e2",fade))
			fx_disc(im,c,3.5+2*pulse,Color("#f7ffff",fade))
		"eos_118":
			# Tectonic Pulse: spreading ground fractures and displaced slabs.
			var c:=Vector2(24,29)
			var extent:float=4.0+18.0*drive
			for j in range(7):
				var a:float=float(j)*TAU/7.0
				var axis:=Vector2(cos(a),sin(a)*.66)
				var normal:=Vector2(-axis.y,axis.x)
				var prev:=c
				for k in range(1,5):
					var f:float=float(k)/4.0
					var q:=c+axis*extent*f+normal*sin(float(k)*2.1+float(j))*2.0*f
					fx_line(im,prev,q,1.5+2.0*drive,Color("#382c2b",fade))
					fx_line(im,prev+Vector2(0,2),q+Vector2(0,2),1.0,Color("#d3a77b",fade))
					prev=q
				var lift:float=sin(t*PI)*float(3+j%3*3)
				mineral(im,prev-Vector2(0,lift),3.1+float(j%2),a,Color("#c9b08d",fade),Color("#675248",fade))
			if t>=peak:
				var radius:float=9+12*(1.0-fade)
				for j in range(9):
					var a:float=float(j)*TAU/9.0
					var q:=c+Vector2(cos(a)*radius,sin(a)*radius*.52)
					fx_disc(im,q,2.1,Color("#bd9b78",fade*.62))
		"eos_484":
			# Earth Power: warm underground vents erupt with soil and glowing energy.
			for j in range(4):
				var x:float=7.0+float(j)*11.0
				var u:float=clampf(drive*1.25-float(j)*.10,0.0,1.0)
				var h:float=3+24*u*fade
				var c:=Vector2(x,37+float(j%2)*3)
				fx_line(im,c-Vector2(4,0),c+Vector2(4,0),2.2,Color("#4c382c",fade))
				fx_line(im,c,c-Vector2(0,h),5.8,Color("#936342",fade))
				fx_line(im,c,c-Vector2(0,h),3.0,Color("#e6ad65",fade))
				fx_line(im,c,c-Vector2(0,h),1.0,Color("#ffe8ad",fade))
				for k in range(3):
					var f:float=fposmod(t+float(k)*.30+float(j)*.13,1.0)
					var q:=c+Vector2(float(k-1)*7*f,-h*sin(f*PI))
					earth_rock(im,q,2.0+float(k%2),Color("#cfaa77",fade),Color("#6d4835",fade))
		"eos_008":
			# Burrow Strike: excavation hole, soil thrown outwards, then emergence.
			var c:=Vector2(24,33)
			var radius:float=4.0+10.0*drive
			for j in range(-4,5):
				var y:float=float(j)
				var w:float=radius*sqrt(maxf(0.0,1.0-y*y/25.0))
				fx_line(im,c+Vector2(-w,y),c+Vector2(w,y),1.0,Color("#302825",fade))
			for j in range(12):
				var a:float=float(j)*TAU/12.0
				var axis:=Vector2(cos(a),sin(a)*.38)
				var f:float=fposmod(t*1.25+float(j)*.09,1.0)
				var q:=c+axis*(radius+5*f)-Vector2(0,12*sin(f*PI)*pulse)
				earth_rock(im,q,2.4+float(j%3)*.5,Color("#c9a375",fade),Color("#79503b",fade))
			if t>=peak:
				for j in range(5):
					var q:=c+Vector2(float(j-2)*4,-5-15*fade)
					fx_line(im,c+Vector2(float(j-2)*2,0),q,1.5,Color("#e8c89b",fade))
		"eos_131":
			# Fault Rift: a single deep chasm propagates and tears open.
			var prev:=Vector2(4,37)
			for j in range(1,10):
				var f:float=float(j)/9.0
				if f>drive+.12:break
				var q:=Vector2(4+39*f,37-24*f+sin(float(j)*2.7)*3)
				var width:float=2.5+5.0*drive
				fx_line(im,prev,q,width+2,Color("#7b5a44",fade))
				fx_line(im,prev,q,width,Color("#251d20",fade))
				fx_line(im,prev+Vector2(0,3),q+Vector2(0,3),1.3,Color("#dcba8c",fade))
				if j%2==0:
					var tip:=q+Vector2(-4,-6)
					fx_line(im,q,tip,1.8,Color("#392a29",fade))
					earth_rock(im,tip-Vector2(0,4*pulse),2.7,Color("#cfad80",fade),Color("#71513c",fade))
				prev=q
		"eos_030":
			# Rock Slide: staggered boulders descend diagonally and shed rubble.
			for j in range(6):
				var f:float=clampf(t*1.40-float(j)*.12,0.0,1.0)
				var landing:=Vector2(12+float(j%3)*13,33+float(j%2)*5)
				var q:=landing+Vector2(-8,-29)*(1.0-f)
				var opacity:float=1.0-smoothstep(.87,1.0,f)
				fx_line(im,q-Vector2(3,10),q,1.9,Color("#c5b19a",opacity))
				mineral(im,q,4.8+float(j%3),float(j)+f*2.8,Color("#ded1bf",opacity),Color("#746763",opacity))
				if f>=.78:
					for k in range(3):
						var a:float=PI+float(k)*PI*.5
						var v:=landing+Vector2(cos(a),sin(a))*(3+9*(f-.78)/.22)
						earth_rock(im,v,2.0,Color("#cdb99f",opacity),Color("#847267",opacity))
		"eos_481":
			# Stone Edge: angular mineral spires thrust up in sequence.
			for j in range(5):
				var f:float=clampf(drive*1.4-float(j)*.11,0.0,1.0)
				var base:=Vector2(7+float(j)*8,38-float(j%2)*4)
				var h:float=(10+float(j%3)*5)*f
				var tip:=base+Vector2(float(j%2)*2-1,-h)
				for k in range(-3,4):
					fx_line(im,base+Vector2(float(k),0),tip,1.2,Color("#706765",fade))
				fx_line(im,base-Vector2(3,0),tip,1.3,Color("#d3c6b2",fade))
				fx_line(im,base+Vector2(1,0),tip,1.1,Color("#9c8b7d",fade))
				if t>=peak:
					var q:=base+Vector2(-4-float(j%2)*2,-h*.45-5*(1.0-fade))
					mineral(im,q,2.3,float(j),Color("#d4bfa6",fade),Color("#766b60",fade))
		"eos_028":
			# Rock Throw: one rotating faceted stone follows a ballistic arc.
			var q:=Vector2(10+27*drive,30-17*sin(drive*PI))
			var radius:float=6.5+1.0*pulse
			fx_line(im,q-Vector2(8*fade,3),q,2.1,Color("#b49c88",fade))
			mineral(im,q,radius,t*TAU,Color("#d6c7b2",fade),Color("#655b56",fade))
			if t>=peak:
				for j in range(5):
					var a:float=float(j)*TAU/5.0
					var axis:=Vector2(cos(a),sin(a))
					var v:=q+axis*(radius+7*(1.0-fade))
					mineral(im,v,2.0,a,Color("#cdbcaa",fade),Color("#817167",fade))
		"eos_073":
			# Rock Tomb: falling stones assemble a rocky enclosure around the target.
			var c:=Vector2(24,29)
			for j in range(6):
				var a:float=float(j)*TAU/6.0
				var u:float=clampf(drive*1.24-float(j%3)*.12,0.0,1.0)
				var base:=c+Vector2(cos(a)*13,sin(a)*7)
				var q:=base-Vector2(0,21*(1.0-u))
				var radius:float=5.2+float(j%2)
				mineral(im,q,radius,a*.55,Color("#c8b8a7",fade),Color("#665b56",fade))
				if t>=peak:
					fx_disc(im,base+Vector2(0,4),2.7,Color("#b9a38d",fade*.7))
			if t>=peak:
				fx_disc(im,c,4.0+3.0*pulse,Color("#514034",fade*.45),3.0+3.0*pulse)
		"lib_ground_1":
			# Fissure Slam: two wide shock fractures crossing a central crater.
			var c:=Vector2(24,30)
			for j in range(4):
				var a:float=PI*.25+float(j)*PI*.5
				var axis:=Vector2(cos(a),sin(a)*.68)
				var tip:=c+axis*(5+22*drive)
				var bend:=c+axis*(3+8*drive)+Vector2(-axis.y,axis.x)*3
				fx_line(im,c,bend,4.3,Color("#3b2c27",fade))
				fx_line(im,bend,tip,3.0,Color("#3b2c27",fade))
				fx_line(im,bend+Vector2(0,3),tip+Vector2(0,3),1.2,Color("#d5b183",fade))
				mineral(im,tip-Vector2(0,7*pulse),3.4,a,Color("#c8a778",fade),Color("#78563e",fade))
			var radius:float=3.0+9.0*drive
			fx_disc(im,c,radius,Color("#8f694b",fade),maxf(0.0,radius-2.5))
			fx_disc(im,c,radius*.55,Color("#342823",fade))
		"eos_057":
			# Gust: expanding curved wind ribbons and entrained dust motes.
			for j in range(4):
				var prev:=Vector2(6,24+float(j-2)*2)
				for k in range(1,15):
					var f:float=float(k)/14.0
					var q:=Vector2(6+34*f*drive,24+float(j-2)*(2+7*f)+sin(f*TAU-t*TAU+float(j))*3.0*f)
					fx_line(im,prev,q,2.2,Color("#749cb5",fade*.7))
					fx_line(im,prev,q,1.0,Color("#e9faff",fade))
					prev=q
			for j in range(7):
				var f:float=fposmod(t+float(j)*.14,1.0)
				var q:=Vector2(7+32*f*drive,24+sin(float(j)*2.4+t*3.0)*12*f)
				fx_disc(im,q,1.2,Color("#c7e5ee",fade))
		"eos_036":
			# Air Cutter: three separated crescent projectiles with tapered edges.
			for j in range(3):
				var f:float=clampf(drive*1.25-float(j)*.12,0.0,1.0)
				var q:=Vector2(9+25*f,15+float(j)*9.0)
				var a:float=-PI*.60+float(j)*.12
				fight_arc(im,q,8.5,a,PI*1.05,Color("#e9fcff",fade),Color("#609bb9",fade),2.8)
				fx_line(im,q-Vector2(9*fade,0),q-Vector2(3,0),1.1,Color("#b5e6f1",fade))
		"eos_442":
			# Air Slash: single broad pressure blade, sharp white leading edge.
			var q:=Vector2(10+22*drive,24)
			var a:float=-1.8+1.1*drive
			fight_arc(im,q,13.5,a,PI*1.02,Color("#eefcff",fade),Color("#5689a8",fade),5.8)
			fight_arc(im,q,15.0,a+.18,PI*.82,Color("#ffffff",fade),Color("#a3e2f4",fade),1.5)
			if t>=peak:
				for j in range(5):
					var angle:float=-1.3+float(j)*.65
					var axis:=Vector2(cos(angle),sin(angle))
					fx_line(im,q+axis*13,q+axis*(17+5*(1.0-fade)),1.2,Color("#c5f1ff",fade))
		"eos_153":
			# Aerial Dive: climbing and descending wind wake; actor route remains authoritative.
			var q:=Vector2(8+29*drive,34-23*sin(drive*PI))
			var angle:float=-1.15+2.30*drive
			var axis:=Vector2(cos(angle),sin(angle))
			var normal:=Vector2(-axis.y,axis.x)
			for j in range(3):
				var v:=q-axis*(5+float(j)*5)
				fx_line(im,v-normal*(4+float(j)),q-normal*2,1.4,Color("#b0d8f3",fade))
				fx_line(im,v+normal*(4+float(j)),q+normal*2,1.4,Color("#e8faff",fade))
			air_feather(im,q,angle-2.35,12.0,Color("#eafaff",fade),Color("#739db9",fade))
			air_feather(im,q,angle+2.35,12.0,Color("#eafaff",fade),Color("#739db9",fade))
			if t>=peak:
				fight_arc(im,q,9+7*(1.0-fade),PI*.1,PI*.8,Color("#dcfaff",fade),Color("#94bbd1",fade),2.0)
		"eos_205":
			# Vault Crash: high vault with vertical speed lines and landing pressure ring.
			var c:=Vector2(24,37)
			var height:float=sin(drive*PI)*27.0
			var q:=c-Vector2(0,height)
			for j in range(4):
				var x:float=float(j-2)*3.8
				var sy:float=1.0 if drive<.5 else -1.0
				fx_line(im,q+Vector2(x,sy*4),q+Vector2(x,sy*(8+height*.35)),1.4,Color("#cbeeff",fade))
			fx_disc(im,q,4.5,Color("#b1d9f0",fade))
			fx_disc(im,q-Vector2(0,1),2.8,Color("#effcff",fade))
			if t>=peak:
				var radius:float=4+15*(1.0-fade)
				for j in range(10):
					var a:float=float(j)*TAU/10.0
					var axis:=Vector2(cos(a),sin(a)*.38)
					fx_line(im,c+axis*radius*.65,c+axis*radius,1.5,Color("#e1f5ff",fade))
					fx_disc(im,c+axis*radius-Vector2(0,4*pulse),1.5,Color("#a5c2cc",fade))
		"eos_100":
			# Skyfall Charge: focused descending pressure cone with long trailing ribbons.
			var q:=Vector2(24,5+31*drive)
			for j in range(5):
				var x:float=float(j-2)*3.2
				var tail:=q+Vector2(x*1.8,-17*fade-3)
				fx_line(im,tail,q+Vector2(x*.4,0),2.4,Color("#558ac2",fade))
				fx_line(im,tail,q+Vector2(x*.4,0),1.0,Color("#d8efff",fade))
			fx_disc(im,q,5.8,Color("#6299d3",fade))
			fx_disc(im,q,3.3,Color("#eff8ff",fade))
			if t>=peak:
				for j in range(7):
					var a:float=PI+float(j)*PI/6.0
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,q+axis*5,q+axis*(10+7*(1.0-fade)),1.8,Color("#b3deff",fade))
		"eos_518":
			# Brave Bird: luminous bird-shaped charge, hot feather tips and recoil sparks.
			var q:=Vector2(10+24*drive,24-8*sin(drive*PI))
			fx_line(im,q-Vector2(18*fade,0),q,5.0,Color("#c86441",fade))
			fx_line(im,q-Vector2(13*fade,0),q,2.5,Color("#ffd294",fade))
			for side in [-1,1]:
				var sy:float=float(side)
				var elbow:=q+Vector2(-6,sy*7)
				var tip:=q+Vector2(-14,sy*(12+3*pulse))
				fx_line(im,q,elbow,4.4,Color("#e57e45",fade))
				fx_line(im,elbow,tip,3.0,Color("#ffca75",fade))
				for j in range(3):
					var v:=elbow.lerp(tip,float(j)/3.0)
					fx_line(im,v,v+Vector2(-4,sy*4),1.7,Color("#ffe0a7",fade))
			fx_line(im,q,q+Vector2(7,0),3.1,Color("#fff5c9",fade))
			if t>=peak:
				for j in range(8):
					var a:float=float(j)*TAU/8.0
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,q+axis*6,q+axis*(11+7*(1.0-fade)),1.4,Color("#ffbe77",fade))
		"eos_178":
			# Wing Attack: feathered wing silhouettes sweep across the target.
			var c:=Vector2(22,24)
			for side in [-1,1]:
				var sy:float=float(side)
				var angle:float=sy*(-2.2+1.5*drive)
				var axis:=Vector2(cos(angle),sin(angle))
				var normal:=Vector2(-axis.y,axis.x)
				for j in range(5):
					var f:float=float(j)/4.0
					var q:=c+axis*(4+12*f)
					air_feather(im,q,angle+sy*.65,9.0-3*f,Color("#effaff",fade),Color("#739fb9",fade))
				fx_line(im,c,c+axis*17,2.2,Color("#c1e7f8",fade))
				fx_line(im,c+normal*2,c+axis*13+normal*2,1.0,Color("#f1ffff",fade))
			if t>=peak:
				fight_arc(im,c,17.5,-1.1,2.2,Color("#e9faff",fade),Color("#8bb5c9",fade),2.7)
		"eos_200":
			# Poison Sting: three slender venom needles, each with a distinct tip.
			for j in range(3):
				var f:float=clampf(drive*1.25-float(j)*.16,0.0,1.0)
				var q:=Vector2(8+29*f,17+float(j)*7.0)
				fx_line(im,q-Vector2(10*fade,0),q,1.1,Color("#9863bf",fade))
				fx_line(im,q-Vector2(5,0),q+Vector2(3,0),2.3,Color("#542d76",fade))
				fx_line(im,q-Vector2(3,-1),q+Vector2(6,0),1.2,Color("#e5b5ff",fade))
				fx_disc(im,q+Vector2(2,1),1.6,Color("#b6ed76",fade))
				if t>=peak:
					fx_disc(im,q+Vector2(5,-4-3*(1.0-fade)),1.1,Color("#c3f690",fade))
		"eos_495":
			# Poison Jab: muscular thrust ending in a single barbed venom spike.
			var q:=Vector2(10+23*drive,24)
			fx_line(im,q-Vector2(15*fade,0),q,4.5,Color("#67377e",fade))
			fx_line(im,q-Vector2(10,0),q-Vector2(1,0),5.5,Color("#532c69",fade))
			for j in range(-4,5):
				fx_line(im,q+Vector2(-2,float(j)),q+Vector2(9,0),1.2,Color("#a866cf",fade))
			fx_line(im,q+Vector2(-2,-3),q+Vector2(9,0),1.6,Color("#f2c8ff",fade))
			fx_line(im,q-Vector2(3,0),q+Vector2(2,0),2.0,Color("#b8ef73",fade))
			if t>=peak:
				for j in range(6):
					var a:float=float(j)*TAU/6.0
					var axis:=Vector2(cos(a),sin(a))
					var v:=q+Vector2(5,0)+axis*(5+9*(1.0-fade))
					water_drop(im,v,1.7,Color("#dcf9a5",fade),Color("#7c9f42",fade))
		"eos_280":
			# Sludge Bomb: arcing pressurized toxic glob, bursting into viscous droplets.
			var q:=Vector2(10+24*drive,28-14*sin(drive*PI))
			var radius:float=6.2+2.0*pulse
			fx_disc(im,q,radius,Color("#572369",fade))
			fx_disc(im,q-Vector2(1,1),radius-1.7,Color("#ad5bc1",fade))
			fx_disc(im,q-Vector2(2,3),2.1,Color("#edb6ef",fade))
			for j in range(3):
				var a:float=float(j)*TAU/3.0+t*TAU
				var v:=q+Vector2(cos(a),sin(a))*radius*.66
				fx_disc(im,v,1.4,Color("#b9e875",fade))
			if t>=peak:
				for j in range(8):
					var a:float=float(j)*TAU/8.0
					var axis:=Vector2(cos(a),sin(a))
					var v:=q+axis*(radius+9*(1.0-fade))
					fx_line(im,q+axis*radius*.75,v,1.7,Color("#9350a9",fade))
					water_drop(im,v,2.0+float(j%2),Color("#cf8bd5",fade),Color("#652c79",fade))
		"eos_197":
			# Virulent Hex: escalating poison bubbles rise around a skull-shaped warning sigil.
			var c:=Vector2(24,24)
			var radius:float=5+11*drive
			for j in range(7):
				var a:float=float(j)*TAU/7.0+t*2.0
				var q:=c+Vector2(cos(a)*radius,sin(a)*radius)
				var r:float=2.2+float(j%3)*.7
				fx_disc(im,q,r,Color("#713c90",fade),maxf(0.0,r-1.2))
				fx_disc(im,q-Vector2(1,1),1.0,Color("#d9b4f1",fade))
			fx_disc(im,c-Vector2(0,2),6.5,Color("#5e357d",fade))
			fx_disc(im,c-Vector2(0,3),5.0,Color("#d3adee",fade))
			for side in [-1,1]:
				fx_disc(im,c+Vector2(float(side)*2.5,-3),1.5,Color("#402650",fade))
			fx_line(im,c+Vector2(-3,3),c+Vector2(3,3),2.8,Color("#d3adee",fade))
			for j in range(3):
				fx_line(im,c+Vector2(float(j-1)*2.2,3),c+Vector2(float(j-1)*2.2,5),.8,Color("#603675",fade))
		"eos_332":
			# Acid: corrosive lime-green liquid sheet with falling drips and small bubbles.
			var head:=Vector2(10+25*drive,24)
			var tail:=Vector2(maxf(4.0,head.x-24*fade),23)
			for j in range(1,12):
				var f:float=float(j)/11.0
				var g:float=float(j-1)/11.0
				var a:=tail.lerp(head,g)+Vector2(0,sin(g*TAU-t*7.0)*2)
				var q:=tail.lerp(head,f)+Vector2(0,sin(f*TAU-t*7.0)*2)
				fx_line(im,a,q,3.0+3.5*f,Color("#507f35",fade))
				fx_line(im,a,q,1.8+2.6*f,Color("#b5e65c",fade))
				fx_line(im,a-Vector2(0,1),q-Vector2(0,1),.8,Color("#efffc1",fade))
			for j in range(5):
				var q:=head+Vector2(-float(j)*4,4+sin(t*PI)*float(j%3)*3)
				water_drop(im,q,2.3,Color("#e3ffa0",fade),Color("#729c3f",fade))
				fx_disc(im,q+Vector2(2,4),1.0,Color("#c9f48d",fade))
		"eos_147":
			# Smog: layered soot-grey and violet clouds with curling turbulent edges.
			for j in range(12):
				var f:float=float(j)/11.0
				var q:=Vector2(8+30*f*drive,24+sin(float(j)*2.4+t*3.0)*(4+7*f))
				var radius:float=3.0+4.0*f+1.4*pulse
				fx_disc(im,q,radius,Color("#393446",(.32+.42*f)*fade))
				fx_disc(im,q-Vector2(1,2),radius*.68,Color("#74647e",(.30+.40*f)*fade))
				if j%3==0:
					fight_arc(im,q,radius+1.2,t*TAU+float(j),PI*.7,Color("#a299ae",fade*.7),Color("#554760",fade*.7),1.1)
			for j in range(5):
				var q:=Vector2(10+float(j)*6,12+sin(t*TAU+float(j))*6)
				fx_disc(im,q,1.0,Color("#b59ac8",fade*.6))
		"eos_485":
			# Gunk Shot: dense irregular waste clump, opaque lobes and heavy splash.
			var q:=Vector2(12+22*drive,25-5*sin(drive*PI))
			var radius:float=8.0+2.0*pulse
			fx_line(im,q-Vector2(14*fade,1),q,5.0,Color("#4b294a",fade))
			fx_disc(im,q,radius,Color("#44233f",fade))
			for j in range(6):
				var a:float=float(j)*TAU/6.0+t
				var v:=q+Vector2(cos(a),sin(a))*radius*.65
				fx_disc(im,v,3.4+float(j%2),Color("#82517e",fade))
				fx_disc(im,v-Vector2(1,1),1.7,Color("#c394b3",fade))
			fx_disc(im,q-Vector2(2,2),2.0,Color("#aaa05d",fade))
			if t>=peak:
				for j in range(9):
					var a:float=float(j)*TAU/9.0
					var axis:=Vector2(cos(a),sin(a))
					var v:=q+axis*(radius+9*(1.0-fade))
					fx_line(im,q+axis*radius*.7,v,2.2,Color("#79506f",fade))
					fx_disc(im,v,2.0+float(j%2),Color("#9f7198",fade))
		"eos_459":
			# Cross Poison: two separately swept toxic blades intersect at contact.
			var c:=Vector2(24,24)
			for side in [-1,1]:
				var sy:float=float(side)
				var u:float=clampf(drive*1.35-(.15 if side>0 else 0.0),0.0,1.0)
				var origin:=c+Vector2(-13,sy*13)
				var tip:=origin.lerp(c+Vector2(13,-sy*13),u)
				fx_line(im,origin,tip,5.0,Color("#5b3376",fade))
				fx_line(im,origin,tip,2.8,Color("#c187ed",fade))
				fx_line(im,origin+Vector2(0,-sy),tip+Vector2(0,-sy),1.0,Color("#ddff9d",fade))
				if t>=peak:
					for j in range(3):
						var v:=c+Vector2(float(j-1)*6,sy*(4+8*(1.0-fade)))
						fx_disc(im,v,1.5,Color("#b9ed80",fade))
			if t>=peak:
				fairy_star(im,c,3.0+3.0*pulse,Color("#f0ffcb",fade))
		"eos_151":
			# Sunlance: solar collection followed by a brilliant focused beam.
			var c:=Vector2(9,24)
			var charge:float=clampf(t/maxf(peak,.01),0.0,1.0)
			for j in range(8):
				var a:float=float(j)*TAU/8.0+t*1.6
				var axis:=Vector2(cos(a),sin(a))
				var q:=c+axis*(13-8*charge)
				fx_line(im,q,q+axis*3.0,1.5,Color("#ffdf76",fade))
			fx_disc(im,c,3.0+5.0*charge,Color("#e9ad31",fade))
			fx_disc(im,c,2.0+3.0*charge,Color("#ffffc8",fade))
			if t>=peak:
				var head:=Vector2(9+34*clampf((t-peak)/maxf(1.0-peak,.01)*2.5,0.0,1.0),24)
				fx_line(im,c,head,8.0*fade+1,Color("#e7b52c",fade))
				fx_line(im,c,head,5.0*fade+1,Color("#fff27a",fade))
				fx_line(im,c,head,2.0,Color("#ffffed",fade))
				for j in range(6):
					var q:=c.lerp(head,float(j)/5.0)+Vector2(0,sin(float(j)*2.2+t*TAU)*7)
					fairy_star(im,q,1.6,Color("#fff2a7",fade))
		"eos_537":
			# Leaf Storm: a widening vortex of spinning leaves and curved wind bands.
			var c:=Vector2(24,25)
			for j in range(3):
				var a:float=t*TAU*1.5+float(j)*TAU/3.0
				fight_arc(im,c,6.0+12.0*drive+float(j)*2,a,PI*.85,Color("#c6f1a0",fade),Color("#4d9b67",fade),1.8)
			for j in range(13):
				var f:float=float(j)/12.0
				var a:float=float(j)*2.4+t*TAU*1.5
				var r:float=(5+16*drive)*(.45+f*.55)
				var q:=c+Vector2(cos(a)*r,sin(a)*r*.88)
				grass_leaf(im,q,a+PI*.5,5.5+float(j%3)*1.5,Color("#c6ed71",fade),Color("#31794a",fade))
		"eos_443":
			# Energy Ball: a translucent green core with orbiting chlorophyll motes.
			var q:=Vector2(10+24*drive,24)
			var r:float=5.5+3.0*pulse
			fx_line(im,q-Vector2(10*fade,0),q,3.4,Color("#589a45",fade))
			fx_disc(im,q,r,Color("#286447",fade))
			fx_disc(im,q,r-1.6,Color("#70bd54",fade))
			fx_disc(im,q-Vector2(1,1),r*.48,Color("#dcff9a",fade))
			for j in range(5):
				var a:float=float(j)*TAU/5.0+t*TAU
				var v:=q+Vector2(cos(a),sin(a))*(r+3)
				fx_disc(im,v,1.5,Color("#c2f785",fade))
				fight_arc(im,q,r+2.0,a,.5,Color("#d8ffac",fade),Color("#408f5a",fade),1.2)
			if t>=peak:
				for j in range(6):
					var a:float=float(j)*TAU/6.0
					var v:=q+Vector2(cos(a),sin(a))*(r+8*(1.0-fade))
					grass_leaf(im,v,a,4.5,Color("#d3ff8a",fade),Color("#428650",fade))
		"eos_336":
			# Leaf Blade: one enlarged leaf-shaped cutting edge with a central vein.
			var c:=Vector2(18+10*drive,24)
			var angle:float=-1.9+2.0*drive
			grass_leaf(im,c,angle,17.0,Color("#b8f078",fade),Color("#286c40",fade))
			var axis:=Vector2(cos(angle),sin(angle))
			fx_line(im,c,c+axis*16,1.4,Color("#efffc3",fade))
			fight_arc(im,c,15.5,angle-1.2,1.65,Color("#e5ffac",fade),Color("#4b9d4d",fade),3.2)
			if t>=peak:
				for j in range(4):
					var a:float=angle+float(j-2)*.45
					var v:=c+Vector2(cos(a),sin(a))*(16+5*(1.0-fade))
					fx_disc(im,v,1.3,Color("#d2f990",fade))
		"eos_182","lib_grass_1":
			# Vine Whip is a single flexible lash; Briar Whip has two thorned strands.
			var briar:bool=id=="lib_grass_1"
			var count:int=2 if briar else 1
			for j in range(count):
				var prev:=Vector2(4,24+float(j)*5)
				for k in range(1,20):
					var f:float=float(k)/19.0
					var reach:float=9+31*drive
					var q:=Vector2(4+reach*f,24+float(j)*5+sin(f*TAU*1.15-t*TAU+float(j)*PI*.6)*7.0*f)
					var width:float=3.8-1.8*f
					fx_line(im,prev,q,width,Color("#286341",fade))
					fx_line(im,prev,q,width*.54,Color("#a0da63",fade))
					if k%4==0:
						if briar:
							fx_line(im,q,q+Vector2(-3,-4 if k%8==0 else 4),1.6,Color("#d3e89d",fade))
						else:
							grass_leaf(im,q,-1.8 if k%8==0 else 1.8,5.0,Color("#b4ec77",fade),Color("#32784b",fade))
					prev=q
				if t>=peak:
					fight_arc(im,prev,5.0+5*(1.0-fade),-1.0,1.9,Color("#d9ffa4",fade),Color("#5a9c50",fade),1.8)
		"eos_253":
			# Petal Frenzy: pink flower petals tumble through a graceful double spiral.
			var c:=Vector2(24,24)
			for j in range(12):
				var f:float=float(j)/11.0
				var a:float=float(j)*2.4+t*TAU*1.4
				var r:float=(4+16*drive)*(.35+f*.65)
				var q:=c+Vector2(cos(a)*r,sin(a)*r)
				var axis:=Vector2(cos(a+.7),sin(a+.7))
				fx_line(im,q-axis*2,q+axis*2,3.4,Color("#b65b88",fade))
				fx_line(im,q-axis*1.5-Vector2(0,1),q+axis*1.5-Vector2(0,1),2.3,Color("#ffd0e4",fade))
				fx_disc(im,q+axis*2,1.0,Color("#fff0f5",fade))
			fight_arc(im,c,10+7*drive,t*TAU,PI*1.2,Color("#ffe3ef",fade*.8),Color("#c17da0",fade*.65),1.4)
		"eos_441":
			# Wood Hammer: solid bark-covered mallet with a downward swing and splinters.
			var pivot:=Vector2(12,36)
			var a:float=-2.1+1.95*drive
			var axis:=Vector2(cos(a),sin(a))
			var normal:=Vector2(-axis.y,axis.x)
			var q:=pivot+axis*23
			fx_line(im,pivot,q,4.6,Color("#54382d",fade))
			fx_line(im,pivot,q,2.7,Color("#aa7948",fade))
			for j in range(-3,4):
				var v:=q+axis*float(j)
				fx_line(im,v-normal*8,v+normal*8,1.6,Color("#795035",fade))
			fx_line(im,q-axis*3-normal*7,q-axis*3+normal*7,1.4,Color("#d1a371",fade))
			for j in range(3):
				var v:=q+normal*float(j-1)*5
				fx_line(im,v-axis*2,v+axis*3,1.0,Color("#4e362c",fade))
			if t>=peak:
				for j in range(7):
					var angle:float=float(j)*TAU/7.0
					var d:=Vector2(cos(angle),sin(angle))
					var v:=q+d*(7+10*(1.0-fade))
					fx_line(im,v-d*3,v+d*2,1.8,Color("#caa16a",fade))
					fx_disc(im,v+Vector2(0,3),1.6,Color("#a58a5e",fade*.7))
		"eos_076":
			# Giga Drain: multiple bright streams return from the target to the caster.
			var from:=Vector2(39,24)
			var dest:=Vector2(9,24)
			for j in range(3):
				var prev:=from
				for k in range(1,18):
					var f:float=float(k)/17.0
					var q:=from.lerp(dest,f)+Vector2(0,sin(f*TAU+t*TAU+float(j)*TAU/3.0)*6.0*sin(f*PI))
					fx_line(im,prev,q,2.5,Color("#428c50",fade*.75))
					fx_line(im,prev,q,1.2,Color("#b3ed76",fade))
					prev=q
			for j in range(6):
				var f:float=fposmod(t*1.6+float(j)*.16,1.0)
				var q:=from.lerp(dest,f)+Vector2(0,sin(f*TAU+float(j))*4)
				fx_disc(im,q,2.1,Color("#e2ffa4",fade))
				grass_leaf(im,q,PI+float(j)*.2,4.5,Color("#a2e86e",fade),Color("#397f4d",fade))
			fx_disc(im,dest,4.5+4.0*drive,Color("#74ba57",fade))
			fx_disc(im,dest,2.7+2.0*drive,Color("#d9ffab",fade))
		"eos_001":
			# Iron Tail: articulated metal segments sweep into a heavy tapered tip.
			var c:=Vector2(16,25)
			var angle:float=-2.2+2.7*drive
			var prev:=c
			for j in range(1,10):
				var f:float=float(j)/9.0
				var a:float=angle+f*1.25
				var q:=c+Vector2(cos(a),sin(a))*19*f
				var width:float=7.0-4.3*f
				fx_line(im,prev,q,width,Color("#35465b",fade))
				fx_line(im,prev-Vector2(0,1),q-Vector2(0,1),width*.55,Color("#cedce7",fade))
				var n:=Vector2(-sin(a),cos(a))
				fx_line(im,q-n*width*.4,q+n*width*.4,1.0,Color("#607589",fade))
				prev=q
			fight_arc(im,c,19.0,angle-.6,1.4,Color("#f4fcff",fade),Color("#7a98ac",fade),2.1)
			if t>=peak:
				for j in range(5):
					var a:float=angle+float(j-2)*.4
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,prev,prev+axis*(4+8*(1.0-fade)),1.2,Color("#ffe4a0",fade))
		"eos_325":
			# Metal Claw: three polished hooked blades, each with a beveled cutting edge.
			for j in range(3):
				var c:=Vector2(12+9*drive+float(j)*5,14+float(j)*7)
				var prev:=c+Vector2(-6,7)
				for k in range(1,10):
					var f:float=float(k)/9.0
					var q:=c+Vector2(-6+22*f,7-16*sin(f*PI*.7))
					fx_line(im,prev,q,4.4*(1.0-f)+1.0,Color("#34495c",fade))
					fx_line(im,prev,q,2.6*(1.0-f)+.6,Color("#c0d4e1",fade))
					fx_line(im,prev-Vector2(0,1),q-Vector2(0,1),.8,Color("#f6ffff",fade))
					prev=q
				if t>=peak:
					fairy_star(im,prev+Vector2(2,1),2.2,Color("#ffe3a1",fade))
		"eos_103":
			# Meteor Mash: a heavy steel fist with a five-point impact flare.
			var q:=Vector2(10+23*drive,24)
			for j in range(4):
				var v:=q-Vector2(5+float(j)*4,0)
				fx_line(im,v+Vector2(-5,-5),v,2.6,Color("#d59755",fade))
				fx_line(im,v+Vector2(-7,4),v,1.3,Color("#ffe8ae",fade))
			fight_fist(im,q,0.0,7.4,Color("#dce8ef",fade),Color("#41556b",fade))
			if t>=peak:
				for j in range(5):
					var a:float=float(j)*TAU/5.0-PI*.5
					var axis:=Vector2(cos(a),sin(a))
					var v:=q+axis*(7+11*(1.0-fade))
					fx_line(im,q+axis*5,v,2.3,Color("#fff1bb",fade))
					fairy_star(im,v,2.1,Color("#f7fbff",fade))
		"eos_536":
			# Flash Cannon: concentrated chrome-white light and a strong directional discharge.
			var c:=Vector2(8,24)
			var head:=Vector2(8+34*drive,24)
			var width:float=4+6*pulse
			fx_disc(im,c,4+4*pulse,Color("#7b9bb5",fade))
			fx_disc(im,c,2+3*pulse,Color("#faffff",fade))
			if drive>.05:
				fx_line(im,c,head,width+2,Color("#415d79",fade))
				fx_line(im,c,head,width,Color("#a7e3ff",fade))
				fx_line(im,c,head,width*.58,Color("#f3ffff",fade))
				for j in range(5):
					var q:=c.lerp(head,float(j)/4.0)
					fx_line(im,q+Vector2(-3,-width*.6),q+Vector2(3,width*.6),1.1,Color("#e5f5fc",fade))
			if t>=peak:
				for j in range(8):
					var a:float=float(j)*TAU/8.0
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,head+axis*4,head+axis*(8+9*(1.0-fade)),1.3,Color("#f5ffff",fade))
		"eos_510":
			# Bullet Punch: fast metallic knuckle strike with two narrow motion echoes.
			for j in range(2,-1,-1):
				var f:float=clampf(drive*1.25-float(j)*.14,0.0,1.0)
				var q:=Vector2(10+24*f,24+float(j%2)*4)
				var opacity:float=fade*(1.0-float(j)*.27)
				fx_line(im,q-Vector2(12,0),q,1.8,Color("#8daec3",opacity))
				fight_fist(im,q,0.0,5.8-float(j)*.7,Color("#edf7fc",opacity),Color("#526a81",opacity))
			if t>=peak:
				var q:=Vector2(34,24)
				for j in range(4):
					var a:float=float(j)*TAU/4.0
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,q+axis*5,q+axis*(8+6*(1.0-fade)),1.1,Color("#fff3c3",fade))
		"eos_431":
			# Iron Head: broad armored forehead with rivets and a blunt compression flash.
			var q:=Vector2(10+24*drive,24)
			for j in range(-7,8):
				var y:float=float(j)
				var w:float=7.5-absf(y)*.45
				fx_line(im,q+Vector2(-w,y),q+Vector2(w,y),1.5,Color("#4d6075",fade))
				fx_line(im,q+Vector2(-w+1,y),q+Vector2(w-1,y),.8,Color("#b6c8d7",fade))
			fx_line(im,q+Vector2(-5,-4),q+Vector2(5,-4),2.1,Color("#f0f9ff",fade))
			for side in [-1,1]:
				fx_disc(im,q+Vector2(-4,float(side)*4),1.3,Color("#647b90",fade))
			if t>=peak:
				fight_arc(im,q,8+9*(1.0-fade),-PI*.65,PI*1.3,Color("#fff4c3",fade),Color("#8298ab",fade),2.2)
		"eos_475":
			# Gyro Ball: spinning solid metal sphere with offset reflective bands.
			var q:=Vector2(10+24*drive,24)
			var radius:float=7.0+2.0*pulse
			fx_disc(im,q,radius,Color("#34485b",fade))
			fx_disc(im,q-Vector2(1,1),radius-1.7,Color("#819bb0",fade))
			fx_disc(im,q-Vector2(2,3),radius*.42,Color("#e1f3ff",fade))
			for j in range(3):
				var a:float=t*TAU*2.5+float(j)*TAU/3.0
				fight_arc(im,q,radius+float(j%2)*2,a,PI*.65,Color("#f0fbff",fade),Color("#7297b0",fade),1.9)
				var v:=q+Vector2(cos(a),sin(a))*(radius+4)
				fx_line(im,v,v+Vector2(-sin(a),cos(a))*4,1.0,Color("#c6e7fa",fade))
		"eos_523":
			# Magnet Bomb: metallic core with paired magnetic poles and converging field lines.
			var q:=Vector2(10+24*drive,26-9*sin(drive*PI))
			mineral(im,q,6.5,t*2,Color("#dce7ed",fade),Color("#52677e",fade))
			for side in [-1,1]:
				var sy:float=float(side)
				var pole:=q+Vector2(0,sy*7)
				var tint:=Color("#f49c9b",fade) if side<0 else Color("#9bdfff",fade)
				fx_disc(im,pole,2.5,tint)
				for j in range(2):
					var radius:float=10.0+float(j)*3
					fight_arc(im,q,radius,sy*PI*.5-.9,1.8,tint,Color("#526b83",fade),1.4)
			if t>=peak:
				for j in range(6):
					var a:float=float(j)*TAU/6.0+t
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,q+axis*6,q+axis*(9+8*(1.0-fade)),1.5,Color("#e7f8ff",fade))
					fx_disc(im,q+axis*(10+8*(1.0-fade)),1.3,Color("#ffe2b3",fade))
		"eos_080","eos_529":
			# Leech Life uses hooked mandibles and a return stream; Bug Bite is a short snap.
			var drain:bool=id=="eos_080"
			var c:=Vector2(24,24)
			var gap:float=15.0-10.0*drive+5.0*(1.0-fade)
			for side in [-1,1]:
				var sy:float=float(side)
				var root:=c+Vector2(sy*(gap+4),-8)
				var elbow:=c+Vector2(sy*(gap+5),3)
				var tip:=c+Vector2(sy*(gap-3),6)
				fx_line(im,root,elbow,4.6,Color("#39462d",fade))
				fx_line(im,elbow,tip,4.0,Color("#39462d",fade))
				fx_line(im,root,elbow,2.6,Color("#aebc70",fade))
				fx_line(im,elbow,tip,2.1,Color("#e7ecad",fade))
				fx_line(im,tip,tip+Vector2(-sy*3,-4),1.8,Color("#f7f4cf",fade))
			if t>=peak:
				if drain:
					var travel:float=smoothstep(peak,1.0,t)
					for j in range(5):
						var f:float=clampf(travel*1.24-float(j)*.11,0.0,1.0)
						var q:=Vector2(36-27*f,24+sin(f*TAU+float(j))*5)
						fx_line(im,q,q+Vector2(4,0),1.3,Color("#c1b957",fade))
						fx_disc(im,q,2.1,Color("#f4e994",fade))
				else:
					for j in range(6):
						var a:float=float(j)*TAU/6.0
						var axis:=Vector2(cos(a),sin(a))
						fx_line(im,c+axis*4,c+axis*(9+6*(1.0-fade)),1.5,Color("#f1dca2",fade))
		"eos_082":
			# Silver Wind: shimmering insect scales carried by a broad curved breeze.
			for j in range(3):
				var prev:=Vector2(5,24+float(j-1)*3)
				for k in range(1,14):
					var f:float=float(k)/13.0
					var q:=Vector2(5+35*f*drive,24+float(j-1)*(3+9*f)+sin(f*TAU-t*TAU)*3)
					fx_line(im,prev,q,2.1,Color("#719fa2",fade*.7))
					fx_line(im,prev,q,.9,Color("#ecffff",fade))
					prev=q
			for j in range(12):
				var f:float=fposmod(t*1.15+float(j)*.09,1.0)
				var q:=Vector2(7+34*f*drive,24+sin(float(j)*2.4+t*3)*14*f)
				fairy_star(im,q,1.2+float(j%3)*.45,Color("#f2ffe8",fade))
		"eos_114":
			# Signal Beam: repeating red and green signal pulses around a pale core.
			var head:=Vector2(9+29*drive,24)
			var tail:=Vector2(maxf(4.0,head.x-31*fade),24)
			fx_line(im,tail,head,4.8,Color("#486b68",fade))
			fx_line(im,tail,head,1.4,Color("#f0fff4",fade))
			for j in range(6):
				var f:float=fposmod(t*1.5+float(j)*.17,1.0)
				var q:=tail.lerp(head,f)
				var tint:=Color("#ff9da1",fade) if j%2==0 else Color("#a7f58c",fade)
				fx_line(im,q+Vector2(-2,-5),q+Vector2(2,5),2.1,tint)
				fx_disc(im,q,1.4,Color("#effff0",fade))
			if t>=peak:
				fairy_star(im,head,4.0+2*pulse,Color("#eaffbd",fade))
		"eos_323":
			# Megahorn: massive tapered beetle horn with a forked root and impact splinters.
			var q:=Vector2(9+23*drive,24)
			var tip:=q+Vector2(10,0)
			fx_line(im,q-Vector2(13*fade,0),q,4.0,Color("#839d55",fade))
			for j in range(-5,6):
				fx_line(im,q+Vector2(-10,float(j)),tip,1.4,Color("#4b5a37",fade))
			fx_line(im,q-Vector2(10,-4),tip,2.0,Color("#d9e6a5",fade))
			fx_line(im,q-Vector2(8,3),q-Vector2(13,8),2.2,Color("#a7b67d",fade))
			if t>=peak:
				for j in range(7):
					var a:float=float(j)*TAU/7.0
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,tip+axis*3,tip+axis*(6+8*(1.0-fade)),1.5,Color("#f5edb2",fade))
		"eos_470":
			# X Scissor: two articulated chitin blades sweep across each other.
			var c:=Vector2(24,24)
			for side in [-1,1]:
				var sy:float=float(side)
				var angle:float=sy*(-1.15+1.95*drive)
				var axis:=Vector2(cos(angle),sin(angle))
				var origin:=c-axis*12
				var tip:=c+axis*14
				fx_line(im,origin,c,5.0,Color("#526336",fade))
				fx_line(im,c,tip,3.8,Color("#526336",fade))
				fx_line(im,origin,tip,2.2,Color("#e5f0a8",fade))
				fx_line(im,c+Vector2(0,sy*2),tip,1.0,Color("#fff9d8",fade))
			if t>=peak:
				fairy_star(im,c,4+3*pulse,Color("#fff8c8",fade))
				for j in range(4):
					var a:float=PI*.25+float(j)*PI*.5
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,c+axis*11,c+axis*(15+4*(1.0-fade)),1.1,Color("#d5e798",fade))
		"eos_502":
			# U Turn: forward strike curves into a returning path; tile movement is unchanged.
			var c:=Vector2(24,24)
			var angle:float=PI+TAU*.72*drive
			fight_arc(im,c,14.0,angle-1.6,1.8,Color("#e4f4b3",fade),Color("#658446",fade),3.2)
			var q:=c+Vector2(cos(angle),sin(angle))*14
			var axis:=Vector2(-sin(angle),cos(angle))
			var normal:=Vector2(-axis.y,axis.x)
			fx_line(im,q,q-axis*5+normal*3,1.8,Color("#edffd1",fade))
			fx_line(im,q,q-axis*5-normal*3,1.8,Color("#edffd1",fade))
			bug_wing(im,q-axis*5,angle,5.5,Color("#e9f6bd",fade),Color("#748c48",fade))
			if t>=peak:
				fairy_star(im,Vector2(11,24),3.0,Color("#f5f9cc",fade))
		"eos_530":
			# Bug Buzz: vibrating wing source and expanding scalloped acoustic fronts.
			var c:=Vector2(24,24)
			for side in [-1,1]:
				var sy:float=float(side)
				var a:float=sy*(1.0+.6*sin(t*TAU*3))
				bug_wing(im,c+Vector2(0,sy*3),a,6.0,Color("#f2f5c3",fade),Color("#738744",fade))
			for j in range(3):
				var radius:float=4.0+float(j)*5+7*drive
				var prev:=c+Vector2(radius,0)
				for k in range(1,25):
					var a:float=float(k)*TAU/24.0
					var rr:float=radius+sin(a*6-t*TAU)*1.2
					var q:=c+Vector2(cos(a),sin(a))*rr
					fx_line(im,prev,q,1.9,Color("#8fa959",fade))
					fx_line(im,prev,q,.8,Color("#f1ffd2",fade))
					prev=q
		"eos_460":
			# Attack Order: a coordinated swarm converges on the commanded point.
			var c:=Vector2(24,24)
			for j in range(8):
				var a:float=float(j)*TAU/8.0+t*1.6
				var axis:=Vector2(cos(a),sin(a))
				var normal:=Vector2(-axis.y,axis.x)
				var radius:float=19.0-13.0*drive+8.0*(1.0-fade)
				var q:=c+axis*radius
				fx_line(im,q+axis*5,q,1.2,Color("#b6d377",fade))
				fx_line(im,q-axis*2,q+axis*2,2.7,Color("#526239",fade))
				fx_line(im,q,q+normal*3.5+axis*2,1.8,Color("#e8f4b0",fade))
				fx_line(im,q,q-normal*3.5+axis*2,1.8,Color("#d2ed99",fade))
			if t>=peak:fairy_star(im,c,4+4*pulse,Color("#f8ffcf",fade))
		"eos_520":
			# Swarm Ward: six protective hexagonal chitin plates lock into a shield.
			var c:=Vector2(24,24)
			for j in range(6):
				var a:float=float(j)*TAU/6.0+t*.4
				var q:=c+Vector2(cos(a),sin(a))*(19-8*drive)
				psi_polygon(im,q,5.0,6,a,Color("#e7f5b5",fade),Color("#678344",fade))
				fx_disc(im,q,1.4,Color("#a7c77a",fade))
			if t>=peak:
				fx_disc(im,c,14.0,Color("#d0ed9a",fade),12.5)
		"eos_449":
			# Hive Renewal: amber honeycomb cells pulse and send healing motes inward.
			var c:=Vector2(24,24)
			for j in range(6):
				var a:float=float(j)*TAU/6.0
				var q:=c+Vector2(cos(a),sin(a))*12
				psi_polygon(im,q,6.0,6,PI/6,Color("#ffdc85",fade),Color("#9f793c",fade))
				var v:=q.lerp(c,drive)
				fx_disc(im,v,2.0,Color("#a6f3af",fade))
			fx_line(im,c-Vector2(0,5),c+Vector2(0,5),2.4,Color("#d8ffca",fade))
			fx_line(im,c-Vector2(5,0),c+Vector2(5,0),2.4,Color("#d8ffca",fade))
		"eos_288":
			# Glow Focus: firefly-like golden abdomen brightens through successive pulses.
			var c:=Vector2(24,27)
			var radius:float=4+6*drive
			fx_disc(im,c,radius+3,Color("#ac8b35",fade*.45))
			fx_disc(im,c,radius,Color("#ebc652",fade))
			fx_disc(im,c-Vector2(1,2),radius*.55,Color("#fff8b8",fade))
			for j in range(7):
				var a:float=float(j)*TAU/7.0+t
				var axis:=Vector2(cos(a),sin(a))
				fx_line(im,c+axis*(radius+2),c+axis*(radius+5+4*pulse),1.2,Color("#ffec9a",fade))
		"eos_164","eos_306":
			# Twin Needles flies as a matched pair; Pin Volley has a staggered five-dart fan.
			var twin:bool=id=="eos_164"
			var count:int=2 if twin else 5
			for j in range(count):
				var f:float=clampf(drive*(1.0 if twin else 1.3)-(0.0 if twin else float(j)*.12),0.0,1.0)
				var q:=Vector2(7+30*f,24+(float(j)-float(count-1)*.5)*(10.0 if twin else 5.0))
				fx_line(im,q-Vector2(8*fade,0),q,1.0,Color("#a6b77a",fade))
				fx_line(im,q-Vector2(5,2),q+Vector2(6,0),1.6,Color("#62783f",fade))
				fx_line(im,q-Vector2(5,-2),q+Vector2(6,0),1.3,Color("#e7edaa",fade))
				if t>=peak:
					fx_disc(im,q+Vector2(7,3),1.2,Color("#f9f2b9",fade))
		"eos_023":
			# Silk Drag: two thin threads unspool into a tightening target-side knot.
			var head:=Vector2(7+31*drive,24)
			for j in range(2):
				var prev:=Vector2(4,24)
				for k in range(1,20):
					var f:float=float(k)/19.0
					var q:=Vector2(4+(head.x-4)*f,24+sin(f*TAU*1.7-t*TAU+float(j)*PI)*3*f)
					fx_line(im,prev,q,1.7,Color("#b2c5b1",fade))
					fx_line(im,prev,q,.8,Color("#fcfff0",fade))
					prev=q
			if t>=peak:
				for j in range(3):
					fight_arc(im,head,3.0+float(j)*1.8,t*2+float(j),PI*1.5,Color("#f6fff3",fade),Color("#b1c3a7",fade),1.0)
		"eos_086":
			# Silken Anchor: radial silk spokes deploy before the web is woven.
			var c:=Vector2(24,24)
			var r:float=4+17*drive
			for j in range(8):
				var a:float=float(j)*TAU/8.0
				var axis:=Vector2(cos(a),sin(a))
				var next_axis:=Vector2(cos(a+TAU/8),sin(a+TAU/8))
				fx_line(im,c,c+axis*r,1.2,Color("#f4f9ed",fade))
				for k in range(1,4):
					var f:float=float(k)/3.0
					if drive>=f*.6:
						var q:=c+axis*r*f
						var v:=c+next_axis*r*f
						var mid:=q.lerp(v,.5).lerp(c,.13)
						fx_line(im,q,mid,1.0,Color("#c3d4bf",fade))
						fx_line(im,mid,v,1.0,Color("#f9fff1",fade))
		"eos_346":
			# Double Rake: two sequential serrated arcs, offset in time.
			for j in range(2):
				var u:float=clampf(drive*1.45-float(j)*.35,0.0,1.0)
				var q:=Vector2(17+10*u,21+float(j)*6)
				var a:float=-1.9+1.5*u
				fight_arc(im,q,13.0,a,PI*.88,Color("#ecf6bc",fade),Color("#668744",fade),3.4)
				for k in range(3):
					var theta:float=a+float(k)*.65
					var v:=q+Vector2(cos(theta),sin(theta))*13
					fx_line(im,v,v+Vector2(cos(theta),sin(theta))*3,1.1,Color("#9ab962",fade))
		"lib_fairy_1":
			# Glimmer Shot: a compact enchanted star comet, not a psychic orb.
			var q:=Vector2(9+29*drive,24)
			for j in range(5):
				var f:float=float(j+1)/5.0
				var v:=q-Vector2(15*f*fade,sin(t*TAU+float(j)*1.5)*4*f)
				var tint:=Color("#f6b8dc",fade*(1.0-f*.6)) if j%2==0 else Color("#ffe6a4",fade*(1.0-f*.6))
				fairy_star(im,v,3.1-1.8*f,tint)
			var radius:float=4.0+3.0*pulse
			for j in range(5):
				var a:float=-PI*.5+float(j)*TAU/5.0+t*.7
				var axis:=Vector2(cos(a),sin(a))
				var normal:=Vector2(-axis.y,axis.x)
				fx_line(im,q+normal*1.8,q+axis*radius,2.3,Color("#af73c7",fade))
				fx_line(im,q-normal*1.3,q+axis*radius,1.3,Color("#ffd9ed",fade))
			fx_disc(im,q,2.5,Color("#fff6cf",fade))
			if t>=peak:
				for j in range(7):
					var a:float=float(j)*TAU/7.0+t*.5
					var v:=q+Vector2(cos(a),sin(a))*(radius+8*(1.0-fade))
					fairy_star(im,v,1.5+float(j%2)*.5,Color("#ffe9b5" if j%2==0 else "#ffc3e8",fade))
		"lib_fairy_2":
			# Pixie Halo: concentric ribbons of gold and pink, orbiting lights and a radial bloom.
			var c:=Vector2(24,24)
			var radius:float=5.0+13.0*drive
			for j in range(2):
				var phase:float=t*TAU+float(j)*PI
				var prev:=c+Vector2(cos(phase)*radius,sin(phase)*radius*.64)
				for k in range(1,29):
					var a:float=phase+float(k)*TAU/28.0
					var q:=c+Vector2(cos(a)*radius,sin(a)*radius*.64+sin(a*2.0+float(j)*PI)*3)
					var tint:=Color("#ffe4a7",fade) if j==0 else Color("#ffc3e9",fade)
					fx_line(im,prev,q,2.4,Color("#a776c9",fade*.78))
					fx_line(im,prev,q,1.1,tint)
					prev=q
			for j in range(8):
				var a:float=float(j)*TAU/8.0-t*TAU
				var v:=c+Vector2(cos(a),sin(a))*(radius+2)
				fairy_star(im,v,1.8+float(j%3)*.6,Color("#fff2ba" if j%2==0 else "#ffd0ee",fade))
			if t>=peak:
				for j in range(8):
					var a:float=float(j)*TAU/8.0
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,c+axis*(radius*.40),c+axis*(radius+4*(1.0-fade)),.9,Color("#fff0d1",fade*.65))
		"lib_fairy_3":
			# Moon Prism: crescent moon gathers light into four orthogonal beams.
			var c:=Vector2(24,24)
			var charge:float=clampf(t/maxf(peak,.01),0.0,1.0)
			var radius:float=5.0+3.0*charge
			for y in range(48):
				for x in range(48):
					var v:=Vector2(x,y)-c
					if v.length()<=radius and (v-Vector2(3,-2)).length()>radius*.80:
						im.set_pixel(x,y,Color("#ffe6b5",fade) if v.length()>radius-1.2 else Color("#fff9ef",fade))
			for j in range(4):
				var a:float=float(j)*PI*.5
				var axis:=Vector2(cos(a),sin(a))
				var normal:=Vector2(-axis.y,axis.x)
				var extent:float=radius+13*drive
				var tip:=c+axis*extent
				if t>=peak:
					fx_line(im,c+axis*radius,tip,4.2,Color("#ad88ed",fade))
					fx_line(im,c+axis*radius,tip,2.4,Color("#eac4ff",fade))
					fx_line(im,c+axis*radius,tip,1.0,Color("#fff8ea",fade))
					fairy_star(im,tip,2.5,Color("#ffe9b1",fade))
					for k in range(2):
						var v:=c+axis*(radius+5+float(k)*5)+normal*sin(t*TAU+float(k))*3
						fx_disc(im,v,1.2,Color("#ffc4df",fade))
				else:
					var v:=c+axis*(18-9*charge)
					fairy_star(im,v,2.0,Color("#d8b8ff",fade))
		"eos_341":
			# Drake Wrath: a concentrated ancestral flame flares into pointed scales.
			var c:=Vector2(24,25)
			var r:float=4.0+10.0*drive
			fx_disc(im,c,r,Color("#4b3389",fade))
			fx_disc(im,c-Vector2(0,2),r*.65,Color("#d78cec",fade))
			fx_disc(im,c-Vector2(0,3),r*.32,Color("#ffdb99",fade))
			for j in range(7):
				var a:float=float(j)*TAU/7.0+t*.8
				var axis:=Vector2(cos(a),sin(a))
				var q:=c+axis*r*.78
				fire_lobe(im,q,2.2+2.2*pulse,t+float(j)*.13,Color("#ffca89",fade),Color("#8c58ca",fade))
				if t>=peak:fx_line(im,q,c+axis*(r+7*(1.0-fade)),1.3,Color("#eac0ff",fade))
		"eos_498":
			# Dragon Rush: forward draconic head and horn silhouettes with a pressure wake.
			var q:=Vector2(10+23*drive,24)
			fx_line(im,q-Vector2(19*fade,0),q,8.0,Color("#493788",fade))
			fx_line(im,q-Vector2(14*fade,0),q,4.0,Color("#85d9d9",fade))
			for side in [-1,1]:
				var sy:float=float(side)
				var brow:=q+Vector2(-3,sy*4)
				var horn:=q+Vector2(-10,sy*11)
				fx_line(im,brow,horn,3.6,Color("#7354b6",fade))
				fx_line(im,brow,horn,1.6,Color("#b9eef0",fade))
				fx_line(im,brow,q+Vector2(9,sy*2),3.8,Color("#a898f0",fade))
				fx_line(im,q+Vector2(1,sy*3),q+Vector2(5,sy*2),1.2,Color("#fff1b1",fade))
			fx_line(im,q+Vector2(2,0),q+Vector2(10,0),2.2,Color("#dcffff",fade))
			if t>=peak:
				for j in range(7):
					var a:float=float(j)*TAU/7.0
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,q+axis*8,q+axis*(12+6*(1.0-fade)),1.5,Color("#a6e7e7",fade))
		"eos_343":
			# Drake Rhythm: ceremonial twin serpentine auras orbit the caster.
			var c:=Vector2(24,24)
			for j in range(2):
				var prev:=c
				for k in range(1,26):
					var f:float=float(k)/25.0
					var a:float=f*TAU*1.15+t*TAU+float(j)*PI
					var r:float=(6+11*drive)*(.25+.75*f)
					var q:=c+Vector2(cos(a)*r,sin(a)*r*.9)
					fx_line(im,prev,q,3.0,Color("#6144a0",fade))
					fx_line(im,prev,q,1.2,Color("#8ce9db" if j==0 else "#d2b9ff",fade))
					prev=q
				var a:float=t*TAU+float(j)*PI+TAU*1.15
				var axis:=Vector2(-sin(a),cos(a))
				var normal:=Vector2(-axis.y,axis.x)
				fx_line(im,prev-normal*3,prev+axis*4,2.0,Color("#f1dcaa",fade))
				fx_line(im,prev+normal*3,prev+axis*4,2.0,Color("#f1dcaa",fade))
			for j in range(5):
				var a:float=float(j)*TAU/5.0-t*2.0
				fairy_star(im,c+Vector2(cos(a),sin(a))*(8+10*drive),1.5,Color("#ffdd9c",fade))
		"eos_091":
			# Draconic Frenzy: alternating savage crossing slashes and red-violet flares.
			var c:=Vector2(24,24)
			for j in range(3):
				var a:float=-2.5+float(j)*1.6+drive*1.4
				var q:=c+Vector2(float(j-1)*3,float(j%2)*3)
				fight_arc(im,q,13.0+float(j)*2,a,1.8,Color("#f9b0a1",fade),Color("#703a90",fade),4.4)
				var axis:=Vector2(cos(a+1.8),sin(a+1.8))
				fire_lobe(im,q+axis*13,2.5,t+float(j)*.23,Color("#ffd1a1",fade),Color("#ab4d96",fade))
			if t>=peak:
				for j in range(8):
					var a:float=float(j)*TAU/8.0+t
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,c+axis*7,c+axis*(15+5*(1.0-fade)),1.4,Color("#e4a0bb",fade))
		"eos_162":
			# Twister: narrowing draconic tornado with rising motes and a visible funnel.
			for j in range(6):
				var y:float=8.0+float(j)*6.0
				var r:float=(16.0-float(j)*2.4)*(.48+.52*drive)
				var prev:=Vector2(24+r,y)
				for k in range(1,21):
					var a:float=float(k)*TAU/20.0+t*TAU+float(j)*.7
					var q:=Vector2(24+cos(a)*r,y+sin(a)*2.5)
					fx_line(im,prev,q,2.3,Color("#5d4b9e",fade*.8))
					fx_line(im,prev,q,1.0,Color("#a0e7dd",fade))
					prev=q
			for j in range(7):
				var f:float=fposmod(t*1.2+float(j)*.15,1.0)
				var q:=Vector2(24+sin(f*TAU*2+float(j))*((1.0-f)*5+f*15),40-33*f)
				fx_disc(im,q,1.4,Color("#d3c1ff",fade))
		"eos_435":
			# Spacial Rend: a dark spatial tear with luminous edges and broken shards.
			var c:=Vector2(24,24)
			var span:float=4+17*drive
			var prev:=c-Vector2(span,span*.83)
			for j in range(1,9):
				var f:float=float(j)/8.0
				var q:=c+Vector2(lerpf(-span,span,f),lerpf(-span*.83,span*.83,f)+sin(float(j)*2.6)*2.3)
				fx_line(im,prev,q,6.5,Color("#8263bc",fade))
				fx_line(im,prev,q,4.2,Color("#291b46",fade))
				fx_line(im,prev-Vector2(0,2),q-Vector2(0,2),1.2,Color("#c2f5ed",fade))
				prev=q
			if t>=peak:
				for j in range(7):
					var f:float=float(j)/6.0
					var q:=c+Vector2(lerpf(-14,14,f),lerpf(-12,12,f))
					var sy:float=-1.0 if j%2==0 else 1.0
					var v:=q+Vector2(-sy*5,sy*(5+8*(1.0-fade)))
					fx_line(im,q,v,1.5,Color("#e3c8ff",fade))
					fx_line(im,v,v+Vector2(sy*3,sy*2),1.0,Color("#9be6df",fade))
		"lib_dragon_1":
			# Drake Claw: a fan of four short talons distinct from Dragon Claw.
			var c:=Vector2(19,24)
			for j in range(4):
				var a:float=-1.2+float(j)*.72+drive*.5
				var axis:=Vector2(cos(a),sin(a))
				var normal:=Vector2(-axis.y,axis.x)
				var root:=c+axis*4
				var elbow:=c+axis*(8+9*drive)+normal*3
				var tip:=c+axis*(11+10*drive)
				fx_line(im,root,elbow,3.7,Color("#514084",fade))
				fx_line(im,elbow,tip,2.7,Color("#514084",fade))
				fx_line(im,root,elbow,1.6,Color("#aee6cb",fade))
				fx_line(im,elbow,tip,1.0,Color("#e8fff0",fade))
		"lib_dragon_2":
			# Drake Breath: an expanding cyan-violet cone of forked flame.
			var head:=Vector2(8+30*drive,24)
			for j in range(9):
				var f:float=float(j)/8.0
				var q:=Vector2(lerpf(5.0,head.x,f),24+sin(f*TAU*2-t*TAU)*(2+5*f))
				var r:float=2.0+3.5*f
				fire_lobe(im,q,r,t+float(j)*.11,Color("#c0fff0",fade),Color("#7255bd",fade))
			if t>=peak:
				for j in range(5):
					var a:float=-1.0+float(j)*.5
					var q:=head+Vector2(cos(a),sin(a))*(4+7*(1.0-fade))
					fx_disc(im,q,1.7,Color("#d2b6ff",fade))
		"lib_dragon_3":
			# Orbit Fang: paired curved fangs spiral inward and snap shut at contact.
			var c:=Vector2(24,24)
			var r:float=17.0-11.0*drive+5*(1.0-fade)
			for j in range(2):
				var a:float=t*TAU*.8+float(j)*PI
				var axis:=Vector2(cos(a),sin(a))
				var normal:=Vector2(-axis.y,axis.x)
				var q:=c+axis*r
				fight_arc(im,c,r,a-1.25,1.25,Color("#b6e6df",fade),Color("#6550a4",fade),2.5)
				fx_line(im,q+normal*4,q-axis*5,3.4,Color("#574180",fade))
				fx_line(im,q-normal*3,q-axis*5,2.0,Color("#e7e5ba",fade))
				fx_line(im,q+normal*4,q-axis*5,1.5,Color("#fff2d1",fade))
			if t>=peak:
				fairy_star(im,c,3+3*pulse,Color("#c9fff0",fade))
		"eos_092","eos_204","eos_206","eos_303","eos_222","eos_210","lib_fighting_2":
			# Side-view articulated kick: thigh, shin, ankle, boot and sole.
			# Individual hit confirmation remains in the existing combat timeline.
			var angle:float=0.0
			var center:=Vector2(21,24)
			var reach:float=1.0
			var weight:float=1.0
			var tint:=Color("#ffe9b7",fade)
			var shade:=Color("#9c533f",fade)
			match id:
				"eos_092":
					angle=.43;center.y+=8.0;reach=.88
				"eos_204":
					angle=-.22;center.y-=7*sin(drive*PI);reach=1.08
				"eos_206":
					angle=-.68;center.y-=5;reach=1.15;weight=1.18
				"eos_303":
					angle=-1.0+1.9*drive;reach=1.02
				"eos_222":
					angle=-.18;reach=.92
				"eos_210":
					angle=.05;reach=.94;weight=.94
				"lib_fighting_2":
					angle=-1.45+2.2*drive;tint=Color("#f7d8a2",fade);shade=Color("#a85d50",fade)
			var bend:float=.28+.72*drive
			var recoil:float=(1.0-fade)*.35
			var hip:=center+Vector2(-12,-9).rotated(angle)
			var knee:=center+Vector2(-5,-5-4*(1.0-bend)).rotated(angle)
			var ankle:=center+Vector2(8*reach*(bend-recoil),5-7*(1.0-bend)).rotated(angle)
			var toe:=ankle+Vector2(6.4*reach,0).rotated(angle)
			var outline:=Color("#573c3a",fade)
			fx_line(im,hip,knee,5.7*weight,outline)
			fx_line(im,knee,ankle,5.2*weight,outline)
			fx_line(im,ankle,toe,6.3*weight,outline)
			fx_line(im,hip,knee,3.6*weight,shade)
			fx_line(im,knee,ankle,3.2*weight,tint)
			fx_line(im,ankle,toe,4.0*weight,Color("#fff4d8",fade))
			var sole:=Vector2(0,2.3*weight).rotated(angle)
			fx_line(im,ankle+sole,toe+sole,1.1,shade)
			if id in ["eos_303","lib_fighting_2"]:
				fight_arc(im,center,17.0,-1.8+angle,1.9,Color("#ffe8b0",fade),Color("#bd784d",fade),2.5)
			elif id in ["eos_204","eos_206"]:
				for j in range(3):
					var q:=hip+Vector2(-3-float(j)*3,3+float(j)*4)
					fx_line(im,q-Vector2(5,4),q,1.3,Color("#f2ce9c",fade))
			elif id in ["eos_222","eos_210"]:
				# Extra speed marks denote the technique, not additional damage events.
				for j in range(2 if id=="eos_222" else 3):
					var q:=ankle+Vector2(-5-float(j)*3,4+float(j)*3).rotated(angle)
					fx_line(im,q-Vector2(5,0).rotated(angle),q,1.1,Color("#fbdbae",fade))
			else:
				fx_line(im,hip+Vector2(-6,6),ankle+Vector2(-3,6),1.2,Color("#f4cf9d",fade))
			if t>=peak:
				var axis:=Vector2(cos(angle),sin(angle))
				var normal:=Vector2(-axis.y,axis.x)
				for j in range(5):
					var a:float=float(j-2)*.46
					var d:=axis.rotated(a)
					var q:=toe+d*(3+7*(1.0-fade))
					fx_line(im,toe+d*2,q,1.4,Color("#fff0b5",fade))
				if id=="eos_092":fx_line(im,toe-normal*2,toe+axis*4-normal*2,1.0,Color("#ffe3a0",fade))
		"eos_136":
			# Sky Uppercut: vertical rising fist and upward pressure wake.
			var q:=Vector2(24,36-24*drive)
			for j in range(3):
				var x:float=float(j-1)*5.0
				fx_line(im,q+Vector2(x,5),q+Vector2(x,12+7*fade),1.8,Color("#c88153",fade))
				fx_line(im,q+Vector2(x,6),q+Vector2(x,10+5*fade),.8,Color("#fff0b8",fade))
			fight_fist(im,q,-PI*.5,7.1,Color("#ffe7b9",fade),Color("#8e4939",fade))
			if t>=peak:
				for j in range(5):
					var a:float=-PI+float(j)*PI/4.0
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,q+axis*7,q+axis*(11+7*(1.0-fade)),1.6,Color("#fff2bb",fade))
		"eos_075":
			# Focused Fist: charge motes converge onto a single heavy punch.
			var q:=Vector2(12+20*drive,24)
			for j in range(6):
				var a:float=float(j)*TAU/6.0+t*.8
				var axis:=Vector2(cos(a),sin(a))
				var r:float=17-9*drive
				fx_line(im,q+axis*r,q+axis*(r-4),1.4,Color("#e8b45b",fade))
			fight_fist(im,q,0.0,8.0,Color("#ffdda1",fade),Color("#9b5533",fade))
			if t>=peak:
				var radius:float=8+9*(1.0-fade)
				fx_disc(im,q,radius,Color("#ffe9a1",fade),radius-1.4)
				for j in range(8):
					var a:float=float(j)*TAU/8.0
					var axis:=Vector2(cos(a),sin(a))
					fx_line(im,q+axis*radius,q+axis*(radius+4),1.5,Color("#ffce72",fade))
		"eos_300":
			# Mach Punch: compact high-speed fist and three horizontal motion streaks.
			var q:=Vector2(8+29*drive,24)
			for j in range(3):
				var y:float=float(j-1)*4
				fx_line(im,q+Vector2(-18*fade,y),q+Vector2(-5,y),1.2,Color("#e8b490",fade))
				fx_line(im,q+Vector2(-12*fade,y),q+Vector2(-5,y),.8,Color("#fff4d2",fade))
			fight_fist(im,q,0.0,5.0,Color("#fff0ce",fade),Color("#b3694c",fade))
			if t>=peak:
				fairy_star(im,q+Vector2(5,0),2.5+2*pulse,Color("#fff6c6",fade))
		"eos_246":
			# Dynamicpunch: heavy twisting fist and irregular, off-axis shock fragments.
			var q:=Vector2(12+20*drive,24)
			var a:float=-.45+.65*drive
			var axis:=Vector2(cos(a),sin(a))
			for j in range(3):
				var v:=q-axis*(6+float(j)*4)
				fight_arc(im,v,4.0+float(j),a+PI*.5,PI,Color("#ffc7a1",fade*.7),Color("#a84b50",fade*.6),1.6)
			fight_fist(im,q,a,8.2,Color("#ffe1ba",fade),Color("#8f4148",fade))
			if t>=peak:
				for j in range(9):
					var theta:float=float(j)*TAU/9.0+sin(float(j)*3.1)*.18
					var d:=Vector2(cos(theta),sin(theta))
					var radius:float=8+10*(1.0-fade)+float(j%3)*2
					fx_line(im,q+d*7,q+d*radius,1.8,Color("#f9b77a",fade))
					fx_disc(im,q+d*(radius+2),1.3,Color("#ef9d8d",fade))
		"eos_430":
			# Hammer Arm: downward hammerfist and flattened floor shockwave.
			var pivot:=Vector2(13,15)
			var angle:float=-1.5+2.7*drive
			var axis:=Vector2(cos(angle),sin(angle))
			var q:=pivot+axis*18
			fx_line(im,pivot,q,5.0,Color("#7d4537",fade))
			fx_line(im,pivot,q,2.9,Color("#e9b27e",fade))
			fight_fist(im,q,angle,7.5,Color("#ffebbd",fade),Color("#854833",fade))
			fight_arc(im,pivot,19.0,angle-1.0,.9,Color("#ffdf9d",fade),Color("#a26944",fade),2.4)
			if t>=peak:
				for j in range(7):
					var a:float=PI+float(j)*PI/6.0
					var d:=Vector2(cos(a),sin(a)*.62)
					fx_line(im,q+d*6,q+d*(10+9*(1.0-fade)),1.6,Color("#ffdc96",fade))
		"eos_440":
			# Close Combat: alternating left/right fists in an authored rapid combination.
			# Cosmetic cadence never produces extra combat events.
			var c:=Vector2(25,24)
			for j in range(3):
				var phase:float=fposmod(t*2.4+float(j)*.34,1.0)
				var side:float=-1.0 if j%2==0 else 1.0
				var q:=Vector2(10+23*sin(phase*PI),24+side*(6-3*sin(phase*PI)))
				var alpha:float=fade*(.4+.6*sin(phase*PI))
				fx_line(im,q-Vector2(9,side*2),q,1.3,Color("#f0b08c",alpha))
				fight_fist(im,q,-side*.24,4.5+sin(phase*PI),Color("#ffe8bd",alpha),Color("#9e5946",alpha))
			if t>=peak:
				for j in range(6):
					var a:float=float(j)*TAU/6.0+t
					var d:=Vector2(cos(a),sin(a))
					fx_line(im,c+d*8,c+d*(13+6*(1.0-fade)),1.2,Color("#fff0c5",fade))
		"eos_500":
			# Drain Punch: solid contact followed by returning green life-energy droplets.
			var q:=Vector2(12+21*drive,24)
			fight_fist(im,q,0.0,7.0,Color("#e9f5ae",fade),Color("#568052",fade))
			if t>=peak:
				var travel:float=smoothstep(peak,1.0,t)
				for j in range(6):
					var f:float=clampf(travel*1.25-float(j)*.09,0.0,1.0)
					var v:=Vector2(37-29*f,24+sin(f*TAU+float(j)*1.5)*7)
					fx_line(im,v+Vector2(4,0),v,1.5,Color("#75b76b",fade))
					fx_disc(im,v,2.1,Color("#d9ffb0",fade))
				fx_disc(im,Vector2(8,24),2.0+3.0*travel,Color("#baf49a",fade))
		"eos_508":
			# Aura Sphere: compact blue orb with a layered white core and curved aura filaments.
			var q:=Vector2(10+25*drive,24)
			var radius:float=4.8+3.2*pulse
			fx_line(im,q-Vector2(12*fade,0),q,3.0,Color("#456fce",fade))
			fx_disc(im,q,radius+1.0,Color("#3158ac",fade))
			fx_disc(im,q,radius-1.0,Color("#79c9f6",fade))
			fx_disc(im,q-Vector2(1,1),radius*.48,Color("#f2ffff",fade))
			for j in range(3):
				var a:float=t*TAU+float(j)*TAU/3.0
				fight_arc(im,q,radius+3.0,a,1.4,Color("#c4f3ff",fade),Color("#547acb",fade),1.4)
			if t>=peak:
				for j in range(6):
					var a:float=float(j)*TAU/6.0
					var d:=Vector2(cos(a),sin(a))
					fx_disc(im,q+d*(radius+7*(1.0-fade)),1.6,Color("#b5eeff",fade))
		"eos_454":
			# Focus Blast: large golden compressed energy projectile with turbulence and burst.
			var q:=Vector2(10+23*drive,24)
			var radius:float=6.0+4.5*pulse
			fx_line(im,q-Vector2(15*fade,0),q,5.2,Color("#c17a4d",fade))
			fx_disc(im,q,radius+1.0,Color("#a95d40",fade))
			fx_disc(im,q,radius-1.3,Color("#edaa62",fade))
			fx_disc(im,q-Vector2(1,1),radius*.55,Color("#fff3bc",fade))
			for j in range(5):
				var a:float=float(j)*TAU/5.0+t*1.5
				fight_arc(im,q,radius+2.5,a,.66,Color("#ffefb0",fade),Color("#bb7148",fade),1.6)
			if t>=peak:
				for j in range(9):
					var a:float=float(j)*TAU/9.0
					var d:=Vector2(cos(a),sin(a))
					fx_line(im,q+d*radius,q+d*(radius+8*(1.0-fade)),1.8,Color("#ffd190",fade))
		"eos_479":
			# Vacuum Wave: transparent compressed-air crescents with empty centers.
			for j in range(3):
				var f:float=clampf(drive*1.3-float(j)*.14,0.0,1.0)
				var q:=Vector2(9+24*f,24)
				var radius:float=5.5+float(j)*1.5+4*f
				fight_arc(im,q,radius,-PI*.52,PI*1.04,Color("#dffbff",fade),Color("#6298ac",fade),2.2)
				fight_arc(im,q,radius-2.3,-PI*.45,PI*.9,Color("#f3ffff",fade),Color("#a2d8e1",fade*.7),1.0)
			if t>=peak:
				for j in range(4):
					var q:=Vector2(33+4*(1.0-fade),16+float(j)*5)
					fx_line(im,q-Vector2(5,0),q,1.0,Color("#d2f5ff",fade))
		"eos_243":
			# Superpower: braced double-fist strike with a heavy radial pressure release.
			var c:=Vector2(24,24)
			for side in [-1,1]:
				var sy:float=float(side)
				var q:=c+Vector2(-8+12*drive,sy*(10-5*drive))
				fight_fist(im,q,-sy*.35,7.0,Color("#fff0c2",fade),Color("#a0503e",fade))
			if t>=peak:
				var radius:float=7+13*(1.0-fade)
				fx_disc(im,c,radius,Color("#e9a05c",fade),maxf(0.0,radius-2.0))
				for j in range(10):
					var a:float=float(j)*TAU/10.0
					var d:=Vector2(cos(a),sin(a))
					fx_line(im,c+d*8,c+d*(radius+3),1.7,Color("#ffde9e",fade))
		"eos_068","eos_090":
			# Karate Chop has a single open knife-hand; Cross Chop uses two crossed forearms.
			var cross:bool=id=="eos_090"
			var count:int=2 if cross else 1
			for j in range(count):
				var sy:float=-1.0 if j==0 else 1.0
				var angle:float=sy*(1.05-1.8*drive)
				var axis:=Vector2(cos(angle),sin(angle))
				var normal:=Vector2(-axis.y,axis.x)
				var q:=Vector2(15+10*drive,24+sy*(7-4*drive))
				var wrist:=q-axis*5
				var tip:=q+axis*8
				fx_line(im,wrist-axis*9,wrist,4.8,Color("#794738",fade))
				fx_line(im,wrist-axis*9,wrist,2.8,Color("#dfa575",fade))
				fx_line(im,wrist,tip,4.6,Color("#794738",fade))
				fx_line(im,wrist,tip,2.8,Color("#ffe0b6",fade))
				for k in range(4):
					var v:=q+normal*(float(k)-1.5)*1.3
					fx_line(im,v,v+axis*(6.0-float(k)*.55),1.1,Color("#fff0d0",fade))
				fx_line(im,q-axis*2,q-axis*2+normal*3.4,1.8,Color("#edbc89",fade))
				if t>=peak:
					fight_arc(im,q,9+6*(1.0-fade),angle-.8,1.6,Color("#ffe6b4",fade),Color("#b86a4b",fade),1.7)
		"lib_fighting_1","eos_531":
			# Palm Burst pushes straight forward; Wake Up Slap sweeps an open hand.
			var slap:bool=id=="eos_531"
			var a:float=(-1.2+2.2*drive) if slap else 0.0
			var axis:=Vector2(cos(a),sin(a))
			var normal:=Vector2(-axis.y,axis.x)
			var q:=Vector2(12+20*drive,24)
			fx_line(im,q-axis*13,q-axis*3,5.0,Color("#8f503f",fade))
			fx_disc(im,q,5.2,Color("#965642",fade))
			fx_disc(im,q,3.8,Color("#f6cfa1",fade))
			for j in range(4):
				var v:=q+normal*(float(j)-1.5)*2.1
				fx_line(im,v,v+axis*(7.0-float(j%3)),2.0,Color("#a5684c",fade))
				fx_line(im,v,v+axis*(6.0-float(j%3)),1.1,Color("#ffe9c1",fade))
			fx_line(im,q-axis*2,q-axis*3+normal*5,2.3,Color("#f6ce9f",fade))
			if t>=peak:
				if slap:
					fight_arc(im,q,11+7*(1.0-fade),a-1.0,2.0,Color("#fff1c6",fade),Color("#c0784c",fade),2.5)
				else:
					for j in range(3):
						fight_arc(im,q,6+float(j)*4+6*(1.0-fade),-1.2,2.4,Color("#ffe3a5",fade),Color("#b87845",fade),1.8)
		"lib_fighting_3":
			# Spirit Fist: spectral knuckles lead a concentrated violet-gold aura.
			var q:=Vector2(10+24*drive,24)
			for j in range(5):
				var v:=q-Vector2(3+float(j)*3,3*sin(t*TAU+float(j)))
				fx_disc(im,v,5.0-float(j)*.7,Color("#8960ab",fade*(.8-float(j)*.12)))
			fight_fist(im,q,0.0,7.0,Color("#fff2d6",fade),Color("#855baa",fade))
			fight_arc(im,q,11.0,t*TAU,PI*1.45,Color("#e6c4ff",fade),Color("#9473b5",fade),2.0)
			if t>=peak:
				for j in range(6):
					var a:float=float(j)*TAU/6.0
					var d:=Vector2(cos(a),sin(a))
					fairy_star(im,q+d*(10+7*(1.0-fade)),1.9,Color("#ffe7b3",fade))
		"eos_072","eos_029":
			# Brick Break splits a masonry slab; Stonebreaker shatters a rough boulder.
			var stone:bool=id=="eos_029"
			var c:=Vector2(29,27)
			var split:float=0.0 if t<peak else 8.0*(1.0-fade)
			for side in [-1,1]:
				var sy:float=float(side)
				var q:=c+Vector2(sy*(4+split),split*.25)
				if stone:
					mineral(im,q,6.0,sy*.6,Color("#d5c0a8",fade),Color("#726159",fade))
				else:
					fx_line(im,q-Vector2(4,0),q+Vector2(4,0),9.0,Color("#985c45",fade))
					fx_line(im,q-Vector2(3,-3),q+Vector2(3,-3),1.5,Color("#dbac82",fade))
					fx_line(im,q-Vector2(4,1),q+Vector2(4,1),1.0,Color("#633f39",fade))
			var hand:=Vector2(12+17*drive,12+10*drive)
			fight_fist(im,hand,.65,6.1,Color("#ffe5b7",fade),Color("#8c4e39",fade))
			if t>=peak:
				for j in range(8 if stone else 5):
					var a:float=float(j)*2.399
					var d:=Vector2(cos(a),sin(a))
					var q:=c+d*(6+12*(1.0-fade))
					earth_rock(im,q,2.0+float(j%2),Color("#cfb69a",fade),Color("#73564a",fade))
		"eos_077":
			# Reversal: the pressure trail bends back into a reverse punch.
			var c:=Vector2(24,24)
			var a:float=-PI*.6+drive*PI*1.3
			fight_arc(im,c,15.0,a,-PI*1.25,Color("#f5dfa8",fade),Color("#b46c4c",fade),3.0)
			var q:=Vector2(37-24*drive,24)
			fight_fist(im,q,PI,6.2,Color("#ffe6b8",fade),Color("#99513e",fade))
			if t>=peak:
				fairy_star(im,q-Vector2(5,0),3+3*pulse,Color("#fff0b2",fade))
		"eos_116":
			# Submission: two gripping hands rotate around the target and tighten.
			var c:=Vector2(24,24)
			var a:float=t*TAU*.7
			var radius:float=14-7*drive
			for j in range(2):
				var angle:float=a+float(j)*PI
				var axis:=Vector2(cos(angle),sin(angle))
				var q:=c+axis*radius
				fight_fist(im,q,angle+PI,5.3,Color("#ffe3b7",fade),Color("#9e5946",fade))
				fight_arc(im,c,radius+3,angle-.9,1.0,Color("#f5d29e",fade),Color("#b07652",fade),2.1)
			if t>=peak:
				fx_disc(im,c,4+5*(1.0-fade),Color("#f3c288",fade),3+5*(1.0-fade))
		"eos_265":
			# Mighty Stance: symmetrical rising strength aura around the caster.
			var c:=Vector2(24,28)
			for side in [-1,1]:
				var sy:float=float(side)
				for j in range(3):
					var q:=c+Vector2(sy*(6+float(j)*4),5-float(j)*3)
					var v:=q-Vector2(0,5+16*drive)
					fx_line(im,q,v,2.7,Color("#ad6849",fade))
					fx_line(im,q,v,1.2,Color("#ffe3a0",fade))
					fx_line(im,v,v+Vector2(-3,4),1.3,Color("#ffecb5",fade))
					fx_line(im,v,v+Vector2(3,4),1.3,Color("#ffecb5",fade))
			fight_arc(im,c,8+9*drive,0,PI,Color("#ffe7a8",fade),Color("#bc8554",fade),2.2)
		"eos_305":
			# Deflect: an angled guard plane with a brief glint, not a damage hit.
			var c:=Vector2(24,24)
			var a:float=-.65+.2*drive
			var axis:=Vector2(cos(a),sin(a))
			var normal:=Vector2(-axis.y,axis.x)
			var radius:float=8+7*drive
			fx_line(im,c-normal*radius,c+normal*radius,4.2,Color("#5981aa",fade))
			fx_line(im,c-normal*radius,c+normal*radius,1.8,Color("#dff7ff",fade))
			fight_arc(im,c,radius,-1.0,2.0,Color("#e5f5ff",fade),Color("#84a3c8",fade),1.6)
			var q:=c+normal*(radius*sin(t*PI))
			fairy_star(im,q,2.1+2.2*pulse,Color("#ffffff",fade))
		"eos_051","eos_340":
			# Retaliation is a measured return guard; Vengeance stores a harsher red aura.
			var revenge:bool=id=="eos_340"
			var c:=Vector2(24,24)
			var outer:=Color("#a04747",fade) if revenge else Color("#9e704e",fade)
			var inner:=Color("#ffc098",fade) if revenge else Color("#fff0bd",fade)
			for j in range(2 if revenge else 1):
				var r:float=15.0-7.0*drive+float(j)*4
				fight_arc(im,c,r,PI*.5+t*.4,PI,inner,outer,2.5)
				fight_arc(im,c,r,PI*1.5+t*.4,PI,inner,outer,1.5)
			for j in range(6 if revenge else 4):
				var a:float=float(j)*TAU/float(6 if revenge else 4)
				var axis:=Vector2(cos(a),sin(a))
				var q:=c+axis*(5+12*(1.0-drive))
				fx_line(im,q,q-axis*4,1.6,inner)
			if t>=peak:
				fx_disc(im,c,3+4*pulse,outer)
		"eos_170":
			# Seismic Grip: lifting hands, overhead arc and downward landing pressure.
			var c:=Vector2(24,35-22*sin(drive*PI))
			for side in [-1,1]:
				var sy:float=float(side)
				fight_fist(im,c+Vector2(sy*8,0),-PI*.5 if drive<.5 else PI*.5,5.0,Color("#ffe3bc",fade),Color("#995c46",fade))
				fx_line(im,c+Vector2(sy*8,6),c+Vector2(sy*8,12),1.4,Color("#edc498",fade))
			if t>=peak:
				for j in range(8):
					var a:float=float(j)*TAU/8.0
					var axis:=Vector2(cos(a),sin(a)*.4)
					fx_line(im,c+axis*5,c+axis*(10+10*(1.0-fade)),1.5,Color("#ffe8b6",fade))
		"eos_007":
			# Redirecting Grip: opposing hand silhouettes trace a curved redirection.
			var c:=Vector2(24,24)
			var a:float=-1.0+2.5*drive
			for j in range(2):
				var theta:float=a+float(j)*PI
				var axis:=Vector2(cos(theta),sin(theta))
				var q:=c+axis*10
				fight_fist(im,q,theta+PI,4.8,Color("#f6dcb0",fade),Color("#94604a",fade))
				fight_arc(im,c,15,theta-.75,1.25,Color("#fcebc3",fade),Color("#bd865f",fade),1.8)
		"lib_electric_1":
			# Static Fang: compact paired jaws with thin static sparks across the bite.
			var c:=Vector2(18+12*drive,24)
			var gap:float=9-7*drive+5*(1.0-fade)
			for side in [-1,1]:
				var sy:float=float(side)
				var prev:=c+Vector2(-9,sy*(gap+3))
				for j in range(4):
					var q:=c+Vector2(-9+float(j)*6,sy*(gap+absf(float(j)-1.5)*2))
					fx_line(im,prev,q,3.3,Color("#4769aa",fade))
					fx_line(im,prev,q,1.5,Color("#a5e8ff",fade))
					fx_line(im,q,q-Vector2(0,sy*(5 if j in [0,3] else 3)),1.6,Color("#fff3b0",fade))
					prev=q
			if t>=peak:
				fx_line(im,c-Vector2(5,3),c+Vector2(1,2),1.5,Color("#b1f2ff",fade))
				fx_line(im,c+Vector2(1,2),c+Vector2(6,-4),1.0,Color("#fffdd3",fade))
		"lib_electric_2":
			# Arc Current: a continuous sinuous electrical filament with alternating forks.
			var prev:=Vector2(4,24)
			for j in range(1,12):
				var f:float=float(j)/11.0
				var q:=Vector2(4+39*f*drive,24+sin(f*TAU*1.5-t*TAU)*6+float(posmod(j*7+frame*3,5)-2))
				fx_line(im,prev,q,3.0,Color("#4a6dce",fade))
				fx_line(im,prev,q,1.6,Color("#83dcff",fade))
				fx_line(im,prev,q,.7,Color("#fffbd1",fade))
				if j%3==0:
					var v:=q+Vector2(-2,7 if j%2==0 else -7)
					fx_line(im,q,v,1.0,Color("#b7edff",fade))
				prev=q
		"lib_electric_3":
			# Storm Cross: four bolts extend along cardinal directions.
			var c:=Vector2(24,24)
			for j in range(4):
				var a:float=float(j)*PI*.5
				var axis:=Vector2(cos(a),sin(a))
				var normal:=Vector2(-axis.y,axis.x)
				var prev:=c
				for k in range(1,6):
					var q:=c+axis*(4+15*drive)*float(k)/5.0+normal*float(posmod(k*7+j*3+frame*5,7)-3)
					fx_line(im,prev,q,3.0,Color("#496fd3",fade))
					fx_line(im,prev,q,1.6,Color("#83dcff",fade))
					fx_line(im,prev,q,.7,Color("#fff5ab",fade))
					prev=q
			fairy_star(im,c,3.0+3.0*pulse,Color("#fff7c3",fade))
		"eos_129":
			# Thunderbolt: a dense branched strike centered on the target.
			var c:=Vector2(24,24)
			for j in range(7):
				var a:float=float(j)*TAU/7.0
				var axis:=Vector2(cos(a),sin(a))
				var normal:=Vector2(-axis.y,axis.x)
				var prev:=c
				for k in range(1,5):
					var q:=c+axis*(6+14*drive)*float(k)/4.0+normal*float(posmod(k*13+j*7+frame*11,9)-4)
					fx_line(im,prev,q,3.2,Color("#516bd5",fade))
					fx_line(im,prev,q,1.8,Color("#8ce4ff",fade))
					fx_line(im,prev,q,.9,Color("#fff6aa",fade))
					if k==2:
						fx_line(im,q,q+axis*3+normal*5,1.0,Color("#b9f4ff",fade))
					prev=q
			fx_disc(im,c,2.7+2*pulse,Color("#fffdd6",fade))
		"eos_144":
			# Spark: compact sharp yellow static burst, smaller than Thunderbolt.
			var c:=Vector2(12+19*drive,24)
			for j in range(5):
				var a:float=float(j)*TAU/5.0+t*.8
				var axis:=Vector2(cos(a),sin(a))
				var normal:=Vector2(-axis.y,axis.x)
				var q:=c+axis*(5+5*drive)
				var v:=q+normal*3
				fx_line(im,c,q,2.1,Color("#e6bd4c",fade))
				fx_line(im,q,v,1.6,Color("#fff38e",fade))
				fx_line(im,v,v+axis*4,1.1,Color("#fffde0",fade))
			fx_disc(im,c,2.8,Color("#fff7ae",fade))
		"eos_189":
			# Shock Wave: three advancing electrified crescent fronts.
			for j in range(3):
				var f:float=clampf(drive*1.3-float(j)*.13,0.0,1.0)
				var c:=Vector2(8+27*f,24)
				var radius:float=6+float(j)*2+4*f
				var prev:=c+Vector2(cos(-PI*.48),sin(-PI*.48))*radius
				for k in range(1,13):
					var a:float=-PI*.48+float(k)*PI*.96/12.0
					var q:=c+Vector2(cos(a),sin(a))*(radius+float(posmod(k*3+frame+j,5)-2))
					fx_line(im,prev,q,2.4,Color("#577dc8",fade))
					fx_line(im,prev,q,1.1,Color("#dcfaff",fade))
					prev=q
		"eos_354":
			# Volt Tackle: charged forward wake around the existing actor dash.
			var q:=Vector2(10+25*drive,24)
			fx_line(im,q-Vector2(18*fade,0),q,7.0,Color("#6b7ed4",fade*.7))
			fx_line(im,q-Vector2(13*fade,0),q,3.6,Color("#ffe365",fade))
			fx_disc(im,q,6.0+2*pulse,Color("#fff2a0",fade))
			for j in range(6):
				var a:float=float(j)*TAU/6.0+t*2.0
				var axis:=Vector2(cos(a),sin(a))
				var normal:=Vector2(-axis.y,axis.x)
				var u:=q+axis*6
				var v:=q+axis*(10+5*pulse)+normal*float(posmod(j+frame,5)-2)
				fx_line(im,u,v,2.0,Color("#80daff",fade))
				fx_line(im,v,v+axis*3,1.1,Color("#fffde0",fade))
		"eos_489":
			# Charge Beam: narrow coherent electric beam with an emitter and traveling bands.
			var c:=Vector2(7,24)
			var q:=Vector2(9+32*drive,24)
			fx_disc(im,c,3.2+3*pulse,Color("#f4d65f",fade))
			fx_disc(im,c,2.0+1.5*pulse,Color("#fffce2",fade))
			fx_line(im,c,q,4.4,Color("#6385d9",fade))
			fx_line(im,c,q,2.4,Color("#b0eaff",fade))
			fx_line(im,c,q,1.1,Color("#fffad0",fade))
			for j in range(5):
				var f:float=fposmod(t*1.6+float(j)*.2,1.0)
				var v:=c.lerp(q,f)
				fx_line(im,v+Vector2(-2,-4),v+Vector2(2,4),1.2,Color("#ffe879",fade))
		"eos_521":
			# Discharge: expanding room-scale radial network with twelve branching arcs.
			var c:=Vector2(24,24)
			var radius:float=4+16*drive
			for j in range(12):
				var a:float=float(j)*TAU/12.0
				var axis:=Vector2(cos(a),sin(a))
				var normal:=Vector2(-axis.y,axis.x)
				var u:=c+axis*radius*.42
				var v:=c+axis*radius*.72+normal*float(posmod(j*7+frame*3,7)-3)
				var w:=c+axis*radius
				fx_line(im,u,v,2.6,Color("#4b7bc9",fade))
				fx_line(im,v,w,1.8,Color("#a2e6ff",fade))
				fx_line(im,v,v+normal*4,1.0,Color("#fff2ad",fade))
			fx_disc(im,c,radius,Color("#7bd6ff",fade*.65),maxf(0.0,radius-1.0))
		"eos_192":
			# Static Lock: three staggered electrical restraints close around the target.
			var c:=Vector2(24,24)
			for j in range(3):
				var radius:float=14-5*drive
				var y:float=float(j-1)*7
				var prev:=c+Vector2(radius,y)
				for k in range(1,25):
					var a:float=float(k)*TAU/24.0
					var q:=c+Vector2(cos(a)*radius,sin(a)*radius*.36+y)+Vector2(0,float(posmod(k*5+frame+j,3)-1))
					fx_line(im,prev,q,2.1,Color("#7288be",fade))
					fx_line(im,prev,q,.9,Color("#ffef98",fade))
					prev=q
		"eos_128":
			# Static Reservoir: energy streams converge into a capacitor-like core.
			var c:=Vector2(24,24)
			for j in range(8):
				var a:float=float(j)*TAU/8.0+t*.7
				var axis:=Vector2(cos(a),sin(a))
				var r:float=19-12*drive
				var q:=c+axis*r
				fx_line(im,q,q-axis*4,1.6,Color("#a8e6ff",fade))
				fx_line(im,q-axis*4,q-axis*6+Vector2(-axis.y,axis.x)*2,1.0,Color("#fff4a8",fade))
			fx_disc(im,c,3.0+5*drive,Color("#5478c6",fade))
			fx_disc(im,c,2.0+3*drive,Color("#fff2a0",fade))
		"eos_493":
			# Magnetic Lift: rising elliptical field rings and floating metallic motes.
			var c:=Vector2(24,35-14*drive)
			for j in range(3):
				var radius:float=8+float(j)*3
				var y:float=-float(j)*6
				var prev:=c+Vector2(radius,y)
				for k in range(1,25):
					var a:float=float(k)*TAU/24.0+t*.6
					var q:=c+Vector2(cos(a)*radius,sin(a)*radius*.35+y)
					fx_line(im,prev,q,1.9,Color("#718ac7",fade))
					fx_line(im,prev,q,.8,Color("#c8edff",fade))
					prev=q
			for j in range(6):
				var a:float=float(j)*TAU/6.0+t*TAU
				var q:=c+Vector2(cos(a)*15,sin(a)*5-8)
				fx_disc(im,q,1.4,Color("#e8f3ff",fade))
		"lib_fire_1":
			# Ember Dart: pointed ember projectile with a narrow incandescent tail.
			var q:=Vector2(9+28*drive,24)
			fx_line(im,q-Vector2(13*fade,0),q,3.2,Color("#bc5331",fade))
			fx_line(im,q-Vector2(9*fade,0),q,1.8,Color("#ffad4a",fade))
			fire_lobe(im,q,3.4+1.5*pulse,t,Color("#fff0a1",fade),Color("#ed7833",fade))
			if t>=peak:
				for j in range(5):
					var a:float=float(j)*TAU/5.0
					var d:=Vector2(cos(a),sin(a))
					fx_line(im,q+d*3,q+d*(6+6*(1.0-fade)),1.1,Color("#ffd080",fade))
		"lib_fire_2":
			# Blazing Torrent: turbulent wide continuous flame cone with bright central flow.
			var head:=Vector2(7+34*drive,24)
			for j in range(9):
				var f:float=float(j)/8.0
				var q:=Vector2(lerpf(5.0,head.x,f),24+sin(f*TAU*1.4-t*TAU)*4.0*f)
				fire_lobe(im,q,2.5+4.0*f,t+f,Color("#ffe89a",fade),Color("#c94b28",fade))
				fx_disc(im,q,1.5+2.0*f,Color("#fff1bd",fade))
			for j in range(6):
				var f:float=fposmod(t*1.4+float(j)*.18,1.0)
				var q:=Vector2(6+32*f*drive,24+sin(float(j)*2.4+t*3.0)*8*f)
				fx_disc(im,q,1.0+float(j%2)*.4,Color("#ffc66a",fade))
		"lib_fire_3":
			# Cinder Vortex: low circular cyclone with ash and glowing coals.
			var c:=Vector2(24,28)
			for j in range(11):
				var a:float=float(j)*TAU/11.0+t*TAU
				var r:float=7+11*drive
				var q:=c+Vector2(cos(a)*r,sin(a)*r*.54)
				fire_lobe(im,q,2.5+float(j%3)*.6,t+float(j)*.09,Color("#ffdb82",fade),Color("#c65430",fade))
				fx_disc(im,q-Vector2(0,5+float(j%3)*2),1.1,Color("#987467",fade*.65))
			fight_arc(im,c,13+6*drive,t*TAU,PI*1.6,Color("#ffcf77",fade),Color("#a84b32",fade),1.6)
		"eos_052":
			# Flame Wheel: rolling ring of fire and hot spokes around an empty hub.
			var c:=Vector2(13+20*drive,24)
			var radius:float=9+3*pulse
			for j in range(10):
				var a:float=float(j)*TAU/10.0+t*TAU*1.5
				var d:=Vector2(cos(a),sin(a))
				var q:=c+d*radius
				fire_lobe(im,q,2.6,t+float(j)*.10,Color("#fff1ad",fade),Color("#de592b",fade))
				if j%2==0:fx_line(im,c+d*4,q,1.2,Color("#ffb751",fade))
			fx_disc(im,c,radius-2,Color("#e67d38",fade),radius-3.5)
			if t>=peak:
				for j in range(5):
					var q:=c+Vector2(-6-float(j)*3,8+float(j%2)*3)
					fx_disc(im,q,1.2,Color("#ffca70",fade))
		"eos_149":
			# Sacred Fire: white-gold flame petals rise from a luminous central seal.
			var c:=Vector2(24,29)
			for j in range(5):
				var a:float=float(j)*TAU/5.0-PI*.5+t*.45
				var d:=Vector2(cos(a),sin(a))
				var q:=c+d*(4+10*drive)
				fire_lobe(im,q,3.1+1.4*pulse,t+float(j)*.2,Color("#fffdeb",fade),Color("#e9b249",fade))
				fx_line(im,c+d*4,q,1.0,Color("#fff4bc",fade))
			fx_disc(im,c,5+3*pulse,Color("#fff6cf",fade))
			if t>=peak:
				for j in range(6):
					var a:float=float(j)*TAU/6.0
					fairy_star(im,c+Vector2(cos(a),sin(a))*(12+7*(1.0-fade)),1.7,Color("#fff0b0",fade))
		"eos_230":
			# Heat Wave: broad hot air distortion ribbons without solid flame projectiles.
			for j in range(4):
				var prev:=Vector2(4,10+float(j)*9)
				for k in range(1,16):
					var f:float=float(k)/15.0
					var q:=Vector2(4+39*f,10+float(j)*9+sin(f*TAU*1.5-t*TAU+float(j)*.8)*(1.5+3*pulse))
					fx_line(im,prev,q,3.0,Color("#c75c39",fade*.52))
					fx_line(im,prev,q,1.1,Color("#ffdb98",fade))
					prev=q
			for j in range(8):
				var f:float=fposmod(t+float(j)*.13,1.0)
				var q:=Vector2(5+38*f,8+float(j%4)*10-3*pulse)
				fx_disc(im,q,1.0,Color("#f8b16d",fade*.7))
		"eos_291":
			# Fire Spin: two tightening flame bands encircle the target.
			var c:=Vector2(24,25)
			var r:float=17-9*drive
			for j in range(2):
				var prev:=c+Vector2(r,0)
				for k in range(1,24):
					var f:float=float(k)/23.0
					var a:float=f*TAU+t*TAU*1.2+float(j)*PI
					var q:=c+Vector2(cos(a)*r,sin(a)*r*.62+float(j*2-1)*5)
					fx_line(im,prev,q,2.2,Color("#e66731",fade))
					fx_line(im,prev,q,.9,Color("#ffdc8b",fade))
					if k%5==0:fire_lobe(im,q,2.4,t+f,Color("#ffe3a0",fade),Color("#cc4f29",fade))
					prev=q
		"eos_517":
			# Flare Blitz: intense forward fire wake; existing actor trajectory is unchanged.
			var q:=Vector2(10+25*drive,24)
			for j in range(6):
				var f:float=float(j)/5.0
				var v:=q-Vector2(17*f*fade,sin(f*TAU-t*TAU)*5*f)
				fire_lobe(im,v,6.0-3.3*f,t+f,Color("#fff0b2",fade),Color("#bd3e25",fade))
			fx_disc(im,q,3.7+2*pulse,Color("#fff8d4",fade))
			if t>=peak:
				for j in range(8):
					var a:float=float(j)*TAU/8.0
					var d:=Vector2(cos(a),sin(a))
					fx_line(im,q+d*5,q+d*(10+8*(1.0-fade)),1.6,Color("#ffb85e",fade))
		"eos_524":
			# Magma Storm: rising molten column with lava droplets and dark smoke.
			var c:=Vector2(24,36)
			for j in range(10):
				var f:float=float(j)/9.0
				var a:float=f*TAU*2.1+t*TAU
				var radius:float=5+10*f
				var q:=c+Vector2(cos(a)*radius,sin(a)*radius*.32-23*f*drive)
				fire_lobe(im,q,3.1+float(j%3)*.8,t+f,Color("#ffd775",fade),Color("#b54724",fade))
				if j%2==0:
					fx_disc(im,q+Vector2(sin(a)*4,-5),2.0,Color("#73534b",fade*.60))
			if t>=peak:
				for j in range(6):
					var a:float=float(j)*TAU/6.0+t
					var q:=c+Vector2(cos(a)*(9+8*(1.0-fade)),sin(a)*6-5)
					fx_disc(im,q,2.1,Color("#f49743",fade))
		"eos_223":
			# Sun Ritual: rising radiant solar disk with rays and orbiting warm motes.
			var c:=Vector2(24,27-9*drive)
			var radius:float=5+7*drive
			fx_disc(im,c,radius,Color("#e3a94f",fade))
			fx_disc(im,c,radius-1.5,Color("#ffd96e",fade))
			fx_disc(im,c,radius*.62,Color("#fff4bc",fade))
			for j in range(12):
				var a:float=float(j)*TAU/12.0+t*.35
				var d:=Vector2(cos(a),sin(a))
				fx_line(im,c+d*(radius+2),c+d*(radius+5+2*pulse),1.5,Color("#ffe5a0",fade))
			for j in range(5):
				var a:float=float(j)*TAU/5.0-t*2
				fairy_star(im,c+Vector2(cos(a),sin(a))*(radius+5),1.3,Color("#fff2b8",fade))
		"lib_water_1":
			# Foam Shot: compact frothy projectile, then expanding foam.
			var q:=Vector2(8+27*drive,24)
			for j in range(9):
				var a:float=float(j)*TAU/9.0
				var p:=q+Vector2(cos(a),sin(a))*(3+8*(1.0-fade))
				fx_disc(im,p,2.5+float(j%3)*.6,Color("#278fb8",fade))
				fx_disc(im,p-Vector2(0,1),1.8+float(j%3)*.5,Color("#e8ffff",fade))
			fx_line(im,q-Vector2(10*fade,0),q,2.0,Color("#7dd9ed",fade))
		"lib_water_2":
			# Pearl Torrent: connected stream of luminous pearl-like globes.
			for j in range(7):
				var f:float=float(j)/6.0
				var q:=Vector2(5+33*f*drive,24+sin(f*TAU-t*TAU)*3)
				var rad:float=2.1+2.8*f
				fx_disc(im,q,rad+1,Color("#2585bd",fade))
				fx_disc(im,q,rad,Color("#a3eefa",fade))
				fx_disc(im,q-Vector2(1,1),rad*.48,Color("#fff9ed",fade))
				if j>0:fx_line(im,q-Vector2(4*drive,0),q,1.1,Color("#b8f5ff",fade))
		"lib_water_3":
			# Surge Wall: upright curling sheet advancing toward the target.
			var x:float=7+27*drive
			for j in range(17):
				var f:float=float(j)/16.0
				var q:=Vector2(x+sin(f*PI)*5,40-30*f)
				fx_line(im,q-Vector2(5+3*f,0),q,3.2,Color("#1c6fa9",fade))
				fx_line(im,q-Vector2(2,0),q,1.9,Color("#65d8f4",fade))
				if j%3==0:fx_disc(im,q+Vector2(2,-2),2.1,Color("#e2ffff",fade))
			fx_disc(im,Vector2(x,39),9+6*pulse,Color("#a8edff",fade*.7),7+6*pulse)
		"eos_016":
			# Bubble: loose cluster of buoyant translucent bubbles.
			for j in range(6):
				var f:float=float(j)/5.0
				var q:=Vector2(8+28*drive-11*f,24+sin(float(j)*2.4+t*TAU)*8-4*t)
				var rad:float=3.2+float(j%3)
				fx_disc(im,q,rad,Color("#397fae",fade*.8))
				fx_disc(im,q,rad-.6,Color("#a1e8ff",fade),rad-1.8)
				fx_disc(im,q-Vector2(1.4,1.6),1.1,Color("#ffffff",fade))
				if t>=peak:fx_disc(im,q+Vector2(4,3),1.0,Color("#d5ffff",fade))
		"eos_032":
			# Whirlpool: inward spiraling water with an open dark eye.
			var c:=Vector2(24,29)
			for arm in range(3):
				var prev:=c
				for j in range(1,29):
					var f:float=float(j)/28.0
					var a:float=f*TAU*1.4+t*TAU*1.5+float(arm)*TAU/3.0
					var rad:float=3+f*(12+5*drive)
					var q:=c+Vector2(cos(a)*rad,sin(a)*rad*.55)
					if j>1:
						fx_line(im,prev,q,2.8,Color("#175f99",fade))
						fx_line(im,prev,q,1.2,Color("#8ce7fa",fade))
					if j%7==0:fx_disc(im,q,1.4,Color("#f0ffff",fade))
					prev=q
		"eos_044":
			# Octazooka: opaque indigo ink glob, then irregular splatter.
			var q:=Vector2(9+26*drive,24)
			fx_line(im,q-Vector2(13*fade,0),q,4.1,Color("#34354e",fade))
			fx_disc(im,q,6+2*pulse,Color("#24243b",fade))
			fx_disc(im,q-Vector2(1,2),3.4,Color("#8788ac",fade))
			if t>=peak:
				for j in range(10):
					var a:float=float(j)*TAU/10.0
					var d:=Vector2(cos(a),sin(a))
					var p:=q+d*(5+10*(1.0-fade))
					fx_line(im,q+d*3,p,1.4+float(j%3)*.6,Color("#3f3f61",fade))
					fx_disc(im,p,2.1,Color("#656b8a",fade))
		"eos_069":
			# Clamp: opposed shell jaws snap shut around a wet central impact.
			var c:=Vector2(24,24)
			var opening:float=11-8*drive
			for side in [-1.0,1.0]:
				var q:=c+Vector2(0,side*opening)
				fight_arc(im,q,10.0,0.0 if side<0 else PI,PI,Color("#d0ffff",fade),Color("#2a82ab",fade),3.1)
				for j in range(5):
					var x:float=-7+float(j)*3.5
					fx_line(im,q+Vector2(x,0),q+Vector2(x,side*-3),1.4,Color("#a1dbe8",fade))
			if t>=peak:
				for j in range(6):
					var a:float=float(j)*TAU/6.0
					fx_disc(im,c+Vector2(cos(a),sin(a))*(5+10*(1.0-fade)),1.5,Color("#b9f9ff",fade))
		"eos_113":
			# Water Spout: tall expanding fountain and ballistic spray.
			var c:=Vector2(24,39)
			for j in range(12):
				var f:float=float(j)/11.0
				var q:=c+Vector2(sin(f*TAU-t*TAU)*3,-29*f*drive)
				fx_disc(im,q,4+4*f,Color("#237eb7",fade))
				fx_disc(im,q-Vector2(1,0),2.2+3*f,Color("#7eddf7",fade))
			for j in range(10):
				var a:float=-PI+float(j)*PI/9.0
				var p:=c+Vector2(cos(a)*17*drive,-25*drive+sin(a)*5+9*(1.0-fade))
				fx_disc(im,p,1.4+float(j%2),Color("#e2ffff",fade))
		"eos_156":
			# Dive: collapsing surface rings, descending bubbles, resurfacing splash.
			var c:=Vector2(24,30)
			var r:float=6+13*drive
			for j in range(3):
				var rr:float=maxf(2.0,r-float(j)*5)
				fx_disc(im,c,rr,Color("#3188bd",fade*.8),maxf(0.0,rr-1.8))
			for j in range(7):
				var f:float=float(j)/6.0
				var p:=c+Vector2(sin(float(j)*2.4)*9,(-13*f if t>=peak else 8*f)*drive)
				fx_disc(im,p,2+float(j%2),Color("#b5f5ff",fade),1.0)
			if t>=peak:
				for j in range(5):
					fx_line(im,c,c+Vector2(-12+float(j)*6,-14*fade),1.3,Color("#d8ffff",fade))
		"eos_158":
			# Waterfall: vertical cascade with turbulent whitewater at its base.
			var c:=Vector2(24,37)
			for j in range(7):
				var x:float=14+float(j)*3.2
				var q:=Vector2(x,5+12*(1.0-drive))
				fx_line(im,q,Vector2(x+sin(t*TAU+float(j))*2,37),3.1,Color("#267daf",fade))
				fx_line(im,q+Vector2(1,0),Vector2(x+1,34),1.3,Color("#9bedff",fade))
			for j in range(9):
				var a:float=float(j)*TAU/9.0
				var p:=c+Vector2(cos(a)*15,sin(a)*5)*(0.4+.6*drive)
				fx_disc(im,p,2.2+float(j%2),Color("#ebffff",fade))
		"eos_159":
			# Muddy Water: sediment-heavy brown breaker with turbid foam.
			for j in range(18):
				var f:float=float(j)/17.0
				var x:float=5+36*f*drive
				var y:float=28-7*sin(f*PI)+sin(f*TAU-t*TAU)*3
				fx_line(im,Vector2(x,35),Vector2(x,y),3.8,Color("#75523b",fade))
				fx_disc(im,Vector2(x,y),3.4,Color("#ba9565",fade))
				if j%3==0:fx_disc(im,Vector2(x,y-2),1.5,Color("#e9d7a8",fade))
			for j in range(7):
				fx_disc(im,Vector2(8+float(j)*5,33+sin(float(j)*2.4+t*TAU)*4),1.2,Color("#d0b88b",fade))
		"eos_219":
			# Surf: rolling wave with a curling crest and foam lip.
			var x:float=8+23*drive
			for j in range(14):
				var f:float=float(j)/13.0
				var q:=Vector2(x-12+f*23,34-15*sin(f*PI))
				fx_line(im,Vector2(q.x,38),q,3.5,Color("#246ba9",fade))
				fx_disc(im,q,3.1,Color("#58c9ea",fade))
				if j%2==0:fx_disc(im,q-Vector2(0,2),2.0,Color("#d6ffff",fade))
			fight_arc(im,Vector2(x+5,26),8.0,PI,PI*1.35,Color("#e9ffff",fade),Color("#2c91bb",fade),2.5)
			for j in range(5):fx_disc(im,Vector2(x+float(j)*2,15+float(j%2)*3),1.4,Color("#c5f9ff",fade))
		"eos_310":
			# Water Pulse: concentric pressure rings traveling forward.
			var q:=Vector2(8+28*drive,24)
			for j in range(3):
				var rad:float=3+float(j)*3.2+3*pulse
				fx_disc(im,q-Vector2(float(j)*3,0),rad,Color("#2478b5",fade*.9),rad-1.7)
				fx_disc(im,q-Vector2(float(j)*3,0),rad-.5,Color("#a9f2ff",fade),rad-1.2)
			fx_disc(im,q,2.4,Color("#e2ffff",fade))
			if t>=peak:fx_disc(im,q,10+9*(1.0-fade),Color("#6ed6ef",fade),8.5+9*(1.0-fade))
		"eos_432":
			# Aqua Jet: streamlined water mantle around the forward rush.
			var q:=Vector2(10+25*drive,24)
			for j in range(8):
				var f:float=float(j)/7.0
				var p:=q-Vector2(f*23*fade,0)
				fx_disc(im,p,5.5-3.8*f,Color("#186da5",fade))
				fx_disc(im,p,4.1-2.6*f,Color("#67dafa",fade))
			for j in range(4):
				var side:float=-1.0 if j%2==0 else 1.0
				fx_line(im,q-Vector2(2,side*2),q-Vector2(15+float(j)*2,side*(5+float(j))),1.2,Color("#deffff",fade))
			fx_disc(im,q+Vector2(2,-1),2.3,Color("#f3ffff",fade))
		"eos_469":
			# Brine: dense salty water glob with crystalline white flecks.
			var q:=Vector2(9+25*drive,24)
			fx_disc(im,q,6+2*pulse,Color("#347d99",fade))
			fx_disc(im,q,4.8+2*pulse,Color("#98cfd8",fade))
			for j in range(8):
				var a:float=float(j)*TAU/8.0+t*2
				var p:=q+Vector2(cos(a),sin(a))*(3+6*(1.0-fade))
				fx_line(im,p-Vector2(1.4,0),p+Vector2(1.4,0),.8,Color("#fcfff1",fade))
				fx_line(im,p-Vector2(0,1.4),p+Vector2(0,1.4),.8,Color("#fcfff1",fade))
			if t>=peak:fx_disc(im,q,9+7*(1.0-fade),Color("#c6e6e1",fade),7.5+7*(1.0-fade))
		"eos_070":
			# Shell Retreat: protective segmented shell closes over the caster.
			var c:=Vector2(24,27)
			var rad:float=7+8*drive
			fight_arc(im,c,rad,PI,PI,Color("#bde8ef",fade),Color("#347695",fade),4.0)
			fx_line(im,c-Vector2(rad,0),c+Vector2(rad,0),2.5,Color("#71b2c4",fade))
			for j in range(5):
				var a:float=PI+float(j)*PI/4.0
				var d:=Vector2(cos(a),sin(a))
				fx_line(im,c+d*3,c+d*(rad-1),1.1,Color("#b3ecf1",fade))
			fx_disc(im,c,rad+3,Color("#82cbdc",fade*.6),rad+1.5)
		"eos_012":
			# Rain Ritual: overhead rain cloud and descending rain streaks.
			for j in range(6):
				var q:=Vector2(12+float(j)*4.8,11+sin(float(j)*1.8)*2)
				fx_disc(im,q,5.8,Color("#527b9f",fade))
				fx_disc(im,q-Vector2(0,2),4.0,Color("#9ab9ce",fade))
			for j in range(12):
				var f:float=fposmod(t*1.6+float(j)*.17,1.0)
				var q:=Vector2(7+float(j%6)*6.5,15+25*f)
				fx_line(im,q,q+Vector2(-2,5),1.1,Color("#a6eaff",fade*drive))
				if f>.8:fx_disc(im,Vector2(q.x,42),3.4,Color("#b9e9f3",fade),2.2)
		"eos_307":
			# Dampening Mist: low drifting translucent banks with dew motes.
			for j in range(12):
				var f:float=float(j)/11.0
				var q:=Vector2(8+32*f,27+sin(f*TAU*1.4-t*TAU)*5)
				fx_disc(im,q,4.5+3*drive,Color("#8abacb",fade*.38))
				fx_disc(im,q-Vector2(1,2),3.0+2*drive,Color("#d9eef0",fade*.55))
			for j in range(7):
				var q:=Vector2(7+float(j)*5.5,19+sin(t*TAU+float(j)*2.4)*4)
				fx_disc(im,q,1.0,Color("#efffff",fade*.8))
		"eos_434":
			# Tidal Halo: protective flowing orbital ring with rising droplets.
			var c:=Vector2(24,27)
			var rad:float=8+7*drive
			var prev:=c+Vector2(rad,0)
			for j in range(1,33):
				var a:float=float(j)*TAU/32.0
				var q:=c+Vector2(cos(a)*rad,sin(a)*rad*.52)
				fx_line(im,prev,q,2.8,Color("#2b8db5",fade))
				fx_line(im,prev,q,1.1,Color("#b5f6ff",fade))
				prev=q
			for j in range(6):
				var a:float=float(j)*TAU/6.0+t*TAU
				var q:=c+Vector2(cos(a)*rad,sin(a)*rad*.52-7*pulse)
				fx_disc(im,q,2.5,Color("#58c9e9",fade))
				fx_disc(im,q-Vector2(1,1),1.2,Color("#edffff",fade))
		"lib_grass_2":
			# Razor Sprout: three pointed young shoots fan out as they travel.
			for j in range(3):
				var side:float=float(j-1)
				var q:=Vector2(7+26*drive-3*absf(side),24+side*10*drive)
				var angle:float=side*.28
				grass_leaf(im,q,angle,8.0,Color("#d7f68a",fade),Color("#397d36",fade))
				fx_line(im,q-Vector2(7*fade,side*2),q,1.1,Color("#a0dc5d",fade))
				if t>=peak:fx_disc(im,q+Vector2(9,side*3),1.4,Color("#ebffc0",fade))
		"lib_grass_3":
			# Root Quake: staggered ground fractures and forked roots.
			for j in range(5):
				var x:float=7+float(j)*8
				var h:float=3+13*smoothstep(float(j)*.07,.55+float(j)*.07,t)
				var q:=Vector2(x,36)
				fx_line(im,q-Vector2(3,0),q+Vector2(4,2),2.2,Color("#594631",fade))
				fx_line(im,q,q+Vector2(-2,-h),3.4,Color("#745031",fade))
				fx_line(im,q-Vector2(1,0),q+Vector2(-2,-h),1.3,Color("#b58b52",fade))
				fx_line(im,q+Vector2(-1,-h*.5),q+Vector2(5,-h*.8),1.7,Color("#799146",fade))
				fx_disc(im,q+Vector2(3,-h*.45),1.4,Color("#c6a46a",fade))
		"eos_221":
			# Needle Arm: cactus-like club, angular spines and a sharp impact.
			var q:=Vector2(9+24*drive,24)
			fx_line(im,q-Vector2(15,4),q,7.2,Color("#285d35",fade))
			fx_line(im,q-Vector2(15,5),q-Vector2(0,1),5.1,Color("#74b75b",fade))
			fx_disc(im,q,6.2,Color("#428947",fade))
			for j in range(8):
				var a:float=float(j)*TAU/8.0
				var d:=Vector2(cos(a),sin(a))
				fx_line(im,q+d*4,q+d*(9+2*pulse),1.5,Color("#e1edac",fade))
			if t>=peak:
				for j in range(5):
					var a:float=-PI*.5+float(j)*PI*.25
					var d:=Vector2(cos(a),sin(a))
					fx_line(im,q+d*8,q+d*(11+5*(1.0-fade)),1.0,Color("#f6ffc3",fade))
		"eos_238":
			# Frenzy Plant: massive branching roots erupt around the target.
			for j in range(5):
				var f:float=float(j)/4.0
				var c:=Vector2(8+32*f,41)
				var h:float=(19+10*sin(f*PI))*drive
				var prev:=c
				for k in range(1,13):
					var u:float=float(k)/12.0
					var q:=c+Vector2(sin(u*4+float(j))*7*u,-h*u)
					fx_line(im,prev,q,5.0-3*u,Color("#5a4731",fade))
					fx_line(im,prev-Vector2(1,0),q-Vector2(1,0),2.5-1.5*u,Color("#9b864b",fade))
					if k==7:grass_leaf(im,q,PI+f*2,8.0,Color("#b8ee69",fade),Color("#3c8740",fade))
					prev=q
				fx_disc(im,c,4+3*pulse,Color("#8a764a",fade*.55),3+3*pulse)
		"eos_297":
			# Magical Leaf: orbiting enchanted leaves with rainbow highlights.
			for j in range(6):
				var f:float=float(j)/5.0
				var a:float=t*TAU*1.4+float(j)*TAU/6.0
				var q:=Vector2(9+25*drive,24)+Vector2(cos(a)*9,sin(a)*11)
				var hue:Color=Color.from_hsv(f,.56,1.0,fade)
				grass_leaf(im,q,a+.5,7.5,hue,Color("#426c65",fade))
				fairy_star(im,q-Vector2(2,2),1.5,Color("#f4ffe4",fade))
				if j%2==0:fx_line(im,q-Vector2(6*fade,0),q,1.0,Color(hue,fade*.65))
		"eos_458":
			# Grass Knot: two flexible stems interlock into a tightening ground snare.
			var c:=Vector2(24,32)
			for j in range(2):
				var prev:=c
				for k in range(1,33):
					var f:float=float(k)/32.0
					var a:float=f*TAU+t*2.0+float(j)*PI
					var q:=c+Vector2(sin(a)*(17-8*drive),sin(a*2)*6-5*pulse)
					if k>1:
						fx_line(im,prev,q,3.3,Color("#376b38",fade))
						fx_line(im,prev,q,1.4,Color("#a4d45f",fade))
					if k%10==0:grass_leaf(im,q,a,5.0,Color("#c9ec80",fade),Color("#43823c",fade))
					prev=q
			fx_disc(im,c,3+2*pulse,Color("#d2ef91",fade))
		"eos_468":
			# Seed Flare: single glowing seed opens into a petaled radial eruption.
			var c:=Vector2(24,24)
			if t<peak:
				fx_line(im,c+Vector2(-3,5),c+Vector2(3,-5),7.0,Color("#407044",fade))
				fx_line(im,c+Vector2(-2,4),c+Vector2(2,-4),4.5,Color("#e4f9a7",fade))
				fx_disc(im,c,8+4*drive,Color("#a8df73",fade*.65),6+4*drive)
			else:
				for j in range(9):
					var a:float=float(j)*TAU/9.0+t*.5
					var d:=Vector2(cos(a),sin(a))
					var q:=c+d*(4+12*(1.0-fade))
					grass_leaf(im,q,a,7.0,Color("#efffc2",fade),Color("#7fc54f",fade))
					fairy_star(im,q,1.7,Color("#fbffdb",fade))
				fx_disc(im,c,6*fade+2,Color("#fbffe0",fade))
		"eos_511":
			# Power Whip: thick thorn-covered lash with a heavy curved snap.
			var prev:=Vector2(5,33)
			for j in range(1,25):
				var f:float=float(j)/24.0
				var q:=Vector2(5+34*f*drive,29+sin(f*PI*1.5-t*TAU*.65)*11)
				fx_line(im,prev,q,5.7-2.7*f,Color("#285e32",fade))
				fx_line(im,prev-Vector2(0,1),q-Vector2(0,1),2.9-1.2*f,Color("#80c756",fade))
				if j%4==0:
					var side:float=-1.0 if j%8==0 else 1.0
					fx_line(im,q,q+Vector2(-3,side*5),1.7,Color("#d2dfa0",fade))
				prev=q
			if t>=peak:
				for j in range(6):
					var a:float=float(j)*TAU/6.0
					var d:=Vector2(cos(a),sin(a))
					fx_line(im,prev+d*3,prev+d*(6+8*(1.0-fade)),1.2,Color("#e6ffac",fade))
		"eos_079":
			# Slumber Spores: mushroom cap releases lavender clouds and soft drifting motes.
			var c:=Vector2(24,31)
			fx_line(im,c,c-Vector2(0,9),4.0,Color("#c9b899",fade))
			for j in range(7):
				var x:float=-9+float(j)*3
				var q:=c+Vector2(x,-9-5*sin(float(j)*PI/6.0))
				fx_disc(im,q,4.0,Color("#9272ae",fade))
				fx_disc(im,q-Vector2(0,2),2.1,Color("#d8bde8",fade))
			for j in range(12):
				var a:float=float(j)*2.4
				var q:=c+Vector2(cos(a)*(5+12*drive),-12-float(j%4)*3-5*drive)
				fx_disc(im,q,1.3+float(j%2)*.5,Color("#d9cdf5",fade*.8))
		"eos_231":
			# Drowse Pollen: pale blue drifting pollen and slow crescent shapes.
			for j in range(10):
				var f:float=float(j)/9.0
				var q:=Vector2(7+33*f,25+sin(float(j)*1.9+t*TAU*.5)*9-5*drive)
				fx_disc(im,q,3.2,Color("#91aec5",fade*.35))
				fx_disc(im,q,1.2,Color("#d9e9ff",fade))
			for j in range(3):
				var q:=Vector2(13+float(j)*11,14-3*drive+float(j%2)*4)
				fight_arc(im,q,4.0,PI*.2,PI*1.45,Color("#e5f2ff",fade),Color("#819dc0",fade),1.6)
		"eos_124":
			# Numbing Pollen: mustard-yellow granules and jagged tingling marks.
			for j in range(17):
				var f:float=float(j)/16.0
				var q:=Vector2(8+31*f*drive,24+sin(float(j)*2.4+t*TAU)*11*f)
				fx_disc(im,q,2.1,Color("#b39b40",fade*.72))
				fx_disc(im,q-Vector2(1,1),1.1,Color("#fff1a0",fade))
			for j in range(4):
				var q:=Vector2(18+float(j)*6,14+float(j%2)*16)
				fx_line(im,q,q+Vector2(3,-3),1.1,Color("#f4db67",fade))
				fx_line(im,q+Vector2(3,-3),q+Vector2(2,2),1.1,Color("#f4db67",fade))
		"eos_351":
			# Cotton Snare: expanding cotton tufts connected by tightening fibers.
			var c:=Vector2(24,26)
			for j in range(7):
				var a:float=float(j)*TAU/7.0+t
				var q:=c+Vector2(cos(a),sin(a))*(14-6*drive)
				fx_line(im,c,q,1.0,Color("#9baab0",fade))
				for k in range(4):
					var b:float=float(k)*TAU/4.0
					var p:=q+Vector2(cos(b),sin(b))*2.5
					fx_disc(im,p,3.1,Color("#bccacf",fade))
					fx_disc(im,p-Vector2(0,1),2.2,Color("#f6fff3",fade))
			fx_disc(im,c,4+3*pulse,Color("#eff9e8",fade))
		"eos_015":
			# Herbal Purge: medicinal leaves spiral outward with cleansing white motes.
			var c:=Vector2(24,26)
			for j in range(6):
				var a:float=float(j)*TAU/6.0+t*TAU
				var q:=c+Vector2(cos(a),sin(a))*(5+10*drive)
				grass_leaf(im,q,a+PI*.5,8.0,Color("#bde5a3",fade),Color("#3e9167",fade))
				fairy_star(im,q-Vector2(0,5),1.5,Color("#f0fff1",fade))
			fx_disc(im,c,6+9*drive,Color("#a4e3b3",fade*.75),4.5+9*drive)
			fx_line(im,c-Vector2(4,0),c+Vector2(4,0),1.4,Color("#f5fff0",fade))
			fx_line(im,c-Vector2(0,4),c+Vector2(0,4),1.4,Color("#f5fff0",fade))
		"eos_094":
			# Verdant Renewal: opening blossom and ascending green restoration light.
			var c:=Vector2(24,30)
			fx_line(im,c+Vector2(0,8),c-Vector2(0,7*drive),2.3,Color("#468b45",fade))
			for j in range(6):
				var a:float=float(j)*TAU/6.0
				var d:=Vector2(cos(a),sin(a))
				var q:=c-Vector2(0,7*drive)+d*(3+5*drive)
				fx_disc(im,q,3.4+1.2*pulse,Color("#d7e79b",fade))
				fx_disc(im,q-Vector2(0,1),2.3,Color("#f2ffcd",fade))
			fx_disc(im,c-Vector2(0,7*drive),3.3,Color("#e4bd64",fade))
			for j in range(5):
				var q:=Vector2(9+float(j)*7,27-17*drive+sin(float(j)*2.0)*4)
				fairy_star(im,q,1.7,Color("#caffad",fade))
		"eos_084":
			# Reed Lullaby: swaying reed blades release musical notes.
			var c:=Vector2(24,38)
			for j in range(4):
				var q:=c+Vector2(-8+float(j)*5,0)
				var tip:=q+Vector2(sin(t*TAU+float(j))*4,-14-float(j%3)*3)
				fx_line(im,q,tip,1.8,Color("#58834a",fade))
				fx_line(im,tip,tip+Vector2(0,-4),2.8,Color("#b7a36b",fade))
			for j in range(4):
				var q:=Vector2(9+float(j)*8,24-13*drive+sin(float(j)*2.3+t*TAU)*3)
				fx_disc(im,q,2.2,Color("#c9efb9",fade))
				fx_line(im,q+Vector2(2,0),q+Vector2(2,-7),1.0,Color("#c9efb9",fade))
				fx_line(im,q+Vector2(2,-7),q+Vector2(5,-5),1.0,Color("#c9efb9",fade))
		"eos_233":
			# Rooted Renewal: anchored root network with upward restorative sap.
			var c:=Vector2(24,34)
			for j in range(7):
				var a:float=float(j)*TAU/7.0
				var d:=Vector2(cos(a),sin(a)*.38)
				var q:=c+d*(8+10*drive)
				fx_line(im,c,q,2.7,Color("#755538",fade))
				fx_line(im,q,q+d*3+Vector2(2,-2),1.4,Color("#a58b56",fade))
				var p:=c+d*6
				fx_line(im,p,p-Vector2(0,10*drive),1.8,Color("#6baf58",fade))
				fx_disc(im,p-Vector2(0,10*drive),1.4,Color("#d8ffac",fade))
			for j in range(5):
				var f:float=fposmod(t+float(j)*.2,1.0)
				var q:=c+Vector2(sin(float(j)*2.4+t)*6,-22*f)
				fx_disc(im,q,1.6,Color("#c9f394",fade))
			fx_disc(im,c,6+3*pulse,Color("#b1db82",fade*.75),4.5+3*pulse)
		"lib_ice_1":
			# Frost Needle: long tapered icy lance, followed by splintering fragments.
			var q:=Vector2(9+25*drive,24)
			var tip:=q+Vector2(9,0)
			fx_line(im,q-Vector2(10,0),tip,3.6,Color("#3c6eb1",fade))
			fx_line(im,q-Vector2(7,2),tip,2.1,Color("#83cce8",fade))
			fx_line(im,q+Vector2(-4,-1),tip,1.0,Color("#f2ffff",fade))
			fx_line(im,q+Vector2(-5,3),tip,1.1,Color("#b3e6ff",fade))
			for j in range(3):
				var p:=q-Vector2(11+float(j)*3,(-1.0 if j%2==0 else 1.0)*3)
				fx_disc(im,p,1.0,Color("#a9dff6",fade))
			if t>=peak:
				for j in range(6):
					var a:float=float(j)*TAU/6.0
					var d:=Vector2(cos(a),sin(a))
					var p:=q+d*(4+10*(1.0-fade))
					fx_line(im,p,p+d*4,1.3,Color("#c5eeff",fade))
					fx_disc(im,p,1.0,Color("#efffff",fade))
		"lib_ice_2":
			# Glacier Ray: broad faceted beam with solid crystalline edges.
			var end_x:float=8+34*drive
			for j in range(15):
				var f:float=float(j)/14.0
				var x:float=4+(end_x-4)*f
				var w:float=2.0+3.0*f+2*pulse
				var c:=Vector2(x,24)
				fx_line(im,c-Vector2(0,w),c+Vector2(0,w),3.0,Color("#4679b9",fade))
				fx_line(im,c-Vector2(0,w*.6),c+Vector2(0,w*.6),2.4,Color("#94dff6",fade))
				fx_disc(im,c,1.2,Color("#f1ffff",fade))
				if j%3==0:
					var side:float=-1.0 if j%2==0 else 1.0
					fx_line(im,c+Vector2(0,w*side),c+Vector2(-3,(w+4)*side),1.5,Color("#d1f1ff",fade))
			if t>=peak:
				for j in range(7):
					var a:float=float(j)*TAU/7.0
					var d:=Vector2(cos(a),sin(a))
					var q:=Vector2(end_x-3,24)+d*(4+6*(1.0-fade))
					fx_line(im,q,q+d*4,1.7,Color("#c2efff",fade))
		"lib_ice_3":
			# Snow Spiral: two corkscrew arms of six-point snowflakes.
			var c:=Vector2(24,26)
			for arm in range(2):
				var prev:=c
				for j in range(1,25):
					var f:float=float(j)/24.0
					var a:float=f*TAU*1.25+t*TAU+float(arm)*PI
					var q:=c+Vector2(cos(a),sin(a)*.72)*(3+f*(10+8*drive))
					if j>1:fx_line(im,prev,q,1.1,Color("#8ec5e6",fade*.65))
					if j%5==0:
						for k in range(3):
							var b:float=float(k)*PI/3.0+a
							var d:=Vector2(cos(b),sin(b))
							fx_line(im,q-d*3,q+d*3,1.0,Color("#efffff",fade))
					else:fx_disc(im,q,1.1,Color("#bdeaff",fade))
					prev=q
		"eos_002":
			# Frost Tumble: rolling faceted snowball, growing and shedding snow.
			var c:=Vector2(9+25*drive,27)
			var radius:float=4.8+5*drive
			fx_disc(im,c,radius,Color("#5785b9",fade))
			fx_disc(im,c-Vector2(1,1),radius-1.3,Color("#c4e7f4",fade))
			for j in range(6):
				var a:float=float(j)*TAU/6.0+t*TAU*2
				var d:=Vector2(cos(a),sin(a))
				fx_line(im,c+d*2,c+d*(radius-1),1.0,Color("#eefcff",fade))
				fx_disc(im,c+d*(radius-2),1.3,Color("#91b9d9",fade))
			for j in range(7):
				var f:float=float(j)/6.0
				var q:=c+Vector2(-radius-10*f,5+sin(float(j)*2.4+t*TAU)*4)
				fx_disc(im,q,1.2+float(j%2),Color("#dcf5ff",fade*(1.0-f*.5)))
			if t>=peak:fx_disc(im,c,12+5*(1.0-fade),Color("#a9d8f4",fade),10+5*(1.0-fade))
		"eos_088":
			# Null Mist: gray-blue fog blankets the field, dissolving bright motes.
			for j in range(15):
				var f:float=float(j)/14.0
				var q:=Vector2(6+36*f,22+sin(f*TAU*1.5-t*TAU)*7+float(j%3)*3)
				fx_disc(im,q,4.5+3*drive,Color("#53698c",fade*.48))
				fx_disc(im,q-Vector2(1,2),3.6+2*drive,Color("#a7bbd0",fade*.53))
			for j in range(6):
				var q:=Vector2(9+float(j)*6,11+float(j%3)*6+8*drive)
				var r:float=2.2*(1.0-drive)+.5
				fx_line(im,q-Vector2(r,r),q+Vector2(r,r),1.0,Color("#ddebf6",fade*(1.0-drive)))
				fx_line(im,q+Vector2(-r,r),q+Vector2(r,-r),1.0,Color("#ddebf6",fade*(1.0-drive)))
		"eos_130":
			# Clear Veil: translucent frosted protective dome and ascending frost dust.
			var c:=Vector2(24,33)
			var radius:float=7+12*drive
			var prev:=c+Vector2(-radius,0)
			for j in range(1,33):
				var a:float=PI+float(j)*PI/32.0
				var q:=c+Vector2(cos(a),sin(a))*radius
				fx_line(im,prev,q,3.6,Color("#669ac1",fade*.55))
				fx_line(im,prev,q,1.4,Color("#d8f7ff",fade))
				if j%8==0:
					fx_line(im,q,c+Vector2((q.x-c.x)*.7,0),.8,Color("#aed8ee",fade*.35))
				prev=q
			fx_line(im,c-Vector2(radius,0),c+Vector2(radius,0),1.2,Color("#b1e0f3",fade*.7))
			for j in range(7):
				var a:float=PI+float(j)*PI/6.0
				var q:=c+Vector2(cos(a),sin(a))*(radius+2)
				fairy_star(im,q,1.4,Color("#f2ffff",fade))
		"eos_014":
			# Frostfall: gathering winter cloud releases faceted hailstones.
			for j in range(7):
				var q:=Vector2(9+float(j)*5,10+sin(float(j)*1.7)*2)
				fx_disc(im,q,5.1,Color("#6e89ac",fade*.85))
				fx_disc(im,q-Vector2(0,2),3.7,Color("#c6dcea",fade))
			for j in range(10):
				var f:float=fposmod(t*1.5+float(j)*.17,1.0)
				var q:=Vector2(7+float(j%6)*6.6,15+24*f)
				var opacity:float=fade*drive
				fx_line(im,q-Vector2(0,5),q,1.0,Color("#b6e4ff",opacity))
				fx_disc(im,q,2.1+float(j%2)*.7,Color("#6e9ecf",opacity))
				fx_disc(im,q-Vector2(1,1),1.2,Color("#f1ffff",opacity))
				if f>.84:
					fx_line(im,q,q+Vector2(3,-2),1.0,Color("#d3efff",opacity))
					fx_line(im,q,q+Vector2(-3,-2),1.0,Color("#d3efff",opacity))
		"lib_poison_1":
			# Venom Flick: a narrow lash throws three sticky venom droplets.
			var q:=Vector2(9+26*drive,24)
			var prev:=Vector2(5,32)
			for j in range(1,13):
				var f:float=float(j)/12.0
				var p:=Vector2(5+(q.x-5)*f,32-8*f+sin(f*PI-t*TAU)*5*f)
				fx_line(im,prev,p,2.7-1.3*f,Color("#56386e",fade))
				fx_line(im,prev,p,1.1,Color("#c779e0",fade))
				prev=p
			for j in range(3):
				var p:=q+Vector2(float(j)*3, float(j-1)*5)
				fx_line(im,p-Vector2(4,1),p,2.0,Color("#8245a8",fade))
				fx_disc(im,p,2.2,Color("#ad57c8",fade))
				fx_disc(im,p-Vector2(0,1),1.0,Color("#f0b9f4",fade))
			if t>=peak:
				for j in range(5):
					var a:float=float(j)*TAU/5.0
					fx_disc(im,q+Vector2(cos(a),sin(a))*(5+7*(1.0-fade)),1.2,Color("#b36ed7",fade))
		"lib_poison_2":
			# Acid Arc: green corrosive liquid follows a high ballistic arc.
			var q:=Vector2(7+31*drive,31-18*sin(drive*PI))
			for j in range(7):
				var f:float=maxf(0.0,drive-float(j)*.065)
				var p:=Vector2(7+31*f,31-18*sin(f*PI))
				fx_disc(im,p,3.2-float(j)*.25,Color("#567b2c",fade))
				fx_disc(im,p-Vector2(0,1),2.1-float(j)*.14,Color("#c0eb55",fade))
			if t>=peak:
				var c:=Vector2(37,34)
				for j in range(9):
					var f:float=float(j)/8.0
					var p:=c+Vector2(-12+18*f,-9*sin(f*PI)*fade)
					fx_line(im,c,p,1.3,Color("#81af36",fade))
					fx_disc(im,p,1.6,Color("#d5f477",fade))
				fx_line(im,c-Vector2(10,0),c+Vector2(7,0),3.5,Color("#587d30",fade*.7))
		"lib_poison_3":
			# Toxic Bloom: sinister blossom releases globules and a purple spore cloud.
			var c:=Vector2(24,28)
			for j in range(6):
				var a:float=float(j)*TAU/6.0+t*.5
				var d:=Vector2(cos(a),sin(a))
				var q:=c+d*(3+8*drive)
				fx_line(im,c,q,5.2,Color("#4c325d",fade))
				fx_disc(im,q,4.2,Color("#9751a3",fade))
				fx_disc(im,q-Vector2(1,1),2.1,Color("#d894c6",fade))
			fx_disc(im,c,4.7,Color("#a4c446",fade))
			fx_disc(im,c,2.2,Color("#e6ec97",fade))
			for j in range(10):
				var a:float=float(j)*TAU/10.0+t
				var q:=c+Vector2(cos(a),sin(a))*(8+11*drive)
				fx_disc(im,q,2.0+float(j%2),Color("#74508b",fade*.55))
				fx_disc(im,q-Vector2(0,1),1.0,Color("#d5a2df",fade))
		"eos_198":
			# Poison Fang: opposing pointed fangs snap shut, injecting violet venom.
			var c:=Vector2(24,24)
			var gap:float=12-9*drive
			for side in [-1.0,1.0]:
				var q:=c+Vector2(0,side*gap)
				var start:float=PI if side<0.0 else 0.0
				fight_arc(im,q,11.0,start,PI,Color("#c6a3d9",fade),Color("#513458",fade),3.2)
				for j in range(4):
					var p:=q+Vector2(-7+float(j)*4.7,0)
					var tip:=p-Vector2(0,side*(6.0 if j==0 or j==3 else 3.5))
					fx_line(im,p,tip,2.4,Color("#dfcfeb",fade))
					fx_line(im,p+Vector2(1,0),tip,1.0,Color("#f5edfa",fade))
					if j==0 or j==3:fx_disc(im,tip,1.7,Color("#ad52ca",fade))
			if t>=peak:
				for j in range(7):
					var a:float=float(j)*TAU/7.0
					var p:=c+Vector2(cos(a),sin(a))*(5+10*(1.0-fade))
					fx_disc(im,p,2.0,Color("#793b92",fade))
					fx_disc(im,p-Vector2(0,1),1.0,Color("#d68ae6",fade))
		"eos_283":
			# Poison Tail: articulated scorpion-like tail swings a toxic stinger.
			var c:=Vector2(13,33)
			var prev:=c
			for j in range(1,21):
				var f:float=float(j)/20.0
				var a:float=-PI*.8+f*PI*1.15+drive*.8
				var q:=c+Vector2(cos(a)*15*f,-14*sin(f*PI)+sin(a)*7*f)
				fx_line(im,prev,q,4.0-2.0*f,Color("#48334f",fade))
				fx_line(im,prev-Vector2(0,1),q-Vector2(0,1),2.0-1.0*f,Color("#9754ae",fade))
				if j%4==0:fx_disc(im,q,2.2,Color("#bd78ce",fade))
				prev=q
			var tip:=prev+Vector2(7*drive,-4)
			fx_line(im,prev,tip,3.2,Color("#7b3b95",fade))
			fx_line(im,prev-Vector2(0,1),tip,1.1,Color("#e2a5ec",fade))
			if t>=peak:
				for j in range(5):
					var a:float=float(j)*TAU/5.0
					fx_disc(im,tip+Vector2(cos(a),sin(a))*(4+8*(1.0-fade)),1.7,Color("#bb68d2",fade))
		"eos_196":
			# Venom Mist: layered violet gas billows, curls upward and disperses.
			for j in range(12):
				var f:float=float(j)/11.0
				var q:=Vector2(6+35*f*drive,29+sin(f*TAU*1.4-t*TAU)*6-4*drive)
				fx_disc(im,q,4.0+3*f,Color("#563868",fade*.65))
				fx_disc(im,q-Vector2(1,2),3.3+2*f,Color("#9560a8",fade*.55))
				if j%3==0:
					fight_arc(im,q,3.0+2*f,t*TAU,PI*1.2,Color("#c89bd5",fade*.7),Color("#73518b",fade*.6),1.0)
			for j in range(8):
				var q:=Vector2(8+float(j)*4.3*drive,19+sin(float(j)*2.4+t*TAU)*7-4*t)
				fx_disc(im,q,1.0+float(j%2)*.6,Color("#bba2ce",fade*.7))
		"eos_202":
			# Acid Shell: protective glossy chemical coating, bubbles and dripping edges.
			var c:=Vector2(24,33)
			var rad:float=7+11*drive
			var prev:=c-Vector2(rad,0)
			for j in range(1,31):
				var a:float=PI+float(j)*PI/30.0
				var q:=c+Vector2(cos(a),sin(a))*rad
				fx_line(im,prev,q,4.0,Color("#526a37",fade*.9))
				fx_line(im,prev-Vector2(0,1),q-Vector2(0,1),2.0,Color("#b9db62",fade))
				if j%6==0:
					fx_line(im,q,q+Vector2(0,4+3*pulse),1.8,Color("#86aa43",fade))
					fx_disc(im,q+Vector2(0,5+3*pulse),1.6,Color("#d3ea8b",fade))
				prev=q
			fx_line(im,c-Vector2(rad,0),c+Vector2(rad,0),2.2,Color("#9ab753",fade*.75))
			for j in range(5):
				var q:=c+Vector2(-10+float(j)*5,-4-10*fposmod(t+float(j)*.19,1.0))
				fx_disc(im,q,2.2,Color("#bde67d",fade*.75),1.1)
		"eos_496":
			# Venom Tile: ground-bound grid of purple toxic spikes and bubbling residue.
			var c:=Vector2(24,31)
			for j in range(4):
				var v:float=float(j)*5
				fx_line(im,c+Vector2(-16+v,-6+v*.38),c+Vector2(5+v,2+v*.38),1.1,Color("#80529a",fade*.8))
				fx_line(im,c+Vector2(-16+v,6-v*.38),c+Vector2(5+v,-2-v*.38),1.1,Color("#80529a",fade*.8))
			for j in range(9):
				var x:float=10+float(j%3)*12
				var y:float=28+float(j/3)*3.5
				var q:=Vector2(x,y)
				var h:float=3+8*drive
				fx_line(im,q-Vector2(3,0),q+Vector2(0,-h),2.3,Color("#4e2e64",fade))
				fx_line(im,q+Vector2(3,0),q+Vector2(0,-h),2.0,Color("#a35bb8",fade))
				fx_disc(im,q+Vector2(0,-h),1.1,Color("#dd9fe2",fade))
				fx_disc(im,q,3.2,Color("#6b427f",fade*.7),2.0)
		"eos_438":
			# Nullifying Venom: cross-cutting toxic spray dissolves aura fragments.
			var q:=Vector2(8+27*drive,24)
			for j in range(7):
				var f:float=float(j)/6.0
				var p:=Vector2(5+(q.x-5)*f,24+sin(float(j)*2.4+t*TAU)*6*f)
				fx_disc(im,p,3.2+f*2,Color("#624275",fade))
				fx_disc(im,p-Vector2(1,1),1.8+f,Color("#ba85c6",fade))
			if t>=peak:
				for j in range(8):
					var a:float=float(j)*TAU/8.0+t*.4
					var d:=Vector2(cos(a),sin(a))
					var p:=q+d*(5+9*(1.0-fade))
					var tint:=Color("#a5bd79",fade)
					fx_line(im,p-d*2,p+d*2,1.3,tint)
					fx_disc(im,p,1.1,Color("#e0e4b7",fade*.7))
				fx_line(im,q-Vector2(5,5),q+Vector2(5,5),2.0,Color("#d6b5e5",fade))
				fx_line(im,q+Vector2(-5,5),q+Vector2(5,-5),2.0,Color("#d6b5e5",fade))
		"lib_ground_2":
			# Sand Drill: a rotating tapered cone of sand and grit bores forward.
			var q:=Vector2(10+23*drive,25)
			for j in range(12):
				var f:float=float(j)/11.0
				var x:float=q.x-20*(1.0-f)*fade
				var rad:float=7.0*(1.0-f)+1.0
				var p:=Vector2(x,25+sin(f*TAU*2.0-t*TAU*2.0)*rad)
				fx_line(im,Vector2(x,25-rad),Vector2(x,25+rad),2.7,Color("#927049",fade))
				fx_line(im,p,p+Vector2(2,0),1.6,Color("#e2bc81",fade))
				if j%2==0:fx_disc(im,p-Vector2(2,2),1.1,Color("#f5d9a7",fade))
			for j in range(7):
				var f:float=float(j)/6.0
				var p:=q+Vector2(-7-14*f,7+sin(float(j)*2.4+t*TAU)*5)
				fx_disc(im,p,1.4+f,Color("#b99a6e",fade))
		"lib_ground_3":
			# Mud Lance: elongated wet earthen spear with a heavy splashing impact.
			var q:=Vector2(8+26*drive,24)
			fx_line(im,q-Vector2(13,0),q+Vector2(7,0),4.8,Color("#60432d",fade))
			fx_line(im,q-Vector2(11,-1),q+Vector2(7,0),2.7,Color("#a37b50",fade))
			fx_line(im,q-Vector2(7,2),q+Vector2(6,0),1.1,Color("#d6b98a",fade))
			for j in range(4):
				var p:=q+Vector2(-5-float(j)*4,3+float(j%2)*4)
				fx_disc(im,p,1.8,Color("#8a6445",fade))
			if t>=peak:
				for j in range(8):
					var a:float=float(j)*TAU/8.0
					var d:=Vector2(cos(a),sin(a))
					var p:=q+d*(4+10*(1.0-fade))
					fx_line(im,q+d*3,p,1.6,Color("#795335",fade))
					fx_disc(im,p,2.0,Color("#b38d62",fade))
		"eos_143":
			# Sand Tomb: sinking sand funnel, rotating grains and collapsing rim.
			var c:=Vector2(24,31)
			for ring in range(4):
				var rad:float=4+float(ring)*4+3*drive
				var prev:=c+Vector2(rad,0)
				for j in range(1,33):
					var a:float=float(j)*TAU/32.0
					var p:=c+Vector2(cos(a)*rad,sin(a)*rad*.44-float(ring)*2*drive)
					if j>1:
						fx_line(im,prev,p,2.1,Color("#765337",fade))
						fx_line(im,prev,p,.9,Color("#d2ae75",fade))
					prev=p
				for j in range(4):
					var a:float=float(j)*TAU/4.0+t*TAU*1.4+float(ring)*.7
					var p:=c+Vector2(cos(a)*rad,sin(a)*rad*.44-float(ring)*2*drive)
					fx_disc(im,p,1.4,Color("#e8cd98",fade))
			fx_disc(im,c,4.0,Color("#513d2e",fade))
		"eos_213":
			# Mud Slap: low wide hand-swept fan of wet muddy clumps.
			var c:=Vector2(7,32)
			for j in range(11):
				var f:float=float(j)/10.0
				var p:=c+Vector2((10+25*f)*drive,-(4+13*f)*sin(f*PI)+sin(float(j)*2.4)*4)
				fx_disc(im,p,2.0+2*f,Color("#66482f",fade))
				fx_disc(im,p-Vector2(0,1),1.2+f,Color("#a27b54",fade))
				if j%2==0:fx_line(im,p-Vector2(5,2),p,1.6,Color("#8d6441",fade))
			if t>=peak:
				for j in range(6):
					var p:=Vector2(25+float(j)*3,34+sin(float(j)*2.4)*4)
					fx_disc(im,p,2.4,Color("#775438",fade*.7))
		"eos_289":
			# Bone Club: a single oversized ivory club swings downward into dirt.
			var c:=Vector2(16+9*drive,19)
			var a:float=-PI*.7+drive*PI*.85
			var d:=Vector2(cos(a),sin(a))
			earth_bone(im,c,a,15.0,Color("#e8d5ad",fade),Color("#826846",fade))
			fight_arc(im,c,15.0,-PI*.8,PI*drive,Color("#e8c99a",fade*.75),Color("#9e7851",fade*.7),1.8)
			if t>=peak:
				var q:=c+d*10
				for j in range(7):
					var b:float=-PI+float(j)*PI/6.0
					var p:=q+Vector2(cos(b)*13,sin(b)*9)*(1.0-fade)
					fx_disc(im,p,1.7+float(j%2),Color("#b28b60",fade))
					fx_line(im,q,p,1.1,Color("#d2b181",fade))
		"eos_285":
			# Bone Flurry: alternating bone thrusts; real hit cadence remains external.
			for j in range(3):
				var f:float=fposmod(t*1.8+float(j)/3.0,1.0)
				var q:=Vector2(9+27*f,18+float(j)*6)
				earth_bone(im,q,-.35+float(j)*.35,10.0,Color("#e8d7b6",fade),Color("#937856",fade))
				fx_line(im,q-Vector2(10,0),q-Vector2(3,0),1.4,Color("#c6a77b",fade*.8))
				if f>.7:
					for k in range(3):
						var a:float=-PI*.5+float(k)*PI*.5
						var d:=Vector2(cos(a),sin(a))
						fx_line(im,q+d*4,q+d*9,1.3,Color("#fff0c9",fade))
		"eos_290":
			# Returning Bone: spinning bone travels outward then back with a curved dust wake.
			var travel:float=sin(t*PI)
			var q:=Vector2(8+30*travel,24-7*sin(t*TAU))
			var a:float=t*TAU*2.0
			earth_bone(im,q,a,12.0,Color("#f1dfba",fade),Color("#91764f",fade))
			for j in range(1,8):
				var f:float=maxf(0.0,t-float(j)*.045)
				var p:=Vector2(8+30*sin(f*PI),24-7*sin(f*TAU))
				fx_disc(im,p,1.7-float(j)*.12,Color("#c0a178",fade*.7))
			if t>=peak:
				fight_arc(im,q,8.0,a,PI*1.2,Color("#e7cda0",fade),Color("#ad895b",fade),1.2)
		"eos_212":
			# Grounding Mist: wet mineral slurry clings low to the ground and settles.
			for j in range(13):
				var f:float=float(j)/12.0
				var q:=Vector2(6+36*f,32+sin(f*TAU*1.5-t*TAU)*4)
				fx_disc(im,q,3.7+2.8*drive,Color("#765c48",fade*.5))
				fx_disc(im,q-Vector2(1,1),2.8+2*drive,Color("#b39c7b",fade*.6))
				if j%3==0:
					fx_line(im,q-Vector2(0,5),q+Vector2(0,3),1.6,Color("#957353",fade))
			for j in range(6):
				var q:=Vector2(8+float(j)*6,17+13*drive+sin(float(j)*2.4)*3)
				fx_disc(im,q,1.3,Color("#d0bc95",fade))
		"eos_295":
			# Thorn Tile: mineral spikes erupt across a ground-aligned diamond lattice.
			var c:=Vector2(24,33)
			for j in range(4):
				var v:float=float(j)*6
				fx_line(im,c+Vector2(-18+v,-6+v*.35),c+Vector2(v,3+v*.35),1.0,Color("#8a6c4c",fade*.8))
				fx_line(im,c+Vector2(-18+v,6-v*.35),c+Vector2(v,-3-v*.35),1.0,Color("#8a6c4c",fade*.8))
			for j in range(9):
				var q:=Vector2(10+float(j%3)*12,27+float(j/3)*4)
				var h:float=3+10*drive
				fx_line(im,q-Vector2(3,0),q+Vector2(0,-h),2.6,Color("#69523d",fade))
				fx_line(im,q+Vector2(3,0),q+Vector2(0,-h),2.0,Color("#c09c71",fade))
				fx_line(im,q,q+Vector2(0,-h),.8,Color("#e5c8a1",fade))
				fx_disc(im,q+Vector2(-4,2),1.2,Color("#ad8a60",fade))
		"eos_296":
			# Seismic Surge: successive compressed ground shock fronts and airborne debris.
			var c:=Vector2(24,31)
			for ring in range(3):
				var f:float=clampf(drive-float(ring)*.20,0.0,1.0)
				var rad:float=3+18*f
				var prev:=c+Vector2(rad,0)
				for j in range(1,33):
					var a:float=float(j)*TAU/32.0
					var offset:float=sin(float(j)*2.4)*1.5
					var q:=c+Vector2(cos(a)*(rad+offset),sin(a)*(rad+offset)*.48)
					fx_line(im,prev,q,2.6,Color("#6b4e35",fade*f))
					fx_line(im,prev,q,1.1,Color("#dbb887",fade*f))
					prev=q
			for j in range(9):
				var a:float=float(j)*TAU/9.0
				var q:=c+Vector2(cos(a)*18*drive,sin(a)*7*drive-11*pulse)
				earth_rock(im,q,2.0+float(j%3)*.7,Color("#c7a578",fade),Color("#785b43",fade))
				fx_disc(im,q+Vector2(0,8),1.5,Color("#b79870",fade*.6))
		"lib_rock_1":
			# Pebble Shot: compact irregular stone with a sparse gravel trail.
			var q:=Vector2(8+28*drive,23-4*sin(drive*PI))
			earth_rock(im,q,4.0,Color("#c3b7a5",fade),Color("#655e57",fade))
			fx_line(im,q-Vector2(11*fade,0),q-Vector2(4,0),1.2,Color("#c5b59e",fade))
			for j in range(4):
				var p:=q+Vector2(-7-float(j)*3,3+float(j%2)*3)
				fx_disc(im,p,1.0,Color("#9d9485",fade))
			if t>=peak:
				for j in range(5):
					var a:float=float(j)*TAU/5.0
					var p:=q+Vector2(cos(a),sin(a))*(4+9*(1.0-fade))
					earth_rock(im,p,1.8,Color("#d2c7b6",fade),Color("#746b62",fade))
		"lib_rock_2":
			# Boulder Rush: huge faceted boulder pushes forward with a compressed gravel wake.
			var q:=Vector2(12+21*drive,26)
			earth_rock(im,q,9+2*pulse,Color("#a69b8d",fade),Color("#514b47",fade))
			var a:float=t*TAU
			for j in range(3):
				var b:float=a+float(j)*TAU/3.0
				var d:=Vector2(cos(b),sin(b))
				fx_line(im,q,q+d*7,1.3,Color("#d1c4af",fade))
			for j in range(6):
				var p:=q+Vector2(-10-float(j)*2,5+sin(float(j)*2.4+t*TAU)*5)
				earth_rock(im,p,2.0+float(j%2),Color("#b8a68c",fade),Color("#766b5e",fade))
			if t>=peak:
				fight_arc(im,q,12+5*(1.0-fade),-PI*.65,PI*1.3,Color("#e6d7be",fade),Color("#978675",fade),2.4)
		"lib_rock_3":
			# Crystal Avalanche: angular crystal columns tumble down in a staggered cascade.
			for j in range(6):
				var f:float=clampf(drive*1.5-float(j)*.10,0.0,1.0)
				var q:=Vector2(8+float(j)*6,5+29*f)
				var a:float=PI*.5+sin(float(j)*2.4+t*TAU)*.4
				var d:=Vector2(cos(a),sin(a))
				var n:=Vector2(-d.y,d.x)
				var tip:=q+d*7
				fx_line(im,q-d*4,tip,4.2,Color("#596e83",fade))
				fx_line(im,q+n*2,tip,2.2,Color("#a1c6d4",fade))
				fx_line(im,q-n*2,tip,1.2,Color("#e4f3ed",fade))
				if f>.85:
					for k in range(3):
						var p:=q+Vector2(float(k-1)*5,6+float(k%2)*2)
						earth_rock(im,p,1.8,Color("#c7d9da",fade),Color("#61717c",fade))
		"eos_093":
			# Ancientpower: levitating ancient stones orbit an amber energy core.
			var c:=Vector2(24,24)
			var rad:float=6+10*drive
			fx_disc(im,c,5+2*pulse,Color("#a78046",fade))
			fx_disc(im,c,3.4+2*pulse,Color("#f4d99c",fade))
			for j in range(6):
				var a:float=float(j)*TAU/6.0+t*TAU
				var d:=Vector2(cos(a),sin(a)*.82)
				var q:=c+d*rad
				fx_line(im,c+d*5,q,1.0,Color("#d3ae72",fade*.65))
				earth_rock(im,q,3.6+float(j%2),Color("#bb9e76",fade),Color("#685643",fade))
				fairy_star(im,q-Vector2(2,3),1.3,Color("#ffe8a9",fade))
		"eos_453":
			# Rock Wrecker: giant dense stone projectile fractures violently upon contact.
			var c:=Vector2(11+23*drive,24)
			if t<peak:
				earth_rock(im,c,11.0,Color("#b7aea2",fade),Color("#49484a",fade))
				fx_line(im,c-Vector2(6,4),c+Vector2(5,4),1.8,Color("#666466",fade))
				fx_line(im,c+Vector2(0,-7),c+Vector2(0,1),1.3,Color("#d9d4c6",fade))
				for j in range(3):
					fx_line(im,c-Vector2(11,5-float(j)*5),c-Vector2(19,5-float(j)*5),1.4,Color("#aaa094",fade))
			else:
				for j in range(10):
					var a:float=float(j)*TAU/10.0
					var d:=Vector2(cos(a),sin(a))
					var q:=c+d*(4+14*(1.0-fade))
					earth_rock(im,q,2.5+float(j%3)*.7,Color("#c2b9ab",fade),Color("#615d5b",fade))
					fx_line(im,c+d*3,q,1.2,Color("#e8d9bd",fade))
				fx_disc(im,c,5+4*fade,Color("#fff0d4",fade))
		"eos_512":
			# Power Gem: rotating jewel facets refract a luminous mineral beam.
			var c:=Vector2(10,24)
			var h:float=5+2*pulse
			var w:float=3+3*absf(cos(t*TAU))
			fx_line(im,c-Vector2(w,0),c+Vector2(w,0),5.2,Color("#665783",fade))
			fx_line(im,c-Vector2(0,h),c+Vector2(0,h),3.3,Color("#bba9e0",fade))
			fx_line(im,c-Vector2(w,0),c-Vector2(0,h),1.6,Color("#e3d8ff",fade))
			fx_line(im,c+Vector2(w,0),c+Vector2(0,h),1.6,Color("#8b83b8",fade))
			var q:=Vector2(12+28*drive,24)
			fx_line(im,c+Vector2(4,0),q,4.6,Color("#947ab7",fade))
			fx_line(im,c+Vector2(4,0),q,2.3,Color("#f2dcf5",fade))
			for j in range(5):
				var p:=Vector2(14+float(j)*5*drive,24+sin(float(j)*2.4+t*TAU)*5)
				fairy_star(im,p,1.5,Color("#f9f2cf",fade))
		"eos_533":
			# Head Smash: angular stone ram silhouette and compressed impact shock.
			var q:=Vector2(9+25*drive,23)
			earth_rock(im,q,7.5,Color("#b7ac9a",fade),Color("#554e48",fade))
			fx_line(im,q-Vector2(3,4),q+Vector2(10,0),4.4,Color("#766d63",fade))
			fx_line(im,q-Vector2(3,5),q+Vector2(10,-1),1.6,Color("#d8cbb7",fade))
			for j in range(4):
				var y:float=16+float(j)*5
				fx_line(im,Vector2(q.x-19,y),Vector2(q.x-7,y),1.5,Color("#ab9d8b",fade))
			if t>=peak:
				for j in range(8):
					var a:float=float(j)*TAU/8.0
					var d:=Vector2(cos(a),sin(a))
					fx_line(im,q+d*5,q+d*(10+8*(1.0-fade)),2.0,Color("#f2dfbf",fade))
					if j%2==0:earth_rock(im,q+d*12,2.5,Color("#b9ae9c",fade),Color("#6c6258",fade))
		"eos_350":
			# Stone Volley: sequential small angular stones in separate flight lanes.
			for j in range(4):
				var f:float=fposmod(t*1.6+float(j)*.25,1.0)
				var q:=Vector2(7+32*f,17+float(j)*4-3*sin(f*PI))
				earth_rock(im,q,3.0+float(j%2)*.7,Color("#c0b4a4",fade),Color("#696159",fade))
				fx_line(im,q-Vector2(8,0),q-Vector2(3,0),1.1,Color("#bdab94",fade))
				if f>.8:
					for k in range(3):
						var p:=q+Vector2(float(k)*2,float(k-1)*5)
						fx_disc(im,p,1.3,Color("#e1d2bb",fade))
		"eos_105":
			# Boulder Tumble: rolling ring of rotating facets and ground-contact chips.
			var c:=Vector2(10+24*drive,28)
			var rad:float=5+4*drive
			fx_disc(im,c,rad,Color("#645b54",fade))
			for j in range(8):
				var a:float=float(j)*TAU/8.0+t*TAU*2
				var d:=Vector2(cos(a),sin(a))
				var q:=c+d*(rad-2)
				earth_rock(im,q,2.7,Color("#b7a894",fade),Color("#76695c",fade))
				fx_line(im,c,q,1.1,Color("#968775",fade))
			fx_disc(im,c,2.4,Color("#c7b7a0",fade))
			for j in range(5):
				var q:=c+Vector2(-9-float(j)*3,8+sin(float(j)*2.4)*3)
				fx_disc(im,q,1.6,Color("#d2bb9a",fade))
		"eos_540":
			# Polished Stone: stationary stone gains a reflective surface through sweeping highlights.
			var c:=Vector2(24,26)
			earth_rock(im,c,10.0,Color("#a6a5a6",fade),Color("#53565d",fade))
			var x:float=-8+16*drive
			fx_line(im,c+Vector2(x,-8),c+Vector2(x+5,6),2.6,Color("#cfd4d6",fade))
			fx_line(im,c+Vector2(x+1,-7),c+Vector2(x+4,4),1.1,Color("#ffffff",fade))
			for j in range(5):
				var a:float=float(j)*TAU/5.0+t*TAU
				var q:=c+Vector2(cos(a),sin(a))*(11+4*pulse)
				fairy_star(im,q,2.2,Color("#f0f3ef",fade))
			fx_disc(im,c,13+3*drive,Color("#b0c4cd",fade*.5),12+3*drive)
		"eos_141":
			# Dune Storm: windborne sand sheets and mineral grit moving diagonally.
			for j in range(5):
				var prev:=Vector2(3,9+float(j)*7)
				for k in range(1,16):
					var f:float=float(k)/15.0
					var q:=Vector2(3+40*f,9+float(j)*7-5*f+sin(f*TAU-t*TAU+float(j))*2.4)
					fx_line(im,prev,q,2.0,Color("#b2a083",fade*.46))
					fx_line(im,prev,q,.8,Color("#e5d0a5",fade*.66))
					prev=q
			for j in range(20):
				var x:float=4+fposmod(float(j)*11+t*40,40.0)
				var y:float=5+float(posmod(j*13,38))
				fx_disc(im,Vector2(x,y),1.0+float(j%3)*.35,Color("#d3b98d",fade*.85))
		"eos_480":
			# Hidden Crags: angular floating stone shards settle into a concealed perimeter.
			var c:=Vector2(24,30)
			for j in range(8):
				var a:float=float(j)*TAU/8.0
				var d:=Vector2(cos(a),sin(a)*.48)
				var q:=c+d*(6+12*drive)-Vector2(0,9*sin(drive*PI))
				var tip:=q+Vector2(sin(a)*2,-7)
				fx_line(im,q-Vector2(3,0),tip,2.7,Color("#645c56",fade))
				fx_line(im,q+Vector2(3,0),tip,2.2,Color("#b0a391",fade))
				fx_line(im,q,tip,1.0,Color("#d8cbb9",fade))
				if t>=peak:fx_disc(im,q+Vector2(0,4),4.0,Color("#a09482",fade*.55),3.0)
			for j in range(5):
				var a:float=float(j)*TAU/5.0+t
				fx_disc(im,c+Vector2(cos(a)*17,sin(a)*8),1.1,Color("#d2c3ad",fade))
		"lib_flying_1":
			# Feather Needle: slim feather darts with distinct shafts and aerodynamic trails.
			for j in range(3):
				var q:=Vector2(7+28*drive-float(j)*4,18+float(j)*6)
				air_feather(im,q,-.18+float(j)*.18,10.0,Color("#f0f9ff",fade),Color("#7999b0",fade))
				fx_line(im,q-Vector2(9,0),q,1.0,Color("#b5dbed",fade))
				if t>=peak:fx_disc(im,q+Vector2(7,0),1.4,Color("#ffffff",fade))
		"lib_flying_2":
			# Gale Scythe: broad curved air blade with tapered secondary edge.
			var c:=Vector2(12+20*drive,24)
			fight_arc(im,c,12+4*pulse,-PI*.75+t*.55,PI*1.25,Color("#f2ffff",fade),Color("#7ea9b9",fade),4.2)
			fight_arc(im,c-Vector2(5,0),9.0,-PI*.65+t*.55,PI*.95,Color("#cbe9f4",fade*.7),Color("#83b2c6",fade*.5),1.4)
			for j in range(5):
				var q:=c+Vector2(-12+float(j)*4,-9+float(j%3)*8)
				fx_line(im,q-Vector2(5,0),q,1.0,Color("#c7e7ee",fade))
		"lib_flying_3":
			# Cyclone Ring: ascending tapered vortex with a clear central eye.
			var c:=Vector2(24,35)
			for ring in range(5):
				var rad:float=4+float(ring)*3+2*drive
				var z:float=float(ring)*5*drive
				var prev:=c+Vector2(rad,-z)
				for j in range(1,33):
					var a:float=float(j)*TAU/32.0
					var q:=c+Vector2(cos(a)*rad,sin(a)*rad*.35-z)
					fx_line(im,prev,q,1.8,Color("#90b8cc",fade*.7))
					fx_line(im,prev,q,.8,Color("#e3f7ff",fade))
					prev=q
				var a:float=t*TAU*2+float(ring)
				var q:=c+Vector2(cos(a)*rad,sin(a)*rad*.35-z)
				air_feather(im,q,a+PI*.5,6.0,Color("#eafaff",fade),Color("#91b4cb",fade))
		"eos_174":
			# Peck: a brief pointed beak strikes with a tight impact star.
			var q:=Vector2(8+27*drive,24)
			fx_line(im,q-Vector2(12,5),q+Vector2(6,0),3.3,Color("#8a795d",fade))
			fx_line(im,q-Vector2(12,-5),q+Vector2(6,0),3.0,Color("#e5cb93",fade))
			fx_line(im,q-Vector2(10,0),q+Vector2(6,0),1.2,Color("#fff1c9",fade))
			if t>=peak:
				fairy_star(im,q+Vector2(6,0),5+3*(1.0-fade),Color("#f9f6de",fade))
				for j in range(3):
					var p:=q+Vector2(9+float(j)*2,float(j-1)*5)
					fx_disc(im,p,1.1,Color("#f1e0b8",fade))
		"eos_179":
			# Aerial Ace: two intersecting precision slashes along a swift trajectory.
			var q:=Vector2(9+25*drive,24)
			for j in range(2):
				var a:float=-PI*.75+float(j)*PI*.7
				fight_arc(im,q+Vector2(float(j)*3,-3+float(j)*6),10.0,a,PI*.9,Color("#f3ffff",fade),Color("#86b6cc",fade),3.0)
			for j in range(4):
				var y:float=14+float(j)*7
				fx_line(im,Vector2(q.x-19,y+4),Vector2(q.x-5,y),1.2,Color("#d0edf7",fade))
			if t>=peak:fairy_star(im,q,4.2,Color("#f9ffff",fade))
		"eos_211":
			# Drill Peck: spiraling pressure bands surround the pointed rotating beak.
			var q:=Vector2(10+24*drive,24)
			fx_line(im,q-Vector2(13,0),q+Vector2(7,0),3.4,Color("#b7a183",fade))
			fx_line(im,q-Vector2(11,-2),q+Vector2(7,0),1.5,Color("#fff2d1",fade))
			for j in range(18):
				var f:float=float(j)/17.0
				var a:float=f*TAU*2.0-t*TAU*2.0
				var p:=q+Vector2(-16+21*f,sin(a)*(7-5*f))
				fx_disc(im,p,1.3,Color("#a7c7da",fade))
				fx_disc(im,p-Vector2(0,1),.8,Color("#f0ffff",fade))
			if t>=peak:
				for j in range(5):
					var a:float=float(j)*TAU/5.0
					var d:=Vector2(cos(a),sin(a))
					fx_line(im,q+d*5,q+d*(9+6*(1.0-fade)),1.2,Color("#e7f6ff",fade))
		"eos_353":
			# Aeroblast: compressed widening wind tunnel with a dense central air jet.
			var end_x:float=7+35*drive
			for band in range(5):
				var prev:=Vector2(4,24)
				for j in range(1,18):
					var f:float=float(j)/17.0
					var q:=Vector2(4+(end_x-4)*f,24+float(band-2)*5*f+sin(f*TAU*2-t*TAU)*1.3)
					fx_line(im,prev,q,2.6,Color("#85b3c9",fade*.75))
					fx_line(im,prev,q,1.2,Color("#e4faff",fade))
					prev=q
			for j in range(3):
				var x:float=8+(end_x-8)*float(j+1)/3.0
				fight_arc(im,Vector2(x-5,24),5+float(j)*3,-PI*.46,PI*.92,Color("#ffffff",fade),Color("#a1cfe0",fade),1.6)
		"eos_446":
			# Chatter: irregular bursts of sound with colored musical notes and wavelets.
			var c:=Vector2(24,24)
			for j in range(4):
				var rad:float=4+float(j)*4+5*drive
				fight_arc(im,c,rad,-PI*.72+float(j)*.22,PI*.9,Color("#d9b7ee",fade),Color("#8295c6",fade),1.4)
			for j in range(5):
				var a:float=float(j)*TAU/5.0+t*1.8
				var q:=c+Vector2(cos(a),sin(a))*(6+10*drive)
				var tint:=Color("#f9deb1" if j%2==0 else "#d3c9fa",fade)
				fx_disc(im,q,2.0,tint)
				fx_line(im,q+Vector2(1,0),q+Vector2(1,-7),1.1,tint)
				fx_line(im,q+Vector2(1,-7),q+Vector2(5,-5),1.1,tint)
		"eos_490":
			# Pluck: snapping beak and a single extracted feather flutters upward.
			var q:=Vector2(10+23*drive,24)
			var gap:float=7*(1.0-drive)+1
			fx_line(im,q-Vector2(10,gap),q+Vector2(7,0),3.2,Color("#9d855f",fade))
			fx_line(im,q-Vector2(10,-gap),q+Vector2(7,0),2.1,Color("#f4d9a6",fade))
			if t>=peak:
				var f:float=1.0-fade
				air_feather(im,q+Vector2(-13*f,-4-10*f),-2.0+t*3,13.0,Color("#fff1ce",fade),Color("#af9979",fade))
				for j in range(3):fx_disc(im,q+Vector2(float(j)*3,-5-float(j)*3),1.1,Color("#eadcc0",fade))
		"eos_444":
			# Wind Escort: directional tailwind ribbons sweep past the caster.
			for j in range(4):
				var prev:=Vector2(3,12+float(j)*7)
				for k in range(1,17):
					var f:float=float(k)/16.0
					var q:=Vector2(3+40*f,12+float(j)*7+sin(f*TAU-t*TAU+float(j))*3)
					fx_line(im,prev,q,1.7,Color("#9bbfca",fade*.7))
					fx_line(im,prev,q,.8,Color("#eefcfa",fade))
					prev=q
			for j in range(4):
				var f:float=fposmod(t+float(j)*.25,1.0)
				var q:=Vector2(5+36*f,13+float(j)*7)
				air_feather(im,q,-.35,7.0,Color("#e8fff0",fade),Color("#8cb7ad",fade))
		"eos_267":
			# Feather Veil: a soft defensive curtain of descending overlapping feathers.
			for j in range(10):
				var f:float=float(j)/9.0
				var q:=Vector2(9+30*f,9+23*drive+sin(float(j)*2.4+t*TAU)*5)
				air_feather(im,q,1.3+sin(float(j)+t*TAU)*.5,10.0,Color("#f0f5ef",fade),Color("#b1b9c5",fade))
				if j%2==0:fx_disc(im,q-Vector2(0,5),1.1,Color("#ffffff",fade))
			fx_disc(im,Vector2(24,35),10+5*drive,Color("#d7e5e4",fade*.5),9+5*drive)
		"eos_509":
			# Feather Rest: folded feather nest with gentle rising healing glints.
			var c:=Vector2(24,33)
			for j in range(8):
				var a:float=PI+float(j)*PI/7.0
				var q:=c+Vector2(cos(a)*13,sin(a)*4)
				air_feather(im,q,a,11.0,Color("#e8f5e5",fade),Color("#8caca2",fade))
			for j in range(6):
				var f:float=fposmod(t+float(j)*.17,1.0)
				var q:=c+Vector2(sin(float(j)*2.4+t)*9,-23*f)
				fairy_star(im,q,1.6,Color("#c7f2c5",fade))
			fx_disc(im,c,9+4*pulse,Color("#a7d4ba",fade*.5),8+4*pulse)
		"eos_456":
			# Clear Gust: broad outward gust visibly disperses fog banks.
			for j in range(7):
				var a:float=float(j)*TAU/7.0+t*.4
				var d:=Vector2(cos(a),sin(a))
				var c:=Vector2(24,24)
				var q:=c+d*(5+13*drive)
				fx_disc(im,q,4.5*(1.0-drive)+1,Color("#a1b9c3",fade*(1.0-drive)))
				fx_line(im,c+d*4,q+d*6,1.8,Color("#d3eef2",fade))
				fx_line(im,c+d*7,q+d*4,.8,Color("#ffffff",fade))
			for j in range(3):
				fight_arc(im,Vector2(24,24),5+float(j)*4+4*drive,t*TAU+float(j),PI*.95,Color("#e2f6fc",fade),Color("#9cbbc6",fade),1.2)
		"eos_040":
			# Mirror Veil: reflective elliptical wind shield with a traveling specular stripe.
			var c:=Vector2(24,24)
			var rad:float=7+9*drive
			var prev:=c+Vector2(rad*.68,0)
			for j in range(1,37):
				var a:float=float(j)*TAU/36.0
				var q:=c+Vector2(cos(a)*rad*.68,sin(a)*rad)
				fx_line(im,prev,q,2.9,Color("#7facc9",fade*.8))
				fx_line(im,prev,q,1.2,Color("#e8fbff",fade))
				prev=q
			var x:float=-7+14*drive
			fx_line(im,c+Vector2(x,-rad*.72),c+Vector2(x+5,rad*.55),2.4,Color("#c5e6f7",fade*.75))
			fx_line(im,c+Vector2(x+1,-rad*.65),c+Vector2(x+4,rad*.4),.9,Color("#ffffff",fade))
			for j in range(4):
				var a:float=float(j)*TAU/4.0+t
				fairy_star(im,c+Vector2(cos(a)*rad*.68,sin(a)*rad),1.6,Color("#f1ffff",fade))
		"lib_bug_1":
			# Silk Snare: a wound silk spool launches and unravels around the target.
			var c:=Vector2(9+25*drive,24)
			if t<peak:
				fx_disc(im,c,4.5,Color("#9d9c87",fade))
				for j in range(5):
					var y:float=-3+float(j)*1.5
					fx_line(im,c+Vector2(-3,y),c+Vector2(3,y+1),1.1,Color("#f2efdc",fade))
				var prev:=Vector2(4,24)
				for j in range(1,19):
					var f:float=float(j)/18.0
					var q:=Vector2(4+(c.x-4)*f,24+sin(f*TAU*2-t*TAU)*3*f)
					fx_line(im,prev,q,1.6,Color("#b0ad97",fade))
					fx_line(im,prev,q,.8,Color("#f7f5e7",fade))
					prev=q
			else:
				var rad:float=14-6*(1.0-fade)
				for band in range(3):
					var prev:=c+Vector2(rad,0)
					for j in range(1,33):
						var a:float=float(j)*TAU/32.0
						var q:=c+Vector2(cos(a)*rad,sin(a)*rad*.48+float(band-1)*6)
						if j>1:
							fx_line(im,prev,q,2.1,Color("#a29e87",fade))
							fx_line(im,prev,q,1.0,Color("#f8f3df",fade))
						prev=q
				for j in range(4):
					var x:float=-7+float(j)*4.5
					fx_line(im,c+Vector2(x,-10),c+Vector2(-x,10),.8,Color("#dfddc7",fade*.8))
		"lib_bug_2":
			# Carapace Charge: armored beetle shell rush, segmented plates and horn.
			var c:=Vector2(10+23*drive,24)
			var outline:=Color("#394b2b",fade)
			var armor:=Color("#829c48",fade)
			var highlight:=Color("#d5e3a1",fade)
			fx_disc(im,c-Vector2(3,0),9.0,outline)
			fx_disc(im,c-Vector2(3,1),7.0,armor)
			fx_line(im,c+Vector2(-3,-7),c+Vector2(-3,7),1.2,outline)
			for j in range(3):
				var x:float=-8+float(j)*4.5
				fight_arc(im,c+Vector2(x,0),5.0,-PI*.48,PI*.96,highlight,outline,1.4)
			fx_disc(im,c+Vector2(5,0),4.5,outline)
			fx_disc(im,c+Vector2(5,-1),3.0,armor)
			fx_line(im,c+Vector2(5,-2),c+Vector2(13,0),2.8,outline)
			fx_line(im,c+Vector2(5,-2),c+Vector2(13,0),1.1,highlight)
			for j in range(4):
				var y:float=15+float(j)*6
				fx_line(im,Vector2(c.x-18,y),Vector2(c.x-11,y),1.1,Color("#b9c791",fade))
			if t>=peak:
				for j in range(7):
					var a:float=float(j)*TAU/7.0
					var d:=Vector2(cos(a),sin(a))
					fx_line(im,c+d*6,c+d*(11+5*(1.0-fade)),1.7,Color("#e8edb0",fade))
		"lib_bug_3":
			# Wing Scales: fluttering moth wings shed iridescent scales into a soft cloud.
			var c:=Vector2(10+18*drive,24)
			var spread:float=.65+.45*absf(sin(t*TAU*2))
			for side in [-1.0,1.0]:
				var a:float=side*PI*.6
				var q:=c+Vector2(-3,side*5*spread)
				bug_wing(im,q,a,8.5*spread,Color("#e0e8b9",fade),Color("#798b65",fade))
				fx_line(im,c,q,1.2,Color("#b7c79b",fade))
			fx_disc(im,c,2.2,Color("#66794f",fade))
			for j in range(18):
				var f:float=float(j)/17.0
				var q:=Vector2(7+32*f,24+sin(float(j)*2.4+t*TAU)*12*(.3+.7*drive))
				var hue:Color=Color("#d4e5b2",fade).lerp(Color("#c9c6e8",fade),float(j%4)/3.0)
				var a:float=t*TAU+float(j)*.7
				var d:=Vector2(cos(a),sin(a))
				fx_line(im,q-d*1.5,q+d*1.5,1.1,hue)
				if j%4==0:fx_disc(im,q,2.6,Color(hue,fade*.22))
				if j%5==0:fairy_star(im,q,1.2,Color("#f8f6de",fade))
		"lib_psychic_1":
			# Mind Spear: sharp magenta lance with a vibrating psychic wake.
			var q:=Vector2(8+28*drive,24)
			fx_line(im,q-Vector2(19*fade,0),q+Vector2(7,0),4.2,Color("#694298",fade))
			fx_line(im,q-Vector2(14*fade,0),q+Vector2(7,0),2.1,Color("#ffc7f4",fade))
			for j in range(5):
				var p:=q-Vector2(4+float(j)*3,sin(t*TAU+float(j))*5)
				fx_disc(im,p,1.3,Color("#e2b6ff",fade))
			if t>=peak:fairy_star(im,q+Vector2(6,0),5.0,Color("#fff0ff",fade))
		"lib_psychic_2":
			# Mirage Pulse: offset ghost images of a traveling elliptical wave.
			for j in range(4):
				var f:float=float(j)/3.0
				var q:=Vector2(9+26*drive-11*f,24+sin(t*TAU+f*3)*4)
				var rad:float=5+6*f
				psi_ring(im,q,rad,Color("#b4d7f5",fade*(1.0-f*.65)),Color("#9b6cb3",fade*(1.0-f*.65)))
				fx_line(im,q-Vector2(3,0),q+Vector2(3,0),1.0,Color("#f4c8eb",fade))
		"lib_psychic_3":
			# Astral Crush: four astral masses compress inward then release a starburst.
			var c:=Vector2(24,24)
			for j in range(4):
				var a:float=float(j)*PI*.5
				var d:=Vector2(cos(a),sin(a))
				var q:=c+d*(17-12*drive)
				psi_polygon(im,q,5.5,4,PI*.25+t,Color("#c9b6ff",fade),Color("#5d498f",fade))
				fx_line(im,q,c+d*3,1.6,Color("#e7bbff",fade))
			if t>=peak:
				for j in range(8):
					var a:float=float(j)*TAU/8.0
					var d:=Vector2(cos(a),sin(a))
					fx_line(im,c+d*3,c+d*(7+14*(1.0-fade)),1.8,Color("#ffe1ff",fade))
			fx_disc(im,c,3+4*pulse,Color("#f4d6ff",fade))
		"eos_110":
			# Psycho Boost: explosive concentrated core, long radial rays and bright satellite fragments.
			var c:=Vector2(24,24)
			fx_disc(im,c,5+7*drive,Color("#7344a9",fade))
			fx_disc(im,c,3+5*drive,Color("#f6baff",fade))
			fx_disc(im,c,2+3*pulse,Color("#fff4dc",fade))
			for j in range(12):
				var a:float=float(j)*TAU/12.0+t*.3
				var d:=Vector2(cos(a),sin(a))
				var rad:float=7+11*drive+3*(1.0-fade)
				fx_line(im,c+d*4,c+d*rad,2.0+float(j%2),Color("#c578f5",fade))
				fx_disc(im,c+d*rad,1.4,Color("#fff0ff",fade))
		"eos_309":
			# Mist Ball: luminous soft orb wrapped in wispy pink fog.
			var q:=Vector2(9+25*drive,24)
			for j in range(8):
				var a:float=float(j)*TAU/8.0+t*TAU
				var p:=q+Vector2(cos(a),sin(a))*(5+3*pulse)
				fx_disc(im,p,3.8,Color("#b0a0d4",fade*.5))
				fx_disc(im,p-Vector2(1,1),2.1,Color("#e5d7f6",fade*.65))
			fx_disc(im,q,5.2,Color("#d9b7eb",fade))
			fx_disc(im,q-Vector2(1,2),2.8,Color("#fdf4ff",fade))
			if t>=peak:fx_disc(im,q,10+8*(1.0-fade),Color("#e1c5ee",fade*.6),8+8*(1.0-fade))
		"eos_335":
			# Luster Purge: white-gold flash refracted through a prismatic psychic halo.
			var c:=Vector2(24,24)
			psi_polygon(im,c,7+8*drive,6,t*.8,Color("#f9e7ff",fade),Color("#a66ac4",fade))
			for j in range(8):
				var a:float=float(j)*TAU/8.0
				var d:=Vector2(cos(a),sin(a))
				fx_line(im,c+d*3,c+d*(5+15*drive),2.0 if j%2==0 else 1.0,Color("#ffedcc",fade))
				fairy_star(im,c+d*(10+8*drive),1.4,Color("#fff7f6",fade))
			fx_disc(im,c,4+5*pulse,Color("#ffffff",fade))
		"eos_473":
			# Zen Headbutt: psychic forehead crest with a forward shock front.
			var q:=Vector2(10+24*drive,24)
			fight_arc(im,q,10.0,-PI*.58,PI*1.16,Color("#ffcbf7",fade),Color("#8050bb",fade),4.4)
			psi_polygon(im,q,5.2,3,0.0,Color("#e6daff",fade),Color("#8250ac",fade))
			for j in range(3):
				fx_line(im,q+Vector2(-15,5*float(j-1)),q+Vector2(-6,5*float(j-1)),1.2,Color("#c1b3ec",fade))
			if t>=peak:fairy_star(im,q+Vector2(8,0),6.0,Color("#fff2df",fade))
		"eos_099":
			# Astral Ward: orbiting constellation around a protective star seal.
			var c:=Vector2(24,24)
			psi_ring(im,c,8+5*drive,Color("#d1b5ff",fade),Color("#604a91",fade))
			var prev:=c+Vector2(16,0)
			for j in range(1,8):
				var a:float=float(j)*TAU/7.0+t
				var q:=c+Vector2(cos(a),sin(a))*16
				fx_line(im,prev,q,.8,Color("#aaa6e9",fade*.7))
				fairy_star(im,q,2.0,Color("#fff0c9",fade))
				prev=q
		"eos_146":
			# Mind Distortion: bent spoon-like glyph with rippling spatial grid.
			var c:=Vector2(24,24)
			for j in range(4):
				var prev:=Vector2(7,11+float(j)*8)
				for k in range(1,13):
					var f:float=float(k)/12.0
					var q:=Vector2(7+34*f,11+float(j)*8+sin(f*TAU+t*TAU)*5*drive)
					fx_line(im,prev,q,1.0,Color("#b19adb",fade*.65))
					prev=q
			fx_line(im,c-Vector2(9,10),c+Vector2(2,2),2.6,Color("#d5c8f1",fade))
			fx_line(im,c+Vector2(2,2),c+Vector2(9,-2),2.6,Color("#d5c8f1",fade))
			fx_disc(im,c+Vector2(11,-3),4.0,Color("#a78cd5",fade),2.1)
		"eos_215":
			# Blank Mind: memory motes evaporate from a fading thought cloud.
			var c:=Vector2(24,26)
			for j in range(7):
				var q:=c+Vector2(-10+float(j)*3.3,-4+sin(float(j)*2.4)*3)
				fx_disc(im,q,4.5,Color("#c4b6e3",fade*(1.0-drive*.65)))
			for j in range(6):
				var q:=c+Vector2(-13+float(j)*5,-6-17*drive)
				fx_disc(im,q,2.6*(1.0-drive)+.6,Color("#eee8ff",fade*(1.0-drive*.8)))
				fx_line(im,q+Vector2(0,3),q+Vector2(0,6),.8,Color("#bba5db",fade*.5))
		"eos_258":
			# Mind Barrier: interlocking hexagonal panels form a rigid enclosure.
			var c:=Vector2(24,24)
			var rad:float=7+10*drive
			psi_polygon(im,c,rad,6,PI*.5,Color("#aee8ff",fade),Color("#6959ab",fade))
			for j in range(6):
				var a:float=float(j)*TAU/6.0+PI*.5
				var q:=c+Vector2(cos(a),sin(a))*rad*.6
				psi_polygon(im,q,4.0,6,PI*.5,Color("#d3d6ff",fade*.7),Color("#8579c4",fade*.6))
		"eos_319":
			# Tranquil Focus: slow expanding gentle rings and a centered lotus-like light.
			var c:=Vector2(24,29)
			for j in range(3):
				var rad:float=6+float(j)*5+3*drive
				fight_arc(im,c,rad,PI,PI,Color("#bde8ed",fade*.85),Color("#8498c9",fade*.6),1.3)
			for j in range(5):
				var a:float=PI+float(j)*PI/4.0
				var d:=Vector2(cos(a),sin(a))
				fx_line(im,c,c+d*(7+4*drive),2.7,Color("#dfc4f7",fade))
			fx_disc(im,c,3.0,Color("#fdf1ff",fade))
		"eos_333":
			# Inner Focus: nested rotating mandala with golden central point.
			var c:=Vector2(24,24)
			psi_polygon(im,c,12+4*drive,8,t*PI,Color("#f0b9ff",fade),Color("#7954a9",fade))
			psi_polygon(im,c,7+2*drive,4,-t*PI,Color("#ffe4b1",fade),Color("#ad70c5",fade))
			for j in range(8):
				var a:float=float(j)*TAU/8.0
				fx_disc(im,c+Vector2(cos(a),sin(a))*10,1.0,Color("#ffe6bd",fade))
			fx_disc(im,c,2+2*pulse,Color("#fff3d0",fade))
		"eos_095":
			# Fleet Mind: fast directional thought streaks and afterimage chevrons.
			for j in range(5):
				var q:=Vector2(5+float(j)*7+4*drive,24+sin(float(j)*1.8+t*TAU)*5)
				fx_line(im,q-Vector2(5,5),q+Vector2(3,0),2.0,Color("#7f9bd4",fade))
				fx_line(im,q-Vector2(5,-5),q+Vector2(3,0),1.2,Color("#d8f5ff",fade))
				fx_line(im,q-Vector2(11,0),q-Vector2(4,0),.9,Color("#b6c0ed",fade))
		"eos_316":
			# Arcane Reversal: an incoming pulse reflects off a tilted mirror.
			var c:=Vector2(24,24)
			psi_polygon(im,c,12,4,PI*.25,Color("#b9e7ff",fade),Color("#625eaa",fade))
			fx_line(im,c-Vector2(6,-8),c+Vector2(6,-8),1.2,Color("#f5eaff",fade))
			var q:=Vector2(6+18*drive,31-7*drive)
			if t>=peak:q=c+Vector2(-16*(1.0-fade),-14*(1.0-fade))
			fx_line(im,q+Vector2(-5,3),q,2.2,Color("#d8b8f9",fade))
			fairy_star(im,q,3.0,Color("#fff0ff",fade))
		"eos_338":
			# Physical Ward: dense forward shield plates and deflected impact streaks.
			var c:=Vector2(24,24)
			for j in range(3):
				var rad:float=9+float(j)*3+2*drive
				fight_arc(im,c,rad,-PI*.58,PI*1.16,Color("#d6f1ff",fade),Color("#657eb0",fade),2.8)
			for j in range(5):
				var q:=Vector2(31+float(j%2)*5,10+float(j)*7)
				fx_line(im,q,q+Vector2(5,-4),1.2,Color("#d7edff",fade))
		"eos_259":
			# Arcane Ward: vertical gold-pink light curtain with luminous panel divisions.
			var c:=Vector2(24,24)
			psi_polygon(im,c,12+3*drive,4,PI*.25,Color("#ffd9e5",fade),Color("#9d72be",fade))
			for j in range(5):
				var x:float=11+float(j)*6
				fx_line(im,Vector2(x,9),Vector2(x,39),1.8,Color("#f7ccae",fade*.8))
				fx_disc(im,Vector2(x,10+26*fposmod(t+float(j)*.2,1.0)),1.4,Color("#fff6d8",fade))
		"eos_108":
			# Mind Ripple: successive crescent pressure waves propagate in a straight line.
			for j in range(5):
				var x:float=5+float(j)*7+5*drive
				var rad:float=4+float(j)*1.7
				fight_arc(im,Vector2(x,24),rad,-PI*.52,PI*1.04,Color("#f0b8ff",fade),Color("#8366b9",fade),2.2)
				if j%2==0:fx_disc(im,Vector2(x,24),1.2,Color("#e1d5ff",fade))
		"eos_187":
			# Phase Step: shrinking departure portal with vertical displaced light fragments.
			var c:=Vector2(24,24)
			var rad:float=16-12*drive
			psi_ring(im,c,rad,Color("#d3c3ff",fade),Color("#7253b3",fade))
			for j in range(9):
				var a:float=float(j)*TAU/9.0+t*TAU
				var q:=c+Vector2(cos(a),sin(a))*rad
				fx_line(im,q,q-Vector2(0,6+float(j%3)*2),1.5,Color("#b5dcff",fade))
			if t>=peak:fairy_star(im,c,4*fade+1,Color("#fdf4ff",fade))
		"eos_266":
			# Stasis Seal: closing square cage with lock glyph and vertical bars.
			var c:=Vector2(24,24)
			var rad:float=18-5*drive
			psi_polygon(im,c,rad,4,PI*.25,Color("#f4b6e4",fade),Color("#7750a1",fade))
			for j in range(4):
				var x:float=14+float(j)*6.5
				fx_line(im,Vector2(x,11),Vector2(x,37),1.4,Color("#9f75c4",fade))
			fx_disc(im,c+Vector2(0,-3),4.0,Color("#f6d1f0",fade),2.3)
			fx_line(im,c+Vector2(-3,1),c+Vector2(3,5),3.5,Color("#d8a6df",fade))
		"eos_448":
			# Ward Exchange: two shield-shaped glyphs trade places along opposite arcs.
			for j in range(2):
				var f:float=drive if j==0 else 1.0-drive
				var q:=Vector2(10+28*f,24+(-1.0 if j==0 else 1.0)*8*sin(f*PI))
				var tint:=Color("#c5e7ff" if j==0 else "#f8c7ec",fade)
				psi_polygon(im,q,6.0,5,PI*.5,tint,Color("#7355aa",fade))
				fx_line(im,q-Vector2(4,0),q+Vector2(4,0),1.0,tint)
		"eos_506":
			# Balance Exchange: a tilting balance scale equalizes two luminous weights.
			var c:=Vector2(24,25)
			var tilt:float=8*(1.0-drive)
			fx_line(im,c,c+Vector2(0,12),2.0,Color("#c7b1e5",fade))
			fx_line(im,c+Vector2(-13,-tilt),c+Vector2(13,tilt),2.0,Color("#f3d7ab",fade))
			for j in range(2):
				var side:float=float(j*2-1)
				var q:=c+Vector2(side*13,side*tilt+6)
				fx_line(im,q-Vector2(0,6),q,1.0,Color("#e7cef0",fade))
				fx_disc(im,q,3.0+float(j)*(1.0-drive)*2,Color("#f6cbdf",fade))
		"eos_513":
			# Force Exchange: gold angular energy bolts cross between two endpoints.
			for j in range(2):
				var f:float=drive if j==0 else 1.0-drive
				var q:=Vector2(8+32*f,24+float(j*2-1)*7*sin(f*PI))
				var d:=Vector2(1.0 if j==0 else -1.0,0)
				fx_line(im,q-d*9,q,2.8,Color("#9e6bab",fade))
				fx_line(im,q,q-d*5+Vector2(0,-4),1.6,Color("#ffe1a5",fade))
				fx_line(im,q,q-d*5+Vector2(0,4),1.6,Color("#ffe1a5",fade))
				fairy_star(im,q,2.0,Color("#fff0c4",fade))
		"eos_514":
			# Inverted Stance: two opposing triangular glyphs rotate half a turn.
			var c:=Vector2(24,24)
			for j in range(2):
				var a:float=float(j)*PI+drive*PI
				var q:=c+Vector2(cos(a),sin(a))*10
				psi_polygon(im,q,6.0,3,a,Color("#f7c5fa" if j==0 else "#c7e6ff",fade),Color("#7254a9",fade))
			fight_arc(im,c,17.0,t*PI,PI*1.5,Color("#e6c4f3",fade),Color("#906bbd",fade),1.3)
		"eos_232":
			# Deep Rest: descending soft crescent and slowly rising Z glyphs.
			var c:=Vector2(15,29)
			fight_arc(im,c,9.0,-PI*.65,PI*1.5,Color("#b6d3ef",fade),Color("#7776b2",fade),4.2)
			for j in range(3):
				var q:=Vector2(20+float(j)*7,29-float(j)*7-6*drive)
				var w:float=3+float(j)
				fx_line(im,q,q+Vector2(w,0),1.2,Color("#dceaff",fade))
				fx_line(im,q+Vector2(w,0),q+Vector2(0,w),1.2,Color("#dceaff",fade))
				fx_line(im,q+Vector2(0,w),q+Vector2(w,w),1.2,Color("#dceaff",fade))
		"eos_464":
			# Burden Transfer: dark status motes leave the caster and cross into the target.
			for j in range(6):
				var f:float=clampf(drive-float(j)*.08,0.0,1.0)
				var q:=Vector2(9+30*f,24+sin(float(j)*2.4+t*TAU)*7)
				fx_disc(im,q,2.7,Color("#64517e",fade))
				fx_disc(im,q-Vector2(0,1),1.3,Color("#c9a9dc",fade))
				fx_line(im,q-Vector2(5,0),q,1.0,Color("#a586cb",fade))
			if t>=peak:psi_ring(im,Vector2(37,24),7.0,Color("#d7b6ea",fade),Color("#70528e",fade))
		"eos_478":
			# Gravity Field: downward arrows compress into a flattened ground well.
			var c:=Vector2(24,34)
			for j in range(5):
				var q:=Vector2(8+float(j)*8,7+22*drive)
				fx_line(im,q-Vector2(0,9),q,2.0,Color("#a69ad9",fade))
				fx_line(im,q-Vector2(4,5),q,1.6,Color("#e1ceff",fade))
				fx_line(im,q+Vector2(4,-5),q,1.6,Color("#e1ceff",fade))
			for j in range(3):
				var rad:float=7+float(j)*5
				fight_arc(im,c,rad,PI,PI,Color("#8a77c5",fade*.7),Color("#504b89",fade),1.4)
		"eos_528":
			# Mind Reveal: opening eye with a sweeping pupil and revealing rays.
			var c:=Vector2(24,24)
			var h:float=2+7*drive
			for j in range(2):
				var prev:=Vector2(9,24)
				for k in range(1,19):
					var f:float=float(k)/18.0
					var q:=Vector2(9+30*f,24+float(j*2-1)*sin(f*PI)*h)
					fx_line(im,prev,q,2.0,Color("#e6c8fa",fade))
					prev=q
			fx_disc(im,c+Vector2(sin(t*TAU)*4,0),4.3,Color("#dcb7f5",fade))
			fx_disc(im,c+Vector2(sin(t*TAU)*4,0),1.8,Color("#634791",fade))
			for j in range(3):
				var a:float=-PI*.7+float(j)*PI*.2
				var d:=Vector2(cos(a),sin(a))
				fx_line(im,c+d*10,c+d*17,1.0,Color("#f8dfed",fade))
		"eos_450":
			# Recovery Seal: crossed healing glyph inside a prohibition circle.
			var c:=Vector2(24,24)
			psi_ring(im,c,12+3*drive,Color("#f1a0be",fade),Color("#835b96",fade))
			fx_line(im,c-Vector2(0,6),c+Vector2(0,6),2.8,Color("#aee0c9",fade))
			fx_line(im,c-Vector2(6,0),c+Vector2(6,0),2.8,Color("#aee0c9",fade))
			fx_line(im,c-Vector2(9,9),c+Vector2(9,9),2.6,Color("#f292ac",fade))
		"eos_298":
			# Arcane Reflection: revolving magic sigil bounces a luminous spark outward.
			var c:=Vector2(24,24)
			psi_polygon(im,c,13,6,t*PI,Color("#e9bfff",fade),Color("#8360bf",fade))
			psi_ring(im,c,8.0,Color("#d0e4ff",fade),Color("#796ab3",fade))
			for j in range(6):
				var a:float=float(j)*TAU/6.0+t
				fairy_star(im,c+Vector2(cos(a),sin(a))*(8+7*drive),1.7,Color("#ffe2b8",fade))
		"eos_499":
			# Tempo Rift: clock face and reversing hands enclosed by skewed spatial frame.
			var c:=Vector2(24,24)
			psi_ring(im,c,13.0,Color("#d5c9ff",fade),Color("#7265aa",fade))
			for j in range(12):
				var a:float=float(j)*TAU/12.0
				var d:=Vector2(cos(a),sin(a))
				fx_line(im,c+d*11,c+d*13,1.0,Color("#ead9ff",fade))
			var a:float=-t*TAU*1.5
			fx_line(im,c,c+Vector2(cos(a),sin(a))*9,1.8,Color("#ffe1bc",fade))
			fx_line(im,c,c+Vector2(cos(a*.4),sin(a*.4))*5,2.1,Color("#c5e6ff",fade))
			psi_polygon(im,c,20.0,4,t*.5,Color("#c0a6df",fade*.6),Color("#7865a4",fade*.45))
		"eos_209":
			# Relic Exchange: two differently colored rotating diamond relics trade paths.
			for j in range(2):
				var f:float=drive if j==0 else 1.0-drive
				var q:=Vector2(9+30*f,24+float(j*2-1)*8*sin(f*PI))
				var tint:=Color("#ffd6a4" if j==0 else "#acdbe8",fade)
				psi_polygon(im,q,5.0,4,t*PI+float(j),tint,Color("#79629e",fade))
				fx_disc(im,q,1.6,tint)
				fx_line(im,q-Vector2(5,0),q,1.0,Color(tint,fade*.65))
		"eos_137":
			# Talent Exchange: two interlocking rotating runes cross and swap hue.
			for j in range(2):
				var f:float=drive if j==0 else 1.0-drive
				var q:=Vector2(11+26*f,24+float(j*2-1)*6*sin(f*PI))
				var tint:=Color("#efb9f4" if j==0 else "#b7e3ff",fade)
				psi_ring(im,q,5.0,tint,Color("#7657ae",fade))
				for k in range(3):
					var a:float=float(k)*TAU/3.0+t*TAU
					fx_line(im,q,q+Vector2(cos(a),sin(a))*4,1.2,tint)
		"eos_220":
			# Talent Mimic: a source rune casts a growing duplicate on the opposite side.
			var c:=Vector2(12,24)
			var q:=Vector2(36,24)
			psi_polygon(im,c,7.0,5,0.0,Color("#e4b6ff",fade),Color("#8058b0",fade))
			psi_polygon(im,q,2+5*drive,5,0.0,Color("#d9c5ff",fade*drive),Color("#8058b0",fade*drive))
			for j in range(5):
				var p:=Vector2(17+float(j)*3,24+sin(t*TAU+float(j))*3)
				fx_disc(im,p,1.0,Color("#efdcff",fade))
		"eos_439":
			# Life Offering: dissolving star rises as restorative light spreads outward.
			var c:=Vector2(24,28-9*drive)
			fairy_star(im,c,8*(1.0-drive)+2,Color("#fff0d2",fade))
			for j in range(10):
				var a:float=float(j)*TAU/10.0+t
				var q:=c+Vector2(cos(a),sin(a))*(5+13*drive)
				fx_disc(im,q,1.3,Color("#d0f1de",fade))
				fx_line(im,q,q-Vector2(0,4),1.0,Color("#e5f5e6",fade))
			if t>=peak:psi_ring(im,Vector2(24,32),9+8*(1.0-fade),Color("#d5f0db",fade),Color("#9ea7c9",fade))
		"eos_526":
			# Moon Renewal: silver crescent sheds descending restorative starlight.
			var c:=Vector2(24,16)
			fight_arc(im,c,9+2*pulse,-PI*.65,PI*1.5,Color("#fff1d4",fade),Color("#a49cc8",fade),4.3)
			for j in range(8):
				var f:float=fposmod(t+float(j)*.13,1.0)
				var q:=Vector2(9+float(j)*4.3,20+20*f)
				fairy_star(im,q,1.5,Color("#e7e4ff",fade))
			fx_disc(im,Vector2(24,36),8+7*drive,Color("#c9e7dc",fade*.75),6.5+7*drive)
		"lib_ghost_1":
			# Shade Claw: a single long hooked spectral talon pulls a smoky wake.
			var q:=Vector2(10+24*drive,24)
			fight_arc(im,q,13.0,-PI*.85+t*.7,PI*1.25,Color("#a2eadb",fade),Color("#302a51",fade),4.5)
			fight_arc(im,q-Vector2(5,2),10.0,-PI*.85+t*.7,PI*.9,Color("#a99bcf",fade*.65),Color("#403251",fade*.7),2.0)
			for j in range(7):
				var p:=q+Vector2(-13+float(j)*3,8+sin(float(j)*2.4+t*TAU)*5)
				fx_disc(im,p,2.0+float(j%2),Color("#544168",fade*.55))
			if t>=peak:fairy_star(im,q+Vector2(5,-3),3.8,Color("#d4ffee",fade))
		"lib_ghost_2":
			# Phantom Thread: a luminous strand winds through displaced shadow wisps.
			var prev:=Vector2(4,24)
			for j in range(1,30):
				var f:float=float(j)/29.0
				var q:=Vector2(4+37*f*drive,24+sin(f*TAU*2-t*TAU)*8*f)
				fx_line(im,prev,q,3.2,Color("#322840",fade))
				fx_line(im,prev,q,1.0,Color("#9ad8ce",fade))
				if j%5==0:fx_disc(im,q-Vector2(2,4),2.2,Color("#74628d",fade*.55))
				prev=q
			if t>=peak:
				for j in range(3):
					fight_arc(im,prev,4+float(j)*3,t*TAU,PI*1.6,Color("#bcebdd",fade),Color("#514269",fade),1.2)
		"lib_ghost_3":
			# Spectral Bloom: eerie petals unfurl into drifting spirit flames.
			var c:=Vector2(24,28)
			for j in range(6):
				var a:float=float(j)*TAU/6.0+t*.7
				var d:=Vector2(cos(a),sin(a))
				var q:=c+d*(4+10*drive)
				fx_line(im,c,q,3.6,Color("#3a2d55",fade))
				fire_lobe(im,q,3.8,t+float(j)*.16,Color("#a8efdb",fade),Color("#6f509f",fade))
				fx_disc(im,q+d*5,1.1,Color("#d6f8ed",fade))
			fx_disc(im,c,5.0,Color("#29263d",fade))
			fx_disc(im,c-Vector2(0,1),2.0,Color("#c4d6ff",fade))
		"eos_120":
			# Lick: broad curling spectral tongue with a rounded wet tip.
			var prev:=Vector2(5,26)
			for j in range(1,22):
				var f:float=float(j)/21.0
				var q:=Vector2(5+33*f*drive,26+sin(f*PI*1.4+t*TAU)*5*f)
				fx_line(im,prev,q,6.8-2.0*f,Color("#4d2d58",fade))
				fx_line(im,prev-Vector2(0,1),q-Vector2(0,1),3.7-1.0*f,Color("#b878a5",fade))
				if j%4==0:fx_line(im,prev,q,1.0,Color("#efb9d5",fade))
				prev=q
			fx_disc(im,prev,2.7,Color("#d8a4c9",fade))
			if t>=peak:
				for j in range(5):
					var a:float=float(j)*TAU/5.0
					fx_disc(im,prev+Vector2(cos(a),sin(a))*(4+6*(1.0-fade)),1.3,Color("#a8d9cc",fade))
		"eos_126":
			# Shadow Punch: compact spectral fist, distinct knuckles and trailing ghost smoke.
			var q:=Vector2(10+24*drive,24)
			fx_line(im,q-Vector2(15,0),q-Vector2(4,0),6.0,Color("#282238",fade))
			fx_disc(im,q-Vector2(2,0),7.5,Color("#4b365f",fade))
			for j in range(4):
				var p:=q+Vector2(4, -6+float(j)*4)
				fx_disc(im,p,3.1,Color("#352945",fade))
				fx_disc(im,p-Vector2(0,1),1.9,Color("#b6a0e1",fade))
			fx_line(im,q+Vector2(-5,5),q+Vector2(2,3),2.7,Color("#8068a5",fade))
			for j in range(5):
				var p:=q+Vector2(-10-float(j)*3,sin(float(j)*2.4+t*TAU)*5)
				fx_disc(im,p,2.9,Color("#514164",fade*.55))
			if t>=peak:
				for j in range(6):
					var a:float=float(j)*TAU/6.0
					var d:=Vector2(cos(a),sin(a))
					fx_line(im,q+d*5,q+d*(9+7*(1.0-fade)),1.5,Color("#c0e7df",fade))
		"eos_437":
			# Ominous Wind: low creeping spirit silhouettes borne on dark curling gusts.
			for j in range(5):
				var f:float=float(j)/4.0
				var q:=Vector2(8+30*f*drive,28+sin(float(j)*2.4+t*TAU)*7)
				fight_arc(im,q,6+3*f,-PI*.8+t,PI*1.45,Color("#90c9c4",fade),Color("#392b51",fade),2.7)
				fx_disc(im,q,3.4,Color("#453453",fade*.8))
				fx_disc(im,q+Vector2(-1,-1),.85,Color("#c8e9e0",fade))
				fx_disc(im,q+Vector2(1,-1),.85,Color("#c8e9e0",fade))
				fx_line(im,q-Vector2(8,1),q-Vector2(3,2),1.5,Color("#79618e",fade*.7))
		"eos_477":
			# Shade Rift: ragged vertical tear opens, then a shadow strikes from within.
			var c:=Vector2(24,24)
			var width:float=2+9*pulse
			for j in range(15):
				var f:float=float(j)/14.0
				var y:float=5+37*f
				var w:float=width*sin(f*PI)
				fx_line(im,Vector2(c.x-w,y),Vector2(c.x+w,y),2.6,Color("#231b36",fade))
				if j%2==0:
					fx_disc(im,Vector2(c.x-w,y),1.4,Color("#8f72c5",fade))
					fx_disc(im,Vector2(c.x+w,y),1.4,Color("#b7dedc",fade))
			if t>=peak:
				var q:=Vector2(24,8+25*(1.0-fade))
				fx_line(im,q-Vector2(0,14),q,6.0,Color("#49345f",fade))
				fx_line(im,q-Vector2(0,12),q,2.2,Color("#c3b6ed",fade))
				fairy_star(im,q,4+4*(1.0-fade),Color("#d8f6ec",fade))
		"eos_013":
			# Mirage Ray: crooked green spectral beam carrying illusory ghost faces.
			var prev:=Vector2(4,24)
			for j in range(1,25):
				var f:float=float(j)/24.0
				var q:=Vector2(4+39*f*drive,24+sin(f*TAU*2-t*TAU)*6*f)
				fx_line(im,prev,q,3.8,Color("#403051",fade))
				fx_line(im,prev,q,1.3,Color("#a1e0cb",fade))
				if j%6==0:
					fx_disc(im,q,3.4,Color("#665681",fade))
					fx_disc(im,q-Vector2(1,1),.85,Color("#e4f8d6",fade))
					fx_disc(im,q+Vector2(1,-1),.85,Color("#e4f8d6",fade))
				prev=q
		"eos_216":
			# Night Echo: dark concentric echoes radiate from a hollow spirit face.
			var c:=Vector2(24,24)
			for j in range(4):
				var rad:float=5+float(j)*4+3*drive
				fight_arc(im,c,rad,t*.6+float(j)*.65,PI*1.72,Color("#b39bd8",fade*.8),Color("#30243e",fade),2.4)
			fx_disc(im,c,6.5,Color("#272135",fade))
			fx_disc(im,c+Vector2(-2,-1),1.2,Color("#aad8cf",fade))
			fx_disc(im,c+Vector2(2,-1),1.2,Color("#aad8cf",fade))
			fx_disc(im,c+Vector2(0,2),1.4,Color("#775c91",fade))
		"eos_005":
			# Dread Dream: looming nightmare mask emerges behind a bed of curling shadows.
			var c:=Vector2(24,22)
			fx_disc(im,c,8+5*drive,Color("#36263e",fade))
			for j in range(5):
				var q:=c+Vector2(-10+float(j)*5,8+sin(float(j)*2.4+t*TAU)*4)
				fire_lobe(im,q,4.0,t+float(j)*.2,Color("#8a719e",fade),Color("#352742",fade))
			for side in [-1.0,1.0]:
				var q:=c+Vector2(side*4,-3)
				fx_line(im,q+Vector2(side*3,-2),q-Vector2(side*2,-1),2.2,Color("#c2dad7",fade))
			fight_arc(im,c+Vector2(0,4),4.0,0.0,PI,Color("#9275b0",fade),Color("#281e36",fade),1.4)
		"eos_313":
			# Fate Link: two ghost flames joined by a tightening chain of spectral links.
			for j in range(2):
				var q:=Vector2(9+float(j)*30,24)
				fire_lobe(im,q,4.5,t+float(j)*.5,Color("#c4eee2",fade),Color("#684d98",fade))
			for j in range(6):
				var f:float=float(j)/5.0
				var q:=Vector2(9+30*f,24+sin(f*PI)*8*(1.0-drive))
				var a:float=float(j%2)*PI*.5
				fight_arc(im,q,4.0,a,TAU,Color("#c2afd9",fade),Color("#4d3a69",fade),1.4)
				fx_disc(im,q,1.0,Color("#e5f8eb",fade))
		"eos_035":
			# Essence Drain: spectral motes pulled from the target into a dark spirit flame.
			var travel:float=drive
			for j in range(7):
				var f:float=clampf(travel-float(j)*.09,0.0,1.0)
				var q:=Vector2(39-30*f,24+sin(float(j)*2.4+t*TAU)*6)
				fx_line(im,q,q+Vector2(5,0),1.5,Color("#715a91",fade))
				fx_disc(im,q,2.6,Color("#4b365e",fade))
				fx_disc(im,q-Vector2(0,1),1.3,Color("#a3ddcf",fade))
			fire_lobe(im,Vector2(9,24),4+3*pulse,t,Color("#b4e8d9",fade),Color("#5b447e",fade))
		"eos_049":
			# Final Grudge: black-purple curse seal with rising spectral flames.
			var c:=Vector2(24,30)
			psi_polygon(im,c,13+3*drive,5,t*.8,Color("#a98ed0",fade),Color("#32233f",fade))
			for j in range(5):
				var a:float=float(j)*TAU/5.0+t*.8
				var q:=c+Vector2(cos(a)*13,sin(a)*8)
				fire_lobe(im,q-Vector2(0,7*drive),3.4,t+float(j)*.2,Color("#b8d9d6",fade),Color("#654487",fade))
				fx_line(im,q,q-Vector2(0,8*drive),1.0,Color("#8467a2",fade))
			fx_line(im,c-Vector2(4,4),c+Vector2(4,4),1.6,Color("#c8afdc",fade))
			fx_line(im,c+Vector2(-4,4),c+Vector2(4,-4),1.6,Color("#c8afdc",fade))
	return im

func combat_frame_image(id:String,frame:int)->Image:
	if id in VISUAL_REMASTER_MOVES:return visual_remaster_frame(id,frame)
	var base:=combat_base_frame_image(id,frame)
	if id in NATIVE_IDENTITY_CASTS:return native_identity_frame(id,frame,base)
	return base

func combat_base_frame_image(id:String,frame:int)->Image:
	var style:Array=combat_style(id)
	var mode:String=combat_animation_mode(id,str(style[0]))
	var light:=Color(style[1]);var dark:=Color(style[2]);var edge:=dark.darkened(.52)
	var im:=Image.create(FX_FRAME_SIZE,FX_FRAME_SIZE,false,Image.FORMAT_RGBA8);im.fill(Color.TRANSPARENT)
	var t:float=float(posmod(frame,FX_FRAME_COUNT))/float(FX_FRAME_COUNT-1)
	var role:String=str(combat_profile(id).role)
	if role.begins_with("electric"):
		electric_sprite(im,id,frame,role);return im
	if role.begins_with("fire_"):
		fire_sprite(im,role,frame);return im
	if role.begins_with("water_"):
		water_sprite(im,role,frame);return im
	if role.begins_with("grass_"):
		grass_sprite(im,role,frame);return im
	if role.begins_with("ice_"):
		ice_sprite(im,role,frame);return im
	if role.begins_with("earth_"):
		earth_sprite(im,role,frame);return im
	if role.begins_with("rock_"):
		rock_sprite(im,role,frame);return im
	if role.begins_with("fight_"):
		fight_sprite(im,role,frame);return im
	if role.begins_with("air_"):
		air_sprite(im,role,frame);return im
	if role.begins_with("poison_"):
		poison_sprite(im,role,frame);return im
	if role.begins_with("bug_"):
		bug_sprite(im,role,frame);return im
	if role.begins_with("psi_"):
		psi_sprite(im,role,frame);return im
	if role.begins_with("ghost_"):
		ghost_sprite(im,role,frame);return im
	if role.begins_with("dragon_"):
		dragon_sprite(im,role,frame);return im
	if role.begins_with("dark_"):
		dark_sprite(im,role,frame);return im
	if role.begins_with("steel_"):
		steel_sprite(im,role,frame);return im
	if role.begins_with("fairy_"):
		fairy_sprite(im,role,frame);return im
	if role=="neutral_echo":
		for i in range(3):
			var radius:float=4.0+fposmod(t+float(i)/3.0,1.0)*17.0
			fx_disc(im,Vector2(24,24),radius,light,maxf(0.0,radius-2.0))
		return im
	if role.begins_with("normal_"):
		normal_contact_sprite(im,role,frame);return im
	if role.begins_with("neutral_"):
		neutral_special_sprite(im,role,frame);return im
	if role.begins_with("support_"):
		support_sprite(im,role,frame);return im
	if role.begins_with("status_"):
		status_sprite(im,role,frame);return im
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
	var normalized:int=posmod(frame,FX_FRAME_COUNT)
	var key:="animated:"+id+":"+str(normalized)
	if fx_animated_cache.has(key):return fx_animated_cache[key] as ImageTexture
	# FIFO eviction only on misses; sprites retain their own reference while visible.
	if fx_animated_order.size()>=FX_ANIMATED_CACHE_CAP:
		fx_animated_cache.erase(fx_animated_order.pop_front())
	var texture:=ImageTexture.create_from_image(combat_frame_image(id,normalized))
	fx_animated_cache[key]=texture
	fx_animated_order.append(key)
	return texture
# Presentation contracts are independent of damage rules. Each attack has a
# caster motion, source socket, launch point, target reaction and sound phases.
var combat_profile_cache:Dictionary={}
func combat_profile(id:String)->Dictionary:
	if not combat_profile_cache.has(id):combat_profile_cache[id]=build_combat_profile(id)
	return combat_profile_cache[id]

func build_combat_profile(id:String)->Dictionary:
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
	match id:
		"lib_normal_1":role="normal_tackle"
		"lib_normal_2":role="neutral_echo"
		"lib_normal_3":role="neutral_beam"
		"lib_fire_1":role="fire_ember"
		"lib_fire_2":role="fire_breath"
		"lib_fire_3":role="fire_vortex"
		"lib_water_1":role="water_bubble"
		"lib_water_2":role="water_bubblebeam"
		"lib_water_3":role="water_surf"
		"lib_electric_1":role="electric_fang"
		"lib_electric_2":role="electric_arc"
		"lib_electric_3":role="electric_room"
		"lib_grass_1":role="grass_whip"
		"lib_grass_2":role="grass_razor"
		"lib_grass_3":role="grass_roots"
		"lib_ice_1":role="ice_shard"
		"lib_ice_2":role="ice_beam"
		"lib_ice_3":role="ice_wind"
		"lib_fighting_1":role="fight_palm"
		"lib_fighting_2":role="fight_roundkick"
		"lib_fighting_3":role="fight_focus"
		"lib_poison_1":role="poison_gunk"
		"lib_poison_2":role="poison_acid"
		"lib_poison_3":role="poison_sludge"
		"lib_ground_1":role="earth_fissure"
		"lib_ground_2":role="earth_rush"
		"lib_ground_3":role="earth_shot"
		"lib_flying_1":role="air_cutter"
		"lib_flying_2":role="air_blast"
		"lib_flying_3":role="air_bounce"
		"lib_psychic_1":role="psi_beam"
		"lib_psychic_2":role="psi_wave"
		"lib_psychic_3":role="psi_luster"
		"lib_bug_1":role="bug_string"
		"lib_bug_2":role="bug_turn"
		"lib_bug_3":role="bug_signal"
		"lib_rock_1":role="rock_throw"
		"lib_rock_2":role="rock_roll"
		"lib_rock_3":role="rock_blast"
		"lib_ghost_1":role="ghost_claw"
		"lib_ghost_2":role="ghost_force"
		"lib_ghost_3":role="ghost_ball"
		"lib_dragon_1":role="dragon_claw"
		"lib_dragon_2":role="dragon_breath"
		"lib_dragon_3":role="dragon_rush"
		"lib_dark_1":role="dark_bite"
		"lib_dark_2":role="dark_void"
		"lib_dark_3":role="dark_pulse"
		"lib_steel_1":role="steel_claw"
		"lib_steel_2":role="steel_bullet"
		"lib_steel_3":role="steel_meteor"
		"lib_fairy_1":role="fairy_glimmer"
		"lib_fairy_2":role="fairy_halo"
		"lib_fairy_3":role="fairy_prism"
		"star_kick":role="fairy_kick"
		"alt_starlit_pup":role="fairy_glimmer"
		"lunar_dust":role="fairy_dust"
		"comet_drop":role="fairy_comet"
		"celestial_verdict":role="fairy_verdict"
		"alt_celestial_guardian":role="fairy_blade"
		"eos_064":role="electric_sky"
		"eos_129":role="electric_burst"
		"eos_188":role="electric_short"
		"eos_189":role="electric_wave"
		"eos_065":role="electric_fist"
		"eos_144":role="electric_spark"
		"eos_193":role="electric_orb"
		"eos_354":role="electric_dash"
		"eos_452":role="electric_fang"
		"eos_489":role="electric_beam"
		"eos_521":role="electric_room"
		"eos_192":role="electric_bind"
		"eos_128":role="electric_charge"
		"eos_493":role="electric_lift"
		"eos_041":role="fire_overheat"
		"eos_052":role="fire_wheel"
		"eos_053":role="fire_breath"
		"eos_149":role="fire_sacred"
		"eos_157":role="fire_blast"
		"eos_230":role="fire_heatwave"
		"eos_262":role="fire_ember"
		"eos_272":role="fire_blastburn"
		"eos_276":role="fire_kick"
		"eos_278":role="fire_eruption"
		"eos_291":role="fire_vortex"
		"eos_292":role="fire_punch"
		"eos_517":role="fire_blitz"
		"eos_519":role="fire_plume"
		"eos_522":role="fire_fang"
		"eos_524":role="fire_magma"
		"eos_047":role="fire_wisp"
		"eos_223":role="fire_sun"
		"eos_016":role="water_bubble"
		"eos_032":role="water_whirlpool"
		"eos_044":role="water_ink"
		"eos_069":role="water_clamp"
		"eos_087":role="water_hammer"
		"eos_113":role="water_spout"
		"eos_156":role="water_dive"
		"eos_158":role="water_fall"
		"eos_159":role="water_mud"
		"eos_219":role="water_surf"
		"eos_239":role="water_cannon"
		"eos_240":role="water_pump"
		"eos_255":role="water_bubblebeam"
		"eos_308":role="water_gun"
		"eos_310":role="water_pulse"
		"eos_432":role="water_jet"
		"eos_433":role="water_tail"
		"eos_469":role="water_brine"
		"eos_070":role="water_shell"
		"eos_012":role="water_rain"
		"eos_307":role="water_mist"
		"eos_434":role="water_ring"
		"eos_076":role="grass_giga"
		"eos_135":role="grass_absorb"
		"eos_151":role="grass_solar"
		"eos_182":role="grass_vine"
		"eos_221":role="grass_needle"
		"eos_238":role="grass_frenzy"
		"eos_251":role="grass_razor"
		"eos_297":role="grass_magic"
		"eos_320":role="grass_mega"
		"eos_336":role="grass_blade"
		"eos_441":role="grass_wood"
		"eos_443":role="grass_energy"
		"eos_458":role="grass_knot"
		"eos_468":role="grass_flare"
		"eos_486":role="grass_bomb"
		"eos_511":role="grass_whip"
		"eos_537":role="grass_storm"
		"eos_163":role="grass_bullet"
		"eos_079":role="grass_spore"
		"eos_231":role="grass_sleep"
		"eos_124":role="grass_stun"
		"eos_351":role="grass_cotton"
		"eos_015":role="grass_aroma"
		"eos_094":role="grass_synthesis"
		"eos_084":role="grass_whistle"
		"eos_329":role="grass_leech"
		"eos_253":role="grass_petal"
		"eos_233":role="grass_roots"
		"eos_504":role="grass_worry"
		"eos_042":role="ice_aurora"
		"eos_097":role="ice_wind"
		"eos_101":role="ice_powder"
		"eos_270":role="ice_blizzard"
		"eos_344":role="ice_punch"
		"eos_345":role="ice_beam"
		"eos_461":role="ice_fang"
		"eos_462":role="ice_shard"
		"eos_180":role="ice_spear"
		"eos_002":role="ice_ball"
		"eos_088":role="ice_haze"
		"eos_130":role="ice_mist"
		"eos_014":role="ice_hail"
		"eos_150":role="ice_cold"
		"eos_535":role="ice_avalanche"
		"eos_008":role="earth_dig"
		"eos_143":role="earth_tomb"
		"eos_213":role="earth_slap"
		"eos_289":role="earth_club"
		"eos_299":role="earth_shot"
		"eos_484":role="earth_power"
		"eos_501":role="earth_bomb"
		"eos_285":role="earth_rush"
		"eos_290":role="earth_return"
		"eos_142":role="earth_dust"
		"eos_212":role="earth_mudcoat"
		"eos_131":role="earth_fissure"
		"eos_295":role="earth_spikes"
		"eos_118":role="earth_quake"
		"eos_296":role="earth_magnitude"
		"eos_028":role="rock_throw"
		"eos_030":role="rock_slide"
		"eos_073":role="rock_tomb"
		"eos_093":role="rock_ancient"
		"eos_453":role="rock_wrecker"
		"eos_481":role="rock_edge"
		"eos_512":role="rock_gem"
		"eos_533":role="rock_smash"
		"eos_350":role="rock_blast"
		"eos_105":role="rock_roll"
		"eos_540":role="rock_polish"
		"eos_141":role="rock_storm"
		"eos_480":role="rock_trap"
		"eos_068":role="fight_chop"
		"eos_072":role="fight_break"
		"eos_075":role="fight_focus"
		"eos_077":role="fight_reversal"
		"eos_090":role="fight_cross"
		"eos_092":role="fight_lowkick"
		"eos_116":role="fight_submission"
		"eos_136":role="fight_uppercut"
		"eos_204":role="fight_jumpkick"
		"eos_206":role="fight_highkick"
		"eos_243":role="fight_super"
		"eos_246":role="fight_dynamic"
		"eos_300":role="fight_mach"
		"eos_303":role="fight_roundkick"
		"eos_430":role="fight_hammer"
		"eos_440":role="fight_close"
		"eos_454":role="fight_blast"
		"eos_479":role="fight_vacuum"
		"eos_500":role="fight_drain"
		"eos_507":role="fight_palm"
		"eos_508":role="fight_aura"
		"eos_531":role="fight_slap"
		"eos_175":role="fight_thrust"
		"eos_222":role="fight_double"
		"eos_210":role="fight_triple"
		"eos_265":role="fight_bulk"
		"eos_305":role="fight_detect"
		"eos_051":role="fight_counter"
		"eos_170":role="fight_toss"
		"eos_340":role="fight_revenge"
		"eos_007":role="fight_vital"
		"eos_029":role="fight_stonebreak"
		"eos_036":role="air_cutter"
		"eos_057":role="air_gust"
		"eos_100":role="air_sky"
		"eos_153":role="air_fly"
		"eos_174":role="air_peck"
		"eos_178":role="air_wing"
		"eos_179":role="air_ace"
		"eos_205":role="air_bounce"
		"eos_211":role="air_drill"
		"eos_353":role="air_blast"
		"eos_442":role="air_slash"
		"eos_446":role="air_chatter"
		"eos_490":role="air_pluck"
		"eos_518":role="air_brave"
		"eos_444":role="air_tailwind"
		"eos_267":role="air_feather"
		"eos_509":role="air_roost"
		"eos_456":role="air_defog"
		"eos_040":role="air_mirror"
		"eos_147":role="poison_smog"
		"eos_196":role="poison_gas"
		"eos_197":role="poison_toxic"
		"eos_198":role="poison_fang"
		"eos_199":role="poison_powder"
		"eos_200":role="poison_sting"
		"eos_202":role="poison_armor"
		"eos_279":role="poison_sludge"
		"eos_280":role="poison_bomb"
		"eos_283":role="poison_tail"
		"eos_332":role="poison_acid"
		"eos_438":role="poison_gastro"
		"eos_459":role="poison_cross"
		"eos_485":role="poison_gunk"
		"eos_495":role="poison_jab"
		"eos_496":role="poison_spikes"
		"eos_023":role="bug_string"
		"eos_080":role="bug_leech"
		"eos_082":role="bug_silver"
		"eos_086":role="bug_web"
		"eos_114":role="bug_signal"
		"eos_164":role="bug_twin"
		"eos_288":role="bug_glow"
		"eos_306":role="bug_pin"
		"eos_323":role="bug_horn"
		"eos_346":role="bug_fury"
		"eos_449":role="bug_heal"
		"eos_460":role="bug_attack"
		"eos_470":role="bug_cross"
		"eos_502":role="bug_turn"
		"eos_520":role="bug_defend"
		"eos_529":role="bug_bite"
		"eos_530":role="bug_buzz"
		"eos_095":role="psi_agility"
		"eos_099":role="psi_cosmic"
		"eos_107":role="psi_beam"
		"eos_108":role="psi_wave"
		"eos_109":role="psi_psychic"
		"eos_110":role="psi_boost"
		"eos_111":role="psi_hypnosis"
		"eos_133":role="psi_extra"
		"eos_137":role="psi_skill"
		"eos_146":role="psi_kinesis"
		"eos_187":role="psi_teleport"
		"eos_209":role="psi_trick"
		"eos_215":role="psi_amnesia"
		"eos_220":role="psi_role"
		"eos_232":role="psi_rest"
		"eos_234":role="psi_confusion"
		"eos_258":role="psi_barrier"
		"eos_259":role="psi_screen"
		"eos_266":role="psi_imprison"
		"eos_298":role="psi_magic"
		"eos_309":role="psi_mist"
		"eos_316":role="psi_mirror"
		"eos_317":role="psi_future"
		"eos_319":role="psi_calm"
		"eos_331":role="psi_dream"
		"eos_333":role="psi_meditate"
		"eos_335":role="psi_luster"
		"eos_338":role="psi_reflect"
		"eos_439":role="psi_wish"
		"eos_448":role="psi_guard"
		"eos_450":role="psi_block"
		"eos_463":role="psi_cut"
		"eos_464":role="psi_shift"
		"eos_473":role="psi_zen"
		"eos_478":role="psi_gravity"
		"eos_499":role="psi_room"
		"eos_506":role="psi_heart"
		"eos_513":role="psi_power"
		"eos_514":role="psi_powertrick"
		"eos_526":role="psi_lunar"
		"eos_528":role="psi_eye"
		"eos_005":role="ghost_nightmare"
		"eos_013":role="ghost_confuse"
		"eos_035":role="ghost_spite"
		"eos_046":role="ghost_astonish"
		"eos_049":role="ghost_grudge"
		"eos_120":role="ghost_lick"
		"eos_126":role="ghost_punch"
		"eos_127":role="ghost_ball"
		"eos_216":role="ghost_shade"
		"eos_313":role="ghost_bond"
		"eos_437":role="ghost_wind"
		"eos_451":role="ghost_sneak"
		"eos_476":role="ghost_claw"
		"eos_477":role="ghost_force"
		"eos_091":role="dragon_rage"
		"eos_162":role="dragon_twister"
		"eos_208":role="dragon_claw"
		"eos_341":role="dragon_flame"
		"eos_342":role="dragon_breath"
		"eos_343":role="dragon_dance"
		"eos_435":role="dragon_rend"
		"eos_494":role="dragon_time"
		"eos_498":role="dragon_rush"
		"eos_538":role="dragon_meteor"
		"eos_539":role="dragon_pulse"
		"eos_022":role="dark_torment"
		"eos_033":role="dark_tears"
		"eos_038":role="dark_pursuit"
		"eos_043":role="dark_memento"
		"eos_045":role="dark_flatter"
		"eos_062":role="dark_crunch"
		"eos_063":role="dark_bite"
		"eos_167":role="dark_faint"
		"eos_172":role="dark_taunt"
		"eos_214":role="dark_thief"
		"eos_249":role="dark_knock"
		"eos_269":role="dark_beat"
		"eos_334":role="dark_snatch"
		"eos_436":role="dark_pulse"
		"eos_445":role="dark_punish"
		"eos_466":role="dark_embargo"
		"eos_472":role="dark_payback"
		"eos_482":role="dark_switch"
		"eos_483":role="dark_void"
		"eos_488":role="dark_assure"
		"eos_491":role="dark_slash"
		"eos_503":role="dark_fling"
		"eos_515":role="dark_sucker"
		"eos_542":role="dark_plot"
		"eos_001":role="steel_tail"
		"eos_083":role="steel_sound"
		"eos_103":role="steel_meteor"
		"eos_186":role="steel_defense"
		"eos_244":role="steel_wing"
		"eos_256":role="steel_doom"
		"eos_325":role="steel_claw"
		"eos_431":role="steel_head"
		"eos_475":role="steel_gyro"
		"eos_510":role="steel_bullet"
		"eos_523":role="steel_magnet"
		"eos_527":role="steel_mirror"
		"eos_532":role="steel_burst"
		"eos_536":role="steel_flash"
		"eos_009":role="normal_thrash"
		"eos_018":role="normal_cut"
		"eos_020":role="normal_superfang"
		"eos_039":role="normal_slap"
		"eos_048":role="normal_return"
		"eos_050":role="normal_strength"
		"eos_061":role="normal_bide"
		"eos_066":role="normal_endeavor"
		"eos_067":role="normal_facade"
		"eos_071":role="normal_constrict"
		"eos_078":role="normal_salt"
		"eos_081":role="normal_slash"
		"eos_096":role="normal_spin"
		"eos_121":role="normal_flail"
		"eos_125":role="normal_bind"
		"eos_132":role="normal_extreme"
		"eos_139":role="normal_headbutt"
		"eos_140":role="normal_edge"
		"eos_154":role="normal_tackle"
		"eos_161":role="normal_slam"
		"eos_176":role="normal_horn"
		"eos_177":role="normal_drill"
		"eos_190":role="normal_quick"
		"eos_203":role="normal_takedown"
		"eos_226":role="normal_fake"
		"eos_235":role="normal_body"
		"eos_247":role="normal_guillotine"
		"eos_248":role="normal_vice"
		"eos_250":role="normal_pound"
		"eos_260":role="normal_scratch"
		"eos_261":role="normal_hyperfang"
		"eos_264":role="normal_dizzy"
		"eos_271":role="normal_stomp"
		"eos_275":role="normal_crushclaw"
		"eos_294":role="normal_wrap"
		"eos_311":role="normal_furyattack"
		"eos_312":role="normal_furyswipes"
		"eos_314":role="normal_false"
		"eos_321":role="normal_megakick"
		"eos_322":role="normal_megapunch"
		"eos_328":role="normal_frustration"
		"eos_347":role="normal_comet"
		"eos_348":role="normal_skull"
		"eos_352":role="normal_struggle"
		"eos_455":role="normal_giga"
		"eos_487":role="normal_double"
		"eos_497":role="normal_last"
		"eos_505":role="normal_grip"
		"eos_516":role="normal_feint"
		"eos_541":role="normal_climb"
		"eos_025":role="neutral_snore"
		"eos_031":role="neutral_weather"
		"eos_060":role="neutral_razor"
		"eos_123":role="neutral_self"
		"eos_145":role="neutral_swift"
		"eos_152":role="neutral_sonic"
		"eos_155":role="neutral_explosion"
		"eos_166":role="neutral_egg"
		"eos_168":role="neutral_barrage"
		"eos_201":role="neutral_spike"
		"eos_207":role="neutral_tri"
		"eos_228":role="neutral_pay"
		"eos_241":role="neutral_voice"
		"eos_242":role="neutral_beam"
		"eos_245":role="neutral_spit"
		"eos_263":role="neutral_secret"
		"eos_277":role="neutral_present"
		"eos_287":role="neutral_covet"
		"eos_324":role="neutral_hidden"
		"eos_360":role="neutral_wide"
		"eos_394":role="neutral_vacuum"
		"eos_457":role="neutral_trump"
		"eos_471":role="neutral_gift"
		"eos_474":role="neutral_wring"
		"eos_006":role="support_sun"
		"eos_019":role="support_rage"
		"eos_021":role="support_pain"
		"eos_026":role="support_bell"
		"eos_055":role="support_sharpen"
		"eos_056":role="support_double"
		"eos_058":role="support_harden"
		"eos_074":role="support_focus"
		"eos_098":role="support_mind"
		"eos_102":role="support_follow"
		"eos_104":role="support_endure"
		"eos_115":role="support_psych"
		"eos_117":role="support_recover"
		"eos_134":role="support_safeguard"
		"eos_148":role="support_growth"
		"eos_160":role="support_stock"
		"eos_165":role="support_egg"
		"eos_169":role="support_minimize"
		"eos_173":role="support_moon"
		"eos_181":role="support_swords"
		"eos_185":role="support_help"
		"eos_195":role="support_howl"
		"eos_218":role="support_slack"
		"eos_225":role="support_wish"
		"eos_236":role="support_swallow"
		"eos_257":role="support_drum"
		"eos_301":role="support_protect"
		"eos_302":role="support_curl"
		"eos_318":role="support_milk"
		"eos_339":role="support_refresh"
		"eos_349":role="support_lock"
		"eos_447":role="support_lucky"
		"eos_492":role="support_acu"
		"eos_003":role="status_yawn"
		"eos_227":role="status_talk"
		"eos_004":role="status_lovely"
		"eos_011":role="status_charm"
		"eos_191":role="status_kiss"
		"eos_326":role="status_attract"
		"eos_534":role="status_captivate"
		"eos_010":role="status_scent"
		"eos_037":role="status_smoke"
		"eos_054":role="status_odor"
		"eos_027":role="status_screech"
		"eos_034":role="status_sing"
		"eos_112":role="status_uproar"
		"eos_171":role="status_supersonic"
		"eos_217":role="status_growl"
		"eos_284":role="status_roar"
		"eos_293":role="status_perish"
		"eos_089":role="status_mean"
		"eos_106":role="status_scary"
		"eos_224":role="status_leer"
		"eos_281":role="status_glare"
		"eos_315":role="status_foresight"
		"eos_017":role="status_encore"
		"eos_059":role="status_disable"
		"eos_194":role="status_block"
		"eos_237":role="status_curse"
		"eos_304":role="status_sub"
		"eos_183":role="status_convert"
		"eos_184":role="status_convert2"
		"eos_282":role="status_transform"
		"eos_286":role="status_camo"
		"eos_119":role="status_nature"
		"eos_138":role="status_sketch"
		"eos_229":role="status_assist"
		"eos_327":role="status_mimic"
		"eos_330":role="status_metronome"
		"eos_465":role="status_first"
		"eos_525":role="status_copycat"
		"eos_024":role="status_swagger"
		"eos_085":role="status_tickle"
		"eos_122":role="status_tail"
		"eos_274":role="status_dance"
		"eos_252":role="status_baton"
		"eos_337":role="status_recycle"
		"eos_254":role="status_splash"
		"eos_268":role="status_whirl"
		"eos_273":role="status_flash"
	if role in ["electric_charge","electric_lift"]:mode="lightning"
	var impact:float=.48 if role in ["contact","electric_contact","electric_short","electric_fist","electric_fang","electric_dash","electric_spark"] else .64 if role in ["projectile","lash","electric_arc","electric_wave","electric_sky","electric_orb","electric_beam"] else .40
	if role in ["fire_breath","fire_ember","fire_blast","fire_wisp"]:impact=.64
	elif role in ["fire_wheel","fire_kick","fire_punch","fire_fang","fire_blitz"]:impact=.48
	if role in ["water_bubble","water_ink","water_cannon","water_pump","water_bubblebeam","water_gun","water_pulse","water_brine"]:impact=.64
	elif role in ["water_clamp","water_hammer","water_dive","water_fall","water_jet","water_tail"]:impact=.48
	if role in ["grass_solar","grass_razor","grass_magic","grass_energy","grass_bomb","grass_storm","grass_bullet","grass_leech","grass_worry"]:impact=.64
	elif role in ["grass_vine","grass_whip","grass_needle","grass_blade","grass_wood","grass_knot"]:impact=.48
	if role in ["ice_aurora","ice_wind","ice_beam","ice_shard","ice_spear"]:impact=.64
	elif role in ["ice_punch","ice_fang","ice_ball"]:impact=.48
	if role in ["earth_shot","earth_bomb","earth_return"]:impact=.64
	elif role in ["earth_club","earth_rush","earth_dig"]:impact=.48
	if role in ["rock_throw","rock_wrecker","rock_blast","rock_gem","rock_ancient"]:impact=.64
	elif role in ["rock_smash","rock_roll","rock_edge"]:impact=.48
	if role.begins_with("fight_"):impact=.64 if role in ["fight_aura","fight_blast","fight_vacuum"] else .48
	if role.begins_with("air_"):impact=.64 if role in ["air_blast","air_cutter","air_sky","air_fly","air_bounce"] else .48
	if role.begins_with("poison_"):impact=.64 if role in ["poison_bomb","poison_gunk","poison_acid","poison_sludge","poison_gastro"] else .48
	if role.begins_with("bug_"):impact=.64 if role in ["bug_string","bug_signal","bug_twin","bug_pin","bug_turn"] else .48
	if role.begins_with("psi_"):impact=.64 if role in ["psi_beam","psi_wave","psi_mist","psi_luster"] else .48
	if role.begins_with("ghost_"):impact=.64 if role in ["ghost_ball","ghost_confuse","ghost_sneak","ghost_force"] else .48
	if role.begins_with("dragon_"):impact=.64 if role in ["dragon_breath","dragon_flame","dragon_pulse","dragon_meteor","dragon_rush"] else .48
	if role.begins_with("dark_"):impact=.64 if role in ["dark_faint","dark_fling","dark_sucker","dark_pulse","dark_void"] else .48
	if role.begins_with("steel_"):impact=.64 if role in ["steel_meteor","steel_bullet","steel_flash","steel_mirror","steel_magnet"] else .48
	if role.begins_with("normal_"):impact=.64 if role in ["normal_extreme","normal_quick","normal_giga","normal_climb"] else .48
	if role.begins_with("neutral_"):impact=.64 if role in ["neutral_beam","neutral_weather","neutral_swift","neutral_egg","neutral_barrage","neutral_spike","neutral_present","neutral_trump","neutral_pay","neutral_hidden","neutral_gift"] else .48
	if role.begins_with("support_"):impact=.48
	if role.begins_with("status_"):impact=.48
	return {"mode":mode,"role":role,"element":element,"pattern":pattern,"range":reach,"duration":float(style[3]),"impact":impact,"socket":"ground" if role in ["ground","fire_plume","fire_magma","water_dive","water_whirlpool","water_surf","grass_frenzy","grass_roots","grass_knot","ice_avalanche","ice_cold","earth_dig","earth_tomb","earth_power","earth_fissure","earth_spikes","earth_quake","earth_magnitude","rock_edge","rock_tomb","rock_trap","rock_roll"] else "head" if role in ["projectile","fire_breath","fire_ember","fire_eruption","water_bubble","water_ink","water_spout","water_cannon","water_pump","water_bubblebeam","water_gun","water_pulse","water_brine","grass_solar","grass_energy","grass_bullet","grass_whistle","ice_aurora","ice_beam","ice_wind","earth_shot","rock_wrecker","rock_blast","rock_gem"] else "center"}
func electric_sprite(im:Image,id:String,frame:int,role:String)->void:
	var cyan:=Color("#40cfff")
	var violet:=Color("#5969ed")
	var gold:=Color("#ffe96b")
	var white:=Color("#fffef2")
	var center:=Vector2(24,24)
	var paths:Array=[]
	if role=="electric_sky":
		var bolt:Array=[Vector2(24,2)]
		for j in range(1,9):bolt.append(Vector2(24+float(posmod(j*17+frame*11,13)-6),2+j*5))
		paths.append(bolt)
	elif role=="electric_burst":
		for i in range(8):
			var angle:float=float(i)*TAU/8.0
			var radius:float=5.0+float(frame)*1.25
			var d:=Vector2(cos(angle),sin(angle))
			paths.append([center,center+d*radius*.48+Vector2(-d.y,d.x)*3.0,center+d*radius])
		fx_disc(im,center,3.0+float(frame),cyan,2.0+float(frame))
	elif role=="electric_short":
		paths.append([Vector2(8,24),Vector2(17,19),Vector2(22,28),Vector2(32,20),Vector2(39,24)])
		fx_disc(im,Vector2(35,24),2.0+float(frame%3),gold)
	elif role=="electric_wave":
		for i in range(3):
			var x:float=8.0+float(i)*10.0+float(frame%3)
			var wave:Array=[]
			for j in range(9):
				var angle:float=-PI*.40+float(j)*PI*.10
				wave.append(Vector2(x+cos(angle)*6.0,24+sin(angle)*18.0))
			paths.append(wave)
	elif role=="electric_fist":
		var offset:float=sin(float(frame)*PI/11.0)*5.0
		fx_disc(im,Vector2(29+offset,24),9.0,violet);fx_disc(im,Vector2(29+offset,24),6.5,gold)
		fx_line(im,Vector2(5,24),Vector2(22+offset,24),5.0,cyan)
		for i in range(4):
			paths.append([Vector2(28,24),Vector2(34+i*2,9+i*9),Vector2(40,7+i*10)])
	elif role=="electric_spark":
		for i in range(6):
			var angle:float=float(i)*TAU/6.0+float(frame)*.35
			var d:=Vector2(cos(angle),sin(angle))
			paths.append([center+d*4,center+d*10+Vector2(-d.y,d.x)*4,center+d*19])
	elif role=="electric_orb":
		var radius:float=10.0+sin(float(frame)*PI/11.0)*5.0
		fx_disc(im,center,radius,violet);fx_disc(im,center,radius-2.0,cyan);fx_disc(im,center,radius*.55,white)
		for i in range(5):
			var a:float=float(i)*TAU/5.0+float(frame)*.2
			var d:=Vector2(cos(a),sin(a));paths.append([center+d*radius*.5,center+d*radius,center+d*(radius+5.0)])
	elif role=="electric_dash":
		for i in range(3):
			var y:float=12.0+float(i)*12.0
			paths.append([Vector2(2,y),Vector2(17,y-4),Vector2(15,y+4),Vector2(43,y)])
		fx_disc(im,Vector2(36,24),7.0,gold,4.0)
	elif role=="electric_fang":
		for i in range(3):
			var x:float=15.0+float(i)*9.0
			var bite:float=sin(float(frame)*PI/11.0)*7.0
			paths.append([Vector2(x-3,8+bite),Vector2(x,19+bite),Vector2(x+4,9+bite)])
			paths.append([Vector2(x-3,40-bite),Vector2(x,29-bite),Vector2(x+4,39-bite)])
	elif role=="electric_beam":
		var w:float=2.0+sin(float(frame)*PI/11.0)*3.0
		fx_line(im,Vector2(3,24),Vector2(44,24),w*3.0,violet)
		fx_line(im,Vector2(3,24),Vector2(44,24),w*1.7,cyan)
		paths.append([Vector2(3,24),Vector2(44,24)])
	elif role=="electric_room":
		for i in range(12):
			var a:float=float(i)*TAU/12.0+float(frame%2)*.1
			var d:=Vector2(cos(a),sin(a));paths.append([center+d*3,center+d*12+Vector2(-d.y,d.x)*5,center+d*21])
		fx_disc(im,center,8.0+float(frame%4)*3.0,cyan,7.0+float(frame%4)*3.0)
	elif role in ["electric_bind","electric_charge","electric_lift"]:
		var radius:float=15.0-float(frame)*.6 if role=="electric_charge" else 10.0+float(frame%4)
		for ring in range(3):
			var path:Array=[]
			for j in range(13):
				var a:float=float(j)*TAU/12.0+float(frame)*.22
				var y:float=float(ring-1)*7.0 if role!="electric_lift" else float(ring)*6.0-float(frame)*.8
				path.append(center+Vector2(cos(a)*radius,sin(a)*radius*.45+y))
			paths.append(path)
	elif role=="electric_contact" or role=="electric_area":
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
	if role in ["electric_contact","electric_area","electric_burst"]:fx_disc(im,center,2.0+float(frame%3),white)
# Connected world-space ribbons: jitter is deterministic and changes at 24 Hz.
func arc_segment(a:Vector3,b:Vector3,width:float,col:Color)->void:
	var direction:=b-a
	if direction.length_squared()<.000001:return
	var side:=direction.cross(Vector3(0,.8,.6)).normalized()*width
	if side.length_squared()<.000001:side=Vector3.RIGHT*width
	for q in [a-side,a+side,b+side,a-side,b+side,b-side]:
		fx_arc_mesh.surface_set_color(col);fx_arc_mesh.surface_add_vertex(q)
	fx_arc_segments+=1
# Preserve intermediate corners when extending a beam or electrical chain.
func combat_path_prefix(points:Array,progress:float)->Array:
	if points.size()<2:return points.duplicate()
	var total:float=0.0
	for i in range(1,points.size()):
		var a:Vector3=points[i-1]
		total+=a.distance_to(points[i])
	var remain:float=total*clampf(progress,0.0,1.0)
	var result:Array=[points[0]]
	for i in range(1,points.size()):
		var a:Vector3=points[i-1]
		var distance:float=a.distance_to(points[i])
		if distance<.00001:continue
		if remain<=distance:
			result.append(a.lerp(points[i],remain/distance));return result
		result.append(points[i]);remain-=distance
	if result.size()==1:result.append(points[-1])
	return result

func electric_world_arc(points:Array,t:float,role:String,tiles:Array,impact:float=.48)->void:
	var travel:float=combat_travel_progress(t,impact)
	var travel_tip:Vector3=combat_path_sample(points,travel)
	var arrived:bool=t>=impact
	var strike_progress:float=clampf((t-impact)/maxf(.001,1.0-impact),0.0,1.0)
	var frame:int=int(t*36.0)
	var paths:Array=[]
	if role=="electric_sky":
		var target:Vector3=points[-1]
		var sky:Vector3=target+Vector3.UP*2.8
		paths.append([sky,sky.lerp(target,travel)])
		if arrived:
			for i in range(4):
				var angle:float=float(i)*TAU/4.0
				paths.append([target,target+Vector3(cos(angle)*.65,.08,sin(angle)*.65)])
	elif role=="electric_burst":
		for tile in tiles:
			var target:Vector3=tile+Vector3.UP*.35
			paths.append([points[0],points[0].lerp(target,travel)])
	elif role=="electric_short":
		paths.append([points[0],points[-1]])
	elif role=="electric_wave":
		var front:Vector3=travel_tip
		var direction:Vector3=(points[-1]-points[0]).normalized()
		var side:Vector3=direction.cross(Vector3.UP)
		for i in range(3):
			var center:Vector3=front-direction*float(i)*.23
			paths.append([center-side*.38,center+Vector3.UP*.27,center+side*.38])
	elif role=="electric_fist":
		paths.append([points[0],points[-1]])
		for i in range(4):
			var angle:float=float(i)*TAU/4.0
			paths.append([points[-1],points[-1]+Vector3(cos(angle)*.42,.25,sin(angle)*.42)])
	elif role=="electric_spark":
		var at:Vector3=points[-1]
		for i in range(6):
			var a:float=float(i)*TAU/6.0+t*TAU
			paths.append([at,at+Vector3(cos(a)*.46,.2*sin(a),sin(a)*.46)])
	elif role=="electric_dash":
		var at:Vector3=travel_tip
		var dir:Vector3=(points[-1]-points[0]).normalized()
		var side:Vector3=dir.cross(Vector3.UP)
		for i in range(3):
			var off:Vector3=side*float(i-1)*.16
			paths.append([at-dir*.7+off,at+off])
	elif role=="electric_fang":
		var at:Vector3=points[-1]
		for i in range(3):
			var off:Vector3=Vector3.RIGHT*float(i-1)*.18
			var bite:float=.45*(1.0-travel) if not arrived else .22*strike_progress
			paths.append([at+off+Vector3.UP*(bite+.2),at+off,at+off-Vector3.UP*(bite+.2)])
	elif role=="electric_beam":
		var prefix:Array=combat_path_prefix(points,travel)
		paths.append(prefix)
		var dir:Vector3=(points[-1]-points[0]).normalized()
		var side:Vector3=dir.cross(Vector3.UP)*.12
		var left:Array=[];var right:Array=[]
		for point in prefix:
			var beam_point:Vector3=point
			left.append(beam_point+side);right.append(beam_point-side)
		paths.append(left);paths.append(right)
	elif role=="electric_room":
		for tile in tiles:
			var at:Vector3=tile+Vector3.UP*.35
			paths.append([at+Vector3(-.32,.12,0),at,at+Vector3(.32,.12,0)])
	elif role in ["electric_bind","electric_charge","electric_lift","electric_orb"]:
		var at:Vector3=points[-1] if role=="electric_bind" else points[0] if role!="electric_orb" else travel_tip
		var radius:float=.38 if role=="electric_bind" else .55*(1.0-t*.6) if role=="electric_charge" else .36
		var rings:int=2 if role!="electric_lift" else 3
		for i in range(rings):
			var path:Array=[]
			for j in range(9):
				var a:float=float(j)*TAU/8.0+t*TAU
				var y:float=float(i)*.18+(t*.65 if role=="electric_lift" else 0.0)
				path.append(at+Vector3(cos(a)*radius,y,sin(a)*radius))
			paths.append(path)
	elif role=="electric_area":
		for tile in tiles:
			var target:Vector3=tile
			paths.append([points[0],target+Vector3(0,.4,0)])
	elif role=="electric_contact":
		paths.append([points[0],points[-1]])
		for i in range(5):
			var angle:float=float(i)*TAU/5.0+float(frame%3)*.2
			paths.append([points[-1],points[-1]+Vector3(cos(angle)*.55,sin(angle)*.38,sin(angle)*.44)])
	else:paths.append(combat_path_prefix(points,travel))
	for path in paths:
		for k in range(path.size()-1):
			var start:Vector3=path[k];var end:Vector3=path[k+1]
			if start.distance_squared_to(end)<.000001:continue
			var last:=start
			var side:Vector3=(end-start).cross(Vector3.UP).normalized()
			for j in range(1,10):
				if fx_arc_segments>=1000:return
				var f:float=float(j)/9.0
				var q:=start.lerp(end,f)
				if j<9:
					var jitter:float=.42 if role=="electric_wave" else .55 if role=="electric_short" else 1.0
					var axis:Vector3=side if side.length_squared()>.0001 else Vector3.RIGHT
					q+=(axis*float(posmod(j*19+k*7+frame*13,19)-9)*.038+Vector3.UP*float(posmod(j*11+frame*7,17)-8)*.045)*jitter
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
# Original procedural SFX. Anatomy and trajectory determine the acoustic
# gesture; elemental synthesis supplies the underlying material.
const AUDIO_ELEMENT_FORM={"normal":"thump","fire":"flame","water":"liquid","electric":"arc","grass":"rustle","ice":"glass","ground":"rumble","rock":"stone","fighting":"thump","flying":"wind","poison":"viscous","bug":"chitin","psychic":"resonance","ghost":"spectral","dark":"void","dragon":"roar","steel":"metal","fairy":"chime"}
func combat_audio_form(id:String,profile:Dictionary)->String:
	var role:String=str(profile.role)
	var contact:=directed_contact_kind(id,role)
	if contact.begins_with("kick"):return "kick"
	if contact.begins_with("fist"):return "punch"
	if contact in ["fang","crunch"]:return contact
	if contact in ["claw","pincer"]:return contact
	var impact:=directed_impact_form(profile)
	if impact in ["detonation","implosion","shockwave"]:return impact
	var projectile:=directed_projectile_form(id,role)
	if projectile in ["beam","aurora_beam","frost_beam","prism_beam","signal_beam","arc_beam","metal_beam"]:return "beam"
	if projectile in ["bubble","bubble_train"]:return "bubble"
	if projectile in ["needle","ice_needle","metal_needle","thorn_needle","twin_needle","wind_blade","leaf_blade"]:return "slice"
	return str(AUDIO_ELEMENT_FORM.get(str(profile.element),"thump"))

func combat_audio_envelope(progress:float,phase:String)->float:
	var p:float=clampf(progress,0.0,1.0)
	var attack:float=.045 if phase in ["impact","miss"] else .12
	var release:float=.14 if phase=="impact" else .22
	return smoothstep(0.0,attack,p)*(1.0-smoothstep(1.0-release,1.0,p))*pow(1.0-p,.85)

func combat_audio_duration(profile:Dictionary,form:String,phase:String)->float:
	var peak:float=clampf(float(profile.impact),.01,.99)
	var duration:float=float(profile.duration)
	if phase=="launch":return clampf(duration*peak,.045,.42)
	if phase=="miss":return .095
	if phase=="status":return .20
	var tail:float=.25 if form in ["detonation","rumble","roar","implosion","shockwave"] else .16
	return clampf(minf(tail,maxf(.085,duration*(1.0-peak))),.085,.30)

func combat_sound(id:String,phase:String,variant:int)->AudioStreamWAV:
	var key:=id+":"+phase+":"+str(variant)
	if fx_audio_cache.has(key):return fx_audio_cache[key]
	var profile:=combat_profile(id)
	var element:String=profile.element
	var role:String=profile.role
	var seed_value:int=posmod(hash(key),2147483647)
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var form:=combat_audio_form(id,profile)
	var duration:=combat_audio_duration(profile,form,phase)
	var rate:int=22050
	var samples:int=int(duration*rate)
	var data:=PackedByteArray();data.resize(samples*2)
	var last_noise:float=0.0
	var slow_noise:float=0.0
	var pitch:float=1.0+float(seed_value%23-11)*.012+float(variant-1)*.06
	for i in range(samples):
		var t:float=float(i)/rate;var p:float=float(i)/samples
		var noise:float=rng.randf_range(-1.0,1.0)
		last_noise=lerpf(last_noise,noise,.18)
		slow_noise=lerpf(slow_noise,noise,.045)
		var envelope:float=combat_audio_envelope(float(i)/maxi(1,samples-1),phase)
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
		# A second, authored acoustic layer separates attacks within each nature.
		var accent:float=0.0
		var strike:bool=phase=="impact"
		var sweep:float=sin(TAU*pitch*(780.0*t-560.0*t*p))
		match form:
			"punch","kick","thump":
				accent=sin(TAU*pitch*(125.0*t-65.0*t*p))*pow(1.0-p,2.0)*.64+(noise-last_noise)*.22
				if form=="kick":accent+=last_noise*.30*sin(p*PI)
			"fang","crunch","pincer":
				var snap:float=pow(maxf(0.0,cos(p*TAU*(2.0 if form=="crunch" else 1.0))),5.0)
				accent=(noise-last_noise)*snap*.66+sin(TAU*170.0*t*pitch)*snap*.28
			"claw","slice","wind":accent=(noise-last_noise)*(.35+.25*sin(p*PI))+sweep*.20
			"detonation","shockwave","rumble","stone":
				accent=slow_noise*.85+sin(TAU*pitch*(72.0*t-32.0*t*p))*.55*pow(1.0-p,1.8)
			"implosion","void":accent=sin(TAU*pitch*(180.0*t+640.0*t*p))*.42+slow_noise*.35
			"bubble","liquid":accent=sin(TAU*pitch*(580.0*t-380.0*t*p)+sin(p*TAU*3.0)*1.6)*.44
			"glass","metal":accent=sin(TAU*1760.0*t*pitch)*.26+sin(TAU*2630.0*t*pitch)*.16
			"chime","resonance","beam":accent=sin(TAU*pitch*(520.0*t+180.0*t*p))*.32+sin(TAU*1040.0*t*pitch)*.18
			"spectral":accent=sin(TAU*pitch*(310.0*t-140.0*t*p)+sin(t*TAU*15.0)*2.2)*.38
			"flame","roar":accent=slow_noise*.65+last_noise*.45
			"arc":accent=(noise-last_noise)*.38*(.55+.45*sin(p*TAU*7.0))
			"rustle","chitin":accent=(noise-last_noise)*.38*absf(sin(p*TAU*4.0))
			"viscous":accent=sin(TAU*pitch*(180.0*t-70.0*t*p)+sin(p*TAU*4.0)*2.6)*.34
		wave=wave*.60+accent*(.85 if strike else .62)
		if strike:wave+=sin(TAU*95.0*t*pitch)*.17*pow(1.0-p,2.0)
		elif phase=="miss":wave=(noise-last_noise)*.34+sweep*.12
		elif phase=="status":wave=sin(TAU*520.0*t*pitch)*.32+sin(TAU*780.0*t*pitch)*.24+wave*.22
		# Smooth saturation, with exact silent endpoints to avoid PCM clicks.
		var signal_value:float=wave*envelope*.85
		var pcm:int=roundi(clampf(signal_value/(1.0+absf(signal_value)*.35),-.95,.95)*32767.0)
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
	var slot:int=fx_audio_cursor
	# Prefer an idle voice instead of cutting an unrelated attack.
	for i in range(fx_audio.size()):
		var candidate:int=posmod(fx_audio_cursor+i,fx_audio.size())
		if not fx_audio[candidate].playing:slot=candidate;break
	var player_audio:=fx_audio[slot];fx_audio_cursor=posmod(slot+1,fx_audio.size())
	if player_audio.playing and phase in ["miss","status"]:return
	player_audio.stop();player_audio.position=at;player_audio.stream=combat_sound(id,phase,variant)
	player_audio.volume_db=-18.0 if phase=="miss" else -14.0 if phase=="status" else -12.0
	player_audio.play()
# Tile anchors remain deterministic; sprite scale and hover offset locate the
# launch/impact socket without moving logical combat or collision tiles.
func combat_socket_height(socket:String,scale:float=1.0,rise:float=0.0)->float:
	if socket=="ground":return .13
	return (.66 if socket=="head" else .45)*maxf(.1,scale)+maxf(0.0,rise)

func combat_actor_socket(actor:Node3D,socket:String)->float:
	if not is_instance_valid(actor):return combat_socket_height(socket)
	var scale:float=float(actor.get_meta("enemy_size_multiplier",1.0))
	var sprite:=actor.get_node_or_null("EnemyPixel") as Sprite3D
	# Remove squash/stretch from measured altitude: deformation is not flight.
	var rise:float=sprite.position.y-.54*scale*sprite.scale.y if sprite!=null else 0.0
	if actor==pet_pose or actor.get_meta("companion_disguise",false):rise+=actor.position.y
	return combat_socket_height(socket,scale,maxf(0.0,rise))

func combat_target_actor(cell:Vector2i)->Node3D:
	if run==null:return null
	if cell==run.player:return disguise_actor if is_instance_valid(disguise_actor) else pet_pose
	for enemy in run.enemies:
		if enemy.pos==cell:
			var actor=actor_nodes.get("enemy:"+str(enemy.get("uid",-1)))
			if is_instance_valid(actor) and not actor.is_queued_for_deletion():return actor
	# Defeated actors may still await impact; their logical target is retained.
	for key in actor_nodes:
		if not str(key).begins_with("enemy:"):continue
		var actor=actor_nodes[key]
		if is_instance_valid(actor) and not actor.is_queued_for_deletion() and actor.get_meta("target",Vector3.INF)==pos(cell):return actor
	return null

func combat_waypoints(source:Vector2i,target:Vector2i,path:Array,source_height:float,target_height:float)->Array:
	var points:Array=[pos(source)+Vector3.UP*source_height]
	var cells:Array=[source]
	for cell in path:
		if cell is Vector2i and cell!=cells[-1]:cells.append(cell)
	if cells[-1]!=target:cells.append(target)
	if cells.size()==1:
		points.append(pos(target)+Vector3.UP*target_height)
	else:
		for i in range(1,cells.size()):
			points.append(pos(cells[i])+Vector3.UP*lerpf(source_height,target_height,float(i)/float(cells.size()-1)))
	return points

# Deferred casts snapshot heights along with tiles, not live actors at replay time.
func snapshot_counter_geometry(event:Dictionary,source_actor:Node3D,target_actor:Node3D)->Dictionary:
	var result:Dictionary=event.duplicate(true)
	var profile:=combat_profile(str(result.fx))
	result["source_height"]=combat_actor_socket(source_actor,str(profile.socket))
	result["target_height"]=combat_actor_socket(target_actor,"center")
	return result

func combat_fx_spawn(event:Dictionary)->void:
	if not is_instance_valid(combat_fx_root):return
	var id:String=str(event.get("fx","basic_strike"))
	var style:Array=combat_style(id)
	var profile:=combat_profile(id)
	var source:Vector2i=event.get("from",Vector2i.ZERO)
	var target:Vector2i=event.get("to",source)
	var source_actor:Node3D=null
	if event.has("uid"):
		var candidate=actor_nodes.get("enemy:"+str(event.uid))
		if is_instance_valid(candidate):source_actor=candidate
	else:
		source_actor=disguise_actor if is_instance_valid(disguise_actor) else pet_pose
	var height:float=float(event.get("source_height",combat_actor_socket(source_actor,str(profile.socket))))
	var target_height:float=float(event.get("target_height",combat_actor_socket(combat_target_actor(target),"center")))
	if source==target and str(profile.socket)=="ground":target_height=height
	var waypoints:Array=combat_waypoints(source,target,event.get("path",[target]),height,target_height)
	var tiles:Array=[]
	for cell in event.get("tiles",[target]):tiles.append(pos(cell)+Vector3(0,.12,0))
	if tiles.is_empty():tiles.append(pos(target)+Vector3(0,.12,0))
	if combat_bursts.size()>=COMBAT_BURST_CAP:
		retire_combat_burst(combat_bursts.pop_front())
	combat_bursts.append({"id":id,"mode":style[0],"profile":profile,"target_player":event.get("target_player",false),"damage":event.get("damage",0),"impacted":false,"age":0.0,"duration":float(style[3]),"points":waypoints,"tiles":tiles,"texture":combat_animated_texture(id,0),"airborne_start":not event.has("uid") and release_charge_phase=="airborne","results":event.get("results",{}).duplicate(true)})
	var burst:Dictionary=combat_bursts[-1]
	burst["impact_waves"]=cast_impact_waves(burst.results)
	burst["impact_times"]=reaction_times(float(burst.duration),float(profile.impact),burst.impact_waves.size())
	burst["impact_cursor"]=0
	play_combat_sound(id,"launch",waypoints[0])
# Leading projectile reaches its destination on the exact impact fraction.
# Trailing particles are delayed within the remaining lifetime, never beyond it.
func combat_travel_progress(t:float,impact:float,trail:float=0.0)->float:
	var peak:float=clampf(impact,.001,.999)
	var delay:float=clampf(trail,0.0,.9)*(1.0-peak)
	return clampf((t-delay)/peak,0.0,1.0)

func combat_path_sample(points:Array,t:float)->Vector3:
	if points.is_empty():return Vector3.ZERO
	if points.size()==1 or t<=0.0:return points[0]
	if t>=1.0:return points[-1]
	# Distance weighting prevents short/long segments from moving at different speeds.
	var length:float=0.0
	for i in range(1,points.size()):
		var a:Vector3=points[i-1]
		length+=a.distance_to(points[i])
	if length<.00001:return points[-1]
	var remaining:float=clampf(t,0.0,1.0)*length
	for i in range(1,points.size()):
		var a:Vector3=points[i-1]
		var distance:float=a.distance_to(points[i])
		if distance<.00001:continue
		if remaining<=distance:return a.lerp(points[i],remaining/distance)
		remaining-=distance
	return points[-1]
# World-space anatomy of a lash: one continuous extending/retracting stem, not
# repeated thumbnail sprites. Leaves and tendrils follow the actual curve.
func vine_world_lash(points:Array,t:float,profile:Dictionary,id:String)->void:
	var style:Array=combat_style(id)
	var light:=Color(style[1]);var dark:=Color(style[2]);var outline:=dark.darkened(.55)
	var peak:float=clampf(float(profile.impact),.12,.88)
	var hold:float=peak+(1.0-peak)*.25
	var reach:float=combat_travel_progress(t,peak) if t<hold else clampf((1.0-t)/maxf(.01,1.0-hold),0.0,1.0)
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
		var width:float=lerpf(.095,.026,f)*(1.8 if profile.role=="grass_whip" else 1.0)
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
func reaction_times(duration:float,impact:float,count:int)->Array[float]:
	var times:Array[float]=[]
	var first:float=maxf(0.0,duration*clampf(impact,0.0,1.0))
	var span:float=maxf(0.0,duration-first)
	for i in range(clampi(count,1,12)):
		times.append(first+span*.85*float(i)/maxi(1,clampi(count,1,12)-1))
	return times

func queue_enemy_reaction(actor:Node3D,defeated:bool,delay:float,direction:Vector3=Vector3.ZERO,span:float=0.0,count:int=1,explicit_times:Array[float]=[])->void:
	if not is_instance_valid(actor):return
	# If a new action kills an actor before its earlier hit resolves, retire the
	# older nonterminal callbacks so they cannot overwrite its defeat pose.
	if defeated:
		for i in range(fx_reactions.size()-1,-1,-1):
			if fx_reactions[i].actor==actor:fx_reactions.remove_at(i)
	actor.set_meta("pending_impact",true)
	if defeated:actor.set_meta("pending_defeat",true)
	var times:Array[float]=explicit_times if not explicit_times.is_empty() else reaction_times(delay+span,delay/(delay+span) if delay+span>0.0 else 0.0,count)
	for i in range(times.size()):
		fx_reactions.append({"actor":actor,"delay":times[i],"defeated":defeated and i==times.size()-1,"direction":direction})

func update_combat_reactions(dt:float)->void:
	# Process chronological order even if a slow frame crosses several impacts.
	var due:Array[Dictionary]=[]
	for i in range(fx_reactions.size()-1,-1,-1):
		var reaction:Dictionary=fx_reactions[i]
		reaction.delay-=dt
		if float(reaction.delay)>0.0:continue
		due.append(reaction);fx_reactions.remove_at(i)
	due.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if float(a.delay)==float(b.delay):return not bool(a.defeated) and bool(b.defeated)
		return float(a.delay)<float(b.delay))
	for reaction in due:
		var actor=reaction.actor
		if not is_instance_valid(actor) or actor.is_queued_for_deletion():continue
		if str(actor.get_meta("enemy_phase",""))=="defeat":continue
		var pending:bool=false
		for next in fx_reactions:
			if next.actor==actor:pending=true;break
		actor.set_meta("pending_impact",pending)
		actor.set_meta("enemy_hit_direction",reaction.direction)
		enemy_pose(actor,"defeat" if reaction.defeated else "hurt",.32 if reaction.defeated else .20)
		queue_ultra_reaction(actor.global_position+Vector3.UP*.54,reaction.direction,bool(reaction.defeated))
		# The actor renderer advances dt later in this frame. Subtract the
		# pre-impact portion now so only the actual post-impact age is applied.
		actor.set_meta("enemy_clock",-clampf(dt+float(reaction.delay),0.0,dt))
		if reaction.defeated:
			actor.set_meta("pending_defeat",false)
			var bar=actor.get_node_or_null("HP")
			var warning=actor.get_node_or_null("Warning")
			if bar!=null:bar.hide()
			if warning!=null:warning.hide()
# Both immediate and delayed casts use the same body presentation contract.
func player_cast_sample(id:String,source:Vector2i,target:Vector2i,age:float=0.0)->Dictionary:
	var profile:=combat_profile(id)
	var duration:float=float(profile.duration)
	var direction:Vector3=(pos(target)-pos(source)).normalized()
	if direction.length_squared()<.0001:direction=Vector3(facing.x,0,facing.y).normalized()
	return {"duration":duration,"remaining":maxf(0.0,duration-age),"impact":float(profile.impact),"impact_delay":maxf(0.0,duration*float(profile.impact)-age),"role":str(profile.role),"motion":cast_motion_kind(id,profile),"direction":direction}

func tile_cast_kind(id:String)->String:
	if id=="eos_008":return "burrow"
	if id=="eos_477":return "vanish"
	if id=="eos_156":return "dive"
	if id in TILE_CAST_AIR:return "air"
	if id in TILE_CAST_GROUND:return "ground"
	return ""

func tile_cast_route(event:Dictionary)->Array:
	var source:Vector2i=event.from
	var target:Vector2i=event.to
	var points:Array=[pos(source)]
	for cell in event.get("path",[]):
		if cell is Vector2i and pos(cell)!=points[-1]:points.append(pos(cell))
		if cell==target:break
	if points[-1]!=pos(target):points.append(pos(target))
	return points

# Full path from origin to target at the same impact clock as the FX, then
# reverse the path. Travel is visual: it never picks up loot or consumes turns.
func tile_cast_sample(points:Array,kind:String,progress:float,impact:float,airborne_start:bool=false)->Dictionary:
	var p:float=clampf(progress,0.0,1.0)
	var peak:float=clampf(impact,.12,.88)
	var returning:bool=p>peak
	var linear:float=clampf(p/peak if not returning else (1.0-p)/(1.0-peak),0.0,1.0)
	# Ease both legs at their endpoints, preserving the exact impact clock.
	var u:float=smoothstep(0.0,1.0,linear)
	var location:Vector3=combat_path_sample(points,u)
	var lo:Vector3=combat_path_sample(points,maxf(0.0,u-.015))
	var hi:Vector3=combat_path_sample(points,minf(1.0,u+.015))
	var motion:Vector3=(hi-lo).normalized()
	if returning:motion=-motion
	var arc:float=sin(PI*u)
	var height:float=0.0
	var visible:bool=true
	match kind:
		"air":
			height=1.25*arc
			if not returning and airborne_start:height+=.95*(1.0-u)
		"burrow","dive":
			# Distinct soil/water depth and resurfacing arcs.
			visible=returning or u>=.76
			height=(.28 if kind=="dive" else .45)*arc if returning else -(.24 if kind=="dive" else .38)*(1.0-u)
		"vanish":
			visible=returning or u>=.76
			height=.35*arc if returning else 0.0
		_:height=.12*arc
	return {"position":location+Vector3.UP*height,"motion":motion,"visible":visible,"returning":returning,"height":height,"path_progress":u}

func tile_cast_active()->bool:
	return attack_time>0.0 and not player_tile_cast.is_empty()

func finish_tile_cast()->void:
	if player_tile_cast.is_empty():return
	var points:Array=player_tile_cast.points
	if points.size()>1:
		var direction:Vector3=points[0]-points[1]
		facing=Rules.aim8(Vector2(direction.x,direction.z))
		lab_update_aim()
		if is_instance_valid(aim_button):aim_button.text="Aim "+["↑","↗","→","↘","↓","↙","←","↖"][maxi(0,Rules.DIR8.find(facing))]
	player_tile_cast.clear()

func begin_player_cast_pose(event:Dictionary,age:float=0.0)->void:
	var sample:=player_cast_sample(str(event.fx),event.from,event.to,age)
	player_cast_duration=float(sample.duration);player_cast_mode=str(sample.role)
	attack_time=float(sample.remaining);player_cast_motion=str(sample.motion)
	player_cast_impact=float(sample.impact);player_impact_delay=float(sample.impact_delay)
	player_cast_waves=caster_wave_times(event,player_cast_duration,player_cast_impact)
	attack_direction=sample.direction
	player_tile_cast.clear()
	var tile_kind:String=tile_cast_kind(str(event.fx))
	if not tile_kind.is_empty() and event.from!=event.to:
		player_tile_cast={"kind":tile_kind,"points":tile_cast_route(event)}
	if is_instance_valid(attack_fx):
		attack_fx.position=pos(event.to)+Vector3(0,.24,0)
		attack_fx.visible=player_impact_delay<=0.0 and attack_time>0.0

func delayed_cast_can_replay(duration:float,age:float,dt:float,body_remaining:float)->bool:
	# Compare the previous animation against the actual launch instant, not the end of the frame.
	return age<duration and body_remaining<=maxf(0.0,dt-age)+.0001

func update_delayed_combat_fx(dt:float)->void:
	var due:Array[Dictionary]=[]
	for i in range(delayed_combat_fx.size()-1,-1,-1):
		var item:Dictionary=delayed_combat_fx[i]
		item.delay-=dt
		if float(item.delay)<=0.0:
			due.append(item);delayed_combat_fx.remove_at(i)
	due.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.delay)<float(b.delay))
	for item in due:
		# This frame's elapsed fraction is applied once, not twice.
		if not is_instance_valid(combat_fx_root):continue
		var age:float=maxf(0.0,-float(item.delay))
		combat_fx_spawn(item.event)
		if not combat_bursts.is_empty():combat_bursts[-1].age=age-dt
		# Do not turn a moved companion toward a historical origin, or interrupt
		# a newer attack/charge. The independently recorded world FX still plays.
		if delayed_cast_can_replay(float(combat_profile(str(item.event.fx)).duration),age,dt,attack_time) and run!=null and run.player==item.event.from and run.charge_phase.is_empty():
			release_charge_phase=""
			begin_player_cast_pose(item.event,age-dt)

# Rendering visits newer bursts first, but the last actual impact wins the hurt pose.
# A visual budget eviction must not silently cancel a pending hit or sound.
# Each wave is one recorded attempt per affected tile, not a guessed hit count.
func cast_impact_waves(results:Dictionary)->Array[Dictionary]:
	var count:int=1
	for tile in results:
		count=maxi(count,mini(12,results[tile].get("attempts",[]).size()))
	if count==1:return [results]
	var waves:Array[Dictionary]=[]
	for i in range(count):
		var wave:Dictionary={}
		for tile in results:
			var row:Dictionary=results[tile]
			var attempts:Array=row.get("attempts",[])
			if attempts.is_empty():
				if i==0:wave[tile]=row
				continue
			if i>=attempts.size():continue
			var attempt:Dictionary=attempts[i].duplicate()
			if i==attempts.size()-1:
				if row.has("status"):attempt["status"]=row.status
				if row.has("heal"):attempt["heal"]=row.heal
			wave[tile]=attempt
		waves.append(wave)
	return waves

# The same attempt ledger drives world FX and caster pose. Split only the
# cosmetic body clock; movement routes and gameplay remain on global time.
func caster_wave_times(event:Dictionary,duration:float,impact:float)->Array[float]:
	var waves:=cast_impact_waves(event.get("results",{}))
	if waves.size()<2:return []
	return reaction_times(duration,impact,waves.size())

func caster_wave_progress(age:float,duration:float,impact:float,times:Array)->float:
	var t:float=clampf(age,0.0,maxf(.001,duration))
	var peak:float=clampf(impact,.12,.88)
	if times.size()<2:return clampf(t/maxf(.001,duration),0.0,1.0)
	var index:int=0
	while index+1<times.size() and t>(float(times[index])+float(times[index+1]))*.5:
		index+=1
	var contact:float=float(times[index])
	var start:float=0.0 if index==0 else (float(times[index-1])+contact)*.5
	var finish:float=duration if index==times.size()-1 else (contact+float(times[index+1]))*.5
	if t<=contact:return peak*clampf((t-start)/maxf(.000001,contact-start),0.0,1.0)
	return peak+(1.0-peak)*clampf((t-contact)/maxf(.000001,finish-contact),0.0,1.0)

func confirmed_wave_times(results:Dictionary,tile:Vector2i,duration:float,impact:float)->Array[float]:
	var waves:=cast_impact_waves(results)
	var times:=reaction_times(duration,impact,waves.size())
	var confirmed:Array[float]=[]
	for i in range(waves.size()):
		if int(waves[i].get(tile,{}).get("damage",0))>0:confirmed.append(times[i])
	return confirmed

func dispatch_cast_waves(burst:Dictionary)->void:
	var waves:Array=burst.get("impact_waves",[])
	var times:Array=burst.get("impact_times",[])
	var cursor:int=int(burst.get("impact_cursor",0))
	while cursor<times.size() and float(burst.age)>=float(times[cursor]):
		var wave:Dictionary=waves[cursor]
		show_cast_results(wave)
		ultra_impact_residue(burst,wave,cursor==0,maxf(0.0,float(burst.age)-float(times[cursor])))
		var audible:bool=wave.is_empty() and cursor==0
		var target:Vector3=burst.points[-1]
		var nearest:float=INF
		var strongest:int=0
		var critical:bool=false
		for tile in wave:
			var row:Dictionary=wave[tile]
			var amount:int=int(row.get("damage",0))
			strongest=maxi(strongest,amount)
			critical=critical or (amount>0 and int(row.get("crit",0))>0)
			if amount+int(row.get("effects",0))+int(row.get("heal",0))>0:
				audible=true
				var point:Vector3=pos(tile)+Vector3.UP*target.y
				var distance:float=point.distance_squared_to(burst.points[-1])
				if distance<nearest:nearest=distance;target=point
		# Do not emit a damage thump for a status effect or an explicit miss.
		var audio_age:float=maxf(0.0,float(burst.age)-float(times[cursor]))
		if audio_age<.14:
			if strongest>0 or (wave.is_empty() and int(burst.get("damage",0))>0):
				play_combat_sound(str(burst.id),"impact",target)
			elif audible:play_combat_sound(str(burst.id),"status" if not wave.is_empty() else "impact",target)
			elif not wave.is_empty():play_combat_sound(str(burst.id),"miss",target)
		if strongest>0 or (wave.is_empty() and cursor==0 and int(burst.get("damage",0))>0):
			var age:float=maxf(0.0,float(burst.age)-float(times[cursor]))
			queue_contact_camera(burst.points[0],target,critical,age)
		cursor+=1
	burst["impact_cursor"]=cursor

# A subtle directional impulse only on confirmed damage; no camera zoom,
# no hit-stop and no re-centering on the enemy's logical tile.
func contact_camera_sample(progress:float)->float:
	var t:float=clampf(progress,0.0,1.0)
	return (1.0-t)*(1.0-t)*sin(t*TAU*1.25)

func queue_contact_camera(source:Vector3,target:Vector3,critical:bool,age:float)->void:
	if age>=.18 or age>fx_contact_camera_age:return
	var direction:=Vector3(target.x-source.x,0,target.z-source.z).normalized()
	if direction.length_squared()<.0001:return
	fx_contact_camera=direction*(.065 if critical else .038)
	fx_contact_camera_age=age

func retire_combat_burst(burst:Dictionary)->void:
	if int(burst.get("impact_cursor",0))>=burst.get("impact_times",[]).size():return
	var record:Dictionary={"id":burst.id,"age":burst.age,"duration":burst.duration,"profile":burst.profile,"points":[burst.points[0],burst.points[-1]],"target_player":burst.get("target_player",false),"damage":burst.get("damage",0),"results":burst.get("results",{}).duplicate(true),"impact_waves":burst.impact_waves,"impact_times":burst.impact_times,"impact_cursor":burst.impact_cursor,"impacted":burst.impacted}
	if retired_impacts.size()>=RETIRED_IMPACT_CAP:
		var replace_index:int=-1
		for i in range(retired_impacts.size()):
			if not retired_impacts[i].target_player or int(retired_impacts[i].damage)<=0:
				replace_index=i;break
		if replace_index<0:
			if not record.target_player or int(record.damage)<=0:return
			replace_index=0
		retired_impacts.remove_at(replace_index)
	retired_impacts.append(record)

func update_retired_impacts(dt:float)->Dictionary:
	var latest:Dictionary={}
	for i in range(retired_impacts.size()-1,-1,-1):
		var record:Dictionary=retired_impacts[i]
		record.age+=dt
		dispatch_cast_waves(record)
		if not bool(record.impacted) and float(record.age)>=float(record.duration)*float(record.profile.impact):
			record.impacted=true
			if str(record.profile.role) in ["ground","earth_quake","earth_magnitude","earth_fissure"]:fx_ground_shake=.22
			if record.target_player and int(record.damage)>0:latest=latest_player_impact(latest,record)
		if int(record.impact_cursor)>=record.impact_times.size():retired_impacts.remove_at(i)
	return latest

func latest_player_impact(current:Dictionary,burst:Dictionary)->Dictionary:
	var age:float=maxf(0.0,float(burst.age)-float(burst.duration)*float(burst.profile.impact))
	if age>=.24 or (not current.is_empty() and age>=float(current.age)):return current
	var direction:Vector3=(burst.points[-1]-burst.points[0]).normalized()
	direction.y=0.0
	return {"age":age,"direction":direction}

# Fair streaming allocation: unused slots flow to the remaining casts.
# Only the visual pool is shared; damage, impacts and sound never wait.
func cast_particle_quota(used:int,capacity:int,remaining:int)->int:
	return maxi(0,capacity-used)/maxi(1,remaining)

# A sustained frame-time threshold with asymmetric recovery prevents flicker.
# Resume/loading spikes are ignored; the effect tier is not a gameplay setting.
func update_fx_performance(dt:float)->void:
	if dt<=0.0 or dt>.25:
		fx_pressure_age=0.0;fx_recovery_age=0.0
		return
	if fx_performance_grace>0.0:
		fx_performance_grace=maxf(0.0,fx_performance_grace-dt)
		return
	fx_frame_average=lerpf(fx_frame_average,dt,1.0-exp(-dt*3.0))
	var pressure_threshold:float=.024 if fx_performance_tier==0 else .033
	var recovery_threshold:float=.020 if fx_performance_tier==1 else .026
	if fx_performance_tier<2 and fx_frame_average>pressure_threshold:
		fx_pressure_age+=dt;fx_recovery_age=0.0
		if fx_pressure_age>=1.0:
			fx_performance_tier+=1;fx_pressure_age=0.0
	elif fx_performance_tier>0 and fx_frame_average<recovery_threshold:
		fx_recovery_age+=dt;fx_pressure_age=0.0
		if fx_recovery_age>=4.0:
			fx_performance_tier-=1;fx_recovery_age=0.0
	else:
		fx_pressure_age=0.0;fx_recovery_age=0.0

func residue_particle_count()->int:
	return 4 if fx_performance_tier==0 else 3 if fx_performance_tier==1 else 2

func combat_fx_update(dt:float)->void:
	update_cast_text(dt)
	var latest_hit:Dictionary={}
	update_delayed_combat_fx(dt)
	var used:int=0
	fx_lights_used=0;fx_halos_used=0;fx_light_scores.clear()
	fx_trail_vertices=0;fx_trail_started=false
	if is_instance_valid(fx_trail_mesh):fx_trail_mesh.clear_surfaces()
	update_combat_reactions(dt)
	fx_ground_shake=maxf(0.0,fx_ground_shake-dt*3.0)
	fx_contact_camera_age=minf(1.0,fx_contact_camera_age+dt)
	latest_hit=update_retired_impacts(dt)
	fx_arc_segments=0
	if is_instance_valid(fx_arc_mesh):fx_arc_mesh.clear_surfaces()
	var arcs_started:bool=false
	var remaining_casts:int=0
	for pending in combat_bursts:
		if float(pending.age)+dt<float(pending.duration):remaining_casts+=1
	var crowded:bool=remaining_casts>1
	# A crowded frame keeps slots for real hit reactions and charging.
	var reserve:int=24 if crowded else 0
	if run!=null and not run.charge_phase.is_empty():reserve=maxi(reserve,12)
	if not fx_reaction_sparks.is_empty():reserve=maxi(reserve,16)
	if not fx_residues.is_empty():reserve=maxi(reserve,12)
	var cast_capacity:int=FX_PARTICLE_CAP-reserve
	fx_cast_particle_limit=FX_PARTICLE_CAP
	for k in range(combat_bursts.size()-1,-1,-1):
		var burst:Dictionary=combat_bursts[k]
		burst.age+=dt
		var t:float=float(burst.age)/float(burst.duration)
		var profile:Dictionary=burst.profile
		dispatch_cast_waves(burst)
		if not burst.impacted and t>=float(profile.impact):
			burst.impacted=true
			if str(profile.role) in ["ground","earth_quake","earth_magnitude","earth_fissure"]:fx_ground_shake=.22
			if burst.get("target_player",false) and int(burst.get("damage",0))>0:
				latest_hit=latest_player_impact(latest_hit,burst)
		if t>=1.0:
			combat_bursts.remove_at(k);continue
		var share:int=cast_particle_quota(used,cast_capacity,remaining_casts)
		remaining_casts=maxi(0,remaining_casts-1)
		fx_cast_particle_limit=used+share
		cinematic_cast_enhancement(burst,t)
		ultra_attack_ribbons(burst,t)
		var mode:String=burst.mode
		var frame:int=clampi(int(t*FX_FRAME_COUNT),0,FX_FRAME_COUNT-1)
		# Hold the exact texture for the current authored frame, even if the
		# shared cache evicts it during a simultaneous multi-target attack.
		if int(burst.get("cached_frame",-1))!=frame:
			burst["cached_frame"]=frame
			burst["texture"]=combat_animated_texture(str(burst.id),frame)
		var animated:ImageTexture=burst.texture
		var points:Array=burst.points
		var tiles:Array=burst.tiles
		if str(profile.role).begins_with("electric") and t>.08 and t<.91:
			if not arcs_started:fx_arc_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,fx_arc_material);arcs_started=true
			electric_world_arc(points,t,str(profile.role),tiles,float(profile.impact))
		elif str(profile.role) in ["lash","ground","grass_vine","grass_whip","grass_needle","earth_quake","earth_magnitude","earth_fissure"] and t>.03:
			if not arcs_started:fx_arc_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,fx_arc_material);arcs_started=true
			if profile.role in ["lash","grass_vine","grass_whip","grass_needle"]:vine_world_lash(points,t,profile,str(burst.id))
			else:quake_world_tiles(tiles,t,str(burst.id))
		var count:int=mini(26,6+tiles.size()*2) if mode in ["cloud","wave","fan","web","shards","beam"] else 14
		if mode in ["flame","whip"]:count=22
		if str(profile.role).begins_with("electric"):count=4
		if profile.role=="lash":count=3
		if profile.role=="ground":count=mini(18,tiles.size()*3)
		# Keep elemental contact accents visible when the base spray is large.
		if crowded:count=mini(count,maxi(1,share*2/3))
		used=confirmed_contact_icons(burst,t,used)
		used=directed_impact_fx(burst,t,used)
		used=critical_contact_fx(burst,used)
		# Reserve the readable projectile head within the same shared cast quota.
		used=projectile_identity_fx(burst,t,used)
		used=ultimate_accent_fx(burst,t,used)
		for j in range(count):
			if used>=fx_cast_particle_limit:break
			var particle:=combat_particles[used];used+=1
			var f:float=float(j)/maxi(1,count-1)
			var angle:float=f*TAU+float(j)*2.399
			var q:Vector3
			var size:float=.55
			match str(profile.mode):
				"vine","whip":
					q=combat_path_sample(points,combat_travel_progress(t,float(profile.impact)));q.y+=.15*sin(angle);size=.22
				"quake":
					q=tiles[j%tiles.size()];q+=Vector3(cos(angle)*t*.32,sin(t*PI)*.65,sin(angle)*t*.32);size=.29
				"lightning","beam","radiant":
					var reach:float=combat_travel_progress(t,float(profile.impact))
					q=combat_path_sample(points,f*reach)
					q.y+=sin(f*PI*4.0-t*14.0)*(.10 if mode=="beam" else .24)
					size=.48 if mode!="beam" else .78
				"flame","fire_stream":
					var travel:float=combat_travel_progress(t,float(profile.impact),f*.65)
					q=combat_path_sample(points,travel)
					q+=Vector3(cos(angle)*travel*.20,sin(angle+t*7.0)*travel*.22, sin(angle)*travel*.20)
					size=.45+travel*.70
				"dart","bubble","bubble_beam","roll","spiral","meteor","leap":
					var travel:float=combat_travel_progress(t,float(profile.impact),f*.5)
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
			if profile.role=="electric_sky":
				q=points[-1]+Vector3(0,lerpf(2.8,.0,combat_travel_progress(t,float(profile.impact))),0);size=.75
			elif profile.role=="electric_burst":
				q=tiles[j%tiles.size()]+Vector3(0,.38,0);size=.62
			elif profile.role=="electric_short":
				q=points[-1]+Vector3(cos(angle)*.16,sin(angle)*.15,0);size=.30
			elif profile.role=="electric_wave":
				q=combat_path_sample(points,combat_travel_progress(t,float(profile.impact),f*.18));size=.70
			elif profile.role in ["electric_fist","electric_fang","electric_spark","electric_bind"]:
				q=points[-1]+Vector3(cos(angle)*.18,sin(angle)*.18,0);size=.45
			elif profile.role in ["electric_orb","electric_dash","electric_beam"]:
				q=combat_path_sample(points,combat_travel_progress(t,float(profile.impact),f*.12));size=.82 if profile.role=="electric_orb" else .42
			elif profile.role=="electric_room":
				q=tiles[j%tiles.size()]+Vector3(0,.42,0);size=.48
			elif profile.role in ["electric_charge","electric_lift"]:
				q=points[0]+Vector3(cos(angle)*.25,t*.55 if profile.role=="electric_lift" else .12,sin(angle)*.25);size=.48
			if str(profile.role).begins_with("fire_"):
				var fire_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.35)
				match fire_role:
					"fire_breath","fire_ember","fire_wisp":
						q=combat_path_sample(points,progress)+Vector3(cos(angle)*.12,sin(angle)*.14,sin(angle)*.12)
						size=.24 if fire_role=="fire_ember" else .38 if fire_role=="fire_wisp" else .35+progress*.65
					"fire_blast":
						q=combat_path_sample(points,progress)
						if t>.55:q+=Vector3(cos(angle),.3*sin(angle),sin(angle))*(t-.55)*.85
						size=.8
					"fire_overheat","fire_blastburn","fire_heatwave","fire_plume":
						q=tiles[j%tiles.size()]+Vector3(cos(angle)*t*.38,.15+sin(t*PI)*(.8 if fire_role=="fire_plume" else .35),sin(angle)*t*.38)
						size=.85 if fire_role=="fire_blastburn" else .58
					"fire_wheel","fire_blitz":
						q=combat_path_sample(points,progress)+Vector3(cos(angle+t*TAU)*.18,.1+absf(sin(angle+t*TAU))*.4,sin(angle+t*TAU)*.18)
						size=.72 if fire_role=="fire_blitz" else .46
					"fire_eruption":
						q=points[0].lerp(points[-1],progress)+Vector3(cos(angle)*.35,sin(progress*PI)*1.1,sin(angle)*.35)
						size=.62
					"fire_vortex","fire_magma":
						q=points[-1]+Vector3(cos(angle+t*TAU*2.0)*.45,f*.75,sin(angle+t*TAU*2.0)*.45)
						size=.9 if fire_role=="fire_magma" else .5
					"fire_sun":
						q=points[0]+Vector3(cos(angle)*.12,1.6+t*.35,sin(angle)*.12);size=.82
					_:
						q=points[-1]+Vector3(cos(angle)*.28,sin(angle)*.3,sin(angle)*.28);size=.62
			if str(profile.role).begins_with("water_"):
				var water_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.35)
				match water_role:
					"water_bubble","water_bubblebeam","water_ink","water_cannon","water_pump","water_gun","water_pulse","water_brine","water_jet":
						q=combat_path_sample(points,progress)+Vector3(cos(angle)*.12,sin(angle)*.13,sin(angle)*.12)
						size=.85 if water_role=="water_cannon" else .30 if water_role in ["water_gun","water_bubble"] else .55
					"water_whirlpool":
						q=points[-1]+Vector3(cos(angle+t*TAU)*.46,.12+f*.25,sin(angle+t*TAU)*.46);size=.54
					"water_spout":
						q=points[0].lerp(points[-1],progress)+Vector3(cos(angle)*.23,sin(progress*PI)*1.3,sin(angle)*.23);size=.64
					"water_fall":
						q=points[-1]+Vector3(cos(angle)*.2,1.5*(1.0-progress),sin(angle)*.2);size=.72
					"water_dive":
						q=points[-1]+Vector3(cos(angle)*t*.4,.04+sin(t*PI)*.26,sin(angle)*t*.4);size=.48
					"water_surf","water_mud":
						var direction:Vector3=(points[-1]-points[0]).normalized()
						q=combat_path_sample(points,progress)+direction.cross(Vector3.UP)*(f-.5)*.8+Vector3.UP*sin(t*PI)*.45
						size=.75 if water_role=="water_surf" else .55
					"water_ring","water_shell","water_mist":
						q=points[0]+Vector3(cos(angle+t*TAU)*.4,.15+f*.5,sin(angle+t*TAU)*.4);size=.48
					"water_rain":
						q=points[0]+Vector3(cos(angle)*.7,1.8*(1.0-progress),sin(angle)*.7);size=.28
					_:
						q=points[-1]+Vector3(cos(angle)*.32,sin(angle)*.28,sin(angle)*.32);size=.60
			if str(profile.role).begins_with("grass_"):
				var grass_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.35)
				match grass_role:
					"grass_absorb","grass_mega","grass_giga":
						var return_progress:float=clampf((t-.25)*1.55-f*.18,0,1)
						q=combat_path_sample(points,1.0-return_progress)+Vector3(cos(angle)*.12,sin(return_progress*PI)*.30,sin(angle)*.12)
						size=.25 if grass_role=="grass_absorb" else .40 if grass_role=="grass_mega" else .60
					"grass_razor","grass_magic","grass_solar","grass_energy","grass_bullet","grass_worry","grass_whistle":
						q=combat_path_sample(points,progress)+Vector3(cos(angle)*.1,sin(angle)*.12,sin(angle)*.1)
						size=.82 if grass_role=="grass_energy" else .38
					"grass_bomb","grass_leech":
						q=combat_path_sample(points,progress)+Vector3(0,sin(progress*PI)*.65,0);size=.54
					"grass_frenzy","grass_knot":
						q=points[-1]+Vector3(cos(angle)*.35,.1+sin(t*PI)*.9,sin(angle)*.35);size=.64
					"grass_spore","grass_sleep","grass_stun","grass_flare":
						q=tiles[j%tiles.size()]+Vector3(cos(angle)*t*.45,.15+f*.45,sin(angle)*t*.45);size=.46
					"grass_storm","grass_petal":
						q=combat_path_sample(points,progress)+Vector3(cos(angle+t*TAU)*.42,.2+f*.5,sin(angle+t*TAU)*.42);size=.48
					"grass_roots","grass_aroma","grass_synthesis":
						q=points[0]+Vector3(cos(angle)*.45,.1+sin(t*PI)*.65,sin(angle)*.45);size=.52
					"grass_vine","grass_whip","grass_needle":
						q=combat_path_sample(points,combat_travel_progress(t,float(profile.impact)))+Vector3(0,.12,0);size=.25
					_:
						q=points[-1]+Vector3(cos(angle)*.30,sin(angle)*.25,sin(angle)*.30);size=.55
			if str(profile.role).begins_with("ice_"):
				var ice_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.35)
				match ice_role:
					"ice_aurora","ice_beam","ice_wind","ice_shard","ice_spear","ice_ball":
						q=combat_path_sample(points,progress)+Vector3(cos(angle)*.1,sin(angle)*.13,sin(angle)*.1)
						if ice_role=="ice_ball":q.y=.14
						size=.75 if ice_role=="ice_beam" or ice_role=="ice_ball" else .44
					"ice_powder","ice_blizzard":
						q=tiles[j%tiles.size()]+Vector3(cos(angle+t*TAU)*.45,1.1*(1.0-progress),sin(angle+t*TAU)*.45);size=.35 if ice_role=="ice_powder" else .62
					"ice_hail","ice_avalanche":
						var at:Vector3=points[0] if ice_role=="ice_hail" else points[-1]
						q=at+Vector3(cos(angle)*.6,1.8*(1.0-progress),sin(angle)*.6);size=.4 if ice_role=="ice_hail" else .78
					"ice_haze","ice_mist":
						q=points[0]+Vector3(cos(angle+t*TAU)*.5,.2+f*.5,sin(angle+t*TAU)*.5);size=.65
					"ice_cold":
						q=points[-1]+Vector3(cos(angle)*t*.4,.1+sin(t*PI)*.7,sin(angle)*t*.4);size=.9
					_:
						q=points[-1]+Vector3(cos(angle)*.28,sin(angle)*.25,sin(angle)*.28);size=.58
			if str(profile.role).begins_with("earth_"):
				var earth_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.35)
				match earth_role:
					"earth_dig":
						q=points[-1]+Vector3(cos(angle)*t*.45,.08+sin(t*PI)*.55,sin(angle)*t*.45);size=.48
					"earth_tomb":
						q=points[-1]+Vector3(cos(angle+t*TAU)*.48,.1+f*.48,sin(angle+t*TAU)*.48);size=.50
					"earth_shot","earth_bomb","earth_slap","earth_dust":
						q=combat_path_sample(points,progress)+Vector3(cos(angle)*.1,sin(progress*PI)*(.75 if earth_role=="earth_bomb" else .18),sin(angle)*.1);size=.74 if earth_role=="earth_bomb" else .35
					"earth_return":
						q=combat_path_sample(points,sin(t*PI))+Vector3(0,.24+sin(t*PI)*.28,0);size=.65
					"earth_power","earth_quake","earth_magnitude","earth_fissure":
						q=tiles[j%tiles.size()]+Vector3(cos(angle)*.35,.07+sin(t*PI)*(.95 if earth_role=="earth_power" else .45),sin(angle)*.35);size=.58
					"earth_spikes":
						q=points[0]+Vector3(cos(angle)*.25,.05+sin(t*PI)*.22,sin(angle)*.25);size=.48
					"earth_mudcoat":
						q=points[0]+Vector3(cos(angle)*.4,.12+f*.5,sin(angle)*.4);size=.48
					_:
						q=points[-1]+Vector3(cos(angle)*.25,sin(angle)*.25,sin(angle)*.25);size=.65
			if str(profile.role).begins_with("rock_"):
				var rock_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.30)
				match rock_role:
					"rock_throw","rock_blast","rock_gem","rock_wrecker","rock_ancient":
						q=combat_path_sample(points,progress)+Vector3(cos(angle)*.12,sin(progress*PI)*(.85 if rock_role=="rock_throw" else .24),sin(angle)*.12)
						size=.95 if rock_role=="rock_wrecker" else .65 if rock_role=="rock_throw" else .45
					"rock_slide","rock_tomb":
						q=points[-1]+Vector3(cos(angle)*.45,1.8*(1.0-progress),sin(angle)*.45)
						size=.64
					"rock_edge":
						q=points[-1]+Vector3(cos(angle)*.28,.05+sin(t*PI)*.75,sin(angle)*.28);size=.70
					"rock_roll":
						q=combat_path_sample(points,progress)+Vector3(0,.12,0);size=.72
					"rock_smash":
						q=points[-1]+Vector3(cos(angle)*t*.45,sin(angle)*.27,sin(angle)*t*.45);size=.70
					"rock_polish":
						q=points[0]+Vector3(cos(angle+t*TAU)*.4,.2+f*.55,sin(angle+t*TAU)*.4);size=.46
					"rock_storm":
						q=points[0]+Vector3(cos(angle+t*TAU*2.0)*.75,.2+f*.8,sin(angle+t*TAU*2.0)*.75);size=.38
					"rock_trap":
						q=points[0]+Vector3(cos(angle)*.42,.04+t*.12,sin(angle)*.42);size=.45
			if str(profile.role).begins_with("fight_"):
				var fight_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.30)
				match fight_role:
					"fight_blast","fight_aura","fight_vacuum","fight_mach":
						q=combat_path_sample(points,progress)+Vector3(0,.12,0);size=.85 if fight_role=="fight_blast" else .52
					"fight_uppercut":
						q=points[-1]+Vector3(cos(angle)*.18,sin(t*PI)*.9,sin(angle)*.18);size=.55
					"fight_jumpkick","fight_highkick","fight_toss":
						q=combat_path_sample(points,progress)+Vector3(0,sin(progress*PI)*(.95 if fight_role=="fight_highkick" else .55),0);size=.60
					"fight_lowkick":
						q=points[-1]+Vector3(cos(angle)*.28,-.22,sin(angle)*.28);size=.48
					"fight_hammer":
						q=points[-1]+Vector3(0,.95*(1.0-progress),0);size=.72
					"fight_drain":
						q=combat_path_sample(points,1.0-clampf((t-.35)*1.7-f*.2,0,1))+Vector3(cos(angle)*.14,.15,sin(angle)*.14);size=.42
					"fight_bulk","fight_detect","fight_counter","fight_revenge","fight_vital":
						q=points[0]+Vector3(cos(angle+t*TAU)*.38,.15+f*.6,sin(angle+t*TAU)*.38);size=.55
					"fight_submission","fight_roundkick":
						q=points[-1]+Vector3(cos(angle+t*TAU)*.38,.15,sin(angle+t*TAU)*.38);size=.58
					_:
						q=points[-1]+Vector3(cos(angle)*.27,sin(angle)*.25,sin(angle)*.27);size=.56
			if str(profile.role).begins_with("air_"):
				var air_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.30)
				match air_role:
					"air_cutter","air_gust","air_blast":
						q=combat_path_sample(points,progress)+Vector3(cos(angle)*.12,.2+sin(angle)*.16,sin(angle)*.12);size=.84 if air_role=="air_blast" else .48
					"air_fly","air_bounce","air_brave":
						q=combat_path_sample(points,progress)+Vector3(0,sin(progress*PI)*(1.35 if air_role=="air_fly" else .75 if air_role=="air_bounce" else .48),0);size=.68
					"air_sky":
						q=points[-1]+Vector3(cos(angle)*.18,2.0*(1.0-progress),sin(angle)*.18);size=.78
					"air_tailwind","air_roost","air_mirror":
						q=points[0]+Vector3(cos(angle+t*TAU)*.42,.1+f*.58,sin(angle+t*TAU)*.42);size=.50
					"air_defog","air_chatter":
						q=tiles[j%tiles.size()]+Vector3(cos(angle)*t*.43,.25+f*.35,sin(angle)*t*.43);size=.46
					"air_feather":
						q=points[-1]+Vector3(cos(angle+t*TAU)*.4,1.1*(1.0-progress),sin(angle+t*TAU)*.4);size=.40
					"air_drill":
						q=points[-1]+Vector3(cos(angle+t*TAU*2.0)*.22,.2,sin(angle+t*TAU*2.0)*.22);size=.55
					_:
						q=points[-1]+Vector3(cos(angle)*.25,sin(angle)*.24,sin(angle)*.25);size=.53
			if str(profile.role).begins_with("poison_"):
				var poison_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.30)
				match poison_role:
					"poison_bomb","poison_gunk","poison_sludge","poison_acid","poison_gastro","poison_sting":
						q=combat_path_sample(points,progress)+Vector3(cos(angle)*.10,sin(progress*PI)*(.75 if poison_role=="poison_bomb" else .18),sin(angle)*.10)
						size=.84 if poison_role=="poison_gunk" else .48
					"poison_armor":
						q=points[0]+Vector3(cos(angle+t*TAU)*.38,.12+f*.62,sin(angle+t*TAU)*.38);size=.52
					"poison_spikes":
						q=tiles[j%tiles.size()]+Vector3(cos(angle)*.32,.04+sin(t*PI)*.13,sin(angle)*.32);size=.42
					"poison_smog","poison_gas","poison_powder","poison_toxic":
						q=points[-1]+Vector3(cos(angle+t)*(.18+t*.35),.08+f*.56,sin(angle+t)*(.18+t*.35));size=.43
					_:
						q=points[-1]+Vector3(cos(angle)*.23,.15+sin(angle)*.18,sin(angle)*.23);size=.54
			if str(profile.role).begins_with("bug_"):
				var bug_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.30)
				match bug_role:
					"bug_string","bug_signal","bug_twin","bug_pin","bug_horn":
						q=combat_path_sample(points,progress)+Vector3(cos(angle)*.10,.12+sin(angle)*.12,sin(angle)*.10)
						size=.68 if bug_role=="bug_horn" else .46
					"bug_leech":
						q=combat_path_sample(points,1.0-clampf((t-.35)*1.7-f*.2,0,1))+Vector3(cos(angle)*.14,.15,sin(angle)*.14);size=.42
					"bug_turn":
						q=combat_path_sample(points,1.0-absf(2.0*progress-1.0))+Vector3(0,sin(progress*PI)*.48,0);size=.55
					"bug_glow","bug_heal","bug_defend":
						q=points[0]+Vector3(cos(angle+t*TAU)*.38,.12+f*.6,sin(angle+t*TAU)*.38);size=.45
					"bug_silver","bug_attack","bug_buzz":
						q=tiles[j%tiles.size()]+Vector3(cos(angle+t*TAU)*.33,.2+sin(angle)*.18,sin(angle+t*TAU)*.33);size=.49
					"bug_web":
						q=points[-1]+Vector3(cos(angle)*t*.4,.12+f*.28,sin(angle)*t*.4);size=.58
					_:
						q=points[-1]+Vector3(cos(angle)*.22,.15+sin(angle)*.18,sin(angle)*.22);size=.53
			if str(profile.role).begins_with("psi_"):
				var psi_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.30)
				match psi_role:
					"psi_beam","psi_wave","psi_mist","psi_luster","psi_cut","psi_zen":
						q=combat_path_sample(points,progress)+Vector3(cos(angle)*.10,.15+sin(angle)*.12,sin(angle)*.10);size=.58
					"psi_dream":
						q=combat_path_sample(points,1.0-clampf((t-.35)*1.7-f*.2,0,1))+Vector3(cos(angle)*.13,.18,sin(angle)*.13);size=.42
					"psi_skill","psi_trick","psi_role","psi_guard","psi_shift","psi_heart","psi_power":
						q=combat_path_sample(points,progress if j%2==0 else 1.0-progress)+Vector3(0,sin(progress*PI)*(.50 if j%2==0 else .25),0);size=.46
					"psi_gravity","psi_room","psi_block","psi_agility","psi_wish","psi_lunar":
						q=tiles[j%tiles.size()]+Vector3(cos(angle)*.30,1.4*(1.0-progress) if psi_role=="psi_gravity" else .15+f*.45,sin(angle)*.30);size=.52
					"psi_cosmic","psi_teleport","psi_amnesia","psi_rest","psi_barrier","psi_screen","psi_magic","psi_mirror","psi_future","psi_calm","psi_meditate","psi_reflect","psi_powertrick":
						q=points[0]+Vector3(cos(angle+t*TAU)*.40,.12+f*.65,sin(angle+t*TAU)*.40);size=.50
					_:
						q=points[-1]+Vector3(cos(angle+t*TAU)*.32,.15+f*.42,sin(angle+t*TAU)*.32);size=.52
			if str(profile.role).begins_with("ghost_"):
				var ghost_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.30)
				match ghost_role:
					"ghost_ball","ghost_confuse","ghost_punch","ghost_lick":
						q=combat_path_sample(points,progress)+Vector3(cos(angle)*.11,.14+sin(angle)*.10,sin(angle)*.11);size=.65 if ghost_role=="ghost_ball" else .46
					"ghost_sneak":
						q=combat_path_sample(points,progress)+Vector3(0,-.24+maxf(0.0,progress-.8)*1.6,0);size=.54
					"ghost_force":
						q=points[-1]+Vector3(cos(angle)*.20,1.4*(1.0-progress),sin(angle)*.20);size=.68
					"ghost_grudge":
						q=points[0]+Vector3(cos(angle+t*TAU)*.38,.12+f*.65,sin(angle+t*TAU)*.38);size=.49
					"ghost_bond":
						q=combat_path_sample(points,f)+Vector3(0,.15+sin(t*TAU+f*TAU)*.15,0);size=.40
					"ghost_wind","ghost_shade":
						q=tiles[j%tiles.size()]+Vector3(cos(angle+t*TAU)*.36,.16+f*.48,sin(angle+t*TAU)*.36);size=.52
					_:
						q=points[-1]+Vector3(cos(angle+t*TAU)*.30,.18+f*.42,sin(angle+t*TAU)*.30);size=.51
			if str(profile.role).begins_with("dragon_"):
				var dragon_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.30)
				match dragon_role:
					"dragon_breath","dragon_flame","dragon_pulse","dragon_rush":
						q=combat_path_sample(points,progress)+Vector3(cos(angle)*.12,.18+sin(angle)*.12,sin(angle)*.12);size=.76 if dragon_role=="dragon_rush" else .56
					"dragon_meteor":
						q=tiles[j%tiles.size()]+Vector3(.4*(1.0-progress),2.0*(1.0-progress),-.3*(1.0-progress));size=.65
					"dragon_rend","dragon_time":
						q=tiles[j%tiles.size()]+Vector3(cos(angle)*.30,.2+f*.46,sin(angle)*.30);size=.60
					"dragon_twister":
						q=points[-1]+Vector3(cos(angle+t*TAU*2.0)*.32,.1+f*.85,sin(angle+t*TAU*2.0)*.32);size=.48
					"dragon_dance":
						q=points[0]+Vector3(cos(angle+t*TAU)*.42,.12+f*.62,sin(angle+t*TAU)*.42);size=.46
					_:
						q=points[-1]+Vector3(cos(angle)*.28,.18+sin(angle)*.25,sin(angle)*.28);size=.56
			if str(profile.role).begins_with("dark_"):
				var dark_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.30)
				match dark_role:
					"dark_faint","dark_sucker","dark_fling":
						q=combat_path_sample(points,progress)+Vector3(0,sin(progress*PI)*(.8 if dark_role=="dark_fling" else .2),0);size=.55
					"dark_thief","dark_snatch","dark_knock":
						q=combat_path_sample(points,1.0-progress)+Vector3(cos(angle)*.12,.15+sin(progress*PI)*.45,sin(angle)*.12);size=.44
					"dark_switch":
						q=combat_path_sample(points,progress if j%2==0 else 1.0-progress)+Vector3(0,sin(progress*PI)*(.48 if j%2==0 else .20),0);size=.43
					"dark_pulse","dark_void","dark_memento","dark_beat":
						q=tiles[j%tiles.size()]+Vector3(cos(angle+t*TAU)*.34,.12+f*.5,sin(angle+t*TAU)*.34);size=.55
					"dark_pursuit","dark_payback","dark_plot":
						q=points[0]+Vector3(cos(angle+t*TAU)*.4,.12+f*.65,sin(angle+t*TAU)*.4);size=.47
					"dark_tears":
						q=points[-1]+Vector3(cos(angle)*.22,.8*(1.0-progress),sin(angle)*.22);size=.35
					_:
						q=points[-1]+Vector3(cos(angle+t*TAU)*.26,.16+f*.36,sin(angle+t*TAU)*.26);size=.52
			if str(profile.role).begins_with("steel_"):
				var steel_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.30)
				match steel_role:
					"steel_meteor","steel_bullet","steel_flash","steel_mirror","steel_magnet","steel_gyro","steel_sound":
						q=combat_path_sample(points,progress)+Vector3(cos(angle)*.10,.15+sin(progress*PI)*(.65 if steel_role=="steel_magnet" else .13),sin(angle)*.10);size=.67 if steel_role=="steel_flash" else .49
					"steel_doom","steel_defense","steel_burst":
						q=points[0]+Vector3(cos(angle+t*TAU)*.38,.12+f*.65,sin(angle+t*TAU)*.38);size=.50
					"steel_tail","steel_wing","steel_claw","steel_head":
						q=points[-1]+Vector3(cos(angle+t*TAU)*.28,.16+sin(angle)*.20,sin(angle+t*TAU)*.28);size=.56
			if str(profile.role).begins_with("normal_"):
				var normal_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.30)
				match normal_role:
					"normal_extreme","normal_quick","normal_tackle","normal_takedown","normal_edge","normal_giga","normal_headbutt","normal_skull","normal_feint","normal_horn","normal_drill","normal_furyattack":
						q=combat_path_sample(points,progress)+Vector3(cos(angle)*.10,.16+sin(progress*PI)*.16,sin(angle)*.10);size=.76 if normal_role=="normal_giga" else .53
					"normal_stomp","normal_megakick","normal_slam","normal_body","normal_climb":
						q=points[-1]+Vector3(cos(angle)*.22,1.0*(1.0-progress),sin(angle)*.22);size=.58
					"normal_bide":
						q=points[0]+Vector3(cos(angle+t*TAU)*.40,.12+f*.6,sin(angle+t*TAU)*.40);size=.50
					"normal_cut","normal_thrash":
						q=tiles[j%tiles.size()]+Vector3(cos(angle+t*TAU)*.28,.16+f*.3,sin(angle+t*TAU)*.28);size=.54
					"normal_constrict","normal_bind","normal_wrap","normal_spin":
						q=points[-1]+Vector3(cos(angle+t*TAU)*.38,.12+f*.55,sin(angle+t*TAU)*.38);size=.48
					_:
						q=points[-1]+Vector3(cos(angle+t*TAU)*.26,.16+f*.36,sin(angle+t*TAU)*.26);size=.52
			if str(profile.role).begins_with("neutral_"):
				var neutral_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.30)
				match neutral_role:
					"neutral_self","neutral_explosion","neutral_vacuum","neutral_wide":
						q=tiles[j%tiles.size()]+Vector3(cos(angle+t*TAU)*.35,.15+f*.6,sin(angle+t*TAU)*.35);size=.76 if neutral_role=="neutral_explosion" else .55
					"neutral_egg","neutral_present","neutral_trump","neutral_pay":
						q=combat_path_sample(points,progress)+Vector3(0,sin(progress*PI)*.75,0);size=.50
					"neutral_covet":
						q=combat_path_sample(points,1.0-progress)+Vector3(0,.15+sin(progress*PI)*.4,0);size=.43
					"neutral_wring":
						q=points[-1]+Vector3(cos(angle+t*TAU)*.3,.12+f*.6,sin(angle+t*TAU)*.3);size=.53
					"neutral_snore":
						q=points[0]+Vector3(cos(angle+t*TAU)*.4,.15+f*.5,sin(angle+t*TAU)*.4);size=.43
					_:
						q=combat_path_sample(points,progress)+Vector3(cos(angle)*.11,.14+sin(angle)*.15,sin(angle)*.11);size=.75 if neutral_role=="neutral_beam" else .48
			if str(profile.role).begins_with("support_"):
				var support_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.30)
				match support_role:
					"support_pain","support_psych":
						q=combat_path_sample(points,progress if j%2==0 else 1.0-progress)+Vector3(0,.15+sin(progress*PI)*.45,0);size=.43
					"support_sun","support_moon","support_bell","support_safeguard","support_egg","support_help","support_milk","support_refresh","support_lucky","support_acu":
						q=tiles[j%tiles.size()]+Vector3(cos(angle+t*TAU)*.32,.12+f*.65,sin(angle+t*TAU)*.32);size=.48
					_:
						q=points[0]+Vector3(cos(angle+t*TAU)*.38,.12+f*.6,sin(angle+t*TAU)*.38);size=.46
			if str(profile.role).begins_with("status_"):
				var status_role:String=str(profile.role)
				var progress:float=combat_travel_progress(t,float(profile.impact),f*.30)
				match status_role:
					"status_convert","status_convert2","status_transform","status_camo","status_talk","status_metronome","status_assist","status_nature","status_recycle":
						q=points[0]+Vector3(cos(angle+t*TAU)*.38,.12+f*.65,sin(angle+t*TAU)*.38);size=.47
					"status_lovely","status_scent","status_odor","status_uproar","status_growl","status_dance","status_perish","status_baton":
						q=tiles[j%tiles.size()]+Vector3(cos(angle+t*TAU)*.3,.12+f*.55,sin(angle+t*TAU)*.3);size=.46
					"status_sketch","status_mimic","status_copycat","status_first":
						q=combat_path_sample(points,1.0-progress)+Vector3(0,.15+sin(progress*PI)*.4,0);size=.44
					"status_sing","status_supersonic","status_screech","status_roar","status_whirl":
						q=combat_path_sample(points,progress)+Vector3(cos(angle)*.12,.18+sin(angle)*.14,sin(angle)*.12);size=.48
					"status_splash":
						q=points[0]+Vector3(cos(angle)*.25,.12+absf(sin(t*TAU))*.6,sin(angle)*.25);size=.42
					_:
						q=points[-1]+Vector3(cos(angle+t*TAU)*.28,.15+f*.5,sin(angle+t*TAU)*.28);size=.46
			# Drained energy travels from victim back to caster; healing stays on caster.
			if profile.role=="drain" and t>=.40:
				var back:float=clampf((t-.40)*2.0-f*.22,0.0,1.0)
				q=combat_path_sample(points,1.0-back)+Vector3(cos(angle)*.10,.15+sin(back*PI)*.35,sin(angle)*.10)
				size=.32+f*.18
			elif profile.role=="heal":
				var radius:float=.12+sin(t*PI)*.38
				q=points[0]+Vector3(cos(angle)*radius,.12+t*.65,sin(angle)*radius)
				size=.36
			particle.billboard=BaseMaterial3D.BILLBOARD_ENABLED;particle.rotation=Vector3.ZERO
			particle.position=q
			particle.texture=animated
			particle.scale=Vector3.ONE*size*(1.0-t*.38)*.40
			particle.modulate=Color(1,1,1,clampf((1.0-t)*3.5,0.0,1.0))
			particle.show()
		if crowded and t>=float(profile.impact):
			used=element_finish_fx(burst,t,used)
			used=authored_stage_fx(burst,t,used)
			used=travel_environment_fx(burst,t,used)
		else:
			used=travel_environment_fx(burst,t,used)
			used=authored_stage_fx(burst,t,used)
			used=element_finish_fx(burst,t,used)
	fx_cast_particle_limit=FX_PARTICLE_CAP
	if run!=null and not run.charge_phase.is_empty():used=charge_environment_fx(used)
	if not latest_hit.is_empty() and is_instance_valid(pet):
		queue_ultra_reaction(pet.global_position+Vector3.UP*.54,latest_hit.direction,false)
	used=ultra_reaction_particles(dt,used)
	used=ultra_update_residues(dt,used)
	if fx_trail_started:fx_trail_mesh.surface_end()
	living_status_fx()
	if not latest_hit.is_empty():
		# The player clock advances once after this method, so compensate for that frame.
		hit_time=.24+dt-float(latest_hit.age)
		player_hit_direction=latest_hit.direction
	if arcs_started:fx_arc_mesh.surface_end()
	for j in range(used,mini(FX_PARTICLE_CAP,combat_particles.size())):combat_particles[j].hide()
	for j in range(fx_lights_used,fx_lights.size()):
		if fx_lights[j].visible:fx_lights[j].hide()
	for j in range(fx_halos_used,fx_halos.size()):
		if fx_halos[j].visible:fx_halos[j].hide()
# Secondary environmental layers use the existing bounded pool, not new nodes
# per cast. Ground rings remain aligned to the floor while debris billboards.
func environment_particle(index:int,position:Vector3,mode:String,light:Color,dark:Color,scale_value:float,alpha:float,flat:bool=false,status_layer:bool=false)->int:
	if index>=mini(combat_particles.size(),FX_PARTICLE_CAP+LIVING_PARTICLE_CAP if status_layer else fx_cast_particle_limit):return index
	var particle:Sprite3D=combat_particles[index]
	var billboard_mode:int=BaseMaterial3D.BILLBOARD_DISABLED if flat else BaseMaterial3D.BILLBOARD_ENABLED
	if particle.billboard!=billboard_mode:particle.billboard=billboard_mode
	var orientation:=Vector3(-PI*.5,0,0) if flat else Vector3.ZERO
	if particle.rotation!=orientation:particle.rotation=orientation
	particle.position=position
	var texture:=combat_pixel_texture(mode,light,dark)
	if particle.texture!=texture:particle.texture=texture
	particle.scale=Vector3.ONE*scale_value
	particle.modulate=Color(1,1,1,clampf(alpha,0.0,1.0))
	particle.show()
	return index+1

# Persistent ailments are driven by rule state, never by a cast's remaining lifetime.
# Reversible real-time ailment envelope. Combat pose timing stays authoritative.
func living_body_sample(actor:Node3D,statuses:Array,dt:float,resting:bool)->Dictionary:
	var sleep_target:float=1.0 if resting and ("sleep" in statuses or "nightmare" in statuses) else 0.0
	var sleep:float=move_toward(float(actor.get_meta("living_sleep_blend",0.0)),sleep_target,maxf(dt,0.0)*3.8)
	actor.set_meta("living_sleep_blend",sleep)
	var phase:float=elapsed*2.8+float(actor.get_instance_id()%17)*.13
	var stretch:float=lerpf(1.0,.67+.025*sin(phase),sleep)
	var width:float=lerpf(1.0,1.14,sleep)
	var sway:float=0.0
	var tint:=Color.WHITE
	var weight:float=0.0
	if "freeze" in statuses:
		tint=Color("#9fdaff");weight=.60
		if resting:
			stretch=lerpf(stretch,.95,.6)
			width=1.04
	elif "toxic" in statuses or "poison" in statuses or "bad_poison" in statuses or "badly_poisoned" in statuses:
		var squeeze:float=pow(maxf(0.0,sin(phase*1.85)),3.0)
		tint=Color("#d4a0f7");weight=.25+.21*squeeze
		if resting and sleep<.1:
			stretch=1.0-.16*squeeze;width=1.0+.13*squeeze
			sway=.025*sin(phase*2.0)*squeeze
	elif "burn" in statuses:
		tint=Color("#ffac79");weight=.32+.12*sin(phase*2.0)
		if resting and sleep<.1:sway=.028*sin(phase*3.0)
	elif "paralysis" in statuses:
		tint=Color("#ffea99");weight=.22
		if resting and sleep<.1:
			var shock:float=pow(maxf(0.0,sin(phase*2.5)),6.0)
			sway=.055*sin(phase*15.0)*shock
			stretch=1.0+.10*shock
	elif "confusion" in statuses and resting and sleep<.1:
		sway=.07*sin(phase*1.5)
	if "nightmare" in statuses:
		tint=Color("#a28ac8");weight=.48
		if resting:sway+=.035*sin(phase*5.0)
	# Fade the body and color independently from the discrete turn status.
	# A cure must not snap a compressed or tinted creature back to neutral.
	var blend:float=1.0-exp(-maxf(dt,0.0)*18.0)
	var old:Dictionary=actor.get_meta("living_body_envelope",{"stretch":1.0,"width":1.0,"sway":0.0,"color":Color.WHITE})
	var target_color:Color=Color.WHITE.lerp(tint,weight)
	var smooth_stretch:float=lerpf(float(old.stretch),stretch,blend)
	var smooth_width:float=lerpf(float(old.width),width,blend)
	var smooth_sway:float=lerpf(float(old.sway),sway,blend)
	var smooth_color:Color=Color(old.color).lerp(target_color,blend)
	var active:bool=not statuses.is_empty() or sleep>.001 or absf(smooth_stretch-1.0)>.001 or absf(smooth_width-1.0)>.001 or absf(smooth_sway)>.001 or not smooth_color.is_equal_approx(Color.WHITE)
	if statuses.is_empty() and sleep<=.001 and absf(smooth_stretch-1.0)<.001 and absf(smooth_width-1.0)<.001 and absf(smooth_sway)<.001 and absf(smooth_color.r-1.0)<.002 and absf(smooth_color.g-1.0)<.002 and absf(smooth_color.b-1.0)<.002:
		smooth_stretch=1.0;smooth_width=1.0;smooth_sway=0.0;smooth_color=Color.WHITE;active=false
	actor.set_meta("living_body_envelope",{"stretch":smooth_stretch,"width":smooth_width,"sway":smooth_sway,"color":smooth_color})
	var color_weight:float=maxf(1.0-smooth_color.r,maxf(1.0-smooth_color.g,1.0-smooth_color.b))
	# Preserve the existing tint/weight API: reconstruct the equivalent color.
	var normalized_tint:Color=Color.WHITE if color_weight<.00001 else Color.WHITE.lerp(smooth_color,1.0/color_weight)
	return {"sleep":sleep,"stretch":smooth_stretch,"width":smooth_width,"sway":smooth_sway,"tint":normalized_tint,"tint_weight":color_weight,"active":active}

func living_enemy_statuses(e:Dictionary)->Array:
	var result:Array=[]
	if int(e.get("sleep_turns",0))>0:result.append("sleep")
	var major:String=str(e.get("major_status",""))
	if not major.is_empty():result.append(major)
	for key in ["nightmare","yawn","confusion","wrapped","stuck","leech","curse","paused","perish","heal_block","infatuated","destiny","encore","taunt","embargo","decoy","whiffer","slow","haste","ability_suppressed"]:
		if int(e.get(key+"_turns",0))>0:result.append(key)
	return result

func living_player_statuses()->Array:
	var result:Array=[]
	if run.boon_active("nap") or run.boon_active("hostile_sleep"):result.append("sleep")
	if run.poison_turns>0:result.append("poison")
	if run.self_confusion_turns>0:result.append("confusion")
	if run.player_slow_turns>0:result.append("slow")
	for key in ["hostile_drowse","wrapping","ingrain","rage","wish","aqua","mist","magnet","mirror_veil","magic_coat","ability_suppressed","embargo","decoy","focus","sleepless","lucky","sure","bide","grudge","snatch","vital_throw"]:
		if run.boon_active(key):result.append(key)
	return result

# Three individually phased Z glyphs rise, sway, grow and dissolve.
# Labels are allocated only when a creature first falls asleep and reused thereafter.
func living_sleep_glyphs(actor:Node3D,sleeping:bool,height:float)->void:
	if not is_instance_valid(actor):return
	var layer:=actor.get_node_or_null("LivingSleepGlyphs") as Node3D
	if not sleeping:
		if layer!=null:layer.hide()
		return
	if layer==null:
		layer=Node3D.new()
		layer.name="LivingSleepGlyphs"
		actor.add_child(layer)
		for i in range(3):
			var glyph:=Label3D.new()
			glyph.text="Z"
			glyph.billboard=BaseMaterial3D.BILLBOARD_ENABLED
			glyph.font_size=36
			glyph.outline_size=5
			glyph.pixel_size=.005
			glyph.outline_modulate=Color("#28274c")
			layer.add_child(glyph)
	layer.show()
	for i in range(3):
		var glyph:=layer.get_child(i) as Label3D
		var t:float=fposmod(elapsed*.72+float(i)/3.0,1.0)
		glyph.position=Vector3(.12+sin(t*TAU)*.12,height+t*.48,0)
		glyph.scale=Vector3.ONE*(.55+t*.7)
		glyph.modulate=Color(.68,.86,1.0,sin(t*PI))

var living_palette_cache:Dictionary={}
func living_status_palette(kind:String)->Array:
	if not living_palette_cache.has(kind):living_palette_cache[kind]=build_living_status_palette(kind)
	return living_palette_cache[kind]

func build_living_status_palette(kind:String)->Array:
	match kind:
		"poison","badly_poisoned","toxic","bad_poison":return ["bubble","#c59bf7","#6838a9",8]
		"burn":return ["flame","#ffd489","#bd492d",7]
		"freeze":return ["shards","#e8faff","#65b8ec",7]
		"paralysis","paralyze","paralyzed":return ["slash","#fff1a3","#cb8c28",6]
		"confusion":return ["impact_star","#ffeaa5","#ad69da",5]
		"sleep","yawn","hostile_drowse":return ["cloud","#c8dfff","#7a83c7",4]
		"nightmare","curse","perish","grudge":return ["cloud","#c5a1ef","#51396c",6]
		"wrapped","wrapping","stuck","leech","ingrain":return ["whip","#b6e6a0","#477846",6]
		"infatuated":return ["bubble","#ffc4e5","#d761a7",5]
		"slow","paused":return ["wave","#aed5fc","#5379ad",5]
		"haste","focus","sure","rage":return ["slash","#ffe2a1","#cc8249",6]
		"aqua","mist","mirror_veil","magic_coat","magnet":return ["wave","#b3fff6","#4ca6d0",6]
		_:return ["impact_star","#d9c6fa","#766b9e",4]

func living_actor_particles(actor:Node3D,statuses:Array,used:int,height:float,budget:int)->int:
	var sleep_blend:float=float(actor.get_meta("living_sleep_blend",0.0))
	living_sleep_glyphs(actor,"sleep" in statuses or "nightmare" in statuses,height*(1.0-.22*sleep_blend))
	if statuses.is_empty() or budget<=0:return used
	var limit:int=mini(used+budget,combat_particles.size())
	var origin:Vector3=actor.global_position
	var status_count:int=mini(statuses.size(),3)
	for k in range(status_count):
		var kind:String=str(statuses[k])
		var style:Array=living_status_palette(kind)
		var light:=Color(str(style[1]))
		var dark:=Color(str(style[2]))
		# Reserve a share for each simultaneous ailment, not just the first.
		var count:int=mini(int(style[3]),ceili(float(limit-used)/float(status_count-k)))
		for i in range(count):
			if used>=limit:return used
			var f:float=fposmod(elapsed*(.7 if kind=="sleep" else 1.15)+float(i)/float(count)+k*.19,1.0)
			var angle:float=float(i)*TAU/float(count)+elapsed*(2.4 if kind=="confusion" else .8)
			var radius:float=.24+.16*sin(f*PI)
			var y:float=.12+f*height*.8
			var size:float=.20+.14*sin(f*PI)
			var flat:bool=false
			match kind:
				"poison","badly_poisoned","toxic","bad_poison":
					radius=.20+f*.32
					y=.08+sin(f*PI)*height*.48
					size=.18+.15*sin(f*PI)
					# At the end of the drop arc, leave a ground-level venom splash.
					flat=f>.78
					if flat:y=.035
				"freeze":
					# Stable facets form a visible ice cage rather than orbiting confetti.
					angle=float(i)*TAU/float(count)
					y=.12+float(i%3)*height*.27
					radius=.38
					size=.37+.08*float(i%3)
				"confusion":
					y=height+.06+.07*sin(angle*2.0)
					radius=.36
				"sleep":
					y=height*.45+f*.36
					radius=.27+f*.16
				"wrapped","wrapping","stuck","leech","ingrain":
					y=.10+float(i%3)*.18
					radius=.34
				"burn":
					y=.08+f*height*.95
					radius=.24+.13*sin(f*PI)
			var q:=origin+Vector3(cos(angle)*radius,y,sin(angle)*radius)
			var texture_mode:String=str(style[0])
			if kind in ["poison","toxic","bad_poison","badly_poisoned"]:texture_mode="venom_splash" if flat else "drop" if i%2==0 else "bubble"
			if kind=="freeze":texture_mode="crystal"
			if kind=="burn" and i%3==0:texture_mode="smoke"
			var opacity:float=.70+.16*sin(f*TAU) if kind=="freeze" else sin(f*PI)*.9
			used=environment_particle(used,q,texture_mode,light,dark,size,opacity,flat,true)
	return used

# Bounded max-min allocation: each affected creature gets a share before
# any creature gets its next particle. Unused demand is redistributed.
func living_particle_budgets(demands:Array[int],capacity:int)->Array[int]:
	var budgets:Array[int]=[]
	budgets.resize(demands.size())
	budgets.fill(0)
	var remaining:int=maxi(0,capacity)
	while remaining>0:
		var progressed:bool=false
		for i in range(demands.size()):
			if budgets[i]>=demands[i]:continue
			budgets[i]+=1
			remaining-=1
			progressed=true
			if remaining==0:break
		if not progressed:break
	return budgets

func living_status_fx()->void:
	if run==null:return
	var used:int=FX_PARTICLE_CAP
	var entries:Array[Dictionary]=[]
	if is_instance_valid(pet):
		var player_states:Array=living_player_statuses()
		if not player_states.is_empty():entries.append({"actor":pet,"statuses":player_states,"height":1.08})
		else:living_sleep_glyphs(pet,false,1.08)
	for key in actor_nodes.keys():
		if not str(key).begins_with("enemy:"):continue
		var actor:=actor_nodes[key] as Node3D
		if not is_instance_valid(actor) or actor.is_queued_for_deletion():continue
		var statuses:Array=actor.get_meta("living_statuses",[])
		if not actor.visible or str(actor.get_meta("enemy_phase",""))=="defeat":statuses=[]
		if statuses.is_empty():
			living_sleep_glyphs(actor,false,1.12)
			continue
		entries.append({"actor":actor,"statuses":statuses,"height":1.12*float(actor.get_meta("enemy_size_multiplier",1.0))})
	if entries.is_empty():
		for j in range(used,combat_particles.size()):
			if combat_particles[j].visible:combat_particles[j].hide()
		return
	var demands:Array[int]=[]
	for entry in entries:
		var demand:int=0
		var statuses:Array=entry.statuses
		for k in range(mini(statuses.size(),3)):
			demand+=int(living_status_palette(str(statuses[k]))[3])
		demands.append(demand)
	var budgets:=living_particle_budgets(demands,mini(LIVING_PARTICLE_CAP,maxi(0,combat_particles.size()-used)))
	for i in range(entries.size()):
		var entry:Dictionary=entries[i]
		# Even a zero-budget actor updates its independent sleep glyphs.
		used=living_actor_particles(entry.actor,entry.statuses,used,float(entry.height),budgets[i])
	for j in range(used,combat_particles.size()):
		if combat_particles[j].visible:combat_particles[j].hide()

func travel_environment_fx(burst:Dictionary,t:float,used:int)->int:
	var id:String=str(burst.id)
	var kind:String=tile_cast_kind(id)
	if kind.is_empty():return used
	var peak:float=float(burst.profile.impact)
	var progress:float=clampf(t/peak,0.0,1.0)
	var after:float=clampf((t-peak)/(1.0-peak),0.0,1.0)
	var points:Array=burst.points
	var travel_points:Array=[]
	for point in points:travel_points.append(Vector3(point.x,0.0,point.z))
	var travel:=tile_cast_sample(travel_points,kind,t,peak,bool(burst.get("airborne_start",false)))
	var source:Vector3=points[0];source.y=.035
	var target:Vector3=points[-1];target.y=.035
	var dust_light:=Color("#c8ad78");var dust_dark:=Color("#705338")
	if kind=="burrow":
		# Origin hole, moving trail of displaced soil, then eruption at contact.
		used=environment_particle(used,source,"earth_hole",dust_light,dust_dark,.85,1.0-t,true)
		var ground:Vector3=travel.position;ground.y=.045
		used=environment_particle(used,ground,"earth_hole",dust_light,dust_dark,.65,1.0-after,true)
		for j in range(8):
			var angle:float=float(j)*TAU/8.0
			var spread:float=.10+.56*after
			var q:=ground+Vector3(cos(angle)*spread,.08+sin(PI*maxf(.12,after))*.70,sin(angle)*spread)
			used=environment_particle(used,q,"shards",dust_light,dust_dark,.40,1.0-after)
	elif kind=="air" or kind=="dive":
		var wind_light:=Color("#dff8ff") if kind=="air" else Color("#9ce7f5")
		var wind_dark:=Color("#729db5") if kind=="air" else Color("#326f9e")
		if t<peak:
			for j in range(6):
				var lagged:float=maxf(0.0,t-float(j)*.075*peak)
				var sample:=tile_cast_sample(travel_points,kind,lagged,peak,bool(burst.get("airborne_start",false)))
				var q:Vector3=sample.position
				q.y=maxf(.05,q.y+.18)
				used=environment_particle(used,q,"slash" if kind=="air" else "bubble",wind_light,wind_dark,.60-float(j)*.055,1.0-float(j)*.12)
		else:
			used=environment_particle(used,target,"bubble",wind_light,wind_dark,.5+after*1.6,1.0-after,true)
			for j in range(8):
				var angle:float=float(j)*TAU/8.0
				var q:=target+Vector3(cos(angle)*after*.85,.1+sin(after*PI)*.40,sin(angle)*after*.85)
				used=environment_particle(used,q,"slash",wind_light,wind_dark,.36,1.0-after)
	elif kind=="ground":
		var ground:Vector3=travel.position;ground.y=.06
		for j in range(5):
			var angle:float=float(j)*TAU/5.0
			used=environment_particle(used,ground+Vector3(cos(angle)*.24,.1+sin(t*PI)*.15,sin(angle)*.24),"cloud",dust_light,dust_dark,.34,1.0-after)
	return used

# Complement the unique move frames with restrained, elemental finishing layers.
# No scene-tree allocation during battle. Use actual target positions; effects
# are cosmetic and never create damage or alter hit resolution.
const ELEMENT_FINISH_MODE={"fire":"ember","electric":"lightning","water":"drop","grass":"leaf","ice":"shards","ground":"shards","rock":"shards","poison":"cloud","psychic":"spiral","ghost":"cloud","dark":"slash","fighting":"impact_star","normal":"impact_star","flying":"slash","bug":"leaf","dragon":"flame","steel":"shards","fairy":"impact_star"}
func cast_result_text(row:Dictionary)->String:
	var damage:int=int(row.get("damage",0))
	var healed:int=int(row.get("heal",0))
	if healed>0 and damage==0:return "+%d HP"%healed
	if damage>0:
		var prefix:String="CRITICAL " if int(row.get("crit",0))>0 else ""
		var suffix:String=" · x%d"%int(row.hits) if int(row.get("hits",0))>1 else ""
		if int(row.get("misses",0))>0:suffix+=" · %d miss"%int(row.misses)
		if not str(row.get("status","")).is_empty():suffix+="\n"+str(row.status)
		return prefix+"−%d HP"%damage+suffix
	if int(row.get("effects",0))>0:return str(row.get("status","EFFECT"))
	if int(row.get("blocked",0))>0:return "NO EFFECT"
	return "MISS"

func show_cast_results(results:Dictionary)->void:
	for tile in results:
		if cast_text_pool.is_empty():return
		var row:Dictionary=results[tile]
		var i:int=cast_text_cursor%cast_text_pool.size();cast_text_cursor+=1
		var tag:Label3D=cast_text_pool[i]
		var damage:int=int(row.get("damage",0))
		tag.text=cast_result_text(row)
		tag.modulate=Color("#ffd473") if int(row.get("crit",0))>0 else Color("#fff2dc") if damage>0 else Color("#78e7a3") if int(row.get("heal",0))>0 else Color("#a6eacb") if int(row.get("effects",0))>0 else Color("#c3cad7")
		tag.font_size=46 if int(row.get("crit",0))>0 else 34
		cast_text_origin[i]=pos(tile)+Vector3(0,1.85,0);tag.position=cast_text_origin[i];cast_text_age[i]=.8;tag.show()

func update_cast_text(dt:float)->void:
	for i in range(cast_text_pool.size()):
		if cast_text_age[i]<=0.0:continue
		cast_text_age[i]=maxf(0.0,cast_text_age[i]-dt)
		var tag:Label3D=cast_text_pool[i]
		var phase:float=1.0-cast_text_age[i]/.8
		tag.position=cast_text_origin[i]+Vector3(0,phase*.65,0)
		tag.modulate.a=clampf(cast_text_age[i]*4.0,0.0,1.0)
		if cast_text_age[i]<=0.0:tag.hide()
	for i in range(response_text_queue.size()-1,-1,-1):
		var pending:Dictionary=response_text_queue[i]
		pending.delay-=dt
		if float(pending.delay)<=0.0:
			show_cast_results({pending.tile:pending.row})
			response_text_queue.remove_at(i)

func schedule_response_text(tile:Vector2i,event:Dictionary,delay:float)->void:
	var amount:int=int(event.get("amount",0))
	if amount<=0:return
	var source:String=str(event.get("source",""))
	var names:Dictionary={"counter":"COUNTER","fate_link":"FATE LINK","trap":"TRAP","weather":"WEATHER","poison":"POISON","toxic":"TOXIC","burn":"BURN","wrap":"BIND","curse":"CURSE","leech":"DRAIN","nightmare":"NIGHTMARE","ally":"ALLY","sleep_counter":"SLEEP COUNTER","boon":"REBOUND"}
	var caption:String=str(names.get(source,""))
	var row:Dictionary={"damage":amount,"hits":1,"crit":0,"status":caption}
	if response_text_queue.size()>=RESPONSE_TEXT_CAP:response_text_queue.pop_front()
	response_text_queue.append({"tile":tile,"delay":maxf(0.0,delay),"row":row})

# Explicit projectile shapes; locomotion attacks intentionally stay excluded.
const PROJECTILE_IDENTITY={"eos_031":"orb","eos_127":"orb","eos_193":"orb","eos_443":"orb","eos_454":"orb","eos_508":"orb","eos_309":"orb","lib_normal_3":"beam","lib_ice_2":"beam","lib_psychic_1":"beam","eos_042":"beam","eos_107":"beam","eos_114":"beam","eos_239":"beam","eos_242":"beam","eos_345":"beam","eos_353":"beam","eos_489":"beam","eos_536":"beam","eos_152":"beam","alt_coralcrab":"beam","lib_fire_2":"stream","lib_dragon_2":"stream","eos_053":"stream","eos_157":"stream","eos_240":"stream","eos_342":"stream","alt_fungal_monarch":"stream","alt_leviathorn":"stream","lib_water_1":"bubble","lib_water_2":"bubble","eos_016":"bubble","eos_255":"bubble","bubble_burst":"bubble","lib_ice_1":"needle","lib_flying_1":"needle","lib_steel_2":"needle","eos_462":"needle","eos_163":"needle","eos_164":"needle","eos_201":"needle","eos_306":"needle","alt_rootgnawer":"needle","alt_hollow_stag":"needle","alt_reef_pup":"needle","alt_crystarok":"needle","alt_voidspider":"needle","feather_fan":"needle","eos_166":"bomb","eos_280":"bomb","eos_485":"bomb","eos_486":"bomb","eos_501":"bomb","eos_523":"bomb","eos_453":"bomb","eos_044":"bomb","lib_psychic_2":"pulse","lib_dark_3":"pulse","eos_189":"pulse","eos_310":"pulse","eos_436":"pulse","eos_539":"pulse","eos_479":"pulse","eos_108":"pulse","jelly_pulse":"pulse","lib_fire_1":"dart","lib_grass_2":"dart","lib_ground_3":"dart","lib_rock_1":"dart","lib_fairy_1":"dart","eos_299":"dart","eos_251":"dart","eos_290":"dart","eos_527":"dart","leaf_dart":"dart","alt_starlit_pup":"dart","nova_bolt":"dart"}

# Material-specific silhouettes use the authored role, not a random ID hash.
const PROJECTILE_ROLE_FORM={"neutral_weather":"weather_orb","ghost_ball":"spectral_orb","electric_orb":"charged_orb","grass_energy":"seed_orb","fight_blast":"force_orb","fight_aura":"aura_orb","psi_mist":"mist_orb","ice_aurora":"aurora_beam","ice_beam":"frost_beam","psi_beam":"prism_beam","bug_signal":"signal_beam","water_cannon":"water_jet","water_pump":"water_jet","air_blast":"wind_blade","electric_beam":"arc_beam","steel_flash":"metal_beam","neutral_sonic":"sonic_ring","fire_breath":"flame_stream","fire_blast":"flame_burst","dragon_breath":"dragon_stream","water_bubblebeam":"bubble_train","ice_shard":"ice_needle","air_cutter":"wind_blade","steel_bullet":"metal_needle","grass_bullet":"seed_train","bug_twin":"twin_needle","bug_pin":"thorn_needle","neutral_spike":"thorn_needle","neutral_egg":"egg_bomb","poison_bomb":"venom_bomb","poison_gunk":"venom_blob","grass_bomb":"seed_bomb","earth_bomb":"earth_bomb","steel_magnet":"magnet_orb","rock_wrecker":"rock_bomb","water_ink":"ink_blob","psi_wave":"prism_pulse","dark_pulse":"shadow_pulse","electric_wave":"charged_pulse","water_pulse":"water_pulse","dragon_pulse":"dragon_pulse","fight_vacuum":"vacuum_pulse","fire_ember":"ember_dart","grass_razor":"leaf_blade","earth_shot":"mud_dart","rock_throw":"rock_dart","fairy_glimmer":"star_dart","earth_return":"mud_dart","steel_mirror":"metal_dart"}
func directed_projectile_form(id:String,role:String)->String:
	return str(PROJECTILE_ROLE_FORM.get(role,PROJECTILE_IDENTITY.get(id,"")))

# X: longitudinal head scale, Y: spacing, Z: maximum trail samples.
func projectile_form_profile(kind:String)->Vector3:
	match kind:
		"beam","aurora_beam","frost_beam","prism_beam","signal_beam","arc_beam","metal_beam":return Vector3(.65,.065,5)
		"stream","flame_stream","dragon_stream","water_jet":return Vector3(.58,.10,4)
		"bubble_train","seed_train","twin_needle":return Vector3(.43,.17,4)
		"bomb","egg_bomb","venom_bomb","venom_blob","seed_bomb","earth_bomb","rock_bomb","ink_blob":return Vector3(.71,.20,2)
		"needle","ice_needle","metal_needle","thorn_needle","wind_blade","leaf_blade":return Vector3(.48,.13,3)
		"pulse","prism_pulse","shadow_pulse","charged_pulse","water_pulse","dragon_pulse","vacuum_pulse","sonic_ring":return Vector3(.67,.15,3)
		_:return Vector3(.53,.17,3)

func projectile_identity_sample(kind:String,points:Array,progress:float,trail:float)->Vector3:
	var p:float=clampf(progress-trail,0.0,1.0)
	var q:Vector3=combat_path_sample(points,p)
	var arc:float=sin(p*PI)
	if kind in ["bomb","egg_bomb","venom_bomb","venom_blob","seed_bomb","earth_bomb","rock_bomb","ink_blob"]:q.y+=arc*(.75 if kind in ["egg_bomb","rock_bomb"] else .55)
	elif kind in ["bubble","bubble_train"]:q.y+=arc*.13
	elif kind in ["seed_train","mud_dart","rock_dart"]:q.y+=arc*.19
	elif kind in ["ghost_ball","spectral_orb","mist_orb"]:q.y+=arc*sin(p*TAU)*.15
	return q

func projectile_identity_fx(burst:Dictionary,t:float,used:int)->int:
	var id:String=str(burst.id)
	if not PROJECTILE_IDENTITY.has(id):return used
	var peak:float=clampf(float(burst.profile.impact),.01,.99)
	if t>=peak:return used
	var points:Array=burst.points
	if points.size()<2 or Vector3(points[0]).distance_squared_to(points[-1])<.001:return used
	var kind:=directed_projectile_form(id,str(burst.profile.role))
	var progress:float=clampf(t/peak,0.0,1.0)
	var style:Array=combat_style(id)
	var light:=Color(style[1]);var dark:=Color(style[2])
	var shape:=projectile_form_profile(kind)
	var count:int=int(shape.z)
	if fx_performance_tier==2:count=mini(count,3)
	var head_mode:String="projectile_"+kind
	for i in range(count):
		if used>=fx_cast_particle_limit:break
		var lag:float=float(i)*shape.y
		if progress<lag:continue
		var q:=projectile_identity_sample(kind,points,progress,lag)
		var scale_value:float=shape.x*(1.0-float(i)*.13)
		var opacity:float=minf(1.0,progress*14.0)*(1.0-float(i)*.16)
		used=environment_particle(used,q,head_mode,light,dark,scale_value,opacity)
	# World-space trail follows the same path and ends at the confirmed contact clock.
	if kind in ["beam","aurora_beam","frost_beam","prism_beam","signal_beam","arc_beam","metal_beam","flame_stream","dragon_stream","water_jet"] and fx_performance_tier<2:
		var previous:=projectile_identity_sample(kind,points,progress,minf(progress,.28))
		for j in range(1,7):
			var f:float=float(j)/6.0
			var q:=projectile_identity_sample(kind,points,progress,minf(progress,.28)*(1.0-f))
			var width:float=.035+.045*f
			ultra_trail_segment(previous,q,width,width,Color(dark,f*.32),Color(light,f*.62))
			previous=q
	return used

# Explicit detonation direction by authored move role, with elemental fallback.
const IMPACT_ELEMENT_FORM={"fire":"combustion","water":"splash","ice":"shatter","electric":"discharge","grass":"bloom","ground":"eruption","rock":"fracture","poison":"splatter","fighting":"force","flying":"shear","psychic":"implosion","ghost":"wisp","dark":"implosion","dragon":"combustion","steel":"fracture","normal":"force","bug":"bloom","fairy":"radiance"}
const IMPACT_ROLE_FORM={"neutral_explosion":"detonation","fire_blast":"combustion","fire_blastburn":"detonation","fire_overheat":"flare","fire_eruption":"eruption","fire_vortex":"vortex","water_surf":"surge","water_cannon":"splash","water_pump":"surge","water_bubblebeam":"bubble_pop","water_bubble":"bubble_pop","water_pulse":"ripple","ice_blizzard":"shatter","ice_avalanche":"fracture","ice_beam":"frost","earth_fissure":"eruption","earth_quake":"shockwave","earth_bomb":"fracture","rock_blast":"fracture","rock_wrecker":"detonation","rock_smash":"fracture","rock_storm":"fracture","fight_blast":"force","air_blast":"shear","poison_bomb":"splatter","poison_gunk":"splatter","grass_bomb":"bloom","grass_storm":"vortex","ghost_ball":"wisp","dark_void":"implosion","dark_pulse":"ripple","dragon_meteor":"detonation","dragon_pulse":"ripple","steel_meteor":"fracture","steel_burst":"discharge","electric_burst":"discharge","electric_beam":"discharge","psi_beam":"radiance","neutral_beam":"force"}
func directed_impact_form(profile:Dictionary)->String:
	return str(IMPACT_ROLE_FORM.get(str(profile.role),IMPACT_ELEMENT_FORM.get(str(profile.element),"force")))

# X is radius, Y is vertical rise, Z is opacity. Every envelope ends at zero
# opacity. Contraction, expansion and ballistic debris use different curves.
func directed_impact_sample(form:String,progress:float)->Vector3:
	var t:float=clampf(progress,0.0,1.0)
	var radius:float=.12+.78*(1.0-pow(1.0-t,2.0))
	var height:float=sin(t*PI)*.38
	var fade:float=pow(1.0-t,1.35)
	match form:
		"implosion":radius=.92*(1.0-smoothstep(0.0,1.0,t))+.04;height=.15*sin(t*PI)
		"combustion","flare","wisp":height=.10+t*.75;radius=.18+t*.42
		"detonation":radius=.15+1.0*(1.0-pow(1.0-t,3.0));height=sin(t*PI)*.60
		"eruption","fracture","shatter":height=sin(t*PI)*.82
		"splash","surge","splatter":height=sin(t*PI)*.60
		"shockwave","ripple":radius=.18+t*1.10;height=0.0
		"discharge":fade*=.68+.32*cos(t*TAU*3.0);height=.24*sin(t*PI)
		"frost":radius=.18+smoothstep(0.0,.65,t)*.63;height=.12
		"bubble_pop":radius=.08+t*.60;height=.15+sin(t*PI)*.32
		"shear":radius=.12+t*.95;height=.15*sin(t*PI)
		"radiance","bloom","vortex":height=sin(t*PI)*.48
	return Vector3(radius,height,fade)

# Multi-hit presentation must not leak damage from a future attempt.
func impact_visual_view(burst:Dictionary)->Dictionary:
	var waves:Array=burst.get("impact_waves",[])
	if waves.size()<2:return burst
	var index:int=int(burst.get("impact_cursor",0))-1
	var active:Dictionary={}
	if index>=0 and index<waves.size():active=waves[index]
	return {"points":burst.points,"results":active,"damage":0}

func impact_visual_phase(burst:Dictionary,t:float)->float:
	if burst.get("impact_waves",[]).size()<2:
		var peak:float=float(burst.profile.impact)
		return clampf((t-peak)/maxf(.01,1.0-peak),0.0,1.0)
	var wave:=contact_wave_sample(burst)
	return 1.0 if wave.is_empty() else float(wave.age)

# Critical accents use only the current confirmed attempt. A later critical
# cannot tint an earlier hit, and a status or blocked row cannot emit a flash.
func critical_impact_tiles(burst:Dictionary)->Array[Vector2i]:
	var targets:Array[Vector2i]=[]
	var wave:=contact_wave_sample(burst)
	if wave.is_empty():return targets
	var results:Dictionary=wave.results
	for tile in results:
		var row:Dictionary=results[tile]
		if int(row.get("damage",0))>0 and int(row.get("crit",0))>0:
			targets.append(tile)
			if targets.size()>=4:break
	return targets

# x = local flash intensity, y = expanding ring, z = outward streak distance.
func critical_finish_sample(phase:float)->Vector3:
	var t:float=clampf(phase,0.0,1.0)
	var fade:float=1.0-smoothstep(.08,1.0,t)
	return Vector3(fade*fade,.42+1.04*smoothstep(0.0,1.0,t),.18+.66*smoothstep(0.0,1.0,t))

func critical_contact_fx(burst:Dictionary,used:int)->int:
	var tiles:=critical_impact_tiles(burst)
	if tiles.is_empty():return used
	var wave:=contact_wave_sample(burst)
	var phase:float=float(wave.age)
	var sample:=critical_finish_sample(phase)
	if sample.x<.025:return used
	var profile:Dictionary=burst.profile
	var style:Array=combat_style(str(burst.id))
	var light:=Color(style[1]).lerp(Color("#fff3c2"),.65)
	var dark:=Color(style[2]).lerp(Color("#e0a34c"),.35)
	# Preserve the elemental center; use a restrained bright rim only on crits.
	for tile in tiles:
		var center:=pos(tile)+Vector3.UP*.64
		used=environment_particle(used,center,"critical_flash",light,dark,.35+.35*sample.x,sample.x)
		if fx_performance_tier<2 and used<fx_cast_particle_limit:
			used=environment_particle(used,Vector3(center.x,.065,center.z),"shock_ring",light,dark,sample.y,sample.x*.65,true)
	# A single target gets two short tapered streaks; crowded casts stay bounded.
	if fx_performance_tier==0 and tiles.size()==1 and used<fx_cast_particle_limit:
		var center:=pos(tiles[0])+Vector3.UP*.64
		var source:Vector3=burst.points[0]
		var forward:=Vector3(center.x-source.x,0,center.z-source.z).normalized()
		if forward.length_squared()<.0001:forward=Vector3.FORWARD
		var side:=Vector3(-forward.z,0,forward.x)
		for sign_value in [-1.0,1.0]:
			var direction:Vector3=(side*sign_value+Vector3.UP*.65+forward*.25).normalized()
			ultra_trail_segment(center+direction*sample.z*.42,center+direction*sample.z,.022*sample.x,.004,Color(light,sample.x*.80),Color(dark,0.0))
	return used

func directed_impact_fx(burst:Dictionary,t:float,used:int)->int:
	var profile:Dictionary=burst.profile
	var id:String=str(burst.id)
	var record:Dictionary=Rules.MOVE_LIBRARY.get(id,Rules.DEV_NATIVE_MOVES.get(id,{}))
	if str(record.get("category",""))=="status" or t<float(profile.impact):return used
	var phase:float=impact_visual_phase(burst,t)
	if phase>=1.0:return used
	var view:=impact_visual_view(burst)
	var results:Dictionary=view.get("results",{})
	var targets:Array[Vector3]=[]
	for tile in results:
		if int(results[tile].get("damage",0))>0:targets.append(pos(tile)+Vector3.UP*.60)
	if targets.is_empty() and results.is_empty() and int(view.get("damage",0))>0:targets.append(burst.points[-1])
	if targets.is_empty():return used
	var form:=directed_impact_form(profile)
	var sample:=directed_impact_sample(form,phase)
	var style:Array=combat_style(id)
	var light:=Color(style[1]);var dark:=Color(style[2])
	var material:String=str(ELEMENT_FINISH_MODE.get(str(profile.element),"impact_star"))
	var source:Vector3=burst.points[0]
	var limit:int=mini(targets.size(),4)
	# Give each confirmed target a readable center before adding debris.
	for i in range(limit):
		used=environment_particle(used,targets[i],"impact_"+form,light,dark,.62+sample.x*.65,sample.z)
	if fx_performance_tier==2:return used
	for i in range(limit):
		var target:Vector3=targets[i]
		var forward:=Vector3(target.x-source.x,0,target.z-source.z).normalized()
		if forward.length_squared()<.0001:forward=Vector3.FORWARD
		var side:=Vector3(-forward.z,0,forward.x)
		var count:int=3 if limit==1 and fx_performance_tier==0 else 1
		for j in range(count):
			var angle:float=float(j)*TAU/float(count)+phase*2.0
			var radial:Vector3=forward*cos(angle)+side*sin(angle)
			if form in ["force","shear","surge"]:radial=forward*.7+side*sin(angle)*.6
			elif form=="vortex":radial=radial.rotated(Vector3.UP,phase*TAU)
			var q:Vector3=target+radial*sample.x+Vector3.UP*sample.y
			var flat:bool=form in ["ripple","shockwave"]
			if flat:q.y=.06
			used=environment_particle(used,q,material,light,dark,.24+.13*sample.z,sample.z*.76,flat)
	return used

# Pick the most recent dispatched wave, never aggregate damage from later hits.
func contact_wave_sample(burst:Dictionary)->Dictionary:
	var waves:Array=burst.get("impact_waves",[])
	var times:Array=burst.get("impact_times",[])
	var index:int=int(burst.get("impact_cursor",0))-1
	if index<0 or index>=waves.size() or index>=times.size():return {}
	var gap:float=maxf(.01,float(burst.duration)-float(times[index]))
	if index+1<times.size():gap=maxf(.01,float(times[index+1])-float(times[index]))
	var life:float=minf(.18,gap)
	var age:float=(float(burst.age)-float(times[index]))/life
	if age<0.0 or age>=1.0:return {}
	return {"results":waves[index],"age":age,"index":index}

func confirmed_contact_icons(burst:Dictionary,_t:float,used:int)->int:
	var id:String=str(burst.id)
	var kind:=directed_contact_kind(id,str(burst.profile.role))
	if kind.is_empty():return used
	var wave:=contact_wave_sample(burst)
	if wave.is_empty():return used
	var age:float=float(wave.age)
	var style:Array=combat_style(id)
	var stage:int=0 if age<.18 else 1 if age<.62 else 2
	var results:Dictionary=wave.results
	var shown:int=0
	for tile in results:
		var row:Dictionary=results[tile]
		if int(row.get("damage",0))<=0:continue
		var height:float=.63
		if kind=="kick_low":height=.32
		elif kind in ["kick_high","fist_upper"]:height=.88
		elif kind in ["kick_double","kick_triple"]:height=.43+float(int(wave.index)%3)*.19
		var q:Vector3=pos(tile)+Vector3(0,height,0)
		var extent:float=(1.22 if kind in ["crunch","kick_heavy","fist_heavy"] else .86)*(1.0+.12*sin(age*PI))
		used=environment_particle(used,q,"contact:"+kind+":"+str(stage),Color(style[1]),Color(style[2]),extent/3.0,1.0-age)
		shown+=1
		if shown>=4 or used>=fx_cast_particle_limit:break
	return used

# Presentation uses actual move mechanics, independent of translated names.
func status_finish_kind(move:Dictionary)->String:
	if str(move.get("category",""))!="status":return ""
	var special:String=str(move.get("special_rule",""))
	var boon:String=str(move.get("boon_kind",""))
	var ailment:String=str(move.get("inflict_status",""))
	if move.has("heal_fraction") or move.has("heal_fixed") or move.has("weather_heal") or special in ["party_heal","party_renew","pain_split"]:return "heal"
	if move.has("shield_kind") or boon in ["mist","aqua","magic_coat","mirror_veil","magnet"]:return "shield"
	if boon=="cure":return "cleanse"
	if special=="transform_form" or str(move.get("stat_transfer","")) in ["conversion","camouflage"]:return "transform"
	if move.has("weather_set") or move.has("floor_sport"):return "weather"
	if move.has("trap_kind") or special in ["decoy","leader_decoy"]:return "trap"
	if ailment in ["sleep","yawn"] or boon=="nap":return "sleep"
	if ailment=="confusion":return "confusion"
	if ailment in ["poison","toxic"]:return "poison"
	if ailment=="burn":return "burn"
	if ailment=="paralysis":return "paralysis"
	if ailment in ["nightmare","perish","heal_block"] or move.has("curse_action") or special in ["destiny_link","torment","spite","embargo","taunt"]:return "curse"
	if special in ["infatuation","captivate"]:return "heart"
	if ailment in ["stuck","leech","paused"] or special in ["encore","tempo_rift"]:return "bind"
	if move.has("speed_change"):return "boost" if int(move.speed_change)>0 else "weaken"
	var changes:Dictionary=move.get("stat_changes",{})
	var up:bool=false;var down:bool=false
	for key in changes:
		up=up or int(changes[key])>0;down=down or int(changes[key])<0
	if up and down:return "exchange"
	if up:return "boost"
	if down or move.has("stat_halves") or move.has("memento"):return "weaken"
	if move.has("stat_transfer") or move.has("reset_room_stats") or special in ["copy_boost","swap_ability","copy_ability","suppress_ability","swap_item"]:return "exchange"
	if boon in ["focus","lucky","sure","rage","ingrain","wish"] or special in ["party_boost","party_rally","belly_drum"]:return "boost"
	if not ailment.is_empty():return "curse"
	return "ritual"

const STATUS_FINISH_STYLE={
	"heal":["status_plus","#d6ffe3","#43aa76"],
	"cleanse":["status_plus","#e1fff9","#60b8d7"],
	"shield":["status_shield","#bbf3ff","#537bbd"],
	"boost":["status_up","#ffe69d","#d68943"],
	"weaken":["status_down","#c3caff","#685aa8"],
	"exchange":["status_exchange","#ffe4b2","#9578c3"],
	"sleep":["status_sleep","#dce9ff","#7784bf"],
	"confusion":["status_swirl","#ffe9a3","#c081da"],
	"poison":["venom_splash","#d9adff","#8344ac"],
	"burn":["ember","#ffda94","#d45d36"],
	"paralysis":["lightning","#fff4a6","#c69a30"],
	"curse":["status_curse","#e0c5ff","#61407e"],
	"heart":["status_heart","#ffcae6","#d15b99"],
	"bind":["status_bind","#bfe8ad","#567f62"],
	"transform":["status_exchange","#d5f5ff","#9675d5"],
	"weather":["wave","#c3edff","#6c9bbb"],
	"trap":["web","#f2d6a2","#8f715e"],
	"ritual":["status_swirl","#e4d5ff","#7868a8"]
}

func status_finish_fx(kind:String,target:Vector3,age:float,used:int)->int:
	var style:Array=STATUS_FINISH_STYLE[kind]
	var light:=Color(style[1]);var dark:=Color(style[2])
	var fade:float=1.0-age
	var rising:bool=kind in ["heal","cleanse","boost","sleep","heart"]
	var falling:bool=kind in ["weaken","curse"]
	if age<.58:
		used=environment_particle(used,target+Vector3.UP*(.20+age*.36 if rising else .34-age*.24 if falling else .25),str(style[0]),light,dark,.56+sin(age*PI)*.15,fade)
	for i in range(4):
		if used>=fx_cast_particle_limit:break
		var a:float=float(i)*TAU/4.0+age*(3.0 if kind in ["confusion","exchange","transform"] else .7)
		var radius:float=.22+age*.40
		if kind=="shield" or kind=="bind":radius=.42
		var y:float=.12+age*.66 if rising else .65*(1.0-age) if falling else .18+sin(age*PI)*.35
		var q:=Vector3(target.x,.045,target.z)+Vector3(cos(a)*radius,y,sin(a)*radius)
		used=environment_particle(used,q,str(style[0]),light,dark,.28,fade*.82)
	if kind in ["shield","bind","trap","weather","transform","heal","cleanse"]:
		used=environment_particle(used,Vector3(target.x,.045,target.z),"shock_ring",light,dark,.55+age*.85,fade*.62,true)
	return used

# Element-specific terminal choreography reuses the existing particle pool.
# Profiles: material, trajectory, spread, height, fade power, spin.
const ELEMENT_DISSIPATION={
	"normal":["smoke","scatter",.65,.12,1.8,.10],
	"fire":["ember","rise",.40,.65,1.3,.45],
	"water":["drop","fall",.72,.32,1.1,.15],
	"electric":["lightning","static",.54,.20,2.4,.20],
	"grass":["leaf","flutter",.58,.40,1.15,1.6],
	"ice":["crystal","fall",.69,.36,1.55,.40],
	"fighting":["impact_star","scatter",.84,.17,2.1,.05],
	"poison":["cloud","diffuse",.52,.52,.85,.55],
	"ground":["smoke","settle",.75,.25,1.2,.12],
	"flying":["slash","stream",.95,.44,1.75,.7],
	"psychic":["spiral","collapse",.60,.35,1.35,2.4],
	"bug":["web","flutter",.50,.27,1.65,1.2],
	"rock":["shards","settle",.63,.32,1.45,.25],
	"ghost":["cloud","rise",.31,.62,1.05,1.2],
	"dragon":["flame","coil",.64,.57,1.4,2.0],
	"dark":["slash","collapse",.54,.15,1.7,1.4],
	"steel":["shards","fall",.43,.21,2.0,.32],
	"fairy":["impact_star","flutter",.57,.53,1.0,1.8]}
# x: radial reach; y: vertical travel; z: scale; w: opacity.
func elemental_dissipation_sample(element:String,progress:float,index:int=0)->Vector4:
	var cue:Array=ELEMENT_DISSIPATION.get(element,ELEMENT_DISSIPATION.normal)
	var t:float=clampf(progress,0.0,1.0)
	var spread:float=float(cue[2])
	var height:float=float(cue[3])
	var radial:float=.12+spread*smoothstep(0.0,1.0,t)
	var lift:float=height*sin(t*PI)
	var size:float=1.0-.65*t
	var alpha:float=pow(1.0-t,float(cue[4]))
	match str(cue[1]):
		"rise":
			lift=height*t;radial=.12+spread*t*.65
		"fall":
			lift=height*(sin(t*PI)-.75*t);radial=.12+spread*t
		"static":
			radial=.12+spread*t*.65
			alpha*=.65+.35*cos((t*3.0+float(index)*.25)*TAU)
		"flutter":
			lift=height*(sin(t*PI)+.25*sin(t*TAU+float(index)*.8)*sin(t*PI))
			radial*=.88+.12*cos(t*TAU+float(index))
		"diffuse":
			lift=height*t;size=.65+.75*t
		"settle":
			lift=height*sin(t*PI)*pow(1.0-t,.65)
		"stream":
			lift=height*t;radial=.12+spread*t
		"collapse":
			radial=.12+spread*(1.0-t);lift=height*sin(t*PI)*.7
		"coil":
			lift=height*t;radial=.12+spread*sin(t*PI)
	return Vector4(radial,lift,size,alpha)

func elemental_dissipation_offset(element:String,progress:float,index:int,count:int,forward:Vector3=Vector3.FORWARD)->Vector3:
	var cue:Array=ELEMENT_DISSIPATION.get(element,ELEMENT_DISSIPATION.normal)
	var t:float=clampf(progress,0.0,1.0)
	var sample:=elemental_dissipation_sample(element,t,index)
	var angle:float=float(index)*TAU/maxi(1,count)+float(cue[5])*t
	var offset:=Vector3(cos(angle)*sample.x,sample.y,sin(angle)*sample.x)
	if str(cue[1])=="stream":
		var side:=Vector3(-forward.z,0,forward.x)
		offset=forward*sample.x+side*sin(angle)*sample.x*.4+Vector3.UP*sample.y
	return offset

func element_finish_fx(burst:Dictionary,t:float,used:int)->int:
	var id:String=str(burst.id)
	var profile:Dictionary=burst.profile
	var style:Array=combat_style(id)
	var light:=Color(str(style[1]));var dark:=Color(str(style[2]))
	var peak:float=float(profile.impact)
	var points:Array=burst.points
	var from:Vector3=points[0]
	var target:Vector3=points[-1]
	var record:Dictionary=Rules.MOVE_LIBRARY.get(id,Rules.DEV_NATIVE_MOVES.get(id,{}))
	var status:bool=str(record.get("category",""))=="status"
	var mode:String=str(ELEMENT_FINISH_MODE.get(str(profile.element),"impact_star"))
	if t<peak*.48:
		var startup:float=clampf(t/(peak*.48),0.0,1.0)
		for j in range(3):
			var angle:float=float(j)*TAU/3.0+startup*2.0
			var q:=from+Vector3(cos(angle)*(.35-.22*startup),.06+.16*startup,sin(angle)*(.35-.22*startup))
			used=environment_particle(used,q,mode,light,dark,.29, sin(startup*PI)*.80)
	elif t>=peak:
		var age:float=impact_visual_phase(burst,t)
		if age>=1.0:return used
		var fade:float=1.0-age
		var count:int=5 if not status else 3
		var view:=impact_visual_view(burst)
		var results:Dictionary=view.get("results",{})
		var resolved:=resolve_element_impact(view)
		if burst.get("impact_waves",[]).size()>1 and resolved.kind!="confirmed":return used
		target=resolved.target
		var primary_tile:Vector2i=resolved.tile
		if resolved.kind=="miss":
			return environment_particle(used,target,"cloud",light,dark,.32+age*.18,fade*.35)
		if status:
			var kind:=status_finish_kind(record)
			if resolved.kind=="confirmed" or kind in ["weather","trap"]:
				used=status_finish_fx(kind,target,age,used)
				var extra_status:int=0
				for tile in results:
					if tile==primary_tile or extra_status>=3:continue
					var hit:Dictionary=results[tile]
					if int(hit.get("effects",0))+int(hit.get("heal",0))<=0:continue
					used=environment_particle(used,pos(tile)+Vector3.UP*.62,str(STATUS_FINISH_STYLE[kind][0]),Color(STATUS_FINISH_STYLE[kind][1]),Color(STATUS_FINISH_STYLE[kind][2]),.45,fade)
					extra_status+=1
			return used
		# Room-wide attacks show a small localized finish at other confirmed targets.
		var extra:int=0
		for tile in results:
			if tile==primary_tile or extra>=4:continue
			var other:Dictionary=results[tile]
			if int(other.get("damage",0))+int(other.get("effects",0))+int(other.get("heal",0))<=0:continue
			var q:Vector3=pos(tile)+Vector3(0,.45,0)
			used=environment_particle(used,q,"bubble" if status else "impact_star",light,dark,.45+age*.38,fade)
			extra+=1
		var element:String=str(profile.element)
		var dissipate:Array=ELEMENT_DISSIPATION.get(element,ELEMENT_DISSIPATION.normal)
		var forward:=Vector3(target.x-from.x,0,target.z-from.z).normalized()
		if forward.length_squared()<.0001:forward=Vector3.FORWARD
		for j in range(count):
			var terminal:=elemental_dissipation_sample(element,age,j)
			var q:=target+elemental_dissipation_offset(element,age,j,count,forward)
			q.y=maxf(.08,q.y)
			used=environment_particle(used,q,str(dissipate[0]),light,dark,.36*terminal.z,terminal.w)
		if resolved.kind=="confirmed":used=cinematic_impact_layers(id,profile,from,target,age,used,light,dark,status)
		if str(profile.element) in ["water","ground","rock","ice","poison","fire","electric"] or profile.pattern in ["room","radius","cross","floor"]:
			var ground:=Vector3(target.x,.045,target.z)
			used=environment_particle(used,ground,"bubble",light,dark,.65+age*1.1,fade*.70,true)
	return used

# Secondary choreography: material-specific trajectories, with a stable move
# signature so two attacks sharing a material need not scatter identically.
# Individually directed secondary choreography: mode, material, count, spread, height.
const AUTHORED_STAGE_FX={
	"lib_normal_1":["dash","impact_star",6,0.32,0.27],
	"lib_normal_2":["fall","shock_ring",8,0.59,1.06],
	"lib_normal_3":["stream","shock_ring",9,0.28,0.43],
	"lib_fire_1":["stream","ember",5,0.18,0.27],
	"lib_fire_2":["cone","flame",10,0.72,0.63],
	"lib_fire_3":["coil","flame",9,0.68,1.34],
	"lib_water_1":["stream","bubble",6,0.23,0.31],
	"lib_water_2":["stream","drop",10,0.4,0.51],
	"lib_water_3":["wave","shock_ring",10,1.15,0.78],
	"lib_electric_1":["pincer","lightning",5,0.36,0.48],
	"lib_electric_2":["helix","lightning",8,0.41,0.59],
	"lib_electric_3":["burst","lightning",10,1.18,0.65],
	"lib_grass_1":["whip","leaf",8,0.4,0.48],
	"lib_grass_2":["cone","leaf",7,0.51,0.41],
	"lib_grass_3":["ground","whip",10,1.19,0.13],
	"lib_ice_1":["stream","crystal",5,0.2,0.26],
	"lib_ice_2":["stream","crystal",10,0.34,0.57],
	"lib_ice_3":["coil","crystal",9,0.76,0.91],
	"lib_fighting_1":["contact","impact_star",7,0.43,0.35],
	"lib_fighting_2":["sweep","slash",7,0.65,0.71],
	"lib_fighting_3":["dash","impact_star",8,0.41,0.57],
	"lib_poison_1":["sweep","drop",6,0.47,0.38],
	"lib_poison_2":["arc","drop",8,0.59,0.79],
	"lib_poison_3":["eruption","venom_splash",10,0.88,0.92],
	"lib_ground_1":["ground","earth_hole",9,0.88,0.11],
	"lib_ground_2":["helix","shards",7,0.32,0.41],
	"lib_ground_3":["stream","shards",8,0.28,0.29],
	"lib_flying_1":["stream","leaf",6,0.18,0.3],
	"lib_flying_2":["sweep","slash",8,0.78,0.62],
	"lib_flying_3":["coil","slash",9,0.84,1.12],
	"lib_psychic_1":["stream","spiral",7,0.23,0.42],
	"lib_psychic_2":["wave","spiral",8,0.72,0.67],
	"lib_psychic_3":["fall","spiral",10,0.69,1.65],
	"lib_bug_1":["whip","web",7,0.3,0.47],
	"lib_bug_2":["dash","shards",8,0.42,0.39],
	"lib_bug_3":["cone","leaf",8,0.63,0.59],
	"lib_rock_1":["stream","shards",5,0.17,0.23],
	"lib_rock_2":["wheel","shards",9,0.47,0.53],
	"lib_rock_3":["fall","crystal",10,1.05,2.12],
	"lib_ghost_1":["sweep","smoke",7,0.58,0.68],
	"lib_ghost_2":["whip","smoke",6,0.33,0.51],
	"lib_ghost_3":["eruption","smoke",9,0.77,1.12],
	"lib_dragon_1":["pincer","flame",7,0.48,0.55],
	"lib_dragon_2":["cone","flame",9,0.76,0.72],
	"lib_dragon_3":["coil","flame",8,0.58,0.87],
	"lib_dark_1":["pincer","slash",5,0.35,0.44],
	"lib_dark_2":["ground","smoke",9,0.92,0.12],
	"lib_dark_3":["wave","smoke",8,0.76,0.61],
	"lib_steel_1":["sweep","crystal",7,0.53,0.64],
	"lib_steel_2":["stream","crystal",8,0.22,0.36],
	"lib_steel_3":["coil","crystal",10,0.93,1.23],
	"lib_fairy_1":["stream","impact_star",6,0.21,0.39],
	"lib_fairy_2":["shield","impact_star",8,0.62,0.89],
	"lib_fairy_3":["fall","crystal",9,0.75,1.89],
	"basic_strike":["contact","impact_star",3,0.24,0.23],
	"briar_arc":["arc","leaf",7,0.36,0.87],
	"alt_bramble_pup":["sweep","slash",5,0.38,0.37],
	"spore_cloud":["cone","cloud",8,0.73,0.44],
	"alt_sporeling":["fall","leaf",5,0.34,0.68],
	"horn_ram":["dash","dart",7,0.33,0.35],
	"alt_thornbeetle":["pincer","slash",6,0.46,0.36],
	"leaf_dart":["stream","leaf",5,0.17,0.23],
	"alt_leafwisp":["cone","leaf",7,0.62,0.48],
	"tusk_sweep":["sweep","shards",7,0.7,0.32],
	"alt_rootgnawer":["stream","leaf",6,0.19,0.28],
	"vine_snap":["whip","leaf",7,0.37,0.52],
	"alt_vinesnap":["pincer","leaf",6,0.43,0.46],
	"rolling_moss":["wheel","shards",8,0.46,0.58],
	"alt_mossmite":["cone","shards",6,0.61,0.38],
	"feather_fan":["cone","leaf",8,0.79,0.54],
	"alt_sylphowl":["sweep","slash",6,0.59,0.77],
	"antler_arc":["sweep","leaf",7,0.76,0.64],
	"alt_hollow_stag":["stream","leaf",7,0.28,0.42],
	"timber_shock":["ground","shock_ring",9,0.97,0.12],
	"alt_grovetitan":["whip","leaf",8,0.51,0.73],
	"royal_spores":["fall","cloud",10,0.91,1.29],
	"alt_fungal_monarch":["stream","cloud",9,0.41,0.56],
	"reef_bite":["pincer","drop",5,0.34,0.36],
	"alt_reef_pup":["stream","drop",5,0.16,0.28],
	"jelly_pulse":["wave","lightning",8,0.66,0.58],
	"alt_jellymancer":["whip","drop",7,0.47,0.49],
	"shell_impact":["contact","shards",7,0.56,0.41],
	"alt_shellguard":["wheel","shards",7,0.35,0.48],
	"bubble_burst":["helix","bubble",7,0.42,0.61],
	"alt_bubblewisp":["coil","bubble",8,0.59,0.47],
	"electric_lash":["whip","lightning",8,0.3,0.66],
	"alt_eelstrix":["pincer","lightning",5,0.27,0.42],
	"double_pincer":["pincer","slash",6,0.49,0.58],
	"alt_coralcrab":["stream","drop",8,0.29,0.34],
	"tentacle_snare":["coil","whip",8,0.45,0.86],
	"alt_anemoneye":["eruption","drop",9,0.71,0.96],
	"fin_slice":["sweep","slash",7,0.69,0.44],
	"alt_marrowray":["stream","dart",6,0.23,0.27],
	"spiral_current":["helix","drop",9,0.46,0.58],
	"alt_leviathorn":["stream","drop",9,0.35,0.37],
	"abyss_grasp":["pincer","smoke",9,0.63,0.75],
	"alt_abyss_colossus":["shield","smoke",8,0.73,0.84],
	"tidal_jaws":["pincer","drop",9,0.59,0.72],
	"alt_tidal_sovereign":["wave","drop",10,1.19,0.67],
	"star_kick":["arc","impact_star",6,0.39,1.02],
	"alt_starlit_pup":["dash","impact_star",5,0.22,0.34],
	"lunar_dust":["fall","impact_star",8,0.65,1.45],
	"alt_lunamoth":["sweep","impact_star",7,0.72,0.81],
	"prism_shatter":["burst","crystal",9,0.88,0.75],
	"alt_crystarok":["stream","crystal",6,0.24,0.31],
	"nova_bolt":["stream","flame",8,0.33,0.43],
	"alt_nova_wisp":["coil","ember",7,0.61,0.69],
	"orbit_lash":["whip","spiral",8,0.49,0.71],
	"alt_orbitserpent":["coil","flame",7,0.47,0.64],
	"comet_drop":["fall","meteor",9,0.59,2.23],
	"alt_comet_hare":["arc","impact_star",6,0.37,1.22],
	"gravity_web":["ground","web",9,1.03,0.1],
	"alt_voidspider":["stream","web",6,0.21,0.31],
	"sonic_cone":["cone","shock_ring",9,0.83,0.7],
	"alt_nebulwing":["burst","shock_ring",8,0.86,0.58],
	"moon_claw":["sweep","smoke",7,0.64,0.64],
	"alt_lunar_prowler":["arc","smoke",8,0.43,1.14],
	"meteor_fist":["fall","meteor",9,0.65,1.95],
	"alt_astro_golem":["burst","shards",10,1.02,0.73],
	"celestial_verdict":["fall","impact_star",10,1.04,2.65],
	"alt_celestial_guardian":["sweep","crystal",8,0.84,0.87],
	"grass_giga":["drain","leaf",10,0.75,0.72],
	"grass_absorb":["drain","leaf",4,0.25,0.3],
	"grass_solar":["stream","impact_star",10,0.19,0.48],
	"grass_vine":["whip","leaf",7,0.28,0.35],
	"grass_needle":["stream","dart",6,0.15,0.22],
	"grass_frenzy":["eruption","leaf",10,0.85,1.45],
	"grass_razor":["cone","leaf",7,0.64,0.3],
	"grass_magic":["helix","leaf",6,0.38,0.44],
	"grass_mega":["drain","leaf",7,0.49,0.5],
	"grass_blade":["sweep","leaf",6,0.67,0.48],
	"grass_wood":["dash","leaf",8,0.35,0.37],
	"grass_energy":["helix","leaf",9,0.46,0.57],
	"grass_knot":["ground","whip",7,0.54,0.09],
	"grass_flare":["burst","leaf",10,1.15,0.65],
	"grass_bomb":["arc","leaf",7,0.58,0.88],
	"grass_whip":["whip","leaf",9,0.46,0.55],
	"grass_storm":["coil","leaf",10,0.94,1.25],
	"grass_bullet":["stream","dart",9,0.25,0.18],
	"grass_spore":["fall","cloud",9,0.68,0.75],
	"grass_sleep":["fall","cloud",6,0.54,1.12],
	"grass_stun":["cone","impact_star",7,0.46,0.55],
	"grass_cotton":["shield","cloud",9,0.66,0.72],
	"grass_aroma":["rise","cloud",7,0.73,0.87],
	"grass_synthesis":["gather","impact_star",8,0.68,1.2],
	"grass_whistle":["wave","leaf",5,0.42,0.35],
	"grass_leech":["drain","leaf",5,0.35,0.21],
	"grass_petal":["coil","leaf",8,0.72,0.78],
	"grass_roots":["ground","whip",8,0.74,0.12],
	"grass_worry":["helix","leaf",5,0.26,0.33],
	"ice_aurora":["wave","crystal",8,0.72,0.75],
	"ice_wind":["cone","shards",7,0.78,0.45],
	"ice_powder":["fall","crystal",7,0.66,0.91],
	"ice_blizzard":["coil","crystal",10,1.25,1.45],
	"ice_punch":["contact","crystal",6,0.35,0.36],
	"ice_beam":["stream","crystal",9,0.16,0.22],
	"ice_fang":["pincer","crystal",5,0.31,0.45],
	"ice_shard":["stream","shards",4,0.12,0.18],
	"ice_spear":["stream","crystal",7,0.24,0.35],
	"ice_ball":["wheel","crystal",7,0.41,0.43],
	"ice_haze":["burst","smoke",8,1.05,0.38],
	"ice_mist":["shield","smoke",6,0.66,0.65],
	"ice_hail":["fall","crystal",10,0.98,2.4],
	"ice_cold":["ground","crystal",9,0.83,0.08],
	"ice_avalanche":["fall","shards",10,1.14,1.85],
	"earth_tomb":["rise","shards",7,0.48,1.13],
	"earth_slap":["cone","shards",5,0.43,0.2],
	"earth_club":["sweep","shards",6,0.55,0.48],
	"earth_shot":["stream","shards",7,0.19,0.22],
	"earth_power":["eruption","shards",9,0.65,1.52],
	"earth_bomb":["arc","shards",8,0.46,0.83],
	"earth_rush":["dash","shards",8,0.34,0.13],
	"earth_return":["arc","shards",6,0.39,0.59],
	"earth_dust":["wave","smoke",8,0.72,0.28],
	"earth_mudcoat":["shield","drop",7,0.47,0.55],
	"earth_fissure":["ground","earth_hole",10,1.18,0.08],
	"earth_spikes":["ground","dart",9,0.87,0.1],
	"earth_quake":["ground","shock_ring",10,1.35,0.12],
	"earth_magnitude":["burst","shards",10,1.22,0.75],
	"rock_throw":["arc","shards",5,0.29,0.91],
	"rock_slide":["fall","shards",9,0.89,1.75],
	"rock_tomb":["rise","shards",8,0.66,0.88],
	"rock_ancient":["helix","crystal",7,0.43,0.66],
	"rock_wrecker":["arc","shards",10,0.85,1.25],
	"rock_edge":["eruption","shards",8,0.43,1.32],
	"rock_gem":["stream","crystal",7,0.31,0.53],
	"rock_smash":["contact","shards",6,0.53,0.38],
	"rock_blast":["stream","shards",9,0.37,0.31],
	"rock_roll":["wheel","shards",8,0.38,0.42],
	"rock_polish":["gather","crystal",5,0.35,0.39],
	"rock_storm":["coil","shards",10,1.12,1.35],
	"rock_trap":["ground","shards",7,0.78,0.08],
	"fight_chop":["sweep","slash",4,0.4,0.49],
	"fight_break":["fall","impact_star",6,0.36,0.83],
	"fight_focus":["gather","impact_star",7,0.44,0.67],
	"fight_reversal":["burst","impact_star",8,0.57,0.49],
	"fight_cross":["pincer","slash",6,0.54,0.59],
	"fight_lowkick":["sweep","slash",5,0.51,0.12],
	"fight_submission":["coil","slash",6,0.29,0.52],
	"fight_uppercut":["rise","impact_star",5,0.23,0.94],
	"fight_jumpkick":["arc","slash",6,0.28,1.02],
	"fight_highkick":["sweep","slash",5,0.57,0.84],
	"fight_super":["dash","impact_star",9,0.68,0.41],
	"fight_dynamic":["contact","impact_star",8,0.53,0.58],
	"fight_mach":["dash","slash",5,0.18,0.19],
	"fight_roundkick":["wheel","slash",6,0.61,0.45],
	"fight_hammer":["fall","impact_star",7,0.53,1.17],
	"fight_close":["pincer","impact_star",9,0.43,0.55],
	"fight_blast":["stream","impact_star",10,0.42,0.64],
	"fight_vacuum":["wave","slash",5,0.37,0.27],
	"fight_drain":["drain","impact_star",6,0.34,0.4],
	"fight_palm":["contact","impact_star",5,0.48,0.32],
	"fight_aura":["helix","impact_star",8,0.28,0.41],
	"fight_slap":["sweep","impact_star",4,0.31,0.31],
	"fight_thrust":["stream","slash",5,0.24,0.33],
	"fight_double":["pincer","slash",4,0.36,0.45],
	"fight_triple":["pincer","impact_star",6,0.39,0.51],
	"fight_bulk":["shield","impact_star",8,0.49,0.91],
	"fight_detect":["shield","slash",4,0.42,0.65],
	"fight_counter":["burst","impact_star",6,0.65,0.35],
	"fight_toss":["arc","impact_star",5,0.31,1.44],
	"fight_revenge":["rise","impact_star",7,0.39,0.85],
	"fight_vital":["sweep","impact_star",7,0.6,0.59],
	"fight_stonebreak":["contact","shards",7,0.51,0.4],
	"bug_string":["whip","web",6,0.22,0.3],
	"bug_leech":["drain","leaf",5,0.22,0.34],
	"bug_silver":["cone","leaf",8,0.72,0.62],
	"bug_web":["ground","web",8,0.83,0.07],
	"bug_signal":["stream","impact_star",7,0.19,0.37],
	"bug_twin":["pincer","dart",4,0.26,0.28],
	"bug_glow":["gather","impact_star",8,0.55,0.81],
	"bug_pin":["stream","dart",5,0.13,0.16],
	"bug_horn":["dash","dart",6,0.25,0.33],
	"bug_fury":["contact","slash",7,0.37,0.44],
	"bug_heal":["rise","impact_star",6,0.4,0.75],
	"bug_attack":["sweep","slash",6,0.45,0.36],
	"bug_cross":["pincer","slash",8,0.55,0.48],
	"bug_turn":["arc","leaf",6,0.33,0.72],
	"bug_defend":["shield","web",7,0.43,0.67],
	"bug_bite":["pincer","slash",4,0.24,0.25],
	"bug_buzz":["wave","impact_star",8,0.85,0.46],
	"psi_agility":["dash","impact_star",7,0.42,0.39],
	"psi_cosmic":["shield","impact_star",9,0.74,1.18],
	"psi_beam":["stream","spiral",9,0.17,0.32],
	"psi_wave":["wave","spiral",8,0.6,0.54],
	"psi_psychic":["coil","spiral",9,0.54,0.95],
	"psi_boost":["burst","spiral",10,0.75,0.85],
	"psi_hypnosis":["coil","spiral",6,0.33,0.73],
	"psi_extra":["rise","impact_star",6,0.43,0.89],
	"psi_skill":["helix","spiral",6,0.36,0.48],
	"psi_kinesis":["rise","spiral",5,0.24,0.99],
	"psi_teleport":["burst","impact_star",7,0.4,0.97],
	"psi_trick":["pincer","spiral",5,0.37,0.55],
	"psi_amnesia":["fall","cloud",6,0.35,0.82],
	"psi_role":["sweep","spiral",5,0.56,0.47],
	"psi_rest":["gather","cloud",5,0.29,0.52],
	"psi_confusion":["helix","impact_star",7,0.49,0.62],
	"psi_barrier":["shield","crystal",8,0.52,0.96],
	"psi_screen":["shield","shock_ring",7,0.66,0.81],
	"psi_imprison":["coil","web",8,0.42,0.88],
	"psi_magic":["shield","spiral",9,0.57,0.76],
	"psi_mist":["cone","smoke",7,0.7,0.64],
	"psi_mirror":["shield","crystal",6,0.48,0.7],
	"psi_future":["gather","impact_star",7,0.51,1.34],
	"psi_calm":["gather","spiral",6,0.45,0.58],
	"psi_dream":["drain","spiral",7,0.39,0.74],
	"psi_meditate":["rise","spiral",6,0.31,0.87],
	"psi_luster":["stream","impact_star",8,0.24,0.5],
	"psi_reflect":["shield","shock_ring",8,0.73,0.67],
	"psi_wish":["fall","impact_star",6,0.39,1.68],
	"psi_guard":["shield","impact_star",8,0.56,0.85],
	"psi_block":["pincer","web",6,0.42,0.63],
	"psi_cut":["sweep","spiral",6,0.63,0.44],
	"psi_shift":["wheel","spiral",7,0.44,0.48],
	"psi_zen":["dash","spiral",7,0.31,0.38],
	"psi_gravity":["ground","shock_ring",10,1.25,0.08],
	"psi_room":["ground","spiral",10,1.47,0.11],
	"psi_heart":["pincer","impact_star",5,0.34,0.5],
	"psi_power":["rise","impact_star",8,0.62,1.02],
	"psi_powertrick":["wheel","impact_star",8,0.56,0.79],
	"psi_lunar":["fall","impact_star",9,0.62,1.76],
	"psi_eye":["gather","spiral",5,0.38,0.71],
	"ghost_nightmare":["coil","smoke",8,0.45,0.91],
	"ghost_confuse":["helix","spiral",6,0.32,0.63],
	"ghost_spite":["drain","smoke",6,0.39,0.43],
	"ghost_astonish":["burst","impact_star",5,0.36,0.57],
	"ghost_grudge":["shield","smoke",7,0.54,0.83],
	"ghost_lick":["whip","slash",5,0.24,0.32],
	"ghost_punch":["contact","smoke",6,0.33,0.28],
	"ghost_ball":["helix","smoke",8,0.38,0.56],
	"ghost_shade":["fall","smoke",7,0.42,1.55],
	"ghost_bond":["pincer","spiral",6,0.51,0.7],
	"ghost_wind":["cone","smoke",8,0.78,0.45],
	"ghost_sneak":["ground","smoke",6,0.51,0.08],
	"ghost_claw":["sweep","slash",6,0.58,0.55],
	"ghost_force":["arc","smoke",9,0.47,1.12],
	"dragon_rage":["burst","flame",8,0.73,0.67],
	"dragon_twister":["coil","flame",10,0.65,1.52],
	"dragon_claw":["sweep","flame",7,0.63,0.45],
	"dragon_flame":["stream","flame",10,0.44,0.36],
	"dragon_breath":["cone","flame",8,0.59,0.61],
	"dragon_dance":["coil","ember",7,0.44,0.95],
	"dragon_rend":["fall","slash",8,0.52,1.72],
	"dragon_time":["wave","spiral",10,1.05,0.78],
	"dragon_rush":["dash","flame",9,0.56,0.53],
	"dragon_meteor":["fall","meteor",10,1.13,2.85],
	"dragon_pulse":["wave","flame",8,0.83,0.51],
	"dark_torment":["coil","smoke",6,0.48,0.65],
	"dark_tears":["fall","drop",5,0.29,0.72],
	"dark_pursuit":["dash","slash",6,0.25,0.31],
	"dark_memento":["drain","smoke",8,0.63,0.68],
	"dark_flatter":["rise","impact_star",5,0.34,0.66],
	"dark_crunch":["pincer","slash",7,0.47,0.5],
	"dark_bite":["pincer","slash",4,0.29,0.29],
	"dark_faint":["dash","smoke",5,0.38,0.25],
	"dark_taunt":["wave","slash",5,0.45,0.42],
	"dark_thief":["sweep","slash",5,0.33,0.32],
	"dark_knock":["contact","slash",6,0.51,0.39],
	"dark_beat":["burst","slash",9,0.66,0.54],
	"dark_snatch":["gather","smoke",6,0.31,0.48],
	"dark_pulse":["wave","spiral",8,0.79,0.61],
	"dark_punish":["fall","slash",7,0.61,1.08],
	"dark_embargo":["shield","web",7,0.47,0.79],
	"dark_payback":["rise","slash",6,0.38,0.73],
	"dark_switch":["wheel","smoke",6,0.52,0.49],
	"dark_void":["ground","smoke",9,1.07,0.08],
	"dark_assure":["contact","slash",5,0.32,0.38],
	"dark_slash":["sweep","slash",7,0.62,0.52],
	"dark_fling":["arc","shards",6,0.41,0.84],
	"dark_sucker":["dash","impact_star",5,0.2,0.22],
	"dark_plot":["gather","smoke",7,0.43,0.96],
	"steel_tail":["sweep","crystal",7,0.68,0.42],
	"steel_sound":["wave","crystal",8,0.75,0.58],
	"steel_meteor":["fall","crystal",8,0.63,2.1],
	"steel_defense":["shield","crystal",9,0.52,0.85],
	"steel_wing":["sweep","crystal",6,0.62,0.62],
	"steel_doom":["ground","shock_ring",8,0.82,0.09],
	"steel_claw":["pincer","crystal",5,0.41,0.46],
	"steel_head":["dash","crystal",7,0.32,0.27],
	"steel_gyro":["wheel","crystal",9,0.48,0.53],
	"steel_bullet":["stream","crystal",6,0.15,0.19],
	"steel_magnet":["gather","crystal",8,0.57,0.69],
	"steel_mirror":["shield","crystal",8,0.74,0.93],
	"steel_burst":["burst","crystal",10,0.97,0.64],
	"steel_flash":["cone","impact_star",7,0.53,0.71],
	"normal_thrash":["coil","impact_star",8,0.53,0.48],
	"normal_cut":["sweep","slash",5,0.45,0.39],
	"normal_superfang":["pincer","slash",6,0.55,0.43],
	"normal_slap":["sweep","impact_star",4,0.27,0.25],
	"normal_return":["arc","impact_star",6,0.42,0.7],
	"normal_strength":["rise","impact_star",7,0.49,0.85],
	"normal_bide":["shield","impact_star",6,0.38,0.56],
	"normal_endeavor":["contact","impact_star",5,0.42,0.38],
	"normal_facade":["burst","impact_star",7,0.59,0.57],
	"normal_constrict":["coil","whip",5,0.25,0.47],
	"normal_salt":["wave","shards",6,0.48,0.2],
	"normal_slash":["sweep","slash",6,0.5,0.5],
	"normal_spin":["wheel","slash",7,0.44,0.37],
	"normal_flail":["coil","slash",6,0.46,0.53],
	"normal_bind":["coil","whip",6,0.31,0.55],
	"normal_extreme":["dash","slash",9,0.48,0.26],
	"normal_headbutt":["contact","impact_star",5,0.31,0.32],
	"normal_edge":["dash","slash",8,0.37,0.47],
	"normal_tackle":["dash","impact_star",5,0.28,0.24],
	"normal_slam":["fall","impact_star",6,0.51,0.92],
	"normal_horn":["stream","dart",5,0.22,0.25],
	"normal_drill":["helix","dart",7,0.26,0.37],
	"normal_quick":["dash","slash",4,0.15,0.15],
	"normal_takedown":["dash","impact_star",7,0.49,0.36],
	"normal_fake":["burst","impact_star",4,0.24,0.3],
	"normal_body":["fall","impact_star",8,0.66,0.87],
	"normal_guillotine":["pincer","slash",5,0.62,0.74],
	"normal_vice":["pincer","slash",4,0.39,0.38],
	"normal_pound":["contact","impact_star",4,0.26,0.21],
	"normal_scratch":["sweep","slash",4,0.33,0.32],
	"normal_hyperfang":["pincer","slash",5,0.42,0.52],
	"normal_dizzy":["helix","impact_star",6,0.45,0.56],
	"normal_stomp":["ground","shock_ring",6,0.58,0.09],
	"normal_crushclaw":["fall","slash",6,0.48,0.79],
	"normal_wrap":["coil","whip",8,0.38,0.75],
	"normal_furyattack":["stream","dart",8,0.3,0.26],
	"normal_furyswipes":["sweep","slash",8,0.48,0.36],
	"normal_false":["sweep","slash",3,0.28,0.22],
	"normal_megakick":["arc","slash",7,0.58,0.94],
	"normal_megapunch":["contact","impact_star",7,0.6,0.39],
	"normal_frustration":["burst","impact_star",8,0.63,0.7],
	"normal_comet":["fall","impact_star",7,0.42,1.3],
	"normal_skull":["dash","impact_star",8,0.43,0.47],
	"normal_struggle":["contact","slash",5,0.37,0.35],
	"normal_giga":["dash","impact_star",10,0.67,0.66],
	"normal_double":["pincer","impact_star",5,0.33,0.41],
	"normal_last":["burst","impact_star",9,0.76,0.84],
	"normal_grip":["pincer","whip",7,0.37,0.54],
	"normal_feint":["dash","slash",4,0.23,0.31],
	"normal_climb":["arc","shards",8,0.36,1.14],
	"neutral_snore":["wave","cloud",6,0.47,0.44],
	"neutral_weather":["fall","impact_star",8,0.81,1.58],
	"neutral_razor":["stream","slash",7,0.36,0.44],
	"neutral_self":["burst","smoke",10,1.1,0.72],
	"neutral_swift":["helix","impact_star",8,0.37,0.54],
	"neutral_sonic":["wave","shock_ring",6,0.52,0.33],
	"neutral_explosion":["burst","smoke",10,1.52,1.32],
	"neutral_egg":["arc","impact_star",5,0.25,0.81],
	"neutral_barrage":["arc","impact_star",8,0.54,1.07],
	"neutral_spike":["stream","dart",6,0.21,0.29],
	"neutral_tri":["pincer","impact_star",6,0.56,0.75],
	"neutral_pay":["fall","crystal",7,0.46,1.21],
	"neutral_voice":["cone","shock_ring",8,0.86,0.66],
	"neutral_beam":["stream","impact_star",10,0.38,0.48],
	"neutral_spit":["stream","drop",6,0.23,0.34],
	"neutral_secret":["helix","spiral",7,0.43,0.6],
	"neutral_present":["arc","impact_star",6,0.4,0.95],
	"neutral_covet":["sweep","impact_star",5,0.36,0.37],
	"neutral_hidden":["coil","impact_star",7,0.4,0.58],
	"neutral_wide":["wave","slash",8,0.91,0.34],
	"neutral_vacuum":["cone","slash",5,0.38,0.24],
	"neutral_trump":["stream","dart",7,0.32,0.5],
	"neutral_gift":["arc","leaf",5,0.43,0.72],
	"neutral_wring":["coil","whip",7,0.36,0.67],
	"support_sun":["gather","ember",8,0.57,1.35],
	"support_rage":["rise","flame",7,0.41,0.88],
	"support_pain":["drain","spiral",7,0.38,0.61],
	"support_bell":["wave","impact_star",6,0.55,0.64],
	"support_sharpen":["gather","crystal",6,0.35,0.65],
	"support_double":["wheel","smoke",7,0.45,0.56],
	"support_harden":["shield","crystal",7,0.48,0.76],
	"support_focus":["gather","impact_star",8,0.38,0.82],
	"support_mind":["coil","spiral",7,0.46,0.88],
	"support_follow":["dash","impact_star",6,0.6,0.43],
	"support_endure":["shield","shock_ring",6,0.43,0.55],
	"support_psych":["helix","spiral",6,0.5,0.67],
	"support_recover":["rise","impact_star",8,0.44,0.81],
	"support_safeguard":["shield","shock_ring",9,0.73,0.92],
	"support_growth":["rise","leaf",8,0.48,1.03],
	"support_stock":["gather","bubble",7,0.39,0.68],
	"support_egg":["fall","impact_star",6,0.41,0.83],
	"support_minimize":["gather","smoke",5,0.29,0.38],
	"support_moon":["fall","impact_star",7,0.51,1.65],
	"support_swords":["rise","slash",8,0.42,0.91],
	"support_help":["pincer","impact_star",6,0.61,0.52],
	"support_howl":["wave","shock_ring",7,0.69,0.62],
	"support_slack":["gather","cloud",5,0.47,0.4],
	"support_wish":["fall","impact_star",8,0.45,1.87],
	"support_swallow":["gather","bubble",6,0.32,0.49],
	"support_drum":["burst","shock_ring",7,0.78,0.3],
	"support_protect":["shield","crystal",8,0.66,0.89],
	"support_curl":["coil","shock_ring",6,0.34,0.42],
	"support_milk":["rise","drop",6,0.43,0.69],
	"support_refresh":["burst","bubble",7,0.54,0.74],
	"support_lock":["gather","crystal",5,0.31,0.55],
	"support_lucky":["coil","impact_star",8,0.58,0.73],
	"support_acu":["rise","dart",7,0.29,0.91],
	"status_yawn":["wave","cloud",5,0.44,0.54],
	"status_talk":["coil","cloud",6,0.4,0.72],
	"status_lovely":["fall","impact_star",6,0.48,0.98],
	"status_charm":["rise","impact_star",5,0.45,0.76],
	"status_kiss":["arc","impact_star",4,0.25,0.65],
	"status_attract":["coil","impact_star",7,0.59,0.75],
	"status_captivate":["helix","impact_star",8,0.63,0.84],
	"status_scent":["wave","cloud",6,0.58,0.41],
	"status_smoke":["burst","smoke",9,0.83,0.49],
	"status_odor":["cone","cloud",7,0.55,0.34],
	"status_screech":["cone","shock_ring",7,0.61,0.56],
	"status_sing":["wave","impact_star",6,0.64,0.87],
	"status_uproar":["burst","shock_ring",9,0.96,0.65],
	"status_supersonic":["stream","shock_ring",7,0.24,0.46],
	"status_growl":["cone","shock_ring",5,0.43,0.32],
	"status_roar":["wave","shock_ring",8,0.88,0.55],
	"status_perish":["fall","smoke",8,0.55,1.13],
	"status_mean":["gather","spiral",5,0.37,0.55],
	"status_scary":["burst","smoke",6,0.47,0.59],
	"status_leer":["stream","impact_star",4,0.18,0.32],
	"status_glare":["pincer","lightning",5,0.3,0.47],
	"status_foresight":["gather","impact_star",6,0.34,0.71],
	"status_encore":["pincer","impact_star",6,0.58,0.52],
	"status_disable":["shield","web",6,0.41,0.59],
	"status_block":["ground","web",7,0.61,0.09],
	"status_curse":["coil","smoke",8,0.62,0.91],
	"status_sub":["burst","smoke",7,0.5,0.62],
	"status_convert":["wheel","spiral",6,0.39,0.51],
	"status_convert2":["helix","spiral",7,0.46,0.61],
	"status_transform":["coil","spiral",9,0.58,0.99],
	"status_camo":["gather","leaf",6,0.42,0.41],
	"status_nature":["rise","leaf",7,0.54,0.88],
	"status_sketch":["sweep","slash",5,0.48,0.57],
	"status_assist":["pincer","impact_star",6,0.51,0.46],
	"status_metronome":["wheel","impact_star",6,0.36,0.69],
	"status_mimic":["mirror","impact_star",5,0.41,0.53],
	"status_first":["dash","impact_star",6,0.27,0.45],
	"status_copycat":["mirror","spiral",7,0.52,0.68],
	"status_swagger":["rise","impact_star",7,0.48,0.83],
	"status_tickle":["whip","leaf",5,0.3,0.36],
	"status_tail":["sweep","leaf",5,0.46,0.24],
	"status_dance":["coil","impact_star",8,0.52,0.71],
	"status_baton":["arc","impact_star",6,0.38,0.76],
	"status_recycle":["wheel","leaf",7,0.44,0.6],
	"status_splash":["arc","drop",5,0.34,0.96],
	"status_whirl":["coil","smoke",9,0.73,0.96],
	"status_flash":["burst","impact_star",9,0.81,0.54],
	"electric_sky":["fall","lightning",7,0.22,2.7],
	"electric_burst":["burst","impact_star",10,0.94,0.42],
	"electric_short":["contact","lightning",4,0.17,0.16],
	"electric_wave":["wave","lightning",6,0.72,0.22],
	"electric_fist":["contact","impact_star",5,0.31,0.34],
	"electric_spark":["dash","lightning",5,0.19,0.27],
	"electric_orb":["helix","impact_star",7,0.34,0.39],
	"electric_dash":["dash","slash",8,0.33,0.18],
	"electric_fang":["pincer","lightning",4,0.31,0.43],
	"electric_beam":["stream","lightning",9,0.1,0.12],
	"electric_room":["fall","lightning",9,0.85,2.1],
	"electric_bind":["coil","lightning",8,0.31,0.82],
	"electric_charge":["gather","impact_star",7,0.55,0.55],
	"electric_lift":["rise","lightning",6,0.42,1.25],
	"fire_overheat":["burst","smoke",10,1.15,1.2],
	"fire_wheel":["wheel","ember",8,0.43,0.6],
	"fire_breath":["cone","flame",8,0.65,0.35],
	"fire_sacred":["rise","flame",7,0.41,1.5],
	"fire_blast":["burst","flame",5,1.12,0.67],
	"fire_heatwave":["wave","ember",9,1.1,0.45],
	"fire_ember":["stream","ember",4,0.16,0.23],
	"fire_blastburn":["eruption","flame",10,1.24,1.6],
	"fire_kick":["sweep","ember",6,0.6,0.55],
	"fire_eruption":["eruption","ember",9,0.78,1.95],
	"fire_vortex":["coil","flame",9,0.49,1.23],
	"fire_punch":["contact","ember",6,0.36,0.29],
	"fire_blitz":["dash","flame",9,0.46,0.38],
	"fire_plume":["rise","smoke",10,0.82,1.68],
	"fire_fang":["pincer","flame",4,0.3,0.41],
	"fire_magma":["coil","ember",8,0.7,0.48],
	"fire_wisp":["helix","flame",3,0.22,0.48],
	"fire_sun":["gather","ember",8,0.81,1.85],
	"water_bubble":["helix","bubble",5,0.34,0.52],
	"water_whirlpool":["coil","drop",9,0.63,0.6],
	"water_ink":["cone","smoke",7,0.55,0.26],
	"water_clamp":["pincer","drop",6,0.38,0.34],
	"water_hammer":["fall","drop",8,0.45,1.2],
	"water_spout":["eruption","drop",10,0.59,1.95],
	"water_dive":["ground","shock_ring",6,0.65,0.09],
	"water_fall":["fall","drop",9,0.42,2.2],
	"water_mud":["wave","drop",8,0.91,0.2],
	"water_surf":["wave","shock_ring",10,1.3,0.55],
	"water_cannon":["stream","drop",10,0.27,0.36],
	"water_pump":["cone","drop",9,0.48,0.45],
	"water_bubblebeam":["stream","bubble",9,0.17,0.33],
	"water_gun":["stream","drop",5,0.12,0.13],
	"water_pulse":["wave","bubble",6,0.58,0.37],
	"water_jet":["dash","drop",7,0.2,0.14],
	"water_tail":["sweep","drop",8,0.7,0.42],
	"water_brine":["cone","drop",6,0.37,0.58],
	"water_shell":["shield","bubble",8,0.49,0.84],
	"water_rain":["fall","drop",10,1.25,2.45],
	"water_mist":["shield","smoke",7,0.79,0.61],
	"water_ring":["coil","bubble",7,0.51,0.53],
	"air_cutter":["cone","slash",5,0.62,0.32],
	"air_gust":["wave","slash",7,0.68,0.2],
	"air_sky":["fall","slash",8,0.36,2.4],
	"air_fly":["arc","slash",7,0.23,2.1],
	"air_peck":["contact","impact_star",3,0.15,0.25],
	"air_wing":["sweep","slash",6,0.81,0.49],
	"air_ace":["dash","slash",6,0.24,0.38],
	"air_bounce":["arc","shock_ring",5,0.46,1.45],
	"air_drill":["helix","slash",7,0.24,0.31],
	"air_blast":["stream","slash",10,0.5,0.5],
	"air_slash":["sweep","slash",5,0.54,0.71],
	"air_chatter":["wave","impact_star",5,0.41,0.62],
	"air_pluck":["pincer","leaf",4,0.21,0.33],
	"air_brave":["arc","slash",9,0.63,1.2],
	"air_tailwind":["dash","leaf",8,0.83,0.38],
	"air_feather":["fall","leaf",8,0.79,1.12],
	"air_roost":["gather","leaf",6,0.53,0.26],
	"air_defog":["burst","smoke",8,1.15,0.29],
	"air_mirror":["shield","slash",5,0.45,0.73],
	"poison_smog":["cone","smoke",8,0.72,0.5],
	"poison_gas":["burst","smoke",10,1.1,0.39],
	"poison_toxic":["ground","venom_splash",7,0.55,0.08],
	"poison_fang":["pincer","drop",4,0.29,0.42],
	"poison_powder":["fall","drop",8,0.82,1.1],
	"poison_sting":["stream","dart",4,0.09,0.18],
	"poison_armor":["shield","drop",7,0.47,0.8],
	"poison_sludge":["arc","drop",6,0.37,0.65],
	"poison_bomb":["arc","venom_splash",9,0.69,0.91],
	"poison_tail":["sweep","drop",6,0.61,0.32],
	"poison_acid":["cone","drop",7,0.48,0.25],
	"poison_gastro":["helix","drop",6,0.33,0.45],
	"poison_cross":["sweep","slash",8,0.51,0.51],
	"poison_gunk":["arc","drop",10,0.83,1.16],
	"poison_jab":["contact","dart",5,0.25,0.28],
	"poison_spikes":["ground","dart",9,1.03,0.1],
	"earth_dig":["ground","shards",8,0.56,0.14],
}

func authored_stage_fx(burst:Dictionary,t:float,used:int)->int:
	var profile:Dictionary=burst.profile
	var role:String=str(profile.role)
	var cue_key:String=str(burst.id) if AUTHORED_STAGE_FX.has(str(burst.id)) else role
	if not AUTHORED_STAGE_FX.has(cue_key):return used
	var cue:Array=AUTHORED_STAGE_FX[cue_key]
	var style:Array=combat_style(str(burst.id))
	var light:=Color(str(style[1]));var dark:=Color(str(style[2]))
	var points:Array=burst.points
	if points.is_empty():return used
	var source:Vector3=points[0]
	var target:Vector3=points[-1]
	var results:Dictionary=burst.get("results",{})
	var primary_tile:=Vector2i(roundi(target.x/1.4),roundi(target.z/1.4))
	var row:Dictionary=results.get(primary_tile,{})
	var miss:bool=not row.is_empty() and int(row.get("damage",0))+int(row.get("effects",0))+int(row.get("heal",0))<=0
	var peak:float=float(profile.impact)
	if t>=peak and miss:
		var resolved:=resolve_element_impact(burst)
		if resolved.kind!="confirmed":return used
		target=resolved.target
	var forward:=Vector3(target.x-source.x,0,target.z-source.z)
	if forward.length_squared()<.0001:forward=Vector3.FORWARD
	forward=forward.normalized()
	var side:=Vector3(-forward.z,0,forward.x)
	var spread:float=float(cue[3])
	var height:float=float(cue[4])
	var count:int=int(cue[2])
	var mode:String=str(cue[0])
	var progress:float=clampf(t/maxf(.01,peak),0.0,1.0)
	var after:float=clampf((t-peak)/maxf(.01,1.0-peak),0.0,1.0)
	var opacity:float=minf(t*12.0,1.0-after)
	for i in range(count):
		if used>=fx_cast_particle_limit:break
		var f:float=float(i)/maxi(1,count-1)
		var angle:float=f*TAU
		var p:float=clampf(progress-f*.23,0.0,1.0)
		var radial:Vector3=forward*cos(angle)+side*sin(angle)
		var q:Vector3=combat_path_sample(points,p)
		var flat:bool=false
		var size:float=.24+.10*sin(f*PI)
		match mode:
			"fall":
				q=target+radial*spread*(.25+f*.75)
				q.y+=height*(1.0-p)*(1.0-p)
			"rise","eruption":
				var anchor:Vector3=source if mode=="rise" else target
				q=anchor+radial*spread*(.2+.8*p)+Vector3.UP*height*sin(p*PI*.75)
			"burst":
				q=target+radial*spread*(.1+.9*after)+Vector3.UP*height*sin(after*PI)
				if t<peak:continue
			"contact":
				q=target+radial*spread*sin(after*PI)+Vector3.UP*height*sin(angle)
				if t<peak*.82:continue
			"pincer":
				var sign_value:float=-1.0 if i%2==0 else 1.0
				q=target+side*sign_value*spread*(1.0-p)+Vector3.UP*height*(.4+.6*f)
			"stream","cone","dash":
				q+=side*(f-.5)*spread*(p if mode=="cone" else 1.0)
				q.y+=height*sin(p*PI+angle)*.65
				if mode=="dash":q-=forward*f*.42
			"wave":
				q+=side*(f-.5)*spread+Vector3.UP*height*absf(sin(angle+p*PI))
			"helix","wheel":
				var turn:float=angle+p*TAU*1.6
				q+=side*cos(turn)*spread+Vector3.UP*sin(turn)*height
			"coil","shield":
				var turn:float=angle+t*TAU*1.4
				q=(source if mode=="shield" else target)+Vector3(cos(turn)*spread,height*f,sin(turn)*spread)
			"gather":
				q=source+radial*spread*(1.0-progress)+Vector3.UP*height*(.2+.8*progress)
			"sweep":
				var turn:float=lerpf(-PI*.75,PI*.75,p)+f*.6
				q=target+(forward*cos(turn)+side*sin(turn))*spread+Vector3.UP*height*sin(p*PI)
			"arc":
				q+=Vector3.UP*height*sin(p*PI)+side*(f-.5)*spread
			"drain":
				# Absorption reverses the travel direction after confirmed contact.
				if t<peak:continue
				var back:float=clampf(after*1.35-f*.26,0.0,1.0)
				q=combat_path_sample(points,1.0-back)+side*cos(angle+back*TAU)*spread*sin(back*PI)+Vector3.UP*height*sin(back*PI)
			"whip":
				q=combat_path_sample(points,p)+side*sin(f*TAU*1.5-progress*5.0)*spread*sin(p*PI)
				q.y+=height*sin(f*PI)
			"mirror":
				q=source.lerp(target,p)+side*cos(angle)*spread+Vector3.UP*height*sin(angle)
				if i%2==1:q=target.lerp(source,p)+side*sin(angle)*spread+Vector3.UP*height*.5
			"ground":
				q=Vector3(target.x,.048,target.z)+radial*spread*(.15+.85*progress)
				flat=true
		used=environment_particle(used,q,str(cue[1]),light,dark,size,opacity*.85,flat)
	return used

func cinematic_impact_layers(id:String,profile:Dictionary,source:Vector3,target:Vector3,age:float,used:int,light:Color,dark:Color,status:bool)->int:
	var element:String=str(profile.element)
	var role:String=str(profile.role)
	var forward:=Vector3(target.x-source.x,0,target.z-source.z)
	if forward.length_squared()<.0001:forward=Vector3.FORWARD
	forward=forward.normalized()
	var side:=Vector3(-forward.z,0,forward.x)
	var signature:int=int(id.hash() & 0xffff)
	var heavy:bool=profile.pattern in ["room","floor","radius","cross"] or "blast" in role or "quake" in role or "meteor" in role
	var count:int=10 if heavy else 6
	if status:count=4
	var fade:float=pow(1.0-age,1.25)
	var ground:=Vector3(target.x,.045,target.z)
	for i in range(count):
		var angle:float=TAU*float(i)/float(count)+float(signature%31)*.12
		var speed:float=.72+float((signature+i*19)%11)*.045
		var travel:float=age*speed*(1.15 if heavy else .8)
		var radial:Vector3=forward*cos(angle)+side*sin(angle)
		var arc:float=sin(age*PI)
		var q:Vector3=ground+radial*(.08+travel)+Vector3.UP*(.12+arc*.48)
		var mode:String="impact_star"
		var size:float=.18+.16*fade
		var flat:bool=false
		match element:
			"fire":
				mode="ember" if i%3!=0 else "smoke"
				q.y=.10+age*(.9+speed*.45)
				q+=forward*age*.25
				size=.24+age*.28 if mode=="smoke" else .22*fade
			"water":
				mode="drop" if age<.76 else "shock_ring"
				q.y=.05+arc*(.65+speed*.30)
				flat=age>=.76
				if flat:q.y=.045
			"poison":
				mode="drop" if age<.63 else "venom_splash"
				q.y=.05+arc*.48
				flat=age>=.63
				if flat:q.y=.047
				size=.26+age*.20
			"ground":
				mode="earth_hole" if i%3==0 else "shards"
				flat=i%3==0;q.y=.045 if flat else .04+arc*.48
				size=.24+age*.25
			"rock":
				mode="shards";q.y=.05+arc*(.7+speed*.42);size=.28+speed*.18
			"steel":
				mode="slash" if i%2==0 else "crystal"
				q.y=.08+arc*.35;size=.18+speed*.16
			"ice":
				mode="crystal";q.y=.05+float(i%3)*.19+arc*.18
				size=.30+age*.12
			"electric":
				mode="lightning" if i%2==0 else "impact_star"
				q=target+radial*travel+Vector3.UP*(arc*.36+sin(angle*3.0+age*20.0)*.14)
			"grass":
				mode="leaf";q=ground+radial.rotated(Vector3.UP,age*1.8)*travel+Vector3.UP*(.10+arc*.72)
			"bug":
				mode="web" if i%3==0 else "leaf";q=ground+radial*travel+Vector3.UP*(.12+arc*.32)
			"flying":
				mode="slash";q=target+radial.rotated(Vector3.UP,age*4.5)*travel+Vector3.UP*(arc*.6)
			"fighting":
				mode="impact_star";q=target+forward*(age*speed*.7)+side*sin(angle)*travel+Vector3.UP*(arc*.25)
			"normal":
				mode="shock_ring" if i%3==0 else "impact_star";q=target+radial*travel
			"dark":
				mode="slash" if i%2==0 else "smoke";q=target-radial*travel+Vector3.UP*(arc*.22)
			"psychic":
				mode="spiral";q=target+radial.rotated(Vector3.UP,age*4.8)*travel+Vector3.UP*(age*.44)
			"ghost":
				mode="cloud" if i%2==0 else "flame";q=target+radial.rotated(Vector3.UP,-age*2.8)*travel+Vector3.UP*(age*.72)
			"fairy":
				mode="impact_star";q=target+radial.rotated(Vector3.UP,age*2.6)*travel+Vector3.UP*(arc*.54)
			"dragon":
				mode="flame" if i%2==0 else "lightning";q=target+radial.rotated(Vector3.UP,age*3.2)*travel+Vector3.UP*(arc*.65)
		used=environment_particle(used,q,mode,light,dark,size,fade*.92,flat)
	if heavy and not status:
		used=environment_particle(used,ground,"shock_ring",light,dark,.35+age*2.25,fade*.68,true)
	return used

func charge_environment_fx(used:int)->int:
	var origin:Vector3=pos(run.player)+Vector3(0,.04,0)
	var pulse:float=.8+.12*sin(elapsed*7.0)
	match run.charge_phase:
		"gather","vanish":
			var style:Array=combat_style(run.charged_move_id)
			var profile:=combat_profile(run.charged_move_id)
			var light:=Color(style[1]);var dark:=Color(style[2])
			var material:String=str(ELEMENT_FINISH_MODE.get(str(profile.element),"impact_star"))
			used=environment_particle(used,origin,"shock_ring",light,dark,pulse,.62,true)
			for j in range(4):
				var f:float=fposmod(elapsed*.85+float(j)/4.0,1.0)
				var angle:float=float(j)*TAU/4.0+elapsed*2.4
				var radius:float=.62*(1.0-f)+.10
				var q:=origin+Vector3(cos(angle)*radius,.15+f*.65,sin(angle)*radius)
				used=environment_particle(used,q,material,light,dark,.28,sin(f*PI)*.9)
		"underground":
			used=environment_particle(used,origin,"earth_hole",Color("#c7a777"),Color("#795638"),pulse, .85,true)
			for j in range(4):
				var angle:float=float(j)*TAU/4.0+elapsed*2.0
				used=environment_particle(used,origin+Vector3(cos(angle)*.35,.12+absf(sin(elapsed*4.0+j))*.3,sin(angle)*.35),"shards",Color("#c8ad78"),Color("#705338"),.28,.85)
		"airborne":
			used=environment_particle(used,origin,"bubble",Color("#a2c6d5"),Color("#536f85"),pulse,.50,true)
			for j in range(4):
				var angle:float=float(j)*TAU/4.0+elapsed*3.0
				used=environment_particle(used,origin+Vector3(cos(angle)*.42,1.05+.16*sin(angle),sin(angle)*.42),"slash",Color("#ecfaff"),Color("#82b6cf"),.40,.85)
	return used

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
		if not actor_nodes.has(key) or not is_instance_valid(actor_nodes[key]):continue
		var actor:Node3D=actor_nodes[key]
		if actor.is_queued_for_deletion():continue
		var direction:=Vector2(event.get("aim",event.to-event.from))
		match str(event.phase):
			"attack":
				var profile:=combat_profile(str(event.get("fx","basic_strike")))
				enemy_pose(actor,"attack",float(profile.duration),direction)
				var kind:String=tile_cast_kind(str(event.get("fx","basic_strike")))
				if not kind.is_empty() and event.from!=event.to:
					actor.set_meta("enemy_tile_cast",{"kind":kind,"points":tile_cast_route(event)})
				actor.set_meta("enemy_cast_motion",cast_motion_kind(str(event.get("fx","basic_strike")),profile))
				actor.set_meta("enemy_cast_impact",float(profile.impact))
				actor.set_meta("enemy_cast_waves",caster_wave_times(event,float(profile.duration),float(profile.impact)))
				event["target_player"]=event.get("to",Vector2i(-999,-999))==run.player
				combat_fx_spawn(event)
			"windup":enemy_pose(actor,"windup",.18,direction)
			"cancel":enemy_pose(actor,"idle",0.0,direction)
			"move":
				if actor.has_meta("species"):
					actor.set_meta("enemy_facing",PixelArt.direction8_for(direction,int(actor.get_meta("enemy_facing",0))))
# Periodic damage, traps and allied actions must not inherit the previous
# player's attack duration, direction, or multi-hit count.
func damage_reaction_spec(profile:Dictionary,new_cast:bool,tracked_hits:int,affected_tile:bool,direction:Vector3)->Dictionary:
	var linked:bool=new_cast and (tracked_hits>0 or affected_tile)
	if not linked:return {"delay":0.0,"span":0.0,"count":1,"direction":Vector3.ZERO}
	var duration:float=float(profile.duration)
	var delay:float=duration*float(profile.impact)
	return {"delay":delay,"span":maxf(0.0,duration-delay),"count":maxi(1,tracked_hits),"direction":direction}

# Only remove the exact cast that already owns a world effect, not every
# counter with the same target and move name.
func remaining_response_events(events:Array,cast_serial:int)->Array:
	var result:Array=[]
	for event in events:
		if cast_serial>=0 and str(event.get("source",""))=="sleep_counter" and int(event.get("cast_serial",-1))==cast_serial:continue
		result.append(event)
	return result

# Reserve the single player body across all targets, including pending casts.
func response_cast_available_at()->float:
	var cursor:float=maxf(0.0,attack_time)
	if run!=null and run.attack_serial!=previous_attack:
		cursor=maxf(cursor,float(combat_profile(run.player_attack_fx).duration))
	for pending in delayed_combat_fx:
		var duration:float=float(combat_profile(str(pending.event.fx)).duration)
		cursor=maxf(cursor,float(pending.delay)+duration+.04)
	return cursor

# Reserve deferred counter slots in simulation serial order, independent of actor traversal.
func eligible_counter_responses(responses:Dictionary,eligible:Dictionary)->Dictionary:
	var result:Dictionary={}
	for uid in responses:
		if eligible.has(uid):result[uid]=responses[uid]
	return result

func visible_counter_responses()->Dictionary:
	var living:Dictionary={}
	var eligible:Dictionary={}
	for enemy in run.enemies:
		var uid:int=int(enemy.get("uid",-1))
		living[uid]=true
		if run.revealed.has(enemy.pos):eligible[uid]=true
	# Defeated actors are still rendered until their terminal reaction finishes.
	for key in actor_nodes:
		if not str(key).begins_with("enemy:"):continue
		var uid:int=int(str(key).trim_prefix("enemy:"))
		if living.has(uid):continue
		var actor=actor_nodes[key]
		if not is_instance_valid(actor) or actor.is_queued_for_deletion():continue
		if actor.has_meta("species") and str(actor.get_meta("enemy_phase",""))!="defeat" and not actor.get_meta("pending_defeat",false):
			eligible[uid]=true
	return eligible_counter_responses(run.visual_turn_damage,eligible)

func global_counter_slots(responses:Dictionary,immediate_serial:int,start:float,budget:int)->Dictionary:
	var candidates:Array[Dictionary]=[]
	for uid in responses:
		var gap:float=0.0
		for event in responses[uid].get("events",[]):
			var serial:int=int(event.get("cast_serial",-1))
			if str(event.get("source",""))=="sleep_counter" and serial>=0 and event.has("from") and event.has("to") and not str(event.get("move_id","")).is_empty():
				if serial==immediate_serial:continue
				candidates.append({"serial":serial,"id":str(event.move_id),"gap":gap})
				gap=0.0
			else:gap+=.12
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.serial)<int(b.serial))
	var slots:Dictionary={}
	var cursor:float=maxf(0.0,start)
	for item in candidates:
		if slots.has(item.serial):continue
		if budget<=0:
			slots[item.serial]=-1.0
			continue
		budget-=1
		cursor+=float(item.gap)
		slots[item.serial]=cursor
		cursor+=float(combat_profile(str(item.id)).duration)+.04
	return slots

var response_slots:Dictionary={}

func response_fx_plan(events:Array,start:float,body_available:float=0.0,cast_budget:int=DELAYED_COMBAT_FX_CAP,slots:Dictionary={})->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var cursor:float=maxf(0.0,start)
	for event in events:
		var item:Dictionary={"hit":cursor,"launch":-1.0,"event":{},"response":event}
		var id:String=str(event.get("move_id",""))
		var serial:int=int(event.get("cast_serial",-1))
		var reserved:bool=slots.has(serial)
		var slot:float=float(slots.get(serial,-1.0))
		if (slot>=0.0 if reserved else cast_budget>0) and str(event.get("source",""))=="sleep_counter" and not id.is_empty() and event.has("from") and event.has("to"):
			cast_budget-=1
			var profile:=combat_profile(id)
			var duration:float=float(profile.duration)
			cursor=maxf(cursor,slot if reserved else body_available)
			item.launch=cursor
			item.hit=cursor+duration*float(profile.impact)
			item.event={"fx":id,"from":event.from,"to":event.to,"tiles":[event.to],"path":event.get("path",[event.to]),"results":event.get("results",{event.to:{"damage":int(event.get("amount",0)),"hits":1,"crit":0}})}
			cursor+=duration+.04
		else:cursor+=.12
		result.append(item)
	return result

func queue_observed_enemy_damage(actor:Node3D,uid:int,tile:Vector2i,defeated:bool)->void:
	var new_cast:bool=run.attack_serial!=previous_attack
	var hits:int=int(run.player_visual_hits.get(uid,0)) if new_cast and run.player_visual_hit_serial==run.attack_serial else 0
	var affected:bool=tile in run.player_attack_cells
	var response_cast:bool=new_cast and run.visual_response_cast_serial==run.attack_serial and run.visual_response_cast_uid==uid
	var response:Dictionary={}
	if run.visual_turn_damage_turn==run.turns and (enemy_event_floor!=run.floor_revision or enemy_event_turn!=run.turns):
		response=run.visual_turn_damage.get(uid,{})
	# The observed pre-turn HP identifies whether damage already occurred in
	# the initiating action, even when the same target also loses HP later.
	if not response.is_empty():
		var old_hp:int=int(actor.get_meta("enemy_hp",response.before))
		affected=affected and old_hp>int(response.before)
	if response_cast:
		hits=maxi(1,hits);affected=true
	var cast_profile:=combat_profile(run.player_attack_fx)
	var spec:=damage_reaction_spec(cast_profile,new_cast,hits,affected,(pos(tile)-pos(run.player)).normalized())
	var actual_times:Array[float]=[]
	if new_cast and run.player_cast_result_serial==run.attack_serial:
		actual_times=confirmed_wave_times(run.player_cast_results,tile,float(cast_profile.duration),float(cast_profile.impact))
	if response.is_empty():
		queue_enemy_reaction(actor,defeated,float(spec.delay),Vector3(spec.direction),float(spec.span),int(spec.count),actual_times)
		return
	var linked:bool=new_cast and (hits>0 or affected)
	var events:Array=remaining_response_events(response.get("events",[]),run.attack_serial if response_cast else -1)
	if response_cast:
		if events.is_empty():
			queue_enemy_reaction(actor,defeated,float(spec.delay),Vector3(spec.direction),float(spec.span),int(spec.count),actual_times)
			return
	var secondary_delay:float=float(spec.delay)+float(spec.span)+.04 if linked else 0.0
	var plan:Array[Dictionary]=response_fx_plan(events if not events.is_empty() else [{}],secondary_delay,response_cast_available_at(),maxi(0,DELAYED_COMBAT_FX_CAP-delayed_combat_fx.size()),response_slots)
	# Reserve effects in chronological order before enqueuing the reactions in reverse.
	# Overflow uses reaction-only timing, not an impact scheduled for a nonexistent effect.
	for item in plan:
		if not item.event.is_empty():
			var source_actor:Node3D=disguise_actor if is_instance_valid(disguise_actor) else pet_pose
			var frozen_event:=snapshot_counter_geometry(item.event,source_actor,actor)
			delayed_combat_fx.append({"delay":float(item.launch),"event":frozen_event})
		else:
			schedule_response_text(tile,item.response,float(item.hit))
	# Queue terminal callback first; subsequent calls preserve that final pose.
	for index in range(plan.size()-1,-1,-1):
		var item:Dictionary=plan[index]
		var direction:Vector3=Vector3.ZERO
		if not item.event.is_empty():
			direction=(pos(item.event.to)-pos(item.event.from)).normalized()
		queue_enemy_reaction(actor,defeated and index==plan.size()-1,float(item.hit),direction)
	if linked:queue_enemy_reaction(actor,false,float(spec.delay),Vector3(spec.direction),float(spec.span),int(spec.count),actual_times)

func refresh_actors():
	response_slots.clear()
	if run.visual_turn_damage_turn==run.turns and (enemy_event_floor!=run.floor_revision or enemy_event_turn!=run.turns):
		var immediate_serial:int=run.attack_serial if run.attack_serial!=previous_attack and run.visual_response_cast_serial==run.attack_serial else -1
		response_slots=global_counter_slots(visible_counter_responses(),immediate_serial,response_cast_available_at()+.04,maxi(0,DELAYED_COMBAT_FX_CAP-delayed_combat_fx.size()))
	for key in actor_nodes.keys():
		if not is_instance_valid(actor_nodes[key]) or actor_nodes[key].is_queued_for_deletion():actor_nodes.erase(key)
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
		var uid:int=int(enemy.get("uid",-1))
		var fresh_response:bool=run.visual_turn_damage_turn==run.turns and (enemy_event_floor!=run.floor_revision or enemy_event_turn!=run.turns) and run.visual_turn_damage.has(uid)
		if int(enemy.hp)<int(root.get_meta("enemy_hp",enemy.hp)) or fresh_response:
			queue_observed_enemy_damage(root,uid,p,false)
		root.set_meta("enemy_hp",int(enemy.hp))
		root.set_meta("native_hp_ratio",clampf(float(enemy.hp)/maxf(1.0,float(enemy.get("max_hp",enemy.hp))),0.0,1.0))
		root.set_meta("native_alert",bool(enemy.get("windup",false)))
		var bar=root.get_node("HP") as Node3D
		bar.scale.x=.72*clampf(float(enemy.hp)/float(enemy.get("max_hp",enemy.hp)),0,1)
		root.get_node("Warning").visible=enemy.get("windup",false)
		var status_label:=root.get_node_or_null("Status") as Label3D
		if status_label==null:
			status_label=Label3D.new();status_label.name="Status";status_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
			status_label.font_size=28;status_label.outline_size=6;status_label.pixel_size=.006
			status_label.position=Vector3(0,2.15 if kind==3 else 1.68,0);root.add_child(status_label)
		status_label.text=run.enemy_status_text(enemy);status_label.visible=not status_label.text.is_empty()
		root.set_meta("living_statuses", living_enemy_statuses(enemy))
	for a in run.allies:
		if int(a.hp)<=0 or not run.revealed.has(a.pos):continue
		var key="ally:"+str(a.uid);desired[key]=true
		var root=actor_for(key,pos(a.pos))
		root.set_meta("target",pos(a.pos))
		if root.get_child_count()==0:
			attach_enemy_pixel(root,str(a.species))
			shape(root,"ring",Vector3(0,.06,0),Vector3(.72,.08,.72),Color("#76ffdc"))
			var label:=Label3D.new();label.name="AllyHP";label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.font_size=28;label.pixel_size=.006;label.position=Vector3(0,1.65,0);root.add_child(label)
		var label:=root.get_node("AllyHP") as Label3D
		label.text="%d/%d"%[a.hp,a.max_hp]
		root.set_meta("native_hp_ratio",clampf(float(a.hp)/maxf(1.0,float(a.max_hp)),0.0,1.0))
	for p in run.player_traps:
		if not run.revealed.has(p) or not run.revealed_player_traps.has(p):continue
		var key="owntrap:"+str(p);desired[key]=true
		if not actor_nodes.has(key):
			var color:=Color("#af72df") if run.player_traps[p]=="toxic" else Color("#d5b16c") if run.player_traps[p]=="rock" else Color("#6accc0")
			shape(actor_for(key,pos(p)),"ring",Vector3(0,.05,0),Vector3(.55,.07,.55),color)
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
					if str(n.get_meta("enemy_phase"))!="defeat" and not n.get_meta("pending_defeat",false):
						var uid:int=int(key.trim_prefix("enemy:"))
						var last_target:Vector3=n.get_meta("target",n.position)
						var cell:=Vector2i(roundi(last_target.x/1.4),roundi(last_target.z/1.4))
						queue_observed_enemy_damage(n,uid,cell,true)
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
func bind_attack_gesture(b:Button,move:Dictionary,action:Callable,is_dev:bool=false)->void:
	# Native button activation (keyboard/accessibility or programmatic press) remains valid.
	# A captured pointer release is dispatched separately and must not cast twice.
	b.pressed.connect(func():
		if not hold_active and not hold_release_pending and not notified and not run.finished:action.call())
	# Godot emulates mouse from touch on Android. Capture the release globally so a drag may leave the button.
	b.gui_input.connect(func(event:InputEvent):
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and not b.disabled and not hold_active and not hold_release_pending and not tile_cast_active():
			hold_active=true;hold_visible=false;hold_age=0.0;hold_origin=b.get_global_transform_with_canvas()*event.position;hold_move=move;hold_action=action;hold_is_dev=is_dev;path.clear())

func held_attack_description(m:Dictionary)->String:
	var pattern:String=str(m.get("pattern","front"));var reach:int=int(m.get("reach",1))
	var range_name:String="Self" if pattern=="self" else "Entire room" if pattern=="room" else "Entire floor" if pattern=="floor" else "Close / upfront" if reach<=1 else "Mid range" if reach<=3 else ("Long range projectile" if pattern=="line" else "Long range")
	var details:String="%s · %s / %s\n%s · %s · %d tiles\nPower %s · PP %s · ACC %s/%s"%[m.get("name","Move"),str(m.get("type","normal")).capitalize(),str(m.get("category","physical")).capitalize(),range_name,str(m.get("reference_range",pattern)).replace("_"," "),reach,str(m.get("power","—")),str(m.get("pp","—")),lab_accuracy(m.get("acc1")),lab_accuracy(m.get("acc2"))]
	if m.has("what_it_does"):details+="\n"+str(m.what_it_does)+"\n"+str(m.condition_text)
	for key in ["reference_crit","reference_strikes","charge_phase","special_rule","status","secondary_status","boon_kind","shield_kind","recoil","drain","weather_required"]:
		if m.has(key):details+=" · "+str(key).replace("_"," ")+": "+str(m[key]).replace("_"," ")
	return details

func show_held_attack()->void:
	if hold_visible:return
	hold_visible=true
	if hold_is_dev:
		dev_detail.text=held_attack_description(hold_move);dev_detail.show()
	else:
		hold_info.text=held_attack_description(hold_move);hold_info.show()

func _input(event:InputEvent)->void:
	if not hold_active:return
	if event is InputEventMouseMotion:
		var delta:Vector2=event.position-hold_origin
		if delta.length()>18.0:
			show_held_attack();facing=Rules.aim8(delta);update_hud();lab_update_aim()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		var action:=hold_action
		hold_active=false;hold_visible=false;hold_move={};hold_release_pending=true
		if is_instance_valid(hold_info):hold_info.hide()
		if hold_is_dev and is_instance_valid(dev_detail):dev_detail.visible=dev_info_mode
		if is_instance_valid(aim_preview):aim_preview.queue_redraw()
		# Allow the GUI to see release so BaseButton clears its pressed state.
		finish_attack_release.call_deferred(action)

func finish_attack_release(action:Callable)->void:
	if not hold_release_pending:return
	hold_release_pending=false
	if action.is_valid() and not notified and not run.finished and not tile_cast_active():action.call()

func draw_aim_preview()->void:
	if not hold_active or not hold_visible or not is_instance_valid(camera) or viewport.size.x<=0 or viewport.size.y<=0:return
	var footprint:Dictionary=run.attack_footprint(run.player,facing,str(hold_move.get("pattern","front")),int(hold_move.get("reach",1)),true)
	var ratio:=area.size/Vector2(viewport.size)
	for tile in footprint:
		var p:=camera.unproject_position(pos(tile)+Vector3(0,.12,0))*ratio
		aim_preview.draw_circle(p,8.0,Color("#aaffb766"));aim_preview.draw_arc(p,9.0,0,TAU,16,Color("#e2ffbf"),2.0)
	var start:=camera.unproject_position(pos(run.player)+Vector3(0,.18,0))*ratio
	var end:=camera.unproject_position(pos(run.player+facing)+Vector3(0,.18,0))*ratio
	aim_preview.draw_line(start,end,Color("#ffe49a"),3.0,true)
	var unit:Vector2=(end-start).normalized()
	aim_preview.draw_line(end,end-unit.rotated(.55)*13.0,Color("#ffe49a"),3.0,true)
	aim_preview.draw_line(end,end-unit.rotated(-.55)*13.0,Color("#ffe49a"),3.0,true)

func rotate_combat_aim()->void:
	path.clear()
	facing=Rules.DIR8[posmod(Rules.DIR8.find(facing)+1,8)]
	lab_update_aim()
	update_hud()
func touch(event:InputEvent):
	if notified or run.finished or tile_cast_active():return
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
		facing=Rules.aim8(Vector2(delta))
		path.clear()
		if target-run.player in Rules.DIR8:run.attack(false,facing)
		sync();return
	path=run.route(run.player,target,true,true)
	tick=0.0
# Charge presentation is driven by the actual turn state; no extra gameplay delay.
func charge_visual_sample(phase:String,releasing:bool,progress:float,impact:float)->Dictionary:
	var t:float=clampf(progress,0.0,1.0)
	var peak:float=clampf(impact,.12,.88)
	var y:float=0.0
	var visible:bool=true
	if not releasing:
		visible=not phase in ["underground","vanish"]
		y=.95 if phase=="airborne" else .04 if phase=="gather" else 0.0
	else:
		match phase:
			"airborne":y=.95*(1.0-smoothstep(0.0,peak,t))
			"underground":
				visible=t>=peak*.55
				y=-.28*(1.0-smoothstep(peak*.55,peak,t)) if visible else 0.0
			"vanish":visible=t>=peak*.55
			"gather":y=.04*(1.0-smoothstep(0.0,peak,t))
	return {"visible":visible,"height":y}

# Presentation priority only; no logical turns, pauses or RNG calls.
func interaction_profile(kind:String)->Dictionary:
	match kind:
		"guardian_seen":return {"priority":5,"duration":.85,"color":Color("#ffad73"),"mode":"alert"}
		"guardian_win","relic":return {"priority":6,"duration":.85,"color":Color("#ffe09b"),"mode":"victory"}
		"eat","spring","trail_fruit":return {"priority":4,"duration":.72,"color":Color("#9af2a3"),"mode":"eat" if kind!="spring" else "heal"}
		"manual":return {"priority":3,"duration":.65,"color":Color("#b7b3ff"),"mode":"treasure"}
		"ward_band","force_band","material":return {"priority":3,"duration":.65,"color":Color("#a2e8ff"),"mode":"treasure"}
		"coin","potion":return {"priority":2,"duration":.55,"color":Color("#ffe5a0") if kind=="coin" else Color("#ffb8a0"),"mode":"treasure"}
		"enemy_win":return {"priority":2,"duration":.55,"color":Color("#ffe5a0"),"mode":"victory"}
		_:return {"priority":1,"duration":.38,"color":Color("#fff0cb"),"mode":"alert"}

func begin_interaction(kind:String,cell:Vector2i)->void:
	var profile:=interaction_profile(kind)
	if reward_age>0.0 and int(profile.priority)<interaction_priority:return
	interaction_kind=kind;interaction_priority=int(profile.priority)
	interaction_duration=float(profile.duration);reward_age=interaction_duration
	reward_fx.position=pos(cell);reward_fx.show()
	if is_instance_valid(interaction_material):interaction_material.albedo_color=profile.color

func sync_creature_discoveries()->void:
	var nearest:Dictionary={}
	var best_distance:float=INF
	for enemy in run.enemies:
		var uid:int=int(enemy.get("uid",-1))
		if uid<0 or seen_creatures.has(uid) or not run.revealed.has(enemy.pos):continue
		seen_creatures[uid]=true
		var distance:float=Vector2(run.player-enemy.pos).length()
		if int(enemy.kind)==3:
			nearest=enemy;best_distance=-1.0
		elif distance<best_distance:
			nearest=enemy;best_distance=distance
	if not nearest.is_empty():
		begin_interaction("guardian_seen" if int(nearest.kind)==3 else "enemy_seen",nearest.pos)

func sync():
	run.dev_refill()
	if run.floor_revision!=active_floor:build_floor()
	else:refresh_actors()
	update_hud()
	var next_charge:String=run.charge_phase
	if next_charge!=visual_charge_phase:
		release_charge_phase=visual_charge_phase if next_charge.is_empty() and run.attack_serial!=previous_attack else ""
		visual_charge_phase=next_charge
		if not next_charge.is_empty():
			# Cancel any older visible swing when a fresh charge starts.
			attack_time=0.0;player_impact_delay=0.0;player_tile_cast.clear()
	if run.attack_serial!=previous_attack:
		previous_attack=run.attack_serial
		var event:Dictionary={"fx":run.player_attack_fx,"from":run.player,"to":run.attack_target,"tiles":run.player_attack_cells,"path":run.player_attack_path}
		if run.player_cast_result_serial==run.attack_serial:event["results"]=run.player_cast_results.duplicate(true)
		begin_player_cast_pose(event)
		combat_fx_spawn(event)
	if run.hp<hp_previous and run.enemy_actions.is_empty():hit_time=.24
	hp_previous=run.hp
	if previous_event!=run.event_serial:
		previous_event=run.event_serial;feedback.text=run.last_event;feedback_time=1.0;feedback.show()
		feedback.size=Vector2(area.size.x,42);feedback.position=Vector2(0,area.size.y*.29)
	# Consume typed events even when another event overwrites the feedback text.
	sync_creature_discoveries()
	for interaction in run.visual_interactions:
		if int(interaction.floor)==run.floor_revision:begin_interaction(str(interaction.kind),interaction.cell)
	run.visual_interactions.clear()
	if run.finished and not notified:
		notified=true
		# Deferred settlement prevents destroying/rebuilding the UI inside a button callback.
		call_deferred("emit_result")
func emit_result():
	if run.dev_sandbox:canceled.emit();return
	ended.emit(run.success,run.floor_count if run.success else run.floor_number-1,maxf(2.0,elapsed))
func update_hud():
	title_text.text="%s · B%d / ∞"%[Data.REGIONS[region],run.floor_number] if run.dev_sandbox else "%s  ·  B%d/%d"%[Data.REGIONS[region],run.floor_number,run.floor_count]
	hp_bar.value=run.hp
	hp_text.text="HP ∞ · DEV" if run.dev_sandbox else "HP %d/%d"%[run.hp,run.max_hp]
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
	if run.stockpile_count>0:status_text.text+=" · Reserve %d/3"%run.stockpile_count
	if not run.temporary_type.is_empty() or not run.adaptive_type.is_empty():status_text.text+=" · "+str(run.current_player_types()[0]).capitalize()
	if run.player_slow_turns>0:status_text.text+=" · Slowed"
	if is_instance_valid(aim_button):aim_button.text="Aim "+["↑","↗","→","↘","↓","↙","←","↖"][maxi(0,Rules.DIR8.find(facing))]
	if is_instance_valid(special_button):special_button.disabled=run.energy<2
	for i in range(move_buttons.size()):
		var id:String=run.equipped_moves[i]
		var move:Dictionary=Rules.MOVE_LIBRARY[id]
		move_buttons[i].text="%s · %d/%d"%[move.name,run.move_pp[id],move.pp]
		if id==run.charged_move_id:move_buttons[i].text="Release "+str(move.name)
		move_buttons[i].disabled=not run.charged_move_id.is_empty() and id!=run.charged_move_id or (run.charged_move_id.is_empty() and int(run.move_pp[id])<=0)
	power_button.text="%s %d/8"%[["Burst","Bolt","Drain"][run.skill_kind],run.energy];power_button.disabled=run.energy<2
	heal_button.text="Berry ∞" if run.dev_sandbox else "Berry ×%d"%run.potions;heal_button.disabled=run.potions==0 or run.hp==run.max_hp
	stairs_button.text="Descend ›" if run.dev_sandbox or run.floor_number<run.floor_count else "Complete expedition"
	stairs_button.disabled=not run.secured or run.player!=run.stairs
	stairs_button.visible=run.secured and run.player==run.stairs
	map.queue_redraw()
# The disguise inherits the companion's movement and impact clock. The
# enemy sprite renderer supplies appearance only, never a second lunge.
func sync_disguise_pose(actor:Node3D,pose:String,motion:Vector2)->bool:
	actor.set_meta("companion_disguise",true)
	actor.set_meta("enemy_facing",PixelArt.direction8_for(motion,int(actor.get_meta("enemy_facing",0))))
	if pose=="attack":
		actor.set_meta("enemy_phase","attack")
		actor.set_meta("enemy_duration",player_cast_duration)
		actor.set_meta("enemy_clock",clampf(player_cast_duration-attack_time,0.0,player_cast_duration))
		actor.set_meta("enemy_cast_impact",player_cast_impact)
		actor.set_meta("enemy_cast_waves",player_cast_waves)
		actor.set_meta("enemy_cast_motion",player_cast_motion)
		return true
	if pose=="hurt":
		actor.set_meta("enemy_phase","hurt")
		actor.set_meta("enemy_duration",.24)
		actor.set_meta("enemy_clock",clampf(.24-hit_time,0.0,.24))
		return true
	if str(actor.get_meta("enemy_phase","idle")) not in ["idle","walk"]:
		enemy_pose(actor,"idle",0.0,motion)
	return false

# Dedicated pooled form-change effect; independent from reward and attack FX.
func setup_form_effects()->void:
	form_sparks.clear()
	form_root=Node3D.new();pet.add_child(form_root);form_root.hide()
	form_material=StandardMaterial3D.new()
	form_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	form_material.albedo_color=Color("#c6c4ff")
	form_material.emission_enabled=true;form_material.emission=Color("#a3baff");form_material.emission_energy_multiplier=.6
	for i in range(16):
		var spark:=shape(form_root,"gem",Vector3.ZERO,Vector3.ONE*.06,Color("#c6c4ff"))
		spark.material_override=form_material;spark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		form_sparks.append(spark)
	form_ring=shape(form_root,"ring",Vector3(0,.065,0),Vector3.ONE,Color("#c6c4ff"))
	form_ring.material_override=form_material;form_ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	form_light=OmniLight3D.new();form_light.light_color=Color("#b6c8ff");form_light.omni_range=2.5;form_light.shadow_enabled=false
	form_root.add_child(form_light);form_light.position.y=.8;form_light.light_energy=0.0

func form_effect_sample(t:float)->Vector3:
	var progress:float=clampf(t,0.0,1.0)
	var peak:float=sin(progress*PI)
	var radius:float=lerpf(.85,.13,smoothstep(0.0,.42,progress)) if progress<.42 else lerpf(.13,1.05,smoothstep(.42,1.0,progress))
	return Vector3(radius,peak,sin(progress*TAU))

func update_form_effect(dt:float,pose:String)->void:
	if not is_instance_valid(form_root):return
	form_age=maxf(0.0,form_age-dt)
	var visible_now:bool=form_age>0.0 and not tile_cast_active() and not run.charge_phase in ["underground","vanish"] and (pet_pose.visible or (is_instance_valid(disguise_actor) and disguise_actor.visible))
	form_root.visible=visible_now
	if not visible_now:
		form_light.light_energy=0.0
		return
	var t:float=1.0-form_age/.72
	var sample:=form_effect_sample(t)
	var at:Vector3=disguise_actor.position if is_instance_valid(disguise_actor) else pet_pose.position
	form_root.position=at
	var ring_radius:float=.35+sample.x
	form_ring.scale=Vector3(ring_radius,.055,ring_radius)
	form_light.light_energy=sample.y*.65
	for i in range(form_sparks.size()):
		var a:float=float(i)*TAU/form_sparks.size()+t*TAU*1.25
		var h:float=.22+float(i%4)*.21+sample.y*.38
		var spark:=form_sparks[i]
		spark.position=Vector3(cos(a)*sample.x,h,sin(a)*sample.x)
		spark.scale=Vector3(.055,.12,.055)*sample.y
		spark.rotation.y=a
	# Strike and hurt silhouettes retain priority. Only the glow is shared.
	if pose in ["idle","reward","eat"] and not tile_cast_active():
		var active:Sprite3D=disguise_actor.get_node_or_null("EnemyPixel") as Sprite3D if is_instance_valid(disguise_actor) else pet_pose.get_node_or_null("PixelCompanion") as Sprite3D
		if active!=null:
			if active.material_override is ShaderMaterial:
				var shader:=active.material_override as ShaderMaterial
				set_fx_uniform(shader,"hit_flash",sample.y*.80)
			else:active.modulate=active.modulate.lerp(Color("#e1edff"),sample.y*.70)

func update_disguise(dt:float,motion:Vector2,moving:bool,pose:String)->void:
	var desired:String=run.transformed_species
	if desired!=disguise_species:
		form_age=.72
		if is_instance_valid(disguise_actor):
			disguise_actor.hide();disguise_actor.queue_free()
		disguise_actor=null;disguise_species=desired
		if not desired.is_empty():
			var actor:=Node3D.new()
			pet.add_child(actor)
			if attach_enemy_pixel(actor,desired):
				disguise_actor=actor
				actor.set_meta("companion_disguise",true)
			else:actor.queue_free()
	if not is_instance_valid(disguise_actor):return
	disguise_actor.visible=pet_pose.visible
	pet_pose.hide()
	disguise_actor.position=pet_pose.position
	if pose=="eat" and not moving:
		var chew:float=sin((1.0-reward_age/maxf(.01,interaction_duration))*TAU*5.0)*.035
		disguise_actor.position.y+=absf(chew)
	if pose=="reward" and not moving:
		# Transformed companions share the celebration, not a second attack pose.
		var celebration:float=clampf(1.0-reward_age/maxf(.01,interaction_duration),0.0,1.0)
		disguise_actor.position.y+=absf(sin(celebration*TAU))*sin(celebration*PI)*.20
	disguise_actor.rotation.z=pet_pose.rotation.z
	disguise_actor.set_meta("living_statuses",living_player_statuses())
	disguise_actor.set_meta("native_hp_ratio",clampf(float(run.hp)/maxf(1.0,float(run.max_hp)),0.0,1.0))
	disguise_actor.set_meta("enemy_facing",PixelArt.direction8_for(motion,int(disguise_actor.get_meta("enemy_facing",0))))
	var synchronized:bool=sync_disguise_pose(disguise_actor,pose,motion)
	update_enemy_pixel(disguise_actor,0.0 if synchronized else dt,Vector3(motion.x,0,motion.y) if moving else Vector3.ZERO,dt)

func advance_player_combat_clock(dt:float)->void:
	attack_time=maxf(0.0,attack_time-dt)
	if attack_time<=0.0 and not player_tile_cast.is_empty():finish_tile_cast()
	hit_time=maxf(0.0,hit_time-dt)
	player_impact_delay=maxf(0.0,player_impact_delay-dt)

func _process(dt:float):
	if notified or not is_instance_valid(pet):return
	if OS.has_feature("mobile"):update_fx_performance(dt)
	elapsed+=dt;tick-=dt
	if hold_active:
		hold_age+=dt
		if hold_age>=.28:show_held_attack()
		if hold_visible and is_instance_valid(aim_preview):aim_preview.queue_redraw()
	combat_fx_update(dt)
	# Advance existing clocks before path movement can launch a new action.
	# A cast created by sync() later in this frame starts at age zero.
	advance_player_combat_clock(dt)
	update_living_ambient(dt)
	update_exterior_world(dt)
	if reward_age>0.0:
		reward_age=maxf(0.0,reward_age-dt)
		var progress:float=1.0-reward_age/maxf(.01,interaction_duration)
		var mode:String=str(interaction_profile(interaction_kind).mode)
		for i in range(reward_pool.size()):
			var spark:=reward_pool[i]
			var angle:float=float(i)*TAU/reward_pool.size()+progress*.6
			var radius:float=.25+progress*.9
			var height:float=.22+sin(progress*PI)*.9
			match mode:
				"alert":
					radius=.38+progress*.62;height=.12
				"eat","heal":
					radius=.48*(1.0-progress*.65);height=.24+progress*1.0+float(i%3)*.08
				"treasure":
					radius=.18+progress*.50;height=.28+sin(progress*PI)*.66+float(i%3)*.08
				"victory":
					radius=.25+progress*.9;height=.22+sin(progress*PI)*.9
			spark.position=Vector3(cos(angle)*radius,height,sin(angle)*radius)
			spark.scale=Vector3(.065,.15,.065)*(1.0-progress*.85)
		reward_fx.visible=reward_age>0.0
		if reward_age<=0.0:interaction_priority=0;interaction_kind=""
	banner_time=maxf(0.0,banner_time-dt)
	floor_banner.visible=banner_time>0.0
	if floor_banner.visible:
		floor_banner.size=Vector2(area.size.x,45);floor_banner.position=Vector2(0,area.size.y*.12);floor_banner.modulate.a=minf(1.0,banner_time*3.0)
	feedback_time=maxf(0.0,feedback_time-dt)
	feedback.visible=feedback_time>0.0
	if feedback.visible:
		feedback.size=Vector2(area.size.x,42);feedback.position=Vector2(0,area.size.y*.29-(1.0-feedback_time)*24.0);feedback.modulate.a=minf(1.0,feedback_time*4.0)
	for key in actor_nodes.keys():
		var n=actor_nodes[key]
		if not is_instance_valid(n) or n.is_queued_for_deletion():
			actor_nodes.erase(key);continue
		if n.has_meta("target"):
			var target_position:Vector3=n.get_meta("target")
			var delta_position:Vector3=target_position-n.position
			n.position=n.position.lerp(target_position,1.0-exp(-dt*15.0))
			update_enemy_pixel(n,dt,delta_position)
		elif n.has_meta("float_item"):
			n.position.y=.12+.07*sin(elapsed*4.0+n.position.x);n.rotation.y=elapsed*1.8
	if tick<=0 and not path.is_empty() and not run.finished and not tile_cast_active():
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
	var moving:bool=travel.length()>.045
	# Logical movement direction takes priority over residual smoothing from a
	# previous turn, avoiding backwards-facing sprites at corridor corners.
	var motion:=Vector2(facing)
	if motion.length_squared()<.0001 and moving:motion=Vector2(travel.x,travel.z)
	pet_pose.position=Vector3.ZERO
	pet_pose.rotation.z=0.0
	var charge_progress:float=1.0-attack_time/maxf(.01,player_cast_duration)
	var releasing:bool=attack_time>0.0 and not release_charge_phase.is_empty()
	var charge:Dictionary=charge_visual_sample(release_charge_phase if releasing else run.charge_phase,releasing,charge_progress,player_cast_impact)
	pet_pose.visible=bool(charge.visible)
	pet_pose.position.y=float(charge.height)
	if not releasing and run.charge_phase=="airborne":pet_pose.position.y+=sin(elapsed*8.0)*.06
	elif not releasing and run.charge_phase=="gather":pet_pose.position.y+=.025*sin(elapsed*12.0)
	if attack_time<=0.0:release_charge_phase=""
	if attack_time>0.0:
		var phase=sin(PI*attack_time/maxf(.01,player_cast_duration))
		var progress:float=1.0-attack_time/maxf(.01,player_cast_duration)
		var body_progress:float=caster_wave_progress(progress*player_cast_duration,player_cast_duration,player_cast_impact,player_cast_waves)
		var cast_offset:=PixelArt.creature_cast_offset(cast_motion_offset(player_cast_motion,body_progress,player_cast_impact),run.transformed_species)
		if releasing and release_charge_phase=="airborne":cast_offset.y=0.0
		pet_pose.position+=pet.basis.inverse()*cast_offset_world(cast_offset,attack_direction)
		attack_fx.visible=player_impact_delay<=0.0;attack_fx.scale=Vector3(1.1-phase*.42,.13,1.1-phase*.42)
	else:attack_fx.hide()
	if hit_time>0.0:
		var reaction:=creature_hit_sample(1.0-hit_time/.24,run.transformed_species)
		var side:=Vector3(-player_hit_direction.z,0.0,player_hit_direction.x)
		pet_pose.rotation.z+=float(reaction.tilt)
		pet_pose.position+=pet.basis.inverse()*(player_hit_direction*.32*float(reaction.recoil)+side*float(reaction.sway))
		pet_pose.position.y+=float(reaction.lift)
	if attack_time>0.0:motion=Vector2(attack_direction.x,attack_direction.z)
	if tile_cast_active():
		var travel_pose:=tile_cast_sample(player_tile_cast.points,str(player_tile_cast.kind),charge_progress,player_cast_impact,release_charge_phase=="airborne")
		pet_pose.position=pet.basis.inverse()*(Vector3(travel_pose.position)-pet.position)
		pet_pose.visible=bool(travel_pose.visible)
		var heading:Vector3=travel_pose.motion
		motion=Vector2(heading.x,heading.z)
		moving=bool(travel_pose.returning)
	var interaction_mode:String=str(interaction_profile(interaction_kind).mode) if reward_age>0.0 else ""
	var expression_pose:String="eat" if interaction_mode=="eat" else "reward" if interaction_mode in ["treasure","victory","heal"] else "idle"
	var pose:String="hurt" if hit_time>0.0 else "attack" if attack_time>0.0 else expression_pose if not moving and run.charge_phase.is_empty() else "idle"
	if tile_cast_active() and charge_progress>player_cast_impact+.08:pose="walk"
	var player_statuses:Array=living_player_statuses()
	# Sleep outranks noncombat celebration/eating; never hide a real attack or hit.
	var can_rest:bool=pose in ["idle","reward","eat"] and not moving and not tile_cast_active() and run.charge_phase.is_empty()
	var player_living:=living_body_sample(pet,player_statuses,dt,can_rest)
	if can_rest and ("sleep" in player_statuses or float(player_living.sleep)>.55):pose="sleep"
	pet_pose.set_meta("pet_mood",PixelArt.dungeon_mood(run.hp,run.max_hp,run.poison_turns>0,pose=="reward"))
	pet_pose.set_meta("dungeon_grounded_gait",true)
	pet_pose.set_meta("dungeon_cast_motion",player_cast_motion)
	pet_pose.set_meta("dungeon_cast_species",run.transformed_species)
	PixelArt.animate_world_sprite(pet_pose,motion,moving,dt,pose,region==1,caster_wave_progress(player_cast_duration-attack_time,player_cast_duration,player_cast_impact,player_cast_waves) if attack_time>0.0 else -1.0,player_cast_impact)
	if pose=="hurt":
		var companion_sprite:=pet_pose.get_node_or_null("PixelCompanion") as Sprite3D
		if companion_sprite!=null:
			var sample:=creature_hit_sample(1.0-hit_time/.24,run.transformed_species)
			var squash:float=float(sample.squash)
			companion_sprite.scale=Vector3(1.0/squash,squash,1.0)
			companion_sprite.position.y=float(companion_sprite.get_meta("world_height"))*.5*squash
			companion_sprite.modulate=Color.WHITE.lerp(Color("#ffc5bc"),float(sample.flash))
	if pose in ["idle","sleep"] and not moving and bool(player_living.active):
		var resting_sprite:=pet_pose.get_node_or_null("PixelCompanion") as Sprite3D
		if resting_sprite!=null:
			var stretch:float=float(player_living.stretch)
			resting_sprite.scale=Vector3(float(player_living.width),stretch,1.0)
			resting_sprite.position.y=float(resting_sprite.get_meta("world_height"))*.5*stretch
			resting_sprite.position.x=float(player_living.sway)
			resting_sprite.modulate=Color.WHITE.lerp(player_living.tint,float(player_living.tint_weight))
	else:
		var active_sprite:=pet_pose.get_node_or_null("PixelCompanion") as Sprite3D
		if active_sprite!=null:active_sprite.position.x=0.0
	var condition:=creature_condition_sample(pet,clampf(float(run.hp)/maxf(1.0,float(run.max_hp)),0.0,1.0),dt,true)
	if pose=="idle" and not bool(player_living.active) and not tile_cast_active():
		var healthy_sprite:=pet_pose.get_node_or_null("PixelCompanion") as Sprite3D
		if healthy_sprite!=null:
			var prior_scale:float=healthy_sprite.scale.y
			healthy_sprite.scale.x/=condition.x
			healthy_sprite.scale.y*=condition.x
			healthy_sprite.position.y+=float(healthy_sprite.get_meta("world_height"))*.5*(healthy_sprite.scale.y-prior_scale)
			healthy_sprite.position.x+=condition.y
	update_disguise(dt,motion,moving,pose)
	var companion_shadow:=pet.get_node_or_null("EnemyContactShadow") as MeshInstance3D
	if companion_shadow!=null:
		var shadow_sample:=enemy_shadow_sample(pet_pose.position,0.0,0.0,1.0,false)
		companion_shadow.position=shadow_sample.position
		companion_shadow.scale=shadow_sample.scale
		companion_shadow.visible=pet_pose.visible and not is_instance_valid(disguise_actor)
	update_form_effect(dt,pose)
	var focus=pet.position+Vector3(0,.18,-.48)
	# The prior floor-build-only shake never reached the actual render loop.
	var shake:float=minf(fx_ground_shake,.10)
	var contact_shift:Vector3=fx_contact_camera*contact_camera_sample(fx_contact_camera_age/.18)
	camera.position=focus+DUNGEON_CAMERA_OFFSET+Vector3(sin(elapsed*61.0)*shake,0,cos(elapsed*73.0)*shake*.45)+contact_shift
	camera.look_at(focus+contact_shift)
