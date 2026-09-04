class_name EnemyAI
extends Node

func take_turn(board: BoardManager) -> void:
	print("--- Enemy Turn Started ---")

	var random_delay = randf_range(0.2, 0.4)
	await get_tree().create_timer(random_delay).timeout

	var battle_manager: BattleManager = get_parent() as BattleManager
	if not battle_manager:
		print("--- Enemy Turn Finished (No BattleManager) ---")
		return

	var enemies: Array[Tile] = []

	for tile in board.tiles.values():
		if tile.occupant and tile.occupant.piece_data and tile.occupant.player == 2 and not tile.occupant.has_status("stunned"):
			enemies.append(tile)

	if enemies.is_empty():
		print("--- Enemy Turn Finished (No Enemies Left) ---")
		return

	var best_enemy: Tile = null
	var best_move_tile: Tile = null
	var min_distance := 999999
	var attack_found := false

	for enemy in enemies:
		var moves = battle_manager.get_valid_moves_for_tile(enemy)
		
		for move_tile in moves:
			var is_attack = (move_tile.occupant.piece_data != null and move_tile.occupant.player == 1)
			
			var nearest_player = _find_nearest_player(board, move_tile)
			if not nearest_player:
				continue

			var dist = abs(move_tile.grid_position.x - nearest_player.grid_position.x) \
				+ abs(move_tile.grid_position.y - nearest_player.grid_position.y)

			if is_attack:
				if not attack_found or dist < min_distance:
					attack_found = true
					min_distance = dist
					best_enemy = enemy
					best_move_tile = move_tile
			elif not attack_found:
				if dist < min_distance:
					min_distance = dist
					best_enemy = enemy
					best_move_tile = move_tile

	if best_enemy == null or best_move_tile == null:
		for enemy in enemies:
			var moves = battle_manager.get_valid_moves_for_tile(enemy)
			if not moves.is_empty():
				best_enemy = enemy
				best_move_tile = moves[0]
				break

	if best_enemy == null or best_move_tile == null:
		print("--- Enemy Turn Finished (No Valid Move At All) ---")
		await get_tree().create_timer(0.3).timeout
		return

	var target_occupant = best_move_tile.occupant
	
	if target_occupant.piece_data and target_occupant.player == 1:
		var damage = CombatRules.calculate_damage(
			best_enemy.occupant.piece_data.power,
			best_enemy.height_level - best_move_tile.height_level,
			false
		)
		
		AudioManager.play_sfx(preload("res://assets/sound/دمیج دادن به مهره ی مقابل.mp3"))
		var attacked_tile = best_move_tile
		
		var died = await CombatRules.apply_combat_damage(
			best_enemy.occupant, 
			target_occupant, 
			damage, 
			board, 
			board.battle_manager
		)
		if died:
			battle_manager._handle_died(attacked_tile)
			battle_manager._execute_dictionary_move(best_enemy, attacked_tile)
			board._move_occupant(best_enemy, attacked_tile)
			await battle_manager._check_promotion(attacked_tile)
		else:
			await battle_manager._apply_knockback(best_enemy, attacked_tile)

	else:
		AudioManager.play_sfx(preload("res://assets/sound/فرود اومدن مهره بعد از حرکت.mp3"))
		battle_manager._execute_dictionary_move(best_enemy, best_move_tile)
		board._move_occupant(best_enemy, best_move_tile)
		await battle_manager._check_promotion(best_move_tile)

	await get_tree().create_timer(0.3).timeout
	print("--- Enemy Turn Finished ---")


func _find_nearest_player(board: BoardManager, reference_tile: Tile) -> Tile:
	var nearest: Tile = null
	var best := 999999

	for tile in board.tiles.values():
		if tile.occupant and tile.occupant.piece_data and tile.occupant.player == 1:
			var d = abs(reference_tile.grid_position.x - tile.grid_position.x) \
				+ abs(reference_tile.grid_position.y - tile.grid_position.y)

			if d < best:
				best = d
				nearest = tile

	return nearest
