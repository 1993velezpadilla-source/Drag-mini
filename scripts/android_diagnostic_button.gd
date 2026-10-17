extends Button
## This is the ONLY script loaded by the Android display diagnostic.
## Gameplay, car initialization and wallpaper plugin are not started until tap.
func _ready() -> void:
    pressed.connect(_open_full_game)

func _open_full_game() -> void:
    text = "LOADING MAIN GAME ..."
    var err := get_tree().change_scene_to_file("res://scenes/main.tscn")
    if err != OK:
        text = "GAME LOAD ERROR " + str(err)
        push_error("DRAG MINI Android diagnostic: main scene failed with " + str(err))
