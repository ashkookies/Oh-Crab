extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D

const SPEED = 30.0
const JUMP_VELOCITY = -190.0
const LADDER_CLIMB_SPEED = 30.0
const LADDER_MOVE_SPEED = 30.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_move = true
var near_ladder = false
var on_ladder = false
var at_ladder_top = false

func _physics_process(delta: float) -> void:
	# Clear ladder states if not near a ladder
	if not near_ladder:
		on_ladder = false
		at_ladder_top = false
		enable_gravity()
	
	# Handle ladder entry/exit
	if near_ladder:
		if Input.is_action_just_pressed("ui_up"):
			if not at_ladder_top:  # Only enter ladder mode if not at top
				on_ladder = true
		elif Input.is_action_just_pressed("ui_down"):
			if at_ladder_top or is_on_floor():
				on_ladder = true
				at_ladder_top = false
	
	  # Handle gravity
	if not on_ladder and not at_ladder_top:
		if not is_on_floor():
			velocity.y += gravity * delta
	
	if can_move:
		var direction := Input.get_axis("ui_left", "ui_right")
		
		# Handle standing on top of the ladder
		if at_ladder_top:
			velocity.y = 0  # Stay at the top
			
			if Input.is_action_just_pressed("ui_down"):
				at_ladder_top = false
				on_ladder = true
				velocity.y = LADDER_CLIMB_SPEED
			
			# Simplified movement at top
			velocity.x = direction * SPEED
			if direction != 0:
				if direction > 0:
					animated_sprite.play("walk_right")
				else:
					animated_sprite.play("walk_left")
			else:
				animated_sprite.play("idle")
				velocity.x = 0
				
			if Input.is_action_just_pressed("ui_accept"):
				at_ladder_top = false
				velocity.y = JUMP_VELOCITY
				enable_gravity()
		
		# Regular ladder climbing logic
		elif on_ladder:
			velocity.y = 0  # Reset vertical velocity by default
			
			if Input.is_action_pressed("ui_up"):
				velocity.y = -LADDER_CLIMB_SPEED
				#animated_sprite.play("climb")
			elif Input.is_action_pressed("ui_down"):
				velocity.y = LADDER_CLIMB_SPEED
				#animated_sprite.play("climb")
			else:
				animated_sprite.play("idle")
			
			velocity.x = direction * LADDER_MOVE_SPEED
		
		# Normal movement logic
		else:
			if Input.is_action_just_pressed("ui_accept") and is_on_floor():
				velocity.y = JUMP_VELOCITY
			
			velocity.x = direction * SPEED
			if velocity.x == 0:
				animated_sprite.play("idle")
			else:
				if velocity.x > 0:
					animated_sprite.play("walk_right")
				else:
					animated_sprite.play("walk_left")
	
		move_and_slide()
		
		if on_ladder:
			# Reset vertical velocity when starting ladder movement
			if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
				velocity.y = 0
			
			# Ladder movement
			if Input.is_action_pressed("ui_up"):
				if not at_ladder_top:
					velocity.y = -LADDER_CLIMB_SPEED
					#animated_sprite.play("climb")
				else:
					velocity.y = 0
					on_ladder = false
			elif Input.is_action_pressed("ui_down"):
				velocity.y = LADDER_CLIMB_SPEED
				at_ladder_top = false
				#animated_sprite.play("climb")
			else:
				velocity.y = 0
				animated_sprite.play("idle")
			
			# Horizontal movement on ladder
			if direction:
				velocity.x = direction * LADDER_MOVE_SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, LADDER_MOVE_SPEED)
		else:
			# Normal movement logic
			if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or at_ladder_top):
				velocity.y = JUMP_VELOCITY
				at_ladder_top = false
			
			# Prevent falling through ladder top
			if at_ladder_top and velocity.y > 0:
				velocity.y = 0
			
			if direction:
				velocity.x = direction * SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
			
			# Update animation based on movement and jump state
			if not is_on_floor() and not at_ladder_top:
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
		velocity.x = move_toward(velocity.x, 0, SPEED)
		animated_sprite.play("idle")
	
	move_and_slide()

func _ready():
	add_to_group("player")

func set_can_move(value: bool):
	can_move = value

func enable_gravity() -> void:
	if not at_ladder_top:
		gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func disable_gravity() -> void:
	gravity = 0
