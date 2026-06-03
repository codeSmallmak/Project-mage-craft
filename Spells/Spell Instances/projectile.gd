extends Node2D

var damage: int = 0
var speed: float = 200.0
var hit: bool = false

func _ready() -> void:
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.6)

func _process(delta: float) -> void:
	if hit:
		return
		
	position.x += 200 * delta
	if position.x > 800:
		queue_free()
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) < 16:
			enemy.take_damage(damage)
			_on_impact()
			return
func _on_impact() -> void:
	hit = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	queue_free()
