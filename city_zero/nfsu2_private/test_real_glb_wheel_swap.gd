extends SceneTree
## Synthetic geometry only: proves four-wheel aftermarket part installation, no EA media.
## This is a binary GLB import test, not a screenshot of any original NFSU2 car.

func _initialize() -> void:
    call_deferred("_test")

func _export_fixture(path: String, with_wheels: bool) -> bool:
    var root := Node3D.new()
    root.name = "SYNTHETIC_GLTF_FIXTURE"
    if with_wheels:
        for index in range(4):
            var wheel := MeshInstance3D.new()
            wheel.name = "SUPRA_KIT00_WHEEL_A.W%d" % index
            wheel.mesh = BoxMesh.new()
            wheel.position = Vector3(2.0 if index < 2 else -2.0,
                                     0.4, -0.9 if index in [0, 3] else 0.9)
            root.add_child(wheel)
    else:
        var rim := MeshInstance3D.new()
        rim.name = "WHEELS_RIM_01_A"
        var cylinder := CylinderMesh.new()
        cylinder.top_radius = 0.42
        cylinder.bottom_radius = 0.42
        cylinder.height = 0.22
        rim.mesh = cylinder
        root.add_child(rim)
    var gltf := GLTFDocument.new()
    var state := GLTFState.new()
    var start_error := gltf.append_from_scene(root, state)
    if start_error != OK:
        push_error("Cannot author synthetic GLB fixture: %s" % start_error)
        root.free()
        return false
    var write_error := gltf.write_to_filesystem(state, path)
    root.free()
    if write_error != OK:
        push_error("Cannot write synthetic GLB fixture: %s" % write_error)
        return false
    return true

func _test() -> void:
    var root_path := ProjectSettings.globalize_path("user://cityzero_wheel_fixture")
    var models_path := root_path.path_join("local_assets/models")
    DirAccess.make_dir_recursive_absolute(models_path)
    if not _export_fixture(models_path.path_join("test_stock.glb"), true):
        quit(1)
        return
    if not _export_fixture(models_path.path_join("test_wheel.glb"), false):
        quit(1)
        return

    var catalog := {
        "schema": "cityzero.nfsu2.private-godot-library.v1",
        "root": root_path,
        "vehicles": {"SUPRA": {
            "model_assets": {"stock": {"glb": "local_assets/models/test_stock.glb"}, "parts": []},
            "compatible_shared_families": ["WHEELS"],
            "sound_stages": {}
        }},
        "shared_families": {"WHEELS": {
            "parts": [{
                "owner_xname": "WHEELS", "part_key": "WHEELS:00AA0001",
                "part_hash": "00AA0001", "family": "WHEEL",
                "slot": "wheel", "kit": "BASE",
                "mount_space": "wheel_local",
                "glb": "local_assets/models/test_wheel.glb"
            }]
        }}
    }
    var catalog_path := root_path.path_join("cityzero_godot_library.json")
    var file := FileAccess.open(catalog_path, FileAccess.WRITE)
    file.store_string(JSON.stringify(catalog))
    file.close()

    var garage_scene = load("res://city_zero/nfsu2_private/CityZeroNFSU2PrivateGarage.gd")
    if garage_scene == null:
        push_error("Genuine-asset loader failed to compile")
        quit(1)
        return
    var garage: Node3D = garage_scene.new()
    get_root().add_child(garage)
    if not garage.open_library(catalog_path) or not garage.open_car("SUPRA"):
        push_error("Cannot load test fixtures through real GLB import path")
        quit(1)
        return
    if garage._stock_wheel_nodes.size() != 4:
        push_error("Genuine wheel anchors not found: %d" % garage._stock_wheel_nodes.size())
        quit(1)
        return
    var found := false
    for part in garage.available_part_variants():
        if str(part.get("part_key", "")) == "WHEELS:00AA0001":
            found = true
    if not found:
        push_error("Documented shared WHEELS catalog wasn't surfaced in showroom")
        quit(1)
        return
    if not garage.install_variant("WHEELS:00AA0001"):
        push_error("Four real imported GLB wheels not installed")
        quit(1)
        return
    var installed: Array = garage._installed_part_roots.get("WHEEL", [])
    if installed.size() != 4:
        push_error("Expected four visible aftermarket GLB wheel instances")
        quit(1)
        return
    for index in range(4):
        if not garage._wheel_anchor_transforms[index].origin.is_equal_approx(installed[index].transform.origin):
            push_error("Source-derived NFSU2 wheel axle transform changed at wheel %d" % index)
            quit(1)
            return
        if garage._stock_wheel_nodes[index].visible:
            push_error("Factory wheel did not hide when new rim installed")
            quit(1)
            return
    if not garage.reset_to_stock("WHEEL"):
        push_error("Factory-wheel restore failed")
        quit(1)
        return
    for index in range(4):
        if not garage._stock_wheel_nodes[index].visible:
            push_error("Restored factory wheel still hidden")
            quit(1)
            return
    print("CITY_ZERO_NFSU2_FOUR_WHEEL_GLB_IMPORT_SWAP_RESTORE_PASS")
    quit(0)
