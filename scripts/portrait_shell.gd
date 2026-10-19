extends Control
## Mobile portrait UI. Each scene is native, separately tappable and responsive.
signal action_selected(action: String)
const Wheels = preload("res://scripts/wheel_layers.gd")
const CARS := [
    "res://assets/cars/civic_hatch_game.png",
    "res://assets/cars/supra_mk4_game.png",
    "res://assets/cars/del_sol_game.png",
    "res://assets/cars/trueno_ae86_game.png"
]
const CYAN := Color("37dafa")
const PINK := Color("ff3d91")
const GOLD := Color("ffc55f")
const BG := Color("081020")
const MAX_FONTSIZE := 28
var section := "menu"
var data: Dictionary = {}
var _cars: Array[Texture2D] = []
var _car_parts: Array[Dictionary] = []
var _font: Font

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _font = ThemeDB.fallback_font
    for idx in range(CARS.size()):
        var texture := load(CARS[idx]) as Texture2D
        _cars.append(texture)
        if texture != null:
            _car_parts.append(Wheels.build(texture, idx))

func _ui_label(txt: String, x1: float, y1: float, x2: float, y2: float, font_scale: float = 0.048, color: Color = Color.WHITE, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
    var l := Label.new()
    l.text = txt
    l.anchor_left = x1; l.anchor_right = x2
    l.anchor_top = y1; l.anchor_bottom = y2
    l.horizontal_alignment = align
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size", clampi(int(size.x * font_scale), 12, MAX_FONTSIZE))
    l.add_theme_color_override("font_color", color)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(l)
    return l

func _button(txt: String, x1: float, y1: float, x2: float, y2: float, action: String, accent: Color = CYAN) -> Button:
    var b := Button.new()
    b.text = txt
    b.anchor_left = x1; b.anchor_right = x2
    b.anchor_top = y1; b.anchor_bottom = y2
    b.offset_left = 3; b.offset_right = -3
    b.offset_top = 4; b.offset_bottom = -4
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_font_size_override("font_size", clampi(int(size.x * 0.042), 13, 23))
    b.add_theme_color_override("font_color", Color("f6f9ff"))
    for mode in ["normal", "hover", "pressed", "disabled"]:
        var style := StyleBoxFlat.new()
        style.bg_color = Color("0d2338") if mode == "normal" else Color("1a3f52")
        style.border_color = accent
        style.set_border_width_all(2)
        style.set_corner_radius_all(10)
        b.add_theme_stylebox_override(mode, style)
    b.pressed.connect(func(): action_selected.emit(action))
    add_child(b)
    return b

func present(target: String, state: Dictionary) -> void:
    section = target
    data = state.duplicate(true)
    for child in get_children():
        child.hide()
        child.queue_free()
    queue_redraw()
    _ui_label("DRAG", 0.08, 0.04, 0.92, 0.105, 0.122, Color("f5faff"))
    _ui_label("MINI", 0.08, 0.099, 0.92, 0.164, 0.115, PINK)
    _ui_label("◉  %s    ★  LV.%d" % [str(data.get("cash", 0)), int(data.get("level", 1))],
        0.07, 0.171, 0.93, 0.209, 0.043, GOLD)
    if section != "menu":
        _button("‹  BACK", 0.055, 0.215, 0.34, 0.27, "menu", PINK)
    match section:
        "menu":
            _home()
        "garage":
            _garage()
        "upgrades":
            _upgrades()
        "settings":
            _settings()
        "career":
            _career()
        "race_select":
            _race_select()
        "wallpaper":
            _wallpaper()
        "wallpaper_preview":
            _wallpaper()
        _:
            _home()

func _home() -> void:
    _ui_label("THE STREETS ARE YOURS", 0.07, 0.22, 0.93, 0.268, 0.051, GOLD)
    _ui_label(str(data.get("car_name", "YOUR RIDE")), 0.05, 0.48, 0.95, 0.526, 0.043, Color.WHITE)
    _ui_label("CAREER  %02d / 12    •    %d WINS" % [int(data.get("stage", 0)) + 1, int(data.get("wins", 0))],
        0.05, 0.60, 0.95, 0.64, 0.041, CYAN)
    _button("RACE", 0.06, 0.675, 0.49, 0.742, "race_select")
    _button("CAREER", 0.51, 0.675, 0.94, 0.742, "career", GOLD)
    _button("GARAGE", 0.06, 0.749, 0.49, 0.816, "garage")
    _button("UPGRADES", 0.51, 0.749, 0.94, 0.816, "upgrades", PINK)
    _button("WALLPAPER", 0.06, 0.823, 0.49, 0.89, "wallpaper", GOLD)
    _button("SETTINGS", 0.51, 0.823, 0.94, 0.89, "settings")
    _button("▶  QUICK START", 0.06, 0.904, 0.94, 0.983, "start", Color("55ff76"))

func _garage() -> void:
    _ui_label("YOUR GARAGE", 0.07, 0.28, 0.93, 0.337, 0.074, CYAN)
    _ui_label(str(data.get("car_name", "")), 0.04, 0.59, 0.96, 0.645, 0.059)
    _button("◀ PREV", 0.065, 0.661, 0.48, 0.729, "car_prev")
    _button("NEXT ▶", 0.52, 0.661, 0.935, 0.729, "car_next")
    _ui_label("VEHICLE %d OF 4  •  ENGINE: %.0f HP" % [int(data.get("car", 0)) + 1, float(data.get("power", 0.0))],
        0.05, 0.747, 0.95, 0.79, 0.042, GOLD)
    _button("UPGRADE CAR", 0.06, 0.815, 0.94, 0.88, "upgrades", PINK)
    _button("RACE THIS CAR", 0.06, 0.902, 0.94, 0.98, "race_select", Color("55ff76"))

func _upgrades() -> void:
    _ui_label("PERFORMANCE LAB  •  TIER 0-5", 0.05, 0.283, 0.95, 0.337, 0.059, PINK)
    var items: Array = data.get("parts", [])
    for i in range(items.size()):
        var part: Dictionary = items[i]
        var yy := 0.35 + float(i) * 0.075
        var cost := int(part["cost"])
        var lv := int(part["level"])
        var sub := "MAXED" if lv >= 5 else ("$%d" % cost)
        var text_value := "%s   %d/5  •  %s" % [str(part["name"]), lv, sub]
        _button(text_value, 0.048, yy, 0.952, yy + 0.067, "upgrade:" + str(part["id"]),
            Color("50ef96") if lv >= 5 else (PINK if i % 2 == 0 else CYAN))
    _ui_label(str(data.get("notice", "Buy upgrades to improve lap times.")), 0.07, 0.893, 0.93, 0.974, 0.040, GOLD)

func _settings() -> void:
    _ui_label("SETTINGS", 0.05, 0.29, 0.95, 0.35, 0.079, CYAN)
    _button("SHIFT: " + ("AUTO" if bool(data.get("auto_shift", false)) else "MANUAL"),
        0.055, 0.37, 0.945, 0.445, "toggle_shift")
    _button("SPEED: " + ("KM/H" if bool(data.get("kmh", true)) else "MPH"),
        0.055, 0.46, 0.945, 0.535, "toggle_units")
    _button("VIBRATION: " + ("ON" if bool(data.get("vibration", true)) else "OFF"),
        0.055, 0.55, 0.945, 0.625, "toggle_vibration")
    _button("TIME OF DAY: " + ("DEVICE TIME" if bool(data.get("dynamic", true)) else "NEON NIGHT"),
        0.055, 0.64, 0.945, 0.715, "toggle_time", PINK)
    _button("WALLPAPER TOUCH: " + ("ON" if bool(data.get("wallpaper_interactive", true)) else "OFF"),
        0.055, 0.73, 0.945, 0.805, "toggle_wallpaper_touch", GOLD)
    _ui_label("Your settings and upgrades save locally.", 0.07, 0.84, 0.93, 0.90, 0.043, Color("c3cbdc"))

func _career() -> void:
    _ui_label("STREET STORY", 0.04, 0.288, 0.96, 0.349, 0.071, PINK)
    _ui_label("CHAPTER %d / 12" % (int(data.get("stage", 0)) + 1), 0.06, 0.375, 0.94, 0.419, 0.052, GOLD)
    _ui_label(str(data.get("story", "")), 0.055, 0.435, 0.945, 0.511, 0.074)
    _ui_label(str(data.get("story_distance", "1/4 MILE")), 0.08, 0.529, 0.92, 0.586, 0.058, CYAN)
    _ui_label("WIN TO UNLOCK THE NEXT CHAPTER", 0.05, 0.64, 0.95, 0.698, 0.044, Color("bac7d8"))
    _ui_label("STAGE PRIZE   $%d" % int(data.get("story_prize", 0)), 0.07, 0.73, 0.93, 0.78, 0.055, GOLD)
    _button("▶  CHALLENGE RIVAL", 0.05, 0.866, 0.95, 0.969, "career_start", Color("52f48a"))

func _race_select() -> void:
    _ui_label("CHOOSE YOUR DISTANCE", 0.04, 0.29, 0.96, 0.352, 0.059, CYAN)
    var distances := ["1/8 MILE  •  201m", "1/4 MILE  •  402m", "1/2 MILE  •  805m", "1 MILE  •  1609m"]
    for i in range(distances.size()):
        _button(("◆ " if i == int(data.get("distance_choice", 1)) else "") + distances[i],
            0.06, 0.378 + float(i) * 0.103, 0.94, 0.466 + float(i) * 0.103,
            "distance:" + str(i), GOLD if i == int(data.get("distance_choice", 1)) else CYAN)
    _button("▶  START RACE", 0.06, 0.855, 0.94, 0.965, "start", Color("52ff78"))

func _wallpaper() -> void:
    _ui_label("LIVE WALLPAPER", 0.04, 0.29, 0.96, 0.36, 0.068, PINK)
    _ui_label("YOUR GARAGE. YOUR HOME SCREEN.", 0.07, 0.39, 0.93, 0.45, 0.05, CYAN)
    _ui_label("Drive the scene with your chosen ride.\nInteractive touches depend on your launcher.",
        0.07, 0.49, 0.93, 0.62, 0.048, Color("c9d9e9"))
    _button("SET LIVE WALLPAPER", 0.07, 0.685, 0.93, 0.773, "wallpaper_apply", Color("57ff8a"))
    _button("PREVIEW WALLPAPER", 0.07, 0.795, 0.93, 0.879, "wallpaper_preview")
    _ui_label(str(data.get("notice", "")), 0.06, 0.893, 0.94, 0.973, 0.037, GOLD)

func _draw() -> void:
    var w := size.x; var h := size.y
    if w < 2.0 or h < 2.0:
        return
    draw_rect(Rect2(Vector2.ZERO, size), BG)
    for i in range(28):
        var yy := h * float(i) / 35.0
        draw_rect(Rect2(0, yy, w, h / 34.0), BG.lerp(Color("242451"), float(i) / 44.0))
    for i in range(25):
        var px := fposmod(float(i * 117 + 19), w)
        draw_circle(Vector2(px, h * float((i * 7) % 29) / 95.0), 1.0 + float(i % 2), Color("8ad4f4", 0.65))
    for i in range(21):
        var px := float(i) * w / 20.0
        var ht := h * (0.062 + float((i * 17) % 9) * 0.013)
        draw_rect(Rect2(px, h * 0.55 - ht, w / 17.0, ht), Color("102542"))
        for j in range(3):
            draw_rect(Rect2(px + 5.0, h * 0.55 - ht + 14 + j * 13, 3.0, 4.0), CYAN if i % 2 else PINK)
    draw_rect(Rect2(0, h * 0.547, w, h * 0.1), Color("0b1425"))
    draw_line(Vector2(0, h * 0.645), Vector2(w, h * 0.645), PINK, 2.0)
    if _cars.size() < 4:
        return
    var index := clampi(int(data.get("car", 0)), 0, 3)
    if section == "menu":
        # All 4 owner car art files are independent, correct-aspect textures.
        _car(_cars[index], Rect2(w * 0.08, h * 0.295, w * 0.84, w * 0.84 * 54.0 / 128.0))
        for i in range(4):
            var sx := w * (0.025 + i * 0.244)
            _car(_cars[i], Rect2(sx, h * 0.535, w * 0.23, w * 0.23 * 54.0 / 128.0))
    elif section == "garage":
        _car(_cars[index], Rect2(w * 0.05, h * 0.385, w * 0.90, w * 0.90 * 54.0 / 128.0))
    elif section in ["career", "race_select", "wallpaper", "wallpaper_preview"]:
        _car(_cars[index], Rect2(w * 0.16, h * 0.56, w * 0.68, w * 0.68 * 54.0 / 128.0))

func _car(texture: Texture2D, r: Rect2) -> void:
    if texture == null:
        return
    draw_rect(Rect2(r.position.x + 8, r.end.y - 10, r.size.x - 16, 12), Color(0.0, 0.0, 0.0, 0.37))
    var idx := _cars.find(texture)
    if idx >= 0 and idx < _car_parts.size():
        Wheels.draw_car(self, _car_parts[idx], r, 0.0)
    else:
        draw_texture_rect(texture, r, false)
