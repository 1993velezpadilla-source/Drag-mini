extends SceneTree

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    if not ResourceLoader.exists("res://scripts/wallpaper_bridge.gd"):
        printerr("Missing wallpaper bridge")
        quit(1)
        return
    if not ResourceLoader.exists("res://addons/Android/LiveWallpaper/LiveWallpaper.gd"):
        printerr("Upstream plugin was not installed")
        quit(1)
        return
    var bridge = load("res://scripts/wallpaper_bridge.gd").new()
    root.add_child(bridge)
    if bridge.is_wallpaper:
        printerr("Wrong wallpaper detection in desktop CI")
        quit(1)
        return
    if bridge.start_live_wallpaper():
        printerr("Desktop unexpectedly started Android wallpaper")
        quit(1)
        return
    var scene := load("res://scenes/main.tscn") as PackedScene
    if scene == null:
        printerr("Cannot load game scene")
        quit(1)
        return
    var game = scene.instantiate()
    root.add_child(game)
    if game.wallpaper_mode or game.images.size() != 4:
        printerr("Unexpected default wallpaper mode or missing cars")
        quit(1)
        return
    game._enter_wallpaper_mode()
    if not game.wallpaper_mode:
        printerr("Failed to enter wallpaper presentation mode")
        quit(1)
        return
    print("DRAG MINI: TheOathMan plugin smoke PASS (desktop safeguards + wallpaper rendering)")
    quit(0)
