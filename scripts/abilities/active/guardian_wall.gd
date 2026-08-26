extends AbilityEffect

func execute(caster: Tile, target_cell: Vector2i, board: BoardManager) -> bool:
	if not caster or not caster.occupant or not caster.occupant.piece_data:
		return false
	
	var ability = caster.occupant.piece_data.active_ability
	caster.occupant.play_aseprite_ability(ability)
	
	await caster.occupant.cast_impact_reached

	var target_tile = board.get_tile_at(target_cell)
	if not target_tile or not target_tile.occupant or not target_tile.occupant.piece_data:
		return false

	var target_unit = target_tile.occupant as Occupant
	if target_unit.player != caster.occupant.player:
		return false
	
	target_unit.apply_status("guarded", 2, {"percent": 0.35})
	return true
