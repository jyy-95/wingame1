class_name SummonEconomySystem
extends RefCounted

const BASE_COST := 10
const STEP_COST := 2
const MAX_COST := 30

func current_cost(run_state: RunState) -> int:
	var dynamic_cost := mini(MAX_COST, BASE_COST + (run_state.summon_count * STEP_COST))
	var trait_discount := 2 if run_state.has_trait("golden_contract") else 0
	var event_discount := run_state.summon_discount_value if run_state.summon_discount_charges > 0 else 0
	return maxi(1, dynamic_cost - trait_discount - event_discount)

func can_summon(run_state: RunState) -> bool:
	return run_state.free_summons > 0 or run_state.gold >= current_cost(run_state)

func pay_for_summon(run_state: RunState) -> int:
	if run_state.free_summons > 0:
		run_state.free_summons -= 1
		return 0
	var cost := current_cost(run_state)
	if not run_state.spend_gold(cost):
		return -1
	run_state.summon_count += 1
	if run_state.summon_discount_charges > 0:
		run_state.summon_discount_charges -= 1
		if run_state.summon_discount_charges <= 0:
			run_state.summon_discount_value = 0
	return cost

func sell_refund(run_state: RunState, purchase_value: int) -> int:
	var ratio := 0.5
	if run_state.has_trait("salvage"):
		ratio = 0.8
	return int(round(purchase_value * ratio))
