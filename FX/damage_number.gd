extends Node2D

# Arc settings
const ARC_HEIGHT: float = 10.0      # How high the number goes
const ARC_LAND: float = 4.0         # How far below start it lands
const ARC_X_DRIFT: float = 16.0     # How far right it drifts
const ARC_UP_TIME: float = 0.4      # Time to reach peak
const ARC_DOWN_TIME: float = 0.4    # Time to land
const ARC_X_EASE_OUT: bool = true   # If true, x slows at end. If false, linear.

# Fade settings
const FADE_DELAY: float = 0.5       # When fade starts
const FADE_DURATION: float = 0.3    # How long fade takes

# Crit settings
const CRIT_FONT_SIZE: int = 14      # Crit number size

@onready var label: Label = $Label
func setup(amount: int, is_crit: bool) -> void:
	if is_crit:
		label.text = str(amount) + "!"
		label.modulate = Color.YELLOW
		label.add_theme_font_size_override("font_size", CRIT_FONT_SIZE)
	else:
		label.text = str(amount)
	
	var start_y = position.y
	var peak_y = start_y - ARC_HEIGHT
	var land_y = start_y + ARC_LAND
	
	# X tween — runs independently
	var tween_x = create_tween()
	tween_x.tween_property(self, "position:x", position.x + ARC_X_DRIFT, ARC_UP_TIME + ARC_DOWN_TIME)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Y tween — arc up then down
	var tween_y = create_tween()
	tween_y.tween_property(self, "position:y", peak_y, ARC_UP_TIME)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_y.tween_property(self, "position:y", land_y, ARC_DOWN_TIME)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Fade tween
	var tween_fade = create_tween()
	tween_fade.tween_interval(FADE_DELAY)
	tween_fade.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	
	await tween_y.finished
	queue_free()
