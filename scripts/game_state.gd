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

var post_buff_destination: String = "next_stage" 

var back := 1
var back_disable: Array = []
var background = {
	1: load("res://assets/Misc/Background/Battle-Background.png"),
	2: load("res://assets/Misc/Background/lvlbackground.png"),
	3: load("res://assets/Misc/Background/LENIN.png"),
	4: load("res://assets/Misc/Background/Greek Architecture.png"),
	5: load("res://assets/Misc/Background/Renaissance.png")
}

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

func apply_saved_preferences(save_data: Dictionary) -> void:
	refresh_background_unlocks(save_data)
	var saved_background := clampi(int(save_data.get("selected_background_id", 1)), 1, background.size())
	back = saved_background if is_background_unlocked(saved_background) else 1

func refresh_background_unlocks(save_data: Dictionary) -> void:
	back_disable.clear()
	var chosen_buffs = save_data.get("chosen_buffs", {})
	if not chosen_buffs is Dictionary:
		return
	if int(chosen_buffs.get("level5", 0)) > 0:
		back_disable.append(5)
	if int(chosen_buffs.get("level10", 0)) > 0:
		back_disable.append(10)
	if int(chosen_buffs.get("level15", 0)) > 0:
		back_disable.append(15)

func is_background_unlocked(background_id: int) -> bool:
	match background_id:
		1:
			return true
		2, 3:
			return 5 in back_disable
		4:
			return 10 in back_disable
		5:
			return 15 in back_disable
	return false

func set_background(background_id: int) -> bool:
	if not background.has(background_id) or not is_background_unlocked(background_id):
		return false
	back = background_id
	return true

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
