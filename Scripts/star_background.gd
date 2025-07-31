extends TextureRect
class_name StarBackground

	
func _process(_delta: float) -> void:
	material.set("shader_parameter/offset", Player.Position * 0.0001)
	#material.set("shader_parameter/paralax", amount)
	return

	
