extends Control
const Rules=preload("res://field_hunt_rules.gd")
const Data=preload("res://research_data.gd")
signal ended(success:bool,completed:int,elapsed:float)
signal canceled
var run=Rules.new()
var camera:Camera3D
var viewport:SubViewport
var world:Node3D
var player:Node3D
var trace:Node3D
var wild:Node3D
var hazards:Array[Node3D]=[]
var readout:Label
var status:Label
var timer_label:Label
var progress:ProgressBar
var calm:ProgressBar
var last_index=0
var last_position=Vector2.ZERO
var notified=false
var tint:Color
var region:int
var rng=RandomNumberGenerator.new()
func setup(r:int,id:int,step:int,finale:bool,patrol:bool,seed_id:int,companion:int):
	region=r;tint=Data.TINTS[r];rng.seed=seed_id;run.setup(r,id,step,finale,patrol,seed_id)
	var root=VBoxContainer.new();root.set_anchors_and_offsets_preset(PRESET_FULL_RECT);root.add_theme_constant_override("separation",0);add_child(root)
	var head=PanelContainer.new();head.add_theme_stylebox_override("panel",skin(Color("#142531"),Color("#354e59")));root.add_child(head)
	var top=HBoxContainer.new();head.add_child(top)
	var back=Button.new();back.text="‹ Exit";back.custom_minimum_size=Vector2(76,48);back.pressed.connect(func():canceled.emit());top.add_child(back)
	var name=Label.new();name.text=Data.REGIONS[r];name.add_theme_font_size_override("font_size",22);name.size_flags_horizontal=SIZE_EXPAND_FILL;top.add_child(name)
	timer_label=Label.new();timer_label.add_theme_font_size_override("font_size",22);top.add_child(timer_label)
	var view=SubViewportContainer.new();view.stretch=true;view.stretch_shrink=1;view.size_flags_vertical=SIZE_EXPAND_FILL;view.mouse_filter=MOUSE_FILTER_STOP;root.add_child(view)
	viewport=SubViewport.new();viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.msaa_3d=Viewport.MSAA_DISABLED;view.add_child(viewport)
	world=Node3D.new();viewport.add_child(world)
	view.gui_input.connect(func(e:InputEvent):
		if e is InputEventMouseButton and e.button_index==MOUSE_BUTTON_LEFT and e.pressed:aim(e.position,view.size)
		elif e is InputEventMouseMotion and (e.button_mask&MOUSE_BUTTON_MASK_LEFT)!=0:aim(e.position,view.size))
	build_world(companion,id,finale)
	var footer=PanelContainer.new();footer.add_theme_stylebox_override("panel",skin(Color("#142531"),Color("#354e59")));root.add_child(footer)
	var bottom=VBoxContainer.new();bottom.add_theme_constant_override("separation",8);footer.add_child(bottom)
	readout=Label.new();readout.add_theme_font_size_override("font_size",23);readout.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;bottom.add_child(readout)
	progress=ProgressBar.new();progress.max_value=run.required;progress.show_percentage=false;progress.custom_minimum_size.y=12;bottom.add_child(progress)
	calm=ProgressBar.new();calm.max_value=1.15;calm.show_percentage=false;calm.custom_minimum_size.y=7;calm.visible=finale;bottom.add_child(calm)
	status=Label.new();status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.add_theme_font_size_override("font_size",14);bottom.add_child(status)
	update_hud()
func skin(bg:Color,edge:Color)->StyleBoxFlat:
	var st=StyleBoxFlat.new();st.bg_color=bg;st.border_color=edge;st.set_border_width_all(1);st.content_margin_left=12;st.content_margin_right=12;st.content_margin_top=10;st.content_margin_bottom=10;return st
func material(c:Color,glow:bool=false)->StandardMaterial3D:
	var m=StandardMaterial3D.new();m.albedo_color=c;m.roughness=.88
	if glow:m.emission_enabled=true;m.emission=c;m.emission_energy_multiplier=.7
	return m
func shape(mesh:Mesh,p:Vector3,scale_value:Vector3,c:Color,parent:Node3D,glow:bool=false)->MeshInstance3D:
	var ob=MeshInstance3D.new();ob.mesh=mesh;ob.material_override=material(c,glow);parent.add_child(ob);ob.position=p;ob.scale=scale_value;return ob
func sphere(p:Vector3,sz:Vector3,c:Color,parent:Node3D,glow:bool=false)->MeshInstance3D:
	var m=SphereMesh.new();m.radial_segments=10;m.rings=6;return shape(m,p,sz,c,parent,glow)
func column(p:Vector3,sz:Vector3,c:Color,parent:Node3D)->MeshInstance3D:
	var m=CylinderMesh.new();m.radial_segments=8;return shape(m,p,sz,c,parent)
func model(id:int,parent:Node3D)->Node3D:
	var root=Node3D.new();parent.add_child(root)
	var file="res://assets/mosskit.glb" if id==0 else "res://assets/creatures/species_%02d.glb"%id
	if ResourceLoader.exists(file):
		var scene=load(file) as PackedScene
		if scene!=null:root.add_child(scene.instantiate())
		if id==0 and ResourceLoader.exists("res://assets/foot.glb"):
			for side in [-1,1]:
				var foot=(load("res://assets/foot.glb") as PackedScene).instantiate() as Node3D
				root.add_child(foot);foot.position=Vector3(side*.37,.20,.16);foot.rotation.y=PI
	else:sphere(Vector3(0,.65,0),Vector3(1.2,1.2,1.2),tint,root)
	root.scale=Vector3.ONE*.78
	return root
func build_world(companion:int,id:int,finale:bool):
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=[Color("#254d44"),Color("#16475d"),Color("#3b416c")][region];env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("#d9eaff");env.environment.ambient_light_energy=.8;world.add_child(env)
	var sun=DirectionalLight3D.new();sun.light_color=Color("#fff2d2");sun.light_energy=1.25;sun.rotation_degrees=Vector3(-55,-30,0);sun.shadow_enabled=true;world.add_child(sun)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.keep_aspect=Camera3D.KEEP_WIDTH;camera.size=20.5;world.add_child(camera);camera.position=Vector3(0,23,17);camera.look_at(Vector3.ZERO);camera.current=true
	var ground=shape(BoxMesh.new(),Vector3(0,-.35,0),Vector3(19,.6,19),[Color("#547d4c"),Color("#427f91"),Color("#777eaa")][region],world)
	var mat=ground.material_override as StandardMaterial3D
	var noise=FastNoiseLite.new();noise.frequency=.12
	var texture=NoiseTexture2D.new();texture.width=256;texture.height=256;texture.noise=noise
	var gradient=Gradient.new();gradient.colors=PackedColorArray([tint.darkened(.64),tint.darkened(.16)]);texture.color_ramp=gradient;mat.albedo_texture=texture;mat.albedo_color=Color.WHITE
	for i in range(70):
		var x=rng.randf_range(-9.1,9.1);var z=rng.randf_range(-9.1,9.1)
		var edge=absf(x)>7.9 or absf(z)>7.9
		if edge:
			if region==0:
				column(Vector3(x,.8,z),Vector3(.35,1.5,.35),Color("#76513f"),world)
				for j in range(3):
					sphere(Vector3(x+(j-1)*.42,1.65+float(j%2)*.42,z),Vector3(1.5,1.5,1.5),[Color("#43845c"),Color("#629e69"),Color("#2d684c")][j],world)
			elif region==1:
				for j in range(3):column(Vector3(x+(j-1)*.25,.5+float(j%2)*.25,z),Vector3(.24,1.0+float(j%2)*.5,.24),[Color("#db9cb6"),Color("#f2c09c"),Color("#aa86ce")][j],world)
			else:
				var m=PrismMesh.new();var rock=shape(m,Vector3(x,.7,z),Vector3(.8,1.7,.8),Color("#b8b7f0"),world);rock.rotation.y=rng.randf_range(0,TAU)
		else:
			sphere(Vector3(x,.035,z),Vector3(.25,.06,.19),tint.darkened(.30),world)
	for i in range(12):
		var x=rng.randf_range(-8,8);var z=rng.randf_range(-8,8)
		sphere(Vector3(x,.10,z),Vector3(.25,.14,.25),Color("#f4d9a1") if region==0 else Color("#b7ecf3"),world)
	player=model(companion,world)
	trace=Node3D.new();world.add_child(trace)
	var ring=TorusMesh.new();ring.inner_radius=.42;ring.outer_radius=.56;ring.rings=16;ring.ring_segments=8;shape(ring,Vector3(0,.13,0),Vector3.ONE,tint.lightened(.4),trace,true)
	sphere(Vector3(0,.55,0),Vector3(.22,.22,.22),Color("#fff0a5"),trace,true)
	if finale:wild=model(id,world)
	for i in range(2 if id<12 else 3):
		var hazard=Node3D.new();world.add_child(hazard);hazards.append(hazard)
		var ring2=TorusMesh.new();ring2.inner_radius=.68;ring2.outer_radius=.85;ring2.rings=20;ring2.ring_segments=8;shape(ring2,Vector3(0,.12,0),Vector3.ONE,Color("#f29b6c"),hazard,true)
		sphere(Vector3(0,.5,0),Vector3(.65,.7,.65),Color("#e29667"),hazard,true)
func aim(p:Vector2,dims:Vector2):
	if dims.x<=0 or dims.y<=0 or run.finished:return
	var screen=p*Vector2(viewport.size)/dims
	var origin=camera.project_ray_origin(screen);var ray=camera.project_ray_normal(screen)
	if absf(ray.y)<.001:return
	var hit=origin+ray*(-origin.y/ray.y)
	run.move_to(Vector2(hit.x,hit.z))
func _process(dt:float):
	if not is_instance_valid(player) or notified:return
	run.tick(dt)
	player.position=Vector3(run.player.x,.1+absf(sin(run.elapsed*12))*.10,run.player.y)
	var move=run.player-last_position
	if move.length()>.01:player.rotation.y=atan2(move.x,move.y)
	last_position=run.player
	var point=run.signal_position()
	trace.position=Vector3(point.x,.02,point.y)
	trace.visible=run.player.distance_to(point)<3.3 and not run.encounter
	if is_instance_valid(wild):
		wild.position=Vector3(point.x,.1,point.y);wild.visible=run.player.distance_to(point)<5.5;wild.rotation.y=atan2(run.player.x-point.x,run.player.y-point.y)
	for i in range(hazards.size()):
		var p=run.hazard_at(i);hazards[i].position=Vector3(p.x,0,p.y)
	update_hud()
	if run.finished:
		notified=true;ended.emit(run.success,run.index,run.elapsed)
func update_hud():
	timer_label.text="%02d s"%ceili(maxf(0,run.time_left))
	progress.value=run.index;calm.value=run.hold
	readout.text=("Approach gently" if run.encounter else "Follow the signal")+" · %d/%d"%[run.index,run.required]
	status.text="Tap or drag to move · Avoid glowing hazards" if not run.started else run.direction()+" · "+("Stay close to earn trust" if run.encounter else "Find the hidden trace")
	if run.hit_cooldown>0:status.text="Hazard! −3 seconds · Keep moving"
