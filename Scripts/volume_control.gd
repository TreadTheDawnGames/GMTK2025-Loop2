extends HBoxContainer
class_name VolumeControl
@onready var slider: HSlider = $HSlider2
@onready var check_box: CheckBox = $CheckBox

@export var busName : String
var busIndex  : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(not busName):
		printerr(name + " LabelSlider does not have a busName")
		return
	busIndex = AudioServer.get_bus_index(busName)
	slider.value = AudioServer.get_bus_volume_linear(busIndex)
	check_box.button_pressed = not AudioServer.is_bus_mute(busIndex)
	check_box.text = "- " + busName
	slider.value_changed.connect(set_bus_volume)
	check_box.pressed.connect(set_bus_mute)
	pass # Replace with function body.

func set_bus_volume(wantedVolume : float):
	AudioServer.set_bus_volume_linear(busIndex, wantedVolume)
	
func set_bus_mute():
	AudioServer.set_bus_mute(busIndex, not check_box.button_pressed)
	
