extends Node
## TheOathMan v1.5.1 Android Live Wallpaper bridge.
## Uses the *native* registered Android singleton; safe on desktop/editor.
signal visibility_changed(visible: bool)
signal trim_memory(level: int)

var is_wallpaper := false
var _native: Object

func _ready() -> void:
    if OS.get_name() != "Android":
        return
    if not Engine.has_singleton("LiveWallpaper"):
        push_warning("Android LiveWallpaper singleton missing. Run the pinned plugin installer and Gradle export.")
        return
    _native = Engine.get_singleton("LiveWallpaper")
    if _native.has_method("IsLiveWallpaper"):
        is_wallpaper = bool(_native.call("IsLiveWallpaper"))
    if _native.has_signal("VisibilityChanged"):
        _native.connect("VisibilityChanged", _on_visibility)
    if _native.has_signal("TrimMemory"):
        _native.connect("TrimMemory", _on_memory)

func start_live_wallpaper() -> bool:
    if OS.get_name() != "Android" or _native == null:
        return false
    if not _native.has_method("startWallpaperService"):
        return false
    return int(_native.call("startWallpaperService")) == 1

func _on_visibility(visible: bool) -> void:
    if not is_wallpaper:
        return
    visibility_changed.emit(visible)
    get_tree().paused = not visible
    if visible:
        Engine.max_fps = 20

func _on_memory(level: int) -> void:
    trim_memory.emit(level)
    if is_wallpaper and level >= 40:
        # Keep wallpaper state lightweight; Godot's engine manages texture lifetime.
        Engine.max_fps = 10
