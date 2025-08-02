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

# Victory sequence tracking
var victory_stats: Dictionary = {}
var victory_sequence_active: bool = false

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
		start_victory_sequence()

func get_collectable_counts() -> Dictionary:
	# Return the accurately tracked counts
	return collectable_counts_by_type

# This starts the victory sequence with slow motion and enhanced effects
func start_victory_sequence():
	if victory_sequence_active:
		return

	victory_sequence_active = true

	# This plays victory sound
	MusicManager.play_audio_omni("UpUIBeep")

	# This calculates victory stats
	calculate_victory_stats()

	# This starts slow motion effect
	Engine.time_scale = 0.2

	# This enhances player trail effects for victory lap
	if player:
		player.apply_boost_trail_effect()

	# This shows victory message
	if hud:
		TutorialManager.show_tutorial_once("victory_lap", "🎉 VICTORY LAP! All collectables found!", hud)

	# This waits for victory lap duration then shows win screen
	await get_tree().create_timer(3.0).timeout

	# This restores normal time
	Engine.time_scale = 1.0

	# This shows enhanced win screen with stats
	GameManager.show_win_screen_with_stats(victory_stats)

# This calculates final victory statistics
func calculate_victory_stats():
	victory_stats = {
		"final_score": GameManager.get_score(),
		"total_collectables": total_collectables,
		"planets_visited": count_visited_planets(),
		"boosts_used": calculate_boosts_used(),
		"completion_time": get_completion_time()
	}

# This counts how many planets the player visited
func count_visited_planets() -> int:
	var visited_count = 0
	for planet in all_planets:
		if planet.has_method("was_visited") and planet.was_visited():
			visited_count += 1
	return visited_count

# This calculates total boosts used during the game
func calculate_boosts_used() -> int:
	# This estimates based on starting boosts vs current boosts
	var starting_boosts = 1
	if player and player.has_meta("starting_boosts"):
		starting_boosts = player.get_meta("starting_boosts")

	var current_boosts = player.BoostCount if player else 0
	var boosts_earned = collected_collectables # Each collectable gives 1 boost

	return starting_boosts + boosts_earned - current_boosts

# This gets approximate completion time (placeholder for now)
func get_completion_time() -> String:
	# This could be enhanced with actual time tracking
	return "Unknown"
