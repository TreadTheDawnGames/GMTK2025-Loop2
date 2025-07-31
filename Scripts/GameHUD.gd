extends Control
class_name GameHUD

# UI element references
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var boosts_label: Label = $VBoxContainer/BoostsLabel
@onready var boost_power_label: Label = $VBoxContainer/BoostPowerLabel
@onready var compass = %Compass
@onready var objectives_panel: ObjectivesPanel = $ObjectivesPanel
@onready var notification_container: Control = $NotificationContainer

# References to game objects
var player: RigidBody2D

func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	
	update_score_display()
	update_boosts_display()
	boost_power_label.visible = false

	# Set up notification container position (bottom right)
	if notification_container:
		notification_container.position = Vector2(get_viewport().size.x - 250, get_viewport().size.y - 100)

func setup_references(player_ref: RigidBody2D, home_ref: Area2D, planets_ref: Array[Area2D]) -> void:
	player = player_ref
	
	if compass:
		compass.setup_compass(player, home_ref, planets_ref)

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	
	update_boost_power_display()
	update_boosts_display()

func _on_score_changed(_new_score: int) -> void:
	update_score_display()

func update_score_display() -> void:
	score_label.text = "Score: " + str(GameManager.get_score())

func update_boosts_display() -> void:
	if player:
		var boost_text = "Boosts: " + ("1" if player.has_boost else "0 (USED)")
		boosts_label.text = boost_text

func update_boost_power_display() -> void:
	if player.current_state == Player.State.AIMING:
		boost_power_label.visible = true
		var power_percentage = player._current_aim_pull_vector.length() / player.max_pull_distance
		var power_int = int(clamp(power_percentage, 0.0, 1.0) * 100)
		boost_power_label.text = "Launch Power: %d%%" % power_int
	else:
		boost_power_label.visible = false

func show_collection_notification(collectable_name: String, points: int) -> void:
	if notification_container:
		# Create notification at bottom right
		var screen_pos = Vector2(0, -40 * notification_container.get_child_count())
		CollectionNotification.create_notification(notification_container, collectable_name, points, screen_pos)
