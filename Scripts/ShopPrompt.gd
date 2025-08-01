extends Control
class_name ShopPrompt

# Floating E prompt that appears when player can interact with shop

@onready var prompt_label: Label = $PromptLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var target_node: Node2D
var camera: Camera2D

func _ready():
	# Hide initially
	visible = false

	# Set up the prompt
	if prompt_label:
		prompt_label.text = "E"
		prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func show_prompt(target: Node2D, camera_ref: Camera2D):
	target_node = target
	camera = camera_ref
	visible = true

	# Start floating animation
	if animation_player and animation_player.has_animation("float"):
		animation_player.play("float")

func hide_prompt():
	visible = false
	if animation_player:
		animation_player.stop()

func _process(_delta):
	if visible and target_node and camera:
		# Convert world position to screen position using the camera
		var world_pos = target_node.global_position
		var screen_pos = camera.get_screen_center_position() + (world_pos - camera.global_position)
		global_position = screen_pos + Vector2(0, -80)  # Float above the target
