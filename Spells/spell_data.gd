class_name SpellData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var unlocked: bool = false
@export var damage: int = 0
@export var cast_animation: String = ""
@export var projectile_scene: PackedScene = null
@export var pattern: Array = []

func _init() -> void:
	pattern = _empty_pattern()

func _empty_pattern() -> Array:
	var p = []
	for i in 5:
		var row = []
		for j in 5:
			row.append(Globals.EnergyType.NONE)
		p.append(row)
	return p
