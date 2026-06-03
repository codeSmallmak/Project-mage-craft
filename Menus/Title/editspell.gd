extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	# Load the pattern editor scene
	var editor = preload("res://Spells/spell_pattern_editor.tscn").instantiate()
	get_tree().root.add_child(editor)
	
	# Load current spell (you'd pass this in or select from a list)
	# For now, grab the first spell
	if SpellManager.spells.size() > 0:
		editor.load_spell(SpellManager.spells[0])
