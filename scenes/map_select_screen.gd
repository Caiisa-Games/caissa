extends Control

@onready var card_container = $Margin/VBoxContainer/CenterContainer/GridContainer
@onready var details = $Margin/VBoxContainer/MapDetailsPanel
@onready var details_empty: Label = $Margin/VBoxContainer/MapDetailsPanel/Margin/Empty
@onready var details_content: HBoxContainer = $Margin/VBoxContainer/MapDetailsPanel/Margin/Content
@onready var details_preview: MapPreview = $Margin/VBoxContainer/MapDetailsPanel/Margin/Content/Preview
@onready var details_name: Label = $Margin/VBoxContainer/MapDetailsPanel/Margin/Content/Text/Name
@onready var details_meta: Label = $Margin/VBoxContainer/MapDetailsPanel/Margin/Content/Text/Meta
@onready var board_size_select: OptionButton = $Margin/VBoxContainer/BottomButtons/Margin/HBoxContainer/RightGroup/ModeSelect

@onready var play_button: Button = $Margin/VBoxContainer/BottomButtons/Margin/HBoxContainer/RightGroup/PlayButton     

@export var maps: Array[BoardData] = []
const BOARD_SIZES: Array[int] = [7, 8, 9]

var selected: BoardData
var displayed_maps: Array[BoardData] = []
var selected_size := BoardManager.DEFAULT_GRID_SIZE

func _ready() -> void:
	play_button.disabled = true
	_setup_size_selector()
	load_maps()
	update_details()

func _setup_size_selector() -> void:
	board_size_select.clear()
	for size in BOARD_SIZES:
		board_size_select.add_item("%d x %d" % [size, size])
		board_size_select.set_item_metadata(board_size_select.item_count - 1, size)
	board_size_select.select(BOARD_SIZES.find(selected_size))
	board_size_select.item_selected.connect(_on_board_size_selected)

func load_maps() -> void:
	for card in card_container.get_children():
		card_container.remove_child(card)
		card.queue_free()
	displayed_maps.clear()

	for data in maps:
		var resized_data := data.resized_to(Vector2i(selected_size, selected_size))
		displayed_maps.append(resized_data)
		var card = preload("res://scenes/map_card.tscn").instantiate() as BoardCard
		card.setup(resized_data)
		card.pressed.connect(select_map.bind(resized_data))
		
		card_container.add_child(card)
		
func select_map(data: BoardData, allow_deselect := true) -> void:
	selected = null if allow_deselect and selected == data else data

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
	details_meta.text = "%d x %d %s  |  %s 0-%d" % [selected.grid_size.x, selected.grid_size.y, tr("board"), tr("elevation"), max_height]


func _on_play_button_pressed() -> void:
	if not selected:
		return
	GameState.board = selected
	GameState.game_mode = GameState.GameMode.MULTIPLAYER
	get_tree().change_scene_to_file("res://scenes/piece_selection.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_random_button_pressed() -> void:
	if displayed_maps.is_empty():
		return
	select_map(displayed_maps.pick_random(), false)

func _on_board_size_selected(index: int) -> void:
	var previous_id := selected.id if selected != null else ""
	selected_size = board_size_select.get_item_metadata(index) as int
	selected = null
	load_maps()

	for map_data in displayed_maps:
		if map_data.id == previous_id:
			selected = map_data
			break
	for card in card_container.get_children():
		(card as BoardCard).set_selected(card.board_data == selected)
	play_button.disabled = selected == null
	update_details()
