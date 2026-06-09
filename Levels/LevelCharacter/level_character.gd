extends Node2D

#region New Code Region
@onready var shared_anims = $SharedCharacterAnimations
@onready var anim_player: AnimationPlayer = $SharedCharacterAnimations.get_child(1)
@onready var character_texture = $SharedCharacterAnimations.get_child(0)

var current_spell: SpellData = null

enum State { IDLE, WALKING, CASTING, LANE_CHANGE, HIT }
var current_state: State = State.IDLE

# ── Animation queue ─────────────────────────────────────────────────────────
var anim_queue: Array[Dictionary] = []   # [{anim:String, state:State}]
var anim_playing: bool = false

# ── Hit interrupt ────────────────────────────────────────────────────────────
var hit_timer: float = 0.0
const HIT_DURATION: float = 0.5
var snapshot: Dictionary = {}            # full state snapshot before hit

# ── Lane changing ─────────────────────────────────────────────────────────────
var lanes: Array = []
var current_lane: int = 1
var lane_tween: Tween = null
var previous_lane: int = 1

# ── Other ─────────────────────────────────────────────────────────────────────
var hp: int = 0
var max_hp: int = 0
var hp_bar: ProgressBar = null
#endregion


# ═══════════════════════════════════════════════════════════════════════════════
#  INIT
# ═══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	SpellManager.spell_cast_requested.connect(_on_spell_cast)
	anim_player.animation_finished.connect(_on_animation_finished)
	shared_anims.projectile_ready.connect(_on_spell_frame)

	var char_id = int(SaveManager.save_data.get("character", -1))
	if char_id >= 0:
		var char_data = CharacterManager.lookup.get(char_id)
		if char_data != null:
			character_texture.texture = char_data.sprite_sheet

	_play_anim("WalkRight", State.WALKING)


# ═══════════════════════════════════════════════════════════════════════════════
#  PROCESS
# ═══════════════════════════════════════════════════════════════════════════════
#region New Code Region
func _process(delta: float) -> void:
	if current_state != State.HIT:
		return

	hit_timer -= delta
	character_texture.visible = int(hit_timer * 10) % 2 == 0

	if hit_timer <= 0.0:
		character_texture.visible = true
		_restore_snapshot()
#endregion


# ═══════════════════════════════════════════════════════════════════════════════
#  CORE STATE MACHINE
# ═══════════════════════════════════════════════════════════════════════════════
#region New Code Region

# The single authoritative way to change state.
func _transition_to(new_state: State) -> void:
	current_state = new_state

# Start playing an animation immediately, clearing the queue.
# Use for interrupting/redirecting — not for chaining.
func _play_anim(anim_name: String, new_state: State) -> void:
	anim_queue.clear()
	_transition_to(new_state)
	anim_playing = true
	anim_player.play(anim_name)

# Enqueue an animation to play after the current one finishes.
func queue_anim(anim_name: String, new_state: State) -> void:
	anim_queue.append({"anim": anim_name, "state": new_state})
	if not anim_playing:
		_pop_queue()

func _pop_queue() -> void:
	if anim_queue.is_empty():
		return
	var next: Dictionary = anim_queue.pop_front()
	_transition_to(next.state)
	anim_playing = true
	anim_player.play(next.anim)

func _on_animation_finished(_anim_name: String) -> void:
	# HIT manages its own loop — ignore finish signals while in HIT.
	if current_state == State.HIT:
		return

	anim_playing = false

	if not anim_queue.is_empty():
		_pop_queue()
		return

	# Default idle behaviour when queue empties.
	match current_state:
		State.CASTING, State.LANE_CHANGE:
			_play_anim("IdleRight", State.IDLE)
		State.WALKING:
			_play_anim("WalkRight", State.WALKING)
		_:
			_play_anim("IdleRight", State.IDLE)

#endregion

# ═══════════════════════════════════════════════════════════════════════════════
#  HIT INTERRUPT
# ═══════════════════════════════════════════════════════════════════════════════

#region New Code Region
func take_damage(damage: int) -> void:
	hp = max(hp - damage, 0)
	if hp_bar:
		hp_bar.value = hp

	if hp <= 0:
		_die()
		return

	if current_state == State.HIT:
		# Already hit — just extend the timer, no new snapshot needed.
		hit_timer = HIT_DURATION
		return

	_enter_hit()

func _enter_hit() -> void:
	# Capture everything needed to resume cleanly.
	snapshot = {
		"state":        current_state,
		"anim":         anim_player.current_animation,
		"queue":        anim_queue.duplicate(true),
		"lane_tween":   lane_tween,
		"lane":         current_lane,
	}

	# Pause any active lane tween in-place.
	if lane_tween and lane_tween.is_valid():
		lane_tween.pause()

	_transition_to(State.HIT)
	hit_timer = HIT_DURATION
	anim_queue.clear()
	anim_playing = true
	anim_player.play("hit")

func _restore_snapshot() -> void:
	if snapshot.is_empty():
		_play_anim("IdleRight", State.IDLE)
		return

	var prev_state: State  = snapshot.get("state", State.IDLE)
	var prev_anim: String  = snapshot.get("anim", "IdleRight")
	var prev_queue: Array  = snapshot.get("queue", [])
	var prev_tween: Tween  = snapshot.get("lane_tween")
	var prev_lane: int     = snapshot.get("lane", current_lane)  # grab before clearing

	snapshot = {}  # now safe to clear

	if prev_state == State.LANE_CHANGE and prev_tween and prev_tween.is_valid():
		anim_queue = prev_queue
		_transition_to(State.LANE_CHANGE)
		anim_playing = true
		anim_player.play("WalkUp" if current_lane < prev_lane else "WalkDown")  # use prev_lane
		prev_tween.play()
		return

	_transition_to(prev_state)
	anim_queue = prev_queue
	anim_playing = true
	anim_player.play(prev_anim)
#endregion


# ═══════════════════════════════════════════════════════════════════════════════
#  LANE CHANGING
# ═══════════════════════════════════════════════════════════════════════════════
#region New Code Region

func setup_lanes(lane_markers: Array) -> void:
	lanes = lane_markers
	position.y = lanes[current_lane].position.y

func _input(event: InputEvent) -> void:
	if current_state in [State.CASTING, State.HIT, State.LANE_CHANGE]:
		return
	if lanes.is_empty():
		return

	if event.is_action_pressed("up") and current_lane > 0:
		_change_lane(current_lane - 1)
	elif event.is_action_pressed("down") and current_lane < lanes.size() - 1:
		_change_lane(current_lane + 1)

func _change_lane(new_lane: int) -> void:
	previous_lane = current_lane   # track before overwriting
	var dir_anim := "WalkUp" if new_lane < current_lane else "WalkDown"
	current_lane = new_lane

	_play_anim(dir_anim, State.LANE_CHANGE)

	lane_tween = create_tween()
	lane_tween.tween_property(self, "position:y", lanes[new_lane].position.y, 0.5)
	lane_tween.tween_callback(_on_lane_change_complete)

func _on_lane_change_complete() -> void:
	lane_tween = null
	if current_state == State.LANE_CHANGE:
		var next_anim := "WalkRight" if get_parent().scrolling else "IdleRight"
		var next_state := State.WALKING if get_parent().scrolling else State.IDLE
		_play_anim(next_anim, next_state)
#endregion


# ═══════════════════════════════════════════════════════════════════════════════
#  SPELLS
# ═══════════════════════════════════════════════════════════════════════════════

#region New Code Region
func _on_spell_cast(spell: SpellData) -> void:
	current_spell = spell
	_play_anim(spell.cast_animation, State.CASTING)

func _on_spell_frame() -> void:
	if current_spell == null or current_spell.projectile_scene == null:
		return
	match current_spell.spell_type:
		SpellData.SpellType.PROJECTILE:    _spawn_projectile()
		SpellData.SpellType.SEEKING_ORB:   _spawn_seeking_orb()

func _spawn_projectile() -> void:
	var projectile = current_spell.projectile_scene.instantiate()
	var rolled = current_spell.roll_damage()
	projectile.damage = rolled[0]
	projectile.is_crit = rolled[1]
	projectile.lane = current_lane
	projectile.position = global_position + Vector2(8, -8)
	projectile.impact_fx = current_spell.impact_fx
	projectile.spell_sprite_frames = current_spell.spell_sprite_frames
	get_parent().add_child(projectile)

func _spawn_seeking_orb() -> void:
	var count = randi_range(current_spell.orb_count_min, current_spell.orb_count_max)
	for i in range(count):
		var orb = current_spell.projectile_scene.instantiate()
		var rolled = current_spell.roll_damage()
		orb.damage = rolled[0]
		orb.is_crit = rolled[1]
		orb.impact_fx = current_spell.impact_fx
		orb.spell_sprite_frames = current_spell.spell_sprite_frames
		orb.position = Vector2(randf_range(-40, -8), randf_range(-50, 230))
		var enemies = get_tree().get_nodes_in_group("enemies")
		if not enemies.is_empty():
			orb.target = enemies.pick_random()
		get_parent().add_child(orb)
#endregion


# ═══════════════════════════════════════════════════════════════════════════════
#  MISC
# ═══════════════════════════════════════════════════════════════════════════════
#region New Code Region

func stop_walking() -> void:
	_play_anim("IdleRight", State.IDLE)

func _die() -> void:
	_transition_to(State.HIT)
	character_texture.visible = true
	anim_player.stop()
	print("Player died — game over")
	# TODO: game over screen
#endregion
