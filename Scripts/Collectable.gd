extends Area2D
class_name Collectable

# Collectable types enum
enum CollectableType {
	STAR,
	SATELLITE,
	CRYSTAL,
	ENERGY_CORE,
	METEOR_FRAGMENT
}

# Signals
signal collected(collectable: Collectable)

# Export variables
@export var collectable_type: CollectableType = CollectableType.STAR
@export var point_value: int = 10
@export var orbit_radius: float = 150.0
@export var orbit_speed: float = 1.0
@export var collection_name: String = "Star"

# Value degradation system
@export var value_degradation_interval: float = 1.0  # Time in seconds between value reductions
@export var value_degradation_amount: int = 1  # Amount to reduce value by each interval
@export var minimum_value: int = 1  # Minimum value the collectable can have

# Internal variables
var orbit_center: Vector2
var orbit_angle: float = 0.0
var is_collected: bool = false
var planet_reference: Area2D

# Value degradation variables
var original_point_value: int
var degradation_timer: float = 0.0

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collection_area: CollisionShape2D = $CollisionShape2D
@onready var collection_particles: CPUParticles2D = $CollectionParticles

func _ready() -> void:
	# Add to collectables group
	add_to_group("collectables")

	# Connect to body entered signal for collection detection
	body_entered.connect(_on_body_entered)

	# Set up collection particles but don't emit yet
	if collection_particles:
		collection_particles.emitting = false
		setup_collection_particles()

	#orbit planet gets set externally now.
	# Find the nearest planet to orbit around
	#find_orbit_planet()

	# Store original point value for degradation system
	original_point_value = point_value

	# Set random starting angle
	orbit_angle = randf() * 2 * PI

func _physics_process(delta: float) -> void:
	if is_collected or not planet_reference:
		return

	# Update value degradation timer
	degradation_timer += delta
	if degradation_timer >= value_degradation_interval:
		degradation_timer = 0.0
		degrade_value()

	# Update orbit position
	orbit_angle += orbit_speed * delta
	if orbit_angle > 2 * PI:
		orbit_angle -= 2 * PI

	# Calculate new position based on orbit
	var orbit_offset = Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
	global_position = orbit_center + orbit_offset

	# Rotate the sprite for visual effect
	sprite.rotation += orbit_speed * delta * 0.5

func find_orbit_planet(overridePlanet : BasePlanet = null) -> void:
	if(overridePlanet):
		planet_reference = overridePlanet
		orbit_center = overridePlanet.global_position
		return
	# Find the closest planet to orbit around
	var planets = get_tree().get_nodes_in_group("planets")
	if planets.is_empty():
		# Fallback: find any BasePlanet in the scene
		planets = find_all_planets(get_tree().current_scene)

	if planets.is_empty():
		print("Warning: No planets found for collectable to orbit!")
		return

	var closest_planet : BasePlanet = null
	var closest_distance = INF

	for planet in planets:
		var distance = global_position.distance_to(planet.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_planet = planet

	if closest_planet:
		planet_reference = closest_planet
		orbit_center = closest_planet.global_position
		# Removed for dynamic spawning.
		
		# Adjust orbit radius based on distance to planet
		#var distance_to_planet = global_position.distance_to(orbit_center)
		#if distance_to_planet > 50:  # If we're far from the planet, use that distance 
			#orbit_radius = distance_to_planet

func find_all_planets(node: Node) -> Array:
	var planets = []
	if node is BasePlanet:
		planets.append(node)
	for child in node.get_children():
		planets.append_array(find_all_planets(child))
	return planets

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
		
	if body is Player:
		collect()

func collect() -> void:
	if is_collected:
		return
		
	is_collected = true
	
	# Play collection particles
	if collection_particles:
		collection_particles.emitting = true
	
	# Add score
	GameManager.add_score(point_value)
	
	# Emit collected signal
	collected.emit(self)
	
	# Hide the sprite and collision
	sprite.visible = false
	collection_area.set_deferred("disabled", true)
	
	# Wait for particles to finish, then remove
	await get_tree().create_timer(1.0).timeout
	queue_free()

func setup_collection_particles() -> void:
	if not collection_particles:
		return
		
	# Configure particles based on collectable type
	match collectable_type:
		CollectableType.STAR:
			collection_particles.texture = load("res://Assets/kenney_simple-space/PNG/Default/star_small.png")
			collection_particles.amount = 20
			collection_particles.color = Color.YELLOW
		CollectableType.SATELLITE:
			collection_particles.amount = 15
			collection_particles.color = Color.CYAN
		CollectableType.CRYSTAL:
			collection_particles.amount = 25
			collection_particles.color = Color.MAGENTA
		CollectableType.ENERGY_CORE:
			collection_particles.amount = 30
			collection_particles.color = Color.GREEN
		CollectableType.METEOR_FRAGMENT:
			collection_particles.amount = 10
			collection_particles.color = Color.ORANGE
	
	# Common particle settings
	collection_particles.lifetime = 0.5
	collection_particles.explosiveness = 1.0
	collection_particles.direction = Vector2(0, -1)
	collection_particles.initial_velocity_min = 50.0
	collection_particles.initial_velocity_max = 100.0
	collection_particles.gravity = Vector2(0, 98)
	collection_particles.scale_amount_min = 0.5
	collection_particles.scale_amount_max = 1.5

func degrade_value() -> void:
	# Reduce the point value over time, but don't go below minimum
	if point_value > minimum_value:
		point_value = max(point_value - value_degradation_amount, minimum_value)

func get_collectable_info() -> Dictionary:
	return {
		"type": collectable_type,
		"name": collection_name,
		"points": point_value
	}
