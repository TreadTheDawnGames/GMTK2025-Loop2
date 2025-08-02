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
@export var spawn_radius: float = 10000.0
# The number of nebulas to spawn.
@export var num_nebulas: int = 4
# The number of planets to spawn.
@export var num_planets: int = 15
# The minimum empty space to leave between the edges of two planets' gravity fields.
@export var min_distance_between_planets: float = 500.0
# How many planets should be clustered inside nebulas.
@export var planets_in_nebulas: int = 8


func _ready() -> void:
	# This generates the random level layout.
	#_generate_level()
	
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

	# This connects to the signals of all collectables in the scene after a short delay.
	call_deferred("connect_collectables")

# This is the main function for procedural generation.
func _generate_level():
	# This holds a list of planets that have been successfully placed.
	var spawned_planets = []
	# This holds a list of nebulas that have been placed.
	var spawned_nebulas = []

	# --- Step 1: Spawn Nebulas (visuals for clusters) ---
	if is_instance_valid(nebula_scene) and is_instance_valid(generated_nebulas_node):
		for i in range(num_nebulas):
			var nebula = nebula_scene.instantiate()
			# Place the nebula at a random position within 75% of the spawn radius
			var nebula_pos = Vector2.from_angle(randf() * TAU) * randf_range(0, spawn_radius * 0.75)
			nebula.global_position = nebula_pos
			generated_nebulas_node.add_child(nebula)
			spawned_nebulas.append(nebula)
	
	# --- Step 2: Spawn Planets ---
	if planet_scenes.is_empty() or not is_instance_valid(generated_planets_node):
		push_warning("Planet scenes array is empty or GeneratedPlanets node is missing. Cannot generate level.")
		return
		
	# This loop tries to place the specified number of planets.
	var planets_to_spawn = num_planets
	for i in range(planets_to_spawn):
		# We'll try to place each planet a few times before giving up.
		var placement_success = false
		for attempt in range(20): # Try up to 20 times to find a valid spot.
			# Pick a random planet scene from the list.
			var planet_scene = planet_scenes.pick_random()
			var planet_instance = planet_scene.instantiate()
			
			# Determine the spawn center point. Some planets will cluster in nebulas.
			var spawn_center = Vector2.ZERO
			if i < planets_in_nebulas and not spawned_nebulas.is_empty():
				# Pick a random nebula to spawn inside of.
				var target_nebula = spawned_nebulas.pick_random()
				spawn_center = target_nebula.global_position
			
			# Get a random position for the planet.
			# It's a random direction (angle) multiplied by a random distance.
			var pos = spawn_center + Vector2.from_angle(randf() * TAU) * randf_range(0, spawn_radius / 2 if spawn_center != Vector2.ZERO else spawn_radius)

			# Get the radius of the new planet's gravity field.
			var new_planet_radius = planet_instance.get_node("CollisionShape2D").shape.radius
			
			# Check for collisions with already spawned planets.
			var overlaps = false
			for existing_planet in spawned_planets:
				var existing_radius = existing_planet.get_node("CollisionShape2D").shape.radius
				var distance = pos.distance_to(existing_planet.global_position)
				
				# If the distance is less than the sum of both radii plus a minimum gap, it overlaps.
				if distance < new_planet_radius + existing_radius + min_distance_between_planets:
					overlaps = true
					break # No need to check other planets, we already found a collision.
			
			# If the position is valid (no overlaps), place the planet.
			if not overlaps:
				planet_instance.global_position = pos
				generated_planets_node.add_child(planet_instance)
				spawned_planets.append(planet_instance)
				placement_success = true
				break # Move on to the next planet.
			else:
				# If the position was invalid, free the unused instance to save memory.
				planet_instance.queue_free()
		
		# If we couldn't place a planet after many tries, print a warning.
		if not placement_success:
			print("Could not place planet %d after 20 attempts. The level might be too crowded." % i)


func find_planets_recursive(node: Node):
	# This searches recursively through all child nodes to find planets.
	for child in node.get_children():
		if child is HomePlanet:
			home_planet = child
			# This ensures the HomePlanet is also in the main planets list.
			all_planets.append(child)
		# This checks if the node is a standard planet.
		elif child is BasePlanet:
			all_planets.append(child)

		# This continues the search into the children of the current node.
		if child.get_child_count() > 0:
			find_planets_recursive(child)
			
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
