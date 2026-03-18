class_name TraitDraftSystem
extends RefCounted

const TraitDef = preload("res://scripts/data/trait_def.gd")

func build_global_choices(run_state: RunState, count: int = 3) -> Array[TraitDef]:
	var available: Array[TraitDef] = []
	for trait_def in GameData.get_global_traits():
		if _is_trait_available(run_state, trait_def):
			available.append(trait_def)
	return _pick_random_choices(run_state.rng, available, count)

func build_evolution_choices(run_state: RunState, hero_id: String, count: int = 3) -> Array[TraitDef]:
	var available: Array[TraitDef] = []
	for trait_def in GameData.get_evolution_traits_for_hero(hero_id):
		if _is_trait_available(run_state, trait_def):
			available.append(trait_def)
	return _pick_random_choices(run_state.rng, available, count)

func _is_trait_available(run_state: RunState, trait_def: TraitDef) -> bool:
	if run_state.has_trait(trait_def.id):
		return false
	for trait_id in trait_def.mutually_exclusive:
		if run_state.has_trait(trait_id):
			return false
	return true

func _pick_random_choices(rng: RandomNumberGenerator, source: Array[TraitDef], count: int) -> Array[TraitDef]:
	var pool: Array[TraitDef] = []
	for trait_def in source:
		pool.append(trait_def)
	var result: Array[TraitDef] = []
	while not pool.is_empty() and result.size() < count:
		var index: int = rng.randi_range(0, pool.size() - 1)
		result.append(pool[index])
		pool.remove_at(index)
	return result