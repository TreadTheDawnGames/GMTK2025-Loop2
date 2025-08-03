extends Control
@onready var color_slider: HSlider = $Panel/VBoxContainer/ColorSliderContainer/ColorSlider
@onready var example_ship: Sprite2D = $Panel/VBoxContainer/ExampleShipContainer/ExampleShip
@onready var player_audio_handler: PlayerAudioHandler = $PlayerAudioHandler
const CREDITS = preload("res://Scenes/UI/credits.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set initial slider value from GameManager
	#color_slider.value = GameManager.get_ship_color_hue()
	# Update example ship color
	update_example_ship_color()
	# Connect to GameManager signal for color changes
	GameManager.ship_color_changed.connect(_on_ship_color_changed)


# Called when the color slider value changes
func _on_color_slider_value_changed(value: float) -> void:
	# Update GameManager with new hue value
	GameManager.set_ship_color_from_hue(value)

# Called when GameManager ship color changes
func _on_ship_color_changed(_new_color: Color) -> void:
	update_example_ship_color()

# Update the example ship sprite color
func update_example_ship_color() -> void:
	#var ship_color = GameManager.get_ship_color()
	#example_ship.modulate = ship_color
	pass
# Called when Back button is pressed
func _on_back_button_pressed() -> void:
	# Return to main menu
	queue_free()

func toggle_banger_music(ticked : bool):
	if ticked:
		MusicManager.stop_audio_omni("background_music")
		MusicManager.play_audio_omni("banger_music")
	else:
		MusicManager.stop_audio_omni("banger_music")
		MusicManager.play_audio_omni("background_music")
	return

func _on_credits_button_pressed() -> void:
	get_tree().root.add_child(CREDITS.instantiate())
	pass # Replace with function body.
