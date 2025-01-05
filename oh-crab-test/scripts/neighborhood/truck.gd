extends Node2D
@export var base_speed: float = 600.0
@export var detection_radius: float = 1000.0
@export var smooth_factor: float = 0.1
var player: Node2D = null
var is_player_nearby: bool = false
var initial_position: Vector2
var animated_sprite: AnimatedSprite2D = null
# Add a signal that other nodes can connect to
signal animation_finished

func _ready():
	# Store the initial position
	initial_position = global_position
	
	# Get and connect the detection area
	var area = $InteractionArea
	if not area:
		print("ERROR: InteractionArea node not found!")
		return
		
	# Connect signals using proper syntax for GDScript 2.0
	area.body_entered.connect(_on_detection_area_body_entered)
	area.body_exited.connect(_on_detection_area_body_exited)
	print("Truck initialized at position: ", initial_position)

func _physics_process(delta):
	print("Physics Process - is_player_nearby:", is_player_nearby)
	print("Physics Process - player:", player)
	
	if is_player_nearby and player:
		var distance_to_player = global_position.distance_to(player.global_position)
		print("Distance to player:", distance_to_player)
		print("Detection radius:", detection_radius)
		
		if distance_to_player <= detection_radius:
			var direction = sign(global_position.x - player.global_position.x)
			var target_x = global_position.x + (direction * base_speed * delta)
			print("Moving truck:")
			print("- Current position:", global_position.x)
			print("- Target position:", target_x)
			print("- Direction:", direction)
			global_position.x = lerp(global_position.x, target_x, smooth_factor)

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		print("Player detected! Player position:", body.global_position)
		print("Truck position:", global_position)
		print("Distance:", global_position.distance_to(body.global_position))
		player = body
		is_player_nearby = true

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		is_player_nearby = false
		print("Player exited!")

# Optional animation functions that only run if animations exist
func play_shake():
	if animated_sprite:
		if animated_sprite.sprite_frames.has_animation("shake"):
			animated_sprite.play("shake")
		else:
			animation_finished.emit()
	else:
		animation_finished.emit()

func _on_animation_finished():
	animation_finished.emit()
