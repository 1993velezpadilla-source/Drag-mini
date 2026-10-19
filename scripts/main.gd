extends Control
## DRAG MINI v0.1: local offline race. Values are arcade balancing, not specs.
const QUARTER_MILE_M := 402.336
const Progression = preload("res://scripts/progression.gd")
const RaceAudio = preload("res://scripts/race_audio.gd")
const WheelLayers = preload("res://scripts/wheel_layers.gd")
const PortraitShell = preload("res://scripts/portrait_shell.gd")
const ProceduralTrack = preload("res://scripts/procedural_track.gd")
# Menu background and controls are built by native_main_menu.gd.
# The old composite menu image is deliberately NOT loaded at runtime.
const CAR_PATHS := [
    "res://assets/cars/civic_hatch_game.png",
    "res://assets/cars/supra_mk4_game.png",
    "res://assets/cars/del_sol_game.png",
    "res://assets/cars/trueno_ae86_game.png"
]
const CARS := [
    {"name":"HONDA CIVIC HATCH", "mass":1110.0, "torque":155.0, "redline":7600.0, "final":4.40, "grip":0.98},
    {"name":"TOYOTA SUPRA MK4", "mass":1500.0, "torque":365.0, "redline":7100.0, "final":3.40, "grip":1.04},
    {"name":"HONDA DEL SOL", "mass":1130.0, "torque":170.0, "redline":7500.0, "final":4.10, "grip":0.97},
    {"name":"TOYOTA TRUENO AE86", "mass":1000.0, "torque":150.0, "redline":7600.0, "final":4.30, "grip":1.02}
]
const RATIOS := [3.10, 2.05, 1.46, 1.10, 0.85]
var images: Array[Texture2D] = []
var visual_cars: Array[Dictionary] = []
var wallpaper_wheel_angle := 0.0
var wallpaper_road_offset := 0.0
var selected := 0
var auto_shift := false
var screen := "menu"
var player := {}
var rival := {}
var elapsed := 0.0
var finish_text := ""
var shift_feedback_until := 0.0
var shift_feedback := ""
var shift_feedback_label: Label
var progress: RefCounted
var race_audio: Node
var race_distance_m := QUARTER_MILE_M
var career_race := false
var race_paid := false
var launched := false
var reaction_seconds := 0.0
var launch_grade := ""
var shift_combo := 0
var skill_points := 0
var race_flash := 0.0
var camera_shake := 0.0
var nitrous_button: Button
var notice := ""
var wallpaper_touch_down := Vector2.ZERO
var wallpaper_boost := 0.0
var menu_overlay: Control
var throttle_held := false
var gas_finger := -1
var mouse_gas := false
var start_light_color := Color("303a44")
var build_label: Label
var countdown := 0.0
var false_start := false
var launch_rpm := 1050.0
var green_timer := 0.0
var countdown_label: Label
var title_label: Label
var detail_label: Label
var telemetry_label: Label
var message_label: Label
var prev_button: Button
var next_button: Button
var mode_button: Button
var race_button: Button
var throttle_button: Button
var shift_button: Button
var retry_button: Button
var garage_button: Button
var wallpaper_button: Button
var wallpaper_bridge
var wallpaper_mode := false

func _ready() -> void:
    progress = Progression.new()
    progress.load_game()
    race_audio = RaceAudio.new()
    add_child(race_audio)
    get_tree().auto_accept_quit = false
    selected = progress.selected
    auto_shift = progress.auto_shift
    if OS.get_name() == "Android":
        DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
    wallpaper_bridge = preload("res://scripts/wallpaper_bridge.gd").new()
    wallpaper_bridge.plugin_ready.connect(_on_wallpaper_plugin_ready)
    add_child(wallpaper_bridge)
    for path in CAR_PATHS:
        var tex := load(path) as Texture2D
        if tex == null:
            push_error("Missing PNG game sprite: " + path)
        images.append(tex)
        if tex != null:
            visual_cars.append(WheelLayers.build(tex, visual_cars.size()))
    ProceduralTrack.load_world()
    _make_ui()
    menu_overlay = PortraitShell.new()
    menu_overlay.name = "PortraitMenu"
    menu_overlay.action_selected.connect(_menu_action)
    add_child(menu_overlay)
    menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _show_main_menu()
    if wallpaper_bridge.is_wallpaper:
        _enter_wallpaper_mode()
    # Keep a colored startup diagnostic until native Godot controls initialize.
    set_meta("dragmini_boot_complete", true)
    var startup_guard := get_node_or_null("StartupFallback") as Control
    if startup_guard != null:
        startup_guard.hide()

func _style_button(button: Button, accent := false) -> void:
    button.add_theme_font_size_override("font_size", 26)
    button.add_theme_color_override("font_color", Color("ffffff"))
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color("c33e28") if accent else Color("263548")
    normal.set_corner_radius_all(18)
    normal.set_content_margin_all(10)
    button.add_theme_stylebox_override("normal", normal)
    var down := StyleBoxFlat.new()
    down.bg_color = Color("f57d34") if accent else Color("426382")
    down.set_corner_radius_all(18)
    button.add_theme_stylebox_override("pressed", down)

func _button(label_text: String, left: float, top: float, right: float, bottom: float, accent := false) -> Button:
    var btn := Button.new()
    btn.text = label_text
    btn.anchor_left = left
    btn.anchor_right = right
    btn.anchor_top = top
    btn.anchor_bottom = bottom
    btn.offset_left = 7
    btn.offset_right = -7
    btn.offset_top = 6
    btn.offset_bottom = -6
    btn.focus_mode = Control.FOCUS_NONE
    _style_button(btn, accent)
    add_child(btn)
    return btn

func _label(text_value: String, top: float, bottom: float, font_size: int) -> Label:
    var label := Label.new()
    label.text = text_value
    label.anchor_left = 0.04
    label.anchor_right = 0.96
    label.anchor_top = top
    label.anchor_bottom = bottom
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color("fff2da"))
    add_child(label)
    return label

func _make_ui() -> void:
    title_label = _label("DRAG MINI", 0.035, 0.108, 36)
    build_label = _label("DRAG MINI • STREET RACING", 0.007, 0.041, 13)
    detail_label = _label("", 0.276, 0.327, 18)
    telemetry_label = _label("", 0.108, 0.179, 19)
    message_label = _label("", 0.765, 0.82, 17)
    shift_feedback_label = _label("", 0.440, 0.495, 31)
    shift_feedback_label.add_theme_constant_override("outline_size", 4)
    shift_feedback_label.add_theme_color_override("font_outline_color", Color("060d19"))
    shift_feedback_label.visible = false
    countdown_label = _label("", 0.333, 0.401, 43)
    countdown_label.visible = false
    prev_button = _button("<", 0.04, 0.70, 0.2, 0.77)
    next_button = _button(">", 0.8, 0.70, 0.96, 0.77)
    mode_button = _button("MANUAL", 0.21, 0.70, 0.79, 0.77)
    race_button = _button("RACE", 0.07, 0.86, 0.93, 0.97, true)
    wallpaper_button = _button("WALLPAPER", 0.55, 0.86, 0.94, 0.97)
    throttle_button = _button("HOLD GAS", 0.035, 0.832, 0.52, 0.969, true)
    shift_button = _button("LAUNCH", 0.54, 0.832, 0.965, 0.969)
    nitrous_button = _button("NITRO", 0.62, 0.764, 0.965, 0.830)
    throttle_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
    shift_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
    nitrous_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
    retry_button = _button("RETRY", 0.035, 0.837, 0.485, 0.969, true)
    garage_button = _button("HOME", 0.515, 0.837, 0.965, 0.969)
    prev_button.pressed.connect(func(): _select_car(-1))
    next_button.pressed.connect(func(): _select_car(1))
    mode_button.pressed.connect(_toggle_mode)
    race_button.pressed.connect(_start_race)
    retry_button.pressed.connect(_start_race)
    garage_button.pressed.connect(_show_main_menu)
    wallpaper_button.pressed.connect(_request_wallpaper)

func _state() -> Dictionary:
    var model: Dictionary = CARS[selected]
    var tuning: Dictionary = progress.performance(selected)
    var part_states: Array = []
    for part in Progression.PARTS:
        part_states.append({"id":part["id"], "name":part["title"],
            "level":progress.level(selected, part["id"]),
            "cost":progress.price(selected, part["id"])})
    var story: Dictionary = Progression.STORY[progress.stage]
    return {
        "car":selected, "car_name":model["name"],
        "power":float(model["torque"]) * float(tuning["torque"]) * 1.38,
        "cash":progress.cash, "wins":progress.wins,
        "level":1 + int(progress.xp / 350),
        "stage":progress.stage, "story":story["title"],
        "rival_name":story["rival_name"], "dialogue":story["dialogue"],
        "story_prize":story["reward"],
        "story_distance":_distance_name(float(story["distance"])),
        "distance_choice":progress.distance_choice,
        "auto_shift":progress.auto_shift, "kmh":progress.show_kmh,
        "vibration":progress.vibrations, "dynamic":progress.dynamic_time,
        "audio":progress.audio_enabled,
        "wallpaper_interactive":progress.wallpaper_interactive,
        "parts":part_states, "notice":notice
    }

func _distance_name(meters: float) -> String:
    if meters < 300.0:
        return "1/8 MILE"
    if meters < 600.0:
        return "1/4 MILE"
    if meters < 1100.0:
        return "1/2 MILE"
    return "1 MILE"

func _present(page: String) -> void:
    for child in get_children():
        if child is Button or child is Label:
            child.visible = false
    screen = page
    menu_overlay.visible = true
    menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_overlay.present(page, _state())
    queue_redraw()

func _menu_action(action: String) -> void:
    if action.begins_with("upgrade:"):
        var part_id := action.trim_prefix("upgrade:")
        if progress.purchase(selected, part_id):
            notice = part_id.to_upper() + " UPGRADED!"
            if OS.get_name() == "Android" and progress.vibrations:
                Input.vibrate_handheld(35)
        else:
            var cost: int = progress.price(selected, part_id)
            notice = "MAX LEVEL" if cost == 0 else "NEED $%d MORE" % maxi(0, cost - progress.cash)
        _present("upgrades")
        return
    if action.begins_with("distance:"):
        progress.distance_choice = clampi(int(action.trim_prefix("distance:")), 0, 3)
        progress.save_game()
        _present("race_select")
        return
    match action:
        "start":
            career_race = false
            race_distance_m = float(Progression.DISTANCES[progress.distance_choice])
            _start_race()
        "career_start":
            career_race = true
            race_distance_m = float(Progression.STORY[progress.stage]["distance"])
            _start_race()
        "menu": _show_main_menu()
        "garage": _show_garage()
        "race", "race_select": _present("race_select")
        "career": _present("career")
        "upgrades": _present("upgrades")
        "settings": _present("settings")
        "wallpaper": _present("wallpaper")
        "wallpaper_apply":
            _request_wallpaper()
            _present("wallpaper")
        "wallpaper_preview": _enter_wallpaper_mode(false)
        "car_prev": _select_car(-1)
        "car_next": _select_car(1)
        "toggle_shift":
            _toggle_mode()
            _present("settings")
        "toggle_units":
            progress.show_kmh = not progress.show_kmh
            progress.save_game()
            _present("settings")
        "toggle_vibration":
            progress.vibrations = not progress.vibrations
            progress.save_game()
            _present("settings")
        "toggle_time":
            progress.dynamic_time = not progress.dynamic_time
            progress.save_game()
            _present("settings")
        "toggle_audio":
            progress.audio_enabled = not progress.audio_enabled
            progress.save_game()
            _present("settings")
        "toggle_wallpaper_touch":
            progress.wallpaper_interactive = not progress.wallpaper_interactive
            progress.save_game()
            _present("settings")
        _:
            push_warning("Unknown menu action: " + action)

func _show_main_menu() -> void:
    wallpaper_mode = false
    Engine.max_fps = 60
    throttle_held = false
    gas_finger = -1
    mouse_gas = false
    _present("menu")

func _show_garage() -> void:
    notice = "Choose your ride. Every car has its own tuning."
    _present("garage")

func _select_car(step: int) -> void:
    selected = posmod(selected + step, CARS.size())
    progress.selected = selected
    progress.save_game()
    _present(screen)

func _toggle_mode() -> void:
    auto_shift = not auto_shift
    progress.auto_shift = auto_shift
    progress.save_game()

func _update_garage() -> void:
    _present("garage")

func _make_driver(car_id: int) -> Dictionary:
    return {"car_id":car_id, "speed":0.0, "distance":0.0,
        "rpm":1050.0, "gear":0, "shift_timer":0.0,
        "finished":false, "finish_time":0.0, "wheel_angle":0.0,
        "tuning":progress.performance(car_id), "nitrous_left":float(progress.level(car_id, "nitrous")) * 2.0,
        "nitrous_active":0.0, "launch_force":1.0, "shift_power":0.0}

func _start_race() -> void:
    screen = "race"
    if menu_overlay != null:
        menu_overlay.visible = false
    build_label.visible = true
    shift_feedback_until = 0.0
    shift_feedback_label.visible = false
    elapsed = 0.0
    finish_text = ""
    throttle_held = false
    gas_finger = -1
    mouse_gas = false
    false_start = false
    launch_rpm = 1050.0
    countdown = 4.0
    green_timer = 0.0
    race_paid = false
    launched = false
    reaction_seconds = 0.0
    launch_grade = ""
    shift_combo = 0
    skill_points = 0
    race_flash = 0.0
    camera_shake = 0.0
    wallpaper_mode = false
    player = _make_driver(selected)
    rival = _make_driver(int(Progression.STORY[progress.stage]["rival"]) if career_race else (selected + 1) % CARS.size())
    # CPU rivals are independent vehicles, NOT secretly using the player's garage mods
    # when the storyline happens to select the same chassis.
    var opponent_power := 1.0 + (0.045 * float(progress.stage + 1) if career_race else 0.0)
    rival["tuning"] = {
        "torque":opponent_power,
        "mass":1.0,
        "grip":1.0 + (0.017 * float(progress.stage + 1) if career_race else 0.0),
        "shift":maxf(0.82, 1.0 - (0.014 * float(progress.stage + 1) if career_race else 0.0)),
        "nitrous":0
    }
    rival["nitrous_left"] = 0.0
    title_label.text = _distance_name(race_distance_m) + " DRAG"
    title_label.visible = true
    telemetry_label.visible = true
    detail_label.visible = true
    message_label.visible = career_race
    if career_race:
        message_label.text = "VS " + str(Progression.STORY[progress.stage]["rival_name"])
    countdown_label.visible = true
    countdown_label.text = "READY"
    for btn in [prev_button, next_button, mode_button, race_button, retry_button, garage_button, wallpaper_button, nitrous_button]:
        btn.visible = false
    throttle_button.visible = true
    shift_button.visible = true
    shift_button.text = "LAUNCH"
    nitrous_button.visible = progress.level(selected, "nitrous") > 0
    _update_hud()
    queue_redraw()

func _input(event: InputEvent) -> void:
    # Two real Android fingers: finger A holds GAS while finger B taps SHIFT.
    if wallpaper_mode:
        if event is InputEventScreenTouch and not wallpaper_bridge.is_wallpaper:
            var preview_touch := event as InputEventScreenTouch
            if preview_touch.pressed and preview_touch.position.y < size.y * 0.18:
                _show_main_menu()
                get_viewport().set_input_as_handled()
                return
        if progress.wallpaper_interactive and event is InputEventScreenTouch:
            var touch_wall := event as InputEventScreenTouch
            if touch_wall.pressed:
                wallpaper_touch_down = touch_wall.position
                wallpaper_boost = 2.0
            elif absf(touch_wall.position.x - wallpaper_touch_down.x) > 60.0:
                selected = posmod(selected + (1 if touch_wall.position.x < wallpaper_touch_down.x else -1), CARS.size())
                progress.selected = selected
                progress.save_game()
            get_viewport().set_input_as_handled()
        if not wallpaper_bridge.is_wallpaper and event is InputEventKey and event.pressed:
            _show_main_menu()
        return
    if screen != "race" or false_start:
        return
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        _route_touch(touch.index, touch.position, touch.pressed)
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and OS.get_name() != "Android":
        # Desktop mouse fallback only; mobile emulated mouse must not steal GAS finger.
        var mouse := event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT:
            _route_mouse(mouse.position, mouse.pressed)

func _route_touch(finger: int, position: Vector2, pressed: bool) -> void:
    if pressed:
        if throttle_button.visible and throttle_button.get_global_rect().has_point(position):
            if gas_finger == -1:
                gas_finger = finger
                _on_gas_down()
        elif nitrous_button.visible and nitrous_button.get_global_rect().has_point(position):
            _activate_nitrous()
        elif shift_button.visible and shift_button.get_global_rect().has_point(position):
            _player_shift()
    elif finger == gas_finger:
        gas_finger = -1
        throttle_held = mouse_gas
    _refresh_pedal_color()

func _route_mouse(position: Vector2, pressed: bool) -> void:
    if pressed and throttle_button.visible and throttle_button.get_global_rect().has_point(position):
        mouse_gas = true
        _on_gas_down()
    elif not pressed and mouse_gas:
        mouse_gas = false
        throttle_held = gas_finger != -1
    elif pressed and nitrous_button.visible and nitrous_button.get_global_rect().has_point(position):
        _activate_nitrous()
    elif pressed and shift_button.visible and shift_button.get_global_rect().has_point(position):
        _player_shift()
    _refresh_pedal_color()

func _refresh_pedal_color() -> void:
    if is_instance_valid(throttle_button):
        throttle_button.modulate = Color("ffddaf") if throttle_held else Color.WHITE

func _activate_nitrous() -> void:
    if screen != "race" or countdown > 0.0 or false_start:
        return
    if float(player.get("nitrous_left", 0.0)) <= 0.0:
        return
    player["nitrous_active"] = 2.0
    nitrous_button.visible = false
    if progress.vibrations and OS.get_name() == "Android":
        Input.vibrate_handheld(60)

func _on_gas_down() -> void:
    if screen != "race" or false_start:
        return
    if countdown > 0.0:
        throttle_held = true
        return
    if false_start:
        throttle_held = false
        countdown_label.text = "FALSE START!"
        title_label.text = "DISQUALIFIED"
        detail_label.text = "Gas pressed before GO!\nTap RETRY to race again."
        throttle_button.visible = false
        shift_button.visible = false
        retry_button.visible = true
        garage_button.visible = true
        queue_redraw()
        return
    throttle_held = true

func _player_shift() -> void:
    if screen != "race" or false_start or player["finished"]:
        return
    if countdown > 0.0:
        _false_start()
        return
    if not launched:
        _launch_car()
        return
    if auto_shift or float(player["shift_timer"]) > 0.0 or int(player["gear"]) >= RATIOS.size() - 1:
        return
    # Only one shift light. Color anticipates timing; text appears on shift press.
    var ratio: float = float(player["rpm"]) / float(CARS[selected]["redline"])
    shift_feedback = "EARLY" if ratio < 0.87 else ("PERFECT" if ratio <= 0.965 else "LATE")
    shift_combo = shift_combo + 1 if shift_feedback == "PERFECT" else 0
    if shift_feedback == "PERFECT":
        skill_points += 120 * maxi(1, shift_combo)
        player["shift_power"] = 0.65
        race_flash = 0.35
        camera_shake = 5.0
    shift_feedback_label.text = shift_feedback + ("  x%d" % shift_combo if shift_combo > 1 else "")
    shift_feedback_label.add_theme_color_override("font_color", Color("ffd34c") if shift_feedback == "EARLY" else (Color("4dff83") if shift_feedback == "PERFECT" else Color("ff5353")))
    shift_feedback_label.visible = true
    shift_feedback_until = 0.70
    _shift(player)
    if shift_feedback == "PERFECT":
        player["shift_timer"] = float(player["shift_timer"]) * 0.52
    elif shift_feedback == "LATE":
        player["shift_timer"] = float(player["shift_timer"]) * 1.35
    if progress.vibrations and OS.get_name() == "Android":
        Input.vibrate_handheld(12 if shift_feedback == "PERFECT" else 28)

func _launch_car() -> void:
    if launched or countdown > 0.0 or false_start:
        return
    launched = true
    # The clutch release is a real decision: delayed reaction and wheelspin hurt ET.
    var rpm_factor := launch_rpm / float(CARS[selected]["redline"])
    var sweet_spot := 0.54
    var error := absf(rpm_factor - sweet_spot)
    var delay_penalty := clampf(reaction_seconds / 1.1, 0.0, 0.48)
    var quality := clampf(1.18 - error * 0.95 - delay_penalty, 0.62, 1.18)
    player["launch_force"] = quality
    launch_grade = "PERFECT LAUNCH" if quality > 1.08 else ("GOOD LAUNCH" if quality > 0.92 else "WHEELSPIN / SLOW")
    skill_points += 200 if quality > 1.08 else (90 if quality > 0.92 else 0)
    shift_feedback_label.text = launch_grade
    shift_feedback_label.add_theme_color_override("font_color", Color("57ffb0") if quality > 0.92 else Color("ffbb63"))
    shift_feedback_until = 0.90
    shift_feedback_label.visible = true
    shift_button.text = "SHIFT +"
    shift_button.visible = not auto_shift
    race_flash = 0.30
    camera_shake = 7.0 if quality <= 0.92 else 3.0
    if progress.vibrations and OS.get_name() == "Android":
        Input.vibrate_handheld(32)

func _false_start() -> void:
    false_start = true
    throttle_held = false
    gas_finger = -1
    mouse_gas = false
    title_label.text = "DISQUALIFIED"
    countdown_label.text = "RED LIGHT"
    detail_label.text = "LAUNCH BEFORE GO"
    shift_button.visible = false
    throttle_button.visible = false
    retry_button.visible = true
    garage_button.visible = true

func _shift(driver: Dictionary) -> void:
    if driver["shift_timer"] > 0.0 or driver["gear"] >= RATIOS.size() - 1:
        return
    driver["gear"] += 1
    driver["shift_timer"] = 0.23 * float(driver["tuning"]["shift"])

func _advance_car(driver: Dictionary, delta: float, gas: bool, shift_auto: bool) -> void:
    if driver["finished"]:
        return
    var model: Dictionary = CARS[driver["car_id"]]
    driver["shift_timer"] = maxf(0.0, driver["shift_timer"] - delta)
    driver["shift_power"] = maxf(0.0, float(driver["shift_power"]) - delta)
    var tuning: Dictionary = driver["tuning"]
    var gear_ratio: float = RATIOS[driver["gear"]] * model["final"]
    var wheel_radius := 0.305
    var coupled_rpm: float = driver["speed"] * gear_ratio * 60.0 / (TAU * wheel_radius)
    driver["rpm"] = clampf(maxf(maxf(1050.0, coupled_rpm), 2700.0 if gas and driver["speed"] < 3.0 else 0.0), 850.0, 8300.0)
    if shift_auto and driver["rpm"] >= model["redline"] * 0.91:
        _shift(driver)
    var throttle := 1.0 if gas and driver["shift_timer"] <= 0.0 else 0.0
    var normalized: float = driver["rpm"] / model["redline"]
    var curve := clampf(1.08 - absf(normalized - 0.65) * 0.63, 0.25, 1.0)
    if driver["rpm"] > model["redline"]:
        curve *= 0.08
    var nitrous_seconds: float = float(driver["nitrous_active"])
    if nitrous_seconds > 0.0:
        nitrous_seconds = maxf(0.0, nitrous_seconds - delta)
        driver["nitrous_active"] = nitrous_seconds
        driver["nitrous_left"] = maxf(0.0, float(driver["nitrous_left"]) - delta)
    var force_boost := 1.5 if nitrous_seconds > 0.0 else 1.0
    if float(driver["distance"]) < 36.0:
        force_boost *= float(driver["launch_force"])
    if float(driver["shift_power"]) > 0.0:
        force_boost *= 1.11
    var wheel_force: float = throttle * model["torque"] * float(tuning["torque"]) * force_boost * curve * gear_ratio * 0.82 / wheel_radius
    var effective_mass: float = model["mass"] * float(tuning["mass"])
    var max_traction: float = effective_mass * 9.81 * model["grip"] * float(tuning["grip"]) * 0.63
    var resistance: float = 0.45 * driver["speed"] * driver["speed"] + 125.0
    var net: float = minf(wheel_force, max_traction) - resistance
    driver["speed"] = maxf(0.0, driver["speed"] + (net / effective_mass) * delta)
    driver["distance"] += driver["speed"] * delta
    # Tire rotation follows *actual* car velocity, including manual coasting.
    driver["wheel_angle"] = fposmod(float(driver["wheel_angle"]) + float(driver["speed"]) * delta / wheel_radius, TAU)
    if driver["distance"] >= race_distance_m:
        driver["distance"] = race_distance_m
        driver["finished"] = true
        driver["finish_time"] = elapsed

func _process(delta: float) -> void:
    race_audio.set_engine(float(player.get("rpm", 1050.0)),
        throttle_held, screen == "race" and not false_start and not wallpaper_mode,
        progress.audio_enabled)
    if wallpaper_mode:
        # Wallpaper has its own inexpensive visual loop, even with racing paused.
        wallpaper_boost = maxf(0.0, wallpaper_boost - delta)
        wallpaper_wheel_angle = fposmod(wallpaper_wheel_angle + delta * (9.0 if wallpaper_boost > 0.0 else 3.8), TAU)
        wallpaper_road_offset += delta * (95.0 if wallpaper_boost > 0.0 else 12.0)
        if wallpaper_road_offset > 1200.0:
            wallpaper_road_offset = 0.0
        queue_redraw()
        return
    if screen != "race":
        return
    race_flash = maxf(0.0, race_flash - delta)
    camera_shake = maxf(0.0, camera_shake - delta * 16.0)
    if shift_feedback_until > 0.0:
        shift_feedback_until = maxf(0.0, shift_feedback_until - delta)
        if shift_feedback_until <= 0.0:
            shift_feedback_label.visible = false
    if false_start:
        return
    if countdown > 0.0:
        var redline: float = float(CARS[selected]["redline"])
        var target_rpm: float = minf(redline * 0.92, 5200.0) if throttle_held else 1050.0
        launch_rpm = move_toward(launch_rpm, target_rpm, delta * (4200.0 if throttle_held else 5200.0))
        player["rpm"] = launch_rpm
        countdown = maxf(0.0, countdown - delta)
        countdown_label.text = "READY" if countdown > 3.0 else ("3" if countdown > 2.0 else ("2" if countdown > 1.0 else ("1" if countdown > 0.0 else "GO!")))
        if countdown <= 0.0:
            message_label.visible = false
            countdown_label.text = "GO!"
            race_flash = 0.48
            shift_button.text = "LAUNCH"
            shift_button.visible = not auto_shift
            if auto_shift:
                _launch_car()
        _update_hud()
        queue_redraw()
        return
    green_timer += delta
    if not launched:
        reaction_seconds += minf(delta, 0.1)
    if green_timer > 0.8:
        countdown_label.visible = false
    if player["finished"] and rival["finished"]:
        return
    var tick := minf(delta, 1.0 / 30.0)
    elapsed += tick
    if launched:
        _advance_car(player, tick, throttle_held, auto_shift)
    # Slight human-like CPU reaction makes staging meaningful.
    if green_timer > 0.20 + float(progress.stage if career_race else 0) * 0.004:
        _advance_car(rival, tick, true, true)
    if player["finished"] and rival["finished"]:
        _end_race()
    _update_hud()
    queue_redraw()

func _end_race() -> void:
    var winning: bool = float(player["finish_time"]) <= float(rival["finish_time"])
    finish_text = "YOU WIN!" if winning else "RIVAL WINS"
    if not race_paid:
        var earned: int = progress.complete_race(winning, float(player["finish_time"]), career_race, race_distance_m)
        var skill_cash: int = skill_points / 8 if winning else skill_points / 20
        progress.cash += skill_cash
        progress.save_game()
        notice = "EARNED $%d  + SKILL $%d  •  TOTAL $%d" % [earned, skill_cash, progress.cash]
        race_paid = true
    title_label.text = finish_text
    detail_label.text = "YOUR TIME: %.2fs\nRIVAL TIME: %.2fs" % [player["finish_time"], rival["finish_time"]]
    throttle_button.visible = false
    shift_button.visible = false
    retry_button.visible = true
    garage_button.visible = true
    nitrous_button.visible = false
    message_label.text = notice
    message_label.visible = true
    countdown_label.visible = false

func _update_hud() -> void:
    var speed_value: float = float(player.get("speed", 0.0)) * (3.6 if progress.show_kmh else 2.2369363)
    telemetry_label.text = "%.2fs   •   %.0f / %.0fm\n%.0f %s  |  GEAR %d  |  %.0f RPM" % [
        elapsed, player.get("distance", 0.0), race_distance_m, speed_value,
        "KM/H" if progress.show_kmh else "MPH", int(player.get("gear", 0)) + 1,
        float(player.get("rpm", 1050.0))]
    if countdown > 0.0:
        telemetry_label.text = "STAGE RPM  %.0f  •  AIM FOR 4000\nHOLD GAS  /  TAP LAUNCH ON GREEN" % launch_rpm
    elif not launched:
        telemetry_label.text = "GREEN! TAP LAUNCH  •  %.2f s" % reaction_seconds
    if finish_text.is_empty():
        detail_label.text = "YOU %.0fm  |  RIVAL %.0fm  •  SKILL %d" % [player.get("distance", 0.0), rival.get("distance", 0.0), skill_points]

func _draw() -> void:
    var sz := size
    if wallpaper_mode:
        _draw_wallpaper(sz)
        return
    if screen != "race":
        return
    draw_rect(Rect2(Vector2.ZERO, sz), Color("081020"))
    # Dedicated low-clutter HUD instead of text floating on the race world.
    draw_rect(Rect2(0, 0, sz.x, sz.y * 0.313), Color("071021"))
    draw_rect(Rect2(sz.x * 0.028, sz.y * 0.087, sz.x * 0.944, sz.y * 0.106), Color("101d30"))
    draw_rect(Rect2(sz.x * 0.028, sz.y * 0.087, sz.x * 0.944, sz.y * 0.106), Color("396583", 0.5), false, 1.5)
    draw_line(Vector2(sz.x * 0.03, sz.y * 0.263), Vector2(sz.x * 0.97, sz.y * 0.263), Color("16364b"), 2.0)
    _draw_rpm_meter(sz)
    var bounds := Rect2(0, sz.y * 0.31, sz.x, sz.y * 0.465)
    var hour: int = int(Time.get_datetime_dict_from_system().get("hour", 21)) if progress.dynamic_time else 22
    ProceduralTrack.draw_world(self, bounds, float(player.get("distance", 0.0)),
        race_distance_m, hour, countdown, false_start)
    # Split lane progress shows the pursuit even when cars are off-camera.
    var track_progress_a := clampf(float(player.get("distance", 0.0)) / race_distance_m, 0.0, 1.0)
    var track_progress_b := clampf(float(rival.get("distance", 0.0)) / race_distance_m, 0.0, 1.0)
    draw_rect(Rect2(sz.x * 0.06, sz.y * 0.775, sz.x * 0.88, 5), Color("25374b"))
    draw_rect(Rect2(sz.x * 0.06, sz.y * 0.775, sz.x * 0.88 * track_progress_a, 3), Color("56ffd0"))
    draw_circle(Vector2(sz.x * (0.06 + track_progress_a * 0.88), sz.y * 0.775), 5, Color("56ffd0"))
    draw_circle(Vector2(sz.x * (0.06 + track_progress_b * 0.88), sz.y * 0.775), 3.5, Color("ff6e85"))
    if visual_cars.is_empty():
        return
    # Both racers remain legible and anchored to their lane, not floating over UI.
    var car_w := sz.x * 0.45
    var difference: float = float(player["distance"]) - float(rival["distance"])
    var shake_x := sin(elapsed * 61.0) * camera_shake
    var player_x := sz.x * 0.15 + clampf(difference * 0.46, -sz.x * 0.11, sz.x * 0.23) + shake_x
    var rival_x := sz.x * 0.15 + clampf(-difference * 0.46, -sz.x * 0.11, sz.x * 0.23)
    var player_id: int = int(player["car_id"])
    var rival_id: int = int(rival["car_id"])
    if rival_id < visual_cars.size():
        WheelLayers.draw_car(self, visual_cars[rival_id], Rect2(rival_x, sz.y * 0.656,
            car_w, car_w * 54.0 / 128.0), float(rival["wheel_angle"]))
    if player_id < visual_cars.size():
        WheelLayers.draw_car(self, visual_cars[player_id], Rect2(player_x, sz.y * 0.534,
            car_w, car_w * 54.0 / 128.0), float(player["wheel_angle"]))
    if float(player.get("nitrous_active", 0.0)) > 0.0:
        for i in range(6):
            var yy := sz.y * (0.562 + float(i) * 0.014)
            var length := sz.x * (0.13 + float(i % 3) * 0.035)
            draw_line(Vector2(player_x - 3, yy),
                Vector2(player_x - 3 - length, yy), Color("4edaff", 0.78), 2.0 + float(i % 2))
    # Speed lines sell motion without expensive image filters.
    if launched and float(player.get("speed", 0.0)) > 12.0:
        var intensity: float = clampf(float(player["speed"]) / 62.0, 0.15, 1.0)
        for i in range(12):
            var y := sz.y * (0.48 + fposmod(float(i) * 0.071, 0.24))
            var x := fposmod(float(i * 111) - float(player["distance"]) * (5.0 + float(i % 4)), sz.x + 100.0) - 40.0
            draw_line(Vector2(x, y), Vector2(x - 45.0 * intensity, y),
                Color(0.65, 0.81, 0.97, 0.10 + intensity * 0.20), 1.0)
    if race_flash > 0.0:
        draw_rect(Rect2(0, sz.y * 0.31, sz.x, sz.y * 0.465),
            Color(0.44, 0.88, 1.0, race_flash * 0.13))

# Live-wallpaper mode: no garage, race logic, multiplayer, HUD or high-rate updates.
# All wallpaper-native calls live in wallpaper_bridge.gd, guarded by Android checks.
func _enter_wallpaper_mode(actual_wallpaper: bool = true) -> void:
    wallpaper_mode = true
    screen = "wallpaper" if actual_wallpaper else "wallpaper_preview"
    # The Godot-native full-screen main menu must not cover Android wallpaper.
    if menu_overlay != null:
        menu_overlay.visible = false
    throttle_held = false
    Engine.max_fps = 20
    if OS.get_name() == "Android":
        DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
    for child in get_children():
        if child is Button or child is Label:
            child.visible = false
    queue_redraw()

func _draw_race_lights(sz: Vector2) -> void:
    # Racing Christmas tree: persistent, readable on the phone.
    var x: float = sz.x * 0.50
    var top: float = sz.y * 0.283
    var r: float = minf(sz.x * 0.025, 18.0)
    for i in range(3):
        var is_on: bool = countdown > 0.0 and countdown <= 3.0 - float(i)
        draw_circle(Vector2(x + (float(i) - 1.0) * (r * 3.0), top), r,
            Color("ffbb36") if is_on else Color("374251"))
    draw_circle(Vector2(x, top + r * 2.6), r,
        Color("4fe28b") if countdown <= 0.0 and not false_start else Color("263e35"))
    if false_start:
        draw_circle(Vector2(x, top + r * 2.6), r, Color("ff3636"))

func _draw_rpm_meter(sz: Vector2) -> void:
    var c := Vector2(sz.x * 0.50, sz.y * 0.230)
    var rad: float = minf(sz.x * 0.14, sz.y * 0.044)
    var redline: float = float(CARS[selected]["redline"])
    var ratio: float = clampf(float(player.get("rpm", 1050.0)) / redline, 0.0, 1.0)
    var start_angle := deg_to_rad(145.0)
    var end_angle := deg_to_rad(395.0)
    draw_arc(c, rad, start_angle, end_angle, 48, Color("65768a"), 8.0, false)
    draw_arc(c, rad, lerpf(start_angle, end_angle, 0.85), end_angle, 15, Color("d8443a"), 8.0, false)
    draw_arc(c, rad, start_angle, lerpf(start_angle, end_angle, ratio), 36, Color("55d8a4"), 5.0, false)
    var angle: float = lerpf(start_angle, end_angle, ratio)
    draw_line(c, c + Vector2(cos(angle), sin(angle)) * rad * 0.84, Color("fff1d7"), 4.0)
    draw_circle(c, 5.0, Color("fff1d7"))
    # Exactly ONE shifting light. Display follows RPM, text follows SHIFT press.
    var shift_color := Color("ffd34c") if ratio < 0.87 else (Color("48ff86") if ratio <= 0.965 else Color("ff4242"))
    var lamp := Vector2(sz.x * 0.50, sz.y * 0.18)
    draw_circle(lamp, 19.0, Color(shift_color.r, shift_color.g, shift_color.b, 0.20))
    draw_circle(lamp, 10.0, shift_color)
    var amp: float = 0.65 + 0.35 * sin(elapsed * 9.0)
    if ratio >= 0.87 and ratio <= 0.965 and launched:
        draw_arc(lamp, 19.0 + amp * 2.0, 0.0, TAU, 24, Color("56ffa4", 0.7), 2.0)

func _draw_wallpaper(sz: Vector2) -> void:
    draw_rect(Rect2(Vector2.ZERO, sz), Color("081020"))
    var hour: int = int(Time.get_datetime_dict_from_system().get("hour", 21)) if progress.dynamic_time else 22
    ProceduralTrack.draw_world(self, Rect2(Vector2.ZERO, sz),
        150.0 + wallpaper_road_offset * 0.7, 1800.0, hour)
    if selected < visual_cars.size():
        var w := sz.x * 0.89
        WheelLayers.draw_car(self, visual_cars[selected],
            Rect2(sz.x * 0.055, sz.y * 0.535, w, w * 54.0 / 128.0), wallpaper_wheel_angle)
    if not wallpaper_bridge.is_wallpaper:
        draw_string(ThemeDB.fallback_font, Vector2(sz.x * 0.07, sz.y * 0.12),
            "WALLPAPER PREVIEW  •  BACK TO EXIT", HORIZONTAL_ALIGNMENT_LEFT,
            -1, clampi(int(sz.x * 0.040), 12, 25), Color("f8d989"))

func _on_wallpaper_plugin_ready(running_as_wallpaper: bool) -> void:
    if running_as_wallpaper and not wallpaper_mode and is_node_ready():
        _enter_wallpaper_mode()

func _request_wallpaper() -> void:
    if wallpaper_bridge.start_live_wallpaper():
        notice = "ANDROID WALLPAPER PICKER OPENED"
    else:
        notice = wallpaper_bridge.diagnostic


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_GO_BACK_REQUEST:
        if screen != "menu" and not wallpaper_bridge.is_wallpaper:
            _show_main_menu()
        else:
            get_tree().quit()
