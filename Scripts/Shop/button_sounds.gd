extends Button
class_name SoundButton

# Animation properties
var original_scale: Vector2
var hover_scale: Vector2
var click_scale: Vector2
var hover_tween: Tween
var click_tween: Tween

var local_button_pressed : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect the button's built-in signals to our functions.
	pressed.connect(on_button_pressed)
	mouse_entered.connect(on_button_hovered)
	mouse_exited.connect(on_button_unhovered)
	
	# Store original scale and calculate hover/click scales for animation.
	original_scale = scale
	hover_scale = original_scale * 1.1
	click_scale = original_scale * 0.9
	
	local_button_pressed = button_pressed
	
	#claud pointed out the size wasn't calculated yet. This probably saved at minimum 20 minutes of googling.
	#call_deferred("_add_touch_button")
	


##Automatically set up a touchscreen button
#func _add_touch_button():
	#var my_size : Vector2 = get_rect().size 
	#print(my_size)
	#var touch_button : TouchScreenButton= TouchScreenButton.new()
	#touch_button.global_position += my_size*0.5
	#var rect_shape : RectangleShape2D = RectangleShape2D.new()
	#rect_shape.size = my_size
	#touch_button.shape = rect_shape
	#for connection : Dictionary in pressed.get_connections():
		#print("Adding " + str(connection["callable"]) + " to " + name)
		#touch_button.pressed.connect(connection["callable"])
	#
	#for connection : Dictionary in toggled.get_connections():
		#print("Adding " + str(connection["callable"]) + " to " + name)
		#touch_button.pressed.connect(connection["callable"])
	##touch_button.pressed.connect(on_button_pressed)
	#add_child(touch_button)


# This function is called when the button is clicked.
func on_button_pressed()->void:
	# Play the UI click sound from the MusicManager.
	MusicManager.play_audio_omni("button_click")
	
	# This creates a click animation: scale down then back to hover/original size.
	if click_tween:
		click_tween.kill()
	click_tween = create_tween()
	click_tween.tween_property(self, "scale", click_scale, 0.1)
	# After shrinking, return to the hover scale if the mouse is still over it, otherwise return to normal.
	click_tween.tween_property(self, "scale", hover_scale if is_hovered() else original_scale, 0.1)

# This function is called when the mouse cursor enters the button's area.
func on_button_hovered()->void:
	# Play the UI hover sound.
	MusicManager.play_audio_omni("button_hover")
	#this makes it so hovered buttons appear on top
	z_index += 1
	# This creates a hover animation: scale up.
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", hover_scale, 0.1)

# This function is called when the mouse cursor leaves the button's area.
func on_button_unhovered()->void:
	#This makes the button go back to it's usual index
	z_index -= 1
	# This creates an unhover animation: scale back to the original size.
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", original_scale, 0.1)
#
#
#func _input(event: InputEvent) -> void:
	#if event is InputEventScreenTouch:
		#if get_global_rect().has_point(event.position):
			#if event.pressed:
				#pressed.emit()
			#else:
				#if(toggle_mode == true):
						#
					##local_button_pressed = !local_button_pressed
					#button_pressed = !button_pressed
					#toggled.emit(button_pressed)
					#
					#if(button_pressed):
						#modulate = Color.RED
					#else:
						#modulate = Color.GREEN
			#pass
				##if(pressed.has_connections()):
					##pressed.emit()
				##if(toggled.has_connections()):
					##toggled.emit(button_pressed)
				##if (button_down.has_connections()):
					##button_down.emit()
