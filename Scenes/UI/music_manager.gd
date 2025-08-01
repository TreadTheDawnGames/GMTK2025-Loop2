extends AudioManager


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var buttons: Array = get_tree().get_nodes_in_group("Button")
	for inst in buttons:
		inst.connect("pressed", self, "on_button_pressed")

func on_button_pressed()->void:
	play_audio_omni("button_click")



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
