extends Control

@export var cedric_data: CharacterData
@export var gen_data: CharacterData
@export var knocker_data: CharacterData

var selected_character: CharacterData = null

func _ready() -> void:
	%CedricButton.pressed.connect(_on_character_selected.bind(cedric_data, %CedricButton))
	%GenButton.pressed.connect(_on_character_selected.bind(gen_data, %GenButton))
	%KnockerButton.pressed.connect(_on_character_selected.bind(knocker_data, %KnockerButton))
	%StartButton.pressed.connect(_on_start)
	%BackButton.pressed.connect(_on_back)
	%StartButton.disabled = true

var selected_button: Button = null

func _on_character_selected(data: CharacterData, button: Button) -> void:
	if selected_button:
		selected_button.button_pressed = false
	selected_button = button
	selected_button.button_pressed = true
	selected_character = data
	%LoreLabel.text = data.lore
	%StartButton.disabled = false

func _on_start() -> void:
	if selected_character == null:
		return
	SaveManager.save_data = {
		"character": selected_character.id,
		"current_map": "",
		"current_node": "",
		"completed_nodes": [],
		"hp": selected_character.base_hp,
		"max_hp": selected_character.base_hp,
		"unlocked_spells": [],
		"unlocked_energies": selected_character.starting_energies
	}
	SaveManager.write()
	get_tree().change_scene_to_file("res://The Grid/spell_grid.tscn")


func _on_back() -> void:
	get_tree().change_scene_to_file("res://Menus/Title/title.tscn")
