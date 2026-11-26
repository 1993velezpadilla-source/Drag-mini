extends Control
const Rules=preload("res://field_hunt_rules.gd")
const Data=preload("res://research_data.gd")
signal ended(success:bool,completed:int,elapsed:float)
signal canceled
var run=Rules.new()
var camera:Camera3D
var field_input:Control
var touch_index=-1
var mouse_held=false
var action_held=false
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
var signal_bar:ProgressBar
var inspect_button:Button
var scan_button:Button
var burst_button:Button
var burst_meter:ProgressBar
var flow_arrows:Array[Node3D]=[]
var mesh_cache:Dictionary={}
var material_cache:Dictionary={}
var pulse:Node3D
var compass_arrow:Node3D
var signal_sample=0.0
var signal_sample_timer=0.0
var signal_trend=""
var destination_marker:Node3D
var found_flash=0.0
var camera_focus=Vector3.ZERO
var last_index=0
var last_position=Vector2.ZERO
var previous_hits=0
var notified=false
var tint:Color
var region:int
var rng=RandomNumberGenerator.new()
func setup(r:int,id:int,step:int,finale:bool,patrol:bool,seed_id:int,companion:int):
	region=r;tint=Data.TINTS[r];rng.seed=seed_id;run.setup(r,id,step,finale,patrol,seed_id);last_position=run.player
	var root=VBoxContainer.new();root.set_anchors_and_offsets_preset(PRESET_FULL_RECT);root.add_theme_constant_override("separation",0);add_child(root)
	var head=PanelContainer.new();head.add_theme_stylebox_override("panel",skin(Color("#142531"),Color("#354e59")));root.add_child(head)
	var top=HBoxContainer.new();head.add_child(top)
	var back=Button.new();back.text="‹ Exit";back.custom_minimum_size=Vector2(76,48);back.pressed.connect(func():canceled.emit());top.add_child(back)
	var name=Label.new();name.text=Data.REGIONS[r];name.add_theme_font_size_override("font_size",22);name.size_flags_horizontal=SIZE_EXPAND_FILL;top.add_child(name)
	timer_label=Label.new();timer_label.add_theme_font_size_override("font_size",22);top.add_child(timer_label)
	var play_area=Control.new();play_area.size_flags_vertical=SIZE_EXPAND_FILL;play_area.clip_contents=true;root.add_child(play_area)
	var view=SubViewportContainer.new();view.stretch=true;view.stretch_shrink=2;view.mouse_filter=MOUSE_FILTER_IGNORE;play_area.add_child(view);view.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	viewport=SubViewport.new();viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.msaa_3d=Viewport.MSAA_DISABLED;view.add_child(viewport)
	world=Node3D.new();viewport.add_child(world)
	field_input=Control.new();field_input.name="FieldInput";field_input.mouse_filter=MOUSE_FILTER_STOP;play_area.add_child(field_input);field_input.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	field_input.gui_input.connect(field_event)
	build_world(companion,id,finale)
	var footer=PanelContainer.new();footer.add_theme_stylebox_override("panel",skin(Color("#142531"),Color("#354e59")));root.add_child(footer)
	var bottom=VBoxContainer.new();bottom.add_theme_constant_override("separation",8);footer.add_child(bottom)
	readout=Label.new();readout.add_theme_font_size_override("font_size",20);readout.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;bottom.add_child(readout)
	progress=field_meter(bottom,"TRUST" if run.encounter else "TRAIL",float(run.required),Color("#a7e9af"))
	var meters=HBoxContainer.new();meters.add_theme_constant_override("separation",14);bottom.add_child(meters)
	var radar=VBoxContainer.new();radar.size_flags_horizontal=SIZE_EXPAND_FILL;meters.add_child(radar)
	var action=VBoxContainer.new();action.size_flags_horizontal=SIZE_EXPAND_FILL;meters.add_child(action)
	signal_bar=field_meter(radar,"SIGNAL",1.0,Color("#71cfee"))
	calm=field_meter(action,"BOND" if run.encounter else "COLLECT",run.capture_time,Color("#f6d48b"))
	status=Label.new();status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.add_theme_font_size_override("font_size",14);bottom.add_child(status)
	var controls=HBoxContainer.new();controls.add_theme_constant_override("separation",8);bottom.add_child(controls)
	scan_button=Button.new();scan_button.custom_minimum_size=Vector2(120,58);scan_button.pressed.connect(func():run.scan());controls.add_child(scan_button)
	inspect_button=Button.new();inspect_button.custom_minimum_size.y=58;inspect_button.size_flags_horizontal=SIZE_EXPAND_FILL;inspect_button.button_down.connect(func():action_held=true;run.set_inspecting(true));inspect_button.button_up.connect(func():action_held=false;run.set_inspecting(false));controls.add_child(inspect_button)
	burst_button=Button.new();burst_button.custom_minimum_size=Vector2(102,58);burst_button.pressed.connect(func():run.burst());controls.add_child(burst_button)
	burst_meter=field_meter(bottom,"ABILITY",4.0,Color("#c6adff"))
	update_hud()
func field_meter(parent:Container,caption_text:String,limit:float,fill_color:Color)->ProgressBar:
	var line=HBoxContainer.new();line.add_theme_constant_override("separation",8);parent.add_child(line)
	var caption=Label.new();caption.text=caption_text;caption.custom_minimum_size.x=65;caption.add_theme_font_size_override("font_size",11);caption.modulate=Color("#b7cbd3");line.add_child(caption)
	var meter=ProgressBar.new();meter.max_value=limit;meter.step=.001;meter.show_percentage=false;meter.custom_minimum_size.y=9;meter.size_flags_horizontal=SIZE_EXPAND_FILL;meter.size_flags_vertical=SIZE_SHRINK_CENTER
	var track=StyleBoxFlat.new();track.bg_color=Color("#0c1922");track.set_corner_radius_all(5)
	var fill=StyleBoxFlat.new();fill.bg_color=fill_color;fill.set_corner_radius_all(5)
	meter.add_theme_stylebox_override("background",track);meter.add_theme_stylebox_override("fill",fill);line.add_child(meter)
	return meter
func skin(bg:Color,edge:Color)->StyleBoxFlat:
	var st=StyleBoxFlat.new();st.bg_color=bg;st.border_color=edge;st.set_border_width_all(1);st.content_margin_left=12;st.content_margin_right=12;st.content_margin_top=10;st.content_margin_bottom=10;return st
func material(c:Color,glow:bool=false)->StandardMaterial3D:
	var key=str(c)+str(glow)
	if material_cache.has(key):return material_cache[key]
	var m=StandardMaterial3D.new();m.albedo_color=c;m.roughness=.88
	if glow:m.emission_enabled=true;m.emission=c;m.emission_energy_multiplier=.7
	material_cache[key]=m
	return m
func shape(mesh:Mesh,p:Vector3,scale_value:Vector3,c:Color,parent:Node3D,glow:bool=false)->MeshInstance3D:
	var ob=MeshInstance3D.new();ob.mesh=mesh;ob.material_override=material(c,glow);parent.add_child(ob);ob.position=p;ob.scale=scale_value;return ob
func sphere(p:Vector3,sz:Vector3,c:Color,parent:Node3D,glow:bool=false)->MeshInstance3D:
	if not mesh_cache.has("sphere"):
		var m=SphereMesh.new();m.radial_segments=10;m.rings=6;mesh_cache["sphere"]=m
	return shape(mesh_cache["sphere"],p,sz,c,parent,glow)
func column(p:Vector3,sz:Vector3,c:Color,parent:Node3D)->MeshInstance3D:
	if not mesh_cache.has("column"):
		var m=CylinderMesh.new();m.radial_segments=8;mesh_cache["column"]=m
	return shape(mesh_cache["column"],p,sz,c,parent)
func prism()->Mesh:
	if not mesh_cache.has("prism"):mesh_cache["prism"]=PrismMesh.new()
	return mesh_cache["prism"]
func flat_shape(mesh:Mesh,p:Vector3,sz:Vector3,c:Color,parent:Node3D,glow:bool=false)->MeshInstance3D:
	var ob=shape(mesh,p,sz,c,parent,glow)
	ob.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return ob
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
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.keep_aspect=Camera3D.KEEP_WIDTH;camera.size=13.4;world.add_child(camera);camera_focus=Vector3(run.player.x,0,run.player.y);camera.position=camera_focus+Vector3(0,23,17);camera.look_at(camera_focus);camera.current=true
	var ground=shape(BoxMesh.new(),Vector3(0,-.35,0),Vector3(22,.6,22),[Color("#547d4c"),Color("#427f91"),Color("#777eaa")][region],world)
	var mat=ground.material_override.duplicate() as StandardMaterial3D
	ground.material_override=mat
	var noise=FastNoiseLite.new();noise.frequency=.12
	var texture=NoiseTexture2D.new();texture.width=256;texture.height=256;texture.noise=noise
	var gradient=Gradient.new();gradient.colors=PackedColorArray([tint.darkened(.64),tint.darkened(.16)]);texture.color_ramp=gradient;mat.albedo_texture=texture;mat.albedo_color=Color.WHITE
	for i in range(86):
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
				var rock=shape(prism(),Vector3(x,.7,z),Vector3(.8,1.7,.8),Color("#b8b7f0"),world);rock.rotation.y=rng.randf_range(0,TAU)
		else:
			sphere(Vector3(x,.035,z),Vector3(.25,.06,.19),tint.darkened(.30),world)
	for i in range(28):
		var x=rng.randf_range(-8,8);var z=rng.randf_range(-8,8)
		var scale_value=rng.randf_range(.15,.35)
		if region==0:
			for j in range(3):
				var grass=flat_shape(prism(),Vector3(x+(j-1)*.08,.13,z),Vector3(.08,.27+float(j%2)*.08,.06),Color("#a7c26d"),world);grass.rotation.y=float(j)*1.2
		elif region==1:sphere(Vector3(x,.04,z),Vector3(scale_value,.09,scale_value*.8),Color("#c1dacf"),world)
		else:sphere(Vector3(x,.12,z),Vector3(scale_value,.22,scale_value),Color("#c2c4ef"),world)
	build_landmarks()
	build_terrain_details()
	player=model(companion,world)
	player.position=Vector3(run.player.x,.1,run.player.y)
	destination_marker=Node3D.new();world.add_child(destination_marker)
	var target_ring=TorusMesh.new();target_ring.inner_radius=.28;target_ring.outer_radius=.34;target_ring.rings=16;target_ring.ring_segments=6
	shape(target_ring,Vector3(0,.08,0),Vector3.ONE,Color("#e9faff"),destination_marker,true)
	destination_marker.hide()
	trace=Node3D.new();world.add_child(trace)
	var ring=TorusMesh.new();ring.inner_radius=.42;ring.outer_radius=.56;ring.rings=16;ring.ring_segments=8;shape(ring,Vector3(0,.13,0),Vector3.ONE,tint.lightened(.4),trace,true)
	build_trace_art()
	trace.hide()
	pulse=Node3D.new();world.add_child(pulse)
	var scan_ring=TorusMesh.new();scan_ring.inner_radius=.94;scan_ring.outer_radius=1.0;scan_ring.rings=24;scan_ring.ring_segments=6;shape(scan_ring,Vector3(0,.09,0),Vector3.ONE,tint.lightened(.6),pulse,true)
	pulse.hide()
	compass_arrow=Node3D.new();world.add_child(compass_arrow)
	var arrow_shaft=BoxMesh.new()
	shape(arrow_shaft,Vector3(0,.18,.12),Vector3(.10,.08,.48),Color("#c8fbff"),compass_arrow,true)
	var arrow_head=prism()
	var tip=shape(arrow_head,Vector3(0,.18,.46),Vector3(.42,.09,.40),Color("#c8fbff"),compass_arrow,true)
	tip.rotation.x=PI/2
	compass_arrow.hide()
	if finale:wild=model(id,world)
	for i in range(2 if id<12 else 3):
		var hazard=Node3D.new();world.add_child(hazard);hazards.append(hazard)
		var ring2=TorusMesh.new();ring2.inner_radius=.68;ring2.outer_radius=.85;ring2.rings=20;ring2.ring_segments=8;shape(ring2,Vector3(0,.12,0),Vector3.ONE,Color("#f29b6c"),hazard,true)
		if region==0:
			for k in range(3):
				var thorn=shape(prism(),Vector3((k-1)*.24,.38,0),Vector3(.32,.76,.4),Color("#da8b56"),hazard,true);thorn.rotation.y=float(k)*1.3
		elif region==1:
			var whirl=TorusMesh.new();whirl.inner_radius=.20;whirl.outer_radius=.48;shape(whirl,Vector3(0,.45,0),Vector3.ONE,Color("#a6e8f5"),hazard,true)
			sphere(Vector3(0,.6,0),Vector3(.28,.48,.28),Color("#e5f8fc"),hazard,true)
		else:
			shape(prism(),Vector3(0,.55,0),Vector3(.62,1.1,.62),Color("#ffc5e5"),hazard,true)
func build_trace_art():
	# Distinct silhouettes for the three biomes; no extra collision objects.
	if region==0:
		for i in range(3):
			var root=Node3D.new();trace.add_child(root);root.position=Vector3(float(i-1)*.23,.08,float(i%2)*.22-.12);root.rotation.y=float(i-1)*.30
			var pad=sphere(Vector3(0,0,.04),Vector3(.23,.045,.19),Color("#ffdd98"),root,true);pad.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for toe in [-1,0,1]:
				var digit=sphere(Vector3(float(toe)*.075,0,-.095),Vector3(.075,.04,.085),Color("#fff2c1"),root,true);digit.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	elif region==1:
		for i in range(4):
			var bubble=sphere(Vector3(sin(float(i)*2.1)*.25,.20+float(i)*.19,cos(float(i)*2.1)*.22),Vector3.ONE*(.16+float(i%2)*.08),Color("#a1f1ff"),trace,true);bubble.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	else:
		for i in range(3):
			var shard=flat_shape(prism(),Vector3(float(i-1)*.19,.30+float(i%2)*.14,0),Vector3(.19,.43,.17),Color("#f5ceff"),trace,true);shard.rotation.z=float(i-1)*.35
func build_landmarks():
	# Distinct landmarks outside the playable route; terrain remains traversable.
	for side in [-1,1]:
		for i in range(3):
			var x=float(side)*8.9;var z=-6.0+float(i)*5.2
			if region==0:
				column(Vector3(x,1.5,z),Vector3(.65,2.8,.65),Color("#765443"),world)
				for j in range(4):
					var ob=sphere(Vector3(x+sin(j*1.6)*.7,2.8+float(j%2)*.4,z+cos(j*1.6)*.6),Vector3(2.2,1.6,2.0),[Color("#3f7756"),Color("#78a66b")][j%2],world)
					ob.rotation.y=float(j)
				for k in range(3):
					var p=Vector3(x-float(side)*.9,.12,z+float(k)*.32)
					column(p,Vector3(.11,.24,.11),Color("#f2d4a1"),world);sphere(p+Vector3(0,.17,0),Vector3(.34,.16,.34),Color("#e0a16c"),world)
			elif region==1:
				sphere(Vector3(x,.2,z),Vector3(1.4,.4,1.3),Color("#59798c"),world)
				for j in range(5):
					var coral=column(Vector3(x+sin(j*1.4)*.42,.70,z+cos(j*1.4)*.42),Vector3(.20,1.2+float(j%3)*.26,.20),[Color("#d88ea9"),Color("#b8b6ec"),Color("#ffcc9e")][j%3],world)
					coral.rotation.z=sin(float(j))*.30
			else:
				var rock=shape(prism(),Vector3(x,1.1,z),Vector3(1.0,2.2,1.0),Color("#b8a8e4"),world);rock.rotation.y=float(i)*.7
				for j in range(3):
					sphere(Vector3(x+sin(j*2.1)*.75,.35,z+cos(j*2.1)*.65),Vector3(1.3,.5,1.3),Color("#d0d9f2"),world)
	if region!=0:
		for i in range(12):
			var marker=Node3D.new();world.add_child(marker)
			marker.position=Vector3(-6+float(i%4)*4,.10,-5+float(i/4)*4.0)
			var arrow=flat_shape(prism(),Vector3.ZERO,Vector3(.16,.08,.7),tint.lightened(.35),marker,true);arrow.rotation.x=PI/2
			flow_arrows.append(marker)
func build_terrain_details():
	# Low profile landmarks provide navigation cues without obscuring the player.
	for i in range(6):
		var p=Vector3(-5.8+float(i%3)*5.8,.015,-4.3+float(i/3)*7.1)
		if region==0:
			var patch=sphere(p,Vector3(2.0,.055,1.4),Color("#8d9460"),world);patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for j in range(4):
				var pebble=sphere(p+Vector3(sin(j*1.7)*.55,.045,cos(j*1.7)*.43),Vector3(.23,.08,.17),Color("#c3b48c"),world);pebble.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif region==1:
			var ripple=TorusMesh.new();ripple.inner_radius=.93;ripple.outer_radius=1.0;ripple.rings=16;ripple.ring_segments=6
			flat_shape(ripple,p+Vector3(0,.05,0),Vector3(1.05,.28,.78),Color("#7bbdc6"),world)
		else:
			var rune=TorusMesh.new();rune.inner_radius=.74;rune.outer_radius=.82;rune.rings=12;rune.ring_segments=6
			flat_shape(rune,p+Vector3(0,.04,0),Vector3(1,.25,1),Color("#b5a9df"),world)
			for j in range(4):
				var stone=flat_shape(prism(),p+Vector3(sin(j*PI/2)*.58,.05,cos(j*PI/2)*.58),Vector3(.16,.08,.24),Color("#e0d6f9"),world);stone.rotation.y=float(j)*PI/2
func field_event(event:InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed and touch_index==-1:
			touch_index=event.index;aim(event.position,field_input.size)
		elif not event.pressed and event.index==touch_index:touch_index=-1
		field_input.accept_event()
	elif event is InputEventScreenDrag:
		if event.index==touch_index:aim(event.position,field_input.size)
		field_input.accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.device==-1 or touch_index!=-1:return
		mouse_held=event.pressed
		if mouse_held:aim(event.position,field_input.size)
		field_input.accept_event()
	elif event is InputEventMouseMotion and mouse_held and touch_index==-1 and event.device!=-1:
		aim(event.position,field_input.size)
		field_input.accept_event()
func _notification(what:int):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_APPLICATION_PAUSED:
		touch_index=-1;mouse_held=false;action_held=false
		run.set_inspecting(false)
func aim(p:Vector2,dims:Vector2):
	if dims.x<=0 or dims.y<=0 or run.finished or not is_instance_valid(camera) or viewport.size.x<=0 or viewport.size.y<=0:return
	var screen=p.clamp(Vector2.ZERO,dims)*Vector2(viewport.size)/dims
	var origin=camera.project_ray_origin(screen);var ray=camera.project_ray_normal(screen)
	if absf(ray.y)<.001:return
	var hit=origin+ray*(-origin.y/ray.y)
	run.move_to(Vector2(hit.x,hit.z))
func _process(dt:float):
	if not is_instance_valid(player) or notified:return
	run.tick(dt)
	var moving=run.player.distance_to(last_position)>.005
	player.position=Vector3(run.player.x,.1+(absf(sin(run.elapsed*12))*.10 if moving else 0.0)+(0.26 if run.burst_left>0 else 0.0),run.player.y)
	destination_marker.position=Vector3(run.destination.x,.02,run.destination.y)
	destination_marker.visible=run.started and not run.finished and run.player.distance_to(run.destination)>.35
	if run.hits>previous_hits:
		previous_hits=run.hits
		Input.vibrate_handheld(65)
	for marker in flow_arrows:
		var force:Vector2=run.current_at(Vector2(marker.position.x,marker.position.z))
		marker.rotation.y=atan2(force.x,force.y);marker.visible=force.length()>.18
	var move=run.player-last_position
	if move.length()>.01:player.rotation.y=atan2(move.x,move.y)
	last_position=run.player
	camera_focus=camera_focus.lerp(Vector3(clampf(run.player.x,-4.0,4.0),0,clampf(run.player.y,-4.0,4.0)),1.0-exp(-dt*7.0))
	camera.position=camera_focus+Vector3(0,23,17);camera.look_at(camera_focus)
	pulse.visible=run.scan_left>0;pulse.position=Vector3(run.player.x,0,run.player.y);pulse.scale=Vector3.ONE*(1.0+7.0*(1.0-run.scan_left/2.6))
	if run.index!=last_index:
		found_flash=1.0;last_index=run.index;signal_sample=run.signal_strength();signal_trend=""
		Input.vibrate_handheld(35)
	found_flash=maxf(0,found_flash-dt)
	var point=run.signal_position()
	var bearing:Vector2=run.scan_vector()
	compass_arrow.visible=bearing.length_squared()>.01
	if compass_arrow.visible:
		compass_arrow.position=Vector3(run.player.x+bearing.x*.95,.08,run.player.y+bearing.y*.95)
		compass_arrow.rotation.y=atan2(bearing.x,bearing.y)
	signal_sample_timer+=dt
	if signal_sample_timer>=.45:
		var strength:float=run.signal_strength()
		var change=strength-signal_sample
		signal_trend=" · Closer" if change>.025 else " · Farther" if change<-.025 else ""
		signal_sample=strength;signal_sample_timer=0.0
	trace.position=Vector3(point.x,.02,point.y)
	trace.visible=run.trace_visible() and not run.finished
	trace.scale=Vector3.ONE*(1.0+.14*sin(run.elapsed*8))
	if is_instance_valid(wild):
		wild.position=Vector3(point.x,.1,point.y);wild.visible=run.player.distance_to(point)<5.5;wild.rotation.y=atan2(run.player.x-point.x,run.player.y-point.y)
		wild.scale=Vector3.ONE*.78*(1.0+.08*sin(run.elapsed*18.0) if run.alert_left()>0.0 else 1.0)
	for i in range(hazards.size()):
		var p=run.hazard_at(i);hazards[i].position=Vector3(p.x,0,p.y);hazards[i].rotation.y=run.elapsed*1.7
	update_hud()
	if run.finished:
		notified=true;ended.emit(run.success,run.index,run.elapsed)
func update_hud():
	timer_label.text="%02d s"%ceili(maxf(0,run.time_left))
	progress.value=run.index;calm.value=run.hold;signal_bar.value=run.signal_strength()
	readout.text=(["Common","Rare","Mystic"][run.tier]+(" encounter" if run.encounter else " trail"))+"  %d/%d"%[run.index,run.required]
	scan_button.text="Scan %d"%run.scans;scan_button.disabled=run.scans<=0 or run.scan_left>0 or run.finished
	burst_button.text=["Dash","Swim","Glide"][region] if run.burst_cooldown<=0 else "%ds"%ceili(run.burst_cooldown)
	burst_button.disabled=run.burst_cooldown>0 or run.finished or run.destination.distance_to(run.player)<.3
	burst_meter.value=4.0-run.burst_cooldown
	inspect_button.text="Wait · alert" if run.alert_left()>0.0 else "Hold to befriend" if run.encounter else "Hold to collect"
	inspect_button.modulate=Color("#a8ffd6") if run.inspect_ready() else Color("#82939c")
	status.text="Tap to move · Use signal strength to search" if not run.started else "Signal: "+("HOT" if run.signal_strength()>.78 else "WARM" if run.signal_strength()>.4 else "COLD")
	if run.started:status.text+=signal_trend
	if run.started and region==1 and run.environmental_force.length()>.55:status.text+=" · Current"
	if run.started and region==2 and run.environmental_force.length()>.7:status.text+=" · Wind gust"
	if run.scan_left>0:status.text="SCAN · "+run.direction()+" · Follow the arrow"
	if run.inspect_ready():status.text="Hold the action button now!"
	if run.alert_left()>0.0 and run.player.distance_to(run.signal_position())<5.5:
		status.text="ALERT · Wait for the creature to calm down"
		inspect_button.modulate=Color("#f5ad8b")
	if found_flash>0:status.text="Trace secured!" if not run.encounter else "Trust gained!"
	if run.hit_cooldown>0:status.text="Hazard! −3 seconds · Keep moving"
	timer_label.modulate=Color("#ffab97") if run.time_left<10 else Color.WHITE
