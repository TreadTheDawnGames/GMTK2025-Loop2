# res://Scripts/GameController.gd
extends Node2D
class_name GameController

@onready var player: Player = $Player
@onready var hud: GameHUD = $HUDLayer/GameHUD
# Placeholder nodes where generated objects will be placed
@onready var generated_planets_node = $GeneratedPlanets
@onready var generated_nebulas_node = $GeneratedNebulas
# Reference to the static, starting HomeBase.
@onready var home_base_node: HomePlanet = $HomeBase

# This holds a reference to the home planet.
var home_planet: HomePlanet
# This holds references to all planets in the scene (static and generated).
var all_planets: Array[Area2D] = []

# This tracks collectables for the win condition.
var total_collectables: int = 0
var collected_collectables: int = 0
var collectable_counts_by_type: Dictionary = {}

# This tracks victory sequence stats and state.
var victory_stats: Dictionary = {}
var victory_sequence_active: bool = false

# --- Procedural Generation Settings ---
@export_category("Level Generation")
# The scenes for planets that can be randomly spawned.
@export var planet_scenes: Array[PackedScene] = [
	preload("res://Scenes/planet_small.tscn"),
	preload("res://Scenes/planet_medium.tscn"),
	preload("res://Scenes/planet_large.tscn")
]
# The scene for the nebula visual effect.
@export var nebula_scene: PackedScene = preload("res://Scenes/Planets/Nebula.tscn")
# The maximum radius from the center (0,0) where planets can spawn.
@export var spawn_radius: float = 30000.0
# The number of nebulas to spawn.
@export var num_nebulas: int = 8
# The number of planets to spawn.
@export var num_planets: int = 500
# The minimum empty space to leave between the edges of two planets' gravity fields.
@export var min_distance_between_planets: float = 2200.0
# How many planets should be clustered inside nebulas.
@export var planets_in_nebulas: int = 8

# --- NEW: Special Celestial Body Settings ---
@export_category("Special Objects")
# The scene for the Sun, which will be placed at the center.
@export var sun_scene: PackedScene = preload("res://Scenes/planet_Sol.tscn")
# The scene for the Black Hole, placed randomly.
@export var black_hole_scene: PackedScene = preload("res://Scenes/planet_black_hole.tscn")
# The scene for additional Home Stations/Shops.
@export var station_scene: PackedScene = preload("res://Scenes/Home.tscn")
# The number of ADDITIONAL random stations to spawn (on top of the main HomeBase).
@export var num_additional_stations: int = 2


func _ready() -> void:
	# Generate the random level layout.
	_generate_level()
	
	# Search the entire scene to find all planet nodes (including newly spawned ones).
	find_planets_recursive(self)

	# Check if the HomePlanet was successfully found.
	if not is_instance_valid(home_planet):
		print("ERROR: GameController could not find the HomePlanet node!")
		return
		
	# Check if the HUD was successfully found.
	if not is_instance_valid(hud):
		print("ERROR: GameController could not find the HUD node!")
		return

	print("Found ", all_planets.size(), " planets in the scene")

	# Set up the HUD with references to the player and all found planets.
	hud.setup_references(player, home_planet, all_planets)

	# Connect to the signals of all collectables in the scene after a short delay.
	call_deferred("connect_collectables")

# REWORKED FUNCTION: This now places special objects first, then fills in the rest.
func _generate_level():
	# This array will keep track of all placed objects to check for overlaps.
	var placed_celestial_bodies = [home_base_node]
	
	# This helper function will handle the placement logic for any given object.
	# It tries to find a valid spot and adds the object to the scene and tracking array.
	var place_object = func(scene: PackedScene, tracking_array: Array, spawn_center: Vector2 = Vector2.ZERO, radius: float = spawn_radius):
		if not is_instance_valid(scene):
			push_warning("Cannot place object: PackedScene is not valid.")
			return

		for attempt in range(50): # Try up to 50 times to find a valid spot.
			var instance = scene.instantiate()
			
			# Get a random position for the object within the specified radius.
			var pos = spawn_center + Vector2.from_angle(randf() * TAU) * randf_range(radius * 0.1, radius)

			# Get the final, scaled radius of the new object's gravity field.
			var new_radius = instance.get_gravity_radius()
			
			# Check for overlaps with all previously placed bodies.
			var overlaps = false
			for existing_body in tracking_array:
				if not is_instance_valid(existing_body): continue
				var existing_radius = existing_body.get_gravity_radius()
				var distance = pos.distance_to(existing_body.global_position)
				
				# If the distance is less than the sum of both radii plus our minimum gap, it overlaps.
				if distance < new_radius + existing_radius + min_distance_between_planets:
					overlaps = true
					break
			
			# If the position is valid (no overlaps), place the object.
			if not overlaps:
				instance.global_position = pos
				generated_planets_node.add_child(instance)
				tracking_array.append(instance)
				return # Successfully placed, exit the function.
			else:
				# If the position was invalid, free the unused instance.
				instance.queue_free()
		
		push_warning("Could not place a %s after 50 attempts." % scene.resource_path)

	# --- Step 1: Place the Sun at the Center ---
	if is_instance_valid(sun_scene):
		var sun = sun_scene.instantiate()
		sun.global_position = Vector2.ZERO # Place it exactly at the center.
		generated_planets_node.add_child(sun)
		placed_celestial_bodies.append(sun)

	# --- Step 2: Place the Black Hole Randomly ---
	if is_instance_valid(black_hole_scene):
		place_object.call(black_hole_scene, placed_celestial_bodies, Vector2.ZERO, spawn_radius)

	# --- Step 3: Place Additional Home Stations ---
	if is_instance_valid(station_scene):
		for i in range(num_additional_stations):
			place_object.call(station_scene, placed_celestial_bodies, Vector2.ZERO, spawn_radius)

	# --- Step 4: Spawn Nebulas (visuals for clusters) ---
	var spawned_nebulas = []
	if is_instance_valid(nebula_scene) and is_instance_valid(generated_nebulas_node):
		for i in range(num_nebulas):
			var nebula = nebula_scene.instantiate()
			var nebula_pos = Vector2.from_angle(randf() * TAU) * randf_range(0, spawn_radius * 0.75)
			nebula.global_position = nebula_pos
			generated_nebulas_node.add_child(nebula)
			spawned_nebulas.append(nebula)
	
	# --- Step 5: Fill the rest of the space with Regular Planets ---
	if not planet_scenes.is_empty():
		var planets_to_spawn = num_planets
		for i in range(planets_to_spawn):
			var planet_scene = planet_scenes.pick_random()
			# Determine if this planet should be in a nebula.
			var spawn_center = Vector2.ZERO
			if i < planets_in_nebulas and not spawned_nebulas.is_empty():
				spawn_center = spawned_nebulas.pick_random().global_position
			
			place_object.call(planet_scene, placed_celestial_bodies, spawn_center, spawn_radius / 2 if spawn_center != Vector2.ZERO else spawn_radius)


func find_planets_recursive(node: Node):
	# This searches recursively through all child nodes to find planets.
	for child in node.get_children():
		if child is HomePlanet:
			# The first HomePlanet found will be set as the main one for the HUD.
			if not is_instance_valid(home_planet):
				home_planet = child
			# This ensures all HomePlanets are in the main planets list for the compass.
			all_planets.append(child)
		# This checks if the node is a standard planet.
		elif child is BasePlanet:
			all_planets.append(child)

		# This continues the search into the children of the current node.
		if child.get_child_count() > 0:
			find_planets_recursive(child)

# ... (The rest of the script remains the same) ...

func connect_collectables() -> void:
	# This initializes the dictionary to store counts for each collectable type.
	collectable_counts_by_type.clear()
	total_collectables = 0

	# This finds all nodes in the "collectables" group.
	var collectables = get_tree().get_nodes_in_group("collectables")
	
	for collectable in collectables:
		if collectable is Collectable:
			# This connects this script to the 'collected' signal of each collectable.
			collectable.collected.connect(_on_collectable_collected)
			total_collectables += 1

			# This gets the name of the collectable type, e.g., "Star", "Crystal".
			var type_name = collectable.collection_name
			
			# This checks if this type is already being tracked.
			if not collectable_counts_by_type.has(type_name):
				# This adds a new entry for this type if it's the first one found.
				collectable_counts_by_type[type_name] = {"collected": 0, "total": 0}
			
			# This increments the total count for this specific type.
			collectable_counts_by_type[type_name]["total"] += 1

	print("Found ", total_collectables, " total collectables across ", collectable_counts_by_type.size(), " types.")
	# This updates the HUD with the initial totals right after counting.
	hud.update_collectable_counts()

func _on_collectable_collected(collectable: Collectable) -> void:
	# This shows a notification on the HUD.
	var info = collectable.get_collectable_info()
	hud.show_collection_notification(info["name"], info["points"])

	# This updates the master count of collected items.
	collected_collectables += 1

	# This updates the count for the specific type that was collected.
	var type_name = collectable.collection_name
	if collectable_counts_by_type.has(type_name):
		collectable_counts_by_type[type_name]["collected"] += 1
	else:
		# This is a fallback in case a type wasn't registered.
		print("Warning: Collected an untracked collectable type: ", type_name)

	# This tells the HUD to refresh its display with the new numbers.
	hud.update_collectable_counts()

	# This notifies the GameManager that a collectable was collected for UI effects.
	GameManager.notify_collectable_collected()

	# This checks if all collectables have been found to trigger the win condition.
	check_win_condition()

func check_win_condition() -> void:
	if collected_collectables >= total_collectables and total_collectables > 0:
		print("All collectables collected! Mission Complete!")
		start_victory_sequence()

func get_collectable_counts() -> Dictionary:
	# This returns the accurately tracked counts by type.
	return collectable_counts_by_type

# This starts the victory sequence with slow motion and enhanced effects.
func start_victory_sequence():
	if victory_sequence_active:
		return

	victory_sequence_active = true

	# This plays a victory sound.
	MusicManager.play_audio_omni("UpUIBeep")

	# This calculates final victory stats.
	calculate_victory_stats()

	# This starts a slow motion effect.
	Engine.time_scale = 0.2

	# This enhances the player's trail effects for a victory lap.
	if player:
		player.apply_boost_trail_effect()

	# This shows a victory message on the HUD.
	if hud:
		TutorialManager.show_tutorial_once("victory_lap", "🎉 VICTORY LAP! All collectables found!", hud)

	# This waits for the victory lap duration then shows the win screen.
	await get_tree().create_timer(3.0).timeout

	# This restores normal time.
	Engine.time_scale = 1.0

	# This shows an enhanced win screen with stats.
	GameManager.show_win_screen_with_stats(victory_stats)

# This calculates the final victory statistics.
func calculate_victory_stats():
	victory_stats = {
		"final_score": GameManager.get_score(),
		"total_collectables": total_collectables,
		"planets_visited": count_visited_planets(),
		"boosts_used": calculate_boosts_used(),
		"completion_time": get_completion_time()
	}

# This counts how many planets the player visited.
func count_visited_planets() -> int:
	var visited_count = 0
	for planet in all_planets:
		if planet.has_method("was_visited") and planet.was_visited():
			visited_count += 1
	return visited_count

# This calculates the total boosts used during the game.
func calculate_boosts_used() -> int:
	# This estimates boosts used based on starting boosts vs current boosts.
	var starting_boosts = 1
	if player and player.has_meta("starting_boosts"):
		starting_boosts = player.get_meta("starting_boosts")

	var current_boosts = player.BoostCount if player else 0
	var boosts_earned = collected_collectables # Each collectable gives 1 boost

	return starting_boosts + boosts_earned - current_boosts

# This gets the approximate completion time.
func get_completion_time() -> String:
	# This is a placeholder for actual time tracking.
	return "Unknown"
