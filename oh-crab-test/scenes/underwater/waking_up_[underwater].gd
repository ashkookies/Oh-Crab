extends Node2D

@onready var dialogue_ui = $Dialogue
@onready var player = $Player
var player_can_move = false
var dialogue_step = 0
var scene9_dialogue_step = 0
var dialogue_active = false
var current_scene = 0

func _ready() -> void:
	if dialogue_ui:
		player = get_tree().get_first_node_in_group("player")
		show_intro_dialogue()
		
		# Set up Scene9 interaction area
		var scene9_area = get_node("Scene9")
		if scene9_area:
			scene9_area.set_interaction_callback(start_scene9_dialogue)

func show_intro_dialogue():
	if not dialogue_ui:
		return
	
	dialogue_active = true
	print("DEBUG: Showing intro dialogue step:", dialogue_step)
	dialogue_ui.visible = true
	
	match dialogue_step:
		0:
			dialogue_ui.trigger_dialogue("Wadahell where am I? Why is it so dark?")
		1:
			dialogue_ui.trigger_dialogue("(Did I sleep for the whole day!?! Mom is gonna kill me)")
		2:
			dialogue_ui.trigger_dialogue("(Huh wait..something doesn't feel right..)")
		3:
			dialogue_ui.trigger_dialogue("Oh! I'm a crab!?! Wahhhhh")
		4:
			dialogue_ui.trigger_dialogue("Okay…how do I get back home?")
		_:
			end_intro_dialogue()
			return

func start_scene9_dialogue():
	if not dialogue_ui or dialogue_active:
		return
		
	dialogue_active = true
	current_scene = 9  # Set current scene to 9 when starting Scene9 dialogue
	player_can_move = false
	if player and player.has_method("set_can_move"):
		player.set_can_move(false)
	
	dialogue_ui.visible = true
	show_scene9_dialogue()

func show_scene9_dialogue():
	if not dialogue_ui:
		return
	
	print("DEBUG: Showing Scene9 dialogue step:", scene9_dialogue_step)
	
	match scene9_dialogue_step:
		0:
			dialogue_ui.trigger_dialogue("(Was that an animal in a plastic cup?)")
		1:
			dialogue_ui.trigger_dialogue("Oh, I can pick them up? Maybe I should clean a little this is getting sad…")
		2:
			dialogue_ui.trigger_dialogue("Baby hermit crab:  Hey get away! That's mine!")
		3:
			dialogue_ui.trigger_dialogue("Huh?")
		4:
			dialogue_ui.trigger_dialogue("Baby hermit crab: Mommy said that's for me! Arghhh get away")
		5:
			dialogue_ui.trigger_dialogue("Hermit crab mother: Honey! Come back here!")
		6:
			dialogue_ui.trigger_dialogue("Hermit crab mother: It's okay, we can find your home somewhere else. Let's not fight with this nice gentlemen.")
		7:
			dialogue_ui.trigger_dialogue("Parent crab: Are there no other shells?")
		8:
			dialogue_ui.trigger_dialogue("Let's go look for shells. There were a lot of them over there earlier.")
		9:
			dialogue_ui.trigger_dialogue("Okay, I’ll wait here. Thank you.")
		_:
			end_scene9_dialogue()
			return

func _input(event):
	if dialogue_active and event.is_action_pressed("ui_accept"):
		if current_scene == 9:
			advance_scene9_dialogue()
		else:
			advance_dialogue()

func advance_dialogue():
	dialogue_step += 1
	show_intro_dialogue()

func advance_scene9_dialogue():
	scene9_dialogue_step += 1
	show_scene9_dialogue()

func end_scene9_dialogue():
	if not dialogue_ui:
		return
	
	print("DEBUG: Ending Scene9 dialogue")
	dialogue_ui.hide_dialogue()
	
	player_can_move = true
	dialogue_active = false
	scene9_dialogue_step = 0
	current_scene = 0
	
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)

func end_intro_dialogue():
	if not dialogue_ui:
		return
	
	print("DEBUG: Ending intro dialogue")
	dialogue_ui.hide_dialogue()
	
	player_can_move = true
	dialogue_active = false
	current_scene = 0
	dialogue_step = 0
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)
