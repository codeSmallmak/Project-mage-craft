# poof.gd
extends Node2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	anim_sprite.play("poof")
	anim_sprite.animation_finished.connect(_on_finished)
	anim_sprite.frame_changed.connect(_on_frame_changed)

func _on_frame_changed() -> void:
	# On last frame, start rapid fade
	if anim_sprite.frame == anim_sprite.sprite_frames.get_frame_count("poof") - 1:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.05)

func _on_finished() -> void:
	queue_free()
