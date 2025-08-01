# Scripts/ShopPrompt.gd
extends Control
class_name ShopPrompt

# Floating E prompt that appears when player can interact with shop

@onready var control_node: Control = $Control
@onready var animation_player: AnimationPlayer = $Control/AnimationPlayer

var target_node: Node2D

func _ready():
	# This hides the prompt initially
	visible = false

	# This starts floating animation when visible
	if animation_player and animation_player.has_animation("float"):
		animation_player.play("float")

func show_prompt(target: Node2D):
	# This sets the node to follow
	target_node = target
	visible = true

func hide_prompt():
	# This hides the prompt
	visible = false

func _process(_delta):
	if visible and is_instance_valid(target_node):
		# This makes the prompt follow the target node in the game world
		# The offset makes it float above the target.
		global_position = target_node.global_position + Vector2(0, -80)
