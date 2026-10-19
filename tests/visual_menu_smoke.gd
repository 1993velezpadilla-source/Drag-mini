extends SceneTree
## Rasterize actual portrait UI/screens (not source photo); reject blank Android frames.
func _initialize() -> void:
    call_deferred("_start")

func _fail(reason: String) -> void:
    printerr("DRAG MINI VISUAL FAIL: " + reason)
    quit(1)

func _check_frame(label: String) -> bool:
    var out := root.get_texture().get_image()
    if out == null or out.get_width() < 400 or out.get_height() < 800:
        _fail(label + " did not render 432x960 portrait")
        return false
    var bins := {}
    for yi in range(3, 31):
        for xi in range(3, 18):
            var x := clampi(roundi(float(xi) * out.get_width() / 20.0), 0, out.get_width() - 1)
            var y := clampi(roundi(float(yi) * out.get_height() / 34.0), 0, out.get_height() - 1)
            var c := out.get_pixel(x, y)
            bins[Vector3i(roundi(c.r * 10), roundi(c.g * 10), roundi(c.b * 10))] = true
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
    if out.save_png(ProjectSettings.globalize_path("res://build/visual-" + label + ".png")) != OK:
        _fail("Cannot save " + label)
        return false
    if bins.size() < 10:
        _fail(label + " was a grey/blank frame (" + str(bins.size()) + " color bins)")
        return false
    return true

func _start() -> void:
    DisplayServer.window_set_size(Vector2i(432, 960))
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    # Visual snapshots must represent a clean install, not credit-rich test saves.
    game.progress.cash = 2500
    game.progress.xp = 0
    game.progress.wins = 0
    game.progress.losses = 0
    game.progress.stage = 0
    game.progress.upgrades = {}
    game.selected = 0
    game.progress.selected = 0
    game.progress.distance_choice = 1
    game.auto_shift = false
    game.progress.auto_shift = false
    game._show_main_menu()
    var fallback = game.get_node_or_null("StartupFallback")
    if fallback == null or fallback.visible or not game.get_meta("dragmini_boot_complete", false):
        _fail("Persistent startup overlay obscures UI")
        return
    for page in ["menu", "garage", "upgrades", "settings", "career", "race_select", "wallpaper"]:
        game._menu_action(page)
        for i in range(5):
            await process_frame
        if not _check_frame(page):
            return
    game._menu_action("start")
    for i in range(5):
        await process_frame
    if not _check_frame("race-start"):
        return
    game.countdown = 0.0
    game.player["distance"] = 399.0
    for i in range(5):
        await process_frame
    if not _check_frame("race-finish"):
        return
    game._enter_wallpaper_mode(false)
    for i in range(5):
        await process_frame
    if not _check_frame("wallpaper-preview"):
        return
    print("DRAG MINI VISUAL PASS: 9 nonblank 432x960 native panels, C++ strip and wallpaper preview")
    quit(0)
