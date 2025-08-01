extends Node2D
const COLLECTABLE_CRYSTAL = preload("res://Scenes/Collectables/Collectable_Crystal.tscn")
const COLLECTABLE_ENERGY_CORE = preload("res://Scenes/Collectables/Collectable_EnergyCore.tscn")
const COLLECTABLE_SATELLITE = preload("res://Scenes/Collectables/Collectable_Satellite.tscn")
const COLLECTABLE_STAR = preload("res://Scenes/Collectables/Collectable_Star.tscn")

@export var OrbitRangeMax : float = 300
@export var OrbitRangeMin : float = 1
@export var OrbitSpeedMax : float = 1.5
@export var OrbitSpeedMin : float = 0.6

@onready var collision_shape_2d: CollisionShape2D = $"../CollisionShape2D"
@onready var sprite_2d: Sprite2D = $"../CollisionShape2D/Sprite2D"
@onready var planet_sprite: Sprite2D = $"../Sprite"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var scenes : Array = [COLLECTABLE_CRYSTAL,COLLECTABLE_ENERGY_CORE,COLLECTABLE_SATELLITE,COLLECTABLE_STAR]
	if(randi()%5 == 4): #1/5 chance no collectable
		return
	else:
		var collectable : Collectable = scenes.pick_random().instantiate()
		var planet_visual_radius = planet_sprite.texture.get_width() * planet_sprite.scale.x / 2.0
		# Set the orbit radius to be somewhere between the planet's surface and its gravity field
		collectable.orbit_radius = randf_range(planet_visual_radius * 1.2, collision_shape_2d.shape.radius * 0.9)
		collectable.find_orbit_planet(owner)
		#collectable.orbit_center = global_position
		collectable.orbit_speed = randf_range(OrbitSpeedMin, OrbitSpeedMax)
		add_child(collectable)
		
	pass # Replace with function body.
