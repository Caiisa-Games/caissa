class_name SettingsData
extends Resource

const MASTER_MUTED := false
const MUSIC_MUTED := false
const SFX_MUTED := false
const DEFAULT_LOCALE := "en"

enum CameraEffectsMode { FULL, REDUCED, OFF }
const DEFAULT_CAMERA_EFFECTS_MODE := CameraEffectsMode.FULL

@export var master_muted: bool  = MASTER_MUTED
@export var music_muted: bool  = MUSIC_MUTED
@export var sfx_muted: bool  = SFX_MUTED
@export var locale: String = DEFAULT_LOCALE
@export var camera_effects_mode: int = DEFAULT_CAMERA_EFFECTS_MODE
