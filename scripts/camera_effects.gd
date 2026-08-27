class_name CameraEffects
extends Node

const FULL_SHAKE := 0.4
const REDUCED_SHAKE := 0.16

var board: Node2D

var _base_position := Vector2.ZERO
var _effect_token := 0
var _return_tween: Tween

func _ready() -> void:
	board = get_parent().get_node_or_null("BoardLayer/Board") as Node2D
	if board == null:
		push_error("CameraEffects could not find BoardLayer/Board.")
		return
	_base_position = board.position

func play_damage_impact(target: Tile, is_kill: bool) -> void:
	if _is_off() or target == null:
		return

	var intensity := _shake_amount() * (1.25 if is_kill else 0.8)
	await _focus_and_shake(target.global_position, intensity, 0.16 if is_kill else 0.12)
	if is_kill and _is_full():
		var prior_time_scale := Engine.time_scale
		Engine.time_scale = 0.0
		await get_tree().create_timer(0.08, true, false, true).timeout
		Engine.time_scale = prior_time_scale

func play_knockback(from_tile: Tile, to_tile: Tile) -> void:
	if _is_off() or from_tile == null or to_tile == null:
		return

	var direction := (to_tile.global_position - from_tile.global_position).normalized()
	var focus := to_tile.global_position + direction * 20.0
	await _focus_and_shake(focus, _shake_amount() * 0.55, 0.16)

func play_promotion(target: Tile) -> void:
	if _is_off() or target == null:
		return

	await _focus_and_shake(target.global_position, _shake_amount() * 0.35, 0.20)

func _focus_and_shake(_focus: Vector2, shake_amount: float, duration: float) -> void:
	if board == null:
		return

	_effect_token += 1
	var token := _effect_token
	_reset_to_base()

	# Keep impacts local: reframing toward the target made the whole board jump.
	var focused_position := _base_position
	var tween := create_tween()
	tween.tween_property(board, "position", focused_position, duration * 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished

	if token != _effect_token:
		return
	var shakes := 3 if _is_full() else 2
	for _i in range(shakes):
		if token != _effect_token:
			return
		board.position = focused_position + Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
		await get_tree().create_timer(duration / float(shakes * 2)).timeout
		board.position = focused_position
		await get_tree().create_timer(duration / float(shakes * 2)).timeout

	if token == _effect_token:
		_reset_to_base(duration * 0.62)

func _reset_to_base(duration := 0.0) -> void:
	if board == null:
		return
	if _return_tween and _return_tween.is_valid():
		_return_tween.kill()
	if duration <= 0.0:
		board.position = _base_position
		return
	_return_tween = create_tween()
	_return_tween.tween_property(board, "position", _base_position, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _is_full() -> bool:
	return SettingsManager.data.camera_effects_mode == SettingsData.CameraEffectsMode.FULL

func _is_off() -> bool:
	return SettingsManager.data.camera_effects_mode == SettingsData.CameraEffectsMode.OFF

func _shake_amount() -> float:
	return FULL_SHAKE if _is_full() else REDUCED_SHAKE
