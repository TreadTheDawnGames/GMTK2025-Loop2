extends Control

const SETTINGS = preload("res://Scenes/UI/Settings.tscn")


# Called when Start Game button is pressed
func _on_start_button_pressed() -> void:
	SlideTransition.EmitOnHalfway()
	# Load the Settings scene
	SlideTransition.Halfway.connect(func(): 
		GameManager.restart_game()
		)
	# Start the game through GameManager

# Called when Settings button is pressed
func _on_settings_button_pressed() -> void:
	#SlideTransition.EmitOnHalfway()
	## Load the Settings scene
	#SlideTransition.Halfway.connect(func(): 
		#get_tree().change_scene_to_file("res://Scenes/UI/Settings.tscn")
		#)
	var settingsScene = SETTINGS.instantiate()
	add_child(settingsScene)

# Called when Exit button is pressed
func _on_exit_button_pressed() -> void:
	# Quit the game
	get_tree().quit()
