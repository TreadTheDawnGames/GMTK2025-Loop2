extends ShopItem
class_name TrajectoryPredictionItem

# Trajectory Prediction shop item - enables curved launch line that shows gravity effects

func _init():
	setup_item()

func setup_item():
	item_name = "Trajectory Predictor"
	description = "Accounts for gravity effects"
	cost = 200
	max_purchases = 1

func apply_effect(player: Player) -> void:
	# Enable trajectory prediction on the player
	player.trajectory_prediction_enabled = true
	
	print("Trajectory prediction enabled! Launch line now shows gravity effects.")

func get_current_cost() -> int:
	return cost
