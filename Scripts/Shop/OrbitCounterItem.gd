# res://Scripts/Shop/OrbitCounterItem.gd
extends ShopItem # This script inherits from the base ShopItem class.
class_name OrbitCounterItem # This assigns a class name for easier referencing.

# This function is the constructor, called when a new instance of this item is created.
func _init():
	# This sets the display name of the item in the shop UI.
	item_name = "Orbital Efficiency"
	# This sets the descriptive text for the item in the shop UI.
	description = "Reduces the required orbit completion by 10%."
	# This sets the initial point cost for the first purchase.
	cost = 500
	# This allows the item to be purchased up to 4 times.
	max_purchases = 4

# This function applies the item's effect to the player character.
func apply_effect(player: Player) -> void:
	# This reduces the player's orbit completion percentage, clamped to a minimum of 50%.
	player.orbit_completion_percentage = clamp(player.orbit_completion_percentage - 0.10, 0.5, 1.0)
	# This prints a confirmation message to the debug console.
	print("Orbital Efficiency upgraded! New completion percentage: %s" % str(player.orbit_completion_percentage * 100) + "%")

# This function calculates the cost for subsequent purchases.
func get_current_cost() -> int:
	# The cost increases by 250 points for each time it has already been purchased.
	return cost + (current_purchases * 250)

# This function gets the display text for the purchase button, showing the upgrade level.
func get_purchase_text() -> String:
	if current_purchases >= max_purchases:
		return "MAXED OUT"
	else:
		return "UPGRADE (%d/%d)" % [current_purchases, max_purchases]
