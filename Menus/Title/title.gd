extends Control


func _ready() -> void:
	var exit_button = %ExitBtn
	var new_game_button = %NewGameBtn
	new_game_button.pressed.connect(_on_new_game)
	exit_button.pressed.connect(_on_exit)

func _on_new_game() -> void:
	get_tree().change_scene_to_file("res://Menus/Character Selection/character_selections_menu.tscn")

func _on_exit() -> void:
	get_tree().quit()
