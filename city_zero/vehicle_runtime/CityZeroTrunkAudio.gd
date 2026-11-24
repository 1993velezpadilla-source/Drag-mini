extends Node3D
class_name CityZeroTrunkAudio
## Author-origin 3D car stereo audio with per-car spectrum analysis.
## Supply user-owned/licensed music through set_stream(). No game audio is bundled.

@export var source_anchor: NodePath
@export var speaker_cones: Array[NodePath] = []
@export_range(-48.0, 6.0, 0.5) var configured_volume_db: float = -8.0
@export_range(0.0, 0.12, 0.005) var cone_scale_amplitude: float = 0.035
@export_range(0.0, 40.0, 0.5) var speaker_3d_range_m: float = 28.0

var _player: AudioStreamPlayer3D
var _spectrum_bus := ""
var _spectrum_bus_index := -1
var _cone_origins: Dictionary = {}
var _smoothing := 0.0

func _ready() -> void:
    _spectrum_bus = "CityZeroCarStereo_" + str(get_instance_id())
    AudioServer.add_bus(-1)
    _spectrum_bus_index = AudioServer.get_bus_index(_spectrum_bus)
    if _spectrum_bus_index < 0:
        _spectrum_bus_index = AudioServer.bus_count - 1
        AudioServer.set_bus_name(_spectrum_bus_index, _spectrum_bus)
    AudioServer.set_bus_send(_spectrum_bus_index, "Master")
    var analyzer := AudioEffectSpectrumAnalyzer.new()
    AudioServer.add_bus_effect(_spectrum_bus_index, analyzer)

    _player = AudioStreamPlayer3D.new()
    _player.name = "TrunkMusic3D"
    _player.bus = _spectrum_bus
    _player.volume_db = configured_volume_db
    _player.max_distance = speaker_3d_range_m
    _player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
    var anchor := get_node_or_null(source_anchor) as Node3D
    if anchor != null:
        anchor.add_child(_player)
    else:
        add_child(_player)

    for path in speaker_cones:
        var cone := get_node_or_null(path) as Node3D
        if cone != null:
            _cone_origins[str(path)] = {"node": cone, "scale": cone.scale}

func set_stream(stream: AudioStream) -> bool:
    if _player == null:
        return false
    _player.stop()
    _player.stream = stream
    return stream != null

func play_music() -> bool:
    if _player == null or _player.stream == null:
        return false
    _player.play()
    return true

func stop_music() -> void:
    if _player != null:
        _player.stop()

func is_playing_music() -> bool:
    return _player != null and _player.playing

func set_music_volume(db: float) -> void:
    configured_volume_db = clampf(db, -48.0, 6.0)
    if _player != null:
        _player.volume_db = configured_volume_db

func _process(delta: float) -> void:
    var bass := 0.0
    if is_playing_music() and _spectrum_bus_index >= 0:
        var effect := AudioServer.get_bus_effect_instance(_spectrum_bus_index, 0) as AudioEffectSpectrumAnalyzerInstance
        if effect != null:
            var value := effect.get_magnitude_for_frequency_range(40.0, 160.0)
            bass = clampf(maxf(value.x, value.y) * 10.0, 0.0, 1.0)
    _smoothing = lerpf(_smoothing, bass, 1.0 - exp(-delta * 18.0))
    for entry in _cone_origins.values():
        var node: Node3D = entry["node"]
        if is_instance_valid(node):
            # Subtle cone-only motion; never stretch the wooden box or entire car.
            node.scale = entry["scale"] * (1.0 + cone_scale_amplitude * _smoothing)

func _exit_tree() -> void:
    for entry in _cone_origins.values():
        var node: Node3D = entry["node"]
        if is_instance_valid(node):
            node.scale = entry["scale"]
    var idx := AudioServer.get_bus_index(_spectrum_bus)
    if idx >= 1:
        AudioServer.remove_bus(idx)
