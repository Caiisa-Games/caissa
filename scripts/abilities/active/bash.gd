extends AbilityEffect

func execute(caster: Tile, target_cell: Vector2i, board: BoardManager) -> bool:
	if not caster or not caster.occupant or not caster.occupant.piece_data:
		return false

	var target_tile = board.get_tile_at(target_cell)
	if not target_tile or not target_tile.occupant or not target_tile.occupant.piece_data:
		return false

	var target_unit = target_tile.occupant as Occupant
	if target_unit.player == caster.occupant.player:
		return false

	var direction: Vector2i = Vector2i(sign(target_cell.x - caster.grid_position.x), sign(target_cell.y - caster.grid_position.y))
	var landing_cell: Vector2i = target_cell + direction
	var landing_tile = board.get_tile_at(landing_cell)

	if landing_tile == null or not board.is_cell_empty(landing_cell):
		return false

	var ability := caster.occupant.piece_data.active_ability
	caster.occupant.play_aseprite_ability(ability)
	await caster.occupant.cast_impact_reached

	var base_power: int = caster.occupant.piece_data.power
	var total_damage: int = int(base_power * 1.5)
	var died = await CombatRules.apply_combat_damage(caster.occupant, target_unit, total_damage, board, board.battle_manager)

	if died:
		board.battle_manager.handle_ability_kill(target_tile)
	else:
		target_unit.apply_status("stunned", 1)

	board.battle_manager._execute_dictionary_move(caster, landing_tile)
	board._move_occupant(caster, landing_tile)

	return true
