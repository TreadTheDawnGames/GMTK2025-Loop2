extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = "High Score: " + str(int(GameManager.high_score))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
