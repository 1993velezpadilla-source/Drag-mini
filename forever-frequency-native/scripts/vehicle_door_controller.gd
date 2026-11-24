extends Node3D
## Blender GLB door hinge animation in Godot 4. Robust against imported
## glTF coordinate-basis rotations. Local Y opens the hinged door.
@export var opening_speed_degrees: float = 105.0
@export var opening_angle_degrees: float = 65.0
var hinges: Dictionary = {}
var closed_quaternions: Dictionary = {}
var current_angle: Dictionary = {}
var target_angle: Dictionary = {}

func _ready() -> void:
    register_hinges(get_parent())
    if hinges.is_empty():
        push_warning("Car has no independent Blender mechanical hinges: " + str(get_parent().name))

func register_hinges(start: Node) -> void:
    hinges.clear()
    closed_quaternions.clear()
    current_angle.clear()
    target_angle.clear()
    _scan(start)

func _scan(node: Node) -> void:
    if node is Node3D and str(node.name).begins_with("DOOR_") and str(node.name).ends_with("_HINGE"):
        var hinge: Node3D = node as Node3D
        var key: String = str(node.name)
        hinges[key] = hinge
        closed_quaternions[key] = hinge.quaternion
        current_angle[key] = 0.0
        target_angle[key] = 0.0
    for child in node.get_children():
        if child != self:
            _scan(child)

func available_doors() -> Array[String]:
    var keys: Array[String] = []
    for id in hinges:
        keys.append(str(id))
    keys.sort()
    return keys

func toggle_door(id: String) -> bool:
    if not hinges.has(id):
        return false
    var opening: float = deg_to_rad(opening_angle_degrees)
    var sign: float = -1.0 if id.contains("_LEFT_") else 1.0
    target_angle[id] = 0.0 if absf(float(target_angle[id])) > 0.1 else sign * opening
    return true

func close_every_door() -> void:
    for id in hinges:
        target_angle[id] = 0.0

func is_door_open(id: String) -> bool:
    return hinges.has(id) and absf(float(target_angle[id])) > 0.1

func _process(delta: float) -> void:
    for id in hinges:
        var hinge: Node3D = hinges[id]
        # Quaternion composition prevents Euler wrap and non-zero glTF parent
        # orientation from leaving a closed door in a wrong physical position.
        var next_angle: float = move_toward(
            float(current_angle[id]), float(target_angle[id]),
            deg_to_rad(opening_speed_degrees) * delta
        )
        current_angle[id] = next_angle
        var imported_closed: Quaternion = closed_quaternions[id]
        hinge.quaternion = imported_closed * Quaternion(Vector3.UP, next_angle)
