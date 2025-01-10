extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var dialogue_node = $"../Dialogue"

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

var is_movement_locked: bool = false

func _physics_process(delta: float) -> void:
	if is_movement_locked:
		velocity.x = 0
		animated_sprite.play("idle")
		move_and_slide()
		return

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Movement
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		if direction > 0:
			animated_sprite.play("walking_right")
		else:
			animated_sprite.play("walking_left")
	else:
		velocity.x = 0
		animated_sprite.play("idle")
	
	move_and_slide()

func lock_movement():
	is_movement_locked = true

func unlock_movement():
	is_movement_locked = false
