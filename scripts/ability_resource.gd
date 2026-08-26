class_name AbilityResource
extends Resource

enum TargetType { SELF, SINGLE_ENEMY, SINGLE_ALLY, AOE_CROSS, AOE_RADIUS }

@export var id: String
@export var name: String
@export_multiline var description: String
@export var energy_cost: int
@export var target_type: TargetType
@export var range: int = 1
@export var script_effect: Script # Custom script

@export_group("Animations")
@export var anim_frames_white: SpriteFrames
@export var anim_frames_black: SpriteFrames
@export var impact_frame_index: int = 2

func create_effect_instance() -> AbilityEffect:
	if script_effect and script_effect.can_instantiate():
		return script_effect.new() as AbilityEffect
	return null
