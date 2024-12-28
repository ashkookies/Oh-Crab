#player.gd
extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D

const SPEED = 60.0
const JUMP_VELOCITY = -300.0

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_move = true  # Add this variable to control movement

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Only process movement inputs if can_move is true
	if can_move:
		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		# Update animation based on movement and jump state
		if not is_on_floor():
			if direction > 0:
				animated_sprite.play("jump_right")
			elif direction < 0:
				animated_sprite.play("jump_left")
			else:
				animated_sprite.play("idle")
		elif direction > 0:
			animated_sprite.play("walk_right")
		elif direction < 0:
			animated_sprite.play("walk_left")
		else:
			animated_sprite.play("idle")
	else:
		# When movement is disabled, stop horizontal movement
		velocity.x = move_toward(velocity.x, 0, SPEED)
		# Still play idle animation when stopped
		animated_sprite.play("idle")
	
	# Always apply movement (for gravity and stopping)
	move_and_slide()

func _on_coin_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.

func _ready():
	add_to_group("player")

# Add this function to control movement from outside
func set_can_move(value: bool):
	can_move = value
