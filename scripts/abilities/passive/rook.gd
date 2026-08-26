extends PassiveEffect

func modify_incoming_damage(owner: Occupant, incoming: int, board: BoardManager) -> int:
	if owner.piece_data and owner.piece_data.name == "rook":
		return int(incoming * 0.85)
	return incoming
