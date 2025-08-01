extends ShopItem
class_name GravityUpgradeItem

# Gravity Upgrade shop item - allows player to upgrade/downgrade gravity with +/- buttons

@export var gravity_modifier: float = 0.2  # 20% change per level
var gravity_level: int = 0  # Current gravity level (-3 to 3)

func _init():
	setup_item()
	
func setup_item():
	item_name = "Gravity Control"
	description = "Adjust gravity effects with +/- buttons"
	cost = 120  # Cost per level
	max_purchases = -1  # Unlimited for this special item
	
func apply_effect(_player: Player) -> void:
	# This method won't be used directly since we handle upgrades/downgrades separately
	pass

func upgrade_gravity(player: Player) -> bool:
	if gravity_level >= 3:
		return false
	
	if GameManager.get_score() < cost:
		return false
	
	# Deduct cost
	GameManager.add_score(-cost)
	
	# Increase gravity level
	gravity_level += 1
	
	# Apply gravity effect
	apply_gravity_change(player)
	
	print("Gravity upgraded to level %d" % gravity_level)
	return true

func downgrade_gravity(player: Player) -> bool:
	if gravity_level <= -3:
		return false

	# Refund cost
	GameManager.add_score(cost)

	# Decrease gravity level
	gravity_level -= 1

	# Apply gravity effect
	apply_gravity_change(player)

	print("Gravity downgraded to level %d" % gravity_level)
	return true

func apply_gravity_change(player: Player) -> void:
	# Add or update gravity modifier component
	var gravity_component = player.get_node_or_null("GravityModifierComponent")
	if not gravity_component:
		gravity_component = preload("res://Scripts/GravityModifierComponent.gd").new()
		gravity_component.name = "GravityModifierComponent"
		player.add_child(gravity_component)
	
	# Set gravity multiplier based on level
	# Level -3 = 0.4, Level -2 = 0.6, Level -1 = 0.8, Level 0 = 1.0 (normal), Level 1 = 1.2, Level 2 = 1.4, Level 3 = 1.6
	gravity_component.gravity_multiplier = 1.0 + (gravity_level * gravity_modifier)
	
	print("Gravity multiplier set to: %.2f" % gravity_component.gravity_multiplier)

func can_upgrade() -> bool:
	return gravity_level < 3 and GameManager.get_score() >= cost

func can_downgrade() -> bool:
	return gravity_level > -3

func get_current_level() -> int:
	return gravity_level

func get_upgrade_cost() -> int:
	return cost

func get_downgrade_refund() -> int:
	return cost
