extends Node
@warning_ignore("unused_signal")
signal spell_cast_requested(spell: SpellData)

var spells: Array = []

func _ready() -> void:
	pass  # SpellLoader populates via register_spell()

func register_spell(spell: SpellData) -> void:
	spells.append(spell)

# Detect all spell pattern matches in the grid
# Returns array of matches: { "spell": spell, "position": Vector2i, "cells": Array }
func detect_all(grid: Array) -> Array:
	var matches = []
	
	for spell in spells:
		if spell.pattern.is_empty():
			continue
		
		var result = _find_pattern(spell.pattern, grid)
		if result != null:
			result["spell"] = spell
			matches.append(result)
	
	return matches

# Search for pattern anywhere in grid, return first match
func _find_pattern(pattern: Array, grid: Array) -> Variant:
	var p_height = pattern.size()
	var p_width = pattern[0].size() if p_height > 0 else 0
	
	var g_height = grid.size()
	var g_width = grid[0].size() if g_height > 0 else 0
	
	# Try every possible top-left position
	for start_y in range(g_height - p_height + 1):
		for start_x in range(g_width - p_width + 1):
			if _matches_at(pattern, grid, start_x, start_y):
				# Found match, collect the cell positions
				var cells = []
				for py in range(p_height):
					for px in range(p_width):
						if pattern[py][px] != -1:  # Only real pattern cells, not wildcards
							cells.append(Vector2i(start_x + px, start_y + py))
				
				return {
					"spell": null,  # Set by detect_all()
					"position": Vector2i(start_x, start_y),
					"cells": cells
				}
	
	return null

# Check if pattern matches at grid position (start_x, start_y)
func _matches_at(pattern: Array, grid: Array, start_x: int, start_y: int) -> bool:
	var p_height = pattern.size()
	var p_width = pattern[0].size()
	
	for py in range(p_height):
		for px in range(p_width):
			if pattern[py][px] == -1:  # Wildcard, match anything
				continue
			if pattern[py][px] != grid[start_y + py][start_x + px]:
				return false
	
	return true
