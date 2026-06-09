class_name EnemyData
extends Resource

@export var id: String
@export var display_name: String
@export var sprite_sheet: Texture2D
@export var sprite_frames: SpriteFrames
@export var hp: int
@export var can_shuffle: bool = false

@export_group("Attack")
@export var attack_interval: float = 1.0
@export var attacks: Array[AttackData] = []

@export_group("Boss")
@export var is_boss := false
@export var boss_name: String = ""
@export var boss_title: String = ""
@export var boss_loot_table: Array[LootEntry] = []
@export var boss_lane: int = -1

func roll_attack() -> AttackData:
	if attacks.is_empty():
		return null
	var total: float = 0.0
	for a in attacks:
		total += a.weight
	var roll := randf() * total
	var cumulative: float = 0.0
	for a in attacks:
		cumulative += a.weight
		if roll <= cumulative:
			return a
	return attacks.back()

func roll_loot() -> LootEntry:
	if boss_loot_table.is_empty():
		return null
	var total_weight: float = 0.0
	for entry in boss_loot_table:
		total_weight += entry.weight
	var roll := randf() * total_weight
	var cumulative: float = 0.0
	for entry in boss_loot_table:
		cumulative += entry.weight
		if roll <= cumulative:
			return entry
	return boss_loot_table.back()
