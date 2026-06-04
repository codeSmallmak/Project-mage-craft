extends Node2D
@onready var shared_anims = $SharedCharacterAnimations
@onready var anim_player: AnimationPlayer = $SharedCharacterAnimations.get_child(1)
@onready var character_texture = $SharedCharacterAnimations.get_child(0)

var current_spell: SpellData = null
enum State { WALKING, IDLE, CASTING, HIT, LANE_CHANGE }
var current_state: State = State.WALKING
var anim_queue: Array = []
var is_playing_anim: bool = false
var lanes = []
var current_lane: int = 1
var is_lane_changing: bool = false
var previous_lane: int = 1
var hp: int = 0
var max_hp: int = 0
var hp_bar: ProgressBar = null
var hit_timer: float = 0.0
const HIT_DURATION: float = 0.5
var pre_hit_state: State = State.IDLE
var pre_hit_anim: String = "IdleRight"
var lane_tween: Tween = null
var lane_tween_paused: bool = false

func _ready() -> void:
	SpellManager.spell_cast_requested.connect(_on_spell_cast)
	
	var char_id = int(SaveManager.save_data.get("character", -1))
	if char_id >= 0:
		var char_data = CharacterManager.lookup.get(char_id)
		if char_data != null:
			character_texture.texture = char_data.sprite_sheet
	
	anim_player.animation_finished.connect(_on_animation_finished)
	shared_anims.projectile_ready.connect(_on_spell_frame)
	queue_animation("WalkRight", State.WALKING)

func _process(delta: float) -> void:
	if current_state == State.HIT:
		hit_timer -= delta
		character_texture.visible = int(hit_timer * 10) % 2 == 0
		if hit_timer <= 0.0:
			character_texture.visible = true
			is_playing_anim = false
			current_state = pre_hit_state
			anim_queue.clear()
			if lane_tween and lane_tween_paused:
				lane_tween_paused = false
				is_lane_changing = true
				current_state = State.LANE_CHANGE
				anim_player.play("WalkUp" if current_lane < previous_lane else "WalkDown")
				lane_tween.play()
			else:
				queue_animation(pre_hit_anim, pre_hit_state)

func _on_spell_frame() -> void:
	if current_spell == null or current_spell.projectile_scene == null:
		return
	
	match current_spell.spell_type:
		SpellData.SpellType.PROJECTILE:
			_spawn_projectile()
		SpellData.SpellType.SEEKING_ORB:
			_spawn_seeking_orb()

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
		# Spawn anywhere on left half, off screen to the left
		orb.position = Vector2(randf_range(-40, -8), randf_range(-50, 230))
		var enemies = get_tree().get_nodes_in_group("enemies")
		if not enemies.is_empty():
			orb.target = enemies.pick_random()
		get_parent().add_child(orb)


func queue_animation(anim_name: String, new_state: State = State.IDLE) -> void:
	anim_queue.append({"anim": anim_name, "state": new_state})
	if not is_playing_anim:
		_process_queue()

func _process_queue() -> void:
	if anim_queue.is_empty():
		return
	var next = anim_queue.pop_front()
	current_state = next.state
	is_playing_anim = true
	anim_player.play(next.anim)

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "hit":
		if current_state == State.HIT:
			anim_player.play("hit")
		return
	
	is_playing_anim = false
	if anim_queue.is_empty():
		queue_animation("IdleRight", State.IDLE)
	else:
		_process_queue()

func stop_walking() -> void:
	anim_player.stop()
	anim_queue.clear()
	is_playing_anim = false
	queue_animation("IdleRight", State.IDLE)

func _on_spell_cast(spell: SpellData) -> void:
	current_spell = spell
	queue_animation(spell.cast_animation, State.CASTING)

func setup_lanes(lane_markers: Array) -> void:
	lanes = lane_markers
	position.y = lanes[current_lane].position.y

func _input(event: InputEvent) -> void:
	if current_state == State.CASTING or current_state == State.HIT:
		return
	if is_lane_changing:
		return
	if lanes.is_empty():
		return
	
	if event.is_action_pressed("up") and current_lane > 0:
		_change_lane(current_lane - 1)
	elif event.is_action_pressed("down") and current_lane < lanes.size() - 1:
		_change_lane(current_lane + 1)

func _change_lane(new_lane: int) -> void:
	previous_lane = current_lane
	is_lane_changing = true
	var target_y = lanes[new_lane].position.y
	var dir_anim = "WalkUp" if new_lane < current_lane else "WalkDown"
	current_lane = new_lane
	
	anim_player.stop()
	anim_queue.clear()
	is_playing_anim = true
	current_state = State.LANE_CHANGE
	anim_player.play(dir_anim)
	
	lane_tween = create_tween()
	lane_tween.tween_property(self, "position:y", target_y, 0.5)
	lane_tween.tween_callback(_on_lane_change_complete)

func _on_lane_change_complete() -> void:
	is_lane_changing = false
	is_playing_anim = false
	lane_tween = null
	lane_tween_paused = false
	if current_state == State.LANE_CHANGE:
		if anim_queue.is_empty():
			var next_anim = "WalkRight" if get_parent().scrolling else "IdleRight"
			var next_state = State.WALKING if get_parent().scrolling else State.IDLE
			queue_animation(next_anim, next_state)
		else:
			_process_queue()

func take_damage(damage: int) -> void:
	if current_state == State.HIT:
		hit_timer = HIT_DURATION
		hp -= damage
		hp = max(hp, 0)
		if hp_bar:
			hp_bar.value = hp
		if hp <= 0:
			_die()
		return
	
	hp -= damage
	hp = max(hp, 0)
	if hp_bar:
		hp_bar.value = hp
	
	if hp <= 0:
		_die()
		return
	
	_enter_hit()

func _enter_hit() -> void:
	if current_state == State.LANE_CHANGE:
		if lane_tween:
			lane_tween.pause()
			lane_tween_paused = true
		is_lane_changing = false
		pre_hit_state = State.LANE_CHANGE
		pre_hit_anim = "WalkRight" if get_parent().scrolling else "IdleRight"
	else:
		pre_hit_state = current_state
		pre_hit_anim = anim_player.current_animation
	
	current_state = State.HIT
	hit_timer = HIT_DURATION
	anim_player.stop()
	anim_queue.clear()
	is_playing_anim = true
	anim_player.play("hit")

func _die() -> void:
	current_state = State.HIT
	character_texture.visible = true
	print("Player died — game over")
	# TODO: game over screen
