extends Sprite2D
class_name RandSprite2D
@export var PlanetSprites : Array[Texture2D]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	texture = PlanetSprites.pick_random()
	rotation_degrees = randi()%360
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
