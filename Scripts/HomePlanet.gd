extends BasePlanet
class_name HomePlanet

@onready var Surface: Area2D = $Sprite/HomeArea
@export var StationSprite : Texture2D

# Shop interaction variables
var player_in_shop_range: bool = false
var current_player: Player = null

# Shop UI references
var shop_ui: ShopManager = null
var shop_prompt: ShopPrompt = null

# Home planet is now just a regular planet for navigation
# Win condition has been moved to collecting all collectables

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Sprite.texture = StationSprite

	# This connects to the Surface area signals for shop interaction
	if Surface:
		Surface.body_entered.connect(_on_shop_area_entered)
		Surface.body_exited.connect(_on_shop_area_exited)

	# This adds some test score for shop testing
	GameManager.add_score(500)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# This checks for E key press when player is in range
	if player_in_shop_range and current_player and Input.is_action_just_pressed("interact"):
		print("E key pressed, opening shop")
		open_shop()

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
		var _camera = current_player.get_node("Camera2D")
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
