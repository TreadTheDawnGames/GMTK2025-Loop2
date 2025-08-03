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

const SPRITE_WIDTH = 128
const SPRITE_HEIGHT = 128
const COLUMNS = 11
const ROWS = 1


func _ready():
	# This sets a random rotation for variety.
	sprite.region_enabled = true
	
	var random_col = randi() % COLUMNS
	var region_x = random_col * SPRITE_WIDTH
	
	sprite.region_rect = Rect2(region_x, 0, SPRITE_WIDTH, SPRITE_HEIGHT)
	
	rotation_degrees = randf_range(0, 360)
	
	# This picks a random color from our list and applies it to the sprite.
	# The alpha (transparency) is set to 0.25 to make it a background element.
	var random_color = nebula_colors.pick_random()
	random_color.a = 0.25
	sprite.modulate = random_color
	
	# This significantly increases the size of the nebulas to be large enough for multiple planets.
	var random_scale = randf_range(25.0, 40.0)
	self.scale = Vector2(random_scale, random_scale)


func get_radius() -> float:
	# This calculates the radius based on a single sprite's width and the nebula's current scale.
	return SPRITE_WIDTH * self.scale.x / 2.0
