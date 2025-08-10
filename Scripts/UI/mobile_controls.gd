extends Control
class_name MobileControls
@onready var ready_to_launch_label: Label = $Label
@onready var primary: ControlTouchButton = $Primary
@onready var secondary: ControlTouchButton = $Secondary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(not GameManager.IsMobile):
		hide()
	else:
		show()

func set_ready_to_launch(is_ready : bool):
	ready_to_launch_label.visible = is_ready
