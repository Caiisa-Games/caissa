class_name PassiveEffect
extends RefCounted

func modify_incoming_damage(owner: Occupant, incoming: int, board: BoardManager) -> int:
	return incoming

func modify_outgoing_damage(owner: Occupant, outgoing: int, target: Occupant, board: BoardManager) -> int:
	return outgoing

func on_damage_dealt(owner: Occupant, damage_dealt: int, target: Occupant, board: BoardManager) -> void:
	pass

func on_kill(owner: Occupant, board: BoardManager, battle_manager: BattleManager) -> void:
	pass

func allows_jump_over() -> bool:
	return false
