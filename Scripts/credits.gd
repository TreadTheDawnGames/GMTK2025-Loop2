extends Control
# Called when Back button is pressed
func _on_back_button_pressed() -> void:
	# Return to main menu
	queue_free()
