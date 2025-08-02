extends Control
class_name TutorialNotification

# Node references
@onready var tutorial_label: Label = $PanelContainer/VBoxContainer/TutorialLabel
@onready var fade_timer: Timer = $FadeTimer

# Animation properties
var fade_duration: float = 1.0
var display_duration: float = 4.0

func _ready() -> void:
	# This sets up the timer
	fade_timer.wait_time = display_duration
	fade_timer.one_shot = true
	fade_timer.timeout.connect(_on_fade_timer_timeout)
	
	# This starts invisible
	modulate.a = 0.0

func show_tutorial(message: String) -> void:
	# This sets the tutorial text
	tutorial_label.text = message

	# This plays tutorial sound
	MusicManager.play_audio_omni("UpUIBeep")

	# This makes visible and fades in
	modulate.a = 0.0
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(self, "modulate:a", 1.0, fade_duration)

	# This starts the display timer
	fade_timer.start()

func _on_fade_timer_timeout() -> void:
	# This fades out and removes
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	fade_out_tween.tween_callback(queue_free)

# This creates and shows a tutorial notification
static func create_tutorial(parent: Node, message: String, position_override: Vector2 = Vector2.ZERO) -> TutorialNotification:
	# This loads the tutorial scene
	var tutorial_scene = preload("res://Scenes/UI/TutorialNotification.tscn")
	var tutorial_instance = tutorial_scene.instantiate()
	
	# This adds to parent
	parent.add_child(tutorial_instance)
	
	# This positions it (use override if provided)
	if position_override != Vector2.ZERO:
		tutorial_instance.position = position_override
	
	# This shows the tutorial
	tutorial_instance.show_tutorial(message)
	
	return tutorial_instance
