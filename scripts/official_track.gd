extends RefCounted
## Draws only the user's uploaded official pixel-art track; middle is streamed
## by crop/scrolling, finish sector appears near actual race end.
const TRACK_PATH := "res://assets/tracks/official_drag_strip.png"
const SOURCE_WIDTH := 1536.0
const SOURCE_HEIGHT := 512.0

static func draw(canvas: CanvasItem, texture: Texture2D, bounds: Rect2, progress: float) -> bool:
    if texture == null:
        return false
    var src_w := float(texture.get_width())
    var src_h := float(texture.get_height())
    var ratio := src_w / SOURCE_WIDTH
    var start_src := Rect2(0, 0, 1250.0 * ratio, src_h)
    var middle_x := 230.0 * ratio + fposmod(progress * 12.0, 1.0) * 215.0 * ratio
    var middle_src := Rect2(middle_x, 0, 1000.0 * ratio, src_h)
    var finish_src := Rect2(245.0 * ratio, 0, 1290.0 * ratio, src_h)
    var crop := start_src if progress < 0.02 else (finish_src if progress > 0.94 else middle_src)
    canvas.draw_texture_rect_region(texture, bounds, crop)
    return progress < 0.02

static func draw_map_tree(canvas: CanvasItem, bounds: Rect2, countdown: float, false_start: bool) -> void:
    # Image coordinates correspond to the three amber lamps on the left-side
    # Christmas tree in the owner's official track photo. This only overlays
    # lighting on the real art; does not paint/recreate any scenery.
    var scale_x: float = bounds.size.x / 1250.0
    var scale_y: float = bounds.size.y / SOURCE_HEIGHT
    for i in range(3):
        var on := countdown > 0.0 and countdown <= 3.0 - float(i)
        var point := bounds.position + Vector2((55.0 + 31.0 * i) * scale_x, 293.0 * scale_y)
        var radius := maxf(3.0, 7.0 * scale_x)
        canvas.draw_circle(point, radius * 1.7, Color(1, 0.58, 0.10, 0.16) if on else Color.TRANSPARENT)
        canvas.draw_circle(point, radius, Color("ffd33e") if on else Color("453e29"))
    var go_point := bounds.position + Vector2(54.0 * scale_x, 326.0 * scale_y)
    var go := countdown <= 0.0 and not false_start
    canvas.draw_circle(go_point, maxf(3.0, 9.0 * scale_x), Color("3aff68") if go else Color("254d32"))
    if false_start:
        canvas.draw_circle(go_point, maxf(3.0, 9.0 * scale_x), Color("fd3030"))
