extends Control
## DRAG MINI native, layered Godot menu. No screenshot/flattened menu texture.
## Layout is authored in the 1536x864 design coordinate system and scales
## to any landscape viewport. Individual cars remain separate PNG textures.
signal action_selected(action: String)

const DESIGN := Vector2(1536.0, 864.0)
const CAR_ART := [
    "res://assets/cars/supra_mk4_game.png",
    "res://assets/cars/del_sol_game.png",
    "res://assets/cars/civic_hatch_game.png",
    "res://assets/cars/trueno_ae86_game.png"
]
const ACTIONS := ["race", "garage", "wallpaper", "upgrades", "settings", "start"]
const ACTION_TITLES := ["RACE", "GARAGE", "WALLPAPER", "UPGRADES", "SETTINGS", "START"]
const ACTION_GLYPHS := ["⚑", "▣", "▧", "⚒", "⚙", "❯❯"]
const ACTION_RECTS := [
    Rect2(46, 686, 219, 118),
    Rect2(272, 686, 190, 118),
    Rect2(469, 686, 199, 118),
    Rect2(676, 686, 195, 118),
    Rect2(879, 686, 194, 118),
    Rect2(1083, 682, 424, 128)
]
const CYAN := Color("21cfff")
const PINK := Color("ff2384")
const NAVY := Color("061426")
const GREEN := Color("54ff48")

var _font: SystemFont
var _cars: Array[Texture2D] = []
var _tap_locked := false
var _title_drag: Label
var _title_mini: Label
var _hotspots: Dictionary = {}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _font = SystemFont.new()
    _font.font_names = PackedStringArray(["Arial Black", "Impact", "Roboto Condensed", "sans-serif-condensed"])
    for path in CAR_ART:
        var texture := load(path) as Texture2D
        if texture == null:
            push_error("DRAG MINI menu is missing separate car PNG: " + path)
        _cars.append(texture)
    _create_logo()
    _create_hud()
    _create_buttons()
    # No photo TextureRect, no single full-frame PNG, no fake hotspots.
    queue_redraw()

func _label(text_value: String, box: Rect2, font_size: int, ink: Color, alignment: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
    var label := Label.new()
    label.text = text_value
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.anchor_left = box.position.x / DESIGN.x
    label.anchor_top = box.position.y / DESIGN.y
    label.anchor_right = box.end.x / DESIGN.x
    label.anchor_bottom = box.end.y / DESIGN.y
    label.horizontal_alignment = alignment
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.clip_text = true
    label.add_theme_font_override("font", _font)
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", ink)
    add_child(label)
    return label

func _create_logo() -> void:
    _title_drag = _label("DRAG", Rect2(475, 105, 590, 148), 143, Color("f8f8fc"))
    _title_drag.add_theme_constant_override("outline_size", 9)
    _title_drag.add_theme_color_override("font_outline_color", Color("03030a"))
    _title_drag.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
    _title_mini = _label("MINI", Rect2(554, 215, 439, 124), 116, PINK)
    _title_mini.add_theme_constant_override("outline_size", 9)
    _title_mini.add_theme_color_override("font_outline_color", Color("080414"))
    _label("ドラッグミニ", Rect2(617, 328, 298, 33), 27, Color("e4e7ef"))

func _create_hud() -> void:
    _label("PLAYER", Rect2(168, 28, 160, 38), 28, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
    _label("Lv. 12", Rect2(168, 60, 126, 30), 20, Color("e7f2ff"), HORIZONTAL_ALIGNMENT_LEFT)
    _label("◉", Rect2(62, 24, 79, 72), 62, Color("eaf5ff"))
    _label("125,340", Rect2(1013, 20, 120, 44), 26, Color.WHITE)
    _label("850", Rect2(1240, 20, 80, 44), 26, Color.WHITE)
    _label("+", Rect2(1136, 24, 37, 37), 34, Color.WHITE)
    _label("+", Rect2(1332, 24, 38, 37), 34, Color.WHITE)
    _label("✉", Rect2(1391, 21, 48, 49), 36, Color.WHITE)
    _label("★", Rect2(1463, 21, 50, 49), 38, Color.WHITE)

func _create_buttons() -> void:
    for i in range(ACTIONS.size()):
        var action: String = ACTIONS[i]
        var box: Rect2 = ACTION_RECTS[i]
        var btn := Button.new()
        btn.name = action.capitalize() + "Touch"
        btn.text = ""
        btn.focus_mode = Control.FOCUS_NONE
        btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        btn.anchor_left = box.position.x / DESIGN.x
        btn.anchor_top = box.position.y / DESIGN.y
        btn.anchor_right = box.end.x / DESIGN.x
        btn.anchor_bottom = box.end.y / DESIGN.y
        var neon := GREEN if action == "start" else (Color("ac70ff") if action == "wallpaper" else (Color("efb955") if action == "upgrades" else CYAN))
        for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
            var style := StyleBoxFlat.new()
            style.bg_color = Color(0.0, 0.06, 0.12, 0.02)
            if style_name == "hover":
                style.bg_color = Color(neon.r, neon.g, neon.b, 0.16)
            elif style_name == "pressed":
                style.bg_color = Color(neon.r, neon.g, neon.b, 0.32)
            style.border_color = Color(neon.r, neon.g, neon.b, 0.0 if style_name == "normal" else 0.75)
            style.set_border_width_all(0 if style_name == "normal" else 3)
            style.set_corner_radius_all(10)
            btn.add_theme_stylebox_override(style_name, style)
        btn.pressed.connect(_on_button_pressed.bind(action, btn))
        add_child(btn)
        _hotspots[action] = btn
        var glyph_col := neon if i != 0 else Color.WHITE
        var icon_box := Rect2(box.position.x, box.position.y + 6, box.size.x, 57)
        var text_box := Rect2(box.position.x, box.position.y + 64, box.size.x, 43)
        if action == "start":
            icon_box = Rect2(box.position.x + 22, box.position.y + 18, 125, 75)
            text_box = Rect2(box.position.x + 132, box.position.y + 18, box.size.x - 155, 75)
        var icon_label := _label(ACTION_GLYPHS[i], icon_box, 49 if action == "start" else 45, glyph_col)
        icon_label.name = action.capitalize() + "Icon"
        var text_label := _label(ACTION_TITLES[i], text_box, 60 if action == "start" else 25, Color.WHITE if action != "wallpaper" and action != "upgrades" else neon)
        text_label.name = action.capitalize() + "Title"

func _on_button_pressed(action: String, button: Button) -> void:
    if _tap_locked:
        return
    _tap_locked = true
    if OS.get_name() == "Android":
        Input.vibrate_handheld(22)
    button.modulate = Color(0.7, 1.0, 1.0)
    var t := create_tween()
    t.tween_property(button, "modulate", Color.WHITE, 0.12)
    t.tween_callback(func():
        _tap_locked = false
        action_selected.emit(action)
    )

func _rect(x: float, y: float, w: float, h: float, c: Color) -> void:
    draw_rect(Rect2(x, y, w, h), c)

func _line(a: Vector2, b: Vector2, c: Color, thick: float = 2.0) -> void:
    draw_line(a, b, c, thick)

func _polygon(points: PackedVector2Array, c: Color) -> void:
    draw_colored_polygon(points, c)

func _draw() -> void:
    if size.x < 5.0 or size.y < 5.0:
        return
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(size.x / DESIGN.x, size.y / DESIGN.y))
    _draw_night_sky()
    _draw_skyline()
    _draw_overpass()
    _draw_garage()
    _draw_track_side()
    _draw_neon_road()
    _draw_logo_backplate()
    _draw_car_lineup()
    _draw_hud_panels()
    _draw_action_panels()
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_night_sky() -> void:
    _rect(0, 0, 1536, 864, Color("040b21"))
    for n in range(30):
        var y: float = float(n) * 15.0
        var mix_amount: float = float(n) / 30.0
        _rect(0, y, 1536, 16, Color("071438").lerp(Color("2b1951"), mix_amount * 0.50))
    for i in range(88):
        var x: float = float((i * 149 + 29) % 1536)
        var y: float = float((i * 67 + 17) % 274)
        var alpha := 0.36 + float(i % 4) * 0.12
        _rect(x, y, 2.0 if i % 6 else 3.5, 2.0, Color(0.55, 0.75, 1.0, alpha))
    # Bluish clouds in a very dark upper skyline.
    for c in range(23):
        var cx := float((c * 139 + 31) % 1536)
        var cy := float((c * 31 + 9) % 240)
        draw_circle(Vector2(cx, cy), 34.0 + float(c % 5) * 11.0, Color(0.09, 0.18, 0.40, 0.25))

func _draw_skyline() -> void:
    # Buildings are separate vectors (no image/screenshot city).
    for i in range(52):
        var x := float(i) * 35.0 - 5.0
        var height := 72.0 + float((i * 73) % 235)
        var top := 453.0 - height
        var color := Color("0d1837") if i % 3 else Color("142451")
        _rect(x, top, 34.0, height, color)
        _line(Vector2(x, top), Vector2(x + 34, top), Color("302a7b"), 2.0)
        for yy in range(int(top + 15), 440, 22):
            for xx in range(int(x + 7), int(x + 30), 11):
                var lit := (i * 19 + yy + xx) % 5 != 0
                if lit:
                    _rect(float(xx), float(yy), 4, 8, Color("50a5e1") if (i + yy) % 3 == 0 else Color("f76db4"))
    # Iconic neon tower and Japanese sign zone.
    _rect(1289, 129, 69, 268, Color("171333"))
    _rect(1328, 101, 9, 31, PINK)
    _rect(1300, 146, 51, 182, Color("511d65"))
    _line(Vector2(1300, 145), Vector2(1350, 145), PINK, 6)
    for i in range(8):
        _line(Vector2(1311, 160.0 + float(i) * 21.0), Vector2(1342, 160.0 + float(i) * 21.0), Color("ff5b99"), 3.0)
    _rect(1162, 210, 11, 164, Color("2f7ad0"))
    _rect(1166, 161, 4, 70, Color("ef4abb"))
    _rect(1169, 136, 2, 32, Color("b6d8fa"))
    _rect(1080, 310, 97, 88, Color("21174a"))
    _line(Vector2(1080, 310), Vector2(1176, 310), PINK, 4)

func _draw_overpass() -> void:
    var bridge := PackedVector2Array([
        Vector2(540, 419), Vector2(1536, 320),
        Vector2(1536, 405), Vector2(540, 479)
    ])
    _polygon(bridge, Color("131932"))
    _line(Vector2(530, 409), Vector2(1536, 316), Color("d32180"), 6.0)
    _line(Vector2(530, 420), Vector2(1536, 327), Color("3984c7"), 3.0)
    for i in range(47):
        var x := 565.0 + float(i) * 21.0
        var y := 421.0 - (x - 540.0) * 0.093
        draw_circle(Vector2(x, y), 2.8, PINK if i % 3 else CYAN)
    for i in range(5):
        var x := 670.0 + float(i) * 171.0
        _polygon(PackedVector2Array([Vector2(x, 451), Vector2(x + 24, 449), Vector2(x + 2, 555), Vector2(x - 16, 555)]), Color("12182e"))
        _line(Vector2(x - 15, 551), Vector2(x + 21, 447), Color("383450"), 2.0)

func _draw_garage() -> void:
    # Deep neon workshop and separate doors, signs, tools, roof and tire stacks.
    _rect(0, 110, 532, 373, Color("13152b"))
    _polygon(PackedVector2Array([Vector2(0, 107), Vector2(539, 158), Vector2(539, 191), Vector2(0, 137)]), Color("19182b"))
    for i in range(13):
        _line(Vector2(float(i) * 40.0, 134), Vector2(float(i) * 40.0, 397), Color("303049"), 2.0)
    _rect(214, 277, 267, 206, Color("343044"))
    for i in range(7):
        _rect(225.0 + float(i) * 35.0, 281, 5, 200, Color("52465a"))
    _rect(248, 382, 58, 91, Color("6b2435"))
    _rect(306, 353, 63, 120, Color("873140"))
    _rect(372, 377, 40, 96, Color("632d38"))
    _rect(252, 317, 57, 7, Color("f8e2b5"))
    _rect(357, 323, 102, 8, Color("f7d4a2"))
    _rect(0, 143, 532, 73, Color("17162e"))
    _rect(229, 164, 222, 54, Color("591634"))
    _line(Vector2(229, 162), Vector2(451, 162), Color("fa317c"), 5.0)
    _line(Vector2(227, 221), Vector2(451, 221), Color("ff2f97"), 5.0)
    _line(Vector2(207, 251), Vector2(492, 251), CYAN, 7.0)
    _line(Vector2(23, 113), Vector2(197, 135), Color("ff1683"), 8.0)
    _rect(199, 276, 8, 209, PINK)
    _rect(473, 280, 7, 203, PINK)
    for i in range(3):
        _rect(102, 250.0 + float(i) * 48.0, 97, 36, Color("272337"))
        _line(Vector2(101, 286.0 + float(i) * 48.0), Vector2(200, 286.0 + float(i) * 48.0), Color("75637d"), 2.0)
    for i in range(10):
        var x := 12.0 + float((i % 5) * 35)
        var y := 420.0 + float(i / 5) * 25.0
        draw_arc(Vector2(x + 15.0, y), 15.0, 0.0, TAU, 16, Color("0c0e13"), 10.0)
    # Draw building sign and side neon lettering using actual font in Godot.
    var sign_font: Font = _font if _font != null else ThemeDB.fallback_font
    draw_string(sign_font, Vector2(234, 204), "DRAG MINI", HORIZONTAL_ALIGNMENT_LEFT, -1, 35, Color("ff639e"))
    for i in range(3):
        draw_string(sign_font, Vector2(117, 282 + i * 48), ["SPEED", "BUILD", "RACE"][i],
            HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("d3d1ee"))

func _draw_track_side() -> void:
    _rect(0, 452, 1536, 136, Color("121b31"))
    # Fence and barrier beneath overpass.
    for x in range(535, 1536, 18):
        _line(Vector2(float(x), 454), Vector2(float(x + 90), 536), Color("46516d", 0.42), 1.0)
        _line(Vector2(float(x), 535), Vector2(float(x + 93), 455), Color("46516d", 0.42), 1.0)
    _rect(1119, 454, 417, 36, Color("2e3651"))
    _line(Vector2(1119, 454), Vector2(1536, 454), Color("6a659a"), 3.0)
    # Christmas-tree lights on the far right, distinct components.
    for cx in [1432.0, 1478.0]:
        _rect(cx - 15, 295, 30, 199, Color("111425"))
        for row in range(6):
            var yy := 317.0 + float(row) * 28.0
            var bulb := Color("ffbc29") if row <= 3 else (Color("4cf94a") if row == 4 else Color("ef303d"))
            draw_circle(Vector2(cx, yy), 11.0, Color(bulb.r, bulb.g, bulb.b, 0.18))
            draw_circle(Vector2(cx, yy), 6.8, bulb)
            draw_arc(Vector2(cx, yy), 8.0, 0.0, TAU, 20, Color("08090b"), 2.0)
        _rect(cx - 4, 489, 8, 58, Color("3b4151"))

func _draw_neon_road() -> void:
    for i in range(40):
        var t := float(i) / 40.0
        _rect(0, 558.0 + t * 306.0, 1536, 8, Color("080e26").lerp(Color("131026"), t))
    _line(Vector2(0, 579), Vector2(1536, 565), Color("a63576"), 3.0)
    for i in range(70):
        var x := float((i * 199 + 57) % 1536)
        var y := 572.0 + float((i * 47 + 9) % 287)
        var source := CYAN if i % 3 == 0 else (PINK if i % 3 == 1 else Color("e39b58"))
        _rect(x, y, 30.0 + float(i % 6) * 20.0, 2.0 + float(i % 4), Color(source.r, source.g, source.b, 0.30))
    # Broad blurry/neon-looking puddle stretches as separate vector strips.
    for k in range(32):
        var y := 573.0 + float(k) * 9.0
        var amt := 0.09 + float(k % 5) * 0.025
        _rect(0, y, 490, 2.0, Color(0.13, 0.65, 1.0, amt))
        _rect(360, y + 3, 415, 2.0, Color(1.0, 0.04, 0.46, amt))
        _rect(800, y + 5, 300, 2.0, Color(1.0, 0.60, 0.15, amt))
        _rect(1150, y + 2, 386, 2.0, Color(0.97, 0.20, 0.64, amt))

func _draw_logo_backplate() -> void:
    # Paint-streak silhouette drawn natively behind separate text nodes.
    _polygon(PackedVector2Array([
        Vector2(480, 190), Vector2(578, 136), Vector2(551, 145),
        Vector2(1052, 92), Vector2(983, 152), Vector2(1081, 191),
        Vector2(1009, 216), Vector2(1072, 294), Vector2(910, 343),
        Vector2(659, 362), Vector2(516, 321), Vector2(569, 261),
        Vector2(454, 253)
    ]), Color("060511"))
    for i in range(7):
        var xx := 503.0 + float(i) * 81.0
        _line(Vector2(xx, 154 - float(i % 3) * 14), Vector2(xx + 106, 135 - float(i % 4) * 17),
            CYAN if i % 2 else PINK, 3.0)
    for i in range(3):
        _line(Vector2(508 + float(i) * 25.0, 346 + float(i) * 5.0),
            Vector2(906 + float(i) * 51.0, 320 + float(i) * 5.0),
            Color("eaeaf5", 0.72), 2.0)

func _draw_car_lineup() -> void:
    # Separate user-provided car textures. Never a composite or menu screenshot.
    var rectangles := [
        Rect2(20, 425, 468, 201),
        Rect2(399, 432, 429, 184),
        Rect2(742, 427, 418, 180),
        Rect2(1083, 420, 433, 186)
    ]
    for i in range(_cars.size()):
        var tex := _cars[i]
        if tex == null:
            continue
        var bounds: Rect2 = rectangles[i]
        # Under-car contact shadows. Pixel vehicle silhouette remains intact.
        draw_ellipse_shadow(bounds.position.x + bounds.size.x * 0.5,
            bounds.end.y - 21.0, bounds.size.x * 0.47)
        draw_texture_rect(tex, bounds, false)
        # Short translucent inverted reflection, using independent texture.
        var display_scale := Vector2(size.x / DESIGN.x, size.y / DESIGN.y)
        draw_set_transform(
            Vector2(bounds.position.x * display_scale.x, (bounds.end.y + 2.0) * display_scale.y),
            0.0, Vector2(display_scale.x, -display_scale.y * 0.30))
        draw_texture_rect(tex, Rect2(0, -bounds.size.y, bounds.size.x, bounds.size.y), false,
            Color(0.45, 0.50, 0.8, 0.11))
        draw_set_transform(Vector2.ZERO, 0.0, display_scale)

func draw_ellipse_shadow(cx: float, cy: float, radius: float) -> void:
    # CanvasItem has no ellipse primitive, so horizontal layered soft shadows.
    for row in range(11):
        var fraction := float(row) / 11.0
        _rect(cx - radius * (1.0 - fraction * 0.1), cy + float(row) * 2.0,
            radius * 2.0 * (1.0 - fraction * 0.1), 3.0, Color(0.0, 0.0, 0.0, 0.13))

func _draw_hud_panels() -> void:
    _panel(Rect2(48, 18, 408, 79), CYAN)
    _rect(150, 74, 282, 11, Color("18263f"))
    _rect(150, 74, 155, 11, CYAN)
    _panel(Rect2(946, 18, 220, 56), Color("8da9c6"))
    _panel(Rect2(1179, 18, 188, 56), Color("8da9c6"))
    _panel(Rect2(1378, 18, 62, 56), Color("8da9c6"))
    _panel(Rect2(1450, 18, 66, 56), Color("8da9c6"))
    # Neon tinted blocks under HUD icons.
    draw_circle(Vector2(985, 47), 17, Color("fdac23"))
    draw_circle(Vector2(1221, 47), 13, Color("25d967"))
    _line(Vector2(49, 99), Vector2(457, 99), Color("4ce0f9", 0.24), 4.0)

func _draw_action_panels() -> void:
    for i in range(ACTION_RECTS.size()):
        var b: Rect2 = ACTION_RECTS[i]
        var neon := GREEN if i == 5 else (Color("b066ff") if i == 2 else (Color("f4b655") if i == 3 else CYAN))
        _panel(b, neon)
        if i == 5:
            _rect(b.position.x + 14, b.position.y + 16,
                b.size.x - 28, b.size.y - 32, Color("0b452a"))
            _line(Vector2(b.position.x + 14, b.end.y - 16),
                Vector2(b.end.x - 14, b.end.y - 16), GREEN, 5.0)

func _panel(b: Rect2, neon: Color) -> void:
    _rect(b.position.x + 3, b.position.y + 3, b.size.x - 6, b.size.y - 6, NAVY)
    draw_rect(Rect2(b.position.x + 2, b.position.y + 2, b.size.x - 4, b.size.y - 4),
        Color(neon.r, neon.g, neon.b, 0.20), false, 8.0)
    draw_rect(Rect2(b.position.x + 6, b.position.y + 6, b.size.x - 12, b.size.y - 12),
        Color(neon.r, neon.g, neon.b, 0.60), false, 2.0)
