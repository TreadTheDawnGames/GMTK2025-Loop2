extends Node

const ASTEROID = preload("res://Scenes/Asteroid.tscn")
@export var FixDistance : float = 6000


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if(Input.is_action_just_pressed("DEBUG-SpawnSoftlockFix")):
		FixSoftlock(Player.Position)
		print("fixing")
	pass

func FixSoftlock(fixPosition : Vector2):
	var asteroid : Asteroid = ASTEROID.instantiate()
	var distance_from_origin = fixPosition.distance_to(Player.origin_position)
	var direction : Vector2 
	if distance_from_origin > Player.max_distance_from_origin-1500:
		direction = fixPosition.normalized() #Vector2(RandNegativePositive(), RandNegativePositive()).normalized()
	else:
		direction = Vector2(RandNegativePositive(), RandNegativePositive()).normalized()
		
	asteroid.global_position = fixPosition + (direction * FixDistance)
	get_tree().root.add_child(asteroid)
	asteroid.Launch(-direction)
	
	return

##Returns a number between -1 and +1 (randf() - randf())
func RandNegativePositive() -> float:
	return randf() - randf()
