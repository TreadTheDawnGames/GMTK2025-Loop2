@tool
extends Node2D

const PLANET_LARGE = preload("res://Scenes/planet_large.tscn")
const PLANET_MEDIUM = preload("res://Scenes/planet_medium.tscn")
const PLANET_SMALL = preload("res://Scenes/planet_small.tscn")

@export_group("Tool Settings")
@export var active: bool = false

@export_group("Planet Spawn Toggles")
@export var spawn_large_planets: bool = true
@export var spawn_medium_planets: bool = true
@export var spawn_small_planets: bool = true

var was_active_last_frame: bool = false
var placing: bool = false


func _ready() -> void:
	# Initialize the 'was_active_last_frame' to match the starting state of 'active'
	if Engine.is_editor_hint():
		was_active_last_frame = active


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return

	# This logic prevents a planet from being placed when the 'active' checkbox is
	# clicked to disable the tool. It works by skipping one frame after deactivation.
	if was_active_last_frame and not active:
		was_active_last_frame = active
		placing = false # Ensure state is reset
		return

	was_active_last_frame = active
	if not active:
		return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not placing:
		# Build a list of spawnable planets based on the editor toggles
		var available_planets = []
		if spawn_large_planets:
			available_planets.append(PLANET_LARGE)
		if spawn_medium_planets:
			available_planets.append(PLANET_MEDIUM)
		if spawn_small_planets:
			available_planets.append(PLANET_SMALL)

		# Only proceed if at least one planet type is selected
		if not available_planets.is_empty():
			var planet_to_add = available_planets.pick_random().instantiate()
			planet_to_add.global_position = get_global_mouse_position()
			add_child(planet_to_add)
			planet_to_add.owner = self # Set owner for saving in the scene
			
		placing = true # Set flag to prevent placing multiple planets while holding mouse down
		
	elif not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		placing = false
