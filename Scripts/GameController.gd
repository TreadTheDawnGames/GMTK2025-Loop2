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
