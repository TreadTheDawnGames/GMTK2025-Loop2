extends Node2D
class_name GameController

@onready var player: Player = $Player
@onready var hud: GameHUD = $HUDLayer/GameHUD

# Find the home planet and other planets dynamically
var home_planet: HomePlanet
var all_planets: Array[Area2D] = []

# Collectable tracking for win condition
var total_collectables: int = 0
var collected_collectables: int = 0
var collectable_counts_by_type: Dictionary = {}

func _ready() -> void:
	# This searches the entire scene to find all planet nodes.
	find_planets_recursive(self)

	# This checks if the HomePlanet was successfully found.
	if not is_instance_valid(home_planet):
		print("ERROR: GameController could not find the HomePlanet node!")
		return
		
	# This checks if the HUD was successfully found.
	if not is_instance_valid(hud):
		print("ERROR: GameController could not find the HUD node!")
		return

	print("Found ", all_planets.size(), " planets in the scene")

	# This sets up the HUD with references to the player and all found planets.
	hud.setup_references(player, home_planet, all_planets)

	# This connects to the signals of all collectables in the scene.
	call_deferred("connect_collectables")
	
func find_planets_recursive(node: Node):
	# This searches recursively through all child nodes to find planets.
	for child in node.get_children():
		if child is HomePlanet:
			home_planet = child
			all_planets.append(child)  # This ensures the HomePlanet is also in the list.
		# This checks if the node is a standard planet.
		elif child is BasePlanet:
			all_planets.append(child)

		# This continues the search into the children of the current node.
		find_planets_recursive(child)
			
func connect_collectables() -> void:
	# Initialize tracking dictionaries
	collectable_counts_by_type = {
		"Star": {"collected": 0, "total": 0},
		"Satellite": {"collected": 0, "total": 0},
		"Crystal": {"collected": 0, "total": 0},
		"Energy Core": {"collected": 0, "total": 0}
	}

	# Find and connect to all collectables
	var collectables = get_tree().get_nodes_in_group("collectables")
	total_collectables = 0
	for collectable in collectables:
		if collectable is Collectable:
			collectable.collected.connect(_on_collectable_collected)
			total_collectables += 1

			# Count by type
			var type_name = collectable.collection_name
			if type_name in collectable_counts_by_type:
				collectable_counts_by_type[type_name]["total"] += 1

	print("Found ", total_collectables, " collectables in the scene")
	for type_name in collectable_counts_by_type:
		print("  ", type_name, ": ", collectable_counts_by_type[type_name]["total"])

func _on_collectable_collected(collectable: Collectable) -> void:
	# Show notification in HUD
	var info = collectable.get_collectable_info()
	hud.show_collection_notification(info["name"], info["points"])

	# Update collection count
	collected_collectables += 1

	# Update count by type
	var type_name = collectable.collection_name
	if type_name in collectable_counts_by_type:
		collectable_counts_by_type[type_name]["collected"] += 1

	# Update HUD with new counts
	hud.update_collectable_counts()

	# Check win condition
	check_win_condition()

func check_win_condition() -> void:
	if collected_collectables >= total_collectables and total_collectables > 0:
		print("All collectables collected! You win!")
		GameManager.show_win_screen()

func get_collectable_counts() -> Dictionary:
	# Return the accurately tracked counts
	return collectable_counts_by_type
