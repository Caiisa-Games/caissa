class_name PieceData
extends Resource

enum PieceClass { TANK, BERSERKER, UTILITY }

@export_group("Info")
@export var name: String
@export var description: String

@export_group("Visuals")
@export var texture_white: Texture2D
@export var texture_black: Texture2D
@export var card_texture: Texture2D

@export_group("Stats")
@export var knockback: int = 1
@export var power: int = 1
@export var defense: int = 1

@export_group("Movement")
@export var movement: MovementData

@export_group("Classification")
@export var piece_class: PieceClass

@export_group("Abilities")
@export var active_ability: AbilityResource
@export var passive_ability: PassiveAbilityResource
