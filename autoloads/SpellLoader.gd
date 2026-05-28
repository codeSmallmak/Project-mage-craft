extends Node

const SPELL_DIR = "res://Spells/Spell Resources/"

func _ready() -> void:
	load_all_spells()

func load_all_spells() -> void:
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
			if spell:
				SpellManager.register_spell(spell)
			else:
				push_warning("SpellLoader: failed to load %s" % path)
		file_name = dir.get_next()

	dir.list_dir_end()
