#interaction_area.gd
extends Area2D
class_name InteractionArea

@export var action_name: String = "interact"

var on_interaction: Callable = func(): pass
var on_exit: Callable = func(): pass

func _ready():
	area_entered.connect(_on_body_entered)
	area_exited.connect(_on_body_exited)

func _on_body_entered(_body: Node2D) -> void:
	on_interaction.call()

func _on_body_exited(_body: Node2D) -> void:
	on_exit.call()
