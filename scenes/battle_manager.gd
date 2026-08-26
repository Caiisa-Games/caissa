class_name BattleManager
extends Node2D

enum Phase { SELECT, MOVE, ABILITY }
enum Turn { PLAYER_1, PLAYER_2 }

@export var mini_queen_data: PieceData

@onready var ui_layer: CanvasLayer = $UI
@onready var board_layer: CanvasLayer = $BoardLayer
@onready var game_over_layer: CanvasLayer = $GameOverLayer
@onready var board: BoardManager = $BoardLayer/Board
@onready var round_label: Label = $UI/TopBar/RoundLabel

@onready var top_bar: Panel = $UI/TopBar
@onready var bottom_panel: Panel = $UI/BottomPanel
@onready var end_turn_btn: Button = $UI/TopBar/EndTurnButton
@onready var top_menu_btn: Button = $UI/TopBar/MenuButton

@onready var player_1_energybar: ProgressBar = $UI/BottomPanel/P1Box/EnergyBar
@onready var player_2_energybar: ProgressBar = $UI/BottomPanel/P2Box/EnergyBar
@onready var player_1_ability_btn: Button = $UI/BottomPanel/P1Box/AbilityBtn
@onready var player_2_ability_btn: Button = $UI/BottomPanel/P2Box/AbilityBtn

@onready var round_label_gm: Label = $GameOverLayer/Control/VBoxContainer/RoundLabel
@onready var winner_label: Label = $GameOverLayer/Control/VBoxContainer/WinnerLabel
@onready var replay_button: Button = $GameOverLayer/Control/Buttons/ReplayButton
@onready var gm_menu_button: Button = $GameOverLayer/Control/Buttons/MenuButton

@onready var bg_background: CanvasItem = $UI/Background
@onready var bg_clouds: CanvasItem = $UI/Clouds

const MAX_ENERGY := 10
const STARTING_ENERGY := 5
const END_TURN_ENERGY_COST := 2
const ENERGY_REWARD_ATTACK := 1
const ENERGY_REWARD_KILL := 2

var player_energy := { Turn.PLAYER_1: STARTING_ENERGY, Turn.PLAYER_2: STARTING_ENERGY }
signal energy_changed(player: Turn, current: int, max: int)

var player_1_pieces: Dictionary = {}
var player_2_pieces: Dictionary = {}
var current_turn: Turn = Turn.PLAYER_1
var current_phase: Phase = Phase.SELECT
var selected_piece: Tile = null
var valid_moves: Array[Tile] = []
var valid_ability_targets: Array[Tile] = []
var round_number: int = 1
var winner: int = 0

var current_wave: int = 0
@export var stage: StageData
@export var stages: Array[StageData]
var enemy_ai: EnemyAI
var turn_locked := false

var extra_turn_pending := false
var ability_feedback_token := 0
var ability_failure_message := ""

func _ready() -> void:
	if _is_singleplayer():
		if GameState.current_stage <= 0:
			GameState.set_current_stage(1)

		var idx = GameState.current_stage - 1
		if idx >= 0 and idx < stages.size():
			stage = stages[idx]
			
		enemy_ai = EnemyAI.new()
		add_child(enemy_ai)

	
	_prepare_scene()
	_start_intro_sequence()

func _prepare_scene() -> void:
	if ui_layer: ui_layer.show()
	if board_layer: board_layer.hide()
	if game_over_layer: game_over_layer.hide()

func _start_intro_sequence() -> void:
	if board_layer: board_layer.show()
	_initialize_game_logic()

func _is_singleplayer() -> bool:
	return GameState.game_mode == GameState.GameMode.SINGLEPLAYER

func _is_game_active() -> bool:
	return winner == 0 and not turn_locked

func start_stage() -> void:
	current_wave = 0
	if stage and stage.waves.size() > 0:
		spawn_wave(current_wave)

func start_multiplayer() -> void:
	pass

func spawn_wave(index: int) -> void:
	if not board or not stage or index >= stage.waves.size():
		return

	var available_columns: Array[int] = []
	for x in range(board.GRID_SIZE):
		available_columns.append(x)
	available_columns.shuffle()

	var zombies_list = stage.waves[index].zombies
	for i in range(min(zombies_list.size(), available_columns.size())):
		var col = available_columns[i]
		var spawn_pos = Vector2i(col, 0)
		var z = zombies_list[i]

		if board.place_piece(z, spawn_pos.x, spawn_pos.y, 2):
			player_2_pieces[spawn_pos] = z

func _initialize_game_logic() -> void:
	if ui_layer: ui_layer.show()
	if board_layer: board_layer.show()

	AudioManager.play_music(preload("res://assets/sound/music_game.ogg"))

	player_1_pieces = GameState.player_1_pieces.duplicate()
	player_2_pieces = GameState.player_2_pieces.duplicate()

	_setup_board()

	if _is_singleplayer():
		start_stage()
	else:
		start_multiplayer()

	_connect_board_signals()
	_update_ui()

func _setup_board() -> void:
	if not board: return
	board.board_data = GameState.board
	board.battle_manager = self
	if not board.board_data:
		return
	board.generate()
	board.set_mode(BoardManager.Mode.BATTLE)

	for pos in player_1_pieces:
		board.place_piece(player_1_pieces[pos], pos.x, pos.y, 1)
	for pos in player_2_pieces:
		board.place_piece(player_2_pieces[pos], pos.x, pos.y, 2)

func _connect_board_signals() -> void:
	if not board: return
	for tile in board.tiles.values():
		tile.tile_clicked.connect(_on_tile_clicked)

func _on_tile_clicked(grid_pos: Vector2i) -> void:
	if not _is_game_active() or not board:
		return

	var tile: Tile = board.get_tile_at(grid_pos)
	if tile == null:
		return

	var p_idx := 1 if current_turn == Turn.PLAYER_1 else 2

	match current_phase:
		Phase.SELECT:
			_handle_selection(tile, p_idx)
		Phase.MOVE:
			_handle_move(tile)
		Phase.ABILITY:
			_handle_ability_target(tile)

func _handle_selection(tile: Tile, p_idx: int) -> void:
	if not tile.occupant.piece_data or tile.occupant.player != p_idx:
		_clear_selection()
		return
	if tile.occupant.has_status("stunned"):
		_clear_selection()
		_show_ability_feedback("This piece is stunned.")
		return

	AudioManager.play_sfx(preload("res://assets/sound/سلکت کردن مهره برای قبل از حرکت.mp3"))
	selected_piece = tile
	tile.occupant.set_selected(true)
	current_phase = Phase.MOVE
	_update_valid_moves()
	_update_ui()
	board.highlight_tile(tile, Tile.HighlightColor.SELF)

func _handle_move(tile: Tile) -> void:
	if not _is_game_active():
		return

	if selected_piece == null or selected_piece.occupant == null or selected_piece.occupant.piece_data == null:
		return

	turn_locked = true
	var p_idx = 1 if current_turn == Turn.PLAYER_1 else 2

	if tile in valid_moves:
		board.clear_all_highlights()

		if tile.occupant.piece_data and tile.occupant.player != p_idx:
			await _handle_attack(tile)
		else:
			AudioManager.play_sfx(preload("res://assets/sound/فرود اومدن مهره بعد از حرکت.mp3"))
			_execute_dictionary_move(selected_piece, tile)
			board._move_occupant(selected_piece, tile)
			await _check_promotion(tile)
			_end_turn()
			turn_locked = false
	else:
		_clear_selection()
		turn_locked = false

func _handle_attack(tile: Tile) -> void:
	if selected_piece == null or selected_piece.occupant == null or selected_piece.occupant.piece_data == null:
		return

	var attacker_tile = selected_piece
	var target_occupant = tile.occupant

	var attacker_power = attacker_tile.occupant.piece_data.power
	var base_damage = CombatRules.calculate_damage(
		attacker_power,
		attacker_tile.height_level - tile.height_level,
		false
	)

	var died = await CombatRules.apply_combat_damage(
		attacker_tile.occupant, 
		target_occupant, 
		base_damage, 
		board, 
		self
	)
	
	AudioManager.play_sfx(preload("res://assets/sound/دمیج دادن به مهره ی مقابل.mp3"))

	gain_energy(current_turn, ENERGY_REWARD_ATTACK)

	if died:
		_handle_died(tile)
		if winner == 0:
			_execute_dictionary_move(attacker_tile, tile)
			board._move_occupant(attacker_tile, tile)
			gain_energy(current_turn, ENERGY_REWARD_KILL)
			await _check_promotion(tile)
	else:
		await _apply_knockback(attacker_tile, tile)

	if winner != 0:
		GameState.winner = winner
		_handle_game_over()
	else:
		_end_turn()

func _apply_knockback(attacker_tile: Tile, target_tile: Tile) -> void:
	var knock_power = attacker_tile.occupant.piece_data.knockback
	if knock_power <= 0:
		return

	var diff = target_tile.grid_position - attacker_tile.grid_position
	var dir = Vector2i(sign(diff.x), sign(diff.y))
	var end_pos = target_tile.grid_position

	for i in range(knock_power):
		var next = end_pos + dir
		if not board.is_within_bounds(next.x, next.y) or board.get_tile_at(next).occupant.piece_data:
			break
		end_pos = next

	if end_pos != target_tile.grid_position:
		var end_tile = board.get_tile_at(end_pos)
		_execute_dictionary_move(target_tile, end_tile)
		board._move_occupant(target_tile, end_tile)
		_execute_dictionary_move(attacker_tile, target_tile)
		board._move_occupant(attacker_tile, target_tile)
		await _check_promotion(target_tile)

func _execute_dictionary_move(from: Tile, to: Tile) -> void:
	if from == null or to == null or from.occupant == null or from.occupant.piece_data == null:
		return
	var dict := player_1_pieces if from.occupant.player == 1 else player_2_pieces
	if not dict.has(from.grid_position):
		return
	var piece = dict[from.grid_position]
	dict.erase(from.grid_position)
	dict[to.grid_position] = piece

func _check_promotion(tile: Tile) -> void:
	var occupant = tile.occupant
	if occupant == null or occupant.piece_data == null or mini_queen_data == null:
		return

	var piece_name = occupant.piece_data.name.to_lower() if occupant.piece_data.name else ""
	var is_pawn = piece_name.contains("pawn") or piece_name.contains("soldier") or piece_name.contains("سرباز")
	if not is_pawn:
		return

	var player = occupant.player
	var y_pos = tile.grid_position.y

	var should_promote = (player == 1 and y_pos == 0) or (player == 2 and y_pos == board.GRID_SIZE - 1)
	if not should_promote:
		return

	occupant.piece_data = mini_queen_data
	if player == 1:
		player_1_pieces[tile.grid_position] = mini_queen_data
	else:
		player_2_pieces[tile.grid_position] = mini_queen_data

	if occupant.has_method("promote_to"):
		await occupant.promote_to(mini_queen_data)

func _handle_died(target_tile: Tile) -> void:
	var target = target_tile.occupant
	var dict = player_1_pieces if target.player == 1 else player_2_pieces
	dict.erase(target_tile.grid_position)
	target.clear_data()

	if _is_singleplayer():
		if player_1_pieces.is_empty():
			winner = 2
			GameState.winner = winner
			_handle_game_over()
			return

		var any_enemy_alive := board.tiles.values().any(
			func(t): return t.occupant.piece_data != null and t.occupant.player == 2
		)

		if not any_enemy_alive:
			current_wave += 1
			if stage and current_wave < stage.waves.size():
				await get_tree().create_timer(1.0).timeout
				spawn_wave(current_wave)
			else:
				winner = 1
				GameState.winner = winner
				GameState.unlock_next_stage()
				_handle_game_over()
		return

	if player_1_pieces.is_empty():
		winner = 2
		GameState.winner = winner
		_handle_game_over()
	elif player_2_pieces.is_empty():
		winner = 1
		GameState.winner = winner
		_handle_game_over()
		
func _trigger_ability_mode(turn: Turn) -> void:
	if turn_locked or current_turn != turn or selected_piece == null or selected_piece.occupant == null:
		return
		
	var occupant = selected_piece.occupant
	var piece_data = occupant.piece_data
	if not piece_data or not piece_data.active_ability:
		return

	var ability: AbilityResource = piece_data.active_ability

	if player_energy[turn] < ability.energy_cost:
		_show_ability_feedback(tr("not_enough_energy") % [ability.energy_cost, player_energy[turn]])
		return

	valid_ability_targets = _get_valid_ability_targets(selected_piece, ability)
	if valid_ability_targets.is_empty():
		_show_ability_feedback(tr("no_ability_targets"))
		return

	if ability.target_type == AbilityResource.TargetType.SELF \
	or ability.target_type == AbilityResource.TargetType.AOE_RADIUS \
	or ability.target_type == AbilityResource.TargetType.AOE_CROSS:
		_execute_ability_on_target(selected_piece)
	else:
		current_phase = Phase.ABILITY
		_highlight_ability_targets()


func _get_valid_ability_targets(caster_tile: Tile, ability: AbilityResource) -> Array[Tile]:
	var targets: Array[Tile] = []
	var caster_pos := caster_tile.grid_position
	var caster_player := caster_tile.occupant.player

	match ability.target_type:
		AbilityResource.TargetType.SELF, AbilityResource.TargetType.AOE_RADIUS, AbilityResource.TargetType.AOE_CROSS:
			targets.append(caster_tile)

		AbilityResource.TargetType.SINGLE_ENEMY:
			if ability.id == "swarm":
				var forward := Vector2i(0, -1 if caster_player == 1 else 1)
				var forward_tile := board.get_tile_at(caster_pos + forward)
				if forward_tile and forward_tile.occupant.piece_data \
				and forward_tile.occupant.player != caster_player:
					targets.append(forward_tile)
				return targets

			for t in board.tiles.values():
				if t.occupant.piece_data and t.occupant.player != caster_player:
					if ability.range <= 0:
						targets.append(t)
					else:
						var dist = abs(t.grid_position.x - caster_pos.x) + abs(t.grid_position.y - caster_pos.y)
						if dist <= ability.range:
							targets.append(t)

		AbilityResource.TargetType.SINGLE_ALLY:
			for t in board.tiles.values():
				if t.occupant.piece_data and t.occupant.player == caster_player:
					if ability.range <= 0:
						targets.append(t)
					else:
						var dist = abs(t.grid_position.x - caster_pos.x) + abs(t.grid_position.y - caster_pos.y)
						if dist <= ability.range:
							targets.append(t)

	return targets


func _execute_ability_on_target(target_tile: Tile) -> void:
	if not _is_valid_ability_target(target_tile):
		return

	var occupant = selected_piece.occupant
	var ability: AbilityResource = occupant.piece_data.active_ability
	turn_locked = true
	ability_failure_message = ""

	var success = await occupant.execute_active_ability(target_tile, board)

	var feedback_message := ""
	if success:
		spend_energy(current_turn, ability.energy_cost)
		AudioManager.play_sfx(preload("res://assets/sound/سلکت کردن مهره برای قبل از حرکت.mp3"))
		_cancel_ability_targeting()
		await _end_turn()
	else:
		feedback_message = ability_failure_message if not ability_failure_message.is_empty() else "Ability could not be used."
		_cancel_ability_targeting()

	turn_locked = false
	if not feedback_message.is_empty():
		_show_ability_feedback(feedback_message)


func _cancel_ability_targeting() -> void:
	valid_ability_targets.clear()
	if selected_piece and selected_piece.occupant and selected_piece.occupant.piece_data:
		current_phase = Phase.MOVE
		_update_valid_moves()
	else:
		_clear_selection()

func _highlight_ability_targets() -> void:
	board.clear_all_highlights()
	for tile in valid_ability_targets:
		if tile.occupant.piece_data and tile.occupant.player != selected_piece.occupant.player:
			tile.set_highlight_color(Tile.HighlightColor.ATTACK)
		else:
			tile.set_highlight_color(Tile.HighlightColor.SELF)


func _handle_ability_target(tile: Tile) -> void:
	if _is_valid_ability_target(tile):
		_execute_ability_on_target(tile)
	else:
		_show_ability_feedback(tr("no_ability_targets"))


func _is_valid_ability_target(tile: Tile) -> bool:
	if tile == null or selected_piece == null or selected_piece.occupant == null:
		return false
	if selected_piece.occupant.piece_data == null or not tile in valid_ability_targets:
		return false

	var ability: AbilityResource = selected_piece.occupant.piece_data.active_ability
	if ability == null:
		return false

	match ability.target_type:
		AbilityResource.TargetType.SINGLE_ENEMY:
			return tile.occupant != null and tile.occupant.piece_data != null \
				and tile.occupant.player != selected_piece.occupant.player
		AbilityResource.TargetType.SINGLE_ALLY:
			return tile.occupant != null and tile.occupant.piece_data != null \
				and tile.occupant.player == selected_piece.occupant.player
		_:
			return tile == selected_piece

func get_valid_moves_for_tile(from_tile: Tile) -> Array[Tile]:
	var moves: Array[Tile] = []
	if not from_tile or not from_tile.occupant or not from_tile.occupant.piece_data:
		return moves

	var piece = from_tile.occupant.piece_data
	var move_data = piece.movement if piece.movement else board.default_movement
	var passive = piece.passive_ability.create_effect_instance() if piece.passive_ability else null
	var can_jump_over := false
	if passive:
		can_jump_over = passive.allows_jump_over()
	var dirs: Array = []

	match move_data.movement_type:
		MovementData.MovementType.ORTHOGONAL:
			dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		MovementData.MovementType.DIAGONAL:
			dirs = [Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(1,1)]
		MovementData.MovementType.BOTH:
			dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
					Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(1,1)]

	for d in dirs:
		for r in range(1, move_data.move_range + 1):
			var tp = from_tile.grid_position + (d * r)
			if not board.is_within_bounds(tp.x, tp.y):
				break
			var target = board.get_tile_at(tp)
			if target.occupant.piece_data:
				if target.occupant.player != from_tile.occupant.player:
					moves.append(target)
				if not can_jump_over:
					break
				else:
					continue
			moves.append(target)

	return moves

func _update_valid_moves() -> void:
	valid_moves.clear()
	if board: board.clear_all_highlights()
	if not selected_piece:
		return

	valid_moves = get_valid_moves_for_tile(selected_piece)

	for target in valid_moves:
		if target.occupant.piece_data and target.occupant.player != selected_piece.occupant.player:
			target.set_highlight_color(Tile.HighlightColor.ATTACK)
		else:
			target.set_highlight_color(Tile.HighlightColor.MOVE)

func _end_turn() -> void:
	if winner != 0:
		return
	_clear_selection()
	for tile in board.tiles.values():
		if tile.occupant and tile.occupant.player == current_turn:
			tile.occupant.tick_statuses()
			
	if extra_turn_pending:
		extra_turn_pending = false
		_update_ui()
		return
	
	if _is_singleplayer():
		current_turn = Turn.PLAYER_2
		await enemy_ai.take_turn(board)
		current_turn = Turn.PLAYER_1
		round_number += 1
	else:
		if current_turn == Turn.PLAYER_1:
			current_turn = Turn.PLAYER_2
		else:
			current_turn = Turn.PLAYER_1
			round_number += 1
	
	_update_ui()

func _clear_selection() -> void:
	if selected_piece and selected_piece.occupant:
		selected_piece.occupant.set_selected(false)

	selected_piece = null
	current_phase = Phase.SELECT
	valid_moves.clear()
	if board: board.clear_all_highlights()
	turn_locked = false
	_update_ui()

func _update_ui() -> void:
	var p_idx = 1 if current_turn == Turn.PLAYER_1 else 2

	if player_1_energybar: player_1_energybar.value = player_energy[Turn.PLAYER_1] * 10
	if player_2_energybar: player_2_energybar.value = player_energy[Turn.PLAYER_2] * 10
	
	_update_ability_button(player_1_ability_btn, Turn.PLAYER_1)
	_update_ability_button(player_2_ability_btn, Turn.PLAYER_2)

	if _is_singleplayer():
		if end_turn_btn: end_turn_btn.visible = false
	else:
		if end_turn_btn:
			end_turn_btn.visible = true
			end_turn_btn.disabled = player_energy[current_turn] < END_TURN_ENERGY_COST

	if board:
		for t in board.tiles.values():
			if t.occupant.piece_data:
				if t.occupant.player == p_idx:
					t.occupant.show_orb()
				else:
					t.occupant.hide_orb()

	if round_label: round_label.text = tr("current_round") % round_number

func _update_ability_button(button: Button, turn: Turn) -> void:
	if not button:
		return

	var can_act := current_turn == turn and selected_piece != null and selected_piece.occupant != null
	var ability: AbilityResource = null
	if can_act and selected_piece.occupant.piece_data:
		ability = selected_piece.occupant.piece_data.active_ability

	if ability == null:
		button.disabled = true
		button.tooltip_text = tr("select_piece_for_ability")
		return

	button.disabled = player_energy[turn] < ability.energy_cost
	button.tooltip_text = _get_ability_tooltip(ability)
	if button.disabled:
		button.tooltip_text = tr("not_enough_energy") % [ability.energy_cost, player_energy[turn]]

func _get_ability_tooltip(ability: AbilityResource) -> String:
	var target_text := "Self"
	match ability.target_type:
		AbilityResource.TargetType.SINGLE_ENEMY:
			target_text = "Enemy"
		AbilityResource.TargetType.SINGLE_ALLY:
			target_text = "Ally"
		AbilityResource.TargetType.AOE_CROSS:
			target_text = "Cross area"
		AbilityResource.TargetType.AOE_RADIUS:
			target_text = "Radius area"

	var range_text := "Unlimited" if ability.range <= 0 else "Range %d" % ability.range
	var details := ability.description.strip_edges()
	if details.is_empty():
		details = "No description available."
	return "%s\n%s\n%d energy · %s · %s" % [ability.name, details, ability.energy_cost, target_text, range_text]

func _show_ability_feedback(message: String) -> void:
	if round_label:
		round_label.text = message
	ability_feedback_token += 1
	_restore_round_label_after_feedback(ability_feedback_token)
	push_warning(message)

func report_ability_failure(message: String) -> void:
	ability_failure_message = message

func _restore_round_label_after_feedback(token: int) -> void:
	await get_tree().create_timer(1.8).timeout
	if token == ability_feedback_token and winner == 0:
		_update_ui()

func gain_energy(player: Turn, amount: int) -> void:
	player_energy[player] = clamp(player_energy[player] + amount, 0, MAX_ENERGY)
	energy_changed.emit(player, player_energy[player], MAX_ENERGY)
	_update_ui()

func spend_energy(player: Turn, amount: int) -> bool:
	if player_energy[player] < amount:
		return false
	player_energy[player] -= amount
	energy_changed.emit(player, player_energy[player], MAX_ENERGY)
	_update_ui()
	return true

func _on_end_turn_button_pressed() -> void:
	if not _is_singleplayer() and not turn_locked:
		if player_energy[current_turn] >= END_TURN_ENERGY_COST:
			player_energy[current_turn] -= END_TURN_ENERGY_COST
			_end_turn()

func _on_menu_button_pressed() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _handle_game_over() -> void:
	if game_over_layer: game_over_layer.show()
	if top_bar: top_bar.hide()
	if bottom_panel: bottom_panel.hide()

	var is_win = winner == 1

	if is_win:
		AudioManager.play_sfx(preload("res://assets/sound/صفحه ی ویکتوری و برد.mp3"))
		if winner_label: winner_label.text = tr("win")

		if _is_singleplayer() and replay_button:
			replay_button.text = tr("next_stage")
	else:
		if winner_label: winner_label.text = tr("lose")
		if replay_button: replay_button.text = tr("replay")

	if round_label_gm: round_label_gm.text = tr("current_round") % round_number

func _on_replay_button_pressed() -> void:
	if not _is_singleplayer():
		get_tree().change_scene_to_file("res://scenes/piece_selection.tscn")
		return

	if winner != 1:
		get_tree().reload_current_scene()
		return

	GameState.set_current_stage(GameState.current_stage + 1)

	if GameState.current_stage > stages.size():
		get_tree().change_scene_to_file("res://scenes/singleplayer/stage_selection.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/battle.tscn")

func handle_ability_kill(tile: Tile) -> void:
	if tile == null or tile.occupant == null or tile.occupant.piece_data == null:
		return

	gain_energy(current_turn, ENERGY_REWARD_KILL)
	_handle_died(tile)

	if winner != 0:
		GameState.winner = winner
		_handle_game_over()

func grant_extra_turn() -> void:
	extra_turn_pending = true

func _on_p1_ability_pressed() -> void:
	if turn_locked or current_turn != Turn.PLAYER_1:
		return
	_trigger_ability_mode(Turn.PLAYER_1)

func _on_p2_ability_pressed() -> void:
	if turn_locked or current_turn != Turn.PLAYER_2:
		return
	_trigger_ability_mode(Turn.PLAYER_2)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo() or winner != 0:
		return

	if event.keycode == KEY_ESCAPE and current_phase != Phase.SELECT:
		_clear_selection()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_E:
		_trigger_ability_mode(current_turn)
		get_viewport().set_input_as_handled()
