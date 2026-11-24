class_name CityMobileInput
extends Control

var joy_id := -1
var look_id := -1
var center := Vector2.ZERO
var axis := Vector2.ZERO
var radius := 66.0
var delta_look := Vector2.ZERO
var button_mode := false
var active := true

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    active = OS.has_feature("mobile")
    visible = active

func _input(event: InputEvent) -> void:
    if not active:
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < size.x * 0.44 and joy_id < 0 and event.position.y > size.y * 0.20:
                joy_id = event.index
                center = event.position
                axis = Vector2.ZERO
            elif look_id < 0 and event.position.y > size.y * 0.16:
                look_id = event.index
        else:
            if event.index == joy_id:
                joy_id = -1
                axis = Vector2.ZERO
            if event.index == look_id:
                look_id = -1
        queue_redraw()
    if event is InputEventScreenDrag:
        if event.index == joy_id:
            axis = ((event.position - center) / radius).limit_length(1.0)
            queue_redraw()
        elif event.index == look_id:
            delta_look += event.relative

func consume_look() -> Vector2:
    var result := delta_look
    delta_look = Vector2.ZERO
    return result

func _draw() -> void:
    if not active:
        return
    var pos := center if joy_id >= 0 else Vector2(100, size.y - 110)
    draw_circle(pos, radius + 10, Color(0.07, 0.10, 0.23, 0.45))
    draw_arc(pos, radius, 0.0, TAU, 46, Color(0.36, 0.93, 1.0, 0.66), 3.0, true)
    draw_circle(pos + axis * radius, 32, Color(0.28, 0.77, 0.95, 0.56))
