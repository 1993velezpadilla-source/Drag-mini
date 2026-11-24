extends SceneTree
## REAL CC0 Dodge Challenger 1970 — Godot viewport proof, not AI artwork.
## Authored source FBX -> Blender GLB -> Godot 4 imported PackedScene.
## Captures 3 actual 3D engine frames and proves model pixels disappear
## when the authentic imported mesh instances are hidden.
const GLB_PATH := "res://assets/licensed_cc0_automobiles/dodge_challenger_1970_rt_original_cc0.glb"

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("CITYZERO_REAL_CHALLENGER_GODOT_RED: " + reason)
    quit(1)

func _meshes(node: Node, result: Array[MeshInstance3D]) -> void:
    if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
        result.append(node as MeshInstance3D)
    for child in node.get_children():
        _meshes(child, result)

func _take(viewport: SubViewport) -> Image:
    await RenderingServer.frame_post_draw
    return viewport.get_texture().get_image()

func _run() -> void:
    var output := OS.get_environment("CITYZERO_CHALLENGER_SCREENSHOTS")
    if output.is_empty():
        output = ProjectSettings.globalize_path("user://challenger-true-godot-frames")
    DirAccess.make_dir_recursive_absolute(output)

    var packed := load(GLB_PATH) as PackedScene
    if packed == null:
        _fail("Real Blender exported GLB not importable: " + GLB_PATH)
        return

    var studio := SubViewport.new()
    studio.size = Vector2i(1280, 800)
    studio.transparent_bg = false
    studio.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(studio)

    var vehicle := packed.instantiate() as Node3D
    if vehicle == null:
        _fail("Original imported GLB is not a 3D scene")
        return
    studio.add_child(vehicle)
    var mesh_instances: Array[MeshInstance3D] = []
    _meshes(vehicle, mesh_instances)
    if mesh_instances.is_empty():
        _fail("Original Dodge mesh data is missing")
        return

    var low := Vector3(INF, INF, INF)
    var high := Vector3(-INF, -INF, -INF)
    var triangles := 0
    for mesh_node in mesh_instances:
        var mesh := mesh_node.mesh
        for surface in range(mesh.get_surface_count()):
            if mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
                continue
            var indices := mesh.surface_get_array_index_len(surface)
            var vertices := mesh.surface_get_array_len(surface)
            triangles += int((indices if indices > 0 else vertices) / 3)
        for corner in range(8):
            var point := mesh_node.global_transform * mesh.get_aabb().get_endpoint(corner)
            low = low.min(point)
            high = high.max(point)
    if triangles < 25000:
        _fail("Not enough genuine imported source triangles: " + str(triangles))
        return
    var center := (low + high) * 0.5
    var dimensions := high - low
    var span := maxf(dimensions.x, maxf(dimensions.y, dimensions.z))
    if span <= 0.05 or span > 1000.0:
        _fail("Invalid imported source bounding dimensions: " + str(dimensions))
        return

    var world := WorldEnvironment.new()
    world.environment = Environment.new()
    world.environment.background_mode = Environment.BG_COLOR
    world.environment.background_color = Color(0.14, 0.17, 0.22)
    world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world.environment.ambient_light_color = Color(0.78, 0.82, 0.90)
    world.environment.ambient_light_energy = 0.8
    studio.add_child(world)

    var floor := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(span * 10.0, span * 10.0)
    floor.mesh = plane
    floor.position = Vector3(center.x, low.y - span * 0.016, center.z)
    var floor_material := StandardMaterial3D.new()
    floor_material.albedo_color = Color(0.16, 0.19, 0.24)
    floor_material.roughness = 0.75
    floor.material_override = floor_material
    studio.add_child(floor)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, 32, -18)
    sun.light_energy = 2.1
    studio.add_child(sun)

    var cam := Camera3D.new()
    cam.projection = Camera3D.PROJECTION_ORTHOGONAL
    cam.size = span * 1.8
    studio.add_child(cam)
    cam.current = true

    var shots := {
        "three_quarter": Vector3(1.45, 0.52, 1.25),
        "opposite_three_quarter": Vector3(-1.45, 0.52, -1.25),
        "side": Vector3(1.8, 0.25, 0.08),
    }
    var report_shots: Array[Dictionary] = []
    for shot in shots.keys():
        var direction: Vector3 = shots[shot]
        cam.global_position = center + direction * span
        cam.look_at(center, Vector3.UP)
        for frame in range(14):
            await process_frame
        var photo := await _take(studio)
        if photo == null or photo.is_empty():
            _fail("Godot rendered empty actual frame " + str(shot))
            return

        # Compare with precisely the SAME scene, camera and lighting, but
        # authentic source car temporarily hidden: proves car pixels are real.
        for mesh_node in mesh_instances:
            mesh_node.visible = false
        for frame in range(5):
            await process_frame
        var without_car := await _take(studio)
        for mesh_node in mesh_instances:
            mesh_node.visible = true
        if without_car == null or without_car.is_empty():
            _fail("Could not perform car-visibility difference test")
            return
        var changed := 0
        for y in range(90, 710, 5):
            for x in range(100, 1180, 5):
                var a := photo.get_pixel(x, y)
                var b := without_car.get_pixel(x, y)
                if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.16:
                    changed += 1
        if changed < 175:
            _fail("Car did not visibly render in native Godot " + str(shot) + ": " + str(changed))
            return
        var target := output.path_join("DODGE_1970_REAL_GODOT_" + str(shot) + ".png")
        if photo.save_png(target) != OK:
            _fail("Could not save authentic Godot PNG: " + target)
            return
        report_shots.append({"angle": shot, "image": target, "actual_mesh_pixel_samples": changed})

    var report := {
        "source": "Original 1970 Challenger CC0 FBX from O3DE, converted with Blender 4.5",
        "validation": "Real Godot 4 viewport frames; visible car pixels confirmed by hide-mesh control",
        "genuine_rendered_meshes": mesh_instances.size(),
        "genuine_rendered_triangles": triangles,
        "imported_dimensions": [dimensions.x, dimensions.y, dimensions.z],
        "game_ready": false,
        "door_animation_verified": false,
        "shots": report_shots
    }
    var meta := FileAccess.open(output.path_join("real_challenger_godot_proof.json"), FileAccess.WRITE)
    if meta == null:
        _fail("Cannot save actual Godot proof report")
        return
    meta.store_string(JSON.stringify(report, "  "))
    meta.close()
    print("CITYZERO_REAL_CHALLENGER_3_GODOT_FRAMES_GREEN " + JSON.stringify(report))
    quit(0)
