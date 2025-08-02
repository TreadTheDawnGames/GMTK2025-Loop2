extends Area2D
class_name BasePlanet

# This exports a variable to the Godot editor, allowing to change it without code.
@export var gravity_strength: float = 4000.0
# This creates an array to store physics bodies that enter the gravity field.
var bodies_in_gravity_field: Array[RigidBody2D] = []
@export var gravityCurve : Curve

@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
# This uses the % syntax to ensure reliable node finding.
# This variable will be 'null' for planets that do not have this node.
@onready var orbit_progress_indicator: Line2D
@onready var AtmoSprite: Sprite2D
@onready var AtmoSpriteOrbited: Sprite2D



# Orbital progress tracking
var current_orbiting_player: Player = null
var orbit_radius: float = 0.0

# This section controls collectable spawning
@export var can_have_collectable: bool = true
# This sets the probability (from 0.0 to 1.0) that a collectable will spawn on this planet.
@export_range(0.0, 1.0) var collectable_spawn_chance: float = 0.8
@export var collectable_scenes: Array[PackedScene] = [
	preload("res://Scenes/Collectables/Collectable_Star.tscn"),
	preload("res://Scenes/Collectables/Collectable_Satellite.tscn"),
	preload("res://Scenes/Collectables/Collectable_Crystal.tscn"),
	preload("res://Scenes/Collectables/Collectable_EnergyCore.tscn")
]


# This holds a reference to the spawned collectable instance.
var spawned_collectable: Collectable = null

func _ready() -> void:
	orbit_progress_indicator = get_node_or_null("OrbitProgressIndicator")
	AtmoSprite = get_node_or_null("CollisionShape2D/Sprite2D")
	AtmoSpriteOrbited = get_node_or_null("CollisionShape2D/Sprite2D/Sprite2D2")
	# This adds the planet to a group for tracking.
	add_to_group("planets")
	# This attempts to spawn a collectable when the planet is ready.
	spawn_collectable_at_center()

func spawn_collectable_at_center():
	# This checks if the planet is allowed to have a collectable.
	if not can_have_collectable or collectable_scenes.is_empty():
		return
		
	# This creates a random chance for the collectable to spawn.
	if randf() > collectable_spawn_chance:
		return # This exits the function if the random check fails.

	# This picks a random collectable scene from the array.
	var collectable_scene = collectable_scenes.pick_random()
	if not collectable_scene:
		return

	# This creates an instance of the chosen collectable.
	var collectable_instance = collectable_scene.instantiate() as Collectable
	add_child(collectable_instance)
	
	# This places the collectable at the center of the planet.
	collectable_instance.position = Vector2.ZERO
	
	# This stores the reference for later.
	spawned_collectable = collectable_instance

# This is a new helper function for the compass.
func has_uncollected_collectable() -> bool:
	# This returns true if the collectable instance is still valid (has not been collected).
	return is_instance_valid(spawned_collectable)

# This is called by the Player script when a loop is completed.
func collect_item(_player: Player):
	# This checks if there is a valid, uncollected item to award.
	if has_uncollected_collectable():
		print(name + " collectable has been awarded.")
		
		# This tells the collectable instance to play its collection effects.
		spawned_collectable.collect()
		# This removes the reference so it cannot be collected again.
		spawned_collectable = null

# This function runs every physics frame.
func _physics_process(_delta: float) -> void:
	# This loops through every body currently stored in the array.
	for body in bodies_in_gravity_field:
		# This calculates the direction from the body towards this planet.
		if(body is Player and not body.onPlanet):
			var direction_to_planet = (global_position - body.global_position).normalized()
			var distance = global_position.distance_to(body.global_position)
			var gravity_falloff = collision_shape_2d.shape.radius / distance
			
			# This calculates the force vector by combining direction and strength.
			var gravity_force = direction_to_planet * gravity_strength * gravity_falloff

			# This applies the calculated force to the center of the body.
			body.apply_central_force(gravity_force)

# This function runs when a body enters the Area2D's collision shape.
func _on_body_entered(body: Node2D) -> void:
	# This checks if the entering node is a RigidBody2D.
	if body is RigidBody2D:
		# This checks if the body is not already in the tracking array.
		if not body in bodies_in_gravity_field:
			# This adds the body to the array so gravity will affect it.
			bodies_in_gravity_field.append(body)
			if body is Player:
				body.start_orbiting(self)
				start_orbit_progress_display(body)


# This function runs when a body exits the Area2D's collision shape.
func _on_body_exited(body: Node2D) -> void:
	# This checks if the exiting body is in the tracking array.
	if body is RigidBody2D and body in bodies_in_gravity_field:
		# This removes the body from the array, stopping the gravity effect.
		bodies_in_gravity_field.erase(body)
		if body is Player:
			body.stop_orbiting(self)
			stop_orbit_progress_display()

# This starts showing orbital progress for a player
func start_orbit_progress_display(player: Player):
	# This ensures the orbit progress indicator exists before trying to use it.
	if not is_instance_valid(orbit_progress_indicator):
		return # This skips the display logic if the node is not present.

	current_orbiting_player = player
	# This calculates orbit radius based on collision shape
	if collision_shape_2d and collision_shape_2d.shape is CircleShape2D:
		var circle_shape = collision_shape_2d.shape as CircleShape2D
		orbit_radius = circle_shape.radius * 1.2 # Slightly larger than planet
	else:
		orbit_radius = 100.0 # Default radius

	orbit_progress_indicator.visible = true
	orbit_progress_indicator.clear_points()

# This stops showing orbital progress
func stop_orbit_progress_display():
	current_orbiting_player = null
	# This ensures the orbit progress indicator exists before trying to use it.
	if is_instance_valid(orbit_progress_indicator):
		orbit_progress_indicator.visible = false
		orbit_progress_indicator.clear_points()

# This updates the orbital progress arc based on player's accumulated angle
func update_orbit_progress(accumulated_angle: float, completion_percentage: float, start_angle: float = 0.0):
	# This ensures the orbit progress indicator exists and is visible before drawing.
	if not is_instance_valid(orbit_progress_indicator) or not orbit_progress_indicator.visible:
		return

	orbit_progress_indicator.clear_points()

	# This calculates how much of the orbit to show
	var progress = abs(accumulated_angle) / (2 * PI * completion_percentage)
	progress = clamp(progress, 0.0, 1.0)

	# This creates arc points starting from the initial angle
	var num_points = int(progress * 64) # Up to 64 points for smooth arc
	if num_points < 2:
		return

	for i in range(num_points + 1):
		# Start the arc from the initial angle where orbit began
		var angle = start_angle + (float(i) / num_points) * progress * 2 * PI * completion_percentage
		var point = Vector2(cos(angle), sin(angle)) * orbit_radius
		orbit_progress_indicator.add_point(point)

# This creates completion flash effect
func flash_orbit_completion():
	# This ensures the orbit progress indicator exists before flashing.
	if not is_instance_valid(orbit_progress_indicator):
		return

	# This plays completion sound
	MusicManager.play_audio_omni("UpUIBeep")

	# This creates flash animation
	var flash_tween = create_tween()
	flash_tween.tween_property(orbit_progress_indicator, "default_color", Color.WHITE, 0.1)
	flash_tween.tween_property(orbit_progress_indicator, "default_color", Color(0, 1, 1, 0.8), 0.2)
	flash_tween.tween_callback(stop_orbit_progress_display)

func SetShowOrbited(orbited : bool):
	AtmoSpriteOrbited.visible = orbited
	return
