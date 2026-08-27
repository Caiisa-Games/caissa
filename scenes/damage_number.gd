class_name DamageNumber
extends Node2D

enum Result { DAMAGE, HEALING, MITIGATED, BLOCKED }

const DAMAGE_COLOR := Color("#ff5b5b")
const HEALING_COLOR := Color("#62e89b")
const MITIGATED_COLOR := Color("#ffbc4d")
const BLOCKED_COLOR := Color("#75caff")

@onready var label: Label = $Label

func configure(amount: int, result: Result, index: int, is_critical := false) -> void:
	var color := _get_color(result)
	label.text = "+%d" % amount if result == Result.HEALING else str(amount)
	label.modulate = color
	label.add_theme_font_size_override("font_size", 10 if is_critical else 8)
	label.add_theme_constant_override("outline_size", 3 if is_critical else 2)

	var horizontal_offset := float((index % 5) - 2) * 8.0
	position += Vector2(horizontal_offset, -float(index % 2) * 5.0)
	call_deferred("_play", horizontal_offset, is_critical)

func _play(horizontal_offset: float, is_critical: bool) -> void:
	var start_position := position
	var arc_target := start_position + Vector2(horizontal_offset * 0.35, -30.0)
	scale = Vector2.ONE * (0.72 if is_critical else 0.62)
	modulate.a = 1.0

	var motion_tween := create_tween()
	motion_tween.set_parallel(true)
	motion_tween.tween_property(self, "position", arc_target, 0.78).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	motion_tween.tween_property(self, "modulate:a", 0.0, 0.26).set_delay(0.52).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	motion_tween.chain().tween_callback(queue_free)

	var pop_tween := create_tween()
	pop_tween.tween_property(self, "scale", Vector2.ONE * (1.24 if is_critical else 1.08), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(self, "scale", Vector2.ONE * (1.05 if is_critical else 0.94), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _get_color(result: Result) -> Color:
	match result:
		Result.HEALING:
			return HEALING_COLOR
		Result.MITIGATED:
			return MITIGATED_COLOR
		Result.BLOCKED:
			return BLOCKED_COLOR
		_:
			return DAMAGE_COLOR
