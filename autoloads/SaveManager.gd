extends Node

const SAVE_PATH = "user://save.json"

var save_data: Dictionary = {}

func new_run(character_id: int) -> void:
	save_data = {
		"character": character_id,
		"current_map": "",
		"current_node": "",
		"completed_nodes": [],
		"hp": 0,
		"max_hp": 0,
		"unlocked_spells": [],
		"unlocked_energies": []
	}
	write()

func write() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))

func read() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	save_data = JSON.parse_string(file.get_as_text())
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
		save_data = {}
