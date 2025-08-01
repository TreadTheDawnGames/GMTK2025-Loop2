extends BasePlanet
class_name HomePlanet

@onready var Surface: Area2D = $ShopArea

# Shop interaction variables
var player_in_shop_range: bool = false
var current_player: Player = null

# Shop UI references
var shop_ui: ShopManager = null
var shop_prompt: ShopPrompt = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# This calls the _ready function from the parent BasePlanet script.
	super._ready()
	
	# This connects the signals for the shop interaction area.
	if Surface:
		Surface.body_entered.connect(_on_shop_area_entered)
		Surface.body_exited.connect(_on_shop_area_exited)

	# This adds some test score for shop testing
	GameManager.add_score(500)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# This checks for the interact key press when the player is in range to open the shop.
	if player_in_shop_range and current_player and Input.is_action_just_pressed("interact"):
		print("E key pressed, opening shop")
		open_shop()

# This overrides the parent's spawning function to ensure home planets never have collectables.
func spawn_collectable_at_center():
	can_have_collectable = false
	# This function is left empty intentionally.
	pass

# Shop interaction functions
func _on_shop_area_entered(body: Node2D) -> void:
	if body is Player:
		print("Player entered shop area")
		player_in_shop_range = true
		current_player = body
		show_shop_prompt()

func _on_shop_area_exited(body: Node2D) -> void:
	if body is Player:
		print("Player exited shop area")
		player_in_shop_range = false
		current_player = null
		hide_shop_prompt()

func show_shop_prompt() -> void:
	if not shop_prompt:
		# This creates shop prompt if it doesn't exist
		var prompt_scene = preload("res://Scenes/Shop/ShopPrompt.tscn")
		shop_prompt = prompt_scene.instantiate()
		get_tree().current_scene.add_child(shop_prompt)

	# This shows the prompt at the home planet position
	if shop_prompt and current_player:
		shop_prompt.show_prompt(self)

func hide_shop_prompt() -> void:
	if shop_prompt:
		shop_prompt.hide_prompt()

func open_shop() -> void:
	if not shop_ui:
		# This creates shop UI if it doesn't exist
		var shop_scene = preload("res://Scenes/Shop/Shop.tscn")
		shop_ui = shop_scene.instantiate()
		get_tree().current_scene.add_child(shop_ui)
		shop_ui.shop_closed.connect(_on_shop_closed)

	if shop_ui and current_player:
		shop_ui.open_shop(current_player)
		hide_shop_prompt()

func close_shop() -> void:
	if shop_ui:
		shop_ui.close_shop()

func _on_shop_closed() -> void:
	# This shows prompt again when shop is closed if player is still in range
	if player_in_shop_range:
		show_shop_prompt()
