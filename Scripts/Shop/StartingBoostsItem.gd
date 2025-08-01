extends ShopItem
class_name StartingBoostsItem

# Starting Boosts shop item - increases the number of boosts the player starts with

@export var boost_increase: int = 1

func _init():
	item_name = "Starting Boosts"
	description = "Start each launch with additional boost charges"
	cost = 100
	max_purchases = 5  # Can be upgraded multiple times
	
func apply_effect(player: Player) -> void:
	# Increase the player's starting boost count
	player.BoostCount += boost_increase
	
	# Also add a property to track starting boosts for respawn
	if not player.has_meta("starting_boosts"):
		player.set_meta("starting_boosts", 1)
	
	var starting_boosts = player.get_meta("starting_boosts") + boost_increase
	player.set_meta("starting_boosts", starting_boosts)
	
	print("Starting boosts increased! Now starting with %d boosts" % starting_boosts)

func get_current_cost() -> int:
	# Increase cost with each purchase
	return cost + (current_purchases * 75)
