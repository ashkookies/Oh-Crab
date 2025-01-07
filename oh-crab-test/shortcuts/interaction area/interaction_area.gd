# interaction_area.gd
@tool
extends Area2D
class_name InteractionArea

@export var event_index: int = 0
@export var action_name: String = "interact"

var on_interaction: Callable = func(): pass
var on_exit: Callable = func(): pass

func _ready():
	area_entered.connect(_on_body_entered)
	area_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	# Only trigger interaction if it's the player
	if body.is_in_group("player") and on_interaction.is_valid():
		on_interaction.call()

func _on_body_exited(body: Node2D) -> void:
	# Only trigger exit if it's the player
	if body.is_in_group("player") and on_exit.is_valid():
		on_exit.call()

func set_interaction_callback(callback: Callable) -> void:
	if callback.is_valid():
		on_interaction = callback
	else:
		on_interaction = func(): pass

func set_exit_callback(callback: Callable) -> void:
	if callback.is_valid():
		on_exit = callback
	else:
		on_exit = func(): pass
