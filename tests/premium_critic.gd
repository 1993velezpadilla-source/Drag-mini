extends SceneTree
## Master + adversarial critic: the upgrade menu cannot lie about physics.
## Also certifies Godot 4.6 Java JNI method discovery fix.
class FakeJNI:
    extends RefCounted
    func has_java_method(name: String) -> bool:
        return name == "openWallpaperPicker"

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    printerr("DRAG MINI PREMIUM CRITIC FAIL: " + reason)
    quit(1)

func _run() -> void:
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    var native = load("res://scripts/wallpaper_bridge.gd")
    if not native._java_method_exists(FakeJNI.new(), "openWallpaperPicker"):
        _fail("Broken plugin probe: must call JNISingleton.has_java_method")
        return
    if native._java_method_exists(FakeJNI.new(), "unrelated"):
        _fail("Fake Java method incorrectly detected")
        return
    var old: float = float(game.progress.tune(game.selected)["final_drive"])
    var home_action = "tune"
    game._menu_action(home_action)
    if game.screen != "tune" or game.menu_overlay.section != "tune":
        _fail("TUNE screen missing from UI router")
        return
    if not game.menu_overlay.get_children().any(func(x): return x is Button and x.text == "+"):
        _fail("Tune plus/minus buttons aren't interactable")
        return
    game._menu_action("tune:final_drive:1")
    var now: float = float(game.progress.tune(game.selected)["final_drive"])
    if now <= old:
        _fail("Gear-ratio setting didn't change")
        return
    var driver: Dictionary = game._make_driver(game.selected)
    if not is_equal_approx(float(driver["tuning"]["final_drive"]), now):
        _fail("Car engine ignores saved gearing")
        return
    var steady := driver.duplicate(true)
    steady["speed"] = 20.0
    steady["gear"] = 2
    var original := steady.duplicate(true)
    original["tuning"] = original["tuning"].duplicate(true)
    original["tuning"]["final_drive"] = old
    game._advance_car(steady, 0.01, true, false)
    game._advance_car(original, 0.01, true, false)
    if float(steady["rpm"]) <= float(original["rpm"]):
        _fail("Final drive isn't applied to wheel/RPM calculation")
        return
    game._menu_action("tune:final_drive:-1")
    game._menu_action("tune:shift_target:1")
    game._menu_action("tune:tire_pressure:-1")
    game._menu_action("tune:launch_rpm:1")
    var state := game._state()
    var t: Dictionary = state["tune"]
    if float(t["shift_target"]) <= 0.91 or float(t["tire_pressure"]) >= 28.0 or float(t["launch_rpm"]) <= 4000.0:
        _fail("Advanced tuning not saved/reflected in UI")
        return
    game.progress.tune_adjust(game.selected, "launch_rpm", -1)
    game.progress.tune_adjust(game.selected, "shift_target", -1)
    game.progress.tune_adjust(game.selected, "tire_pressure", 1)
    # Free tuning cannot be used to mint currency.
    var before_money: int = int(game.progress.cash)
    for n in range(25):
        game.progress.tune_adjust(game.selected, "final_drive", 1)
    if int(game.progress.cash) != before_money:
        _fail("Tuning accidentally changed in-game economy")
        return
    for n in range(25):
        game.progress.tune_adjust(game.selected, "final_drive", -1)
    # Frame pacing comparison: 30fps and 120fps must move same distance.
    var thirty := game._make_driver(game.selected)
    var onetwenty := game._make_driver(game.selected)
    for i in range(300):
        for subframe in range(4):
            game._advance_car(onetwenty, 1.0/120.0, true, true)
        game._advance_car(thirty, 1.0/30.0, true, true)
    if absf(float(thirty["distance"]) - float(onetwenty["distance"])) > 3.0:
        _fail("Physics is excessively frame-rate dependent")
        return
    print("DRAG MINI PREMIUM CRITIC PASS: JNI has_java_method, independent real tuning, price safety, 30/120Hz physics")
    quit(0)
