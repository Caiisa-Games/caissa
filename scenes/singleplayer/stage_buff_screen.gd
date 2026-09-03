class_name StageBuffPopup
extends Control

signal buff_selected

@onready var option1_btn: Button = $Option1Btn
@onready var option2_btn: Button = $Option2Btn
@onready var confirm_btn: Button = $ConfirmBtn
@onready var texture_rect: TextureRect = $TextureRect

var current_stage: int = 1
var selected_choice: int = 0
var is_animating: bool = false
var confirm_click_count: int = 0
var is_first_confirm: bool = true
var shutter_count: int = 0

var option1_original_y: float = 0.0
var option2_original_y: float = 0.0
var confirm_hidden_y: float = 0.0
var confirm_original_y: float = 0.0

func _ready() -> void:
	_setup_buttons()
	
	option1_original_y = option1_btn.position.y
	option2_original_y = option2_btn.position.y
	confirm_original_y = confirm_btn.position.y
	
	confirm_hidden_y = confirm_original_y + 200.0 
	confirm_btn.position.y = confirm_hidden_y
	confirm_btn.disabled = true
	confirm_btn.text = tr("confirm")
	confirm_btn.visible = false
	
	texture_rect.visible = false
	
	option1_btn.position.y = option1_original_y - 30.0
	option2_btn.position.y = option2_original_y - 30.0
	
	_animate_options_entrance_with_delay()

func _animate_options_entrance_with_delay() -> void:
	is_animating = true
	await get_tree().create_timer(3.0).timeout
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(option1_btn, "position:y", option1_original_y, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(option2_btn, "position:y", option2_original_y, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	await tween.finished
	is_animating = false
func _setup_buttons() -> void:
	current_stage = GameState.current_stage
	
	match current_stage:
		5:
			option1_btn.text = "10% کاهش نیروی دشمن"
			option2_btn.text = "10 اضافه کردن جون نیروی خودی"
		10:
			option1_btn.text = "3 واحد اضافه کردن قدرت نیروی خودی"
			option2_btn.text = "10% کاهش نیروی دشمن"
		15:
			option1_btn.text = "15% کاهش نیروی دشمن"
			option2_btn.text = "15 اضافه کردن جون نیروی خودی"
		_:
			option1_btn.text = ""
			option2_btn.text = ""

func _on_option1_pressed() -> void:
	if is_animating or not option1_btn.visible: 
		return
	_select_choice(1)

func _on_option2_pressed() -> void:
	if is_animating or not option2_btn.visible: 
		return
	_select_choice(2)

func _select_choice(choice: int) -> void:
	if selected_choice == choice:
		option1_btn.modulate = Color.WHITE
		option2_btn.modulate = Color.WHITE
		selected_choice = 0
		if is_first_confirm:
			confirm_btn.disabled = true
			_slide_out_confirm()
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
	
	if is_first_confirm:
		_slide_in_confirm()

func _slide_in_confirm() -> void:
	confirm_btn.visible = true
	var tween = create_tween()
	tween.tween_property(confirm_btn, "position:y", confirm_original_y, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)

func _slide_out_confirm() -> void:
	var tween = create_tween()
	tween.tween_property(confirm_btn, "position:y", confirm_hidden_y, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
	await tween.finished
	confirm_btn.visible = false

func _show_texture_rect() -> void:
	texture_rect.visible = true
	texture_rect.modulate.a = 0.0
	
	if confirm_click_count == 1:
		texture_rect.texture = load("res://assets/icons/Attack.png")
	elif confirm_click_count >= 2:
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
	if GameState.post_buff_destination == "next_stage":
		GameState.set_current_stage(GameState.current_stage + 1)
		if GameState.current_stage > 15: 
			get_tree().change_scene_to_file("res://scenes/singleplayer/stage_selection.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/battle.tscn")
	else:
		GameState.reset()
		if GameState.game_mode == GameState.GameMode.SINGLEPLAYER:
			get_tree().change_scene_to_file("res://scenes/singleplayer/stage_selection.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/map_select_screen.tscn")

func _on_confirm_btn_pressed() -> void:
	if is_first_confirm and selected_choice == 0:
		return
	if is_animating:
		return

	confirm_click_count += 1

	if confirm_click_count == 1:
		if selected_choice != 0:
			_save_choice(selected_choice)
		
		option1_btn.visible = false
		option2_btn.visible = false
		is_first_confirm = false
		
		_show_texture_rect()
		confirm_btn.disabled = false
		
	elif confirm_click_count == 2:
		_show_texture_rect()
		confirm_btn.disabled = false
		
	elif confirm_click_count >= 3:
		_redirect()
