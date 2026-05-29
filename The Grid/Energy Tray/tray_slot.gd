extends Control

const EnergyOrbScene = preload("res://The Grid/Energy Orbs/energy_orb.tscn")

var occupied: bool = false

func _ready() -> void:
	await get_tree().process_frame
	spawn_orb()

func spawn_orb() -> void:
	if occupied:
		return
	var unlocked = SaveManager.save_data.get("unlocked_energies", [])
	if unlocked.is_empty():
		return
	var random_type = unlocked[randi() % unlocked.size()]
	var inst = EnergyOrbScene.instantiate()
	inst.energy_type = random_type
	inst.original_parent = self
	inst.scale = Vector2.ZERO
	get_tree().root.add_child.call_deferred(inst)
	inst.set_deferred("global_position", global_position + inst.size / 2)
	inst.pivot_offset = inst.size / 2
	occupied = true
	await get_tree().process_frame
	var tween = inst.create_tween()
	tween.tween_property(inst, "scale", Vector2.ONE, 0.3)
	await tween.finished
	inst.is_ready = true
