extends SceneTree
## Adversarial model and state sanity checks. Engine parser will validate all scripts.

const State = preload("res://scripts/game_state.gd")
const Main = preload("res://scenes/main.tscn")
var failures: Array[String] = []

func assert_that(cond: bool, message: String) -> void:
    if not cond:
        failures.append(message)
        push_error("GAUNTLET FAILED: "+message)
    else:
        print("PASS: "+message)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var s = State.new()
    assert_that(s.coins == 250,"initial wallet")
    assert_that(not s.build_stage(),"stage locked before 50 fans")
    assert_that(s.coins == 250,"failed stage purchase does not spend money")
    var test_beats: Array[int] = [0,2,1,3,1,0,3,2]
    var earned: Dictionary = s.publish_track(test_beats)
    assert_that(s.records == 1,"record publishes")
    assert_that(s.fans >= 20 and earned["fans"] > 0,"music unlocks fans")
    var first_business_cost := 120
    var previous_coins: int = s.coins
    assert_that(s.open_shop(),"buy first business")
    assert_that(s.coins == previous_coins - first_business_cost,"one-time business cost")
    assert_that(s.businesses == 1,"business persists")
    var crop: Dictionary = s.harvest()
    assert_that(crop["ok"],"farm produces a real reward")
    assert_that(not s.harvest()["ok"],"farm exploit cooldown enforced")
    s.companion_bond = 29
    assert_that(not s.evolve_pet(),"pet cannot evolve before bonding")
    s.companion_bond = 30
    assert_that(s.evolve_pet() and s.companion == "LUMEN","pet evolution changes species")
    assert_that(Main != null,"native scene parses")
    var loaded_world: Node3D = Main.instantiate()
    assert_that(loaded_world != null,"real 3D world instantiates")
    assert_that(ResourceLoader.exists("res://assets/la_caldera_records.glb"),"custom La Caldera Records Blender GLB imports")
    assert_that(ResourceLoader.exists("res://assets/artist_avatar.glb"),"original Blender artist character imports")
    assert_that(ResourceLoader.exists("res://assets/companion_nova.glb"),"original Blender companion imports")
    assert_that(ResourceLoader.exists("res://assets/moon_market.glb"),"custom market model imports")
    loaded_world.free()
    if failures.is_empty():
        print("GAUNTLET GREEN — 18 core checks")
        quit(0)
    else:
        print("GAUNTLET RED — ",failures)
        quit(1)
