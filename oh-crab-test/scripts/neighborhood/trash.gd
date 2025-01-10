extends Node2D
signal trash_collected

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var empty_trash: TileMap = $EmptyTrash
@onready var half_empty_trash: TileMap = $HalfEmptyTrash
@onready var full_trash: TileMap = $FullTrash
@onready var prompt_label: Label = $PromptLabel
@onready var collection_label: Label = $CollectionLabel

# Enum for trash states
enum TrashState { FULL, HALF_EMPTY, EMPTY }

# Export variables for inspector configuration
@export var initial_state: TrashState = TrashState.FULL
@export var flip_horizontally: bool = false
@export var is_interactable: bool = true  # New exported variable

var current_state: TrashState
var can_interact: bool = false
var is_collected: bool = false
var original_scale: Vector2
var original_position: Vector2

func _ready():
	interaction_area.on_interaction = Callable(self, "_on_interact")
	interaction_area.on_exit = Callable(self, "_on_exit_area")
	prompt_label.visible = false
	collection_label.visible = false
	
	# Store the original scale and position
	original_scale = empty_trash.scale
	original_position = empty_trash.position
	
	# Initialize states
	set_initial_trash_state()
	update_flip_state()

func set_flip_horizontally(value: bool) -> void:
	flip_horizontally = value
	if is_node_ready():
		update_flip_state()

func set_initial_trash_state():
	current_state = initial_state
	update_trash_visibility()

func update_flip_state():
	if not (empty_trash and half_empty_trash and full_trash):
		return
	
	# Apply flip while preserving original scale
	var target_scale = original_scale
	target_scale.x = -abs(original_scale.x) if flip_horizontally else abs(original_scale.x)
	
	# Calculate the width of the tilemap
	var tile_size = empty_trash.tile_set.tile_size.x
	var used_cells = empty_trash.get_used_cells(0)  # 0 is the default layer
	var width = 0
	if used_cells.size() > 0:
		width = tile_size  # Assuming the trash is 1 tile wide
	
	# Calculate the correct offset
	var offset = width if flip_horizontally else 0
	var new_position = original_position
	new_position.x += offset if flip_horizontally else 0
	
	# Apply scale and position to all tilemaps
	for tilemap in [empty_trash, half_empty_trash, full_trash]:
		tilemap.scale = target_scale
		tilemap.position = new_position

func update_trash_visibility():
	# Hide all tilemaps first
	empty_trash.visible = false
	half_empty_trash.visible = false
	full_trash.visible = false
	
	# Show only the current state's tilemap
	match current_state:
		TrashState.FULL:
			full_trash.visible = true
		TrashState.HALF_EMPTY:
			half_empty_trash.visible = true
		TrashState.EMPTY:
			empty_trash.visible = true

func _on_interact():
	if not is_collected and is_interactable:  # Modified to check is_interactable
		show_prompt("[F] to pick up trash")
		can_interact = true

func _on_exit_area():
	if not is_collected:
		prompt_label.visible = false
	can_interact = false

func _process(delta: float):
	if can_interact and Input.is_action_just_pressed("interact") and not is_collected and is_interactable:  # Modified to check is_interactable
		collect_trash()

func collect_trash():
	print("+1 Trash")
	current_state = TrashState.EMPTY
	update_trash_visibility()
	is_collected = true
	can_interact = false
	prompt_label.visible = false
	show_collection_message("+1 Trash")
	emit_signal("trash_collected")

func show_prompt(message: String):
	prompt_label.text = message
	prompt_label.visible = true

func show_collection_message(message: String):
	collection_label.text = message
	collection_label.visible = true
	await get_tree().create_timer(2.0).timeout
	collection_label.visible = false
