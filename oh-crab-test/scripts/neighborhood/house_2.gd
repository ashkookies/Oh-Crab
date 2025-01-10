extends Node2D

@onready var dialogue_ui = $Dialogue
@onready var mom_area = $Mom/InteractionArea
@onready var player = $Player
var has_triggered_mom_dialogue = false
var dialogue_active = false
var dialogue_step = 0
var current_scene = 1

func _ready():
	# Connect the mom's interaction area signal
	if mom_area:
		mom_area.body_entered.connect(_on_mom_area_entered)
		print("DEBUG: Mom interaction area signals connected")
	
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)

func _input(event):
	if event.is_action_pressed("ui_accept") and dialogue_active:
		print("DEBUG: Dialogue advance triggered")
		dialogue_step += 1
		show_mom_dialogue()
		get_viewport().set_input_as_handled()

func _on_mom_area_entered(body):
	print("DEBUG: Body entered Mom area:", body.name)
	if body == player and not has_triggered_mom_dialogue:
		start_mom_dialogue()

func start_mom_dialogue():
	if not has_triggered_mom_dialogue:
		print("DEBUG: Starting mom dialogue")
		current_scene = 1
		dialogue_step = 0
		dialogue_active = true
		has_triggered_mom_dialogue = true
		
		if player:
			player.set_can_move(false)
			
		if dialogue_ui:
			dialogue_ui.visible = true
			show_mom_dialogue()
		else:
			print("DEBUG: Dialogue UI is null!")

func show_mom_dialogue():
	print("DEBUG: Showing mom dialogue step:", dialogue_step)
	if not dialogue_ui:
		return
	
	dialogue_ui.visible = true
	
	match dialogue_step:
		0:
			dialogue_ui.trigger_dialogue("It seems like you've finished your task")
		1:
			dialogue_ui.trigger_dialogue("Well done!")
		2:
			dialogue_ui.trigger_dialogue("You can go back to bed now if you want")
		_:
			end_dialogue()
			return

func end_dialogue():
	print("DEBUG: Ending dialogue")
	if dialogue_ui:
		dialogue_ui.hide_dialogue()
	dialogue_active = false
	
	if player:
		print("DEBUG: Re-enabling player movement")
		player.set_can_move(true)
