extends Control

@onready var home_icon: TextureRect = %HomeIcon
@onready var planet_icons_container: Control = %PlanetIcons

var player: RigidBody2D
var home_planet: Area2D
var planets: Array[Area2D] = []
var planet_icons: Array[TextureRect] = []

# --- Minimap Settings ---
# The radius of the map circle in pixels.
@export var map_radius: float = 50.0
# How much to "zoom" the map. Smaller numbers = more zoomed out.
@export var map_scale: float = 0.01

# Planet icon texture
var planet_texture: Texture2D = preload("res://Assets/kenney_simple-space/meteor_small.png")
func _ready():
	
	var background: TextureRect = $Background
	background.modulate = Color(0.1, 0.1, 0.2, 0.8)

func setup_compass(player_ref: RigidBody2D, home_ref: Area2D, planets_ref: Array[Area2D]):
	player = player_ref
	home_planet = home_ref
	planets = planets_ref
	create_planet_icons()

func create_planet_icons():
	# Clear existing icons
	for icon in planet_icons:
		if is_instance_valid(icon):
			icon.queue_free()
	planet_icons.clear()
	
	# Create icons for each planet
	for _i in range(planets.size()):
		var planet_icon = TextureRect.new()
		planet_icon.texture = planet_texture
		planet_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		planet_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		planet_icon.size = Vector2(16, 16)
		planet_icon.pivot_offset = planet_icon.size / 2
		planet_icons_container.add_child(planet_icon)
		planet_icons.append(planet_icon)

func _process(_delta):
	if not is_instance_valid(player) or not is_instance_valid(home_planet):
		return
	
	update_map()

func update_map():
	var player_pos = player.global_position
	
	update_icon_position(home_icon, home_planet.global_position, player_pos)
	
	for i in range(min(planets.size(), planet_icons.size())):
		if is_instance_valid(planets[i]) and is_instance_valid(planet_icons[i]):
			update_icon_position(planet_icons[i], planets[i].global_position, player_pos)

func update_icon_position(icon: TextureRect, world_pos: Vector2, player_pos: Vector2):
	# 1. Get the vector from the player to the object in the game world.
	var relative_pos = world_pos - player_pos
	
	# 2. Scale that huge world vector down to our tiny map scale.
	var map_pos = relative_pos * map_scale
	
	# 3. If the object is outside our map's radius, clamp it to the edge.
	if map_pos.length() > map_radius:
		map_pos = map_pos.normalized() * map_radius

	# 4. Set the icon's position on the map.
	icon.position = map_pos + $CompassCenter.size / 2.0
	
	# --- Visuals (Color & Size) ---
	var distance = player_pos.distance_to(world_pos)
	var scale_factor = clamp(2000.0 / distance, 0.6, 1.5) # Adjust sizing
	icon.scale = Vector2(scale_factor, scale_factor)

	if icon == home_icon:
		icon.modulate = Color.CYAN
		var pulse = sin(Time.get_ticks_msec() / 200.0) * 0.1 + 1.0
		icon.scale *= pulse
	else:
		if distance < 1500:
			icon.modulate = Color.GREEN
		elif distance < 5000:
			icon.modulate = Color.YELLOW
		else:
			icon.modulate = Color.RED
