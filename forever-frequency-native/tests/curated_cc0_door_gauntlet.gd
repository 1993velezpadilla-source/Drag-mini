extends SceneTree
## Gate for real, downloaded CC0 source geometry AFTER genuine Godot glTF import.
## No dummy door meshes, no screenshot-only or variable-only acceptance.
const Controller = preload("res://scripts/vehicle_door_controller.gd")
var failures: Array[String] = []

func report(ok: bool, label: String) -> void:
    if ok:
        print("REAL CC0 DOOR PASS: " + label)
    else:
        failures.append(label)
        push_error("REAL CC0 DOOR FAIL: " + label)

func find_actual_mesh(node: Node) -> MeshInstance3D:
    if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
        return node as MeshInstance3D
    for child in node.get_children():
        var found: MeshInstance3D = find_actual_mesh(child)
        if found != null:
            return found
    return null

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var models := [
        {"id": "curated_family_sedan", "doors": 4},
        {"id": "curated_midengine_supercar", "doors": 2}
    ]
    for rec in models:
        var path: String = "res://assets/curated_rigged/" + str(rec["id"]) + ".glb"
        report(ResourceLoader.exists(path), "Godot imported original CC0 source " + path)
        if not ResourceLoader.exists(path):
            continue
        var packed: PackedScene = load(path)
        report(packed != null, "Actual GLB PackedScene valid " + path)
        if packed == null:
            continue
        var car: Node3D = packed.instantiate()
        root.add_child(car)
        var animator = Controller.new()
        car.add_child(animator)
        await process_frame
        var doors: Array[String] = animator.available_doors()
        report(doors.size() == int(rec["doors"]), str(rec["id"]) + " full physical hinge count")
        for door_name in doors:
            var hinge: Node3D = animator.hinges[door_name]
            var movable: MeshInstance3D = find_actual_mesh(hinge)
            report(movable != null, door_name + " has genuine source geometry")
            if movable == null:
                continue
            var sample: Vector3 = movable.mesh.get_aabb().end
            var before: Vector3 = movable.to_global(sample)
            var closed: Quaternion = hinge.quaternion
            report(animator.toggle_door(door_name), door_name + " opens")
            for i in range(95):
                animator._process(1.0 / 60.0)
            await process_frame
            report(animator.is_door_open(door_name), door_name + " reports open")
            report(hinge.quaternion.angle_to(closed) > 0.18, door_name + " rotates real glTF hinge")
            report(movable.to_global(sample).distance_to(before) > 0.07,
                door_name + " moves imported source mesh")
            report(animator.toggle_door(door_name), door_name + " closes")
            for i in range(95):
                animator._process(1.0 / 60.0)
            await process_frame
            report(not animator.is_door_open(door_name), door_name + " closes state")
            report(hinge.quaternion.angle_to(closed) < 0.025,
                door_name + " returns to original local orientation")
            report(movable.to_global(sample).distance_to(before) < 0.035,
                door_name + " returns actual source mesh to its starting position")
        car.queue_free()
        await process_frame
    if failures.is_empty():
        print("REAL CC0 CARS BLENDER RIG + GODOT KINEMATICS GREEN")
        quit(0)
    else:
        print("REAL CC0 CAR GAUNTLET FAILED: ", failures)
        quit(1)
