extends Node
## DRAG MINI Android wallpaper bridge; native Android singleton detection only.
## Java/Android plugin availability is NOT testable in desktop Godot CI.
signal plugin_ready(is_wallpaper: bool)
signal visibility_changed(visible: bool)
signal trim_memory(level: int)

var is_wallpaper := false
var _native: Object
var _probe_time := 0.0
var _probe_attempts := 0
var diagnostic := "not checked"

func _ready() -> void:
    set_process(OS.get_name() == "Android")
    if OS.get_name() == "Android":
        _try_connect()
    else:
        diagnostic = "Desktop build, wallpaper only on Android"

func _process(delta: float) -> void:
    if _native != null or OS.get_name() != "Android":
        set_process(false)
        return
    _probe_time += delta
    if _probe_time < 0.30:
        return
    _probe_time = 0.0
    _probe_attempts += 1
    _try_connect()
    if _probe_attempts >= 30 and _native == null:
        diagnostic = "LiveWallpaper Android singleton missing after 9s"
        push_warning(diagnostic)
        set_process(false)

func _try_connect() -> void:
    if _native != null:
        return
    if not Engine.has_singleton("LiveWallpaper"):
        diagnostic = "Android engine has no LiveWallpaper singleton"
        return
    _native = Engine.get_singleton("LiveWallpaper")
    diagnostic = "LiveWallpaper singleton registered"
    if _native.has_method("IsLiveWallpaper"):
        is_wallpaper = bool(_native.call("IsLiveWallpaper"))
    if _native.has_signal("VisibilityChanged"):
        _native.connect("VisibilityChanged", _on_visibility)
    if _native.has_signal("TrimMemory"):
        _native.connect("TrimMemory", _on_memory)
    set_process(false)
    plugin_ready.emit(is_wallpaper)

func start_live_wallpaper() -> bool:
    if OS.get_name() != "Android":
        diagnostic = "Android only"
        return false
    _try_connect()
    if _native == null:
        diagnostic = "PLUGIN UNAVAILABLE: no native Android singleton (check APK plugin registration)"
        return false
    if not _native.has_method("startWallpaperService"):
        diagnostic = "PLUGIN ERROR: startWallpaperService missing from native API"
        return false
    var result: int = int(_native.call("startWallpaperService"))
    if result != 1:
        diagnostic = "Android reports live wallpapers unavailable"
        return false
    diagnostic = "Opened Android wallpaper selector"
    return true

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
        Engine.max_fps = 10
