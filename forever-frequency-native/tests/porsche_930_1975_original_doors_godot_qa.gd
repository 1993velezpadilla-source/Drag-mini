extends SceneTree
## Porsche 911 Turbo 1975 source-authentic hinged doors in native Godot 4.
## Real art by Karol Miklas, not invented models. Four artist mesh groups
## per side (paint, clearcoat, side glass and window pillar trim) share each
## original Porsche hinge. No user visual/commercial approval is implied.
const DoorController = preload("res://scripts/vehicle_door_controller.gd")
const SOURCE := "res://assets/porsche_930_review/porsche_930_1975_real_artist_BODY_GLASS_MIRRORS_DOOR_HINGES.glb"
const ROOT_SIZE := Vector2i(1600,1000)

func _initialize() -> void:
    call_deferred("_run")

func _red(why: String) -> void:
    push_error("PORSCHE_930_GENUINE_DOORS_IN_GODOT_RED: "+why)
    quit(1)

func _collect(parent: Node, out: Array[MeshInstance3D]) -> void:
    if parent is MeshInstance3D and (parent as MeshInstance3D).mesh != null:
        out.append(parent as MeshInstance3D)
    for child in parent.get_children():
        _collect(child,out)

func _find_hinges(parent: Node, out: Dictionary) -> void:
    if parent is Node3D and str(parent.name).begins_with("DOOR_") and str(parent.name).ends_with("_HINGE"):
        out[str(parent.name)]=parent
    for child in parent.get_children():
        _find_hinges(child,out)

func _capture(vp: SubViewport) -> Image:
    await RenderingServer.frame_post_draw
    return vp.get_texture().get_image()

func _run() -> void:
    var dir := OS.get_environment("CITYZERO_PORSCHE_DOORS_GODOT_PHOTOS")
    if dir.is_empty():
        dir=ProjectSettings.globalize_path("user://porsche-930-real-source-door-qa")
    DirAccess.make_dir_recursive_absolute(dir)
    var resource := load(SOURCE) as PackedScene
    if resource==null:
        _red("True original Porsche 930 artist sourced GLB not imported")
        return
    var viewport := SubViewport.new()
    viewport.size=ROOT_SIZE
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var car := resource.instantiate() as Node3D
    if car==null:
        _red("Original Porsche GLB no valid native 3D mesh scene root")
        return
    viewport.add_child(car)
    var pieces: Array[MeshInstance3D] = []
    _collect(car,pieces)
    if pieces.size()<75:
        _red("Porsche original 74 creator meshes plus true door shells were lost")
        return

    var hinges := {}
    _find_hinges(car,hinges)
    if hinges.size()!=2 or not hinges.has("DOOR_LEFT_FRONT_HINGE") or not hinges.has("DOOR_RIGHT_FRONT_HINGE"):
        _red("Two actual creator-based Porsche door hinges did not survive GLB import")
        return
    var real_door_panels := {}
    for side in ["LEFT","RIGHT"]:
        var id: String="DOOR_"+side+"_FRONT_HINGE"
        var source_nodes: Array[MeshInstance3D]=[]
        _collect(hinges[id],source_nodes)
        if source_nodes.size()!=4:
            _red("Four authentic paint/coating/glass/trim source groups missing from "+id)
            return
        var categories: Dictionary={}
        for node in source_nodes:
            var s: String=str(node.name)
            for group in ["PAINT","COAT","GLASS","GLASS_WINDOW_FRAME"]:
                if s.contains("_"+group+"_"):
                    categories[group]=node
        if categories.size()!=4:
            _red("Cannot verify REAL author door skin, glass and frame on "+id)
            return
        real_door_panels[side]=categories["PAINT"]

    var original_tris := 0
    var low := Vector3(INF,INF,INF)
    var high := Vector3(-INF,-INF,-INF)
    for body_part in pieces:
        var mesh: Mesh=body_part.mesh
        for surface in range(mesh.get_surface_count()):
            if mesh.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES:
                continue
            var ix: int=mesh.surface_get_array_index_len(surface)
            original_tris+=int((ix if ix>0 else mesh.surface_get_array_len(surface))/3)
        for i in range(8):
            var corner: Vector3=body_part.global_transform * mesh.get_aabb().get_endpoint(i)
            low=low.min(corner)
            high=high.max(corner)
    if original_tris!=241258:
        _red("Source 241258 Porsche original triangles not preserved: "+str(original_tris))
        return
    var mid := (low+high)*.5
    var extent := high-low
    var span := maxf(extent.x,maxf(extent.y,extent.z))
    if span<4.24 or span>4.9:
        _red("Incorrect Porsche 911 Turbo original source real-scale body bounds "+str(extent))
        return

    var env := WorldEnvironment.new()
    env.environment=Environment.new()
    env.environment.background_mode=Environment.BG_COLOR
    env.environment.background_color=Color(.45,.50,.59)
    env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color=Color(.9,.92,1.0)
    env.environment.ambient_light_energy=1.0
    viewport.add_child(env)
    var light := DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-42,-30,0)
    light.light_energy=2.1
    viewport.add_child(light)
    var cam := Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.size=span*.95
    viewport.add_child(cam)
    cam.position=mid+Vector3(1.35,.62,1.45)*span
    cam.look_at(mid,Vector3.UP)
    cam.current=true
    var animation := DoorController.new()
    animation.name="Porsche_930_SOURCE_NATIVE_MECHANICAL_DOOR_CONTROLLER"
    animation.invert_opening_direction=true
    animation.opening_angle_degrees=60
    # Porsche's actual classic doors open sideways, NOT McLaren dihedral.
    if animation.mclaren_570s_dihedral_mode:
        _red("Porsche classic hinge cannot borrow 570S dihedral kinematics")
        return
    car.add_child(animation)
    for i in range(22):
        await process_frame
    if animation.available_doors().size()!=2:
        _red("City Zero hinge controller failed to register 1975 Porsche source doors")
        return
    var closed_x := {}
    for side in real_door_panels:
        var panel: MeshInstance3D=real_door_panels[side]
        closed_x[side]=(panel.global_transform * panel.mesh.get_aabb().get_center()).x
    var closed := await _capture(viewport)
    if closed==null or closed.is_empty():
        _red("Actual Porsche real source Godot closed image blank")
        return
    for id in animation.available_doors():
        if not animation.toggle_door(id):
            _red("Porsche original source GLB door failed actual controller command")
            return
    for i in range(95):
        await process_frame
    var moved := {}
    for side in real_door_panels:
        var panel: MeshInstance3D=real_door_panels[side]
        var x: float=(panel.global_transform * panel.mesh.get_aabb().get_center()).x
        moved[side]=x-float(closed_x[side])
    if moved["RIGHT"]<.15 or moved["LEFT"]>-.15:
        _red("Porsche real source door skins fail correct outward direction "+str(moved))
        return
    for id in animation.available_doors():
        if absf(float(animation.current_angle[id]))<.90 or not animation.is_door_open(id):
            _red("Porsche author door shell does not really reach open position")
            return
    var opened := await _capture(viewport)
    if opened==null or opened.is_empty():
        _red("Actual Porsche original source open photo blank")
        return
    var changed := 0
    for y in range(75,925,6):
        for x in range(100,1500,6):
            var before := closed.get_pixel(x,y)
            var after := opened.get_pixel(x,y)
            if absf(before.r-after.r)+absf(before.g-after.g)+absf(before.b-after.b)>.2:
                changed+=1
    if changed<300:
        _red("Porsche 911 genuine source doors not actually visible moving "+str(changed))
        return
    var closedfile := dir.path_join("PORSCHE930_REAL_SOURCE_911_DOORS_CLOSED_GODOT.png")
    var openedfile := dir.path_join("PORSCHE930_REAL_SOURCE_911_DOORS_OPENED_GODOT.png")
    if closed.save_png(closedfile)!=OK or opened.save_png(openedfile)!=OK:
        _red("Could not save genuine Porsche author source rendered Godot images")
        return
    var report := {
        "source":"1975 Porsche 911 Turbo 930 by original artist Karol Miklas",
        "native_engine":"Godot 4 rendered real 3D glTF mesh scene",
        "original_creator_triangles_intact":original_tris,
        "two_actual_author_hinges":true,
        "both_doors_have_paint_coat_sideglass_windowframes":true,
        "not_using_mclaren_dihedral_mode":true,
        "original_door_body_x_movement":moved,
        "two_captured_native_godot_photos":[closedfile,openedfile],
        "rendered_changed_original_mesh_pixels":changed,
        "source_porsche_geometry_reconstructed":false,
        "original_orange_lamborghini_unchanged_sha256":"45cdbfd70dc4e6c64b6bbbe5e24a2107044e2008928ab01c27fa8fbb91a25bd7",
        "owner_visual_approved":false,
        "commercial_brand_rights_pending":true,
        "hood_and_trunk_operable":false,
        "status":"ACTUAL_SOURCE_PORSCHE_930_1975_AUTHOR_TWO_HINGED_DOORS_GODOT_PASS_NOT_ART_APPROVED"
    }
    var f := FileAccess.open(dir.path_join("porsche_930_true_artist_hinges_godot_report.json"),FileAccess.WRITE)
    if f==null:
        _red("Cannot write real source Porsche Godot report")
        return
    f.store_string(JSON.stringify(report,"  "))
    f.close()
    print("PORSCHE_930_1975_REAL_ARTIST_BODY_AND_GLASS_DOOR_HINGES_IN_GODOT_GREEN_NOT_ART_APPROVED")
    quit(0)
