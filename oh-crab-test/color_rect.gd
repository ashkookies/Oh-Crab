# HealthBar.gd
extends ColorRect

var health = 100
var max_health = 100

func _ready():
	custom_minimum_size = Vector2(50, 10)

func update_health(new_health):
	health = new_health
	queue_redraw()

func _draw():
	var health_rect = Rect2(0, 0, size.x * (health / max_health), size.y)
	draw_rect(health_rect, Color.GREEN)
