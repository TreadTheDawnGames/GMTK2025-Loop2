extends Control
class_name ShopManager

# Shop UI Manager

@onready var shop_panel: Panel = $ShopPanel
@onready var items_container: VBoxContainer = $ShopPanel/VBoxContainer/ScrollContainer/ItemsContainer
@onready var score_label: Label = $ShopPanel/VBoxContainer/HeaderContainer/ScoreLabel
@onready var close_button: Button = $ShopPanel/VBoxContainer/HeaderContainer/CloseButton
@onready var title_label: Label = $ShopPanel/VBoxContainer/HeaderContainer/TitleLabel

# Shop items
var shop_items: Array[ShopItem] = []
var current_player: Player = null

# Signals
signal shop_closed

func _ready():
	# Hide shop initially
	visible = false
	
	# Connect close button
	if close_button:
		close_button.pressed.connect(close_shop)
	
	# Initialize shop items
	initialize_shop_items()
	
	# Connect to score changes
	GameManager.score_changed.connect(_on_score_changed)

func initialize_shop_items():
	# Create shop items TODO Add more
	var magnet_item = MagnetItem.new()
	var boosts_item = StartingBoostsItem.new()
	var gravity_plus_item = GravityModifierItem.new()
	gravity_plus_item.gravity_type = GravityModifierItem.GravityType.INCREASE
	gravity_plus_item.setup_item()
	
	var gravity_minus_item = GravityModifierItem.new()
	gravity_minus_item.gravity_type = GravityModifierItem.GravityType.DECREASE
	gravity_minus_item.setup_item()
	
	shop_items = [magnet_item, boosts_item, gravity_plus_item, gravity_minus_item]
	
	# Create UI for each item
	create_shop_ui()

func create_shop_ui():
	# Clear existing items
	for child in items_container.get_children():
		child.queue_free()
	
	# Create UI for each shop item
	for item in shop_items:
		var item_ui = create_item_ui(item)
		items_container.add_child(item_ui)

func create_item_ui(item: ShopItem) -> Control:
	var item_container = HBoxContainer.new()
	item_container.custom_minimum_size = Vector2(0, 60)
	
	# Item info container
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Item name
	var name_label = Label.new()
	name_label.text = item.item_name
	name_label.add_theme_font_size_override("font_size", 16)
	info_container.add_child(name_label)
	
	# Item description
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	info_container.add_child(desc_label)
	
	# Cost label
	var cost_label = Label.new()
	cost_label.text = "Cost: %d pts" % item.get_current_cost()
	cost_label.add_theme_font_size_override("font_size", 12)
	info_container.add_child(cost_label)
	
	item_container.add_child(info_container)
	
	# Purchase button
	var purchase_button = Button.new()
	purchase_button.text = item.get_purchase_text()
	purchase_button.custom_minimum_size = Vector2(120, 50)
	purchase_button.disabled = not item.can_purchase()
	
	# Connect purchase button
	purchase_button.pressed.connect(func(): purchase_item(item, purchase_button, cost_label))
	
	item_container.add_child(purchase_button)
	
	return item_container

func open_shop(player: Player):
	current_player = player
	visible = true
	get_tree().paused = true
	update_shop_display()

func close_shop():
	visible = false
	get_tree().paused = false
	shop_closed.emit()

func purchase_item(item: ShopItem, button: Button, cost_label: Label):
	if not current_player:
		return
	
	if item.purchase(current_player):
		# Update button and cost display
		button.text = item.get_purchase_text()
		button.disabled = not item.can_purchase()
		cost_label.text = "Cost: %d pts" % item.get_current_cost()
		
		# Update score display
		update_score_display()
		
		print("Purchased: %s" % item.item_name)
	else:
		print("Cannot purchase: %s" % item.item_name)

func update_shop_display():
	update_score_display()
	
	# Update all item UIs
	var item_uis = items_container.get_children()
	for i in range(min(shop_items.size(), item_uis.size())):
		var item = shop_items[i]
		var item_ui = item_uis[i]
		
		# Update button state
		var button = item_ui.get_child(1) as Button
		if button:
			button.text = item.get_purchase_text()
			button.disabled = not item.can_purchase()
		
		# Update cost label
		var info_container = item_ui.get_child(0)
		var cost_label = info_container.get_child(2) as Label
		if cost_label:
			cost_label.text = "Cost: %d pts" % item.get_current_cost()

func update_score_display():
	if score_label:
		score_label.text = "Score: %d" % GameManager.get_score()

func _on_score_changed(new_score: int):
	update_score_display()
	
	# Update button states when score changes
	var item_uis = items_container.get_children()
	for i in range(min(shop_items.size(), item_uis.size())):
		var item = shop_items[i]
		var item_ui = item_uis[i]
		var button = item_ui.get_child(1) as Button
		if button:
			button.disabled = not item.can_purchase()

func _input(event):
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact")):
		close_shop()
