extends Node2D
@export var level_data: LevelData
var chunks := []
var active_chunks: Array[Node2D] = []
var scrolling: bool = true
var active_enemies: int = 0
var spawn_timer: float = 0.0
var next_spawn_time: float = 0.0
var encounters_remaining: int = 0
var in_combat: bool = false

@onready var hp_bar = %HPBar
@onready var player = $LevelCharacter
@onready var stop_positions = $StopPositions
@onready var player_lanes = $PlayerLanes

func _ready() -> void:
	chunks = level_data.chunk_scenes
	_spawn_chunk(0.0)
	_spawn_chunk(320.0)
	encounters_remaining = randi_range(level_data.min_encounters, level_data.max_encounters)
	next_spawn_time = 2.0
	player.setup_lanes(player_lanes.get_children())
	
	# Initialize HP from CharacterData
	var char_id = int(SaveManager.save_data.get("character", -1))
	var max_hp = 10  # Fallback
	if char_id >= 0:
		var char_data = CharacterManager.lookup.get(char_id)
		if char_data != null:
			max_hp = char_data.base_hp
	
	hp_bar.max_value = max_hp
	hp_bar.value = max_hp
	hp_bar.show_percentage = false
	player.hp = max_hp
	player.max_hp = max_hp
	player.hp_bar = hp_bar

func _process(delta: float) -> void:
	if not scrolling:
		return
	
	for chunk in active_chunks:
		chunk.position.x -= level_data.scroll_speed * delta
	if active_chunks.size() > 0:
		var front = active_chunks.back()
		if front.position.x <= 0.0:
			_spawn_chunk(front.position.x + 320.0)
	while active_chunks.size() > 0 and active_chunks.front().position.x <= -320.0:
		var old = active_chunks.pop_front()
		old.queue_free()
	
	# Spawn timer only ticks when not in combat
	if not in_combat:
		spawn_timer += delta
		if spawn_timer >= next_spawn_time:
			spawn_timer = 0.0
			_spawn_group()

func _spawn_chunk(x_pos: float) -> void:
	var chunk = chunks.pick_random().instantiate()
	chunk.z_index = -1
	chunk.position.x = x_pos
	add_child(chunk)
	active_chunks.append(chunk)

func _spawn_group() -> void:
	if encounters_remaining <= 0:
		# TODO: spawn boss
		return
	
	var table = level_data.spawn_table
	if table.is_empty():
		return
	
	encounters_remaining -= 1
	in_combat = true
	
	var group_size = randi_range(level_data.min_group_size, level_data.max_group_size)
	var markers = stop_positions.get_children()
	var used_markers = []
	
	for i in range(group_size):
		var entry = table.pick_random()
		var enemy = entry.enemy_scene.instantiate()
		enemy.enemy_data = entry.enemy_info
		
		var available = markers.filter(func(m): return m not in used_markers)
		if available.is_empty():
			break
		var marker = available.pick_random()
		used_markers.append(marker)
		# Parse row from marker name e.g. "Row0Col2"
		# substr(3, 1) — start at index 3 (after "Row"), read 1 character to get the row number
		var row = int(marker.name.substr(3, 1))
		enemy.lane = row
		enemy.stop_position = marker.position.x
		enemy.position = Vector2(360 + (i * 16), marker.position.y)
		enemy.player = player
		enemy.reached_position.connect(func(): fight_start())
		enemy.died.connect(func(): _on_enemy_died())
		active_enemies += 1
		add_child(enemy)

func fight_start() -> void:
	if not scrolling:
		return
	in_combat = true
	scrolling = false
	player.stop_walking()

func _on_enemy_died() -> void:
	active_enemies -= 1
	if active_enemies <= 0:
		in_combat = false
		scrolling = true
		player.queue_animation("WalkRight", player.State.WALKING)
		next_spawn_time = randf_range(level_data.min_spawn_interval, level_data.max_spawn_interval)
		spawn_timer = 0.0
