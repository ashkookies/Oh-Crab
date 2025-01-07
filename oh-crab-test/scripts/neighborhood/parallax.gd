extends ParallaxBackground

@export var scroll_speed: float = 100.0
@onready var camera = get_tree().get_first_node_in_group("camera")

func _ready():
	# Call adjust_all_layers after a tiny delay to ensure proper initialization
	call_deferred("adjust_all_layers")
	get_tree().root.size_changed.connect(adjust_all_layers)

func _process(delta):
	if camera:
		# Simpler, more stable scrolling
		scroll_offset.x = -camera.global_position.x

func adjust_all_layers():
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Add a scale multiplier to make everything bigger
	var size_multiplier = 1.5  # Increase this value to make everything bigger
	
	for layer in get_children():
		if not layer is ParallaxLayer:
			continue
			
		var sprite = get_sprite_from_layer(layer)
		if not sprite or not sprite.texture:
			continue
			
		var texture_size = sprite.texture.get_size()
		
		# Calculate scale to fit height and multiply by our size multiplier
		var scale_y = (viewport_size.y / texture_size.y) * size_multiplier
		var scale_x = scale_y  # Keep aspect ratio
		
		# Apply scaling
		sprite.scale = Vector2(scale_x, scale_y)
		
		# Center vertically, align to left
		sprite.centered = false
		sprite.position = Vector2(0, 0)
		
		# Adjust motion mirroring for the new scale
		layer.motion_mirroring.x = texture_size.x * scale_x
		layer.position = Vector2.ZERO

func get_sprite_from_layer(layer):
	for child in layer.get_children():
		if child is Sprite2D:
			return child
	return null
