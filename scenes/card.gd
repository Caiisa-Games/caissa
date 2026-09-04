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
	if is_disabled or is_animating or is_selected: return
	is_selected = true
	is_animating = true
	
	var tween = create_tween()
	tween.tween_property(texture_rect, "rotation", texture_rect.rotation + (2 * PI), 0.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	var scale_tween = create_tween().set_parallel(true)
	scale_tween.tween_property(self, "scale", original_scale * 1.15, 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(texture_rect, "scale", Vector2(1.2, 1.2), 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await scale_tween.finished

	await get_tree().create_timer(0.5).timeout

	var reset_tween = create_tween().set_parallel(true)
	reset_tween.tween_property(self, "scale", original_scale * 1.05, 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	reset_tween.tween_property(texture_rect, "scale", Vector2(1.05, 1.05), 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await reset_tween.finished
	is_animating = false

func deselect() -> void:
	if is_disabled or is_animating or not is_selected: return
	is_selected = false
	is_animating = true
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", original_scale * 0.9, 0.2)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(texture_rect, "scale", Vector2(0.8, 0.8), 0.2)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await tween.finished

	await get_tree().create_timer(0.5).timeout

	var back_tween = create_tween().set_parallel(true)
	back_tween.tween_property(self, "scale", original_scale, 0.2)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	back_tween.tween_property(texture_rect, "scale", Vector2(1.0, 1.0), 0.2)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await back_tween.finished
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
