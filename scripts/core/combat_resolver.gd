class_name CombatResolver
extends RefCounted

const EnemyActor = preload("res://scripts/ui/enemy_actor.gd")
const HeroPiece = preload("res://scripts/ui/hero_piece.gd")
const PieceStats = preload("res://scripts/core/piece_stats.gd")

func process(delta: float, battle_root: Node) -> void:
	var enemies: Array[EnemyActor] = battle_root.get_active_enemies()
	if enemies.is_empty():
		return
	for piece: HeroPiece in battle_root.board_manager.get_active_pieces():
		piece.cooldown_remaining -= delta
		if piece.cooldown_remaining > 0.0:
			continue
		var stats: PieceStats = battle_root.get_piece_combat_stats(piece)
		var target: EnemyActor = _pick_target(piece, enemies, stats)
		if target == null:
			piece.cooldown_remaining = 0.15
			continue
		_execute_attack(piece, target, enemies, stats, battle_root)
		piece.cooldown_remaining = maxf(0.08, stats.attack_interval)

func _pick_target(piece: HeroPiece, enemies: Array[EnemyActor], stats: PieceStats) -> EnemyActor:
	var piece_position: Vector2 = piece.get_global_rect().get_center()
	var target: EnemyActor = null
	var best_distance := INF
	for enemy: EnemyActor in enemies:
		var distance := piece_position.distance_to(enemy.get_global_rect().get_center())
		if distance > stats.attack_range:
			continue
		if distance < best_distance:
			best_distance = distance
			target = enemy
	return target

func _execute_attack(piece: HeroPiece, target: EnemyActor, enemies: Array[EnemyActor], stats: PieceStats, battle_root: Node) -> void:
	var targets: Array[EnemyActor] = [target]
	if stats.mode == "pierce":
		var pierce_total := 1 + stats.pierce_targets
		for enemy: EnemyActor in enemies:
			if enemy == target:
				continue
			if enemy.position.y >= target.position.y and targets.size() < pierce_total:
				targets.append(enemy)
	elif stats.chain_hits > 0:
		var nearby: Array[EnemyActor] = enemies.duplicate()
		nearby.sort_custom(func(a: EnemyActor, b: EnemyActor): return a.position.distance_to(target.position) < b.position.distance_to(target.position))
		for enemy: EnemyActor in nearby:
			if enemy == target:
				continue
			if targets.size() > stats.chain_hits:
				break
			targets.append(enemy)
	for enemy: EnemyActor in targets:
		_apply_damage(piece, enemy, stats, battle_root, enemy != target)
	if stats.mode == "splash":
		for enemy: EnemyActor in enemies:
			if enemy == target:
				continue
			if enemy.position.distance_to(target.position) <= stats.splash_radius:
				_apply_damage(piece, enemy, stats, battle_root, true)

func _apply_damage(piece: HeroPiece, enemy: EnemyActor, stats: PieceStats, battle_root: Node, reduced: bool) -> void:
	var damage: float = stats.damage * (0.72 if reduced else 1.0)
	if enemy.get_health_ratio() > 0.75:
		damage *= 1.0 + stats.healthy_damage_pct
	if enemy.freeze_time > 0.0:
		damage *= 1.0 + stats.bonus_vs_frozen
	if enemy.armor > 0.0:
		damage *= 1.0 + stats.bonus_vs_armor
	if piece.last_target_instance_id == enemy.get_instance_id():
		piece.combo_stacks += 1
	else:
		piece.combo_stacks = 0
		piece.last_target_instance_id = enemy.get_instance_id()
	damage *= 1.0 + (piece.combo_stacks * stats.combo_pct)
	var execute_threshold := stats.execute_threshold
	if enemy.get_health_ratio() <= execute_threshold:
		damage *= 3.0
	var did_crit: bool = battle_root.run_state.rng.randf() <= stats.crit_chance
	if did_crit:
		damage *= 1.75 + stats.crit_damage_bonus
	var dealt: float = enemy.apply_damage(damage)
	battle_root.run_state.register_damage(piece.get_display_label(), dealt)
	var totem_effect: Dictionary = battle_root.totem_system.consume_hit_effect(battle_root.run_state, int(stats.totem_charge_on_hit))
	var poison_total: float = stats.poison_dps + float(totem_effect.get("poison_dps", 0.0))
	if poison_total > 0.0:
		enemy.apply_poison(poison_total, 2.5)
	var freeze_duration: float = 0.0
	if battle_root.run_state.rng.randf() <= stats.freeze_chance:
		freeze_duration = maxf(freeze_duration, 0.55 * (1.0 + stats.freeze_duration_pct))
	freeze_duration = maxf(freeze_duration, float(totem_effect.get("freeze_duration", 0.0)))
	if freeze_duration > 0.0:
		enemy.apply_freeze(freeze_duration)
	if stats.slow_chance > 0.0 and battle_root.run_state.rng.randf() <= stats.slow_chance:
		enemy.apply_slow(stats.slow_pct, 1.4)
	if stats.push_chance > 0.0 and battle_root.run_state.rng.randf() <= stats.push_chance:
		enemy.apply_push(stats.push_distance)
	if did_crit and stats.crit_splash_radius > 0.0:
		for splash_enemy: EnemyActor in battle_root.get_active_enemies():
			if splash_enemy == enemy:
				continue
			if splash_enemy.position.distance_to(enemy.position) <= stats.crit_splash_radius:
				var splash_damage: float = splash_enemy.apply_damage(damage * stats.crit_splash_pct)
				battle_root.run_state.register_damage(piece.get_display_label(), splash_damage)
	if battle_root.has_method("show_hit_feedback"):
		battle_root.call("show_hit_feedback", piece, enemy, dealt, {
			"mode": stats.mode,
			"crit": did_crit,
			"freeze": freeze_duration > 0.0,
			"poison": poison_total > 0.0,
			"reduced": reduced,
		})
