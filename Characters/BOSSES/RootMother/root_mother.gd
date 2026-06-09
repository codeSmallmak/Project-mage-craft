extends BaseEnemy

enum State {
	WALK, GROW, IDLE,
	SHRINK_MOVE,
	VINE_LASH_MOVE, VINE_LASH_ATTACK,
	LASER_MOVE, LASER_ATTACK,
	PROJECTILE_ATTACK,
	HEAL,
	SUMMON,
	SHRINK_RETURN,
	HIT
}
var current_state: State = State.WALK

var _attack_hit_landed: bool = false
var _attack_lane: int = 0
var _is_shrunk: bool = false
var _vine_lash_gap: int = 0  # 0 = between lanes 0-1, 1 = between lanes 1-2


# ═══════════════════════════════════════════════════════════════════════════════
#  STATE MACHINE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	super._ready()
	scale = Vector2.ZERO

func _transition_to(new_state: State) -> void:
	current_state = new_state

func _is_hit_state() -> bool:
	return current_state == State.HIT

func _is_invincible() -> bool:
	return _is_shrunk

func _process(delta: float) -> void:
	charge_bar.visible = current_state == State.IDLE or current_state == State.HIT
	health_bar.visible = current_state == State.HIT

	match current_state:
		State.WALK:
			position.x -= 50 * delta
			if position.x <= stop_position:
				position.x = stop_position
				_grow_in()

		State.IDLE:
			charge_time += delta
			charge_bar.value = (charge_time / enemy_data.attack_interval) * 100.0
			if charge_time >= enemy_data.attack_interval:
				_choose_action()

		State.HIT:
			hit_timer -= delta
			anim_sprite.visible = int(hit_timer * 10) % 2 == 0
			if hit_timer <= 0.0:
				anim_sprite.visible = true
				_restore_snapshot()


# ═══════════════════════════════════════════════════════════════════════════════
#  ACTION SELECTION
# ═══════════════════════════════════════════════════════════════════════════════

func _choose_action() -> void:
	current_attack = enemy_data.roll_attack()
	if current_attack == null:
		_reset_to_idle()
		return
	# TODO: branch on attack id to determine which cycle to run


# ═══════════════════════════════════════════════════════════════════════════════
#  HIT INTERRUPT OVERRIDES
# ═══════════════════════════════════════════════════════════════════════════════

func take_damage(damage: int, is_crit: bool = false) -> void:
	if _is_invincible():
		return
	super.take_damage(damage, is_crit)

func _on_enter_hit() -> void:
	match current_state:
		State.VINE_LASH_ATTACK, State.LASER_ATTACK, State.PROJECTILE_ATTACK:
			if anim_sprite.frame_changed.is_connected(_on_attack_frame_changed):
				anim_sprite.frame_changed.disconnect(_on_attack_frame_changed)
	_transition_to(State.HIT)

func _build_snapshot() -> Dictionary:
	var snap = super._build_snapshot()
	snap["state"] = current_state
	snap["attack_lane"] = _attack_lane
	snap["is_shrunk"] = _is_shrunk
	snap["vine_lash_gap"] = _vine_lash_gap
	return snap

func _on_restore_snapshot(snap: Dictionary) -> void:
	var prev_state: State = snap.get("state", State.IDLE)
	var prev_tween: Tween = snap.get("tween")
	_attack_lane = snap.get("attack_lane", 0)
	_is_shrunk = snap.get("is_shrunk", false)
	_vine_lash_gap = snap.get("vine_lash_gap", 0)
	current_attack = snap.get("current_attack", null)

	match prev_state:
		State.WALK:
			_transition_to(State.WALK)
			anim_sprite.play("idle")
		State.GROW:
			_transition_to(State.GROW)
			if prev_tween and prev_tween.is_valid():
				prev_tween.play()
			else:
				scale = Vector2.ONE
				_is_shrunk = false
				_reset_to_idle()
		State.IDLE:
			scale = Vector2.ONE
			_is_shrunk = false
			_reset_to_idle()
		State.SHRINK_MOVE, State.SHRINK_RETURN, \
		State.VINE_LASH_MOVE, State.LASER_MOVE:
			_transition_to(prev_state)
			if prev_tween and prev_tween.is_valid():
				prev_tween.play()
			else:
				scale = Vector2.ZERO
				_is_shrunk = true
				_do_return()
		State.VINE_LASH_ATTACK, State.LASER_ATTACK:
			_transition_to(prev_state)
			if prev_tween and prev_tween.is_valid():
				prev_tween.play()
			else:
				scale = Vector2.ONE
				_is_shrunk = false
				_on_attack_frame_changed()
		State.PROJECTILE_ATTACK, State.HEAL, State.SUMMON:
			_shrink_return()
		_:
			scale = Vector2.ONE
			_is_shrunk = false
			_reset_to_idle()


# ═══════════════════════════════════════════════════════════════════════════════
#  SHARED BURROW HELPERS (placeholders — cycles built next)
# ═══════════════════════════════════════════════════════════════════════════════

func _grow_in() -> void:
	_transition_to(State.GROW)
	scale = Vector2.ZERO
	_is_shrunk = false
	reached_position.emit()
	anim_sprite.play("idle")
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	active_tween = create_tween()
	active_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	active_tween.tween_callback(_reset_to_idle)

func _shrink_return() -> void:
	_transition_to(State.SHRINK_RETURN)
	_is_shrunk = false
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	active_tween = create_tween()
	active_tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.12)
	active_tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	active_tween.tween_callback(_do_return)

func _do_return() -> void:
	_is_shrunk = true
	if level == null:
		_grow_in()
		return

	var unclaimed = level.get_unclaimed_markers()
	if unclaimed.is_empty():
		if current_marker_name == "" or not level.claimed_positions.has(current_marker_name):
			var any = level.stop_positions.get_children().pick_random()
			level.claim_position(any.name, self)
			current_marker_name = any.name
			stop_position = any.position.x
			move_target = any.position
		position = move_target
		_grow_in()
		return

	var target_marker: Node2D = unclaimed.pick_random()

	if not level.claim_position(target_marker.name, self):
		position = move_target
		_grow_in()
		return

	if current_marker_name != "":
		level.release_position(current_marker_name)

	current_marker_name = target_marker.name
	lane = int(target_marker.name.substr(3, 1))
	stop_position = target_marker.position.x
	move_target = target_marker.position

	if active_tween and active_tween.is_valid():
		active_tween.kill()
	active_tween = create_tween()
	active_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_property(self, "position", target_marker.position, 0.4)
	active_tween.tween_callback(_grow_in)

func _on_attack_frame_changed() -> void:
	pass


# ═══════════════════════════════════════════════════════════════════════════════
#  UTIL
# ═══════════════════════════════════════════════════════════════════════════════

func _reset_to_idle() -> void:
	_is_shrunk = false
	scale = Vector2.ONE
	super._reset_to_idle()
	_transition_to(State.IDLE)

func _die() -> void:
	scale = Vector2.ONE
	if anim_sprite.frame_changed.is_connected(_on_attack_frame_changed):
		anim_sprite.frame_changed.disconnect(_on_attack_frame_changed)
	super._die()
