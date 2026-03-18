class_name TotemSystem
extends RefCounted

const TotemDef = preload("res://scripts/data/totem_def.gd")

func get_selected_totem(run_state: RunState) -> TotemDef:
	return GameData.totems.get(run_state.totem_id) as TotemDef

func get_passive_modifiers(run_state: RunState) -> Dictionary:
	var modifiers: Dictionary = {}
	var totem: TotemDef = get_selected_totem(run_state)
	if totem == null:
		return modifiers
	var power_scale: float = 1.0 + _get_power_bonus(run_state)
	match totem.effect_id:
		"crit":
			modifiers["crit_chance"] = totem.base_value * power_scale
			modifiers["crit_damage"] = (0.45 + (totem.level_step * float(run_state.totem_level - 1))) * power_scale
	return modifiers

func consume_hit_effect(run_state: RunState, extra_charge: int = 0) -> Dictionary:
	var totem: TotemDef = get_selected_totem(run_state)
	if totem == null:
		return {}
	run_state.totem_hit_counter += 1 + extra_charge
	var power_scale: float = 1.0 + _get_power_bonus(run_state)
	if totem.effect_id == "poison" and run_state.totem_hit_counter % 6 == 0:
		return {"poison_dps": (totem.base_value + (run_state.totem_level - 1) * totem.level_step) * power_scale}
	if totem.effect_id == "freeze" and run_state.totem_hit_counter % 8 == 0:
		return {"freeze_duration": (totem.base_value + (run_state.totem_level - 1) * totem.level_step) * power_scale}
	return {}

func _get_power_bonus(run_state: RunState) -> float:
	var bonus: float = 0.0
	if run_state.has_trait("crystal_focus"):
		bonus += 0.2
	return bonus