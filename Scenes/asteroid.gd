extends RigidBody2D
class_name Asteroid

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
@export var FixSpeed = 6000


func Launch(dir : Vector2):
	apply_central_impulse(dir * FixSpeed)

#func _physics_process(delta: float) -> void:
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Vector2(Input.get_axis("DEBUG-LEFT", "DEBUG-RIGHT"), Input.get_axis("DEBUG-UP", "DEBUG-DOWN"))
	#if direction:
		#linear_velocity = direction * SPEED
	#else:
		#linear_velocity = lerp(linear_velocity, Vector2.ZERO, 0.5)
