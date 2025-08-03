extends Node

# Singleton for managing game state and settings
signal ship_color_changed(new_color: Color)
signal score_changed(new_score: int)
# This new signal is emitted only when a collectable is picked up.
signal collectable_collected()

# Ship color settings
var ship_color: Color = Color.WHITE
var ship_color_hue: float = 0.0  # 0.0 to 1.0 for hue slider

var high_score : float = 0:
	get: return high_score
	set (value): 
		if value > high_score:
			high_score = value
# Score system
var current_score: int = 0

# Tutorial settings
var tutorials_enabled: bool = true

# Game state
enum GameState {
	MENU,
	PLAYING,
	WIN,
	LOSE
}

var current_game_state: GameState = GameState.MENU

# Predefined ship colors for easy access
var ship_colors: Array[Color] = [
	Color.RED,        # Hue 0.0
	Color.ORANGE,     # Hue ~0.08
	Color.YELLOW,     # Hue ~0.17
	Color.GREEN,      # Hue ~0.33
	Color.CYAN,       # Hue ~0.5
	Color.BLUE,       # Hue ~0.67
	Color.MAGENTA,    # Hue ~0.83
	Color.WHITE       # Special case
]

@onready var Background: StarBackground

func _ready() -> void:
	# Set initial ship color
	set_ship_color_from_hue(0.0)  # Start with red
# Set ship color based on hue value (0.0 to 1.0)
func set_ship_color_from_hue(hue_value: float) -> void:
	ship_color_hue = clamp(hue_value, 0.0, 1.0)
	
	# Create color from HSV (Hue, Saturation, Value)
	var _ship_color = Color.from_hsv(ship_color_hue, 1.0, 1.0)
	
	# Emit signal to notify other nodes
	ship_color_changed.emit(ship_color)

# Get current ship color
func get_ship_color() -> Color:
	return ship_color

# Get current hue value for slider
func get_ship_color_hue() -> float:
	return ship_color_hue

# Set game state
func set_game_state(new_state: GameState) -> void:
	current_game_state = new_state

# Get current game state
func get_game_state() -> GameState:
	return current_game_state

# Score management functions
func add_score(points: int) -> void:
	current_score += points
	high_score = current_score
	score_changed.emit(current_score)

func get_score() -> int:
	return current_score

func reset_score() -> void:
	current_score = 0
	score_changed.emit(current_score)

# Restart the game
func restart_game() -> void:
	reset_score()  # Reset score when restarting
	set_game_state(GameState.PLAYING)
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")

# Go to main menu
func go_to_main_menu() -> void:
	set_game_state(GameState.MENU)
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")

# Show win screen
func show_win_screen() -> void:
	set_game_state(GameState.WIN)
	get_tree().change_scene_to_file.call_deferred("res://Scenes/UI/WinScreen.tscn")

# Show win screen with victory stats
func show_win_screen_with_stats(stats: Dictionary) -> void:
	# This stores stats for the win screen to access
	set_meta("victory_stats", stats)
	show_win_screen()

# Show lose screen
func show_lose_screen() -> void:
	set_game_state(GameState.LOSE)
	get_tree().change_scene_to_file("res://Scenes/UI/LoseScreen.tscn")

# Tutorial settings functions
func set_tutorials_enabled(enabled: bool) -> void:
	tutorials_enabled = enabled

func get_tutorials_enabled() -> bool:
	return tutorials_enabled

# Collectable collection notification
func notify_collectable_collected() -> void:
	collectable_collected.emit()
