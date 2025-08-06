extends RigidBody2D
class_name Player
@onready var audioHandler: PlayerAudioHandler = $AudioHandler
# The trail effects
@onready var trail_2d_1: Line2D = $CollisionShape2D/Node2D/Trail2D
@onready var trail_2d_2: Line2D = $CollisionShape2D/Node2D2/Trail2D
@onready var point_numbers_origin: Node2D = $PointNumbersOrigin
@onready var aim_line: Line2D = $AimLine


# This tracks the maximum number of skips the player can have.
var max_skips_per_orbit: int = 1
# This tracks the current number of available skips.
var current_skips_available: int = 0

var dead : bool = false
# Trail effect properties
var original_trail_length: int = 10
var original_trail_color: Color = Color.WHITE
var braking_trail_color: Color = Color(0.8, 0.2, 0.2, 0.8) # Dull red
var boost_trail_color: Color = Color(0, 1, 1, 1) # Bright cyan
var trail_effect_tween: Tween
var hud #= get_tree().root.get_node("Game/HUDLayer/GameHUD")

# This defines a set of named states for the player's state machine.
enum State {
	READY_TO_AIM,
	AIMING,
	LAUNCHED
}

var mobileBrake : bool = false

# A cooldown for launching. TTDG: I use it to make sure releasing fast doesn't use a boost.
const LAUNCH_COOLDOWN_TIME : float = 0.3
# yeah that (half a second)
var canBoost : bool = false

var canSkip : bool = true
@onready var Shape: CollisionShape2D = $CollisionShape2D

@export var softlock_sensitivity = 50
@export_category("Orbit Settings")
@export_range(0.0, 1.0) var orbit_completion_percentage: float = 0.5#0.95 # 95%

@export var SoftlockTime : float = 2
@export var DEBUG_DoLoseCondition : bool = true
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
#const CLICK_TIME : float = 0.2

# Flag to double launch if on planet
var onPlanet : bool = false

# The variable that counts your loop streak
var loopCounter : int = 0
var highScore : int = 0

# Scoring system variables
var points : int = 0  # Points earned from orbiting planets
var mult : int = 0    # Multiplier from entering gravity fields and skips
var final_score : int = 0  # Calculated when crashing

# Track planets that have been orbited for first-time bonus
var orbited_planets: Array[BasePlanet] = []

# This array will keep track of all planets whose gravity fields the player is currently inside.
var overlapping_planets: Array[BasePlanet] = []

static var Position : Vector2
# This variable will hold the player's current state from the enum above.
var current_state: State = State.READY_TO_AIM
# This boolean tracks if the one-time boost is still available.
var BoostCount: int = 3:
	get: return BoostCount
	set(value):
		var old_value = BoostCount
		BoostCount = value
		if(BoostCount == 0):
			Sprite.frame_coords.y = 1
			$"BoostParticles-Explosion".Emit(true)
			# This shows out of boosts tutorial (only when transitioning from >0 to 0)
			if old_value > 0:
				if hud:
					TutorialManager.show_out_of_boosts_tutorial(hud)
		else:
			# Sets the sprite frame to indicate boosts are available.
			Sprite.frame_coords.y = 0

# This new variable will store the calculated pull vector while aiming.
var _current_aim_pull_vector: Vector2 = Vector2.ZERO

# Stores whether a single touch is happening on mobile.
var SingleTouchDown : bool = false

# Lose condition variables
static var max_distance_from_origin: float = 35000.0  # Maximum distance before losing
var origin_position: Vector2 = Vector2.ZERO # No longer static, can be changed.
var has_lost: bool = false

# This function allows the GameController to tell the player where its "home" is.
func set_origin_point(new_origin: Vector2):
	# This sets the center point for the lose condition distance check.
	origin_position = new_origin

# This creates a reference to the Line2D node for drawing the power bar.
@onready var line_2d: Line2D = $Line2D

# Trajectory prediction settings
@export var trajectory_prediction_enabled: bool = false # DEBUG Turn on True if wanting to test
@export var trajectory_steps: int = 50 # Original 50
@export var trajectory_step_time: float = 0.1

# This section is for the new orbit tracking logic.
var current_orbiting_planet: BasePlanet = null
var last_angle_to_planet: float = 0.0
var accumulated_orbit_angle: float = 0.0
var orbit_start_angle: float = 0.0  # Angle where orbit started

# Whether the game is running on a mobile OS

func _ready() -> void:
	hud = get_tree().root.get_node("Game/HUDLayer/GameHUD")
	TutorialManager.show_how_to_play(hud)
	# setup damp mode
	linear_damp_mode = RigidBody2D.DAMP_MODE_COMBINE
	# Stores starting position as origin
	origin_position = global_position
	# Applies ship color from GameManager
	apply_ship_color()
	# Connects to color change signal
	GameManager.ship_color_changed.connect(_on_ship_color_changed)
	GameManager.reset_score()


# Applies the current ship color from GameManager
func apply_ship_color() -> void:
	# This line is commented out as it seems ship color modulation is not currently active.
	# var ship_color = GameManager.get_ship_color()
	# Sprite.modulate = ship_color
	pass
	
# Called when ship color changes in GameManager
func _on_ship_color_changed(_new_color: Color) -> void:
	apply_ship_color()

# Calculates final score when crashing
func calculate_final_score() -> void:
	final_score = points * mult
	print("Final Score Calculation: ", points, " points * ", mult, " mult = ", final_score)
	# Use the animated score addition instead of regular add_score
	GameManager.process_final_score(final_score, point_numbers_origin.global_position)
	if(final_score == 0):
		audioHandler.PlaySoundAtGlobalPosition(Sounds.ShipCrash, global_position)
	else:
		audioHandler.PlaySoundAtGlobalPosition(Sounds.GetPOints, global_position)

# Checks if player has gone too far and should lose
func check_lose_condition() -> void:
	# This stops the function if the player has already lost or if the debug flag is off.
	if has_lost or not DEBUG_DoLoseCondition:
		return

	# This calculates the distance from the center of the map (0,0) instead of the starting origin.
	var distance_from_center = global_position.distance_to(Vector2.ZERO)
	# This checks if the player's distance from the center exceeds the maximum allowed distance.
	if distance_from_center > max_distance_from_origin:
		# This sets a flag to ensure the lose sequence only runs once.
		has_lost = true
		# This prints a debug message to the console.
		print("Player went too far! Distance from center: ", distance_from_center)

		# This calculates and adds the final score before showing the lose screen.
		calculate_final_score()
		# This tells the GameManager to switch to the lose screen.
		GameManager.show_lose_screen()

var mobilePosition : Vector2
# This function is called by Godot when an input event occurs on this object.
#func _input(ev: InputEvent) -> void:
	#if ev is InputEventMouseButton:
		#var event = ev as InputEventMouseButton
		#if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			#clickTimer = get_tree().create_timer(CLICK_TIME)
			#get_viewport().set_input_as_handled()

# A timer to check if the mouse button was down/up quick
#var clickTimer : SceneTreeTimer

var singleTouchProcessed : bool = false
var mouseReleased = true
var initialClickPos : Vector2
var aim_canceled : bool = false

func process_mobile_input():
	if(GameManager.IsMobile):
		match TouchHelper.state.size():
			0: # No touches
				mobileBrake = false
				SingleTouchDown = false
				singleTouchProcessed = false
			
			1: # One touch (for aiming/launching)
				if(not singleTouchProcessed):
					SingleTouchDown = true
					singleTouchProcessed = true
				#clickTimer = get_tree().create_timer(CLICK_TIME)
				
				# Converts screen touch position to world position.
				var screen_position = TouchHelper.state.values()[0]
				var canvas_transform = get_viewport().get_canvas_transform()
				var world_position = canvas_transform.affine_inverse() * screen_position
				mobilePosition = world_position
	return

# This function is called every frame.
func _process(_delta: float) -> void:
	# Handles mobile touch inputs to determine player action.
	process_mobile_input()
	# Does not process input if game is paused (e.g., shop is open).
	
	if get_tree().paused:
		return


	# Updates player's global position for background parallax.
	Position = global_position

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		aim_canceled = true
		current_state = State.READY_TO_AIM
		update_aim_line()
		line_2d.clear_points()
		pass

	## Debug input to reset the player's launch state.
	#if (Input.is_action_just_pressed("DEBUG-RESET_LAUNCH")):
		#Reset()
	# Handles left mouse button or single touch for aiming.
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or SingleTouchDown:
		if not aim_canceled:
			if mouseReleased:
				if (current_state == State.LAUNCHED):
					apply_boost()
				else:
					initialClickPos = GetGlobalClickPosition()
				mouseReleased = false
			# Starts aiming only when pressed and from the READY_TO_AIM state.
			if current_state == State.READY_TO_AIM:
				current_state = State.AIMING
				# Immediately updates aim line for visual feedback.
				update_aim_line()
	else:
		if(aim_canceled):
			aim_canceled= false
		mouseReleased = true
		initialClickPos = Vector2.ZERO
	
	# Updates the aim line only while AIMING and the mouse button/touch is held.
	if current_state == State.AIMING and (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or SingleTouchDown):
		# Updates the aim line visuals and _current_aim_pull_vector.
		update_aim_line()
		
		aim_line.clear_points()
		aim_line.add_point((initialClickPos))
		aim_line.add_point((GetGlobalClickPosition()))

		
		# Makes the ship face the mouse cursor while aiming.
		var mouse_position = to_local(initialClickPos) - to_local(GetGlobalClickPosition())
		look_at(to_global(mouse_position))
	else:
		aim_line.clear_points()
	# Launches on mouse release while AIMING.
	if current_state == State.AIMING and not ((Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or SingleTouchDown)):
		# Calls the function to launch the player using the stored aim vector.
		launch()
		
	## Checks for a quick click to apply a boost.
	#if((Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)or SingleTouchDown) and current_state == State.LAUNCHED):
		##this shouldn't need a timer to detect when the mouse is down, we want to detect when it's lifted.  It shouldn't matter because of the state the player is in.
		##if clickTimer and clickTimer.time_left > 0 and BoostCount > 0 and canBoost:
			#apply_boost()
			##clickTimer = null

static var softlockTimer : SceneTreeTimer
static var isBeingSaved : bool = false
@export var softlockTime : float = 3.0
static var doNotSave : bool = false

# This function runs every physics frame, ideal for physics-related code.
func _physics_process(_delta: float) -> void:
	# Does not process physics input if game is paused (e.g., shop is open).
	
	var debugInput = Vector2(Input.get_axis("DEBUG-LEFT", "DEBUG-RIGHT"), Input.get_axis("DEBUG-UP", "DEBUG-DOWN")) * 50
	move_and_collide(debugInput)
	# Updates player's global position.
	Position = global_position
	
	# This section continuously determines the strongest gravitational influence.
	var strongest_planet: BasePlanet = null
	var max_force = -1.0

	# Iterate through all planets the player is currently inside.
	for planet in overlapping_planets:
		if not is_instance_valid(planet):
			continue
		
		# Calculate the force magnitude for this planet.
		var distance = global_position.distance_to(planet.global_position)
		var radius = planet.collision_shape_2d.shape.radius
		var strength = planet.gravity_strength
		var force = strength * (radius / max(distance, 1.0))

		# If this planet's force is the strongest so far, it becomes the new candidate.
		if force > max_force:
			max_force = force
			strongest_planet = planet
	
	# Check if the dominant planet has changed.
	if strongest_planet != current_orbiting_planet:
		# If we were orbiting a planet before, stop its indicator.
		if is_instance_valid(current_orbiting_planet):
			current_orbiting_planet.stop_orbit_progress_display()
			
		# Switch focus to the new strongest planet.
		current_orbiting_planet = strongest_planet
		
		# If there is a new planet to orbit, reset the tracking for it.
		if is_instance_valid(current_orbiting_planet):
			# Place to reset all orbit-related state.
			accumulated_orbit_angle = 0.0
			last_angle_to_planet = (global_position - current_orbiting_planet.global_position).angle()
			orbit_start_angle = last_angle_to_planet
			current_skips_available = max_skips_per_orbit
			canSkip = true
			current_orbiting_planet.start_orbit_progress_display(self)


	# This logic detects if the player is stuck at a very low velocity and summons a "saving" asteroid.
	if(not onPlanet and BoostCount == 0 and current_state == State.LAUNCHED and (linear_velocity.length() < softlock_sensitivity) and not isBeingSaved):
		if(not doNotSave):
			isBeingSaved = true
			if(not softlockTimer):
				softlockTimer = get_tree().create_timer(SoftlockTime)
				softlockTimer.timeout.connect(func(): 
					SoftlockFixer.FixSoftlock(self)
				)
		else:
			doNotSave = false
	elif not onPlanet and BoostCount > 0 and current_state == State.LAUNCHED and (linear_velocity.length() < 5) and not isBeingSaved:
		get_tree().create_timer(5).timeout.connect(func(): TutorialManager.show_stuck_with_boosts(hud))
		pass
		
	# Checks if the player has drifted too far from the starting origin.
	check_lose_condition()
	if is_inside_tree():
		# Moves the player and checks for collisions.
		var collision : KinematicCollision2D = move_and_collide(linear_velocity.normalized(), true)
		if(collision):
			var collider = collision.get_collider()
			# Checks if the collided object's owner is a planet.
			if collider.owner is BasePlanet:
				if(!onPlanet):
					if collider.owner is HomePlanet:
						# Handles collision with a home planet.
						# Resets the loop counter and clears the trails.
						loopCounter = 0
						trail_2d_1.clear_points()
						trail_2d_2.clear_points()

						# Calculates the final score upon returning home.
						calculate_final_score()

						# Stops the player's movement.
						linear_velocity = Vector2.ZERO
						angular_velocity = 0.0
						audioHandler.PlaySoundAtGlobalPosition(Sounds.ShipCollide, global_position)
						
						# Resets the player's state to be ready for another launch.
						Reset()
						onPlanet = true

						# Shows a tutorial about landing to regain boosts.
						if hud:
							TutorialManager.show_land_for_boost_tutorial(hud)
					else:
						# This is the logic for colliding with a regular planet.
						if(current_skips_available > 0) and collider.owner is not Asteroid:
							print("Skip")

							current_skips_available -= 1
							if(canSkip):
								BoostCount += 1
	
							canSkip = false

							PointNumbers.display_number(mult, point_numbers_origin.global_position, 1)
							mult *= 2
							audioHandler.PlaySoundAtGlobalPosition(Sounds.ShipCollide, global_position)
							audioHandler.PlaySoundAtGlobalPosition(Sounds.PingHigh, global_position)
							
						else:
							# This handles crashing into a regular planet.
							loopCounter = 0
							trail_2d_1.clear_points()
							trail_2d_2.clear_points()
							calculate_final_score()
							linear_velocity = Vector2.ZERO
							angular_velocity = 0.0
							audioHandler.PlaySoundAtGlobalPosition(Sounds.ShipCollide, global_position)
							
							Reset()
							onPlanet = true
			# Checks if the collided object is an asteroid.
			elif collider is Asteroid:
				audioHandler.PlaySoundAtGlobalPosition(Sounds.ShipCollide, global_position)
				softlockTimer = null
				isBeingSaved = false
				doNotSave = true
				
	# This block runs only when the player has been launched and is in motion.
	if current_state == State.LAUNCHED:
		# Makes the rocket point in the direction it's moving.
		if linear_velocity.length() > 0.01:
			rotation = linear_velocity.angle()
		# Checks if the boost is available and the user pressed the boost action.
		if BoostCount > 0 and Input.is_action_just_pressed("boost"):
			apply_boost()
		# Checks for the brake action (keyboard, right mouse, or mobile).
		if(Input.is_action_pressed("brake") or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or mobileBrake):
			linear_damp = 5
			apply_braking_trail_effect()
		else:
			linear_damp = 0
			# Resets trail effects when not braking.
			if trail_effect_tween and trail_2d_1.default_color == braking_trail_color:
				reset_trail_effects()
			
	# Calls the function to handle orbit progress tracking.
	handle_orbit_tracking()
	
# This function tracks the player's progress around a planet.
func handle_orbit_tracking():
	# Stops the function if the player is not currently orbiting a planet.
	if not is_instance_valid(current_orbiting_planet):
		return
	
	# Calculates the player's current angle relative to the planet's center.
	var current_angle = (global_position - current_orbiting_planet.global_position).angle()
	# Calculates how much the angle has changed since the last physics frame.
	var delta_angle = angle_difference(last_angle_to_planet, current_angle)
	
	# Accumulates total angular movement regardless of orbit direction (clockwise or counter-clockwise).
	accumulated_orbit_angle += abs(delta_angle)
	
	# Stores the current angle to compare against in the next frame.
	last_angle_to_planet = current_angle
	
	# Tells the planet to update its visual progress line, passing the direction of rotation.
	current_orbiting_planet.update_orbit_progress(accumulated_orbit_angle, orbit_completion_percentage, orbit_start_angle, sign(delta_angle))
	
	# Checks if the accumulated angle has reached a full loop.
	if accumulated_orbit_angle >= (2 * PI) * orbit_completion_percentage:

		# Checks if this is the first time orbiting this specific planet for a score bonus.
		var is_first_orbit = current_orbiting_planet not in orbited_planets
		# If it is the first time, adds it to the list of visited planets.
		if current_orbiting_planet is Planet_Sol:
			PointNumbers.display_number(50, point_numbers_origin.global_position, 0)  # Green color for bonus
			PointNumbers.display_number(mult * 5, point_numbers_origin.global_position + Vector2(1000, 0), 1)  # Green color for bonus
			points += 50
			mult *= 5
		
		if is_first_orbit:
			orbited_planets.append(current_orbiting_planet)
			if(current_orbiting_planet.AtmoSprite.material):
				current_orbiting_planet.SetShowOrbited(true)
			
			if current_orbiting_planet is not Planet_Sol:
				# This adds a +5 score bonus for the first orbit.
				#GameManager.add_score(5)
				print("First orbit bonus! +5 score")
				points += 5
				PointNumbers.display_number(5, point_numbers_origin.global_position, 0)  # Green color for bonus
		else: if current_orbiting_planet is not Planet_Sol:
			# Increases the base points for the final score calculation.
			points += 1
			# Displays the points number on screen.
			PointNumbers.display_number(1, point_numbers_origin.global_position, 0)
		# Tells the planet to run its completion flash animation.
		current_orbiting_planet.flash_orbit_completion()
		orbit_start_angle = last_angle_to_planet
		#current_orbiting_planet.start_orbit_progress_display(self)
		# Gives the player one boost charge.
		BoostCount += 1
		# Plays the collectable sound effect.
		audioHandler.PlaySoundAtGlobalPosition(Sounds.CollectableGet, global_position)
		# Tells the planet to release its collectable to the player.
		current_orbiting_planet.collect_item(self)
		# Adds the collectable's point value to the score.
		#GameManager.add_score(50)

		# Resets the accumulated angle back to zero to start tracking the next loop.
		accumulated_orbit_angle = 0.0

func ColorMix(color1: Color, color2:Color, ratio:float) -> Color:
	return ratio * color1 + (1-ratio) * color2

# This is a helper function to correctly calculate the difference between two angles.
func angle_difference(from, to):
	var diff = fmod(to - from + PI, 2 * PI) - PI
	return diff if diff < -PI else fmod(to - from - PI, 2 * PI) + PI

# This function is called by a planet when the player enters its gravity well.
func start_orbiting(planet: BasePlanet):

	if not planet in overlapping_planets:
		overlapping_planets.append(planet)
	
	# The rest of the logic is now handled by the _physics_process loop,
	mult += 1
	PointNumbers.display_number(1, point_numbers_origin.global_position, 1)
	audioHandler.PlaySoundAtGlobalPosition(Sounds.PingLow, global_position)
	
	# Shows the first-time orbit tutorial if it hasn't been shown yet.
	if hud:
		TutorialManager.show_first_orbit_tutorial(hud)
		TutorialManager.show_orbit_for_extra_boost_tutorial(hud)

# This function is called by a planet when the player leaves its gravity well.
func stop_orbiting(planet: BasePlanet):
	if planet in overlapping_planets:
		overlapping_planets.erase(planet)


# This function handles the logic for launching the player.
func launch() -> void:
	canSkip = true
	get_tree().create_timer(LAUNCH_COOLDOWN_TIME).timeout.connect(func(): canBoost=true)
	canBoost = false
	# Uses the pre-calculated and stored aim vector.
	var final_pull_vector = _current_aim_pull_vector
	
	# Sets the player's initial velocity based on the stored pull vector and launch power.  THIS IS THE FREAKING LAUNCH CODE
	linear_velocity = final_pull_vector * launch_power * (4.0 if onPlanet else 2.5)
	
	# Changes the state to LAUNCHED.
	current_state = State.LAUNCHED
	# Makes the RigidBody no longer clickable after launch.
	set_pickable(false)
	# Clears the aiming line from the screen.
	line_2d.clear_points()
	
	_LaunchParticles.Emit()
	
	# If on the planet and boosting, handles getting off the planet after physics calculations.
	if(onPlanet):
		onPlanet = false
			
	audioHandler.PlaySoundAtGlobalPosition(Sounds.Launch, global_position)

# This function applies the one-time boost.
func apply_boost() -> void:
	#Don't boost if you don't have any boosts
	if(BoostCount <= 0):
		return
	# Gets the forward direction of the rocket.
	var boost_direction = Vector2.RIGHT.rotated(rotation)
	# Applies an instant force (impulse) in the forward direction.
	apply_central_impulse(boost_direction * boost_strength)
	# Consumes the boost so it cannot be used again.
	BoostCount -= 1

	# Provides visual feedback that the boost was used.
	_BoostParticles.Emit(true)
	apply_boost_trail_effect()

	camera_2d.Shake()
	audioHandler.PlaySoundAtGlobalPosition(Sounds.Boost, global_position)

# This function draws and updates the aiming line.
func update_aim_line() -> void:
	
	# Calculates the global vector from the player's current position to the current mouse position.
	var pull_vector_from_player_to_mouse = initialClickPos - GetGlobalClickPosition()
	# Clamps the vector's length to the max_pull_distance.
	_current_aim_pull_vector = pull_vector_from_player_to_mouse.limit_length(max_pull_distance)

	# Calculates the power percentage (0.0 to 1.0) based on distance.
	var power_percentage = _current_aim_pull_vector.length() / max_pull_distance

	# Clears any previous points from the line.
	line_2d.clear_points()

	if trajectory_prediction_enabled:
		# Creates curved trajectory line accounting for gravity.
		create_curved_trajectory_line(power_percentage)
	else:
		# Creates simple straight line.
		create_straight_aim_line(power_percentage)

# Resets player state for a new launch or game attempt.
func Reset():
	Sprite.frame_coords.y = 0
	current_state = State.READY_TO_AIM
	
	accumulated_orbit_angle = 0.0
	

	# Resets scoring variables for new attempt.
	points = 0
	mult = 1
	final_score = 0

	# Resets boost count to starting amount (including shop upgrades).
	if has_meta("starting_boosts"):
		BoostCount = get_meta("starting_boosts")
	else:
		BoostCount = 3
	
	#resets the known orbited planets
	for planet : BasePlanet in orbited_planets:
		planet.SetShowOrbited(false)
	orbited_planets.clear()
	
	# This resets trail effects
	reset_trail_effects()

# Gets the global click or touch position.
func GetGlobalClickPosition() -> Vector2:
	if GameManager.IsMobile and TouchHelper.state.values()[0] :
		return mobilePosition
	else:
		return get_global_mouse_position()

# Creates a straight aim line (original behavior).
func create_straight_aim_line(power_percentage: float) -> void:
	# Adds a point at the player's center (0,0 in local coordinates for the Line2D).
	line_2d.add_point(Vector2.ZERO)

	# Adds the end point of the pull vector, transformed into Line2D's local space.
	# Ensures the line points correctly regardless of player's current rotation.
	line_2d.add_point(global_transform.basis_xform_inv(_current_aim_pull_vector))

	# Calculates the color interpolation from white to red based on power.
	var line_color = Color.WHITE.lerp(Color.RED, power_percentage)
	line_2d.default_color = line_color

	# Sets the line width based on power (thicker line = more power).
	line_2d.width = 3.0 + power_percentage * 7.0

# Creates a curved trajectory line accounting for gravity effects.
func create_curved_trajectory_line(power_percentage: float) -> void:
	# Calculates initial velocity for trajectory simulation
	var initial_velocity = _current_aim_pull_vector * launch_power * (2.0 if onPlanet else 1.0)

	# Simulates trajectory with physics.
	var trajectory_points = simulate_trajectory(global_position, initial_velocity)

	# Adds trajectory points to the line.
	line_2d.add_point(Vector2.ZERO)  # Starts at player position.
	for point in trajectory_points:
		var local_point = global_transform.basis_xform_inv(point - global_position)
		line_2d.add_point(local_point)

	# Sets line appearance based on power.
	var line_color = Color.WHITE.lerp(Color.CYAN, power_percentage)  # Different color for curved line.
	line_2d.default_color = line_color
	line_2d.width = 4.0 + power_percentage * 6.0

# Simulates trajectory accounting for gravity only when intersecting planet gravity zones.
func simulate_trajectory(start_pos: Vector2, initial_velocity: Vector2) -> Array[Vector2]:
	var trajectory_points: Array[Vector2] = []
	var sim_position = start_pos
	var sim_velocity = initial_velocity

	# Gets all planets in the scene for gravity calculation.
	var planets = get_tree().get_nodes_in_group("planets")
	if planets.is_empty():
		# Fallback: finds planets by type if group is empty.
		planets = []
		var root = get_tree().current_scene
		if root:
			for child in root.get_children():
				if child is BasePlanet:
					planets.append(child)

	# Simulates trajectory step by step.
	for i in range(trajectory_steps):
		# Calculates gravity forces only from planets whose gravity zones intersect trajectory.
		var total_gravity_force = Vector2.ZERO

		for planet in planets:
			if not is_instance_valid(planet) or not planet is BasePlanet:
				continue

			var planet_pos = planet.global_position
			var distance = sim_position.distance_to(planet_pos)

			# Gets planet's gravity zone radius (Area2D collision shape).
			var gravity_zone_radius = 200.0
			if planet.collision_shape_2d and planet.collision_shape_2d.shape is CircleShape2D:
				gravity_zone_radius = planet.collision_shape_2d.shape.radius

			# Applies gravity only if trajectory point is within the gravity zone.
			if distance <= gravity_zone_radius and distance > 50.0:
				# Calculates gravity force similar to planet.gd.
				var direction_to_planet = (planet_pos - sim_position).normalized()
				var gravity_strength = planet.gravity_strength

				# Gets planet's physical radius for falloff calculation.
				var planet_physical_radius = 100.0
				if planet.sprite and planet.sprite.texture:
					# Estimates physical radius from sprite.
					var sprite_size = planet.sprite.texture.get_size() * planet.sprite.scale
					planet_physical_radius = max(sprite_size.x, sprite_size.y) * 0.5

				var gravity_falloff = planet_physical_radius / distance
				var gravity_force = direction_to_planet * gravity_strength * gravity_falloff

				# Applies gravity modifier if player has one.
				var gravity_component = get_node_or_null("GravityModifierComponent")
				if gravity_component:
					gravity_force = gravity_component.modify_gravity_force(gravity_force)

				total_gravity_force += gravity_force

		# Updates velocity with gravity (simplified physics).
		sim_velocity += total_gravity_force * trajectory_step_time / mass

		# Updates position.
		sim_position += sim_velocity * trajectory_step_time

		# Adds point to trajectory.
		trajectory_points.append(sim_position)

		# Stops simulation if trajectory goes too far.
		if sim_position.distance_to(start_pos) > max_pull_distance * 3:
			break

	return trajectory_points

# This initializes trail properties.
func _ready_trail_setup():
	if trail_2d_1 and trail_2d_2:
		# Stores original trail properties.
		original_trail_length = trail_2d_1.length if trail_2d_1.has_method("length") else 10
		original_trail_color = trail_2d_1.default_color
# This resets trails to normal appearance.
func reset_trail_effects():
	if not trail_2d_1 or not trail_2d_2:
		return

	# Stops any ongoing trail animation.
	if trail_effect_tween:
		trail_effect_tween.kill()

	# Resets trail properties to normal.
	if trail_2d_1.has_method("set_length"):
		trail_2d_1.length = original_trail_length
	if trail_2d_2.has_method("set_length"):
		trail_2d_2.length = original_trail_length

	trail_2d_1.default_color = original_trail_color
	trail_2d_2.default_color = original_trail_color

# This applies braking trail effect.
func apply_braking_trail_effect():
	if not trail_2d_1 or not trail_2d_2:
		return

	# Stops any ongoing animation.
	if trail_effect_tween:
		trail_effect_tween.kill()

	# Creates braking effect - shorter, red trails.
	trail_effect_tween = create_tween()
	trail_effect_tween.parallel().tween_property(trail_2d_1, "default_color", braking_trail_color, 0.2)
	trail_effect_tween.parallel().tween_property(trail_2d_2, "default_color", braking_trail_color, 0.2)

	# Shortens trails if possible.
	if trail_2d_1.has_method("set_length"):
		trail_effect_tween.parallel().tween_method(func(length): trail_2d_1.length = length, original_trail_length, original_trail_length * 0.5, 0.2)
	if trail_2d_2.has_method("set_length"):
		trail_effect_tween.parallel().tween_method(func(length): trail_2d_2.length = length, original_trail_length, original_trail_length * 0.5, 0.2)

# This applies boost trail effect.
func apply_boost_trail_effect():
	if not trail_2d_1 or not trail_2d_2:
		return

	# Stops any ongoing animation.
	if trail_effect_tween:
		trail_effect_tween.kill()

	# Creates boost effect - longer, bright cyan trails.
	trail_effect_tween = create_tween()
	trail_effect_tween.parallel().tween_property(trail_2d_1, "default_color", boost_trail_color, 0.1)
	trail_effect_tween.parallel().tween_property(trail_2d_2, "default_color", boost_trail_color, 0.1)

	# Lengthens trails if possible.
	if trail_2d_1.has_method("set_length"):
		trail_effect_tween.parallel().tween_method(func(length): trail_2d_1.length = length, original_trail_length, original_trail_length * 2.0, 0.1)
	if trail_2d_2.has_method("set_length"):
		trail_effect_tween.parallel().tween_method(func(length): trail_2d_2.length = length, original_trail_length, original_trail_length * 2.0, 0.1)

	# Fades back to normal after 1 second.
	trail_effect_tween.tween_interval(1.0)
	trail_effect_tween.parallel().tween_property(trail_2d_1, "default_color", original_trail_color, 0.5)
	trail_effect_tween.parallel().tween_property(trail_2d_2, "default_color", original_trail_color, 0.5)

	if trail_2d_1.has_method("set_length"):
		trail_effect_tween.parallel().tween_method(func(length): trail_2d_1.length = length, original_trail_length * 2.0, original_trail_length, 0.5)
	if trail_2d_2.has_method("set_length"):
		trail_effect_tween.parallel().tween_method(func(length): trail_2d_2.length = length, original_trail_length * 2.0, original_trail_length, 0.5)

func Explode(_position : Vector2):
	dead = true
	Sprite.hide()
	$CollisionShape2D.hide()
	linear_damp = 10
	audioHandler.PlaySoundAtGlobalPosition(Sounds.DownUIBeep, global_position)
	get_tree().create_timer(1).timeout.connect(GameManager.show_lose_screen)
	pass
