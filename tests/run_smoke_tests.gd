extends SceneTree

const RunState = preload("res://scripts/core/run_state.gd")
const SummonEconomySystem = preload("res://scripts/core/summon_economy_system.gd")
const TraitDraftSystem = preload("res://scripts/core/trait_draft_system.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	_smoke_game_data(failures)
	_smoke_economy(failures)
	_smoke_traits(failures)
	_smoke_evolution_gate(failures)
	if failures.is_empty():
		print("Smoke tests passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)

func _smoke_game_data(failures: Array[String]) -> void:
	if GameData.heroes.size() != 8:
		failures.append("Expected 8 heroes")
	if GameData.totems.size() != 3:
		failures.append("Expected 3 totems")
	if GameData.stages.size() != 15:
		failures.append("Expected 15 stages")

func _smoke_economy(failures: Array[String]) -> void:
	var run_state := RunState.new(1234)
	var economy := SummonEconomySystem.new()
	if economy.current_cost(run_state) != 10:
		failures.append("Initial summon cost should be 10")
	run_state.summon_count = 5
	if economy.current_cost(run_state) <= 10:
		failures.append("Summon cost should scale upward")
	run_state.free_summons = 1
	if economy.pay_for_summon(run_state) != 0:
		failures.append("Free summon should cost 0")

func _smoke_traits(failures: Array[String]) -> void:
	var run_state := RunState.new(9876)
	var draft_system := TraitDraftSystem.new()
	var choices := draft_system.build_global_choices(run_state)
	if choices.size() != 3:
		failures.append("Expected 3 global trait choices")
	var ids := {}
	for choice in choices:
		if ids.has(choice.id):
			failures.append("Duplicate trait choice detected")
		ids[choice.id] = true

func _smoke_evolution_gate(failures: Array[String]) -> void:
	var run_state := RunState.new(42)
	if not run_state.needs_evolution_draft("ember_mage", 3):
		failures.append("3-star should request evolution draft initially")
	run_state.mark_evolution_breakpoint("ember_mage", 3)
	if run_state.needs_evolution_draft("ember_mage", 3):
		failures.append("3-star draft should only happen once per hero")