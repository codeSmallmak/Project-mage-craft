extends Node

const SPELL_DIR = "res://Spells/Spell Resources/"

func _ready() -> void:
	pass  # Don't load on startup

func load_spells_for_save() -> void:
	SpellManager.spells.clear()  # Flush previous run's spells
	var unlocked: Array = SaveManager.save_data.get("unlocked_spells", [])
	
	var dir = DirAccess.open(SPELL_DIR)
	if not dir:
		push_error("SpellLoader: could not open spell directory")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path = SPELL_DIR + file_name
			var spell = load(path) as SpellData
			if spell and spell.id in unlocked:
				SpellManager.register_spell(spell)
			
		file_name = dir.get_next()
	dir.list_dir_end()
