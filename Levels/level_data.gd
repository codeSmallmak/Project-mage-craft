class_name LevelData
extends Resource

@export_group("Scrolling")
@export var scroll_speed: float = 50.0
@export var chunk_scenes: Array[PackedScene] = []


@export_group("Encounters")
@export var min_encounters: int = 3
@export var max_encounters: int = 6
@export var min_group_size: int = 1
@export var max_group_size: int = 3
@export var min_spawn_interval: float = 3.0
@export var max_spawn_interval: float = 8.0
@export var spawn_table: Array[SpawnEntry] = []

@export_group("Boss")
@export var boss_table: Array[SpawnEntry] = []
