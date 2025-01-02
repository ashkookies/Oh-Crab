extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
const SPEED = 130.0
const JUMP_VELOCITY = -300.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if direction != 0:
		if direction > 0:
			animated_sprite.play("walking_right")
		else:
			animated_sprite.play("walking_left")
	else:
		animated_sprite.play("idle")
		velocity.x = 0
	
				
	move_and_slide()
