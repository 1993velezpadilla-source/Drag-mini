extends SceneTree
# Generate original procedural PCM at build time, not during a mobile turn.
const Dungeon=preload("res://dungeon_view.gd")
const FOLDER="res://generated_combat_audio"
var source_hashes:Dictionary={}
const ENV=["ember","splash","crystal","gravel","dig","dive","drip","static","leaves","metal","wind","land","vanish"]
const STATUS=["heal","drain","cleanse","shield","boost","weaken","exchange","transform","sleep","confusion","poison","burn","paralysis","freeze","curse","heart","bind","trap","weather","blocked","ritual"]

func _initialize()->void:
	call_deferred("bake")

func write_sample(pack:FileAccess,entries:Dictionary,key:String,stream:AudioStreamWAV)->void:
	var bytes:PackedByteArray=stream.data
	entries[key]=[pack.get_position(),bytes.size(),float(stream.get_meta("combat_pcm_peak",.78))]
	source_hashes[key]=hash(bytes)
	pack.store_buffer(bytes)

func percentile(sorted_usec:Array[int],fraction:float)->int:
	if sorted_usec.is_empty():return 0
	return sorted_usec[clampi(int(ceil(float(sorted_usec.size())*fraction))-1,0,sorted_usec.size()-1)]

func bake()->void:
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FOLDER))!=OK:
		push_error("cannot create audio pack folder")
		quit(1)
		return
	var view:=Dungeon.new()
	# A previous build must never become the source of this build.
	view.fx_audio_pack_checked=true
	var pack:=FileAccess.open(FOLDER+"/audio.pcm",FileAccess.WRITE)
	if pack==null:
		view.free()
		quit(1)
		return
	var entries:Dictionary={}
	var catalog:Dictionary=Dungeon.Rules.MOVE_LIBRARY.duplicate()
	catalog.merge(Dungeon.Rules.DEV_NATIVE_MOVES)
	var ids:Array=catalog.keys()
	if not ids.has("basic_strike"):ids.append("basic_strike")
	for species in Dungeon.Rules.SIGNATURE_SKILLS:
		var signature:String=str(Dungeon.Rules.SIGNATURE_SKILLS[species][6])
		if not ids.has(signature):ids.append(signature)
		var secondary:String="alt_"+str(species)
		if not ids.has(secondary):ids.append(secondary)
	ids.sort()
	var started:int=Time.get_ticks_msec()
	for id in ids:
		for phase in ["launch","impact","miss","status"]:
			for variant in range(3):
				write_sample(pack,entries,str(id)+":"+phase+":"+str(variant),view.combat_sound(id,phase,variant))
	for variant in range(3):
		for kind in ENV:
			var phase:String="env_"+kind
			write_sample(pack,entries,phase+":"+str(variant),view.combat_environment_sound(phase,variant))
		for kind in STATUS:
			var phase:String="status_"+kind
			write_sample(pack,entries,phase+":"+str(variant),view.combat_status_sound(phase,variant))
	var size:int=pack.get_position()
	pack.close()
	var index:=FileAccess.open(FOLDER+"/index.json",FileAccess.WRITE)
	if index==null:
		view.free()
		quit(1)
		return
	index.store_string(JSON.stringify({"version":1,"bytes":size,"entries":entries}))
	index.close()
	view.free()
	var reader:=Dungeon.new()
	reader.combat_audio_pack_init()
	var failed:int=0
	var cold_usec:Array[int]=[]
	var cached_usec:Array[int]=[]
	var peak_cache_entries:int=0
	for key in entries:
		var start_usec:int=Time.get_ticks_usec()
		var stream:AudioStreamWAV=reader.combat_audio_cached(key)
		cold_usec.append(Time.get_ticks_usec()-start_usec)
		if stream==null:
			failed+=1
			continue
		var bytes:PackedByteArray=stream.data
		if bytes.size()!=int(entries[key][1]) or bytes.decode_s16(0)!=0 or bytes.decode_s16(bytes.size()-2)!=0 or hash(bytes)!=int(source_hashes[key]):
			failed+=1
		start_usec=Time.get_ticks_usec()
		var reused:AudioStreamWAV=reader.combat_audio_cached(key)
		cached_usec.append(Time.get_ticks_usec()-start_usec)
		if reused!=stream:failed+=1
		peak_cache_entries=maxi(peak_cache_entries,reader.fx_audio_cache.size())
	if reader.fx_audio_pack_hits!=entries.size() or peak_cache_entries>Dungeon.FX_AUDIO_CACHE_CAP:failed+=1
	cold_usec.sort()
	cached_usec.sort()
	print("KINDRIA_AUDIO_PACK_BENCH samples=",cold_usec.size()," cold_p50_usec=",percentile(cold_usec,.50)," cold_p95_usec=",percentile(cold_usec,.95)," cold_p99_usec=",percentile(cold_usec,.99)," cold_max_usec=",percentile(cold_usec,1.0)," cache_p95_usec=",percentile(cached_usec,.95)," cache_peak_entries=",peak_cache_entries)
	reader.free()
	print("KINDRIA_AUDIO_PACK entries=",entries.size()," bytes=",size," elapsed_ms=",Time.get_ticks_msec()-started," failures=",failed)
	quit(0 if failed==0 else 1)
