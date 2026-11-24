extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var source := load("res://city_zero/nfsu2_private/CityZeroNFSU2PrivateGarage.gd")
    if source == null:
        push_error("Failed to compile private NFSU2 loader")
        quit(1)
        return
    var instance: Node3D = source.new()
    get_root().add_child(instance)
    var directory := ProjectSettings.globalize_path("user://cityzero_nfsu2_synthetic")
    DirAccess.make_dir_recursive_absolute(directory)
    var source_file := directory.path_join("cityzero_godot_library.json")
    var report: Dictionary = {
        "schema": "cityzero.nfsu2.private-godot-library.v1",
        "root": directory,
        "vehicles": {
            "SUPRA": {
                "model_assets": {"status": "no_model_exports", "stock": null, "parts": []},
                "sound_stages": {},
                "performance_categories": {"engine": "1"},
                "vinyls": {"count": 0}
            }
        }
    }
    var f := FileAccess.open(source_file, FileAccess.WRITE)
    if f == null:
        push_error("Cannot create synthetic test registry")
        quit(1)
        return
    f.store_string(JSON.stringify(report))
    f.close()
    if not instance.open_library(source_file):
        push_error("Could not read synthetic local registry")
        quit(1)
        return
    var ids: PackedStringArray = instance.car_ids()
    if ids.size() != 1 or ids[0] != "SUPRA":
        push_error("Wrong car identities: " + str(ids))
        quit(1)
        return
    if instance.open_car("SUPRA"):
        push_error("Model loader fabricated absent original NFSU2 mesh")
        quit(1)
        return
    if not instance._private_file("../secret.bin").is_empty():
        push_error("Path traversal was accepted")
        quit(1)
        return
    var showroom := load("res://city_zero/nfsu2_private/CityZeroNFSU2Showroom.tscn") as PackedScene
    if showroom == null:
        push_error("Godot GUI showroom scene does not compile")
        quit(1)
        return
    var scene := showroom.instantiate()
    get_root().add_child(scene)
    await process_frame
    await process_frame
    if scene.get_child_count() < 2:
        push_error("Showroom UI or viewport is missing")
        quit(1)
        return
    print("CITYZERO_NFSU2_PRIVATE_SHOWROOM_SMOKE_PASS")
    quit(0)
