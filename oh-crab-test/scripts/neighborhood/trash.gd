#trash.gd
extends Node2D

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var sprite = $Sprite2D
@onready var prompt_label: Label = $PromptLabel  # Label above trash
@onready var collection_label: Label = $CollectionLabel  # Label in top-right

var can_interact: bool = false
var is_collected: bool = false

func _ready():
	interaction_area.on_interaction = Callable(self, "_on_interact")
	interaction_area.on_exit = Callable(self, "_on_exit_area")
	prompt_label.visible = false
	collection_label.visible = false
	
	# Set up the collection label in the top right
	collection_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	collection_label.position = Vector2(-100, 20)  # Adjust these values as needed

func _on_interact():
	if not is_collected:
		show_prompt("[F] to pick up trash")
		can_interact = true

func _on_exit_area():
	if not is_collected:
		prompt_label.visible = false
	can_interact = false

func _process(_delta: float):
	if can_interact and Input.is_action_just_pressed("interact") and not is_collected:
		collect_trash()

func collect_trash():
	print("Trash collected")
	sprite.visible = false
	is_collected = true
	can_interact = false
	prompt_label.visible = false
	show_collection_message("Trash collected")

func show_prompt(message: String):
	prompt_label.text = message
	prompt_label.visible = true

func show_collection_message(message: String):
	collection_label.text = message
	collection_label.visible = true
	await get_tree().create_timer(2.0).timeout
	collection_label.visible = false
