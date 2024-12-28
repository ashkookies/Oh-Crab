# Textbox.gd
extends CanvasLayer

signal dialogue_finished

const CHAR_READ_RATE = 0.05

@onready var textbox_container = $TextboxContainer
@onready var start_symbol = $TextboxContainer/MarginContainer/HBoxContainer/Start
@onready var end_symbol = $TextboxContainer/MarginContainer/HBoxContainer/End
@onready var label = $TextboxContainer/MarginContainer/HBoxContainer/Label

enum State {
	READY,
	READING,
	FINISHED
}

var current_state = State.READY
var text_queue: Array = []  # Initialize as empty array

func _ready():
	print("Starting state: State.READY")
	hide_textbox()

func _process(_delta):
	match current_state:
		State.READY:
			if text_queue.size() > 0:  # Changed from empty() to size() > 0
				display_text()
		State.READING:
			if Input.is_action_just_pressed("ui_accept"):
				label.visible_ratio = 1.0
				var tween = get_tree().create_tween()
				tween.kill()
				end_symbol.text = "v"
				change_state(State.FINISHED)
		State.FINISHED:
			if Input.is_action_just_pressed("ui_accept"):
				change_state(State.READY)
				hide_textbox()
				dialogue_finished.emit()

func queue_text(next_text):
	text_queue.append(next_text)  # Changed from push_back to append

func hide_textbox():
	start_symbol.text = ""
	end_symbol.text = ""
	label.text = ""
	textbox_container.hide()

func show_textbox():
	start_symbol.text = "*"
	textbox_container.show()

func display_text():
	var next_text = text_queue.pop_front()
	label.text = next_text
	label.visible_ratio = 0.0
	change_state(State.READING)
	show_textbox()
	
	var tween = create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, len(next_text) * CHAR_READ_RATE)
	tween.tween_callback(func(): _on_tween_completed())

func change_state(next_state):
	current_state = next_state
	match current_state:
		State.READY:
			print("Changing state to: State.READY")
		State.READING:
			print("Changing state to: State.READING")
		State.FINISHED:
			print("Changing state to: State.FINISHED")

func _on_tween_completed():
	end_symbol.text = "v"
	change_state(State.FINISHED)
