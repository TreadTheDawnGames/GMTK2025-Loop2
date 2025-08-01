@tool
extends Node2D
const PLANET_LARGE = preload("res://Scenes/planet_large.tscn")
const PLANET_MEDIUM = preload("res://Scenes/planet_medium.tscn")
const PLANET_SMALL = preload("res://Scenes/planet_small.tscn")

var planets : Array = [PLANET_LARGE, PLANET_MEDIUM, PLANET_SMALL]
@export var active : bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.

var placing = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if not active:
			return
		if(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not placing):
			print("Editor click!")
			var planetToAdd = planets.pick_random().instantiate()
			planetToAdd.global_position = get_global_mouse_position()
			$".".add_child(planetToAdd)
			planetToAdd.owner = self
			placing = true
			
		elif(not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
			placing = false
			pass
		
