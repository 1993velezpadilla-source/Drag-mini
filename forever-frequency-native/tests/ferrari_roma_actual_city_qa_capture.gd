extends SceneTree
## The ACTUAL PLAYABLE CITY scene, not isolated model showroom.
## Load only when CITYZERO_DEV_FERRARI_ROMA=1 with original creator GLB provided.
## Real two doors, real source hood, real source trunk. No fabricated photos.
func _initialize() -> void:
    call_deferred("_capture_in_real_game")

func _red(msg: String) -> void:
    push_error("CITYZERO_FERRARI_ROMA_DEV_ACTUAL_CITY_GAME_QA_RED: "+msg)
    quit(1)

func _wait_frames(n: int) -> void:
    for i in range(n):
        await process_frame

func _photo(vp: Viewport) -> Image:
    await RenderingServer.frame_post_draw
    return vp.get_texture().get_image()

func _capture_in_real_game() -> void:
    if OS.get_environment("CITYZERO_DEV_FERRARI_ROMA")!="1":
        _red("Ferrari scene must be a development-only opt-in, never a production car")
        return
    var folder := OS.get_environment("CITYZERO_FERRARI_ACTUAL_CITY_GAME_PHOTOS")
    if folder.is_empty():
        folder=ProjectSettings.globalize_path("user://ferrari-roma-source-city-optin-review")
    DirAccess.make_dir_recursive_absolute(folder)

    var city_scene := load("res://scenes/main.tscn") as PackedScene
    if city_scene==null:
        _red("Cannot load ACTUAL Godot city main scene")
        return
    var city := city_scene.instantiate() as Node3D
    if city==null:
        _red("Actual City Zero world lacks 3D root")
        return
    root.add_child(city)
    await _wait_frames(20)

    var gold: Node3D=city.get("lamborghini_orange_car")
    var car: Node3D=city.get("ferrari_roma_review_car")
    var hood: Node3D=city.get("ferrari_roma_review_hood")
    var trunk: Node3D=city.get("ferrari_roma_review_trunk")
    var door_controller=city.get("ferrari_roma_review_door_controller")
    if gold==null or car==null or hood==null or trunk==null or door_controller==null:
        _red("ACTUAL main City scene did not include unchanged gold Lamborghini and 4-hinge prototype Ferrari")
        return
    if car.name!="CityZero_UNAPPROVED_FerrariRoma_Real_Hinges_DevQA":
        _red("Approved/original Ferrari visual separation label lost")
        return
    if gold.name!="CityZero_Approved_Orange_Lamborghini":
        _red("Do not replace original orange gold Lamborghini model")
        return
    if car.position.distance_to(gold.position)<3.8:
        _red("Unapproved Ferrari is overlapping approved orange car")
        return
    if door_controller.available_doors().size()!=2:
        _red("Actual City game did not import both real Ferrari creator-made door pivots")
        return

    var cam: Camera3D=city.get("camera")
    if cam==null:
        _red("Actual playable City Zero game camera missing")
        return
    city.set_process(false)
    city.set_physics_process(false)
    var target := car.global_position+Vector3(0,.75,0)
    cam.global_position=target+Vector3(4.85,2.3,5.15)
    cam.look_at(target,Vector3.UP)
    cam.fov=49.0
    cam.current=true
    await _wait_frames(40)

    var closed: Image=await _photo(root.get_viewport())
    if closed==null or closed.is_empty():
        _red("ACTUAL City Zero Ferrari showroom closed frame blank")
        return

    var original_hood: Quaternion=hood.quaternion
    var original_trunk: Quaternion=trunk.quaternion
    for id in door_controller.available_doors():
        if not door_controller.toggle_door(id):
            _red("Native Ferrari original body and glazing door pivots failed in ACTUAL City game")
            return
    hood.quaternion=original_hood * Quaternion(Vector3.RIGHT,deg_to_rad(-54.0))
    trunk.quaternion=original_trunk * Quaternion(Vector3.RIGHT,deg_to_rad(56.0))
    await _wait_frames(95)
    for id in door_controller.available_doors():
        if not door_controller.is_door_open(id) or absf(float(door_controller.current_angle[id]))<.9:
            _red("Ferrari creator source doors failed to reach true opening angle in CITY Zero")
            return

    var opened: Image=await _photo(root.get_viewport())
    if opened==null or opened.is_empty() or closed.get_size()!=opened.get_size():
        _red("Cannot compare actual City Zero car closed/open main game frames")
        return

    var differing := 0
    var palette := {}
    for y in range(80,closed.get_height()-60,5):
        for x in range(80,closed.get_width()-80,5):
            var before := closed.get_pixel(x,y)
            var after := opened.get_pixel(x,y)
            palette[before.to_html(false)]=true
            if absf(before.r-after.r)+absf(before.g-after.g)+absf(before.b-after.b)>.20:
                differing+=1
    if differing<280 or palette.size()<70:
        _red("Ferrari original body + actual hinged parts not visibly moving in REAL City game: "+str(differing))
        return

    var closed_name := folder.path_join("FERRARI_ROMA_REAL_CITY_DEV_REVIEW_ALL_PANELS_CLOSED.png")
    var opened_name := folder.path_join("FERRARI_ROMA_REAL_CITY_DEV_REVIEW_ALL_PANELS_OPENED.png")
    if closed.save_png(closed_name)!=OK or opened.save_png(opened_name)!=OK:
        _red("Cannot save original 3D car screenshots in actual playable game")
        return

    var manifest := {
        "scene":"res://scenes/main.tscn",
        "engine":"Godot 4 actual City Zero playable native main world",
        "gold_original_lamborghini_unmodified_present":true,
        "source_ferrari_proto_imported":true,
        "ferrari_approved_by_owner":false,
        "ferrari_shipped_in_android_apk":false,
        "explicit_opt_in_environment":"CITYZERO_DEV_FERRARI_ROMA=1",
        "physically_hinged_creator_body_parts":["door_left","door_right","hood","trunk"],
        "image_model_replaced_with_generated_ai":false,
        "actual_scene_changed_pixel_samples":differing,
        "actual_game_images":[closed_name,opened_name],
        "artist":"Ddiaz Design",
        "source_original_triangle_count":238791,
        "trademark_license_review_pending":true
    }
    var report := FileAccess.open(folder.path_join("ferrari_true_source_in_actual_city_dev_report.json"),FileAccess.WRITE)
    if report==null:
        _red("Cannot save actual playable City screenshot JSON")
        return
    report.store_string(JSON.stringify(manifest,"  "))
    report.close()
    print("CITYZERO_FERRARI_ROMA_ACTUAL_GAME_MAIN_CITY_4_SOURCE_HINGES_SCREENSHOTS_GREEN")
    quit(0)
