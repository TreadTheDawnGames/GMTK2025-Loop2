extends RigidBody2D

# This defines a set of named states for the player's state machine.
enum State {
	READY_TO_AIM, 
	AIMING,       
	LAUNCHED     
}

# This exports a variable for launch power, tunable in the Inspector.
@export var launch_power: float = 10.0
# This exports a variable for the maximum distance you can pull back, preventing insane speeds.
@export var max_pull_distance: float = 200.0
# This exports a variable for the boost impulse strength.
@export var boost_strength: float = 1000.0

# This variable will hold the player's current state from the enum above.
var current_state: State = State.READY_TO_AIM

# This variable will store the position where the player starts dragging the mouse.
var start_drag_position: Vector2

# This boolean tracks if the one-time boost is still available.
var has_boost: bool = true

# This creates a reference to the Line2D node for drawing the aim line.
@onready var line_2d: Line2D = $Line2D
# This creates a reference to the Sprite2D node.
@onready var sprite: Sprite2D = $Sprite2D


# This function is called by Godot when an input event occurs on this object.
func _input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# This checks if the current state is READY_TO_AIM and the event is a left mouse button press.
	if current_state == State.READY_TO_AIM and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# This sets the state to AIMING.
		current_state = State.AIMING
		# This records the starting position of the drag.
		start_drag_position = get_global_mouse_position()

# This function is called every frame.
func _process(delta: float) -> void:
	# This checks if currently in the AIMING state.
	if current_state == State.AIMING:
		# This updates the aiming line visuals every frame.
		update_aim_line()

		# This checks if the left mouse button has been released.
		if Input.is_action_just_released("ui_accept"): # "ui_accept" is usually Left Click or Space
			# This calls the function to launch the player.
			launch()

# This function runs every physics frame, ideal for physics-related code.
func _physics_process(delta: float) -> void:
	# This checks if the player is in the air.
	if current_state == State.LAUNCHED:
		# This makes the rocket point in the direction it's moving.
		rotation = linear_velocity.angle()

		# This checks if the boost is available and if the player presses the boost key ("ui_select" is usually Enter or Space).
		if has_boost and Input.is_action_just_pressed("ui_select"):
			# This calls the boost function.
			apply_boost()

# This function handles the logic for launching the player.
func launch() -> void:
	# This calculates the vector from the drag start to the current mouse position.
	var pull_vector = start_drag_position - get_global_mouse_position()
	# This clamps the vector's length to the max_pull_distance.
	pull_vector = pull_vector.limit_length(max_pull_distance)
	
	# This sets the player's initial velocity based on the pull vector and launch power.
	linear_velocity = pull_vector * launch_power
	
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
	# This provides visual feedback that the boost was used (e.g., change color).
	sprite.modulate = Color.CYAN
	# TODO: Add a particle effect or sound for the boost here!

# This function draws and updates the aiming line.
func update_aim_line() -> void:
	# This calculates the pull vector from the start to the current mouse position.
	var pull_vector = start_drag_position - get_global_mouse_position()
	# This clamps the vector's length.
	pull_vector = pull_vector.limit_length(max_pull_distance)

	# This clears any previous points from the line.
	line_2d.clear_points()
	# This adds a point at the player's center (0,0 in local coordinates).
	line_2d.add_point(Vector2.ZERO)
	# This adds a point at the end of the pull vector, creating the aiming line.
	# This uses the INVERSE of the player's transform to convert the global pull vector to local space for the Line2D.
	line_2d.add_point(transform.affine_inverse() * pull_vector)
