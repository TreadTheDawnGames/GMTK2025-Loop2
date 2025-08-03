extends Node2D
class_name PlanetGenerator
@onready var generated_planets_node = $GeneratedPlanets
@onready var generated_nebulas_node = $GeneratedNebulas

# --- Procedural Generation Settings ---
@export_category("Level Generation")
# The scenes for planets that can be randomly spawned.
@export var planet_scenes: Array[PackedScene] = [
	preload("res://Scenes/planet_small.tscn"),
	preload("res://Scenes/planet_medium.tscn"),
	preload("res://Scenes/planet_large.tscn")
]
# The scene for the nebula visual effect.
@export var nebula_scene: PackedScene = preload("res://Scenes/Planets/Nebula.tscn")
# The maximum radius from the center (0,0) where planets can spawn.
@export var spawn_radius: float = 30000.0
# The number of nebulas to spawn.
@export var num_nebulas: int = 8
# The number of planets to spawn.
@export var num_planets: int = 50
# The minimum empty space to leave between the edges of two regular planets.
@export var min_distance_between_planets: float = 1500.0
# How many planets should be clustered inside nebulas.
@export var planets_in_nebulas: int = 8

# --- Special Celestial Body Settings ---
@export_category("Special Objects")
# The scene for the Sun, which will be placed at the center.
@export var sun_scene: PackedScene = preload("res://Scenes/planet_Sol.tscn")
# The scene for the Black Hole, placed randomly.
@export var black_hole_scene: PackedScene = preload("res://Scenes/planet_black_hole.tscn")
# The scene for additional Home Stations/Shops.
@export var station_scene: PackedScene = preload("res://Scenes/Home.tscn")
# The number of ADDITIONAL random stations to spawn (on top of the main HomeBase).
@export var num_additional_stations: int = 2
# The extra empty space required around stations to prevent them from feeling crowded.
@export var station_separation_buffer: float = 4000.0
@onready var player: Player = $Player

var home_planet: HomePlanet

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

## This is the main function for procedural generation.
#func _generate_level():
	## This array will keep track of all placed objects to check for overlaps.
	#var placed_celestial_bodies = []
	#
	## This helper function will handle the placement logic for any given object.
	#var place_object = func(scene: PackedScene, tracking_array: Array, pos: Vector2):
		#if not is_instance_valid(scene):
			#push_warning("Cannot place object: PackedScene is not valid.")
			#return null
#
		#var instance = scene.instantiate()
		#var new_radius = instance.get_gravity_radius()
		#
		## Check for overlaps with all previously placed bodies.
		#var overlaps = false
		#for existing_body in tracking_array:
			#if not is_instance_valid(existing_body): continue
			#
			#var existing_radius = existing_body.get_gravity_radius()
			#var distance = pos.distance_to(existing_body.global_position)
			#
			## Determine the required buffer based on what's being placed.
			#var required_buffer = min_distance_between_planets
			## Check if either the new object or the existing one is a station.
			#var is_new_obj_station = instance is HomePlanet
			#var is_existing_obj_station = existing_body is HomePlanet
			#if is_new_obj_station or is_existing_obj_station:
				#required_buffer = station_separation_buffer
#
			## If the distance is less than the sum of both radii plus our required buffer, it overlaps.
			#if distance < new_radius + existing_radius + required_buffer:
				#overlaps = true
				#break
		#
		## If the position is valid (no overlaps), place the object.
		#if not overlaps:
			#instance.global_position = pos
			#generated_planets_node.add_child(instance)
			#tracking_array.append(instance)
			#return instance
		#else:
			## If the position was invalid, free the unused instance.
			#instance.queue_free()
			#return null
#
	## --- Step 1: Place Stations Evenly Across the Map ---
	#var total_stations = 1 + num_additional_stations
	#var angle_per_sector = TAU / total_stations # TAU is 360 degrees in radians.
	#
	#for i in range(total_stations):
		#var station_placed = false
		#for attempt in range(20): # Try multiple times to place a station in its sector.
			## Calculate the angle range for the current "slice" of the map.
			#var sector_start_angle = i * angle_per_sector
			#var sector_end_angle = (i + 1) * angle_per_sector
			#
			## Pick a random angle and distance within this sector.
			## Stations are placed in the outer half of the map to feel like outposts.
			#var random_angle = randf_range(sector_start_angle, sector_end_angle)
			#var random_radius = randf_range(spawn_radius * 0.5, spawn_radius * 0.9)
			#var station_pos = Vector2.from_angle(random_angle) * random_radius
#
			#var station_instance = place_object.call(station_scene, placed_celestial_bodies, station_pos)
#
			#if is_instance_valid(station_instance):
				## If this is the first station being placed, it's the player's home base.
				#if not is_instance_valid(self.home_planet):
					#self.home_planet = station_instance
					## Move the player to start next to this newly placed station.
					#player.global_position = home_planet.global_position + Vector2(0, -250)
					## This tells the player that this station is its new "home" for the lose condition.
					#player.set_origin_point(home_planet.global_position)
				#
				#station_placed = true
				#break # Move to the next sector.
		#
		#if not station_placed:
			#print("Could not place a station in sector %d after 20 attempts." % i)
#
	## --- Step 2: Place the Sun at the Center ---
	#if is_instance_valid(sun_scene):
		#var sun = sun_scene.instantiate()
		#sun.global_position = Vector2.ZERO
		#generated_planets_node.add_child(sun)
		#placed_celestial_bodies.append(sun)
#
	## --- Step 4: Spawn Nebulas (visuals for clusters) ---
	#var spawned_nebulas = []
	#if is_instance_valid(nebula_scene) and is_instance_valid(generated_nebulas_node):
		#for i in range(num_nebulas):
			#var nebula = nebula_scene.instantiate()
			#var nebula_pos = Vector2.from_angle(randf() * TAU) * randf_range(0, spawn_radius * 0.75)
			#nebula.global_position = nebula_pos
			#generated_nebulas_node.add_child(nebula)
			#spawned_nebulas.append(nebula)
	#
	## --- Step 5: Fill the rest of the space with Regular Planets ---
	#if not planet_scenes.is_empty():
		#var planets_to_spawn = num_planets
		#for i in range(planets_to_spawn):
			#for attempt in range(20):
				#var planet_scene = planet_scenes.pick_random()
				#var spawn_center = Vector2.ZERO
				#if i < planets_in_nebulas and not spawned_nebulas.is_empty():
					#spawn_center = spawned_nebulas.pick_random().global_position
				#
				#var pos = spawn_center + Vector2.from_angle(randf() * TAU) * randf_range(0, spawn_radius / 2 if spawn_center != Vector2.ZERO else spawn_radius)
				#if is_instance_valid(place_object.call(planet_scene, placed_celestial_bodies, pos)):
					#break
