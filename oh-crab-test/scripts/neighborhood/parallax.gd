extends ParallaxBackground

@export var scroll_speed: float = 100.0
@onready var camera = get_tree().get_first_node_in_group("camera")  # Dynamically fetch the camera node

func _ready():
	# Adjust layers to fit the viewport
	adjust_all_layers()
	
	# Connect to viewport size change for dynamic resizing
	get_tree().root.size_changed.connect(adjust_all_layers)
	
	# Debug to ensure the camera is found
	if camera:
		print("Camera found: ", camera.name)
	else:
		print("Camera not found! Ensure it is in the 'camera' group.")

func _process(_delta):
	if camera:
		# Update the scroll offset based on the camera's global position
		scroll_offset = -camera.global_position

func adjust_all_layers():
	# Get the viewport size
	var viewport_size = get_viewport().get_visible_rect().size
	
	for layer in get_children():
		if not layer is ParallaxLayer:
			continue  # Skip non-ParallaxLayer nodes
		
		# Get the sprite child of the layer
		var sprite = get_sprite_from_layer(layer)
		if not sprite or not sprite.texture:
			continue  # Skip if no sprite or texture is found
		
		# Calculate scaling to fit the screen dynamically
		var texture_size = sprite.texture.get_size()
		var scale_x = viewport_size.x / texture_size.x
		var scale_y = viewport_size.y / texture_size.y
		var final_scale = max(scale_x, scale_y) * 1.5  # Ensure a buffer to prevent gaps
		
		# Apply scaling and reset positions
		sprite.scale = Vector2(final_scale, final_scale)
		sprite.centered = true
		sprite.position = Vector2.ZERO
		layer.position = Vector2.ZERO
		
		# Set motion mirroring to ensure proper scrolling
		layer.motion_mirroring.x = texture_size.x * final_scale
		layer.motion_mirroring.y = texture_size.y * final_scale

func get_sprite_from_layer(layer):
	# Find the first Sprite2D node in the layer
	for child in layer.get_children():
		if child is Sprite2D:
			return child
	return null
