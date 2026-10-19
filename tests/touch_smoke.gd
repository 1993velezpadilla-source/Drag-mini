extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    printerr("DRAG MINI TOUCH FAIL: " + reason)
    quit(1)

func _run() -> void:
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.auto_shift = false
    game._start_race()
    if game.countdown <= 3.0 or game.countdown_label.text != "READY":
        _fail("READY or countdown absent")
        return
    var gas: Vector2 = game.throttle_button.get_global_rect().get_center()
    var shift: Vector2 = game.shift_button.get_global_rect().get_center()
    game._route_touch(7, gas, true)
    for i in range(15):
        game._process(0.05)
    if not game.throttle_held or game.false_start or float(game.player["rpm"]) <= 1050.0:
        _fail("holding GAS during staging should rev legally")
        return
    if float(game.player["distance"]) != 0.0:
        _fail("moving before GO")
        return
    game._route_touch(8, shift, true)
    if not game.false_start:
        _fail("LAUNCH before GO must be a DQ")
        return
    game._start_race()
    gas = game.throttle_button.get_global_rect().get_center()
    game._route_touch(7, gas, true)
    for i in range(85):
        game._process(0.05)
    if game.countdown > 0.0 or game.false_start:
        _fail("GO should release the car")
        return
    if game.launched or float(game.player["distance"]) != 0.0:
        _fail("Clutch launched automatically before manual LAUNCH tap")
        return
    shift = game.shift_button.get_global_rect().get_center()
    game._route_touch(8, shift, true)
    if not game.launched or int(game.player["gear"]) != 0:
        _fail("LAUNCH must engage first gear on second finger")
        return
    game._route_touch(8, shift, false)
    for i in range(20):
        game._process(0.05)
    if float(game.player["distance"]) <= 0.0 or not game.throttle_held:
        _fail("post-green acceleration broken")
        return
    shift = game.shift_button.get_global_rect().get_center()
    var old_gear: int = int(game.player["gear"])
    game._route_touch(8, shift, true)
    if int(game.player["gear"]) != old_gear + 1:
        _fail("second finger did not shift")
        return
    game._route_touch(8, shift, false)
    if not game.throttle_held or game.gas_finger != 7:
        _fail("SHIFT released GAS held by the other finger")
        return
    game._route_touch(7, gas, false)
    if game.throttle_held:
        _fail("GAS not released with original finger")
        return
    print("DRAG MINI TOUCH PASS: staging, DQ, GO, independent GAS+SHIFT fingers")
    quit(0)
