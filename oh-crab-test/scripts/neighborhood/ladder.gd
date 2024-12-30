extends Area2D

@onready var top_area: CollisionShape2D = $TopArea

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	assert(top_area != null, "TopArea CollisionShape2D is required")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.near_ladder = true
		# Check if player is entering through the top area
		var top_area_position = top_area.global_position
		var top_area_extents = top_area.shape.extents if top_area.shape is RectangleShape2D else Vector2.ZERO
		if body.global_position.y <= top_area_position.y + top_area_extents.y:
			body.at_ladder_top = true
			body.on_ladder = false  # Force off ladder state when at top
			body.disable_gravity()
			print("Entered top area - pos_y: ", body.global_position.y, " top_y: ", top_area_position.y)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Exiting ladder area - was_at_top: ", body.at_ladder_top, " was_on_ladder: ", body.on_ladder)
		body.near_ladder = false
		
		# Only keep at_ladder_top true if they're actually at the top position
		var top_area_position = top_area.global_position
		var top_area_extents = top_area.shape.extents if top_area.shape is RectangleShape2D else Vector2.ZERO
		if body.global_position.y > top_area_position.y + top_area_extents.y:
			body.at_ladder_top = false
			body.enable_gravity()
