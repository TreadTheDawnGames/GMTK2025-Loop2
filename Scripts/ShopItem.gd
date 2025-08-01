extends Resource
class_name ShopItem

# Base class for all shop items

@export var item_name: String = ""
@export var description: String = ""
@export var cost: int = 0
@export var icon: Texture2D = null
@export var is_purchased: bool = false
@export var max_purchases: int = 1  # -1 for unlimited
@export var current_purchases: int = 0

# Virtual function to be overridden by specific items
func apply_effect(player: Player) -> void:
	push_error("apply_effect() must be implemented by subclass")

# Check if item can be purchased
func can_purchase() -> bool:
	if is_purchased and max_purchases == 1:
		return false
	if max_purchases > 0 and current_purchases >= max_purchases:
		return false
	return GameManager.get_score() >= cost

# Purchase the item
func purchase(player: Player) -> bool:
	if not can_purchase():
		return false
	
	# Deduct cost
	GameManager.add_score(-cost)
	
	# Apply effect
	apply_effect(player)
	
	# Update purchase state
	current_purchases += 1
	if max_purchases == 1:
		is_purchased = true
	
	return true

# Get display text for purchase button
func get_purchase_text() -> String:
	if is_purchased and max_purchases == 1:
		return "PURCHASED"
	elif max_purchases > 1:
		return "BUY (%d/%d)" % [current_purchases, max_purchases]
	else:
		return "BUY - %d pts" % cost

# Get the current cost (might increase with multiple purchases)
func get_current_cost() -> int:
	return cost
