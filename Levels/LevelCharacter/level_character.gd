extends Node2D
@onready var shared_anims = $SharedCharacterAnimations
@onready var anim_player: AnimationPlayer = $SharedCharacterAnimations.get_child(1)
@onready var character_texture = $SharedCharacterAnimations.get_child(0)

var current_spell: SpellData = null
enum State { WALKING, IDLE, CASTING, HIT }
var current_state: State = State.WALKING
var anim_queue: Array = []
var is_playing_anim: bool = false

func _ready() -> void:
	print("LevelCharacter _ready")
	SpellManager.spell_cast_requested.connect(_on_spell_cast)
	
	var char_id = int(SaveManager.save_data.get("character", -1))
	if char_id >= 0:
		var char_data = CharacterManager.lookup.get(char_id)
		if char_data != null:
			character_texture.texture = char_data.sprite_sheet
	
	anim_player.animation_finished.connect(_on_animation_finished)
	shared_anims.projectile_ready.connect(_on_projectile_frame) 
	queue_animation("WalkRight")

func _on_projectile_frame() -> void:
	if current_spell == null or current_spell.projectile_scene == null:
		print("No projectile scene on spell: ", current_spell.display_name if current_spell else "null")
		return
	
	var projectile = current_spell.projectile_scene.instantiate()
	projectile.damage = current_spell.damage
	projectile.position = global_position + Vector2(8, -8)
	get_parent().add_child(projectile)

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

func _on_animation_finished(_anim_name: String) -> void:
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
