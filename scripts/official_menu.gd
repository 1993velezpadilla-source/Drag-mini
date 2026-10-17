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
const MENU_ASSET := "res://assets/ui/official_main_menu.png"

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_PASS
    var image := TextureRect.new()
    image.name = "OfficialMenuPhoto"
    image.set_anchors_preset(Control.PRESET_FULL_RECT)
    image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    image.stretch_mode = TextureRect.STRETCH_SCALE
    image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if ResourceLoader.exists(MENU_ASSET):
        image.texture = load(MENU_ASSET) as Texture2D
    else:
        push_warning("OFFICIAL DRAG MINI MENU PNG NOT INSTALLED: " + MENU_ASSET)
    add_child(image)
    if image.texture == null:
        var missing := Label.new()
        missing.text = "OFFICIAL MENU IMAGE NOT INSTALLED"
        missing.set_anchors_preset(Control.PRESET_CENTER)
        missing.position = Vector2(24, 24)
        missing.add_theme_font_size_override("font_size", 23)
        add_child(missing)
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
    # Touch: light up the existing painted icon and give physical feedback.
    var tween := create_tween()
    button.pivot_offset = button.size * 0.5
    tween.tween_property(button, "scale", Vector2(0.975, 0.975), 0.07)
    tween.tween_property(button, "scale", Vector2.ONE, 0.11)
    if Input.get_current_cursor_shape() >= 0:
        Input.vibrate_handheld(27)
    action_selected.emit(action)
