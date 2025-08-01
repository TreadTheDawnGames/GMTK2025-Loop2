extends HBoxContainer
class_name VolumeControl
@onready var label: Label = $Label
@onready var slider: HSlider = $HSlider2

@export var busName : String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(not busName):
		printerr(name + " LabelSlider does not have a busName")
		return
	label.text = "- " + busName
	slider.value_changed.connect(func(a): 
		var wantedVolume = linear_to_db(a)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(busName), wantedVolume))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
