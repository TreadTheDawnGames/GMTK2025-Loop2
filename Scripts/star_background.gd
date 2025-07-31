extends TextureRect


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func UpdateShaderUV(position : Vector2):
	self.get_material().set_shader_param("my_value",position)
	return
