extends Control

@onready var card_container = $Margin/VBoxContainer/CenterContainer/GridContainer
@onready var details = $Margin/VBoxContainer/MapDetailsPanel
@onready var details_empty: Label = $Margin/VBoxContainer/MapDetailsPanel/Margin/Empty
@onready var details_content: HBoxContainer = $Margin/VBoxContainer/MapDetailsPanel/Margin/Content
@onready var details_preview: MapPreview = $Margin/VBoxContainer/MapDetailsPanel/Margin/Content/Preview
@onready var details_name: Label = $Margin/VBoxContainer/MapDetailsPanel/Margin/Content/Text/Name
@onready var details_meta: Label = $Margin/VBoxContainer/MapDetailsPanel/Margin/Content/Text/Meta

@onready var play_button: Button = $Margin/VBoxContainer/BottomButtons/Margin/HBoxContainer/RightGroup/PlayButton     

@export var maps: Array[BoardData] = []
var selected: BoardData

func _ready() -> void:
	play_button.disabled = true
	load_maps()
	update_details()

func load_maps():
	for data in maps:
		var card = preload("res://scenes/map_card.tscn").instantiate() as BoardCard
		card.setup(data)
		card.pressed.connect(select_map.bind(data))
		
		card_container.add_child(card)
		
func select_map(data: BoardData):
	selected = null if selected == data else data

	for card in card_container.get_children():
		(card as BoardCard).set_selected(card.board_data == selected)

	play_button.disabled = selected == null
	update_details()

func update_details() -> void:
	var has_selection := selected != null
	details_empty.visible = not has_selection
	details_content.visible = has_selection
	if not has_selection:
		details_preview.board_data = null
		return

	details_preview.board_data = selected
	details_name.text = selected.board_name
	var max_height := 0
	for height in selected.cell_heights:
		max_height = maxi(max_height, height)
	details_meta.text = "%d x %d board  |  Elevation 0-%d" % [selected.grid_size.x, selected.grid_size.y, max_height]


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
