extends Control
class_name GameHUD

const FloatingNumber = preload("res://Scenes/UI/FloatingNumber.tscn")

# This stores references to UI elements.
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var high_score_label: Label = $VBoxContainer/HighScoreLabel
@onready var level_goal_label: Label = $VBoxContainer/LevelGoalLabel
@onready var boost_power_label: Label = $VBoxContainer/BoostPowerLabel
@onready var compass = %Compass
@onready var objectives_panel: ObjectivesPanel = $ObjectivesPanel
@onready var notification_container: Control = $NotificationContainer
@onready var points_label: RichTextLabel = $PointsLabel
@onready var boosts_label: Label = $BoostsLabel

@onready var collectable_counter: CollectableCounter = $CollectableCounter
@onready var mobile_controls: MobileControls = $MobileControls

# This stores references to game objects.
var player: Player
var game_controller

# This stores the tween for the score flash effect.
var score_flash_tween: Tween
var level_flash_tween: Tween
var score: int = 0

func _ready() -> void:
	# This connects to the signal for when the score changes.
	GameManager.score_changed.connect(_on_score_changed)
	# This connects to the signal for when a level is completed.
	GameManager.level_completed.connect(_on_level_completed)
	# This connects to the signal for animated score additions.
	GameManager.score_animation_requested.connect(_on_score_animation_requested)
	
	# This sets the initial display values.
	score = GameManager.get_score()
	update_score_display()
	update_high_score_display()
	update_level_goal_display()
	update_boosts_display()
	boost_power_label.visible = false

	# This sets up the notification container position.
	if notification_container:
		notification_container.position = Vector2(get_viewport().size.x - 250, get_viewport().size.y - 100)

func setup_references(player_ref: RigidBody2D, home_ref: Area2D, planets_ref: Array[Area2D], sun_ref: Area2D) -> void:
	# This sets up references to core game nodes.
	player = player_ref
	game_controller = get_node("../../") as GameController

	if compass:
		compass.setup_compass(player, home_ref, planets_ref, sun_ref)

func _process(_delta: float) -> void:
	# This does nothing if the player is not valid.
	if not is_instance_valid(player):
		return

	# update_boost_power_display()
	update_boosts_display()
	update_points_display()

func _on_score_changed(new_score: int) -> void:
	# This updates the score and creates a flash effect.
	var difference = new_score - score
	score = new_score
	if difference > 0:
		show_floating_score(difference)
	update_score_display()
	update_high_score_display()
	update_level_goal_display()
	flash_score_label()

func _on_score_animation_requested(points: int, world_position: Vector2) -> void:
	# This creates an animated score that flies from the world position to the score UI
	animate_score_to_ui(points, world_position)

func _on_level_completed(completed_level: int, goal_score: int, delay : int = 0) -> void:
	# This creates a special notification when a level is completed.
	print("Level %d completed! Reached goal of %d points" % [completed_level, goal_score])
	
	# Flash the level goal label for a longer time, then update the display
	flash_level_goal_label_extended()
	
	# Show a level completion notification
	if notification_container:
		get_tree().create_timer(delay).timeout.connect(func():
			var screen_pos = Vector2(0, -40 * notification_container.get_child_count())
			CollectionNotification.create_notification(notification_container, "LEVEL " + comma_separated_string(completed_level) + " COMPLETE!", goal_score, screen_pos)
		)
func animate_score_to_ui(points: int, world_position: Vector2) -> void:
	# This creates a label that animates from the world position to the score UI
	var animated_label = Label.new()
	animated_label.text = "+" + comma_separated_string(points)
	animated_label.add_theme_font_size_override("font_size", 24)
	
	# Add the label to the HUD
	add_child(animated_label)
	
	var screen_pos = get_viewport().get_canvas_transform() * world_position
	
	# Set initial position
	animated_label.global_position = screen_pos
	
	if points == 0:
		# --- NEW ANIMATION FOR +0 ---
		# Make the label gray and less prominent
		animated_label.modulate = Color.GRAY
		
		var tween = create_tween()
		# The animation will be sequential
		tween.set_parallel(false) 
		
		# Step 1: Move up slightly
		var rise_position = animated_label.global_position + Vector2(0, -40)
		tween.tween_property(animated_label, "global_position", rise_position, 0.4).set_ease(Tween.EASE_OUT)
		
		# Step 2: Fall down and to the left, off the screen
		var fall_position = animated_label.global_position + Vector2(-150, 400)
		tween.tween_property(animated_label, "global_position", fall_position, 1.0).set_ease(Tween.EASE_IN)
		
		# Create a separate, parallel tween just for fading out during the fall
		var fade_tween = create_tween()
		fade_tween.tween_property(animated_label, "modulate:a", 0.0, 1.0).set_delay(0.4)
		
		# Clean up the label after the animation is finished
		tween.tween_callback(animated_label.queue_free)
		
	else:
		animated_label.modulate = Color.YELLOW
		
		# Get the target position (score label position)
		var target_pos = score_label.global_position
		
		# Create the animation
		var tween = create_tween()
		tween.parallel().tween_property(animated_label, "global_position", target_pos, 1.0)
		tween.parallel().tween_property(animated_label, "modulate:a", 0.0, 0.8)
		tween.tween_callback(animated_label.queue_free)

func show_floating_score(amount: int):
	var floating_number = FloatingNumber.instantiate()
	PointNumbers.add_child(floating_number)
	var start_pos = score_label.global_position + Vector2(score_label.size.x, 0)
	floating_number.start(amount, start_pos)

func update_score_display() -> void:
	# This updates only the score text.
	var score_text = "Score: " + comma_separated_string(GameManager.get_score())
	score_label.text = score_text

func update_high_score_display() -> void:
	# This updates the high score display.
	var high_score_text = "Best: " + comma_separated_string(GameManager.get_best_combo())
	high_score_label.text = high_score_text

func update_level_goal_display() -> void:
	# This updates the level and goal display.
	var current_level = GameManager.get_current_level()
	var current_goal = GameManager.get_current_level_goal()
	
	# This updates the text to show the new format: Level X | Goal: current/target.
	var level_goal_text = "Level "+comma_separated_string(current_level)+" | Goal: " +comma_separated_string(current_goal)
	level_goal_label.text = level_goal_text

func update_boosts_display() -> void:
	# This updates the text for available boosts.
	if player:
		var boost_text = comma_separated_string(player.BoostCount)
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

#Godot forums
static func comma_separated_string(num : int):
	var string = str(num)
	for itr in range(0, len(str(num)), 3):
		if itr !=0:
			string = string.insert(len(str(num))-itr, ",")
	return string

func update_points_display() -> void:
	if player:
		var points_text = comma_separated_string(player.points) + " * [color=red]" + comma_separated_string(player.mult) + "[/color]"
		points_label.text = points_text

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

func flash_level_goal_label_extended():
	# This creates an extended gold flash effect on the level goal label when a level is completed.
	if not level_goal_label:
		return

	# This stops any ongoing flash.
	if level_flash_tween:
		level_flash_tween.kill()

	# This creates the extended flash animation that lasts longer.
	level_flash_tween = create_tween()
	
	# Flash multiple times
	for i in range(5):
		level_flash_tween.tween_property(level_goal_label, "modulate", Color.GOLD, 0.2)
		level_flash_tween.tween_property(level_goal_label, "modulate", Color.WHITE, 0.2)
	
	# Final flash to gold and stay for a moment
	level_flash_tween.tween_property(level_goal_label, "modulate", Color.GOLD, 0.3)
	level_flash_tween.tween_property(level_goal_label, "modulate", Color.WHITE, 0.5)
	
	# Update the display after the animation completes
	level_flash_tween.tween_callback(update_level_goal_display)
