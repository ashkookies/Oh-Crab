extends Node2D

@onready var trash_barrier = $TrashBarrier
@onready var barrier_detector = $TrashBarrier/DetectorArea
var dialogue_ui  # We'll find this in _ready
var trash_items = []
var required_trash_count = 0
var collected_trash_count = 0
var dialogue_cooldown = false

func _ready():
	print("DEBUG: TrashBarrierController _ready called")
	
	# Try different ways to find the dialogue UI
	dialogue_ui = _find_dialogue_node()
	if dialogue_ui:
		print("DEBUG: Dialogue UI found successfully")
	else:
		print("DEBUG: Failed to find Dialogue UI node!")
	
	# Initialize the barrier
	if trash_barrier:
		trash_barrier.visible = true
		trash_barrier.set_deferred("collision_layer", 1)
		trash_barrier.set_deferred("collision_mask", 1)
		print("DEBUG: Trash barrier initialized")
	else:
		print("DEBUG: Trash barrier node not found!")
	
	# Setup detector area
	if barrier_detector:
		barrier_detector.set_collision_layer_value(1, true)
		barrier_detector.set_collision_mask_value(1, true)
		barrier_detector.body_entered.connect(_on_detector_area_entered)
		print("DEBUG: Barrier detector initialized and connected")
	else:
		print("DEBUG: Barrier detector node not found!")
	
	# Get all trash items and connect signals
	trash_items = get_tree().get_nodes_in_group("trash")
	required_trash_count = trash_items.size()
	print("DEBUG: Found", required_trash_count, "trash items")
	
	for trash in trash_items:
		if not trash.is_connected("trash_collected", _on_trash_collected):
			trash.connect("trash_collected", _on_trash_collected)

func _find_dialogue_node() -> Node:
	# Try different paths to find the dialogue node
	var possible_paths = [
		"Dialogue",           # Direct child
		"../Dialogue",        # Sibling
		"../../Dialogue",     # Parent's sibling
		"/root/Game/Dialogue" # Absolute path
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node:
			print("DEBUG: Found dialogue at path:", path)
			return node
	
	# If we still haven't found it, try searching the scene tree
	var root = get_tree().root
	return _find_dialogue_in_tree(root)

func _find_dialogue_in_tree(node: Node) -> Node:
	if node.name == "Dialogue":
		return node
	
	for child in node.get_children():
		var result = _find_dialogue_in_tree(child)
		if result:
			return result
	
	return null

func _on_detector_area_entered(body):
	print("DEBUG: Something entered detector area:", body.name)
	if body.is_in_group("player"):
		print("DEBUG: Player detected at barrier")
		print("DEBUG: Collected trash:", collected_trash_count, "/", required_trash_count)
		if collected_trash_count < required_trash_count and not dialogue_cooldown:
			print("DEBUG: Showing reminder dialogue")
			show_reminder_dialogue()
		else:
			print("DEBUG: Not showing dialogue - Cooldown:", dialogue_cooldown)

func show_reminder_dialogue():
	print("DEBUG: Attempting to show dialogue")
	if dialogue_ui:
		print("DEBUG: Triggering dialogue UI")
		dialogue_ui.trigger_dialogue("(I need to get all the trash)")
		dialogue_cooldown = true
		
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(func():
			print("DEBUG: Hiding dialogue and resetting cooldown")
			dialogue_ui.hide_dialogue()
			dialogue_cooldown = false
		)
	else:
		print("DEBUG: Cannot show dialogue - dialogue_ui is null!")

func _on_trash_collected():
	collected_trash_count += 1
	print("DEBUG: Collected trash ", collected_trash_count, "/", required_trash_count)
	
	if collected_trash_count >= required_trash_count:
		remove_trash_barrier()

func remove_trash_barrier():
	if trash_barrier:
		print("DEBUG: Removing trash barrier - all trash collected")
		trash_barrier.visible = false
		trash_barrier.set_deferred("collision_layer", 0)
		trash_barrier.set_deferred("collision_mask", 0)
