extends Node2D

@onready var dialogue_ui = $Dialogue
@onready var interaction_area_2 = $Scene2
@onready var interaction_area_3 = $Mom/InteractionArea
@onready var player = $Player
@onready var truck = $Truck
@onready var barrier = $Barrier
@onready var barrier_detector = $Barrier/DetectorArea
@onready var tutorial_sprite: AnimatedSprite2D = $TutorialSprite

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
		print("DEBUG: Scene2 area signals connected")
	
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

	if tutorial_sprite:
		tutorial_sprite.visible = false
		tutorial_sprite.position = Vector2(20, 20)

var is_player_in_scene2_area = false


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
	
	# Show tutorial sprite
	await get_tree().create_timer(0.5).timeout
	show_tutorial_popup()
	
	player_can_move = true
	dialogue_active = false
	current_scene = 0
	dialogue_step = 0
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)

func show_tutorial_popup():
	if tutorial_sprite:
		# You can also adjust position here if needed
		tutorial_sprite.position = Vector2(20, 20)  # Adjust these values
		tutorial_sprite.visible = true
		tutorial_sprite.play("default")  # Or whatever your animation name is
		await get_tree().create_timer(2.0).timeout
		tutorial_sprite.stop()
		tutorial_sprite.visible = false

func set_tutorial_position(new_position: Vector2):
	if tutorial_sprite:
		tutorial_sprite.position = new_position

func _input(event):
	# Only handle dialogue advancement if not showing tutorial
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
			activate_barrier()
			print("DEBUG: Truck stopped, barrier activated")

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
				# Use a timer node instead of await for better control
				var timer = Timer.new()
				add_child(timer)
				timer.wait_time = 1.5
				timer.one_shot = true
				timer.timeout.connect(func(): start_truck_movement())
				timer.start()
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

func start_truck_movement():
	print("DEBUG: Starting truck movement")
	is_truck_leaving = true
	if truck:
		print("DEBUG: Truck position before movement:", truck.position)

func end_dialogue():
	print("DEBUG: Ending dialogue in scene:", current_scene)
	if dialogue_ui:
		dialogue_ui.hide_dialogue()
	dialogue_active = false
	
	if current_scene == 3:
		deactivate_barrier()
	
	if player:
		player.set_can_move(true)

func _on_scene2_body_entered(body):
	print("DEBUG: Body entered Scene2 area:", body.name)
	if body == player and not has_triggered_scene2:
		on_interaction_scene2()
		
func _on_scene3_body_entered(body):
	print("DEBUG: Body entered Scene3 area:", body.name)
	if body == player and not has_triggered_scene3 and has_triggered_scene2:
		on_interaction_scene3()
