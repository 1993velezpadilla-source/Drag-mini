extends SceneTree
## Actual Godot framebuffer capture. Only intended to run with a real display / Xvfb.

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var packed: PackedScene = load("res://scenes/main.tscn")
    var game_scene: Node3D = packed.instantiate()
    root.add_child(game_scene)
    for i in range(50):
        await process_frame
    var screenshot: Image = root.get_texture().get_image()
    if screenshot == null or screenshot.is_empty():
        push_error("Screenshot capture returned no framebuffer")
        quit(1)
        return
    var target := ProjectSettings.globalize_path("res://preview_real_godot.png")
    var result: Error = screenshot.save_png(target)
    print("ACTUAL GAMEPLAY CAPTURE STATUS ",result, " at ",target)
    quit(0 if result == OK else 1)
