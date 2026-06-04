# fx.gd
extends Node2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func setup(sprite_frames: SpriteFrames) -> void:
	anim_sprite.sprite_frames = sprite_frames
	anim_sprite.play("default")
	anim_sprite.animation_finished.connect(queue_free)
