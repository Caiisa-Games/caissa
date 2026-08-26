extends AbilityEffect

const CROSS_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, 0),
	#Vector2i.ZERO,
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(0, 2),
]

func execute(caster: Tile, _target_cell: Vector2i, board: BoardManager) -> bool:
	if not caster or not caster.occupant or not caster.occupant.piece_data:
		return false

	var center: Vector2i = caster.grid_position
	var caster_player: int = caster.occupant.player

	for offset in CROSS_OFFSETS:
		var target_pos: Vector2i = center + offset
		
		if not board.is_within_bounds(target_pos.x, target_pos.y):
			continue

		var tile: Tile = board.get_tile_at(target_pos)
		if tile == null:
			continue

		var ability = caster.occupant.piece_data.active_ability
		caster.occupant.play_aseprite_ability(ability)

		var unit: Occupant = tile.occupant
		if unit and unit.piece_data and unit.player == caster_player:
			var heal_amount: int = int(unit.max_hp * 0.35)
			unit.current_hp = min(unit.current_hp + heal_amount, unit.max_hp)
			unit._update_hp()
			unit.show_hp_label()

			_play_unit_heal_effect(unit)

	return true

#TEMP, ANIMATION ADDED LATER:
func _play_tile_divine_effect(tile: Tile) -> void:
	if tile.highlight_sprite == null:
		return

	tile.highlight_sprite.color = Color(0.2, 1.0, 0.4, 0.7)
	tile.highlight_sprite.visible = true
	tile.highlight_sprite.modulate.a = 1.0

	var tween := tile.create_tween()
	tween.tween_property(tile.highlight_sprite, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		tile.highlight_sprite.visible = false
		tile.highlight_sprite.modulate.a = 1.0
	)


func _play_unit_heal_effect(unit: Occupant) -> void:
	var tween := unit.create_tween()
	unit.modulate = Color(0.5, 2.5, 0.8)
	tween.tween_property(unit, "modulate", Color.WHITE, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
