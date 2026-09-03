extends Node

enum GameMode {
	MULTIPLAYER,
	SINGLEPLAYER,
	NONE
}

var game_mode: GameMode = GameMode.NONE

var board: BoardData

var player_1_pieces: Dictionary = {}
var player_2_pieces: Dictionary = {}

var winner: int = 0
var intro_played: bool = false

var current_stage: int = 1
var highest_unlocked_stage: int = 1

var saved_extra_pieces_limit: int = 0

var post_buff_destination: String = "next_stage" # "next_stage" یا "menu"

func reset() -> void:
	player_1_pieces.clear()
	player_2_pieces.clear()
	winner = 0

func unlock_next_stage() -> void:
	unlock_stage(current_stage + 1)

func unlock_stage(stage: int) -> void:
	if stage > highest_unlocked_stage:
		highest_unlocked_stage = stage
		if SaveManager and "data" in SaveManager:
			SaveManager.data.highest_unlocked_level = highest_unlocked_stage
			if SaveManager.has_method("save"):
				SaveManager.save()

func set_current_stage(value: int) -> bool:
	current_stage = value
	return true

func get_pieces_for_player(player: int) -> Dictionary:
	match player:
		1: return player_1_pieces
		2: return player_2_pieces
	return {}

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_F11:
			toggle_fullscreen()

func toggle_fullscreen() -> void:
	var current_mode := DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1152, 648))
