extends Control
class_name GameHUD

# This stores references to UI elements.
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var boosts_label: Label = $VBoxContainer/BoostsLabel
@onready var boost_power_label: Label = $VBoxContainer/BoostPowerLabel
@onready var compass = %Compass
@onready var objectives_panel: ObjectivesPanel = $ObjectivesPanel
@onready var notification_container: Control = $NotificationContainer
@onready var collectable_counter: CollectableCounter = $CollectableCounter

# This stores references to game objects.
var player: Player
var game_controller

# This stores the tween for the score flash effect.
var score_flash_tween: Tween

func _ready() -> void:
	# This connects to the signal for when the score changes.
	GameManager.score_changed.connect(_on_score_changed)
	
	# This sets the initial display values.
	update_score_display()
	update_boosts_display()
	boost_power_label.visible = false

	# This sets up the notification container position.
	if notification_container:
		notification_container.position = Vector2(get_viewport().size.x - 250, get_viewport().size.y - 100)

func setup_references(player_ref: RigidBody2D, home_ref: Area2D, planets_ref: Array[Area2D]) -> void:
	# This sets up references to core game nodes.
	player = player_ref
	game_controller = get_node("../../") as GameController

	if compass:
		compass.setup_compass(player, home_ref, planets_ref)

func _process(_delta: float) -> void:
	# This does nothing if the player is not valid.
	if not is_instance_valid(player):
		return
	
	# This updates UI elements that change every frame.
	update_boost_power_display()
	update_boosts_display()

func _on_score_changed(_new_score: int) -> void:
	# This updates the score and creates a flash effect.
	update_score_display()
	flash_score_label()

func update_score_display() -> void:
	# This updates only the score text.
	var score_text = "Score: " + str(GameManager.get_score())
	score_label.text = score_text

func update_boosts_display() -> void:
	# This updates the text for available boosts.
	if player:
		var boost_text = "Boosts: " + str(player.BoostCount)
		boosts_label.text = boost_text

func update_boost_power_display() -> void:
	# This shows and updates the launch power while aiming.
	if player.current_state == Player.State.AIMING:
		boost_power_label.visible = true
		var power_percentage = player._current_aim_pull_vector.length() / player.max_pull_distance
		var power_int = int(clamp(power_percentage, 0.0, 1.0) * 100)
		boost_power_label.text = "Launch Power: %d%%" % power_int
	else:
		boost_power_label.visible = false

func update_collectable_counts() -> void:
	# This gets the latest counts from the controller and updates the counter UI.
	if collectable_counter and game_controller:
		var counts = game_controller.get_collectable_counts()
		var total_collected = 0
		var total_available = 0

		# This sums up all collectable types.
		for type_name in counts:
			total_collected += counts[type_name]["collected"]
			total_available += counts[type_name]["total"]

		collectable_counter.update_collectable_count(total_collected, total_available)

func show_collection_notification(collectable_name: String, points: int) -> void:
	# This shows a notification when a collectable is gathered.
	if notification_container:
		var screen_pos = Vector2(0, -40 * notification_container.get_child_count())
		CollectionNotification.create_notification(notification_container, collectable_name, points, screen_pos)

func flash_score_label():
	# This creates a green flash effect on the score label.
	if not score_label:
		return

	# This stops any ongoing flash.
	if score_flash_tween:
		score_flash_tween.kill()

	# This creates the new flash animation.
	score_flash_tween = create_tween()
	score_flash_tween.tween_property(score_label, "modulate", Color.GREEN, 0.1)
	score_flash_tween.tween_property(score_label, "modulate", Color.WHITE, 0.3)
