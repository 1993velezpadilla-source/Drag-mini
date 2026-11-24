extends SceneTree
## Genuine Godot 4.4 framebuffer captures, including independently positioned 3D cameras.
## A visual gauntlet needs a wide city shot and an unflattering side view, not cherry-picking.

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var packed: PackedScene = load("res://scenes/main.tscn")
    var game_scene: Node3D = packed.instantiate()
    root.add_child(game_scene)
    for i in range(55):
        await process_frame

    # Current real-player viewpoint with actual HUD.
    if not _save_frame("preview_real_godot.png"):
        quit(1)
        return

    # Hide ONLY GUI overlays for scene quality assessment, not geometry.
    for child in game_scene.get_children():
        if child is CanvasLayer:
            child.visible = false

    var critic_camera := Camera3D.new()
    critic_camera.fov = 57.0
    critic_camera.near = 0.1
    critic_camera.far = 180.0
    game_scene.add_child(critic_camera)
    critic_camera.current = true
    var shots := [
        {"file": "preview_city_aerial.png", "from": Vector3(5,24,17), "toward": Vector3(0,1,-12)},
        {"file": "preview_market_street.png", "from": Vector3(27,7,4), "toward": Vector3(13,2,-14)},
        {"file": "preview_studio_closeup.png", "from": Vector3(-24,6,-1), "toward": Vector3(-14,4,-15)},
    ]
    for shot in shots:
        critic_camera.position = shot["from"]
        critic_camera.look_at(shot["toward"])
        for i in range(12):
            await process_frame
        if not _save_frame(shot["file"]):
            quit(1)
            return
    print("REAL GODOT FOUR-ANGLE VISUAL GAUNTLET GREEN")
    quit(0)

func _save_frame(filename: String) -> bool:
    var screenshot: Image = root.get_texture().get_image()
    if screenshot == null or screenshot.is_empty():
        push_error("Missing real framebuffer for " + filename)
        return false
    var target := ProjectSettings.globalize_path("res://" + filename)
    var result: Error = screenshot.save_png(target)
    print("REAL FRAMEBUFFER CAPTURE ",filename," ",result," bytes ",screenshot.get_width(),"x",screenshot.get_height())
    return result == OK
