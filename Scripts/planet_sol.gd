extends BasePlanet
class_name Planet_Sol
@onready var DeathZone: Area2D = $Area2D

func _ready() -> void: 
	super._ready()
	can_have_collectable = false
	DeathZone.body_entered.connect(DoPlayerDeath)
	
func DoPlayerDeath(node : Node2D):
	if node is Player:
		node.Explode(global_position)
	return
