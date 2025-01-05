extends ParallaxBackground

@export var scroll_speed: float = 100.0

func _ready():
	adjust_all_layers()
	get_tree().root.size_changed.connect(adjust_all_layers)

func adjust_all_layers():
	var viewport_size = get_viewport().get_visible_rect().size
	
	for layer in get_children():
		if not layer is ParallaxLayer:
			continue
			
		var sprite = get_sprite_from_layer(layer)
		if not sprite or not sprite.texture:
			continue
			
		var texture_size = sprite.texture.get_size()
		
		# Set different motion scales based on layer name
		match layer.name.to_lower():
			"sky":
				layer.motion_scale.x = 0.0
			"clouds":
				layer.motion_scale.x = 0.1
			"mountainback2", "mountainback":
				layer.motion_scale.x = 0.2
			"mountain":
				layer.motion_scale.x = 0.3
			"village":
				layer.motion_scale.x = 0.4
			"river", "riverreflection", "riverfront":
				layer.motion_scale.x = 0.5
		
		# Calculate scale to fill screen height
		var scale_y = viewport_size.y / texture_size.y
		var scale_x = scale_y  # Keep aspect ratio
		
		# If width doesn't cover the viewport, scale up to ensure full coverage
		if texture_size.x * scale_x < viewport_size.x:
			scale_x = viewport_size.x / texture_size.x
			scale_y = scale_x  # Keep aspect ratio
			
		sprite.scale = Vector2(scale_x, scale_y)
		
		# Set mirroring to the scaled texture width
		layer.motion_mirroring.x = texture_size.x * scale_x
		
		# Center the sprite horizontally and vertically
		sprite.position = Vector2(texture_size.x * scale_x / 2, texture_size.y * scale_y / 2)
		sprite.centered = true
		layer.position = Vector2.ZERO

func get_sprite_from_layer(layer: ParallaxLayer) -> Sprite2D:
	for child in layer.get_children():
		if child is Sprite2D:
			return child
	return null

func _process(delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	# Change direction to match the intuitive movement
	scroll_offset.x += scroll_speed * direction * delta
