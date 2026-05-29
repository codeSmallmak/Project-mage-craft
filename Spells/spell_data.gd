class_name SpellData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var unlocked: bool = false
@export var damage: int = 0
@export var cast_animation: String = ""
@export var projectile_scene: PackedScene = null
@export var pattern: Array = []
@export var rotations: String = "none"  # ADD — "none", "2way", "all4"

# Array of triplet values that determine the offset position and orb type at the position. 
# Ex. [0, 0, 1,  1, 0, 1,  2, 0, 1] would be a horizontal line of 3 fire orbs
# read as [0, 0, 1, | 1, 0, 1, | 2, 0, 1] with 0,0 -The leftmost cell- set to orb type 1 -fire-
# then 1,0 -the cell 1 position to the positive x of 0,0- also being orb type 1 and so on. 
# Alt explanation: Reading that as triplets: (x=0, y=0, orb=FIRE), (x=1, y=0, orb=FIRE), (x=2, y=0, orb=FIRE)
@export var slots: Array = [] # If slots is empty, the spell uses the legacy pattern field instead.

func _init() -> void:
	pattern = _empty_pattern()

func _empty_pattern() -> Array:
	var p = []
	for i in 5:
		var row = []
		for j in 5:
			row.append(0)
		p.append(row)
	return p

# ADD — converts legacy pattern to slots format for unified detection
func get_slots() -> Array:
	var result = []
	if not slots.is_empty():
		var i = 0
		while i +2 < slots.size():
			var offset = Vector2i( slots[i], slots[i + 1])
			result.append({ "offset": offset, "orb": slots[i + 2] })
			i += 3
		return result
	
	# Convert legacy 5x5 patter to slot list
	for y in range(5):
		for x in range(5):
			if pattern[y][x] != Globals.EnergyType.NONE:
				result.append({ "offset": Vector2i(x, y), "orb": pattern[x][y] })
	return result
