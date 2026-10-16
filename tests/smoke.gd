extends SceneTree

func _initialize() -> void:
    var scene := load("res://scenes/main.tscn")
    assert(scene != null, "Main scene missing")
    for path in ["civic_hatch_game", "supra_mk4_game", "del_sol_game", "trueno_ae86_game"]:
        assert(ResourceLoader.exists("res://assets/cars/%s.png" % path), "Missing PNG: " + path)
    print("DRAG MINI SMOKE: PASS (scene + four PNG sprites)")
    quit(0)
