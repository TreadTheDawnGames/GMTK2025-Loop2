extends Node2D
class_name PlayerAudioHandler

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func PlaySoundAtGlobalPosition(sound : AudioStream, globPos : Vector2, busName : String = "SFX"):
	if(not sound):
		DisplayServer.beep()
	
	var audioPlayer : AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	audioPlayer.stream = sound
	audioPlayer.global_position = globPos
	audioPlayer.autoplay = true
	audioPlayer.pitch_scale = randf_range(1.0, 1.5)
	audioPlayer.bus = busName
	audioPlayer.finished.connect(func(): audioPlayer.queue_free())
	get_tree().root.add_child(audioPlayer)
