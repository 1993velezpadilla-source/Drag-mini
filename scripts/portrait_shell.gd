extends Control
## DRAG MINI - Street Edition: 9:20 portrait-native premium UI.
## No screenshots, no flattened menu. Pixel-inspired scenes and 4 independent owner cars.
signal action_selected(action: String)

const WHEELS = preload("res://scripts/wheel_layers.gd")
const CAR_PATHS := [
    "res://assets/cars/civic_hatch_game.png",
    "res://assets/cars/supra_mk4_game.png",
    "res://assets/cars/del_sol_game.png",
    "res://assets/cars/trueno_ae86_game.png"
]
const BG := Color("080d16")
const PANEL := Color("101c2a")
const CYAN := Color("57dbef")
const PINK := Color("ff598c")
const GOLD := Color("f8c77a")
const GREEN := Color("6cf3b2")
const MUTED := Color("b0c3d4")
var section := "menu"
var data: Dictionary = {}
var _cars: Array[Texture2D] = []
var _car_parts: Array[Dictionary] = []
var _motion := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for i in range(CAR_PATHS.size()):
        var tex := load(CAR_PATHS[i]) as Texture2D
        _cars.append(tex)
        _car_parts.append(WHEELS.build(tex, i) if tex != null else {})
    set_process(false)

func _process(delta: float) -> void:
    _motion = fposmod(_motion + delta, 4096.0)
    queue_redraw()

func _text(t: String, x1: float, y1: float, x2: float, y2: float,
        font: float = 0.043, color: Color = Color.WHITE,
        align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
    var l := Label.new()
    l.text = t
    l.anchor_left = x1
    l.anchor_right = x2
    l.anchor_top = y1
    l.anchor_bottom = y2
    l.horizontal_alignment = align
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.clip_text = true
    l.add_theme_font_size_override("font_size", clampi(int(size.x * font), 12, 48))
    l.add_theme_color_override("font_color", color)
    if font > 0.065:
        l.add_theme_constant_override("outline_size", 3)
        l.add_theme_color_override("font_outline_color", Color("060912"))
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(l)
    return l

func _button(t: String, x1: float, y1: float, x2: float, y2: float,
        action: String, glow: Color = CYAN) -> Button:
    var btn := Button.new()
    btn.text = t
    btn.anchor_left = x1
    btn.anchor_right = x2
    btn.anchor_top = y1
    btn.anchor_bottom = y2
    btn.offset_left = 2
    btn.offset_right = -2
    btn.offset_top = 2
    btn.offset_bottom = -2
    btn.focus_mode = Control.FOCUS_NONE
    btn.add_theme_font_size_override("font_size", clampi(int(size.x * 0.040), 13, 23))
    btn.add_theme_color_override("font_color", Color("f6faff"))
    var normal := StyleBoxFlat.new()
    normal.bg_color = PANEL
    normal.border_color = Color(glow.r, glow.g, glow.b, 0.80)
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(11)
    normal.shadow_size = 4
    normal.shadow_color = Color(glow.r, glow.g, glow.b, 0.14)
    btn.add_theme_stylebox_override("normal", normal)
    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color(glow.r * 0.26, glow.g * 0.26, glow.b * 0.26)
    pressed.border_color = glow
    btn.add_theme_stylebox_override("pressed", pressed)
    btn.add_theme_stylebox_override("hover", pressed)
    btn.pressed.connect(func(): action_selected.emit(action))
    add_child(btn)
    return btn

func _heading(label: String, subtitle: String, color: Color = CYAN) -> void:
    _text(label, 0.06, 0.282, 0.94, 0.345, 0.074, color)
    _text(subtitle, 0.05, 0.345, 0.95, 0.387, 0.033, MUTED)

func present(next_page: String, state: Dictionary) -> void:
    section = next_page
    data = state.duplicate(true)
    set_process(next_page == "menu")
    for child in get_children():
        child.hide()
        child.queue_free()
    queue_redraw()
    _text("DRAG", 0.06, 0.028, 0.94, 0.108, 0.136, Color("f2f5ff"))
    _text("MINI", 0.06, 0.099, 0.94, 0.162, 0.111, PINK)
    _text("STREET EDITION     ◆     LV.%d" % int(data.get("level", 1)),
        0.06, 0.163, 0.94, 0.196, 0.035, GOLD)
    _text("CREDITS  $%s" % str(data.get("cash", 0)),
        0.05, 0.197, 0.95, 0.232, 0.049, Color("fff0cf"))
    if section != "menu":
        _button("‹  HOME", 0.058, 0.238, 0.340, 0.279, "menu", PINK)
    match section:
        "menu": _home()
        "garage": _garage()
        "upgrades": _upgrades()
        "tune": _tune()
        "settings": _settings()
        "career": _career()
        "race_select": _race_select()
        "wallpaper", "wallpaper_preview": _wallpaper()
        _: _home()

func _home() -> void:
    _text("BUILD  ◆  TUNE  ◆  RACE", 0.07, 0.247, 0.93, 0.29, 0.051, GOLD)
    _text(str(data.get("car_name", "YOUR GARAGE")), 0.06, 0.478, 0.94, 0.522, 0.046)
    _text("CAREER %02d / 12   •   %d VICTORIES" %
        [int(data.get("stage", 0)) + 1, int(data.get("wins", 0))],
        0.05, 0.587, 0.95, 0.622, 0.038, GOLD)
    _button("RACE", 0.055, 0.663, 0.488, 0.733, "race_select", GREEN)
    _button("CAREER", 0.512, 0.663, 0.945, 0.733, "career", GOLD)
    _button("GARAGE", 0.055, 0.739, 0.488, 0.810, "garage")
    _button("UPGRADES", 0.512, 0.739, 0.945, 0.810, "upgrades", PINK)
    _button("WALLPAPER", 0.055, 0.816, 0.488, 0.885, "wallpaper", GOLD)
    _button("SETTINGS", 0.512, 0.816, 0.945, 0.885, "settings")
    _button("▶  QUICK START", 0.055, 0.906, 0.945, 0.983, "start", GREEN)

func _garage() -> void:
    _heading("THE GARAGE", "BUILD YOUR IDENTITY  /  SELECT CHASSIS")
    _text(str(data.get("car_name", "")), 0.05, 0.557, 0.95, 0.618, 0.067)
    _button("‹ PREV", 0.057, 0.645, 0.480, 0.710, "car_prev", GOLD)
    _button("NEXT ›", 0.52, 0.645, 0.943, 0.710, "car_next", GOLD)
    _text("%d / 4   •   EST. %.0f HP" % [int(data.get("car", 0)) + 1, float(data.get("power", 0.0))],
        0.05, 0.722, 0.95, 0.777, 0.052, GREEN)
    _button("DYNO & FINE TUNE", 0.055, 0.788, 0.945, 0.851, "tune", CYAN)
    _button("▶  TAKE IT TO THE STRIP", 0.055, 0.877, 0.945, 0.962, "race_select", GREEN)

func _upgrades() -> void:
    _heading("PERFORMANCE LAB", "7 SYSTEMS  /  5 LEVELS EACH", PINK)
    var parts: Array = data.get("parts", [])
    for i in range(parts.size()):
        var part: Dictionary = parts[i]
        var yy := 0.395 + float(i) * 0.0685
        var lv := int(part.get("level", 0))
        var cost := int(part.get("cost", 0))
        var desc := "MAX" if lv == 5 else "$%d" % cost
        _button("%s     T%d / 5     %s" % [str(part.get("name", "")), lv, desc],
            0.055, yy, 0.945, yy + 0.060, "upgrade:" + str(part["id"]),
            GREEN if lv == 5 else (PINK if i % 2 == 0 else CYAN))
    _text(str(data.get("notice", "Build, test, repeat.")), 0.06, 0.887, 0.94, 0.929, 0.036, GOLD)
    _button("TUNE YOUR BUILD", 0.055, 0.934, 0.945, 0.987, "tune", GREEN)

func _tune() -> void:
    _heading("DYNO / TUNE", "REAL TIME SETUP  •  ADJUST AND TEST", GREEN)
    var values: Dictionary = data.get("tune", {})
    var names := ["FINAL DRIVE", "TIRE PRESSURE", "AUTO SHIFT RPM", "LAUNCH TARGET"]
    var ids := ["final_drive", "tire_pressure", "shift_target", "launch_rpm"]
    var formats := ["%.2f x", "%.0f PSI", "%.0f %%", "%.0f RPM"]
    for i in range(4):
        var field: String = ids[i]
        var val: float = float(values.get(field, [1.0, 28.0, 0.91, 4000.0][i]))
        var shown := val * 100.0 if i == 2 else val
        var yy := 0.485 + float(i) * 0.078
        _text(names[i], 0.07, yy - 0.023, 0.93, yy, 0.036, MUTED)
        _button("−", 0.06, yy, 0.235, yy + 0.054, "tune:" + field + ":-1", PINK)
        _text(formats[i] % shown, 0.24, yy, 0.77, yy + 0.054, 0.050, GOLD)
        _button("+", 0.765, yy, 0.94, yy + 0.054, "tune:" + field + ":1", GREEN)
    _button("▶  TEST TUNE ON STRIP", 0.055, 0.876, 0.945, 0.958, "race_select", GREEN)

func _settings() -> void:
    _heading("RACE SETTINGS", "YOUR COCKPIT. YOUR RULES.")
    var rows := [
        ["SHIFT: " + ("AUTO" if bool(data.get("auto_shift", false)) else "MANUAL"), "toggle_shift"],
        ["SPEED: " + ("KM/H" if bool(data.get("kmh", true)) else "MPH"), "toggle_units"],
        ["ENGINE SOUND: " + ("ON" if bool(data.get("audio", true)) else "OFF"), "toggle_audio"],
        ["VIBRATION: " + ("ON" if bool(data.get("vibration", true)) else "OFF"), "toggle_vibration"],
        ["TIME: " + ("PHONE CLOCK" if bool(data.get("dynamic", true)) else "MIDNIGHT"), "toggle_time"],
        ["WALLPAPER TOUCH: " + ("ON" if bool(data.get("wallpaper_interactive", true)) else "OFF"), "toggle_wallpaper_touch"]
    ]
    for i in range(rows.size()):
        var y := 0.395 + float(i) * 0.086
        _button(rows[i][0], 0.060, y, 0.940, y + 0.073, rows[i][1],
            CYAN if i % 2 == 0 else PINK)
    _text("ALL SETTINGS SAVED OFFLINE", 0.075, 0.926, 0.925, 0.972, 0.035, GOLD)

func _career() -> void:
    _heading("STREET STORY", "CHAPTER %02d / 12" % [int(data.get("stage", 0)) + 1], PINK)
    _text(str(data.get("story", "")), 0.06, 0.420, 0.94, 0.483, 0.066)
    _text(str(data.get("story_distance", "1/4 MILE")), 0.06, 0.490, 0.94, 0.536, 0.061, CYAN)
    _text("RIVAL  /  " + str(data.get("rival_name", "")), 0.07, 0.553, 0.93, 0.608, 0.057, GOLD)
    _text(str(data.get("dialogue", "")), 0.09, 0.628, 0.91, 0.724, 0.038, MUTED)
    _text("WIN PURSE   $%d" % int(data.get("story_prize", 0)),
        0.06, 0.755, 0.94, 0.813, 0.052, GOLD)
    _button("▶  CHALLENGE RIVAL", 0.055, 0.879, 0.945, 0.969, "career_start", GREEN)

func _race_select() -> void:
    _heading("TEST & RACE", "SELECT THE STRIP DISTANCE", GREEN)
    var dist := ["1/8 MILE     201 M", "1/4 MILE     402 M", "1/2 MILE     805 M", "FULL MILE     1609 M"]
    for i in range(dist.size()):
        var y := 0.395 + float(i) * 0.097
        _button(("◆  " if i == int(data.get("distance_choice", 1)) else "   ") + dist[i],
            0.065, y, 0.935, y + 0.082, "distance:" + str(i),
            GOLD if i == int(data.get("distance_choice", 1)) else CYAN)
    _text("TUNE THE LAUNCH. PERFECT THE SHIFT.", 0.06, 0.806, 0.94, 0.858, 0.038, MUTED)
    _button("▶  LINE UP", 0.055, 0.875, 0.945, 0.963, "start", GREEN)

func _wallpaper() -> void:
    _heading("LIVE WALLPAPER", "DRAG MINI • ON YOUR HOME SCREEN", PINK)
    _text("YOUR CAR  /  THE PIXEL CITY", 0.07, 0.403, 0.93, 0.455, 0.049, GOLD)
    _text("Tap to rev  •  Swipe to swap cars", 0.05, 0.480, 0.95, 0.533, 0.040, MUTED)
    _button("SET ANDROID LIVE WALLPAPER", 0.055, 0.739, 0.945, 0.817, "wallpaper_apply", GREEN)
    _button("PREVIEW WALLPAPER", 0.055, 0.830, 0.945, 0.900, "wallpaper_preview")
    _text(str(data.get("notice", "Requires a supported Android launcher.")),
        0.05, 0.913, 0.95, 0.980, 0.033, GOLD)

func _draw() -> void:
    var w := size.x
    var h := size.y
    if w < 4.0 or h < 4.0:
        return
    draw_rect(Rect2(Vector2.ZERO, size), BG)
    _scene(w, h)
    # Header remains clear and legible over all backdrops.
    _box(w * 0.03, h * 0.019, w * 0.94, h * 0.216, Color("050b16", 0.93), PINK)
    if section == "menu":
        _box(w * 0.035, h * 0.635, w * 0.93, h * 0.345, Color("050d1b", 0.90), CYAN)
        _car_clipped(w, h, 0.08, 0.319, 0.84, 0.0, true)
        for i in range(4):
            _car_clipped(w, h, 0.035 + float(i) * 0.244, 0.532, 0.225, float(i), false)
    elif section == "garage":
        _box(w * 0.045, h * 0.308, w * 0.91, h * 0.23, Color("0b1a29", 0.9), CYAN)
        _car_clipped(w, h, 0.075, 0.403, 0.85, 0.0, false)
    elif section == "tune":
        _box(w * 0.045, h * 0.321, w * 0.91, h * 0.140, Color("0b1a29", 0.94), GREEN)
        _car_clipped(w, h, 0.30, 0.355, 0.40, 0.0, false)
        _draw_dyno(w, h)
    elif section in ["upgrades", "settings", "race_select", "career", "wallpaper", "wallpaper_preview"]:
        _box(w * 0.042, h * 0.307, w * 0.916, h * 0.545, Color("071222", 0.94), CYAN if section != "career" else PINK)
        if section == "wallpaper" or section == "wallpaper_preview":
            _car_clipped(w, h, 0.12, 0.580, 0.76, 0.0, false)

func _scene(w: float, h: float) -> void:
    # Original 2.5D-inspired pixel skyline, all drawn in engine, never flattened.
    var hue := Color("0e2a45") if section in ["garage", "tune"] else Color("22213e")
    for i in range(24):
        var yy := float(i) * h / 25.0
        draw_rect(Rect2(0, yy, w, h / 24.0), BG.lerp(hue, float(i) * 0.014))
    for j in range(28):
        var xx := fposmod(float(j) * 91.0 + 14.0, w)
        var yy := fposmod(float(j * 59), h * 0.49)
        draw_rect(Rect2(xx, yy, 2, 2), Color("aac5e9", 0.43))
    var band := h * 0.59
    for i in range(19):
        var width := w / 18.0
        var x := float(i) * width - 3.0
        var bh := h * (0.06 + float((i * 13 + 3) % 9) * 0.013)
        var building := Color("0e2134") if i % 3 else Color("162a43")
        draw_rect(Rect2(x, band - bh, width + 1, bh), building)
        for row in range(3):
            var y := band - bh + 9.0 + row * 16.0
            if y < band - 3:
                draw_rect(Rect2(x + 5, y, 3, 5), CYAN if i % 2 else PINK)
                draw_rect(Rect2(x + 14, y, 3, 5), GOLD if i % 5 == 0 else Color("1c4962"))
    draw_rect(Rect2(0, band, w, h * 0.41), Color("091524"))
    draw_line(Vector2(0, band + 5), Vector2(w, band + 5), PINK, 2.0)
    for i in range(35):
        var x := fposmod(float(i * 131) - _motion * 8.0, w + 140.0) - 60.0
        var y := band + float((i * 41) % 320) * h / 960.0
        draw_rect(Rect2(x, y, 21.0 + float(i % 5) * 12.0, 1.0),
            Color(CYAN.r, CYAN.g, CYAN.b, 0.12))
    if section in ["garage", "tune"]:
        for i in range(7):
            draw_line(Vector2(w * float(i) / 6.0, band - h * 0.10),
                Vector2(w * float(i) / 6.0, band + h * 0.16), Color("1f5674", 0.20), 1.0)

func _box(x: float, y: float, w: float, h: float, fill: Color, rim: Color) -> void:
    draw_rect(Rect2(x, y, w, h), fill)
    draw_rect(Rect2(x, y, w, h), Color(rim.r, rim.g, rim.b, 0.48), false, 2.0)
    draw_rect(Rect2(x + 4, y + 4, w - 8, 2.0), Color(rim.r, rim.g, rim.b, 0.2))

func _car_clipped(w: float, h: float, bx: float, by: float, bw: float, idx: float, animate: bool) -> void:
    if _cars.size() != 4:
        return
    var car: int = int(idx) if idx > 0 else clampi(int(data.get("car", 0)), 0, 3)
    # Four on home are independent sprites; idx zero must be Civic in first slot.
    if section == "menu" and bw < 0.3:
        car = int(idx)
    var width := w * bw
    var bob := sin(_motion * 1.4) * 2.0 if animate else 0.0
    var bounds := Rect2(w * bx, h * by + bob, width, width * 54.0 / 128.0)
    var shadow := Rect2(bounds.position.x + bounds.size.x * 0.12,
        bounds.end.y - 6, bounds.size.x * 0.76, 7)
    draw_rect(shadow, Color(0, 0, 0, 0.48))
    if _car_parts[car].is_empty():
        if _cars[car] != null:
            draw_texture_rect(_cars[car], bounds, false)
    else:
        WHEELS.draw_car(self, _car_parts[car], bounds, _motion * 0.2 if animate else 0.0)

func _draw_dyno(w: float, h: float) -> void:
    var left := w * 0.11
    var top := h * 0.804
    var chart_w := w * 0.78
    var chart_h := h * 0.062
    var boost := float(data.get("tune", {}).get("final_drive", 1.0))
    for i in range(5):
        draw_line(Vector2(left, top + i * chart_h / 4.0),
            Vector2(left + chart_w, top + i * chart_h / 4.0), Color("32475a", 0.65), 1)
    for i in range(50):
        var u := float(i) / 49.0
        var v := float(i + 1) / 49.0
        var torque_a := clampf(sin(u * PI * 0.80) * (0.58 + boost * 0.17) + 0.11, 0.0, 0.96)
        var torque_b := clampf(sin(v * PI * 0.80) * (0.58 + boost * 0.17) + 0.11, 0.0, 0.96)
        draw_line(Vector2(left + u * chart_w, top + chart_h * (1.0 - torque_a)),
            Vector2(left + v * chart_w, top + chart_h * (1.0 - torque_b)), GREEN, 2.0)
