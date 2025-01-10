extends RigidBody2D

signal trash_thrown

@onready var interaction_area = $InteractionArea
@onready var sprite = $Sprite2D
@onready var prompt_text = $PromptText

var player_in_range = false
var has_been_thrown = false
var drop_timer = 0.0
var dialogue_timer = 0.0
const DROP_DELAY = 0.5  # Time before the trash starts falling
const DIALOGUE_DELAY = 1.5  # Time to wait after dropping before showing dialogue
var dialogue_triggered = false

func _ready():
	print("ThrowTrash: Ready")
	interaction_area.body_entered.connect(_on_interaction)
	interaction_area.body_exited.connect(_on_exit)
	freeze = true
	prompt_text.hide()
	sprite.hide()  # Hide the sprite initially
	print("ThrowTrash: Initial setup complete")

func _process(delta):
	if player_in_range and not has_been_thrown:
		if Input.is_action_just_pressed("interact"):
			print("Interact key pressed while in range")
			throw_trash()
		else:
			print("In range, waiting for interact key")
	
	# Handle drop delay timer
	if has_been_thrown and freeze:
		drop_timer -= delta
		if drop_timer <= 0:
			print("ThrowTrash: Starting to fall")
			freeze = false  # Now the trash will start falling
			dialogue_timer = DIALOGUE_DELAY  # Start the dialogue delay timer
	
	# Handle dialogue delay timer
	if not freeze and not dialogue_triggered:
		dialogue_timer -= delta
		if dialogue_timer <= 0:
			print("ThrowTrash: Triggering dialogue")
			dialogue_triggered = true
			emit_signal("trash_thrown")  # This will trigger the dialogue in DialogueManager

func _on_interaction(body):
	if body.is_in_group("player"):
		print("ThrowTrash: Player entered interaction area")
		player_in_range = true
		if not has_been_thrown:
			prompt_text.show()
		print("ThrowTrash: Prompt should be visible now")

func _on_exit(body):
	if body.is_in_group("player"):
		print("ThrowTrash: Player exited interaction area")
		player_in_range = false
		prompt_text.hide()

func throw_trash():
	print("ThrowTrash: Throwing trash")
	prompt_text.hide()
	has_been_thrown = true
	sprite.show()  # Show the sprite
	drop_timer = DROP_DELAY  # Start the drop delay timer
