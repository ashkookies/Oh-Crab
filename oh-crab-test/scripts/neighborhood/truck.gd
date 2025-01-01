#truck.gd

extends Node2D

@export var base_speed: float = 600.0  # Speed when the truck starts moving
@export var detection_radius: float = 1000.0  # Distance at which the truck starts moving
@export var smooth_factor: float = 0.1  # Controls the smoothing; lower values = smoother

var player: Node2D = null
var is_player_nearby: bool = false
var initial_position: Vector2

func _ready():
	# Store the initial position
	initial_position = global_position

	# Get and connect the detection area
	var area = $InteractionArea
	if not area:
		print("ERROR: InteractionArea node not found!")
		return

	area.body_entered.connect(_on_detection_area_body_entered)
	area.body_exited.connect(_on_detection_area_body_exited)
	print("Truck initialized at position: ", initial_position)

func _physics_process(delta):
	# Only move if the player is nearby
	if is_player_nearby and player:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player <= detection_radius:
			# Determine the horizontal direction
			var direction = sign(global_position.x - player.global_position.x)
			# Calculate target X position
			var target_x = global_position.x + (direction * base_speed * delta)
			# Smoothly interpolate to the target X position
			global_position.x = lerp(global_position.x, target_x, smooth_factor)

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		print("Player detected!")
		player = body
		is_player_nearby = true

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		is_player_nearby = false
		print("Player exited!")
