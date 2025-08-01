extends ShopItem
class_name MagnetItem

# Magnet shop item - attracts collectables to the player

@export var magnet_strength: float = 500.0
@export var magnet_range: float = 200.0

func _init():
	item_name = "Magnet"
	description = "Attracts nearby collectables to your ship"
	cost = 150
	max_purchases = 3  # Can be upgraded
	
func apply_effect(player: Player) -> void:
	# Add magnet component to player if it doesn't exist
	var magnet_component = player.get_node_or_null("MagnetComponent")
	if not magnet_component:
		magnet_component = preload("res://Scripts/MagnetComponent.gd").new()
		magnet_component.name = "MagnetComponent"
		player.add_child(magnet_component)
	
	# Upgrade magnet strength and range
	magnet_component.strength += magnet_strength
	magnet_component.range += magnet_range
	
	print("Magnet upgraded! Strength: %d, Range: %d" % [magnet_component.strength, magnet_component.range])

func get_current_cost() -> int:
	# Increase cost with each purchase
	return cost + (current_purchases * 50)
