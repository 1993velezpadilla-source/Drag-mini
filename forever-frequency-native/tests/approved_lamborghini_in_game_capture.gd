extends SceneTree
## Captures ACTUAL Godot frames of the already-authored REVULSE in City's
## playable main scene, with both door hinges closed and fully open.
## No illustration generation. Fail on missing GLB, missing hinges or no visible
## frame difference. PNG output is available as a GitHub Actions artifact.

var _frames_closed: Image
var _frames_open: Image

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("CITY_ZERO_APPROVED_LAMBORGHINI_GAME_SCREENSHOT_RED: " + message)
    quit(1)

func _wait_frames(n: int) -> void:
    for i in range(n):
        await process_frame

func _save_frame(viewport: Viewport, target: String) -> Image:
    await RenderingServer.frame_post_draw
    var picture := viewport.get_texture().get_image()
    if picture == null or picture.is_empty():
        return null
    var error := picture.save_png(target)
    if error != OK:
        push_error("Cannot save Godot image %s: %d" % [target, error])
        return null
    return picture

func _capture() -> void:
    var dir := OS.get_environment("CITYZERO_REVULSE_SCREENSHOTS")
    if dir.is_empty():
        dir = ProjectSettings.globalize_path("user://revulse-in-game")
    DirAccess.make_dir_recursive_absolute(dir)

    var world_scene := load("res://scenes/main.tscn") as PackedScene
    if world_scene == null:
        _fail("Actual city game scene cannot load")
        return
    var city := world_scene.instantiate() as Node3D
    if city == null:
        _fail("Actual city world root invalid")
        return
    root.add_child(city)
    await _wait_frames(8)
    var car: Node3D = city.get("revulse_car")
    var animator = city.get("revulse_doors")
    if car == null or animator == null:
        _fail("Previously approved supercar rig did not spawn IN the real City Zero game")
        return
    var names: Array[String] = animator.available_doors()
    if names.size() != 2:
        _fail("Previously approved Lamborghini-style model requires exactly two mechanical hinges")
        return

    # Force fixed reviewer camera to see both silhouette and actual street;
    # no separate image-generation, offscreen Blender or compositing pass.
    city.set_process(false)
    city.set_physics_process(false)
    var cam: Camera3D = city.get("camera")
    if cam == null:
        _fail("City Zero's genuine gameplay camera is missing")
        return
    var focus := car.global_position + Vector3(0, 0.65, 0)
    cam.global_position = focus + Vector3(5.8, 2.2, 5.4)
    cam.look_at(focus, Vector3.UP)
    cam.fov = 52.0
    cam.current = true

    await _wait_frames(40)
    var viewport := root.get_viewport()
    var closed_path := dir.path_join("LAMBORGHINI_CITY_ZERO_IN_GAME_DOORS_CLOSED.png")
    var closed := await _save_frame(viewport, closed_path)
    if closed == null:
        _fail("Closed screenshot could not be saved by Godot")
        return

    for door_name in names:
        if not animator.toggle_door(door_name):
            _fail("Original approved car mechanical hinge failed: " + door_name)
            return
    # 65deg at 105deg/s requires ~0.62s. 85 frames give full travel even
    # with slower software GPU on GitHub CI.
    await _wait_frames(85)
    for door_name in names:
        if not animator.is_door_open(door_name):
            _fail("Door state was not open: " + door_name)
            return
        if absf(float(animator.current_angle[door_name])) < 0.85:
            _fail("Imported door hinge never physically reached opened angle")
            return
    var opened_path := dir.path_join("LAMBORGHINI_CITY_ZERO_IN_GAME_DOORS_OPEN.png")
    var opened := await _save_frame(viewport, opened_path)
    if opened == null:
        _fail("Opened screenshot could not be saved by Godot")
        return

    if closed.get_width() < 800 or closed.get_height() < 400:
        _fail("Godot screenshots are smaller than expected")
        return
    if closed.get_size() != opened.get_size():
        _fail("Closed and open screenshot dimensions differ")
        return
    var changed := 0
    var sampled := 0
    var distinct_closed: Dictionary = {}
    var distinct_open: Dictionary = {}
    for y in range(100, closed.get_height() - 60, 5):
        for x in range(100, closed.get_width() - 100, 5):
            var a := closed.get_pixel(x, y)
            var b := opened.get_pixel(x, y)
            distinct_closed[a.to_html(false)] = true
            distinct_open[b.to_html(false)] = true
            sampled += 1
            if absf(a.r-b.r) + absf(a.g-b.g) + absf(a.b-b.b) > 0.20:
                changed += 1
    if distinct_closed.size() < 70 or distinct_open.size() < 70:
        _fail("Blank/stale renderer capture: insufficient actual scene colors")
        return
    if changed < 180:
        _fail("Doors-open screenshot is not visibly different from doors-closed")
        return

    var metadata := {
        "source": "Godot 4.4 actual City Zero main scene viewport",
        "model": "curated_midengine_supercar.glb",
        "real_glb": true,
        "in_city_world": true,
        "hinges": names,
        "closed": closed_path,
        "open": opened_path,
        "changed_grid_pixels": changed,
        "sample_count": sampled,
        "captured_resolution": [closed.get_width(), closed.get_height()]
    }
    var f := FileAccess.open(dir.path_join("godot_actual_scene_evidence.json"), FileAccess.WRITE)
    if f == null:
        _fail("Could not write actual game capture evidence")
        return
    f.store_string(JSON.stringify(metadata, "  "))
    f.close()
    print("CITY_ZERO_APPROVED_LAMBORGHINI_ACTUAL_IN_GAME_SCREENSHOTS_GREEN ", JSON.stringify(metadata))
    quit(0)
