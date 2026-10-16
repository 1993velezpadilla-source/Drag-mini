extends SceneTree

func _initialize() -> void:
    var scene := load("res://scenes/main.tscn") as PackedScene
    assert(scene != null, "Main scene missing")
    for car_name in ["civic_hatch_game", "supra_mk4_game", "del_sol_game", "trueno_ae86_game"]:
        assert(ResourceLoader.exists("res://assets/cars/%s.png" % car_name), "Missing PNG: " + car_name)
    var game := scene.instantiate()
    assert(game != null, "Cannot instantiate main scene")
    root.add_child(game)
    assert(game.images.size() == 4, "Car sprites not imported")
    game._start_race()
    assert(game.screen == "race", "Race did not start")
    game._process(1.0 / 60.0)
    game._show_garage()
    assert(game.screen == "garage", "Cannot return to garage")
    print("DRAG MINI SMOKE: PASS (startup, 4 sprites, race, garage)")
    quit(0)
