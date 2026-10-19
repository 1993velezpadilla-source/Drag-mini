extends SceneTree
## Master Orchestrator + Adversarial Critic: every menu action, mechanic,
## transaction, settings save and race length must produce an observable effect.
func _initialize() -> void:
    call_deferred("_run")

func fail_test(msg: String) -> void:
    printerr("DRAG MINI CRITIC FAIL: " + msg)
    quit(1)

func _run() -> void:
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    if game.size.y <= game.size.x:
        fail_test("Portrait viewport is not taller than wide")
        return
    if game.screen != "menu" or game.menu_overlay == null or not game.menu_overlay.visible:
        fail_test("Startup menu did not appear")
        return
    # Regress the user's original bug: every main-menu button used to start a race.
    # Press the actual Button signal, not merely the controller's route method.
    var main_buttons := {
        "RACE":"race_select", "CAREER":"career", "GARAGE":"garage",
        "UPGRADES":"upgrades", "WALLPAPER":"wallpaper", "SETTINGS":"settings"
    }
    for title in main_buttons.keys():
        game._show_main_menu()
        var tapped := false
        for widget in game.menu_overlay.get_children():
            if widget is Button and widget.visible and widget.text == title:
                if widget.get_global_rect().size.x < 35.0 or widget.get_global_rect().size.y < 32.0:
                    fail_test("Main screen " + title + " has a too-small tap zone")
                    return
                widget.pressed.emit()
                tapped = true
                break
        if not tapped or game.screen != main_buttons[title]:
            fail_test("Button " + title + " was missing or incorrectly routed to race")
            return
    game._show_main_menu()
    var quick_start := false
    for widget in game.menu_overlay.get_children():
        if widget is Button and widget.visible and widget.text.contains("QUICK START"):
            widget.pressed.emit()
            quick_start = true
            break
    if not quick_start or game.screen != "race":
        fail_test("Quick START must be the ONLY home shortcut that immediately launches a race")
        return
    game._show_main_menu()
    var all_views := ["race_select", "garage", "upgrades", "settings", "career", "wallpaper"]
    for page in all_views:
        game._menu_action(page)
        if game.screen != page or game.menu_overlay.section != page:
            fail_test("Menu action " + page + " was routed incorrectly")
            return
        if game.menu_overlay.get_child_count() < 4:
            fail_test(page + " has no usable interactive controls")
            return
    game._menu_action("menu")
    if game.menu_overlay._car_parts.size() != 4:
        fail_test("Cut-out chassis and independent wheels not rebuilt for four cars")
        return
    var initial: int = int(game.selected)
    game._menu_action("garage")
    game._menu_action("car_next")
    if game.selected == initial or game.progress.selected != game.selected:
        fail_test("Garage carousel cannot change selected vehicle")
        return
    var saved_money: int = int(game.progress.cash)
    var before: int = int(game.progress.level(game.selected, "engine"))
    game._menu_action("upgrade:engine")
    if game.progress.level(game.selected, "engine") != before + 1 or game.progress.cash >= saved_money:
        fail_test("Upgrade purchase did not debit credits and install a part")
        return
    game._menu_action("settings")
    var old_auto: bool = game.auto_shift
    game._menu_action("toggle_shift")
    if game.auto_shift == old_auto or game.progress.auto_shift != game.auto_shift:
        fail_test("Shift settings don't work")
        return
    game._menu_action("toggle_shift")
    game._menu_action("toggle_units")
    if game.progress.show_kmh:
        fail_test("KM/H to MPH setting didn't change")
        return
    game._menu_action("toggle_units")
    game._menu_action("toggle_time")
    if game.progress.dynamic_time:
        fail_test("Time of day toggle didn't change")
        return
    game._menu_action("toggle_time")
    for idx in range(4):
        game._menu_action("distance:" + str(idx))
        if game.progress.distance_choice != idx:
            fail_test("Race length %d not selected" % idx)
            return
        game._menu_action("start")
        if game.screen != "race" or game.race_distance_m != float(game.Progression.DISTANCES[idx]):
            fail_test("Race distance %d incorrectly launched" % idx)
            return
        if game.get("track_image") != null:
            fail_test("Track JPEG dependency must be absent")
            return
    game._menu_action("career_start")
    if not game.career_race or game.race_distance_m != float(game.Progression.STORY[game.progress.stage]["distance"]):
        fail_test("Story stage distance is not applied")
        return
    var cpu: Dictionary = game._make_driver((game.selected + 1) % 4)
    var player: Dictionary = game._make_driver(game.selected)
    game._advance_car(cpu, 0.12, true, true)
    game._advance_car(player, 0.12, true, true)
    if float(player["speed"]) <= 0.0 or float(cpu["speed"]) <= 0.0:
        fail_test("Upgrade-driven physics is stalled")
        return
    if game.progress.level(game.selected, "nitrous") == 0:
        game.progress.cash = 99999
        game.progress.purchase(game.selected, "nitrous")
    game._start_race()
    game.countdown = 0.0
    game._activate_nitrous()
    if float(game.player["nitrous_active"]) <= 0.0:
        fail_test("Nitrous purchase can't be activated")
        return
    if game.progress._levels(game.selected)["engine"] == 0:
        fail_test("Installed upgrades lost after changing screens")
        return
    var race_cash: int = int(game.progress.cash)
    game.player["finished"] = true
    game.rival["finished"] = true
    game.player["finish_time"] = 12.3
    game.rival["finish_time"] = 15.5
    game._end_race()
    if not game.race_paid or game.progress.cash <= race_cash:
        fail_test("Race reward wasn't added to player's save")
        return
    var after_cash: int = int(game.progress.cash)
    game._end_race()
    if game.progress.cash != after_cash:
        fail_test("Exploit: duplicate rewards by calling result twice")
        return
    var stage := int(game.progress.stage)
    if stage < 1:
        fail_test("Career didn't progress after winning")
        return
    game._menu_action("wallpaper_preview")
    if not game.wallpaper_mode or game.screen != "wallpaper_preview":
        fail_test("Wallpaper preview failed to render")
        return
    game._show_main_menu()
    if game.wallpaper_mode or game.screen != "menu":
        fail_test("Can't leave wallpaper preview")
        return
    game.progress.save_game()
    var Reloaded = load("res://scripts/progression.gd")
    var loaded = Reloaded.new()
    loaded.load_game()
    if loaded.cash != game.progress.cash or loaded.stage != game.progress.stage:
        fail_test("Persistent offline career save/reload failed")
        return
    print("DRAG MINI GAUNTLET PASS: portrait/menu routing, 4 race lengths, upgrades, economy, settings, story, nitrous, wallpaper preview, save")
    quit(0)
