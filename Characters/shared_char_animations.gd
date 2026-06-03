extends Node2D
signal projectile_ready

func _emit_projectile_ready() -> void:
	projectile_ready.emit()
	
