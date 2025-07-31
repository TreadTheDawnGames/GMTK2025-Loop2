extends Node2D
class_name GameController

@onready var player: Player = $Player
@onready var hud: GameHUD = $HUDLayer/GameHUD

# Find the home planet and other planets dynamically
var home_planet: HomePlanet
var all_planets: Array[Area2D] = []

func _ready() -> void:
	# Find all planets and the home planet in the scene
	for child in get_children():
		if child is HomePlanet:
			home_planet = child
		# Check if the node is a standard planet
		if child.get_script() == load("res://Scripts/planet.gd"):
			all_planets.append(child)
			
	if not is_instance_valid(home_planet):
		print("ERROR: GameController could not find the HomePlanet node!")
		return
		
	if not is_instance_valid(hud):
		print("ERROR: GameController could not find the HUD node!")
		return

	# Set up HUD references with all the found nodes
	hud.setup_references(player, home_planet, all_planets)

	# Connect to collectable collection signals
	call_deferred("connect_collectables")

func connect_collectables() -> void:
	# Find and connect to all collectables
	var collectables = get_tree().get_nodes_in_group("collectables")
	for collectable in collectables:
		if collectable is Collectable:
			collectable.collected.connect(_on_collectable_collected)

func _on_collectable_collected(collectable: Collectable) -> void:
	# Show notification in HUD
	var info = collectable.get_collectable_info()
	hud.show_collection_notification(info["name"], info["points"])
