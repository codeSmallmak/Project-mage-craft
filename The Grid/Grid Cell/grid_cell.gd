extends Control
var occupied = false
var current_orb = null

func _ready() -> void:
	add_to_group("grid_cells")
