# res://Scripts/GameController.gd
extends Node2D
class_name GameController

@onready var player: Player = $Player
@onready var hud: GameHUD = $HUDLayer/GameHUD
# Placeholder nodes where generated objects will be placed
@onready var generated_planets_node = $GeneratedPlanets
@onready var generated_nebulas_node = $GeneratedNebulas

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
@export var num_planets: int = 50
# The minimum empty space to leave between the edges of two regular planets.
@export var min_distance_between_planets: float = 1500.0
# How many planets should be clustered inside nebulas.
@export var planets_in_nebulas: int = 8

# --- Special Celestial Body Settings ---
@export_category("Special Objects")
# The scene for the Sun, which will be placed at the center.
@export var sun_scene: PackedScene = preload("res://Scenes/planet_Sol.tscn")
# The scene for the Black Hole, placed randomly.
#@export var black_hole_scene: PackedScene = preload("res://Scenes/planet_black_hole.tscn")
# The scene for additional Home Stations/Shops.
@export var station_scene: PackedScene = preload("res://Scenes/Home.tscn")
# The number of ADDITIONAL random stations to spawn (on top of the main HomeBase).
@export var num_additional_stations: int = 2
# The extra empty space required around stations to prevent them from feeling crowded.
@export var station_separation_buffer: float = 4000.0


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

# This is the main function for procedural generation.
func _generate_level():
	# This array will keep track of all placed objects to check for overlaps.
	var placed_celestial_bodies = []
	
	# This helper function will handle the placement logic for any given object.
	var place_object = func(scene: PackedScene, tracking_array: Array, pos: Vector2):
		if not is_instance_valid(scene):
			push_warning("Cannot place object: PackedScene is not valid.")
			return null

		var instance = scene.instantiate()
		var new_radius = instance.get_gravity_radius()
		
		# Check for overlaps with all previously placed bodies.
		var overlaps = false
		for existing_body in tracking_array:
			if not is_instance_valid(existing_body): continue
			
			var existing_radius = existing_body.get_gravity_radius()
			var distance = pos.distance_to(existing_body.global_position)
			
			# Determine the required buffer based on what's being placed.
			var required_buffer = min_distance_between_planets
			# Check if either the new object or the existing one is a station.
			var is_new_obj_station = instance is HomePlanet
			var is_existing_obj_station = existing_body is HomePlanet
			if is_new_obj_station or is_existing_obj_station:
				required_buffer = station_separation_buffer

			# If the distance is less than the sum of both radii plus our required buffer, it overlaps.
			if distance < new_radius + existing_radius + required_buffer:
				overlaps = true
				break
		
		# If the position is valid (no overlaps), place the object.
		if not overlaps:
			instance.global_position = pos
			generated_planets_node.add_child(instance)
			tracking_array.append(instance)
			return instance
		else:
			# If the position was invalid, free the unused instance.
			instance.queue_free()
			return null

	# --- Step 1: Place Stations Evenly Across the Map ---
	var total_stations = 1 + num_additional_stations
	var angle_per_sector = TAU / total_stations # TAU is 360 degrees in radians.
	
	for i in range(total_stations):
		var station_placed = false
		for attempt in range(20): # Try multiple times to place a station in its sector.
			# Calculate the angle range for the current "slice" of the map.
			var sector_start_angle = i * angle_per_sector
			var sector_end_angle = (i + 1) * angle_per_sector
			
			# Pick a random angle and distance within this sector.
			# Stations are placed in the outer half of the map to feel like outposts.
			var random_angle = randf_range(sector_start_angle, sector_end_angle)
			var random_radius = randf_range(spawn_radius * 0.5, spawn_radius * 0.9)
			var station_pos = Vector2.from_angle(random_angle) * random_radius

			var station_instance = place_object.call(station_scene, placed_celestial_bodies, station_pos)

			if is_instance_valid(station_instance):
				# If this is the first station being placed, it's the player's home base.
				if not is_instance_valid(self.home_planet):
					self.home_planet = station_instance
					# Move the player to start next to this newly placed station.
					player.global_position = home_planet.global_position + Vector2(0, -250)
					# This tells the player that this station is its new "home" for the lose condition.
					player.set_origin_point(home_planet.global_position)
				
				station_placed = true
				break # Move to the next sector.
		
		if not station_placed:
			print("Could not place a station in sector %d after 20 attempts." % i)

	# --- Step 2: Place the Sun at the Center ---
	if is_instance_valid(sun_scene):
		var sun = sun_scene.instantiate()
		sun.global_position = Vector2.ZERO
		generated_planets_node.add_child(sun)
		placed_celestial_bodies.append(sun)

	## --- Step 3: Place the Black Hole Randomly ---
	#if is_instance_valid(black_hole_scene):
		#for attempt in range(50):
			#var pos = Vector2.from_angle(randf() * TAU) * randf_range(spawn_radius * 0.1, spawn_radius)
			#if is_instance_valid(place_object.call(black_hole_scene, placed_celestial_bodies, pos)):
				#break

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
			for attempt in range(20):
				var planet_scene = planet_scenes.pick_random()
				var spawn_center = Vector2.ZERO
				if i < planets_in_nebulas and not spawned_nebulas.is_empty():
					spawn_center = spawned_nebulas.pick_random().global_position
				
				var pos = spawn_center + Vector2.from_angle(randf() * TAU) * randf_range(0, spawn_radius / 2 if spawn_center != Vector2.ZERO else spawn_radius)
				if is_instance_valid(place_object.call(planet_scene, placed_celestial_bodies, pos)):
					break


func find_planets_recursive(node: Node):
	# This searches recursively through all child nodes to find planets.
	for child in node.get_children():
		# This checks if the node is a standard planet or a home planet.
		if child is BasePlanet:
			all_planets.append(child)

		# This continues the search into the children of the current node.
		if child.get_child_count() > 0:
			find_planets_recursive(child)

func connect_collectables() -> void:
	collectable_counts_by_type.clear()
	total_collectables = 0
	var collectables = get_tree().get_nodes_in_group("collectables")
	
	for collectable in collectables:
		if collectable is Collectable:
			collectable.collected.connect(_on_collectable_collected)
			total_collectables += 1
			var type_name = collectable.collection_name
			if not collectable_counts_by_type.has(type_name):
				collectable_counts_by_type[type_name] = {"collected": 0, "total": 0}
			collectable_counts_by_type[type_name]["total"] += 1

	print("Found ", total_collectables, " total collectables across ", collectable_counts_by_type.size(), " types.")
	hud.update_collectable_counts()

func _on_collectable_collected(collectable: Collectable) -> void:
	var info = collectable.get_collectable_info()
	hud.show_collection_notification(info["name"], info["points"])
	collected_collectables += 1
	var type_name = collectable.collection_name
	if collectable_counts_by_type.has(type_name):
		collectable_counts_by_type[type_name]["collected"] += 1
	else:
		print("Warning: Collected an untracked collectable type: ", type_name)
	hud.update_collectable_counts()
	GameManager.notify_collectable_collected()
	check_win_condition()

func check_win_condition() -> void:
	if collected_collectables >= total_collectables and total_collectables > 0:
		print("All collectables collected! Mission Complete!")
		start_victory_sequence()

func get_collectable_counts() -> Dictionary:
	return collectable_counts_by_type

func start_victory_sequence():
	if victory_sequence_active:
		return
	victory_sequence_active = true
	MusicManager.play_audio_omni("UpUIBeep")
	calculate_victory_stats()
	Engine.time_scale = 0.2
	if player:
		player.apply_boost_trail_effect()
	if hud:
		TutorialManager.show_tutorial_once("victory_lap", "🎉 VICTORY LAP! All collectables found!", hud)
	await get_tree().create_timer(3.0).timeout
	Engine.time_scale = 1.0
	GameManager.show_win_screen_with_stats(victory_stats)

func calculate_victory_stats():
	victory_stats = {
		"final_score": GameManager.get_score(),
		"total_collectables": total_collectables,
		"planets_visited": count_visited_planets(),
		"boosts_used": calculate_boosts_used(),
		"completion_time": get_completion_time()
	}

func count_visited_planets() -> int:
	var visited_count = 0
	for planet in all_planets:
		if planet.has_method("was_visited") and planet.was_visited():
			visited_count += 1
	return visited_count

func calculate_boosts_used() -> int:
	var starting_boosts = 1
	if player and player.has_meta("starting_boosts"):
		starting_boosts = player.get_meta("starting_boosts")
	var current_boosts = player.BoostCount if player else 0
	var boosts_earned = collected_collectables
	return starting_boosts + boosts_earned - current_boosts

func get_completion_time() -> String:
	return "Unknown"
