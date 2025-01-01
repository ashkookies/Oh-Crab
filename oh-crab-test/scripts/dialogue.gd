extends CanvasLayer

# Add the signal declaration at the top
signal dialogue_completed

@onready var textbox_container = $TextboxContainer
@onready var text_label = $TextboxContainer/MarginContainer/HBoxContainer/Label
@onready var start_symbol = $TextboxContainer/MarginContainer/HBoxContainer/Start
@onready var end_symbol = $TextboxContainer/MarginContainer/HBoxContainer/End

@export var text_speed: float = 0.05
@export var auto_hide: bool = true

var current_text: String = ""
var displayed_text: String = ""
var is_text_completed: bool = false
var dialogue_active: bool = false

func _ready():
	textbox_container.hide()
	dialogue_active = false
	reset_dialogue_state()
	
	if text_speed > 0:
		process_mode = Node.PROCESS_MODE_ALWAYS

func reset_dialogue_state():
	current_text = ""
	displayed_text = ""
	is_text_completed = false

@warning_ignore("unused_parameter")
func _process(delta):
	if dialogue_active and !is_text_completed:
		if displayed_text.length() < current_text.length():
			displayed_text += current_text[displayed_text.length()]
			text_label.text = displayed_text
		else:
			is_text_completed = true

func show_dialogue(text: String):
	if text.is_empty():
		return
	current_text = text
	displayed_text = ""
	is_text_completed = false
	dialogue_active = true
	textbox_container.show()
	print("DEBUG: Showing dialogue: ", text)

func hide_dialogue():
	dialogue_active = false
	textbox_container.hide()
	reset_dialogue_state()
	# Emit the signal when dialogue is hidden
	dialogue_completed.emit()

func trigger_dialogue(text: String):
	show_dialogue(text)
	print("DEBUG: Triggered dialogue: ", text)

func complete_text():
	if !is_text_completed:
		displayed_text = current_text
		text_label.text = displayed_text
		is_text_completed = true

# Add this function to handle advancing dialogue
func advance_dialogue():
	if is_text_completed:
		hide_dialogue()  # This will emit the dialogue_completed signal
	else:
		complete_text()
