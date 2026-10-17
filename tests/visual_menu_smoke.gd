extends SceneTree
## Prevent a repeat of the Pixel Fold V0.5 solid grey display.
## Run under xvfb (not --headless), so Godot actually rasterizes.
func _initialize() -> void:
    call_deferred("_start")

func _fail(reason: String) -> void:
    printerr("DRAG MINI VISUAL FAIL: " + reason)
    quit(1)

func _check_frame(label: String) -> bool:
    var vp := root
    var output := vp.get_texture().get_image()
    if output == null or output.get_width() < 600 or output.get_height() < 350:
        _fail(label + " render texture is empty or too small")
        return false
    var bins := {}
    for yi in range(3, 18):
        for xi in range(3, 32):
            var x := clampi(roundi(float(xi) * output.get_width() / 34.0), 0, output.get_width() - 1)
            var y := clampi(roundi(float(yi) * output.get_height() / 20.0), 0, output.get_height() - 1)
            var c := output.get_pixel(x, y)
            bins[Vector3i(roundi(c.r * 10.0), roundi(c.g * 10.0), roundi(c.b * 10.0))] = true
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
    var err: int = output.save_png(ProjectSettings.globalize_path("res://build/visual-" + label + ".png"))
    if err != OK:
        _fail("Failed saving " + label + " screenshot")
        return false
    if bins.size() < 22:
        _fail(label + " screen is solid gray/black or official photo never rendered (" + str(bins.size()) + " color bins)")
        return false
    return true

func _start() -> void:
    DisplayServer.window_set_size(Vector2i(1280, 720))
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    var fallback = game.get_node_or_null("StartupFallback")
    if fallback == null:
        _fail("Static startup fallback scene not installed")
        return
    if not game.get_meta("dragmini_boot_complete", false) or fallback.visible:
        _fail("Game did not finish startup or static fallback incorrectly covers menu")
        return
    for i in range(8):
        await process_frame
    if not _check_frame("official-menu"):
        return
    game._menu_action("race")
    for i in range(8):
        await process_frame
    if not _check_frame("official-race-track"):
        return
    print("DRAG MINI VISUAL PASS: official menu and race render actual colorful frames")
    quit(0)
