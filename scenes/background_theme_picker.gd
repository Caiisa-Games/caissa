class_name BackgroundThemePicker
extends Control

const THEME_COUNT := 5
const POPUP_SIZE := Vector2i(510, 174)
const THEME_NAMES := ["theme_classic", "theme_level", "theme_lenin", "theme_greek", "theme_renaissance"]
const THEME_UNLOCKS := ["", "theme_unlock_stage_5", "theme_unlock_stage_5", "theme_unlock_stage_10", "theme_unlock_stage_15"]
const THEME_BACKGROUNDS := [
	preload("res://assets/Misc/Background/Battle-Background.png"),
	preload("res://assets/Misc/Background/lvlbackground.png"),
	preload("res://assets/Misc/Background/LENIN.png"),
	preload("res://assets/Misc/Background/Greek Architecture.png"),
	preload("res://assets/Misc/Background/Renaissance.png"),
]

@export var trigger_path: NodePath
@export var background_path: NodePath

var trigger: Button
var background: TextureRect
var popup: PopupPanel
var theme_cards: Array[Button] = []

func _ready() -> void:
	trigger = get_node(trigger_path) as Button
	background = get_node(background_path) as TextureRect
	popup = $Popup
	for card in $Popup/Panel/Margin/Content/ThemeRow.get_children():
		if card is Button:
			theme_cards.append(card)
			card.pressed.connect(_select_theme.bind(theme_cards.size()))
	trigger.pressed.connect(_toggle_popup)
	_apply_current_theme()

func _toggle_popup() -> void:
	if popup.visible:
		popup.hide()
		return
	_refresh_cards()
	var rect := trigger.get_global_rect()
	popup.size = POPUP_SIZE
	popup.position = Vector2i(rect.position + Vector2(0, rect.size.y + 8))
	popup.popup()

func _refresh_cards() -> void:
	for index in theme_cards.size():
		var theme_id := index + 1
		var card := theme_cards[index]
		var unlocked := GameState.is_background_unlocked(theme_id)
		card.disabled = not unlocked
		card.tooltip_text = tr(THEME_NAMES[index]) if unlocked else tr(THEME_UNLOCKS[index])
		(card.get_node("Caption") as Label).text = tr(THEME_NAMES[index]) if unlocked else tr("theme_locked")
		(card.get_node("Preview") as TextureRect).modulate = Color.WHITE if unlocked else Color(0.33, 0.33, 0.33, 1)
		card.modulate = Color("c8f3ff") if theme_id == GameState.back else Color.WHITE

func _select_theme(theme_id: int) -> void:
	if not GameState.set_background(theme_id):
		return
	SaveManager.data.selected_background_id = theme_id
	SaveManager.save()
	_apply_current_theme()
	popup.hide()

func _apply_current_theme() -> void:
	background.texture = GameState.background[GameState.back]
	trigger.icon = THEME_BACKGROUNDS[GameState.back - 1]
	trigger.expand_icon = true
	trigger.text = "%s: %s" % [tr("arena_theme"), tr(THEME_NAMES[GameState.back - 1])]
	_refresh_cards()
