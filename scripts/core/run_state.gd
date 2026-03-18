class_name RunState
extends RefCounted

const TraitDef = preload("res://scripts/data/trait_def.gd")

var seed := 0
var stage_id := ""
var stage_index := 0
var rng := RandomNumberGenerator.new()
var gold := 35
var base_hp := 24
var max_base_hp := 24
var rerolls := 1
var current_wave_index := -1
var summon_count := 0
var total_kills := 0
var kill_haste_stacks := 0
var active_global_traits: Array[TraitDef] = []
var active_evolution_traits: Dictionary = {}
var unlocked_evolution_breakpoints: Dictionary = {}
var totem_id := ""
var totem_level := 1
var free_summons := 0
var summon_discount_value := 0
var summon_discount_charges := 0
var next_wave_bombard_damage := 0.0
var next_wave_bonus_haste := 0.0
var next_wave_bonus_damage := 0.0
var next_wave_bonus_elite_reward := 0
var next_wave_has_bonus_elite := false
var damage_stats: Dictionary = {}
var totem_hit_counter := 0

func _init(seed_value: int = 0, in_stage_id: String = "", in_stage_index: int = 0) -> void:
	seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())
	stage_id = in_stage_id
	stage_index = in_stage_index
	rng.seed = seed

func add_global_trait(trait_def: TraitDef) -> void:
	active_global_traits.append(trait_def)

func add_evolution_trait(hero_id: String, star_level: int, trait_def: TraitDef) -> void:
	if not active_evolution_traits.has(hero_id):
		active_evolution_traits[hero_id] = []
	active_evolution_traits[hero_id].append(trait_def)
	mark_evolution_breakpoint(hero_id, star_level)

func mark_evolution_breakpoint(hero_id: String, star_level: int) -> void:
	if not unlocked_evolution_breakpoints.has(hero_id):
		unlocked_evolution_breakpoints[hero_id] = []
	if not unlocked_evolution_breakpoints[hero_id].has(star_level):
		unlocked_evolution_breakpoints[hero_id].append(star_level)

func needs_evolution_draft(hero_id: String, star_level: int) -> bool:
	if star_level != 3 and star_level != 5:
		return false
	if not unlocked_evolution_breakpoints.has(hero_id):
		return true
	return not unlocked_evolution_breakpoints[hero_id].has(star_level)

func get_traits_for_hero(hero_id: String) -> Array[TraitDef]:
	var result: Array[TraitDef] = []
	if not active_evolution_traits.has(hero_id):
		return result
	for trait_def in active_evolution_traits[hero_id]:
		result.append(trait_def as TraitDef)
	return result

func has_trait(trait_id: String) -> bool:
	for trait_def in active_global_traits:
		if trait_def.id == trait_id:
			return true
	for hero_id in active_evolution_traits.keys():
		for trait_def in active_evolution_traits[hero_id]:
			if trait_def.id == trait_id:
				return true
	return false

func add_gold(amount: int) -> void:
	gold += amount

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true

func add_base_hp(amount: int) -> void:
	base_hp = mini(max_base_hp, base_hp + amount)

func lose_base_hp(amount: int) -> void:
	base_hp = maxi(0, base_hp - amount)

func register_damage(source_label: String, amount: float) -> void:
	damage_stats[source_label] = damage_stats.get(source_label, 0.0) + amount

func register_kill() -> void:
	total_kills += 1
	if has_trait("battlefield_rhythm") and total_kills % 5 == 0:
		kill_haste_stacks = mini(10, kill_haste_stacks + 1)

func consume_wave_modifiers() -> Dictionary:
	var payload: Dictionary = {
		"bombard": next_wave_bombard_damage,
		"wave_haste": next_wave_bonus_haste,
		"wave_damage": next_wave_bonus_damage,
		"bonus_elite": next_wave_has_bonus_elite,
		"bonus_elite_reward": next_wave_bonus_elite_reward
	}
	next_wave_bombard_damage = 0.0
	next_wave_bonus_haste = 0.0
	next_wave_bonus_damage = 0.0
	next_wave_has_bonus_elite = false
	next_wave_bonus_elite_reward = 0
	return payload