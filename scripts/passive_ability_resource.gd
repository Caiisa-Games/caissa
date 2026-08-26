class_name PassiveAbilityResource
extends Resource

@export var id: String
@export var name: String
@export_multiline var description: String
@export var script_effect: Script

func create_effect_instance() -> PassiveEffect:
	if script_effect and script_effect.can_instantiate():
		return script_effect.new() as PassiveEffect
	return null
