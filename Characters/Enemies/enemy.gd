extends Node2D
@export var enemy_data: EnemyData
@export var stop_position: float = 200.0
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var charge_bar: ProgressBar = $ProgressBar

signal reached_position
signal died

enum State { WALK, IDLE, DASH_FORWARD, ATTACK, DASH_BACK, HIT }
var current_state: State = State.WALK
var charge_time: float = 0.0
var hit_timer: float = 0.0
const HIT_DURATION: float = 0.5
var player: Node2D
var hp: int = 0

func _ready() -> void:
	add_to_group("enemies")
	if enemy_data != null:
		anim_sprite.sprite_frames = enemy_data.sprite_frames
		anim_sprite.play("walk")
		hp = enemy_data.hp
	
	charge_bar.custom_minimum_size = Vector2(32, 4)
	charge_bar.show_percentage = false

func _process(delta: float) -> void:
	charge_bar.visible = (current_state == State.IDLE or current_state == State.HIT)
	
	match current_state:
		State.WALK:
			position.x -= 50 * delta
			if position.x <= stop_position:
				position.x = stop_position
				current_state = State.IDLE
				reached_position.emit()
				anim_sprite.play("idle")
				charge_time = 0.0
		
		State.IDLE:
			charge_time += delta
			charge_bar.value = (charge_time / enemy_data.attack_interval) * 100.0
			if charge_time >= enemy_data.attack_interval:
				current_state = State.DASH_FORWARD
				_dash_forward()
		
		State.HIT:
			hit_timer -= delta
			# Blink by toggling visibility on a short interval
			anim_sprite.visible = int(hit_timer * 10) % 2 == 0
			if hit_timer <= 0.0:
				anim_sprite.visible = true
				current_state = State.IDLE
				anim_sprite.play("idle")

func take_damage(damage: int) -> void:
	# Immune during dashes
	if current_state == State.DASH_FORWARD or current_state == State.DASH_BACK:
		return
	
	hp -= damage
	
	if hp <= 0:
		_die()
		return
	
	_enter_hit()

func _enter_hit() -> void:
	current_state = State.HIT
	hit_timer = HIT_DURATION
	anim_sprite.play("hit")

func _die() -> void:
	current_state = State.HIT  # Prevent further actions
	anim_sprite.play("hit")
	await anim_sprite.animation_finished
	died.emit()
	queue_free()

func _dash_forward() -> void:
	var target_x = player.position.x + 16
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:x", target_x, 0.3)
	tween.tween_callback(func(): _attack())

func _attack() -> void:
	current_state = State.ATTACK
	anim_sprite.play("attack")
	await anim_sprite.animation_finished
	_dash_back()

func _dash_back() -> void:
	current_state = State.DASH_BACK
	anim_sprite.flip_h = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:x", stop_position, 0.3)
	tween.tween_callback(func(): _reset_to_idle())

func _reset_to_idle() -> void:
	anim_sprite.flip_h = false
	current_state = State.IDLE
	charge_time = 0.0
	anim_sprite.play("idle")
