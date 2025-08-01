extends TouchZoomCamera2D

#https://www.youtube.com/watch?v=LGt-jjVf-ZU
class_name ScreenShake2

@export var randomStrength: float = 10.0
@export var shakeFade: float = 10.0

var rng = RandomNumberGenerator.new()

var shake_str: float = 0.0

func Shake():
	shake_str = randomStrength

func _process(delta: float) -> void:
	if(shake_str >0):
		shake_str = lerpf(shake_str,0,shakeFade*delta)
		offset = RandomOffset()

func RandomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_str, shake_str), rng.randf_range(-shake_str, shake_str))

func _input(event: InputEvent) -> void:
	super._input(event)
	#Godot forums
	if event is InputEventMouseButton:
		if event.is_pressed():
			# zoom in
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom *= 1.1
				# call the zoom function
			# zoom out
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				# call the zoom function
				zoom *= 0.9
		zoom = zoom.clamp(Vector2(0.1,0.1), Vector2(1.5,1.5))
	pass
	
