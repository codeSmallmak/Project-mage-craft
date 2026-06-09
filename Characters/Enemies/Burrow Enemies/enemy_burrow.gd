extends BaseEnemy

enum State { WALK, GROW, IDLE, SHRINK_MOVE, GROW_ATTACK, ATTACK, SHRINK_RETURN, HIT }
var current_state: State = State.WALK
var _attack_hit_landed: bool = false
var _attack_lane: int = 0
var _is_shrunk: bool = false


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
				current_attack = enemy_data.roll_attack()
				if current_attack == null:
					_reset_to_idle()
					return
				if enemy_data.can_shuffle and _has_unclaimed_markers() and randi() % 2 == 0:
					_shrink_move()
				else:
					_shrink_attack()

		State.HIT:
			hit_timer -= delta
			anim_sprite.visible = int(hit_timer * 10) % 2 == 0
			if hit_timer <= 0.0:
				anim_sprite.visible = true
				_restore_snapshot()


# ═══════════════════════════════════════════════════════════════════════════════
#  BURROW CYCLE
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

func _shrink_move() -> void:
	_transition_to(State.SHRINK_MOVE)
	anim_sprite.play("idle")
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	active_tween = create_tween()
	active_tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.12)
	active_tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	active_tween.tween_callback(_do_move)

func _do_move() -> void:
	_is_shrunk = true
	if level == null:
		_grow_in()
		return

	var unclaimed = level.get_unclaimed_markers()
	if unclaimed.is_empty():
		_grow_in()
		return

	var target_marker: Node2D = unclaimed.pick_random()

	if not level.claim_position(target_marker.name, self):
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

func _shrink_attack() -> void:
	if current_attack == null:
		_reset_to_idle()
		return
	_transition_to(State.SHRINK_MOVE)
	anim_sprite.play("idle")
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	active_tween = create_tween()
	active_tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.12)
	active_tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	active_tween.tween_callback(_do_attack_move)

func _do_attack_move() -> void:
	_is_shrunk = true
	if current_attack == null:
		_grow_in()
		return
	var lanes = level.player_lanes.get_children()
	_attack_lane = randi() % lanes.size()
	var target_pos = Vector2(
		lanes[_attack_lane].position.x + current_attack.attack_x_offset,
		lanes[_attack_lane].position.y
	)

	if active_tween and active_tween.is_valid():
		active_tween.kill()
	active_tween = create_tween()
	active_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_property(self, "position", target_pos, 0.3)
	active_tween.tween_callback(_grow_attack)

func _grow_attack() -> void:
	_is_shrunk = false
	_transition_to(State.GROW_ATTACK)
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	active_tween = create_tween()
	active_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	active_tween.tween_callback(_attack)

func _attack() -> void:
	if current_attack == null:
		_shrink_return()
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
		_shrink_return()

func _on_attack_frame_changed() -> void:
	if _attack_hit_landed or current_attack == null:
		return
	if anim_sprite.frame != current_attack.impact_frame:
		return

	_attack_hit_landed = true
	var hit_lanes: Array = current_attack.get_attack_lanes(_attack_lane)

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

func _shrink_return() -> void:
	_transition_to(State.SHRINK_RETURN)
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


# ═══════════════════════════════════════════════════════════════════════════════
#  HIT INTERRUPT OVERRIDES
# ═══════════════════════════════════════════════════════════════════════════════

func take_damage(damage: int, is_crit: bool = false) -> void:
	if _is_invincible():
		return
	super.take_damage(damage, is_crit)

func _on_enter_hit() -> void:
	if current_state == State.ATTACK:
		if anim_sprite.frame_changed.is_connected(_on_attack_frame_changed):
			anim_sprite.frame_changed.disconnect(_on_attack_frame_changed)
	_transition_to(State.HIT)

func _build_snapshot() -> Dictionary:
	var snap = super._build_snapshot()
	snap["state"] = current_state
	snap["attack_lane"] = _attack_lane
	snap["is_shrunk"] = _is_shrunk
	return snap

func _on_restore_snapshot(snap: Dictionary) -> void:
	var prev_state: State = snap.get("state", State.IDLE)
	var prev_tween: Tween = snap.get("tween")
	_attack_lane = snap.get("attack_lane", 0)
	_is_shrunk = snap.get("is_shrunk", false)
	current_attack = snap.get("current_attack", null)

	match prev_state:
		State.WALK:
			_transition_to(State.WALK)
			anim_sprite.play("idle")

		State.GROW, State.GROW_ATTACK:
			_transition_to(prev_state)
			if prev_tween and prev_tween.is_valid():
				prev_tween.play()
			else:
				scale = Vector2.ONE
				_is_shrunk = false
				if prev_state == State.GROW_ATTACK:
					_attack()
				else:
					_reset_to_idle()

		State.IDLE:
			scale = Vector2.ONE
			_is_shrunk = false
			_reset_to_idle()

		State.SHRINK_MOVE, State.SHRINK_RETURN:
			_transition_to(prev_state)
			if prev_tween and prev_tween.is_valid():
				prev_tween.play()
			else:
				scale = Vector2.ZERO
				_is_shrunk = true
				if prev_state == State.SHRINK_MOVE:
					_do_move()
				else:
					_do_return()

		State.ATTACK:
			_shrink_return()

		_:
			scale = Vector2.ONE
			_is_shrunk = false
			_reset_to_idle()


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
