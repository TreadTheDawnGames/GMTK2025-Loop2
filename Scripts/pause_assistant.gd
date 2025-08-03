extends Node2D
@onready var hud: CanvasLayer = $"../HUDLayer"

var settings
const SETTINGS = preload("res://Scenes/UI/Settings.tscn")

func _process(delta):
	if(Input.is_action_just_pressed("Pause")):
		if(not is_instance_valid(settings)):
			settings = SETTINGS.instantiate()
			hud.add_child(settings)
			print("adding settings scene")
			get_tree().paused = true
		else:
			settings.queue_free()
			print("trying to add two settings screens")
			get_tree().paused = false
			
	return
