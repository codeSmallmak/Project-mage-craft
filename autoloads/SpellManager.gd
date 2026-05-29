extends Node

# All registered spells including rotation variants
var spells: Array = []

# Internal: built from spells at load time, same structure as before
# but now keyed differently — we don't use this for detection anymore
var _lookup: Dictionary = {}

func _ready() -> void:
	pass  # SpellLoader populates via register_spell()

func register_spell(spell) -> void:
	# Generate rotation variants and register each one
	spells.append(spell)

# Core detection function: Called whenever an orb is placed
# Returns all SpellData whose slot patterns are present on the gird. 
# grid_state is a dictionary of { Vector2i: int} of only the occupied cells
func detect_all(grid_state: Dictionary) -> Array:
	# print("detect_all called, grid has ", grid_state.size(), " occupied cells")
	var matches = []
	# Build a position lookup per orb type for fast anchor filtering
	# This is what makes it efficient 
	var orb_positions = {}
	for pos in grid_state:
		var orb = grid_state[pos]
		if not orb_positions.has(orb):
			orb_positions[orb] = []
		orb_positions[orb].append(pos)
	
	for spell in spells:
		var variants = _expand_rotations(spell)
		for variant in variants:
			var spell_slots = spell.get_slots()
			if spell_slots.is_empty():
				continue
			var anchor_orb = spell_slots[0].orb
			for anchor_pos in orb_positions.get(anchor_orb, []):
				if _try_match(spell, spell_slots, anchor_pos, grid_state):
					matches.append({ "spell": spell, "anchor": anchor_pos, "cells": _get_match_cells(spell_slots, anchor_pos) })
	
	return matches

func _try_match(spell, slots, anchor, grid_state) -> bool:
	for slot in slots:
		var pos = anchor + slot.offset
		if not grid_state.has(pos):
			return false
		if grid_state[pos] != slot.orb:
			return false
	return true

func _get_match_cells(slots, anchor) -> Array:
	var cells  = []
	for slot in slots:
		cells.append(anchor + slot.offset)
	return cells

# Kept to check_pattern to avoid errors in any legacy code that calls it
# Converts the pattern in the grid to a string and checks for exact matches
func check_pattern(grid: Array) -> SpellData:
	return _lookup.get(_pattern_to_key(grid), null)

func _pattern_to_key(pattern: Array) -> String:
	var key = ""
	for row in pattern:
		for cell in row:
			key += str(cell)
	return key

# Allow for rotation of specific spells based off paramaters set in json spell data. 
# mirrors the logic already found in spell_library.gd
func _expand_rotations(spell) -> Array:
	var base_slots = spell.get_slots()
	var flag = spell.rotations
	
	var slot_variants = []
	match flag:
		"none":
			slot_variants = [base_slots]
		"2way":
			slot_variants = [base_slots, _rotate_slots(base_slots)]
		"all4":
			var current = base_slots
			for _i in range(4):
				current = _rotate_slots(current)
				if not _is_duplicate(slot_variants, current):
					slot_variants.append(current)
		_:
			slot_variants = [base_slots]
	
	var result = []
	for i in range(slot_variants.size()):
		# Create a lightweight wrapper - duplicate the spell resource and override its slots with 
		# the rotation variant
		var variant = spell.duplicate()
		variant.slots = slot_variants[i]
		variant.id = spell.id + ("" if slot_variants.size() == 1 else "_rot%d" % i)
		result.append(variant)
	return result
	
func _rotate_slots(slots: Array) -> Array:
	var rotated = []
	for s in slots:
		rotated.append({ "offset": Vector2i(-s.offset.y, s.offset.x), "orb": s.orb })
	var min_x = rotated[0].offset.x
	var min_y = rotated[0].offset.y
	for s in rotated:
		min_x = min(min_x, s.offset.x)
		min_y = min(min_y, s.offset.y)
	var normalized = []
	for s in rotated:
		normalized.append({ "offset": s.offset - Vector2i(min_x, min_y), "orb": s.orb })
	return normalized

func _is_duplicate(existing: Array, candidate: Array) -> bool:
	for accepted in existing:
		if _slots_equal(accepted, candidate):
			return true
	return false

func _slots_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size(): return false
	var freq = {}
	for s in a:
		var key = "%d,%d,%d" % [s.offset.x, s.offset.y, s.orb]
		freq[key] = freq.get(key, 0) + 1
	for s in b:
		var key = "%d,%d,%d" % [s.offset.x, s.offset.y, s.orb]
		if not freq.has(key) or freq[key] == 0: return false
		freq[key] -= 1
	return true
