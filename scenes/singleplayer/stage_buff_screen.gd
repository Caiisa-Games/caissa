class_name StageBuffPopup
extends Control

signal buff_selected

@onready var option1_btn: Button = $Option1Btn
@onready var option2_btn: Button = $Option2Btn
@onready var confirm_btn: Button = $ConfirmBtn
@onready var color_rect: ColorRect = $ColorRect
@onready var texture_rect: TextureRect = $TextureRect

var current_stage: int = 1
var selected_choice: int = 0
var is_animating: bool = false
var confirm_click_count: int = 0
var is_first_confirm: bool = true
var shutter_count: int = 0

func _ready() -> void:
	_setup_buttons()
	confirm_btn.disabled = true
	confirm_btn.text = tr("confirm")
	texture_rect.visible = false
	color_rect.position.y = -color_rect.size.y
	option1_btn.visible = true
	option2_btn.visible = true

func _setup_buttons() -> void:
	current_stage = GameState.current_stage
	if current_stage not in [5, 10, 15]:
		return
	option1_btn.text = tr("option1_stage_%d" % current_stage)
	option2_btn.text = tr("option2_stage_%d" % current_stage)

func _on_option1_pressed() -> void:
	_select_choice(1)

func _on_option2_pressed() -> void:
	_select_choice(2)

func _select_choice(choice: int) -> void:
	if selected_choice == choice:
		option1_btn.modulate = Color.WHITE
		option2_btn.modulate = Color.WHITE
		selected_choice = 0
		if is_first_confirm:
			confirm_btn.disabled = true
		return
	
	option1_btn.modulate = Color.WHITE
	option2_btn.modulate = Color.WHITE
	
	selected_choice = choice
	
	match choice:
		1:
			option1_btn.modulate = Color.GREEN
		2:
			option2_btn.modulate = Color.GREEN
	
	confirm_btn.disabled = false

func _animate_shutter() -> void:
	is_animating = true

	
	option1_btn.visible = false
	option2_btn.visible = false

	confirm_btn.visible = true

	color_rect.position.y = -color_rect.size.y

	var tween = create_tween()
	tween.set_parallel(false)

	tween.tween_property(color_rect, "position:y", 0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_interval(0.8)
	tween.tween_property(color_rect, "position:y", -color_rect.size.y, 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)

	tween.tween_callback(func():
		is_animating = false
		_show_buttons()
		_show_texture_rect()
	)

func _show_buttons() -> void:
	option1_btn.visible = false
	option2_btn.visible = false

	
	confirm_btn.visible = true

	option1_btn.modulate = Color.WHITE
	option2_btn.modulate = Color.WHITE

	confirm_btn.disabled = false

	_setup_buttons()

func _show_texture_rect() -> void:
	texture_rect.visible = true
	texture_rect.modulate.a = 0.0
	if shutter_count == 1:
		texture_rect.texture = load("res://assets/icons/Attack.png")
	elif shutter_count == 2:
		texture_rect.texture = load("res://assets/icons/Class1.png")

	var tween = create_tween()
	tween.tween_property(texture_rect, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)


func _save_choice(choice: int) -> void:
	current_stage = GameState.current_stage

	if current_stage == 5:
		SaveManager.data.chosen_buffs.level5 = choice
	elif current_stage == 10:
		SaveManager.data.chosen_buffs.level10 = choice
	elif current_stage == 15:
		SaveManager.data.chosen_buffs.level15 = choice 

	SaveManager.save()
	BuffManager.apply_stage_buff(current_stage, choice)



func _redirect() -> void:
	current_stage = GameState.current_stage
	GameState.game_mode = GameState.GameMode.SINGLEPLAYER
	
	confirm_click_count = 0
	texture_rect.visible = false
	color_rect.position.y = -color_rect.size.y
	is_first_confirm = true
	option1_btn.visible = true
	option2_btn.visible = true
	confirm_btn.visible = true
	option1_btn.modulate = Color.WHITE
	option2_btn.modulate = Color.WHITE
	selected_choice = 0
	confirm_btn.disabled = true
	_setup_buttons()
	
	get_tree().change_scene_to_file("res://scenes/piece_selection.tscn")


func _on_confirm_btn_pressed() -> void:
	if selected_choice == 0 or is_animating:
		return

	confirm_click_count += 1

	option1_btn.visible = false
	option2_btn.visible = false
	if confirm_click_count >= 3:
		_redirect()
		return

	_save_choice(selected_choice)

	shutter_count = confirm_click_count

	_animate_shutter()
