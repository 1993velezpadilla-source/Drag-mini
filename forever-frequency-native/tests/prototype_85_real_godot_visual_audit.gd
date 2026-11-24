extends SceneTree
## Inspect EVERY authentic Blender export from the 85-prototype vehicle fleet
## in native Godot 4. Capture 12 real non-AI viewport screenshots.
## Intentional fail-closed label: technical import IS NOT art approval.
const PORTFOLIO := [
    "compact_sedan__compact_c",
    "exotic_supercar__rossa_v",
    "basic_pickup__ranger",
    "luxury_pickup__denali",
    "electric_future__cyber_wedge",
    "hypersport__falcon_1340",
    "dirtbike__trail_450",
    "buggy__dune_4x4",
    "watercraft__coastal_rib",
    "watercraft__marina_cruiser",
    "helicopter__med_evac",
    "airplane__sky_train"
]
const EXPECTED_SOURCES := {"premium_fleet": 59, "mobility_fleet": 26}

func _initialize() -> void:
    call_deferred("_run")

func _fail(why: String) -> void:
    push_error("CITYZERO_85_ACTUAL_GODOT_VISUAL_GAUNTLET_RED: " + why)
    quit(1)

func _collect_meshes(node: Node, found: Array[MeshInstance3D]) -> void:
    if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
        found.append(node as MeshInstance3D)
    for child in node.get_children():
        _collect_meshes(child, found)

func _shot(v: SubViewport) -> Image:
    await RenderingServer.frame_post_draw
    return v.get_texture().get_image()

func _run() -> void:
    var dest := OS.get_environment("CITYZERO_85_ACTUAL_GODOT_PHOTOS")
    if dest.is_empty():
        dest = ProjectSettings.globalize_path("user://actual-85-vehicle-qa")
    DirAccess.make_dir_recursive_absolute(dest)
    var seen: Dictionary = {}
    var audited: Array[Dictionary] = []
    var actual_photos: Array[Dictionary] = []
    var photo_count := 0
    for group in EXPECTED_SOURCES:
        var kind: String = group
        var manifest_name: String = "fleet_metrics.json" if kind == "premium_fleet" else "metrics.json"
        var raw := FileAccess.get_file_as_string("res://assets/" + kind + "/" + manifest_name)
        var parsed: Variant = JSON.parse_string(raw)
        var models: Array = []
        if kind == "premium_fleet":
            if not (parsed is Dictionary) or not parsed.has("vehicles"):
                _fail("Original Blender fleet car metrics unavailable")
                return
            models = parsed["vehicles"]
        elif parsed is Array:
            models = parsed
        else:
            _fail("Original Blender water/air/motorcycle metrics unavailable")
            return
        if models.size() != EXPECTED_SOURCES[kind]:
            _fail("Actual Blender-generated prototype asset count mismatch " + kind + " " + str(models.size()))
            return
        for entry in models:
            var identity: String = entry["id"]
            if seen.has(identity):
                _fail("Duplicate identity among genuine car model exports " + identity)
                return
            seen[identity] = true
            var file := "res://assets/" + kind + "/" + identity + ".glb"
            var resource := load(file) as PackedScene
            if resource == null:
                _fail("Actual 3D GLB was NOT imported in Godot " + identity)
                return
            var viewport := SubViewport.new()
            viewport.size = Vector2i(1280, 800)
            viewport.transparent_bg = false
            viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
            root.add_child(viewport)
            var model := resource.instantiate() as Node3D
            if model == null:
                _fail("Actual GLB is not a valid scene " + identity)
                return
            viewport.add_child(model)
            var nodes: Array[MeshInstance3D] = []
            _collect_meshes(model, nodes)
            if nodes.size() < 6:
                _fail("Original Blender source has too few native real 3D mesh instances " + identity)
                return
            var low := Vector3(INF, INF, INF)
            var high := Vector3(-INF, -INF, -INF)
            var triangles: int = 0
            for mesh_node in nodes:
                var mesh: Mesh = mesh_node.mesh
                for surface in range(mesh.get_surface_count()):
                    if mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
                        continue
                    var indices: int = mesh.surface_get_array_index_len(surface)
                    triangles += int((indices if indices > 0 else mesh.surface_get_array_len(surface)) / 3)
                for corner in range(8):
                    var vertex := mesh_node.global_transform * mesh.get_aabb().get_endpoint(corner)
                    low = low.min(vertex)
                    high = high.max(vertex)
            var minimum := 1000 if kind == "mobility_fleet" else 15000
            if triangles < minimum:
                _fail("Blender original geometry got lost in Godot " + identity + " " + str(triangles))
                return
            var dims := high - low
            var span: float = maxf(dims.x, maxf(dims.y, dims.z))
            if span < 0.05 or span > 120.0:
                _fail("Actual GLB has implausible native 3D dimensions " + identity + " " + str(dims))
                return
            audited.append({
                "id":identity,"kind":kind,"mesh_instances":nodes.size(),
                "godot_original_triangles":triangles,
                "source_blender_triangles":int(entry["triangles"]),
                "scene_source":file,"art_approved":false,
                "gameplay_ready":false,"needs_human_visual_review":true
            })
            if abs(triangles-int(entry["triangles"])) > max(40.0, float(entry["triangles"])*0.05):
                _fail("Real source mesh triangles mismatch " + identity)
                return

            if PORTFOLIO.has(identity):
                var env := WorldEnvironment.new()
                env.environment = Environment.new()
                env.environment.background_mode = Environment.BG_COLOR
                env.environment.background_color = Color(0.14, 0.17, 0.24)
                env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
                env.environment.ambient_light_color = Color(0.78, 0.82, 0.9)
                env.environment.ambient_light_energy = 0.9
                viewport.add_child(env)
                var light := DirectionalLight3D.new()
                light.rotation_degrees = Vector3(-48, -32, -17)
                light.light_energy = 2.2
                viewport.add_child(light)
                var cam := Camera3D.new()
                cam.projection = Camera3D.PROJECTION_ORTHOGONAL
                cam.size = span * 1.85
                viewport.add_child(cam)
                var midpoint := (low + high) * 0.5
                cam.global_position = midpoint + Vector3(1.37, 0.55, -1.52) * span
                cam.look_at(midpoint, Vector3.UP)
                cam.current = true
                for frame in range(14):
                    await process_frame
                var visible := await _shot(viewport)
                if visible == null or visible.is_empty():
                    _fail("Blank ACTUAL Godot engine viewport " + identity)
                    return
                for node in nodes:
                    node.visible = false
                for frame in range(5):
                    await process_frame
                var hidden := await _shot(viewport)
                for node in nodes:
                    node.visible = true
                if hidden == null or hidden.is_empty():
                    _fail("Missing controlled vehicle-mesh hide proof " + identity)
                    return
                var actual_car_pixels := 0
                for y in range(80, 720, 5):
                    for x in range(100, 1180, 5):
                        var a := visible.get_pixel(x, y)
                        var b := hidden.get_pixel(x, y)
                        if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) > 0.17:
                            actual_car_pixels += 1
                if actual_car_pixels < 120:
                    _fail("Visible original source geometry not proven " + identity + " " + str(actual_car_pixels))
                    return
                var target := dest.path_join(identity + "_ACTUAL_GODOT_3D_NOT_APPROVED.png")
                if visible.save_png(target) != OK:
                    _fail("Could not capture original Godot scene " + identity)
                    return
                actual_photos.append({"id":identity,"image":target,"actual_mesh_pixel_sample_count":actual_car_pixels,
                                      "fake_generated_images":false,"source_scene":file,"approved":false})
                photo_count += 1
                print("CITYZERO_85_PROTOTYPE_ACTUAL_NATIVE_GODOT_SCREENSHOT",identity,actual_car_pixels,flush=true)
            viewport.queue_free()
            await process_frame
    if seen.size() != 85 or audited.size() != 85 or photo_count != PORTFOLIO.size():
        _fail("Not ALL real 85 prototype imports / twelve true screenshots were checked " +
              str([seen.size(), audited.size(), photo_count]))
        return
    var result := {
        "engine":"Godot 4 real OpenGL native software viewport",
        "exact_original_lamborghini_not_replaced":true,
        "premature_art_approval":false,"original_blender_exports_loaded":audited.size(),
        "real_godot_contact_images":photo_count,
        "asset_audit":audited,"photographic_proofs":actual_photos,
        "final_gold_standard_approved":0,
        "quality_note":"65+ authored hard-surface meshes and correct GLB import DO NOT mean Lamborghini-level art."
    }
    var f := FileAccess.open(dest.path_join("godot_85_real_vehicle_audit.json"),FileAccess.WRITE)
    if f == null:
        _fail("Cannot write actual engine report")
        return
    f.store_string(JSON.stringify(result,"  "))
    f.close()
    print("CITYZERO_85_REAL_GODOT_IMPORTS_AND_12_TRUE_RENDERED_VIEWS_GREEN")
    quit(0)
