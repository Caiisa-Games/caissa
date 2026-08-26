extends PassiveEffect

func on_damage_dealt(owner: Occupant, damage_dealt: int, target: Occupant, board: BoardManager) -> void:
	if not owner.piece_data or owner.piece_data.name != "bishop":
		return

	var heal_amount = int(damage_dealt * 0.40)
	if heal_amount <= 0:
		return

	var lowest_ally: Occupant = null
	var lowest_pct := 1.1

	for tile in board.tiles.values():
		var unit = tile.occupant
		if unit and unit.piece_data and unit.player == owner.player and unit.max_hp > 0:
			var pct = float(unit.current_hp) / unit.max_hp
			if pct < lowest_pct:
				lowest_pct = pct
				lowest_ally = unit

	if lowest_ally:
		lowest_ally.current_hp = min(lowest_ally.current_hp + heal_amount, lowest_ally.max_hp)
		lowest_ally._update_hp()
		lowest_ally.show_hp_label()
