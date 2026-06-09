class_name AttackData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var weight: float = 1.0
@export var animation: String = ""
@export var impact_frame: int = 0

@export_group("Damage")
@export var damage_min: int = 0
@export var damage_max: int = 0
@export var impact_fx: Globals.FXType = Globals.FXType.IMPACT1

@export_group("Range")
@export var range_above: int = 0
@export var range_below: int = 0

@export_group("Positioning")
@export var attack_x_offset: float = 16.0

@export_group("Projectile")
@export var is_projectile: bool = false
@export var projectile_sprite_frames: SpriteFrames = null
@export var trail_sprite_frames: SpriteFrames = null
@export var trail_spawn_interval: float = 0.1
@export var projectile_speed: float = 150.0
@export var projectile_y_offset: float = -8.0



func roll_damage() -> int:
	return randi_range(damage_min, damage_max)

func get_attack_lanes(enemy_lane: int) -> Array[int]:
	var hit_lanes: Array[int] = []
	for i in range(enemy_lane - range_above, enemy_lane + range_below + 1):
		if i >= 0 and i <= 2:
			hit_lanes.append(i)
	return hit_lanes
