# energy_orb.gd
extends Control

var energy_type: int = Globals.EnergyType.FIRE
var is_being_dragged := false
var original_parent : Control
var dragged_from_pos : Vector2
var mouse_offset : Vector2
var is_ready: bool = false

func _ready() -> void:
	_update_visuals()

func _on_gui_input(event: InputEvent) -> void:
	if not is_ready:
		return
	if event.is_action_pressed("primary") and not is_being_dragged:
		mouse_offset = get_local_mouse_position()
		dragged_from_pos = global_position
		z_index += 1
		is_being_dragged = true

# Handle dragging and grid snapping
func _input(event) -> void:
	if not is_ready or not is_being_dragged:
		return
	
	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position() - mouse_offset
	
	if event.is_action_released("primary"):
		_on_drag_release()

# Release the orb and snap to the best grid cell
func _on_drag_release() -> void:
	z_index -= 1
	is_being_dragged = false
	
	var best_cell = null
	var best_area = 0.0
	
	# Find the grid cell with the most overlap
	for cell in get_tree().get_nodes_in_group("grid_cells"):
		var intersection = cell.get_global_rect().intersection(get_global_rect())
		if intersection.get_area() > best_area:
			best_area = intersection.get_area()
			best_cell = cell
	
	# Snap to best cell if it's empty
	if best_cell and not best_cell.occupied:
		original_parent.occupied = false
		if original_parent.has_method("spawn_orb"):
			original_parent.spawn_orb()
		
		original_parent = best_cell
		dragged_from_pos = best_cell.global_position
		best_cell.occupied = true
		best_cell.current_orb = self
		
		# Notify spell grid that orb placement changed
		get_tree().get_first_node_in_group("spell_grid").on_orb_placed()
	
	global_position = dragged_from_pos

# Load the visual icon for this orb type
func _update_visuals() -> void:
	var enum_keys = Globals.EnergyType.keys()
	
	if energy_type < 0 or energy_type >= enum_keys.size():
		push_error("Energy type index " + str(energy_type) + " is out of bounds!")
		return
	
	var element_name: String = enum_keys[energy_type].to_lower()
	var full_path: String = "res://The Grid/Energy Orbs/Energy Icons/" + element_name + "_energy_icon.tres"
	
	if ResourceLoader.exists(full_path):
		%IconSprite.texture = load(full_path)
	else:
		push_error("Automatic Orb Loader: Missing file at '" + full_path + "'. Does the file name match your Globals enum?")
