extends SceneTree
## No screenshots synthesized: verify exact owner media files committed in GitHub.
func _initialize() -> void:
    call_deferred("_run")

func _bad(msg: String) -> void:
    printerr("DRAG MINI OFFICIAL FAIL: " + msg)
    quit(1)

func _run() -> void:
    var menu_image: String = "res://assets/ui/official_main_menu.jpg"
    var track_image: String = "res://assets/tracks/official_drag_strip.jpg"
    var menu_sha := FileAccess.get_sha256(menu_image)
    var track_sha := FileAccess.get_sha256(track_image)
    if menu_sha != "927fd4a3ff7bd29408454e767c580512500d30b77c11fc97e172c2ea96529060":
        _bad("Original menu image bytes differ from owner's uploaded source")
        return
    if track_sha != "6652dc1f7852f43c4a58d82ae29503d80eb0a492f221deb2078a588bf6500ac7":
        _bad("Original track image bytes differ from owner's uploaded source")
        return
    var menu_t := load(menu_image) as Texture2D
    var track_t := load(track_image) as Texture2D
    if menu_t == null or menu_t.get_width() != 1536 or menu_t.get_height() != 864:
        _bad("Official main menu texture failed to import")
        return
    if track_t == null or track_t.get_width() != 1536 or track_t.get_height() != 512:
        _bad("Official race strip texture failed to import")
        return

    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    if game.screen != "menu":
        _bad("Official clickable menu must be the initial screen")
        return
    if game.menu_overlay == null or game.menu_overlay.get_node_or_null("StartTouch") == null:
        _bad("START hotspot missing from actual photo menu")
        return
    for hotspot in ["RaceTouch", "GarageTouch", "WallpaperTouch", "UpgradesTouch", "SettingsTouch", "StartTouch"]:
        if game.menu_overlay.get_node_or_null(hotspot) == null:
            _bad("Clickable main menu hotspot missing: " + hotspot)
            return
    game._menu_action("race")
    if game.screen != "race":
        _bad("Photo menu RACE tap did not begin game")
        return
    if game.track_image == null:
        _bad("Race is not using official strip texture")
        return
    game.countdown = 0.0
    game.auto_shift = false
    game.throttle_held = true
    game.player["rpm"] = float(game.CARS[game.selected]["redline"]) * 0.90
    game.player["shift_timer"] = 0.0
    game._player_shift()
    if game.shift_feedback != "PERFECT" or not game.shift_feedback_label.visible:
        _bad("Perfect-shift feedback not only triggered on SHIFT press")
        return
    game._process(1.0)
    if game.shift_feedback_label.visible:
        _bad("Shift feedback must auto-hide after a brief interval")
        return
    game.player["shift_timer"] = 0.0
    game.player["rpm"] = float(game.CARS[game.selected]["redline"]) * 0.4
    game._player_shift()
    if game.shift_feedback != "EARLY":
        _bad("Early shift window wrong")
        return
    game.player["shift_timer"] = 0.0
    game.player["rpm"] = float(game.CARS[game.selected]["redline"]) * 0.99
    game._player_shift()
    if game.shift_feedback != "LATE":
        _bad("Late shift window wrong")
        return
    print("DRAG MINI OFFICIAL ART + SHIFT PASS: original image hashes, menu hotspots, shifting verdicts")
    quit(0)
