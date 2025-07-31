extends Area2D
class_name BasePlanet

# This exports a variable to the Godot editor, allowing to change it without code.
@export var gravity_strength: float = 6000.0

# This creates an array to store physics bodies that enter the gravity field.
var bodies_in_gravity_field: Array[RigidBody2D] = []


# This function runs every physics frame.
func _physics_process(delta: float) -> void:
	# This loops through every body currently stored in the array.
	for body in bodies_in_gravity_field:
		# This calculates the direction from the body towards this planet.
		var direction_to_planet = (global_position - body.global_position).normalized()

		# This calculates the force vector by combining direction and strength.
		var gravity_force = direction_to_planet * gravity_strength # * remap distance vs radius
		
		# This applies the calculated force to the center of the body.
		body.apply_central_force(gravity_force)


# This function runs when a body enters the Area2D's collision shape.
func _on_body_entered(body: Node2D) -> void:
	# This checks if the entering node is a RigidBody2D.
	if body is RigidBody2D:
		# This checks if the body is not already in the tracking array.
		if not body in bodies_in_gravity_field:
			# This adds the body to the array so gravity will affect it.
			bodies_in_gravity_field.append(body)


# This function runs when a body exits the Area2D's collision shape.
func _on_body_exited(body: Node2D) -> void:
	# This checks if the exiting body is in the tracking array.
	if body in bodies_in_gravity_field:
		# This removes the body from the array, stopping the gravity effect.
		bodies_in_gravity_field.erase(body)
