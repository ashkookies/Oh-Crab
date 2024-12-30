extends Node2D

@onready var dialogue_ui = $Dialogue
@onready var interaction_area_2 = $Scene2
@onready var interaction_area_3 = $Scene3
@onready var player = $Player
@onready var truck = $Truck
@onready var barrier = $Barrier
@onready var barrier_area = $Barrier/CollisionShape2D

var player_can_move = false  # Changed to start false
var dialogue_active = false
var has_triggered_scene2 = false
var has_triggered_scene3 = false
var is_truck_leaving = false
var dialogue_step = 0
var current_scene = 1  # Start with intro scene
var barrier_dialogue_cooldown = false
var waiting_for_timer = false

var truck_target_x = 500
var truck_initial_x = 0

func _ready():
	print("DEBUG: _ready called")
	current_scene = 1
	player_can_move = false
	dialogue_active = true
	dialogue_step = 0
	
	if player and player.has_method("set_can_move"):
		player.set_can_move(false)
	
	if dialogue_ui:
		show_intro_dialogue()
	
	if truck:
		truck_initial_x = truck.position.x
	
	if barrier:
		barrier.visible = false
		barrier.set_deferred("disabled", true)
	
	if interaction_area_2:
		interaction_area_2.on_interaction = func(): on_interaction_scene2()
	if interaction_area_3:
		interaction_area_3.on_interaction = func(): on_interaction_scene3()

func show_intro_dialogue():
	if dialogue_ui:
		match dialogue_step:
			0:
				dialogue_ui.trigger_dialogue("Oh no! I forgot to take out the trash!")
			1:
				dialogue_ui.trigger_dialogue("The truck should be here any minute now...")
			2:
				dialogue_ui.trigger_dialogue("I better hurry!")
			_:
				end_intro_dialogue()
				return

func end_intro_dialogue():
	dialogue_ui.hide_dialogue()
	player_can_move = true
	dialogue_active = false
	current_scene = 0
	dialogue_step = 0
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)


func _input(event):
	if dialogue_active and event.is_action_pressed("ui_accept"):
		if not waiting_for_timer:
			if current_scene == 1:
				dialogue_step += 1
				show_intro_dialogue()
			else:
				end_dialogue()
			get_viewport().set_input_as_handled()

func _on_barrier_area_entered(body):
	print("DEBUG: Barrier collision detected with:", body.name if body else "null")
	if body == player and dialogue_ui:
		print("DEBUG: Showing barrier dialogue")
		dialogue_ui.trigger_dialogue("I should go back home.")
		# Hide dialogue after 2 seconds
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
		
		if barrier_area:
			if barrier_area.body_entered.is_connected(_on_barrier_area_entered):
				barrier_area.body_entered.disconnect(_on_barrier_area_entered)
			barrier_area.body_entered.connect(_on_barrier_area_entered)
			print("DEBUG: Barrier collision signal connected")
	else:
		print("DEBUG: Failed to activate barrier - barrier node is null")

func deactivate_barrier():
	if barrier:
		print("DEBUG: DEACTIVATING barrier - Scene:", current_scene, " Step:", dialogue_step)
		barrier.visible = false
		barrier.process_mode = Node.PROCESS_MODE_DISABLED
		barrier.set_deferred("disabled", true)
		barrier.set_deferred("collision_layer", 0)
		barrier.set_deferred("collision_mask", 0)
		
		print("DEBUG: Barrier properties after deactivation:")
		print("- visible:", barrier.visible)
		print("- process_mode:", barrier.process_mode)
		print("- collision_layer:", barrier.collision_layer)
		print("- collision_mask:", barrier.collision_mask)
	else:
		print("DEBUG: Failed to deactivate barrier - barrier node is null")

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
				waiting_for_timer = false
			1:
				dialogue_ui.trigger_dialogue("Hey!! I still have some trash here!")
				waiting_for_timer = true
				var timer = get_tree().create_timer(1.5)
				await timer.timeout
				waiting_for_timer = false
				dialogue_step += 1
				show_next_dialogue()
			2:
				print("DEBUG: Reached final dialogue step")
				start_truck_movement()
				waiting_for_timer = true
				var timer = get_tree().create_timer(1.5)
				await timer.timeout
				waiting_for_timer = false
				dialogue_step += 1
				show_next_dialogue()
			3:
				dialogue_ui.trigger_dialogue("NOOOOO! Mom is gonna kill me T-T")
				waiting_for_timer = false
			4:
				dialogue_ui.trigger_dialogue("(I should just go back home)")
				waiting_for_timer = false
				dialogue_step += 1
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
				deactivate_barrier()
			_:
				return

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
		dialogue_step += 1
		show_next_dialogue()
	else:
		dialogue_ui.hide_dialogue()
		if current_scene == 3:
			print("DEBUG: Final check - deactivating barrier")
			deactivate_barrier()
			
		print("DEBUG: Dialogue complete, enabling player movement")
		player_can_move = true
		dialogue_active = false
		var timer = get_tree().create_timer(0.1)
		await timer.timeout
		if player and player.has_method("set_can_move"):
			player.set_can_move(true)
