extends Node
class_name MagnetComponent

# Component that attracts collectables to the player

var strength: float = 0.0
var range: float = 0.0
var player: Player

func _ready():
	player = get_parent() as Player
	if not player:
		push_error("MagnetComponent must be a child of Player")
		return

func _physics_process(_delta):
	if not player or strength <= 0:
		return

	# Find all collectables in range
	var collectables = get_tree().get_nodes_in_group("collectables")

	for collectable in collectables:
		if not is_instance_valid(collectable):
			continue

		var distance = player.global_position.distance_to(collectable.global_position)

		if distance <= range and distance > 0:
			# Calculate attraction force
			var direction = (player.global_position - collectable.global_position).normalized()
			var force_strength = strength * (range - distance) / range

			# Apply force to collectable - try different methods
			if collectable.has_method("apply_central_force"):
				collectable.apply_central_force(direction * force_strength)
			elif collectable.has_method("apply_impulse"):
				collectable.apply_impulse(direction * force_strength * _delta)
			elif collectable.has_method("set_global_position"):
				# For non-physics collectables, move them directly
				var move_amount = direction * force_strength * _delta * 0.01
				collectable.global_position += move_amount
