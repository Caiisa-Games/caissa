extends Control

@onready var card_container = $Margin/VBoxContainer/CenterContainer/GridContainer
@onready var details = $Margin/VBoxContainer/MapDetailsPanel

@onready var play_button: Button = $Margin/VBoxContainer/BottomButtons/Margin/HBoxContainer/RightGroup/Control/PlayButton     

@export var maps: Array[BoardData] = []
var selected: BoardData

func _ready() -> void:
	play_button.disabled = true
	load_maps()

func load_maps():
	for data in maps:
		var card = preload("res://scenes/map_card.tscn").instantiate() as BoardCard
		card.setup(data)
		card.pressed.connect(select_map.bind(data))
		
		card_container.add_child(card)
		
func select_map(data: BoardData):
	for card in card_container.get_children():
		(card as BoardCard).set_selected(data == card.board_data && selected != data)
	if selected == data:
		selected = null
		play_button.disabled = true
	else:
		selected = data
		play_button.disabled = false


func _on_play_button_pressed() -> void:
	if not selected:
		return
	GameState.board = selected
	GameState.game_mode = GameState.GameMode.MULTIPLAYER
	get_tree().change_scene_to_file("res://scenes/piece_selection.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_random_button_pressed() -> void:
	var chosen_board = maps.pick_random()
	select_map(chosen_board)
