extends Node
# Original generated PCM effects. No recording, network or copyrighted samples.
var enabled := true
var sounds := {}
var voices: Array[AudioStreamPlayer] = []
var cursor := 0
var music_enabled := true
var music:AudioStreamPlayer
func _ready() -> void:
	for i in range(8):
		var p:=AudioStreamPlayer.new()
		p.volume_db=-11
		add_child(p)
		voices.append(p)
	sounds["coin"]=tone(880,1580,0.11,0.30)
	sounds["snack"]=tone(480,950,0.18,0.28)
	sounds["jump"]=tone(210,670,0.16,0.24)
	sounds["slide"]=tone(230,75,0.20,0.18)
	sounds["step"]=tone(110,45,0.07,0.11)
	sounds["power"]=tone(380,1450,0.40,0.30)
	sounds["shield"]=tone(520,220,0.24,0.26)
	sounds["crash"]=tone(110,28,0.33,0.42)
	sounds["swoosh"]=tone(360,95,0.13,0.18)
	music=AudioStreamPlayer.new()
	music.volume_db=-17
	add_child(music)
	if ResourceLoader.exists("res://assets/skyway-music.wav"):
		var stream:=load("res://assets/skyway-music.wav") as AudioStreamWAV
		stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin=0
		stream.loop_end=stream.data.size() >> 1
		music.stream=stream
func tone(start: float, end: float, duration: float, gain: float) -> AudioStreamWAV:
	var data:=PackedByteArray()
	var count:=int(22050*duration)
	data.resize(count*2)
	var phase:=0.0
	for i in range(count):
		var t:=float(i)/float(count)
		phase+=TAU*lerpf(start,end,t)/22050
		var env:=minf(1.0,t*30.0)*pow(1.0-t,2.0)
		var sample:=int(clampf((sin(phase)+0.18*sin(2*phase))*gain*env,-1,1)*32767)
		data.encode_s16(i*2,sample)
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=22050
	stream.data=data
	return stream
func toggle() -> void:
	enabled=not enabled
	if not enabled:
		for p in voices: p.stop()
func play_fx(name: String) -> void:
	if not enabled or not sounds.has(name) or voices.is_empty(): return
	var p:=voices[cursor]
	cursor=(cursor+1)%voices.size()
	p.stream=sounds[name]
	p.play()

func start_music() -> void:
	if music_enabled and music!=null and music.stream!=null and not music.playing: music.play()
func stop_music() -> void:
	if music!=null: music.stop()
func toggle_music() -> void:
	music_enabled=not music_enabled
	if not music_enabled: stop_music()
	else: start_music()
func set_music_paused(value:bool) -> void:
	if music!=null: music.stream_paused=value
