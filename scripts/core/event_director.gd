class_name EventDirector
extends RefCounted

func pick_event(run_state: RunState) -> EventDef:
	var pool: Array[EventDef] = GameData.get_randomizable_events()
	if pool.is_empty():
		return null
	var total_weight: int = 0
	for event_def in pool:
		total_weight += event_def.weight
	var roll: int = run_state.rng.randi_range(1, total_weight)
	var cursor: int = 0
	for event_def in pool:
		cursor += event_def.weight
		if roll <= cursor:
			return event_def
	return pool[0]

func apply_option(run_state: RunState, option: Dictionary, battle_root: Node) -> void:
	match option.get("effect", ""):
		"summon_discount_buff":
			run_state.summon_discount_value = int(option.get("value", 0))
			run_state.summon_discount_charges = int(option.get("charges", 0))
		"gain_gold":
			run_state.add_gold(int(option.get("value", 0)))
		"totem_level":
			run_state.totem_level += int(option.get("value", 0))
		"gold_and_heal":
			run_state.add_gold(int(option.get("gold", 0)))
			run_state.add_base_hp(int(option.get("heal", 0)))
		"next_wave_bombard":
			run_state.next_wave_bombard_damage += float(option.get("value", 0.0))
		"gain_reroll":
			run_state.rerolls += int(option.get("value", 0))
		"wave_haste":
			run_state.next_wave_bonus_haste += float(option.get("value", 0.0))
		"elite_contract":
			run_state.next_wave_has_bonus_elite = true
			run_state.next_wave_bonus_elite_reward += int(option.get("value", 0))
		"free_summon":
			run_state.free_summons += int(option.get("value", 0))
		"heal_core":
			run_state.add_base_hp(int(option.get("value", 0)))
		"wave_damage":
			run_state.next_wave_bonus_damage += float(option.get("value", 0.0))
		"totem_and_gold":
			run_state.totem_level += int(option.get("totem", 0))
			run_state.add_gold(int(option.get("gold", 0)))
	if battle_root.has_method("add_log"):
		battle_root.call("add_log", "%s: %s" % [option.get("label", Localization.text("event_default")), option.get("description", "")])