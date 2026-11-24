extends SceneTree

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var code := load("res://city_zero/vehicle_runtime/CityZeroTrunkAudio.gd")
    if code == null:
        push_error("Trunk audio script failed to parse/load")
        quit(1)
        return
    var container := Node3D.new()
    container.name = "TestCarTrunk"
    var mount := Node3D.new()
    mount.name = "SoundMount"
    container.add_child(mount)
    var cone := Node3D.new()
    cone.name = "BassCone"
    container.add_child(cone)

    var audio: Node3D = code.new()
    audio.name = "LiveTrunkAudio"
    audio.source_anchor = NodePath("../SoundMount")
    audio.speaker_cones = [NodePath("../BassCone")]
    container.add_child(audio)
    get_root().add_child(container)
    await process_frame

    var expected_bus := "CityZeroCarStereo_" + str(audio.get_instance_id())
    if AudioServer.get_bus_index(expected_bus) < 0:
        push_error("Real audio bus not registered")
        quit(1)
        return
    if audio.play_music():
        push_error("Playing with no user-owned stream must be rejected")
        quit(1)
        return
    if not audio.set_stream(AudioStreamGenerator.new()):
        push_error("Cannot install synthetic audio generator stream")
        quit(1)
        return
    if not audio.play_music() or not audio.is_playing_music():
        push_error("3D playback did not start")
        quit(1)
        return
    audio.set_music_volume(-120.0)
    if audio.configured_volume_db != -48.0:
        push_error("Volume safety clamp failed")
        quit(1)
        return
    audio.stop_music()
    if audio.is_playing_music():
        push_error("Audio failed to stop")
        quit(1)
        return
    container.queue_free()
    await process_frame
    if AudioServer.get_bus_index(expected_bus) >= 0:
        push_error("Orphaned per-vehicle sound bus")
        quit(1)
        return
    print("CITYZERO_TRUNK_AUDIO_SMOKE_OK")
    quit(0)
