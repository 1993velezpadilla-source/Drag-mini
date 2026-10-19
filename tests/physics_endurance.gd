extends SceneTree
## Long-form physics critic: actually finish each distance with real car dynamics,
## not just checking that four menu labels exist.
func _initialize() -> void:
    call_deferred("_run")

func _error(message: String) -> void:
    printerr("DRAG MINI ENDURANCE FAIL: " + message)
    quit(1)

func _run() -> void:
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.auto_shift = true
    for i in range(4):
        game.career_race = false
        game.race_distance_m = float(game.Progression.DISTANCES[i])
        game._start_race()
        game.auto_shift = true
        game.countdown = 0.0
        game.countdown_label.text = "GO!"
        game.throttle_held = true
        var max_ticks: int = 24000
        var prev_m: float = 0.0
        var reached: bool = false
        for step in range(max_ticks):
            game._process(1.0 / 30.0)
            if float(game.player["distance"]) + 0.0001 < prev_m:
                _error("distance moved backwards in race %d" % i)
                return
            prev_m = float(game.player["distance"])
            if game.player["finished"] and game.rival["finished"]:
                reached = true
                break
        if not reached:
            _error("cannot finish real-world race length %.3fm after %.0fs simulated" % [game.race_distance_m, float(max_ticks) / 30.0])
            return
        if not game.race_paid:
            _error("race completed without rewards and results")
            return
        if absf(float(game.player["distance"]) - game.race_distance_m) > 0.001:
            _error("player finish line improperly clamped for race length %d" % i)
            return
        if float(game.player["finish_time"]) < 3.0 or float(game.rival["finish_time"]) < 3.0:
            _error("unrealistic instant-finishing drag race")
            return
        print("ENDURANCE %s PASS: player %.2fs / CPU %.2fs" % [
            game._distance_name(game.race_distance_m),
            float(game.player["finish_time"]), float(game.rival["finish_time"])])
    print("DRAG MINI ENDURANCE PASS: all four distances finish with CPU, finish line, telemetry and payout")
    quit(0)
