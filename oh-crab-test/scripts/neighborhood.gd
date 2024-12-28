# neighborhood.gd
extends Node2D

@onready var dialogue_ui = $Scene2
@onready var interaction_area = $InteractionArea

func _ready():
	# Explicitly hide dialogue at start
	if dialogue_ui:
		dialogue_ui.hide_dialogue()
		
	# Wait one frame before setting up interactions to ensure everything is initialized
	await get_tree().create_timer(0.1).timeout
	
	# Set up the interaction callbacks
	if interaction_area:
		interaction_area.on_interaction = func(): _on_interaction()
		interaction_area.on_exit = func(): _on_exit()

func _on_interaction():
	dialogue_ui.trigger_dialogue("Your dialogue text here!")

func _on_exit():
	dialogue_ui.hide_dialogue()
