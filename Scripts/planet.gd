extends Area2D
class_name BasePlanet

# This exports a variable to the Godot editor, allowing to change it without code.
@export var gravity_strength: float = 6000.0

# This creates an array to store physics bodies that enter the gravity field.
var bodies_in_gravity_field: Array[RigidBody2D] = []
@export var gravityCurve : Curve
@onready var Sprite: Sprite2D = $CollisionShape2D/Sprite2D
# Orbit detection variables
var player_orbit_data: Dictionary = {}  # Stores orbit tracking data for each player


func _ready() -> void:
	# Add to planets group
	add_to_group("planets")


# This function runs every physics frame.
func _physics_process(_delta: float) -> void:
	# This loops through every body currently stored in the array.
	for body in bodies_in_gravity_field:
		# This calculates the direction from the body towards this planet.
		if(not body.onPlanet):
			var direction_to_planet = (global_position - body.global_position).normalized()

		# This calculates the force vector by combining direction and strength.
			var gravity_force = direction_to_planet * gravity_strength * ((Sprite.texture.get_size().x/2) / to_local(global_position).distance_to(body.to_local(global_position))) # gravityCurve.sample

		# This applies the calculated force to the center of the body.
			body.apply_central_force(gravity_force)

		# Track orbit for players
		if body is Player:
			track_player_orbit(body)
		
	

# This function runs when a body enters the Area2D's collision shape.
func _on_body_entered(body: Node2D) -> void:
	# This checks if the entering node is a RigidBody2D.
	if body is RigidBody2D:
		# This checks if the body is not already in the tracking array.
		if not body in bodies_in_gravity_field:
			# This adds the body to the array so gravity will affect it.
			bodies_in_gravity_field.append(body)

			# Initialize orbit tracking for players
			if body is Player:
				initialize_orbit_tracking(body)


# This function runs when a body exits the Area2D's collision shape.
func _on_body_exited(body: Node2D) -> void:
	# This checks if the exiting body is in the tracking array.
	if body is not RigidBody2D:
		return
		
	if body in bodies_in_gravity_field:
		# This removes the body from the array, stopping the gravity effect.
		bodies_in_gravity_field.erase(body)

		# Clean up orbit tracking for players
		if body is Player and body in player_orbit_data:
			player_orbit_data.erase(body)

# Initialize orbit tracking for a player
func initialize_orbit_tracking(player: Player) -> void:
	var initial_angle = get_angle_to_player(player)
	player_orbit_data[player] = {
		"last_angle": initial_angle,
		"total_rotation": 0.0,
		"has_completed_orbit": false,
		"last_orbit_time": 0.0  # Prevent rapid orbit scoring
	}

# Track player's orbit around this planet
func track_player_orbit(player: Player) -> void:
	if not player in player_orbit_data:
		initialize_orbit_tracking(player)
		return

	var current_angle = get_angle_to_player(player)
	var orbit_data = player_orbit_data[player]
	var last_angle = orbit_data["last_angle"]

	# Calculate angle difference, handling wrap-around
	var angle_diff = current_angle - last_angle
	if angle_diff > PI:
		angle_diff -= 2 * PI
	elif angle_diff < -PI:
		angle_diff += 2 * PI

	# Update total rotation
	orbit_data["total_rotation"] += angle_diff
	orbit_data["last_angle"] = current_angle

	# Check if player completed a full orbit (360 degrees = 2π radians)
	var current_time = Time.get_time_dict_from_system()["second"]
	if abs(orbit_data["total_rotation"]) >= 2 * PI and not orbit_data["has_completed_orbit"]:
		# Prevent rapid orbit scoring (minimum 2 seconds between orbits)
		if current_time - orbit_data["last_orbit_time"] >= 2.0:
			orbit_data["has_completed_orbit"] = true
			orbit_data["last_orbit_time"] = current_time
			award_orbit_score(player)
			# Reset for potential multiple orbits
			orbit_data["total_rotation"] = 0.0
			orbit_data["has_completed_orbit"] = false

# Get angle from planet center to player
func get_angle_to_player(player: Player) -> float:
	var direction = player.global_position - global_position
	return direction.angle()

# Award score for completing an orbit
func award_orbit_score(player: Player) -> void:
	GameManager.add_score(100)
	player.BoostCount += 1
	print("Player completed orbit around planet! +100 points")
