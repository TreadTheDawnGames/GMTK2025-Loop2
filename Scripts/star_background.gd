extends Control
class_name StarBackground

	
func _process(_delta: float) -> void:
	material.set("shader_parameter/offset", Player.Position)
	#material.set("shader_parameter/paralax", amount)
	return

	
