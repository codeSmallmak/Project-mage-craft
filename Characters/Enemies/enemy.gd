extends Node2D
@export var enemy_data: EnemyData
@export var stop_position: float = 200.0
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var charge_bar: ProgressBar = $ProgressBar
@onready var health_bar: ProgressBar = $HealthBar
@export var death_poof: PackedScene
@export var damage_number_scene: PackedScene

signal reached_position
signal died

enum State { WALK, IDLE, DASH_FORWARD, ATTACK, DASH_BACK, HIT }
var current_state: State = State.WALK
var charge_time: float = 0.0
var hit_timer: float = 0.0
const HIT_DURATION: float = 0.5
var player: Node2D
var hp: int = 0
var lane: int = 1
var _attack_hit_landed: bool = false

func _ready() -> void:
	add_to_group("enemies")
	if enemy_data != null:
		anim_sprite.sprite_frames = enemy_data.sprite_frames
		anim_sprite.play("walk")
		hp = enemy_data.hp
	
	_setup_bar(charge_bar, Color.YELLOW)
	_setup_bar(health_bar, Color.RED)
	health_bar.max_value = enemy_data.hp
	health_bar.value = enemy_data.hp

func _setup_bar(bar: ProgressBar, color: Color) -> void:
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(32, 4)
	bar.add_theme_stylebox_override("fill", _make_stylebox(color))

func _make_stylebox(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style

func _process(delta: float) -> void:
	charge_bar.visible = (current_state == State.IDLE or current_state == State.HIT)
	health_bar.visible = (current_state == State.HIT)
	
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
			anim_sprite.visible = int(hit_timer * 10) % 2 == 0
			if hit_timer <= 0.0:
				anim_sprite.visible = true
				current_state = State.IDLE
				anim_sprite.play("idle")

func take_damage(damage: int, is_crit: bool = false) -> void:
	if current_state == State.DASH_FORWARD or current_state == State.DASH_BACK:
		_immune_flash()
		if damage_number_scene != null:
			var num = damage_number_scene.instantiate()
			num.position = global_position + Vector2(0, -16)
			get_parent().add_child(num)
			num.setup(0, false)
		return
	
	hp -= damage
	health_bar.value = hp
	
	if damage_number_scene != null:
		var num = damage_number_scene.instantiate()
		num.position = global_position + Vector2(0, -16)
		get_parent().add_child(num)
		num.setup(damage, is_crit)
	
	if hp <= 0:
		_die()
		return
	
	_enter_hit()

func _immune_flash() -> void:
	var tween = create_tween()
	tween.tween_property(anim_sprite, "modulate", Color(1, 1, 1, 0.3), 0.05)
	tween.tween_property(anim_sprite, "modulate", Color.WHITE, 0.05)
	tween.tween_property(anim_sprite, "modulate", Color(1, 1, 1, 0.3), 0.05)
	tween.tween_property(anim_sprite, "modulate", Color.WHITE, 0.05)

func _enter_hit() -> void:
	current_state = State.HIT
	hit_timer = HIT_DURATION
	anim_sprite.play("hit")

func _die() -> void:
	current_state = State.HIT
	anim_sprite.visible = false
	charge_bar.visible = false
	health_bar.visible = false
	
	if death_poof != null:
		var poof = death_poof.instantiate()
		poof.position = global_position
		get_parent().add_child(poof)
	
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
	_attack_hit_landed = false
	anim_sprite.play("attack")
	
	# Ensure clean connection
	if anim_sprite.frame_changed.is_connected(_on_attack_frame_changed):
		anim_sprite.frame_changed.disconnect(_on_attack_frame_changed)
	anim_sprite.frame_changed.connect(_on_attack_frame_changed)
	
	await anim_sprite.animation_finished
	if anim_sprite.frame_changed.is_connected(_on_attack_frame_changed):
		anim_sprite.frame_changed.disconnect(_on_attack_frame_changed)
	_dash_back()
	
func _on_attack_frame_changed() -> void:
	if _attack_hit_landed:
		return
	if anim_sprite.frame == enemy_data.attack_impact_frame:
		_attack_hit_landed = true
		var hit_lanes = enemy_data.get_attack_lanes(lane)
		var player_hit = false
		
		if player.current_lane in hit_lanes:
			player_hit = true
		elif player.is_lane_changing:
			if player.previous_lane in hit_lanes or player.current_lane in hit_lanes:
				player_hit = true
		
		if player_hit:
			player.take_damage(enemy_data.roll_damage())
			var fx = Globals.spawn_fx(get_parent(), player.global_position + Vector2(4,-8), Globals.FXType.IMPACT3)
			if fx:
				fx.scale.x = -1


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
