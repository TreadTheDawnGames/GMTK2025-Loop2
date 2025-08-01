extends RigidBody2D
class_name Player

# This defines a set of named states for the player's state machine.
enum State {
	READY_TO_AIM,
	AIMING,
	LAUNCHED
}

# A cooldown for launching. TTDG: I use it to make sure releasing fast doesn't use a boost.
const LAUNCH_COOLDOWN_TIME : float = 0.3
# yeah that (half a second)
var canBoost : bool = false

# The particles
@onready var _LaunchParticles: ParticleEffect = $LaunchParticles
@onready var _BoostParticles: ParticleEffect = $BoostParticles
# The sprite
@onready var Sprite: Sprite2D = $Sprite2D
# The Camera
@onready var camera_2d: ScreenShake = $Camera2D

# This exports a variable for launch power, tunable in the Inspector.
@export var launch_power: float = 10.0
# This exports a variable for the maximum drag distance (100% power).
@export var max_pull_distance: float = 200.0
# This exports a variable for the boost impulse strength.
@export var boost_strength: float = 1000.0

#defines how fast a click should be. I use 0.2 in another game just fine.
const CLICK_TIME : float = 0.2

# Flag to double launch if on planet
var onPlanet : bool = false

static var Position : Vector2
# This variable will hold the player's current state from the enum above.
var current_state: State = State.READY_TO_AIM
# This boolean tracks if the one-time boost is still available.
var BoostCount: int = 1

# This new variable will store the calculated pull vector while aiming.
var _current_aim_pull_vector: Vector2 = Vector2.ZERO

#stores whether a single touch is happening
var SingleTouchDown : bool = false

# Lose condition variables
static var max_distance_from_origin: float = 15000.0  # Maximum distance before losing
static var origin_position: Vector2 = Vector2.ZERO
var has_lost: bool = false

# This creates a reference to the Line2D node for drawing the power bar.
@onready var line_2d: Line2D = $Line2D
# This creates a reference to the Sprite2D node.
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	
	linear_damp_mode = RigidBody2D.DAMP_MODE_COMBINE
	# Store starting position as origin
	origin_position = global_position
	# Apply ship color from GameManager
	apply_ship_color()
	# Connect to color change signal
	GameManager.ship_color_changed.connect(_on_ship_color_changed)

# Apply the current ship color from GameManager
func apply_ship_color() -> void:
	#var ship_color = GameManager.get_ship_color()
	#Sprite.modulate = ship_color
	pass
	
# Called when ship color changes in GameManager
func _on_ship_color_changed(_new_color: Color) -> void:
	apply_ship_color()

# Check if player has gone too far and should lose
func check_lose_condition() -> void:
	if has_lost:
		return

	var distance_from_origin = global_position.distance_to(origin_position)
	if distance_from_origin > max_distance_from_origin:
		has_lost = true
		print("Player went too far! Distance: ", distance_from_origin)
		
		# Show lose screen after a short delay
		#await get_tree().create_timer(1.0).timeout
		#Actually don't lol
		GameManager.show_lose_screen()

# This function is called by Godot when an input event occurs on this object.
func _input(ev: InputEvent) -> void:
	if ev is InputEventScreenDrag:
		if ev.index == 0 and ev.is_pressed():
			SingleTouchDown = true
		elif ev.index == 0 and not ev.is_pressed():
			SingleTouchDown = false
	if ev is InputEventMouseButton:
		var event = ev as InputEventMouseButton
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			clickTimer = get_tree().create_timer(CLICK_TIME)
			
# a timer to check if the mouse button was down/up quick
var clickTimer : SceneTreeTimer

# This function is called every frame.
func _process(_delta: float) -> void:
	#change the offset position of the background so it looks more like you're moving
	Position = global_position
	
	#Reset whether ship can aim
	if (Input.is_action_just_pressed("DEBUG-RESET_LAUNCH")):
		Reset()
	
	
	# This handles only the left mouse button events.
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# This starts aiming only when pressed and only from READY_TO_AIM.
		if current_state == State.READY_TO_AIM:
			current_state = State.AIMING
			# Immediately update aim line for visual feedback.
			update_aim_line()
			

			
		# This launches on mouse release while AIMING.

	# This updates the aim line only while AIMING and the mouse button is held.
	if current_state == State.AIMING and (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or SingleTouchDown):
		# This updates the aim line visuals and _current_aim_pull_vector.
		update_aim_line()

		
		# This makes the ship face the mouse cursor while aiming.
		var mouse_position = to_local(global_position) - to_local(get_global_mouse_position())
		look_at(to_global(mouse_position))
	
	# This checks if the player is aiming and spacebar is pressed to launch.
	# Note: This is separate from mouse release to allow "set and shoot" with space.
	if current_state == State.AIMING and not (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or SingleTouchDown):
		# This calls the function to launch the player using the stored aim vector.
		#if(sleeping):
			#set_deferred("sleeping", false)
			#onPlanet = true
		launch()
		
	if(not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		if clickTimer and clickTimer.time_left > 0 and BoostCount > 0 and canBoost:
			apply_boost()
			clickTimer = null

# This function runs every physics frame, ideal for physics-related code.
func _physics_process(delta: float) -> void:
	# Debug movement (assuming "DEBUG-*" inputs are set up) || WASD
	global_position += Vector2(Input.get_axis("DEBUG-LEFT", "DEBUG-RIGHT"), Input.get_axis("DEBUG-UP", "DEBUG-DOWN")) * 1000 * delta

	# Check lose condition - if player is too far from origin
	check_lose_condition()
	if is_inside_tree():
		var collision : KinematicCollision2D = move_and_collide(linear_velocity.normalized(), true)
		if(collision):
			var collider = collision.get_collider()
			if collider.owner is BasePlanet:
				if(!onPlanet):
					print("onPlanet")
					#linear_velocity = Vector2.ZERO
					#angular_velocity = 0.0
					#set_deferred("sleeping", true)
					#Reset()
				onPlanet = true

	# This checks if the player is in the air.
	if current_state == State.LAUNCHED:
		# This makes the rocket point in the direction it's moving.
		if linear_velocity.length() > 0.01: # Avoid rotation issues if velocity is zero
			rotation = linear_velocity.angle()
		# This checks if the boost is available and the user pressed boost.
		if BoostCount > 0 and Input.is_action_just_pressed("boost"):
			apply_boost()
		if(Input.is_action_pressed("brake")):
			linear_damp = 5
		else:
			linear_damp = 0
# This function handles the logic for launching the player.
func launch() -> void:
	
	get_tree().create_timer(LAUNCH_COOLDOWN_TIME).timeout.connect(func(): canBoost=true)
	canBoost = false
	# Use the pre-calculated and stored aim vector.
	var final_pull_vector = _current_aim_pull_vector
	
	# This sets the player's initial velocity based on the stored pull vector and launch power.
	linear_velocity = final_pull_vector * launch_power * (2.0 if onPlanet else 1.0)
	
	# This changes the state to LAUNCHED.
	current_state = State.LAUNCHED
	# This makes the RigidBody no longer clickable after launch.
	set_pickable(false)
	# This clears the aiming line from the screen.
	line_2d.clear_points()
	
	_LaunchParticles.Emit()
	
	#If you're on the planet and boost, you're getting off the planet, but it needs to happen AFTER the math is done.
	if(onPlanet):
		print("OffPlanet")
		
		onPlanet = false
			
	# TODO: Add a sound for the boost here!

# This function applies the one-time boost.
func apply_boost() -> void:
	# This gets the forward direction of the rocket.
	var boost_direction = Vector2.RIGHT.rotated(rotation)
	# This applies an instant force (impulse) in the forward direction.
	apply_central_impulse(boost_direction * boost_strength)
	# This consumes the boost so it cannot be used again.
	#BoostCount -= 1
	
	# This provides visual feedback that the boost was used.
	#sprite.modulate = Color.CYAN
	_BoostParticles.Emit(true)
	if(BoostCount == 0):
		Sprite.frame_coords.y = 1
		$"BoostParticles-Explosion".Emit(true)
	camera_2d.Shake()
	

	# TODO: Add a sound for the boost here!

# This function draws and updates the aiming line.
func update_aim_line() -> void:
	# This calculates the global vector from the player's current position to the current mouse position.
	var pull_vector_from_player_to_mouse = global_position - get_global_mouse_position()
	# This clamps the vector's length to the max_pull_distance.
	_current_aim_pull_vector = pull_vector_from_player_to_mouse.limit_length(max_pull_distance)
	
	# This calculates the power percentage (0.0 to 1.0) based on distance.
	var power_percentage = _current_aim_pull_vector.length() / max_pull_distance
	
	# This clears any previous points from the line.
	line_2d.clear_points()
	# This adds a point at the player's center (0,0 in local coordinates for the Line2D).
	line_2d.add_point(Vector2.ZERO)
	
	# This adds the end point of the pull vector, transformed into Line2D's local space.
	# It ensures the line points correctly regardless of player's current rotation.
	line_2d.add_point(global_transform.basis_xform_inv(_current_aim_pull_vector))
	
	# This calculates the color interpolation from white to red based on power.
	var line_color = Color.WHITE.lerp(Color.RED, power_percentage)
	line_2d.default_color = line_color
	
	# This sets the line width based on power (thicker line = more power).
	line_2d.width = 3.0 + power_percentage * 7.0


func Reset():
	Sprite.frame_coords.y = 0
	current_state = State.READY_TO_AIM
	BoostCount = 1
