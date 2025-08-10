#Godot forums https://forum.godotengine.org/t/create-a-custom-touchscreenbutton/39219

extends Control
class_name ControlTouchButton
signal pressed()

var is_pressed = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if get_global_rect().has_point(event.position):
			is_pressed = event.pressed
			if is_pressed:
				pressed.emit()
	#if event is InputEventScreenDrag:
		#if get_global_rect().has_point(event.position):
			#pressed.emit()
