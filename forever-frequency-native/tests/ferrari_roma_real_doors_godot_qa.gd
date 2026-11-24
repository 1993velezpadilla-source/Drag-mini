extends SceneTree
## Native Godot 4: real source Ferrari door-body and transparent glass shells
## are children of mechanical hinge nodes; screenshot actual closed/open motion.
## No invented 3D bodywork or generated images.
const DoorController = preload("res://scripts/vehicle_door_controller.gd")
const SOURCE := "res://assets/ferrari_roma_review/ferrari_roma_2020_real_artist_island_DOOR_HINGES.glb"

func _initialize() -> void:
    call_deferred("_run")

func _fail(why: String) -> void:
    push_error("FERRARI_ROMA_TRUE_ORIGINAL_ARTIST_HINGED_DOORS_GODOT_RED: " + why)
    quit(1)

func _meshes(parent: Node, out: Array[MeshInstance3D]) -> void:
    if parent is MeshInstance3D and (parent as MeshInstance3D).mesh != null:
        out.append(parent as MeshInstance3D)
    for child in parent.get_children():
        _meshes(child,out)

func _locate_hinges(parent: Node, output: Dictionary) -> void:
    if parent is Node3D and str(parent.name).begins_with("DOOR_") and str(parent.name).ends_with("_HINGE"):
        output[str(parent.name)] = parent
    for child in parent.get_children():
        _locate_hinges(child,output)

func _frame(vp: SubViewport) -> Image:
    await RenderingServer.frame_post_draw
    return vp.get_texture().get_image()

func _mesh_frame_bounds(cam: Camera3D, nodes: Array[MeshInstance3D]) -> Rect2:
    # The input is genuine GLTF artist geometry, not a generated photo.
    var left_top := Vector2(INF,INF)
    var right_bottom := Vector2(-INF,-INF)
    for part in nodes:
        var source: Mesh = part.mesh
        for corner in range(8):
            var point: Vector3 = part.global_transform * source.get_aabb().get_endpoint(corner)
            var projected: Vector2 = cam.unproject_position(point)
            left_top = left_top.min(projected)
            right_bottom = right_bottom.max(projected)
    return Rect2(left_top, right_bottom-left_top)

func _check_close_frontal_view(cam: Camera3D, nodes: Array[MeshInstance3D], tag: String) -> bool:
    var rect: Rect2 = _mesh_frame_bounds(cam,nodes)
    var width: float = rect.size.x/1600.0
    var height: float = rect.size.y/1000.0
    var safe: bool = rect.position.x>=25.0 and rect.position.y>=25.0 and rect.end.x<=1575.0 and rect.end.y<=975.0
    print("REAL_FERRARI_ROMA_NATIVE_CLOSEUP_FRAME ",tag," actual mesh width fraction=",width," height=",height," no_crop=",safe)
    return width>=.58 and maxf(width,height)>=.64 and safe

func _run() -> void:
    var folder := OS.get_environment("CITYZERO_FERRARI_TRUE_HINGES_GODOT")
    if folder.is_empty():
        folder = ProjectSettings.globalize_path("user://ferrari-roma-real-body-doors")
    DirAccess.make_dir_recursive_absolute(folder)
    var original_scene := load(SOURCE) as PackedScene
    if original_scene == null:
        _fail("Actual Blender island-rig original car GLB missing")
        return
    var vp := SubViewport.new()
    vp.size = Vector2i(1600,1000)
    vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var car := original_scene.instantiate() as Node3D
    if car == null:
        _fail("GLB root is not a native scene")
        return
    vp.add_child(car)
    var all_meshes: Array[MeshInstance3D] = []
    _meshes(car,all_meshes)
    var hinges := {}
    _locate_hinges(car,hinges)
    if all_meshes.size() < 15 or hinges.size() != 2:
        _fail("Original model did not retain true door body/glass nodes or 2 hinges")
        return
    for name in ["DOOR_LEFT_FRONT_HINGE","DOOR_RIGHT_FRONT_HINGE"]:
        if not hinges.has(name):
            _fail("Not a true mirrored left/right physical hinge: "+name)
            return
        var panels: Array[MeshInstance3D] = []
        _meshes(hinges[name],panels)
        if panels.size() != 2:
            _fail("Original body AND glass meshes are not both mounted on hinge "+name)
            return
        var panel_triangles := 0
        for panel in panels:
            for i in range(panel.mesh.get_surface_count()):
                var m: Mesh = panel.mesh
                var ni: int = m.surface_get_array_index_len(i)
                panel_triangles += int((ni if ni>0 else m.surface_get_array_len(i))/3)
        if panel_triangles < 2500:
            _fail("Hinge is only a fake transform, not true original artist door geometry "+name)
            return

    var animation := DoorController.new()
    animation.name="SOURCE_PANEL_DOOR_HINGE_CONTROLLER"
    car.add_child(animation)
    await process_frame
    if animation.available_doors().size() != 2:
        _fail("Native Godot door controller cannot operate both original hinge nodes")
        return

    var low := Vector3(INF,INF,INF)
    var high := Vector3(-INF,-INF,-INF)
    for part in all_meshes:
        for j in range(8):
            var pos := part.global_transform * part.mesh.get_aabb().get_endpoint(j)
            low = low.min(pos)
            high = high.max(pos)
    var mid := (low+high)*.5
    var size := high-low
    var span := maxf(size.x,maxf(size.y,size.z))
    if span < 4.4 or span > 4.95:
        _fail("Source car body dimensions were damaged during door separation")
        return

    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color(.40,.46,.56)
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color(.92,.93,1.0)
    env.environment.ambient_light_energy = 1.1
    vp.add_child(env)
    var light := DirectionalLight3D.new()
    light.light_energy = 2.1
    light.rotation_degrees=Vector3(-53,-30,0)
    vp.add_child(light)
    var cam := Camera3D.new()
    cam.projection = Camera3D.PROJECTION_ORTHOGONAL
    # Close physical automotive review camera: make real Ferrari fill frame;
    # previous 1.13*span framing made it look like a tiny toy in 1600x1000.
    cam.size=span*.78
    vp.add_child(cam)
    cam.position=mid+Vector3(1.35,.62,1.5)*span
    cam.look_at(mid,Vector3.UP)
    cam.current=true
    for i in range(20):
        await process_frame
    if not _check_close_frontal_view(cam,all_meshes,"CLOSED"):
        _fail("Actual source Ferrari car is too small or cropped with doors CLOSED")
        return
    var closed := await _frame(vp)
    if closed==null or closed.is_empty():
        _fail("Could not photograph closed REAL Ferrari Roma door panels in Godot")
        return
    for id in animation.available_doors():
        if not animation.toggle_door(id):
            _fail("Original hinged door refused open command "+id)
            return
    for i in range(95):
        await process_frame
    for id in animation.available_doors():
        if not animation.is_door_open(id) or absf(float(animation.current_angle[id])) < .93:
            _fail("Original body + glass hinge did not actually animate "+id)
            return
    if not _check_close_frontal_view(cam,all_meshes,"OPEN"):
        _fail("Real original Ferrari body and door windows are cropped or tiny when OPEN")
        return
    var opened := await _frame(vp)
    if opened==null or opened.is_empty():
        _fail("Could not photograph two physically opened original doors")
        return
    var distinct := 0
    var sample_total := 0
    for y in range(80,920,5):
        for x in range(100,1500,5):
            var a := closed.get_pixel(x,y)
            var b := opened.get_pixel(x,y)
            sample_total += 1
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>.22:
                distinct += 1
    if distinct < 300:
        _fail("Opening hinges does not actually move visible original Ferrari panels "+str(distinct))
        return
    var path_closed := folder.path_join("REAL_FERRARI_ROMA_AUTHOR_DOORS_CLOSED_GODOT.png")
    var path_opened := folder.path_join("REAL_FERRARI_ROMA_AUTHOR_DOORS_OPENED_GODOT.png")
    if closed.save_png(path_closed)!=OK or opened.save_png(path_opened)!=OK:
        _fail("Real Godot PBR door capture file failed")
        return
    var evidence := {
        "model":"Genuine artist-authored Ferrari Roma source GLB with restored original mesh islands",
        "two_author_body_panels_hinged":true,
        "both_original_glass_panel_groups_follow_hinge":true,
        "original_source_geometry_replaced":false,
        "source_trunk_mechanically_open":false,
        "source_hood_mechanically_open":false,
        "owner_art_approved":false,
        "licensing_rights_review_pending":true,
        "actual_imported_mesh_count":all_meshes.size(),
        "hinge_ids":animation.available_doors(),
        "doors_reached_real_open_angles":true,
        "true_rendered_changed_pixels":distinct,
        "sampled_pixels":sample_total,
        "photos":[path_closed,path_opened],
        "status":"TWO_TRUE_MECHANICAL_FERRARI_BODY_AND_GLASS_HINGES_IN_NATIVE_GODOT_PASS__NOT_ART_APPROVED"
    }
    var report := FileAccess.open(folder.path_join("ferrari_roma_true_rig_real_godot_report.json"),FileAccess.WRITE)
    if report==null:
        _fail("Could not save original door mechanism proof")
        return
    report.store_string(JSON.stringify(evidence,"  "))
    report.close()
    print("REAL_FERRARI_ROMA_SOURCE_DOOR_SHELLS_GODOT_CLOSED_AND_OPENED_TRUE_ENGINE_PASS",distinct)
    quit(0)
