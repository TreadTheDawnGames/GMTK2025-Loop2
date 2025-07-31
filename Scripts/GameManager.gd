extends Node

# Singleton for managing game state and settings
signal ship_color_changed(new_color: Color)

# Ship color settings
var ship_color: Color = Color.WHITE
var ship_color_hue: float = 0.0  # 0.0 to 1.0 for hue slider

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

func _ready() -> void:
	# Set initial ship color
	set_ship_color_from_hue(0.0)  # Start with red

# Set ship color based on hue value (0.0 to 1.0)
func set_ship_color_from_hue(hue_value: float) -> void:
	ship_color_hue = clamp(hue_value, 0.0, 1.0)
	
	# Create color from HSV (Hue, Saturation, Value)
	ship_color = Color.from_hsv(ship_color_hue, 1.0, 1.0)
	
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

# Restart the game
func restart_game() -> void:
	set_game_state(GameState.PLAYING)
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")

# Go to main menu
func go_to_main_menu() -> void:
	set_game_state(GameState.MENU)
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")

# Show win screen
func show_win_screen() -> void:
	set_game_state(GameState.WIN)
	get_tree().change_scene_to_file("res://Scenes/UI/WinScreen.tscn")

# Show lose screen
func show_lose_screen() -> void:
	set_game_state(GameState.LOSE)
	get_tree().change_scene_to_file("res://Scenes/UI/LoseScreen.tscn")
