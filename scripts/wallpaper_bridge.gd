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
    # Godot 4.6 exposes only Java/Kotlin @UsedByGodot methods.
    # New distinct public endpoint first; legacy endpoint second.
    var supported := ["openWallpaperPicker", "startWallpaperService"]
    var tried := false
    for name in supported:
        if _native.has_method(name):
            tried = true
            var result: int = int(_native.call(name))
            if result == 1:
                diagnostic = "Android wallpaper picker opened"
                return true
    if tried:
        diagnostic = "WALLPAPER PICKER FAILED: Android rejected the launch. Check device live-wallpaper support."
    else:
        var exported := PackedStringArray()
        for method in _native.get_method_list():
            var method_name := str(method.get("name", ""))
            if method_name.to_lower().contains("wallpaper"):
                exported.append(method_name)
        diagnostic = "PLUGIN API NOT EXPORTED: Reinstall the new ARM64 APK. Native methods: " + ", ".join(exported)
    return false

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
