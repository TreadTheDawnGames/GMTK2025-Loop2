extends Control

const SETTINGS = preload("res://Scenes/UI/Settings.tscn")

# Animation references
@onready var orbit_path: Path2D = $AnimatedBackground/OrbitPath
@onready var path_follow: PathFollow2D = $AnimatedBackground/OrbitPath/PathFollow2D
var orbit_tween: Tween


# This creates a default path if one is not defined in the editor.
func create_default_orbit_path():
	var radius = 80.0
	var points_count = 32 # More points for a smoother circle
	
	for i in range(points_count + 1):
		var angle = (float(i) / points_count) * TAU
		var point_position = Vector2(cos(angle), sin(angle)) * radius
		orbit_path.curve.add_point(point_position)

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

func start_ship_orbit_animation():
	# This creates endless orbiting animation for the demo ship
	if not path_follow:
		return

	# This check is an extra safeguard in case something unexpected happens.
	if not is_instance_valid(orbit_path.curve) or orbit_path.curve.get_baked_length() == 0:
		printerr("Cannot start orbit animation, path is still invalid.")
		return
		
	orbit_tween = create_tween()
	orbit_tween.set_loops() # This makes it loop infinitely
	orbit_tween.tween_property(path_follow, "progress_ratio", 1.0, 8.0) # 8 seconds per orbit
	orbit_tween.tween_property(path_follow, "progress_ratio", 0.0, 0.0) # Reset instantly
