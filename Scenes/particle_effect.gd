extends CPUParticles2D
class_name ParticleEffect

func Emit(excludeChildren : bool = false):
	emitting = true
	if(excludeChildren):
		return
	for child : CPUParticles2D in get_children().filter(func(a): return a is CPUParticles2D):
		child.emitting = true
	return

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
