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
    for car in game.visual_cars:
        if not car.has("body") or not car.has("wheel") or not car.has("front") or not car.has("rear"):
            _fail("a car lacks animated tire layers")
            return
        if car["wheel"].get_width() < 20:
            _fail("wheel texture missing")
            return
    game._start_race()
    if game.screen != "race":
        _fail("race start failed")
        return
    # The wheels must advance as the car moves (not a static PNG sliding).
    game._process(1.0 / 60.0)
    if float(game.player["speed"]) <= 0.0 or float(game.player["wheel_angle"]) <= 0.0:
        _fail("player wheels did not move with acceleration")
        return
    if float(game.rival["wheel_angle"]) <= 0.0:
        _fail("CPU car wheels did not move")
        return
    game._show_garage()
    if game.screen != "garage":
        _fail("garage return failed")
        return
    print("DRAG MINI SMOKE: PASS (4 independent wheel layers, speed-coupled tire animation, race, garage)")
    quit(0)
