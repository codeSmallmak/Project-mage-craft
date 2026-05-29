class_name MapNode
extends Node2D

@export var up: String = ""
@export var down: String = ""
@export var left: String = ""
@export var right: String = ""
@export var is_blocking: bool = false

func get_connection(direction: String) -> String:
	match direction:
		"up": return up
		"down": return down
		"left": return left
		"right": return right
	return ""
