extends BasePlanet
class_name black_hole

func _ready() -> void: 
	super._ready()
	can_have_collectable = false

func _on_body_exited(body: Node2D) -> void:
	super(body)
	if body is Player:
		var player = body as Player
		player.points += 50
		PointNumbers.display_number(player.points, player.point_numbers_origin.global_position, 0)
