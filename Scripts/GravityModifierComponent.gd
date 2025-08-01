extends Node
class_name GravityModifierComponent

# Component that modifies gravity effects on the player

var gravity_multiplier: float = 1.0
var player: Player

func _ready():
	player = get_parent() as Player
	if not player:
		push_error("GravityModifierComponent must be a child of Player")
		return

# This function will be called by planets when applying gravity
func modify_gravity_force(original_force: Vector2) -> Vector2:
	return original_force * gravity_multiplier
