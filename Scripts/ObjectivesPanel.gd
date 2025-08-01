extends Control
class_name ObjectivesPanel

# Objective tracking
var objectives: Dictionary = {}
var objective_labels: Dictionary = {}

# Node references
@onready var objectives_container: VBoxContainer = $VBoxContainer
@onready var title_label: Label = $VBoxContainer/TitleLabel

func _ready() -> void:
	# Initialize objectives based on collectables in the scene
	call_deferred("scan_collectables_and_setup_objectives")

func scan_collectables_and_setup_objectives() -> void:
	# Count collectables by type in the scene
	var collectable_counts: Dictionary = {}
	
	# Find all collectables in the scene
	var collectables = get_tree().get_nodes_in_group("collectables")
	if collectables.is_empty():
		# Fallback: search for Collectable nodes
		collectables = find_all_collectables(get_tree().current_scene)
	
	# Count each type
	for collectable in collectables:
		if collectable is Collectable:
			var type_name = collectable.collection_name
			if type_name in collectable_counts:
				collectable_counts[type_name] += 1
			else:
				collectable_counts[type_name] = 1
			
			# Connect to collection signal
			collectable.collected.connect(_on_collectable_collected)
	
	# Set up objectives
	for type_name in collectable_counts:
		var total = collectable_counts[type_name]
		add_objective(type_name, 0, total)

func find_all_collectables(node: Node) -> Array:
	var collectables = []
	
	if node is Collectable:
		collectables.append(node)
	
	for child in node.get_children(true):
		collectables.append_array(find_all_collectables(child))
	
	return collectables

func add_objective(objective_name: String, current: int, target: int) -> void:
	# Store objective data
	objectives[objective_name] = {
		"current": current,
		"target": target,
		"completed": false
	}
	
	# Create label for this objective
	var objective_label = Label.new()
	objective_label.text = "%s: %d/%d" % [objective_name, current, target]
	
	# Style the label
	var label_settings = LabelSettings.new()
	label_settings.font_size = 16
	label_settings.outline_size = 2
	label_settings.outline_color = Color.BLACK
	objective_label.label_settings = label_settings
	
	# Add to container
	objectives_container.add_child(objective_label)
	objective_labels[objective_name] = objective_label

func update_objective(objective_name: String, new_current: int) -> void:
	if objective_name not in objectives:
		return
	
	var objective = objectives[objective_name]
	objective["current"] = new_current
	
	# Check if completed
	if new_current >= objective["target"] and not objective["completed"]:
		objective["completed"] = true
		print("Objective completed: %s" % objective_name)
	
	# Update label
	if objective_name in objective_labels:
		var label = objective_labels[objective_name]
		label.text = "%s: %d/%d" % [objective_name, new_current, objective["target"]]
		
		# Change color if completed
		if objective["completed"]:
			label.modulate = Color.GREEN
		else:
			label.modulate = Color.WHITE

func _on_collectable_collected(collectable: Collectable) -> void:
	var type_name = collectable.collection_name
	
	if type_name in objectives:
		var current = objectives[type_name]["current"]
		update_objective(type_name, current + 1)

func get_completion_status() -> Dictionary:
	var total_objectives = objectives.size()
	var completed_objectives = 0
	
	for objective_name in objectives:
		if objectives[objective_name]["completed"]:
			completed_objectives += 1
	
	return {
		"completed": completed_objectives,
		"total": total_objectives,
		"all_complete": completed_objectives == total_objectives
	}
