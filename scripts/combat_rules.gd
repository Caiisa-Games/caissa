class_name CombatRules

static func calculate_damage(
	attacker_power: int, 
	height_delta: int, 
	is_critical: bool = false
) -> int:
	
	var raw_damage = attacker_power

	var height_multiplier = 0.25 * clamp(height_delta, -3, 3)
	raw_damage *= (1 + height_multiplier)
	
	if is_critical:
		raw_damage = int(raw_damage * 1.5)
	
	return max(1, raw_damage)

static func is_within_range(attacker_pos: Vector2i, target_pos: Vector2i, attack_range: int) -> bool:
	var dx = abs(attacker_pos.x - target_pos.x)
	var dy = abs(attacker_pos.y - target_pos.y)
	var distance = max(dx, dy)
	return distance <= attack_range


static func apply_combat_damage(
	attacker: Occupant, 
	target: Occupant, 
	base_damage: int, 
	board: BoardManager, 
	battle_manager: BattleManager
) -> bool:
	if target == null or target.piece_data == null:
		return false

	var dmg: int = base_damage
	var mitigated := 0

	if attacker and attacker.piece_data and attacker.piece_data.passive_ability:
		var atk_passive = attacker.piece_data.passive_ability.create_effect_instance()
		if atk_passive:
			dmg = atk_passive.modify_outgoing_damage(attacker, dmg, target, board)

	if target and target.piece_data and target.piece_data.passive_ability:
		var def_passive = target.piece_data.passive_ability.create_effect_instance()
		if def_passive:
			dmg = def_passive.modify_incoming_damage(target, dmg, board)

	if target.has_status("guarded"):
		var guard_data = target.get_status_data("guarded")
		mitigated = int(dmg * float(guard_data.get("percent", 0.35)))
		dmg -= mitigated
		target.consume_status_on_hit("guarded")
		print_debug("MITIGATED", mitigated)

	dmg = max(dmg, 0)
	var target_tile := target.get_parent().get_parent() as Tile
	var is_kill := dmg > 0 and dmg >= target.current_hp
	if dmg > 0 and battle_manager and target_tile:
		await battle_manager.play_damage_impact(target_tile, is_kill)

	var died: bool = await target.take_damage(dmg, mitigated > 0)

	if attacker and attacker.piece_data and attacker.piece_data.passive_ability:
		var atk_passive2 = attacker.piece_data.passive_ability.create_effect_instance()
		if atk_passive2:
			atk_passive2.on_damage_dealt(attacker, dmg, target, board)

	if died and attacker and attacker.piece_data and attacker.piece_data.passive_ability:
		var atk_passive3 = attacker.piece_data.passive_ability.create_effect_instance()
		if atk_passive3:
			atk_passive3.on_kill(attacker, board, battle_manager)

	return died
