# Coin.gd
extends Area2D

var textbox

func _ready():
	# Get the textbox node using the absolute path from root
	textbox = get_node("/root/Game/Textbox")
	if !textbox:
		push_error("Textbox not found! Check the node path.")

func _on_body_entered(_body: Node2D) -> void:
	if textbox:
		# Disable the collision and hide the coin immediately
		set_collision_layer_value(0, false)
		set_collision_mask_value(0, false)
		visible = false
		textbox.queue_text("You found a coin!")
		# Don't wait for dialogue_finished to queue_free
		queue_free()
