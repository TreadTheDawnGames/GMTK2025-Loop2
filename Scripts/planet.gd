# res://Scripts/planet.gd
extends Area2D
class_name BasePlanet

# This preloads the satellite scene so it can be spawned from code.
const SATELLITE_SCENE = preload("res://Scenes/Planets/Satellite.tscn")

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
@export_group("Collectables")
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

# This section controls satellite spawning
@export_group("Satellites")
# This toggles whether this planet can have satellites
@export var can_have_satellites: bool = true
# This sets the probability (from 0.0 to 1.0) that satellites will spawn
@export_range(0.0, 1.0) var satellite_spawn_chance: float = 0.1
# This is the minimum number of satellites that can spawn
@export var num_satellites_min: int = 1
# This is the maximum number of satellites that can spawn
@export var num_satellites_max: int = 3


func _ready() -> void:
	orbit_progress_indicator = get_node_or_null("OrbitProgressIndicator")
	AtmoSprite = get_node_or_null("CollisionShape2D/Sprite2D")
	AtmoSpriteOrbited = get_node_or_null("CollisionShape2D/Sprite2D/Sprite2D2")
	# This adds the planet to a group for tracking.
	add_to_group("planets")
	# This attempts to spawn a collectable when the planet is ready.
	spawn_collectable_at_center()
	# This attempts to spawn satellites around the planet
	_spawn_satellites()

func _spawn_satellites() -> void:
	# This checks if satellites are allowed on this planet type.
	if not can_have_satellites:
		return
	
	# This creates a random chance for satellites to spawn based on the spawn chance variable.
	if randf() > satellite_spawn_chance:
		return
		
	# This determines a random number of satellites to spawn within the specified range.
	var num_to_spawn = randi_range(num_satellites_min, num_satellites_max)
	
	# This loops to create each satellite.
	for i in range(num_to_spawn):
		# This creates a new satellite instance from the preloaded scene.
		var satellite = SATELLITE_SCENE.instantiate() as Satellite
		
		# This adds the satellite to the scene tree as a child of the planet.
		add_child(satellite)
		
		# This sets the center of the satellite's orbit to the planet's position.
		satellite.orbit_center = global_position
		
		# This gets the visual radius of the planet's sprite.
		var planet_visual_radius = sprite.texture.get_width() * sprite.scale.x / 2.0
		# This gets the radius of the planet's gravity field.
		var gravity_radius = collision_shape_2d.shape.radius
		
		# This sets the satellite's orbit radius to be between the planet surface and its gravity edge.
		satellite.orbit_radius = randf_range(planet_visual_radius * 1.5, gravity_radius * 0.8)
		# This sets a random orbit speed for the satellite.
		satellite.orbit_speed = randf_range(0.5, 1.5) * [-1, 1].pick_random() # This also randomizes direction

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
func update_orbit_progress(accumulated_angle: float, completion_percentage: float, start_angle: float, direction: float = 1.0):
	
	# This ensures the orbit progress indicator exists before drawing.
	if not is_instance_valid(orbit_progress_indicator):
		return

	# This makes sure the line is visible before we add points to it.
	orbit_progress_indicator.visible = true
	# This removes all previous points from the line to redraw it from scratch.
	orbit_progress_indicator.clear_points()

	# This calculates how much of the orbit to show based on the player's progress.
	var progress = accumulated_angle / (2 * PI * completion_percentage)
	# This clamps the progress value between 0 (start) and 1 (full loop).
	progress = clamp(progress, 0.0, 1.0)

	# This determines how many points to draw for a smooth arc.
	var num_points = int(progress * 64)
	# This exits if there aren't enough points to draw a line.
	if num_points < 2:
		return

	# This loop creates the points for the visual arc.
	for i in range(num_points + 1):
		# This calculates the angle for each point of the arc.
		var angle = start_angle + (float(i) / num_points) * progress * 2 * PI * completion_percentage * direction
		# This converts the angle and radius into a 2D position.
		var point = Vector2(cos(angle), sin(angle)) * orbit_radius
		# This adds the calculated point to the line.
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
	# This animates the line's color to bright white over 0.1 seconds.
	flash_tween.tween_property(orbit_progress_indicator, "default_color", Color.WHITE, 0.1)
	# This animates the line's color back to its normal cyan color.
	flash_tween.tween_property(orbit_progress_indicator, "default_color", Color(0, 1, 1, 0.8), 0.2)
	# This calls a function to hide the line after the flash is complete.
	flash_tween.tween_callback(stop_orbit_progress_display)

# This gets the radius of the gravity field for procedural generation.
func get_gravity_radius() -> float:
	# This ensures the CollisionShape2D node exists before we try to access it.
	if not is_instance_valid(collision_shape_2d):
		return 200.0 # This returns a default radius if the node isn't ready.

	# This checks if the shape assigned to the collider is a circle.
	if collision_shape_2d.shape is CircleShape2D:
		# This gets the base radius from the shape resource itself.
		var local_radius = collision_shape_2d.shape.radius
		
		# This gets the scale of the parent Area2D node (this planet).
		var planet_scale = self.scale
		
		# This calculates the true radius by multiplying the local radius by the largest scale component.
		return local_radius * max(planet_scale.x, planet_scale.y)
	else:
		# This shows a warning and returns a default value if the shape is not a circle.
		push_warning("Planet %s does not have a CircleShape2D for its gravity field." % name)
		return 200.0

# This function controls the visual feedback for orbited planets.
func SetShowOrbited(orbited : bool):
	# This checks if the atmosphere sprite for orbited planets exists.
	if is_instance_valid(AtmoSpriteOrbited):
		# This sets the visibility of the orbited indicator sprite.
		AtmoSpriteOrbited.visible = orbited
	return
