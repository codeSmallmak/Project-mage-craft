extends Control

func _ready() -> void:
	var exit_button = %ExitBtn
	var new_game_button = %NewGameBtn
	var load_game_button = %LoadGameBtn
	
	new_game_button.pressed.connect(_on_new_game)
	exit_button.pressed.connect(_on_exit)
	load_game_button.pressed.connect(_on_load_game)
	load_game_button.disabled = !SaveManager.has_save()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_grave"):  # ~ key
		var editor = preload("res://Spells/spell_pattern_editor.tscn").instantiate()
		get_tree().root.add_child(editor)

func _on_new_game() -> void:
	get_tree().change_scene_to_file("res://Menus/Character Selection/character_selections_menu.tscn")

func _on_load_game() -> void:
	SaveManager.read()
	get_tree().change_scene_to_file("res://Game/game.tscn")

func _on_exit() -> void:
	get_tree().quit()
