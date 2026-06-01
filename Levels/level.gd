extends Node2D

@export var level_data: LevelData
var chunks := []
var active_chunks: Array[Node2D] = []
var scrolling: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chunks = level_data.chunk_scenes
	_spawn_chunk(0.0)
	_spawn_chunk(320.0)
	_spawn_enemy()

# Called every frame. 'delta' is the elapsed time since the previous frame.
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
	
func _spawn_chunk(x_pos: float) -> void:
	var chunk = chunks.pick_random().instantiate()
	chunk.z_index = -1
	chunk.position.x = x_pos
	add_child(chunk)
	active_chunks.append(chunk)


func _spawn_enemy() -> void:
	var table = level_data.spawn_table
	if table.is_empty():
		return
	var entry = table.pick_random()
	var enemy = entry.enemy_scene.instantiate()
	enemy.enemy_data = entry.enemy_info
	enemy.position = Vector2(660, 40)
	add_child(enemy)
