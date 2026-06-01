extends Node2D

@export var enemy_data: EnemyData
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if enemy_data != null:
		anim_sprite.sprite_frames = enemy_data.sprite_frames
		anim_sprite.play("walk")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	position.x -= 50* _delta
	pass


func flash_damage() -> void:
	modulate = Color(1, 1, 1, 0.4)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
