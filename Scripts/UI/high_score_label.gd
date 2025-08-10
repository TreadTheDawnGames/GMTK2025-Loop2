extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = "Best Combo: " + GameHUD.comma_separated_string(int(GameManager.best_combo))
	pass # Replace with function body.
