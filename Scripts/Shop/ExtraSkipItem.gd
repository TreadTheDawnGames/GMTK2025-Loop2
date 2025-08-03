# res://Scripts/Shop/ExtraSkipItem.gd
extends ShopItem # This script inherits from the base ShopItem class.
class_name ExtraSkipItem # This assigns a class name for easier referencing.

# This function is the constructor, called when a new instance of this item is created.
func _init():
	# This sets the display name of the item in the shop UI.
	item_name = "Extra Skip"
	# This sets the descriptive text for the item in the shop UI.
	description = "Allows an additional planet skip."
	# This sets the initial point cost for the first purchase of this item.
	cost = 250
	# This sets the maximum number of times this item can be purchased.
	max_purchases = 3

# This function applies the item's effect to the player character.
func apply_effect(player: Player) -> void:
	# This increases the player's maximum number of available skips per orbit.
	player.max_skips_per_orbit += 1
	# This prints a confirmation message to the debug console.
	print("Max skips increased to: %d" % player.max_skips_per_orbit)

# This function calculates the cost for subsequent purchases.
func get_current_cost() -> int:
	# The cost increases by 150 points for each time it has already been purchased.
	return cost + (current_purchases * 150)
