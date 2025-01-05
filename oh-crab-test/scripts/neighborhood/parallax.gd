extends ParallaxBackground

@export var scroll_speed: float = 100.0
@export var sprite_scale: float = 1.0

# Define specific motion scales for each layer type
const BACKGROUND_SCALE = 0.2  # Sky and clouds
const MIDGROUND_SCALE = 0.5   # Mountains and houses
const FOREGROUND_SCALE = 0.8  # Front elements

func _ready():
	await get_tree().process_frame
	adjust_all_layers()
	get_tree().root.size_changed.connect(adjust_all_layers)  # Changed to connect directly to adjust_all_layers

func get_all_parallax_layers() -> Array:
	var layers = []
	for child in get_children():
		if child is ParallaxLayer:
			layers.append(child)
	return layers

func adjust_all_layers():
	var viewport_size = get_viewport().get_visible_rect().size
	
	for i in range(get_all_parallax_layers().size()):
		var layer = get_all_parallax_layers()[i]
		var sprite = get_sprite_from_layer(layer)
		if sprite and sprite.texture:
			var texture_size = sprite.texture.get_size()
			
			# Set motion scale based on layer position
			match i:
				0: # Background (sky/clouds)
					layer.motion_scale = Vector2(BACKGROUND_SCALE, 1)
				1: # Midground (mountains/houses)
					layer.motion_scale = Vector2(MIDGROUND_SCALE, 1)
				_: # Foreground and other layers
					layer.motion_scale = Vector2(FOREGROUND_SCALE, 1)
			
			# Calculate scale
			sprite.scale = Vector2(sprite_scale, sprite_scale)
			
			# Ensure the sprite covers enough area for scrolling both directions
			var required_width = viewport_size.x / layer.motion_scale.x
			var repeats = ceil(required_width / (texture_size.x * sprite_scale))
			
			# Set mirroring to exactly match the texture size
			layer.motion_mirroring = Vector2(texture_size.x * sprite_scale, 0)
			
			# Position sprite to cover screen in both directions
			var screen_center = viewport_size.x / 2
			var texture_center = (texture_size.x * sprite_scale) / 2
			sprite.position.x = screen_center - texture_center
			sprite.position.y = 0

func get_sprite_from_layer(layer: ParallaxLayer) -> Sprite2D:
	for child in layer.get_children():
		if child is Sprite2D:
			return child
	return null

func _process(delta):
	# Handle scrolling speed
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		scroll_offset.x -= scroll_speed * direction * delta
