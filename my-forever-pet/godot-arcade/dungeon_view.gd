extends Control
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
var actor_nodes:Dictionary={}
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
var exterior_max_height=0.0
var exterior_groups:Array[Vector2i]=[]
var exterior_vistas:Array[Vector2i]=[]
var habitat_tall:Array[Vector2i]=[]
var habitat_large:Array[Vector2i]=[]
var vista_large:Array[Vector2i]=[]
var scenic_bounds:Array[AABB]=[]
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
func setup(r:int,id:int,step:int,finale:bool,patrol:bool,seed_id:int,companion:int):
	region=r;companion_id=companion
	run.setup(r,id,step,finale,patrol,seed_id,companion)
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
	if ResourceLoader.exists(portrait_path):portrait.texture=load(portrait_path)
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
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.keep_aspect=Camera3D.KEEP_WIDTH;camera.size=10.4;world.add_child(camera);camera.current=true
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
	attack_button=button(a,"Strike",func():path.clear();run.attack();sync(),true)
	power_button=button(a,"Skill",func():path.clear();run.attack(true);sync())
	heal_button=button(a,"Berry",func():path.clear();run.heal();sync())
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
				var patch=smoothstep(-.28,.38,h)
				var grain=.5+.5*sin(u*TAU*19.0+sin(w*TAU*13.0)*2.0)
				color=Color(.69,.64,.49).lerp(Color(.75,.80,.58),patch)
				color=color.darkened(grain*.035)
				var leaf=smoothstep(.89,.99,sin(u*TAU*8.0+w*TAU*11.0+sin(w*TAU*7.0)*2.0))
				color=color.lerp(Color(.79,.56,.25),leaf*.14)
				relief=h*.09+grain*.009
			elif region==1:
				# Seabed sandstone: crossing ripples and light caustics, no masonry.
				var ripple=sin(w*TAU*7.0+sin(u*TAU*2.0)*1.45)
				var wave=sin((u+w)*TAU*3.0+sin(w*TAU*2.0))
				var caustic=pow(1.0-absf(wave),7.0)
				color=Color(.54,.69,.72).lerp(Color(.80,.94,.91),clampf(.55+h*.85+ripple*.13,0.0,1.0))
				color=color.lightened(caustic*.09)
				relief=h*.09+ripple*.032
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
	for y in range(size_px):
		for x in range(size_px):
			var dx=heights[y*size_px+posmod(x+1,size_px)]-heights[y*size_px+posmod(x-1,size_px)]
			var dy=heights[posmod(y+1,size_px)*size_px+x]-heights[posmod(y-1,size_px)*size_px+x]
			var n=Vector3(-dx*2.6,-dy*2.6,1).normalized()
			normals.set_pixel(x,y,Color(n.x*.5+.5,n.y*.5+.5,n.z*.5+.5,1))
	img.generate_mipmaps();normals.generate_mipmaps()
	terrain_texture=ImageTexture.create_from_image(img);terrain_normal=ImageTexture.create_from_image(normals)
	floor_surface_signature=img.get_data().hex_encode().sha256_text()
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
	exterior_groups.clear();exterior_vistas.clear();habitat_tall.clear();habitat_large.clear();vista_large.clear();scenic_bounds.clear();habitat_low.clear();habitat_ground_candidates.clear();exterior_distances.clear();exterior_life.clear();exterior_life_parts.clear();exterior_life_centers.clear();exterior_clock=0.0
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
	# One foreground focal point per room, then additional midground clusters.
	# The 3x3 exclusion protects all traversable cells; overlap with the back
	# of wall geometry is intentional, like a continuous natural embankment.
	for room in run.rooms:
		if vista_parts.is_empty() or exterior_vistas.size()>=12:break
		var middle:Vector2i=room.get_center()
		var choices:Array[Vector2i]=[Vector2i(room.position.x-3,middle.y),Vector2i(room.end.x+2,middle.y),Vector2i(middle.x,room.position.y-3),Vector2i(middle.x,room.end.y+2),Vector2i(middle.x,room.end.y+1)]
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
			vista_placements.append(placement);scenic_bounds.append(bounds)
			exterior_vistas.append(q);exterior_groups.append(q)
			if large:vista_large.append(q)
			break
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
		var large=habitat_wide_clearance(q)
		var scale_value=(1.32+.31*float(posmod(q.x*13+q.y*7,9))/8.0) if large else (.87+.17*float(posmod(q.x*13+q.y*7,9))/8.0)
		var height_factor=1.05+.43*float(posmod(q.x*17+q.y*3,11))/10.0
		if not large:height_factor=minf(height_factor,1.28)
		var elevation=.10 if region==2 else -.42
		var center=pos(q)+Vector3(0,elevation,0)
		var placement=Transform3D(Basis(Vector3.UP,angle).scaled(Vector3(scale_value,scale_value*height_factor,scale_value)),center)
		var bounds=measure_scenery(tall_parts,placement)
		if not scenery_clear_of_floor(bounds):
			large=false
			placement=Transform3D(Basis(Vector3.UP,angle).scaled(Vector3(.88,1.10,.88)),center)
			bounds=measure_scenery(tall_parts,placement)
		if not scenery_clear_of_floor(bounds):continue
		tall_placements.append(placement);scenic_bounds.append(bounds)
		habitat_tall.append(q)
		if large:habitat_large.append(q)
	batch_exterior_parts(tall_parts,tall_placements)
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
	floor_detail_count=0
	var parts=rock_parts("res://assets/dungeon_"+["forest","reef","star"][region]+"_floor_detail.glb")
	if parts.is_empty():return
	var placements:Array[Transform3D]=[]
	for room in run.rooms:
		var used=0
		for y in range(room.position.y,room.end.y):
			for x in range(room.position.x,room.end.x):
				if used>=3:continue
				var q=Vector2i(x,y)
				if not run.cells.has(q) or q==run.player or q==run.stairs or run.loot.has(q) or run.traps.has(q):continue
				if run.enemy_at(q)>=0:continue
				var edge=x==room.position.x or x==room.end.x-1 or y==room.position.y or y==room.end.y-1
				if region!=2 and not edge and posmod(x*13+y*7,3)!=0:continue
				if posmod(x*19+y*37+run.floor_number,5)!=0:continue
				var angle=float(posmod(x*3+y*11,8))*PI*.25
				placements.append(Transform3D(Basis(Vector3.UP,angle),pos(q)+Vector3(0,.005,0)));used+=1
	batch_parts(parts,placements,false);floor_detail_count=placements.size()
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
func build_exterior_surface():
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
	var deep:Color=[Color("#253d28"),Color("#163c4c"),Color("#24243e")][region]
	var raised:Color=[Color("#57684b"),Color("#3b6d77"),Color("#5c537f")][region]
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
			if not near:
				# Broad ridges, basins and cloud valleys behind the actual scenery.
				var relief=broad.get_noise_2d(q.x,q.y)
				h-=depth_factor*(1.0-support)*([.40,1.10,2.35][region]+.48*relief)
				h+=minf(.24,depth_factor*(1.0-support)*maxf(0.0,relief)*.40)
				h=minf(h,-.35)
			heights[y*width+x]=h;exterior_max_height=maxf(exterior_max_height,h)
			vertices.append(Vector3(q.x*1.4,h,q.y*1.4));uvs.append(Vector2(q))
			var color=deep.lerp(raised,clampf(.43+n*.57,0.0,1.0))
			color=color.lerp(distant,depth_factor*.75)
			var cloud=broad.get_noise_2d(q.x,q.y)
			if region==2:color=color.lerp(Color("#8070a8"),smoothstep(-.05,.55,cloud)*depth_factor*.42)
			# Baked contact shadow under the actual authored placement centers.
			color=color.darkened(support*.18)
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
	if region==2:material.albedo_texture=null;material.normal_enabled=false
	exterior_surface.material_override=material;geometry.add_child(exterior_surface)
	exterior_surface.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	exterior_vertex_count=vertices.size()
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
	if not natural_boundary(walls):
		batch(geometry,walls,"box",Vector3(1.4,.88,1.4),palette[2],true)
		boundary_detail(walls)
	room_detail(seen)
	interior_floor_detail()
	passage_thresholds()
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
	# Creature GLBs face local -Z; initial south-facing pet should look toward camera.
	pet_pose.rotation.y=PI
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
	camera.position=focus+Vector3(0,7.6,11.3);camera.look_at(focus)
	refresh_actors()
	floor_build_usec=Time.get_ticks_usec()-start_usec
	print("DUNGEON_FLOOR_BUILD region=",region," floor=",run.floor_number," usec=",floor_build_usec," rocks=",rock_modules," cached_rock_sets=",rock_mesh_cache.size()," landmarks=",landmark_count," details=",detail_count," paired_spans=",span_count," corners=",corner_count," terraces=",terrace_count," floor_details=",floor_detail_count," thresholds=",threshold_count," exterior_vertices=",exterior_vertex_count," exterior_groups=",exterior_groups.size()," exterior_static_batches=",exterior_static_batches," exterior_life=",exterior_life_centers.size())
func actor_for(key:String,at:Vector3)->Node3D:
	if actor_nodes.has(key):return actor_nodes[key]
	var n=Node3D.new();actors.add_child(n);n.position=at;actor_nodes[key]=n;actor_created+=1
	return n
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
			var id:int=run.specimen if kind==3 else Data.POOLS[region][(kind+run.floor_number)%Data.POOLS[region].size()]
			var ob=model(root,id);ob.rotation.y=PI
			if kind==3:ob.scale*=1.45
			var height=1.9 if kind==3 else 1.42
			shape(root,"box",Vector3(0,height,0),Vector3(.75,.09,.12),Color("#212835"))
			var bar=shape(root,"box",Vector3(0,height+.015,.012),Vector3(.72,.075,.13),Color("#ee7c83"));bar.name="HP"
			var marker=shape(root,"ring",Vector3(0,.06,0),Vector3(.74,.12,.74),Color("#ffb25d"));marker.name="Warning"
		var bar=root.get_node("HP") as Node3D
		bar.scale.x=.72*clampf(float(enemy.hp)/float(enemy.get("max_hp",enemy.hp)),0,1)
		root.get_node("Warning").visible=enemy.get("windup",false)
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
			n.hide();n.queue_free();actor_nodes.erase(key)
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
	path=run.route(run.player,target,true)
	tick=0.0
func sync():
	if run.floor_revision!=active_floor:build_floor()
	else:refresh_actors()
	update_hud()
	if run.attack_serial!=previous_attack:
		previous_attack=run.attack_serial;attack_time=.28;attack_direction=(pos(run.attack_target)-pos(run.player)).normalized()
		attack_fx.position=pos(run.attack_target)+Vector3(0,.24,0);attack_fx.show()
	if run.hp<hp_previous:hit_time=.24
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
	status_text.text=run.message
	power_button.text="%s %d/8"%[["Burst","Bolt","Drain"][run.skill_kind],run.energy];power_button.disabled=run.energy<2
	heal_button.text="Berry ×%d"%run.potions;heal_button.disabled=run.potions==0 or run.hp==run.max_hp
	stairs_button.text="Descend ›" if run.floor_number<run.floor_count else "Complete expedition"
	stairs_button.disabled=not run.secured or run.player!=run.stairs
	stairs_button.visible=run.secured and run.player==run.stairs
	map.queue_redraw()
func _process(dt:float):
	if notified or not is_instance_valid(pet):return
	elapsed+=dt;tick-=dt
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
	for n in actor_nodes.values():
		if n.has_meta("target"):n.position=n.position.lerp(n.get_meta("target"),1.0-exp(-dt*15.0))
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
	pet.position=pet.position.lerp(target,1.0-exp(-dt*18.0))
	destination_fx.visible=not path.is_empty()
	if destination_fx.visible:destination_fx.position=pos(path[-1])+Vector3(0,.06,0)
	attack_time=maxf(0.0,attack_time-dt);hit_time=maxf(0.0,hit_time-dt)
	var moving=pet.position.distance_to(target)>.06
	pet_pose.position=Vector3(0,.09*absf(sin(elapsed*18.0)) if moving else .015*sin(elapsed*3.5),0)
	pet_pose.rotation.z=sin(elapsed*20.0)*.07 if moving else 0.0
	if region==1:
		pet_pose.position.y=.10+.055*sin(elapsed*5.0)
		pet_pose.rotation.z=sin(elapsed*7.0)*.045 if moving else 0.0
	if attack_time>0.0:
		var phase=sin(PI*attack_time/.28)
		pet_pose.position+=pet.basis.inverse()*attack_direction*phase*.40
		attack_fx.visible=true;attack_fx.scale=Vector3(1.1-phase*.42,.13,1.1-phase*.42)
	else:attack_fx.hide()
	if hit_time>0.0:pet_pose.rotation.z+=sin(hit_time*45.0)*.19
	if facing!=Vector2i.ZERO:pet.rotation.y=atan2(float(facing.x),float(facing.y))
	var focus=pet.position+Vector3(0,.18,-.48)
	camera.position=focus+Vector3(0,7.6,11.3);camera.look_at(focus)
