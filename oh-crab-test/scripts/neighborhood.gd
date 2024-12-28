extends Node2D

@onready var dialogue_ui = $Dialogue
@onready var interaction_area_2 = $Scene2
@onready var interaction_area_3 = $Scene3
@onready var player = $Player
@onready var truck = $Truck
@onready var barrier = $Barrier
@onready var barrier_area = $Barrier/CollisionArea  # New Area2D node

var player_can_move = true
var dialogue_active = false
var has_triggered_scene2 = false
var has_triggered_scene3 = false
var is_truck_leaving = false
var dialogue_step = 0
var current_scene = 0
var barrier_dialogue_cooldown = false

# New variables for truck movement
var truck_target_x = 500
var truck_initial_x = 0

func _ready():
	print("DEBUG: _ready called")
	if dialogue_ui:
		dialogue_ui.hide_dialogue()
	
	if truck:
		truck_initial_x = truck.position.x
	
	# Initially hide the barrier
	if barrier:
		barrier.visible = false
		barrier.set_deferred("disabled", true)
	
	# Connect the Area2D signal
	if barrier_area:
		barrier_area.body_entered.connect(_on_barrier_area_entered)
	
	await get_tree().create_timer(0.1).timeout
	
	if interaction_area_2:
		interaction_area_2.on_interaction = func(): on_interaction_scene2()
	if interaction_area_3:
		interaction_area_3.on_interaction = func(): on_interaction_scene3()

# Updated function name to match the Area2D
func _on_barrier_area_entered(body):
	if body == player and not barrier_dialogue_cooldown:
		show_barrier_dialogue()
		barrier_dialogue_cooldown = true
		# Reset cooldown after 2 seconds to prevent spam
		await get_tree().create_timer(2.0).timeout
		barrier_dialogue_cooldown = false

func show_barrier_dialogue():
	var dialogue_messages = [
		"I can't go this way, the truck already left!",
		"There must be another way...",
		"Mom's going to be so mad if I don't catch up to that truck!"
	]
	# Randomly select one of the messages
	var random_message = dialogue_messages[randi() % dialogue_messages.size()]
	dialogue_ui.trigger_dialogue(random_message)
	await get_tree().create_timer(2.0).timeout
	dialogue_ui.hide_dialogue()

func _physics_process(delta):
	if is_truck_leaving and truck:
		if truck.position.x < truck_target_x:
			truck.position.x += 100 * delta
		else:
			is_truck_leaving = false
			activate_barrier()
			print("DEBUG: Truck stopped, barrier activated")

func activate_barrier():
	if barrier:
		print("DEBUG: ACTIVATING barrier - Scene:", current_scene, " Step:", dialogue_step)
		barrier.visible = true
		barrier.set_deferred("disabled", false)
	else:
		print("DEBUG: Failed to activate barrier - barrier node is null")

func deactivate_barrier():
	if barrier:
		print("DEBUG: DEACTIVATING barrier - Scene:", current_scene, " Step:", dialogue_step)
		# Force all possible ways to disable the barrier
		barrier.visible = false
		barrier.process_mode = Node.PROCESS_MODE_DISABLED
		barrier.set_deferred("disabled", true)
		barrier.set_deferred("collision_layer", 0)
		barrier.set_deferred("collision_mask", 0)
		
		# Print barrier properties to verify changes
		print("DEBUG: Barrier properties after deactivation:")
		print("- visible:", barrier.visible)
		print("- process_mode:", barrier.process_mode)
		print("- collision_layer:", barrier.collision_layer)
		print("- collision_mask:", barrier.collision_mask)
	else:
		print("DEBUG: Failed to deactivate barrier - barrier node is null")

func _input(event):
	if dialogue_active or (current_scene == 2 and dialogue_step == 5) or (current_scene == 3 and dialogue_step == 4):
		if event.is_action_pressed("ui_accept"):
			print("DEBUG: Dialog advance triggered. Current step: ", dialogue_step)
			end_dialogue()
			get_viewport().set_input_as_handled()

func on_interaction_scene2():
	if not has_triggered_scene2:
		current_scene = 2
		dialogue_step = 0
		show_next_dialogue()
		player_can_move = false
		dialogue_active = true
		has_triggered_scene2 = true
		
		if player and player.has_method("set_can_move"):
			player.set_can_move(false)

func on_interaction_scene3():
	if not has_triggered_scene3 and has_triggered_scene2:
		current_scene = 3
		dialogue_step = 0
		show_next_dialogue()
		player_can_move = false
		dialogue_active = true
		has_triggered_scene3 = true
		
		if player and player.has_method("set_can_move"):
			player.set_can_move(false)

func show_next_dialogue():
	print("DEBUG: Starting dialogue step:", dialogue_step, " in scene:", current_scene)
	
	if current_scene == 2:
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
	elif current_scene == 3:
		match dialogue_step:
			0:
				dialogue_ui.trigger_dialogue("Mom… The garbage truck already left…")
			1:
				dialogue_ui.trigger_dialogue("Mom: Boy if you don't want to end up being the one inside the trash bag instead, then RUN!")
			2:
				dialogue_ui.trigger_dialogue("OKAY CHILL!!!!")
			3:
				dialogue_ui.trigger_dialogue("Ugh, what a way to start my morning")
				# Deactivate barrier before the last dialogue step
				deactivate_barrier()
			4:
				return
	
	dialogue_step += 1

func start_truck_movement():
	print("DEBUG: start_truck_movement called")
	is_truck_leaving = true
	if truck:
		print("DEBUG: Truck found at position: ", truck.position)
	else:
		print("DEBUG: Truck node is null!")

func end_dialogue():
	print("DEBUG: end_dialogue called with step:", dialogue_step, " in scene:", current_scene)
	dialogue_ui.hide_dialogue()
	
	var max_steps = 5 if current_scene == 2 else 4
	
	if dialogue_step < max_steps:
		print("DEBUG: Moving to next dialogue")
		show_next_dialogue()
	else:
		if current_scene == 2:
			start_truck_movement()
		
		# Make sure barrier is deactivated at the end of scene 3
		if current_scene == 3:
			print("DEBUG: Final check - deactivating barrier")
			deactivate_barrier()
			
		print("DEBUG: Dialogue complete, enabling player movement")
		player_can_move = true
		dialogue_active = false
		await get_tree().create_timer(0.1).timeout
		if player and player.has_method("set_can_move"):
			player.set_can_move(true)
