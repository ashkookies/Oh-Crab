extends Node2D

var story_events = [
	{
		"text": ["Hey! Mr. Garbage Man!", "Please slow down!"],
		"position": Vector2(-1000, 0),
		"type": "dialogue",
		"speaker": "Nugu",
		"auto_start": true
	},
	{
		"text": ["PLEASE!! I just want to go to sleep!"],
		"position": Vector2(300, 10),
		"type": "dialogue",
		"speaker": "Nugu",
		"trigger_scene_event": "truck_leaving",
		"auto_play": false
	},
	{
		"text": ["Usain Bolt please take over my body!!!"],
		"position": Vector2(425, 0),
		"type": "dialogue",
		"speaker": "Nugu",
		"auto_play": false,
		"auto_advance": true
	},
	{
		"text": [" (Oh, there seems to be trash on the ground…I wonder if I can catch up to the truck if I follow it)"],
		"position": Vector2(600, 0),
		"type": "dialogue",
		"speaker": "Nugu",
		"auto_play": false,
		"restrict_movement": true
	},
	{
		"text": ["Hey Nugu! Wanna play with us?", "Later!!"],
		"position": Vector2(800, 0),
		"type": "dialogue",
		"speakers": ["Friend1", "Nugu"],
		"auto_play": false,
		"restrict_movement": true,
		"unlock_movement_after": true,
		"trigger_scene_event": "friend1_stop"  # Added this trigger
	},
	{
		"text": ["Hey kid! Wanna join our coastal cleanup drive-", "MOVE!!"],
		"position": Vector2(1000, 0),
		"type": "dialogue",
		"speakers": ["Stranger1", "Nugu"],
		"auto_play": false,
		"restrict_movement": true
	}
]

signal dialogue_started
signal dialogue_ended

@onready var dialogue_system: Node
@onready var truck: Node2D
@onready var player: Node2D
@onready var friend1: AnimatedSprite2D

var current_line_index: int = 0
var current_event_text: Array
var current_event_index: int = 0
var triggered_events: Dictionary = {}
var current_dialogue_active: bool = false
var can_advance: bool = false
var input_disabled: bool = false

func _ready() -> void:
	print("StoryManager: Starting initialization...")
	dialogue_system = get_node_or_null("Dialogue")
	truck = get_node_or_null("Truck")
	player = get_tree().get_first_node_in_group("player")
	friend1 = get_node_or_null("Friend1")
	
	if dialogue_system:
		# Check if signal exists and connect it
		if dialogue_system.has_signal("dialogue_completed"):
			if !dialogue_system.is_connected("dialogue_completed", _on_dialogue_completed):
				dialogue_system.dialogue_completed.connect(_on_dialogue_completed)
				print("Connected dialogue_completed signal")
		else:
			push_error("Dialogue system missing dialogue_completed signal!")
	
	setup_interaction_areas()
	
	# Start first dialogue after a short delay
	await get_tree().create_timer(1.0).timeout
	start_first_dialogue()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		print("Space pressed - Dialogue active:", current_dialogue_active, " Can advance:", can_advance)
		if current_dialogue_active and can_advance and !input_disabled:
			input_disabled = true
			print("Attempting to advance dialogue")
			handle_dialogue_advance()
			await get_tree().create_timer(0.2).timeout
			input_disabled = false

func _unhandled_input(event: InputEvent) -> void:
	# Debug print to verify input detection
	if event.is_action_pressed("ui_accept"):
		print("Space bar pressed! Dialogue active:", current_dialogue_active, " Input disabled:", input_disabled)
	
	# Check if dialogue is active and input isn't disabled
	if !current_dialogue_active || input_disabled:
		return
		
	# Handle both space and enter keys
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		input_disabled = true
		print("Advancing dialogue...")
		handle_dialogue_advance()
		# Re-enable input after a short delay
		await get_tree().create_timer(0.2).timeout
		input_disabled = false

func handle_dialogue_advance() -> void:
	print("Handle dialogue advance - Current line:", current_line_index, "/", current_event_text.size())
	if !can_advance:
		return
	
	can_advance = false
	
	if current_line_index < current_event_text.size():
		show_next_line()
	else:
		print("No more lines, completing dialogue")
		_on_dialogue_completed()

func setup_interaction_areas() -> void:
	for i in story_events.size():
		var event = story_events[i]
		var interaction_area = create_interaction_area()
		interaction_area.position = event.position
		interaction_area.set_meta("event_index", i)
		add_child(interaction_area)

func create_interaction_area() -> Area2D:
	var area = Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.extents = Vector2(50, 134)
	collision.shape = shape
	area.add_child(collision)
	
	# Connect the area signal
	area.body_entered.connect(_on_interaction_area_entered.bind(area))
	
	return area

func _on_interaction_area_entered(body: Node2D, area: Area2D) -> void:
	if !body.is_in_group("player"):
		return
		
	var event_index = area.get_meta("event_index")
	
	# Don't retrigger active dialogue
	if current_dialogue_active && current_event_index == event_index:
		return
		
	# Trigger new dialogue if not already triggered
	if !triggered_events.has(event_index):
		if current_dialogue_active:
			force_complete_current_dialogue()
		trigger_event(event_index)

func start_first_dialogue() -> void:
	for i in story_events.size():
		if story_events[i].get("auto_start", false):
			trigger_event(i)
			break

func force_complete_current_dialogue() -> void:
	current_dialogue_active = false
	dialogue_system.hide()
	dialogue_ended.emit()
	enable_player_movement(true)

func enable_player_movement(enabled: bool) -> void:
	if !player:
		return
		
	if player.has_method("enable_movement"):
		player.call("enable_movement", enabled)
	if player.has_method("set_can_move"):
		player.call("set_can_move", enabled)

# Make sure these functions are properly setting can_advance
func _on_dialogue_completed() -> void:
	print("Dialogue completed called")
	
	if current_line_index >= current_event_text.size():
		var current_event = story_events[current_event_index]
		triggered_events[current_event_index] = true
		
		if current_event.has("trigger_scene_event"):
			match current_event.trigger_scene_event:
				"truck_leaving":
					animate_truck_leaving()
				"friend1_stop":
					handle_friend1_animation()
		
		current_dialogue_active = false
		if dialogue_system:
			dialogue_system.hide()
		dialogue_ended.emit()
		
		if player:
			if player.has_method("set_dialogue_active"):
				player.call("set_dialogue_active", false)
			if current_event.get("unlock_movement_after", true):
				enable_player_movement(true)
		
		await get_tree().create_timer(0.5).timeout
		current_event_index += 1
	else:
		can_advance = true
		print("Dialogue not complete yet, can advance to next line")

func trigger_event(index: int) -> void:
	current_event_index = index
	var event = story_events[index]
	current_event_text = event.text
	current_line_index = 0
	current_dialogue_active = true
	dialogue_started.emit()
	
	if player:
		if player.has_method("set_dialogue_active"):
			player.call("set_dialogue_active", true)
		if event.get("restrict_movement", false):
			enable_player_movement(false)
	
	show_next_line()

func show_next_line() -> void:
	if !dialogue_system:
		print("Cannot show line - dialogue system missing")
		return
		
	var event = story_events[current_event_index]
	var line = str(current_event_text[current_line_index])
	
	print("Showing line:", line)
	dialogue_system.show()
	
	if event.get("type") == "narration":
		dialogue_system.trigger_dialogue("*" + line + "*")
	else:
		var speaker = ""
		if event.has("speakers"):
			speaker = str(event.speakers[current_line_index])
		else:
			speaker = str(event.get("speaker", ""))
		
		var full_line = speaker + ": " + line if speaker else line
		print("Triggering dialogue:", full_line)
		dialogue_system.trigger_dialogue(full_line)
	
	current_line_index += 1
	await get_tree().create_timer(0.2).timeout
	can_advance = true
	print("Ready for next line - Can advance set to true")

func animate_truck_leaving() -> void:
	if !truck:
		return
		
	var tween = create_tween()
	tween.tween_property(truck, "position:x", truck.position.x + 300, 1.5)
	await tween.finished
	
	if is_instance_valid(truck):
		truck.queue_free()

func handle_friend1_animation() -> void:
	if friend1:
		friend1.stop()  # Stop any current animation
		friend1.frame = 0  # Set to default frame
		
		# If the sprite has a play_animation() method, stop it
		if friend1.has_method("play_animation"):
			friend1.play_animation("default")
			
		# If you're using the built-in animation player
		if friend1.sprite_frames:
			friend1.stop()
			friend1.animation = "default"
