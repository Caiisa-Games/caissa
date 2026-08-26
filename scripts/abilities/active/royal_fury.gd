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

	var base_power: int = caster.occupant.piece_data.power
	var missing_hp: int = max(0, target_unit.max_hp - target_unit.current_hp)
	var execute_bonus: int = int(missing_hp * 0.20)
	var height_diff: int = caster.height_level - target_tile.height_level
	var height_bonus: int = max(0, height_diff * 2)

	var total_damage: int = base_power + execute_bonus + height_bonus

	var died = await CombatRules.apply_combat_damage(
		caster.occupant,
		target_unit,
		total_damage, 
		board, 
		board.battle_manager
	)
	
	if died:
		board.battle_manager.handle_ability_kill(target_tile)

	return true
