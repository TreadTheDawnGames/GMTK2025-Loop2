extends Button
class_name SoundButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(on_button_pressed)

var isHovered : bool = false
func _process(_delta: float) -> void:
	if(is_hovered() and not isHovered):
		isHovered = true
		on_button_hovered()
	elif not is_hovered():
		isHovered = false

func on_button_pressed()->void:
	MusicManager.play_audio_omni("button_click")

func on_button_hovered()->void:
	MusicManager.play_audio_omni("button_hover")
