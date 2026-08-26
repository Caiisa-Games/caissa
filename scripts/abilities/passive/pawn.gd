extends PassiveEffect

func modify_outgoing_damage(owner: Occupant, outgoing: int, target: Occupant, board: BoardManager) -> int:
	if owner.piece_data and owner.piece_data.name == "pawn":
		if owner.max_hp > 0 and (float(owner.current_hp) / owner.max_hp) < 0.30:
			return int(outgoing * 1.20)
	return outgoing
