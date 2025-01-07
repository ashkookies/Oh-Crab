extends Node

@onready var dialogue_system = $Dialogue
@onready var interaction_area = $Scene5

# List of dialogue messages
var dialogue_messages = [
	"Phew! Finally!",
	"(Oh! So this is where our trash ends up. Might as well do the same)",
	# Add more messages as needed
]
var current_message_index = 0
var dialogue_triggered = false

func _ready():
	var truck = $Truck  # Adjust path if needed
	
	if truck:
		# Disable movement logic without removing script
		truck.is_player_nearby = false
		truck.set_physics_process(false)
		# Optionally, disconnect signals
		var area = truck.get_node("InteractionArea")
		if area:
			area.body_entered.disconnect(truck._on_detection_area_body_entered)
			area.body_exited.disconnect(truck._on_detection_area_body_exited)
	
	if dialogue_system:
		dialogue_system.dialogue_completed.connect(_on_dialogue_completed)
	else:
		print("ERROR: DialogueSystem node not found!")
		
	if interaction_area:
		# Connect the InteractionArea signals to our dialogue functions
		interaction_area.on_interaction = func(): _on_interaction_area_entered()
		interaction_area.on_exit = func(): _on_interaction_area_exited()
	else:
		print("ERROR: InteractionArea node not found!")

func _input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		if dialogue_system.dialogue_active:
			dialogue_system.advance_dialogue()

func _on_interaction_area_entered():
	if !dialogue_triggered:
		trigger_next_dialogue()
		dialogue_triggered = true

func _on_interaction_area_exited():
	if dialogue_system.dialogue_active:
		dialogue_system.hide_dialogue()

func _on_dialogue_completed():
	current_message_index += 1
	if current_message_index < dialogue_messages.size():
		trigger_next_dialogue()

func trigger_next_dialogue():
	if current_message_index < dialogue_messages.size():
		dialogue_system.trigger_dialogue(dialogue_messages[current_message_index])
