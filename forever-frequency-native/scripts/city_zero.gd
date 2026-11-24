extends Node3D
## Forever Frequency — City Zero native 3D vertical slice.
## Every building is a real mesh in a 3D world; no HTML, no sprites-as-buildings.

const GameState = preload("res://scripts/game_state.gd")
const MobileInput = preload("res://scripts/mobile_input.gd")
const CarDoorController = preload("res://scripts/vehicle_door_controller.gd")
const LAMBORGHINI_ORANGE_MODEL = "res://assets/curated_rigged/curated_midengine_supercar.glb"
# Ferrari source has separate author attribution; shown only in opt-in dev QA.
const FERRARI_ROMA_REVIEW_MODEL = "res://assets/review_only/ferrari_roma_2020_REAL_AUTHOR_BODY_DOORS_HOOD_TRUNK.glb"
const CityLife = preload("res://scripts/city_life.gd")
const BEAT: Array[int] = [0, 2, 1, 3, 1, 0, 3, 2]
const LANDMARKS := {
    "La Caldera Records": Vector3(-13, 0, -12),
    "Moon Market": Vector3(12, 0, -12),
    "Forever Home": Vector3(-13, 0, 12),
    "Pixel Garden": Vector3(12, 0, 12),
    "Radio Tower": Vector3(22, 0, 12),
    "Nova Stage": Vector3(0, 0, 23),
    "Available Lot": Vector3(22, 0, -12),
}
const COLORS := {
    "road": Color("2a3038"), "stripe": Color("ddd0bb"),
    "sidewalk": Color("a99f93"), "park": Color("41664e"),
    "studio": Color("5a2831"), "glass": Color("548595"),
    "market": Color("a37d86"), "home": Color("adb6ad"),
    "neon": Color("e15dcb"), "cyan": Color("46dbe0"),
    "warm": Color("ffc185"), "soil": Color("80674f")
}

var game: ForeverGameState
var hero: CharacterBody3D
var hero_mesh: Node3D
var companion: Node3D
var camera: Camera3D
var mobile: CityMobileInput
var ui_root: Control
var camera_yaw := 0.45
var camera_pitch := 0.42
var speed := 7.1
var camera_distance := 10.25
var touch_interact := false
var panel: PanelContainer
var hint: Label
var mission: Label
var currency: Label
var world_time_label: Label
var music_message: Label
var music_index := 0
var overlay: Control
var stage_visual: Node3D
var town_clock := 18.0
var ui_refresh := 0.0
var status_until := 0.0
var mouse_captured := false
var car: Node3D
var lamborghini_orange_car: Node3D
var lamborghini_orange_doors
var ferrari_roma_review_car: Node3D
var ferrari_roma_review_door_controller
var ferrari_roma_review_hood: Node3D
var ferrari_roma_review_trunk: Node3D
var citizens: Array[Dictionary] = []
var audio_player: AudioStreamPlayer
var road_material: StandardMaterial3D
var sidewalk_material: StandardMaterial3D

func _ready() -> void:
    game = GameState.new()
    game.load_save()
    _create_environment()
    _create_ground_and_streets()
    _create_city()
    _spawn_approved_lamborghini_orange_in_city()
    # Does NOT distribute or spawn visually rejected assets in the player game.
    # Only a development QA run with the original source asset explicitly
    # injected and opt-in flag sees the unreleased Ferrari candidate.
    if OS.get_environment("CITYZERO_DEV_FERRARI_ROMA") == "1":
        _spawn_unapproved_ferrari_roma_preview()
    # Full Blender-batched city dressing; editable separately, not another greybox.
    if ResourceLoader.exists("res://assets/urban_life_district.glb"):
        var district: PackedScene = load("res://assets/urban_life_district.glb")
        var runtime_streetscape := district.instantiate()
        runtime_streetscape.name = "Blender_Premium_Urban_District"
        add_child(runtime_streetscape)
    _create_citizens()
    _create_player()
    if ResourceLoader.exists("res://assets/car_2026_ev_sedan.glb") and ResourceLoader.exists("res://assets/citizen_00.glb"):
        var living_city := CityLife.new()
        living_city.name = "City_Life_Motion_and_Street_Systems"
        add_child(living_city)
    _create_mobile_ui()
    _create_music_audio()
    _update_hud()
    if game.offline_income > 0:
        _message("City Zero earned %d coins while you were away!" % game.offline_income, 5.0)
    else:
        _message("Welcome to City Zero • Walk to La Caldera Records, press E", 5.0)

func _exit_tree() -> void:
    if game != null:
        game.save_game()

func _make_material(c: Color, emission: bool = false, metallic: float = 0.0) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = c
    mat.metallic = metallic
    mat.roughness = 0.72 if not emission else 0.32
    if emission:
        mat.emission_enabled = true
        mat.emission = c
        mat.emission_energy_multiplier = 1.8
    return mat

func _box(parent: Node3D, pos: Vector3, scale: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = scale
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = pos
    node.material_override = _make_material(color, glow)
    parent.add_child(node)
    return node

func _sphere(parent: Node3D, pos: Vector3, radius: float, color: Color, glow: bool = false) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 12
    mesh.rings = 8
    node.mesh = mesh
    node.position = pos
    node.material_override = _make_material(color, glow)
    parent.add_child(node)
    return node

func _solid(parent: Node3D, pos: Vector3, scale: Vector3, color: Color) -> StaticBody3D:
    var solid := StaticBody3D.new()
    solid.position = pos
    parent.add_child(solid)
    _box(solid, Vector3.ZERO, scale, color)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = scale
    collision.shape = shape
    solid.add_child(collision)
    return solid

func _nameplate(parent: Node3D, caption: String, pos: Vector3, c: Color = Color.WHITE) -> void:
    var sign := Label3D.new()
    sign.text = caption
    sign.position = pos
    sign.font_size = 70
    sign.pixel_size = 0.005
    sign.modulate = c
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.no_depth_test = false
    sign.outline_size = 8
    sign.outline_modulate = Color("202131")
    parent.add_child(sign)

func _create_environment() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    var sky := Sky.new()
    var dusk := ProceduralSkyMaterial.new()
    # The 2026 district targets a vivid lavender-blue sky and warm pink dusk.
    # A separate original equirectangular alpha-cloud map breaks up flat horizons.
    dusk.sky_top_color = Color("#4c74ad")
    dusk.sky_horizon_color = Color("#d48aa5")
    dusk.ground_horizon_color = Color("#8a6c82")
    dusk.ground_bottom_color = Color("#243349")
    dusk.sky_curve = 0.22
    dusk.use_debanding = true
    if ResourceLoader.exists("res://assets/cloud_cover.png"):
        dusk.sky_cover = load("res://assets/cloud_cover.png")
        dusk.sky_cover_modulate = Color(1.0,0.87,0.93,0.67)
    sky.sky_material = dusk
    env.background_mode = Environment.BG_SKY
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("aaa6ba")
    env.ambient_light_energy = 0.31
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.fog_enabled = true
    env.fog_light_color = Color("43536c")
    env.fog_density = 0.002
    world.environment = env
    add_child(world)
    var sunlight := DirectionalLight3D.new()
    sunlight.rotation_degrees = Vector3(-33, -42, 0)
    sunlight.light_color = Color("ffb68a")
    sunlight.light_energy = 0.71
    sunlight.shadow_enabled = true
    sunlight.directional_shadow_max_distance = 70
    add_child(sunlight)
    var ambient := DirectionalLight3D.new()
    ambient.rotation_degrees = Vector3(-55, 132, 0)
    ambient.light_energy = 0.13
    ambient.light_color = Color("697bba")
    add_child(ambient)


func _city_surface(path: String, fallback: Color, tile: float) -> StandardMaterial3D:
    var mat := _make_material(fallback)
    mat.roughness = 0.90
    if ResourceLoader.exists(path):
        var tex: Texture2D = load(path)
        if tex != null:
            mat.albedo_texture = tex
            mat.albedo_color = Color(0.86,0.88,0.90,1.0)
            mat.uv1_triplanar = true
            mat.uv1_world_triplanar = true
            mat.uv1_scale = Vector3(tile,tile,tile)
    return mat

func _create_ground_and_streets() -> void:
    road_material = _city_surface("res://assets/road_asphalt.jpg",COLORS.road,0.23)
    sidewalk_material = _city_surface("res://assets/sidewalk_concrete.jpg",COLORS.sidewalk,0.42)
    _solid(self, Vector3(0,-0.42,0), Vector3(94,0.8,94), COLORS.park)
    # Long thoroughfares create a walkable street grid, not an isometric board.
    for p in [-30.0, 0.0, 30.0]:
        _box(self, Vector3(p,0.022,0), Vector3(8.7,0.06,94), COLORS.road).material_override = road_material
        _box(self, Vector3(0,0.024,p), Vector3(94,0.055,8.7), COLORS.road).material_override = road_material
        _box(self, Vector3(p - 5.7,0.08,0), Vector3(2.4,0.15,94), COLORS.sidewalk).material_override = sidewalk_material
        _box(self, Vector3(p + 5.7,0.08,0), Vector3(2.4,0.15,94), COLORS.sidewalk).material_override = sidewalk_material
        _box(self, Vector3(0,0.09,p - 5.7), Vector3(94,0.15,2.4), COLORS.sidewalk).material_override = sidewalk_material
        _box(self, Vector3(0,0.09,p + 5.7), Vector3(94,0.15,2.4), COLORS.sidewalk).material_override = sidewalk_material
        for i in range(-8,9):
            var q := i * 5.0
            _box(self, Vector3(p,0.061,q), Vector3(0.10,0.03,1.6), COLORS.stripe)
            _box(self, Vector3(q,0.062,p), Vector3(1.6,0.03,0.10), COLORS.stripe)
    for x in [-30.0, 0.0, 30.0]:
        for z in [-30.0, 0.0, 30.0]:
            for a in range(-4,5):
                _box(self, Vector3(x + a * 0.65,0.07,z + 5.8), Vector3(0.34,0.02,2.6), Color("e2dfd7"))
    # Framed intersections and planted medians make the block feel inhabited.
    for ii in [-1, 1]:
        for iz in [-1, 1]:
            _box(self,Vector3(ii*6.4,0.12,iz*6.4),Vector3(0.18,0.06,7.5),Color("d2c6b8"))
            _box(self,Vector3(ii*6.4,0.12,iz*6.4),Vector3(7.5,0.06,0.18),Color("d2c6b8"))
    # Perimeter park and a pedestrian waterfront promenade.
    _box(self, Vector3(-40,0.04,0), Vector3(3,0.10,86), Color("b1a58d"))
    _box(self, Vector3(-43,0.035,0), Vector3(3,0.07,86), Color("368d9b"))
    for i in range(-9,10):
        _tree(Vector3(-37,0,i*4.4), 0.8)

func _make_building(name: String, center: Vector3, size: Vector3, wall: Color, glass: Color, accent: Color, primitive_visual: bool = true) -> Node3D:
    var group := Node3D.new()
    group.name = name.replace(" ", "_")
    group.position = center
    add_child(group)
    if not primitive_visual:
        var body := StaticBody3D.new()
        group.add_child(body)
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.position.y = size.y / 2.0
        collision.shape = shape
        body.add_child(collision)
        return group
    _solid(group, Vector3(0,size.y/2,0), size, wall)
    _box(group, Vector3(0,size.y+0.2,0), Vector3(size.x+0.7,0.35,size.z+0.7), Color("242d44"))
    _box(group, Vector3(0,0.12,size.z/2+0.5), Vector3(size.x+2,0.18,1.5), Color("c2bdc3"))
    # Per-instance windows are consolidated into a small number of draw calls.
    var transforms: Array[Transform3D] = []
    var cols := maxi(2, int(size.x / 1.5))
    var rows := maxi(2, int(size.y / 1.75))
    for floor_idx in range(rows):
        for col_idx in range(cols):
            var y := 1.55 + floor_idx * 1.75
            if y > size.y - 0.45:
                continue
            var x := -size.x/2.0 + (col_idx + 0.5) * size.x / cols
            var tx := Transform3D.IDENTITY
            tx.origin = Vector3(x,y,size.z/2.0 + 0.065)
            transforms.append(tx)
            var back := Transform3D.IDENTITY
            back.origin = Vector3(x,y,-size.z/2.0 - 0.065)
            transforms.append(back)
    var side_cols := maxi(2,int(size.z / 2.0))
    for floor_idx in range(rows):
        for i in range(side_cols):
            var y := 1.55 + floor_idx * 1.75
            if y > size.y - 0.45:
                continue
            var z := -size.z/2.0 + (i+0.5) * size.z/side_cols
            for side in [-1,1]:
                var tr := Transform3D(Basis(Vector3.UP,PI/2.0),Vector3(side*(size.x/2.0+0.065),y,z))
                transforms.append(tr)
    if not transforms.is_empty():
        var window_mesh := BoxMesh.new()
        window_mesh.size = Vector3(0.74,1.02,0.12)
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        mm.mesh = window_mesh
        mm.instance_count = transforms.size()
        for i in range(transforms.size()):
            mm.set_instance_transform(i,transforms[i])
        var batch := MultiMeshInstance3D.new()
        batch.multimesh = mm
        batch.material_override = _make_material(glass,true,0.14)
        group.add_child(batch)
    _box(group, Vector3(0,1.4,size.z/2 + 0.2), Vector3(2.3,2.65,0.25), Color("272d48"))
    _box(group, Vector3(0,1.45,size.z/2 + 0.38), Vector3(1.8,2.15,0.06), glass, true)
    _box(group, Vector3(0,size.y-0.2,size.z/2 + 0.35), Vector3(size.x+0.25,0.2,0.25), accent,true)
    _nameplate(group, name.to_upper(), Vector3(0, size.y + 1.1, size.z/2+0.25), Color.WHITE)
    return group

func _tree(pos: Vector3, scale_factor: float = 1.0) -> void:
    var root := Node3D.new()
    root.position = pos
    root.scale = Vector3.ONE * scale_factor
    add_child(root)
    if ResourceLoader.exists("res://assets/street_tree.glb"):
        var tree_scene: PackedScene = load("res://assets/street_tree.glb")
        root.add_child(tree_scene.instantiate())
        return
    _box(root,Vector3(0,1.0,0), Vector3(0.36,2.0,0.36), Color("6b4c40"))
    _sphere(root,Vector3(0,2.9,0),1.25,Color("347e63"))
    _sphere(root,Vector3(-0.6,2.7,0.3),0.82,Color("4b9a76"))
    _sphere(root,Vector3(0.7,3.1,-0.3),0.78,Color("3c8e79"))

func _lamp(pos: Vector3, pink: bool = false) -> void:
    var group := Node3D.new()
    group.position = pos
    add_child(group)
    if ResourceLoader.exists("res://assets/street_lamp.glb"):
        var lamp_scene: PackedScene = load("res://assets/street_lamp.glb")
        group.add_child(lamp_scene.instantiate())
        return
    _box(group,Vector3(0,2,0),Vector3(0.16,4,0.16),Color("282e42"))
    _box(group,Vector3(0.65,4,0),Vector3(1.3,0.15,0.17),Color("282e42"))
    _sphere(group,Vector3(1.18,3.8,0),0.25,COLORS.neon if pink else COLORS.warm,true)
    var light := OmniLight3D.new()
    light.position = Vector3(1.1,3.65,0)
    light.light_color = COLORS.neon if pink else COLORS.warm
    light.light_energy = 0.7
    light.omni_range = 6
    light.shadow_enabled = false
    group.add_child(light)

func _create_city() -> void:
    var has_studio := ResourceLoader.exists("res://assets/la_caldera_records.glb")
    var studio := _make_building("LA CALDERA RECORDS",Vector3(-14,0,-14),Vector3(12,10,10),COLORS.studio,COLORS.glass,COLORS.neon,not has_studio)
    if has_studio:
        _spawn_blender_prop("res://assets/la_caldera_records.glb",Vector3(-14,0,-14),Vector3.ONE)
    else:
        _box(studio,Vector3(0,5.5,5.33),Vector3(10.1,3.2,0.3),Color("335e7d"))
        _nameplate(studio,"LA CALDERA  /  RECORDS",Vector3(0,8,5.68),Color("f4e1c2"))
    var market_asset := ResourceLoader.exists("res://assets/moon_market.glb")
    var market := _make_building("MOON MARKET",Vector3(13,0,-13),Vector3(11,6.5,10),COLORS.market,COLORS.warm,Color("ff827e"),not market_asset)
    if market_asset:
        _spawn_blender_prop("res://assets/moon_market.glb",Vector3(13,0,-13),Vector3.ONE)
    else:
        _box(market,Vector3(0,3,5.8),Vector3(10.9,0.5,2.2),Color("d86d83"))
    var home_asset := ResourceLoader.exists("res://assets/forever_home.glb")
    _make_building("FOREVER HOME",Vector3(-14,0,13),Vector3(11,8.5,11),COLORS.home,Color("8fd7ed"),Color("fd8fca"),not home_asset)
    if home_asset:
        _spawn_blender_prop("res://assets/forever_home.glb",Vector3(-14,0,13),Vector3.ONE)
    for i in range(3):
        _tree(Vector3(-20+i*3.0,0,20),0.75)
    var garden := Node3D.new()
    garden.name = "Pixel_Garden"
    garden.position = Vector3(12,0,13)
    add_child(garden)
    if ResourceLoader.exists("res://assets/pixel_garden.glb"):
        var scene: PackedScene = load("res://assets/pixel_garden.glb")
        garden.add_child(scene.instantiate())
    else:
        _box(garden,Vector3(0,0.35,0),Vector3(11,0.7,11),Color("bda98b"))
        for i in range(4):
            for j in range(3):
                _box(garden,Vector3(-4+i*2.4,0.75,-3+j*3),Vector3(1.7,0.35,2.2),COLORS.soil)
                _sphere(garden,Vector3(-4+i*2.4,1.0,-3+j*3),0.42,Color("65c384"))
        _nameplate(garden,"PIXEL GARDEN",Vector3(0,3,0),Color("d2fabe"))
    var radio := Node3D.new()
    radio.position = Vector3(23,0,13)
    add_child(radio)
    if ResourceLoader.exists("res://assets/radio_one.glb"):
        var scene: PackedScene = load("res://assets/radio_one.glb")
        radio.add_child(scene.instantiate())
    else:
        _box(radio,Vector3(0,2,0),Vector3(5.6,4,5.6),Color("53617c"))
        for h in range(4):
            _box(radio,Vector3(0,5+h*2.2,0),Vector3(0.45,2.2,0.45),Color("bdc6ce"))
            _box(radio,Vector3(0,5+h*2.2,0),Vector3(3.2-h*0.35,0.16,0.16),COLORS.cyan,true)
        _nameplate(radio,"RADIO ONE",Vector3(0,6,3),COLORS.cyan)
    stage_visual = Node3D.new()
    stage_visual.name = "Nova_Stage"
    stage_visual.position = Vector3(0,0,23)
    add_child(stage_visual)
    if ResourceLoader.exists("res://assets/nova_stage.glb"):
        var scene: PackedScene = load("res://assets/nova_stage.glb")
        stage_visual.add_child(scene.instantiate())
    else:
        _box(stage_visual,Vector3(0,0.5,0),Vector3(13,1,8),Color("272c48"))
        _box(stage_visual,Vector3(0,5,-3.4),Vector3(13.5,0.4,0.35),COLORS.neon,true)
        for p in [-6.0,6.0]:
            _box(stage_visual,Vector3(p,3,-3.4),Vector3(0.3,6,0.3),Color("829ab2"))
        _nameplate(stage_visual,"NOVA STAGE",Vector3(0,6.3,-3),Color("ffdcf9"))
    _box(self,Vector3(23,0.10,-13),Vector3(12,0.2,12),Color("b29b84"))
    _nameplate(self,"FUTURE DISTRICT",Vector3(23,1.8,-13),COLORS.warm)
    for i in range(-3,4):
        _tree(Vector3(-23,0,i*5.6),0.76)
        _tree(Vector3(6.7,0,i*7.2),0.67)
        _lamp(Vector3(5.3,0,i*6.2),i%2==0)
    for i in range(-3,4):
        _lamp(Vector3(i*7,0,5.3),i%2==1)
    if not ResourceLoader.exists("res://assets/car_2026_ev_sedan.glb"):
        for p in [Vector3(2,0,-17), Vector3(-3,0,17), Vector3(29,0,-4)]:
            _parked_car(p)
    for pos in [Vector3(-2.1,0,-7.9),Vector3(-22,0,4),Vector3(5.5,0,16),Vector3(18,0,21)]:
        _spawn_blender_prop("res://assets/city_bench.glb",pos,Vector3.ONE)
    if not ResourceLoader.exists("res://assets/car_2026_ev_sedan.glb"):
        car = Node3D.new()
        car.position = Vector3(-3,0,1)
        add_child(car)
        _car_mesh(car,Color("e09b7d"))
    if not game.stage_built:
        if not ResourceLoader.exists("res://assets/nova_stage.glb"):
            _box(stage_visual,Vector3(0,0.9,1),Vector3(6,0.5,3),Color("677184"))
    else:
        _add_stage_fx()

func _spawn_unapproved_ferrari_roma_preview() -> void:
    # Evaluator-only: source-verified Ferrari Roma has independent real
    # artist-authored doors/body glass plus hood and trunk mechanics.
    # This GLB must NEVER be included by default in the Android release.
    var raw: String = ProjectSettings.globalize_path(FERRARI_ROMA_REVIEW_MODEL)
    if not FileAccess.file_exists(raw):
        push_error("CITYZERO_FERRARI_DEVELOPMENT_ASSET_NOT_PROVIDED: "+raw)
        return
    var original_doc := GLTFDocument.new()
    var original_state := GLTFState.new()
    var result: Error = original_doc.append_from_file(raw,original_state)
    if result != OK:
        push_error("CITYZERO_FERRARI_ROMA_REVIEW_ORIGINAL_MESH_IMPORT_FAILED "+str(result))
        return
    ferrari_roma_review_car = original_doc.generate_scene(original_state) as Node3D
    if ferrari_roma_review_car == null:
        push_error("CITYZERO_FERRARI_ROMA_REVIEW_MISSING_NATIVE_MESH_ROOT")
        return
    ferrari_roma_review_car.name = "CityZero_UNAPPROVED_FerrariRoma_Real_Hinges_DevQA"
    ferrari_roma_review_car.position = Vector3(7.7,0.08,-25.0)
    ferrari_roma_review_car.rotation.y = PI
    add_child(ferrari_roma_review_car)
    ferrari_roma_review_door_controller = CarDoorController.new()
    ferrari_roma_review_door_controller.name = "QA_Only_Real_Ferrari_Door_Leaf_Controller"
    ferrari_roma_review_car.add_child(ferrari_roma_review_door_controller)
    var door_ids: Array[String] = ferrari_roma_review_door_controller.available_doors()
    ferrari_roma_review_hood = ferrari_roma_review_car.find_child("HOOD_FRONT_HINGE",true,false) as Node3D
    ferrari_roma_review_trunk = ferrari_roma_review_car.find_child("TRUNK_REAR_HINGE",true,false) as Node3D
    if door_ids.size() != 2 or ferrari_roma_review_hood == null or ferrari_roma_review_trunk == null:
        push_error("CITYZERO_FERRARI_REVIEW_FOUR_TRUE_AUTHOR_PIVOTS_MISSING")
        ferrari_roma_review_car.queue_free()
        ferrari_roma_review_car = null
        ferrari_roma_review_door_controller = null
        ferrari_roma_review_hood = null
        ferrari_roma_review_trunk = null
        return
    print("CITYZERO_FERRARI_ROMA_REAL_GAME_MAIN_SCENE_DEV_REVIEW_ONLY: 2 original doors, true hood, true trunk; NOT ART APPROVED")


func _spawn_approved_lamborghini_orange_in_city() -> void:
    # The already-approved original CC0 curated midengine supercar: real authored
    # GLB from the prior CityZero car audit, two fully rigged door hinges.
    # Only the real exported GLB is accepted. Missing model => no fake car.
    # Godot's editor .glb.import file may fail to materialize in CI even
    # though Blender exported the genuine GLB successfully. Read that exact
    # original binary at runtime instead of depending on editor ResourceLoader.
    var actual_glb := ProjectSettings.globalize_path(LAMBORGHINI_ORANGE_MODEL)
    if not FileAccess.file_exists(actual_glb):
        push_warning("CITY_ZERO_LAMBORGHINI_ORANGE_ASSET_MISSING: " + actual_glb)
        return
    var gltf_doc := GLTFDocument.new()
    var gltf_state := GLTFState.new()
    var import_status := gltf_doc.append_from_file(actual_glb, gltf_state)
    if import_status != OK:
        push_error("CITY_ZERO_LAMBORGHINI_ORANGE_ORIGINAL_GLB_LOAD_FAILED: " + str(import_status))
        return
    lamborghini_orange_car = gltf_doc.generate_scene(gltf_state) as Node3D
    if lamborghini_orange_car == null:
        push_error("CITY_ZERO_LAMBORGHINI_ORANGE_INVALID_GLTF_ROOT")
        return
    lamborghini_orange_car.name = "CityZero_Approved_Orange_Lamborghini"
    # Keep clear of the generic traffic car at (2, 0, -17).
    lamborghini_orange_car.position = Vector3(-2.3, 0.08, -25.0)
    lamborghini_orange_car.rotation.y = PI
    add_child(lamborghini_orange_car)
    lamborghini_orange_doors = CarDoorController.new()
    lamborghini_orange_doors.name = "Mechanical_Pair_Of_Doors"
    lamborghini_orange_car.add_child(lamborghini_orange_doors)
    var names: Array[String] = lamborghini_orange_doors.available_doors()
    if names.size() != 2:
        push_error("LAMBORGHINI_ORANGE requires two real mechanical door hinges, got " + str(names))
        lamborghini_orange_car.queue_free()
        lamborghini_orange_car = null
        lamborghini_orange_doors = null
        return
    print("CITY_ZERO_LAMBORGHINI_ORANGE_IN_CITY_OK: ", lamborghini_orange_car.global_position, " doors=", names)


func toggle_lamborghini_orange_doors() -> bool:
    if lamborghini_orange_car == null or lamborghini_orange_doors == null:
        return false
    # A parked car may be opened from the street; never open random traffic.
    if hero != null and hero.global_position.distance_to(lamborghini_orange_car.global_position) > 10.0:
        _message("Approach the Lamborghini-style supercar to open its doors.", 2.5)
        return false
    var names: Array[String] = lamborghini_orange_doors.available_doors()
    if names.size() != 2:
        return false
    var opening: bool = not lamborghini_orange_doors.is_door_open(names[0])
    for door_name in names:
        if lamborghini_orange_doors.is_door_open(door_name) != opening:
            lamborghini_orange_doors.toggle_door(door_name)
    _message("LAMBORGHINI • DOORS OPEN" if opening else "LAMBORGHINI • DOORS CLOSED", 2.6)
    return true


func _spawn_blender_prop(path: String, pos: Vector3, scl: Vector3) -> void:
    if not ResourceLoader.exists(path):
        return
    var packed = load(path)
    if packed is PackedScene:
        var instance: Node3D = packed.instantiate()
        add_child(instance)
        instance.position = pos
        instance.scale = scl

func _add_stage_fx() -> void:
    for i in range(6):
        _box(stage_visual,Vector3(-5+i*2.0,1.8,-3.1),Vector3(0.8,0.6,0.3),COLORS.cyan if i%2==0 else COLORS.neon,true)

func _car_mesh(root: Node3D, color: Color) -> void:
    if ResourceLoader.exists("res://assets/city_car.glb"):
        var scene: PackedScene = load("res://assets/city_car.glb")
        root.add_child(scene.instantiate())
        return
    _box(root,Vector3(0,0.55,0),Vector3(2.0,0.8,3.8),color)
    _box(root,Vector3(0,1.15,-0.2),Vector3(1.7,0.7,1.9),Color("7197ab"))
    for x in [-0.96,0.96]:
        for z in [-1.2,1.2]:
            _sphere(root,Vector3(x,0.33,z),0.33,Color("252c38"))
    for x in [-0.65,0.65]:
        _box(root,Vector3(x,0.65,-1.94),Vector3(0.4,0.2,0.08),Color("ffebbb"),true)

func _parked_car(p: Vector3) -> void:
    var root := Node3D.new()
    root.position = p
    root.rotation.y = 1.57
    add_child(root)
    _car_mesh(root,Color("7c98bb") if p.x < 0 else Color("d1b5a4"))

func _create_citizens() -> void:
    # Prefer distinct Blender character models over identical avatar recolors.
    if ResourceLoader.exists("res://assets/citizen_00.glb"):
        return
    for i in range(12):
        var citizen := Node3D.new()
        add_child(citizen)
        var tone := Color.from_hsv(float(i%6)/10.0 + 0.05,0.38,0.86)
        if ResourceLoader.exists("res://assets/artist_avatar.glb"):
            var citizen_model: PackedScene = load("res://assets/artist_avatar.glb")
            var citizen_visual: Node3D = citizen_model.instantiate()
            citizen.add_child(citizen_visual)
            _dress_citizen_avatar(citizen_visual, i)
            citizen.scale = Vector3.ONE * (0.84 + 0.028 * float(i % 7))
        else:
            _sphere(citizen,Vector3(0,1.9,0),0.30,Color("d5b49c"))
            _box(citizen,Vector3(0,1.12,0),Vector3(0.48,1.0,0.35),tone)
            for x in [-0.15,0.15]:
                _box(citizen,Vector3(x,0.38,0),Vector3(0.17,0.74,0.20),Color("2e354a"))
        var px := -22.0+float(i%6)*8
        var pz := -5.8 if i%2==0 else 5.8
        citizen.position = Vector3(px,0,pz)
        citizens.append({"node":citizen,"phase":float(i)*1.6,"axis":i%2,"start":citizen.position})

func _dress_citizen_avatar(actor: Node3D, style: int) -> void:
    # Adversarial visual gate: a city with 12 exact clones is NOT an inhabited city.
    # Keep the single lightweight Blender mesh but create per-citizen clothing,
    # hair, skin and accessory palettes. Never tint the full character.
    var jackets: Array[Color] = [
        Color("8d4559"), Color("597284"), Color("b78554"), Color("637b5a"),
        Color("76638d"), Color("c6a88b"), Color("3c7674"), Color("b97168")
    ]
    var trousers: Array[Color] = [
        Color("292f43"), Color("3e4259"), Color("715c50"), Color("354947"),
        Color("41415a"), Color("5f514a"), Color("273b40"), Color("48425a")
    ]
    var skins: Array[Color] = [
        Color("a8775b"), Color("d3a58a"), Color("916449"), Color("b88d72"),
        Color("ddba9c"), Color("825640"), Color("bb9277"), Color("9f7257")
    ]
    for node in actor.find_children("*", "MeshInstance3D", true, false):
        var part := node as MeshInstance3D
        if part == null or part.mesh == null:
            continue
        var item := part.name.to_lower()
        if (style % 4 == 0) and ("headphone" in item or "headphone halo" in item):
            part.visible = false
        if (style % 5 == 0) and "producer messenger bag" in item:
            part.visible = false
        var chosen := Color.TRANSPARENT
        if "hoodie oversized torso" in item:
            chosen = jackets[style % jackets.size()]
        elif "jogger trouser leg" in item:
            chosen = trousers[style % trousers.size()]
        elif "hands" in item:
            chosen = skins[style % skins.size()]
        elif "sideburns" in item:
            chosen = Color("2b252b") if style % 2 == 0 else Color("604331")
        elif "training sneakers" in item:
            chosen = Color("e7dbc5") if style % 3 == 0 else Color("313c52")
        if chosen.a > 0.0:
            var source_mat := part.mesh.surface_get_material(0)
            if source_mat is BaseMaterial3D:
                var instance_mat := (source_mat as BaseMaterial3D).duplicate() as BaseMaterial3D
                instance_mat.albedo_color = chosen
                part.material_override = instance_mat

func _create_player() -> void:
    hero = CharacterBody3D.new()
    hero.name = "Player"
    hero.position = Vector3(-8.5,0.1,-2.2)
    add_child(hero)
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.39
    capsule.height = 2.15
    collider.position.y = 1.08
    collider.shape = capsule
    hero.add_child(collider)
    hero_mesh = Node3D.new()
    hero.add_child(hero_mesh)
    if ResourceLoader.exists("res://assets/artist_avatar.glb"):
        var artist_scene: PackedScene = load("res://assets/artist_avatar.glb")
        hero_mesh.add_child(artist_scene.instantiate())
    else:
        _box(hero_mesh, Vector3(0,1.12,0),Vector3(0.68,0.98,0.42), Color("25345d"))
        _sphere(hero_mesh,Vector3(0,1.92,0),0.39,Color("d1a68f"))
        _sphere(hero_mesh,Vector3(0,2.18,-0.08),0.38,Color("24263c"))
        _box(hero_mesh, Vector3(0,1.02,-0.24),Vector3(0.54,0.16,0.12),COLORS.neon,true)
        for x in [-0.22,0.22]:
            _box(hero_mesh,Vector3(x,0.38,0),Vector3(0.26,0.75,0.3),Color("262c44"))
            _box(hero_mesh,Vector3(x,0.10,-0.10),Vector3(0.35,0.22,0.6),Color("f0ebe9"))
    # Hero identity belongs in the HUD, not a floating debug label.
    companion = Node3D.new()
    companion.name = "Companion"
    companion.position = Vector3(1.4,0,-6.4)
    add_child(companion)
    _pet_mesh()
    camera = Camera3D.new()
    camera.current = true
    camera.fov = 63.0
    camera.near = 0.08
    camera.far = 120.0
    add_child(camera)
    camera.position = Vector3(6,5,6)
    camera.look_at(hero.global_position + Vector3.UP * 1.3)

func _pet_mesh() -> void:
    for child in companion.get_children():
        child.queue_free()
    var col := Color("b2eff0")
    if game.companion == "LUMEN": col = Color("f9b1e9")
    elif game.companion == "SOLAR": col = Color("f6e5a0")
    if ResourceLoader.exists("res://assets/companion_nova.glb"):
        var pet_scene: PackedScene = load("res://assets/companion_nova.glb")
        companion.add_child(pet_scene.instantiate())
    else:
        _sphere(companion,Vector3(0,0.40,0),0.43,col)
        _sphere(companion,Vector3(-0.28,0.72,-0.08),0.2,col)
        _sphere(companion,Vector3(0.28,0.72,-0.08),0.2,col)
        _sphere(companion,Vector3(-0.14,0.42,-0.35),0.055,Color("293047"))
        _sphere(companion,Vector3(0.14,0.42,-0.35),0.055,Color("293047"))
        _sphere(companion,Vector3(0,0.3,-0.40),0.05,COLORS.neon,true)
    # Companion identified through the in-game UI; keep the 3D silhouette unobstructed.

func _physics_process(dt: float) -> void:
    if hero == null or mobile == null:
        return
    var axis := mobile.axis
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): axis.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): axis.y += 1.0
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): axis.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): axis.x += 1.0
    axis = axis.limit_length(1.0)
    var forward := Vector3(sin(camera_yaw),0,cos(camera_yaw))
    var right := Vector3(forward.z,0,-forward.x)
    var move_dir := right * axis.x + forward * axis.y
    if move_dir.length_squared() > 0.01:
        hero_mesh.rotation.y = lerp_angle(hero_mesh.rotation.y,atan2(move_dir.x,move_dir.z),dt*11)
        hero_mesh.position.y = lerpf(hero_mesh.position.y,abs(sin(Time.get_ticks_msec()*0.012))*0.09,dt*8.0)
    else:
        hero_mesh.position.y = lerpf(hero_mesh.position.y,0.0,dt*8.0)
    hero.velocity.x = move_dir.x * speed
    hero.velocity.z = move_dir.z * speed
    if hero.is_on_floor():
        hero.velocity.y = -0.6
    else:
        hero.velocity.y -= 17 * dt
    hero.move_and_slide()
    hero.position.x = clampf(hero.position.x,-43,43)
    hero.position.z = clampf(hero.position.z,-43,43)
    var look := mobile.consume_look()
    camera_yaw -= look.x * 0.0046
    camera_pitch = clampf(camera_pitch + look.y*0.0034,0.12,0.86)
    var desired := hero.global_position + Vector3(0,1.45,0)
    var orbit := Vector3(sin(camera_yaw)*cos(camera_pitch),sin(camera_pitch),cos(camera_yaw)*cos(camera_pitch))*camera_distance
    camera.global_position = camera.global_position.lerp(desired + orbit, minf(1.0,dt*8.0))
    camera.look_at(desired)
    var pet_target := hero.global_position + Vector3(1.25,0,0.95)
    companion.global_position = companion.global_position.lerp(pet_target,minf(1.0,dt*3.0))
    companion.position.y = 0.1 + sin(Time.get_ticks_msec()*0.004)*0.15

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        camera_yaw -= event.relative.x*0.006
        camera_pitch = clampf(camera_pitch + event.relative.y*0.004,0.12,0.86)
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_E or event.keycode == KEY_SPACE:
            _interact()
        elif event.keycode == KEY_O:
            toggle_lamborghini_orange_doors()
        elif event.keycode == KEY_ESCAPE:
            _hide_panel()

func _process(dt: float) -> void:
    town_clock = fmod(town_clock + dt*0.006,24.0)
    ui_refresh += dt
    if ui_refresh > 0.16:
        ui_refresh = 0.0
        _update_hud()
    for c in citizens:
        var npc: Node3D = c["node"]
        var t := Time.get_ticks_msec()/1000.0 + float(c["phase"])
        var start: Vector3 = c["start"]
        if int(c["axis"]) == 0:
            npc.position = start + Vector3(sin(t*0.32)*5.0,0,0)
            npc.rotation.y = PI*0.5 if cos(t*0.32)>0 else -PI*0.5
        else:
            npc.position = start + Vector3(0,0,sin(t*0.32)*5.0)
            npc.rotation.y = 0 if cos(t*0.32)>0 else PI
    if car != null:
        car.position.z = fmod(Time.get_ticks_msec()*0.002,70.0)-35.0
    if status_until > 0 and Time.get_ticks_msec()/1000.0 > status_until:
        status_until = 0

func _nearest_place() -> String:
    var best := ""
    var best_dist := 6.5
    if hero == null:
        return best
    for key in LANDMARKS:
        var dist: float = hero.position.distance_to(LANDMARKS[key])
        if dist < best_dist:
            best = key
            best_dist = dist
    return best

func _interact() -> void:
    if overlay != null and overlay.visible:
        return
    var place := _nearest_place()
    match place:
        "La Caldera Records": _open_studio()
        "Pixel Garden": _visit_garden()
        "Moon Market": _visit_market()
        "Forever Home": _visit_home()
        "Radio Tower": _visit_radio()
        "Nova Stage": _visit_stage()
        "Available Lot": _visit_lot()
        _: _message("Get closer to a building to interact.",2.5)

func _visit_garden() -> void:
    var result := game.harvest()
    if result["ok"]:
        _message("Harvested Pixel Garden! +%d coins • companion bond increased" % result["coins"],4.0)
    else:
        _message("Seeds are growing. Return in %d seconds." % result["remaining"],3.0)

func _visit_market() -> void:
    if game.open_shop():
        _message("Moon Market expanded! %d business(es) now produce offline income." % game.businesses,4.0)
    else:
        _message("Market expansion costs %d coins (max 3)." % (120 + game.businesses*160),4.0)

func _visit_home() -> void:
    game.companion_bond = mini(100,game.companion_bond+10)
    game.save_game()
    if game.evolve_pet():
        _pet_mesh()
        _message("Your companion evolved into %s!" % game.companion,4.0)
    else:
        _message("Home sweet home! Companion bond %d/30 for evolution." % game.companion_bond,4.0)

func _visit_radio() -> void:
    if game.tracks.is_empty():
        _message("Radio One needs a track. Record something at La Caldera Records!",4.0)
        return
    game.fans += 9 + game.records * 2
    game.coins += 8
    game.save_game()
    _message("Radio One aired %s! New listeners discovered you." % game.tracks.back()["name"],4.0)

func _visit_stage() -> void:
    if not game.stage_built:
        if game.build_stage():
            _add_stage_fx()
            _message("NOVA STAGE UNLOCKED! Your city now hosts live shows.",5.0)
        else:
            _message("Build Nova Stage with 50 fans and 200 coins.",3.5)
    else:
        game.fans += 18
        game.coins += 30
        game.save_game()
        _message("LIVE GIG COMPLETE! +18 fans • +30 coins.",4.0)

func _visit_lot() -> void:
    _message("Next neighborhood expansion • planned for City Zero 0.2",3.5)

func _create_music_audio() -> void:
    audio_player = AudioStreamPlayer.new()
    var stream := AudioStreamGenerator.new()
    stream.mix_rate = 22050.0
    stream.buffer_length = 0.25
    audio_player.stream = stream
    add_child(audio_player)
    audio_player.play()

func _play_note(pad: int) -> void:
    var playback = audio_player.get_stream_playback()
    if not (playback is AudioStreamGeneratorPlayback):
        return
    var freq: float = [261.63,329.63,392.00,523.25][pad]
    var frames := mini(playback.get_frames_available(),2000)
    for i in range(frames):
        var env := 1.0-float(i)/2000.0
        var sample := sin(float(i)*TAU*float(freq)/22050.0)*0.16*env
        playback.push_frame(Vector2(sample,sample))

func _open_studio() -> void:
    music_index = 0
    _make_overlay()
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation",20)
    panel.add_child(v)
    var title := _ui_label("LA CALDERA RECORDS  /  MAKE A BEAT", 31,Color("ffffff"))
    v.add_child(title)
    v.add_child(_ui_label("Play the eight-pad pattern shown below to publish your track.",18,Color("c0d6ea")))
    v.add_child(_ui_label("PATTERN:  1  -  3  -  2  -  4  -  2  -  1  -  4  -  3",22,COLORS.cyan))
    music_message = _ui_label("READY • 0 / 8",21,Color("ffdce8"))
    v.add_child(music_message)
    var pads := HBoxContainer.new()
    pads.add_theme_constant_override("separation",12)
    v.add_child(pads)
    var palette := [COLORS.cyan,COLORS.neon,Color("f7bb67"),Color("7d98fc")]
    for i in range(4):
        var n := i
        var btn := _styled_button(str(i+1),palette[i])
        btn.custom_minimum_size = Vector2(96,95)
        btn.pressed.connect(func(): _beat_pressed(n))
        pads.add_child(btn)
    var close := _styled_button("Leave studio",Color("475c78"))
    close.pressed.connect(_hide_panel)
    v.add_child(close)

func _beat_pressed(pad: int) -> void:
    _play_note(pad)
    if BEAT[music_index] != pad:
        music_index = 0
        music_message.text = "Wrong pad — retry the pattern! 0 / 8"
        return
    music_index += 1
    music_message.text = "NICE! %d / 8" % music_index
    if music_index >= BEAT.size():
        var result := game.publish_track(BEAT)
        music_message.text = "TRACK RELEASED!  +%d FANS  +%d COINS" % [result["fans"],result["coins"]]
        music_index = 0
        _message("Your track is now playing in City Zero!",5.0)
        _update_hud()

func _make_overlay() -> void:
    if overlay != null:
        overlay.queue_free()
    overlay = Control.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    ui_root.add_child(overlay)
    var shade := ColorRect.new()
    shade.color = Color(0.025,0.035,0.080,0.85)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(shade)
    panel = PanelContainer.new()
    panel.add_theme_stylebox_override("panel",_panel_style(Color("171e37"),Color("5e9dc2")))
    panel.anchor_left = 0.5
    panel.anchor_right = 0.5
    panel.anchor_top = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = -325
    panel.offset_right = 325
    panel.offset_top = -235
    panel.offset_bottom = 235
    panel.add_theme_constant_override("margin_left",20)
    overlay.add_child(panel)
    overlay.visible = true

func _hide_panel() -> void:
    if overlay != null:
        overlay.queue_free()
        overlay = null

func _panel_style(bg: Color, outline: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = outline
    style.set_border_width_all(2)
    style.set_corner_radius_all(17)
    style.content_margin_left = 14
    style.content_margin_right = 14
    style.content_margin_top = 10
    style.content_margin_bottom = 10
    return style

func _ui_label(value: String, fs: int, c: Color) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size",fs)
    label.add_theme_color_override("font_color",c)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return label

func _styled_button(value: String, c: Color) -> Button:
    var button := Button.new()
    button.text = value
    button.add_theme_font_size_override("font_size",21)
    button.add_theme_color_override("font_color",Color.WHITE)
    button.add_theme_stylebox_override("normal",_panel_style(c.darkened(0.48),c))
    button.add_theme_stylebox_override("hover",_panel_style(c.darkened(0.26),c.lightened(0.3)))
    button.add_theme_stylebox_override("pressed",_panel_style(c.darkened(0.15),c))
    return button

func _create_mobile_ui() -> void:
    var canvas := CanvasLayer.new()
    canvas.layer = 3
    add_child(canvas)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(root)
    ui_root = root
    mobile = MobileInput.new()
    root.add_child(mobile)
    var titlepanel := PanelContainer.new()
    titlepanel.add_theme_stylebox_override("panel",_panel_style(Color("12172bdc"),COLORS.cyan))
    titlepanel.offset_left = 16
    titlepanel.offset_top = 14
    titlepanel.offset_right = 348
    titlepanel.offset_bottom = 105
    root.add_child(titlepanel)
    var meta := VBoxContainer.new()
    meta.add_theme_constant_override("separation",1)
    titlepanel.add_child(meta)
    var title := _ui_label("◉ FOREVER FREQUENCY",17,Color("e5f8ff"))
    meta.add_child(title)
    meta.add_child(_ui_label("LA CALDERA  ·  CITY ZERO",13,Color("8bdbe0")))
    world_time_label = _ui_label("",11,Color("f5d8af"))
    world_time_label.autowrap_mode = TextServer.AUTOWRAP_OFF
    meta.add_child(world_time_label)
    var stats := PanelContainer.new()
    stats.add_theme_stylebox_override("panel",_panel_style(Color("12172bdb"),Color("5d789f")))
    stats.anchor_left = 1
    stats.anchor_right = 1
    stats.offset_left = -385
    stats.offset_right = -14
    stats.offset_top = 14
    stats.offset_bottom = 65
    root.add_child(stats)
    currency = _ui_label("",17,Color("f6efda"))
    stats.add_child(currency)
    var missionpanel := PanelContainer.new()
    missionpanel.add_theme_stylebox_override("panel",_panel_style(Color("111728d8"),Color("7b5aa3")))
    missionpanel.anchor_left = 1
    missionpanel.anchor_right = 1
    missionpanel.offset_left = -270
    missionpanel.offset_right = -14
    missionpanel.offset_top = 88
    missionpanel.offset_bottom = 184
    root.add_child(missionpanel)
    mission = _ui_label("",13,Color("e5d9ff"))
    missionpanel.add_child(mission)
    var hintpanel := PanelContainer.new()
    hintpanel.add_theme_stylebox_override("panel",_panel_style(Color("12172bdc"),COLORS.cyan))
    hintpanel.anchor_top = 1
    hintpanel.anchor_bottom = 1
    hintpanel.anchor_left = 0.5
    hintpanel.anchor_right = 0.5
    hintpanel.offset_left = -285
    hintpanel.offset_right = 285
    hintpanel.offset_top = -80
    hintpanel.offset_bottom = -29
    root.add_child(hintpanel)
    hint = _ui_label("",16,Color("e5f8ff"))
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hintpanel.add_child(hint)
    var action := _styled_button("INTERACT   ✦",COLORS.neon)
    action.anchor_left = 1
    action.anchor_right = 1
    action.anchor_top = 1
    action.anchor_bottom = 1
    action.offset_left = -184
    action.offset_right = -18
    action.offset_top = -89
    action.offset_bottom = -26
    action.pressed.connect(_interact)
    root.add_child(action)
    var door_button := _styled_button("LAMBORGHINI  •  DOORS", COLORS.cyan)
    door_button.anchor_left = 1
    door_button.anchor_right = 1
    door_button.anchor_top = 1
    door_button.anchor_bottom = 1
    door_button.offset_left = -230
    door_button.offset_right = -18
    door_button.offset_top = -162
    door_button.offset_bottom = -99
    door_button.pressed.connect(toggle_lamborghini_orange_doors)
    root.add_child(door_button)
    door_button.visible = lamborghini_orange_car != null
    var label := _ui_label("WASD · move    Drag · look    E · enter    O · Lamborghini doors",12,Color("ddeeff"))
    label.anchor_top = 1
    label.anchor_bottom = 1
    label.offset_left = 22
    label.offset_right = 510
    label.offset_top = -38
    label.offset_bottom = -11
    root.add_child(label)

func _update_hud() -> void:
    if currency == null:
        return
    currency.text = "◉ %d COINS    ♫ %d FANS    ★ LV %d" % [game.coins,game.fans,game.level]
    world_time_label.text = "CITY TIME  %02d:%02d  ·  NOVA  /  %s" % [int(town_clock),int((town_clock-int(town_clock))*60),game.companion]
    mission.text = "✦ YOUR FIRST RELEASE\nEnter La Caldera Records\nPublish a song · earn fans"
    var place := _nearest_place()
    if Time.get_ticks_msec()/1000.0 < status_until:
        return
    hint.text = "E  •  %s" % place.to_upper() if place != "" else "EXPLORE CITY ZERO  •  WALK INTO A BUILDING'S AREA"

func _message(s: String, duration: float = 3.0) -> void:
    if hint != null:
        hint.text = s
    status_until = Time.get_ticks_msec()/1000.0 + duration
