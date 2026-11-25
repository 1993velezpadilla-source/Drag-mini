extends Node3D
# Standalone 3D vertical slice; no native wallet writes yet.
const LANES := [-2.0, 0.0, 2.0]
const SEGMENT := 18.0
const SEGMENTS := 8
const GRAVITY := 25.0
const JUMP_SPEED := 10.5
const PLAYER_Z := 0.0
const PICKUP := 2
const SNACK := 3
const MAGNET := 4
const SHIELD := 5
const DOUBLE := 6
const BOOST := 7
var magnet_time := 0.0
var shield_time := 0.0
var double_time := 0.0
var boost_time := 0.0
var power_label: Label
var fx: Node3D
var dust: Array[MeshInstance3D] = []
var dust_ages: Array[float] = []
var aura: MeshInstance3D
var audio: Node
var audio_button: Button
var next_step := 0.0
var rng := RandomNumberGenerator.new()
var player: CharacterBody3D
var mascot: Node3D
var feet: Array[Node3D] = []
var models := {}
var using_blender := false
var loaded_assets := 0
var player_shape: CollisionShape3D
var camera: Camera3D
var chunks: Array[Node3D] = []
var entities: Array[Area3D] = []
var pools: Array = [[],[],[],[],[],[],[],[]]
var created_entities := 0
var reused_entities := 0
var previous_safe_lane := 1
var pattern_count := 0
var lane := 1
var slide := 0.0
var distance := 0.0
var coins := 0
var snacks := 0
var speed := 9.0
var started := false
var ended := false
var paused_run := false
var touch_start := Vector2.ZERO
var touch_active := false
var gesture_sent := false
var touch_id := -1
var spawn_at := 20.0
var status: Label
var hint: Label
var score_label: Label
var coin_label: Label
var snack_label: Label
var pause_button: Button
var result_panel: PanelContainer
var result_text: Label
var result_button: Button
var last_hud := ""
var jump_buffer := 0.0
var material_cache := {}
var session_claimed := false
var clock := 0.0

func material(color: Color, metallic := 0.0) -> StandardMaterial3D:
	var key := str(color) + str(metallic)
	if not material_cache.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.44
		m.metallic = metallic
		material_cache[key] = m
	return material_cache[key]

func mesh(parent: Node3D, shape: Mesh, pos: Vector3, color: Color, metallic := 0.0) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = shape
	n.material_override = material(color, metallic)
	n.position = pos
	parent.add_child(n)
	return n

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return mesh(parent, m, pos, color)

func orb(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = 0.5
	m.height = 1.0
	m.radial_segments = 20
	m.rings = 10
	var n := mesh(parent, m, pos, color)
	n.scale = size
	return n

func asset(parent: Node3D, name: String, pos: Vector3) -> Node3D:
	if not models.has(name):
		var path := "res://assets/"+name+".glb"
		if not ResourceLoader.exists(path):
			return null
		models[name]=load(path)
	var n: Node3D=models[name].instantiate()
	parent.add_child(n)
	n.position=pos
	loaded_assets+=1
	return n

func _ready() -> void:
	using_blender=ResourceLoader.exists("res://assets/bridge.glb")
	rng.seed = 7319 if OS.get_cmdline_user_args().has("--test") else Time.get_ticks_usec()
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#72b8f0")
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color=Color("#377dd5")
	sky_mat.sky_horizon_color=Color("#b7e0ff")
	sky_mat.ground_horizon_color=Color("#c8e7ff")
	sky_mat.ground_bottom_color=Color("#7495ca")
	sky.sky_material=sky_mat
	e.sky=sky
	e.background_mode=Environment.BG_SKY
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#c5d9ee")
	e.ambient_light_energy = 0.28
	e.reflected_light_source = Environment.REFLECTED_SOURCE_DISABLED
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_color = Color("#ffdfb0")
	sun.light_energy = 0.66
	sun.light_specular=0.3
	sun.directional_shadow_max_distance=44.0
	sun.shadow_bias=0.07
	sun.shadow_normal_bias=0.55
	sun.shadow_enabled = true
	add_child(sun)
	var floor_body := StaticBody3D.new()
	add_child(floor_body)
	var floor_shape := CollisionShape3D.new()
	var plane := BoxShape3D.new()
	plane.size = Vector3(8, 1, 300)
	floor_shape.shape = plane
	floor_shape.position = Vector3(0,-0.5,-100)
	floor_body.add_child(floor_shape)
	for i in range(SEGMENTS):
		var chunk := Node3D.new()
		add_child(chunk)
		chunk.position.z = 12.0 - i * SEGMENT
		chunks.append(chunk)
		make_chunk(chunk, i)
	make_player()
	camera = Camera3D.new()
	camera.position = Vector3(0, 4.25, 7.1)
	camera.fov = 58
	camera.far=140
	add_child(camera)
	camera.look_at(Vector3(0, 0.25, -10))
	make_effects()
	audio=preload("res://dash_audio.gd").new()
	add_child(audio)
	make_hud()
	fill_track()
	if OS.get_cmdline_user_args().has("--test"):
		call_deferred("test_run")
	elif OS.get_cmdline_user_args().has("--capture"):
		call_deferred("capture_review")

func make_chunk(chunk: Node3D, index: int) -> void:
	if using_blender and asset(chunk,"bridge",Vector3.ZERO)!=null:
		if index%3==1: asset(chunk,"arch",Vector3(0,0,-4))
		if index%2==0:
			for side in [-1,1]: asset(chunk,"island",Vector3(side*8,0,-4))
		return
	box(chunk, Vector3(0,-0.22,0), Vector3(6.6,0.42,SEGMENT), Color("#815541"))
	for i in range(9):
		box(chunk, Vector3(0,0.005,-8+i*2), Vector3(6.35,0.06,1.96), Color("#b77b50") if i%2==0 else Color("#bd855e"))
	for side in [-1,1]:
		box(chunk, Vector3(side,0.05,0), Vector3(0.055,0.03,SEGMENT), Color("#f9deb4"))
		box(chunk, Vector3(side*3.4,0.12,0), Vector3(0.35,0.55,SEGMENT), Color("#8090a0"))
		box(chunk, Vector3(side*3.55,1.28,0), Vector3(0.18,0.19,SEGMENT), Color("#704839"))
		for i in range(3):
			var z := -6.0+i*6.0
			box(chunk, Vector3(side*3.5,0.75,z), Vector3(0.36,1.5,0.36), Color("#758397"))
			box(chunk, Vector3(side*3.5,1.5,z), Vector3(0.50,0.18,0.50), Color("#966644"))
			if i%2 == 0:
				box(chunk, Vector3(side*3.5,2.1,z), Vector3(0.13,1.15,0.13), Color("#4c4050"))
				orb(chunk, Vector3(side*3.5,2.7,z), Vector3(0.52,0.64,0.52), Color("#ffd079"))
			else:
				box(chunk, Vector3(side*3.65,0.5,z), Vector3(0.76,0.65,0.76), Color("#8c766c"))
				for k in range(4):
					orb(chunk, Vector3(side*3.65+cos(k*1.57)*0.25,1.05,z+sin(k*1.57)*0.25), Vector3(0.65,0.8,0.65), Color("#438f52"))
		if index%2==0:
			var island := CylinderMesh.new()
			island.top_radius = 2.8
			island.bottom_radius = 0.5
			island.height = 3.5
			mesh(chunk,island,Vector3(side*8,-1.8,-4),Color("#6f8195"))
			var grass := CylinderMesh.new()
			grass.top_radius = 2.65
			grass.bottom_radius = 2.65
			grass.height = 0.35
			mesh(chunk,grass,Vector3(side*8,0,-4),Color("#64a66a"))
			var tower := CylinderMesh.new()
			tower.top_radius=0.8
			tower.bottom_radius=0.9
			tower.height=3.2
			mesh(chunk,tower,Vector3(side*8,1.6,-4),Color("#e2d1b9"))
			var roof := CylinderMesh.new()
			roof.top_radius=0.05
			roof.bottom_radius=1.05
			roof.height=1.6
			mesh(chunk,roof,Vector3(side*8,4,-4),Color("#486799"))
	if index%3==1:
		for side in [-1,1]:
			box(chunk,Vector3(side*3.3,2.0,-4),Vector3(0.7,4.0,0.7),Color("#a6a1a0"))
		for i in range(13):
			var angle := PI*i/12.0
			var n := box(chunk,Vector3(cos(angle)*3.3,3.8+sin(angle)*3.3,-4),Vector3(0.8,0.7,0.8),Color("#b9ad9b"))
			n.rotation.z=angle

func make_player() -> void:
	player = CharacterBody3D.new()
	player.collision_layer = 2
	player.collision_mask = 1
	add_child(player)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius=0.48
	capsule.height=1.35
	collision.shape=capsule
	collision.position.y=0.68
	player.add_child(collision)
	player_shape=collision
	mascot=Node3D.new()
	player.add_child(mascot)
	mascot.rotation.y=PI
	if using_blender and asset(mascot,"mosskit",Vector3.ZERO)!=null:
		for side in [-1,1]:
			var foot := asset(mascot,"foot",Vector3(side*0.37,0.20,0.16))
			if foot!=null: foot.rotation.y=PI
			if foot!=null: feet.append(foot)
		return
	orb(mascot,Vector3(0,0.85,0),Vector3(1.48,1.52,1.2),Color("#8bdc42"))
	for side in [-1,1]:
		var ear := orb(mascot,Vector3(side*0.48,1.60,0),Vector3(0.43,0.77,0.35),Color("#91de47"))
		ear.rotation.z=side*-0.37
		var inner := orb(mascot,Vector3(side*0.48,1.61,0.13),Vector3(0.25,0.53,0.15),Color("#f0a3ac"))
		inner.rotation.z=side*-0.37
		orb(mascot,Vector3(side*0.29,1.02,0.54),Vector3(0.33,0.48,0.13),Color("#292039"))
		orb(mascot,Vector3(side*0.29-0.05,1.13,0.61),Vector3(0.11,0.14,0.045),Color.WHITE)
		orb(mascot,Vector3(side*0.47,0.78,0.46),Vector3(0.22,0.12,0.08),Color("#f18c9e"))
		feet.append(orb(mascot,Vector3(side*0.37,0.20,0.16),Vector3(0.68,0.4,0.67),Color("#73bf38")))
	orb(mascot,Vector3(0,0.72,0.61),Vector3(0.28,0.25,0.09),Color("#4b253e"))
	orb(mascot,Vector3(0,0.65,0.66),Vector3(0.17,0.085,0.04),Color("#ee7296"))

func panel_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=bg
	style.border_color=border
	style.shadow_color=Color(0.22,0.48,0.95,0.32)
	style.shadow_size=4
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left=12
	style.content_margin_right=12
	style.content_margin_top=7
	style.content_margin_bottom=7
	return style

func hud_label(parent: Control, value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text=value
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func style_button(button: Button, gold := false) -> void:
	button.add_theme_stylebox_override("normal",panel_style(Color("#b76b25") if gold else Color("#303567"),Color("#ffd997") if gold else Color("#a6c9ff"),13))
	button.add_theme_stylebox_override("pressed",panel_style(Color("#81501f") if gold else Color("#4e5291"),Color("#fff1bd"),13))
	button.add_theme_font_size_override("font_size",20)
	button.add_theme_color_override("font_color",Color("#fff5df"))

func make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	layer.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	ui.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left=10
	panel.offset_right=-10
	panel.offset_top=10
	panel.offset_bottom=145
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",panel_style(Color("#182344ef"),Color("#91baff"),18))
	var column := VBoxContainer.new()
	column.mouse_filter=Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation",5)
	panel.add_child(column)
	var header := HBoxContainer.new()
	header.mouse_filter=Control.MOUSE_FILTER_IGNORE
	column.add_child(header)
	hud_label(header,"FOREVER\nPET",14,Color("#c1d9ff"))
	status=hud_label(header,"PET DASH",29,Color("#ffdc87"))
	audio_button=Button.new()
	audio_button.text="SFX"
	style_button(audio_button)
	audio_button.pressed.connect(func():
		audio.call("toggle")
		audio_button.text="SFX" if audio.get("enabled") else "Mute")
	header.add_child(audio_button)
	pause_button=Button.new()
	pause_button.text="Ⅱ"
	pause_button.custom_minimum_size=Vector2(52,40)
	style_button(pause_button)
	pause_button.pressed.connect(toggle_pause)
	header.add_child(pause_button)
	var stats := HBoxContainer.new()
	stats.mouse_filter=Control.MOUSE_FILTER_IGNORE
	column.add_child(stats)
	score_label=hud_label(stats,"0 m",20,Color("#f0f1ff"))
	coin_label=hud_label(stats,"0 coins",20,Color("#ffd775"))
	snack_label=hud_label(stats,"0 snacks",20,Color("#a9e2bd"))
	hud_label(column,"SKY BRIDGE  •  Collect snacks for your pet!",16,Color("#cbd9ff"))
	power_label=hud_label(column,"MAGNET  •  SHIELD  •  ×2  •  BOOST",15,Color("#e9d5ff"))
	var footer := PanelContainer.new()
	ui.add_child(footer)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left=12
	footer.offset_right=-12
	footer.offset_top=-84
	footer.offset_bottom=-12
	footer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	footer.add_theme_stylebox_override("panel",panel_style(Color("#202647eb"),Color("#b9aaff"),18))
	var bottom := HBoxContainer.new()
	bottom.mouse_filter=Control.MOUSE_FILTER_IGNORE
	footer.add_child(bottom)
	hint=hud_label(bottom,"Swipe to start",17,Color("#f1ebff"))
	var exit := Button.new()
	exit.text="Exit & collect"
	exit.custom_minimum_size=Vector2(148,48)
	style_button(exit,true)
	exit.pressed.connect(finish_run)
	bottom.add_child(exit)
	result_panel=PanelContainer.new()
	ui.add_child(result_panel)
	result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_panel.offset_left=-195
	result_panel.offset_right=195
	result_panel.offset_top=-120
	result_panel.offset_bottom=120
	result_panel.add_theme_stylebox_override("panel",panel_style(Color("#202b4b"),Color("#a9c8ff"),20))
	var result_box := VBoxContainer.new()
	result_box.add_theme_constant_override("separation",12)
	result_panel.add_child(result_box)
	result_text=hud_label(result_box,"",24,Color("#f9e4b4"))
	result_button=Button.new()
	result_button.custom_minimum_size=Vector2(0,52)
	style_button(result_button,true)
	result_button.pressed.connect(func():
		if ended:
			get_tree().reload_current_scene()
		else:
			toggle_pause())
	result_box.add_child(result_button)
	result_panel.hide()
	update_hud()

func finish_run() -> void:
	if not ended:
		ended=true
		paused_run=false
		update_hud()

func fill_track() -> void:
	while spawn_at<distance+95:
		# Every obstacle row has at least one reachable lane; adjacent safe lanes
		# change by at most one lane at a time. Alternate rows and clear runs.
		var free_lane := clampi(previous_safe_lane+rng.randi_range(-1,1),0,2)
		var blocked_lanes: Array[int] = []
		for i in range(3):
			if i!=free_lane: blocked_lanes.append(i)
		var first := rng.randi_range(0,1)
		if pattern_count%5!=4:
			make_entity(blocked_lanes[first],rng.randi_range(0,1),spawn_at)
			if pattern_count>=3 and pattern_count%3==0:
				make_entity(blocked_lanes[1-first],rng.randi_range(0,1),spawn_at)
		for i in range(5):
			make_entity(free_lane,PICKUP,spawn_at-3.2+i*1.5)
		if rng.randf()<0.55:
			make_entity(free_lane,SNACK,spawn_at+4.8)
		if pattern_count%4==2:
			make_entity(free_lane,MAGNET+rng.randi_range(0,3),spawn_at+7.4)
		previous_safe_lane=free_lane
		pattern_count+=1
		spawn_at+=maxf(12.0,speed*1.22)

func make_entity(which_lane: int, kind: int, at: float) -> void:
	var a: Area3D
	var recycled: bool = not pools[kind].is_empty()
	if recycled:
		a=pools[kind].pop_back()
		a.show()
		reused_entities+=1
	else:
		a=Area3D.new()
		created_entities+=1
		add_child(a)
	a.position=Vector3(LANES[which_lane],0,-(at-distance))
	a.monitoring=false
	a.monitorable=false
	a.set_meta("kind",kind)
	a.set_meta("at",at)
	a.set_meta("resolved",false)
	entities.append(a)
	if recycled:
		if a.get_child_count()>0: (a.get_child(0) as Node3D).rotation.y=0
		return
	if using_blender and asset(a,["crate","barrier","coin","snack","magnet","shield","double","boost"][kind],Vector3.ZERO)!=null:
		return
	if kind==0:
		box(a,Vector3(0,0.45,0),Vector3(1.30,0.90,0.9),Color("#9c5b37"))
		for side in [-1,1]:
			box(a,Vector3(side*0.55,0.45,0.47),Vector3(0.14,0.86,0.07),Color("#d4a46c"))
		box(a,Vector3(0,0.76,0.48),Vector3(1.15,0.10,0.07),Color("#d4a46c"))
	elif kind==1:
		for side in [-1,1]:
			box(a,Vector3(side*0.65,0.83,0),Vector3(0.20,1.66,0.28),Color("#35496d"))
		box(a,Vector3(0,1.45,0),Vector3(1.52,0.42,0.32),Color("#d99547"))
		for side in [-1,1]:
			orb(a,Vector3(side*0.57,1.83,0),Vector3(0.23,0.24,0.23),Color("#ffd367"))
	elif kind==PICKUP:
		var ring := CylinderMesh.new()
		ring.top_radius=0.31
		ring.bottom_radius=0.31
		ring.height=0.12
		var coin := mesh(a,ring,Vector3(0,0.75,0),Color("#ffd05a"),0.55)
		coin.rotation.x=PI/2
	elif kind==SNACK:
		orb(a,Vector3(0,0.75,0),Vector3(0.68,0.45,0.68),Color("#607fbc"))
		for i in range(5):
			orb(a,Vector3(cos(i*1.26)*0.19,0.99,sin(i*1.26)*0.19),Vector3(0.16,0.13,0.16),Color("#e1ae5a"))
	else:
		orb(a,Vector3(0,0.85,0),Vector3(0.85,0.85,0.85),[Color.RED,Color.CYAN,Color.GOLD,Color.DEEP_SKY_BLUE][kind-MAGNET])

func toggle_pause() -> void:
	if not ended:
		paused_run=not paused_run
		touch_active=false
		touch_id=-1
		update_hud()

func gesture(delta: Vector2) -> void:
	if ended or paused_run:
		return
	started=true
	if absf(delta.x)>absf(delta.y) and absf(delta.x)>22:
		lane=clampi(lane+(1 if delta.x>0 else -1),0,2)
	elif delta.y < -22:
		if player.is_on_floor() and slide<=0:
			player.velocity.y=JUMP_SPEED
			audio.call("play_fx","jump")
		else:
			jump_buffer=0.14
	elif delta.y > 22:
		jump_buffer=0
		if player.is_on_floor():
			slide=0.65
			audio.call("play_fx","slide")
		else: player.velocity.y=minf(player.velocity.y,-13)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not touch_active:
			touch_start=event.position
			touch_active=true
			gesture_sent=false
			touch_id=event.index
		elif not event.pressed and event.index==touch_id:
			touch_active=false
			if not gesture_sent: gesture(event.position-touch_start)
			touch_id=-1
	elif event is InputEventScreenDrag and touch_active and event.index==touch_id:
		if not gesture_sent and (event.position-touch_start).length()>=24:
			gesture_sent=true
			gesture(event.position-touch_start)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.device!=InputEvent.DEVICE_ID_EMULATION:
		if event.pressed:
			touch_start=event.position
			touch_active=true
		elif touch_active:
			touch_active=false
			gesture(event.position-touch_start)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT: gesture(Vector2(-80,0))
			KEY_RIGHT: gesture(Vector2(80,0))
			KEY_UP,KEY_SPACE: gesture(Vector2(0,-80))
			KEY_DOWN: gesture(Vector2(0,80))
			KEY_P: toggle_pause()

func _physics_process(dt: float) -> void:
	if ended or paused_run:
		return
	player.velocity.y-=GRAVITY*dt
	var capsule := player_shape.shape as CapsuleShape3D
	capsule.height=0.96 if slide>0 else 1.35
	player_shape.position.y=capsule.height*0.5
	player.velocity.x=clampf((LANES[lane]-player.position.x)*14,-15,15)
	player.move_and_slide()
	player.position.z=PLAYER_Z
	if jump_buffer>0:
		if player.is_on_floor() and slide<=0:
			player.velocity.y=JUMP_SPEED
			jump_buffer=0
		else: jump_buffer=maxf(0,jump_buffer-dt)
	if not started:
		return
	clock+=dt
	magnet_time=maxf(0,magnet_time-dt)
	shield_time=maxf(0,shield_time-dt)
	double_time=maxf(0,double_time-dt)
	boost_time=maxf(0,boost_time-dt)
	speed=minf(20.0,9.0+distance*0.018)+(4.0 if boost_time>0 else 0.0)
	distance+=speed*dt
	slide=maxf(0,slide-dt)
	mascot.scale.y=lerpf(mascot.scale.y,0.48 if slide>0 else 1.0, minf(1,dt*16))
	mascot.rotation.y=PI+clampf(player.velocity.x*0.023,-0.24,0.24)
	mascot.rotation.z=lerpf(mascot.rotation.z,clampf(player.velocity.x*0.025,-0.24,0.24),dt*8)
	mascot.position.y=0.035*(1+sin(clock*32)) if player.is_on_floor() and slide<=0 else 0.0
	if player.is_on_floor() and slide<=0 and clock>=next_step:
		next_step=clock+0.19
		audio.call("play_fx","step")
	update_effects(dt)
	for i in range(feet.size()):
		feet[i].position.z=0.16+sin(clock*16+i*PI)*0.25 if player.is_on_floor() and slide<=0 else 0.16
		feet[i].position.y=0.20+maxf(0,sin(clock*16+i*PI))*0.18 if player.is_on_floor() and slide<=0 else 0.20
	for chunk in chunks:
		chunk.position.z+=speed*dt
		if chunk.position.z>SEGMENT*1.5:
			chunk.position.z-=SEGMENTS*SEGMENT
	for i in range(entities.size()-1,-1,-1):
		var a:=entities[i]
		var old_z:=a.position.z
		a.position.z=float(a.get_meta("at"))*-1+distance
		var kind:=int(a.get_meta("kind"))
		if kind>=PICKUP and a.get_child_count()>0:
			(a.get_child(0) as Node3D).rotation.y+=dt*2.5
		# Test the full swept depth interval, with the same world sizes as the meshes.
		var contact := maxf(old_z,a.position.z)>=-0.80 and minf(old_z,a.position.z)<=0.80
		var attraction := kind==PICKUP and magnet_time>0 and absf(a.position.z)<5.0
		if attraction: a.position.x=move_toward(a.position.x,player.position.x,dt*19)
		if (contact or attraction) and not bool(a.get_meta("resolved")) and absf(a.position.x-player.position.x)<0.92:
			if kind>=PICKUP:
				if player.position.y<1.1 or attraction:
					collect_kind(kind)
					a.set_meta("resolved",true)
					a.hide()
			elif hazard_hit(kind,player.position.y,slide>0):
				if shield_time>0 or boost_time>0:
					if boost_time<=0: shield_time=0
					a.set_meta("resolved",true)
					a.hide()
					audio.call("play_fx","shield")
				else:
					ended=true
					audio.call("play_fx","crash")
					break
		if a.position.z>2.5:
			a.hide()
			pools[kind].append(a)
			entities.remove_at(i)
	fill_track()
	camera.position.x=lerpf(camera.position.x,player.position.x*0.18,minf(1,dt*6))
	update_hud()

func collect_kind(kind: int) -> void:
	match kind:
		PICKUP:
			coins+=2 if double_time>0 else 1
			audio.call("play_fx","coin")
		SNACK:
			snacks+=1
			audio.call("play_fx","snack")
		MAGNET:
			magnet_time=12.0
		SHIELD:
			shield_time=15.0
		DOUBLE:
			double_time=12.0
		BOOST:
			boost_time=6.0
	if kind>=MAGNET: audio.call("play_fx","power")

func make_effects() -> void:
	fx=Node3D.new()
	add_child(fx)
	for i in range(12):
		var p:=orb(fx,Vector3.ZERO,Vector3.ONE*0.14,Color("#f1dcc6"))
		p.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		p.hide()
		dust.append(p)
		dust_ages.append(-1.0)
	aura=orb(player,Vector3(0,0.9,0),Vector3(1.95,2.0,1.95),Color("#65d6ff"))
	var m:=StandardMaterial3D.new()
	m.albedo_color=Color(0.25,0.85,1.0,0.19)
	m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	aura.material_override=m
	aura.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	aura.hide()

func update_effects(dt:float) -> void:
	aura.visible=shield_time>0 or boost_time>0
	if player.is_on_floor() and slide<=0 and int(clock*15)!=int((clock-dt)*15):
		for i in range(dust.size()):
			if dust_ages[i]<0:
				dust[i].position=Vector3(player.position.x+sin(clock*17)*0.25,0.12,0.65)
				dust[i].show()
				dust_ages[i]=0
				break
	for i in range(dust.size()):
		if dust_ages[i]<0: continue
		dust_ages[i]+=dt
		dust[i].position.z+=speed*dt*0.7
		dust[i].position.y+=dt*0.34
		dust[i].scale=Vector3.ONE*(0.12+dust_ages[i]*0.33)
		if dust_ages[i]>0.5:
			dust[i].hide()
			dust_ages[i]=-1

func hazard_hit(kind: int, feet_y: float, sliding: bool) -> bool:
	if kind==0: return feet_y<0.90
	if kind==1: return feet_y+(0.74 if sliding else 1.55)>1.16
	return false

func update_hud() -> void:
	var active_powers: Array[String]=[]
	if magnet_time>0: active_powers.append("MAGNET %ds"%ceili(magnet_time))
	if shield_time>0: active_powers.append("SHIELD %ds"%ceili(shield_time))
	if double_time>0: active_powers.append("×2 %ds"%ceili(double_time))
	if boost_time>0: active_powers.append("BOOST %ds"%ceili(boost_time))
	var powers: String="  •  ".join(active_powers)
	power_label.text=powers if not powers.is_empty() else "Collect power-ups to extend your run"
	var key := str(int(distance))+":"+str(coins)+":"+str(snacks)+":"+str(ended)+":"+str(paused_run)+":"+str(started)
	if key==last_hud: return
	last_hud=key
	score_label.text="%d m"%int(distance)
	coin_label.text="%d coins"%coins
	snack_label.text="%d snacks"%snacks
	hint.text="Run complete" if ended else "Paused" if paused_run else "← →  lanes  •  ↑ jump  •  ↓ slide" if started else "Swipe to start"
	pause_button.disabled=ended
	result_panel.visible=ended or paused_run
	if ended:
		result_text.text="RUN COMPLETE\n%d m  •  %d coins\n%d snacks collected"%[int(distance),coins,snacks]
		result_button.text="Run again"
	elif paused_run:
		result_text.text="PAUSED"
		result_button.text="Resume"

func claim_result() -> Dictionary:
	if session_claimed or not ended:
		return {}
	session_claimed=true
	return {"distance":int(distance),"coins":coins,"snacks":snacks}

func test_run() -> void:
	# Deterministic headless scene boot + input, track generation and reward idempotence.
	await get_tree().physics_frame
	await get_tree().physics_frame
	gesture(Vector2(-80,0))
	assert(lane==0 and started)
	gesture(Vector2(80,0))
	assert(lane==1)
	assert(chunks.size()==SEGMENTS and entities.size()>10)
	assert((mascot.transform.basis*Vector3.BACK).z < -0.99,"mascot must face away")
	assert(using_blender and loaded_assets>20,"Blender assets missing or not instantiated")
	# Isolate control tests from randomly spawned obstacles.
	for entity in entities: entity.queue_free()
	entities.clear()
	spawn_at=distance+1000
	assert(hazard_hit(0,0,false) and not hazard_hit(0,1.1,false))
	assert(hazard_hit(1,0,false) and not hazard_hit(1,0,true))
	gesture(Vector2(0,-80))
	for i in range(15): await get_tree().physics_frame
	assert(player.position.y>0.9)
	for i in range(55): await get_tree().physics_frame
	assert(player.is_on_floor())
	gesture(Vector2(0,80))
	assert(slide>0)
	for i in range(45): await get_tree().physics_frame
	assert(slide==0)
	var old_distance:=distance
	for i in range(20):
		await get_tree().physics_frame
	assert(distance>old_distance)
	toggle_pause()
	var frozen:=distance
	for i in range(3):
		await get_tree().physics_frame
	assert(distance==frozen)
	toggle_pause()
	make_entity(1,PICKUP,distance+0.6)
	for i in range(30): await get_tree().physics_frame
	assert(coins==1 and not ended)
	assert(not pools[PICKUP].is_empty())
	var count_before:=created_entities
	make_entity(1,PICKUP,distance+0.6)
	assert(created_entities==count_before and reused_entities>0)
	for i in range(30): await get_tree().physics_frame
	assert(coins==2 and not ended)
	collect_kind(DOUBLE)
	collect_kind(PICKUP)
	assert(coins==4 and double_time>0)
	collect_kind(MAGNET)
	make_entity(0,PICKUP,distance+3.0)
	for i in range(35): await get_tree().physics_frame
	assert(coins==6 and magnet_time>0)
	collect_kind(SHIELD)
	make_entity(1,0,distance+1.0)
	for i in range(20): await get_tree().physics_frame
	assert(not ended and shield_time==0)
	collect_kind(BOOST)
	assert(boost_time>0)
	boost_time=0
	make_entity(1,0,distance+1.0)
	for i in range(20): await get_tree().physics_frame
	assert(ended and result_panel.visible)
	assert(not claim_result().is_empty() and claim_result().is_empty())
	print("PET_DASH_3D_SMOKE_PASS")
	get_tree().quit(0)

func capture_review() -> void:
	# Actual rendered game frame, not a mockup. Show the first playable section.
	await get_tree().process_frame
	started=true
	for i in range(45): await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var result := image.save_png("/tmp/pet-dash-review.png")
	assert(result==OK)
	print("PET_DASH_RENDER_CAPTURE_OK")
	get_tree().quit(0)
