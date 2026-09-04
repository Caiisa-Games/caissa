class_name MainMenu
extends Control

const MAP_SELECTION_SCENE = "res://scenes/map_select_screen.tscn"
const LEVEL_SELECTION_SCENE = "res://scenes/singleplayer/stage_selection.tscn"
const SETTINGS_SCENE = preload("res://scenes/settings_menu.tscn")
const CLICK_SFX = preload("res://assets/sound/فشردن دکمه های سنگی.mp3")
const TRANSITION_MUSIC = preload("res://assets/sound/music_transition.ogg")

const CREDITS_START_POS = Vector2(395, 620)
const CREDITS_END_POS = Vector2(395, -655)
const CREDITS_DURATION = 15.0
const FADE_DURATION = 0.7

@onready var color_fade: ColorRect = $ColorRect2
@onready var credits_label: Label = $CreditsLabel
@onready var sp_button: TextureButton = $CenterButtons/SPButton
@onready var mp_button: TextureButton = $CenterButtons/MPButton
@onready var exit_button: TextureButton = $CenterButtons/ExitButton
@onready var settings_button: Button = $HBoxContainer/SettingsButton
@onready var settings_menu: SettingsMenu = $SettingsMenu

@onready var splash_container: Control = $Fade
@onready var splash_dimmer: ColorRect = $Fade/Overlay
@onready var loading_bar: ProgressBar = $Fade/ProgressBar

func _ready() -> void:
	GameState.game_mode = GameState.GameMode.NONE
	SaveManager.load_save()
	GameState.apply_saved_preferences(SaveManager.data)
	if not GameState.intro_played:
		_prepare_ui_for_intro()
		_run_intro_sequence()
	else:
		_reveal_main_menu()

func _prepare_ui_for_intro() -> void:
	$Background.hide()
	$Title.hide()
	sp_button.hide()
	mp_button.hide()
	$HBoxContainer.hide()
	exit_button.hide()
	
	color_fade.hide()
	color_fade.modulate.a = 0
	credits_label.hide()
	
	splash_container.show()
	splash_dimmer.modulate = Color.BLACK
	loading_bar.value = 0
	
func _run_intro_sequence() -> void:
	var intro = create_tween()
	
	intro.tween_interval(1.5)
	intro.tween_property(splash_dimmer, "modulate:a", 0.0, 3.0)
	
	intro.parallel().tween_property(loading_bar, "value", 100.0, 4.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	intro.tween_callback(_reveal_main_menu)

func _reveal_main_menu() -> void:
	GameState.intro_played = true
	splash_container.hide()
	
	$Background.show()
	$Title.show()
	mp_button.show()
	sp_button.show()
	$HBoxContainer.show()
	exit_button.show()
	
	color_fade.hide()
	color_fade.modulate.a = 0
	
	$Title.play("default")
	AudioManager.play_music(preload("res://assets/sound/music_menu.ogg"))

func _on_settings_button_pressed() -> void:
	if settings_menu.visible: return
	AudioManager.play_sfx(CLICK_SFX)
	settings_menu.open()

func _on_credits_button_pressed() -> void:
	if credits_label.visible: return
	
	AudioManager.play_sfx(CLICK_SFX)	
	settings_menu.close()
	
	credits_label.show()
	credits_label.position = CREDITS_START_POS
	
	var tween = create_tween()
	tween.tween_property(credits_label, "position", CREDITS_END_POS, CREDITS_DURATION)
	tween.finished.connect(func(): 
		credits_label.hide()
		_set_input_enabled(true)
	)

func _on_settings_hover() -> void:
	_play_anim(settings_button, "hover")

func _on_settings_exit() -> void:
	_play_anim(settings_button, "unhover")

func _on_exit_button_pressed() -> void:
	AudioManager.play_sfx(CLICK_SFX)
	await get_tree().create_timer(0.2).timeout 
	get_tree().quit()

func _play_anim(btn: Node, anim: String) -> void:
	var sprite = btn.get_node_or_null("AnimatedSprite2D")
	if sprite: sprite.play(anim)

func _set_input_enabled(state: bool) -> void:
	var mode = Control.MOUSE_FILTER_PASS if state else Control.MOUSE_FILTER_IGNORE
	sp_button.mouse_filter = mode
	mp_button.mouse_filter = mode
	exit_button.mouse_filter = mode
	settings_button.mouse_filter = mode

func _on_sp_button_pressed() -> void:
	_set_input_enabled(false)
	AudioManager.play_music(TRANSITION_MUSIC, "Music", false)
	
	GameState.game_mode = GameState.GameMode.SINGLEPLAYER
	
	color_fade.show()
	var tween = create_tween()
	tween.tween_property(color_fade, "modulate:a", 1.0, FADE_DURATION)
	tween.finished.connect(func(): get_tree().change_scene_to_file(LEVEL_SELECTION_SCENE))
	
func _on_mp_button_pressed() -> void:
	_set_input_enabled(false)
	AudioManager.play_music(TRANSITION_MUSIC, "Music", false)
	
	GameState.game_mode = GameState.GameMode.MULTIPLAYER
	
	color_fade.show()
	var tween = create_tween()
	tween.tween_property(color_fade, "modulate:a", 1.0, FADE_DURATION)
	tween.finished.connect(func(): get_tree().change_scene_to_file(MAP_SELECTION_SCENE))
