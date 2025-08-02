extends Control

# Node references
@onready var stats_container: VBoxContainer = $PanelContainer/VBoxContainer
@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	display_victory_stats()

# Called when Restart button is pressed
func _on_restart_button_pressed() -> void:
	SlideTransition.EmitOnHalfway()
	# Load the Settings scene
	SlideTransition.Halfway.connect(func(): 
		GameManager.restart_game()
		)

# Called when Menu button is pressed
func _on_menu_button_pressed() -> void:
	SlideTransition.EmitOnHalfway()
	# Load the Settings scene
	SlideTransition.Halfway.connect(func():
		GameManager.go_to_main_menu()
		)

# This displays victory statistics if available
func display_victory_stats():
	if not GameManager.has_meta("victory_stats"):
		return

	var stats = GameManager.get_meta("victory_stats") as Dictionary
	if not stats:
		return

	# This creates stats labels and inserts them before the spacer
	var spacer_index = 0
	for i in range(stats_container.get_child_count()):
		var child = stats_container.get_child(i)
		if child.name == "Spacer2":
			spacer_index = i
			break

	# This creates stats display
	var stats_label = Label.new()
	stats_label.name = "StatsLabel"
	stats_label.text = format_victory_stats(stats)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.modulate = Color(0.9, 0.9, 0.9)

	# This inserts before the spacer
	stats_container.add_child(stats_label)
	stats_container.move_child(stats_label, spacer_index)

# This formats the victory stats into a readable string
func format_victory_stats(stats: Dictionary) -> String:
	var lines = []

	lines.append("🎉 MISSION COMPLETE! 🎉")
	lines.append("")

	if "final_score" in stats:
		lines.append("Final Score: %d points" % stats["final_score"])

	if "total_collectables" in stats:
		lines.append("Collectables Found: %d/%d" % [stats["total_collectables"], stats["total_collectables"]])

	if "planets_visited" in stats:
		lines.append("Planets Visited: %d" % stats["planets_visited"])

	if "boosts_used" in stats:
		lines.append("Boosts Used: %d" % stats["boosts_used"])

	if "completion_time" in stats and stats["completion_time"] != "Unknown":
		lines.append("Completion Time: %s" % stats["completion_time"])

	return "\n".join(lines)
