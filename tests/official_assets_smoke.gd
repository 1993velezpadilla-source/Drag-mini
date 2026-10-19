extends SceneTree
## 4 separate pixel-art vehicles, single shift light and C++ authored scenery.
func _initialize() -> void:
    call_deferred("_run")

func bad(msg: String) -> void:
    printerr("DRAG MINI PORTRAIT FAIL: " + msg)
    quit(1)

func _run() -> void:
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    if game.get_node_or_null("StartupFallback/OriginalMainMenu") != null:
        bad("Static photo is incorrectly used as the main menu")
        return
    if game.menu_overlay.get_script().resource_path != "res://scripts/portrait_shell.gd":
        bad("Portrait UI not active")
        return
    if game.menu_overlay._cars.size() != 4 or game.menu_overlay._car_parts.size() != 4:
        bad("Four native-layered car silhouettes/wheels are missing")
        return
    for i in range(4):
        if game.menu_overlay._cars[i] == null:
            bad("Missing independent car texture: " + str(i))
            return
    var f := FileAccess.get_file_as_string("res://assets/tracks/track_geometry.json")
    var world = JSON.parse_string(f)
    if not world is Dictionary or int(world.get("length_m", 0)) < 1610:
        bad("C++ authored mile-long world is missing")
        return
    game._menu_action("start")
    if game.screen != "race":
        bad("Quick START did not launch race")
        return
    game.countdown = 0.0
    game.auto_shift = false
    game.throttle_held = true
    game._launch_car()
    game.player["rpm"] = float(game.CARS[game.selected]["redline"]) * 0.90
    game.player["shift_timer"] = 0.0
    game._player_shift()
    if game.shift_feedback != "PERFECT" or not game.shift_feedback_label.visible:
        bad("Perfect shift only appears on a tap")
        return
    game._process(1.0)
    if game.shift_feedback_label.visible:
        bad("Shift feedback didn't auto-hide")
        return
    game.player["shift_timer"] = 0.0
    game.player["rpm"] = float(game.CARS[game.selected]["redline"]) * 0.5
    game._player_shift()
    if game.shift_feedback != "EARLY":
        bad("Premature shift incorrectly classified")
        return
    game.player["shift_timer"] = 0.0
    game.player["rpm"] = float(game.CARS[game.selected]["redline"]) * 0.99
    game._player_shift()
    if game.shift_feedback != "LATE":
        bad("Over-rev shift incorrectly classified")
        return
    print("DRAG MINI PORTRAIT + SHIFT PASS: four car layers, C++ world, one shift indicator, 3 timing verdicts")
    quit(0)
