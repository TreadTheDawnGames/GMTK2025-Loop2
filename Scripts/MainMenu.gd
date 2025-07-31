extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called when Start Game button is pressed
func _on_start_button_pressed() -> void:
	# Load the Game scene
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")

# Called when Settings button is pressed
func _on_settings_button_pressed() -> void:
	# Load the Settings scene
	get_tree().change_scene_to_file("res://Scenes/UI/Settings.tscn")

# Called when Exit button is pressed
func _on_exit_button_pressed() -> void:
	# Quit the game
	get_tree().quit()
