extends Control

#@onready var home_icon: TextureRect = %HomeIcon
@onready var planet_icons_container: Control = %PlanetIcons
#@onready var player_dot: TextureRect = %PlayerDot

var player: RigidBody2D
var home_planet: Area2D
var planets: Array[Area2D] = []
var planet_icons: Array[TextureRect] = []
var shop_icons: Array[TextureRect] = []
# This is a new array for the collectable indicators.
var collectable_indicator_icons: Array[TextureRect] = []

# --- Minimap Settings ---
# The radius of the map circle in pixels.
@export var map_radius: float = 50.0
# How much to "zoom" the map. Smaller numbers = more zoomed out.
@export var map_scale: float = 0.01
@export var planet_range_threshold: float = 2000.0

# Textures for the different map icons
var planet_texture: Texture2D = preload("res://Assets/kenney_simple-space/meteor_small.png")
var shop_texture: Texture2D = preload("res://Assets/kenney_simple-space/AAA-ChosenKenney/station_A.png")#preload("res://Assets/kenney_space-shooter-extension/AAA-ChosenKenneySpace/spaceStation_020.png")#preload("res://Assets/kenney_space-shooter-extension/PNG/Sprites/Station/spaceStation_021.png")
@onready var center_ship: Sprite2D = $CenterShip

# This texture will be used for the new indicator icon.
var collectable_indicator_texture: Texture2D = preload("res://Assets/kenney_simple-space/AAA-ChosenKenney/star_small.png")

func _ready():
	var background: TextureRect = $Background
	background.modulate = Color(0.1, 0.1, 0.2, 0.8)
	#setup_player_dot()

func setup_compass(player_ref: RigidBody2D, home_ref: Area2D, planets_ref: Array[Area2D]):
	player = player_ref
	home_planet = home_ref
	planets = planets_ref
	create_planet_and_indicator_icons()
	create_shop_icons()

#func setup_player_dot():
	#if not player_dot:
		#return
	#player_dot.texture = player_texture
	#player_dot.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	#player_dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	#player_dot.size = Vector2(8, 8)
	#player_dot.pivot_offset = player_dot.size / 2
	#player_dot.modulate = Color.WHITE
	#var compass_center = $CompassCenter
	#player_dot.position = compass_center.size / 2.0 - player_dot.size / 2.0

func create_planet_and_indicator_icons():
	# This clears existing icons.
	for icon in planet_icons:
		if is_instance_valid(icon): icon.queue_free()
	for icon in collectable_indicator_icons:
		if is_instance_valid(icon): icon.queue_free()
	planet_icons.clear()
	collectable_indicator_icons.clear()

	# This creates icons for each planet and its collectable indicator.
	for _i in range(planets.size()):
		var planet_icon = TextureRect.new()
		planet_icon.texture = planet_texture
		planet_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		planet_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		planet_icon.size = Vector2(16, 16)
		planet_icon.pivot_offset = planet_icon.size / 2
		planet_icons_container.add_child(planet_icon)
		planet_icons.append(planet_icon)
		
		# This creates the collectable indicator icon.
		var indicator_icon = TextureRect.new()
		indicator_icon.texture = collectable_indicator_texture
		indicator_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		indicator_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		indicator_icon.size = Vector2(8, 8)
		indicator_icon.pivot_offset = indicator_icon.size / 2
		indicator_icon.modulate = Color.PINK
		indicator_icon.visible = false # This hides it by default.
		planet_icons_container.add_child(indicator_icon)
		collectable_indicator_icons.append(indicator_icon)

func create_shop_icons():
	# This function creates icons for home planets (shops).
	for icon in shop_icons:
		if is_instance_valid(icon): icon.queue_free()
	shop_icons.clear()
	for i in range(planets.size()):
		var planet = planets[i]
		var shop_icon = TextureRect.new()
		shop_icon.texture = shop_texture
		shop_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		shop_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		shop_icon.size = Vector2(12, 12)
		shop_icon.pivot_offset = shop_icon.size / 2
		shop_icon.modulate = Color.CYAN
		shop_icon.visible = planet is HomePlanet
		planet_icons_container.add_child(shop_icon)
		shop_icons.append(shop_icon)

func _process(_delta):
	if not is_instance_valid(player) or not is_instance_valid(home_planet):
		return
	update_map()

func update_map():
	var player_pos = player.global_position
	#update_icon_position(home_icon, home_planet.global_position, player_pos)
	
	center_ship.rotation = player.rotation + deg_to_rad(90)
	
	for i in range(min(planets.size(), planet_icons.size())):
		if is_instance_valid(planets[i]) and is_instance_valid(planet_icons[i]):
			var planet = planets[i]
			var planet_icon = planet_icons[i]
			
			# Hide regular planet icons - only show home planets and collectables
			planet_icon.visible = false

			# This updates the shop icon position.
			if i < shop_icons.size() and is_instance_valid(shop_icons[i]):
				update_shop_icon_position(shop_icons[i], planet, player_pos)

			# This is the logic for the collectable indicator.
			if i < collectable_indicator_icons.size() and is_instance_valid(collectable_indicator_icons[i]):
				var indicator_icon = collectable_indicator_icons[i]
				indicator_icon.scale = Vector2(3,3)
				# This checks the planet to see if it has a collectable.
				if planet.has_uncollected_collectable():
					indicator_icon.visible = true
					# Position the indicator relative to the planet's world position
					var planet_world_pos = planet.global_position
					var relative_pos = planet_world_pos - player_pos
					var map_pos = relative_pos * map_scale
					if map_pos.length() > map_radius:
						map_pos = map_pos.normalized() * map_radius
					indicator_icon.position = map_pos + $CompassCenter.size / 2.0
				else:
					indicator_icon.visible = false

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
	var scale_factor = clamp(2000.0 / distance, 0.6, 1.5)
	icon.scale = Vector2(scale_factor, scale_factor)
#
	#if icon == home_icon:
		#icon.modulate = Color.CYAN
		#var pulse = sin(Time.get_ticks_msec() / 200.0) * 0.1 + 1.0
		#icon.scale *= pulse
	#else:
	#if distance < planet_range_threshold:
		#icon.modulate = Color.GREEN
	#elif distance < planet_range_threshold * 2:
		#icon.modulate = Color.YELLOW
	#else:
		#icon.modulate = Color.RED

func update_shop_icon_position(shop_icon: TextureRect, planet: Area2D, player_pos: Vector2):
	if not planet is HomePlanet:
		shop_icon.visible = false
		return
	shop_icon.visible = true
	var planet_world_pos = planet.global_position
	var relative_pos = planet_world_pos - player_pos
	var map_pos = relative_pos * map_scale
	if map_pos.length() > map_radius:
		map_pos = map_pos.normalized() * map_radius
	var offset = Vector2(8, -8)
	shop_icon.position = map_pos + $CompassCenter.size / 2.0 + offset
	var distance = player_pos.distance_to(planet_world_pos)
	if distance < planet_range_threshold:
		shop_icon.modulate = Color.CYAN #Color(0.8, 0.4, 0.0, 0.7)
	else:
		shop_icon.modulate = Color.DARK_CYAN
