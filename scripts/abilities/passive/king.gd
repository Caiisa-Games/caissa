extends PassiveEffect

func modify_incoming_damage(owner: Occupant, incoming: int, board: BoardManager) -> int:
	var owner_tile: Tile = owner.get_parent().get_parent() as Tile
	if not owner_tile:
		return incoming

	for tile in board.tiles.values():
		var unit = tile.occupant
		if unit and unit.piece_data and unit.piece_data.name == "king" and unit.player == owner.player:
			var dist = abs(tile.grid_position.x - owner_tile.grid_position.x) + abs(tile.grid_position.y - owner_tile.grid_position.y)
			if dist <= 2:
				return int(incoming * 0.85)

	return incoming
