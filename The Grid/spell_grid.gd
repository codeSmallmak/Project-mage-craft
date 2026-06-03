extends Control

func _ready() -> void:
	add_to_group("spell_grid")

func on_orb_placed() -> void:
	var grid = _build_grid_state()
	var matches = SpellManager.detect_all(grid)
	
	if matches.size() > 0:
		_cast_spells(matches, grid)

# Build a 5x5 grid array from occupied cells
func _build_grid_state() -> Array:
	var grid = []
	for y in range(5):
		var row = []
		for x in range(5):
			row.append(0)  # Default to empty
		grid.append(row)
	
	# Fill in occupied cells
	for cell in get_tree().get_nodes_in_group("grid_cells"):
		if cell.occupied and cell.current_orb != null:
			var pos = _cell_to_grid_pos(cell)
			grid[pos.y][pos.x] = cell.current_orb.energy_type
	
	return grid

# Convert grid cell index to Vector2i grid coordinates
func _cell_to_grid_pos(cell) -> Vector2i:
	var idx = cell.get_index()
	return Vector2i(idx % 5, idx / 5)

# Cast all matched spells and remove consumed orbs
func _cast_spells(matches: Array, grid: Array) -> void:
	var consumed = {}
	
	for match in matches:
		# Set spell reference on the match
		# Need to find which spell this pattern belonged to
		var matched_spell = _find_spell_for_match(match, grid)
		if matched_spell:
			for pos in match.cells:
				consumed[pos] = true
			SpellManager.spell_cast_requested.emit(matched_spell)
	
	# Remove consumed orbs
	for cell in get_tree().get_nodes_in_group("grid_cells"):
		var pos = _cell_to_grid_pos(cell)
		if consumed.has(pos):
			if cell.current_orb != null:
				cell.current_orb.queue_free()
				cell.current_orb = null
			cell.occupied = false

# Find which spell this match came from
func _find_spell_for_match(match: Dictionary, grid: Array) -> SpellData:
	var pos = match.position
	for spell in SpellManager.spells:
		if SpellManager._matches_at(spell.pattern, grid, pos.x, pos.y):
			return spell
	return null
