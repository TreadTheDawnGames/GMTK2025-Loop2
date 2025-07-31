extends RigidBody2D
class_name Player
# This defines a set of named states for the player's state machine.
enum State {
	READY_TO_AIM,
	AIMING,
	LAUNCHED
}

# This exports a variable for launch power, tunable in the Inspector.
@export var launch_power: float = 10.0
# This exports a variable for the maximum drag distance (100% power).
@export var max_pull_distance: float = 200.0
# This exports a variable for the boost impulse strength.
@export var boost_strength: float = 1000.0

# This variable will hold the player's current state from the enum above.
var current_state: State = State.READY_TO_AIM
# This boolean tracks if the one-time boost is still available.
var has_boost: bool = true

# This creates a reference to the Line2D node for drawing the power bar.
@onready var line_2d: Line2D = $Line2D
# This creates a reference to the Sprite2D node.
@onready var sprite: Sprite2D = $Sprite2D

# This function is called by Godot when an input event occurs on this object.
func _input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# This handles only the left mouse button events.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# This starts aiming only when pressed and only from READY_TO_AIM.
		if event.is_pressed() and current_state == State.READY_TO_AIM:
			current_state = State.AIMING
			# This updates the aim line immediately so it appears on click.
			update_aim_line()
		# This launches on release while AIMING.
		elif not event.is_pressed() and current_state == State.AIMING:
			launch()

# This function is called every frame.
func _process(delta: float) -> void:
	# This updates the aim line only while AIMING and the mouse button is held.
	if current_state == State.AIMING and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# This updates the aim line visuals.
		update_aim_line()
		
		# This makes the ship face the mouse cursor while aiming.
		var mouse_position = get_global_mouse_position()
		look_at(mouse_position)
	
	# This checks if the player is aiming and spacebar is pressed to launch.
	if current_state == State.AIMING and Input.is_action_just_pressed("ui_select"):
		# This calls the function to launch the player.
		launch()

# This function runs every physics frame, ideal for physics-related code.
func _physics_process(delta: float) -> void:
	
	global_position += Vector2(Input.get_axis("DEBUG-LEFT", "DEBUG-RIGHT"), Input.get_axis("DEBUG-UP", "DEBUG-DOWN")) * 50
	
	# This checks if the player is in the air.
	if current_state == State.LAUNCHED:
		# This makes the rocket point in the direction it's moving.
		if linear_velocity.length() > 0.01: # Avoid rotation issues if velocity is zero
			rotation = linear_velocity.angle()
		# This checks if the boost is available and the user pressed boost.
		if has_boost and Input.is_action_just_pressed("ui_select"):
			apply_boost()

# This function handles the logic for launching the player.
func launch() -> void:
	# This calculates the global vector from the ship's current position to the current mouse position.
	var pull_vector_global = get_global_mouse_position() - global_position
	# This clamps the vector's length to the max_pull_distance.
	pull_vector_global = pull_vector_global.limit_length(max_pull_distance)
	
	# This calculates the power percentage (0.0 to 1.0) based on distance.
	var power_percentage = pull_vector_global.length() / max_pull_distance
	
	# This sets the player's initial velocity based on the pull vector and launch power.
	# linear_velocity is a global property, so directly using the global pull_vector works.
	linear_velocity = pull_vector_global * launch_power
	
	# This changes the state to LAUNCHED.
	current_state = State.LAUNCHED
	# This makes the RigidBody no longer clickable after launch.
	set_pickable(false)
	# This clears the aiming line from the screen.
	line_2d.clear_points()

# This function applies the one-time boost.
func apply_boost() -> void:
	# This gets the forward direction of the rocket.
	var boost_direction = Vector2.RIGHT.rotated(rotation)
	# This applies an instant force (impulse) in the forward direction.
	apply_central_impulse(boost_direction * boost_strength)
	# This consumes the boost so it cannot be used again.
	has_boost = false
	# This provides visual feedback that the boost was used TODO CHANGE.
	sprite.modulate = Color.CYAN
	# TODO: Add a particle effect or sound for the boost here!

# This function draws and updates the aiming line.
func update_aim_line() -> void:
	# This calculates the global vector from the player's current position to the current mouse position.
	var pull_vector_global = get_global_mouse_position() - global_position
	# This clamps the vector's length to the max_pull_distance.
	pull_vector_global = pull_vector_global.limit_length(max_pull_distance)
	
	# This calculates the power percentage (0.0 to 1.0) based on distance.
	var power_percentage = pull_vector_global.length() / max_pull_distance
	
	# This clears any previous points from the line.
	line_2d.clear_points()
	# This adds a point at the player's center (0,0 in local coordinates for the Line2D).
	line_2d.add_point(Vector2.ZERO)
	
	# This adds the end point of the pull vector.
	line_2d.add_point(global_transform.basis_xform_inv(pull_vector_global))
	
	# This calculates the color interpolation from white to red based on power.
	var line_color = Color.WHITE.lerp(Color.RED, power_percentage)
	line_2d.default_color = line_color
	
	# This sets the line width based on power (thicker line = more power).
	line_2d.width = 3.0 + power_percentage * 7.0
