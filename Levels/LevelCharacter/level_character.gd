extends Node2D

@onready var anim_player: AnimationPlayer = $SharedCharacterAnimations.get_child(1)
@onready var character_texture = $SharedCharacterAnimations.get_child(0)

func _ready() -> void:
	var char_id = int(SaveManager.save_data.get("character", -1))
	if char_id >= 0:
		var char_data = CharacterManager.lookup.get(char_id)
		if char_data != null:
			character_texture.texture = char_data.sprite_sheet
	anim_player.play("WalkRight")
