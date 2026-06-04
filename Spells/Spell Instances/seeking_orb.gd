extends Node2D
var damage: int = 0
var is_crit: bool = false
var impact_fx: Globals.FXType = Globals.FXType.IMPACT1
var target: Node2D = null
var hit: bool = false
# Organic movement
var time: float = 0.0
var wobble_x: float = randf_range(1.5, 3.0)
var wobble_y: float = randf_range(1.5, 3.0)
var wobble_strength: float = randf_range(8.0, 20.0)
var speed: float = 80.0
var spell_sprite_frames: SpriteFrames = null
var delay: float = 0.0
var _ready_to_move: bool = false

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_ready_to_move = false
	delay = randf_range(0.0, 0.8)
	
	if spell_sprite_frames != null:
		anim_sprite.sprite_frames = spell_sprite_frames
		anim_sprite.play("default")
	
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	tween.tween_callback(func(): _ready_to_move = true)

func _process(delta: float) -> void:
	if not _ready_to_move:
		return
	
	if delay > 0.0:
		delay -= delta
		return
	
	if hit:
		return
	
	time += delta
	
	if not is_instance_valid(target):
		_fade_out()
		return
	
	var dir = (target.global_position - global_position).normalized()
	var wobble = Vector2(
		sin(time * wobble_x * PI) * wobble_strength,
		cos(time * wobble_y * PI) * wobble_strength
	)
	
	position += (dir * speed + wobble) * delta
	
	if global_position.distance_to(target.global_position) < 12:
		target.take_damage(damage, is_crit)
		Globals.spawn_fx(get_parent(), global_position, impact_fx)
		_fade_out()

func _fade_out() -> void:
	hit = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	queue_free()
