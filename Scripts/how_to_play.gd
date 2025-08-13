extends Control
@onready var rich_text_label: RichTextLabel = $Panel/RichTextLabel
@onready var button: Button = $Panel/Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(GameManager.IsMobile):
		rich_text_label.text = "Drag the screen to launch your ship\n\nTap the left side of the screen to boost.\n\nHold the right side to brake.\n\nWhen on a station (you spawn on one) tap it to open the shop.\n\nLoop as many unique planets as you can to maximize your score!\n\nYou win when you either score 2,500 points in one combo\nOR collect all artifacts."
	else:
		rich_text_label.text = "Drag the screen to launch your ship\n\nLeft click or spacebar to boost.\n\nRight click or shift to brake.\n\nWhen on a station (you spawn on one) press \"E\" or click it to open the shop.\n\nLoop as many unique planets as you can to maximize your score!\n\nYou win when you either score 2,500 points in one combo\nOR collect all artifacts."
	pass # Replace with function body.
	button.pressed.connect(queue_free)
