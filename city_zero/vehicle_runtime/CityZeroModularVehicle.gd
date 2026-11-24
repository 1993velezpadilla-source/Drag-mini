extends Node3D
class_name CityZeroModularVehicle
## Generic vehicle customization/animation controller for imported, licensed real 3D models.
## No placeholder or copyrighted meshes are created by this class.
## Configure hinge locations/rotations in Blender for EACH car; there are no guessed angles.

@export var hood_pivot: NodePath
@export var trunk_pivot: NodePath
@export var left_door_pivot: NodePath
@export var right_door_pivot: NodePath

# Degrees RELATIVE to the authored closed transform, per vehicle.
@export var hood_open_delta: Vector3 = Vector3.ZERO
@export var trunk_open_delta: Vector3 = Vector3.ZERO
@export var left_door_open_delta: Vector3 = Vector3.ZERO
@export var right_door_open_delta: Vector3 = Vector3.ZERO
@export_range(0.05, 4.0, 0.05) var panel_animation_seconds: float = 0.65

# Example: {"front_bumper": ^"VisualParts/FrontBumper", "hood": ^"VisualParts/Hood"}
# Part mount children are the ORIGINAL STOCK parts and will be shown again on reset.
@export var visual_mounts: Dictionary = {}
# 12 optional NodePaths to the authored MARKER_AUDIO_COMP_0..11 locations.
@export var speaker_mounts: Array[NodePath] = []

var _panel_nodes: Dictionary = {}
var _panel_closed: Dictionary = {}
var _panel_open: Dictionary = {}
var _panel_tweens: Dictionary = {}
var _part_mount_nodes: Dictionary = {}
var _stock_children: Dictionary = {}
var _installed_nodes: Dictionary = {}
var _installed_ids: Dictionary = {}
var _speaker_nodes: Dictionary = {}
var _speaker_ids: Dictionary = {}

func _ready() -> void:
    _register_panel("hood", hood_pivot)
    _register_panel("trunk", trunk_pivot)
    _register_panel("left_door", left_door_pivot)
    _register_panel("right_door", right_door_pivot)
    for slot in visual_mounts:
        var part_path: Variant = visual_mounts[slot]
        if not part_path is NodePath:
            push_warning("Invalid visual mount path for slot: " + str(slot))
            continue
        var mount := get_node_or_null(part_path) as Node3D
        if mount == null:
            push_warning("Missing part mount: " + str(slot))
            continue
        _part_mount_nodes[str(slot)] = mount
        var originals: Array[Node3D] = []
        for child in mount.get_children():
            if child is Node3D:
                originals.append(child)
        _stock_children[str(slot)] = originals

func _register_panel(kind: String, location: NodePath) -> void:
    if String(location).is_empty():
        return
    var pivot := get_node_or_null(location) as Node3D
    if pivot == null:
        push_warning("Missing hinge for " + kind + " (author a real pivot in Blender)")
        return
    _panel_nodes[kind] = pivot
    _panel_closed[kind] = pivot.rotation_degrees
    _panel_open[kind] = false

func _open_delta(kind: String) -> Vector3:
    match kind:
        "hood":
            return hood_open_delta
        "trunk":
            return trunk_open_delta
        "left_door":
            return left_door_open_delta
        "right_door":
            return right_door_open_delta
    return Vector3.ZERO

func set_panel_open(kind: String, should_open: bool, instant: bool = false) -> bool:
    if not _panel_nodes.has(kind):
        return false
    # Explicit authoring prevents accidentally animating a wrongly placed pivot.
    var delta := _open_delta(kind)
    if delta.is_zero_approx() and should_open:
        push_warning("Opening angle not authored for: " + kind)
        return false
    if _panel_tweens.has(kind):
        var previous: Tween = _panel_tweens[kind]
        if previous != null and previous.is_running():
            previous.kill()
    var pivot: Node3D = _panel_nodes[kind]
    var destination: Vector3 = _panel_closed[kind] + (delta if should_open else Vector3.ZERO)
    _panel_open[kind] = should_open
    if instant:
        pivot.rotation_degrees = destination
        return true
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(pivot, "rotation_degrees", destination, panel_animation_seconds)
    _panel_tweens[kind] = tween
    return true

func toggle_panel(kind: String) -> bool:
    return set_panel_open(kind, not bool(_panel_open.get(kind, false)))

func is_panel_open(kind: String) -> bool:
    return bool(_panel_open.get(kind, false))

func _install_into(mount: Node3D, scene: PackedScene) -> Node3D:
    if scene == null:
        return null
    var candidate := scene.instantiate() as Node3D
    if candidate == null:
        return null
    # Staged replacement: instantiate first. Never delete a usable stock part on failure.
    mount.add_child(candidate)
    candidate.transform = Transform3D.IDENTITY
    return candidate

func install_visual_part(slot: String, part_id: String, scene: PackedScene) -> bool:
    if not _part_mount_nodes.has(slot) or part_id.is_empty():
        return false
    var mount: Node3D = _part_mount_nodes[slot]
    var candidate := _install_into(mount, scene)
    if candidate == null:
        return false
    if _installed_nodes.has(slot):
        var old: Node3D = _installed_nodes[slot]
        if is_instance_valid(old):
            old.queue_free()
    for child in _stock_children.get(slot, []):
        if is_instance_valid(child):
            child.visible = false
    _installed_nodes[slot] = candidate
    _installed_ids[slot] = part_id
    return true

func restore_stock_visual(slot: String) -> bool:
    if not _part_mount_nodes.has(slot):
        return false
    if _installed_nodes.has(slot):
        var previous: Node3D = _installed_nodes[slot]
        if is_instance_valid(previous):
            previous.queue_free()
        _installed_nodes.erase(slot)
    _installed_ids.erase(slot)
    for child in _stock_children.get(slot, []):
        if is_instance_valid(child):
            child.visible = true
    return true

func install_speaker(socket_index: int, part_id: String, scene: PackedScene) -> bool:
    if socket_index < 0 or socket_index >= speaker_mounts.size() or socket_index > 11:
        return false
    var socket := get_node_or_null(speaker_mounts[socket_index]) as Node3D
    if socket == null or part_id.is_empty():
        return false
    var candidate := _install_into(socket, scene)
    if candidate == null:
        return false
    if _speaker_nodes.has(socket_index):
        var previous: Node3D = _speaker_nodes[socket_index]
        if is_instance_valid(previous):
            previous.queue_free()
    _speaker_nodes[socket_index] = candidate
    _speaker_ids[socket_index] = part_id
    return true

func remove_speaker(socket_index: int) -> void:
    if _speaker_nodes.has(socket_index):
        var previous: Node3D = _speaker_nodes[socket_index]
        if is_instance_valid(previous):
            previous.queue_free()
    _speaker_nodes.erase(socket_index)
    _speaker_ids.erase(socket_index)

func get_visual_loadout() -> Dictionary:
    # Only IDs/states, never raw meshes or proprietary payloads.
    return {
        "parts": _installed_ids.duplicate(true),
        "speakers": _speaker_ids.duplicate(true),
        "panels": _panel_open.duplicate(true)
    }

func apply_catalog_loadout(data: Dictionary, part_catalog: Dictionary, speaker_catalog: Dictionary) -> bool:
    # The calling save/network layer must verify ownership, permissions and compatibility.
    # Unknown IDs are rejected, not substituted with some other vehicle's part.
    var requested_parts: Dictionary = data.get("parts", {})
    var requested_speakers: Dictionary = data.get("speakers", {})
    for slot in requested_parts:
        var part_id := str(requested_parts[slot])
        if not _part_mount_nodes.has(str(slot)) or not part_catalog.has(part_id):
            return false
        if not part_catalog[part_id] is PackedScene:
            return false
    for index in requested_speakers:
        var n := int(index)
        var part_id := str(requested_speakers[index])
        if n < 0 or n >= speaker_mounts.size() or n > 11 or not speaker_catalog.has(part_id):
            return false
        if not speaker_catalog[part_id] is PackedScene:
            return false
    for slot in requested_parts:
        if not install_visual_part(str(slot), str(requested_parts[slot]), part_catalog[requested_parts[slot]]):
            return false
    for index in requested_speakers:
        if not install_speaker(int(index), str(requested_speakers[index]), speaker_catalog[requested_speakers[index]]):
            return false
    var state: Dictionary = data.get("panels", {})
    for kind in state:
        if _panel_nodes.has(str(kind)):
            set_panel_open(str(kind), bool(state[kind]), true)
    return true
