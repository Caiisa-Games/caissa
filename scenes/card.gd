class_name Card
extends Control

signal clicked(card: Card)

@export_group("Class Icons")
@export var tank_icon: Texture2D
@export var berserker_icon: Texture2D
@export var util_icon: Texture2D

@export_group("Stat Icons")
@export var hp_icon: Texture2D
@export var atk_icon: Texture2D
@export var kb_icon: Texture2D

@onready var blank_card = $BlankCard
@onready var card_texture: TextureRect = $CardTexture
@onready var texture_rect: TextureRect = $BlankCard/Margin/Content/Control/ClassIcon


var piece_data: PieceData
var is_selected: bool = false
var is_disabled: bool = false
var original_scale: Vector2
var _selection_tween: Tween
var _selection_animation_token := 0

func _ready() -> void:
	original_scale = scale
	blank_card.hide()
	card_texture.show()
	
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)

func set_piece_data(data: PieceData) -> void:
	piece_data = data
	_update_display()

func _update_display() -> void:
	if not piece_data: return
	
	card_texture.texture = piece_data.card_texture
	
	$BlankCard/Margin/Content/NameLabel.text = piece_data.name
	$BlankCard/Margin/Content/StatsGrid/HP_Row/Bar.value = piece_data.defense
	$BlankCard/Margin/Content/StatsGrid/ATK_Row/Bar.value = piece_data.power
	$BlankCard/Margin/Content/StatsGrid/KB_Row/Bar.value = piece_data.knockback
	
	$BlankCard/Margin/Content/StatsGrid/HP_Row/Icon.texture = hp_icon
	$BlankCard/Margin/Content/StatsGrid/ATK_Row/Icon.texture = atk_icon
	$BlankCard/Margin/Content/StatsGrid/KB_Row/Icon.texture = kb_icon

	var c_icon = _get_class_icon()
	$BlankCard/Margin/Content/Control/ClassIcon.texture = c_icon

func _get_class_icon() -> Texture2D:
	match piece_data.piece_class:
		PieceData.PieceClass.TANK: return tank_icon
		PieceData.PieceClass.BERSERKER: return berserker_icon
		PieceData.PieceClass.UTILITY: return util_icon
	return null

var is_animating: bool = false

func select() -> void:
	if is_disabled or is_selected: return
	is_selected = true
	_play_selection_animation(true)

func deselect() -> void:
	if is_disabled or not is_selected: return
	is_selected = false
	_play_selection_animation(false)

func _play_selection_animation(is_selecting: bool) -> void:
	_cancel_selection_animation()
	is_animating = true
	var animation_token := _selection_animation_token
	_selection_tween = create_tween().set_parallel(true)
	var target_scale := original_scale * (1.05 if is_selecting else 1.0)
	var target_icon_scale := Vector2.ONE * (1.05 if is_selecting else 1.0)
	_selection_tween.tween_property(self, "scale", target_scale, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_selection_tween.tween_property(texture_rect, "scale", target_icon_scale, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if is_selecting:
		_selection_tween.tween_property(texture_rect, "rotation", texture_rect.rotation + (2 * PI), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_selection_tween.finished.connect(func():
		if animation_token == _selection_animation_token:
			is_animating = false
	)

func _cancel_selection_animation() -> void:
	_selection_animation_token += 1
	if _selection_tween and _selection_tween.is_valid():
		_selection_tween.kill()
	is_animating = false

func _on_mouse_entered() -> void:
	if is_disabled: return
	card_texture.hide()
	blank_card.show()
	if blank_card.has_method("start_hover"):
		blank_card.start_hover()

func _on_mouse_exited() -> void:
	if is_disabled: return
	blank_card.hide()
	card_texture.show()
	if card_texture.has_method("play_exit_shader"):
		card_texture.play_exit_shader()

func set_disabled(disabled: bool) -> void:
	is_disabled = disabled
	if is_disabled:
		modulate = Color(0.3, 0.3, 0.3, 0.7)
		mouse_filter = MOUSE_FILTER_IGNORE
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)
		mouse_filter = MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if is_disabled: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
		accept_event()


func _on_class_icon_mouse_entered() -> void:
	if is_disabled: return
	card_texture.hide()
	blank_card.show()
	if blank_card.has_method("start_hover"):
		blank_card.start_hover()


func _on_control_mouse_entered() -> void:
	if is_disabled: return
	card_texture.hide()
	blank_card.show()
	if blank_card.has_method("start_hover"):
		blank_card.start_hover()
