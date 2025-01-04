extends Node2D

@onready var dialogue_ui = $Dialogue
@onready var interaction_area_2 = $Scene2
@onready var interaction_area_3 = $Mom/InteractionArea
@onready var player = $Player
@onready var truck = $Truck
@onready var barrier = $Barrier
@onready var barrier_detector = $Barrier/DetectorArea
@onready var viewport_size: Vector2
@onready var screen_center: Vector2
@onready var tutorial_margin: float = 100.0
@onready var tutorial_layer = $TutorialLayer
@onready var tutorial_group = $TutorialLayer/TutorialSprites
@onready var key_w = $TutorialLayer/TutorialSprites/W as AnimatedSprite2D
@onready var key_a = $TutorialLayer/TutorialSprites/A as AnimatedSprite2D
@onready var key_s = $TutorialLayer/TutorialSprites/S as AnimatedSprite2D
@onready var key_d = $TutorialLayer/TutorialSprites/D as AnimatedSprite2D
@onready var key_jump = $TutorialLayer/TutorialSprites/Space as AnimatedSprite2D


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
		"keys": ["horizontal"],
		"sprites": ["a", "d"],
		"positions": {
			"a": Vector2(0.2, 0.5),  # 20% from left
			"d": Vector2(0.8, 0.5)   # 80% from left
		},
		"required_actions": ["ui_left", "ui_right"]
	},
	{
		"keys": ["vertical"],
		"sprites": ["w", "s"],
		"positions": {
			"w": Vector2(0.5, 0.4),  # Changed from 0.7 to 0.4
			"s": Vector2(0.5, 0.6)   # Changed from 0.9 to 0.6
		},
		"duration": 2.0
	},
	{
		"keys": ["jump"],
		"sprites": ["space"],
		"positions": {
			"space": Vector2(0.5, 0.5)  # Changed from 0.8 to 0.5
		},
		"duration": 2.0
	}
]

var waiting_for_tutorial_input = false
var required_tutorial_actions = []

func _ready():
	print("Tutorial nodes check:")
	print("- tutorial_group:", tutorial_group != null)
	print("- key_w:", key_w != null)
	print("- key_a:", key_a != null)
	print("- key_s:", key_s != null)
	print("- key_d:", key_d != null)
	print("- key_jump:", key_jump != null)
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

	if tutorial_group:
		tutorial_group.position = Vector2.ZERO
		tutorial_group.visible = true
		tutorial_group.modulate.a = 1
		print("Tutorial group setup:")
		print("- Position:", tutorial_group.position)
		print("- Visible:", tutorial_group.visible)
		
		# Make sure tutorial group is visible
		tutorial_group.visible = true
		
		# Debug each sprite
		for sprite in [key_w, key_a, key_s, key_d, key_jump]:
			if sprite:
				print("Sprite {sprite.name}:")
				print("- Has frames:", sprite.sprite_frames != null)
				if sprite.sprite_frames:
					print("- Animations:", sprite.sprite_frames.get_animation_names())
				print("- Position:", sprite.position)
				print("- Visible:", sprite.visible)
				
				# Make sure each sprite is set up correctly
				sprite.visible = false  # Will be made visible when needed
				sprite.modulate.a = 0   # Will be set to 1 when shown
	
	if !is_tutorial_nodes_valid():
		print("ERROR: Tutorial sprites not properly set up!")
		return
		
	update_screen_dimensions()
	get_tree().root.size_changed.connect(update_screen_dimensions)
	initialize_tutorial_sprites()
	
	print("\nValidating tutorial setup:")
	if not tutorial_group is Node2D:
		print("ERROR: tutorial_group must be a Node2D!")
		return
		
	for sprite_name in ["W", "A", "S", "D", "Space"]:
		var sprite = get_node_or_null("TutorialSprites/" + sprite_name)
		if not sprite is AnimatedSprite2D:
			print("ERROR: " + sprite_name + " sprite not found or not an AnimatedSprite2D!")
		else:
			print(sprite_name + " sprite found and valid")
	
	print("\n=== TUTORIAL SETUP DEBUG ===")
	
	# Check tutorial group
	print("\nTutorial Group Check:")
	print("- Reference:", tutorial_group)
	print("- Is Node2D:", tutorial_group is Node2D if tutorial_group else "null")
	print("- Position:", tutorial_group.position if tutorial_group is Node2D else "N/A")
	print("- Visible:", tutorial_group.visible if tutorial_group else "null")
	
	# Check all sprite references
	print("\nSprite References Check:")
	var sprites = {
		"W": key_w,
		"A": key_a,
		"S": key_s,
		"D": key_d,
		"Space": key_jump
	}
	
	for key in sprites:
		var sprite = sprites[key]
		print("\n{key} Sprite Check:")
		print("- Reference:", sprite)
		print("- Is AnimatedSprite2D:", sprite is AnimatedSprite2D if sprite else "null")
		if sprite and sprite is AnimatedSprite2D:
			print("- Has frames:", sprite.sprite_frames != null)
			print("- Animations:", sprite.sprite_frames.get_animation_names() if sprite.sprite_frames else "none")
			print("- Position:", sprite.position)
			print("- Visible:", sprite.visible)
			print("- Modulate:", sprite.modulate)

func is_tutorial_nodes_valid() -> bool:
	return tutorial_group != null && key_w != null && key_a != null && key_s != null && key_d != null && key_jump != null

func initialize_tutorial_sprites():
	if is_tutorial_nodes_valid():
		key_w.modulate.a = 0
		key_a.modulate.a = 0
		key_s.modulate.a = 0
		key_d.modulate.a = 0
		key_jump.modulate.a = 0

func update_screen_dimensions():
	# Get the actual viewport size
	viewport_size = get_viewport().get_visible_rect().size
	print("Viewport size: ", viewport_size)  # Debug line
	screen_center = viewport_size / 2
	print("Screen center: ", screen_center)  # Debug line

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
	if !is_tutorial_nodes_valid():
		print("DEBUG: Cannot start tutorial - sprites not found!")
		return
		
	print("DEBUG: Starting tutorial sequence - Setting showing_tutorial to true")
	showing_tutorial = true
	current_tutorial_step = 0
	show_current_tutorial_step()

func show_current_tutorial_step():
	if current_tutorial_step >= tutorial_sequence.size():
		print("ERROR: Tutorial step out of bounds!")
		return
		
	# Hide all sprites first
	hide_all_keys()
	
	var step = tutorial_sequence[current_tutorial_step]
	
	# Force tutorial group visibility
	tutorial_group.visible = true
	tutorial_group.modulate.a = 1
	
	for sprite_name in step.sprites:
		var sprite = get_sprite_for_key(sprite_name)
		if sprite:
			# IMPORTANT: Set both visible AND modulate
			sprite.visible = true  # Set visibility first
			sprite.modulate = Color(1, 1, 1, 1)  # Full opacity
			
			# Calculate and set position
			var screen_pos = get_screen_position(step.positions[sprite_name])
			sprite.position = screen_pos
			
			print("Sprite %s settings:" % sprite_name)
			print("- visible: %s" % sprite.visible)
			print("- modulate: %s" % sprite.modulate)
			print("- position: %s" % sprite.position)
			
			if sprite.sprite_frames:
				sprite.play("default")
				print("Playing animation for %s" % sprite_name)

func get_sprite_for_key(key_name: String) -> AnimatedSprite2D:
	match key_name:
		"w": return key_w
		"a": return key_a
		"s": return key_s
		"d": return key_d
		"space": return key_jump
	return null

func hide_all_keys():
	for sprite in [key_w, key_a, key_s, key_d, key_jump]:
		if sprite:
			sprite.stop()  # Stop any running animations
			sprite.visible = false  # Hide the sprite
			sprite.modulate = Color(1, 1, 1, 0)  # Make fully transparent

func get_screen_position(factors: Vector2) -> Vector2:
	# Try both potential node paths
	var dialogue_box = dialogue_ui.get_node_or_null("Dialogue") if dialogue_ui else null
	if not dialogue_box:
		dialogue_box = dialogue_ui.get_node_or_null("DialogueBox") if dialogue_ui else null
		
	if dialogue_box:
		var box_pos = dialogue_box.global_position
		var box_size = dialogue_box.size
		
		var pos = Vector2(
			box_pos.x + (box_size.x * factors.x),
			box_pos.y + (box_size.y * factors.y)
		)
		
		print("Dialogue box position: ", box_pos)
		print("Dialogue box size: ", box_size)
		print("Calculated position within dialogue: ", pos)
		
		return pos
	else:
		print("ERROR: Could not find dialogue box node. Available children:", 
			  dialogue_ui.get_children() if dialogue_ui else "dialogue_ui is null")
		return Vector2.ZERO

func end_tutorial_sequence():
	print("DEBUG: Starting end_tutorial_sequence")
	print("DEBUG: Tutorial state before end:", showing_tutorial)
	
	# Stop all animations
	key_w.stop()
	key_a.stop()
	key_s.stop()
	key_d.stop()
	key_jump.stop()
	
	# Hide using modulate
	key_w.modulate.a = 0
	key_a.modulate.a = 0
	key_s.modulate.a = 0
	key_d.modulate.a = 0
	key_jump.modulate.a = 0
	
	showing_tutorial = false
	print("DEBUG: Tutorial state after end:", showing_tutorial)
	
	# Make sure player can move after tutorial
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)

func _input(event):
	# Add debug prints for input state
	if event.is_action_pressed("ui_accept"):
		print("DEBUG: Space pressed")
		print("DEBUG: Current state - dialogue_active:", dialogue_active)
		print("DEBUG: Current state - showing_tutorial:", showing_tutorial)
		print("DEBUG: Current state - current_scene:", current_scene)
		print("DEBUG: Current state - dialogue_step:", dialogue_step)
		print("DEBUG: Current state - waiting_for_tutorial_input:", waiting_for_tutorial_input)
	
	# Handle tutorial input
	if waiting_for_tutorial_input and showing_tutorial:
		print("DEBUG: Caught in tutorial input handler")
		for action in required_tutorial_actions:
			if event.is_action_pressed(action):
				print("DEBUG: Tutorial action detected:", action)
				waiting_for_tutorial_input = false
				advance_tutorial()
				break
	
	# Keep existing input handling
	if event.is_action_pressed("ui_accept") and dialogue_active and not showing_tutorial:
		print("DEBUG: Dialogue advance triggered")
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
	print("DEBUG: dialogue_active before:", dialogue_active)
	
	if not dialogue_ui:
		print("DEBUG: Dialogue UI is null!")
		return
	
	dialogue_ui.visible = true
	dialogue_active = true
	
	if current_scene == 2:
		print("DEBUG: Processing scene 2 dialogue, step:", dialogue_step)
		match dialogue_step:
			0:
				print("DEBUG: Showing first truck dialogue")
				dialogue_ui.trigger_dialogue("(There's the truck!!)")
			1:
				print("DEBUG: Showing second truck dialogue")
				dialogue_ui.trigger_dialogue("Hey!! I still have some trash here!")
				start_truck_movement()
				activate_barrier()
			2:
				print("DEBUG: Showing third truck dialogue")
				dialogue_ui.trigger_dialogue("NOOOOO! Mom is gonna kill me T-T")
			3:
				print("DEBUG: Showing fourth truck dialogue")
				dialogue_ui.trigger_dialogue("(I should just go back home)")
			_:
				print("DEBUG: Ending dialogue - no more steps")
				end_dialogue()
				return
	
	elif current_scene == 3:
		print("DEBUG: Processing scene 3 dialogue, step:", dialogue_step)
		match dialogue_step:
			0:
				print("DEBUG: Showing first mom dialogue")
				dialogue_ui.trigger_dialogue("Mom… The garbage truck already left…")
			1:
				print("DEBUG: Showing second mom dialogue")
				dialogue_ui.trigger_dialogue("Mom: Boy if you don't want to end up being the one inside the trash bag instead, then RUN!")
			2:
				print("DEBUG: Showing third mom dialogue")
				dialogue_ui.trigger_dialogue("OKAY CHILL!!!!")
			3:
				print("DEBUG: Showing fourth mom dialogue")
				dialogue_ui.trigger_dialogue("Ugh, what a way to start my morning")
				deactivate_barrier()
			_:
				print("DEBUG: Ending scene 3 dialogue")
				end_dialogue()
				return

func end_dialogue():
	print("DEBUG: Ending dialogue in scene:", current_scene)
	print("DEBUG: Dialogue step:", dialogue_step)
	if dialogue_ui:
		dialogue_ui.hide_dialogue()
	dialogue_active = false
	
	if current_scene == 3:
		print("DEBUG: Scene 3 dialogue ended, deactivating barrier")
		deactivate_barrier()
	
	if player:
		print("DEBUG: Re-enabling player movement")
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
		print("DEBUG: Entering scene2 interaction")
		print("DEBUG: Tutorial state before:", showing_tutorial)
		
		# Force end tutorial if it's still active
		if showing_tutorial:
			print("DEBUG: Force ending tutorial sequence")
			end_tutorial_sequence()
		
		showing_tutorial = false  # Force it false anyway
		print("DEBUG: Tutorial state after:", showing_tutorial)
		
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
		
		# Make sure player movement is disabled
		if player:
			print("DEBUG: Disabling player movement")
			player.set_can_move(false)
		else:
			print("DEBUG: Player node not found!")
			
		# Make sure dialogue UI is properly set up
		if dialogue_ui:
			print("DEBUG: Setting up dialogue UI")
			dialogue_ui.visible = true
			show_next_dialogue()
		else:
			print("DEBUG: Dialogue UI is null!")

func advance_tutorial():
	print("DEBUG: Advancing tutorial from step", current_tutorial_step)
	current_tutorial_step += 1
	if current_tutorial_step >= tutorial_sequence.size():
		print("DEBUG: Tutorial complete, ending sequence")
		end_tutorial_sequence()
	else:
		show_current_tutorial_step()

func debug_sprite_status(sprite: AnimatedSprite2D, name: String):
	if sprite:
		print("\nSprite %s Status:" % name)
		print("- exists: true")
		print("- visible: %s" % sprite.visible)
		print("- modulate alpha: %s" % sprite.modulate.a)
		print("- global position: %s" % sprite.global_position)
		print("- position: %s" % sprite.position)
		print("- parent visible: %s" % (sprite.get_parent().visible if sprite.get_parent() else 'no parent'))
		print("- sprite frames: %s" % (sprite.sprite_frames != null))
	else:
		print("Sprite %s is null!" % name)
