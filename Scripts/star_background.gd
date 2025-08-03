# res://Scripts/star_background.gd
extends ColorRect
class_name StarBackground

# This creates a slot in the Inspector to link the player node.
@export var player_node: Node2D
@onready var player: Player = $"../../Player"

func _ready() -> void:
	player_node = player

func _process(_delta: float) -> void:
	# This check prevents the game from crashing if the player hasn't been linked in the editor.
	if not is_instance_valid(player_node):
		printerr("THERE IS NO PLAYER NODE")
		return

	# This uses the specific player instance's position to move the shader for a parallax effect.
	material.set("shader_parameter/offset", player_node.global_position)
	
	# This now calculates the distance from the center of the map (0,0) to match the new lose condition.
	var distance_from_center = player_node.global_position.length()#.distance_to(Vector2.ZERO)
	
	# This calculates how close the player is to the "death zone" boundary.
	var differenceBetweenShipPosAndMaxDistance: float = abs(Player.max_distance_from_origin - distance_from_center)

	# This logic makes the background turn red as the player gets too far.
	if differenceBetweenShipPosAndMaxDistance < 1500:
		# This gets the current background color from the shader.
		var bgc: Color = material.get("shader_parameter/bg_color")
		# This calculates the intensity of the red color based on proximity to the edge.
		var red: float = clamp(1.0 - (differenceBetweenShipPosAndMaxDistance / 1500.0), 0.0, 0.33)
		# This sets the new background color with the added red tint.
		material.set("shader_parameter/bg_color", Color(abs(red), bgc.g, bgc.b))
	else:
		# This resets the background color to black when the player is safe.
		material.set("shader_parameter/bg_color", Color(0, 0, 0))
		
	return
