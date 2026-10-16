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
    if game.images.size() != 4:
        _fail("could not import all 4 sprites")
        return
    game._start_race()
    if game.screen != "race":
        _fail("race start failed")
        return
    game._process(1.0 / 60.0)
    game._show_garage()
    if game.screen != "garage":
        _fail("garage return failed")
        return
    print("DRAG MINI SMOKE: PASS (start, sprites, race, garage)")
    quit(0)
