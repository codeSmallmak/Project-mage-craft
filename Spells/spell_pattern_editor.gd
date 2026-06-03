extends Control
class_name SpellPatternEditor

@onready var spell_label = %SpellNameDisplay
@onready var energy_btn = %EnergyBtn
@onready var save_btn = %SaveBtn
@onready var grid_container = %GridContainer
@onready var back_btn = %BackButton
@onready var forward_btn = %ForwardButton

var current_spell: SpellData = null
var grid_buttons = []
var current_spell_index: int = 0
var current_energy: int = Globals.EnergyType.FIRE
var spell_resources = []

var spell_dir = "res://Spells/Spell Resources/"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_spell_list()
	
	grid_buttons = grid_container.get_children()
	
	energy_btn.pressed.connect(_on_energy_button_pressed)
	energy_btn.gui_input.connect(_on_energy_btn_gui_input)
	save_btn.pressed.connect(_on_save_pressed)
	back_btn.pressed.connect(_on_prev_spell)
	forward_btn.pressed.connect(_on_next_spell)
	
	for i in range(grid_buttons.size()):
		var btn = grid_buttons[i]
		var x = i % 5
		@warning_ignore("integer_division")
		var y = i / 5
		btn.pressed.connect(_on_grid_button_pressed.bind(x, y))
	
	if spell_resources.size() > 0:
		current_spell_index = 0
		load_spell(spell_resources[0])
	
	_update_energy_label()

func _load_spell_list() -> void:
	var dir = DirAccess.open(spell_dir)
	if not dir:
		print("ERROR: Could not open spell directory: ", spell_dir)
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path = spell_dir + file_name
			var spell = load(path) as SpellData
			if spell:
				spell_resources.append(spell)
			else:
				print("WARNING: Could not load spell at: ", path)
		file_name = dir.get_next()

func _get_energy_name(energy_type: int) -> String:
	if energy_type == -1:
		return "WILDCARD"
	var keys = Globals.EnergyType.keys()
	if energy_type >= 0 and energy_type < keys.size():
		return keys[energy_type]
	return "NONE"

func load_spell(spell: SpellData) -> void:
	current_spell = spell
	spell_label.text = spell.display_name
	_pad_pattern_to_5x5()
	_update_grid()

func _pad_pattern_to_5x5() -> void:
	if current_spell.pattern.size() == 5:
		if current_spell.pattern[0].size() == 5:
			return
	
	# Create fresh 5x5 of wildcards (-1) instead of zeros
	var padded = []
	for y in range(5):
		var row = []
		for x in range(5):
			row.append(-1)  # Default to wildcard
		padded.append(row)
	
	# Copy existing pattern into top-left of 5x5
	for y in range(current_spell.pattern.size()):
		for x in range(current_spell.pattern[y].size()):
			padded[y][x] = current_spell.pattern[y][x]
	
	current_spell.pattern = padded	


func _update_grid() -> void:
	if not current_spell:
		return
	for i in range(grid_buttons.size()):
		@warning_ignore("integer_division")
		var y = i / 5
		var x = i % 5
		var btn = grid_buttons[i]
		var value = current_spell.pattern[y][x]
		btn.text = "*" if value == -1 else str(value)

func _update_energy_label() -> void:
	energy_btn.text = _get_energy_name(current_energy)

func _on_grid_button_pressed(x: int, y: int) -> void:
	if not current_spell:
		return
	current_spell.pattern[y][x] = current_energy
	_update_grid()

# Left click cycles forward, right click cycles backward
func _on_energy_btn_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_cycle_energy(-1)

func _on_energy_button_pressed() -> void:
	_cycle_energy(1)

func _cycle_energy(direction: int) -> void:
	var max_energy = Globals.EnergyType.size() - 1
	if current_energy == -1:
		current_energy = 0 if direction == 1 else max_energy
	elif current_energy == 0 and direction == -1:
		current_energy = -1
	elif current_energy == max_energy and direction == 1:
		current_energy = -1
	else:
		current_energy += direction
	_update_energy_label()

func _on_prev_spell() -> void:
	current_spell_index = max(0, current_spell_index - 1)
	load_spell(spell_resources[current_spell_index])

func _on_next_spell() -> void:
	current_spell_index = min(spell_resources.size() - 1, current_spell_index + 1)
	load_spell(spell_resources[current_spell_index])

func _on_save_pressed() -> void:
	if not current_spell:
		return
	current_spell.pattern = _get_trimmed_pattern()
	ResourceSaver.save(current_spell)
	print("Spell saved: ", current_spell.pattern)

# Trim outer zeros from pattern, preserving intentional internal gaps
func _get_trimmed_pattern() -> Array:
	var min_x = 4; var max_x = 0
	var min_y = 4; var max_y = 0
	var found = false
	
	for y in range(5):
		for x in range(5):
			if current_spell.pattern[y][x] != 0:
				min_x = min(min_x, x)
				max_x = max(max_x, x)
				min_y = min(min_y, y)
				max_y = max(max_y, y)
				found = true
	
	if not found:
		return []
	
	var trimmed = []
	for y in range(min_y, max_y + 1):
		var row = []
		for x in range(min_x, max_x + 1):
			row.append(current_spell.pattern[y][x])
		trimmed.append(row)
	
	print("Trimmed pattern: ", trimmed)
	return trimmed
