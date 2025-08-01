extends BasePlanet
class_name HomePlanet

@onready var Surface: Area2D = $Sprite/HomeArea

# Home planet is now just a regular planet for navigation
# Win condition has been moved to collecting all collectables

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# No longer connecting to body entered for win condition
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
