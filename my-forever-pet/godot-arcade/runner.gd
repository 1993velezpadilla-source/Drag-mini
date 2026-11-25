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
const CART := 8
const TALL := 9
const LOW_BAR := 10
const TIME_ORB := 11
const SPRING := 12
const SKY_RING := 13
const GEM := 14
const RESCUE := 15
const SMASH := 16
var rescued := 0
var rescue_time := 0.0
var rescue_buddy: Node3D
var smash_charges := 0
var smash_time := 0.0
var smashed := 0
var perfect_dodges := 0
var slow_time := 0.0
var spring_time := 0.0
var air_jump_used := false
var combo := 0
var best_combo := 0
var combo_timer := 0.0
var skill_points := 0
var skill_clears := 0
var sky_rings := 0
var gems := 0
var challenge_index := 0
var challenge_progress := 0
var challenge_label: Label
var challenge_bar: ProgressBar
var last_challenge_hud := ""
var skill_flash := 0.0
var skill_feedback: Label
var crash_remaining := 0.0
var crash_player_y := 0.0
var music_button: Button
var moving_rows := 0
var sky_ship:Node3D
var ship_origin:=Vector3.ZERO
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
var shadow_mesh: QuadMesh
var shadow_material: ShaderMaterial
var player_shadow: MeshInstance3D
var pickup_flash := 0.0
var pickup_feedback: Label
var best_score := 0
var best_saved := false
var review_driver := false
var safe_rows: Array[Vector3] = []
var peak_active := 0
var hud_refresh := 0.0
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
var pools: Array = [[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]]
var created_entities := 0
var reused_entities := 0
var previous_safe_lane := 1
var pattern_count := 0
var lane := 1
var slide := 0.0
var distance := 0.0
var distance_offset := 0.0
const REBASE_INTERVAL := 1024.0
var rebase_count := 0
var chunk_recycles := 0
var scenery_rng := RandomNumberGenerator.new()
var coins := 0
var snacks := 0
var speed := 9.0
var started := false
var ended := false
var retired_run := false
var retire_button: Button
var paused_run := false
var touch_start := Vector2.ZERO
var touch_active := false
var gesture_sent := false
var touch_id := -1
var spawn_at := 15.0
var status: Label
var hint: Label
var score_label: Label
var points_label: Label
var coin_label: Label
var snack_label: Label
var pause_button: Button
var result_panel: PanelContainer
var result_text: Label
var result_button: Button
var last_hud := ""
var last_power_hud := ""
var scenery_visibility_updates := 0
var jump_buffer := 0.0
var air_slide_pending := false
var lane_impulse := 0.0
var scene_anim: Array[Node3D] = []
var scene_anim_origins: Array[Vector3] = []
var speed_lines: Array[MeshInstance3D] = []
var speed_line_mat: StandardMaterial3D
var power_ring: MeshInstance3D
var last_input_dir := Vector2.ZERO
const SLIDE_SECONDS := 0.70
const FAST_FALL := 22.0
var mandatory_rows := 0
var driver_action_at := -1.0
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
	# Let imported mesh LODs transition earlier for distant scenery, not the player.
	if name in ["bridge","arch","island"]:
		for child in n.find_children("*","MeshInstance3D",true,false):
			(child as MeshInstance3D).lod_bias=0.65
	# Tiny collectibles and distant islands do not need expensive shadow passes.
	if name in ["coin","snack","magnet","shield","double","boost","island","airship","rainbow","time_orb","spring","sky_ring","gem","rescue","smash"]:
		for child in n.find_children("*","MeshInstance3D",true,false):
			(child as MeshInstance3D).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(n)
	n.position=pos
	loaded_assets+=1
	return n

func _ready() -> void:
	using_blender=ResourceLoader.exists("res://assets/bridge.glb")
	review_driver=OS.get_cmdline_user_args().has("--soak") or OS.get_cmdline_user_args().has("--capture")
	rng.seed = 7319 if OS.get_cmdline_user_args().has("--test") or review_driver else Time.get_ticks_usec()
	scenery_rng.seed=uint64_seed(rng.seed)
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
	if ResourceLoader.exists("res://assets/sky-panorama.png"):
		var panorama:=PanoramaSkyMaterial.new()
		panorama.panorama=load("res://assets/sky-panorama.png")
		sky.sky_material=panorama
	else: sky.sky_material=sky_mat
	e.sky=sky
	e.background_mode=Environment.BG_SKY
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#c5d9ee")
	e.ambient_light_energy = 0.28
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_color = Color("#ffdfb0")
	sun.light_energy = 0.66
	sun.light_specular=0.3
	sun.directional_shadow_max_distance=30.0
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
	update_scenery_visibility()
	make_player()
	make_ground_shadow_resources()
	player_shadow=ground_shadow(self,1.8,1.3)
	camera = Camera3D.new()
	camera.position = Vector3(0, 4.55, 7.8)
	camera.fov = 58
	camera.far=140
	add_child(camera)
	camera.look_at(Vector3(0, 1.1, -12))
	make_cloudscape()
	make_effects()
	rescue_buddy=asset(self,"rescue",Vector3(0,0,1.55))
	if rescue_buddy!=null:
		rescue_buddy.scale=Vector3.ONE*0.64
		rescue_buddy.rotation.y=PI
		rescue_buddy.hide()
	audio=preload("res://dash_audio.gd").new()
	add_child(audio)
	load_best()
	make_hud()
	fill_track()
	if OS.get_cmdline_user_args().has("--test"):
		call_deferred("test_run")
	elif OS.get_cmdline_user_args().has("--capture"):
		call_deferred("capture_review")
	elif OS.get_cmdline_user_args().has("--soak"):
		call_deferred("soak_review")

func make_cloudscape() -> void:
	# Actual animated 3D airship and sky arch, not a screenshot overlay.
	sky_ship=asset(self,"airship",Vector3(-12.0,12.0,-40.0))
	if sky_ship!=null:
		ship_origin=sky_ship.position
		sky_ship.scale=Vector3.ONE*1.5
	var rainbow:=asset(self,"rainbow",Vector3(0,1.5,-72.0))
	if rainbow!=null: rainbow.scale=Vector3.ONE*2.2
	# Panorama supplies clouds; real distant GLB islands add silhouettes and depth.
	# Fixed world backdrop avoids spawning high-cost scenery per track row.
	for i in range(6):
		var side:float=-1.0 if i%2==0 else 1.0
		var island:=asset(self,"island",Vector3(side*(17.0+float(i%3)*7),5.0+float(i%3)*4,-39.0-float(i)*11))
		if island!=null:
			island.scale=Vector3.ONE*(1.5+float(i%3)*0.22)
			island.rotation.y=float(i)*0.8
			scene_anim.append(island)
			scene_anim_origins.append(island.position)

func uint64_seed(value:int) -> int:
	return value ^ 0x51CEB00C

func refresh_chunk_decor(chunk:Node3D) -> void:
	for child in chunk.get_children():
		if not child.has_meta("scenery_island"): continue
		var island:=child as Node3D
		var side:float=float(island.get_meta("scenery_island"))
		island.position.x=side*scenery_rng.randf_range(8.0,10.8)
		island.position.y=scenery_rng.randf_range(-0.3,2.0)
		island.rotation.y=scenery_rng.randf_range(-0.35,0.35)
		island.scale=Vector3.ONE*scenery_rng.randf_range(0.95,1.30)

func make_chunk(chunk: Node3D, index: int) -> void:
	if using_blender and asset(chunk,"bridge",Vector3.ZERO)!=null:
		if index%2==1: asset(chunk,"arch",Vector3(0,0,-4))
		if index%2==0:
			for side in [-1,1]:
				var island:=asset(chunk,"island",Vector3(side*(8.0+float(index%3)),float(index%3)*1.3,-4))
				if island!=null:
					island.set_meta("scenery_island",side)
					island.scale=Vector3.ONE*(1.0+float(index%3)*0.12)
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

func update_scenery_visibility() -> void:
	# Chunks remain pooled. The far scenery is beyond the useful portrait view.
	for chunk in chunks:
		chunk.visible=chunk.position.z > -90.0 and chunk.position.z < 24.0
	scenery_visibility_updates+=1

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
	points_label=hud_label(stats,"0 pts",18,Color("#ffdc87"))
	score_label=hud_label(stats,"0 m",18,Color("#f0f1ff"))
	coin_label=hud_label(stats,"0 coins",18,Color("#ffd775"))
	snack_label=hud_label(stats,"0 snacks",18,Color("#a9e2bd"))
	hud_label(column,"LITTLE MOSSKIT  •  ENDLESS RUN",16,Color("#cbd9ff"))
	power_label=hud_label(column,"MAGNET  •  SHIELD  •  ×2  •  BOOST",15,Color("#e9d5ff"))
	challenge_label=hud_label(column,"Collect 15 coins",14,Color("#ffe5a4"))
	challenge_bar=ProgressBar.new()
	challenge_bar.show_percentage=false
	challenge_bar.custom_minimum_size.y=6
	challenge_bar.add_theme_stylebox_override("background",panel_style(Color("#15213c"),Color("#354b73"),4))
	challenge_bar.add_theme_stylebox_override("fill",panel_style(Color("#e8b64e"),Color("#f9db89"),4))
	challenge_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	column.add_child(challenge_bar)
	var footer := PanelContainer.new()
	ui.add_child(footer)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left=12
	footer.offset_right=-12
	footer.offset_top=-103
	footer.offset_bottom=-12
	footer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	footer.add_theme_stylebox_override("panel",panel_style(Color("#202647eb"),Color("#b9aaff"),18))
	pickup_feedback=Label.new()
	ui.add_child(pickup_feedback)
	pickup_feedback.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	pickup_feedback.offset_left=-150
	pickup_feedback.offset_right=150
	pickup_feedback.offset_top=-205
	pickup_feedback.offset_bottom=-160
	pickup_feedback.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	pickup_feedback.add_theme_font_size_override("font_size",25)
	pickup_feedback.add_theme_color_override("font_color",Color("#ffe18a"))
	pickup_feedback.add_theme_color_override("font_outline_color",Color("#253458"))
	pickup_feedback.add_theme_constant_override("outline_size",6)
	pickup_feedback.mouse_filter=Control.MOUSE_FILTER_IGNORE
	pickup_feedback.hide()
	skill_feedback=Label.new()
	ui.add_child(skill_feedback)
	skill_feedback.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	skill_feedback.offset_left=-230
	skill_feedback.offset_right=230
	skill_feedback.offset_top=-105
	skill_feedback.offset_bottom=-60
	skill_feedback.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	skill_feedback.add_theme_font_size_override("font_size",28)
	skill_feedback.add_theme_color_override("font_color",Color("#ffe297"))
	skill_feedback.add_theme_color_override("font_outline_color",Color("#252655"))
	skill_feedback.add_theme_constant_override("outline_size",6)
	skill_feedback.mouse_filter=Control.MOUSE_FILTER_IGNORE
	skill_feedback.hide()
	var bottom := HBoxContainer.new()
	bottom.mouse_filter=Control.MOUSE_FILTER_IGNORE
	footer.add_child(bottom)
	var controls:=VBoxContainer.new()
	controls.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	controls.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bottom.add_child(controls)
	hint=hud_label(controls,"Swipe left / right",14,Color("#f1ebff"))
	var actions:=HBoxContainer.new()
	actions.mouse_filter=Control.MOUSE_FILTER_IGNORE
	controls.add_child(actions)
	for action in ["↑ Jump","↓ Slide"]:
		var button:=Button.new()
		button.text=action
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y=38
		style_button(button)
		button.add_theme_font_size_override("font_size",16)
		var delta:=Vector2(0,-80 if action=="↑ Jump" else 80)
		button.button_down.connect(func(): gesture(delta))
		actions.add_child(button)
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
	retire_button=Button.new()
	retire_button.text="End run & collect"
	retire_button.custom_minimum_size.y=48
	style_button(retire_button,true)
	retire_button.pressed.connect(retire_run)
	result_box.add_child(retire_button)
	retire_button.hide()
	music_button=Button.new()
	music_button.text="Music: ON"
	style_button(music_button)
	music_button.pressed.connect(func():
		audio.call("toggle_music")
		music_button.text="Music: ON" if audio.get("music_enabled") else "Music: OFF")
	result_box.add_child(music_button)
	music_button.hide()
	result_panel.hide()
	update_hud()

func retire_run() -> void:
	# Only a deliberate choice from Pause may end a non-crashed endless run.
	if not ended and paused_run:
		audio.call("stop_music")
		retired_run=true
		ended=true
		paused_run=false
		update_hud()

func total_distance() -> float:
	return distance_offset+distance

func rebase_track() -> void:
	if distance<REBASE_INTERVAL: return
	var shift:=floorf(distance/REBASE_INTERVAL)*REBASE_INTERVAL
	distance-=shift
	distance_offset+=shift
	spawn_at-=shift
	for a in entities: a.set_meta("at",float(a.get_meta("at"))-shift)
	for i in range(safe_rows.size()): safe_rows[i].x-=shift
	driver_action_at-=shift
	rebase_count+=1

func is_pickup(kind:int) -> bool:
	return (kind>=PICKUP and kind<=BOOST) or (kind>=TIME_ORB and kind<=SMASH)

func hazard_for(tier:int) -> int:
	if tier==0: return rng.randi_range(0,1)
	var choices:Array[int]=[0,1,LOW_BAR,CART]
	if tier>=2: choices.append(TALL)
	return choices[rng.randi_range(0,choices.size()-1)]

func fill_track() -> void:
	while spawn_at<distance+95:
		var free_lane:=clampi(previous_safe_lane+rng.randi_range(-1,1),0,2)
		var blocked_lanes:Array[int]=[]
		for i in range(3):
			if i!=free_lane: blocked_lanes.append(i)
		var tier:=mini(3,int((distance_offset+spawn_at)/85.0))
		var first:=rng.randi_range(0,1)
		var action:=-1
		# After the warm-up, occasional full-width obstacle rows require a
		# vertical action. The recommended lane stays reachable laterally.
		if tier>=1 and pattern_count%7==5:
			action=0 if pattern_count%2==1 else 1
			for i in range(3): make_entity(i,action,spawn_at)
			mandatory_rows+=1
		elif tier>=2 or pattern_count%5!=4:
			var kind:=hazard_for(tier)
			make_entity(blocked_lanes[first],kind,spawn_at)
			if kind==CART: moving_rows+=1
			if tier>=2 or (pattern_count>=3 and pattern_count%3==0):
				var second:=hazard_for(tier)
				make_entity(blocked_lanes[1-first],second,spawn_at)
				if second==CART: moving_rows+=1
		# Keep collectible trails clear of the mandatory hazard itself.
		if action<0:
			for i in range(5): make_entity(free_lane,PICKUP,spawn_at-3.2+i*1.5)
		else:
			for offset in [-3.2,-1.8,1.8,3.2]: make_entity(free_lane,PICKUP,spawn_at+offset)
		if pattern_count%5==2:
			var power:=MAGNET+rng.randi_range(0,3)
			if tier>=1 and pattern_count%15==2: power=TIME_ORB
			elif tier>=1 and pattern_count%15==7: power=SPRING
			elif tier>=2 and pattern_count%15==12: power=SMASH
			make_entity(free_lane,power,spawn_at+5.1)
		elif rng.randf()<0.60:
			make_entity(free_lane,SNACK,spawn_at+4.8)
		if tier>=1 and action<0 and pattern_count%9==3:
			# Optional airborne route; ground coins remain available.
			make_entity(free_lane,SKY_RING,spawn_at)
		if tier>=1 and action<0 and pattern_count%11==8:
			make_entity(free_lane,GEM,spawn_at+6.7)
		if tier>=1 and action<0 and pattern_count%12==9:
			make_entity(free_lane,RESCUE,spawn_at+7.8)
		if review_driver: safe_rows.append(Vector3(spawn_at,float(free_lane),float(action)))
		previous_safe_lane=free_lane
		pattern_count+=1
		var projected_speed:=minf(25.0,9.0+(distance_offset+spawn_at)*0.024)
		spawn_at+=maxf(10.5,projected_speed*(1.24-0.07*tier))

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
	a.set_meta("cart_shift",0.0)
	a.set_meta("skill_clear",false)
	a.set_meta("dodge_candidate",false)
	entities.append(a)
	if recycled:
		if a.get_child_count()>0:
			var visual:=a.get_child(0) as Node3D
			visual.rotation.y=0
			visual.position.y=0
		return
	if using_blender and asset(a,["crate","barrier","coin","snack","magnet","shield","double","boost","cart","tall","low_bar","time_orb","spring","sky_ring","gem","rescue","smash"][kind],Vector3.ZERO)!=null:
		if is_pickup(kind) and kind!=BOOST and kind!=SKY_RING:
			ground_shadow(a,0.75 if kind==PICKUP else 1.10,0.52 if kind==PICKUP else 0.75)
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
	elif kind==CART or kind==TALL or kind==LOW_BAR:
		var height:=3.15 if kind!=LOW_BAR else 0.72
		box(a,Vector3(0,height*0.5,0),Vector3(1.5,height,1.5 if kind==CART else 0.5),Color("#b44c2f"))
	elif kind==SNACK:
		orb(a,Vector3(0,0.75,0),Vector3(0.68,0.45,0.68),Color("#607fbc"))
		for i in range(5):
			orb(a,Vector3(cos(i*1.26)*0.19,0.99,sin(i*1.26)*0.19),Vector3(0.16,0.13,0.16),Color("#e1ae5a"))
	elif kind>=TIME_ORB:
		orb(a,Vector3(0,2.05 if kind==SKY_RING else 0.85,0),Vector3.ONE*0.75,Color("#9f8cff"))
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
	audio.call("start_music")
	if absf(delta.x)>absf(delta.y) and absf(delta.x)>22:
		var target_lane:=clampi(lane+(1 if delta.x>0 else -1),0,2)
		if target_lane!=lane:
			lane_impulse=float(target_lane-lane)
			lane=target_lane
			audio.call("play_fx","swoosh")
	elif delta.y < -22:
		if player.is_on_floor() and player.velocity.y<=0:
			slide=0
			air_slide_pending=false
			player.velocity.y=JUMP_SPEED
			audio.call("play_fx","jump")
			audio.call("start_music")
		elif spring_time>0 and not air_jump_used and not air_slide_pending:
			air_jump_used=true
			player.velocity.y=JUMP_SPEED*0.82
			audio.call("play_fx","spring")
		else:
			jump_buffer=0.14
	elif delta.y > 22:
		jump_buffer=0
		if player.is_on_floor() and player.velocity.y<=0:
			slide=SLIDE_SECONDS
			air_slide_pending=false
		else:
			# Cancel upward motion now and retain the full roll on landing.
			air_slide_pending=true
			player.velocity.y=-FAST_FALL
		audio.call("play_fx","slide")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not touch_active:
			touch_start=event.position
			touch_active=true
			gesture_sent=false
			last_input_dir=Vector2.ZERO
			touch_id=event.index
		elif not event.pressed and event.index==touch_id:
			touch_active=false
			if not gesture_sent: gesture(event.position-touch_start)
			touch_id=-1
	elif event is InputEventScreenDrag and touch_active and event.index==touch_id:
		var delta:Vector2=event.position-touch_start
		var threshold:=maxf(24.0,get_viewport().get_visible_rect().size.x*0.045)
		if delta.length()>=threshold:
			var direction:=Vector2(signf(delta.x),0) if absf(delta.x)>absf(delta.y) else Vector2(0,signf(delta.y))
			# A fresh direction can be chained during one continuous touch.
			if not gesture_sent or direction!=last_input_dir:
				gesture_sent=true
				last_input_dir=direction
				gesture(delta)
			touch_start=event.position
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

func make_ground_shadow_resources() -> void:
	shadow_mesh=QuadMesh.new()
	shadow_mesh.size=Vector2.ONE
	var shader:=Shader.new()
	shader.code="shader_type spatial; render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled; void fragment(){float d=length((UV-vec2(0.5))*2.0); ALBEDO=vec3(0.075,0.045,0.09); ALPHA=(1.0-smoothstep(0.18,1.0,d))*0.38;}"
	shadow_material=ShaderMaterial.new()
	shadow_material.shader=shader

func ground_shadow(parent:Node3D,w:float,h:float) -> MeshInstance3D:
	var n:=MeshInstance3D.new()
	n.mesh=shadow_mesh
	n.material_override=shadow_material
	n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.rotation.x=-PI/2
	n.position.y=0.085
	n.scale=Vector3(w,h,1)
	parent.add_child(n)
	return n

func run_score() -> int:
	return int(total_distance()*10)+coins*25+snacks*50+skill_points

func load_best() -> void:
	if OS.get_cmdline_user_args().has("--test") or review_driver: return
	var config:=ConfigFile.new()
	if config.load("user://dash-record.cfg")==OK:
		best_score=maxi(0,int(config.get_value("records","best",0)))

func save_best() -> void:
	if best_saved: return
	best_saved=true
	best_score=maxi(best_score,run_score())
	if OS.get_cmdline_user_args().has("--test") or review_driver: return
	var config:=ConfigFile.new()
	config.set_value("records","best",best_score)
	config.save("user://dash-record.cfg")

func contact_depth(kind:int) -> float:
	# Forgiving capsule plus the actual half-depth of each obstacle.
	if kind==0: return 0.72
	if kind==1: return 0.39
	if kind==LOW_BAR: return 0.43
	if kind==CART: return 1.15
	if kind==TALL: return 0.68
	if kind==BOOST: return 0.92
	return 0.64

func pickup_reachable(kind:int,feet_y:float,attracted:bool) -> bool:
	if kind==SKY_RING: return feet_y>0.85 and feet_y<3.5
	return attracted or (feet_y<0.95 if kind!=BOOST else feet_y<0.42)

func _physics_process(dt: float) -> void:
	if ended:
		if crash_remaining>0:
			crash_remaining=maxf(0,crash_remaining-dt)
			var t:=1.0-crash_remaining/0.58
			mascot.rotation.x=lerpf(-0.12,-1.5,sin(t*PI*0.5))
			mascot.rotation.z=sin(t*PI*2.0)*0.35
			player.position.y=lerpf(crash_player_y,0.0,t)
			mascot.position.y=0.05+sin(t*PI)*0.42
			camera.position.x=player.position.x*0.30+sin(t*PI*12)*0.09*(1-t)
			if crash_remaining<=0:
				last_hud=""
				update_hud()
		return
	if paused_run: return
	if review_driver and started:
		# CI only: follow the procedurally generated reachable route; never bypass collision.
		while not safe_rows.is_empty() and distance>safe_rows[0].x+1.0:
			safe_rows.pop_front()
		if not safe_rows.is_empty():
			var row:=safe_rows[0]
			lane=int(row.y)
			var lead:=speed*(0.33 if int(row.z)==0 else 0.18)
			if row.z>=0 and row.x!=driver_action_at and row.x-distance<=lead:
				driver_action_at=row.x
				gesture(Vector2(0,-80 if int(row.z)==0 else 80))
	player.velocity.y-=GRAVITY*dt
	var capsule := player_shape.shape as CapsuleShape3D
	capsule.height=0.96 if slide>0 or air_slide_pending else 1.35
	player_shape.position.y=capsule.height*0.5
	player.velocity.x=clampf((LANES[lane]-player.position.x)*19,-19,19)
	player.move_and_slide()
	player.position.z=PLAYER_Z
	if player.is_on_floor(): air_jump_used=false
	if air_slide_pending and player.is_on_floor():
		air_slide_pending=false
		slide=SLIDE_SECONDS
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
	slow_time=maxf(0,slow_time-dt)
	spring_time=maxf(0,spring_time-dt)
	rescue_time=maxf(0,rescue_time-dt)
	smash_time=maxf(0,smash_time-dt)
	if smash_time<=0: smash_charges=0
	combo_timer=maxf(0,combo_timer-dt)
	if combo_timer<=0: combo=0
	var base_speed:=minf(25.0,9.0+total_distance()*0.024)
	speed=(base_speed+4.0 if boost_time>0 else base_speed*0.68 if slow_time>0 else base_speed)
	distance+=speed*dt
	rebase_track()
	slide=maxf(0,slide-dt)
	mascot.scale.y=lerpf(mascot.scale.y,0.48 if slide>0 or air_slide_pending else 1.0, minf(1,dt*16))
	mascot.rotation.y=PI+clampf(player.velocity.x*0.023,-0.24,0.24)
	lane_impulse=move_toward(lane_impulse,0,dt*3.5)
	mascot.rotation.z=lerpf(mascot.rotation.z,clampf(player.velocity.x*0.025+lane_impulse*0.09,-0.29,0.29),minf(1,dt*12))
	mascot.rotation.x=lerpf(mascot.rotation.x,-0.32 if air_slide_pending or slide>0 else clampf(player.velocity.y*0.018,-0.16,0.16),minf(1,dt*15))
	mascot.position.y=0.035*(1+sin(clock*32)) if player.is_on_floor() and slide<=0 else 0.0
	if player.is_on_floor() and slide<=0 and clock>=next_step:
		next_step=clock+0.19
		audio.call("play_fx","step")
	update_effects(dt)
	player_shadow.position.x=player.position.x
	var shadow_scale:=1.0/(1.0+maxf(0,player.position.y)*0.30)
	player_shadow.scale=Vector3(1.8*shadow_scale,1.3*shadow_scale,1)
	pickup_flash=maxf(0,pickup_flash-dt)
	skill_flash=maxf(0,skill_flash-dt)
	skill_feedback.visible=skill_flash>0
	skill_feedback.modulate.a=minf(1,skill_flash*3)
	pickup_feedback.visible=pickup_flash>0
	if pickup_flash>0:
		pickup_feedback.modulate.a=minf(1,pickup_flash*4)
	for i in range(feet.size()):
		feet[i].position.z=0.16+sin(clock*16+i*PI)*0.25 if player.is_on_floor() and slide<=0 else 0.16
		feet[i].position.y=0.20+maxf(0,sin(clock*16+i*PI))*0.18 if player.is_on_floor() and slide<=0 else 0.20
		feet[i].rotation.x=sin(clock*16+i*PI)*0.45 if player.is_on_floor() and slide<=0 else -0.14
	for chunk in chunks:
		chunk.position.z+=speed*dt
		if chunk.position.z>SEGMENT*1.5:
			chunk.position.z-=SEGMENTS*SEGMENT
			chunk_recycles+=1
			refresh_chunk_decor(chunk)
	update_scenery_visibility()
	for i in range(entities.size()-1,-1,-1):
		var a:=entities[i]
		var old_z:=a.position.z
		var kind:=int(a.get_meta("kind"))
		var base_z:=distance-float(a.get_meta("at"))
		# The cart moves toward the runner in its own lane; displacement is
		# bounded to leave the adjacent generated safe route reachable.
		var shift:=clampf((base_z+24.0)*0.16,0.0,3.2) if kind==CART else 0.0
		a.position.z=base_z+shift
		a.set_meta("cart_shift",shift)
		if is_pickup(kind) and kind!=BOOST and kind!=SKY_RING and a.visible and a.position.z > -45.0 and a.get_child_count()>0:
			var visual:=a.get_child(0) as Node3D
			visual.rotation.y+=dt*2.5
			visual.position.y=sin(clock*4+float(a.get_meta("at"))*0.38)*0.07
		# Test the full swept depth interval, with the same world sizes as the meshes.
		var depth:=contact_depth(kind)
		var contact := maxf(old_z,a.position.z)>=-depth and minf(old_z,a.position.z)<=depth
		var attraction := kind==PICKUP and magnet_time>0 and absf(a.position.z)<5.0
		if attraction: a.position.x=move_toward(a.position.x,player.position.x,dt*19)
		var lateral:=absf(a.position.x-player.position.x)
		# A near dodge requires actual prior alignment shortly before contact.
		if not is_pickup(kind) and a.position.z<-depth and a.position.z>=-depth-speed*0.35 and lateral<0.55:
			a.set_meta("dodge_candidate",true)
		if (contact or attraction) and not bool(a.get_meta("resolved")) and lateral<(0.92 if is_pickup(kind) else 1.05):
			if is_pickup(kind):
				if pickup_reachable(kind,player.position.y,attraction):
					collect_kind(kind)
					a.set_meta("resolved",true)
					a.hide()
			elif hazard_hit(kind,player.position.y,slide>0 or air_slide_pending,lateral):
				if smash_time>0 and smash_charges>0:
					smash_charges-=1
					smashed+=1
					skill_points+=150
					a.set_meta("resolved",true)
					a.hide()
					show_skill("SMASH  +150")
					audio.call("play_fx","smash")
				elif shield_time>0 or boost_time>0:
					if boost_time<=0: shield_time=0
					a.set_meta("resolved",true)
					a.hide()
					audio.call("play_fx","shield")
				else:
					ended=true
					crash_player_y=player.position.y
					crash_remaining=0.58
					audio.call("play_fx","crash")
					audio.call("stop_music")
					break
		if not is_pickup(kind) and not bool(a.get_meta("resolved")) and not bool(a.get_meta("skill_clear")) and contact and lateral<0.34 and not hazard_hit(kind,player.position.y,slide>0 or air_slide_pending,lateral):
			# Award once only after the trailing edge clears, not on approach.
			if a.position.z>=depth:
				a.set_meta("skill_clear",true)
				award_skill_clear()
		if not is_pickup(kind) and not bool(a.get_meta("resolved")) and not bool(a.get_meta("skill_clear")) and bool(a.get_meta("dodge_candidate")) and a.position.z>=depth and old_z<depth and lateral>=1.05:
			a.set_meta("skill_clear",true)
			perfect_dodges+=1
			skill_points+=125
			show_skill("PERFECT DODGE  +125")
			audio.call("play_fx","skill")
		if a.position.z>2.5:
			a.hide()
			pools[kind].append(a)
			entities.remove_at(i)
	fill_track()
	peak_active=maxi(peak_active,entities.size())
	camera.position.x=lerpf(camera.position.x,player.position.x*0.30,minf(1,dt*7))
	camera.position.y=lerpf(camera.position.y,4.55+clampf(player.position.y*0.13,0,0.25),minf(1,dt*5))
	camera.fov=lerpf(camera.fov,58.0+minf(5.0,(speed-9.0)*0.28),minf(1,dt*3))
	hud_refresh+=dt
	if ended or hud_refresh>=0.075:
		hud_refresh=0
		update_hud()

func challenge_goal() -> int:
	return [15,3,2,1][challenge_index%4]+mini(3,int(challenge_index/4.0))
func challenge_name() -> String:
	return ["Collect coins","Clear obstacles","Collect snacks","Rescue pets"][challenge_index%4]
func show_skill(message:String) -> void:
	skill_feedback.text=message
	skill_flash=1.10
func challenge_event(event:int) -> void:
	if event!=challenge_index%4: return
	challenge_progress+=1
	if challenge_progress>=challenge_goal():
		skill_points+=500
		challenge_index+=1
		challenge_progress=0
		show_skill("CHALLENGE COMPLETE  +500")
		audio.call("play_fx","challenge")
func award_skill_clear() -> void:
	skill_clears+=1
	skill_points+=100
	show_skill("CLEAN MOVE  +100")
	audio.call("play_fx","skill")
	challenge_event(1)
func collect_kind(kind: int) -> void:
	match kind:
		PICKUP:
			coins+=2 if double_time>0 else 1
			combo+=1
			best_combo=maxi(best_combo,combo)
			combo_timer=2.2
			if combo%5==0:
				skill_points+=50*mini(int(combo/5.0),5)
				show_skill("COIN COMBO ×%d"%combo)
				audio.call("play_fx","skill")
			challenge_event(0)
			pickup_feedback.text="+2 coins" if double_time>0 else "+1 coin"
			pickup_flash=0.55
			audio.call("play_fx","coin")
		SNACK:
			snacks+=1
			challenge_event(2)
			pickup_feedback.text="+1 snack"
			pickup_flash=0.8
			audio.call("play_fx","snack")
		MAGNET:
			magnet_time=12.0
		SHIELD:
			shield_time=15.0
		DOUBLE:
			double_time=12.0
		BOOST:
			boost_time=6.0
		TIME_ORB:
			slow_time=8.0
		SPRING:
			spring_time=10.0
		SKY_RING:
			sky_rings+=1
			skill_points+=250
			show_skill("SKY TRICK  +250")
			audio.call("play_fx","skill")
		GEM:
			gems+=1
			if gems>=3:
				gems=0
				skill_points+=1000
				show_skill("GEM SET  +1000")
				audio.call("play_fx","challenge")
			else: show_skill("SKY GEM  %d/3"%gems)
		RESCUE:
			rescued+=1
			rescue_time=8.0
			skill_points+=300
			show_skill("PET RESCUED  +300")
			challenge_event(3)
			audio.call("play_fx","rescue")
		SMASH:
			smash_charges=3
			smash_time=12.0
	if kind>=MAGNET and kind<=BOOST or kind==TIME_ORB or kind==SPRING or kind==SMASH:
		pickup_feedback.text={MAGNET:"MAGNET",SHIELD:"SHIELD",DOUBLE:"DOUBLE COINS",BOOST:"TURBO",TIME_ORB:"TIME BUBBLE",SPRING:"DOUBLE JUMP",SMASH:"SMASH MODE"}[kind]
		pickup_flash=1.0
		audio.call("play_fx","power")

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
	var torus:=TorusMesh.new()
	torus.inner_radius=0.87
	torus.outer_radius=0.95
	torus.rings=24
	torus.ring_segments=6
	power_ring=mesh(player,torus,Vector3(0,0.16,0),Color("#68e2ff"))
	power_ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ring_mat:=StandardMaterial3D.new()
	ring_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.albedo_color=Color("#8cecff")
	power_ring.material_override=ring_mat
	power_ring.hide()
	speed_line_mat=StandardMaterial3D.new()
	speed_line_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	speed_line_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	speed_line_mat.albedo_color=Color(0.65,0.88,1,0.28)
	var strip:=BoxMesh.new()
	strip.size=Vector3(0.025,0.025,1.0)
	for i in range(10):
		var line:=mesh(fx,strip,Vector3.ZERO,Color.WHITE)
		line.material_override=speed_line_mat
		line.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		line.hide()
		speed_lines.append(line)

func update_effects(dt:float) -> void:
	aura.visible=shield_time>0 or boost_time>0 or smash_charges>0
	if rescue_buddy!=null:
		rescue_buddy.visible=rescue_time>0
		if rescue_buddy.visible:
			rescue_buddy.position.x=lerpf(rescue_buddy.position.x,player.position.x+0.57,minf(1,dt*6))
			rescue_buddy.position.y=0.10+absf(sin(clock*12))*0.18+player.position.y*0.35
			rescue_buddy.position.z=1.50+sin(clock*5)*0.13
	power_ring.visible=magnet_time>0 or boost_time>0 or shield_time>0
	power_ring.rotation.y=clock*2.0
	power_ring.scale=Vector3.ONE*(1.0+sin(clock*7)*0.08)
	for i in range(scene_anim.size()):
		scene_anim[i].position.y=scene_anim_origins[i].y+sin(clock*0.35+float(i))*0.32
	if sky_ship!=null:
		sky_ship.position=ship_origin+Vector3(sin(clock*0.18)*5.0,sin(clock*0.42)*0.75,0)
		sky_ship.rotation.z=sin(clock*0.35)*0.04
	var intensity:=clampf((speed-12.0)/13.0,0,1)
	speed_line_mat.albedo_color=Color(0.65,0.88,1.0,0.12+intensity*0.30)
	for i in range(speed_lines.size()):
		var line:=speed_lines[i]
		line.visible=intensity>0.15 or boost_time>0
		line.position=Vector3((-1.0 if i%2==0 else 1.0)*(2.5+float(i%3)*0.20),0.10,fposmod(clock*(8+speed*0.5)+float(i)*4.3,35.0)-29.0)
		line.scale.z=1.0+intensity*2.4
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

func hazard_hit(kind: int, feet_y: float, sliding: bool, lateral:float=0.0) -> bool:
	# Real vertical overlap: clearing the top OR fitting below the beam is
	# safe. Posts/lamps only collide near their actual lateral position.
	var top:=feet_y+(0.74 if sliding else 1.55)
	match kind:
		0: return feet_y<0.86 and lateral<0.93
		1:
			if lateral>0.38 and lateral<1.0:
				return feet_y<1.94
			return lateral<0.98 and feet_y<1.66 and top>1.18
		LOW_BAR: return feet_y<0.74 and lateral<0.98
		CART: return feet_y<2.76 and lateral<1.03
		TALL: return feet_y<3.10 and lateral<1.03
	return false

func update_hud() -> void:
	var active_powers: Array[String]=[]
	if magnet_time>0: active_powers.append("MAGNET %ds"%ceili(magnet_time))
	if shield_time>0: active_powers.append("SHIELD %ds"%ceili(shield_time))
	if double_time>0: active_powers.append("×2 %ds"%ceili(double_time))
	if boost_time>0: active_powers.append("BOOST %ds"%ceili(boost_time))
	if slow_time>0: active_powers.append("TIME %ds"%ceili(slow_time))
	if spring_time>0: active_powers.append("SPRING %ds"%ceili(spring_time))
	if smash_charges>0: active_powers.append("SMASH ×%d"%smash_charges)
	var powers: String="  •  ".join(active_powers)
	var power_text := powers if not powers.is_empty() else "Collect power-ups to extend your run"
	if power_text!=last_power_hud:
		last_power_hud=power_text
		power_label.text=power_text
	var challenge_text:="%s %d/%d  •  Combo %d  •  Gems %d/3  •  Pets %d"%[challenge_name(),challenge_progress,challenge_goal(),combo,gems,rescued]
	if challenge_text!=last_challenge_hud:
		last_challenge_hud=challenge_text
		challenge_label.text=challenge_text
		challenge_bar.max_value=challenge_goal()
		challenge_bar.value=challenge_progress
	var key := str(int(total_distance()))+":"+str(coins)+":"+str(snacks)+":"+str(ended)+":"+str(paused_run)+":"+str(started)+":"+str(skill_points)
	if key==last_hud: return
	last_hud=key
	points_label.text="%d pts"%run_score()
	score_label.text="%d m"%int(total_distance())
	coin_label.text="%d coins"%coins
	snack_label.text="%d snacks"%snacks
	hint.text=("Run ended" if retired_run else "Game over") if ended else "Paused" if paused_run else "Swipe left / right" if started else "Swipe to start"
	pause_button.disabled=ended
	result_panel.visible=(ended and crash_remaining<=0) or paused_run
	retire_button.visible=paused_run and not ended
	music_button.visible=paused_run and not ended
	audio.call("set_music_paused",paused_run or ended)
	if ended:
		save_best()
		result_text.text="%s\n%d pts  •  Best %d\n%d m  •  %d coins  •  %d snacks"%["RUN ENDED" if retired_run else "GAME OVER",run_score(),best_score,int(total_distance()),coins,snacks]
		result_button.text="Run again"
	elif paused_run:
		result_text.text="PAUSED"
		result_button.text="Resume"

func claim_result() -> Dictionary:
	if session_claimed or not ended:
		return {}
	session_claimed=true
	return {"distance":int(total_distance()),"coins":coins,"snacks":snacks}

func test_run() -> void:
	# Deterministic headless scene boot + input, track generation and reward idempotence.
	await get_tree().physics_frame
	await get_tree().physics_frame
	gesture(Vector2(-80,0))
	assert(lane==0 and started)
	gesture(Vector2(80,0))
	assert(lane==1)
	assert(chunks.size()==SEGMENTS and entities.size()>10)
	assert(scenery_visibility_updates>0 and not chunks[SEGMENTS-1].visible)
	assert((mascot.transform.basis*Vector3.BACK).z < -0.99,"mascot must face away")
	assert(using_blender and loaded_assets>20,"Blender assets missing or not instantiated")
	# Isolate control tests from randomly spawned obstacles.
	for entity in entities: entity.queue_free()
	entities.clear()
	spawn_at=distance+1000
	assert(hazard_hit(0,0,false) and not hazard_hit(0,1.1,false))
	assert(hazard_hit(1,0,false) and not hazard_hit(1,0,true))
	assert(not hazard_hit(1,1.80,false),"clear above red beam")
	assert(hazard_hit(1,1.5,false) and hazard_hit(1,0,true,0.65))
	assert(not hazard_hit(LOW_BAR,1.0,false) and hazard_hit(LOW_BAR,0,true))
	assert(hazard_hit(TALL,2.2,false) and hazard_hit(CART,2.2,false))
	var kinds:Dictionary={}
	var saved_seed:=rng.state
	for i in range(80): kinds[hazard_for(3)]=true
	rng.state=saved_seed
	assert(kinds.has(CART) and kinds.has(TALL) and kinds.has(LOW_BAR))
	assert(contact_depth(1)<contact_depth(0))
	assert(not pickup_reachable(PICKUP,1.5,false) and pickup_reachable(PICKUP,1.5,true))
	assert(not pickup_reachable(BOOST,0.7,false) and pickup_reachable(BOOST,0,false))
	assert(player_shadow.mesh==shadow_mesh)
	gesture(Vector2(0,-80))
	for i in range(15): await get_tree().physics_frame
	assert(player.position.y>0.9)
	for i in range(55): await get_tree().physics_frame
	assert(player.is_on_floor())
	gesture(Vector2(0,80))
	assert(slide>0)
	for i in range(45): await get_tree().physics_frame
	assert(slide==0)
	# Airborne down swipe must cancel ascent and start a full landing slide.
	gesture(Vector2(0,-80))
	for i in range(12): await get_tree().physics_frame
	assert(player.position.y>0.5 and not player.is_on_floor())
	gesture(Vector2(0,80))
	assert(air_slide_pending and player.velocity.y<=-FAST_FALL)
	for i in range(15): await get_tree().physics_frame
	assert(player.is_on_floor() and not air_slide_pending and slide>0.40)
	assert(not hazard_hit(1,player.position.y,true))
	# Exercise real touch-event handler, including direction changes without lifting.
	var press:=InputEventScreenTouch.new()
	press.index=3
	press.pressed=true
	press.position=Vector2(270,480)
	_unhandled_input(press)
	var drag:=InputEventScreenDrag.new()
	drag.index=3
	drag.position=Vector2(180,480)
	_unhandled_input(drag)
	assert(lane==0 and slide>0)
	drag.position=Vector2(90,480)
	_unhandled_input(drag)
	assert(lane==0)
	drag.position=Vector2(180,480)
	_unhandled_input(drag)
	assert(lane==1 and slide>0)
	press.pressed=false
	press.position=drag.position
	_unhandled_input(press)
	assert(not touch_active and lane==1)
	# Up from a slide starts a new jump immediately.
	gesture(Vector2(0,-80))
	assert(slide==0 and player.velocity.y==JUMP_SPEED)
	for i in range(65): await get_tree().physics_frame
	assert(player.is_on_floor())
	# Exercise actual moving collision loop: jump over and slide under the same beam.
	make_entity(1,1,distance+speed*0.40)
	gesture(Vector2(0,-80))
	for i in range(60): await get_tree().physics_frame
	assert(not ended and player.is_on_floor(),"jump must clear actual red beam")
	make_entity(1,1,distance+speed*0.28)
	gesture(Vector2(0,80))
	for i in range(48): await get_tree().physics_frame
	assert(not ended and slide==0,"slide must clear actual red beam")
	make_entity(0,CART,distance+8.0)
	var cart:=entities.back() as Area3D
	var cart_z:=cart.position.z
	var start_distance:=distance
	for i in range(12): await get_tree().physics_frame
	assert(not ended and cart.position.z-cart_z>distance-start_distance+0.1,"cart approaches independently")
	for i in range(60): await get_tree().physics_frame
	assert(not ended,"adjacent cart must not hit runner")
	# New power-ups must change movement, not just display a timer.
	collect_kind(SPRING)
	gesture(Vector2(0,-80))
	for i in range(16): await get_tree().physics_frame
	gesture(Vector2(0,-80))
	assert(air_jump_used and player.velocity.y>8.0)
	var second_jump_velocity:=player.velocity.y
	gesture(Vector2(0,-80))
	assert(player.velocity.y==second_jump_velocity,"only one extra jump per takeoff")
	jump_buffer=0
	for i in range(100): await get_tree().physics_frame
	assert(player.is_on_floor() and not air_jump_used)
	spring_time=0
	var normal_speed:=speed
	collect_kind(TIME_ORB)
	for i in range(3): await get_tree().physics_frame
	assert(speed<normal_speed*0.75 and slow_time>0)
	slow_time=0
	for i in range(3): await get_tree().physics_frame
	assert(speed>=normal_speed)
	var old_distance:=distance
	for i in range(20):
		await get_tree().physics_frame
	assert(distance>old_distance)
	retire_run()
	assert(not ended,"cannot end a live run without pausing")
	toggle_pause()
	assert(retire_button.visible)
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
	collect_kind(SMASH)
	make_entity(1,0,distance+1.0)
	for i in range(20): await get_tree().physics_frame
	assert(not ended and smash_charges==2 and smashed==1)
	smash_charges=0
	smash_time=0
	collect_kind(BOOST)
	assert(boost_time>0)
	boost_time=0
	make_entity(1,0,distance+1.0)
	for i in range(50): await get_tree().physics_frame
	assert(ended and result_panel.visible and not retired_run and not retire_button.visible)
	assert(crash_remaining==0 and player.position.y<0.1)
	assert(best_saved and best_score>=run_score())
	var before_bonus:=skill_points
	collect_kind(GEM)
	collect_kind(GEM)
	collect_kind(GEM)
	assert(gems==0 and skill_points==before_bonus+1000)
	collect_kind(SKY_RING)
	assert(sky_rings==1 and skill_points==before_bonus+1250)
	assert(pickup_reachable(SKY_RING,1.2,false) and not pickup_reachable(SKY_RING,0,false))
	collect_kind(TIME_ORB)
	collect_kind(SPRING)
	assert(slow_time==8 and spring_time==10)
	challenge_index=0
	challenge_progress=14
	challenge_event(0)
	assert(challenge_index==1 and challenge_progress==0)
	assert(skill_points==before_bonus+1750)
	collect_kind(RESCUE)
	assert(rescued==1 and rescue_time==8 and skill_points==before_bonus+2050)
	collect_kind(SMASH)
	assert(smash_charges==3 and smash_time==12)
	assert(not claim_result().is_empty() and claim_result().is_empty())
	# Exercise explicit retirement without adding a distance-based end condition.
	ended=false
	paused_run=true
	retire_run()
	assert(ended and retired_run and not paused_run)
	print("PET_DASH_3D_SMOKE_PASS")
	get_tree().quit(0)

func capture_review() -> void:
	# Real game frame; capture first, then run the desktop timing sample.
	print("DASH_CAPTURE_READY")
	await get_tree().process_frame
	started=true
	# Capture during the initial safe stretch rather than after a slow render
	# benchmark might have let the uncontrolled player crash.
	print("DASH_CAPTURE_BEGIN")
	while distance<3.0 and not ended:
		await get_tree().physics_frame
	print("DASH_CAPTURE_DISTANCE ",distance)
	await RenderingServer.frame_post_draw
	var review:=get_viewport().get_texture().get_image()
	assert(review.save_png("/tmp/pet-dash-review.png")==OK)
	print("DASH_CAPTURE_IMAGE_SAVED")
	var frame_ms: Array[float]=[]
	var last_us:=Time.get_ticks_usec()
	for i in range(10):
		await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec()
		if i>=2: frame_ms.append(float(now-last_us)/1000.0)
		last_us=now
	frame_ms.sort()
	assert(not ended,"capture driver crashed during timing")
	var p95:=frame_ms[int((frame_ms.size()-1)*0.95)]
	var metrics:=FileAccess.open("/tmp/pet-dash-render-metrics.json",FileAccess.WRITE)
	metrics.store_string(JSON.stringify({"renderer":RenderingServer.get_current_rendering_method(),"samples":frame_ms.size(),"median_ms":frame_ms[int(frame_ms.size()/2.0)],"p95_ms":p95,"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),"scope":"desktop virtual display; not Android"}))
	metrics.close()
	await RenderingServer.frame_post_draw
	print("PET_DASH_RENDER_CAPTURE_OK")
	get_tree().quit(0)

func soak_review() -> void:
	# Fixed-fps headless CI runs a long procedural session with real physics,
	# pickup logic, recycling and collisions; not a GPU or Android benchmark.
	await get_tree().physics_frame
	started=true
	var steps:=0
	while total_distance()<3200.0 and not ended and steps<20000:
		await get_tree().physics_frame
		steps+=1
	assert(not ended and total_distance()>=3200.0,"endless route stopped unexpectedly")
	var checkpoint:=total_distance()
	for i in range(180): await get_tree().physics_frame
	assert(not ended and total_distance()>checkpoint+30.0,"run must continue past the test checkpoint")
	assert(rebase_count>=3 and distance<REBASE_INTERVAL)
	assert(chunk_recycles>100 and chunks.size()==SEGMENTS)
	assert(pattern_count>35 and reused_entities>100 and mandatory_rows>3 and moving_rows>3)
	assert(created_entities<180 and peak_active<130)
	assert(coins>20)
	var result:=FileAccess.open("/tmp/pet-dash-soak.json",FileAccess.WRITE)
	assert(result!=null)
	result.store_string(JSON.stringify({"distance":total_distance(),"local_distance":distance,"rebases":rebase_count,"chunk_recycles":chunk_recycles,"steps":steps,"coins":coins,"snacks":snacks,"rescued":rescued,"smashed":smashed,"perfect_dodges":perfect_dodges,"rows":pattern_count,"mandatory_rows":mandatory_rows,"moving_rows":moving_rows,"allocated":created_entities,"reused":reused_entities,"peak_active":peak_active,"scope":"deterministic headless endless physics; 3200m checkpoint plus continued gameplay, not physical-device FPS"}))
	result.close()
	print("PET_DASH_SOAK_PASS")
	get_tree().quit(0)
