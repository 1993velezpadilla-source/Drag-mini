extends Control
## Independent, static, asset-backed startup guard. Keeps owner's official
## image on screen even if the gameplay GDScript fails during Android _ready().
## A separate script avoids depending on the main game initialization.
const STARTUP_TIMEOUT_SECONDS := 8.0
var elapsed := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)

func _process(delta: float) -> void:
    if get_parent().get_meta("dragmini_boot_complete", false):
        hide()
        set_process(false)
        return
    elapsed += delta
    if elapsed >= STARTUP_TIMEOUT_SECONDS:
        var status := get_node_or_null("StartupMessage") as Label
        if status != null:
            status.text = "DRAG MINI STARTUP ERROR\nSend Android logcat: Godot / godot / AndroidRuntime"
            status.show()
        push_error("DRAG MINI STARTUP TIMEOUT: game UI not initialized (8 seconds)")
        set_process(false)
