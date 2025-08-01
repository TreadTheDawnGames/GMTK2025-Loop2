extends ShopItem
class_name GravityModifierItem

# Gravity Modifier shop item - allows player to increase or decrease gravity effects

enum GravityType {
	INCREASE,
	DECREASE
}

@export var gravity_type: GravityType = GravityType.INCREASE
@export var gravity_modifier: float = 0.2  # 20% change per purchase

func _init():
	setup_item()

func setup_item():
	max_purchases = 3  # Can be upgraded multiple times

	if gravity_type == GravityType.INCREASE:
		item_name = "Gravity +"
		description = "Increase gravity effects for tighter orbits"
		cost = 120
	else:
		item_name = "Gravity -"
		description = "Decrease gravity effects for easier navigation"
		cost = 120

func apply_effect(player: Player) -> void:
	# Add or update gravity modifier component
	var gravity_component = player.get_node_or_null("GravityModifierComponent")
	if not gravity_component:
		gravity_component = preload("res://Scripts/GravityModifierComponent.gd").new()
		gravity_component.name = "GravityModifierComponent"
		player.add_child(gravity_component)

	# Apply gravity modification
	if gravity_type == GravityType.INCREASE:
		gravity_component.gravity_multiplier += gravity_modifier
	else:
		gravity_component.gravity_multiplier -= gravity_modifier

	# Ensure multiplier doesn't go below a minimum value
	gravity_component.gravity_multiplier = max(gravity_component.gravity_multiplier, 0.1)

	var effect_text = "increased" if gravity_type == GravityType.INCREASE else "decreased"
	print("Gravity %s! Multiplier: %.2f" % [effect_text, gravity_component.gravity_multiplier])

func get_current_cost() -> int:
	# Increase cost with each purchase
	return cost + (current_purchases * 60)
