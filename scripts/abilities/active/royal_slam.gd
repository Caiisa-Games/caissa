extends AbilityEffect

func execute(caster: Tile, _target_cell: Vector2i, board: BoardManager) -> bool:
	if not caster.occupant.piece_data:
		return false
	var center: Vector2i = caster.grid_position
	var ability = caster.occupant.piece_data.active_ability
	var adjacent_cells: Array[Vector2i] = board.get_surrounding_cells(center, 1)
	
	caster.occupant.play_aseprite_ability(ability)
	
	await caster.occupant.cast_impact_reached
	
	AudioManager.play_sfx(preload("res://assets/sound/دمیج دادن به مهره ی مقابل.mp3"))	

	for cell in adjacent_cells:
		var cell_tile = board.get_tile_at(cell)
		if cell_tile == null or cell_tile.occupant == null or cell_tile.occupant.piece_data == null:
			continue
		var unit = cell_tile.occupant as Occupant
		
		if unit.player != caster.occupant.player:
			var dmg = int(unit.current_hp * 0.10)
			var died = await CombatRules.apply_combat_damage(
				caster.occupant,
				unit,
				dmg, 
				board, 
				board.battle_manager
			)
			
			if died:
				board.battle_manager.handle_ability_kill(cell_tile)
				continue

			var dir: Vector2i = cell - center
			var push_target: Vector2i = cell + dir
			if not board.get_tile_at(push_target):
				continue
				
			if board.is_cell_empty(push_target):
				var push_tile := board.get_tile_at(push_target)
				board.battle_manager._execute_dictionary_move(cell_tile, push_tile)
				board._move_occupant(cell_tile, push_tile)
			else:
				var blocking_unit = board.get_tile_at(push_target).occupant as Occupant
				if blocking_unit and blocking_unit.piece_data:
					var blocker_died = await CombatRules.apply_combat_damage(
						caster.occupant,
						blocking_unit,
						caster.occupant.piece_data.power, 
						board, 
						board.battle_manager
					)
					if blocker_died:
						board.battle_manager.handle_ability_kill(board.get_tile_at(push_target))
						
				var unit_died_from_collision = await CombatRules.apply_combat_damage(
					caster.occupant,
					unit,
					caster.occupant.piece_data.power, 
					board, 
					board.battle_manager
				)
				if unit_died_from_collision:
					board.battle_manager.handle_ability_kill(cell_tile)
				
	return true
