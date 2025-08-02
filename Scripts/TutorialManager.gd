extends Node

# This tracks which tutorials have been shown
var tutorials_shown: Dictionary = {}

# Tutorial messages - For now, I don't like these
const FIRST_ORBIT_MESSAGE = "You've entered a gravity well! Complete a full loop to earn another Boost Charge!"
const OUT_OF_BOOSTS_MESSAGE = "Out of Boosts! Find a planet and orbit it to recharge."

# This shows a tutorial if it hasn't been shown before
func show_tutorial_once(tutorial_id: String, message: String, parent: Node) -> void:
	if tutorial_id in tutorials_shown:
		return # Already shown
	
	# This marks as shown
	tutorials_shown[tutorial_id] = true
	
	# Calculate a position at the bottom-center of the screen.
	var screen_size = parent.get_viewport_rect().size
	# The tutorial notification is 600px wide and 100px high.
	var notification_width = 600
	var notification_height = 100
	
	# Calculate the X position to be centered.
	var x_pos = (screen_size.x - notification_width) / 2
	# Calculate the Y position to be at the bottom, with 20px of padding.
	var y_pos = screen_size.y - notification_height - 20
	
	var spawn_position = Vector2(x_pos, y_pos)
	
	# This creates and shows the tutorial at our calculated position.
	TutorialNotification.create_tutorial(parent, message, spawn_position)


# This shows the first orbit tutorial
func show_first_orbit_tutorial(parent: Node) -> void:
	show_tutorial_once("first_orbit", FIRST_ORBIT_MESSAGE, parent)

# This shows the out of boosts tutorial
func show_out_of_boosts_tutorial(parent: Node) -> void:
	show_tutorial_once("out_of_boosts", OUT_OF_BOOSTS_MESSAGE, parent)

# This resets all tutorials (for testing or new game)
func reset_tutorials() -> void:
	tutorials_shown.clear()
