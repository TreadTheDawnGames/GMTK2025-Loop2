extends Control
class_name ShopPrompt

# Signal to notify when the prompt is tapped
signal shop_requested

@onready var control_node: Control = $Control
@onready var animation_player: AnimationPlayer = $Control/AnimationPlayer

var target_node: Node2D

func _ready():
	# Hide the prompt initially
	visible = false

	# Start floating animation when visible
	if animation_player and animation_player.has_animation("float"):
		animation_player.play("float")

func show_prompt(target: Node2D):
	# Set the node to follow
	target_node = target
	visible = true

func hide_prompt():
	# Hide the prompt
	visible = false

# This is the new function to handle taps!
func _gui_input(event: InputEvent) -> void:
	# Check if the input is a screen touch and if it's the 'pressed' action
	if event is InputEventScreenTouch and event.is_pressed():
		# Emit the signal to let the HomePlanet know the shop should open
		shop_requested.emit()
		# Accept the event to stop it from propagating further (e.g., to the player's aim input)
		get_viewport().set_input_as_handled()

func _process(_delta):
	if visible and is_instance_valid(target_node):
		# Make the prompt follow the target node in the game world
		# The offset makes it float above the target.
		global_position = target_node.global_position + Vector2(0, -80)
