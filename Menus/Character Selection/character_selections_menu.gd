extends Control

@export var cedric_data: CharacterData
@export var gen_data: CharacterData
@export var knocker_data: CharacterData

var selected_character: CharacterData = null

func _ready() -> void:
	%CedricButton.pressed.connect(_on_character_selected.bind(cedric_data))
	%GenButton.pressed.connect(_on_character_selected.bind(gen_data))
	%KnockerButton.pressed.connect(_on_character_selected.bind(knocker_data))
	%StartButton.pressed.connect(_on_start)
	%BackButton.pressed.connect(_on_back)
	%StartButton.disabled = true

func _on_character_selected(data: CharacterData) -> void:
	selected_character = data
	%LoreLabel.text = data.lore
	%StartButton.disabled = false

func _on_start() -> void:
	if selected_character == null:
		return
	SaveManager.new_run(selected_character.id)
	get_tree().change_scene_to_file("res://Game/game.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://Menus/Title/title.tscn")
