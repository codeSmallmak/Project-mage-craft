extends Node2D
var damage: int = 0
var speed: float = 200.0
var hit: bool = false
var is_crit: bool = false
var lane: int = 1  # Set by LevelCharacter on spawn
var impact_fx: Globals.FXType = Globals.FXType.IMPACT1
var spell_sprite_frames: SpriteFrames = null

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if spell_sprite_frames != null:
		anim_sprite.sprite_frames = spell_sprite_frames
		anim_sprite.play("default")
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.6)

func _process(delta: float) -> void:
	if hit:
		return
	
	position.x += speed * delta
	if position.x > 800:
		queue_free()
	
	# Find enemies in same lane, hit the closest one
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var closest_dist = 16.0
	
	for enemy in enemies:
		if enemy.lane != lane:
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_enemy = enemy
	
	if closest_enemy != null:
		closest_enemy.take_damage(damage, is_crit)
		_on_impact()

func _on_impact() -> void:
	hit = true
	Globals.spawn_fx(get_parent(), global_position, impact_fx)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.05)
	tween.tween_property(self, "modulate:a", 0.0, 0.05)
	await tween.finished
	queue_free()
