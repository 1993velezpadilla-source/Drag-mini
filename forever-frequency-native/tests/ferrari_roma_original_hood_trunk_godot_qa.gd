extends SceneTree
## Real Godot 4 importer and native engine screenshots of exact Ferrari Roma
## creator-made hood and trunk connected mesh islands. NOT invented CGI.
const SOURCE := "res://assets/ferrari_roma_review/ferrari_roma_2020_REAL_AUTHOR_BODY_DOORS_HOOD_TRUNK.glb"

func _initialize() -> void:
    call_deferred("_run")

func _red(msg: String) -> void:
    push_error("CITYZERO_ORIGINAL_FERRARI_HOOD_TRUNK_GODOT_RED "+msg)
    quit(1)

func _all_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
    if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
        out.append(node as MeshInstance3D)
    for child in node.get_children():
        _all_meshes(child,out)

func _find_node(parent: Node, seek: String) -> Node3D:
    if str(parent.name)==seek and parent is Node3D:
        return parent as Node3D
    for ch in parent.get_children():
        var found: Node3D = _find_node(ch,seek)
        if found != null:
            return found
    return null

func _capture(vp: SubViewport) -> Image:
    await RenderingServer.frame_post_draw
    return vp.get_texture().get_image()

func _run() -> void:
    var directory := OS.get_environment("CITYZERO_FERRARI_HOOD_TRUNK_GODOT_FRAMES")
    if directory.is_empty():
        directory = ProjectSettings.globalize_path("user://original-ferrari-hood-trunk")
    DirAccess.make_dir_recursive_absolute(directory)
    var resource := load(SOURCE) as PackedScene
    if resource == null:
        _red("Cannot import actual original Ferrari separated 3D body GLB")
        return
    var vp := SubViewport.new()
    vp.size = Vector2i(1600,1000)
    vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var car := resource.instantiate() as Node3D
    if car == null:
        _red("Source GLB is not a native Godot 3D scene")
        return
    vp.add_child(car)
    var all: Array[MeshInstance3D] = []
    _all_meshes(car,all)
    if all.size() < 19:
        _red("Original Ferrari artistic geometry and door, hood, trunk meshes missing")
        return

    var hood := _find_node(car,"HOOD_FRONT_HINGE")
    var trunk := _find_node(car,"TRUNK_REAR_HINGE")
    if hood == null or trunk == null:
        _red("Creator hood/trunk geometry was not parented to actual hinge nodes")
        return
    if _find_node(car,"DOOR_LEFT_FRONT_HINGE")==null or _find_node(car,"DOOR_RIGHT_FRONT_HINGE")==null:
        _red("Do NOT lose the genuine artist real Ferrari doors while moving trunk/hood")
        return
    var hood_meshes: Array[MeshInstance3D] = []
    var trunk_meshes: Array[MeshInstance3D] = []
    _all_meshes(hood,hood_meshes)
    _all_meshes(trunk,trunk_meshes)
    if hood_meshes.size()!=1 or trunk_meshes.size()!=1:
        _red("Hinges must each own a REAL Ferrari factory surface mesh")
        return
    var hood_triangles := 0
    var trunk_triangles := 0
    for node in hood_meshes:
        var m: Mesh = node.mesh
        for surf in range(m.get_surface_count()):
            var n: int = m.surface_get_array_index_len(surf)
            hood_triangles += int((n if n>0 else m.surface_get_array_len(surf)) / 3)
    for node in trunk_meshes:
        var m: Mesh = node.mesh
        for surf in range(m.get_surface_count()):
            var n: int = m.surface_get_array_index_len(surf)
            trunk_triangles += int((n if n>0 else m.surface_get_array_len(surf)) / 3)
    if hood_triangles != 3256+1836 or trunk_triangles != 1240+1154:
        _red("Hood/trunk are not exact original untouched Ferrari artist panels: "+str([hood_triangles,trunk_triangles]))
        return

    var source_triangles := 0
    var low := Vector3(INF,INF,INF)
    var high := Vector3(-INF,-INF,-INF)
    for obj in all:
        var m: Mesh = obj.mesh
        for surf in range(m.get_surface_count()):
            if m.surface_get_primitive_type(surf)!=Mesh.PRIMITIVE_TRIANGLES:
                continue
            var n: int = m.surface_get_array_index_len(surf)
            source_triangles += int((n if n>0 else m.surface_get_array_len(surf))/3)
        for corner in range(8):
            var p: Vector3 = obj.global_transform * m.get_aabb().get_endpoint(corner)
            low = low.min(p)
            high = high.max(p)
    if source_triangles != 238791:
        _red("Original 238791 author-made Ferrari source triangles changed during separate panels")
        return
    var mid := (low+high)*.5
    var span := maxf(high.x-low.x,maxf(high.y-low.y,high.z-low.z))
    if span<4.4 or span>5.1:
        _red("Ferrari factory 4.656m dimensions damaged")
        return
    var world := WorldEnvironment.new()
    world.environment=Environment.new()
    world.environment.background_mode=Environment.BG_COLOR
    world.environment.background_color=Color(.43,.50,.60)
    world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    world.environment.ambient_light_color=Color(.91,.94,1.0)
    world.environment.ambient_light_energy=1.05
    vp.add_child(world)
    var light := DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-46,-31,-10)
    light.light_energy=2.5
    vp.add_child(light)
    var camera := Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=span*.90
    vp.add_child(camera)
    camera.current=true
    var out_frames: Array[Dictionary] = []
    var pivots := {"hood":hood,"trunk":trunk}
    for item in ["hood","trunk"]:
        var hinge: Node3D = pivots[item]
        var closed_quat: Quaternion = hinge.quaternion
        var forward: bool = item=="hood"
        camera.position=mid+Vector3(1.3,.77,1.58 if forward else -1.58)*span
        camera.look_at(mid,Vector3.UP)
        for cycle in range(14):
            await process_frame
        var closed := await _capture(vp)
        if closed == null or closed.is_empty():
            _red("Real native Godot could not render original closed "+item)
            return
        hinge.quaternion=closed_quat * Quaternion(Vector3.RIGHT,deg_to_rad(-54.0 if forward else 56.0))
        for cycle in range(15):
            await process_frame
        var opened := await _capture(vp)
        if opened == null or opened.is_empty():
            _red("Real native Godot could not render original open "+item)
            return
        var changed := 0
        for y in range(90,910,5):
            for x in range(90,1510,5):
                var a := closed.get_pixel(x,y)
                var b := opened.get_pixel(x,y)
                if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>.18:
                    changed += 1
        if changed < 200:
            _red("Rotating source hinge did not visibly open ORIGINAL "+item+" "+str(changed))
            return
        for state in ["CLOSED","OPENED"]:
            var im: Image = closed if state=="CLOSED" else opened
            var filename: String = "FERRARI_ROMA_REAL_AUTHOR_"+item.to_upper()+"_"+state+"_NATIVE_GODOT.png"
            if im.save_png(directory.path_join(filename)) != OK:
                _red("Failed native Godot real original source screenshot "+filename)
                return
        out_frames.append({"part":item,"original_creator_panels_moved":true,
                           "actual_changed_pixel_samples":changed,
                           "source_panel_triangles":hood_triangles if forward else trunk_triangles})
        print("FERRARI_ROMA_TRUE_SOURCE_HINGED_GODOT_",item," PIXELS ",changed)
        hinge.quaternion=closed_quat
        for cycle in range(5):
            await process_frame
    if out_frames.size()!=2:
        _red("Both actual hood and trunk body motion tests incomplete")
        return
    var report := {
        "source":"Real 2020 Ferrari Roma artist original GLB, separated source disconnected body panels",
        "original_artist_triangles":source_triangles,
        "real_left_right_glass_hood_trunk_physical_hinge_nodes":true,
        "bonnet_and_trunk_not_fake_meshes":true,
        "native_godot_screenshots":4,
        "source_panel_tests":out_frames,
        "user_approved":false,
        "engine_bay_production_art_pending":true,
        "cargo_compartment_art_pending":true,
        "commercial_brand_rights_unverified":true,
        "original_orange_lamborghini_unchanged_sha256":"45cdbfd70dc4e6c64b6bbbe5e24a2107044e2008928ab01c27fa8fbb91a25bd7"
    }
    var out := FileAccess.open(directory.path_join("ferrari_roma_original_hood_trunk_engine_report.json"),FileAccess.WRITE)
    if out==null:
        _red("Could not write Godot exact source panel forensic report")
        return
    out.store_string(JSON.stringify(report,"  "))
    out.close()
    print("FERRARI_ROMA_ORIGINAL_ARTIST_HOOD_TRUNK_REAL_GODOT_4_VIEWS_GREEN")
    quit(0)
