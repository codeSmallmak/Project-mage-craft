extends BaseEnemy

enum State { WALK, IDLE, MOVING, HIT }
var current_state: State = State.WALK


# ═══════════════════════════════════════════════════════════════════════════════
#  STATE MACHINE
# ═══════════════════════════════════════════════════════════════════════════════

func _transition_to(new_state: State) -> void:
	current_state = new_state

func _is_hit_state() -> bool:
	return current_state == State.HIT

func _process(delta: float) -> void:
	super._process(delta)
	charge_bar.visible = current_state == State.IDLE or current_state == State.HIT
	health_bar.visible = current_state == State.HIT

	match current_state:
		State.WALK:
			position.x -= 50 * delta
			if position.x <= stop_position:
				position.x = stop_position
				_transition_to(State.IDLE)
				reached_position.emit()
				anim_sprite.play("idle")
				charge_time = 0.0

		State.IDLE:
			charge_time += delta
			charge_bar.value = (charge_time / enemy_data.attack_interval) * 100.0
			if charge_time >= enemy_data.attack_interval:
				_try_move()

		State.HIT:
			hit_timer -= delta
			anim_sprite.visible = int(hit_timer * 10) % 2 == 0
			if hit_timer <= 0.0:
				anim_sprite.visible = true
				_restore_snapshot()


# ═══════════════════════════════════════════════════════════════════════════════
#  HIT INTERRUPT OVERRIDES
# ═══════════════════════════════════════════════════════════════════════════════

func _on_enter_hit() -> void:
	_transition_to(State.HIT)

func _build_snapshot() -> Dictionary:
	var snap = super._build_snapshot()
	snap["state"] = current_state
	return snap

func _on_restore_snapshot(snap: Dictionary) -> void:
	var prev_state: State = snap.get("state", State.IDLE)
	var prev_tween: Tween = snap.get("tween")

	match prev_state:
		State.WALK:
			_transition_to(State.WALK)
			anim_sprite.play("walk")

		State.MOVING:
			_transition_to(State.MOVING)
			_restore_moving(prev_tween)

		_:
			_reset_to_idle()


# ═══════════════════════════════════════════════════════════════════════════════
#  SHUFFLE OVERRIDES
# ═══════════════════════════════════════════════════════════════════════════════

func _on_move_started() -> void:
	_transition_to(State.MOVING)
	anim_sprite.play("walk")

func _on_move_failed() -> void:
	_reset_to_idle()

func _reset_to_idle() -> void:
	super._reset_to_idle()
	_transition_to(State.IDLE)
