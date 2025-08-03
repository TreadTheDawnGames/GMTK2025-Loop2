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

@onready var tutorial_toggle: SoundButton = $PanelContainer/VBoxContainer/TutorialToggleContainer/TutorialToggle
func _ready():
	# Set initial tutorial toggle state
	if tutorial_toggle:
		tutorial_toggle.button_pressed = GameManager.get_tutorials_enabled()
	TutorialManager.tutorials_shown.clear()



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

func _on_tutorial_toggle_toggled(button_pressed: bool) -> void:
	# Update GameManager with new tutorial setting
	GameManager.set_tutorials_enabled(button_pressed)


func _on_touch_screen_tutorial_button_pressed() -> void:
	if tutorial_toggle:
		tutorial_toggle.button_pressed = tutorial_toggle.button_pressed
		GameManager.set_tutorials_enabled(tutorial_toggle.button_pressed)
	pass # Replace with function body.
