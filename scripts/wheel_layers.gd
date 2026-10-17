extends RefCounted
## Four vehicle sprites -> independent chassis + rotating front/rear tires.
## Coordinates are measured from 128x54 official art. Pixel processing runs once at boot.
const LAYOUTS := [
    {"rear":Vector2(24.0,39.0), "front":Vector2(103.0,39.0), "diameter":21.0, "style":0, "mask_baked":true},
    {"rear":Vector2(27.0,41.0), "front":Vector2(99.0,41.0), "diameter":22.0, "style":1, "mask_baked":false},
    {"rear":Vector2(24.0,41.0), "front":Vector2(99.0,41.0), "diameter":22.0, "style":2, "mask_baked":false},
    {"rear":Vector2(30.0,39.0), "front":Vector2(99.0,39.0), "diameter":20.0, "style":3, "mask_baked":true}
]
const SOURCE_SIZE := Vector2(128.0, 54.0)

static func build(source: Texture2D, car_index: int) -> Dictionary:
    assert(car_index >= 0 and car_index < LAYOUTS.size())
    var layout: Dictionary = LAYOUTS[car_index]
    var raw: Image = source.get_image()
    raw.convert(Image.FORMAT_RGBA8)
    var img: Image = raw.duplicate()
    # Civic/AE86 art has baked rims: delete only the inner circle.
    # Supra/Del Sol art already has transparent holes for the wheel mounts.
    if bool(layout["mask_baked"]):
        for key in ["front", "rear"]:
            var center: Vector2 = layout[key]
            var radius: float = float(layout["diameter"]) * 0.43
            for iy in range(maxi(0, int(floor(center.y-radius))), mini(img.get_height(), int(ceil(center.y+radius))+1)):
                for ix in range(maxi(0, int(floor(center.x-radius))), mini(img.get_width(), int(ceil(center.x+radius))+1)):
                    var d := Vector2(float(ix) + 0.5, float(iy) + 0.5).distance_to(center)
                    if d <= radius:
                        img.set_pixel(ix, iy, Color.TRANSPARENT)
    return {
        "body": ImageTexture.create_from_image(img),
        "wheel": _wheel_texture(int(layout["style"])),
        "front": layout["front"],
        "rear": layout["rear"],
        "diameter": float(layout["diameter"]),
        "source": source
    }

static func _wheel_texture(style: int) -> Texture2D:
    # Small independent pixel-art texture (transparent outside tire).
    # Styles: 0 gunmetal 6-spoke, 1 silver 5-spoke, 2 silver 5-hole, 3 black 5-spoke.
    const SIDE := 26
    const MID := 12.5
    var img := Image.create(SIDE, SIDE, false, Image.FORMAT_RGBA8)
    img.fill(Color.TRANSPARENT)
    var spokes := 6 if style == 0 else 5
    var rim_light := Color8(166, 169, 172) if style == 1 or style == 2 else Color8(105, 111, 120)
    var rim_dark := Color8(68, 76, 84) if style == 1 or style == 2 else Color8(34, 39, 47)
    if style == 3:
        rim_light = Color8(83, 88, 93)
        rim_dark = Color8(24, 27, 32)
    for y in range(SIDE):
        for x in range(SIDE):
            var vec := Vector2(float(x) + 0.5 - MID, float(y) + 0.5 - MID)
            var r: float = vec.length()
            if r > 11.8:
                continue
            var col := Color8(16, 18, 23)
            if r >= 10.65:
                col = Color8(17, 18, 21)
            elif r >= 9.4:
                col = Color8(43, 45, 49)
            elif r >= 8.0:
                col = rim_light
            elif r >= 7.1:
                col = rim_dark
            elif r >= 2.0:
                # Rotating spoke pattern with brake-dark cavities in between.
                var theta: float = atan2(vec.y, vec.x)
                var angular_distance: float = absf(sin(theta * float(spokes) * 0.5)) * r
                if angular_distance < 1.1:
                    col = rim_light
                else:
                    col = Color8(16, 19, 24)
                    if style == 2 and r > 5.8:
                        col = rim_dark
            elif r >= 1.1:
                col = Color8(208, 208, 209) if style == 1 or style == 2 else Color8(86, 90, 97)
            else:
                col = Color8(191, 45, 31) if style == 0 else Color8(123, 124, 130)
            img.set_pixel(x, y, col)
    return ImageTexture.create_from_image(img)

static func draw_car(canvas: CanvasItem, parts: Dictionary, bounds: Rect2, wheel_angle: float) -> void:
    # One draw API for garage, race (player/CPU) and Android wallpaper.
    # Wheels render on top of body; no static rims left visible.
    var body: Texture2D = parts["body"]
    var wheel: Texture2D = parts["wheel"]
    canvas.draw_texture_rect(body, bounds, false)
    var scale_xy := Vector2(bounds.size.x / SOURCE_SIZE.x, bounds.size.y / SOURCE_SIZE.y)
    var size_pixels: float = float(parts["diameter"])
    var wheel_size := Vector2(size_pixels * scale_xy.x, size_pixels * scale_xy.y)
    for key in ["rear", "front"]:
        var center: Vector2 = bounds.position + Vector2(parts[key]) * scale_xy
        canvas.draw_set_transform(center, wheel_angle, Vector2.ONE)
        canvas.draw_texture_rect(wheel, Rect2(-wheel_size * 0.5, wheel_size), false)
    canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
