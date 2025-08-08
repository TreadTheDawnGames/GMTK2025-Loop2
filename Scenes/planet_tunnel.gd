extends BasePlanet
class_name HollowPlanet
@onready var area_2d: Area2D = $Area2D


func _physics_process(delta: float) -> void:
	if current_orbiting_player and not global_position.distance_to(current_orbiting_player.global_position) < get_node("AnimatableBody2D/CollisionShape2D").shape.get_rect().size.x / 2:
		super._physics_process(delta)

func _ready() -> void:
	super._ready()
	area_2d.body_entered.connect(_skip)
	#rotation_degrees = randf_range(0,360)

func _skip(body):
	if current_orbiting_player:
		current_orbiting_player.points += 1
		current_orbiting_player.current_skips_available += 1
		print("skipped in planet")
