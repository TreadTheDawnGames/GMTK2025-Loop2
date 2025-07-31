extends Control
class_name CollectionNotification

# Node references
@onready var notification_label: Label = $NotificationLabel
@onready var fade_timer: Timer = $FadeTimer

# Animation variables
var fade_duration: float = 2.0
var slide_distance: float = 50.0
var initial_position: Vector2

func _ready() -> void:
	# Set up the timer
	fade_timer.wait_time = fade_duration
	fade_timer.one_shot = true
	fade_timer.timeout.connect(_on_fade_timer_timeout)
	
	# Store initial position
	initial_position = position
	
	# Start invisible
	modulate.a = 0.0

func show_collection(collectable_name: String, points: int) -> void:
	# Set the text
	notification_label.text = "+%d %s" % [points, collectable_name]
	
	# Reset position and make visible
	position = initial_position
	modulate.a = 1.0
	
	# Start the fade animation
	fade_timer.start()
	
	# Create slide up animation
	var tween = create_tween()
	tween.parallel().tween_property(self, "position", initial_position + Vector2(0, -slide_distance), fade_duration)
	tween.parallel().tween_property(self, "modulate:a", 0.0, fade_duration)

func _on_fade_timer_timeout() -> void:
	# Remove this notification
	queue_free()

# Static method to create and show a notification
static func create_notification(parent: Node, collectable_name: String, points: int, screen_position: Vector2) -> CollectionNotification:
	# Load the notification scene
	var notification_scene = preload("res://Scenes/UI/CollectionNotification.tscn")
	var notification = notification_scene.instantiate()
	
	# Add to parent
	parent.add_child(notification)
	
	# Position it
	notification.position = screen_position
	
	# Show the collection
	notification.show_collection(collectable_name, points)
	
	return notification
