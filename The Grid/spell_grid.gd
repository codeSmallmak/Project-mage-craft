extends Control

func _ready() -> void:
	add_to_group("spell_grid")

# Call this after any orb is placed or removed
# Build the grid_state dict from your current cell nodes
func on_orb_placed() -> void:
	var grid_state = _build_grid_state()
	var matches = SpellManager.detect_all(grid_state)
	if matches.size() > 0:
		_cast_spells(matches, grid_state)

func _build_grid_state() -> Dictionary:
	var state = {}
	for cell in get_tree().get_nodes_in_group("grid_cells"):
		if cell.occupied and cell.current_orb != null:
			state[_cell_to_grid_pos(cell)] = cell.current_orb.energy_type
	return state

func _cell_to_grid_pos(cell) -> Vector2i:
	# Convert the cell's position in the grid layout to a Vector2i coordinate
	# Adjust this to match how your GridContainer or layout positions cells
	var idx = cell.get_index()
	return Vector2i(idx % 5, idx / 5)

func _cast_spells(matches: Array, grid_state: Dictionary) -> void:
	# Collect all cells to consume across all matches
	var consumed = {}
	for match in matches:
		for pos in match.cells:
			consumed[pos] = true
		# Trigger the spell effect
		print("Cast: %s" % match.spell.display_name)
		# TODO: connect to your damage/VFX systems here

	# Clear only the consumed cells
	for cell in get_tree().get_nodes_in_group("grid_cells"):
		var pos = _cell_to_grid_pos(cell)
		if consumed.has(pos):
			if cell.current_orb != null:
				cell.current_orb.queue_free()
				cell.current_orb = null
			cell.occupied = false
