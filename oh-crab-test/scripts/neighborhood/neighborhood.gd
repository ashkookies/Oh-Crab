##STOP HERE
extends Node2D

var story_events = [
	{
		"text": ["Hey! Mr. Garbage Man!", "Please slow down!"],
		"position": Vector2(100, 0),
		"type": "dialogue",
		"speaker": "Nugu",
		"auto_start": true
	},
	{
		"text": ["PLEASE!! I just want to go to sleep!"],
		"position": Vector2(200, 0),
		"type": "dialogue",
		"speaker": "Nugu",
		"trigger_scene_event": "truck_leaving",
		"auto_play": false
	},
	{
		"text": ["Usain Bolt please take over my body!!!"],
		"position": Vector2(300, 0),
		"type": "dialogue",
		"speaker": "Nugu",
		"auto_play": false
	},
	{
		"text": [" (Oh, there seems to be trash on the ground…I wonder if I can catch up to the truck if I follow it)"],
		"position": Vector2(400, 0),
		"type": "dialogue",
		"speaker": "Nugu",
		"auto_play": false,
		"restrict_movement": true  # Add this flag for complete movement restriction
	}
]

signal dialogue_started
signal dialogue_ended

@onready var dialogue_system = get_node("Dialogue")
@onready var truck = get_node("Truck")
@onready var player = get_tree().get_first_node_in_group("player")

var current_line_index = 0
var current_event_text: Array
var current_event_index = 0
var triggered_events = {}
var current_dialogue_active = false
var can_advance = false
var input_disabled = false

func _ready():
	setup_interaction_areas()
	dialogue_system.dialogue_completed.connect(_on_dialogue_completed)
	if truck:
		truck.position = Vector2(200, 0)
	
	await get_tree().create_timer(1.0).timeout
	start_first_dialogue()

func _input(event):
	if current_dialogue_active and dialogue_system.visible:
		# Check for both ui_accept (Enter) and jump action (Space)
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
			# Prevent the event from being processed by other nodes
			get_viewport().set_input_as_handled()
			if not input_disabled:
				input_disabled = true
				handle_dialogue_advance()
				await get_tree().create_timer(0.2).timeout
				input_disabled = false

func handle_dialogue_advance():
	if can_advance:
		print("Advancing dialogue")
		can_advance = false
		if current_line_index >= current_event_text.size():
			_on_dialogue_completed()
		else:
			show_next_line()

func start_first_dialogue():
	for i in story_events.size():
		if story_events[i].get("auto_start", false):
			trigger_event(i)
			break

func setup_interaction_areas():
	for i in story_events.size():
		var event = story_events[i]
		var interaction_area = create_interaction_area()
		interaction_area.position = event.position
		interaction_area.event_index = i
		add_child(interaction_area)
		add_debug_visual(interaction_area)

func create_interaction_area():
	var area = preload("res://shortcuts/interaction area/interaction_area.gd").new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	shape.extents = Vector2(50, 100)
	collision.shape = shape
	area.add_child(collision)
	
	area.body_entered.connect(func(body): _on_interaction_area_entered(body, area))
	return area

func add_debug_visual(area: Node2D):
	var debug_rect = ColorRect.new()
	debug_rect.size = Vector2(100, 200)
	debug_rect.position = Vector2(-50, -100)
	debug_rect.color = Color(1, 0, 0, 0.2)
	area.add_child(debug_rect)

func _on_interaction_area_entered(body: Node2D, area: Area2D):
	if body.is_in_group("player"):
		var event_index = area.event_index
		if not triggered_events.has(event_index):
			print("Triggering event ", event_index)
			if current_dialogue_active:
				force_complete_current_dialogue()
			trigger_event(event_index)

func force_complete_current_dialogue():
	current_dialogue_active = false
	dialogue_system.hide()
	dialogue_ended.emit()
	if player and player.has_method("enable_movement"):
		player.enable_movement(true)

func _on_dialogue_completed():
	print("Dialogue completed signal received")
	can_advance = true
	
	if current_line_index >= current_event_text.size():
		var current_event = story_events[current_event_index]
		triggered_events[current_event_index] = true
		
		if current_event.has("trigger_scene_event"):
			match current_event.trigger_scene_event:
				"truck_leaving":
					animate_truck_leaving()
		
		current_dialogue_active = false
		dialogue_system.hide()
		dialogue_ended.emit()
		
		# Reset all movement controls when dialogue ends
		if player:
			if player.has_method("set_dialogue_active"):
				player.set_dialogue_active(false)
			if player.has_method("set_can_move"):
				player.set_can_move(true)
		
		await get_tree().create_timer(0.5).timeout
		current_event_index += 1
	else:
		can_advance = true

func trigger_event(index: int):
	print("Triggering event: ", index)
	current_event_index = index
	var event = story_events[index]
	current_event_text = event.text
	current_line_index = 0
	current_dialogue_active = true
	dialogue_started.emit()
	
	if player:
		# Set dialogue active state in player
		if player.has_method("set_dialogue_active"):
			player.set_dialogue_active(true)
			
		# Handle movement restrictions
		if event.get("restrict_movement", false) and player.has_method("set_can_move"):
			player.set_can_move(false)
	
	show_next_line()

func show_next_line():
	if current_line_index < current_event_text.size():
		var event = story_events[current_event_index]
		var speaker = event.get("speaker", "")
		var line = current_event_text[current_line_index]
		
		dialogue_system.show()
		if event.get("type") == "narration":
			dialogue_system.trigger_dialogue("*" + line + "*")
		else:
			var full_line = speaker + ": " + line if speaker else line
			print("Showing dialogue line: ", full_line)
			dialogue_system.trigger_dialogue(full_line)
		
		current_line_index += 1
		await get_tree().create_timer(0.2).timeout
		can_advance = true
	else:
		_on_dialogue_completed()

func animate_truck_leaving():
	if truck:
		var tween = create_tween()
		tween.tween_property(truck, "position:x", 500, 1.5)
		tween.tween_callback(func(): truck.queue_free())
