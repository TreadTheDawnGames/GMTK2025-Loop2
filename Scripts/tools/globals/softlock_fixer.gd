extends Node

const ASTEROID = preload("res://Scenes/Asteroid.tscn")
@export var FixDistance : float = 6000


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("DEBUG-SpawnSoftlockFix"):
		# This finds the player node in the current scene by looking for the "player" group.
		var player_node = get_tree().get_first_node_in_group("player")
		
		# This is a safety check to make sure the player exists before we try to use it.
		if is_instance_valid(player_node):
			# This now correctly passes the entire player node instance to the function.
			FixSoftlock(player_node)
			print("fixing")
	pass

func FixSoftlock(player_node: Player):
	# This ensures the player node is valid before proceeding.
	if not is_instance_valid(player_node):
		return

	var asteroid : Asteroid = ASTEROID.instantiate()
	
	# This gets the player's current position from the passed-in node.
	var fixPosition = player_node.global_position
	
	# This now correctly accesses the non-static 'origin_position' from the specific player instance.
	var distance_from_origin = fixPosition.distance_to(player_node.origin_position)
	var direction : Vector2
	
	# This uses the static 'max_distance_from_origin' which is correct.
	if distance_from_origin > Player.max_distance_from_origin-1500:
		direction = fixPosition.normalized()
	else:
		direction = Vector2(RandNegativePositive(), RandNegativePositive()).normalized()
		
	asteroid.global_position = fixPosition + (direction * FixDistance)
	get_tree().root.add_child(asteroid)
	asteroid.Launch(-direction)
	
	return

##Returns a number between -1 and +1 (randf() - randf())
func RandNegativePositive() -> float:
	return randf() - randf()
