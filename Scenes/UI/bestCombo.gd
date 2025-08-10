extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = "High Score: " + GameHUD.comma_separated_string(int(GameManager.highest_score))
	pass # Replace with function body.
