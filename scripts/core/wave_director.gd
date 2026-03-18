class_name WaveDirector
extends RefCounted

const WaveDef = preload("res://scripts/data/wave_def.gd")

var stage: StageDef
var current_wave: WaveDef
var current_wave_index := -1
var remaining_spawns := 0
var spawn_timer := 0.0
var active := false
var modifiers: Dictionary = {}

func setup(stage_def: StageDef) -> void:
	stage = stage_def
	current_wave = null
	current_wave_index = -1
	remaining_spawns = 0
	spawn_timer = 0.0
	active = false
	modifiers = {}

func start_wave(wave_index: int, run_state: RunState) -> void:
	current_wave_index = wave_index
	current_wave = stage.wave_defs[wave_index]
	remaining_spawns = current_wave.spawn_count
	spawn_timer = 0.05
	active = true
	modifiers = run_state.consume_wave_modifiers()

func update(delta: float, battle_root: Node) -> void:
	if not active or current_wave == null:
		return
	spawn_timer -= delta
	while remaining_spawns > 0 and spawn_timer <= 0.0:
		spawn_timer += current_wave.spawn_interval
		var enemy_id: String = current_wave.enemy_ids[battle_root.run_state.rng.randi_range(0, current_wave.enemy_ids.size() - 1)]
		battle_root.spawn_enemy(enemy_id)
		remaining_spawns -= 1
	if remaining_spawns <= 0 and current_wave.boss_id != "" and not battle_root.boss_spawned:
		battle_root.spawn_enemy(current_wave.boss_id, true)
		battle_root.boss_spawned = true
	if bool(modifiers.get("bonus_elite", false)) and not battle_root.bonus_elite_spawned:
		battle_root.bonus_elite_spawned = true
		battle_root.spawn_enemy("juggernaut")
	if float(modifiers.get("bombard", 0.0)) > 0.0 and not battle_root.wave_bombard_applied:
		battle_root.apply_wave_bombard(float(modifiers.get("bombard", 0.0)))
		battle_root.wave_bombard_applied = true
	if remaining_spawns <= 0 and battle_root.get_active_enemy_count() == 0 and (current_wave.boss_id == "" or battle_root.boss_spawned):
		active = false

func is_wave_complete(battle_root: Node) -> bool:
	return not active and current_wave != null and remaining_spawns <= 0 and battle_root.get_active_enemy_count() == 0