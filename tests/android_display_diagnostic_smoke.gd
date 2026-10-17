extends SceneTree
## Headless structure gate. Actual Android screen MUST still be checked on phone.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene := load("res://scenes/android_diagnostic.tscn") as PackedScene
    if scene == null:
        printerr("DIAG FAIL: no independent Android boot scene")
        quit(1)
        return
    var root_node := scene.instantiate() as Control
    root.add_child(root_node)
    var pink := root_node.get_node_or_null("NeonPinkFrame") as ColorRect
    var photo := root_node.get_node_or_null("OfficialMenuPhoto") as TextureRect
    var title := root_node.get_node_or_null("DiagnosticHeading") as Label
    var open_game := root_node.get_node_or_null("DiagnosticAction") as Button
    if pink == null or pink.color.r < 0.9 or photo == null or photo.texture == null:
        printerr("DIAG FAIL: vivid startup frame and real menu photo missing")
        quit(1)
        return
    if title == null or not title.text.contains("0.6") or open_game == null:
        printerr("DIAG FAIL: unique build title/button missing")
        quit(1)
        return
    print("DRAG MINI DIAG PASS: isolated magenta Android first frame, original menu photo, launch button")
    quit(0)
