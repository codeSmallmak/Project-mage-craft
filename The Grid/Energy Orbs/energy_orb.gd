extends Control
var energy_type: int = Globals.EnergyType.FIRE
var is_being_dragged := false
var drag_info : Dictionary
var original_parent : Control
var dragged_from_pos : Vector2
var mouse_offset : Vector2
var is_ready: bool = false

func _ready() -> void:
	_update_visuals()

func _on_gui_input(event: InputEvent) -> void:
	if !is_ready:
		return
	if event.is_action_pressed("primary") && !is_being_dragged:
		mouse_offset = get_local_mouse_position()
		dragged_from_pos = global_position
		z_index += 1
		is_being_dragged = true

func _input(event):
	if !is_ready:
		return
	if event is InputEventMouseMotion && is_being_dragged:
		global_position = get_global_mouse_position() - mouse_offset
	if event.is_action_released("primary") && is_being_dragged:
		z_index -= 1
		is_being_dragged = false
		
		var best_cell = null
		var best_area = 0.0
		
		for cell in get_tree().get_nodes_in_group("grid_cells"):
			var intersection = cell.get_global_rect().intersection(get_global_rect())
			if intersection.get_area() > best_area:
				best_area = intersection.get_area()
				best_cell = cell
		
		if best_cell and !best_cell.occupied:
			original_parent.occupied = false
			if original_parent.has_method("spawn_orb"):
				original_parent.spawn_orb()
			original_parent = best_cell
			dragged_from_pos = best_cell.global_position
			best_cell.occupied = true
		
		global_position = dragged_from_pos

func _update_visuals() -> void:
	var icons = {
		Globals.EnergyType.FIRE: preload("res://The Grid/Energy Orbs/Energy Icons/fire_energy_icon.tres"),
		Globals.EnergyType.ICE: preload("res://The Grid/Energy Orbs/Energy Icons/ice_energy_icon.tres"),
		Globals.EnergyType.LIGHTNING: preload("res://The Grid/Energy Orbs/Energy Icons/lightning_energy_icon.tres"),
		Globals.EnergyType.NATURE: preload("res://The Grid/Energy Orbs/Energy Icons/nature_energy_icon.tres"),
		Globals.EnergyType.WATER: preload("res://The Grid/Energy Orbs/Energy Icons/water_energy_icon.tres"),
		Globals.EnergyType.WIND: preload("res://The Grid/Energy Orbs/Energy Icons/wind_energy_icon.tres"),
	}
	%IconSprite.texture = icons[energy_type]
