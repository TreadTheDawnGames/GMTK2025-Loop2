extends Node

const ASTEROID = preload("res://Scenes/Asteroid.tscn")
@export var FixDistance : float = 1920
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if(Input.is_action_just_pressed("DEBUG-SpawnSoftlockFix")):
		FixSoftlock(Player.Position)
		print("fixing")
	pass

func FixSoftlock(fixPosition : Vector2):
	var asteroid : Asteroid = ASTEROID.instantiate()
	var direction : Vector2 = Vector2(RandNegativePositive(), RandNegativePositive()).normalized()
	asteroid.global_position = fixPosition + (direction * FixDistance)
	get_tree().root.add_child(asteroid)
	asteroid.Launch(-direction)
	
	return

##Returns a number between -1 and +1 (randf() - randf())
func RandNegativePositive() -> float:
	return randf() - randf()
