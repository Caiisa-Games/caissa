class_name EnemyAI
extends Node

const ACTION_DELAY := 0.18


func take_turn(board: BoardManager) -> void:
	var battle_manager: BattleManager = get_parent() as BattleManager
	if battle_manager == null:
		return

	await get_tree().create_timer(randf_range(0.2, 0.4)).timeout

	var enemies: Array[Tile] = []
	for tile in board.tiles.values():
		if tile.occupant and tile.occupant.piece_data and tile.occupant.player == 2:
			enemies.append(tile)

	enemies.sort_custom(func(a: Tile, b: Tile): return a.grid_position.y < b.grid_position.y or (a.grid_position.y == b.grid_position.y and a.grid_position.x < b.grid_position.x))

	for enemy in enemies:
		if battle_manager.winner != 0 or enemy.occupant.piece_data == null or enemy.occupant.player != 2:
			break
		if enemy.occupant.has_status("stunned"):
			continue

		var move_tile := _choose_move(board, battle_manager, enemy)
		if move_tile == null:
			continue

		await _perform_action(board, battle_manager, enemy, move_tile)
		if battle_manager.winner == 0:
			await get_tree().create_timer(ACTION_DELAY).timeout

func _choose_move(board: BoardManager, battle_manager: BattleManager, enemy: Tile) -> Tile:
	var best_move: Tile = null
	var best_attack := false
	var best_kill := false
	var best_target_hp := 999999
	var best_distance := 999999

	for move_tile in battle_manager.get_valid_moves_for_tile(enemy):
		var target := move_tile.occupant
		var is_attack := target and target.piece_data and target.player == 1

		if is_attack:
			var damage := CombatRules.calculate_damage(
				enemy.occupant.piece_data.power,
				enemy.height_level - move_tile.height_level,
				false
			)
			var is_kill := damage >= target.current_hp
			if not best_attack or (is_kill and not best_kill) or (is_kill == best_kill and target.current_hp < best_target_hp):
				best_move = move_tile
				best_attack = true
				best_kill = is_kill
				best_target_hp = target.current_hp
			continue

		if best_attack:
			continue
		var nearest_player := _find_nearest_player(board, move_tile)
		if nearest_player == null:
			continue
		var distance := _get_distance(move_tile, nearest_player)
		if distance < best_distance:
			best_move = move_tile
			best_distance = distance

	return best_move

func _perform_action(board: BoardManager, battle_manager: BattleManager, enemy: Tile, move_tile: Tile) -> void:
	var target := move_tile.occupant
	if target and target.piece_data and target.player == 1:
		var damage := CombatRules.calculate_damage(
			enemy.occupant.piece_data.power,
			enemy.height_level - move_tile.height_level,
			false
		)

		AudioManager.play_sfx(preload("res://assets/sound/دمیج دادن به مهره ی مقابل.mp3"))
		var died := await CombatRules.apply_combat_damage(
			enemy.occupant,
			target,
			damage,
			board,
			battle_manager
		)
		if died:
			battle_manager._handle_died(move_tile)
			if battle_manager.winner == 0:
				battle_manager._execute_dictionary_move(enemy, move_tile)
				board._move_occupant(enemy, move_tile)
				await battle_manager._check_promotion(move_tile)
		else:
			await battle_manager._apply_knockback(enemy, move_tile)
		return

	AudioManager.play_sfx(preload("res://assets/sound/فرود اومدن مهره بعد از حرکت.mp3"))
	battle_manager._execute_dictionary_move(enemy, move_tile)
	board._move_occupant(enemy, move_tile)
	await battle_manager._check_promotion(move_tile)


func _find_nearest_player(board: BoardManager, reference_tile: Tile) -> Tile:
	var nearest: Tile = null
	var best := 999999

	for tile in board.tiles.values():
		if tile.occupant and tile.occupant.piece_data and tile.occupant.player == 1:
			var distance := _get_distance(reference_tile, tile)
			if distance < best:
				best = distance
				nearest = tile

	return nearest


func _get_distance(first: Tile, second: Tile) -> int:
	return abs(first.grid_position.x - second.grid_position.x) + abs(first.grid_position.y - second.grid_position.y)
