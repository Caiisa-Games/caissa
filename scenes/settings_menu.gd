class_name SettingsMenu
extends CanvasLayer

signal closed

const CLICK_SFX := preload("res://assets/sound/فشردن دکمه های سنگی.mp3")
const ANIM_DURATION := 0.5

@onready var overlay: Panel = $Overlay
@onready var tray: PanelContainer = $Tray

@onready var music_slider: VolumeSlider = $Tray/Margin/Content/AudioSection/MusicMute
@onready var sfx_slider: VolumeSlider = $Tray/Margin/Content/AudioSection/SFXMute
@onready var lang_picker: LanguagePicker = $Tray/Margin/Content/LanguageSection/LanguagePicker
@onready var camera_effects_picker: OptionButton = $Tray/Margin/Content/CameraEffectsSection/CameraEffectsPicker

var is_animating: bool = false

func _ready() -> void:
	visible = false
	overlay.modulate.a = 0
	tray.scale = Vector2.ZERO
	_configure_camera_effects_picker()
	camera_effects_picker.item_selected.connect(_on_camera_effects_selected)
	SettingsManager.locale_changed.connect(_on_locale_changed)
	_sync_ui_with_settings()

func _sync_ui_with_settings() -> void:
	music_slider.check_button.button_pressed = not SettingsManager.data.music_muted
	sfx_slider.check_button.button_pressed = not SettingsManager.data.sfx_muted
	camera_effects_picker.select(SettingsManager.data.camera_effects_mode)

func _configure_camera_effects_picker() -> void:
	camera_effects_picker.clear()
	camera_effects_picker.add_item(tr("camera_effects_full"), SettingsData.CameraEffectsMode.FULL)
	camera_effects_picker.add_item(tr("camera_effects_reduced"), SettingsData.CameraEffectsMode.REDUCED)
	camera_effects_picker.add_item(tr("camera_effects_off"), SettingsData.CameraEffectsMode.OFF)

func _on_locale_changed(_locale: String) -> void:
	_configure_camera_effects_picker()
	_sync_ui_with_settings()

func _on_camera_effects_selected(index: int) -> void:
	SettingsManager.set_camera_effects_mode(camera_effects_picker.get_item_id(index))

func open() -> void:
	if is_animating: return
	
	is_animating = true
	visible = true
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(overlay, "modulate:a", 1.0, ANIM_DURATION)
	tween.tween_property(tray, "scale", Vector2.ONE, ANIM_DURATION)
	
	tween.chain().finished.connect(func(): is_animating = false)

func close() -> void:
	if is_animating: return
	
	AudioManager.play_sfx(CLICK_SFX)
	is_animating = true
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(overlay, "modulate:a", 0.0, ANIM_DURATION)
	tween.tween_property(tray, "scale", Vector2.ZERO, ANIM_DURATION)
	
	tween.chain().finished.connect(func():
		is_animating = false
		visible = false
		closed.emit()
	)

func _on_mute_toggled(toggled_on: bool, bus_name: String) -> void:
	SettingsManager.set_muted(bus_name, toggled_on)

func _on_language_pressed(locale: String) -> void:
	SettingsManager.set_locale(locale)
	_sync_ui_with_settings()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and not is_animating and event.is_pressed() and not event.is_echo() and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
