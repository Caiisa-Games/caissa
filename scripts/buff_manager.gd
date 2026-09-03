extends Node

var active_buffs: Array[int] = []
var shown_popups: Array[int] = []

var player_hp_bonus: int = 0
var player_atk_flat_bonus: int = 0
var enemy_atk_debuff: float = 0.0
var enemy_morale_debuff: float = 0.0
var extra_pieces_limit: int = 0

func has_shown_popup(stage: int) -> bool:
	return stage in shown_popups

func mark_popup_shown(stage: int) -> void:
	if not stage in shown_popups:
		shown_popups.append(stage)

func apply_stage_buff(stage: int, choice: int) -> void:
	if GameState.game_mode != GameState.GameMode.SINGLEPLAYER:
		return
		
	if has_shown_popup(stage):
		return

	match stage:
		5:
			if choice == 1:
				enemy_atk_debuff += 0.10
			elif choice == 2:
				player_hp_bonus += 10
		10:
			if choice == 1:
				player_atk_flat_bonus += 3
			elif choice == 2:
				enemy_atk_debuff += 0.10
		15:
			if choice == 1:
				enemy_atk_debuff += 0.15
			elif choice == 2:
				player_hp_bonus += 15

	mark_popup_shown(stage)

func get_calculated_hp(piece_data: PieceData, player_owner: int) -> int:
	if not piece_data: return 0
	var base_hp = piece_data.defense
	if GameState.game_mode == GameState.GameMode.SINGLEPLAYER and player_owner == 1:
		return base_hp + player_hp_bonus
	return base_hp

func get_calculated_atk(piece_data: PieceData, player_owner: int) -> int:
	if not piece_data: return 0
	var base_atk = piece_data.power
	
	if GameState.game_mode == GameState.GameMode.SINGLEPLAYER:
		if player_owner == 1:
			return int(float(base_atk) + float(player_atk_flat_bonus))
		elif player_owner == 2:
			return max(1, int(float(base_atk) * (1.0 - enemy_atk_debuff)))
			
	return base_atk

func reset_buffs() -> void:
	shown_popups.clear()
	player_hp_bonus = 0
	player_atk_flat_bonus = 0
	enemy_atk_debuff = 0.0
	enemy_morale_debuff = 0.0
	extra_pieces_limit = 0
