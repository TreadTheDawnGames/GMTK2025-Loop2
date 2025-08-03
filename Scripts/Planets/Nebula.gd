extends Node2D
class_name Nebula

@onready var sprite: Sprite2D = $Sprite2D

# An array of colors to randomly choose from for the nebula's tint.
var nebula_colors = [
	Color("ff4545"), # Red
	Color("4dff8a"), # Green
	Color("4d5bff"), # Blue
	Color("ff4dcf"), # Pink/Purple
	Color("4dfff2"), # Cyan
]

var ContainedPlanets : Array[BasePlanet]

func _ready():
	# This sets a random rotation for variety.
	rotation_degrees = randf_range(0, 360)
	
	# This picks a random color from our list and applies it to the sprite.
	# The alpha (transparency) is set to 0.25 to make it a background element.
	var random_color = nebula_colors.pick_random()
	random_color.a = 0.25
	sprite.modulate = random_color
	
	# This randomly scales the nebula to make them different sizes.
	var random_scale = randf_range(6.0, 10.0)
	sprite.scale = Vector2(random_scale, random_scale)

# This function helps the GameController know the size of the nebula for clustering planets.
func get_radius() -> float:
	# It calculates the radius based on the texture's width and the sprite's current scale.
	if sprite and sprite.texture:
		return sprite.texture.get_width() * sprite.scale.x / 2.0
	return 500.0 # This is a default radius if something goes wrong.
