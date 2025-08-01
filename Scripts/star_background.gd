extends Control
class_name StarBackground

	
func _process(_delta: float) -> void:
	material.set("shader_parameter/offset", Player.Position)
	var differenceBetweenShipPosAndMaxDistance : float = abs(Player.max_distance_from_origin - Player.Position.distance_to(Player.origin_position))

	if differenceBetweenShipPosAndMaxDistance < 1500:
		var bgc : Color = material.get("shader_parameter/bg_color")
		var red : float = clamp(1.0 - (differenceBetweenShipPosAndMaxDistance / 1500.0), 0.0, 0.33)
		material.set("shader_parameter/bg_color", Color(abs(red), bgc.g, bgc.b))
	else:
		material.set("shader_parameter/bg_color", Color(0,0,0))
		
	#material.set("shader_parameter/paralax", amount)
	return

	
