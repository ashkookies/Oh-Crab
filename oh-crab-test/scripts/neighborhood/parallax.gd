extends ParallaxBackground

@export var scroll_speed: float = 100.0
@export var sky_scale: float = 0.1
@export var clouds_scale: float = 0.2
@export var mountainback_scale: float = 0.3
@export var mountainback2_scale: float = 0.3
@export var mountain_scale: float = 0.4
@export var village_scale: float = 0.5
@export var river_scale: float = 0.6
@export var riverreflection_scale: float = 0.6
@export var riverfront_scale: float = 0.7
@export var is_indoor := false

@onready var camera = get_tree().get_first_node_in_group("camera")

func _ready():
	call_deferred("adjust_all_layers")
	get_tree().root.size_changed.connect(adjust_all_layers)

func _process(delta):
	if camera:
		# Calculate scroll offset while preserving backgrounds at negative x positions
		scroll_offset.x = -camera.global_position.x
		
		# Ensure each layer maintains its motion_mirroring for both positive and negative directions
		for layer in get_children():
			if layer is ParallaxLayer:
				var sprite = get_sprite_from_layer(layer)
				if sprite and sprite.texture:
					# Make sure motion_mirroring works in both directions
					layer.motion_mirroring.x = abs(layer.motion_mirroring.x)

func adjust_all_layers():
	var viewport_size = get_viewport().get_visible_rect().size
	
	for layer in get_children():
		if not layer is ParallaxLayer:
			continue
			
		var sprite = get_sprite_from_layer(layer)
		if not sprite or not sprite.texture:
			continue
			
		var texture_size = sprite.texture.get_size()
		var base_scale = (viewport_size.y * 1.2) / texture_size.y
		
		sprite.scale = Vector2(base_scale, base_scale)
		sprite.centered = false
		layer.motion_mirroring.x = texture_size.x * base_scale
				
		match layer.name:
			"Sky":
				sprite.position = Vector2(0, -85)
				layer.motion_scale.x = clouds_scale
				var sky_scale = (viewport_size.y * 3.0) / texture_size.y
				sprite.scale = Vector2(sky_scale, sky_scale)
			"Clouds":
				sprite.position = Vector2(0, -40)
				layer.motion_scale.x = clouds_scale
			"MountainBack2", "MountainBack", "Mountain":
				sprite.position = Vector2(0, -50)
				layer.motion_scale.x = mountain_scale
			"Village":
				sprite.position = Vector2(0, -50)
				layer.motion_scale.x = river_scale
			"River", "RiverReflection", "RiverFront":
				sprite.position = Vector2(0, -85)
				layer.motion_scale.x = river_scale
				var river_scale = (viewport_size.y * 1.0) / texture_size.y
				sprite.scale = Vector2(river_scale, river_scale)
				var riverreflection_scale = (viewport_size.y * 1.0) / texture_size.y
				sprite.scale = Vector2(riverreflection_scale, riverreflection_scale)
				var riverfront_scale = (viewport_size.y * 1.0) / texture_size.y
				sprite.scale = Vector2(riverfront_scale, riverfront_scale)
			_:
				sprite.position = Vector2(0, viewport_size.y * 0.0)
				layer.motion_scale.x = 0.5
		
		layer.position = Vector2.ZERO

func get_sprite_from_layer(layer):
	for child in layer.get_children():
		if child is Sprite2D:
			return child
	return null

func is_in_indoor_area() -> bool:
	# You can implement this based on your game's logic
	# For example, checking if the player is inside a specific area or zone
	var player = get_tree().get_first_node_in_group("player")
	if player:
		return player.is_in_group("indoor")
	return false
