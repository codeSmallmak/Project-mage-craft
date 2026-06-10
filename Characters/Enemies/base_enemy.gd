class_name BaseEnemy
extends Node2D

@export var enemy_data: EnemyData
@export var stop_position: float = 200.0
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var charge_bar: ProgressBar = $ProgressBar
@onready var health_bar: ProgressBar = $HealthBar
@export var death_poof: PackedScene
@export var damage_number_scene: PackedScene

@warning_ignore("unused_signal")
signal reached_position
signal died

var charge_time: float = 0.0
var hit_timer: float = 0.0
const HIT_DURATION: float = 0.5

var player: Node2D
var level: Node2D = null
var hp: int = 0
var lane: int = 1
var current_marker_name: String = ""
var move_target: Vector2 = Vector2.ZERO
var debug_id: String = ""
var _pending_death: bool = false
var current_attack: AttackData = null

var snapshot: Dictionary = {}
var active_tween: Tween = null


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

func _process(_delta: float) -> void:
	pass
# ═══════════════════════════════════════════════════════════════════════════════
#  HIT INTERRUPT
# ═══════════════════════════════════════════════════════════════════════════════

func take_damage(damage: int, is_crit: bool = false) -> void:
	hp -= damage
	health_bar.value = hp
	_spawn_damage_number(damage, is_crit)

	if hp <= 0:
		if _is_hit_state():
			_pending_death = true
			return
		_enter_hit()
		_pending_death = true
		return

	if _is_hit_state():
		hit_timer = HIT_DURATION
		return

	_enter_hit()

func _enter_hit() -> void:
	snapshot = _build_snapshot()

	if active_tween and active_tween.is_valid():
		active_tween.pause()

	hit_timer = HIT_DURATION
	_on_enter_hit()
	anim_sprite.play("hit")

func _on_enter_hit() -> void:
	pass

func _is_hit_state() -> bool:
	return false

func _build_snapshot() -> Dictionary:
	return {
		"charge":         charge_time,
		"tween":          active_tween,
		"marker_name":    current_marker_name,
		"stop_x":         stop_position,
		"move_target":    move_target,
		"current_attack": current_attack,
	}

func _restore_snapshot() -> void:
	if _pending_death:
		_die()
		return
	if snapshot.is_empty():
		_reset_to_idle()
		return
	var snap = snapshot
	snapshot = {}
	_on_restore_snapshot(snap)

func _on_restore_snapshot(_snap: Dictionary) -> void:
	_reset_to_idle()

func _reset_to_idle() -> void:
	active_tween = null
	anim_sprite.flip_h = false
	charge_time = 0.0
	anim_sprite.play("idle")


# ═══════════════════════════════════════════════════════════════════════════════
#  SHUFFLE
# ═══════════════════════════════════════════════════════════════════════════════

func _has_unclaimed_markers() -> bool:
	return level != null and not level.get_unclaimed_markers().is_empty()

func _try_move() -> void:
	if level == null:
		_on_move_failed()
		return

	var unclaimed = level.get_unclaimed_markers()
	if unclaimed.is_empty():
		_on_move_failed()
		return

	var target_marker: Node2D = unclaimed.pick_random()

	if not level.claim_position(target_marker.name, self):
		_on_move_failed()
		return

	if current_marker_name != "":
		level.release_position(current_marker_name)

	current_marker_name = target_marker.name
	lane = int(target_marker.name.substr(3, 1))
	stop_position = target_marker.position.x
	move_target = target_marker.position

	if target_marker.position.x > position.x:
		anim_sprite.flip_h = true

	if active_tween and active_tween.is_valid():
		active_tween.kill()
	active_tween = create_tween()
	active_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_property(self, "position", target_marker.position, 0.8)
	active_tween.tween_callback(_reset_to_idle)
	_on_move_started()

func _on_move_started() -> void:
	anim_sprite.play("walk")

func _on_move_failed() -> void:
	_reset_to_idle()

func _restore_moving(prev_tween: Tween) -> void:
	if prev_tween and prev_tween.is_valid():
		anim_sprite.play("walk")
		prev_tween.play()
	else:
		position = move_target
		_reset_to_idle()


# ═══════════════════════════════════════════════════════════════════════════════
#  DEATH
# ═══════════════════════════════════════════════════════════════════════════════

func _die() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	if current_marker_name != "" and level != null:
		level.release_position(current_marker_name)
		current_marker_name = ""

	anim_sprite.visible = false
	charge_bar.visible = false
	health_bar.visible = false

	if death_poof != null:
		var poof = death_poof.instantiate()
		poof.position = global_position
		get_parent().add_child(poof)

	died.emit()
	queue_free()


# ═══════════════════════════════════════════════════════════════════════════════
#  UTIL
# ═══════════════════════════════════════════════════════════════════════════════

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

func _spawn_damage_number(damage: int, is_crit: bool) -> void:
	if damage_number_scene == null:
		return
	var num = damage_number_scene.instantiate()
	num.position = global_position + Vector2(0, -16)
	get_parent().add_child(num)
	num.setup(damage, is_crit)
