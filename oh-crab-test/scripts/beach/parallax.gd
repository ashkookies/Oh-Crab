extends ParallaxBackground

@export var scroll_speed: float = 100.0
@export var vertical_offset: float = 0.0  # Added for vertical position control
@export var global_scale: float = 1.0     # Added for scale control

@onready var camera = get_tree().get_first_node_in_group("camera")

func _ready():
	call_deferred("adjust_all_layers")
	get_tree().root.size_changed.connect(adjust_all_layers)

func _process(delta):
	if camera:
		scroll_offset.x = -camera.global_position.x

func set_vertical_offset(offset: float):
	vertical_offset = offset
	adjust_all_layers()

func set_global_scale(scale: float):
	global_scale = scale
	adjust_all_layers()

func adjust_all_layers():
	var viewport_size = get_viewport().get_visible_rect().size
	var size_multiplier = 0.2 * global_scale  # Apply global scale to size multiplier
	
	# Calculate the ground position (assuming it's at 80% of the screen height)
	var ground_position = viewport_size.y * 0.2
	
	for layer in get_children():
		if not layer is ParallaxLayer:
			continue
			
		var sprite = get_sprite_from_layer(layer)
		if not sprite or not sprite.texture:
			continue
			
		var texture_size = sprite.texture.get_size()
		
		# Calculate scale to fit height and multiply by size multiplier
		var scale_y = (viewport_size.y / texture_size.y) * size_multiplier
		var scale_x = scale_y  # Keep aspect ratio
		
		# Apply scaling
		sprite.scale = Vector2(scale_x, scale_y)
		
		# Calculate vertical position based on ground level and add vertical offset
		var scaled_height = texture_size.y * scale_y
		var y_position = ground_position - scaled_height + vertical_offset
		
		# Center horizontally, position vertically relative to ground
		sprite.centered = false
		sprite.position = Vector2(0, y_position)
		
		# Adjust motion mirroring for the new scale
		layer.motion_mirroring.x = texture_size.x * scale_x
		
		# Adjust ParallaxLayer motion scale based on layer depth
		match sprite.get_parent().name.to_lower():
			"sky":
				layer.motion_scale.x = 0.0
			"clouds1":
				layer.motion_scale.x = 0.3
			"clouds2":
				layer.motion_scale.x = 0.4
			"land":
				layer.motion_scale.x = 0.6

func get_sprite_from_layer(layer):
	for child in layer.get_children():
		if child is Sprite2D:
			return child
	return null
