extends PassiveEffect

func on_kill(owner: Occupant, board: BoardManager, battle_manager: BattleManager) -> void:
	if owner.piece_data and owner.piece_data.name == "queen":
		battle_manager.grant_extra_turn()
