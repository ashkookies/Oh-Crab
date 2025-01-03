extends TileMap

# Track individual tile opacities
var tile_opacities = {}

func set_tile_opacity(coords: Vector2i, opacity: float):
	# Ensure opacity is between 0 and 1
	opacity = clamp(opacity, 0.0, 1.0)
	
	# Store the opacity value
	var key = str(coords.x) + "," + str(coords.y)
	tile_opacities[key] = opacity
	
	# Create a Sprite2D for this tile if it doesn't exist
	var sprite_name = "opacity_sprite_" + key
	var sprite = get_node_or_null(sprite_name)
	
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = sprite_name
		add_child(sprite)
		
		# Get tile texture and size
		var tile_data = get_cell_tile_data(0, coords)
		if tile_data:
			sprite.texture = tile_data.texture
			sprite.region_enabled = true
			sprite.region_rect = tile_data.texture_region
			
	# Position the sprite exactly over the tile
	sprite.position = map_to_local(coords)
	
	# Set the opacity
	sprite.modulate = Color(1, 1, 1, opacity)

# Helper function to get tile opacity
func get_tile_opacity(coords: Vector2i) -> float:
	var key = str(coords.x) + "," + str(coords.y)
	return tile_opacities.get(key, 1.0)  # Default to 1.0 if not set
