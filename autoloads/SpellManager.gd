extends Node

var spells: Array = []
var _lookup: Dictionary = {}

func _ready() -> void:
	_build_lookup()

func register_spell(spell: SpellData) -> void:
	spells.append(spell)
	_lookup[_pattern_to_key(spell.pattern)] = spell

func _build_lookup() -> void:
	_lookup.clear()
	for spell in spells:
		_lookup[_pattern_to_key(spell.pattern)] = spell

func check_pattern(grid: Array) -> SpellData:
	return _lookup.get(_pattern_to_key(grid), null)

func _pattern_to_key(_pattern: Array) -> String:
	return ""
	#var key = ""
	#for row in pattern:
		#for cell in row:
			#key += str(cell)
	#return key
