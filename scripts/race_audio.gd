extends Node
## Low-allocation arcade engine synthesizer. No licensed engine recordings.
## Godot AudioStreamGenerator synthesizes exhaust harmonics from actual RPM.
var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _phase := 0.0
var _rpm := 1000.0
var _throttle := 0.0
var _is_racing := false
var _enabled := true
const RATE := 22050.0

func _ready() -> void:
    set_process(false)
    if DisplayServer.get_name() == "headless":
        return
    var generator := AudioStreamGenerator.new()
    generator.mix_rate = RATE
    generator.buffer_length = 0.12
    _player = AudioStreamPlayer.new()
    _player.stream = generator
    _player.volume_db = -13.0
    add_child(_player)
    _player.play()
    _playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
    set_process(true)

func set_engine(rpm: float, throttle: bool, racing: bool, enabled: bool) -> void:
    _rpm = clampf(rpm, 750.0, 9200.0)
    _throttle = 1.0 if throttle else 0.0
    _is_racing = racing
    _enabled = enabled

func _process(_delta: float) -> void:
    if _playback == null or not _player.playing:
        return
    var samples := mini(_playback.get_frames_available(), 2048)
    # Note frequency tracks real engine revs; envelope quiet outside races.
    var hz := _rpm / 60.0 * 1.65
    var amplitude := (0.12 + _throttle * 0.27) if _is_racing and _enabled else 0.0
    for i in range(samples):
        _phase = fposmod(_phase + TAU * hz / RATE, TAU)
        var raw := sin(_phase) * 0.48 + sin(_phase * 2.0) * 0.26 + sin(_phase * 4.0) * 0.09
        var value := clampf(raw * amplitude, -0.5, 0.5)
        _playback.push_frame(Vector2(value, value))
