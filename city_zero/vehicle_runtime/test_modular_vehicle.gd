extends SceneTree
## Synthetic headless test. No vehicle meshes / proprietary assets required.

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var vehicle_script = load("res://city_zero/vehicle_runtime/CityZeroModularVehicle.gd")
    if vehicle_script == null:
        push_error("Vehicle runtime script failed to load")
        quit(1)
        return

    var car: Node3D = vehicle_script.new()
    car.name = "SyntheticCar"
    var hood := Node3D.new()
    hood.name = "HoodPivot"
    car.add_child(hood)
    var trunk := Node3D.new()
    trunk.name = "TrunkPivot"
    car.add_child(trunk)
    var body_mount := Node3D.new()
    body_mount.name = "BodyMount"
    car.add_child(body_mount)
    var stock := Node3D.new()
    stock.name = "OriginalPart"
    body_mount.add_child(stock)
    var speaker_mount := Node3D.new()
    speaker_mount.name = "AudioMount"
    car.add_child(speaker_mount)

    car.hood_pivot = NodePath("HoodPivot")
    car.trunk_pivot = NodePath("TrunkPivot")
    car.hood_open_delta = Vector3(-60.0, 0.0, 0.0)
    car.trunk_open_delta = Vector3(55.0, 0.0, 0.0)
    car.visual_mounts = {"hood": NodePath("BodyMount")}
    car.speaker_mounts = [NodePath("AudioMount")]

    get_root().add_child(car)
    await process_frame

    if not car.set_panel_open("hood", true, true) or not car.is_panel_open("hood"):
        push_error("Hood did not open")
        quit(1)
        return
    if absf(hood.rotation_degrees.x + 60.0) > 0.01:
        push_error("Hood hinge rotation incorrect")
        quit(1)
        return
    if not car.set_panel_open("trunk", true, true):
        push_error("Trunk did not open")
        quit(1)
        return

    var sample := Node3D.new()
    var packed := PackedScene.new()
    if packed.pack(sample) != OK:
        push_error("Could not pack synthetic part")
        quit(1)
        return
    sample.free()

    if not car.install_visual_part("hood", "test_hood_1", packed) or stock.visible:
        push_error("Part replacement failed")
        quit(1)
        return
    if not car.install_speaker(0, "test_speaker_1", packed):
        push_error("Speaker socket failed")
        quit(1)
        return
    var loadout: Dictionary = car.get_visual_loadout()
    if loadout["parts"]["hood"] != "test_hood_1" or loadout["speakers"][0] != "test_speaker_1":
        push_error("Loadout tracking incorrect")
        quit(1)
        return
    if not car.restore_stock_visual("hood") or not stock.visible:
        push_error("Stock restore failed")
        quit(1)
        return
    if car.install_speaker(12, "invalid", packed):
        push_error("Out-of-range audio socket improperly accepted")
        quit(1)
        return
    print("CITY_ZERO_MODULAR_VEHICLE_SMOKE_OK")
    quit(0)
