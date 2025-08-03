# res://Scripts/star_background.gd
extends ColorRect
class_name StarBackground

# This creates a slot in the Inspector to link the player node.
@export var player_node: Node2D


func _process(_delta: float) -> void:
	# This check prevents the game from crashing if the player hasn't been linked in the editor.
	if not is_instance_valid(player_node):
		return

	# This now uses the specific player instance's position to move the shader.
	material.set("shader_parameter/offset", player_node.global_position)
	
	# This now calculates the distance from the player's unique, non-static origin point.
	var distance_from_origin = player_node.global_position.distance_to(player_node.origin_position)
	
	# This calculates how close the player is to the "death zone" boundary.
	var differenceBetweenShipPosAndMaxDistance: float = abs(Player.max_distance_from_origin - distance_from_origin)

	# This logic makes the background turn red as the player gets too far.
	if differenceBetweenShipPosAndMaxDistance < 1500:
		var bgc: Color = material.get("shader_parameter/bg_color")
		var red: float = clamp(1.0 - (differenceBetweenShipPosAndMaxDistance / 1500.0), 0.0, 0.33)
		material.set("shader_parameter/bg_color", Color(abs(red), bgc.g, bgc.b))
	else:
		material.set("shader_parameter/bg_color", Color(0, 0, 0))
		
	return
