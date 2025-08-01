extends HBoxContainer
class_name VolumeControl
@onready var label: Label = $Label
@onready var slider: HSlider = $HSlider2
@onready var check_box: CheckBox = $CheckBox

@export var busName : String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(not busName):
		printerr(name + " LabelSlider does not have a busName")
		return
	slider.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(busName))
	var busIndex = AudioServer.get_bus_index(busName)
	label.text = "- " + busName
	slider.value_changed.connect(func(wantedVolume): 
		AudioServer.set_bus_volume_linear(busIndex, wantedVolume))
	
	check_box.pressed.connect(func(): 
		AudioServer.set_bus_mute(busIndex, check_box.button_pressed)
		)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
