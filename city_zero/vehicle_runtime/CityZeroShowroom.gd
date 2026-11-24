extends Node3D
## City Zero garage reference: opens an actual authorized CC0 .glb, not a generated car.
## Import the GLB from https://github.com/JaronKBragg7337/spectral-gt-rs
const MODEL := "res://city_zero/assets/reference_cc0/spectral_gt_rs_game_ready.glb"

var _car: Node3D
var _camera: Camera3D
var _yaw := -0.9
var _pitch := 0.25
var _distance := 9.0
var _label: Label
var _animations: Dictionary = {}
var _controls: HBoxContainer
var _fingers: Dictionary = {}
var _opened: Dictionary = {}

func _ready() -> void:
    _setup_studio()
    _setup_interface()
    var model := load(MODEL) as PackedScene
    if model == null:
        _label.text = "MODEL UNAVAILABLE\nRun City Zero CC0 import workflow to fetch the real licensed GLB."
        return
    _car = model.instantiate() as Node3D
    if _car == null:
        _label.text = "MODEL REJECTED\nInvalid 3D root in source GLB."
        return
    _car.name = "VerifiedCC0Vehicle"
    add_child(_car)
    _collect_animations(_car)
    var names: Array[String] = []
    for key in _animations:
        names.append(str(key))
    _label.text = "SPECTRAL GT RS — CC0 3D REFERENCE\n" + str(names.size()) + " original animation clips. Drag to orbit; scroll or pinch to zoom."
    _build_animation_controls()

func _setup_studio() -> void:
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color(0.07, 0.09, 0.13)
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color(0.65, 0.72, 0.83)
    environment.environment.ambient_light_energy = 0.85
    add_child(environment)

    var floor := MeshInstance3D.new()
    floor.name = "RealScaleStudioFloor"
    var plane := PlaneMesh.new()
    plane.size = Vector2(36.0, 36.0)
    floor.mesh = plane
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.10, 0.12, 0.17)
    mat.metallic = 0.15
    mat.roughness = 0.55
    floor.material_override = mat
    floor.position.y = -0.04
    add_child(floor)

    for details in [
        {"angle": Vector3(-48.0, -25.0, 0.0), "power": 2.2},
        {"angle": Vector3(-65.0, 165.0, 0.0), "power": 1.25}
    ]:
        var key := DirectionalLight3D.new()
        key.rotation_degrees = details["angle"]
        key.light_energy = details["power"]
        key.shadow_enabled = true
        add_child(key)

    _camera = Camera3D.new()
    _camera.fov = 46.0
    add_child(_camera)
    _camera.current = true
    _update_camera()

func _update_camera() -> void:
    if _camera == null:
        return
    _pitch = clampf(_pitch, -0.15, 1.05)
    _distance = clampf(_distance, 4.0, 17.0)
    var focus := Vector3(0.0, 0.95, 0.0)
    _camera.position = focus + Vector3(
        sin(_yaw) * cos(_pitch) * _distance,
        sin(_pitch) * _distance,
        cos(_yaw) * cos(_pitch) * _distance
    )
    _camera.look_at(focus, Vector3.UP)

func _setup_interface() -> void:
    var overlay := CanvasLayer.new()
    add_child(overlay)
    var main := Control.new()
    main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    main.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.add_child(main)

    var panel := PanelContainer.new()
    panel.anchor_left = 0.02
    panel.anchor_right = 0.98
    panel.anchor_top = 0.02
    panel.anchor_bottom = 0.18
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    main.add_child(panel)
    var top := VBoxContainer.new()
    panel.add_child(top)
    _label = Label.new()
    _label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _label.add_theme_font_size_override("font_size", 18)
    _label.text = "Importing real vehicle..."
    top.add_child(_label)

    var hint := Label.new()
    hint.name = "InteractionHints"
    hint.text = "Hood & doors: real GLB animations only.  Trunk audio: requires separately licensed components."
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    top.add_child(hint)
    var controls := HBoxContainer.new()
    controls.name = "Controls"
    top.add_child(controls)
    _controls = controls

func _collect_animations(node: Node) -> void:
    if node is AnimationPlayer:
        var player := node as AnimationPlayer
        for name in player.get_animation_list():
            _animations[str(name)] = {"player": player, "name": name}
    for child in node.get_children():
        _collect_animations(child)

func _build_animation_controls() -> void:
    if _controls == null:
        return
    for item in ["Hood_Service_PingPong", "Doors_PingPong", "Doors_PingPong.001", "Steering_Input_PingPong"]:
        if not _animations.has(item):
            continue
        var button := Button.new()
        button.text = item.replace("_PingPong", "").replace("_", " ").replace(".001", " R")
        button.custom_minimum_size = Vector2(110, 46)
        button.pressed.connect(_toggle_animation.bind(item))
        _controls.add_child(button)

func _toggle_animation(key: String) -> void:
    if not _animations.has(key):
        return
    var data: Dictionary = _animations[key]
    var player: AnimationPlayer = data["player"]
    var name: StringName = data["name"]
    var should_open := not bool(_opened.get(key, false))
    _opened[key] = should_open
    if should_open:
        player.play(name)
    else:
        player.play_backwards(name)

func _finger_span() -> float:
    if _fingers.size() < 2:
        return 0.0
    var positions := _fingers.values()
    return (Vector2(positions[0]) - Vector2(positions[1])).length()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _fingers[event.index] = event.position
        else:
            _fingers.erase(event.index)
    elif event is InputEventScreenDrag:
        if _fingers.size() >= 2:
            var previous_span := _finger_span()
            _fingers[event.index] = event.position
            var current_span := _finger_span()
            if previous_span > 5.0 and current_span > 5.0:
                _distance *= previous_span / current_span
        else:
            _fingers[event.index] = event.position
            _yaw -= event.relative.x * 0.008
            _pitch += event.relative.y * 0.006
        _update_camera()
    elif event is InputEventMouseMotion and _fingers.is_empty() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        _yaw -= event.relative.x * 0.008
        _pitch += event.relative.y * 0.006
        _update_camera()
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _distance /= 1.12
            _update_camera()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _distance *= 1.12
            _update_camera()
