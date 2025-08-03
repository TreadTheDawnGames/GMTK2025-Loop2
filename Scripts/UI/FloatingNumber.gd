extends Label

func start(score_value, start_position):
	text = "+" + str(score_value)
	global_position = start_position
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Move up
	tween.tween_property(self, "global_position", global_position + Vector2(0, -50), 1.5)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 1.5).from(1.0)
	
	tween.tween_callback(queue_free)
