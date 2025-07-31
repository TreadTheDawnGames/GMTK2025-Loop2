extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called when Restart button is pressed
func _on_restart_button_pressed() -> void:
	GameManager.restart_game()

# Called when Menu button is pressed
func _on_menu_button_pressed() -> void:
	GameManager.go_to_main_menu()
