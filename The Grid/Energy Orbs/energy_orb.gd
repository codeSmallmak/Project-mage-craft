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
	if !is_ready or !is_being_dragged:
		return
	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position() - mouse_offset
	if event.is_action_released("primary"):
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
			best_cell.current_orb = self
			get_tree().get_first_node_in_group("spell_grid").on_orb_placed()
		
		global_position = dragged_from_pos

func _update_visuals() -> void:
	# 1. Get the list of names from your enum (e.g., ["NONE", "FIRE", "ICE", ...])
	var enum_keys = Globals.EnergyType.keys()
	
	# Safety check: make sure the current energy_type index is actually valid
	if energy_type < 0 or energy_type >= enum_keys.size():
		push_error("Energy type index " + str(energy_type) + " is out of bounds!")
		return
		
	# 2. Convert the enum name to lowercase (e.g., "LIGHTNING" becomes "lightning")
	var element_name: String = enum_keys[energy_type].to_lower()
	
	# 3. Construct the path dynamically
	var base_path: String = "res://The Grid/Energy Orbs/Energy Icons/"
	var full_path: String = base_path + element_name + "_energy_icon.tres"
	
	# 4. Use load() instead of preload() so it can accept a dynamic string variable
	if ResourceLoader.exists(full_path):
		%IconSprite.texture = load(full_path)
	else:
		push_error("Automatic Orb Loader: Missing file at '" + full_path + "'. Does the file name match your Globals enum?")
