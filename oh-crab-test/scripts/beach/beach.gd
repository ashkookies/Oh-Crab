# DialogueManager.gd
extends Node

@onready var dialogue_system = $Dialogue
@onready var interaction_area_4 = $Scene4
@onready var interaction_area_5 = $Scene5
@onready var interaction_area_6 = $Scene6
@onready var throw_trash = $ThrowTrash
@onready var player = get_tree().get_first_node_in_group("player")

var scene4_dialogue = [
	"Phew! Finally!"
]

var scene5_dialogue = [
	"(Oh! So this is where our trash ends up. Might as well do the same)"
]

var throw_dialogue = [
	"*Nugu throws the trash into the water*",
	"(Well... time to go home)"
]

var scene6_dialogue = [
	"Voices: ~Do you truly wish to follow in this path?~",
	"*Nugu turns to the left*",
	"Nugu: What? Who's there?"
]

var current_messages = []
var current_message_index = 0
var scene4_triggered = false
var scene5_triggered = false
var scene6_triggered = false
var has_thrown_trash = false

func _ready():
	if dialogue_system:
		dialogue_system.dialogue_completed.connect(_on_dialogue_completed)
	else:
		print("ERROR: DialogueSystem node not found!")
		
	if throw_trash:
		throw_trash.trash_thrown.connect(_on_trash_thrown)
	else:
		print("ERROR: ThrowTrash node not found!")
		
	if interaction_area_5:
		interaction_area_5.on_interaction = func(): _on_scene5_entered()
		interaction_area_5.on_exit = func(): _on_interaction_area_exited()
	else:
		print("ERROR: Scene5 node not found!")

	if interaction_area_4:
		interaction_area_4.on_interaction = func(): _on_scene4_entered()
		interaction_area_4.on_exit = func(): _on_interaction_area_exited()
	else:
		print("ERROR: Scene4 node not found!")
		
	if interaction_area_6:
		interaction_area_6.on_interaction = func(): _on_scene6_entered()
		interaction_area_6.on_exit = func(): _on_interaction_area_exited()
	else:
		print("ERROR: Scene6 node not found!")

func _input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		if dialogue_system.dialogue_active:
			dialogue_system.advance_dialogue()

func _on_scene4_entered():
	if !scene4_triggered:
		current_messages = scene4_dialogue
		current_message_index = 0
		trigger_next_dialogue()
		scene4_triggered = true
		player.can_move = false

func _on_scene5_entered():
	if !scene5_triggered:
		current_messages = scene5_dialogue
		current_message_index = 0
		trigger_next_dialogue()
		scene5_triggered = true
		player.can_move = false

func _on_scene6_entered():
	if has_thrown_trash and !scene6_triggered:
		current_messages = scene6_dialogue
		current_message_index = 0
		trigger_next_dialogue()
		scene6_triggered = true
		player.can_move = false

func _on_interaction_area_exited():
	if dialogue_system.dialogue_active:
		dialogue_system.hide_dialogue()

func _on_trash_thrown():
	has_thrown_trash = true
	current_messages = throw_dialogue
	current_message_index = 0
	trigger_next_dialogue()
	player.can_move = false

func _on_dialogue_completed():
	current_message_index += 1
	if current_message_index < current_messages.size():
		if current_messages == scene6_dialogue and current_message_index == 1:
			# Turn player sprite to the left after first dialogue in Scene6
			if player:
				var animated_sprite = player.get_node("AnimatedSprite2D")
				if animated_sprite:
					animated_sprite.flip_h = true
			trigger_next_dialogue()
		else:
			trigger_next_dialogue()
	else:
		player.can_move = true

func trigger_next_dialogue():
	if current_message_index < current_messages.size():
		dialogue_system.trigger_dialogue(current_messages[current_message_index])
