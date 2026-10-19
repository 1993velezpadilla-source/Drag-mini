extends SceneTree

func _initialize() -> void:
    call_deferred("_run_smoke")

func _fail(message: String) -> void:
    printerr("DRAG MINI SMOKE FAIL: " + message)
    quit(1)

func _run_smoke() -> void:
    var scene := load("res://scenes/main.tscn") as PackedScene
    if scene == null:
        _fail("main scene not found")
        return
    for car_name in ["civic_hatch_game", "supra_mk4_game", "del_sol_game", "trueno_ae86_game"]:
        if not ResourceLoader.exists("res://assets/cars/%s.png" % car_name):
            _fail("sprite missing: " + car_name)
            return
    var game := scene.instantiate()
    if game == null:
        _fail("main scene instantiate failed")
        return
    root.add_child(game)
    if game.images.size() != 4 or game.visual_cars.size() != 4:
        _fail("could not prepare all 4 sprites / wheel layers")
        return
    for car_id in range(4):
        var car: Dictionary = game.visual_cars[car_id]
        if not car.has("body") or not car.has("wheel") or not car.has("front") or not car.has("rear"):
            _fail("car %d has incomplete front/rear wheel layers" % car_id)
            return
        if car["wheel"].get_width() < 20:
            _fail("car %d has no proper wheel texture" % car_id)
            return
        # Certify EVERY car, not only the selected Civic and the CPU Supra.
        var driver: Dictionary = game._make_driver(car_id)
        game._advance_car(driver, 0.08, true, true)
        if float(driver["speed"]) <= 0.0 or float(driver["wheel_angle"]) <= 0.0:
            _fail("car %d did not advance tire angle under throttle" % car_id)
            return
    game._start_race()
    if game.screen != "race":
        _fail("race start failed")
        return
    # GAS can rev during the tree, but cannot move until GO.
    game._on_gas_down()
    game._process(0.5)
    if game.false_start or float(game.player["speed"]) != 0.0 or game.launch_rpm <= 1050.0:
        _fail("staging revs must be legal and stationary")
        return
    # LAUNCH is the clutch release: releasing before GO is a red light.
    game._player_shift()
    if not game.false_start:
        _fail("premature clutch release must disqualify")
        return
    game._start_race()
    game._on_gas_down()
    for i in range(145):
        game._process(1.0 / 30.0)
    if game.false_start or game.countdown > 0.0:
        _fail("legal launch was blocked")
        return
    if float(game.player["speed"]) <= 0.0 or float(game.player["wheel_angle"]) <= 0.0:
        _fail("player wheels did not move with acceleration")
        return
    if float(game.rival["wheel_angle"]) <= 0.0:
        _fail("CPU car wheels did not move")
        return
    var initial_gear: int = int(game.player["gear"])
    game._player_shift()
    if int(game.player["gear"]) != initial_gear + 1 or not game.throttle_held:
        _fail("power shift must increase gear while GAS stays held")
        return
    game._show_garage()
    if game.screen != "garage":
        _fail("garage return failed")
        return
    print("DRAG MINI SMOKE: PASS (4 independent wheel layers, speed-coupled tire animation, race, garage)")
    quit(0)
