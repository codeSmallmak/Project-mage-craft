extends BaseEnemy

enum State { WALK, IDLE, DASH_FORWARD, ATTACK, DASH_BACK, MOVING, HIT }
var current_state: State = State.WALK
var _attack_hit_landed: bool = false


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
				current_attack = enemy_data.roll_attack()
				if current_attack == null:
					_reset_to_idle()
					return
				if enemy_data.can_shuffle and _has_unclaimed_markers() and randi() % 2 == 0:
					_try_move()
				else:
					_dash_forward()

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
	if current_state == State.ATTACK:
		if anim_sprite.frame_changed.is_connected(_on_attack_frame_changed):
			anim_sprite.frame_changed.disconnect(_on_attack_frame_changed)
	_transition_to(State.HIT)

func _build_snapshot() -> Dictionary:
	var snap = super._build_snapshot()
	snap["state"] = current_state
	return snap

func _on_restore_snapshot(snap: Dictionary) -> void:
	var prev_state: State = snap.get("state", State.IDLE)
	var prev_tween: Tween = snap.get("tween")
	current_attack = snap.get("current_attack", null)

	match prev_state:
		State.WALK:
			_transition_to(State.WALK)
			anim_sprite.play("walk")

		State.IDLE:
			_reset_to_idle()
			charge_time = snap.get("charge", 0.0)

		State.DASH_FORWARD, State.DASH_BACK:
			_transition_to(prev_state)
			anim_sprite.flip_h = prev_state == State.DASH_BACK
			if prev_tween and prev_tween.is_valid():
				prev_tween.play()
			else:
				_finish_dash(prev_state)

		State.ATTACK:
			_dash_back()

		State.MOVING:
			_transition_to(State.MOVING)
			_restore_moving(prev_tween)

		_:
			_reset_to_idle()

func _finish_dash(from_state: State) -> void:
	if from_state == State.DASH_FORWARD:
		_attack()
	else:
		position.x = stop_position
		_reset_to_idle()


# ═══════════════════════════════════════════════════════════════════════════════
#  SHUFFLE OVERRIDES
# ═══════════════════════════════════════════════════════════════════════════════

func _on_move_started() -> void:
	_transition_to(State.MOVING)
	anim_sprite.play("walk")

func _on_move_failed() -> void:
	_dash_forward()


# ═══════════════════════════════════════════════════════════════════════════════
#  ATTACK CYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _dash_forward() -> void:
	if current_attack == null:
		_reset_to_idle()
		return
	_transition_to(State.DASH_FORWARD)
	var target_x = player.position.x + current_attack.attack_x_offset
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	active_tween = create_tween()
	active_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_property(self, "position:x", target_x, 0.3)
	active_tween.tween_callback(func(): _attack())

func _attack() -> void:
	if current_attack == null:
		_reset_to_idle()
		return
	_transition_to(State.ATTACK)
	_attack_hit_landed = false
	anim_sprite.play(current_attack.animation)

	if anim_sprite.frame_changed.is_connected(_on_attack_frame_changed):
		anim_sprite.frame_changed.disconnect(_on_attack_frame_changed)
	anim_sprite.frame_changed.connect(_on_attack_frame_changed)

	await anim_sprite.animation_finished

	if anim_sprite.frame_changed.is_connected(_on_attack_frame_changed):
		anim_sprite.frame_changed.disconnect(_on_attack_frame_changed)

	if current_state == State.ATTACK:
		_dash_back()

func _on_attack_frame_changed() -> void:
	if _attack_hit_landed or current_attack == null:
		return
	if anim_sprite.frame != current_attack.impact_frame:
		return

	_attack_hit_landed = true
	var hit_lanes: Array = current_attack.get_attack_lanes(lane)

	var player_in_hit_lane: bool = player.current_lane in hit_lanes
	var player_mid_change: bool = (player.current_state == player.State.LANE_CHANGE) \
		and (player.current_lane in hit_lanes or player.previous_lane in hit_lanes)

	if player_in_hit_lane or player_mid_change:
		player.take_damage(current_attack.roll_damage())
		var fx = Globals.spawn_fx(
			get_parent(),
			player.global_position + Vector2(4, -8),
			current_attack.impact_fx
		)
		if fx:
			fx.scale.x = -1

func _dash_back() -> void:
	_transition_to(State.DASH_BACK)
	anim_sprite.flip_h = true
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	active_tween = create_tween()
	active_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_property(self, "position:x", stop_position, 0.3)
	active_tween.tween_callback(func(): _reset_to_idle())

func _reset_to_idle() -> void:
	super._reset_to_idle()
	_transition_to(State.IDLE)

func _die() -> void:
	if anim_sprite.frame_changed.is_connected(_on_attack_frame_changed):
		anim_sprite.frame_changed.disconnect(_on_attack_frame_changed)
	super._die()
