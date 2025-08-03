extends Node2D
class_name Nebula

@onready var sprite: Sprite2D = $Sprite2D

# --- Updated Spritesheet Layout ---
# Your new spritesheet has 12 sprites, likely 128x128 each.
const SPRITE_WIDTH = 128
const SPRITE_HEIGHT = 128
const COLUMNS = 12
const ROWS = 1


func _ready():
	# Most logic is moved to the setup function.
	# This ensures the sprite is ready to be configured.
	sprite.region_enabled = true
	rotation_degrees = randf_range(0, 360)
	var random_scale = randf_range(7.0, 14.0)
	self.scale = Vector2(random_scale, random_scale)

# This new function sets up the nebula based on a color group index.
# 0 = Red, 1 = Green, 2 = Purple, 3 = Blue
func setup_nebula(color_group_index: int):
	# This determines the starting column for the color group (0, 3, 6, 9).
	var start_col = color_group_index * 3
	
	# This picks a random sprite from the 3 available for that color group.
	var random_col = start_col + (randi() % 3)
	
	var region_x = random_col * SPRITE_WIDTH
	
	sprite.region_rect = Rect2(region_x, 0, SPRITE_WIDTH, SPRITE_HEIGHT)
	
	# We no longer apply a random color tint, as the sprites are already colored.
	# The alpha is set directly.
	sprite.modulate.a = 0.25


func get_radius() -> float:
	return SPRITE_WIDTH * self.scale.x / 2.0
