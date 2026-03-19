extends Node

var heroes: Dictionary = {}
var enemies: Dictionary = {}
var global_traits: Array[TraitDef] = []
var evolution_traits: Array[TraitDef] = []
var totems: Dictionary = {}
var events: Array[EventDef] = []
var stages: Array[StageDef] = []

func _ready() -> void:
	rebuild()

func rebuild() -> void:
	heroes.clear()
	enemies.clear()
	global_traits.clear()
	evolution_traits.clear()
	totems.clear()
	events.clear()
	stages.clear()
	_build_heroes()
	_build_enemies()
	_build_traits()
	_build_totems()
	_build_events()
	_build_stages()

func get_stage_list() -> Array[StageDef]:
	return stages

func get_stage(stage_id: String) -> StageDef:
	for stage in stages:
		if stage.id == stage_id:
			return stage
	return stages[0]

func get_global_traits() -> Array[TraitDef]:
	return global_traits

func get_evolution_traits_for_hero(hero_id: String) -> Array[TraitDef]:
	var result: Array[TraitDef] = []
	for trait_def in evolution_traits:
		if trait_def.hero_ids.has(hero_id):
			result.append(trait_def)
	return result

func get_randomizable_events() -> Array[EventDef]:
	return events

func get_totem_choices_for_stage(stage: StageDef) -> Array[TotemDef]:
	var result: Array[TotemDef] = []
	for totem_id in totems.keys():
		var id_text: String = str(totem_id)
		if stage.banned_totem_ids.has(id_text):
			continue
		result.append(totems[id_text] as TotemDef)
	return result

func get_hero(hero_id: String) -> HeroDef:
	return heroes.get(hero_id) as HeroDef

func get_enemy(enemy_id: String) -> EnemyDef:
	return enemies.get(enemy_id) as EnemyDef

func get_totem(totem_id: String) -> TotemDef:
	return totems.get(totem_id) as TotemDef

func get_event(event_id: String) -> EventDef:
	for event_def in events:
		if event_def.id == event_id:
			return event_def
	return null

func get_trait_by_id(trait_id: String) -> TraitDef:
	for trait_def in global_traits:
		if trait_def.id == trait_id:
			return trait_def
	for trait_def in evolution_traits:
		if trait_def.id == trait_id:
			return trait_def
	return null

func _txt(en_text: String, zh_text: String) -> String:
	if Localization.is_chinese():
		return zh_text
	return en_text

func _to_string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	return result

func _build_heroes() -> void:
	for hero_def in [
		_make_hero("ember_mage", _txt("Ember Mage", "烬火法师"), "striker", "single", Color("ff7b54"), 14.0, 0.95, 2000.0, 0.0, ["burn", "crit"], ["fire", "burst"]),
		_make_hero("frost_oracle", _txt("Frost Oracle", "霜语先知"), "control", "single", Color("7fd4ff"), 10.0, 1.1, 2000.0, 0.0, ["freeze", "slow"], ["ice", "control"]),
		_make_hero("tide_guard", _txt("Tide Guard", "潮汐卫士"), "vanguard", "splash", Color("4ca6ff"), 11.0, 1.2, 2000.0, 55.0, ["armor", "wave"], ["water", "front"]),
		_make_hero("blade_dancer", _txt("Blade Dancer", "刃舞者"), "striker", "single", Color("ffe082"), 16.0, 0.85, 2000.0, 0.0, ["execute", "combo"], ["blade", "burst"]),
		_make_hero("venom_sage", _txt("Venom Sage", "蚀毒贤者"), "control", "single", Color("82d173"), 9.0, 0.9, 2000.0, 0.0, ["poison", "amplify"], ["poison", "dot"]),
		_make_hero("storm_caller", _txt("Storm Caller", "风暴召唤师"), "striker", "splash", Color("c8a2ff"), 13.0, 1.15, 2000.0, 70.0, ["chain", "storm"], ["storm", "aoe"]),
		_make_hero("iron_warden", _txt("Iron Warden", "铁壁守卫"), "vanguard", "single", Color("b0bec5"), 12.0, 1.05, 2000.0, 0.0, ["guard", "wall"], ["tank", "front"]),
		_make_hero("solar_priest", _txt("Solar Priest", "曜光祭司"), "striker", "pierce", Color("ffd166"), 12.5, 1.0, 2000.0, 0.0, ["solar", "focus"], ["light", "support"])
	]:
		heroes[hero_def.id] = hero_def

func _build_enemies() -> void:
	var specs: Array = [
		["slime", _txt("Stone Slime", "岩壳史莱姆"), "90c978", 55.0, 20.0, 0.0, 4, 1, false, ["grunt"]],
		["scout", _txt("Spike Scout", "尖刺斥候"), "f4d35e", 42.0, 25.0, 0.0, 4, 1, false, ["fast"]],
		["shell", _txt("Shell Guard", "壳甲守卫"), "8d99ae", 90.0, 18.0, 8.0, 5, 1, false, ["armor"]],
		["mender", _txt("Brood Mender", "巢群医者"), "52b788", 84.0, 16.0, 0.0, 6, 1, false, ["regen"]],
		["spitter", _txt("Acid Spitter", "酸液喷吐者"), "b56576", 68.0, 22.0, 2.0, 5, 1, false, ["acid"]],
		["crusher", _txt("Rift Crusher", "裂隙粉碎者"), "6d597a", 138.0, 15.0, 10.0, 7, 2, false, ["elite"]],
		["phantom", _txt("Phase Phantom", "相位幽灵"), "9d4edd", 58.0, 28.0, 4.0, 6, 1, false, ["phase"]],
		["healer", _txt("Spirit Healer", "灵能医师"), "84a59d", 74.0, 14.0, 0.0, 6, 1, false, ["support"]],
		["juggernaut", _txt("Juggernaut", "铁甲巨兽"), "495057", 185.0, 12.0, 16.0, 9, 2, false, ["elite", "armor"]],
		["wyrm_boss", _txt("Tidal Wyrm", "潮汐巨龙"), "277da1", 620.0, 10.0, 8.0, 35, 3, true, ["boss"]],
		["lich_boss", _txt("Frost Lich", "霜魂巫妖"), "8ecae6", 580.0, 8.0, 4.0, 35, 3, true, ["boss"]],
		["forge_boss", _txt("Forge Warden", "熔炉典狱官"), "e76f51", 700.0, 6.0, 12.0, 40, 3, true, ["boss", "armor"]]
	]
	for spec in specs:
		var enemy_def: EnemyDef = EnemyDef.new()
		enemy_def.id = str(spec[0])
		enemy_def.display_name = str(spec[1])
		enemy_def.color = Color(str(spec[2]))
		enemy_def.max_hp = float(spec[3])
		enemy_def.speed = float(spec[4])
		enemy_def.armor = float(spec[5])
		enemy_def.reward = int(spec[6])
		enemy_def.contact_damage = int(spec[7])
		enemy_def.is_boss = bool(spec[8])
		enemy_def.tags = _to_string_array(spec[9] as Array)
		enemies[enemy_def.id] = enemy_def

func _build_traits() -> void:
	global_traits = [
		_make_global_trait("rapid_tempo", _txt("Rapid Tempo", "迅捷节奏"), _txt("All heroes gain 18 percent attack speed.", "所有英雄获得 18% 攻击速度。"), {"attack_speed_pct": 0.18}),
		_make_global_trait("sharpsight", _txt("Sharpsight", "锐目锁定"), _txt("All heroes gain 40 range.", "所有英雄获得 40 射程。"), {"range_flat": 40.0}),
		_make_global_trait("lucky_payday", _txt("Lucky Payday", "幸运结算"), _txt("Gain 12 extra gold after each wave.", "每波结束额外获得 12 金币。"), {"wave_bonus_gold": 12}),
		_make_global_trait("king_weapon", _txt("King Weapon", "王者兵装"), _txt("All heroes gain crit chance and crit damage.", "所有英雄获得暴击率和暴击伤害。"), {"crit_chance": 0.12, "crit_damage": 0.35}),
		_make_global_trait("frost_harbor", _txt("Frost Harbor", "霜港回响"), _txt("Freeze duration increased by 35 percent.", "冻结持续时间提高 35%。"), {"freeze_duration_pct": 0.35}),
		_make_global_trait("venom_reservoir", _txt("Venom Reservoir", "毒液储层"), _txt("Hits apply 5 poison damage per second.", "攻击附带每秒 5 点中毒伤害。"), {"poison_dps": 5.0}),
		_make_global_trait("focused_fire", _txt("Focused Fire", "集火指令"), _txt("Deal 20 percent more damage to healthy enemies.", "对高生命敌人额外造成 20% 伤害。"), {"healthy_damage_pct": 0.2}),
		_make_global_trait("finishing_blow", _txt("Finishing Blow", "终结一击"), _txt("Execute threshold increased by 8 percent.", "斩杀阈值提高 8%。"), {"execute_threshold": 0.08}),
		_make_global_trait("golden_contract", _txt("Golden Contract", "黄金契约"), _txt("Starting summon price reduced by 2.", "基础召唤价格降低 2。"), {"summon_discount": 2}),
		_make_global_trait("field_training", _txt("Field Training", "战地训练"), _txt("All heroes gain 4 base damage.", "所有英雄获得 4 点基础伤害。"), {"damage_flat": 4.0}),
		_make_global_trait("arc_echo", _txt("Arc Echo", "弧光回响"), _txt("AOE heroes gain 22 percent damage.", "范围型英雄伤害提高 22%。"), {"tag_damage:aoe": 0.22}),
		_make_global_trait("linebreaker", _txt("Linebreaker", "破阵穿透"), _txt("Pierce attacks deal 25 percent bonus damage.", "穿透攻击额外造成 25% 伤害。"), {"mode_damage:pierce": 0.25}),
		_make_global_trait("stability_core", _txt("Stability Core", "稳定核心"), _txt("Core HP plus 3.", "核心生命值 +3。"), {"core_hp": 3}),
		_make_global_trait("bounty_chain", _txt("Bounty Chain", "赏金连锁"), _txt("Elite and boss kills grant 15 extra gold.", "击杀精英和首领额外获得 15 金币。"), {"elite_bonus_gold": 15}),
		_make_global_trait("crystal_focus", _txt("Crystal Focus", "晶核专注"), _txt("Totem power increased by 20 percent.", "图腾强度提高 20%。"), {"totem_power_pct": 0.2}),
		_make_global_trait("mobilization", _txt("Mobilization", "紧急动员"), _txt("Start with 18 extra gold.", "开局额外获得 18 金币。"), {"starting_gold": 18}),
		_make_global_trait("battlefield_rhythm", _txt("Battlefield Rhythm", "战场节拍"), _txt("Every 5 kills grants stacking haste.", "每击杀 5 个敌人获得一层攻速。"), {"kill_haste_stack_pct": 0.02}),
		_make_global_trait("salvage", _txt("Salvage", "回收利用"), _txt("Selling units refunds 80 percent cost.", "出售单位返还 80% 花费。"), {"sell_refund_pct": 0.8})
	]
	evolution_traits = [
		_make_evo_trait("ember_superheat", _txt("Superheat", "超热爆燃"), _txt("Critical hits create a small explosion.", "暴击会引发小范围爆炸。"), "ember_mage", {"crit_splash_radius": 60.0, "crit_splash_pct": 0.5}),
		_make_evo_trait("ember_meteor", _txt("Meteor Fall", "陨星坠落"), _txt("Five star attacks become meteor blasts.", "五星后攻击变为陨石轰击。"), "ember_mage", {"mode_override": "splash", "damage_pct": 0.3, "splash_flat": 85.0}),
		_make_evo_trait("frost_deepfreeze", _txt("Deep Freeze", "深度冻结"), _txt("Freeze chance increased by 18 percent.", "冻结概率提高 18%。"), "frost_oracle", {"freeze_chance": 0.18}),
		_make_evo_trait("frost_shards", _txt("Frost Shards", "碎霜棱镜"), _txt("Frozen enemies take 28 percent more damage.", "被冻结的敌人额外承受 28% 伤害。"), "frost_oracle", {"bonus_vs_frozen": 0.28}),
		_make_evo_trait("tide_riptide", _txt("Riptide", "裂潮激流"), _txt("Splash radius increased by 45.", "溅射范围提高 45。"), "tide_guard", {"splash_flat": 45.0}),
		_make_evo_trait("tide_tsunami", _txt("Tsunami Wall", "海啸之墙"), _txt("Hits may push enemies backward.", "攻击有概率将敌人击退。"), "tide_guard", {"push_chance": 0.22, "push_distance": 28.0}),
		_make_evo_trait("blade_combo", _txt("Combo Rush", "连斩疾袭"), _txt("Repeated hits on the same target scale damage.", "连续攻击同一目标会叠加伤害。"), "blade_dancer", {"combo_pct": 0.12}),
		_make_evo_trait("blade_execution", _txt("Final Cut", "终幕裁断"), _txt("Execute threshold increased by 18 percent.", "斩杀阈值提高 18%。"), "blade_dancer", {"execute_threshold": 0.18}),
		_make_evo_trait("venom_corrosion", _txt("Corrosion", "腐蚀毒蚀"), _txt("Bonus damage against armored enemies.", "对护甲敌人额外造成伤害。"), "venom_sage", {"bonus_vs_armor": 0.3}),
		_make_evo_trait("venom_bloom", _txt("Venom Bloom", "毒花蔓延"), _txt("Poison spreads to nearby enemies.", "中毒会向附近敌人扩散。"), "venom_sage", {"poison_splash_radius": 75.0}),
		_make_evo_trait("storm_chain", _txt("Storm Chain", "雷链扩散"), _txt("Attacks chain two extra times.", "攻击额外连锁 2 次。"), "storm_caller", {"chain_hits": 2}),
		_make_evo_trait("storm_overload", _txt("Overload", "风暴过载"), _txt("Bonus damage against groups.", "对群体敌人造成更高伤害。"), "storm_caller", {"damage_pct": 0.25}),
		_make_evo_trait("warden_anchor", _txt("Anchor Line", "锚定防线"), _txt("Hits always apply a slow.", "攻击必定施加减速。"), "iron_warden", {"slow_chance": 1.0, "slow_pct": 0.25}),
		_make_evo_trait("warden_bulwark", _txt("Bulwark Echo", "壁垒回响"), _txt("Damage scales with missing core HP.", "伤害随核心损失生命提高。"), "iron_warden", {"damage_per_core_loss_pct": 0.1}),
		_make_evo_trait("solar_lance", _txt("Solar Lance", "曜光长枪"), _txt("Pierce gains one extra target.", "穿透攻击额外命中 1 个目标。"), "solar_priest", {"pierce_targets": 1}),
		_make_evo_trait("solar_hymn", _txt("Solar Hymn", "曜光圣咏"), _txt("Hits charge the totem.", "攻击会为图腾充能。"), "solar_priest", {"totem_charge_on_hit": 1.0})
	]

func _build_totems() -> void:
	for spec in [
		["poison_totem", _txt("Poison Totem", "毒系图腾"), _txt("Every sixth hit applies strong poison.", "每第 6 次命中附加强力中毒。"), "67c587", "poison", 8.0, 3.0],
		["crit_totem", _txt("Crit Totem", "暴击图腾"), _txt("Team gains crit chance and crit damage.", "全队获得暴击率和暴击伤害。"), "ffb703", "crit", 0.16, 0.12],
		["frost_totem", _txt("Frost Totem", "冰冻图腾"), _txt("Every eighth hit can freeze.", "每第 8 次命中触发冻结。"), "8ecae6", "freeze", 0.65, 0.2]
	]:
		var totem_def: TotemDef = TotemDef.new()
		totem_def.id = str(spec[0])
		totem_def.display_name = str(spec[1])
		totem_def.description = str(spec[2])
		totem_def.color = Color(str(spec[3]))
		totem_def.effect_id = str(spec[4])
		totem_def.base_value = float(spec[5])
		totem_def.level_step = float(spec[6])
		totems[totem_def.id] = totem_def

func _build_events() -> void:
	events = [
		_make_event("bargain_merchant", _txt("Bargain Merchant", "折扣商人"), _txt("A traveling merchant offers a deal.", "路过的商人提供了一笔交易。"), [
			{"label": _txt("Three Cheap Summons", "三次折扣召唤"), "description": _txt("Next 3 summons cost 4 less.", "接下来 3 次召唤便宜 4 金币。"), "effect": "summon_discount_buff", "value": 4, "charges": 3},
			{"label": _txt("Take Gold", "直接拿钱"), "description": _txt("Gain 20 gold now.", "立即获得 20 金币。"), "effect": "gain_gold", "value": 20}
		]),
		_make_event("totem_echo", _txt("Totem Echo", "图腾回响"), _txt("The core totem pulses with power.", "核心图腾释放出新的脉冲。"), [
			{"label": _txt("Level Totem", "升级图腾"), "description": _txt("Totem level plus 1.", "图腾等级 +1。"), "effect": "totem_level", "value": 1},
			{"label": _txt("Gold And Heal", "金币与修复"), "description": _txt("Gain 12 gold and heal 1 core HP.", "获得 12 金币并回复 1 点核心生命。"), "effect": "gold_and_heal", "gold": 12, "heal": 1}
		]),
		_make_event("meteor_support", _txt("Meteor Support", "轨道支援"), _txt("Orbital support locks onto next wave.", "轨道火力已锁定下一波。"), [
			{"label": _txt("Call Bombard", "请求轰炸"), "description": _txt("Next wave starts with 80 damage to all enemies.", "下一波开始时对所有敌人造成 80 伤害。"), "effect": "next_wave_bombard", "value": 80},
			{"label": _txt("Store Energy", "储存能量"), "description": _txt("Gain 1 reroll.", "获得 1 次重随。"), "effect": "gain_reroll", "value": 1}
		]),
		_make_event("frenzy_protocol", _txt("Frenzy Protocol", "狂热协议"), _txt("Emergency combat protocol is active.", "应急战斗协议已启动。"), [
			{"label": _txt("Go Faster", "全速推进"), "description": _txt("Team gains 25 percent attack speed this wave.", "本波全队获得 25% 攻速。"), "effect": "wave_haste", "value": 0.25},
			{"label": _txt("Take Gold", "拿金币"), "description": _txt("Gain 24 gold now.", "立即获得 24 金币。"), "effect": "gain_gold", "value": 24}
		]),
		_make_event("risky_contract", _txt("Risky Contract", "高风险契约"), _txt("High risk contract for extra rewards.", "接受高风险任务以换取更多收益。"), [
			{"label": _txt("Accept", "接受"), "description": _txt("Next wave gains one elite, reward plus 20 gold.", "下一波额外出现一个精英，奖励 +20 金币。"), "effect": "elite_contract", "value": 20},
			{"label": _txt("Decline", "拒绝"), "description": _txt("Stay safe and gain 8 gold.", "稳妥处理并获得 8 金币。"), "effect": "gain_gold", "value": 8}
		]),
		_make_event("emergency_cache", _txt("Emergency Cache", "前线补给"), _txt("Frontline supply crate arrived.", "一批前线补给抵达了。"), [
			{"label": _txt("Free Hero", "免费英雄"), "description": _txt("Gain 1 free summon.", "获得 1 次免费召唤。"), "effect": "free_summon", "value": 1},
			{"label": _txt("Take Reroll", "获得重随"), "description": _txt("Gain 1 reroll.", "获得 1 次重随。"), "effect": "gain_reroll", "value": 1}
		]),
		_make_event("field_medic", _txt("Field Medic", "战地医师"), _txt("Support team patches the core.", "支援小队开始修复核心。"), [
			{"label": _txt("Repair Core", "修复核心"), "description": _txt("Heal 2 core HP.", "回复 2 点核心生命。"), "effect": "heal_core", "value": 2},
			{"label": _txt("Cash Out", "兑换金币"), "description": _txt("Gain 15 gold.", "获得 15 金币。"), "effect": "gain_gold", "value": 15}
		]),
		_make_event("volatile_crystal", _txt("Volatile Crystal", "不稳定晶体"), _txt("A crystal can be detonated or stabilized.", "这块晶体可以引爆，也可以稳定回收。"), [
			{"label": _txt("Detonate", "引爆"), "description": _txt("Next wave heroes gain 20 percent damage.", "下一波英雄获得 20% 伤害。"), "effect": "wave_damage", "value": 0.2},
			{"label": _txt("Stabilize", "稳定回收"), "description": _txt("Totem level plus 1 and gain 10 gold.", "图腾等级 +1 并获得 10 金币。"), "effect": "totem_and_gold", "totem": 1, "gold": 10}
		])
	]

func _build_stages() -> void:
	var boss_cycle: Array[String] = ["wyrm_boss", "lich_boss", "forge_boss"]
	for chapter in range(1, 4):
		for index in range(1, 6):
			var stage_def: StageDef = StageDef.new()
			stage_def.id = "chapter_%d_stage_%d" % [chapter, index]
			stage_def.display_name = _txt("Chapter %d - Stage %d", "第 %d 章 - 第 %d 关") % [chapter, index]
			stage_def.chapter = chapter
			stage_def.difficulty = ((chapter - 1) * 5) + index
			stage_def.description = _txt("Survive 5 waves and defeat the boss.", "撑过 5 波并击败首领。")
			stage_def.tags = _to_string_array([])
			if stage_def.difficulty % 4 == 0:
				stage_def.banned_totem_ids = _to_string_array(["crit_totem"])
				stage_def.tags.append("no_crit")
			stage_def.wave_defs = _build_stage_waves(stage_def.difficulty, boss_cycle[(chapter + index) % boss_cycle.size()])
			stages.append(stage_def)

func _build_stage_waves(difficulty: int, boss_id: String) -> Array[WaveDef]:
	var wave_1: WaveDef = _make_wave(_txt("Scout Wave", "侦察波次"), ["slime", "scout"], 7 + difficulty, 0.70, 18 + difficulty * 2)
	var wave_2: WaveDef = _make_wave(_txt("Pressure Wave", "压力波次"), ["slime", "shell", "spitter"], 8 + difficulty, 0.64, 20 + difficulty * 2)
	var wave_3: WaveDef = _make_wave(_txt("Chaos Wave", "混沌波次"), ["mender", "phantom", "crusher"], 7 + difficulty, 0.62, 24 + difficulty * 2)
	var wave_4: WaveDef = _make_wave(_txt("Elite Wave", "精英波次"), ["healer", "juggernaut", "crusher"], 6 + difficulty, 0.58, 26 + difficulty * 3)
	var boss_wave: WaveDef = _make_wave(_txt("Boss Wave", "首领波次"), ["shell", "phantom"], 4 + int(difficulty / 2.0), 0.85, 45 + difficulty * 3, boss_id)
	return [wave_1, wave_2, wave_3, wave_4, boss_wave]

func _make_hero(hero_id: String, hero_name: String, role_name: String, mode: String, color_value: Color, base_damage_value: float, interval: float, range_value: float, splash: float, pool: Array[String], hero_tags: Array[String]) -> HeroDef:
	var hero_def: HeroDef = HeroDef.new()
	hero_def.id = hero_id
	hero_def.display_name = hero_name
	hero_def.role = role_name
	hero_def.attack_mode = mode
	hero_def.color = color_value
	hero_def.base_damage = base_damage_value
	hero_def.attack_interval = interval
	hero_def.attack_range = range_value
	hero_def.splash_radius = splash
	hero_def.trait_pool = pool
	hero_def.tags = hero_tags
	return hero_def

func _make_global_trait(trait_id: String, trait_name: String, text: String, modifiers: Dictionary, effect_id: String = "") -> TraitDef:
	var trait_def: TraitDef = TraitDef.new()
	trait_def.id = trait_id
	trait_def.display_name = trait_name
	trait_def.description = text
	trait_def.category = "global"
	trait_def.modifiers = modifiers
	trait_def.effect_id = effect_id
	return trait_def

func _make_evo_trait(trait_id: String, trait_name: String, text: String, hero_id: String, modifiers: Dictionary, effect_id: String = "") -> TraitDef:
	var trait_def: TraitDef = TraitDef.new()
	trait_def.id = trait_id
	trait_def.display_name = trait_name
	trait_def.description = text
	trait_def.category = "evolution"
	trait_def.hero_ids = [hero_id]
	trait_def.modifiers = modifiers
	trait_def.effect_id = effect_id
	return trait_def

func _make_event(event_id: String, event_name: String, text: String, option_defs: Array[Dictionary]) -> EventDef:
	var event_def: EventDef = EventDef.new()
	event_def.id = event_id
	event_def.display_name = event_name
	event_def.description = text
	event_def.options = option_defs
	return event_def

func _make_wave(label: String, enemy_ids: Array[String], spawn_count: int, spawn_interval: float, reward: int, boss_id: String = "") -> WaveDef:
	var wave_def: WaveDef = WaveDef.new()
	wave_def.label = label
	wave_def.enemy_ids = enemy_ids
	wave_def.spawn_count = spawn_count
	wave_def.spawn_interval = spawn_interval
	wave_def.reward = reward
	wave_def.boss_id = boss_id
	return wave_def