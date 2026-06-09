extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if SaveManager.has_save():
		SaveManager.read()
		SpellLoader.load_spells_for_save()
	else:
		get_tree().change_scene_to_file("res://Menus/Title/title.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
