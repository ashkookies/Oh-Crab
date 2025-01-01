extends CanvasLayer

signal dialogue_finished

# Constants
const CHAR_READ_RATE = 0.05

# Onready variables
@onready var textbox_container = $TextboxContainer
@onready var text_label = $TextboxContainer/MarginContainer/HBoxContainer/Label
@onready var start_symbol = $TextboxContainer/MarginContainer/HBoxContainer/Start
@onready var end_symbol = $TextboxContainer/MarginContainer/HBoxContainer/End

# Export variables
@export var text_speed: float = 0.05
@export var auto_hide: bool = true

# State enum
enum State {
	READY,
	READING,
	FINISHED
}

# State variables
var current_state = State.READY
var text_queue: Array = []
var current_text: String = ""
var displayed_text: String = ""
var is_text_completed: bool = false
var dialogue_active: bool = false

func _ready():
	textbox_container.hide()
	reset_dialogue_state()
	
	if text_speed > 0:
		process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta):
	match current_state:
		State.READY:
			if text_queue.size() > 0:
				display_text()
		State.READING:
			if Input.is_action_just_pressed("ui_accept"):
				complete_text()
		State.FINISHED:
			if Input.is_action_just_pressed("ui_accept"):
				change_state(State.READY)
				if text_queue.size() == 0:
					dialogue_finished.emit()

func reset_dialogue_state():
	current_text = ""
	displayed_text = ""
	is_text_completed = false
	text_queue.clear()

func queue_text(next_text: String):
	text_queue.append(next_text)
	
	if current_state == State.READY and text_queue.size() == 1:
		display_text()

func show_dialogue(text: String):
	if text.is_empty():
		return
	queue_text(text)
	dialogue_active = true
	textbox_container.show()

func trigger_dialogue(text: String):
	show_dialogue(text)

func hide_dialogue():
	dialogue_active = false
	textbox_container.hide()
	reset_dialogue_state()

func show_textbox():
	start_symbol.text = "*"
	textbox_container.show()

func display_text():
	current_text = text_queue.pop_front()
	text_label.text = current_text
	text_label.visible_ratio = 0.0
	change_state(State.READING)
	show_textbox()
	
	var tween = create_tween()
	tween.tween_property(text_label, "visible_ratio", 1.0, len(current_text) * CHAR_READ_RATE)
	tween.tween_callback(func(): _on_tween_completed())

func complete_text():
	if current_state == State.READING:
		text_label.visible_ratio = 1.0
		var tween = get_tree().create_tween()
		tween.kill()
		end_symbol.text = "v"
		change_state(State.FINISHED)

func change_state(next_state):
	current_state = next_state

func _on_tween_completed():
	end_symbol.text = "v"
	change_state(State.FINISHED)
