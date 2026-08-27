extends Node

signal settings_changed(data: SettingsData)
signal mute_changed(bus: String, is_muted: bool)
signal locale_changed(locale: String)
signal camera_effects_mode_changed(mode: int)

const SAVE_PATH := "user://settings.cfg"
const SECTION := "settings"

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

var data := SettingsData.new()

func _ready() -> void:
	load_settings()
	_apply_all()

func set_muted(bus: String, is_muted: bool) -> void:
	match bus:
		BUS_MASTER: data.master_muted = is_muted
		BUS_MUSIC: data.music_muted = is_muted
		BUS_SFX: data.sfx_muted = is_muted
	
	_apply_mute_state(bus, is_muted)
	mute_changed.emit(bus, is_muted)
	save_settings()

func set_locale(locale: String) -> void:
	data.locale = locale
	TranslationServer.set_locale(locale)
	locale_changed.emit(locale)
	save_settings()

func set_camera_effects_mode(mode: int) -> void:
	data.camera_effects_mode = clampi(mode, SettingsData.CameraEffectsMode.FULL, SettingsData.CameraEffectsMode.OFF)
	camera_effects_mode_changed.emit(data.camera_effects_mode)
	save_settings()

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "master_muted", data.master_muted)
	cfg.set_value(SECTION, "music_muted", data.music_muted)
	cfg.set_value(SECTION, "sfx_muted", data.sfx_muted)
	cfg.set_value(SECTION, "locale", data.locale)
	cfg.set_value(SECTION, "camera_effects_mode", data.camera_effects_mode)
	cfg.save(SAVE_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	
	data.master_muted = cfg.get_value(SECTION, "master_muted", data.MASTER_MUTED)
	data.music_muted  = cfg.get_value(SECTION, "music_muted", data.MUSIC_MUTED)
	data.sfx_muted    = cfg.get_value(SECTION, "sfx_muted", data.SFX_MUTED)
	data.locale       = cfg.get_value(SECTION, "locale", "en")
	data.camera_effects_mode = clampi(
		int(cfg.get_value(SECTION, "camera_effects_mode", data.DEFAULT_CAMERA_EFFECTS_MODE)),
		SettingsData.CameraEffectsMode.FULL,
		SettingsData.CameraEffectsMode.OFF
	)

func _apply_all() -> void:
	_apply_mute_state(BUS_MASTER, data.master_muted)
	_apply_mute_state(BUS_MUSIC, data.music_muted)
	_apply_mute_state(BUS_SFX, data.sfx_muted)
	TranslationServer.set_locale(data.locale)

func _apply_mute_state(bus: String, is_muted: bool) -> void:
	var bus_idx := AudioServer.get_bus_index(bus)
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, is_muted)

func reset_to_defaults() -> void:
	data = SettingsData.new()
	_apply_all()
	save_settings()
	settings_changed.emit(data)
