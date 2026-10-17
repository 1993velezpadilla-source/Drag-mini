extends Control
## Uses the user's ORIGINAL DRAG MINI menu photograph, never recreated art.
signal action_selected(action: String)
const SOURCE_SIZE := Vector2(1536, 864)
const HOTSPOTS := {
    "race": Rect2(25, 676, 232, 148),
    "garage": Rect2(269, 676, 203, 148),
    "wallpaper": Rect2(476, 676, 194, 148),
    "upgrades": Rect2(678, 676, 198, 148),
    "settings": Rect2(884, 676, 204, 148),
    "start": Rect2(1098, 671, 415, 155)
}
const MENU_ASSET := "res://assets/ui/official_main_menu.jpg"
var _tap_locked := false

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_PASS
    # The official photo is drawn directly by the root Control (main.gd).
    # This transparent child handles touches ONLY and cannot hide the image.
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for action: String in HOTSPOTS:
        _add_hotspot(action, HOTSPOTS[action])

func _add_hotspot(action: String, source: Rect2) -> void:
    var b := Button.new()
    b.name = action.capitalize() + "Touch"
    b.text = ""
    b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    b.focus_mode = Control.FOCUS_NONE
    b.anchor_left = source.position.x / SOURCE_SIZE.x
    b.anchor_right = (source.position.x + source.size.x) / SOURCE_SIZE.x
    b.anchor_top = source.position.y / SOURCE_SIZE.y
    b.anchor_bottom = (source.position.y + source.size.y) / SOURCE_SIZE.y
    for mode in ["normal", "hover", "pressed", "focus", "disabled"]:
        var style := StyleBoxFlat.new()
        style.bg_color = Color(0.20, 0.95, 1.00, 0.0 if mode == "normal" else (0.25 if mode == "pressed" else 0.11))
        style.border_color = Color(0.43, 0.94, 1.0, 0.0 if mode == "normal" else 0.9)
        style.set_border_width_all(3 if mode != "normal" else 0)
        style.set_corner_radius_all(8)
        b.add_theme_stylebox_override(mode, style)
    b.pressed.connect(func(): _activate(action, b))
    add_child(b)

func _activate(action: String, button: Button) -> void:
    if _tap_locked:
        return
    _tap_locked = true
    # Play touch feedback BEFORE transitioning. Old version switched instantly.
    var tween := create_tween()
    button.pivot_offset = button.size * 0.5
    tween.tween_property(button, "scale", Vector2(0.975, 0.975), 0.07)
    tween.tween_property(button, "scale", Vector2.ONE, 0.11)
    if OS.get_name() == "Android":
        Input.vibrate_handheld(27)
    tween.tween_callback(func():
        _tap_locked = false
        action_selected.emit(action)
    )
