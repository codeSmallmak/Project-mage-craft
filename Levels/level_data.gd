class_name LevelData
extends Resource

@export var chunk_scenes: Array[PackedScene] = []
@export var scroll_speed: float = 50.0
@export var spawn_table: Array[SpawnEntry] = []
@export var min_group_size: int = 1
@export var max_group_size: int = 3
@export var min_spawn_interval: float = 3.0  # Seconds between spawns
@export var max_spawn_interval: float = 8.0  # Seconds between spawns
@export var min_encounters: int = 3          # Min groups before boss
@export var max_encounters: int = 6          # Max groups before boss
