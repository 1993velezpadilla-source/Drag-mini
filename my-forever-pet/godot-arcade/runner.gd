extends Node3D
# Standalone 3D vertical slice; no native wallet writes yet.
const LANES := [-2.0, 0.0, 2.0]
const SEGMENT := 18.0
const SEGMENTS := 8
const GRAVITY := 25.0
const JUMP_SPEED := 10.5
const PLAYER_Z := 0.0
const START_SPEED := 13.0
const MAX_SPEED := 36.0
const SURF_SPEED_BONUS := 8.0
const SPEED_GAIN := 0.024
const TIME_ORB_MIN_SPEED := 33.0
const TIME_ORB_DURATION := 6.5
const TIME_ORB_FACTOR := 0.70
const TIME_ORB_RECOVERY := 0.65
var bubble_rng := RandomNumberGenerator.new()
var next_time_orb_at := 850.0
var time_orbs_spawned := 0
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
const SURF := 17
const PORTAL := 18
const COURIER := 19
const ROLLER := 20
const CARD := 21
const TREASURE := 22
const JETPACK := 23
const AIR_COIN := 24
const JET_DURATION := 8.0
const JET_HEIGHT := 4.4
const SURF_DURATION := 14.0
var jet_time := 0.0
var jet_lift := 0.0
var jet_grace := 0.0
var jet_model: Node3D
var jet_coin_at := 0.0
var jet_coins := 0
var jet_runs := 0
var mixed_rows := 0
var last_required_row := -4
var last_required_action := 1
var lane_only_review := false
var unassisted_review := false
var unassisted_seed := 7319
var forced_lane_changes := 0
var safe_lane_streak := 0
var treasure_routes := 0
var treasure_opened := 0
var treasure_time := 0.0
var cards := 0
var card_sets := 0
var surf_saves := 0
var surf_grace := 0.0
var surf_exit_flash := 0.0
var burst_pool: Array[CPUParticles3D] = []
var burst_index := 0
var surf_trails: Array[MeshInstance3D] = []
var burst_count := 0
var glow_mesh: QuadMesh
var glow_materials: Dictionary = {}
var shadow_chunks: Dictionary = {}
var shadow_state: Dictionary = {}
var shadow_transitions := 0
const SURF_LIFT := 0.90
const SURF_SLIDE_LIFT := 0.40
const EXPERT_RAMP_START := 300.0
const EXPERT_RAMP_END := 960.0
const EXPERT_ROW_SECONDS := 0.46
const EXPERT_DENSE_AT := 960.0
var expert_rows := 0
var expert_action_rows := 0
var expert_chain_rows := 0
const WORLD_NAMES := ["Sky Kingdom","Crystal Gardens","Moonlight Isles"]
var surf_time := 0.0
var surf_end_reason := ""
var surf_end_count := 0
const DASH_BUILD := "SURF FIX 21"
var surf_board: Node3D
var world_index := 0
var world_visits := 0
var world_label: Label
var world_environment: Environment
var biome_skies: Array[Texture2D] = []
var sky_panorama: PanoramaSkyMaterial
var backdrop_nodes: Array[Node3D] = []
var world_sun: DirectionalLight3D
var portal_flash := 0.0
var portal_overlay: ColorRect
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
var power_grid: GridContainer
var power_cards: Dictionary = {}
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
var pools: Array = [[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]]
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
var speed := START_SPEED
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
	if name in ["bridge","arch","island","crystal_island","moon_island","palace","cloud_bank","garden_island","royal_gate","windmill_island"]:
		for child in n.find_children("*","MeshInstance3D",true,false):
			(child as MeshInstance3D).lod_bias=0.65
	# Tiny collectibles and distant islands do not need expensive shadow passes.
	if name in ["coin","snack","magnet","shield","double","boost","island","airship","rainbow","time_orb","spring","sky_ring","gem","rescue","smash","surf_pickup","surf_board","portal","crystal_island","moon_island","palace","cloud_bank","garden_island","windmill_island","story_card","treasure_gate"]:
		for child in n.find_children("*","MeshInstance3D",true,false):
			(child as MeshInstance3D).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(n)
	n.position=pos
	loaded_assets+=1
	return n

func _ready() -> void:
	using_blender=ResourceLoader.exists("res://assets/bridge.glb")
	lane_only_review=OS.get_cmdline_user_args().has("--lane-only")
	unassisted_review=OS.get_cmdline_user_args().has("--unassisted")
	review_driver=OS.get_cmdline_user_args().has("--soak") or OS.get_cmdline_user_args().has("--capture") or lane_only_review or unassisted_review
	rng.seed = 7319 if OS.get_cmdline_user_args().has("--test") or review_driver else Time.get_ticks_usec()
	if unassisted_review:
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--seed="): unassisted_seed=int(arg.trim_prefix("--seed="))
		rng.seed=unassisted_seed
	scenery_rng.seed=uint64_seed(rng.seed)
	bubble_rng.seed=uint64_seed(rng.seed+109)
	next_time_orb_at=bubble_rng.randf_range(850.0,1050.0)
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
		sky_panorama=PanoramaSkyMaterial.new()
		for file in ["sky-panorama.png","sky-crystal.png","sky-moon.png"]:
			var texture:=load("res://assets/"+file) as Texture2D if ResourceLoader.exists("res://assets/"+file) else load("res://assets/sky-panorama.png") as Texture2D
			biome_skies.append(texture)
		sky_panorama.panorama=biome_skies[0]
		sky.sky_material=sky_panorama
	else: sky.sky_material=sky_mat
	e.sky=sky
	e.background_mode=Environment.BG_SKY
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#c5d9ee")
	e.ambient_light_energy = 0.42
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	world_environment=e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_color = Color("#ffdfb0")
	sun.light_energy = 0.66
	sun.light_specular=0.42
	sun.directional_shadow_max_distance=30.0
	sun.shadow_bias=0.07
	sun.shadow_normal_bias=0.45
	sun.directional_shadow_blend_splits=true
	sun.shadow_enabled = true
	add_child(sun)
	world_sun=sun
	# Soft cool rim illumination, with no second shadow pass.
	var rim:=DirectionalLight3D.new()
	rim.rotation_degrees=Vector3(-20,145,0)
	rim.light_color=Color("#a5d7ff")
	rim.light_energy=0.18
	rim.light_specular=0.18
	rim.shadow_enabled=false
	add_child(rim)
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
		var casters:Array[MeshInstance3D]=[]
		for child in chunk.find_children("*","MeshInstance3D",true,false):
			var mi:=child as MeshInstance3D
			if mi.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: casters.append(mi)
		shadow_chunks[chunk]=casters
	update_scenery_visibility()
	make_player()
	make_pixel_runner()
	make_ground_shadow_resources()
	make_glow_resources()
	player_shadow=ground_shadow(self,1.8,1.3)
	camera = Camera3D.new()
	camera.position = Vector3(0, 4.55, 7.8)
	camera.fov = 58
	camera.far=140
	add_child(camera)
	camera.look_at(Vector3(0, 1.1, -12))
	make_cloudscape()
	make_effects()
	surf_board=asset(player,"surf_board",Vector3.ZERO)
	if surf_board!=null: surf_board.hide()
	jet_model=asset(mascot,"jetpack",Vector3(0,0.85,-0.58))
	if jet_model!=null: jet_model.hide()
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
	elif lane_only_review:
		call_deferred("lane_only_test")
	elif unassisted_review:
		call_deferred("unassisted_test")

func make_cloudscape() -> void:
	# Actual animated 3D airship and sky arch, not a screenshot overlay.
	sky_ship=asset(self,"airship",Vector3(-12.0,12.0,-40.0))
	if sky_ship!=null:
		ship_origin=sky_ship.position
		sky_ship.scale=Vector3.ONE*1.5
	var rainbow:=asset(self,"rainbow",Vector3(0,1.5,-72.0))
	if rainbow!=null: rainbow.scale=Vector3.ONE*2.2
	var palace:=asset(self,"palace",Vector3(0,2.0,-105.0))
	if palace!=null:
		palace.scale=Vector3.ONE*3.1
		palace.set_meta("biome",0)
		backdrop_nodes.append(palace)
	for i in range(4):
		var bank:=asset(self,"cloud_bank",Vector3((-1.0 if i%2==0 else 1.0)*(8.0+float(i)*3),-2.0+float(i%2)*6,-21.0-float(i)*13))
		if bank!=null:
			bank.scale=Vector3.ONE*(2.6+float(i)*0.55)
			scene_anim.append(bank)
			scene_anim_origins.append(bank.position)
	# Panorama supplies clouds; real distant GLB islands add silhouettes and depth.
	# Fixed world backdrop avoids spawning high-cost scenery per track row.
	for i in range(6):
		var side:float=-1.0 if i%2==0 else 1.0
		var island:=asset(self,["palace","garden_island","windmill_island"][i%3],Vector3(side*(13.0+float(i%3)*6),4.0+float(i%3)*5,-39.0-float(i)*11))
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
		island.visible=int(island.get_meta("biome",0))==world_index
		island.position.x=side*scenery_rng.randf_range(8.0,10.8)
		island.position.y=scenery_rng.randf_range(-0.3,2.0)
		island.rotation.y=scenery_rng.randf_range(-0.35,0.35)
		island.scale=Vector3.ONE*scenery_rng.randf_range(0.95,1.30)

func make_chunk(chunk: Node3D, index: int) -> void:
	if using_blender and asset(chunk,"bridge",Vector3.ZERO)!=null:
		if index%2==1: asset(chunk,"royal_gate" if index%4==3 else "arch",Vector3(0,0,-4))
		if index%2==0:
			for side in [-1,1]:
				for biome in range(3):
					var name:String=["island","crystal_island","moon_island"][biome]
					if biome==0: name=["garden_island","windmill_island","island"][(int(index/2.0)+int(side>0))%3]
					var island:=asset(chunk,name,Vector3(side*(8.0+float(index%3)),float(index%3)*1.3,-4))
					if island!=null:
						island.set_meta("scenery_island",side)
						island.set_meta("biome",biome)
						island.scale=Vector3.ONE*(1.0+float(index%3)*0.12)
						island.visible=biome==world_index
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
		# Only the near road/arch participates in shadow passes. Cache changes.
		var near_shadow:=chunk.visible and chunk.position.z>-24.0 and chunk.position.z<24.0
		if shadow_state.get(chunk,null)!=near_shadow:
			shadow_state[chunk]=near_shadow
			for mi in shadow_chunks.get(chunk,[]):
				mi.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if near_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			shadow_transitions+=1
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
	var active_store=get_node_or_null("/root/PetStore")
	var active_id:int=active_store.species() if active_store!=null and active_store.arcade_mode==4 else 0
	if using_blender and active_id>0:
		var file="res://assets/creatures/species_%02d.glb"%active_id
		if ResourceLoader.exists(file):
			var selected=load(file) as PackedScene
			if selected!=null:
				mascot.add_child(selected.instantiate())
				# Preserve runner foot-array contract for the original animation controller.
				for side in [-1,1]:
					var pivot=Node3D.new();mascot.add_child(pivot);pivot.position=Vector3(side*.37,.20,.16);feet.append(pivot)
				return
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


# Pixel-art presentation only: retain original mascot transform, feet and physics.
var pixel_runner: Sprite3D
var pixel_runner_frames: Array[Texture2D] = []

func pixel_ellipse(img:Image, center:Vector2, radii:Vector2, tint:Color) -> void:
	for y in range(maxi(0,int(center.y-radii.y)),mini(img.get_height(),int(center.y+radii.y)+1)):
		for x in range(maxi(0,int(center.x-radii.x)),mini(img.get_width(),int(center.x+radii.x)+1)):
			var q:= (Vector2(x,y)-center)/radii
			if q.length_squared()<=1.0: img.set_pixel(x,y,tint)

func mosskit_back_frame(step:int) -> Texture2D:
	var img:=Image.create(48,48,false,Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var outline:=Color("#24421d")
	var shade:=Color("#4b912d")
	var mid:=Color("#78c83d")
	var light:=Color("#a4e85b")
	for side in [-1,1]:
		var foot_y:=41.0+float(step*side)
		var foot:=Vector2(24+side*10,foot_y)
		pixel_ellipse(img,foot,Vector2(8,5),outline)
		pixel_ellipse(img,foot+Vector2(0,-1),Vector2(6,3),shade)
		pixel_ellipse(img,foot+Vector2(-1,-2),Vector2(4,2),mid)
		var ear:=Vector2(24+side*12,11)
		pixel_ellipse(img,ear,Vector2(6,10),outline)
		pixel_ellipse(img,ear+Vector2(0,-1),Vector2(4,8),mid)
		pixel_ellipse(img,ear+Vector2(-1,-3),Vector2(2,4),light)
	pixel_ellipse(img,Vector2(24,10),Vector2(5,6),outline)
	pixel_ellipse(img,Vector2(24,9),Vector2(3,4),light)
	pixel_ellipse(img,Vector2(24,26),Vector2(19,17),outline)
	pixel_ellipse(img,Vector2(24,26),Vector2(17,15),shade)
	pixel_ellipse(img,Vector2(23,23),Vector2(16,13),mid)
	pixel_ellipse(img,Vector2(18,17),Vector2(9,4),light)
	for side in [-1,1]:
		pixel_ellipse(img,Vector2(24+side*11,23),Vector2(4,4),shade)
		pixel_ellipse(img,Vector2(23+side*11,22),Vector2(3,3),light)
	pixel_ellipse(img,Vector2(24,36),Vector2(6,6),outline)
	pixel_ellipse(img,Vector2(24,35),Vector2(5,5),shade)
	pixel_ellipse(img,Vector2(23,34),Vector2(3,3),light)
	return ImageTexture.create_from_image(img)

func make_pixel_runner() -> void:
	var store=get_node_or_null("/root/PetStore")
	var species_id:int=store.species() if store!=null and store.arcade_mode==4 else 0
	# Every selected companion keeps its own silhouette. Missing art falls back
	# to the original 3D model, never to another species.
	if species_id==0:
		for step in [0,2,-2]:
			pixel_runner_frames.append(mosskit_back_frame(step))
	else:
		var path: String="res://assets/pet_rear_%d.png"%species_id
		if not ResourceLoader.exists(path): return
		var original:=load(path) as Texture2D
		if original==null: return
		var img:=original.get_image()
		if img==null or img.is_empty(): return
		img.convert(Image.FORMAT_RGBA8)
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var c:=img.get_pixel(x,y)
				if c.a<0.5: c=Color.TRANSPARENT
				else: c=Color(roundf(c.r*15.0)/15.0,roundf(c.g*15.0)/15.0,roundf(c.b*15.0)/15.0,1.0)
				img.set_pixel(x,y,c)
		pixel_runner_frames.append(ImageTexture.create_from_image(img))
	for child in mascot.get_children():
		if child is Node3D: child.hide()
	pixel_runner=Sprite3D.new()
	pixel_runner.name="ActivePetPixelBack"
	pixel_runner.texture=pixel_runner_frames[0]
	pixel_runner.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	pixel_runner.pixel_size=0.043 if species_id==0 else 0.036
	pixel_runner.position.y=0.99
	pixel_runner.shaded=false
	pixel_runner.double_sided=true
	mascot.add_child(pixel_runner)

func animate_pixel_runner(running:bool) -> void:
	if not is_instance_valid(pixel_runner): return
	var frame:int=1+int(floor(clock*9.0))%2 if running and pixel_runner_frames.size()==3 else 0
	pixel_runner.texture=pixel_runner_frames[frame]


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
	style.content_margin_top=4
	style.content_margin_bottom=4
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
	portal_overlay=ColorRect.new()
	portal_overlay.color=Color(0.66,0.91,1.0,0)
	portal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portal_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(portal_overlay)
	var panel := PanelContainer.new()
	ui.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left=10
	panel.offset_right=-10
	panel.offset_top=10
	panel.offset_bottom=72
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",panel_style(Color("#101b2b99"),Color("#ffffff26"),12))
	var column := VBoxContainer.new()
	column.mouse_filter=Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation",2)
	panel.add_child(column)
	var header := HBoxContainer.new()
	header.mouse_filter=Control.MOUSE_FILTER_IGNORE
	column.add_child(header)
	var brand:=hud_label(header,"PET DASH · 21",16,Color("#fff0b5"))
	brand.add_theme_color_override("font_outline_color",Color("#38203f"))
	brand.add_theme_constant_override("outline_size",4)
	status=brand
	audio_button=Button.new()
	audio_button.text="SFX"
	style_button(audio_button)
	audio_button.pressed.connect(func():
		audio.call("toggle")
		audio_button.text="SFX" if audio.get("enabled") else "Mute")
	header.add_child(audio_button)
	pause_button=Button.new()
	pause_button.text="Ⅱ"
	pause_button.custom_minimum_size=Vector2(45,32)
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
	world_label=hud_label(column,"SKY KINGDOM",10,Color("#cbd9ff"))
	world_label.hide()
	power_label=hud_label(column,"Find power-ups and secret sky gems",12,Color("#e9d5ff"))
	power_label.hide()
	power_grid=GridContainer.new()
	power_grid.columns=3
	power_grid.mouse_filter=Control.MOUSE_FILTER_IGNORE
	power_grid.add_theme_constant_override("h_separation",8)
	power_grid.add_theme_constant_override("v_separation",3)
	ui.add_child(power_grid)
	power_grid.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	power_grid.offset_left=12
	power_grid.offset_top=-175
	power_grid.offset_right=12
	power_grid.offset_bottom=-175
	for entry in [["MAGNET",12.0,"#70e8ff"],["SHIELD",15.0,"#8ee5a5"],["×2 COINS",12.0,"#ffcf61"],["TURBO",6.0,"#ff8b59"],["TIME BUBBLE",TIME_ORB_DURATION,"#b7a0ff"],["DOUBLE JUMP",10.0,"#83dcff"],["SMASH",12.0,"#ffac78"],["SKY SURF",SURF_DURATION,"#8af0f5"],["JETPACK",JET_DURATION,"#ffbd77"],["TREASURE",5.0,"#ffdf87"],["RESCUE",8.0,"#f4a4cf"]]:
		make_power_card(str(entry[0]),float(entry[1]),Color(str(entry[2])))
	power_grid.hide()
	challenge_label=hud_label(column,"Collect 15 coins",11,Color("#ffe5a4"))
	challenge_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	challenge_bar=ProgressBar.new()
	challenge_bar.show_percentage=false
	challenge_bar.custom_minimum_size.y=3
	challenge_bar.add_theme_stylebox_override("background",panel_style(Color("#15213c"),Color("#354b73"),4))
	challenge_bar.add_theme_stylebox_override("fill",panel_style(Color("#e8b64e"),Color("#f9db89"),4))
	challenge_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	column.add_child(challenge_bar)
	var footer := PanelContainer.new()
	ui.add_child(footer)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left=12
	footer.offset_right=-12
	footer.offset_top=-72
	footer.offset_bottom=-12
	footer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	footer.add_theme_stylebox_override("panel",panel_style(Color("#17274bc9"),Color("#d5b46b"),16))
	pickup_feedback=Label.new()
	ui.add_child(pickup_feedback)
	pickup_feedback.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	pickup_feedback.offset_left=-150
	pickup_feedback.offset_right=150
	pickup_feedback.offset_top=-205
	pickup_feedback.offset_bottom=-160
	pickup_feedback.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	pickup_feedback.add_theme_font_size_override("font_size",17)
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
	skill_feedback.offset_top=-278
	skill_feedback.offset_bottom=-242
	skill_feedback.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	skill_feedback.add_theme_font_size_override("font_size",19)
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
	hint=hud_label(controls,"Swipe left / right",12,Color("#f1ebff"))
	var actions:=HBoxContainer.new()
	actions.mouse_filter=Control.MOUSE_FILTER_IGNORE
	controls.add_child(actions)
	for action in ["↑ Jump","↓ Slide"]:
		var button:=Button.new()
		button.text=action
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y=32
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
			var store=get_node_or_null("/root/PetStore")
			if store!=null and store.arcade_mode==4:
				var result=claim_result()
				if not result.is_empty(): store.finish_arcade(int(result.coins),clock,int(result.snacks))
				get_tree().change_scene_to_file("res://hub.tscn")
			else: get_tree().reload_current_scene()
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
	jet_coin_at-=shift
	for a in entities: a.set_meta("at",float(a.get_meta("at"))-shift)
	for i in range(safe_rows.size()): safe_rows[i].x-=shift
	driver_action_at-=shift
	rebase_count+=1

func is_pickup(kind:int) -> bool:
	return (kind>=PICKUP and kind<=BOOST) or (kind>=TIME_ORB and kind<=PORTAL) or kind==CARD or kind==TREASURE or kind==JETPACK or kind==AIR_COIN

func hazard_for(tier:int) -> int:
	if tier==0: return [0,1,CART,LOW_BAR][rng.randi_range(0,3)]
	var choices:Array[int]=[0,1,LOW_BAR,CART]
	if tier>=2:
		choices.append(TALL)
		choices.append(COURIER)
		choices.append(ROLLER)
	return choices[rng.randi_range(0,choices.size()-1)]

func base_run_speed(at:float) -> float:
	return minf(MAX_SPEED,START_SPEED+maxf(0.0,at)*SPEED_GAIN)

func time_orb_eligible(at:float) -> bool:
	return at>=next_time_orb_at and base_run_speed(at)>=TIME_ORB_MIN_SPEED

func row_spacing(at:float,tier:int) -> float:
	# Preserve the approved opening; compress encounter time as the run gets faster.
	# At the speed cap, rows are 16.56m apart rather than 26.46m.
	var expert:=smoothstep(EXPERT_RAMP_START,EXPERT_RAMP_END,at)
	var seconds:=lerpf(0.84-0.035*tier,EXPERT_ROW_SECONDS,expert)
	return maxf(9.5,base_run_speed(at)*seconds)

func fill_track() -> void:
	while spawn_at<distance+95:
		var tier:=mini(3,int((distance_offset+spawn_at)/60.0))
		var free_lane:=clampi(previous_safe_lane+rng.randi_range(-1,1),0,2)
		if free_lane==previous_safe_lane:
			free_lane=previous_safe_lane+(-1 if previous_safe_lane==2 or (previous_safe_lane==1 and rng.randf()<0.5) else 1)
		if free_lane!=previous_safe_lane: forced_lane_changes+=1
		safe_lane_streak=safe_lane_streak+1 if free_lane==previous_safe_lane else 0
		var blocked_lanes:Array[int]=[]
		for i in range(3):
			if i!=free_lane: blocked_lanes.append(i)
		var action:=-1
		var treasure_row:=tier>=1 and pattern_count%12==4
		# Action gates have recovery rows on either side; all three lanes are occupied.
		var expert:=smoothstep(EXPERT_RAMP_START,EXPERT_RAMP_END,distance_offset+spawn_at)
		var required:=pattern_count>=2 and not treasure_row and (pattern_count==2 or (pattern_count-last_required_row>=2 and (pattern_count-last_required_row>=3 or rng.randf()<lerpf(0.80,1.0,expert))))
		if distance_offset+spawn_at>=EXPERT_DENSE_AT:
			# Three consecutive alternating action gates, then one recovery row.
			# Treasure branches occupy recovery rows, never replace a required gate.
			required=pattern_count%4!=0
			expert_rows+=1
			if required:
				expert_action_rows+=1
				if last_required_row==pattern_count-1: expert_chain_rows+=1
		if required:
			action=1-last_required_action
			last_required_action=action
			make_entity(free_lane,action,spawn_at)
			for blocked in blocked_lanes: make_entity(blocked,TALL,spawn_at)
			last_required_row=pattern_count
			mandatory_rows+=1
			mixed_rows+=1
		elif treasure_row:
			var alternate_lane:=free_lane+(-1 if free_lane==2 else 1)
			make_entity(3-free_lane-alternate_lane,TALL,spawn_at)
			make_entity(alternate_lane,TREASURE,spawn_at)
			treasure_routes+=1
		else:
			for blocked in blocked_lanes:
				var kind:=0 if pattern_count%3==1 and blocked==blocked_lanes[0] else hazard_for(tier)
				if distance_offset+spawn_at>=EXPERT_DENSE_AT: kind=CART if blocked==blocked_lanes[0] else COURIER
				make_entity(blocked,kind,spawn_at)
				if kind==CART or kind==COURIER or kind==ROLLER: moving_rows+=1
		# Coin trails no longer paint a continuous guaranteed safe lane.
		# Some lead to jumpable hazards; the mandatory route is still reachable.
		var coin_lane:=free_lane
		if action<0 and not treasure_row and pattern_count%3==1 and distance_offset+spawn_at<EXPERT_DENSE_AT: coin_lane=blocked_lanes[0]
		if action==0:
			for offset in [-2.0,0.0,2.0]:
				make_entity(free_lane,SKY_RING if offset==0.0 and pattern_count%5==0 else PICKUP,spawn_at+offset)
				if offset!=0.0 or pattern_count%5!=0:
					entities.back().set_meta("height",1.6)
					entities.back().position.y=1.6
		elif action==1:
			for offset in [-2.4,2.4]: make_entity(free_lane,PICKUP,spawn_at+offset)
		else:
			for offset in [-2.4,-1.2,0.0,1.2]:
				make_entity(coin_lane,PICKUP,spawn_at+offset)
				if coin_lane!=free_lane:
					entities.back().set_meta("height",1.55)
					entities.back().position.y=1.55
		if pattern_count%7==2:
			var power:=MAGNET+rng.randi_range(0,3)
			var pickup_at:=distance_offset+spawn_at+3.6
			var slot:=int(pattern_count/7.0)%6
			if time_orb_eligible(pickup_at):
				power=TIME_ORB
				time_orbs_spawned+=1
				next_time_orb_at=pickup_at+bubble_rng.randf_range(650.0,1000.0)
			elif slot==1: power=SPRING
			elif slot==2: power=SURF
			elif slot==3: power=JETPACK
			elif slot==4: power=SMASH
			# CI can test the exact generated hazards without any speed/shield assist.
			if not unassisted_review: make_entity(free_lane,power,spawn_at+3.6)
		elif action<0 and rng.randf()<0.34:
			make_entity(free_lane,SNACK,spawn_at+3.6)
		if tier>=1 and action<0 and pattern_count%11==8: make_entity(free_lane,GEM,spawn_at+4.8)
		if tier>=1 and action<0 and pattern_count%12==9: make_entity(free_lane,RESCUE,spawn_at+4.8)
		if tier>=1 and action<0 and pattern_count%10==6: make_entity(free_lane,CARD,spawn_at+4.8)
		if tier>=1 and pattern_count%18==10: make_entity(1,PORTAL,spawn_at+5.5)
		if review_driver: safe_rows.append(Vector3(spawn_at,float(free_lane),float(action)))
		previous_safe_lane=free_lane
		pattern_count+=1
		spawn_at+=row_spacing(distance_offset+spawn_at,tier)

# Continuous oncoming travel relative to the road, anchored at the planned
# encounter distance. The row generator retains its original escape lane.
func approach_factor(kind:int) -> float:
	match kind:
		CART: return 1.75
		COURIER: return 1.95
		ROLLER: return 1.55
	return 1.0

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
	a.position=Vector3(LANES[which_lane],JET_HEIGHT if kind==AIR_COIN else 0.65 if kind==JETPACK else 0.0,(distance-at)*approach_factor(kind))
	a.monitoring=false
	a.monitorable=false
	a.set_meta("kind",kind)
	a.set_meta("height",JET_HEIGHT if kind==AIR_COIN else 0.65 if kind==JETPACK else 0.0)
	a.set_meta("at",at)
	a.set_meta("resolved",false)
	a.set_meta("warned",false)
	a.set_meta("wheel_angle",0.0)
	a.set_meta("skill_clear",false)
	a.set_meta("dodge_candidate",false)
	entities.append(a)
	if recycled:
		if a.get_child_count()>0:
			var visual:=a.get_child(0) as Node3D
			visual.rotation=Vector3.ZERO
			visual.position=Vector3.ZERO
		if a.has_meta("halo"): (a.get_meta("halo") as MeshInstance3D).hide()
		return
	if using_blender and asset(a,["crate","barrier","coin","snack","magnet","shield","double","boost","cart","tall","low_bar","time_orb","spring","sky_ring","gem","rescue","smash","surf_pickup","portal","courier","roller","story_card","treasure_gate","jetpack","coin"][kind],Vector3.ZERO)!=null:
		if is_pickup(kind) and kind!=BOOST and kind!=SKY_RING and kind!=PORTAL and kind!=TREASURE and kind!=AIR_COIN:
			ground_shadow(a,0.75 if kind==PICKUP else 1.10,0.52 if kind==PICKUP else 0.75)
		add_pickup_glow(a,kind)
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
	elif kind==CART or kind==TALL or kind==LOW_BAR or kind==COURIER or kind==ROLLER:
		var height:=3.15 if kind!=LOW_BAR and kind!=ROLLER else 0.72 if kind==LOW_BAR else 1.30
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
		if jet_time>0 or jet_lift>0.5: return
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
		if jet_time>0 or jet_lift>0.5: return
		# Duck on the board instead of dismounting; collision and visuals lower together.
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

func make_glow_resources() -> void:
	glow_mesh=QuadMesh.new()
	glow_mesh.size=Vector2(2.0,2.0)
	var shader:=Shader.new()
	shader.code="shader_type spatial; render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled; uniform vec4 tint : source_color = vec4(1.0,0.7,0.2,1.0); void fragment(){float d=length(UV-vec2(0.5))*2.0; float ring=exp(-pow((d-0.56)*12.0,2.0)); float soft=pow(max(0.0,1.0-d),2.4); ALBEDO=tint.rgb; ALPHA=(ring*0.18+soft*0.30)*(1.0-smoothstep(0.78,1.0,d));}"
	for kind in [SNACK,MAGNET,SHIELD,DOUBLE,TIME_ORB,SPRING,SKY_RING,GEM,RESCUE,SMASH,SURF,CARD]:
		var material:=ShaderMaterial.new()
		material.shader=shader
		var tint:Color=Color("#ffcd63") if kind in [SNACK,DOUBLE,CARD,SKY_RING] else Color("#a9a0ff") if kind in [GEM,SPRING,SMASH] else Color("#64dfff")
		material.set_shader_parameter("tint",tint)
		glow_materials[kind]=material

func add_pickup_glow(a:Area3D,kind:int) -> void:
	if not glow_materials.has(kind): return
	var halo:=MeshInstance3D.new()
	halo.name="PickupHalo"
	halo.mesh=glow_mesh
	halo.material_override=glow_materials[kind]
	halo.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.position=Vector3(0,2.05 if kind==SKY_RING else 0.90,0.25)
	halo.visible=false
	a.add_child(halo)
	a.set_meta("halo",halo)

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
	if kind==0: return 0.85
	if kind==1: return 0.39
	if kind==LOW_BAR: return 0.43
	if kind==CART or kind==COURIER: return 1.15
	if kind==ROLLER: return 0.83
	if kind==TALL: return 0.68
	if kind==BOOST: return 0.92
	return 0.64

func end_surf(reason:String) -> void:
	if surf_time<=0.0: return
	surf_time=0.0
	surf_end_reason=reason
	surf_end_count+=1
	if surf_board!=null: surf_board.hide()
	for trail in surf_trails: trail.hide()
	print("SURF_END ",reason," distance=",total_distance()," slide=",slide," air_slide=",air_slide_pending)
	if reason=="TIME EXPIRED": show_skill("BOARD TIME UP")

func runner_hazard_hit(kind:int,lateral:float) -> bool:
	var duck:=slide>0.0 or air_slide_pending
	var feet_y:=player.position.y+surf_lift()
	# Surf crouch clearance is based on ground-relative body posture, not the
	# hover offset. The old summed height falsely clipped the beam on landing.
	# Side posts and every other actual obstacle still use normal collision.
	if surf_time>0.0 and duck and kind==1 and lateral<=0.38:
		feet_y=player.position.y
	return hazard_hit(kind,feet_y,duck,lateral)

func surf_lift() -> float:
	if surf_time<=0.0: return 0.0
	return SURF_SLIDE_LIFT if slide>0.0 or air_slide_pending else SURF_LIFT

func pickup_reachable(kind:int,feet_y:float,attracted:bool) -> bool:
	if kind==PORTAL: return true
	if kind==AIR_COIN: return jet_time>0 and jet_lift>2.7
	if jet_time>0 or jet_lift>1.0: return false
	if kind==TREASURE: return true
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
				audio.call("play_fx","game_over")
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
			var lead:=speed*(0.34 if int(row.z)==0 else 0.20)
			if not lane_only_review and row.z>=0 and row.x!=driver_action_at and row.x-distance<=lead:
				driver_action_at=row.x
				gesture(Vector2(0,-80 if int(row.z)==0 else 80))
	player.velocity.y-=GRAVITY*dt
	var capsule := player_shape.shape as CapsuleShape3D
	capsule.height=0.96 if slide>0 or air_slide_pending else 1.35
	player_shape.position.y=capsule.height*0.5
	var lane_speed:=28.0 if surf_time>0 else 19.0
	player.velocity.x=clampf((LANES[lane]-player.position.x)*lane_speed,-lane_speed,lane_speed)
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
	if surf_time>0.0:
		if surf_time<=dt: end_surf("TIME EXPIRED")
		else: surf_time-=dt
	var was_flying:=jet_time>0.0
	jet_time=maxf(0.0,jet_time-dt)
	if was_flying and jet_time<=0.0: jet_grace=1.1
	jet_grace=maxf(0.0,jet_grace-dt)
	jet_lift=move_toward(jet_lift,JET_HEIGHT if jet_time>0.0 else 0.0,dt*10.0)
	if jet_model!=null: jet_model.visible=jet_time>0.0 or jet_lift>0.5
	if jet_time>0.9:
		while jet_coin_at<distance+30.0:
			make_entity(int(floorf((jet_coin_at+distance_offset)/9.0))%3,AIR_COIN,jet_coin_at)
			jet_coin_at+=2.4
	treasure_time=maxf(0,treasure_time-dt)
	surf_grace=maxf(0,surf_grace-dt)
	surf_exit_flash=maxf(0,surf_exit_flash-dt)
	portal_flash=maxf(0,portal_flash-dt)
	var bubble_tint:=0.08*clampf(slow_time/TIME_ORB_RECOVERY,0.0,1.0)
	portal_overlay.color=Color(0.66,0.91,1.0,maxf(portal_flash*0.48,bubble_tint))
	smash_time=maxf(0,smash_time-dt)
	if smash_time<=0: smash_charges=0
	combo_timer=maxf(0,combo_timer-dt)
	if combo_timer<=0: combo=0
	var full_speed:=base_run_speed(total_distance())+(4.0 if boost_time>0 else 0.0)+(SURF_SPEED_BONUS if surf_time>0 else 0.0)+(2.0 if jet_time>0 else 0.0)
	# Bubble wins over simultaneous turbo/surf speed; controls remain real-time.
	# Last 650ms eases directly back to the current full run speed.
	speed=full_speed*lerpf(1.0,TIME_ORB_FACTOR,clampf(slow_time/TIME_ORB_RECOVERY,0.0,1.0))
	distance+=speed*dt
	rebase_track()
	slide=maxf(0,slide-dt)
	mascot.scale.y=lerpf(mascot.scale.y,0.48 if slide>0 or air_slide_pending else 1.0, minf(1,dt*16))
	mascot.rotation.y=PI+clampf(player.velocity.x*0.023,-0.24,0.24)
	lane_impulse=move_toward(lane_impulse,0,dt*3.5)
	mascot.rotation.z=lerpf(mascot.rotation.z,clampf(player.velocity.x*0.025+lane_impulse*0.09,-0.29,0.29),minf(1,dt*12))
	mascot.rotation.x=lerpf(mascot.rotation.x,-0.32 if air_slide_pending or slide>0 else clampf(player.velocity.y*0.018,-0.16,0.16),minf(1,dt*15))
	var running_pose:=player.is_on_floor() and slide<=0 and surf_time<=0 and jet_lift<0.1
	mascot.position.y=(0.035*(1+sin(clock*32)) if running_pose else 0.0)+(surf_lift()+0.025*sin(clock*10) if surf_time>0 else 0.0)+jet_lift
	if surf_board!=null:
		surf_board.visible=surf_time>0
		surf_board.rotation.z=clampf(player.velocity.x*0.025,-0.25,0.25)
		mascot.rotation.z=surf_board.rotation.z if surf_time>0 else mascot.rotation.z
		# Keep the entire board above the deck even when banked and crouching.
		surf_board.position.y=surf_lift()-SURF_LIFT+0.025*sin(clock*10)+jet_lift
	if running_pose and clock>=next_step:
		next_step=clock+0.19
		audio.call("play_fx","step")
	update_effects(dt)
	player_shadow.position.x=player.position.x
	var shadow_scale:=1.0/(1.0+maxf(0,player.position.y+surf_lift())*0.30)
	player_shadow.scale=Vector3(1.8*shadow_scale,1.3*shadow_scale,1)
	pickup_flash=maxf(0,pickup_flash-dt)
	skill_flash=maxf(0,skill_flash-dt)
	skill_feedback.visible=skill_flash>0
	skill_feedback.modulate.a=minf(1,skill_flash*3)
	pickup_feedback.visible=pickup_flash>0
	if pickup_flash>0:
		pickup_feedback.modulate.a=minf(1,pickup_flash*4)
	animate_pixel_runner(running_pose)
	for i in range(feet.size()):
		feet[i].position.z=(0.13 if i==0 else -0.13) if surf_time>0 else (0.16+sin(clock*16+i*PI)*0.25 if running_pose else 0.16)
		feet[i].position.y=0.20+maxf(0,sin(clock*16+i*PI))*0.18 if running_pose else 0.20
		feet[i].rotation.x=sin(clock*16+i*PI)*0.45 if running_pose else (0.0 if surf_time>0 else -0.14)
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
		# Never cap the oncoming motion. Spawn farther ahead and preserve the
		# designed encounter distance while approaching at 1.55–1.95x road speed.
		var factor:=approach_factor(kind)
		a.position.z=base_z*factor
		a.position.y=float(a.get_meta("height"))
		if factor>1.0 and a.visible and not bool(a.get_meta("warned")) and a.position.z>-speed*factor*1.15 and a.position.z<0 and absf(a.position.x-player.position.x)<1.05:
			a.set_meta("warned",true)
			audio.call("play_fx","incoming")
		if kind==ROLLER and a.visible and a.position.z>-40 and a.get_child_count()>0:
			var wheel:=a.get_child(0) as Node3D
			var angle:=float(a.get_meta("wheel_angle"))-(a.position.z-old_z)/0.65
			a.set_meta("wheel_angle",angle)
			wheel.rotation.x=angle
			wheel.position=Vector3(0,0.65,0)-Basis(Vector3.RIGHT,angle)*Vector3(0,0.65,0)
		if is_pickup(kind) and kind!=BOOST and kind!=SKY_RING and kind!=PORTAL and kind!=TREASURE and a.visible and a.position.z > -45.0 and a.get_child_count()>0:
			var visual:=a.get_child(0) as Node3D
			visual.rotation.y=sin(clock*3.8+float(a.get_meta("at"))*0.13)*0.65 if kind==PICKUP else visual.rotation.y+dt*2.5
			visual.position.y=sin(clock*4+float(a.get_meta("at"))*0.38)*0.07
		if a.has_meta("halo"):
			var halo:=a.get_meta("halo") as MeshInstance3D
			halo.visible=a.visible and a.position.z>-24.0 and a.position.z<0.5
			if halo.visible:
				halo.scale=Vector3.ONE*(1.0+0.07*sin(clock*6.0+float(kind)))
		# Test the full swept depth interval, with the same world sizes as the meshes.
		var depth:=contact_depth(kind)
		var contact := maxf(old_z,a.position.z)>=-depth and minf(old_z,a.position.z)<=depth
		var attraction := kind==PICKUP and float(a.get_meta("height"))==0.0 and magnet_time>0 and absf(a.position.z)<4.0 and jet_lift<0.5
		if attraction: a.position.x=move_toward(a.position.x,player.position.x,dt*19)
		var lateral:=absf(a.position.x-player.position.x)
		# A near dodge requires actual prior alignment shortly before contact.
		if not is_pickup(kind) and a.position.z<-depth and a.position.z>=-depth-speed*factor*0.35 and lateral<0.55:
			a.set_meta("dodge_candidate",true)
		if (contact or attraction) and not bool(a.get_meta("resolved")) and (kind==PORTAL or lateral<(0.92 if is_pickup(kind) else 1.05)):
			if is_pickup(kind):
				if (kind==PICKUP and float(a.get_meta("height"))>0.0 and player.position.y>0.8 and jet_lift<0.5) or (not (kind==PICKUP and float(a.get_meta("height"))>0.0) and pickup_reachable(kind,player.position.y,attraction)):
					collect_kind(kind)
					if kind!=PICKUP or combo%3==0:
						reward_burst(Vector3(player.position.x,player.position.y+0.9,0),Color("#ffe69a") if kind==PICKUP or kind==CARD else Color("#9fefff"),kind!=PICKUP)
					a.set_meta("resolved",true)
					a.hide()
			elif jet_time<=0 and jet_lift<0.5 and jet_grace<=0 and runner_hazard_hit(kind,lateral):
				if surf_time>0:
					end_surf("IMPACT %d"%kind)
					surf_grace=0.65
					surf_exit_flash=0.35
					surf_saves+=1
					if surf_board!=null: surf_board.hide()
					mascot.position.y=0
					a.set_meta("resolved",true)
					a.hide()
					for trail in surf_trails: trail.hide()
					reward_burst(Vector3(player.position.x,player.position.y+0.7,0),Color("#9aeaff"),true)
					show_skill("BOARD HIT — KEEP RUNNING")
					audio.call("play_fx","board_break")
				elif surf_grace>0:
					a.set_meta("resolved",true)
					a.hide()
				elif smash_time>0 and smash_charges>0:
					smash_charges-=1
					smashed+=1
					skill_points+=150
					a.set_meta("resolved",true)
					a.hide()
					reward_burst(Vector3(a.position.x,0.9,a.position.z),Color("#ffba63"),true)
					show_skill("SMASH  +150")
					audio.call("play_fx","smash")
				elif shield_time>0:
					shield_time=0
					a.set_meta("resolved",true)
					a.hide()
					audio.call("play_fx","shield")
				else:
					ended=true
					end_surf("RUN ENDED")
					if surf_board!=null: surf_board.hide()
					crash_player_y=player.position.y
					crash_remaining=0.58
					for trail in surf_trails: trail.hide()
					reward_burst(Vector3(player.position.x,player.position.y+0.7,0),Color("#ffc47a"),true)
					audio.call("play_fx","crash")
					audio.call("stop_music")
					break
		if jet_time<=0 and jet_lift<0.5 and jet_grace<=0 and not is_pickup(kind) and not bool(a.get_meta("resolved")) and not bool(a.get_meta("skill_clear")) and contact and lateral<0.34 and not runner_hazard_hit(kind,lateral):
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
	camera.position.x=lerpf(camera.position.x,player.position.x*0.30+sin(clock*55)*surf_exit_flash*0.24,minf(1,dt*7))
	camera.position.y=lerpf(camera.position.y,4.55+clampf(player.position.y*0.13,0,0.25)+jet_lift*0.83,minf(1,dt*5))
	camera.fov=lerpf(camera.fov,58.0+minf(8.0,(speed-START_SPEED)*0.28),minf(1,dt*3))
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
func enter_next_world() -> void:
	world_index=(world_index+1)%WORLD_NAMES.size()
	world_visits+=1
	portal_flash=0.85
	world_label.text=WORLD_NAMES[world_index].to_upper()+"  •  ENDLESS RUN"
	# Existing foreground chunks are retained; upcoming recycled scenery changes.
	world_sun.light_color=[Color("#ffdfb0"),Color("#c2f4ff"),Color("#d4b5ff")][world_index]
	world_environment.ambient_light_color=[Color("#c5d9ee"),Color("#bbf1ff"),Color("#b9b9ff")][world_index]
	world_environment.ambient_light_energy=[0.42,0.44,0.40][world_index]
	if sky_panorama!=null and biome_skies.size()==3: sky_panorama.panorama=biome_skies[world_index]
	for backdrop in backdrop_nodes: backdrop.visible=int(backdrop.get_meta("biome"))==world_index
	show_skill(WORLD_NAMES[world_index].to_upper())
	audio.call("play_fx","portal")

func collect_kind(kind: int) -> void:
	match kind:
		PICKUP,AIR_COIN:
			var value:=2 if double_time>0 else 1
			if kind==AIR_COIN:
				value+=1
				jet_coins+=1
			if surf_time>0: value+=1
			if treasure_time>0: value+=1
			coins+=value
			combo+=1
			best_combo=maxi(best_combo,combo)
			combo_timer=1.05
			if combo%10==0:
				skill_points+=50*mini(int(combo/5.0),5)
				show_skill("COIN COMBO ×%d"%combo)
				audio.call("play_fx","skill")
			challenge_event(0)
			pickup_feedback.text="+%d coins"%value if value>1 else "+1 coin"
			pickup_flash=0.55
			audio.call("play_fx","coin",1.0+0.035*float(mini(combo%10,9)))
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
			slow_time=TIME_ORB_DURATION
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
		SURF:
			# Picking up a board mid-duck or mid-fast-fall must not cancel the action.
			surf_time=SURF_DURATION
			surf_end_reason=""
		JETPACK:
			jet_time=JET_DURATION
			jet_runs+=1
			jet_coin_at=distance+12.0
			# Jetpack and board can coexist. Neither pickup silently destroys the other.
			slide=0.0
			air_slide_pending=false
			show_skill("SKY FLIGHT — COLLECT AIR COINS")
		PORTAL:
			enter_next_world()
		TREASURE:
			treasure_opened+=1
			treasure_time=5.0
			skill_points+=350
			show_skill("TREASURE ROUTE +350")
			audio.call("play_fx","treasure")
		CARD:
			cards+=1
			if cards==3:
				cards=0
				card_sets+=1
				skill_points+=750
				show_skill("SKY CHRONICLE COMPLETE +750")
				audio.call("play_fx","challenge")
			else:
				show_skill("SKY CHRONICLE %d/3"%cards)
				audio.call("play_fx","card")
	if kind>=MAGNET and kind<=BOOST or kind==TIME_ORB or kind==SPRING or kind==SMASH or kind==SURF or kind==JETPACK:
		pickup_feedback.text={MAGNET:"MAGNET",SHIELD:"SHIELD",DOUBLE:"DOUBLE COINS",BOOST:"TURBO",TIME_ORB:"TIME BUBBLE",SPRING:"DOUBLE JUMP",SMASH:"SMASH MODE",SURF:"SKY SURF",JETPACK:"JETPACK"}[kind]
		pickup_flash=1.0
		audio.call("play_fx","power")

func make_burst_pool() -> void:
	# One original Blender mesh, shared by four bounded one-shot emitters.
	var source:=asset(fx,"reward_spark",Vector3.ZERO)
	if source==null: return
	var parts:=source.find_children("*","MeshInstance3D",true,false)
	if parts.is_empty():
		source.queue_free()
		return
	var shared_mesh:Mesh=(parts[0] as MeshInstance3D).mesh
	source.hide()
	source.queue_free()
	for i in range(4):
		var p:=CPUParticles3D.new()
		p.emitting=false
		p.one_shot=true
		p.amount=12
		p.lifetime=0.45
		p.explosiveness=1.0
		p.direction=Vector3(0,1,0)
		p.spread=80
		p.gravity=Vector3(0,-5,0)
		p.initial_velocity_min=1.8
		p.initial_velocity_max=4.2
		p.scale_amount_min=0.6
		p.scale_amount_max=1.3
		p.mesh=shared_mesh
		p.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fx.add_child(p)
		burst_pool.append(p)

func reward_burst(position:Vector3, tint:Color, strong:=false) -> void:
	if burst_pool.is_empty(): return
	var p:=burst_pool[burst_index]
	burst_index=(burst_index+1)%burst_pool.size()
	p.position=position
	p.color=tint
	p.amount=12 if strong else 6
	p.restart()
	p.emitting=true
	burst_count+=1

func make_effects() -> void:
	fx=Node3D.new()
	add_child(fx)
	make_burst_pool()
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
	# Two shared emissive trail strips follow the board, never allocate mid-run.
	var trail_mesh:=BoxMesh.new()
	trail_mesh.size=Vector3(0.065,0.035,2.5)
	for side in [-1,1]:
		var trail:=mesh(fx,trail_mesh,Vector3.ZERO,Color.WHITE)
		trail.material_override=speed_line_mat
		trail.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		trail.hide()
		surf_trails.append(trail)

func update_effects(dt:float) -> void:
	aura.visible=shield_time>0 or boost_time>0 or smash_charges>0 or surf_grace>0
	if rescue_buddy!=null:
		rescue_buddy.visible=rescue_time>0
		if rescue_buddy.visible:
			rescue_buddy.position.x=lerpf(rescue_buddy.position.x,player.position.x+0.57,minf(1,dt*6))
			rescue_buddy.position.y=0.10+absf(sin(clock*12))*0.18+player.position.y*0.35
			rescue_buddy.position.z=1.50+sin(clock*5)*0.13
	power_ring.visible=magnet_time>0 or boost_time>0 or shield_time>0 or slow_time>0
	power_ring.rotation.y=clock*2.0
	power_ring.scale=Vector3.ONE*(1.0+sin(clock*7)*0.08)
	for i in range(scene_anim.size()):
		scene_anim[i].position.y=scene_anim_origins[i].y+sin(clock*0.35+float(i))*0.32
	if sky_ship!=null:
		sky_ship.position=ship_origin+Vector3(sin(clock*0.18)*5.0,sin(clock*0.42)*0.75,0)
		sky_ship.rotation.z=sin(clock*0.35)*0.04
	for i in range(surf_trails.size()):
		var trail:=surf_trails[i]
		trail.visible=surf_time>0
		trail.position=Vector3(player.position.x+(-0.42 if i==0 else 0.42),player.position.y+surf_lift()-0.20+jet_lift,1.65)
		trail.rotation.z=mascot.rotation.z
		trail.scale.z=1.0+0.12*sin(clock*18+i)
	var intensity:=clampf((speed-12.0)/13.0,0,1)
	speed_line_mat.albedo_color=Color(0.65,0.88,1.0,0.12+intensity*0.30)
	for i in range(speed_lines.size()):
		var line:=speed_lines[i]
		line.visible=intensity>0.15 or boost_time>0 or surf_time>0 or jet_time>0
		line.position=Vector3((-1.0 if i%2==0 else 1.0)*(2.5+float(i%3)*0.20),0.10,fposmod(clock*(8+speed*0.5)+float(i)*4.3,35.0)-29.0)
		line.scale.z=1.0+intensity*2.4
	if player.is_on_floor() and slide<=0 and surf_time<=0 and jet_lift<0.1 and int(clock*15)!=int((clock-dt)*15):
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
		0: return feet_y<1.04 and lateral<1.0
		1:
			if lateral>0.38 and lateral<1.0:
				return feet_y<1.94
			return lateral<0.98 and feet_y<1.66 and top>1.18
		LOW_BAR: return feet_y<0.84 and lateral<1.03
		CART: return feet_y<2.76 and lateral<1.03
		COURIER: return feet_y<2.22 and lateral<1.03
		ROLLER: return feet_y<1.30 and lateral<0.98
		TALL: return feet_y<3.10 and lateral<1.03
	return false

func make_power_card(name_text:String, duration:float, accent:Color) -> void:
	var card:=VBoxContainer.new()
	card.custom_minimum_size.x=106
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.mouse_filter=Control.MOUSE_FILTER_IGNORE
	card.add_theme_constant_override("separation",1)
	power_grid.add_child(card)
	var name_label:=hud_label(card,name_text,10,accent)
	name_label.add_theme_color_override("font_outline_color",Color("#101827"))
	name_label.add_theme_constant_override("outline_size",5)
	var bar:=ProgressBar.new()
	bar.max_value=duration
	bar.step=0.0
	bar.show_percentage=false
	bar.custom_minimum_size=Vector2(100,5)
	bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var bg:=StyleBoxFlat.new()
	bg.bg_color=Color("#253753")
	bg.set_corner_radius_all(3)
	var fill:=StyleBoxFlat.new()
	fill.bg_color=accent
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background",bg)
	bar.add_theme_stylebox_override("fill",fill)
	card.add_child(bar)
	power_cards[name_text]={"card":card,"label":name_label,"bar":bar}
	card.hide()

func set_power_card(name_text:String,remaining:float,suffix:String="") -> bool:
	var item:Dictionary=power_cards[name_text]
	var card:=item["card"] as VBoxContainer
	var bar:=item["bar"] as ProgressBar
	var name_label:=item["label"] as Label
	var active:=remaining>0.0 and not ended
	card.visible=active
	bar.value=remaining if active else 0.0
	if active:
		var next_label:="%s %ds%s"%[name_text,ceili(remaining),suffix]
		if name_label.text!=next_label: name_label.text=next_label
	return active

func update_hud() -> void:
	var active_count:=0
	for active in [set_power_card("MAGNET",magnet_time),set_power_card("SHIELD",shield_time),set_power_card("×2 COINS",double_time),set_power_card("TURBO",boost_time),set_power_card("TIME BUBBLE",slow_time),set_power_card("DOUBLE JUMP",spring_time),set_power_card("SMASH",smash_time if smash_charges>0 else 0.0," ×%d"%smash_charges),set_power_card("SKY SURF",surf_time),set_power_card("JETPACK",jet_time),set_power_card("TREASURE",treasure_time),set_power_card("RESCUE",rescue_time)]:
		if active: active_count+=1
	power_grid.visible=active_count>0
	power_label.hide()
	var challenge_text:="%s %d/%d  ·  Gems %d/3  ·  Cards %d/3"%[challenge_name(),challenge_progress,challenge_goal(),gems,cards]
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
		var store=get_node_or_null("/root/PetStore")
		result_button.text="Collect & return" if store!=null and store.arcade_mode==4 else "Run again"
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
	assert(base_run_speed(0.0)==START_SPEED and START_SPEED>9.0 and MAX_SPEED==base_run_speed(2000.0))
	assert(not time_orb_eligible(100.0) and not time_orb_eligible(next_time_orb_at-1.0) and time_orb_eligible(next_time_orb_at))
	assert(time_orbs_spawned==0 and row_spacing(0.0,0)<12.0)
	assert(is_equal_approx(row_spacing(100.0,1),base_run_speed(100.0)*0.805))
	assert(is_equal_approx(row_spacing(960.0,3),MAX_SPEED*EXPERT_ROW_SECONDS))
	assert(row_spacing(3200.0,3)<17.0 and row_spacing(3200.0,3)>16.0)
	for entity in entities: assert(int(entity.get_meta("kind"))!=TIME_ORB)
	assert(power_cards.size()==11 and jet_model!=null)
	assert(scenery_visibility_updates>0 and not chunks[SEGMENTS-1].visible)
	assert((mascot.transform.basis*Vector3.BACK).z < -0.99,"mascot must face away")
	assert(using_blender and loaded_assets>20,"Blender assets missing or not instantiated")
	# Isolate control tests from randomly spawned obstacles.
	for entity in entities: entity.queue_free()
	entities.clear()
	spawn_at=distance+1000
	assert(hazard_hit(0,0,false) and hazard_hit(0,0.95,false) and not hazard_hit(0,1.1,false))
	assert(hazard_hit(1,0,false) and not hazard_hit(1,0,true))
	assert(not hazard_hit(1,1.80,false),"clear above red beam")
	assert(hazard_hit(1,1.5,false) and hazard_hit(1,0,true,0.65))
	assert(not hazard_hit(LOW_BAR,1.0,false) and hazard_hit(LOW_BAR,0,true))
	assert(hazard_hit(TALL,2.2,false) and hazard_hit(CART,2.2,false))
	assert(hazard_hit(COURIER,2.1,false) and not hazard_hit(COURIER,2.3,false))
	assert(hazard_hit(ROLLER,0,false) and not hazard_hit(ROLLER,1.4,false))
	var kinds:Dictionary={}
	var saved_seed:=rng.state
	for i in range(80): kinds[hazard_for(3)]=true
	rng.state=saved_seed
	assert(kinds.has(CART) and kinds.has(TALL) and kinds.has(LOW_BAR) and kinds.has(COURIER) and kinds.has(ROLLER))
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
	# Measure sustained travel at long range and at approach, not merely wheel spin.
	for kind in [CART,COURIER,ROLLER]:
		make_entity(0,kind,distance+20.0)
		var cart:=entities.back() as Area3D
		for sample in range(2):
			var cart_z:=cart.position.z
			var start_distance:=distance
			for i in range(30): await get_tree().physics_frame
			assert(not ended and is_equal_approx((cart.position.z-cart_z)/(distance-start_distance),approach_factor(kind)),"continuous oncoming speed")
		for i in range(180): await get_tree().physics_frame
		assert(not ended and not cart.visible,"oncoming vehicle must pass and recycle safely")
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
	update_hud()
	var timer_bar:=power_cards["TIME BUBBLE"]["bar"] as ProgressBar
	assert(timer_bar.is_visible_in_tree() and timer_bar.value>0.0 and timer_bar.value<timer_bar.max_value)
	boost_time=2.0
	for i in range(3): await get_tree().physics_frame
	assert(speed<(base_run_speed(total_distance())+4.0)*0.75,"bubble must override turbo speed")
	slow_time=0.10
	for i in range(10): await get_tree().physics_frame
	assert(slow_time==0.0 and speed>=normal_speed+3.9)
	update_hud()
	assert(not timer_bar.is_visible_in_tree() and timer_bar.value==0.0)
	boost_time=0
	for i in range(3): await get_tree().physics_frame
	assert(speed>=normal_speed)
	# Surf stays equipped through empty gestures, real jump/duck obstacles and landing.
	collect_kind(SURF)
	for i in range(3): await get_tree().physics_frame
	make_entity(1,LOW_BAR,distance+speed*0.35)
	for i in range(42): await get_tree().physics_frame
	assert(not ended and surf_board.visible and surf_time>0)
	var before_surf:=surf_time
	gesture(Vector2(0,-80))
	for i in range(12): await get_tree().physics_frame
	assert(player.position.y>0.5 and surf_board.visible and surf_time>0 and surf_time<before_surf)
	gesture(Vector2(0,80))
	assert(air_slide_pending and surf_time>0)
	for i in range(15): await get_tree().physics_frame
	assert(player.is_on_floor() and slide>0 and surf_board.visible and surf_time>0)
	for i in range(45): await get_tree().physics_frame
	assert(slide==0 and surf_time>0)
	make_entity(1,0,distance+speed*0.34)
	gesture(Vector2(0,-80))
	for i in range(60): await get_tree().physics_frame
	assert(not ended and surf_time>0 and surf_board.visible and player.is_on_floor())
	make_entity(1,1,distance+speed*0.27)
	gesture(Vector2(0,80))
	assert(surf_time>0 and slide>0 and not hazard_hit(1,surf_lift(),true))
	for i in range(45): await get_tree().physics_frame
	assert(not ended and surf_board.visible and surf_time>0 and surf_saves==0)
	# Exercise the actual mobile swipe path and footer button repeatedly on empty track.
	collect_kind(SURF)
	var prior_ends:=surf_end_count
	var before_swipes:=surf_time
	for i in range(4):
		var down:=InputEventScreenTouch.new()
		down.index=5
		down.pressed=true
		down.position=Vector2(200,300)
		_unhandled_input(down)
		var swipe:=InputEventScreenDrag.new()
		swipe.index=5
		swipe.position=Vector2(200,420)
		_unhandled_input(swipe)
		down.pressed=false
		down.position=swipe.position
		_unhandled_input(down)
		for tick in range(12): await get_tree().physics_frame
		update_hud()
		assert(surf_time>0 and surf_end_count==prior_ends and surf_board.visible and slide>0)
		assert((power_cards["SKY SURF"]["bar"] as ProgressBar).is_visible_in_tree())
		assert(speed>=base_run_speed(total_distance())+SURF_SPEED_BONUS-0.1)
	assert(surf_time<before_swipes and surf_time>before_swipes-2.0)
	for tick in range(45): await get_tree().physics_frame
	# A board pickup while sliding must preserve the slide, even on the pickup frame.
	gesture(Vector2(0,80))
	var old_slide:=slide
	collect_kind(SURF)
	assert(slide==old_slide and surf_time==SURF_DURATION)
	for i in range(45): await get_tree().physics_frame
	# Repeat real collisions at the actual maximum speed plus board bonus.
	var original_offset:=distance_offset
	distance_offset=2000.0
	collect_kind(SURF)
	for i in range(3): await get_tree().physics_frame
	assert(is_equal_approx(speed,MAX_SPEED+SURF_SPEED_BONUS))
	make_entity(1,0,distance+speed*0.34)
	gesture(Vector2(0,-80))
	for i in range(60): await get_tree().physics_frame
	assert(not ended and player.is_on_floor() and surf_board.visible and surf_saves==0)
	make_entity(1,1,distance+speed*0.27)
	gesture(Vector2(0,80))
	for i in range(45): await get_tree().physics_frame
	assert(not ended and surf_board.visible and surf_time>0 and surf_saves==0)
	# Timer expiry still removes the board normally without consuming a crash save.
	surf_time=0.01
	for i in range(3): await get_tree().physics_frame
	assert(surf_time==0.0 and not surf_board.visible and not ended and surf_saves==0 and surf_end_reason=="TIME EXPIRED")
	distance_offset=original_offset
	collect_kind(SURF)
	for i in range(3): await get_tree().physics_frame
	assert(speed>=normal_speed+SURF_SPEED_BONUS-0.5)
	var planted:=feet[0].position
	for i in range(10): await get_tree().physics_frame
	assert(feet[0].position.is_equal_approx(planted),"surf feet must stay planted")
	make_entity(1,TALL,distance+1.5)
	for i in range(22): await get_tree().physics_frame
	assert(not ended and surf_time==0 and surf_saves==1 and not surf_board.visible and surf_end_reason=="IMPACT %d"%TALL)
	assert(burst_pool.size()==4 and burst_count>0 and not surf_trails[0].visible)
	for i in range(50): await get_tree().physics_frame
	assert(surf_grace==0 and not ended)
	# Jetpack really lifts the player presentation, avoids ground collisions, and collects sky coins.
	collect_kind(SURF)
	collect_kind(JETPACK)
	assert(surf_time==SURF_DURATION,"jetpack pickup cannot silently destroy surfboard")
	make_entity(1,TALL,distance+4.0)
	for i in range(45): await get_tree().physics_frame
	assert(not ended and jet_lift>4.0 and jet_model.visible)
	make_entity(1,AIR_COIN,distance+0.8)
	var air_before:=jet_coins
	for i in range(15): await get_tree().physics_frame
	assert(jet_coins>air_before)
	jet_time=0.01
	for i in range(80): await get_tree().physics_frame
	assert(jet_lift==0.0 and not jet_model.visible and not ended and surf_time>0 and surf_board.visible)
	surf_time=0.01
	for i in range(3): await get_tree().physics_frame
	# Full-width portal activates even when runner is in an outer lane.
	gesture(Vector2(-80,0))
	make_entity(1,PORTAL,distance+speed*0.30)
	for i in range(45): await get_tree().physics_frame
	assert(world_index==1 and world_visits==1 and not ended)
	gesture(Vector2(80,0))
	for i in range(30): await get_tree().physics_frame
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
	coins=0
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
	assert(slow_time==TIME_ORB_DURATION and spring_time==10)
	challenge_index=0
	challenge_progress=14
	challenge_event(0)
	assert(challenge_index==1 and challenge_progress==0)
	assert(skill_points==before_bonus+1750)
	collect_kind(RESCUE)
	assert(rescued==1 and rescue_time==8 and skill_points==before_bonus+2050)
	collect_kind(SMASH)
	assert(smash_charges==3 and smash_time==12)
	var card_score:=skill_points
	collect_kind(CARD)
	collect_kind(CARD)
	collect_kind(CARD)
	assert(cards==0 and card_sets==1 and skill_points==card_score+750)
	var treasure_score:=skill_points
	collect_kind(TREASURE)
	assert(treasure_opened==1 and treasure_time==5.0 and skill_points==treasure_score+350)
	var before_coins:=coins
	double_time=0
	collect_kind(PICKUP)
	assert(coins==before_coins+2)
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
	# Staged real viewport captures of the world assets, not concept images.
	# Stop physics after the active benchmark; preserve gameplay timing metrics.
	set_physics_process(false)
	for biome in [1,2]:
		enter_next_world()
		for chunk in chunks: refresh_chunk_decor(chunk)
		portal_overlay.color.a=0.0
		skill_feedback.hide()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var frame:=get_viewport().get_texture().get_image()
		assert(frame.save_png("/tmp/pet-dash-biome-%d.png"%biome)==OK)
	print("PET_DASH_RENDER_CAPTURE_OK")
	get_tree().quit(0)

func unassisted_test() -> void:
	await get_tree().physics_frame
	started=true
	var ticks:=0
	while not ended and total_distance()<3200.0 and ticks<20000:
		await get_tree().physics_frame
		ticks+=1
	assert(not ended and total_distance()>=3200.0,"legal route must work without power-ups; seed %d at %.1f m"%[unassisted_seed,total_distance()])
	assert(speed>=MAX_SPEED-0.1 and jet_runs==0 and surf_saves==0 and mixed_rows>40)
	assert(pattern_count>150,"expert run must sustain denser rows at the speed cap")
	assert(expert_rows>100 and expert_action_rows*4>=expert_rows*3-4 and expert_chain_rows>50,"expert obstacle chains must occupy three of every four rows")
	# The same legal-route driver must lose at the cap if it stops jumping/ducking.
	# Keep its exact lane knowledge and disable only vertical gestures.
	var expert_checkpoint:=total_distance()
	var expert_gates:=mixed_rows
	lane_only_review=true
	var late_ticks:=0
	while not ended and total_distance()<expert_checkpoint+120.0 and late_ticks<300:
		await get_tree().physics_frame
		late_ticks+=1
	assert(ended,"lane-only play must fail at max speed even with perfect lane knowledge")
	print("PET_DASH_EXPERT_LANE_ONLY_FAILS seed=",unassisted_seed," after_m=",total_distance()-expert_checkpoint)
	print("PET_DASH_UNASSISTED_PASS seed=",unassisted_seed," distance=",expert_checkpoint," speed=",speed," gates=",expert_gates)
	get_tree().quit(0)

func lane_only_test() -> void:
	# A bot that knows the safe lane, but never jumps or slides, must fail.
	await get_tree().physics_frame
	started=true
	var ticks:=0
	while not ended and ticks<600:
		await get_tree().physics_frame
		ticks+=1
	assert(ended and total_distance()<65.0,"lane switching alone must not clear the opening action gate")
	print("PET_DASH_LANE_ONLY_FAILS ",total_distance())
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
	assert(world_visits>=3,"portals must recur in endless run")
	assert(treasure_routes>=5,"optional treasure routes must recur")
	assert(time_orbs_spawned>=2 and time_orbs_spawned<=5,"rare late-run bubbles only")
	assert(created_entities<240 and peak_active<160)
	assert(mixed_rows>40,"dense alternating action gates must recur")
	assert(forced_lane_changes==pattern_count,"safe lane must change at every row")
	assert(burst_pool.size()==4 and surf_trails.size()==2 and burst_count>20)
	assert(shadow_chunks.size()==SEGMENTS and shadow_transitions>20)
	assert(glow_materials.size()==12)
	assert(coins>20)
	var result:=FileAccess.open("/tmp/pet-dash-soak.json",FileAccess.WRITE)
	assert(result!=null)
	result.store_string(JSON.stringify({"distance":total_distance(),"local_distance":distance,"rebases":rebase_count,"chunk_recycles":chunk_recycles,"steps":steps,"coins":coins,"snacks":snacks,"rescued":rescued,"smashed":smashed,"perfect_dodges":perfect_dodges,"world_visits":world_visits,"treasure_routes":treasure_routes,"treasure_opened":treasure_opened,"reward_bursts":burst_count,"burst_pool":burst_pool.size(),"shadow_transitions":shadow_transitions,"rows":pattern_count,"mixed_rows":mixed_rows,"forced_lane_changes":forced_lane_changes,"jet_runs":jet_runs,"jet_coins":jet_coins,"time_orbs_spawned":time_orbs_spawned,"mandatory_rows":mandatory_rows,"moving_rows":moving_rows,"allocated":created_entities,"reused":reused_entities,"peak_active":peak_active,"scope":"deterministic headless endless physics; 3200m checkpoint plus continued gameplay, not physical-device FPS"}))
	result.close()
	print("PET_DASH_SOAK_PASS")
	get_tree().quit(0)
