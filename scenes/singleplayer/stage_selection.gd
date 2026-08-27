class_name StageSelection
extends Control

@onready var buttons = {
	1: get_node_or_null("Button1"),
	2: get_node_or_null("Button2"),
	3: get_node_or_null("Button3"),
	4: get_node_or_null("Button4"),
	5: get_node_or_null("Button5"),
	6: get_node_or_null("Button6"),
	7: get_node_or_null("Button7"),
	8: get_node_or_null("Button8"),
	9: get_node_or_null("Button9"),
	10: get_node_or_null("Button10"),
	11: get_node_or_null("Button11"),
	12: get_node_or_null("Button12"),
	13: get_node_or_null("Button13"),
	14: get_node_or_null("Button14"),
	15: get_node_or_null("Button15"),
	16: get_node_or_null("Button16"),
	17: get_node_or_null("Button17"),
	18: get_node_or_null("Button18"),
	19: get_node_or_null("Button19"),
	20: get_node_or_null("Button20")
}

@onready var safe_btn_5: Button = get_node_or_null("SafeButton5")
@onready var safe_btn_10: Button = get_node_or_null("SafeButton10")
@onready var button_1_a: Button = $GridContainer2/Button
@onready var button_2_b: Button = $GridContainer2/Button2

const BUFF_POPUP_SCENE = preload("res://scenes/singleplayer/stage_buff_screen.tscn")

var check = 0
var pos = 1152
var pos_camera = 1152.0
var is_moving = false

func _ready() -> void:
	_update_stage_buttons()
	_update_safe_buttons()
	update_navigation_buttons()

func update_navigation_buttons() -> void:
	var camera_x = $Camera2D.position.x
	
	if camera_x <= 576.0:
		button_1_a.modulate.a = 0.0
		button_1_a.disabled = true
	else:
		button_1_a.modulate.a = 1.0
		button_1_a.disabled = false
	
	if camera_x >= 4032.0:
		button_2_b.modulate.a = 0.0
		button_2_b.disabled = true
	else:
		button_2_b.modulate.a = 1.0
		button_2_b.disabled = false


func _update_stage_buttons() -> void:
	var unlocked_stage = GameState.highest_unlocked_stage
	for stage_num in buttons:
		var btn = buttons[stage_num]
		if btn:
			if stage_num <= unlocked_stage:
				btn.disabled = false
				if not btn.pressed.is_connected(_on_stage_pressed):
					btn.pressed.connect(_on_stage_pressed.bind(stage_num))
			else:
				btn.disabled = true
	camera()


func camera():
	if GameState.highest_unlocked_stage <= 5:
		$Camera2D.position.x = 576.0
	elif GameState.highest_unlocked_stage <= 10:
		$Camera2D.position.x = 1728.0
	elif GameState.highest_unlocked_stage <= 15:
		$Camera2D.position.x = 2880
	else:
		$Camera2D.position.x = 4032     

func _update_safe_buttons() -> void:
	var unlocked = GameState.highest_unlocked_stage
	_setup_single_safe(safe_btn_5, 5, unlocked == 6)
	_setup_single_safe(safe_btn_10, 10, unlocked == 11)

func _setup_single_safe(btn: Button, stage_num: int, is_active: bool) -> void:
	if not btn: return
	
	btn.disabled = not is_active
	if is_active:
		btn.modulate = Color.GOLD 
		if not btn.pressed.is_connected(_open_safe_popup):
			btn.pressed.connect(_open_safe_popup.bind(stage_num))
	else:
		btn.modulate = Color.DARK_GRAY

func _open_safe_popup(stage_num: int) -> void:
	GameState.current_stage = stage_num
	if BUFF_POPUP_SCENE:
		var popup = BUFF_POPUP_SCENE.instantiate() #as StageBuffPopup
		add_child(popup)
		popup.buff_selected.connect(_update_safe_buttons)

func _on_stage_pressed(stage_num: int) -> void:
	GameState.current_stage = stage_num
	GameState.game_mode = GameState.GameMode.SINGLEPLAYER
	get_tree().change_scene_to_file("res://scenes/piece_selection.tscn")


func _on_button_pressed() -> void:
	if is_moving:
		return
	
	is_moving = true
	
	var new_camera_x = clamp(
		$Camera2D.position.x - pos_camera,
		576.0,
		4032
	)
	
	var new_grid_x = clamp(
		$GridContainer2.position.x - pos,
		0.0,
		3456.0
	)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(
		$Camera2D,
		"position:x",
		new_camera_x,
		0.5
	)
	
	tween.tween_property(
		$GridContainer2,
		"position:x",
		new_grid_x,
		0.5
	)
	
	await tween.finished
	is_moving = false
	update_navigation_buttons()


func _on_button_2_pressed() -> void:
	if is_moving:
		return
	
	is_moving = true
	
	var new_camera_x = clamp(
		$Camera2D.position.x + pos_camera,
		576.0,
		4032
	)
	
	var new_grid_x = clamp(
		$GridContainer2.position.x + pos,
		0.0,
		3456.0
	)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(
		$Camera2D,
		"position:x",
		new_camera_x,
		0.5
	)
	
	tween.tween_property(
		$GridContainer2,
		"position:x",
		new_grid_x,
		0.5
	)
	
	await tween.finished
	is_moving = false
	update_navigation_buttons()
