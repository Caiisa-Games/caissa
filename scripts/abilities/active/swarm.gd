extends AbilityEffect

func execute(caster: Tile, target_cell: Vector2i, board: BoardManager) -> bool:
	if not caster or not caster.occupant or not caster.occupant.piece_data:
		return false

	var target_tile = board.get_tile_at(target_cell)
	if not target_tile or not target_tile.occupant or not target_tile.occupant.piece_data:
		return false
	if target_tile.occupant.player == caster.occupant.player:
		return false

	var forward := Vector2i(0, -1 if caster.occupant.player == 1 else 1)
	if target_cell != caster.grid_position + forward:
		return false

	var perpendicular := Vector2i(1, 0)
	var spawn_cells: Array[Vector2i] = [
		caster.grid_position + perpendicular,
		caster.grid_position - perpendicular,
	]
	var flank_cells: Array[Vector2i] = [
		target_cell + perpendicular,
		target_cell - perpendicular,
	]

	var invalid_spawns: Array[Tile] = []
	var has_invalid_spawn := false
	for cell in spawn_cells:
		var tile := board.get_tile_at(cell)
		if tile == null:
			has_invalid_spawn = true
			continue
		if tile.occupant and tile.occupant.piece_data:
			has_invalid_spawn = true
			invalid_spawns.append(tile)

	if has_invalid_spawn:
		await _flash_invalid_tiles(board, invalid_spawns)
		_report_failure(board, "Swarm needs both adjacent tiles clear.")
		return false

	var invalid_flanks: Array[Tile] = []
	var has_invalid_flank := false
	for cell in flank_cells:
		var tile := board.get_tile_at(cell)
		if tile == null:
			has_invalid_flank = true
		else:
			invalid_flanks.append(tile)

	if has_invalid_flank:
		await _flash_invalid_tiles(board, invalid_flanks)
		_report_failure(board, "Swarm needs room around its target.")
		return false

	var clones: Array[Sprite2D] = []
	for i in range(spawn_cells.size()):
		var spawn_tile := board.get_tile_at(spawn_cells[i])
		_spawn_smoke(board, spawn_tile, caster.occupant.player)
		clones.append(_create_clone(board, caster, spawn_tile))

	await board.get_tree().create_timer(0.12).timeout
	var dash := board.create_tween().set_parallel(true)
	for i in range(clones.size()):
		dash.tween_property(clones[i], "position", _tile_visual_position(board.get_tile_at(flank_cells[i])), 0.28) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await dash.finished

	var base_power: int = caster.occupant.piece_data.power
	var target_unit := target_tile.occupant as Occupant
	var target_died := await CombatRules.apply_combat_damage(
		caster.occupant, target_unit, base_power, board, board.battle_manager
	)
	if target_died:
		board.battle_manager.handle_ability_kill(target_tile)

	var attacker_tile := await _advance_caster_after_central_hit(
		caster, target_tile, forward, target_died, board
	)

	for cell in flank_cells:
		var tile = board.get_tile_at(cell)
		if tile == null or tile.occupant == null or tile.occupant.piece_data == null:
			continue
		var unit = tile.occupant as Occupant
		if unit.player == attacker_tile.occupant.player:
			continue

		var died = await CombatRules.apply_combat_damage(attacker_tile.occupant, unit, base_power, board, board.battle_manager)
		if died:
			board.battle_manager.handle_ability_kill(tile)

	for clone in clones:
		_dissolve_clone(clone)
	await board.get_tree().create_timer(0.22).timeout
	return true

func _advance_caster_after_central_hit(
	caster: Tile, target_tile: Tile, forward: Vector2i, target_died: bool, board: BoardManager
) -> Tile:
	var can_advance := target_died
	var knockback_tile := board.get_tile_at(target_tile.grid_position + forward)

	if not target_died:
		can_advance = knockback_tile != null and knockback_tile.occupant.piece_data == null
		if can_advance:
			board.battle_manager._execute_dictionary_move(target_tile, knockback_tile)
			board._move_occupant(target_tile, knockback_tile)

	if can_advance:
		board.battle_manager._execute_dictionary_move(caster, target_tile)
		board._move_occupant(caster, target_tile)
		await board.battle_manager._check_promotion(target_tile)
		return target_tile

	return caster

func _report_failure(board: BoardManager, message: String) -> void:
	if board.battle_manager:
		board.battle_manager.report_ability_failure(message)

func _flash_invalid_tiles(board: BoardManager, tiles: Array[Tile]) -> void:
	board.clear_all_highlights()
	for tile in tiles:
		if tile:
			tile.set_highlight_color(Tile.HighlightColor.ATTACK)
	await board.get_tree().create_timer(0.4).timeout

func _tile_visual_position(tile: Tile) -> Vector2:
	return tile.position + Vector2(0, -tile.height_level * 10.0 + 8.0)

func _create_clone(board: BoardManager, caster: Tile, spawn_tile: Tile) -> Sprite2D:
	var clone := Sprite2D.new()
	var source := caster.occupant.sprite
	clone.texture = source.texture
	clone.offset = source.offset
	clone.scale = source.scale
	clone.centered = source.centered
	clone.flip_h = source.flip_h
	clone.flip_v = source.flip_v
	clone.position = _tile_visual_position(spawn_tile)
	clone.modulate = Color(0.8, 0.9, 1.0, 0.88) if caster.occupant.player == 1 else Color(1.0, 0.82, 0.88, 0.88)
	clone.z_index = 4096
	board.add_child(clone)
	return clone

func _spawn_smoke(board: BoardManager, tile: Tile, player: int) -> void:
	var smoke := Polygon2D.new()
	smoke.polygon = PackedVector2Array([Vector2(-10, 0), Vector2(-5, -9), Vector2(5, -9), Vector2(10, 0), Vector2(5, 9), Vector2(-5, 9)])
	smoke.position = _tile_visual_position(tile)
	smoke.color = Color("8fd3ff") if player == 1 else Color("ff9bb5")
	smoke.modulate.a = 0.7
	smoke.z_index = 4095
	board.add_child(smoke)
	var tween := smoke.create_tween().set_parallel(true)
	tween.tween_property(smoke, "scale", Vector2(2.2, 2.2), 0.35)
	tween.tween_property(smoke, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(smoke.queue_free)

func _dissolve_clone(clone: Sprite2D) -> void:
	var tween := clone.create_tween().set_parallel(true)
	tween.tween_property(clone, "modulate:a", 0.0, 0.2)
	tween.tween_property(clone, "scale", clone.scale * 1.15, 0.2)
	tween.chain().tween_callback(clone.queue_free)
