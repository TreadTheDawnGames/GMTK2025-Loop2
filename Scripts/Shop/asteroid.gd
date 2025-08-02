extends RigidBody2D
class_name Asteroid

@export var FixSpeed = 6000
@onready var Shape: CollisionShape2D = $CollisionShape2D
@onready var VisNotif: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	VisNotif.screen_exited.connect(func(): 
		Player.isBeingSaved = false
		Player.softlockTimer = null
		queue_free()
		print("Bye bye!"))

func Launch(dir : Vector2):
	apply_central_impulse(dir * FixSpeed)
