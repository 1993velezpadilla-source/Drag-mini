extends RefCounted
## Offline-first career/garage economy. All credits are earned, never fake UI amounts.
const PARTS := [
    {"id":"engine", "title":"ENGINE", "price":550},
    {"id":"turbo", "title":"TURBO", "price":700},
    {"id":"transmission", "title":"TRANSMISSION", "price":480},
    {"id":"tires", "title":"TIRES & GRIP", "price":380},
    {"id":"weight", "title":"WEIGHT REDUCTION", "price":400},
    {"id":"ecu", "title":"ECU / TUNE", "price":450},
    {"id":"nitrous", "title":"NITROUS", "price":650}
]
const MAX_LEVEL := 5
const DISTANCES := [201.168, 402.336, 804.672, 1609.344]
const STORY := [
    {"title":"Backstreet Rookie", "distance":201.168, "reward":900, "rival":0, "rival_name":"Mika", "dialogue":"New racer? These streets don't forgive mistakes."},
    {"title":"Harbor Lights", "distance":402.336, "reward":1150, "rival":2, "rival_name":"Rex", "dialogue":"My docks. My rules. Try to keep up."},
    {"title":"Midnight Traffic", "distance":201.168, "reward":1350, "rival":3, "rival_name":"Nova", "dialogue":"Midnight belongs to whoever shifts perfectly."},
    {"title":"Industrial Heat", "distance":402.336, "reward":1600, "rival":0, "rival_name":"Torque", "dialogue":"The factory run will expose your weak engine."},
    {"title":"Cityline Duel", "distance":804.672, "reward":1850, "rival":1, "rival_name":"Sable", "dialogue":"Cross the bridge. Don't look at the skyline."},
    {"title":"Neon Boulevard", "distance":402.336, "reward":2050, "rival":2, "rival_name":"Ghost", "dialogue":"This neon street has broken faster cars than yours."},
    {"title":"The Expressway", "distance":804.672, "reward":2500, "rival":3, "rival_name":"Juno", "dialogue":"No shortcuts. Half a mile, full power."},
    {"title":"Highway Legend", "distance":1609.344, "reward":3200, "rival":1, "rival_name":"Drift King", "dialogue":"They call this stretch the legend breaker."},
    {"title":"Tarmac Revenge", "distance":402.336, "reward":3800, "rival":0, "rival_name":"Torque", "dialogue":"You came back? This time there are no excuses."},
    {"title":"Ghost at Dawn", "distance":804.672, "reward":4400, "rival":2, "rival_name":"Mika", "dialogue":"We started here. Now race me like a champion."},
    {"title":"King of the Mile", "distance":1609.344, "reward":5200, "rival":3, "rival_name":"Sable", "dialogue":"The full mile. Everything you built comes down to this."},
    {"title":"Drag Mini Champion", "distance":1609.344, "reward":8500, "rival":1, "rival_name":"The King", "dialogue":"Beat me and the city's crown is yours."}
]
var cash := 2500
var xp := 0
var wins := 0
var losses := 0
var stage := 0
var selected := 0
var auto_shift := false
var distance_choice := 1
var show_kmh := true
var vibrations := true
var audio_enabled := true
var dynamic_time := true
var upgrades: Dictionary = {}
var best_times: Dictionary = {}
var wallpaper_interactive := true

func _levels(car: int) -> Dictionary:
    var key := str(car)
    if not upgrades.has(key) or not upgrades[key] is Dictionary:
        upgrades[key] = {}
    var result: Dictionary = upgrades[key]
    for part in PARTS:
        if not result.has(part["id"]):
            result[part["id"]] = 0
    return result

func load_game() -> void:
    var file := ConfigFile.new()
    if file.load("user://drag_mini_v1.cfg") != OK:
        var legacy := ConfigFile.new()
        if legacy.load("user://garage.cfg") == OK:
            selected = clampi(int(legacy.get_value("garage", "selected", 0)), 0, 3)
            auto_shift = bool(legacy.get_value("garage", "auto_shift", false))
        for car in range(4):
            _levels(car)
        return
    cash = maxi(0, int(file.get_value("career", "cash", 2500)))
    xp = maxi(0, int(file.get_value("career", "xp", 0)))
    wins = maxi(0, int(file.get_value("career", "wins", 0)))
    losses = maxi(0, int(file.get_value("career", "losses", 0)))
    stage = clampi(int(file.get_value("career", "stage", 0)), 0, STORY.size() - 1)
    selected = clampi(int(file.get_value("garage", "selected", 0)), 0, 3)
    auto_shift = bool(file.get_value("garage", "auto_shift", false))
    distance_choice = clampi(int(file.get_value("garage", "distance_choice", 1)), 0, DISTANCES.size() - 1)
    show_kmh = bool(file.get_value("settings", "show_kmh", true))
    vibrations = bool(file.get_value("settings", "vibrations", true))
    audio_enabled = bool(file.get_value("settings", "audio_enabled", true))
    dynamic_time = bool(file.get_value("settings", "dynamic_time", true))
    wallpaper_interactive = bool(file.get_value("settings", "wallpaper_interactive", true))
    upgrades = file.get_value("garage", "upgrades", {})
    best_times = file.get_value("career", "best_times", {})
    if not upgrades is Dictionary:
        upgrades = {}
    if not best_times is Dictionary:
        best_times = {}
    for car in range(4):
        var levels := _levels(car)
        for part in PARTS:
            var id: String = part["id"]
            levels[id] = clampi(int(levels[id]), 0, MAX_LEVEL)

func save_game() -> bool:
    var f := ConfigFile.new()
    for key in ["cash", "xp", "wins", "losses", "stage"]:
        f.set_value("career", key, get(key))
    f.set_value("career", "best_times", best_times)
    f.set_value("garage", "selected", selected)
    f.set_value("garage", "auto_shift", auto_shift)
    f.set_value("garage", "distance_choice", distance_choice)
    f.set_value("garage", "upgrades", upgrades)
    for key in ["show_kmh", "vibrations", "dynamic_time", "wallpaper_interactive", "audio_enabled"]:
        f.set_value("settings", key, get(key))
    return f.save("user://drag_mini_v1.cfg") == OK

func level(car: int, id: String) -> int:
    return int(_levels(car).get(id, 0))

func price(car: int, id: String) -> int:
    for part in PARTS:
        if part["id"] == id:
            var lv := level(car, id)
            if lv >= MAX_LEVEL:
                return 0
            return int(part["price"]) * (lv + 1) * (lv + 1)
    return -1

func purchase(car: int, id: String) -> bool:
    var cost := price(car, id)
    if cost <= 0 or cash < cost:
        return false
    cash -= cost
    _levels(car)[id] = level(car, id) + 1
    save_game()
    return true

func performance(car: int) -> Dictionary:
    return {
        "torque":1.0 + 0.09 * level(car, "engine") + 0.105 * level(car, "turbo") + 0.035 * level(car, "ecu"),
        "mass":1.0 - 0.035 * level(car, "weight"),
        "grip":1.0 + 0.075 * level(car, "tires"),
        "shift":1.0 - 0.08 * level(car, "transmission"),
        "nitrous":level(car, "nitrous")
    }

func complete_race(won: bool, seconds: float, career: bool, distance_m: float) -> int:
    var reward := int(300.0 + distance_m * 0.70) if won else 110
    if career and won:
        reward += int(STORY[stage]["reward"])
        if stage < STORY.size() - 1:
            stage += 1
    cash += reward
    xp += 90 if won else 25
    if won:
        wins += 1
    else:
        losses += 1
    var key := "%.3f:%d" % [distance_m, selected]
    if seconds > 0.0 and (not best_times.has(key) or seconds < float(best_times[key])):
        best_times[key] = seconds
    save_game()
    return reward
