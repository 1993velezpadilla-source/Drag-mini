extends RefCounted
## Infinite camera-scroll vector racing strip. World landmarks authored by C++.
## No track PNG/JPG, no horizontal stretching, no empty end of scenery.
const FILE := "res://assets/tracks/track_geometry.json"
const ROAD := Color("161c2b")
const GOLD := Color("ffc764")
static var props: Array = []
static var geometry_loaded := false

static func load_world() -> void:
    if geometry_loaded:
        return
    geometry_loaded = true
    if FileAccess.file_exists(FILE):
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(FILE))
        if parsed is Dictionary and parsed.get("version", 0) == 1 and parsed.get("props", []) is Array:
            props = parsed["props"]
    if props.is_empty():
        # Deterministic safety-net for direct Godot runs before the C++ asset build.
        for i in range(90):
            props.append({"m":24.0 + float(i) * 20.0,
                "kind":["palm", "lights", "grandstand", "billboard", "warehouse", "tower"][i % 6],
                "h":18})

static func _r(c: CanvasItem, x: float, y: float, w: float, h: float, color: Color) -> void:
    c.draw_rect(Rect2(x, y, w, h), color)
static func _line(c: CanvasItem, x1: float, y1: float, x2: float, y2: float, color: Color, width: float = 2.0) -> void:
    c.draw_line(Vector2(x1, y1), Vector2(x2, y2), color, width)
static func _px(world_m: float, camera_m: float, b: Rect2) -> float:
    return b.position.x + b.size.x * 0.24 + (world_m - camera_m) * (b.size.x / 145.0)

static func draw_world(c: CanvasItem, b: Rect2, camera_m: float, finish_m: float, hour: int, countdown: float = -1.0, red_light: bool = false) -> void:
    load_world()
    var x := b.position.x
    var y := b.position.y
    var w := b.size.x
    var h := b.size.y
    if w < 2.0 or h < 2.0:
        return
    var night := hour >= 19 or hour < 6
    var dusk := hour >= 17 and hour < 19 or hour >= 6 and hour < 8
    var sky := Color("071329") if night else (Color("774f85") if dusk else Color("2979b9"))
    var glow := Color("fca46b") if dusk else (Color("0f315a") if night else Color("85d4f8"))
    _r(c, x, y, w, h, sky)
    for i in range(16):
        _r(c, x, y + h * float(i) / 27.0, w, h / 26.0, sky.lerp(glow, float(i) / 26.0))
    var sun_x := x + w * 0.76
    var sun_y := y + h * 0.22
    if night:
        for ring in [0.096, 0.084, 0.069]:
            c.draw_circle(Vector2(sun_x, sun_y), h * ring, Color(0.63, 0.76, 1.0, 0.045))
    c.draw_circle(Vector2(sun_x, sun_y), h * 0.065, Color("ffe2a0") if not night else Color("d4e5fc"))
    # Atmospheric cloud bands, and rare faint night stars. Drawn, not sprites.
    for i in range(12):
        var cloud_x := x + fposmod(float(i * 193 + 19) - camera_m * 0.07, w + 180.0) - 80.0
        var cloud_y := y + h * (0.10 + float((i * 17) % 17) * 0.011)
        var cloud_col := Color(0.85, 0.92, 1.0, 0.08) if night else Color(0.96, 0.97, 1.0, 0.35)
        _r(c, cloud_x, cloud_y + h * 0.016, h * 0.12, h * 0.008, cloud_col)
        _r(c, cloud_x + h * 0.025, cloud_y, h * 0.055, h * 0.014, cloud_col)
    if night:
        for star in range(65):
            var sx := x + fposmod(float(star * 257 + 7), w)
            var sy := y + h * float((star * 79 + 11) % 36) / 100.0
            c.draw_circle(Vector2(sx, sy), 0.6 + float(star % 3) * 0.25,
                Color(0.85, 0.94, 1.0, 0.32 + float(star % 4) * 0.08))
    # Parallax skyline: periodic in world meters, never runs out at the 1-mile mark.
    for i in range(-2, 26):
        var skyline_x := x + fposmod(float(i) * w / 12.0 - camera_m * 0.24, w + 110.0) - 70.0
        var tall := h * (0.12 + float((i * 13 + 91) % 8) * 0.018)
        _r(c, skyline_x, y + h * 0.48 - tall, w / 11.0, tall + h * 0.04, Color("152e4a") if night else Color("52739a"))
        for row in range(5):
            for col in range(3):
                var win_y := y + h * 0.48 - tall + 12.0 + float(row) * h * 0.025
                if win_y >= y + h * 0.476:
                    continue
                var glass := Color("ffc26a", 0.90) if night else Color("b9dfff", 0.55)
                if (row * 7 + col * 11 + i) % 4 == 0:
                    glass = Color("123352")
                _r(c, skyline_x + 6.0 + float(col) * w / 120.0, win_y,
                    maxf(2.0, w / 190.0), maxf(3.0, h * 0.008), glass)
        if i % 7 == 0:
            _line(c, skyline_x + w / 22.0, y + h * 0.48 - tall,
                skyline_x + w / 22.0, y + h * 0.48 - tall - h * 0.06, Color("8c9eb9"), 1.2)
            c.draw_circle(Vector2(skyline_x + w / 22.0, y + h * 0.48 - tall - h * 0.06),
                2.5, Color("ff4968"))
    # Distant waterfront highway and cable-stayed bridge.
    _r(c, x, y + h * 0.45, w, h * 0.065, Color("2d4752"))
    var bridge_scroll := fposmod(camera_m * 0.12, w + 260.0)
    var bridge_base := x + w * 0.51 - bridge_scroll
    _line(c, bridge_base - w * 0.48, y + h * 0.455, bridge_base + w * 0.48, y + h * 0.455, Color("a3afb8", 0.7), 3.5)
    for tower in [-w * 0.23, w * 0.23]:
        var tx := bridge_base + tower
        _line(c, tx, y + h * 0.46, tx, y + h * 0.30, Color("94bbd0", 0.65), 4.0)
        for cable in range(5):
            _line(c, tx, y + h * 0.312, tx + (float(cable) - 2.0) * w * 0.065,
                y + h * 0.455, Color("8cb2c6", 0.45), 1.0)
    for sparkle in range(28):
        var ripple_x := x + fposmod(float(sparkle * 111) - camera_m * 0.15, w)
        _r(c, ripple_x, y + h * (0.481 + float(sparkle % 3) * 0.008),
            w * 0.013, 2, Color("57dbfb", 0.26))
    _line(c, x, y + h * 0.47, x + w, y + h * 0.47, Color("80adb7"), 3.0)
    # Procedural C++ world-space prop layer, culled against current scroll camera.
    for item in props:
        var m := float(item.get("m", 0.0))
        var px := _px(m, camera_m, b)
        if px < x - 90.0 or px > x + w + 90.0:
            continue
        var elevation := h * 0.45
        var kind := str(item.get("kind", "palm"))
        var ht := h * float(item.get("h", 18)) / 105.0
        if kind == "palm":
            var crown := Vector2(px - ht * 0.14, y + elevation - ht)
            _line(c, px, y + elevation, crown.x, crown.y, Color("584d35"), maxf(3.0, ht * 0.065))
            _line(c, px - 1.0, y + elevation - ht * 0.27, crown.x, crown.y,
                Color("b79a65"), 1.2)
            for j in range(8):
                var ang := (float(j) / 8.0) * TAU
                var sweep := Vector2(cos(ang) * ht * 0.57, sin(ang) * ht * 0.19 - ht * 0.05)
                var end := crown + sweep
                var leaf_color := Color("16865f") if j % 2 == 0 else Color("3aa374")
                c.draw_line(crown, end, leaf_color, maxf(2.0, ht * 0.08))
                c.draw_line(end, end + Vector2(signf(sweep.x) * ht * 0.14, ht * 0.10),
                    Color("1e7256"), maxf(2.0, ht * 0.046))
                for k in range(3):
                    var fraction := float(k + 1) / 4.0
                    var point := crown.lerp(end, fraction)
                    c.draw_line(point, point + Vector2(0, ht * 0.08),
                        Color("238958"), maxf(1.0, ht * 0.015))
        elif kind == "lights":
            _line(c, px, y + elevation, px, y + elevation - ht * 1.2, Color("b0b4c1"), 4.0)
            _line(c, px - 16, y + elevation - ht * 1.18, px + 16, y + elevation - ht * 1.18, Color("b8bcc7"), 3.0)
            for lamp in [-12.0, 0.0, 12.0]:
                if night:
                    c.draw_circle(Vector2(px + lamp, y + elevation - ht * 1.16), 12.0,
                        Color(1.0, 0.9, 0.64, 0.055))
                c.draw_circle(Vector2(px + lamp, y + elevation - ht * 1.16),
                    3.2, Color("fff8ce") if night else Color("eff5ff"))
        elif kind == "billboard":
            _r(c, px - 18, y + elevation - ht, 37, ht * 0.60, Color("e64293"))
            _r(c, px - 14, y + elevation - ht + 5, 28, 6, Color("ffffff"))
            _line(c, px, y + elevation - ht * 0.40, px, y + elevation, Color("8595a9"), 3.0)
        elif kind == "grandstand":
            _r(c, px - 25, y + elevation - ht * 0.45, 54, ht * 0.45, Color("293b55"))
            for row in range(3):
                _line(c, px - 23, y + elevation - ht * 0.4 + row * 8, px + 27, y + elevation - ht * 0.4 + row * 8, Color("ed4f8d"))
        else:
            _r(c, px - 20, y + elevation - ht, 47, ht, Color("243e5b") if night else Color("6b88a6"))
            _r(c, px - 10, y + elevation - ht + 9, 19, 6, Color("56d6ff"))
    # Lane/road elevation stable across all four race lengths.
    var near_y := y + h * 0.51
    _r(c, x, near_y, w, h * 0.49, ROAD)
    # Asphalt surface shade bands, curb/guardrail reflections, lane wear.
    for band in range(18):
        var frac := float(band) / 18.0
        _r(c, x, near_y + frac * h * 0.49, w, h * 0.049,
            ROAD.lerp(Color("313b50"), 0.08 + frac * 0.32))
    for road_stripe in range(21):
        var xx := x + fposmod(float(road_stripe * 127) - camera_m * 5.5, w + 95.0) - 42.0
        var yy := near_y + h * (0.075 + float(road_stripe % 13) * 0.026)
        _r(c, xx, yy, w * (0.04 + float(road_stripe % 5) * 0.008),
            maxf(1.0, h * 0.002), Color("a5b5c5", 0.045))
    _r(c, x, near_y + h * 0.012, w, h * 0.020, Color("546276"))
    for curb in range(32):
        var curb_x := _px(float(curb * 7), camera_m, b)
        if curb_x >= x - 25 and curb_x <= x + w + 25:
            _r(c, curb_x, near_y + h * 0.014, maxf(4.0, w * 0.024), h * 0.011,
                Color("ff367c") if curb % 2 == 0 else Color("62d5ee"))
    _r(c, x, y + h * 0.735, w, h * 0.033, Color("353e4f"))
    _line(c, x, y + h * 0.725, x + w, y + h * 0.725, Color("d5e0dd"), maxf(1.0, h * 0.005))
    # Kilometer-anchored road dashes: scroll naturally with the world.
    var first_m := maxi(0, int(camera_m) - 100)
    var last_m := mini(1800, int(camera_m) + 220)
    for meter in range(first_m - (first_m % 8), last_m, 8):
        var mark_x := _px(float(meter), camera_m, b)
        var mark_width := maxf(4.0, w / 145.0 * 3.6)
        _r(c, mark_x, y + h * 0.745, mark_width, maxf(3.0, h * 0.007), Color("cfbfab"))
        _r(c, mark_x, y + h * 0.975, mark_width * 0.5, 2, Color("5785b7", 0.4))
    _r(c, x, y + h * 0.947, w, h * 0.03, Color("626d78"))
    _line(c, x, y + h * 0.945, x + w, y + h * 0.945, Color("b3b8bb"), 3.0)
    # Roadside foreground mesh and guard fence: vector-only, scroll-safe.
    _line(c, x, y + h * 0.925, x + w, y + h * 0.925, Color("8098a8", 0.8), 1.4)
    for fence in range(25):
        var offset := float(fence) * w / 24.0
        var top := y + h * 0.90
        var bottom := y + h * 0.943
        _line(c, x + offset, top, x + offset + w / 35.0, bottom,
            Color("788d9c", 0.24), 0.8)
        _line(c, x + offset + w / 35.0, top, x + offset, bottom,
            Color("788d9c", 0.24), 0.8)
        if fence % 5 == 0:
            _r(c, x + offset, y + h * 0.886, 4, h * 0.065, Color("6b7e8e"))
    var end_x := _px(finish_m, camera_m, b)
    if end_x > x - 35 and end_x < x + w + 35:
        for row in range(10):
            for col in range(2):
                _r(c, end_x + col * 10, near_y + h * 0.048 + row * (h * 0.042), 10.0, h * 0.042,
                    Color.WHITE if (row + col) % 2 == 0 else Color("151923"))
        _r(c, end_x - 41, y + h * 0.31, 85, 22, Color("141b2e"))
        c.draw_string(ThemeDB.fallback_font, Vector2(end_x - 38, y + h * 0.31 + 16), "FINISH", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff0c6"))
    if camera_m < 45.0:
        var start_x := _px(0.0, camera_m, b)
        _r(c, start_x, near_y + h * 0.03, 5, h * 0.42, Color.WHITE)
        _draw_tree(c, Vector2(start_x - 18.0, y + h * 0.49), maxf(4.0, h * 0.022), countdown, red_light)

static func _draw_tree(c: CanvasItem, pos: Vector2, radius: float, countdown: float, red_light: bool) -> void:
    _r(c, pos.x - 5, pos.y - radius * 5.2, 10, radius * 10.5, Color("0c1521"))
    for i in range(3):
        var lit := countdown > 0.0 and countdown <= 3.0 - float(i)
        c.draw_circle(pos + Vector2(0, (float(i) - 3.2) * radius * 2.0), radius,
            Color("ffc543") if lit else Color("554b32"))
    c.draw_circle(pos + Vector2(0, radius * 2.0), radius, Color("f43d53") if red_light else
        (Color("43ff8a") if countdown <= 0.0 else Color("254e32")))
