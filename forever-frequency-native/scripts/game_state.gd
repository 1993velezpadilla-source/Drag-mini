class_name ForeverGameState
extends RefCounted

const FILE_PATH := "user://city_zero_save.json"
const MAX_OFFLINE_SECONDS := 8 * 3600

var coins: int = 250
var fans: int = 0
var level: int = 1
var records: int = 0
var businesses: int = 0
var companion: String = "NOVA"
var companion_bond: int = 0
var seeds: int = 2
var harvests: int = 0
var last_harvest_time: int = 0
var stage_built: bool = false
var last_save_time: int = 0
var offline_income: int = 0
var tracks: Array = []

func load_save() -> void:
    if not FileAccess.file_exists(FILE_PATH):
        return
    var file := FileAccess.open(FILE_PATH, FileAccess.READ)
    if file == null:
        return
    var data = JSON.parse_string(file.get_as_text())
    if not (data is Dictionary):
        return
    coins = max(0, int(data.get("coins", coins)))
    fans = max(0, int(data.get("fans", fans)))
    level = max(1, int(data.get("level", level)))
    records = max(0, int(data.get("records", records)))
    businesses = max(0, int(data.get("businesses", businesses)))
    companion = str(data.get("companion", companion))
    companion_bond = clampi(int(data.get("companion_bond", 0)), 0, 100)
    seeds = max(0, int(data.get("seeds", seeds)))
    harvests = max(0, int(data.get("harvests", harvests)))
    last_harvest_time = int(data.get("last_harvest_time", 0))
    stage_built = bool(data.get("stage_built", false))
    last_save_time = int(data.get("last_save_time", 0))
    if data.get("tracks", []) is Array:
        tracks = data.get("tracks", [])
    var elapsed: int = clampi(int(Time.get_unix_time_from_system()) - last_save_time, 0, MAX_OFFLINE_SECONDS)
    offline_income = int(float(elapsed) / 60.0) * businesses * 2
    coins += offline_income

func save_game() -> void:
    last_save_time = int(Time.get_unix_time_from_system())
    var file := FileAccess.open(FILE_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify({
        "coins": coins,
        "fans": fans,
        "level": level,
        "records": records,
        "businesses": businesses,
        "companion": companion,
        "companion_bond": companion_bond,
        "seeds": seeds,
        "harvests": harvests,
        "last_harvest_time": last_harvest_time,
        "stage_built": stage_built,
        "last_save_time": last_save_time,
        "tracks": tracks,
    }, "\t"))

func publish_track(pattern: Array[int]) -> Dictionary:
    records += 1
    var earned_fans := 22 + records * 4
    var earned_coins := 35 + int(fans * 0.06)
    fans += earned_fans
    coins += earned_coins
    companion_bond = mini(100, companion_bond + 4)
    level = 1 + int((fans + harvests * 10) / 180.0)
    tracks.append({"name":"Echo Session %02d" % records,"pattern":pattern,"fans": earned_fans})
    if tracks.size() > 32:
        tracks.pop_front()
    save_game()
    return {"fans":earned_fans,"coins":earned_coins}

func harvest() -> Dictionary:
    var now := int(Time.get_unix_time_from_system())
    if last_harvest_time != 0 and now - last_harvest_time < 35:
        return {"ok":false,"remaining":35 - (now - last_harvest_time)}
    last_harvest_time = now
    harvests += 1
    coins += 18 + businesses * 2
    companion_bond = mini(100, companion_bond + 6)
    save_game()
    return {"ok":true,"coins":18 + businesses * 2}

func open_shop() -> bool:
    var cost := 120 + businesses * 160
    if coins < cost or businesses >= 3:
        return false
    coins -= cost
    businesses += 1
    save_game()
    return true

func build_stage() -> bool:
    if stage_built or coins < 200 or fans < 50:
        return false
    coins -= 200
    stage_built = true
    save_game()
    return true

func evolve_pet() -> bool:
    if companion_bond < 30:
        return false
    companion_bond = 0
    if companion == "NOVA":
        companion = "LUMEN"
    elif companion == "LUMEN":
        companion = "SOLAR"
    else:
        companion = "NOVA"
    save_game()
    return true
