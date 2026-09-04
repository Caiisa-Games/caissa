class_name PieceSelection
extends Control

const SELECT_SFX := preload("res://assets/sound/سلکت کردن مهره برای قبل از حرکت.mp3")
const CONFIRM_SFX := preload("res://assets/sound/بعد از انتخاب همه ی کارت های یک پلیر.mp3")
const MOVE_SFX := preload("res://assets/sound/فرود اومدن مهره بعد از حرکت.mp3")

enum FlowStep { P1_SELECT, P2_SELECT, P1_PLACE, P2_PLACE }

@onready var selection_overlay: PanelContainer = $UICanvas/MainUI/SelectionOverlay
@onready var selection_grid: GridContainer = $UICanvas/MainUI/SelectionOverlay/HBoxContainer/GridArea/SelectionGrid
@onready var confirm_selection_btn: Button = $UICanvas/MainUI/SelectionOverlay/HBoxContainer/Sidebar/Margin/VBoxContainer/ConfirmBtn
@onready var draft_back_btn: Button = $UICanvas/MainUI/SelectionOverlay/HBoxContainer/Sidebar/Margin/VBoxContainer/BackBtn

@onready var split_container: HSplitContainer = $UICanvas/MainUI/HSplitContainer

@onready var card_flow: HFlowContainer = $UICanvas/MainUI/HSplitContainer/LeftPanel/MarginContainer/VBoxContainer/ScrollContainer/CardFlow
@onready var confirm_placement_btn: Button = $UICanvas/MainUI/HSplitContainer/LeftPanel/MarginContainer/VBoxContainer/StartButton

@onready var board: BoardManager = $Board

@onready var draft_turn_label: Label = $UICanvas/MainUI/SelectionOverlay/HBoxContainer/Sidebar/Margin/VBoxContainer/DraftLabels/DraftTurnLabel
@onready var draft_count_label: Label = $UICanvas/MainUI/SelectionOverlay/HBoxContainer/Sidebar/Margin/VBoxContainer/DraftLabels/DraftCountLabel

@onready var placement_turn_label: Label = $UICanvas/MainUI/HSplitContainer/LeftPanel/MarginContainer/VBoxContainer/TopBar/PlayerTurnLabel
@onready var placement_count_label: Label = $UICanvas/MainUI/HSplitContainer/LeftPanel/MarginContainer/VBoxContainer/TopBar/SelectedCountLabel

@export var available_boards: Array[BoardData]

@export_group("Card Pools")
@export var singleplayer_pieces: Array[PieceData] = []
@export var multiplayer_pieces: Array[PieceData] = []

var current_step: FlowStep = FlowStep.P1_SELECT
var current_player: int = 1
var player1_hand: Array[PieceData] = []
var player2_hand: Array[PieceData] = []
var player1_placed: Dictionary = {}
var player2_placed: Dictionary = {}

var selected_card: Card = null
var selected_tile: Tile = null

const UNLOCK_STAGES = [1, 3, 6, 9, 11, 14]
var max_pieces_p1 := 3
var max_pieces_p2 := 3

@onready var background_texture: TextureRect = $Background

func _ready() -> void:
	$Background.texture = GameState.background[GameState.back]
	if GameState.game_mode == GameState.GameMode.NONE:
		push_error("Invalid gamemode")
		return
	AudioManager.play_music(preload("res://assets/sound/music_menu.ogg"))
	
	if GameState.game_mode == GameState.GameMode.SINGLEPLAYER:
		if available_boards.size() > 0:
			GameState.board = available_boards.pick_random()
		_setup_singleplayer()
	else:
		_setup_multiplayer()
		
	if not GameState.board:
		if available_boards.size() > 0:
			GameState.board = available_boards.pick_random()
		else:
			return
	
	board.set_mode(BoardManager.Mode.PREVIEW)
	board.board_data = GameState.board
	board.generate()
	_position_board_base_at_viewport_bottom()
	_connect_signals()
	
	_start_selection_phase()

func _setup_singleplayer() -> void:
	var current_stage = GameState.current_stage
	
	var allowed_picks = 1
	if current_stage >= 10:
		allowed_picks = 5
	elif current_stage >= 8:
		allowed_picks = 3
	elif current_stage >= 5:
		allowed_picks = 2
	else:
		allowed_picks = 1
		
	var unlocked_count = 0
	for req in UNLOCK_STAGES:
		if current_stage >= req:
			unlocked_count += 1

	var base_limit = min(allowed_picks, unlocked_count)
	var extra_buff = GameState.saved_extra_pieces_limit
	
	max_pieces_p1 = min(base_limit + extra_buff, 6)
	max_pieces_p1 = clamp(max_pieces_p1, 1, 6)
	max_pieces_p2 = 0

func _setup_multiplayer() -> void:
	max_pieces_p1 = 3
	max_pieces_p2 = 3

func _position_board_base_at_viewport_bottom() -> void:
	var required_board_y := get_viewport_rect().size.y - board.get_base_bottom() * board.scale.y
	board.position.y = maxf(board.position.y, required_board_y)

func _connect_signals() -> void:
	for tile in board.tiles.values():
		tile.tile_clicked.connect(_on_tile_clicked)
	
	if not confirm_selection_btn.pressed.is_connected(_on_confirm_selection_pressed):
		confirm_selection_btn.pressed.connect(_on_confirm_selection_pressed)
	if not confirm_placement_btn.pressed.is_connected(_on_confirm_placement_pressed):
		confirm_placement_btn.pressed.connect(_on_confirm_placement_pressed)
	if not draft_back_btn.pressed.is_connected(_on_exit_pressed):
		draft_back_btn.pressed.connect(_on_exit_pressed)

func _start_selection_phase() -> void:
	split_container.hide()
	selection_overlay.show()
	confirm_selection_btn.disabled = true
	
	for child in selection_grid.get_children():
		child.queue_free()
	
	var card_scene = load("res://scenes/card.tscn")
	var is_single = GameState.game_mode == GameState.GameMode.SINGLEPLAYER
	var current_stage = GameState.current_stage if is_single else 999
	
	var active_pieces: Array[PieceData] = singleplayer_pieces if is_single else multiplayer_pieces
	
	for i in range(active_pieces.size()):
		var piece = active_pieces[i]
		var card = card_scene.instantiate() as Card
		selection_grid.add_child(card)
		card.set_piece_data(piece)
		
		if is_single:
			var req_stage = 999
			if i < UNLOCK_STAGES.size():
				req_stage = UNLOCK_STAGES[i]
				
			if current_stage < req_stage:
				card.set_disabled(true)
			else:
				card.set_disabled(false)
		
		card.clicked.connect(_on_card_interacted)
		
		var hand = _get_current_hand()
		if piece in hand and not card.is_disabled:
			card.select()
			
	_update_ui()

func _start_placement_phase() -> void:
	selection_overlay.hide()
	split_container.show()
	selected_card = null
	confirm_placement_btn.visible = false
	
	for child in card_flow.get_children():
		child.queue_free()
	
	var card_scene = load("res://scenes/card.tscn")
	for piece in _get_current_hand():
		var card = card_scene.instantiate() as Card
		card_flow.add_child(card)
		card.set_piece_data(piece)
		card.clicked.connect(_on_card_interacted)
	_update_ui()

func _on_card_interacted(card: Card) -> void:
	if card.is_disabled: 
		return
		
	if current_step <= FlowStep.P2_SELECT:
		_handle_draft_interaction(card)
	else:
		_handle_placement_interaction(card)
	_update_ui()

func _handle_draft_interaction(card: Card) -> void:
	var hand = _get_current_hand()
	var max_pieces = _get_current_max_pieces()
	
	if card.is_selected:
		card.deselect()
		hand.erase(card.piece_data)
	else:
		if GameState.game_mode == GameState.GameMode.MULTIPLAYER:
			var same_class_piece: PieceData = null
			
			for piece in hand:
				if piece.piece_class == card.piece_data.piece_class:
					same_class_piece = piece
					break
			
			if same_class_piece != null:
				hand.erase(same_class_piece)
				_deselect_card_by_data(selection_grid, same_class_piece)


		if hand.size() < max_pieces:
			card.select()
			hand.append(card.piece_data)
			AudioManager.play_sfx(SELECT_SFX)

	confirm_selection_btn.disabled = (hand.size() != max_pieces)

func _handle_placement_interaction(card: Card) -> void:
	if card.is_selected:
		card.deselect()
		selected_card = null
		board.clear_all_highlights()
	else:
		for child in card_flow.get_children():
			if child is Card: child.deselect()
		
		card.select()
		selected_card = card
		selected_tile = null
		board.clear_all_highlights()
		board.highlight_tiles(get_valid_placement_tiles(current_player))

func _on_confirm_selection_pressed() -> void:
	AudioManager.play_sfx(CONFIRM_SFX)
	
	var is_single = GameState.game_mode == GameState.GameMode.SINGLEPLAYER
	if is_single:
		current_step = FlowStep.P1_PLACE
		current_player = 1
		_start_placement_phase()
	else:
		if current_step == FlowStep.P1_SELECT:
			current_step = FlowStep.P2_SELECT
			current_player = 2
			_start_selection_phase()
		else:
			current_step = FlowStep.P1_PLACE
			current_player = 1
			_start_placement_phase()

func _on_confirm_placement_pressed() -> void:
	AudioManager.play_sfx(CONFIRM_SFX)
	
	var is_single = GameState.game_mode == GameState.GameMode.SINGLEPLAYER
	if is_single:
		GameState.player_1_pieces = player1_placed
		_go_to_battle()
	else:
		if current_step == FlowStep.P1_PLACE:
			current_step = FlowStep.P2_PLACE
			current_player = 2
			_start_placement_phase()
		else:
			GameState.player_1_pieces = player1_placed
			GameState.player_2_pieces = player2_placed
			_go_to_battle()

func _go_to_battle() -> void:
	var loading_scene = load("res://scenes/loading_screen.tscn").instantiate() as LoadingScreen
	loading_scene.target_scene = "res://scenes/battle.tscn"
	get_tree().root.add_child(loading_scene)
	get_tree().current_scene = loading_scene
	queue_free()

func _on_tile_clicked(grid_pos: Vector2i) -> void:
	if current_step < FlowStep.P1_PLACE: return
	var tile = board.get_tile_at(grid_pos)
	
	if selected_tile != null:
		_handle_repositioning(tile)
	elif tile.occupant.piece_data != null:
		_handle_board_piece_click(tile)
	elif selected_card != null and _is_valid_placement_row(grid_pos.y):
		_place_new_piece(grid_pos)

func _place_new_piece(grid_pos: Vector2i) -> void:
	if board.place_piece(selected_card.piece_data, grid_pos.x, grid_pos.y, current_player):
		AudioManager.play_sfx(MOVE_SFX)
		_get_current_placed_dict()[grid_pos] = selected_card.piece_data
		selected_card.hide()
		selected_card.deselect()
		selected_card = null
		board.clear_all_highlights()
		_update_ui()
		_validate_placement_completion()

func _validate_placement_completion() -> void:
	var max_pieces = _get_current_max_pieces()
	var is_complete = _get_current_placed_dict().size() == max_pieces
	confirm_placement_btn.visible = is_complete
	confirm_placement_btn.disabled = not is_complete

func _handle_board_piece_click(tile: Tile) -> void:
	if tile.occupant.player != current_player: return
	if selected_card: selected_card.deselect()
	selected_card = null
	selected_tile = tile
	board.clear_all_highlights()
	board.highlight_tiles(get_valid_placement_tiles(current_player))
	board.highlight_tile(tile, Tile.HighlightColor.SELF)

func _handle_repositioning(target_tile: Tile) -> void:
	var can_reposition = target_tile != selected_tile and \
						_is_valid_placement_row(target_tile.grid_position.y) and \
						selected_tile.occupant.player == current_player
						
	if can_reposition:
		var dict = _get_current_placed_dict()
		if target_tile.occupant.piece_data == null:
			dict[target_tile.grid_position] = dict[selected_tile.grid_position]
			dict.erase(selected_tile.grid_position)
			board._move_occupant(selected_tile, target_tile)
			AudioManager.play_sfx(MOVE_SFX)
		elif target_tile.occupant.player == current_player:
			var selected_piece = dict[selected_tile.grid_position]
			dict[selected_tile.grid_position] = dict[target_tile.grid_position]
			dict[target_tile.grid_position] = selected_piece
			_swap_placed_occupants(selected_tile, target_tile)
			AudioManager.play_sfx(MOVE_SFX)
		
	selected_tile = null
	board.clear_all_highlights()

func _swap_placed_occupants(first_tile: Tile, second_tile: Tile) -> void:
	var first_piece = first_tile.occupant.piece_data
	var second_piece = second_tile.occupant.piece_data
	var first_hp = first_tile.occupant.current_hp
	var second_hp = second_tile.occupant.current_hp
	var show_health = board.current_mode == BoardManager.Mode.BATTLE

	first_tile.occupant.set_data(second_piece, current_player, second_hp, show_health)
	second_tile.occupant.set_data(first_piece, current_player, first_hp, show_health)

func _update_ui() -> void:
	if current_step <= FlowStep.P2_SELECT:
		draft_turn_label.text = tr("player_label") % current_player
		draft_count_label.text = tr("pieces_picked") % [_get_current_hand().size(), _get_current_max_pieces()]
		placement_turn_label.text = "" 
		placement_count_label.text = ""
	else:
		placement_turn_label.text = tr("player_label") % current_player
		placement_count_label.text = tr("pieces_placed") % [_get_current_placed_dict().size(), _get_current_max_pieces()]
func _get_current_hand() -> Array[PieceData]:
	return player1_hand if current_player == 1 else player2_hand

func _get_current_placed_dict() -> Dictionary:
	return player1_placed if current_player == 1 else player2_placed

func _get_current_max_pieces() -> int:
	return max_pieces_p1 if current_player == 1 else max_pieces_p2

func _is_valid_placement_row(y: int) -> bool:
	return y == (0 if current_player == 2 else board.grid_size.y - 1)

func get_valid_placement_tiles(p_idx: int) -> Array[Tile]:
	var tiles: Array[Tile] = []
	var y = 0 if p_idx == 2 else board.grid_size.y - 1
	for x in range(board.grid_size.x):
		var t = board.get_tile_at(Vector2i(x, y))
		if t and t.occupant.piece_data == null: tiles.append(t)
	return tiles

func _deselect_card_by_data(container: Control, data: PieceData) -> void:
	for child in container.get_children():
		if child is Card and child.piece_data == data:
			child.deselect()
			return

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map_select_screen.tscn")
