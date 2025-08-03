# res://Scripts/Satellite.gd
extends Area2D
class_name Satellite

# This signal is emitted when the satellite is hit
signal hit

# This holds a reference to the particles that emit when the satellite is destroyed
@onready var explosion_particles: CPUParticles2D = $ExplosionParticles
# This holds a reference to the audio handler for playing sounds
@onready var audio_handler: PlayerAudioHandler = $PlayerAudioHandler

# This exports a speed threshold. If the player's speed is above this, the satellite explodes.
@export var destruction_speed_threshold: float = 600.0

# These variables control the satellite's orbit
var orbit_center: Vector2 = Vector2.ZERO
var orbit_radius: float = 200.0
var orbit_speed: float = 1.0
var current_angle: float = 0.0

# This function is called once when the node enters the scene tree
func _ready() -> void:
	# This connects the body_entered signal to the _on_body_entered function
	body_entered.connect(_on_body_entered)
	# This sets a random starting angle for the orbit to make satellites look different
	current_angle = randf_range(0, TAU)

# This function is called every physics frame
func _physics_process(delta: float) -> void:
	# This updates the satellite's angle based on its speed and the time passed
	current_angle += orbit_speed * delta
	# This calculates the new position based on the orbit center, radius, and new angle
	global_position = orbit_center + Vector2.RIGHT.rotated(current_angle) * orbit_radius
	
	# This makes the satellite always face towards the planet it's orbiting.
	look_at(orbit_center)
	# This adds a 90-degree rotation offset because the satellite sprite's "forward" is its top (up), not its right side.
	rotation += PI / 2

# This function is called when another physics body enters the satellite's area
func _on_body_entered(body: Node2D) -> void:
	# This checks if the body that entered is the player
	if body is Player:
		# This gets the player's current speed.
		var player_speed = body.linear_velocity.length()
		
		# This checks if the player's speed is greater than the destruction threshold.
		if player_speed > destruction_speed_threshold:
			# This calls the function to handle the satellite's destruction if the player is moving fast.
			on_hit()
		else:
			# This handles the bounce logic if the player is moving slowly.
			on_bounce(body)

# This function handles the bounce logic for slow collisions.
func on_bounce(player: Player) -> void:
	# This calculates the collision normal (the direction from the satellite's center to the player's center).
	var collision_normal = (player.global_position - global_position).normalized()
	
	# This reflects the player's velocity off the collision normal to create a bounce effect.
	player.linear_velocity = player.linear_velocity.bounce(collision_normal)
	
	# This applies a small impulse to push the player away, preventing them from getting stuck.
	player.apply_central_impulse(collision_normal * 200)
	
	# This plays a collision sound for the bounce.
	audio_handler.PlaySoundAtGlobalPosition(Sounds.ShipCollide, global_position)

# This function handles the logic for when the satellite is destroyed.
func on_hit() -> void:
	# This adds 3 points to the player's score
	GameManager.add_score(3)
	# This displays the number "3" at the satellite's position to give visual feedback
	PointNumbers.display_number(3, global_position, 0)
	
	# This plays a collision sound at the satellite's current location
	audio_handler.PlaySoundAtGlobalPosition(Sounds.ShipCollide, global_position)
	
	# This makes the explosion particles emit
	if is_instance_valid(explosion_particles):
		# This moves the particle emitter out of the satellite node
		explosion_particles.reparent(get_tree().root)
		# This ensures particles are emitted at the correct world position
		explosion_particles.global_position = self.global_position
		# This starts the particle emission
		explosion_particles.emitting = true
		# This creates a timer to free the particle node after it has finished emitting
		get_tree().create_timer(explosion_particles.lifetime + 0.5).timeout.connect(explosion_particles.queue_free)

	# This emits the hit signal
	hit.emit()
	# This removes the satellite from the game
	queue_free()
