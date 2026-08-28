class_name PieceShadow
extends Node2D

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.26))
	draw_circle(Vector2.ZERO, 31.0, Color(0.015, 0.025, 0.04, 0.035))
	draw_circle(Vector2.ZERO, 25.0, Color(0.015, 0.025, 0.04, 0.055))
	draw_circle(Vector2.ZERO, 18.0, Color(0.015, 0.025, 0.04, 0.075))
