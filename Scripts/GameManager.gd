# res://Scripts/GameManager.gd
extends Node

# Singleton for managing game state and settings
signal ship_color_changed(new_color: Color)
signal score_changed(new_score: int)
signal level_completed(new_level: int, goal_score: int)
signal collectable_collected()
signal score_animation_requested(points: int, world_position: Vector2)

# Ship color settings
var ship_color: Color = Color.WHITE
var ship_color_hue: float = 0.0

# This now stores the highest single score chunk ever achieved.
var high_score: int = 0
# This remains the score for the current run.
var current_score: int = 0
# This is the player's persistent level.
var current_level: int = 1

var tutorials_enabled: bool = true

enum GameState { MENU, PLAYING, WIN, LOSE }
var current_game_state: GameState = GameState.MENU

func _ready() -> void:
	set_ship_color_from_hue(0.0)

var level_goal : int = 50
# Calculate the goal score for a given level
func calculate_goal_for_level(level: int) -> int:
	# A new progression better suited for single score chunks.
	# Lvl 1->2: 50, Lvl 2->3: 200, Lvl 3->4: 450 etc.
	if(level == 1):
		return level_goal
	level_goal += level_goal
	if(level % 3 == 0):
		level_goal += level_goal * 0.25
	return level_goal

func get_current_level_goal() -> int:
	return level_goal

func get_current_level() -> int:
	return current_level

func check_level_completion(final_score_chunk: int):
	# Checks if the cashed-in score meets the goal.
	if final_score_chunk >= get_current_level_goal():
		var completed_goal = get_current_level_goal()
		level_completed.emit(current_level, completed_goal)
		current_level += 1
		calculate_goal_for_level(current_level)
		print("Level Up! Reached level %d. Next goal: %d" % [current_level, get_current_level_goal()])

# This new function processes the big score chunk at the end of a run.
func process_final_score(final_score: int, world_position: Vector2):
	# Update the 'high_score' (Best) if this chunk is a new record.
	if final_score > high_score:
		high_score = final_score
	
	# Add the chunk to the total run score.
	current_score += final_score
	
	# Emit signals to update the HUD.
	score_animation_requested.emit(final_score, world_position)
	score_changed.emit(current_score)
	
	# Check if this score chunk achieves the level goal.
	check_level_completion(final_score)

# This is for small, incidental points (like first orbit bonus).
func add_score(points: int) -> void:
	current_score += points
	score_changed.emit(current_score)

func get_score() -> int:
	return current_score

func get_high_score() -> int:
	# This function now correctly returns the best score chunk for the HUD.
	return high_score

func reset_score() -> void:
	# This resets only the current run's score. Best and Level persist.
	current_score = 0
	score_changed.emit(current_score)

# --- The rest of the functions from your original script ---

func set_ship_color_from_hue(hue_value: float) -> void:
	ship_color_hue = clamp(hue_value, 0.0, 1.0)
	ship_color = Color.from_hsv(ship_color_hue, 1.0, 1.0)
	ship_color_changed.emit(ship_color)

func get_ship_color() -> Color:
	return ship_color

func get_ship_color_hue() -> float:
	return ship_color_hue

func set_game_state(new_state: GameState) -> void:
	current_game_state = new_state

func get_game_state() -> GameState:
	return current_game_state

func restart_game() -> void:
	reset_score()
	set_game_state(GameState.PLAYING)
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")

func go_to_main_menu() -> void:
	set_game_state(GameState.MENU)
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")

func show_win_screen() -> void:
	set_game_state(GameState.WIN)
	get_tree().change_scene_to_file.call_deferred("res://Scenes/UI/WinScreen.tscn")

func show_win_screen_with_stats(stats: Dictionary) -> void:
	set_meta("victory_stats", stats)
	show_win_screen()

func show_lose_screen() -> void:
	set_game_state(GameState.LOSE)
	get_tree().change_scene_to_file("res://Scenes/UI/LoseScreen.tscn")

func set_tutorials_enabled(enabled: bool) -> void:
	tutorials_enabled = enabled

func get_tutorials_enabled() -> bool:
	return tutorials_enabled

func notify_collectable_collected() -> void:
	collectable_collected.emit()
