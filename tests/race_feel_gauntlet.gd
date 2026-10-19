extends SceneTree
## Adversarial race feel: tap-to-launch is a real skill check, not an idle auto-scroller.
func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    printerr("DRAG MINI RACE FEEL FAIL: " + message)
    quit(1)

func _run() -> void:
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.auto_shift = false
    game._start_race()
    game.countdown = 0.0
    game.throttle_held = true
    game.launch_rpm = 4000.0
    for i in range(12):
        game._process(1.0 / 30.0)
    if game.launched or float(game.player["distance"]) != 0.0:
        _fail("manual clutch auto-launched before pressing LAUNCH")
        return
    if float(game.rival["distance"]) <= 0.0 or game.reaction_seconds < 0.2:
        _fail("Rival doesn't move while player waits on green")
        return
    game._player_shift()
    if not game.launched or int(game.player["gear"]) != 0:
        _fail("Green LAUNCH incorrectly upshifted or didn't engage")
        return
    if game.player["launch_force"] <= 1.0 or game.skill_points < 90:
        _fail("Staging RPM/launch timing didn't affect the race")
        return
    var fuel_score: int = game.skill_points
    game.player["rpm"] = float(game.CARS[game.selected]["redline"]) * 0.92
    game._player_shift()
    if game.shift_feedback != "PERFECT" or game.skill_points <= fuel_score or game.shift_combo != 1:
        _fail("Perfect gear shift failed to award bonus")
        return
    game.player["shift_timer"] = 0.0
    game.player["rpm"] = float(game.CARS[game.selected]["redline"]) * 0.92
    game._player_shift()
    if game.shift_combo != 2 or not game.shift_feedback_label.visible:
        _fail("Perfect shift combo not building from consecutive skill")
        return
    game.player["shift_timer"] = 0.0
    game.player["rpm"] = float(game.CARS[game.selected]["redline"]) * 0.40
    game._player_shift()
    if game.shift_combo != 0 or game.shift_feedback != "EARLY":
        _fail("Early shift did not break combo")
        return
    var previous_power := float(game.player["launch_force"])
    game._start_race()
    game.countdown = 0.0
    game.reaction_seconds = 1.5
    game.launch_rpm = 7200.0
    game._player_shift()
    if not game.launched or float(game.player["launch_force"]) >= previous_power:
        _fail("Bad clutch timing must be measurably worse than tuned launch")
        return
    game.auto_shift = true
    game._start_race()
    game.countdown = 0.01
    game._process(0.03)
    if not game.launched or not game.auto_shift:
        _fail("Automatic shift mode should still launch at green")
        return
    game.progress.audio_enabled = false
    game._menu_action("settings")
    if game._state()["audio"]:
        _fail("Engine sound switch did not change state")
        return
    print("DRAG MINI RACE FEEL PASS: reaction timing, clutch, perfect combos, penalty, auto mode, sound control")
    quit(0)
