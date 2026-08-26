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

	var perp := Vector2i(1, 0)
	var spawn_cells: Array[Vector2i] = [
		caster.grid_position + perp,
		caster.grid_position - perp,
	]
	var flank_cells: Array[Vector2i] = [
		target_cell + perp,
		target_cell - perp,
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

	var ability := caster.occupant.piece_data.active_ability
	var smoke_animations: Array[AnimatedSprite2D] = []
	for cell in spawn_cells:
		var spawn_tile := board.get_tile_at(cell)
		var smoke := _create_spawn_smoke(board, caster, spawn_tile, ability)
		if smoke:
			smoke_animations.append(smoke)
	if not smoke_animations.is_empty():
		await smoke_animations[0].animation_finished
		for smoke in smoke_animations:
			smoke.queue_free()

	var clones: Array[Sprite2D] = []
	for i in range(spawn_cells.size()):
		var spawn_tile := board.get_tile_at(spawn_cells[i])
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
	return tile.position

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

func _create_spawn_smoke(
	board: BoardManager, caster: Tile, spawn_tile: Tile, ability: AbilityResource
) -> AnimatedSprite2D:
	var frames := ability.anim_frames_white if caster.occupant.player == 1 else ability.anim_frames_black
	if frames == null:
		frames = ability.anim_frames_white if ability.anim_frames_white else ability.anim_frames_black
	if frames == null or not frames.has_animation("cast"):
		return null

	var smoke := AnimatedSprite2D.new()
	smoke.sprite_frames = frames
	smoke.position = _tile_visual_position(spawn_tile)
	smoke.scale = caster.occupant.ability_sprite.scale
	smoke.centered = false
	smoke.z_index = 4095
	var first_texture := frames.get_frame_texture("cast", 0)
	if first_texture:
		smoke.offset = Vector2(-first_texture.get_width() / 2.0, -first_texture.get_height())
	board.add_child(smoke)
	smoke.play("cast")
	return smoke

func _dissolve_clone(clone: Sprite2D) -> void:
	var tween := clone.create_tween().set_parallel(true)
	tween.tween_property(clone, "modulate:a", 0.0, 0.2)
	tween.tween_property(clone, "scale", clone.scale * 1.15, 0.2)
	tween.chain().tween_callback(clone.queue_free)
