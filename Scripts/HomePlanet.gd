extends BasePlanet
class_name HomePlanet

@onready var Surface: Area2D = $ShopArea

# Shop interaction variables
var player_in_shop_range: bool = false
var current_player: Player = null
@onready var animatable_body_2d: AnimatableBody2D = $AnimatableBody2D

# Shop UI references
var shop_ui: ShopManager = null
var shop_prompt: ShopPrompt = null
var mouseOverShop = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# This calls the _ready function from the parent BasePlanet script.
	super._ready()
	
	# This connects the signals for the shop interaction area.
	if Surface:
		Surface.body_entered.connect(_on_shop_area_entered)
		Surface.body_exited.connect(_on_shop_area_exited)
		
		Surface.mouse_entered.connect(func(): mouseOverShop = true)
		Surface.mouse_exited.connect(func(): mouseOverShop = false)

var clickTimer:SceneTreeTimer
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# This checks for the interact key press when the player is in range to open the shop.
	if player_in_shop_range and current_player and Input.is_action_just_pressed("interact"):
		print("E key pressed, opening shop")
		open_shop()
	if(mouseOverShop and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		clickTimer = get_tree().create_timer(0.2)
		clickTimer.timeout.connect(func(): clickTimer = null)
	
	if(current_player and clickTimer and mouseOverShop and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and clickTimer.time_left > 0):
		open_shop()
		current_player.current_state = current_player.State.READY_TO_AIM
		current_player.linear_velocity = Vector2.ZERO
		mouseOverShop = false

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
		
		shop_prompt.shop_requested.connect(open_shop)
		
		# Add the newly created prompt to the main game scene.
		get_tree().current_scene.add_child(shop_prompt)

	# Check if the node is already in the tree before adding it.
	if not shop_prompt.is_inside_tree():
		print("Adding shop_prompt to the scene tree.")
		get_tree().current_scene.add_child(shop_prompt)
	else:
		print("Attempted to add shop_prompt, but it's already in the tree!")

	if shop_prompt and current_player:
		shop_prompt.show_prompt(self)

func hide_shop_prompt() -> void:
	if shop_prompt:
		shop_prompt.hide_prompt()

var shop_scene = preload("res://Scenes/Shop/Shop.tscn")
func open_shop() -> void:
	if not shop_ui:
		# This creates shop UI if it doesn't exist
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
