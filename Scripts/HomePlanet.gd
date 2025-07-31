extends BasePlanet
class_name HomePlanet

@onready var Surface: Area2D = $Sprite/HomeArea

signal LevelComplete

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Surface.body_entered.connect(BodyEntered)
	pass # Replace with function body.

func BodyEntered(node : Node2D):
	if(node is Player):
		LevelComplete.emit()
		print("YOU WIN!")
		# Show win screen
		GameManager.show_win_screen()
	return
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
