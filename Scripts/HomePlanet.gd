extends BasePlanet
class_name HomePlanet

@onready var Surface: Area2D = $HomeArea

signal LevelComplete

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
