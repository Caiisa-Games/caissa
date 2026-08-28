class_name CameraEffects
extends Node

const FULL_SHAKE := 0.8
const REDUCED_SHAKE := 0.4

var screen_layers: Array[CanvasLayer] = []
var _base_offsets: Array[Vector2] = []

var _effect_token := 0
var _return_tween: Tween

func _ready() -> void:
	for child in get_parent().get_children():
		if child is CanvasLayer:
			screen_layers.append(child)
			_base_offsets.append(child.offset)
	if screen_layers.is_empty():
		push_error("CameraEffects could not find battle screen layers.")
		return

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
	if screen_layers.is_empty():
		return

	_effect_token += 1
	var token := _effect_token
	_reset_to_base()

	var shakes := 3 if _is_full() else 2
	for _i in range(shakes):
		if token != _effect_token:
			return
		_set_screen_offset(Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount)))
		await get_tree().create_timer(duration / float(shakes * 2)).timeout
		_set_screen_offset(Vector2.ZERO)
		await get_tree().create_timer(duration / float(shakes * 2)).timeout

	if token == _effect_token:
		_reset_to_base(duration * 0.62)

func _reset_to_base(duration := 0.0) -> void:
	if screen_layers.is_empty():
		return
	if _return_tween and _return_tween.is_valid():
		_return_tween.kill()
	if duration <= 0.0:
		_set_screen_offset(Vector2.ZERO)
		return
	_return_tween = create_tween()
	_return_tween.set_parallel()
	for index in screen_layers.size():
		_return_tween.tween_property(screen_layers[index], "offset", _base_offsets[index], duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _set_screen_offset(shake_offset: Vector2) -> void:
	for index in screen_layers.size():
		screen_layers[index].offset = _base_offsets[index] + shake_offset

func _is_full() -> bool:
	return SettingsManager.data.camera_effects_mode == SettingsData.CameraEffectsMode.FULL

func _is_off() -> bool:
	return SettingsManager.data.camera_effects_mode == SettingsData.CameraEffectsMode.OFF

func _shake_amount() -> float:
	return FULL_SHAKE if _is_full() else REDUCED_SHAKE
