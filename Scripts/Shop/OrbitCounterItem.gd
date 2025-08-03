# res://Scripts/Shop/OrbitCounterItem.gd
extends ShopItem # This script inherits from the base ShopItem class.
class_name OrbitCounterItem # This assigns a class name for easier referencing.
# This function is the constructor, called when a new instance of this item is created.
func _init():
	# This sets the display name of the item in the shop UI.
	item_name = "Orbit Counter"
	# This sets the descriptive text for the item in the shop UI.
	description = "Displays your orbit progress around planets."
	# This sets the point cost for this item.
	cost = 300
	# This makes the item a single, non-repeatable purchase.
	max_purchases = 1
# This function applies the item's effect to the player character.
func apply_effect(player: Player) -> void:
	# This enables the orbit counter functionality on the player.
	player.has_orbit_counter = true
	# This prints a confirmation message to the debug console.
	print("Orbit Counter enabled!")
