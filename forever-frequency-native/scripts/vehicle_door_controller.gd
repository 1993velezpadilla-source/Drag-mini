extends Node3D
## Blender GLB door hinge animation in Godot 4. Robust against imported
## glTF coordinate-basis rotations. Local Y opens the hinged door.
@export var opening_speed_degrees: float = 105.0
@export var opening_angle_degrees: float = 65.0
## Certain source models are authored with mirror-inverted hinge axes.
## Opt in ONLY for a rig with visual clockwise/outward-door verification.
## Keeping this false preserves user-approved original orange Lamborghini.
@export var invert_opening_direction: bool = false
## Opt-in ONLY for actual McLaren 570S original hinged door geometry.
## The 570S uses dihedral, UPWARD + OUTWARD opening, not ordinary car doors.
## Never enable this on the approved orange Lamborghini or Ferrari.
@export var mclaren_570s_dihedral_mode: bool = false
## Axis study on actual 57,933-triangle, 108-primitive artist source:
## hinge pivot (side .89, height .60, nose 1.0), door centroid
## (side .867, height .727, longitudinal .318), choose 0.65 lateral axis.
@export_range(0.30,0.85,0.01) var dihedral_lateral_axis_fraction: float = 0.65
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
    if invert_opening_direction:
        sign = -sign
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
        var local_rotation_axis := Vector3.UP
        if mclaren_570s_dihedral_mode:
            # Both door skin + side glass + mirror physically rise instead of
            # rotating sideways only. Axis mirrors with each side and stays
            # exactly at the source-authored hinge pivot. At zero degrees
            # this is the IDENTITY, preserving all original closed positions.
            var lateral_sign: float = 1.0 if str(id).contains("_RIGHT_") else -1.0
            var tilt: float = clampf(dihedral_lateral_axis_fraction,0.30,0.85)
            local_rotation_axis = Vector3(
                -lateral_sign * tilt,
                sqrt(1.0 - tilt * tilt),
                0.0
            )
        hinge.quaternion = imported_closed * Quaternion(local_rotation_axis, next_angle)
