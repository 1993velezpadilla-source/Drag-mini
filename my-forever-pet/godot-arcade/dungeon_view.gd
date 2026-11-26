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
var reward_fx:Node3D
var reward_age=0.0
var reward_pool:Array[MeshInstance3D]=[]
var scene_cache:Dictionary={}
var rock_mesh_cache:Dictionary={}
var floor_build_usec=0
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
		"Berry":symbol='<circle cx="8" cy="14" r="6" fill="#f66d79"/><circle cx="16" cy="15" r="6" fill="#d83a61"/><path d="M12 10Q6 0 18 2Q19 8 12 10Z" fill="#a1df74"/>'
	var image=Image.new()
	image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24">'+symbol+'</svg>')
	return ImageTexture.create_from_image(image)
func button(parent:Node,value:String,action:Callable,accent:bool=false)->Button:
	var b=Button.new();b.text=value;b.custom_minimum_size.y=62;b.size_flags_horizontal=SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size",17)
	var action_color=Color("#315f43") if value=="Strike" else Color("#59417b") if value=="Skill" else Color("#765032") if value=="Berry" else Color("#283b4a")
	var frame=style(action_color,Color("#d6b877"),18);frame.shadow_color=Color("#090f18bb");frame.shadow_size=4;frame.shadow_offset=Vector2(0,3)
	b.add_theme_stylebox_override("normal",frame)
	b.add_theme_stylebox_override("hover",style(action_color.lightened(.14),Color("#ffe4a0"),18))
	if value in ["Strike","Skill","Berry"]:
		b.icon=action_icon(value);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",27)
	b.add_theme_stylebox_override("pressed",style(Color("#496b81"),Color("#f6e2a6")))
	b.add_theme_stylebox_override("disabled",style(Color("#202b36"),Color("#34404e")))
	b.add_theme_color_override("font_disabled_color",Color("#8393a3"))
	b.pressed.connect(action);parent.add_child(b);return b
func build_ui():
	var base=VBoxContainer.new();add_child(base);base.set_anchors_and_offsets_preset(PRESET_FULL_RECT);base.add_theme_constant_override("separation",0)
	var header=PanelContainer.new();header.add_theme_stylebox_override("panel",style(Color("#162535"),Color("#ad925d"),16));base.add_child(header)
	var h=HBoxContainer.new();header.add_child(h)
	var back=button(h,"‹",leave);back.tooltip_text="Leave expedition";back.size_flags_horizontal=SIZE_SHRINK_BEGIN;back.custom_minimum_size.x=45;back.add_theme_font_size_override("font_size",28)
	var portrait=TextureRect.new();portrait.custom_minimum_size=Vector2(72,72);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var portrait_path="res://assets/pet_%d.png"%companion_id
	if ResourceLoader.exists(portrait_path):portrait.texture=load(portrait_path)
	h.add_child(portrait)
	var info=VBoxContainer.new();info.size_flags_horizontal=SIZE_EXPAND_FILL;h.add_child(info)
	title_text=label(info,"",22,Color("#ffe1a4"))
	hp_bar=ProgressBar.new();hp_bar.max_value=run.max_hp;hp_bar.custom_minimum_size.y=19;hp_bar.show_percentage=false;info.add_child(hp_bar)
	hp_bar.add_theme_stylebox_override("fill",style(Color("#62c88b"),Color("#a4f1ba"),8))
	hp_bar.add_theme_stylebox_override("background",style(Color("#0c1723"),Color("#32465b"),6))
	stats=label(info,"",14,Color("#c7dce7"))
	floor_label=label(info,"",12,Color("#a5d8ce"))
	area=Control.new();area.size_flags_vertical=SIZE_EXPAND_FILL;area.clip_contents=true;base.add_child(area)
	var holder=SubViewportContainer.new();holder.stretch=true;holder.stretch_shrink=1;holder.mouse_filter=MOUSE_FILTER_IGNORE;area.add_child(holder);holder.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	viewport=SubViewport.new();viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;holder.add_child(viewport)
	world=Node3D.new();viewport.add_child(world)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=palette[2].darkened(.55);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("#e0edff");env.environment.ambient_light_energy=.38;world.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-35,0);sun.light_color=[Color("#fff2d4"),Color("#c0eaff"),Color("#d9d2ff")][region];sun.light_energy=.78;sun.shadow_enabled=true;world.add_child(sun)
	var fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-35,145,0);fill.light_color=palette[3];fill.light_energy=.18;fill.shadow_enabled=false;world.add_child(fill)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.keep_aspect=Camera3D.KEEP_WIDTH;camera.size=8.2;world.add_child(camera);camera.current=true
	var input=Control.new();area.add_child(input);input.set_anchors_and_offsets_preset(PRESET_FULL_RECT);input.mouse_filter=MOUSE_FILTER_STOP;input.gui_input.connect(touch)
	map=Control.new();map.mouse_filter=MOUSE_FILTER_IGNORE;area.add_child(map);map.position=Vector2(10,10);map.size=Vector2(146,112);map.draw.connect(draw_map)
	feedback=Label.new();feedback.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;feedback.add_theme_font_size_override("font_size",24);feedback.add_theme_color_override("font_outline_color",Color("#142535"));feedback.add_theme_constant_override("outline_size",7);feedback.mouse_filter=MOUSE_FILTER_IGNORE;area.add_child(feedback);feedback.hide()
	floor_banner=Label.new();floor_banner.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;floor_banner.add_theme_font_size_override("font_size",25);floor_banner.add_theme_color_override("font_outline_color",Color("#142535"));floor_banner.add_theme_constant_override("outline_size",8);floor_banner.mouse_filter=MOUSE_FILTER_IGNORE;area.add_child(floor_banner);floor_banner.hide()
	var footer=PanelContainer.new();footer.add_theme_stylebox_override("panel",style(Color("#162535"),Color("#ad925d"),18));base.add_child(footer)
	var v=VBoxContainer.new();v.add_theme_constant_override("separation",6);footer.add_child(v)
	status_text=label(v,"",16,Color("#ffe1a4"));status_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status_text.custom_minimum_size.y=22;status_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var a=HBoxContainer.new();v.add_child(a)
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
				var patch=smoothstep(-.13,.22,h)
				var grain=.5+.5*sin(u*TAU*19.0+sin(w*TAU*13.0)*2.0)
				color=Color(.55,.48,.33).lerp(Color(.71,.88,.53),patch)
				color=color.darkened(grain*.07)
				var leaf=smoothstep(.89,.99,sin(u*TAU*8.0+w*TAU*11.0+sin(w*TAU*7.0)*2.0))
				color=color.lerp(Color(.79,.56,.25),leaf*.14)
				relief=h*.15+grain*.012
			elif region==1:
				# Seabed sandstone: crossing ripples and light caustics, no masonry.
				var ripple=sin(w*TAU*7.0+sin(u*TAU*2.0)*1.45)
				var wave=sin((u+w)*TAU*3.0+sin(w*TAU*2.0))
				var caustic=pow(1.0-absf(wave),7.0)
				color=Color(.54,.69,.72).lerp(Color(.80,.94,.91),clampf(.55+h*.85+ripple*.13,0.0,1.0))
				color=color.lightened(caustic*.17)
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
func batch_parts(parts:Array,placements:Array[Transform3D],shadows:bool=true):
	if placements.is_empty():return
	for part in parts:
		var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=part.mesh;mm.instance_count=placements.size()
		for i in range(placements.size()):mm.set_instance_transform(i,placements[i]*part.transform)
		var instance=MultiMeshInstance3D.new();instance.multimesh=mm;geometry.add_child(instance)
		if not shadows:instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func natural_boundary(points:Array[Vector3])->bool:
	rock_modules=0;span_count=0
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
	var placements:Array[Transform3D]=[]
	# Pair straight wall cells that face the same open space. Do not span corridors.
	if not spans.is_empty():
		for q in available:
			if consumed.has(q):continue
			if posmod(q.x*31+q.y*17+run.floor_number,4)==0:continue
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
				placements.append(Transform3D(Basis(Vector3.UP,angle),middle))
				consumed[q]=true;consumed[other]=true;span_count+=1
				break
		batch_parts(spans,placements)
	for variant in range(3):
		var singles:Array[Transform3D]=[]
		for q in available:
			if consumed.has(q):continue
			if posmod(q.x*19+q.y*7+run.floor_number,3)!=variant:continue
			var angle=float(posmod(q.x*3+q.y*5,4))*PI*.5
			var scale_value=Vector3(1.08,.78+.27*float(posmod(q.x*13+q.y,5))/4.0,1.08)
			singles.append(Transform3D(Basis(Vector3.UP,angle).scaled(scale_value),pos(q)))
		batch_parts(variants[variant],singles)
		rock_modules+=singles.size()
	rock_modules+=span_count*2
	return rock_modules==points.size()
func backdrop_landmarks(wall_cells:Dictionary):
	landmark_count=0
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
				used.append(q);landmark_count+=1
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
func floor_name()->String:
	return ["Ancient passages","Treasure chamber","Monster den","Restorative grotto","Forgotten ruins"][run.floor_kind]
func build_floor():
	var start_usec=Time.get_ticks_usec()
	if is_instance_valid(geometry):geometry.hide();geometry.queue_free()
	if is_instance_valid(actors):actors.hide();actors.queue_free()
	geometry=Node3D.new();world.add_child(geometry);actors=Node3D.new();world.add_child(actors);actor_nodes.clear()
	var a:Array[Vector3]=[];var b:Array[Vector3]=[];var walls:Array[Vector3]=[]
	floor_ornaments.clear()
	var seen:Dictionary={}
	for p in run.cells:
		var q:Vector2i=p
		if (q.x+q.y)%2==0:a.append(pos(q)+Vector3(0,-.13,0))
		else:b.append(pos(q)+Vector3(0,-.13,0))
		if posmod(q.x*37+q.y*19+run.floor_number*13,11)==0:floor_ornaments.append(pos(q)+Vector3(0,.003,0))
		for d in Rules.DIR:
			var next:Vector2i=q+d
			if not run.cells.has(next) and not seen.has(next):
				seen[next]=true;walls.append(pos(next)+Vector3(0,.44,0))
	var ground:Color=[Color("#7b8856"),Color("#72a4b5"),Color("#77709a")][region]
	var far_ground=shape(geometry,"box",Vector3(25,-.77,20),Vector3(88,.35,78),palette[2].darkened(.15))
	far_ground.material_override=mat(palette[2].darkened(.15));far_ground.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	batch(geometry,a,"box",Vector3(1.40,.24,1.40),ground,true);batch(geometry,b,"box",Vector3(1.40,.24,1.40),ground.lightened(.025),true)
	# Dark foundation closes small rock gaps; the visible silhouette comes from sculpted Blender modules.
	var foundation:Array[Vector3]=[]
	for p in walls:foundation.append(p-Vector3(0,.28,0))
	batch(geometry,foundation,"box",Vector3(1.4,.38,1.4),palette[2],true)
	wall_decorations=0
	var scenery_points:Array[Vector3]=[]
	var scenery_seen:Dictionary={}
	for cell in seen:
		for direction in Rules.DIR:
			var q:Vector2i=cell+direction
			if run.cells.has(q) or seen.has(q) or scenery_seen.has(q):continue
			scenery_seen[q]=true
			if posmod(q.x*17+q.y*31+run.floor_number,4)==0:
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
	if not natural_boundary(walls):
		batch(geometry,walls,"box",Vector3(1.4,.88,1.4),palette[2],true)
		boundary_detail(walls)
	room_detail(seen)
	var dais=prop(geometry,"dungeon_"+["forest","reef","star"][region]+"_dais",pos(run.relic)+Vector3(0,-.025,0))
	if dais!=null:dais.rotation.y=PI*.25
	for i in range(run.rooms.size()):
		var p=pos(run.rooms[i].position)+Vector3(-.52,0,-.52)
		if prop(geometry,["dungeon_forest_shrine","dungeon_reef_shrine","dungeon_star_shrine"][region],p)==null:
			shape(geometry,"gem" if region!=0 else "orb",p+Vector3(0,.45,0),Vector3(.38,.88,.38),palette[3])
			shape(geometry,"box",p+Vector3(0,.11,0),Vector3(.62,.18,.62),palette[2])
	pet=Node3D.new();geometry.add_child(pet);pet.position=pos(run.player)
	pet_pose=model(pet,companion_id);pet_pose.scale*=1.28
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
	camera.position=pet.position+Vector3(0,8.5,10.5);camera.look_at(pet.position)
	refresh_actors()
	floor_build_usec=Time.get_ticks_usec()-start_usec
	print("DUNGEON_FLOOR_BUILD region=",region," floor=",run.floor_number," usec=",floor_build_usec," rocks=",rock_modules," cached_rock_sets=",rock_mesh_cache.size()," landmarks=",landmark_count," details=",detail_count," paired_spans=",span_count)
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
func draw_map():
	map.draw_style_box(style(Color("#142632e8"),Color("#75968b"),12),Rect2(Vector2.ZERO,map.size))
	var extent=Vector2i.ONE
	for p in run.cells:extent=Vector2i(maxi(extent.x,p.x+1),maxi(extent.y,p.y+1))
	var unit=minf((map.size.x-16.0)/extent.x,(map.size.y-16.0)/extent.y)
	var offset=(map.size-Vector2(extent)*unit)*.5
	for p in run.revealed:
		map.draw_rect(Rect2(Vector2(p)*unit+offset,Vector2.ONE*maxf(1.0,unit-.7)),Color("#759b9f"))
	for p in run.loot:
		if run.revealed.has(p):map.draw_circle((Vector2(p)+Vector2(.5,.5))*unit+offset,maxf(1.0,unit*.24),Color("#ffcf72"))
	for enemy in run.enemies:
		if run.revealed.has(enemy.pos):map.draw_circle((Vector2(enemy.pos)+Vector2(.5,.5))*unit+offset,maxf(1.2,unit*.3),Color("#f58b90"))
	if run.revealed.has(run.stairs):map.draw_rect(Rect2(Vector2(run.stairs)*unit+offset,Vector2.ONE*unit),Color("#f8d18b"))
	map.draw_circle((Vector2(run.player)+Vector2(.5,.5))*unit+offset,maxf(2.0,unit*.5),Color("#c2ffb5"))
func touch(event:InputEvent):
	if notified or run.finished:return
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
	floor_label.text="%s  ·  %d/%d rooms"%[floor_name(),run.explored_rooms.size(),run.rooms.size()]
	stats.text="HP %d/%d  ·  %d coins  ·  %d KO"%[run.hp,run.max_hp,run.coins,run.defeated]
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
	if attack_time>0.0:
		var phase=sin(PI*attack_time/.28)
		pet_pose.position+=pet.basis.inverse()*attack_direction*phase*.40
		attack_fx.visible=true;attack_fx.scale=Vector3(1.1-phase*.42,.13,1.1-phase*.42)
	else:attack_fx.hide()
	if hit_time>0.0:pet_pose.rotation.z+=sin(hit_time*45.0)*.19
	if facing!=Vector2i.ZERO:pet.rotation.y=atan2(float(facing.x),float(facing.y))
	camera.position=pet.position+Vector3(0,8.5,10.5);camera.look_at(pet.position)
