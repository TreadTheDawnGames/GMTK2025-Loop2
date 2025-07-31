extends Control

@onready var current_color_label: Label = $VBoxContainer/CurrentColorLabel

# Current selected ship color
var selected_ship_color: String = "White"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_color_display()

# Update the display to show current selected color
func update_color_display() -> void:
	current_color_label.text = "Current Color: " + selected_ship_color

# Called when Red button is pressed
func _on_red_button_pressed() -> void:
	selected_ship_color = "Red"
	update_color_display()
	print("Ship color changed to Red")

# Called when Blue button is pressed
func _on_blue_button_pressed() -> void:
	selected_ship_color = "Blue"
	update_color_display()
	print("Ship color changed to Blue")

# Called when Green button is pressed
func _on_green_button_pressed() -> void:
	selected_ship_color = "Green"
	update_color_display()
	print("Ship color changed to Green")

# Called when Yellow button is pressed
func _on_yellow_button_pressed() -> void:
	selected_ship_color = "Yellow"
	update_color_display()
	print("Ship color changed to Yellow")

# Called when Back button is pressed
func _on_back_button_pressed() -> void:
	# Return to main menu
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
