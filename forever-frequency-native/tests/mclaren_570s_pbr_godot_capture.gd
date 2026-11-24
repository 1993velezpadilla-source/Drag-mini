extends SceneTree
## Five genuine Godot 4 views of the unmodified artist McLaren 570S bodywork
## with specialist PBR paint/glass. No model is fabricated by this script.
## Mechanical doors/bonnet are NOT claimed where original geometry is fused.
const SCENE_PATH := "res://assets/mclaren_570s_review/mclaren_570s_2016_ORIGINAL_Author_DeepBlue_PBR.glb"
const VIEWS := {
    "01_front_three_quarter": Vector3(1.03, 0.52, 1.4),
    "02_true_side": Vector3(1.8, 0.18, 0),
    "03_true_front": Vector3(0, 0.19, 1.8),
    "04_true_rear": Vector3(0, 0.20, -1.8),
    "05_rear_three_quarter": Vector3(1.03, 0.53, -1.4)
}
const RESOLUTION := Vector2i(1600, 1000)

func _initialize() -> void:
    call_deferred("_run")

func _red(text: String) -> void:
    push_error("MCLAREN_570S_REAL_GODOT_PBR_RED: " + text)
    quit(1)

func _all_meshes(parent: Node, out: Array[MeshInstance3D]) -> void:
    if parent is MeshInstance3D and (parent as MeshInstance3D).mesh != null:
        out.append(parent as MeshInstance3D)
    for child in parent.get_children():
        _all_meshes(child, out)

func _photo(vp: SubViewport) -> Image:
    await RenderingServer.frame_post_draw
    return vp.get_texture().get_image()

func _run() -> void:
    var target_folder := OS.get_environment("CITY_ZERO_FERRARI_GODOT_SHOTS")
    if target_folder.is_empty():
        target_folder = ProjectSettings.globalize_path("user://original-mclaren-570s-pbr")
    DirAccess.make_dir_recursive_absolute(target_folder)

    var scene_resource := load(SCENE_PATH) as PackedScene
    if scene_resource == null:
        _red("Original artist model did not import as actual 3D GLB scene")
        return
    var stage := SubViewport.new()
    stage.name = "REAL_MCLAREN_570S_ARTIST_SOURCE_GODOT_VIEWPORT"
    stage.size = RESOLUTION
    stage.transparent_bg = false
    stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(stage)
    var model := scene_resource.instantiate() as Node3D
    if model == null:
        _red("Real source GLB lacked valid scene root")
        return
    stage.add_child(model)

    var all: Array[MeshInstance3D] = []
    _all_meshes(model, all)
    if all.size() < 78:
        _red("Artist mesh hierarchy lost; too few genuine mesh objects " + str(all.size()))
        return

    var low := Vector3(INF, INF, INF)
    var high := Vector3(-INF, -INF, -INF)
    var endpoints: Array[Vector3] = []
    var tris := 0
    var surfaces := 0
    var materials := 0
    for m in all:
        var original: Mesh = m.mesh
        for surf in range(original.get_surface_count()):
            var mode: int = original.surface_get_primitive_type(surf)
            if mode != Mesh.PRIMITIVE_TRIANGLES:
                continue
            surfaces += 1
            var indices: int = original.surface_get_array_index_len(surf)
            tris += int((indices if indices > 0 else original.surface_get_array_len(surf)) / 3)
            if original.surface_get_material(surf) != null:
                materials += 1
        for corner in range(8):
            var pt: Vector3 = m.global_transform * original.get_aabb().get_endpoint(corner)
            low = low.min(pt)
            high = high.max(pt)
            endpoints.append(pt)
    if tris < 57000 or materials < 25:
        _red("Premium source true triangle/material count lost: " + str([tris, materials]))
        return
    var dimension := high-low
    var longest := maxf(dimension.x, maxf(dimension.y, dimension.z))
    if longest < 4.48 or longest > 4.58:
        _red("Artist McLaren 570S model does not have correct original 4.530m dimensions: " + str(dimension))
        return
    var mid := (high+low)*0.5

    var world := WorldEnvironment.new()
    world.environment = Environment.new()
    world.environment.background_mode = Environment.BG_COLOR
    world.environment.background_color = Color(0.42, 0.49, 0.59)
    world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world.environment.ambient_light_color = Color(0.85, 0.88, 1.0)
    world.environment.ambient_light_energy = 1.05
    stage.add_child(world)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-46.0,-27.0,-9.0)
    light.light_energy = 2.3
    stage.add_child(light)
    var rim := DirectionalLight3D.new()
    rim.rotation_degrees = Vector3(-33.0,158.0,0.0)
    rim.light_energy = 0.9
    stage.add_child(rim)

    var camera := Camera3D.new()
    camera.name = "HONEST_FULL_FRAME_REAL_GODOT_CAMERA"
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = longest * 1.55
    stage.add_child(camera)
    camera.current = true
    var results: Array[Dictionary] = []
    for title in VIEWS:
        var offset: Vector3 = VIEWS[title]
        camera.global_position = mid + offset * longest
        camera.look_at(mid, Vector3.UP)
        camera.size = longest * 1.55
        for frame in range(6):
            await process_frame
        var pmin := Vector2(INF,INF)
        var pmax := Vector2(-INF,-INF)
        for pos in endpoints:
            var projected: Vector2 = camera.unproject_position(pos)
            pmin = pmin.min(projected)
            pmax = pmax.max(projected)
        var ratio := (pmax-pmin)/Vector2(RESOLUTION)
        var magnification := maxf(ratio.x/.77,ratio.y/.76)
        if magnification < 0.03 or magnification > 3.5:
            _red("Could not physically frame original mesh: " + title)
            return
        camera.size *= magnification
        for frame in range(8):
            await process_frame
        pmin = Vector2(INF,INF)
        pmax = Vector2(-INF,-INF)
        for pos in endpoints:
            var point: Vector2 = camera.unproject_position(pos)
            pmin = pmin.min(point)
            pmax = pmax.max(point)
        ratio = (pmax-pmin)/Vector2(RESOLUTION)
        if ratio.x < .50 or maxf(ratio.x, ratio.y) < .72:
            _red("Tiny far-away McLaren render REJECTED " + title + " " + str(ratio))
            return
        if pmin.x < 0 or pmin.y < 0 or pmax.x > RESOLUTION.x or pmax.y > RESOLUTION.y:
            _red("Actual original body is cropped by camera in " + title)
            return
        var picture := await _photo(stage)
        if picture == null or picture.is_empty():
            _red("Native Godot did not render the real McLaren mesh " + title)
            return
        for m in all:
            m.visible = false
        for frame in range(5):
            await process_frame
        var hidden := await _photo(stage)
        for m in all:
            m.visible = true
        if hidden == null or hidden.is_empty():
            _red("Missing actual hidden-artist-geometry pixel control " + title)
            return
        var diff_count := 0
        for y in range(90, 910, 6):
            for x in range(90, 1510, 6):
                var a := picture.get_pixel(x,y)
                var b := hidden.get_pixel(x,y)
                if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) > .17:
                    diff_count += 1
        if diff_count < 550:
            _red("Car-shaped pixels NOT backed by true source geometry "+title+" "+str(diff_count))
            return
        var name: String = str(title)+"_REAL_MCLAREN_570S_PBR_GODOT_NO_AI.png"
        var imagefile := target_folder.path_join(name)
        if picture.save_png(imagefile) != OK:
            _red("Could not save actual native Godot image " + title)
            return
        results.append({"view":title,"filename":name,"actual_car_pixels":diff_count,
                        "width_fraction":snappedf(ratio.x, .0001),
                        "height_fraction":snappedf(ratio.y, .0001)})
        print("REAL_SOURCE_MCLAREN_570S_NATIVE_GODOT_FRAME",title,diff_count,"fraction",ratio)

    if results.size() != 5:
        _red("Did not capture all five actual 3D engine angles")
        return
    var report := {
        "status":"REAL_MCLAREN_570S_GODOT_NATIVE_PBR_REVIEW__NOT_VISUALLY_APPROVED",
        "source":"Artist-authored McLaren 570S geometry from Ddiaz Design",
        "actual_source_mesh_instances":all.size(),
        "source_triangles":tris,
        "material_surfaces":materials,
        "car_dimensions_m":[dimension.x,dimension.y,dimension.z],
        "source_original_body_preserved":true,
        "cameras_fill_viewport":true,
        "source_doors_mechanically_separated":false,
        "bonnet_and_trunk_mechanisms":false,
        "requires_independent_commercial_rights_review":true,
        "original_orange_lamborghini_sha256":"45cdbfd70dc4e6c64b6bbbe5e24a2107044e2008928ab01c27fa8fbb91a25bd7",
        "owner_art_approved":false,
        "native_godot_real_pngs":results
    }
    var out := FileAccess.open(target_folder.path_join("real_mclaren_570s_5views_godot_report.json"),FileAccess.WRITE)
    if out == null:
        _red("Cannot write completed McLaren independent real-engine report")
        return
    out.store_string(JSON.stringify(report,"  "))
    out.close()
    print("MCLAREN_570S_GODOT_5_TRUE_CLOSEUP_ENGINE_VIEWS_GREEN_NOT_ART_APPROVED")
    quit(0)
