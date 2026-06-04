class_name EnemyData
extends Resource

@export var id: String
@export var display_name: String
@export var sprite_sheet: Texture2D
@export var sprite_frames: SpriteFrames
@export var hp: int
@export var attack_impact_fx: Globals.FXType = Globals.FXType.IMPACT1
@export var attack_damage_min: int
@export var attack_damage_max: int
@export var attack_interval: float
@export var attack_impact_frame: int = 0  # Which frame triggers the hit
@export var attack_range_above: int = 0
@export var attack_range_below: int = 0
@export var allowed_lanes: Array[int] = [0, 1, 2]
@export var is_boss := false

func roll_damage() -> int:
	return randi_range(attack_damage_min, attack_damage_max)

func get_attack_lanes(enemy_lane: int) -> Array[int]:
	var hit_lanes: Array[int] = []
	for i in range(enemy_lane - attack_range_above, enemy_lane + attack_range_below + 1):
		if i >= 0 and i <= 2:
			hit_lanes.append(i)
	return hit_lanes
