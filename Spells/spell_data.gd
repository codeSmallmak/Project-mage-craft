class_name SpellData
extends Resource
enum SpellType { PROJECTILE, SEEKING_ORB }

@export var id: String = ""
@export var display_name: String = ""
@export var unlocked: bool = false
@export var spell_type: SpellType = SpellType.PROJECTILE
@export var spell_sprite_frames: SpriteFrames = null
@export var damage_min: int = 0
@export var damage_max: int = 0
@export var crit_chance: int = 0
@export var cast_animation: String = ""
@export var projectile_scene: PackedScene = null
@export var impact_fx: Globals.FXType
@export var pattern: Array = []
@export var orb_count_min: int = 1
@export var orb_count_max: int = 1


func _init() -> void:
	pattern = _empty_pattern()

func _empty_pattern() -> Array:
	var p = []
	for i in 5:
		var row = []
		for j in 5:
			row.append(-1)
		p.append(row)
	return p

func roll_damage() -> Array:
	var rolled = randi_range(damage_min, damage_max)
	if crit_chance > 0:
		if randi_range(1, crit_chance) == 1:
			return [rolled * 2, true]
	return [rolled, false]
