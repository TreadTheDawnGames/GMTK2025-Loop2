extends Node

func display_number(value: int, position: Vector2, is_critical: int = 0, display_time: float = 0.20):
	var number = Label.new()
	number.global_position = position
	number.text = str(value)
	number.z_index = 5
	number.label_settings = LabelSettings.new()
	
	var color = "#FFF"
	if is_critical == 1:
		color = "#B22"
	elif is_critical == 2:
		color = Color.GREEN
	if value == 0:
		color = "FFF8"
	
	number.label_settings.font_color = color
	number.label_settings.font_size = 500
	number.label_settings.outline_color = "#000"
	number.label_settings.outline_size = 1
	
	call_deferred("add_child", number)
	
	await number.resized
	number.pivot_offset = Vector2(number.size / 2)
	
	var display_duration = 1 # Change this value to control how long it stays
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		number, "position:y", number.position.y - 200, display_duration
	)
	tween.tween_property(
		number, "position.y", number.position.y, display_duration
	)
	tween.tween_property(
			number, "scale", Vector2.ZERO, 0.25
	).set_delay(display_duration - display_time) # Delay the scaling down effect
	
	await tween.finished
	number.queue_free()
