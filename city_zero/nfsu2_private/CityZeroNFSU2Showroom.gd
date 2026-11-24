extends Control
## Real GLB showroom; no fabricated car meshes or fallback vehicle images.
## Open a locally imported cityzero_godot_library.json to use your own NFSU2 files.

var _garage: CityZeroNFSU2PrivateGarage
var _selector: OptionButton
var _parts: OptionButton
var _status: Label
var _dialog: FileDialog
var _part_rows: Array = []
var _dragging := false
var _vinyl_popup: AcceptDialog
var _vinyl_selector: OptionButton
var _vinyl_image: TextureRect
var _vinyl_rows: Array = []

func _ready() -> void:
    _build_ui()


func _build_ui() -> void:
    var root_ui := VBoxContainer.new()
    root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_ui.add_theme_constant_override("separation", 8)
    add_child(root_ui)

    var top := HBoxContainer.new()
    root_ui.add_child(top)
    var choose := Button.new()
    choose.text = "OPEN NFSU2 LIBRARY"
    choose.pressed.connect(_choose_file)
    top.add_child(choose)
    var turn := Button.new()
    turn.text = "SPIN 360"
    turn.pressed.connect(_spin_car)
    top.add_child(turn)

    _status = Label.new()
    _status.text = "No original NFSU2 GLBs loaded. Choose your private library."
    _status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root_ui.add_child(_status)

    var viewer := SubViewportContainer.new()
    viewer.stretch = true
    viewer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    viewer.custom_minimum_size = Vector2(300, 390)
    root_ui.add_child(viewer)
    viewer.gui_input.connect(_on_viewer_input)

    var viewport := SubViewport.new()
    viewport.size = Vector2i(720, 920)
    viewport.own_world_3d = true
    viewport.transparent_bg = false
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewer.add_child(viewport)

    var stage := Node3D.new()
    stage.name = "RealGLBStage"
    viewport.add_child(stage)

    _garage = CityZeroNFSU2PrivateGarage.new()
    _garage.name = "PrivateNFSU2Vehicle"
    _garage.import_failed.connect(_on_error)
    _garage.car_loaded.connect(_on_car_loaded)
    stage.add_child(_garage)

    var floor := MeshInstance3D.new()
    floor.name = "ShowroomFloorOnly_NoFakeCar"
    var plane := PlaneMesh.new()
    plane.size = Vector2(80, 80)
    floor.mesh = plane
    floor.position.y = -0.03
    var gray := StandardMaterial3D.new()
    gray.albedo_color = Color(0.18, 0.2, 0.24)
    gray.roughness = 0.65
    floor.material_override = gray
    stage.add_child(floor)

    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color(0.10, 0.12, 0.17)
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color(0.86, 0.89, 0.95)
    environment.environment.ambient_light_energy = 0.9
    stage.add_child(environment)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, 37, 0)
    sun.light_energy = 2.0
    stage.add_child(sun)

    var camera := Camera3D.new()
    camera.position = Vector3(7.0, 3.6, 7.0)
    stage.add_child(camera)
    camera.look_at(Vector3(0, 1, 0), Vector3.UP)
    camera.current = true

    var selection_row := HBoxContainer.new()
    root_ui.add_child(selection_row)
    _selector = OptionButton.new()
    _selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _selector.item_selected.connect(_select_car)
    selection_row.add_child(_selector)

    _parts = OptionButton.new()
    _parts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    selection_row.add_child(_parts)

    var edit_row := HBoxContainer.new()
    root_ui.add_child(edit_row)
    var install := Button.new()
    install.text = "INSTALL KIT PART"
    install.pressed.connect(_install_part)
    edit_row.add_child(install)
    var reset := Button.new()
    reset.text = "RESTORE STOCK"
    reset.pressed.connect(_restore_part)
    edit_row.add_child(reset)
    var audio := Button.new()
    audio.text = "PLAY SOURCE AUDIO"
    audio.pressed.connect(_try_sound)
    edit_row.add_child(audio)

    var stats_row := HBoxContainer.new()
    root_ui.add_child(stats_row)
    var engine_stats := Button.new()
    engine_stats.text = "ENGINE / RPM / TORQUE"
    engine_stats.pressed.connect(_show_engine_stats)
    stats_row.add_child(engine_stats)
    var vinyl_count := Button.new()
    vinyl_count.text = "VINYL CATALOG"
    vinyl_count.pressed.connect(_show_vinyl_count)
    stats_row.add_child(vinyl_count)

    _dialog = FileDialog.new()
    _dialog.title = "Select cityzero_godot_library.json"
    _dialog.access = FileDialog.ACCESS_FILESYSTEM
    _dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    _dialog.add_filter("*.json", "Godot library JSON")
    _dialog.file_selected.connect(_file_chosen)
    add_child(_dialog)

    _vinyl_popup = AcceptDialog.new()
    _vinyl_popup.title = "Original car-specific NFSU2 vinyl previews"
    add_child(_vinyl_popup)
    var vinyl_column := VBoxContainer.new()
    vinyl_column.custom_minimum_size = Vector2(320, 375)
    _vinyl_popup.add_child(vinyl_column)
    var note := Label.new()
    note.text = "Original decoded texture preview. Applying the vinyl to the body requires the source's composite-skin masks."
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vinyl_column.add_child(note)
    _vinyl_selector = OptionButton.new()
    _vinyl_selector.item_selected.connect(_preview_vinyl)
    vinyl_column.add_child(_vinyl_selector)
    _vinyl_image = TextureRect.new()
    _vinyl_image.custom_minimum_size = Vector2(280, 280)
    _vinyl_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _vinyl_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    vinyl_column.add_child(_vinyl_image)


func _choose_file() -> void:
    _dialog.popup_centered_ratio(0.95)


func _file_chosen(path: String) -> void:
    if not _garage.open_library(path):
        return
    _selector.clear()
    for car in _garage.car_ids():
        _selector.add_item(car)
    if _selector.item_count > 0:
        _selector.select(0)
        _select_car(0)
    else:
        _status.text = "The library contains no cars."


func _select_car(index: int) -> void:
    if index < 0 or index >= _selector.item_count:
        return
    var xname := _selector.get_item_text(index)
    _garage.open_car(xname)


func _on_car_loaded(xname: String) -> void:
    _vinyl_selector.clear()
    _vinyl_image.texture = null
    _vinyl_rows = _garage.vinyl_records().get("vinyls", [])
    for vinyl in _vinyl_rows:
        _vinyl_selector.add_item(str(vinyl.get("name", "VINYL")))
    _parts.clear()
    _part_rows = _garage.available_part_variants()
    for part in _part_rows:
        _parts.add_item("%s | %s | %s" % [
            str(part.get("owner_xname", xname)),
            str(part.get("kit", "BASE")),
            str(part.get("family", "PART"))
        ])
    _status.text = "%s: REAL original GLB loaded • %d part variants" % [
        xname, _part_rows.size()
    ]


func _install_part() -> void:
    var selected := _parts.get_selected_id()
    if selected < 0 or selected >= _part_rows.size():
        return
    var part: Dictionary = _part_rows[selected]
    if _garage.install_variant(str(part.get("part_key", part.get("part_hash", "")))):
        _status.text = "Installed real part: " + str(part.get("source_name", ""))


func _restore_part() -> void:
    var selected := _parts.get_selected_id()
    if selected < 0 or selected >= _part_rows.size():
        return
    var family := str(_part_rows[selected].get("family", ""))
    if _garage.reset_to_stock(family):
        _status.text = "Restored original factory part: " + family


func _try_sound() -> void:
    var stages := _garage.available_engine_stages()
    for stage in ["stock", "street", "pro", "extreme"]:
        var info: Dictionary = stages.get(stage, {})
        var banks: Dictionary = info.get("referenced_audio", {})
        for name in banks:
            if banks[name].get("status", "") == "decoded_audio_available":
                if _garage.play_bank_preview(stage, str(name)):
                    _status.text = "Playing genuine decoded source: " + str(name)
                    return
    _status.text = "No decoded source WAV available in this private import."


func _show_engine_stats() -> void:
    var original := _garage.original_physics_record()
    var factory: Dictionary = original.get("factory_physics", {})
    if factory.is_empty():
        _status.text = "Original GLOBALB.BUN physics unavailable for this car."
        return
    var rpm: Array = factory.get("engine_idle_redline_max_rpm", [])
    var torque: Array = factory.get("torque_curve_kNm", [])
    if rpm.size() != 3 or torque.is_empty():
        _status.text = "Original engine data incomplete."
        return
    var max_torque := 0.0
    for value in torque:
        max_torque = maxf(max_torque, float(value))
    _status.text = "Original %s: idle %.0f · redline %.0f · max %.0f RPM · peak %.0f Nm (stock)" % [
        _garage.installed_car(), float(rpm[0]), float(rpm[1]), float(rpm[2]),
        max_torque * 1000.0
    ]


func _show_vinyl_count() -> void:
    var vinyls := _garage.vinyl_records()
    if _vinyl_selector.item_count > 0:
        _vinyl_selector.select(0)
        _preview_vinyl(0)
    _vinyl_popup.popup_centered_ratio(0.88)
    _status.text = "%s: %d source vinyl textures, %d decoded PNG previews" % [
        _garage.installed_car(), int(vinyls.get("count", 0)),
        int(vinyls.get("decoded_previews", 0))
    ]


func _preview_vinyl(index: int) -> void:
    if index < 0 or index >= _vinyl_rows.size():
        _vinyl_image.texture = null
        return
    _vinyl_image.texture = _garage.load_original_vinyl_preview(index)


func _spin_car() -> void:
    if _garage.installed_car().is_empty():
        return
    var tween := create_tween()
    tween.tween_property(_garage, "rotation:y",
        _garage.rotation.y + TAU, 3.0).set_trans(Tween.TRANS_LINEAR)


func _on_viewer_input(event: InputEvent) -> void:
    if _garage.installed_car().is_empty():
        return
    if event is InputEventScreenDrag:
        _garage.rotate_y(-event.relative.x * 0.008)
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            _dragging = event.pressed
    elif event is InputEventMouseMotion and _dragging:
        _garage.rotate_y(-event.relative.x * 0.008)


func _on_error(reason: String) -> void:
    _status.text = "Source error: " + reason
