extends Line2D

var queue : Array = []
@export var MAX_LENGTH : int
func _process(_delta):
	var pos = global_position
	
	queue.push_front(pos)
	if queue.size() > MAX_LENGTH:
		queue.pop_back()
		
	clear_points()
	
	for point in queue:
		add_point(pos)
