extends Control
## DRAG MINI v0.1: local offline race. Values are arcade balancing, not specs.
const QUARTER_MILE_M := 402.336
const WheelLayers = preload("res://scripts/wheel_layers.gd")
const CAR_PATHS := [
    "res://assets/cars/civic_hatch_game.png",
    "res://assets/cars/supra_mk4_game.png",
    "res://assets/cars/del_sol_game.png",
    "res://assets/cars/trueno_ae86_game.png"
]
const CARS := [
    {"name":"YELLOW HATCH", "mass":1110.0, "torque":155.0, "redline":7600.0, "final":4.40, "grip":0.98},
    {"name":"WHITE COUPE", "mass":1500.0, "torque":365.0, "redline":7100.0, "final":3.40, "grip":1.04},
    {"name":"RED TARGA", "mass":1130.0, "torque":170.0, "redline":7500.0, "final":4.10, "grip":0.97},
    {"name":"PANDA 86", "mass":1000.0, "torque":150.0, "redline":7600.0, "final":4.30, "grip":1.02}
]
const RATIOS := [3.10, 2.05, 1.46, 1.10, 0.85]
var images: Array[Texture2D] = []
var visual_cars: Array[Dictionary] = []
var wallpaper_wheel_angle := 0.0
var wallpaper_road_offset := 0.0
var selected := 0
var auto_shift := false
var screen := "garage"
var player := {}
var rival := {}
var elapsed := 0.0
var finish_text := ""
var throttle_held := false
var countdown := 0.0
var false_start := false
var launch_rpm := 1050.0
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
    _load_garage()
    wallpaper_bridge = preload("res://scripts/wallpaper_bridge.gd").new()
    add_child(wallpaper_bridge)
    for path in CAR_PATHS:
        var tex := load(path) as Texture2D
        if tex == null:
            push_error("Missing PNG game sprite: " + path)
        images.append(tex)
        if tex != null:
            visual_cars.append(WheelLayers.build(tex, visual_cars.size()))
    _make_ui()
    _show_garage()
    if wallpaper_bridge.is_wallpaper:
        _enter_wallpaper_mode()

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
    title_label = _label("DRAG MINI", 0.04, 0.14, 57)
    detail_label = _label("", 0.63, 0.74, 27)
    telemetry_label = _label("", 0.16, 0.27, 28)
    message_label = _label("", 0.72, 0.80, 24)
    countdown_label = _label("", 0.275, 0.35, 42)
    countdown_label.visible = false
    prev_button = _button("<", 0.04, 0.78, 0.20, 0.86)
    next_button = _button(">", 0.80, 0.78, 0.96, 0.86)
    mode_button = _button("MANUAL", 0.21, 0.78, 0.79, 0.86)
    race_button = _button("RACE 1/4 MILE", 0.07, 0.88, 0.93, 0.97, true)
    wallpaper_button = _button("WALLPAPER", 0.56, 0.88, 0.94, 0.97)
    wallpaper_button.visible = OS.get_name() == "Android"
    if wallpaper_button.visible:
        race_button.anchor_right = 0.56
    throttle_button = _button("HOLD GAS", 0.05, 0.83, 0.53, 0.97, true)
    shift_button = _button("SHIFT +", 0.55, 0.83, 0.95, 0.97)
    retry_button = _button("RETRY", 0.05, 0.83, 0.47, 0.97, true)
    garage_button = _button("GARAGE", 0.53, 0.83, 0.95, 0.97)
    prev_button.pressed.connect(func(): _select_car(-1))
    next_button.pressed.connect(func(): _select_car(1))
    mode_button.pressed.connect(_toggle_mode)
    race_button.pressed.connect(_start_race)
    throttle_button.button_down.connect(_on_gas_down)
    throttle_button.button_up.connect(func(): throttle_held = false)
    shift_button.pressed.connect(_player_shift)
    retry_button.pressed.connect(_start_race)
    garage_button.pressed.connect(_show_garage)
    wallpaper_button.pressed.connect(_request_wallpaper)

func _show_garage() -> void:
    screen = "garage"
    throttle_held = false
    title_label.text = "DRAG MINI"
    title_label.visible = true
    telemetry_label.visible = false
    message_label.visible = true
    message_label.text = "4 starter cars · 6 free garage slots"
    for btn in [prev_button, next_button, mode_button, race_button]:
        btn.visible = true
    for btn in [throttle_button, shift_button, retry_button, garage_button]:
        btn.visible = false
    wallpaper_button.visible = OS.get_name() == "Android"
    countdown_label.visible = false
    _update_garage()
    queue_redraw()

func _select_car(step: int) -> void:
    selected = posmod(selected + step, CARS.size())
    _save_garage()
    _update_garage()

func _toggle_mode() -> void:
    auto_shift = not auto_shift
    _save_garage()
    _update_garage()

func _update_garage() -> void:
    mode_button.text = "AUTO SHIFT" if auto_shift else "MANUAL SHIFT"
    detail_label.text = "%s  (%d/4)\n%s · ARCADE ENGINE\n%s" % [
        CARS[selected]["name"], selected + 1,
        "AUTOMATIC" if auto_shift else "MANUAL",
        "Choose your ride and start a race"
    ]
    queue_redraw()

func _make_driver(car_id: int) -> Dictionary:
    return {"car_id":car_id, "speed":0.0, "distance":0.0,
        "rpm":1050.0, "gear":0, "shift_timer":0.0,
        "finished":false, "finish_time":0.0, "wheel_angle":0.0}

func _start_race() -> void:
    screen = "race"
    elapsed = 0.0
    finish_text = ""
    throttle_held = false
    false_start = false
    launch_rpm = 1050.0
    countdown = 3.8
    player = _make_driver(selected)
    rival = _make_driver((selected + 1) % CARS.size())
    title_label.text = "1/4 MILE DRAG"
    title_label.visible = true
    telemetry_label.visible = true
    detail_label.visible = true
    message_label.visible = false
    countdown_label.visible = true
    countdown_label.text = "3"
    for btn in [prev_button, next_button, mode_button, race_button, retry_button, garage_button, wallpaper_button]:
        btn.visible = false
    throttle_button.visible = true
    shift_button.visible = not auto_shift
    _update_hud()
    queue_redraw()

func _on_gas_down() -> void:
    if screen != "race" or false_start:
        return
    if countdown > 0.0:
        false_start = true
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
    if screen == "race" and countdown <= 0.0 and not false_start and not auto_shift and not player["finished"]:
        _shift(player)

func _shift(driver: Dictionary) -> void:
    if driver["shift_timer"] > 0.0 or driver["gear"] >= RATIOS.size() - 1:
        return
    driver["gear"] += 1
    driver["shift_timer"] = 0.23

func _advance_car(driver: Dictionary, delta: float, gas: bool, shift_auto: bool) -> void:
    if driver["finished"]:
        return
    var model: Dictionary = CARS[driver["car_id"]]
    driver["shift_timer"] = maxf(0.0, driver["shift_timer"] - delta)
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
    var wheel_force: float = throttle * model["torque"] * curve * gear_ratio * 0.82 / wheel_radius
    var max_traction: float = model["mass"] * 9.81 * model["grip"] * 0.63
    var resistance: float = 0.45 * driver["speed"] * driver["speed"] + 125.0
    var net: float = minf(wheel_force, max_traction) - resistance
    driver["speed"] = maxf(0.0, driver["speed"] + (net / model["mass"]) * delta)
    driver["distance"] += driver["speed"] * delta
    # Tire rotation follows *actual* car velocity, including manual coasting.
    driver["wheel_angle"] = fposmod(float(driver["wheel_angle"]) + float(driver["speed"]) * delta / wheel_radius, TAU)
    if driver["distance"] >= QUARTER_MILE_M:
        driver["distance"] = QUARTER_MILE_M
        driver["finished"] = true
        driver["finish_time"] = elapsed

func _process(delta: float) -> void:
    if wallpaper_mode:
        # Wallpaper has its own inexpensive visual loop, even with racing paused.
        wallpaper_wheel_angle = fposmod(wallpaper_wheel_angle + delta * 3.8, TAU)
        wallpaper_road_offset = fposmod(wallpaper_road_offset + delta * 80.0, 160.0)
        queue_redraw()
        return
    if screen != "race":
        return
    if false_start:
        return
    if countdown > 0.0:
        var redline: float = float(CARS[selected]["redline"])
        var target_rpm: float = minf(redline * 0.92, 5200.0) if throttle_held else 1050.0
        launch_rpm = move_toward(launch_rpm, target_rpm, delta * (4200.0 if throttle_held else 5200.0))
        player["rpm"] = launch_rpm
        countdown = maxf(0.0, countdown - delta)
        countdown_label.text = "3" if countdown > 2.8 else ("2" if countdown > 1.8 else ("1" if countdown > 0.8 else ("GO!" if countdown > 0.0 else "")))
        if countdown <= 0.0:
            countdown_label.text = "GO!"
            _update_hud()
        queue_redraw()
        return
    if player["finished"] and rival["finished"]:
        return
    var tick := minf(delta, 1.0 / 30.0)
    elapsed += tick
    _advance_car(player, tick, throttle_held, auto_shift)
    _advance_car(rival, tick, true, true)
    if player["finished"] and rival["finished"]:
        _end_race()
    _update_hud()
    queue_redraw()

func _end_race() -> void:
    var winning: bool = float(player["finish_time"]) <= float(rival["finish_time"])
    finish_text = "YOU WIN!" if winning else "RIVAL WINS"
    title_label.text = finish_text
    detail_label.text = "YOUR TIME: %.2fs\nRIVAL TIME: %.2fs" % [player["finish_time"], rival["finish_time"]]
    throttle_button.visible = false
    shift_button.visible = false
    retry_button.visible = true
    garage_button.visible = true
    countdown_label.visible = false

func _update_hud() -> void:
    telemetry_label.text = "TIME %.2f s   |   DIST %.0f m\n%d km/h   |   GEAR %d   |   %.0f RPM" % [
        elapsed, player["distance"], roundi(player["speed"] * 3.6),
        player["gear"] + 1, player["rpm"]]
    if countdown > 0.0:
        telemetry_label.text = "STAGING • %.0f RPM\nWAIT FOR GO! • EARLY GAS = DQ" % launch_rpm
    if finish_text.is_empty():
        detail_label.text = "YOU: %.0f m   •   RIVAL: %.0f m" % [player["distance"], rival["distance"]]

func _draw() -> void:
    var sz := size
    if wallpaper_mode:
        _draw_wallpaper(sz)
        return
    draw_rect(Rect2(Vector2.ZERO, sz), Color("0c1421"))
    draw_rect(Rect2(0, sz.y * 0.28, sz.x, sz.y * 0.30), Color("162b3d"))
    draw_line(Vector2(0, sz.y * 0.28), Vector2(sz.x, sz.y * 0.28), Color("ef7d2e"), 4)
    draw_line(Vector2(0, sz.y * 0.58), Vector2(sz.x, sz.y * 0.58), Color("ef7d2e"), 4)
    if images.is_empty():
        return
    if screen == "garage":
        if selected < visual_cars.size():
            var w := sz.x * 0.91
            WheelLayers.draw_car(self, visual_cars[selected], Rect2(sz.x * 0.045, sz.y * 0.325, w, w * 54.0 / 128.0), 0.0)
    else:
        var start_x := sz.x * 0.02
        var course_w := sz.x * 0.42
        for p in [0.25, 0.50, 0.75, 1.0]:
            var x: float = start_x + course_w * float(p)
            draw_line(Vector2(x, sz.y * 0.29), Vector2(x, sz.y * 0.70), Color("86919c", 0.6), 2)
        draw_line(Vector2(0, sz.y * 0.495), Vector2(sz.x, sz.y * 0.495), Color("f1e5bb"), 3)
        var car_w := sz.x * 0.43
        var player_id: int = int(player["car_id"])
        if player_id < visual_cars.size():
            var px: float = start_x + course_w * (player["distance"] / QUARTER_MILE_M)
            WheelLayers.draw_car(self, visual_cars[player_id], Rect2(px, sz.y * 0.35, car_w, car_w * 54.0 / 128.0), float(player["wheel_angle"]))
        var rival_id: int = int(rival["car_id"])
        if rival_id < visual_cars.size():
            var rx: float = start_x + course_w * (rival["distance"] / QUARTER_MILE_M)
            WheelLayers.draw_car(self, visual_cars[rival_id], Rect2(rx, sz.y * 0.52, car_w, car_w * 54.0 / 128.0), float(rival["wheel_angle"]))

# Live-wallpaper mode: no garage, race logic, multiplayer, HUD or high-rate updates.
# All wallpaper-native calls live in wallpaper_bridge.gd, guarded by Android checks.
func _enter_wallpaper_mode() -> void:
    wallpaper_mode = true
    screen = "wallpaper"
    throttle_held = false
    Engine.max_fps = 20
    for child in get_children():
        if child is Button or child is Label:
            child.visible = false
    queue_redraw()

func _draw_wallpaper(sz: Vector2) -> void:
    draw_rect(Rect2(Vector2.ZERO, sz), Color("08101d"))
    draw_rect(Rect2(0, sz.y * 0.68, sz.x, sz.y * 0.32), Color("203341"))
    draw_rect(Rect2(0, sz.y * 0.79, sz.x, sz.y * 0.03), Color("445968"))
    draw_line(Vector2(0, sz.y * 0.81), Vector2(sz.x, sz.y * 0.81), Color("e6c88b"), 3)
    # Scrolling road dashes provide motion context for a right-facing car.
    for i in range(-1, 7):
        var dash_x: float = float(i) * 160.0 - wallpaper_road_offset
        draw_rect(Rect2(dash_x, sz.y * 0.90, 64, 5), Color("e6c88b"))
    if selected >= visual_cars.size():
        return
    var w := sz.x * 0.82
    WheelLayers.draw_car(self, visual_cars[selected], Rect2(sz.x * 0.09, sz.y * 0.64, w, w * 54.0 / 128.0), wallpaper_wheel_angle)

func _request_wallpaper() -> void:
    if not wallpaper_bridge.start_live_wallpaper():
        message_label.visible = true
        message_label.text = "Wallpaper plugin unavailable; install v1.5.1 and use Android Gradle export."

func _load_garage() -> void:
    var config := ConfigFile.new()
    if config.load("user://garage.cfg") == OK:
        selected = clampi(int(config.get_value("garage", "selected", 0)), 0, CARS.size() - 1)
        auto_shift = bool(config.get_value("garage", "auto_shift", false))

func _save_garage() -> void:
    var config := ConfigFile.new()
    config.set_value("garage", "selected", selected)
    config.set_value("garage", "auto_shift", auto_shift)
    var result := config.save("user://garage.cfg")
    if result != OK:
        push_warning("Could not persist selected car.")
