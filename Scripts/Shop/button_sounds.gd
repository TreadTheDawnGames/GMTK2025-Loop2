extends Button
class_name SoundButton

# Animation properties
var original_scale: Vector2
var hover_scale: Vector2
var click_scale: Vector2
var hover_tween: Tween
var click_tween: Tween
var do_touch_button : bool = false

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
	if(do_touch_button):
		create_touch_screen_button(self)


func create_touch_screen_button(purchase_button : SoundButton):
	#This creates the purchase button for the item for mobile.
	var touch_button = TouchScreenButton.new()
	var rectShape = RectangleShape2D.new()
	rectShape.size=purchase_button.size
	touch_button.position = purchase_button.position + (purchase_button.size * 0.5)
	touch_button.shape = rectShape
	add_child(touch_button)
	touch_button.pressed.connect(func(): 
		if not disabled:
			get_connections()[0].call()
		)


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
	
	# This creates a hover animation: scale up.
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", hover_scale, 0.1)

# This function is called when the mouse cursor leaves the button's area.
func on_button_unhovered()->void:
	# This creates an unhover animation: scale back to the original size.
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", original_scale, 0.1)
