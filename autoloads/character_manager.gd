extends Node

const CEDRIC = preload("res://Characters/Character Resources/Cedric.tres")
const GEN = preload("res://Characters/Character Resources/Genevieve.tres")
const KNOCKER = preload("res://Characters/Character Resources/Knocker.tres")

var lookup: Dictionary = {}

func _ready() -> void:
	for c in [CEDRIC, GEN, KNOCKER]:
		lookup[c.id] = c
