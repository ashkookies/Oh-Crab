extends Node2D

@onready var crab = $Crab
@onready var chef = $Chef
@onready var dialogue_layer = $Dialogue

var crab_initial_pos: Vector2
var chef_initial_pos: Vector2
var current_question: String
var correct_answer: int
var battle_active: bool = false

@onready var question_label = $Dialogue/QuestionLabel
@onready var answer_input = $Dialogue/AnswerInput
@onready var submit_button = $Dialogue/SubmitButton

func _ready():
	crab_initial_pos = crab.position
	chef_initial_pos = chef.position
	submit_button.pressed.connect(_on_submit_pressed)
	start_battle()

func generate_question() -> Dictionary:
	var operations = ["+", "-", "*"]
	var operation = operations[randi() % operations.size()]
	var num1 = randi() % 10 + 1
	var num2 = randi() % 10 + 1
	
	var answer: int
	match operation:
		"+": answer = num1 + num2
		"-": answer = num1 - num2
		"*": answer = num1 * num2
	
	return {
		"question": str(num1) + " " + operation + " " + str(num2) + " = ?",
		"answer": answer
	}

func start_battle():
	if battle_active:
		return
		
	battle_active = true
	var question_data = generate_question()
	current_question = question_data.question
	correct_answer = question_data.answer
	
	question_label.text = current_question
	answer_input.text = ""
	answer_input.editable = true

func _on_submit_pressed():
	if !battle_active:
		return
		
	var player_answer = int(answer_input.text)
	answer_input.editable = false
	
	if player_answer == correct_answer:
		attack_animation(crab, chef)
	else:
		attack_animation(chef, crab)

func attack_animation(attacker, target):
	battle_active = false
	var tween = create_tween()
	var original_pos = attacker.position
	
	tween.tween_property(attacker, "position", target.position, 0.5)
	tween.tween_interval(0.3)
	tween.tween_property(attacker, "position", original_pos, 0.5)
	tween.tween_callback(start_battle)

func _input(event):
	if event.is_action_pressed("ui_accept") and battle_active:
		_on_submit_pressed()

func position_health_bars():
	# Offset for health bars above characters
	var health_bar_offset = Vector2(0, -30)
	
	# Ensure health bars are properly positioned relative to their parent
