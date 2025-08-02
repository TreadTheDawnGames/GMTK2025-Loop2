extends Button
class_name SoundButton

# Animation properties
var original_scale: Vector2
var hover_scale: Vector2
var click_scale: Vector2
var hover_tween: Tween
var click_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(on_button_pressed)
	# Store original scale and calculate hover/click scales
	original_scale = scale
	hover_scale = original_scale * 1.1
	click_scale = original_scale * 0.9


var isHovered : bool = false
func _process(_delta: float) -> void:
	if(is_hovered() and not isHovered):
		isHovered = true
		on_button_hovered()

	elif not is_hovered() and isHovered:
		isHovered = false
		on_button_unhovered()

func on_button_pressed()->void:
	MusicManager.play_audio_omni("button_click")
	# This creates click animation - scale down then back to hover
	if click_tween:
		click_tween.kill()
	click_tween = create_tween()
	click_tween.tween_property(self, "scale", click_scale, 0.1)
	click_tween.tween_property(self, "scale", hover_scale if isHovered else original_scale, 0.1)

func on_button_hovered()->void:
	MusicManager.play_audio_omni("button_hover")
	# This creates hover animation - scale up
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", hover_scale, 0.1)

func on_button_unhovered()->void:
	# This creates unhover animation - scale back to original
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", original_scale, 0.1)
