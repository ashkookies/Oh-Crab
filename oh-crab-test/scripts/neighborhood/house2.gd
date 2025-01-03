extends Node

@onready var dialogue_box = $Dialogue
@onready var mom_interaction: InteractionArea = $Mom/	InteractionArea

var dialogue_lines = [
	"It seems like you've completed your task",
	"Well done!",
	"You can go back to bed now"
]

var current_line_index = 0
var is_dialogue_active = false

func _ready():
	if !dialogue_box:
		push_error("DialogueBox node not found!")
		return
		
	if !mom_interaction:
		push_error("MomInteractionArea node not found!")
		return
	
	mom_interaction.on_interaction = start_dialogue
	mom_interaction.on_exit = end_dialogue
	dialogue_box.dialogue_completed.connect(_on_dialogue_completed)

func start_dialogue():
	if not is_dialogue_active:
		is_dialogue_active = true
		current_line_index = 0
		show_next_line()

func show_next_line():
	if current_line_index < dialogue_lines.size():
		dialogue_box.show_dialogue(dialogue_lines[current_line_index])
		current_line_index += 1
	else:
		end_dialogue()

func _on_dialogue_completed():
	if is_dialogue_active and current_line_index < dialogue_lines.size():
		show_next_line()

func end_dialogue():
	is_dialogue_active = false
	dialogue_box.hide_dialogue()
	current_line_index = 0

func _input(event):
	# Check for space key press
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE and is_dialogue_active:
			dialogue_box.advance_dialogue()
