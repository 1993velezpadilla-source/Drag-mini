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
var spawn_at := 20.0
var status: Label
var hint: Label
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
	e.ambient_light_color = Color("#b9d7ff")
	e.ambient_light_energy = 0.65
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_color = Color("#ffdfb0")
	sun.light_energy = 1.3
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
	camera.position = Vector3(0, 4.15, 7.7)
	camera.fov = 63
	add_child(camera)
	camera.look_at(Vector3(0, 1.8, -15))
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
	if using_blender and asset(mascot,"mosskit",Vector3.ZERO)!=null:
		for side in [-1,1]:
			var foot := asset(mascot,"foot",Vector3(side*0.37,0.20,0.16))
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

func make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_bottom=80
	var style := StyleBoxFlat.new()
	style.bg_color=Color("#17213de8")
	style.border_color=Color("#83bdfb")
	style.set_border_width_all(2)
	style.set_corner_radius_all(15)
	panel.add_theme_stylebox_override("panel",style)
	layer.add_child(panel)
	var row := HBoxContainer.new()
	panel.add_child(row)
	status=Label.new()
	status.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	status.add_theme_font_size_override("font_size",24)
	row.add_child(status)
	var pause_btn := Button.new()
	pause_btn.text="Pause"
	pause_btn.custom_minimum_size=Vector2(95,64)
	pause_btn.pressed.connect(toggle_pause)
	row.add_child(pause_btn)
	hint=Label.new()
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top=-110
	hint.offset_bottom=-45
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size",20)
	layer.add_child(hint)
	var retry := Button.new()
	retry.text="Restart"
	retry.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	retry.offset_left=-80
	retry.offset_right=80
	retry.offset_top=-48
	retry.pressed.connect(func(): get_tree().reload_current_scene())
	layer.add_child(retry)
	update_hud()

func fill_track() -> void:
	while spawn_at<distance+95:
		var free_lane := rng.randi_range(0,2)
		var blocked := (free_lane+1+rng.randi_range(0,1))%3
		make_entity(blocked,rng.randi_range(0,1),spawn_at)
		for i in range(4):
			make_entity(free_lane,PICKUP,spawn_at-3.0+i*1.5)
		if rng.randf()<0.45:
			make_entity(free_lane,SNACK,spawn_at+3.8)
		spawn_at+=maxf(10.0,speed*1.35)

func make_entity(which_lane: int, kind: int, at: float) -> void:
	var a := Area3D.new()
	a.position=Vector3(LANES[which_lane],0,-(at-distance))
	a.monitoring=false
	a.monitorable=false
	a.set_meta("kind",kind)
	a.set_meta("at",at)
	a.set_meta("resolved",false)
	add_child(a)
	entities.append(a)
	if using_blender and asset(a,["crate","barrier","coin","snack"][kind],Vector3.ZERO)!=null:
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
	else:
		orb(a,Vector3(0,0.75,0),Vector3(0.68,0.45,0.68),Color("#607fbc"))
		for i in range(5):
			orb(a,Vector3(cos(i*1.26)*0.19,0.99,sin(i*1.26)*0.19),Vector3(0.16,0.13,0.16),Color("#e1ae5a"))

func toggle_pause() -> void:
	if not ended:
		paused_run=not paused_run
		update_hud()

func gesture(delta: Vector2) -> void:
	if ended or paused_run:
		return
	started=true
	if absf(delta.x)>absf(delta.y) and absf(delta.x)>22:
		lane=clampi(lane+(1 if delta.x>0 else -1),0,2)
	elif delta.y < -22 and player.is_on_floor() and slide<=0:
		player.velocity.y=JUMP_SPEED
	elif delta.y > 22 and player.is_on_floor():
		slide=0.65

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start=event.position
			touch_active=true
		elif touch_active:
			touch_active=false
			gesture(event.position-touch_start)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
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
	if not started:
		return
	clock+=dt
	speed=minf(20.0,9.0+distance*0.018)
	distance+=speed*dt
	slide=maxf(0,slide-dt)
	mascot.scale.y=lerpf(mascot.scale.y,0.48 if slide>0 else 1.0, minf(1,dt*16))
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
		if kind==PICKUP and a.get_child_count()>0:
			(a.get_child(0) as Node3D).rotation.y+=dt*2.5
		# Test the full swept depth interval, with the same world sizes as the meshes.
		var contact := maxf(old_z,a.position.z)>=-0.80 and minf(old_z,a.position.z)<=0.80
		if contact and not bool(a.get_meta("resolved")) and absf(a.position.x-player.position.x)<0.92:
			if kind>=PICKUP:
				if player.position.y<1.1:
					if kind==PICKUP: coins+=1
					else: snacks+=1
					a.set_meta("resolved",true)
					a.hide()
			elif hazard_hit(kind,player.position.y,slide>0):
				ended=true
		if a.position.z>2.5:
			a.queue_free()
			entities.remove_at(i)
	fill_track()
	camera.position.x=lerpf(camera.position.x,player.position.x*0.18,minf(1,dt*6))
	update_hud()

func hazard_hit(kind: int, feet_y: float, sliding: bool) -> bool:
	if kind==0: return feet_y<0.90
	if kind==1: return feet_y+(0.74 if sliding else 1.55)>1.16
	return false

func update_hud() -> void:
	status.text="PET DASH   %d m   •   %d coins   •   %d snacks"%[int(distance),coins,snacks]
	hint.text="RUN COMPLETE" if ended else "PAUSED" if paused_run else "Swipe lanes  •  Up: jump  •  Down: slide"

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
	assert(using_blender and loaded_assets>20)
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
	ended=true
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
