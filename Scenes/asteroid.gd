extends RigidBody2D
class_name Asteroid

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
@export var FixSpeed = 6000
@onready var Shape: CollisionShape2D = $CollisionShape2D
@onready var VisNotif: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	VisNotif.screen_exited.connect(queue_free)

func Launch(dir : Vector2):
	apply_central_impulse(dir * FixSpeed)
