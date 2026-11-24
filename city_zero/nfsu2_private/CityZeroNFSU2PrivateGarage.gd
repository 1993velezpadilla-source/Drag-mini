extends Node3D
class_name CityZeroNFSU2PrivateGarage
## Runtime consumer for the user's privately imported original NFSU2 assets.
## GLTFDocument loads REAL locally exported GLBs, never placeholder geometry.
## NFSU2's commercial game assets must not be bundled into public APKs.
##
## Input: tools/nfsu2_prepare_godot_library.py --import-root <private_output>.
## Editor example: call open_library("/absolute/path/to/cityzero_godot_library.json").
## The source "part" GLBs are generated in one car coordinate frame in Blender.

signal library_opened(car_count: int)
signal car_loaded(xname: String)
signal part_changed(family: String, kit: String)
signal import_failed(reason: String)

@export_file("*.json") var library_path: String = ""
@export var car_to_open: String = ""
@export var auto_open_on_ready: bool = false

var _catalog: Dictionary = {}
var _private_root: String = ""
var _current_id: String = ""
var _vehicle_root: Node3D
var _stock_hidden: Dictionary = {}
var _installed_part_roots: Dictionary = {}
var _stock_wheel_nodes: Array[MeshInstance3D] = []
var _wheel_anchor_transforms: Array[Transform3D] = []
var _wheel_markers: Dictionary = {}
var _audio_player: AudioStreamPlayer3D

func _ready() -> void:
    if auto_open_on_ready and not library_path.is_empty():
        if open_library(library_path) and not car_to_open.is_empty():
            open_car(car_to_open)


func open_library(path: String) -> bool:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        import_failed.emit("Library file not found: " + path)
        return false
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        import_failed.emit("Invalid JSON library")
        return false
    var data: Dictionary = parsed
    if data.get("schema", "") != "cityzero.nfsu2.private-godot-library.v1":
        import_failed.emit("Unsupported private library schema")
        return false
    if typeof(data.get("vehicles", null)) != TYPE_DICTIONARY:
        import_failed.emit("Library has no vehicles dictionary")
        return false
    _private_root = str(data.get("root", "")).simplify_path()
    # When the library is copied from desktop to Android, the desktop absolute
    # path is stale. Use the actual location of the JSON file instead.
    if _private_root.is_empty() or not DirAccess.dir_exists_absolute(_private_root):
        _private_root = path.get_base_dir().simplify_path()
    if _private_root.is_empty() or not DirAccess.dir_exists_absolute(_private_root):
        import_failed.emit("Private import directory is missing")
        return false
    _catalog = data
    library_opened.emit(_catalog["vehicles"].size())
    return true


func car_ids() -> PackedStringArray:
    if not _catalog.has("vehicles"):
        return PackedStringArray()
    var ids := PackedStringArray()
    for key in _catalog["vehicles"].keys():
        ids.append(str(key))
    ids.sort()
    return ids


func _private_file(relative: String) -> String:
    var normalized := relative.replace("\\", "/")
    if normalized.is_empty() or normalized.begins_with("/") or normalized.contains(":"):
        return ""
    var parts := normalized.split("/")
    for part in parts:
        if part == ".." or part == "." or part.is_empty():
            return ""
    var candidate := _private_root.path_join(normalized).simplify_path()
    if not candidate.begins_with(_private_root.rstrip("/") + "/"):
        return ""
    if not FileAccess.file_exists(candidate):
        return ""
    return candidate


func _instantiate_glb(relative: String) -> Node3D:
    var source := _private_file(relative)
    if source.is_empty() or not source.to_lower().ends_with(".glb"):
        return null
    var state := GLTFState.new()
    var loader := GLTFDocument.new()
    var status := loader.append_from_file(source, state)
    if status != OK:
        import_failed.emit("GLB import failed with error " + str(status) + ": " + relative)
        return null
    return loader.generate_scene(state) as Node3D


func _clear_previous() -> void:
    if _vehicle_root != null and is_instance_valid(_vehicle_root):
        remove_child(_vehicle_root)
        _vehicle_root.free()
    _vehicle_root = null
    _installed_part_roots.clear()
    _stock_hidden.clear()
    _stock_wheel_nodes.clear()
    _wheel_anchor_transforms.clear()
    _wheel_markers.clear()
    _current_id = ""


func open_car(xname: String) -> bool:
    var vehicles: Dictionary = _catalog.get("vehicles", {})
    if not vehicles.has(xname):
        import_failed.emit("Car not present in NFSU2 source data: " + xname)
        return false
    var car: Dictionary = vehicles[xname]
    var models: Dictionary = car.get("model_assets", {})
    var stock: Variant = models.get("stock", null)
    if not stock is Dictionary or str(stock.get("glb", "")).is_empty():
        import_failed.emit("Real stock GLB for " + xname + " has not been exported")
        return false
    var candidate := _instantiate_glb(str(stock["glb"]))
    if candidate == null:
        return false
    _clear_previous()
    _vehicle_root = candidate
    _vehicle_root.name = "NFSU2_" + xname
    add_child(_vehicle_root)
    _remember_stock_wheel_anchors()
    _current_id = xname
    _audio_player = AudioStreamPlayer3D.new()
    _audio_player.name = "AuthenticAudioPreview"
    _vehicle_root.add_child(_audio_player)
    car_loaded.emit(xname)
    return true


func _scan_stock_wheel_nodes(node: Node, candidates: Dictionary) -> void:
    if node is MeshInstance3D:
        var name := str(node.name).to_upper()
        if name.contains("WHEEL") or name.contains("_RIM"):
            var expression := RegEx.new()
            expression.compile("[._]W([0-3])$")
            var found := expression.search(name)
            if found != null:
                var index := int(found.get_string(1))
                if not candidates.has(index):
                    candidates[index] = node
    for child in node.get_children():
        _scan_stock_wheel_nodes(child, candidates)


func _remember_stock_wheel_anchors() -> void:
    _stock_wheel_nodes.clear()
    _wheel_anchor_transforms.clear()
    _wheel_markers.clear()
    if _vehicle_root == null:
        return
    var candidates: Dictionary = {}
    _scan_stock_wheel_nodes(_vehicle_root, candidates)
    # Do not guess missing wheel coordinates; the original source has 4 axle
    # transforms, and all must be present before a shared rim can be fitted.
    if candidates.size() != 4:
        return
    var inverse_car := _vehicle_root.global_transform.affine_inverse()
    for index in range(4):
        if not candidates.has(index):
            _stock_wheel_nodes.clear()
            _wheel_anchor_transforms.clear()
            return
        var wheel: MeshInstance3D = candidates[index]
        _stock_wheel_nodes.append(wheel)
        _wheel_anchor_transforms.append(inverse_car * wheel.global_transform)
        _wheel_markers[index] = wheel.name


func installed_car() -> String:
    return _current_id


func available_part_variants(family: String = "") -> Array:
    if _current_id.is_empty():
        return []
    var car: Dictionary = _catalog["vehicles"][_current_id]
    var rows: Array = car.get("model_assets", {}).get("parts", []).duplicate(true)
    var allowed: Array = car.get("compatible_shared_families", [])
    var shared: Dictionary = _catalog.get("shared_families", {})
    for family_name in allowed:
        var extras: Dictionary = shared.get(str(family_name), {})
        for part in extras.get("parts", []):
            if part is Dictionary:
                rows.append(part.duplicate(true))
    if family.is_empty():
        return rows
    var found: Array = []
    for row in rows:
        if str(row.get("family", "")).to_upper() == family.to_upper():
            found.append(row)
    return found


func _normalize_family(name: String) -> String:
    var upper := name.to_upper()
    var exp := RegEx.new()
    exp.compile("_(KITW?[0-9]+|STYLE[0-9]+)_")
    upper = exp.sub(upper, "_", true)
    exp.compile("_[ABCD]$")
    return exp.sub(upper, "", false)


func _collect_stock_family(node: Node, normalized_family: String, out: Array) -> void:
    if node is MeshInstance3D and _normalize_family(node.name) == normalized_family:
        out.append(node)
    for child in node.get_children():
        _collect_stock_family(child, normalized_family, out)


func _remove_previous_part(part: Variant) -> void:
    if part is Array:
        for entry in part:
            if entry is Node and is_instance_valid(entry):
                entry.get_parent().remove_child(entry)
                entry.free()
    elif part is Node and is_instance_valid(part):
        part.get_parent().remove_child(part)
        part.free()


func _install_real_wheel_set(row: Dictionary) -> bool:
    if _vehicle_root == null or _stock_wheel_nodes.size() != 4:
        import_failed.emit("All four genuine wheel anchor transforms are required")
        return false
    if str(row.get("mount_space", "")) != "wheel_local":
        import_failed.emit("Selected wheel GLB has not been exported in wheel-local space")
        return false
    # Stage four genuine GLB instances before hiding the factory wheels.
    var staged: Array[Node3D] = []
    for index in range(4):
        var wheel := _instantiate_glb(str(row.get("glb", "")))
        if wheel == null:
            for temp in staged:
                _remove_previous_part(temp)
            return false
        wheel.name = "AuthenticRim_%d_%s" % [index, str(row.get("part_hash", ""))]
        _vehicle_root.add_child(wheel)
        wheel.transform = _wheel_anchor_transforms[index]
        staged.append(wheel)
    if _installed_part_roots.has("WHEEL"):
        _remove_previous_part(_installed_part_roots["WHEEL"])
    else:
        var hidden: Array = []
        for factory_wheel in _stock_wheel_nodes:
            hidden.append(factory_wheel)
            factory_wheel.visible = false
        _stock_hidden["WHEEL"] = hidden
    _installed_part_roots["WHEEL"] = staged
    part_changed.emit("WHEEL", str(row.get("kit", "BASE")))
    return true


func install_variant(source_hash: String) -> bool:
    if _current_id.is_empty():
        return false
    var match_data: Dictionary = {}
    for row in available_part_variants():
        if str(row.get("part_key", "")) == source_hash or (
                str(row.get("part_hash", "")) == source_hash):
            match_data = row
            break
    if match_data.is_empty():
        import_failed.emit("Unknown part hash for this car: " + source_hash)
        return false
    var slot := str(match_data.get("slot", "other"))
    if slot == "wheel":
        return _install_real_wheel_set(match_data)
    if slot in ["brake", "audio", "spinner"]:
        import_failed.emit("Genuine %s mount marker required; refusing to place part at car origin" % slot)
        return false
    var candidate := _instantiate_glb(str(match_data.get("glb", "")))
    if candidate == null:
        return false
    var family := str(match_data.get("family", ""))
    if family.is_empty():
        candidate.free()
        return false
    var key := family.to_upper()
    if _installed_part_roots.has(key):
        _remove_previous_part(_installed_part_roots[key])
    else:
        var hidden: Array = []
        _collect_stock_family(_vehicle_root, _normalize_family(family), hidden)
        _stock_hidden[key] = hidden
        for mesh in hidden:
            if is_instance_valid(mesh):
                mesh.visible = false
    _vehicle_root.add_child(candidate)
    candidate.name = "CustomPart_" + str(match_data.get("part_hash", ""))
    _installed_part_roots[key] = candidate
    part_changed.emit(family, str(match_data.get("kit", "BASE")))
    return true


func reset_to_stock(family: String) -> bool:
    var key := family.to_upper()
    if key.contains("WHEEL") or key.contains("_RIM"):
        key = "WHEEL"
    if not _installed_part_roots.has(key):
        return false
    _remove_previous_part(_installed_part_roots[key])
    _installed_part_roots.erase(key)
    for mesh in _stock_hidden.get(key, []):
        if is_instance_valid(mesh):
            mesh.visible = true
    _stock_hidden.erase(key)
    part_changed.emit(family, "STOCK")
    return true


func available_engine_stages() -> Dictionary:
    if _current_id.is_empty():
        return {}
    return _catalog["vehicles"][_current_id].get("sound_stages", {}).duplicate(true)


func available_performance_categories() -> Dictionary:
    if _current_id.is_empty():
        return {}
    # These are per-car enable/disable settings; NOT fabricated physics figures.
    return _catalog["vehicles"][_current_id].get("performance_categories", {}).duplicate(true)


func original_physics_record() -> Dictionary:
    if _current_id.is_empty():
        return {}
    # The reader copies only original source values. It NEVER applies upgrade
    # packages, invents power gains or reuses a different vehicle's physics.
    return _catalog["vehicles"][_current_id].get("original_physics", {}).duplicate(true)


func original_upgrade_targets() -> Dictionary:
    return original_physics_record().get("upgrade_source_targets", {}).duplicate(true)


func vinyl_records() -> Dictionary:
    if _current_id.is_empty():
        return {}
    # Original UV maps must be kept; the vinyl PNG is NOT a generic car material.
    return _catalog["vehicles"][_current_id].get("vinyls", {}).duplicate(true)


func play_bank_preview(stage: String, bank_name: String, stream_index: int = 0) -> bool:
    ## Auditions an original decoded stream. This is NOT RPM-synthesized engine
    ## audio (GIN sweep timing + ABK layering need the full sound engine).
    if _current_id.is_empty() or stream_index < 0:
        return false
    var stages: Dictionary = available_engine_stages()
    var settings: Dictionary = stages.get(stage.to_lower(), {})
    var banks: Dictionary = settings.get("referenced_audio", {})
    var record: Dictionary = banks.get(bank_name, {})
    if record.get("status", "") != "decoded_audio_available":
        return false
    var wavs: Array = record.get("decoded_private_audio", [])
    if stream_index >= wavs.size():
        return false
    var source := _private_file(str(wavs[stream_index]))
    if source.is_empty():
        return false
    var decoded: AudioStream = null
    if source.to_lower().ends_with(".wav"):
        decoded = AudioStreamWAV.load_from_file(source)
    elif source.to_lower().ends_with(".ogg"):
        decoded = AudioStreamOggVorbis.load_from_file(source)
    if decoded == null:
        return false
    _audio_player.stop()
    _audio_player.stream = decoded
    _audio_player.play()
    return true
