extends Node

signal scene_changed()

var current_scene = null
var fade_overlay: ColorRect
var fade_duration: float = 1.0

func _ready() -> void:
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	setup_fade_overlay()

func setup_fade_overlay() -> void:
	# Create a ColorRect that covers the entire viewport
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color(0, 0, 0, 1.0)  # Start fully opaque
	
	# Set up the CanvasLayer first
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	add_child(canvas_layer)
	
	# Create a Control node to handle full-screen sizing
	var control = Control.new()
	control.anchor_right = 1.0  # Stretch to full width
	control.anchor_bottom = 1.0  # Stretch to full height
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(control)
	
	# Setup the ColorRect to fill the entire Control
	fade_overlay.anchor_right = 1.0
	fade_overlay.anchor_bottom = 1.0
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(fade_overlay)
	
	# Start with fade in
	fade_in()

func fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, fade_duration)

func fade_out() -> void:
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, fade_duration)
	await tween.finished

func change_scene(next_scene_path: String) -> void:
	await fade_out()
	
	# Free the current scene
	current_scene.free()
	
	# Load and instance the new scene
	var new_scene = load(next_scene_path)
	current_scene = new_scene.instantiate()
	
	# Add it to root
	get_tree().root.add_child(current_scene)
	
	# Make it compatible with the SceneTree.change_scene_to_file() API
	get_tree().current_scene = current_scene
	
	emit_signal("scene_changed")
	fade_in()
