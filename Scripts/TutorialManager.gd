extends Node

# This tracks which tutorials have been shown
var tutorials_shown: Dictionary = {}

# This is a queue system to prevent overlapping tutorials.
var tutorial_queue: Array = []
var current_tutorial_active: bool = false

# These are the tutorial messages.
const FIRST_ORBIT_MESSAGE = "You've entered a gravity well! Complete a full loop to earn another Boost Charge!"
const OUT_OF_BOOSTS_MESSAGE = "Out of Boosts! Find a planet and orbit it to recharge."
const LAND_FOR_BOOST_MESSAGE = "Land on a planet to get your boost back!"
const ORBIT_FOR_EXTRA_BOOST_MESSAGE = "You can also orbit a planet to get an extra boost!"

# This shows a tutorial if it hasn't been shown before.
func show_tutorial_once(tutorial_id: String, message: String, parent: Node) -> void:
	# This checks if tutorials are enabled in the game settings.
	if not GameManager.get_tutorials_enabled():
		return

	if tutorial_id in tutorials_shown:
		return # Already shown

	# This adds the tutorial to the queue if one is already showing.
	if current_tutorial_active:
		tutorial_queue.append({"id": tutorial_id, "message": message, "parent": parent})
		return

	# This marks the tutorial as active and shown.
	current_tutorial_active = true
	tutorials_shown[tutorial_id] = true
	
	# This calculates a position at the bottom-center of the screen.
	var screen_size = parent.get_viewport_rect().size
	var notification_width = 600
	var notification_height = 100
	
	var x_pos = (screen_size.x - notification_width) / 2
	var y_pos = screen_size.y - notification_height - 20
	
	var spawn_position = Vector2(x_pos, y_pos)
	
	# This creates and shows the tutorial at the calculated position.
	var tutorial_instance = TutorialNotification.create_tutorial(parent, message, spawn_position)
	# This connects to the tutorial's finished signal to process the queue.
	tutorial_instance.tutorial_finished.connect(_on_tutorial_finished)

# This function is called when a tutorial notification finishes fading out.
func _on_tutorial_finished():
	current_tutorial_active = false
	# This checks if there are other tutorials waiting in the queue.
	if not tutorial_queue.is_empty():
		var next_tutorial = tutorial_queue.pop_front()
		# This calls the show function again to display the next tutorial.
		show_tutorial_once(next_tutorial.id, next_tutorial.message, next_tutorial.parent)


# This shows the first orbit tutorial
func show_first_orbit_tutorial(parent: Node) -> void:
	show_tutorial_once("first_orbit", FIRST_ORBIT_MESSAGE, parent)

# This shows the out of boosts tutorial
func show_out_of_boosts_tutorial(parent: Node) -> void:
	show_tutorial_once("out_of_boosts", OUT_OF_BOOSTS_MESSAGE, parent)

# This shows the land for boost tutorial
func show_land_for_boost_tutorial(parent: Node) -> void:
	show_tutorial_once("land_for_boost", LAND_FOR_BOOST_MESSAGE, parent)

# This shows the orbit for extra boost tutorial
func show_orbit_for_extra_boost_tutorial(parent: Node) -> void:
	show_tutorial_once("orbit_for_extra_boost", ORBIT_FOR_EXTRA_BOOST_MESSAGE, parent)

# This resets all tutorials (for testing or new game)
func reset_tutorials() -> void:
	tutorials_shown.clear()
