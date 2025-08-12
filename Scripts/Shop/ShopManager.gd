# res://Scripts/Shop/ShopManager.gd
extends CanvasLayer # This makes the shop a UI layer that draws on top of the game.
class_name ShopManager # This assigns a class name for easier referencing.

# These get references to the various UI nodes within the shop scene.
@onready var shop_panel: Panel = $Control/ShopPanel
@onready var items_container: VBoxContainer = $Control/ShopPanel/VBoxContainer/ScrollContainer/ItemsContainer
@onready var score_label: Label = $Control/ShopPanel/VBoxContainer/HeaderContainer/ScoreLabel
@onready var close_button: Button = $Control/ShopPanel/VBoxContainer/HeaderContainer/CloseButton
@onready var title_label: Label = $Control/ShopPanel/VBoxContainer/HeaderContainer/TitleLabel

## These preload the scripts for the new shop items.
#const ExtraSkipItem = preload("res://Scripts/Shop/ExtraSkipItem.gd")
#const OrbitCounterItem = preload("res://Scripts/Shop/OrbitCounterItem.gd")
## This is an existing item that will be kept.
#const StartingBoostsItem = preload("res://Scripts/Shop/StartingBoostsItem.gd")


var shop_items: Array[ShopItem] = [] # This array will hold all the available shop items.
var current_player: Player = null # This will hold a reference to the player when the shop is open.

signal shop_closed # This signal is emitted when the shop is closed.

# These variables are for purchase feedback animations and messages.
var score_flash_tween: Tween
var success_message_scene = preload("res://Scenes/UI/TutorialNotification.tscn")

# This function is called once when the node is added to the scene.
func _ready():
	# This tells the node to continue processing even when the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# This hides the shop UI by default.
	visible = false
	
	# This connects the close button's 'pressed' signal to the close_shop function.
	if close_button:
		close_button.pressed.connect(close_shop)
	
	# This calls the function to set up all the shop items.
	initialize_shop_items()
	
	# This connects to the GameManager's signal to update the score display when it changes.
	GameManager.score_changed.connect(_on_score_changed)

# This function creates instances of all the shop items.
func initialize_shop_items():
	# This function is no longer needed, as items are now managed by each HomePlanet.
	pass

# This function builds the UI for all items in the shop.
func create_shop_ui():
	# This clears any existing items from the container to prevent duplicates.
	for child in items_container.get_children():
		child.queue_free()
	
	# This loops through each shop item from the CURRENT planet and creates its UI representation.
	for item in shop_items:
		var item_ui = create_item_ui(item)
		items_container.add_child(item_ui)

# This function creates the specific UI for a single shop item.
func create_item_ui(item: ShopItem) -> Control:
	var item_container = HBoxContainer.new()
	item_container.custom_minimum_size = Vector2(0, 60)

	# This container holds the item's name and description.
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# This creates the label for the item's name.
	var name_label = Label.new()
	name_label.text = item.item_name
	name_label.add_theme_font_size_override("font_size", 16)
	info_container.add_child(name_label)

	# This creates the label for the item's description.
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	info_container.add_child(desc_label)

	item_container.add_child(info_container)
	
	# This handles regular, non-specialized shop items.
	# This creates the label for the item's cost.
	var cost_label = Label.new()
	cost_label.text = "Cost: %d pts" % item.get_current_cost()
	cost_label.add_theme_font_size_override("font_size", 12)
	info_container.add_child(cost_label)

	# This creates the purchase button for the item.
	var purchase_button = SoundButton.new()
	purchase_button.text = item.get_purchase_text()
	purchase_button.custom_minimum_size = Vector2(120, 50)
	purchase_button.disabled = not item.can_purchase()

	# This connects the button's 'pressed' signal to the purchase_item function.
	purchase_button.pressed.connect(func(): purchase_item(item, purchase_button, cost_label))

	item_container.add_child(purchase_button)

	return item_container

# This function opens the shop UI.
func open_shop(player: Player, from_planet: HomePlanet):
	current_player = player
	shop_items = from_planet.shop_items # Use the specific planet's inventory
	visible = true
	get_tree().paused = true
	create_shop_ui() # Rebuild the UI with the new items
	update_shop_display()

# This function closes the shop UI.
func close_shop():
	visible = false
	get_tree().paused = false # This unpauses the main game simulation.
	shop_closed.emit() # This emits a signal to notify that the shop has closed.

# This function is called when a purchase button is pressed.
func purchase_item(item: ShopItem, button: SoundButton, cost_label: Label):
	if not current_player:
		return

	if item.purchase(current_player):
		# This updates the button text and state after a successful purchase.
		button.text = item.get_purchase_text()
		button.disabled = not item.can_purchase()
		cost_label.text = "Cost: %d pts" % item.get_current_cost()

		# This updates the score display with a flashing effect.
		update_score_display()
		flash_score_label()

		# This shows a success message to the player.
		show_purchase_success_message(item.item_name)

		print("Purchased: %s" % item.item_name)
	else:
		print("Cannot purchase: %s" % item.item_name)

# This function updates all displayed information in the shop.
func update_shop_display():
	update_score_display()

	# This loops through all item UIs to update their states (e.g., if a button should be disabled).
	var item_uis = items_container.get_children()
	for i in range(min(shop_items.size(), item_uis.size())):
		var item = shop_items[i]
		var item_ui = item_uis[i]
		
		# This handles regular items.
		var button = item_ui.get_child(1) as SoundButton
		if button:
			button.text = item.get_purchase_text()
			button.disabled = not item.can_purchase()

		# This updates the cost label for items with dynamic costs.
		var info_container = item_ui.get_child(0)
		var cost_label = info_container.get_child(2) as Label
		if cost_label:
			cost_label.text = "Cost: %d pts" % item.get_current_cost()


# This function updates the score label with the current score from the GameManager.
func update_score_display():
	if score_label:
		# Use the comma-separated string function for consistency with the main HUD.
		score_label.text = "Score: " + GameHUD.comma_separated_string(GameManager.get_score())

# This function is called when the GameManager's score changes.
func _on_score_changed(_new_score: int):
	update_score_display()

	# This updates the state of all purchase buttons whenever the score changes.
	var item_uis = items_container.get_children()
	for i in range(min(shop_items.size(), item_uis.size())):
		var item = shop_items[i]
		var item_ui = item_uis[i]

		# This handles regular items.
		var button = item_ui.get_child(1) as SoundButton
		if button:
			button.disabled = not item.can_purchase()

# This function handles input events while the shop is open.
func _input(event):
	# This allows closing the shop with the Escape key or the "interact" key (E).
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact")):
		close_shop()

# This function creates a flashing effect on the score label.
func flash_score_label():
	if not score_label:
		return

	# This stops any ongoing flash animation.
	if score_flash_tween:
		score_flash_tween.kill()

	# This creates the new flash animation.
	score_flash_tween = create_tween()
	score_flash_tween.tween_property(score_label, "modulate", Color.GREEN, 0.1)
	score_flash_tween.tween_property(score_label, "modulate", Color.WHITE, 0.3)

# This function shows a success message after a purchase.
func show_purchase_success_message(item_name: String):
	# This plays a success sound.
	MusicManager.play_audio_omni("UpUIBeep")

	var success_message = success_message_scene.instantiate()
	add_child(success_message)

	# This positions the message near the top of the shop panel.
	success_message.position = Vector2(0, -100)

	# This sets the text and fades in the success message.
	success_message.tutorial_label.text = "✓ " + item_name + " purchased!"
	success_message.modulate.a = 0.0
	var fade_in_tween = success_message.create_tween()
	fade_in_tween.tween_property(success_message, "modulate:a", 1.0, success_message.fade_duration)
	success_message.fade_timer.start()
