extends SceneTree
## Import/render probe of one real authored, CC0 car model.
## Copyright/data provenance: https://github.com/JaronKBragg7337/spectral-gt-rs
const GLB_PATH := "res://city_zero/assets/reference_cc0/spectral_gt_rs_game_ready.glb"

func _initialize() -> void:
    call_deferred("_run")

func _collect(node: Node, counts: Dictionary) -> void:
    if node is MeshInstance3D:
        counts["meshes"] += 1
    elif node is AnimationPlayer:
        counts["animation_players"] += 1
        counts["animations"].append_array((node as AnimationPlayer).get_animation_list())
    for child in node.get_children():
        _collect(child, counts)

func _run() -> void:
    var model_scene := load(GLB_PATH) as PackedScene
    if model_scene == null:
        push_error("CC0 model not imported: " + GLB_PATH)
        quit(1)
        return
    var instance := model_scene.instantiate() as Node3D
    if instance == null:
        push_error("Real GLB root is not 3D")
        quit(1)
        return
    var counts := {"meshes": 0, "animation_players": 0, "animations": []}
    _collect(instance, counts)
    if counts["meshes"] < 50:
        push_error("Incomplete GLB: not enough independent mesh nodes: " + str(counts))
        instance.free()
        quit(1)
        return

    var viewport := SubViewport.new()
    viewport.size = Vector2i(1280, 720)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport.transparent_bg = false
    get_root().add_child(viewport)
    viewport.add_child(instance)

    var floor := MeshInstance3D.new()
    floor.name = "PhotoStudioFloor"
    var plane := PlaneMesh.new()
    plane.size = Vector2(20.0, 20.0)
    floor.mesh = plane
    floor.position.y = -0.02
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.13, 0.15, 0.19)
    mat.roughness = 0.78
    floor.material_override = mat
    viewport.add_child(floor)

    var sky := WorldEnvironment.new()
    sky.environment = Environment.new()
    sky.environment.background_mode = Environment.BG_COLOR
    sky.environment.background_color = Color(0.18, 0.20, 0.26)
    sky.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    sky.environment.ambient_light_color = Color(0.78, 0.80, 0.88)
    sky.environment.ambient_light_energy = 0.85
    viewport.add_child(sky)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-45.0, 35.0, -10.0)
    light.light_energy = 2.0
    light.shadow_enabled = true
    viewport.add_child(light)

    var camera := Camera3D.new()
    camera.position = Vector3(7.0, 3.2, 6.5)
    camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
    camera.fov = 49.0
    viewport.add_child(camera)
    camera.current = true

    for i in range(15):
        await process_frame
    await RenderingServer.frame_post_draw

    var image := viewport.get_texture().get_image()
    if image == null or image.is_empty():
        push_error("Renderer returned no image")
        quit(1)
        return
    var file := OS.get_environment("CITYZERO_SCREENSHOT")
    if file.is_empty():
        file = "user://cityzero-real-vehicle-probe.png"
    else:
        DirAccess.make_dir_recursive_absolute(file.get_base_dir())
    var err := image.save_png(file)
    if err != OK:
        push_error("Failed to write vehicle image: " + str(err))
        quit(1)
        return
    var unique: Dictionary = {}
    for y in range(0, image.get_height(), 40):
        for x in range(0, image.get_width(), 40):
            var color := image.get_pixel(x, y)
            unique[color.to_html()] = true
    print("CITYZERO_REAL_CAR_PROBE:", JSON.stringify({
        "meshes": counts["meshes"], "animation_players": counts["animation_players"],
        "animations": counts["animations"], "pixel_colors": unique.size(), "screenshot": file
    }))
    if unique.size() < 5:
        push_error("Screenshot looks blank or no actual car render")
        quit(1)
        return
    quit(0)
