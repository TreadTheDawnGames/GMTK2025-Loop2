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
@export var point_value: int = 100
@export var collection_name: String = "Star"

# Node references
@onready var audioHandler: PlayerAudioHandler = $PlayerAudioHandler
@onready var sprite: Sprite2D = $Sprite2D
@onready var collection_area: CollisionShape2D = $CollisionShape2D
@onready var collection_particles: CPUParticles2D = $CollectionParticles

# Internal variables
var is_collected: bool = false

func _ready() -> void:
	# This adds the collectable to a group for tracking purposes.
	add_to_group("collectables")
	# This disables direct collision, as looping is the collection method.
	collection_area.set_deferred("disabled", true)
	# This ensures the sprite is visible when spawned by the planet.
	sprite.visible = true

func collect() -> void:
	if is_collected:
		return
		
	is_collected = true
	
	# This makes the sprite invisible immediately.
	sprite.visible = false
	
	# This reparents the particle effect to the root so it can finish playing.
	var particles = collection_particles
	if is_instance_valid(particles):
		particles.reparent(get_tree().root)
		particles.global_position = self.global_position
		particles.emitting = true
		var particle_lifetime = particles.lifetime + 0.5
		get_tree().create_timer(particle_lifetime).timeout.connect(particles.queue_free)

	audioHandler.PlaySoundAtGlobalPosition(Sounds.CollectableGet, global_position)
	
	# Add score
	GameManager.add_score(point_value)
	
	# Emit collected signal
	collected.emit(self)
	
	# This removes the main collectable node after its effects are detached.
	queue_free()

func get_collectable_info() -> Dictionary:
	return {
		"type": collectable_type,
		"name": collection_name,
		"points": point_value
	}
