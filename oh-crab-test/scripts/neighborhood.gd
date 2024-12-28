extends Node2D

@onready var dialogue_ui = $Dialogue
@onready var interaction_area = $InteractionArea
@onready var player = $Player
@onready var truck = $Truck

var player_can_move = true
var dialogue_active = false
var has_triggered = false
var is_truck_leaving = false
var dialogue_step = 0

func _ready():
	print("DEBUG: _ready called")
	if dialogue_ui:
		dialogue_ui.hide_dialogue()
	
	await get_tree().create_timer(0.1).timeout
	
	if interaction_area:
		interaction_area.on_interaction = func(): on_interaction()

func _physics_process(delta):
	if is_truck_leaving and truck:
		print("DEBUG: Moving truck")
		truck.position.x += 100 * delta
		print("DEBUG: New truck position: ", truck.position)

func _input(event):
	# Block jump input while dialogue is active OR we're on the last step
	if dialogue_active or dialogue_step == 5:
		if event.is_action("jump"):
			get_viewport().set_input_as_handled()
			return
		
		if event.is_action_pressed("ui_accept"):
			print("DEBUG: Dialog advance triggered. Current step: ", dialogue_step)
			end_dialogue()
			# Prevent the event from propagating after handling dialogue
			get_viewport().set_input_as_handled()

func on_interaction():
	if not has_triggered:
		show_next_dialogue()
		player_can_move = false
		dialogue_active = true
		has_triggered = true
		
		if player and player.has_method("set_can_move"):
			player.set_can_move(false)

func show_next_dialogue():
	print("DEBUG: Starting dialogue step: ", dialogue_step)
	match dialogue_step:
		0:
			dialogue_ui.trigger_dialogue("(There's the truck!!)")
		1:
			dialogue_ui.trigger_dialogue("Hey!! I still have some trash here!")
		2:
			print("DEBUG: Reached final dialogue step")
			start_truck_movement()
		3: 
			dialogue_ui.trigger_dialogue("NOOOOO! Mom is gonna kill me T-T")
		4:
			dialogue_ui.trigger_dialogue("(I should just go back home)")
		5:
			return
	
	dialogue_step += 1
	print("DEBUG: Ending dialogue step: ", dialogue_step)

func start_truck_movement():
	print("DEBUG: start_truck_movement called")
	print("DEBUG: Before setting is_truck_leaving: ", is_truck_leaving)
	is_truck_leaving = true
	print("DEBUG: After setting is_truck_leaving: ", is_truck_leaving)
	if truck:
		print("DEBUG: Truck found at position: ", truck.position)
	else:
		print("DEBUG: Truck node is null!")

func end_dialogue():
	print("DEBUG: end_dialogue called with step: ", dialogue_step)
	dialogue_ui.hide_dialogue()
	
	if dialogue_step < 5:
		print("DEBUG: Moving to next dialogue")
		show_next_dialogue()
	else:
		start_truck_movement()
		# Only now do we fully enable player movement and disable dialogue control
		print("DEBUG: Dialogue complete, enabling player movement")
		player_can_move = true
		dialogue_active = false
		await get_tree().create_timer(0.1).timeout  # Small delay before enabling movement
		if player and player.has_method("set_can_move"):
			player.set_can_move(true)
