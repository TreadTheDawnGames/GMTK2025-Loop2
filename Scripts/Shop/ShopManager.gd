extends CanvasLayer
class_name ShopManager

# Shop UI Manager

@onready var shop_panel: Panel = $Control/ShopPanel
@onready var items_container: VBoxContainer = $Control/ShopPanel/VBoxContainer/ScrollContainer/ItemsContainer
@onready var score_label: Label = $Control/ShopPanel/VBoxContainer/HeaderContainer/ScoreLabel
@onready var close_button: Button = $Control/ShopPanel/VBoxContainer/HeaderContainer/CloseButton
@onready var title_label: Label = $Control/ShopPanel/VBoxContainer/HeaderContainer/TitleLabel

# Shop items
var shop_items: Array[ShopItem] = []
var current_player: Player = null

# Signals
signal shop_closed

func _ready():
	# This tells the node to keep running even when the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# This hides shop initially
	visible = false
	
	# This connects close button
	if close_button:
		close_button.pressed.connect(close_shop)
	
	# This initializes shop items
	initialize_shop_items()
	
	# This connects to score changes
	GameManager.score_changed.connect(_on_score_changed)

func initialize_shop_items():
	# This creates shop items TODO Add more
	var magnet_item = MagnetItem.new()
	var boosts_item = StartingBoostsItem.new()
	var gravity_upgrade_item = GravityUpgradeItem.new()

	shop_items = [magnet_item, boosts_item, gravity_upgrade_item]

	# This creates UI for each item
	create_shop_ui()

func create_shop_ui():
	# This clears existing items
	for child in items_container.get_children():
		child.queue_free()
	
	# This creates UI for each shop item
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

	item_container.add_child(info_container)

	# Special handling for GravityUpgradeItem
	if item is GravityUpgradeItem:
		var gravity_item = item as GravityUpgradeItem

		# Create button container
		var button_container = VBoxContainer.new()

		# Level display
		var level_label = Label.new()
		level_label.text = "Level: %d (-3 to 3)" % gravity_item.get_current_level()
		level_label.add_theme_font_size_override("font_size", 12)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button_container.add_child(level_label)

		# Button row container
		var button_row = HBoxContainer.new()

		# Minus button
		var minus_button = Button.new()
		minus_button.text = "-"
		minus_button.custom_minimum_size = Vector2(50, 40)
		minus_button.disabled = not gravity_item.can_downgrade()
		minus_button.pressed.connect(func(): downgrade_gravity(gravity_item, minus_button, level_label))
		button_row.add_child(minus_button)

		# Plus button
		var plus_button = Button.new()
		plus_button.text = "+"
		plus_button.custom_minimum_size = Vector2(50, 40)
		plus_button.disabled = not gravity_item.can_upgrade()
		plus_button.pressed.connect(func(): upgrade_gravity(gravity_item, plus_button, level_label))
		button_row.add_child(plus_button)

		button_container.add_child(button_row)

		# Cost info
		var cost_label = Label.new()
		cost_label.text = "120 pts/level"
		cost_label.add_theme_font_size_override("font_size", 10)
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button_container.add_child(cost_label)

		item_container.add_child(button_container)
	else:
		# Regular item handling
		# Cost label
		var cost_label = Label.new()
		cost_label.text = "Cost: %d pts" % item.get_current_cost()
		cost_label.add_theme_font_size_override("font_size", 12)
		info_container.add_child(cost_label)

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

func upgrade_gravity(gravity_item: GravityUpgradeItem, plus_button: Button, level_label: Label):
	if not current_player:
		return

	if gravity_item.upgrade_gravity(current_player):
		# Update UI
		level_label.text = "Level: %d (-3 to 3)" % gravity_item.get_current_level()
		plus_button.disabled = not gravity_item.can_upgrade()

		# Update minus button (find it as sibling)
		var button_row = plus_button.get_parent()
		var minus_button = button_row.get_child(0) as Button
		if minus_button:
			minus_button.disabled = not gravity_item.can_downgrade()

		# Update score display
		update_score_display()

func downgrade_gravity(gravity_item: GravityUpgradeItem, minus_button: Button, level_label: Label):
	if not current_player:
		return

	if gravity_item.downgrade_gravity(current_player):
		# Update UI
		level_label.text = "Level: %d (-3 to 3)" % gravity_item.get_current_level()
		minus_button.disabled = not gravity_item.can_downgrade()

		# Update plus button (find it as sibling)
		var button_row = minus_button.get_parent()
		var plus_button = button_row.get_child(1) as Button
		if plus_button:
			plus_button.disabled = not gravity_item.can_upgrade()

		# Update score display
		update_score_display()

func update_shop_display():
	update_score_display()

	# Update all item UIs
	var item_uis = items_container.get_children()
	for i in range(min(shop_items.size(), item_uis.size())):
		var item = shop_items[i]
		var item_ui = item_uis[i]

		if item is GravityUpgradeItem:
			# Handle GravityUpgradeItem special case
			var gravity_item = item as GravityUpgradeItem
			var button_container = item_ui.get_child(1)
			var level_label = button_container.get_child(0) as Label
			var button_row = button_container.get_child(1)
			var minus_button = button_row.get_child(0) as Button
			var plus_button = button_row.get_child(1) as Button

			if level_label:
				level_label.text = "Level: %d (-3 to 3)" % gravity_item.get_current_level()
			if minus_button:
				minus_button.disabled = not gravity_item.can_downgrade()
			if plus_button:
				plus_button.disabled = not gravity_item.can_upgrade()
		else:
			# Handle regular items
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

func _on_score_changed(_new_score: int):
	update_score_display()

	# Update button states when score changes
	var item_uis = items_container.get_children()
	for i in range(min(shop_items.size(), item_uis.size())):
		var item = shop_items[i]
		var item_ui = item_uis[i]

		if item is GravityUpgradeItem:
			# Handle GravityUpgradeItem special case
			var gravity_item = item as GravityUpgradeItem
			var button_container = item_ui.get_child(1)
			var button_row = button_container.get_child(1)
			var minus_button = button_row.get_child(0) as Button
			var plus_button = button_row.get_child(1) as Button

			if minus_button:
				minus_button.disabled = not gravity_item.can_downgrade()
			if plus_button:
				plus_button.disabled = not gravity_item.can_upgrade()
		else:
			# Handle regular items
			var button = item_ui.get_child(1) as Button
			if button:
				button.disabled = not item.can_purchase()

func _input(event):
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact")):
		close_shop()
