extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
const SPEED = 60.0
const JUMP_VELOCITY = -300.0

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

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

	move_and_slide()

func _on_coin_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.
