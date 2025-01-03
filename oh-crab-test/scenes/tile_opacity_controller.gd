extends TileMap

var tile_data_image: Image
var tile_data_texture: ImageTexture
var shader_material: ShaderMaterial

func _ready():
	# Create shader material
	shader_material = ShaderMaterial.new()
	shader_material.shader = preload("res://scripts/neighborhood/house.gdshader")  # Adjust path as needed
	
	# Initialize tile data texture
	var map_size = get_used_rect().size
	tile_data_image = Image.create(map_size.x, map_size.y, false, Image.FORMAT_R8)
	tile_data_image.fill(Color(1, 0, 0, 0))  # Initialize all tiles to full opacity
	
	# Update texture and shader uniforms
	_update_texture()
	shader_material.set_shader_parameter("tile_map_size", Vector2(map_size.x, map_size.y))
	
	# Apply shader material
	material = shader_material

func _update_texture():
	if tile_data_texture == null:
		tile_data_texture = ImageTexture.create_from_image(tile_data_image)
	else:
		tile_data_texture.update(tile_data_image)
	shader_material.set_shader_parameter("tile_data", tile_data_texture)

func set_tile_opacity(tile_pos: Vector2i, opacity: float):
	# Ensure opacity is in valid range
	opacity = clamp(opacity, 0.0, 1.0)
	
	# Convert tile position to local coordinates
	var local_pos = tile_pos - get_used_rect().position
	
	# Set the opacity in the data image
	tile_data_image.set_pixel(local_pos.x, local_pos.y, Color(opacity, 0, 0, 0))
	
	# Update the texture
	_update_texture()

func get_tile_opacity(tile_pos: Vector2i) -> float:
	var local_pos = tile_pos - get_used_rect().position
	return tile_data_image.get_pixel(local_pos.x, local_pos.y).r

# Example function to fade a specific tile
func fade_tile(tile_pos: Vector2i, target_opacity: float, duration: float):
	var tween = create_tween()
	var start_opacity = get_tile_opacity(tile_pos)
	
	tween.tween_method(
		func(value: float): set_tile_opacity(tile_pos, value),
		start_opacity,
		target_opacity,
		duration
	)
