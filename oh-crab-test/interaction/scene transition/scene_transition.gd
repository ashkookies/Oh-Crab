# scene_transition.gd
extends Node
class_name SceneTransition

@export var next_scene_path: String = ""
@export var transition_delay: float = 0.0

func _ready() -> void:
	# Get the parent InteractionArea
	var interaction_area = get_parent()
	if not interaction_area is InteractionArea:
		push_error("SceneTransition must be a child of an InteractionArea!")
		return
		
	# Set up the transition callback
	interaction_area.on_interaction = func():
		if transition_delay > 0:
			get_tree().create_timer(transition_delay).timeout.connect(
				func(): _change_scene()
			)
		else:
			_change_scene()

func _change_scene() -> void:
	if not next_scene_path.is_empty():
		get_tree().change_scene_to_file(next_scene_path)
	else:
		push_error("Cannot transition: Next scene path is not set!")
