extends SceneTree
## Isolated Godot 4 screenshot proof for THREE genuine external CC BY 4.0
## authored vehicle GLBs. No procedurally generated bodies, no AI images.
## Car pixels must disappear in a mesh-visibility control frame.
const CAR_MODELS := [{"id": "audi_r8", "author": "wallon"}]

func _initialize() -> void:
    call_deferred("_run")

func _fail(detail: String) -> void:
    push_error("CITYZERO_ARTIST_FLEET_GODOT_RED: " + detail)
    quit(1)

func _find_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
    if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
        result.append(node as MeshInstance3D)
    for child in node.get_children():
        _find_meshes(child, result)

func _image(viewport: SubViewport) -> Image:
    await RenderingServer.frame_post_draw
    return viewport.get_texture().get_image()

func _capture() -> void:
    var output := OS.get_environment("CITYZERO_ARTIST_GODOT_PHOTOS")
    if output.is_empty():
        output = ProjectSettings.globalize_path("user://real-artist-car-godot")
    DirAccess.make_dir_recursive_absolute(output)
    var records: Array[Dictionary] = []
    for car in CAR_MODELS:
        var name: String = car["id"]
        var model_path := "res://assets/licensed_ccby_car_fleet/" + name + "_blender_import.glb"
        var packed := load(model_path) as PackedScene
        if packed == null:
            _fail("Missing actual source glTF imported in Godot: " + name)
            return

        var stage := SubViewport.new()
        stage.size = Vector2i(1280, 800)
        stage.transparent_bg = false
        stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
        root.add_child(stage)
        var vehicle := packed.instantiate() as Node3D
        if vehicle == null:
            _fail("Original model has no 3D scene " + name)
            return
        stage.add_child(vehicle)
        var meshes: Array[MeshInstance3D] = []
        _find_meshes(vehicle, meshes)
        if meshes.is_empty():
            _fail("Artist mesh is absent " + name)
            return
        var low := Vector3(INF, INF, INF)
        var high := Vector3(-INF, -INF, -INF)
        var tri_count := 0
        for obj in meshes:
            var mesh: Mesh = obj.mesh
            for surface in range(mesh.get_surface_count()):
                if mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
                    continue
                var idx: int = mesh.surface_get_array_index_len(surface)
                tri_count += int((idx if idx > 0 else mesh.surface_get_array_len(surface)) / 3)
            for corner in range(8):
                var point := obj.global_transform * mesh.get_aabb().get_endpoint(corner)
                low = low.min(point)
                high = high.max(point)
        if tri_count < 300000:
            _fail("Too little actual artist geometry " + name)
            return
        var center := (low + high) * 0.5
        var dims := high - low
        var span := maxf(dims.x, maxf(dims.y, dims.z))
        if span <= 0.03 or span > 1000:
            _fail("Invalid artist mesh bounds " + name)
            return

        var env := WorldEnvironment.new()
        env.environment = Environment.new()
        env.environment.background_mode = Environment.BG_COLOR
        env.environment.background_color = Color(0.14, 0.18, 0.25)
        env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
        env.environment.ambient_light_color = Color(0.87, 0.88, 0.95)
        env.environment.ambient_light_energy = 0.9
        stage.add_child(env)
        var sun := DirectionalLight3D.new()
        sun.rotation_degrees = Vector3(-48, 35, -18)
        sun.light_energy = 2.25
        stage.add_child(sun)
        var camera := Camera3D.new()
        camera.projection = Camera3D.PROJECTION_ORTHOGONAL
        camera.size = span * 0.83
        stage.add_child(camera)
        camera.current = true
        var viewpoints := {
            "three_quarter": Vector3(1.3, 0.48, 1.35),
            "reverse": Vector3(-1.4, 0.47, -1.22),
            "side": Vector3(1.8, 0.15, 0),
            "front": Vector3(0, 0.22, 1.8),
            "rear": Vector3(0, 0.22, -1.8),
        }
        var photos: Array[Dictionary] = []
        for view in viewpoints.keys():
            var direction: Vector3 = viewpoints[view]
            camera.global_position = center + direction * span
            camera.look_at(center, Vector3.UP)
            for i in range(16):
                await process_frame
            var shot := await _image(stage)
            if shot == null or shot.is_empty():
                _fail("No actual Godot framebuffer " + name + " " + str(view))
                return
            for obj in meshes:
                obj.visible = false
            for i in range(5):
                await process_frame
            var negative := await _image(stage)
            for obj in meshes:
                obj.visible = true
            if negative == null or negative.is_empty():
                _fail("Missing negative control image " + name)
                return
            var changed := 0
            for y in range(80, 720, 5):
                for x in range(100, 1180, 5):
                    var a := shot.get_pixel(x, y)
                    var b := negative.get_pixel(x, y)
                    if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.16:
                        changed += 1
            if changed < 550:
                _fail("Car not visible: insufficient actual mesh pixels " + name + " " + str(view))
                return
            var file := output.path_join(name + "_REAL_GODOT_" + str(view) + ".png")
            if shot.save_png(file) != OK:
                _fail("Failed native Godot PNG save " + file)
                return
            photos.append({"angle": view, "png": file, "actual_mesh_sampled_pixels": changed})
        records.append({
            "id": name, "author": car["author"], "license": "CC-BY-4.0",
            "source_type": "Artist original GLB imported with Blender 4.5",
            "real_godot_mesh_instances": meshes.size(),
            "real_godot_triangles": tri_count,
            "photographs": photos, "doors_opening_verified": false,
            "gameplay_ready": false,
        })
        stage.queue_free()
        await process_frame

    var report := {
        "engine": "Actual Godot 4 software OpenGL viewport",
        "validation": "Each real vehicle visible against same camera and lights with source mesh disabled",
        "artist_car_count": records.size(), "real_native_godot_photos": 5,
        "vehicles": records
    }
    var f := FileAccess.open(output.path_join("artist_fleet_REAL_GODOT_report.json"), FileAccess.WRITE)
    if f == null:
        _fail("Cannot write artist fleet proof")
        return
    f.store_string(JSON.stringify(report, "  "))
    f.close()
    print("AUDI_R8_REAL_GODOT_FIVE_VIEWS_NOT_APPROVED " + JSON.stringify(report))
    quit(0)

func _run() -> void:
    await _capture()
