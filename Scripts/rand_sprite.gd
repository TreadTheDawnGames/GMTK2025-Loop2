extends Sprite2D
class_name RandSprite2D
@export var PlanetSprites : Array[Texture2D]
const CIRCLE_NORMAL_MAP = preload("res://Assets/Shaders/CircleNormalMap.png")
@export var normalMap : Array[Texture2D] 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation_degrees = randi()%360
	var canvas = CanvasTexture.new()
	canvas.diffuse_texture = PlanetSprites.pick_random()
	if(normalMap):
		canvas.normal_texture = normalMap[PlanetSprites.find(canvas.diffuse_texture)]
	else:
		canvas.normal_texture = CIRCLE_NORMAL_MAP
	texture = canvas
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#var canvas : CanvasTexture = texture as CanvasTexture
	rotation += _delta * 0.01
	pass
