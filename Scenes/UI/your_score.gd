extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = "This Game: " + GameHUD.comma_separated_string(int(GameManager.get_score()))
	pass # Replace with function body.
