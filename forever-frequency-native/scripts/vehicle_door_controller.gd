extends Node3D
## Reusable, moddable door actuator for native Blender->Godot GLB instances.
## A hinge is a genuine empty transform exported as DOOR_LEFT_FRONT_HINGE,
## DOOR_RIGHT_FRONT_HINGE, etc. Its skin, inside panel, handle and window are
## children and rotate together. No disappearing static mesh is permitted.
##
## Attach as a child of any imported vehicle scene root and call toggle_door().
@export var opening_speed_degrees: float = 105.0
@export var opening_angle_degrees: float = 65.0
var hinges: Dictionary = {}
var closed_angles: Dictionary = {}
var targets: Dictionary = {}

func _ready() -> void:
    register_hinges(get_parent())
    if hinges.is_empty():
        push_warning("Vehicle has no mechanical door hinges: " + str(get_parent().name))

func register_hinges(start: Node) -> void:
    hinges.clear()
    closed_angles.clear()
    targets.clear()
    _scan(start)

func _scan(node: Node) -> void:
    if node is Node3D and str(node.name).begins_with("DOOR_") and str(node.name).ends_with("_HINGE"):
        var hinge: Node3D = node as Node3D
        var key: String = str(node.name)
        hinges[key] = hinge
        closed_angles[key] = hinge.rotation.y
        targets[key] = hinge.rotation.y
    for child in node.get_children():
        if child != self:
            _scan(child)

func available_doors() -> Array[String]:
    var keys: Array[String] = []
    for key in hinges:
        keys.append(str(key))
    keys.sort()
    return keys

func toggle_door(id: String) -> bool:
    if not hinges.has(id):
        return false
    var sign: float = 1.0 if id.contains("_LEFT_") else -1.0
    var closed_angle: float = float(closed_angles[id])
    var is_open: bool = absf(float(targets[id]) - closed_angle) > 0.1
    targets[id] = closed_angle if is_open else closed_angle + sign * deg_to_rad(opening_angle_degrees)
    return true

func close_every_door() -> void:
    for id in hinges:
        targets[id] = float(closed_angles[id])

func is_door_open(id: String) -> bool:
    return hinges.has(id) and absf(float(targets[id]) - float(closed_angles[id])) > 0.1

func _process(delta: float) -> void:
    for id in hinges:
        var hinge: Node3D = hinges[id]
        hinge.rotation.y = move_toward(
            hinge.rotation.y,
            float(targets[id]),
            deg_to_rad(opening_speed_degrees) * delta
        )
