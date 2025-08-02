extends Control
class_name CollectableCounter

# This uses the % syntax for more reliable node references.
@onready var background_panel: Panel = $BackgroundPanel
@onready var icon_texture: TextureRect = $BackgroundPanel/VBoxContainer/HBoxContainer/IconTexture
@onready var count_label: Label = $BackgroundPanel/VBoxContainer/HBoxContainer/CountLabel
@onready var progress_bar: ProgressBar = $BackgroundPanel/VBoxContainer/ProgressBar

# This stores animation tweens.
var flash_tween: Tween
var pulse_tween: Tween

# This stores the texture for the collectable icon.
var collectable_icon: Texture2D = preload("res://Assets/kenney_simple-space/AAA-ChosenKenney/star_small.png")

func _ready():
	# This sets up the initial appearance of the UI.
	setup_ui_appearance()
	
	# This connects to the game manager's signal for collectable collection.
	if GameManager:
		GameManager.collectable_collected.connect(_on_collectable_collected)

func setup_ui_appearance():
	# This sets the collectable icon texture and color.
	if icon_texture:
		icon_texture.texture = collectable_icon
		icon_texture.modulate = Color.GOLD
	
	# This styles the background panel with a rounded, dark look.
	if background_panel:
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0, 0, 0, 0.7)
		style_box.corner_radius_top_left = 12
		style_box.corner_radius_top_right = 12
		style_box.corner_radius_bottom_left = 12
		style_box.corner_radius_bottom_right = 12
		style_box.border_width_left = 2
		style_box.border_width_right = 2
		style_box.border_width_top = 2
		style_box.border_width_bottom = 2
		style_box.border_color = Color.GOLD
		background_panel.add_theme_stylebox_override("panel", style_box)
	
	# This styles the text label.
	if count_label:
		count_label.add_theme_color_override("font_color", Color.WHITE)
		count_label.add_theme_font_size_override("font_size", 20)
	
	# This styles the progress bar.
	if progress_bar:
		progress_bar.modulate = Color.GOLD

func update_collectable_count(collected: int, total: int):
	# This is a check to make sure the label node was found correctly.
	if count_label == null:
		print("CRITICAL ERROR: 'count_label' in CollectableCounter.gd is null. Check the node path and name.")
		return
		
	# This updates the count label text.
	count_label.text = "%d/%d" % [collected, total]
	
	# This updates the progress bar value.
	if progress_bar:
		progress_bar.max_value = total
		progress_bar.value = collected
		
		# This changes the color of the bar when all items are collected.
		if collected == total and total > 0:
			progress_bar.modulate = Color.GREEN
			flash_completion()
		else:
			progress_bar.modulate = Color.GOLD

func flash_completion():
	# This creates a flashing effect when all collectables are gathered.
	if flash_tween:
		flash_tween.kill()
	
	flash_tween = create_tween()
	flash_tween.set_loops(3)
	flash_tween.tween_property(self, "modulate", Color.GREEN, 0.2)
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func flash_collection():
	# This creates a quick pulse effect when one collectable is gathered.
	if pulse_tween:
		pulse_tween.kill()
	
	pulse_tween = create_tween()
	pulse_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	
	# This also flashes the icon for emphasis.
	if icon_texture:
		var icon_tween = create_tween()
		icon_tween.tween_property(icon_texture, "modulate", Color.WHITE, 0.1)
		icon_tween.tween_property(icon_texture, "modulate", Color.GOLD, 0.3)

func _on_collectable_collected():
	# This triggers the collection flash when a collectable is collected.
	flash_collection()
