extends SceneTree
## Test true hinge transforms AFTER glTF has been imported by Godot.
## Opening/closing must move child geometry, not merely toggle a variable.
const DoorController = preload("res://scripts/vehicle_door_controller.gd")
var failed: Array[String] = []

func check(ok: bool, label: String) -> void:
    if not ok:
        failed.append(label)
        push_error("DOOR GAUNTLET RED: " + label)
    else:
        print("DOOR PASS: " + label)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var cars := [
        {"id":"exotic_supercar__revulse", "doors":2},
        {"id":"compact_sedan__compact_c", "doors":4},
        {"id":"basic_pickup__workhorse", "doors":4},
        {"id":"electric_future__cyber_wedge", "doors":4}
    ]
    for rec in cars:
        var path: String = "res://assets/premium_fleet/" + str(rec["id"]) + ".glb"
        check(ResourceLoader.exists(path), "Actual GLB imported: " + path)
        if not ResourceLoader.exists(path):
            continue
        var packed: PackedScene = load(path)
        check(packed != null, "PackedScene valid: " + path)
        if packed == null:
            continue
        var car: Node3D = packed.instantiate()
        root.add_child(car)
        var animator = DoorController.new()
        car.add_child(animator)
        await process_frame
        var door_names: Array[String] = animator.available_doors()
        check(door_names.size() == int(rec["doors"]), str(rec["id"]) + " has true hinge count")
        for door_name in door_names:
            var hinge: Node3D = animator.hinges[door_name]
            var mesh_found := false
            var movable: MeshInstance3D = null
            for child in hinge.get_children():
                if child is MeshInstance3D:
                    mesh_found = true
                    if movable == null:
                        movable = child
            check(mesh_found, door_name + " owns a non-fake door mesh")
            if not mesh_found:
                continue
            var start_pos: Vector3 = movable.global_position
            var closed_rotation: Quaternion = hinge.quaternion
            check(animator.toggle_door(door_name), door_name + " can be opened")
            animator._process(0.70)
            await process_frame
            check(animator.is_door_open(door_name), door_name + " reports open")
            check(hinge.quaternion.angle_to(closed_rotation) > 0.18, door_name + " rotates relative to original closed glTF quaternion")
            check(movable.global_position.distance_to(start_pos) > 0.05, door_name + " moves its actual mesh")
            check(animator.toggle_door(door_name), door_name + " can be closed")
            # Headless CI can run frames much faster than 60 FPS. Waiting for
            # 65 process_frame signals does NOT mean 65/60 seconds elapsed.
            # Advance the controller with fixed simulation deltas instead,
            # and verify the actual hinge settled before comparing transforms.
            for i in range(90):
                animator._process(1.0 / 60.0)
            await process_frame
            check(not animator.is_door_open(door_name), door_name + " reports shut")
            check(absf(float(animator.current_angle[door_name])) < 0.001,
                door_name + " physically reaches the exact closed angle")
            check(hinge.quaternion.angle_to(closed_rotation) < 0.035, door_name + " returns exactly to original imported closed quaternion")
            check(movable.global_position.distance_to(start_pos) < 0.07, door_name + " restores door mesh to its original world position")
        car.queue_free()
        await process_frame
    if failed.is_empty():
        print("REAL GODOT DOOR KINEMATICS GAUNTLET GREEN")
        quit(0)
    else:
        print("DOOR GAUNTLET FAILED: ", failed)
        quit(1)
