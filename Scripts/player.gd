extends RigidBody2D
class_name Player
@onready var audioHandler: PlayerAudioHandler = $AudioHandler
# The trail effects
@onready var trail_2d_1: Line2D = $CollisionShape2D/Node2D/Trail2D
@onready var trail_2d_2: Line2D = $CollisionShape2D/Node2D2/Trail2D

@onready var point_numbers_origin: Node2D = $PointNumbersOrigin


# Trail effect properties
var original_trail_length: int = 10
var original_trail_color: Color = Color.WHITE
var braking_trail_color: Color = Color(0.8, 0.2, 0.2, 0.8) # Dull red
var boost_trail_color: Color = Color(0, 1, 1, 1) # Bright cyan
var trail_effect_tween: Tween

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

@export_category("Orbit Settings")
@export_range(0.0, 1.0) var orbit_completion_percentage: float = 0.95 # 95%

@export var SoftlockTime : float = 3
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
const CLICK_TIME : float = 0.2

# Flag to double launch if on planet
var onPlanet : bool = false

#the variable that counts your loop streak
var loopCounter : int = 0
var highScore : int = 0

# Scoring system variables
var points : int = 0  # points earned from orbiting planets
var mult : int = 0    # multiplier from entering gravity fields and skips
var final_score : int = 0  # calculated when crashing

static var Position : Vector2
# This variable will hold the player's current state from the enum above.
var current_state: State = State.READY_TO_AIM
# This boolean tracks if the one-time boost is still available.
var BoostCount: int = 1:
	get: return BoostCount
	set(value):
		var old_value = BoostCount
		BoostCount = value
		if(BoostCount == 0):
			Sprite.frame_coords.y = 1
			$"BoostParticles-Explosion".Emit(true)
			# This shows out of boosts tutorial (only when transitioning from >0 to 0)
			if old_value > 0:
				var hud = get_tree().root.get_node("Game/HUDLayer/GameHUD")
				if hud:
					TutorialManager.show_out_of_boosts_tutorial(hud)
		else:
			sprite.frame_coords.y = 0

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

# Trajectory prediction settings
@export var trajectory_prediction_enabled: bool = false # DEBUG Turn on True if wanting to test
@export var trajectory_steps: int = 50 #original 50
@export var trajectory_step_time: float = 0.1
# This creates a reference to the Sprite2D node.
@onready var sprite: Sprite2D = $Sprite2D

# This section is for the new orbit tracking logic.
var current_orbiting_planet: BasePlanet = null
var last_angle_to_planet: float = 0.0
var accumulated_orbit_angle: float = 0.0

#Whether the game is running on a mobile OS
var isMobile : bool = false
var orbit_start_angle: float = 0.0  # Angle where orbit started

func _ready() -> void:
	isMobile = OS.has_feature("web_android") or OS.has_feature("web_ios")
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

# Calculate final score when crashing
func calculate_final_score() -> void:
	final_score = points * mult
	print("Final Score Calculation: ", points, " points * ", mult, " mult = ", final_score)
	GameManager.add_score(final_score)
	PointNumbers.display_number(final_score, point_numbers_origin.global_position, 2, -2)

# Check if player has gone too far and should lose
func check_lose_condition() -> void:
	if has_lost or not DEBUG_DoLoseCondition:
		return

	var distance_from_origin = global_position.distance_to(origin_position)
	if distance_from_origin > max_distance_from_origin:
		has_lost = true
		print("Player went too far! Distance: ", distance_from_origin)

		# Calculate and add final score before showing lose screen
		calculate_final_score()

		# Show lose screen after a short delay
		#await get_tree().create_timer(1.0).timeout
		#Actually don't lol
		GameManager.show_lose_screen()

var mobilePosition : Vector2
# This function is called by Godot when an input event occurs on this object.
func _input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var event = ev as InputEventMouseButton
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			clickTimer = get_tree().create_timer(CLICK_TIME)
			get_viewport().set_input_as_handled()

# a timer to check if the mouse button was down/up quick
var clickTimer : SceneTreeTimer

var singleTouchProcessed : bool = false
# This function is called every frame.
func _process(_delta: float) -> void:
	#for fingieIndex in TouchHelper.state.keys()
	if(isMobile):
		match TouchHelper.state.size():
			0:
				mobileBrake = false
				SingleTouchDown = false
				singleTouchProcessed = false
			
			1:
				if(not singleTouchProcessed):
					SingleTouchDown = true
					singleTouchProcessed = true
				clickTimer = get_tree().create_timer(CLICK_TIME)
				
				#godot forums
				var screen_position = TouchHelper.state.values()[0]
				var canvas_transform = get_viewport().get_canvas_transform()
				var world_position = canvas_transform.affine_inverse() * screen_position
				mobilePosition = world_position
				
			2:
				singleTouchProcessed = false
				mobileBrake = true
	
	# Don't process input if game is paused (shop is open)
	if get_tree().paused:
		return

	#change the offset position of the background so it looks more like you're moving
	Position = global_position

	#Reset whether ship can aim
	if (Input.is_action_just_pressed("DEBUG-RESET_LAUNCH")):
		Reset()
	
	# This handles only the left mouse button events.
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or SingleTouchDown:
		# This starts aiming only when pressed and only from READY_TO_AIM.
		if current_state == State.READY_TO_AIM:
			current_state = State.AIMING
			# Immediately update aim line for visual feedback.
			update_aim_line()

	# This updates the aim line only while AIMING and the mouse button is held.
	if current_state == State.AIMING and (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or SingleTouchDown):
		# This updates the aim line visuals and _current_aim_pull_vector.
		update_aim_line()
		
		# This makes the ship face the mouse cursor while aiming.
		var mouse_position = to_local(global_position) - to_local(GetGlobalClickPosition())
		look_at(to_global(mouse_position))
	
	# This launches on mouse release while AIMING.
	if current_state == State.AIMING and not ((Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or SingleTouchDown)):
		# This calls the function to launch the player using the stored aim vector.
		launch()
		
	if(not (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)or SingleTouchDown)):
		if clickTimer and clickTimer.time_left > 0 and BoostCount > 0 and canBoost:
			apply_boost()
			clickTimer = null

static var softlockTimer : SceneTreeTimer
static var isBeingSaved : bool = false
@export var softlockTime : float = 3.0
static var doNotSave : bool = false
# This function runs every physics frame, ideal for physics-related code.
func _physics_process(_delta: float) -> void:
	print("IsBeingSaved:" + str(isBeingSaved))
	# Don't process physics input if game is paused (shop is open)
	if get_tree().paused:
		return
	# Debug movement (assuming "DEBUG-*" inputs are set up) || WASD
	
	#linear_velocity += Vector2(Input.get_axis("DEBUG-LEFT", "DEBUG-RIGHT"), Input.get_axis("DEBUG-UP", "DEBUG-DOWN")) * 500
	#if(Input.is_action_just_released("DEBUG-LEFT") or Input.is_action_just_released("DEBUG-RIGHT") or Input.is_action_just_released("DEBUG-UP") or Input.is_action_just_released("DEBUG-DOWN")):
		#linear_velocity = Vector2.ZERO
	#if(Input.is_action_just_pressed("DEBUG-ADD_BOOST")):
		#BoostCount +=1
	
	#print("Velocity" + str(linear_velocity.length()))
	#print("IsBeingSaved: " + str(isBeingSaved))
	
	if(not onPlanet and BoostCount == 0 and current_state == State.LAUNCHED and (linear_velocity.length() < 5) and not isBeingSaved):
		if(not doNotSave):
			isBeingSaved = true
			if(not softlockTimer):
				print("Summoning saving asteroid")
				softlockTimer = get_tree().create_timer(SoftlockTime)
				softlockTimer.timeout.connect(func(): 
					SoftlockFixer.FixSoftlock(global_position)
				)
		else:
			doNotSave = false
		

	
	# Check lose condition - if player is too far from origin
	check_lose_condition()
	if is_inside_tree():
		var collision : KinematicCollision2D = move_and_collide(linear_velocity.normalized(), true)
		if(collision):
			var collider = collision.get_collider()
			if collider.owner is BasePlanet:
				if(!onPlanet):
					if(canSkip == true) and collider.owner is not HomePlanet and collider.owner is not Asteroid:
						print("Skip")
						canSkip = false
						BoostCount += 1
						#points += 3
						#PointNumbers.display_number(points, point_numbers_origin.global_position, 0)
						
						mult *= 2
						PointNumbers.display_number(mult, point_numbers_origin.global_position, 1)

						# Add mult *2 every time a skip is performed
						#mult *= 2
						#print("Skip performed! Mult: ", mult)

						audioHandler.PlaySoundAtGlobalPosition(Sounds.ShipCollide, global_position)
					else:
						#reset loop counter
						loopCounter = 0
						#Reset Trail
						trail_2d_1.clear_points()
						trail_2d_2.clear_points()

						# Calculate final score when crashing into planet
						calculate_final_score()

						print("onPlanet")
						linear_velocity = Vector2.ZERO
						angular_velocity = 0.0
						audioHandler.PlaySoundAtGlobalPosition(Sounds.ShipCollide, global_position)
						#set_deferred("sleeping", true)
						Reset()
						onPlanet = true
			elif collider is Asteroid:
				# Calculate final score when crashing into asteroid
				#calculate_final_score()

				audioHandler.PlaySoundAtGlobalPosition(Sounds.ShipCollide, global_position)
				softlockTimer = null
				isBeingSaved = false
				doNotSave = true
				
				
		
	# This checks if the player is in the air.
	if current_state == State.LAUNCHED:
		# This makes the rocket point in the direction it's moving.
		if linear_velocity.length() > 0.01: # Avoid rotation issues if velocity is zero
			rotation = linear_velocity.angle()
		# This checks if the boost is available and the user pressed boost.
		if BoostCount > 0 and Input.is_action_just_pressed("boost"):
			apply_boost()
		if(Input.is_action_pressed("brake") or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or mobileBrake):
			linear_damp = 5
			apply_braking_trail_effect()
		else:
			linear_damp = 0
			# This resets trail effects when not braking
			if trail_effect_tween and trail_2d_1.default_color == braking_trail_color:
				reset_trail_effects()
			
	# This calls the function to handle orbit progress tracking.
	handle_orbit_tracking()

# This is a new function to track the orbital loop.
func handle_orbit_tracking():
	if not is_instance_valid(current_orbiting_planet):
		return
	# This calculates the angle from the planet to the player.
	var current_angle = (global_position - current_orbiting_planet.global_position).angle()
	# This calculates the change in angle since the last frame, handling angle wrapping.
	var delta_angle = angle_difference(last_angle_to_planet, current_angle)
	# This adds the change to our total.
	accumulated_orbit_angle += delta_angle
	# This updates the angle for the next frame.
	last_angle_to_planet = current_angle

	# This updates the orbital progress indicator on the planet
	current_orbiting_planet.update_orbit_progress(accumulated_orbit_angle, orbit_completion_percentage, orbit_start_angle)

	# This checks if we completed a full circle (2 * PI radians).
	if abs(accumulated_orbit_angle) >= (2 * PI) * orbit_completion_percentage:
		print("Loop complete!")

		# Add +1 to points every time orbiting a planet
		points += 1
		print("Orbited planet! Points: ", points)
		#display points
		PointNumbers.display_number(points, point_numbers_origin.global_position, 0)
		
		# This creates flash effect on planet
		current_orbiting_planet.flash_orbit_completion()
		# This tells the planet to give its collectable.
		BoostCount += 1
		audioHandler.PlaySoundAtGlobalPosition(Sounds.CollectableGet, global_position)
		current_orbiting_planet.collect_item(self)
		GameManager.add_score(50)


		# This resets the angle so we don't collect again immediately.
		accumulated_orbit_angle = 0.0

# This is a helper function to correctly calculate the difference between two angles.
func angle_difference(from, to):
	var diff = fmod(to - from + PI, 2 * PI) - PI
	return diff if diff < -PI else fmod(to - from - PI, 2 * PI) + PI

# This function is called by a planet when the player enters its gravity.
func start_orbiting(planet: BasePlanet):
	current_orbiting_planet = planet
	accumulated_orbit_angle = 0.0
	last_angle_to_planet = (global_position - planet.global_position).angle()
	orbit_start_angle = last_angle_to_planet  # Remember where we started
	print("Started orbiting: ", planet.name)

	# This shows first orbit tutorial
	var hud = get_tree().root.get_node("Game/HUDLayer/GameHUD")
	if hud:
		TutorialManager.show_first_orbit_tutorial(hud)

# This function is called by a planet when the player leaves its gravity.
func stop_orbiting(planet: BasePlanet):
	# This ensures we only stop orbiting the correct planet.
	if planet == current_orbiting_planet:
		current_orbiting_planet = null
		accumulated_orbit_angle = 0.0
		print("Stopped orbiting: ", planet.name)
		canSkip = true

# This function handles the logic for launching the player.
func launch() -> void:
	canSkip = true
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
			
	audioHandler.PlaySoundAtGlobalPosition(Sounds.Launch, global_position)

# This function applies the one-time boost.
func apply_boost() -> void:
	# This gets the forward direction of the rocket.
	var boost_direction = Vector2.RIGHT.rotated(rotation)
	# This applies an instant force (impulse) in the forward direction.
	apply_central_impulse(boost_direction * boost_strength)
	# This consumes the boost so it cannot be used again.
	BoostCount -= 1

	# This provides visual feedback that the boost was used.
	#sprite.modulate = Color.CYAN
	_BoostParticles.Emit(true)
	apply_boost_trail_effect()

	camera_2d.Shake()
	audioHandler.PlaySoundAtGlobalPosition(Sounds.Boost, global_position)

# This function draws and updates the aiming line.
func update_aim_line() -> void:

	# This calculates the global vector from the player's current position to the current mouse position.
	var pull_vector_from_player_to_mouse = global_position - GetGlobalClickPosition()
	# This clamps the vector's length to the max_pull_distance.
	_current_aim_pull_vector = pull_vector_from_player_to_mouse.limit_length(max_pull_distance)

	# This calculates the power percentage (0.0 to 1.0) based on distance.
	var power_percentage = _current_aim_pull_vector.length() / max_pull_distance

	# This clears any previous points from the line.
	line_2d.clear_points()

	if trajectory_prediction_enabled:
		# This creates curved trajectory line accounting for gravity
		create_curved_trajectory_line(power_percentage)
	else:
		# This creates simple straight line
		create_straight_aim_line(power_percentage)


func Reset():
	Sprite.frame_coords.y = 0
	current_state = State.READY_TO_AIM
	
	accumulated_orbit_angle = 0.0

	# Reset scoring variables for new attempt
	points = 0
	mult = 1
	final_score = 0

	# Reset boost count to starting amount (including shop upgrades)
	if has_meta("starting_boosts"):
		BoostCount = get_meta("starting_boosts")
	else:
		BoostCount = 1

	# This resets trail effects
	reset_trail_effects()

func GetGlobalClickPosition() -> Vector2:
	if isMobile and TouchHelper.state.values()[0] :
		return mobilePosition
	else:
		return get_global_mouse_position()

# Creates straight aim line (original behavior)
func create_straight_aim_line(power_percentage: float) -> void:
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

# Creates curved trajectory line accounting for gravity effects
func create_curved_trajectory_line(power_percentage: float) -> void:
	# This calculates initial velocity for trajectory simulation
	var initial_velocity = _current_aim_pull_vector * launch_power * (2.0 if onPlanet else 1.0)

	# This simulates trajectory with physics
	var trajectory_points = simulate_trajectory(global_position, initial_velocity)

	# This adds trajectory points to the line
	line_2d.add_point(Vector2.ZERO)  # Start at player position
	for point in trajectory_points:
		var local_point = global_transform.basis_xform_inv(point - global_position)
		line_2d.add_point(local_point)

	# This sets line appearance based on power
	var line_color = Color.WHITE.lerp(Color.CYAN, power_percentage)  # Different color for curved line
	line_2d.default_color = line_color
	line_2d.width = 4.0 + power_percentage * 6.0

# Simulates trajectory accounting for gravity only when intersecting planet gravity zones
func simulate_trajectory(start_pos: Vector2, initial_velocity: Vector2) -> Array[Vector2]:
	var trajectory_points: Array[Vector2] = []
	var sim_position = start_pos
	var sim_velocity = initial_velocity

	# Get all planets in the scene for gravity calculation
	var planets = get_tree().get_nodes_in_group("planets")
	if planets.is_empty():
		# Fallback: find planets by type
		planets = []
		var root = get_tree().current_scene
		if root:
			for child in root.get_children():
				if child is BasePlanet:
					planets.append(child)

	# Simulate trajectory step by step
	for i in range(trajectory_steps):
		# Calculate gravity forces only from planets whose gravity zones intersect trajectory
		var total_gravity_force = Vector2.ZERO

		for planet in planets:
			if not is_instance_valid(planet) or not planet is BasePlanet:
				continue

			var planet_pos = planet.global_position
			var distance = sim_position.distance_to(planet_pos)

			# Get planet's gravity zone radius (Area2D collision shape)
			var gravity_zone_radius = 200.0  # Default
			if planet.collision_shape_2d and planet.collision_shape_2d.shape is CircleShape2D:
				gravity_zone_radius = planet.collision_shape_2d.shape.radius

			# Only apply gravity if trajectory point is within the gravity zone
			if distance <= gravity_zone_radius and distance > 50.0:
				# Calculate gravity force similar to planet.gd
				var direction_to_planet = (planet_pos - sim_position).normalized()
				var gravity_strength = planet.gravity_strength

				# Get planet's physical radius for falloff calculation
				var planet_physical_radius = 100.0  # Default
				if planet.sprite and planet.sprite.texture:
					# Estimate physical radius from sprite
					var sprite_size = planet.sprite.texture.get_size() * planet.sprite.scale
					planet_physical_radius = max(sprite_size.x, sprite_size.y) * 0.5

				var gravity_falloff = planet_physical_radius / distance
				var gravity_force = direction_to_planet * gravity_strength * gravity_falloff

				# Apply gravity modifier if player has one
				var gravity_component = get_node_or_null("GravityModifierComponent")
				if gravity_component:
					gravity_force = gravity_component.modify_gravity_force(gravity_force)

				total_gravity_force += gravity_force

		# Update velocity with gravity (simplified physics)
		sim_velocity += total_gravity_force * trajectory_step_time / mass

		# Update position
		sim_position += sim_velocity * trajectory_step_time

		# Add point to trajectory
		trajectory_points.append(sim_position)

		# Stop simulation if trajectory goes too far
		if sim_position.distance_to(start_pos) > max_pull_distance * 3:
			break

	return trajectory_points

# This initializes trail properties
func _ready_trail_setup():
	if trail_2d_1 and trail_2d_2:
		# This stores original trail properties
		original_trail_length = trail_2d_1.length if trail_2d_1.has_method("length") else 10
		original_trail_color = trail_2d_1.default_color

# This resets trails to normal appearance
func reset_trail_effects():
	if not trail_2d_1 or not trail_2d_2:
		return

	# This stops any ongoing trail animation
	if trail_effect_tween:
		trail_effect_tween.kill()

	# This resets trail properties to normal
	if trail_2d_1.has_method("set_length"):
		trail_2d_1.length = original_trail_length
	if trail_2d_2.has_method("set_length"):
		trail_2d_2.length = original_trail_length

	trail_2d_1.default_color = original_trail_color
	trail_2d_2.default_color = original_trail_color

# This applies braking trail effect
func apply_braking_trail_effect():
	if not trail_2d_1 or not trail_2d_2:
		return

	# This stops any ongoing animation
	if trail_effect_tween:
		trail_effect_tween.kill()

	# This creates braking effect - shorter, red trails
	trail_effect_tween = create_tween()
	trail_effect_tween.parallel().tween_property(trail_2d_1, "default_color", braking_trail_color, 0.2)
	trail_effect_tween.parallel().tween_property(trail_2d_2, "default_color", braking_trail_color, 0.2)

	# This shortens trails if possible
	if trail_2d_1.has_method("set_length"):
		trail_effect_tween.parallel().tween_method(func(length): trail_2d_1.length = length, original_trail_length, original_trail_length * 0.5, 0.2)
	if trail_2d_2.has_method("set_length"):
		trail_effect_tween.parallel().tween_method(func(length): trail_2d_2.length = length, original_trail_length, original_trail_length * 0.5, 0.2)

# This applies boost trail effect
func apply_boost_trail_effect():
	if not trail_2d_1 or not trail_2d_2:
		return

	# This stops any ongoing animation
	if trail_effect_tween:
		trail_effect_tween.kill()

	# This creates boost effect - longer, bright cyan trails
	trail_effect_tween = create_tween()
	trail_effect_tween.parallel().tween_property(trail_2d_1, "default_color", boost_trail_color, 0.1)
	trail_effect_tween.parallel().tween_property(trail_2d_2, "default_color", boost_trail_color, 0.1)

	# This lengthens trails if possible
	if trail_2d_1.has_method("set_length"):
		trail_effect_tween.parallel().tween_method(func(length): trail_2d_1.length = length, original_trail_length, original_trail_length * 2.0, 0.1)
	if trail_2d_2.has_method("set_length"):
		trail_effect_tween.parallel().tween_method(func(length): trail_2d_2.length = length, original_trail_length, original_trail_length * 2.0, 0.1)

	# This fades back to normal after 1 second
	trail_effect_tween.tween_interval(1.0)
	trail_effect_tween.parallel().tween_property(trail_2d_1, "default_color", original_trail_color, 0.5)
	trail_effect_tween.parallel().tween_property(trail_2d_2, "default_color", original_trail_color, 0.5)

	if trail_2d_1.has_method("set_length"):
		trail_effect_tween.parallel().tween_method(func(length): trail_2d_1.length = length, original_trail_length * 2.0, original_trail_length, 0.5)
	if trail_2d_2.has_method("set_length"):
		trail_effect_tween.parallel().tween_method(func(length): trail_2d_2.length = length, original_trail_length * 2.0, original_trail_length, 0.5)
