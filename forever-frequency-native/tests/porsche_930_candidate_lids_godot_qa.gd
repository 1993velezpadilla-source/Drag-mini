extends SceneTree
## Isolated experimental front/rear source panels, never production.
const SOURCE := "res://assets/UNAPPROVED_PORSCHE930_FRONT_REAR_SOURCE_CANDIDATES.glb"
func _initialize() -> void:
    call_deferred("_run")
func _collect(node: Node, meshes: Array[MeshInstance3D], pivots: Dictionary) -> void:
    if node is MeshInstance3D and node.mesh != null:
        meshes.append(node)
    if node is Node3D and str(node.name) in ["EXPERIMENTAL_FRONT_LUGGAGE_PIVOT", "EXPERIMENTAL_REAR_PAIRED_SURFACES_PIVOT"]:
        pivots[str(node.name)]=node
    for c in node.get_children():
        _collect(c,meshes,pivots)
func _fail(message: String) -> void:
    push_error("PORSCHE930_CANDIDATE_LIDS_RED: "+message)
    quit(1)
func _run() -> void:
    var target := OS.get_environment("CITYZERO_PORSCHE_CANDIDATE_LID_SHOTS")
    if target.is_empty() or DirAccess.make_dir_recursive_absolute(target)!=OK:
        _fail("output missing")
        return
    var resource := load(SOURCE) as PackedScene
    if resource==null:
        _fail("source missing")
        return
    var vp := SubViewport.new()
    vp.size=Vector2i(1600,1000)
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var car := resource.instantiate() as Node3D
    vp.add_child(car)
    var meshes: Array[MeshInstance3D]=[]
    var pivots := {}
    _collect(car,meshes,pivots)
    if pivots.size()!=2:
        _fail("two source candidate pivots missing")
        return
    var triangles:=0
    var lo:=Vector3(INF,INF,INF)
    var hi:=Vector3(-INF,-INF,-INF)
    var baseline: Dictionary={}
    for mesh in meshes:
        baseline[mesh]=mesh.global_transform
        for i in range(mesh.mesh.get_surface_count()):
            if mesh.mesh.surface_get_primitive_type(i)!=Mesh.PRIMITIVE_TRIANGLES:
                _fail("unexpected primitive")
                return
            var count:int=mesh.mesh.surface_get_array_index_len(i)
            if count==0:count=mesh.mesh.surface_get_array_len(i)
            triangles+=int(count/3.0)
        for j in range(8):
            var p:Vector3=mesh.global_transform*mesh.get_aabb().get_endpoint(j)
            lo=lo.min(p)
            hi=hi.max(p)
    if triangles!=241258:
        _fail("triangle count changed: "+str(triangles))
        return
    var env:=WorldEnvironment.new()
    env.environment=Environment.new()
    env.environment.background_mode=Environment.BG_COLOR
    env.environment.background_color=Color(.35,.4,.48)
    env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color=Color(.9,.9,.9)
    env.environment.ambient_light_energy=.8
    vp.add_child(env)
    var light:=DirectionalLight3D.new()
    vp.add_child(light)
    light.rotation_degrees=Vector3(-45,-35,0)
    light.light_energy=1.8
    var cam:=Camera3D.new()
    vp.add_child(cam)
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.size=5.5
    cam.current=true
    var mid:Vector3=(lo+hi)*.5
    var results:Dictionary={}
    for key in ["EXPERIMENTAL_FRONT_LUGGAGE_PIVOT","EXPERIMENTAL_REAR_PAIRED_SURFACES_PIVOT"]:
        var pivot:Node3D=pivots[key]
        var original:Transform3D=pivot.transform
        var front:bool=key.contains("FRONT")
        # Blender -Y is Godot +Z; both coordinate systems share lateral X.
        cam.position=mid+Vector3(3.0,3.3,5.5 if front else -5.5)
        cam.look_at(mid)
        for i in range(4):await process_frame
        await RenderingServer.frame_post_draw
        var closed:Image=vp.get_texture().get_image()
        if closed.save_png(target.path_join(key+"_CLOSED.png"))!=OK:
            _fail("closed capture")
            return
        pivot.transform=original.rotated_local(Vector3.RIGHT,deg_to_rad(-55.0 if front else 55.0))
        var moving:=0
        var min_lift:=INF
        for mesh in meshes:
            var before:Transform3D=baseline[mesh]
            if pivot.is_ancestor_of(mesh):
                moving+=1
                var center:Vector3=mesh.get_aabb().get_center()
                min_lift=minf(min_lift,(mesh.global_transform*center).y-(before*center).y)
            elif not mesh.global_transform.is_equal_approx(before):
                _fail("unrelated source moved: "+str(mesh.name))
                return
        if moving!=2 or min_lift<.12:
            _fail("candidate did not rise correctly: "+str([moving,min_lift]))
            return
        for i in range(4):await process_frame
        await RenderingServer.frame_post_draw
        var opened:Image=vp.get_texture().get_image()
        if opened.save_png(target.path_join(key+"_OPEN.png"))!=OK:
            _fail("open capture")
            return
        var changed:=0
        for y in range(0,1000,5):
            for x in range(0,1600,5):
                var a:Color=closed.get_pixel(x,y)
                var b:Color=opened.get_pixel(x,y)
                if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>.15:changed+=1
        if changed<100:
            _fail("candidate invisible motion")
            return
        pivot.transform=original
        for mesh in meshes:
            if not mesh.global_transform.is_equal_approx(baseline[mesh]):
                _fail("closed roundtrip failed")
                return
        results[key]={"moving_meshes":moving,"minimum_lift_m":min_lift,"changed_pixels_sampled":changed}
    var report:=FileAccess.open(target.path_join("UNAPPROVED_CANDIDATE_REPORT.json"),FileAccess.WRITE)
    if report==null:
        _fail("report failed")
        return
    report.store_string(JSON.stringify({"triangles":triangles,"results":results,"shipping_approved":false,"visual_review_pending":true}, "\t"))
    report.close()
    print("PORSCHE930_EXPERIMENTAL_SOURCE_LIDS_GODOT_MOTION_PASS_NOT_APPROVED")
    quit()
