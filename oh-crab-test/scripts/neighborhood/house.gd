extends Node2D

@onready var dialogue_ui = $Dialogue
@onready var interaction_area_2 = $Scene2
@onready var interaction_area_3 = $Mom/InteractionArea
@onready var player = $Player
@onready var truck = $Truck
@onready var barrier = $Barrier
@onready var barrier_detector = $Barrier/DetectorArea
@onready var tutorial_group = $TutorialSprites
@onready var key_w = $TutorialSprites/W
@onready var key_a = $TutorialSprites/A
@onready var key_s = $TutorialSprites/S
@onready var key_d = $TutorialSprites/D
@onready var key_jump = $TutorialSprites/Space

var player_can_move = false
var dialogue_active = false
var has_triggered_scene2 = false
var has_triggered_scene3 = false
var is_truck_leaving = false
var dialogue_step = 0
var current_scene = 1  # Start with intro scene
var barrier_dialogue_cooldown = false
var waiting_for_timer = false
var showing_tutorial = false

var truck_target_x = 500
var truck_initial_x = 0

var current_tutorial_step = 0

var tutorial_sequence = [
	{
		"controls": ["horizontal"],  # Show A and D first
		"positions": {
			"a": Vector2(0, 0),   # A to the left
			"d": Vector2(100, 60)   # D to the right
		},
		"wait_for_input": true,     # Wait for A or D press
		"required_actions": ["move_left", "move_right"]
	},
	{
		"controls": ["vertical"],   # Show W and S next
		"positions": {
			"w": Vector2(60, 20),   # W above
			"s": Vector2(60, 60)    # S below
		},
		"duration": 2.0            # Show for 2 seconds
	},
	{
		"controls": ["jump"],      # Show jump key last
		"positions": {
			"jump": Vector2(60, 40)
		},
		"duration": 2.0           # Show for 2 seconds
	}
]

var waiting_for_tutorial_input = false
var required_tutorial_actions = []

func _ready():
	print("DEBUG: _ready called")
	current_scene = 1
	player_can_move = false
	dialogue_active = true
	dialogue_step = 0
	
	if interaction_area_2:
		interaction_area_2.body_entered.connect(_on_scene2_body_entered)
		print("DEBUG: Scene2 area signals connected")
		
	if interaction_area_3:
		interaction_area_3.body_entered.connect(_on_scene3_body_entered)
		print("DEBUG: Scene3 area signals connected")
	
	if player and player.has_method("set_can_move"):
		player.set_can_move(false)
	
	if dialogue_ui:
		show_intro_dialogue()
	
	if truck:
		truck_initial_x = truck.position.x
	
	if barrier:
		barrier.visible = false
		barrier.set_deferred("collision_layer", 0)
		barrier.set_deferred("collision_mask", 0)
		
		if barrier_detector:
			barrier_detector.body_entered.connect(_on_barrier_area_entered)
			print("DEBUG: Barrier detector signal connected")

	# Initialize tutorial sprites
	if tutorial_group:
		# Parent Node doesn't need visibility setting
		key_w.visible = false
		key_a.visible = false
		key_s.visible = false
		key_d.visible = false
		key_jump.visible = false
	set_process_input(true)

func show_intro_dialogue():
	if not dialogue_ui:
		return
	
	print("DEBUG: Showing intro dialogue step:", dialogue_step)
	dialogue_ui.visible = true  # Ensure UI is visible
	
	match dialogue_step:
		0:
			dialogue_ui.trigger_dialogue("uhh wahhh naur")
		1:
			dialogue_ui.trigger_dialogue("Mom: You've been rotting in your bed all morning! Get up and take out the trash NOW!")
		2:
			dialogue_ui.trigger_dialogue("UGGHHH I'll be there in a minute!")
		3:
			dialogue_ui.trigger_dialogue("Mom: The garbage truck will leave soon, don't come back if you can't throw it out in time!")
		4:
			dialogue_ui.trigger_dialogue("UghhhHHHHhhhhHHHHh FIiiIiIne")
		_:
			end_intro_dialogue()
			return

func end_intro_dialogue():
	if not dialogue_ui:
		return
	
	print("DEBUG: Ending intro dialogue")
	dialogue_ui.hide_dialogue()
	
	# Show tutorial sequence
	await get_tree().create_timer(0.5).timeout
	show_tutorial_sequence()
	
	player_can_move = true
	dialogue_active = false
	current_scene = 0
	dialogue_step = 0
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)

func show_tutorial_sequence():
	print("DEBUG: Starting tutorial sequence")
	showing_tutorial = true
	current_tutorial_step = 0
	show_current_tutorial_step()

func show_current_tutorial_step():
	if current_tutorial_step >= tutorial_sequence.size():
		end_tutorial_sequence()
		return
		
	var step = tutorial_sequence[current_tutorial_step]
	
	# Hide all keys first
	key_w.visible = false
	key_a.visible = false
	key_s.visible = false
	key_d.visible = false
	key_jump.visible = false
	
	# Show and position the required keys for this step
	for control in step.controls:
		match control:
			"horizontal":
				key_a.visible = true
				key_d.visible = true
				key_a.position = step.positions.a
				key_d.position = step.positions.d
				key_a.play("default")
				key_d.play("default")
				
				# Set up input waiting
				waiting_for_tutorial_input = true
				required_tutorial_actions = step.required_actions
				
			"vertical":
				key_w.visible = true
				key_s.visible = true
				key_w.position = step.positions.w
				key_s.position = step.positions.s
				key_w.play("default")
				key_s.play("default")
				
				# Use timer for this step
				if step.has("duration"):
					await get_tree().create_timer(step.duration).timeout
					advance_tutorial()
				
			"jump":
				key_jump.visible = true
				key_jump.position = step.positions.jump
				key_jump.play("default")
				
				# Use timer for this step
				if step.has("duration"):
					await get_tree().create_timer(step.duration).timeout
					advance_tutorial()

func end_tutorial_sequence():
	print("DEBUG: Ending tutorial sequence")
	# Stop all animations
	key_w.stop()
	key_a.stop()
	key_s.stop()
	key_d.stop()
	key_jump.stop()
	
	# Hide everything
	key_w.visible = false
	key_a.visible = false
	key_s.visible = false
	key_d.visible = false
	key_jump.visible = false
	showing_tutorial = false
	
	# Make sure player can move after tutorial
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)


func _input(event):
	# Handle tutorial input
	if waiting_for_tutorial_input and showing_tutorial:
		for action in required_tutorial_actions:
			if event.is_action_pressed(action):
				waiting_for_tutorial_input = false
				advance_tutorial()
				break
	
	# Keep existing input handling
	if event.is_action_pressed("ui_accept") and dialogue_active and not showing_tutorial:
		print("DEBUG: Advancing dialogue - Scene:", current_scene, " Step:", dialogue_step)
		dialogue_step += 1
		match current_scene:
			1: show_intro_dialogue()
			2, 3: show_next_dialogue()
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
			print("DEBUG: Truck stopped")  

func activate_barrier():
	if barrier:
		print("DEBUG: ACTIVATING barrier - Scene:", current_scene, " Step:", dialogue_step)
		barrier.visible = true
		# Enable collision on the StaticBody2D
		barrier.set_deferred("collision_layer", 1)
		barrier.set_deferred("collision_mask", 1)
		
		# Make sure detector is properly connected
		if barrier_detector and not barrier_detector.body_entered.is_connected(_on_barrier_area_entered):
			barrier_detector.body_entered.connect(_on_barrier_area_entered)
			print("DEBUG: Barrier detector signal connected")
	else:
		print("DEBUG: Failed to activate barrier - barrier node is null")

func deactivate_barrier():
	if barrier:
		print("DEBUG: DEACTIVATING barrier - Scene:", current_scene, " Step:", dialogue_step)
		barrier.visible = false
		barrier.process_mode = Node.PROCESS_MODE_DISABLED
		
		# Disable collision on the StaticBody2D
		barrier.set_deferred("collision_layer", 0)
		barrier.set_deferred("collision_mask", 0)
		
		# Disconnect the detector signal
		if barrier_detector and barrier_detector.body_entered.is_connected(_on_barrier_area_entered):
			barrier_detector.body_entered.disconnect(_on_barrier_area_entered)
		
		print("DEBUG: Barrier properties after deactivation:")
		print("- visible:", barrier.visible)
		print("- process_mode:", barrier.process_mode)
		print("- collision_layer:", barrier.collision_layer)
		print("- collision_mask:", barrier.collision_mask)
	else:
		print("DEBUG: Failed to deactivate barrier - barrier node is null")

func show_next_dialogue():
	print("DEBUG: Starting dialogue step:", dialogue_step, " in scene:", current_scene)
	
	if not dialogue_ui:
		print("DEBUG: Dialogue UI is null!")
		return
	
	dialogue_ui.visible = true  # Ensure UI is visible
	dialogue_active = true
	
	if current_scene == 2:
		match dialogue_step:
			0:
				dialogue_ui.trigger_dialogue("(There's the truck!!)")
			1:
				dialogue_ui.trigger_dialogue("Hey!! I still have some trash here!")
				# Start truck movement and activate barrier immediately
				start_truck_movement()
				activate_barrier()
			2:
				dialogue_ui.trigger_dialogue("NOOOOO! Mom is gonna kill me T-T")
			3:
				dialogue_ui.trigger_dialogue("(I should just go back home)")
			_:
				end_dialogue()
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
				end_dialogue()
				return

func end_dialogue():
	print("DEBUG: Ending dialogue in scene:", current_scene)
	if dialogue_ui:
		dialogue_ui.hide_dialogue()
	dialogue_active = false
	
	if current_scene == 3:
		deactivate_barrier()
	
	if player:
		player.set_can_move(true)

func start_truck_movement():
	print("DEBUG: Starting truck movement")
	is_truck_leaving = true
	if truck:
		print("DEBUG: Truck position before movement:", truck.position)

func _on_scene2_body_entered(body):
	print("DEBUG: Body entered Scene2 area:", body.name)
	if body == player and not has_triggered_scene2:
		on_interaction_scene2()
		
func _on_scene3_body_entered(body):
	print("DEBUG: Body entered Scene3 area:", body.name)
	if body == player and not has_triggered_scene3 and has_triggered_scene2:
		on_interaction_scene3()

func on_interaction_scene2():
	if not has_triggered_scene2:
		current_scene = 2
		dialogue_step = 0
		dialogue_active = true
		has_triggered_scene2 = true
		
		# Move mom to a new position
		var mom = $Mom
		if mom:
			mom.position = Vector2(-116, 99)
			print("DEBUG: Mom moved to position:", mom.position)
		else:
			print("DEBUG: Mom node not found!")
		
		if player:
			player.set_can_move(false)
		if dialogue_ui:
			dialogue_ui.visible = true
			show_next_dialogue()
		else:
			print("DEBUG: Dialogue UI is null!")

func on_interaction_scene3():
	print("DEBUG: Attempting to trigger Scene 3")
	if not has_triggered_scene3 and has_triggered_scene2:
		print("DEBUG: Scene 3 triggered successfully")
		current_scene = 3
		dialogue_step = 0
		dialogue_active = true
		has_triggered_scene3 = true
		if player:
			player.set_can_move(false)
		dialogue_ui.visible = true  # Ensure UI is visible
		show_next_dialogue()

func advance_tutorial():
	current_tutorial_step += 1
	show_current_tutorial_step()
