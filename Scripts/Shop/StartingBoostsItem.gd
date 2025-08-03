# res://Scripts/Shop/StartingBoostsItem.gd
extends ShopItem # This script inherits from the base ShopItem class.
class_name StartingBoostsItem # This assigns a class name for easier referencing.

@export var boost_increase: int = 1 # This sets how many boosts are granted per purchase.

# This function is the constructor, called when a new instance of this item is created.
func _init():
	# This sets the display name of the item in the shop UI.
	item_name = "Starting Boosts"
	# This sets the descriptive text for the item in the shop UI.
	description = "Start each launch with additional boost charges"
	# This sets the initial point cost for the first purchase.
	cost = 100
	# This sets the maximum number of times this item can be purchased.
	max_purchases = 3

# This function applies the item's effect to the player character.
func apply_effect(player: Player) -> void:
	# This gets the current number of starting boosts, defaulting to 3 if it hasn't been upgraded before.
	var current_starting_boosts = player.get_meta("starting_boosts", 3)
	# This calculates the new total number of starting boosts.
	var new_starting_boosts = current_starting_boosts + boost_increase
	# This stores the new starting boost count in the player's metadata for use on reset.
	player.set_meta("starting_boosts", new_starting_boosts)
	
	# This immediately grants the purchased boost to the player for the current session.
	player.BoostCount += boost_increase
	
	# This prints a confirmation message to the debug console.
	print("Starting boosts increased! Now starting with %d boosts" % new_starting_boosts)

# This function calculates the cost for subsequent purchases.
func get_current_cost() -> int:
	# The cost increases by 75 points for each time it has already been purchased.
	return cost + (current_purchases * 75)