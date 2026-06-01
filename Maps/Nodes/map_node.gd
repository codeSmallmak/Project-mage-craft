class_name MapNode
extends Node2D

@export var up: String = ""
@export var down: String = ""
@export var left: String = ""
@export var right: String = ""
@export var is_blocking: bool = false
@export var is_level: bool = false
@export var level_scene: PackedScene = null
@export var level_name: String = ""


func _ready() -> void:
	if is_level and SaveManager.is_node_completed(name):
		is_blocking = false

func get_connection(direction: String) -> String:
	match direction:
		"up": return up
		"down": return down
		"left": return left
		"right": return right
	return ""

func _enter_level() -> void:
	SaveManager.save_data["current_node"] = name
	SaveManager.write()
	get_tree().change_scene_to_packed(level_scene)
