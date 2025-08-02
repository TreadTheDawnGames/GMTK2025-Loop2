@tool
extends Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $".."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		
		#print(collision_shape_2d.shape.get_property_list())
		scale = Vector2.ONE * collision_shape_2d.shape.get_rect().size.x / (texture.get_size().x/1.9)
		return
	pass
