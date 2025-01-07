extends RigidBody2D

@onready var interaction_area = $InteractionArea
@onready var sprite = $Sprite2D
@onready var prompt_text = $PromptText
var player_in_range = false

func _ready():
	print("ThrowTrash: Ready")
	interaction_area.body_entered.connect(_on_interaction)
	interaction_area.body_exited.connect(_on_exit)
	freeze = true
	prompt_text.hide()
	print("ThrowTrash: Initial setup complete")

func _process(_delta):
	if player_in_range:
		if Input.is_action_just_pressed("interact"):
			print("Interact key pressed while in range")
			throw_trash()
		else:
			print("In range, waiting for interact key")

func _on_interaction(body):
	if body.is_in_group("player"):  # Make sure your player is in the "player" group
		print("ThrowTrash: Player entered interaction area")
		player_in_range = true
		prompt_text.show()
		print("ThrowTrash: Prompt should be visible now")

func _on_exit(body):
	if body.is_in_group("player"):  # Make sure your player is in the "player" group
		print("ThrowTrash: Player exited interaction area")
		player_in_range = false
		prompt_text.hide()

func throw_trash():
	print("ThrowTrash: Throwing trash")
	freeze = false
	prompt_text.hide()
