@tool
extends Node
class_name SceneTransition

# Reference the autoloaded singleton
@onready var scene_manager = get_node("/root/SceneManager")
@export var next_scene_path: String = ""
@export var transition_delay: float = 0.0

func _ready() -> void:
	# Get the parent InteractionArea
	var interaction_area = get_parent()
	if not interaction_area is InteractionArea:
		push_error("SceneTransition must be a child of an InteractionArea!")
		return
	
	# Set up the transition callback
	if interaction_area.has_method("set_interaction_callback"):
		interaction_area.set_interaction_callback(
			func():
				if transition_delay > 0:
					get_tree().create_timer(transition_delay).timeout.connect(
						func(): change_scene()
					)
				else:
					change_scene()
		)
	else:
		push_error("InteractionArea missing set_interaction_callback method!")

func change_scene() -> void:
	if next_scene_path.is_empty():
		push_error("Cannot transition: Next scene path is not set!")
		return
	
	scene_manager.change_scene(next_scene_path)  # Using the referenced singleton
