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
var meshes:Dictionary={}
var mats:Dictionary={}
var active_floor=0
var facing=Vector2i.DOWN
func setup(r:int,id:int,step:int,finale:bool,patrol:bool,seed_id:int,companion:int):
	region=r;companion_id=companion
	run.setup(r,id,step,finale,patrol,seed_id,companion)
	palette=[ [Color("#37574b"),Color("#58775a"),Color("#17392f"),Color("#f4c77b")], [Color("#244c64"),Color("#39748a"),Color("#123449"),Color("#7ce8e4")], [Color("#414264"),Color("#62678b"),Color("#282c50"),Color("#dbb8ff")] ][r]
	build_ui()
	build_floor()
	update_hud()
func style(bg:Color,border:Color,radius:int=14)->StyleBoxFlat:
	var s=StyleBoxFlat.new();s.bg_color=bg;s.border_color=border;s.set_border_width_all(2);s.set_corner_radius_all(radius)
	s.content_margin_left=12;s.content_margin_right=12;s.content_margin_top=8;s.content_margin_bottom=8
	return s
func label(parent:Node,value:String,size_value:int,color:Color=Color.WHITE)->Label:
	var l=Label.new();l.text=value;l.add_theme_font_size_override("font_size",size_value);l.modulate=color;parent.add_child(l);return l
func button(parent:Node,value:String,action:Callable,accent:bool=false)->Button:
	var b=Button.new();b.text=value;b.custom_minimum_size.y=54;b.size_flags_horizontal=SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size",17)
	b.add_theme_stylebox_override("normal",style(Color("#315f62") if accent else Color("#25374a"),Color("#79d5c3") if accent else Color("#53657d")))
	b.add_theme_stylebox_override("pressed",style(Color("#496b81"),Color("#f6e2a6")))
	b.pressed.connect(action);parent.add_child(b);return b
func build_ui():
	var base=VBoxContainer.new();add_child(base);base.set_anchors_and_offsets_preset(PRESET_FULL_RECT);base.add_theme_constant_override("separation",0)
	var header=PanelContainer.new();header.add_theme_stylebox_override("panel",style(Color("#162535"),Color("#344e63"),0));base.add_child(header)
	var h=HBoxContainer.new();header.add_child(h)
	var back=button(h,"Exit",leave);back.size_flags_horizontal=SIZE_SHRINK_BEGIN
	var info=VBoxContainer.new();info.size_flags_horizontal=SIZE_EXPAND_FILL;h.add_child(info)
	title_text=label(info,"",22,Color("#ffe1a4"))
	hp_bar=ProgressBar.new();hp_bar.max_value=run.max_hp;hp_bar.custom_minimum_size.y=15;hp_bar.show_percentage=false;info.add_child(hp_bar)
	hp_bar.add_theme_stylebox_override("fill",style(Color("#77d5a5"),Color("#77d5a5"),6))
	stats=label(info,"",14,Color("#c7dce7"))
	area=Control.new();area.size_flags_vertical=SIZE_EXPAND_FILL;area.clip_contents=true;base.add_child(area)
	var holder=SubViewportContainer.new();holder.stretch=true;holder.stretch_shrink=1;holder.mouse_filter=MOUSE_FILTER_IGNORE;area.add_child(holder);holder.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	viewport=SubViewport.new();viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;holder.add_child(viewport)
	world=Node3D.new();viewport.add_child(world)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=palette[2].darkened(.55);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("#e0edff");env.environment.ambient_light_energy=.65;world.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-35,0);sun.light_energy=.9;sun.shadow_enabled=true;world.add_child(sun)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.keep_aspect=Camera3D.KEEP_WIDTH;camera.size=9.5;world.add_child(camera);camera.current=true
	var input=Control.new();area.add_child(input);input.set_anchors_and_offsets_preset(PRESET_FULL_RECT);input.mouse_filter=MOUSE_FILTER_STOP;input.gui_input.connect(touch)
	map=Control.new();map.mouse_filter=MOUSE_FILTER_IGNORE;area.add_child(map);map.position=Vector2(10,10);map.size=Vector2(153,105);map.draw.connect(draw_map)
	var footer=PanelContainer.new();footer.add_theme_stylebox_override("panel",style(Color("#162535"),Color("#344e63"),0));base.add_child(footer)
	var v=VBoxContainer.new();v.add_theme_constant_override("separation",6);footer.add_child(v)
	status_text=label(v,"",16,Color("#ffe1a4"));status_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status_text.custom_minimum_size.y=44
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
		var scene=load(file) as PackedScene
		if scene!=null:node.add_child(scene.instantiate())
		if id==0 and ResourceLoader.exists("res://assets/foot.glb"):
			for side in [-1,1]:
				var foot=(load("res://assets/foot.glb") as PackedScene).instantiate() as Node3D
				node.add_child(foot);foot.position=Vector3(side*.37,.20,.16);foot.rotation.y=PI
	else:shape(node,"orb",Vector3(0,.55,0),Vector3(.8,1,.8),Data.TINTS[id%3])
	node.scale=Vector3.ONE*.70
	return node
func prop(parent:Node3D,name_value:String,at:Vector3)->Node3D:
	var file="res://assets/"+name_value+".glb"
	if not ResourceLoader.exists(file):return null
	var scene=load(file) as PackedScene
	if scene==null:return null
	var ob=scene.instantiate() as Node3D
	if ob==null:return null
	parent.add_child(ob);ob.position=at
	return ob
func batch(parent:Node3D,points:Array[Vector3],kind:String,sz:Vector3,c:Color):
	if points.is_empty():return
	var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh(kind);mm.instance_count=points.size()
	for i in range(points.size()):mm.set_instance_transform(i,Transform3D(Basis.from_scale(sz),points[i]))
	var instance=MultiMeshInstance3D.new();instance.multimesh=mm;instance.material_override=mat(c);parent.add_child(instance)
func build_floor():
	if is_instance_valid(geometry):geometry.hide();geometry.queue_free()
	if is_instance_valid(actors):actors.hide();actors.queue_free()
	geometry=Node3D.new();world.add_child(geometry);actors=Node3D.new();world.add_child(actors)
	var a:Array[Vector3]=[];var b:Array[Vector3]=[];var walls:Array[Vector3]=[]
	var seen:Dictionary={}
	for p in run.cells:
		var q:Vector2i=p
		if (q.x+q.y)%2==0:a.append(pos(q)+Vector3(0,-.13,0))
		else:b.append(pos(q)+Vector3(0,-.13,0))
		for d in Rules.DIR:
			var next:Vector2i=q+d
			if not run.cells.has(next) and not seen.has(next):
				seen[next]=true;walls.append(pos(next)+Vector3(0,.44,0))
	batch(geometry,a,"box",Vector3(1.38,.24,1.38),palette[0]);batch(geometry,b,"box",Vector3(1.38,.24,1.38),palette[1])
	batch(geometry,walls,"box",Vector3(1.4,.94,1.4),palette[2])
	var tops:Array[Vector3]=[]
	for p in walls:tops.append(p+Vector3(0,.51,0))
	batch(geometry,tops,"box",Vector3(1.42,.14,1.42),palette[1])
	for i in range(run.rooms.size()):
		var p=pos(run.rooms[i].position)+Vector3(-.48,0,-.48)
		if prop(geometry,["dungeon_forest_shrine","dungeon_reef_shrine","dungeon_star_shrine"][region],p)==null:
			shape(geometry,"gem" if region!=0 else "orb",p+Vector3(0,.45,0),Vector3(.38,.88,.38),palette[3])
			shape(geometry,"box",p+Vector3(0,.11,0),Vector3(.62,.18,.62),palette[2])
	pet=model(geometry,companion_id);pet.position=pos(run.player)
	active_floor=run.floor_revision
	camera.position=pet.position+Vector3(0,12,8);camera.look_at(pet.position)
	refresh_actors()
func refresh_actors():
	for child in actors.get_children():child.hide();child.queue_free()
	for p in run.loot:
		if not run.revealed.has(p):continue
		var kind:String=run.loot[p]
		var c=Color("#ffd277") if kind=="coin" else Color("#f2a8c0") if kind=="potion" else palette[3]
		if kind=="relic" and prop(actors,"dungeon_chest",pos(p))!=null:continue
		var item=shape(actors,"gem",pos(p)+Vector3(0,.36,0),Vector3(.38,.6,.38),c);item.rotation.y=.7
	for enemy in run.enemies:
		var p:Vector2i=enemy.pos
		if not run.revealed.has(p):continue
		var id:int=Data.POOLS[region][(int(enemy.kind)+run.floor_number)%Data.POOLS[region].size()]
		var ob=model(actors,id);ob.position=pos(p);ob.rotation.y=PI
		shape(actors,"box",pos(p)+Vector3(0,1.42,0),Vector3(.6,.07,.09),Color("#ee7c83"))
	for p in run.traps:
		if run.revealed.has(p):shape(actors,"ring",pos(p)+Vector3(0,.04,0),Vector3(.5,.06,.5),Color("#b9788b"))
	if run.revealed.has(run.stairs):
		if prop(actors,"dungeon_stairs",pos(run.stairs))==null:
			for i in range(3):shape(actors,"box",pos(run.stairs)+Vector3(0,.08+float(i)*.12,float(i)*.20-.2),Vector3(.95,.16,.32),palette[3] if run.secured else palette[2])
		if run.secured:shape(actors,"ring",pos(run.stairs)+Vector3(0,.08,0),Vector3(.7,.12,.7),Color("#e9d28c"))
func draw_map():
	map.draw_rect(Rect2(Vector2.ZERO,map.size),Color("#102030dd"))
	for p in run.revealed:
		map.draw_rect(Rect2(Vector2(p)*6+Vector2(9,9),Vector2(5,5)),Color("#6994a6"))
	if run.revealed.has(run.stairs):map.draw_rect(Rect2(Vector2(run.stairs)*6+Vector2(9,9),Vector2(5,5)),Color("#f8d18b"))
	map.draw_circle(Vector2(run.player)*6+Vector2(11.5,11.5),3.5,Color("#b1ffbc"))
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
	if run.finished and not notified:
		notified=true
		# Deferred settlement prevents destroying/rebuilding the UI inside a button callback.
		call_deferred("emit_result")
func emit_result():
	ended.emit(run.success,run.floor_count if run.success else run.floor_number-1,maxf(2.0,elapsed))
func update_hud():
	title_text.text="%s  ·  B%d/%d"%[Data.REGIONS[region],run.floor_number,run.floor_count]
	hp_bar.value=run.hp
	stats.text="HP %d/%d  •  %d coins  •  %d KO"%[run.hp,run.max_hp,run.coins,run.defeated]
	status_text.text=run.message
	power_button.text="%s %d/8"%[["Burst","Bolt","Drain"][run.skill_kind],run.energy];power_button.disabled=run.energy<2
	heal_button.text="Berry ×%d"%run.potions;heal_button.disabled=run.potions==0 or run.hp==run.max_hp
	stairs_button.text="Descend ›" if run.floor_number<run.floor_count else "Complete expedition"
	stairs_button.disabled=not run.secured or run.player!=run.stairs
	map.queue_redraw()
func _process(dt:float):
	if notified or not is_instance_valid(pet):return
	elapsed+=dt;tick-=dt
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
	if facing!=Vector2i.ZERO:pet.rotation.y=atan2(float(facing.x),float(facing.y))
	camera.position=pet.position+Vector3(0,12,8);camera.look_at(pet.position)
