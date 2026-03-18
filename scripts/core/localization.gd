extends Node

signal language_changed(language_code: String)

const LANGUAGE_ZH := "zh_CN"
const LANGUAGE_EN := "en"

var current_language: String = LANGUAGE_ZH

var _texts := {
	"summon_hero": {LANGUAGE_EN: "Summon Hero", LANGUAGE_ZH: "召唤英雄"},
	"battle_log": {LANGUAGE_EN: "Battle Log", LANGUAGE_ZH: "战斗日志"},
	"prev_stage": {LANGUAGE_EN: "Prev", LANGUAGE_ZH: "上一关"},
	"restart_stage": {LANGUAGE_EN: "Restart", LANGUAGE_ZH: "重开"},
	"next_stage": {LANGUAGE_EN: "Next", LANGUAGE_ZH: "下一关"},
	"traits": {LANGUAGE_EN: "Traits", LANGUAGE_ZH: "词条"},
	"damage": {LANGUAGE_EN: "Damage", LANGUAGE_ZH: "伤害统计"},
	"language": {LANGUAGE_EN: "Language", LANGUAGE_ZH: "语言"},
	"language_zh": {LANGUAGE_EN: "简体中文", LANGUAGE_ZH: "简体中文"},
	"language_en": {LANGUAGE_EN: "English", LANGUAGE_ZH: "English"},
	"reroll": {LANGUAGE_EN: "Reroll", LANGUAGE_ZH: "重随"},
	"pick_totem": {LANGUAGE_EN: "Pick Totem", LANGUAGE_ZH: "选择图腾"},
	"pick_totem_desc": {LANGUAGE_EN: "Choose one core totem for this run.", LANGUAGE_ZH: "为本局选择一个核心图腾。"},
	"pick_trait": {LANGUAGE_EN: "Pick Trait", LANGUAGE_ZH: "选择词条"},
	"pick_trait_desc": {LANGUAGE_EN: "Choose one run modifier.", LANGUAGE_ZH: "选择一个本局增益。"},
	"evolution_trait": {LANGUAGE_EN: "Evolution Trait", LANGUAGE_ZH: "进化词条"},
	"evolution_reached": {LANGUAGE_EN: "%s reached %d stars.", LANGUAGE_ZH: "%s 达到 %d 星。"},
	"stage_clear_title": {LANGUAGE_EN: "Stage Clear", LANGUAGE_ZH: "关卡完成"},
	"stage_clear_desc": {LANGUAGE_EN: "You survived all 5 waves.", LANGUAGE_ZH: "你成功撑过了全部 5 波。"},
	"defeat_title": {LANGUAGE_EN: "Defeat", LANGUAGE_ZH: "战斗失败"},
	"defeat_desc": {LANGUAGE_EN: "The core was destroyed.", LANGUAGE_ZH: "核心被摧毁了。"},
	"restart_desc": {LANGUAGE_EN: "Play again with a new seed.", LANGUAGE_ZH: "用新的种子重新开始。"},
	"retry_desc": {LANGUAGE_EN: "Retry this stage.", LANGUAGE_ZH: "重新挑战当前关卡。"},
	"next_stage_desc": {LANGUAGE_EN: "Move to the next stage.", LANGUAGE_ZH: "前往下一关。"},
	"entered_stage": {LANGUAGE_EN: "Entered %s with seed %d.", LANGUAGE_ZH: "进入 %s，种子 %d。"},
	"board_full": {LANGUAGE_EN: "Board full.", LANGUAGE_ZH: "部署区已满。"},
	"not_enough_gold": {LANGUAGE_EN: "Not enough gold.", LANGUAGE_ZH: "金币不足。"},
	"no_free_slot": {LANGUAGE_EN: "No free slot.", LANGUAGE_ZH: "没有空位。"},
	"summoned": {LANGUAGE_EN: "Summoned %s.", LANGUAGE_ZH: "已召唤 %s。"},
	"bombard_triggered": {LANGUAGE_EN: "Bombard triggered.", LANGUAGE_ZH: "轰炸已触发。"},
	"defeated_enemy": {LANGUAGE_EN: "Defeated %s.", LANGUAGE_ZH: "击败了 %s。"},
	"leak_damage": {LANGUAGE_EN: "Leak: core takes %d.", LANGUAGE_ZH: "漏怪：核心受到 %d 点伤害。"},
	"wave_clear": {LANGUAGE_EN: "Wave clear: %s.", LANGUAGE_ZH: "波次完成：%s。"},
	"start_wave": {LANGUAGE_EN: "Start wave %d.", LANGUAGE_ZH: "开始第 %d 波。"},
	"totem_selected": {LANGUAGE_EN: "Totem: %s.", LANGUAGE_ZH: "图腾：%s。"},
	"trait_selected": {LANGUAGE_EN: "Trait: %s.", LANGUAGE_ZH: "词条：%s。"},
	"evolution_selected": {LANGUAGE_EN: "Evolution: %s.", LANGUAGE_ZH: "进化：%s。"},
	"sold_piece": {LANGUAGE_EN: "Sold piece for %d.", LANGUAGE_ZH: "出售单位，获得 %d 金币。"},
	"run_ended": {LANGUAGE_EN: "Run ended.", LANGUAGE_ZH: "本局结束。"},
	"stage_seed": {LANGUAGE_EN: "%s · Seed %d", LANGUAGE_ZH: "%s · 种子 %d"},
	"wave_line": {LANGUAGE_EN: "Wave %d / %d · Enemies %d", LANGUAGE_ZH: "第 %d / %d 波 · 敌人 %d"},
	"totem_none": {LANGUAGE_EN: "No Totem", LANGUAGE_ZH: "未选择图腾"},
	"totem_none_desc": {LANGUAGE_EN: "Pick a totem to unlock passive power and upgrades.", LANGUAGE_ZH: "选择图腾后才能获得被动与强化。"},
	"totem_none_charge": {LANGUAGE_EN: "No charge available", LANGUAGE_ZH: "暂无充能信息"},
	"totem_passive": {LANGUAGE_EN: "Passive effect always active", LANGUAGE_ZH: "被动效果持续生效"},
	"totem_charge_line": {LANGUAGE_EN: "Charge %d / %d", LANGUAGE_ZH: "充能 %d / %d"},
	"totem_upgrade": {LANGUAGE_EN: "Upgrade Totem", LANGUAGE_ZH: "图腾强化"},
	"totem_upgrade_locked": {LANGUAGE_EN: "Pick a totem first.", LANGUAGE_ZH: "请先选择图腾。"},
	"totem_upgraded": {LANGUAGE_EN: "Totem upgraded to Lv.%d.", LANGUAGE_ZH: "图腾已提升到 Lv.%d。"},
	"no_traits_yet": {LANGUAGE_EN: "No traits yet.", LANGUAGE_ZH: "暂无词条。"},
	"no_damage_stats_yet": {LANGUAGE_EN: "No damage stats yet.", LANGUAGE_ZH: "暂无伤害数据。"},
	"no_logs_yet": {LANGUAGE_EN: "No logs yet.", LANGUAGE_ZH: "暂无战斗记录。"},
	"event_default": {LANGUAGE_EN: "Event", LANGUAGE_ZH: "事件"},
	"option_default": {LANGUAGE_EN: "Option", LANGUAGE_ZH: "选项"},
	"language_changed": {LANGUAGE_EN: "Language changed. Stage restarted.", LANGUAGE_ZH: "语言已切换，当前关卡已重开。"},
	"stage_overview": {LANGUAGE_EN: "Stage Overview", LANGUAGE_ZH: "关卡概览"},
	"run_intel": {LANGUAGE_EN: "Run Intel", LANGUAGE_ZH: "局内信息"},
	"quick_speed": {LANGUAGE_EN: "Speed", LANGUAGE_ZH: "倍速"},
	"quick_stats": {LANGUAGE_EN: "Stats", LANGUAGE_ZH: "统计"},
	"quick_log": {LANGUAGE_EN: "Log / Menu", LANGUAGE_ZH: "日志 / 菜单"},
	"speed_mode": {LANGUAGE_EN: "%0.1fx\n%s", LANGUAGE_ZH: "%0.1fx\n%s"},
	"deploy_strip": {LANGUAGE_EN: "Deploy Strip", LANGUAGE_ZH: "部署带"},
	"deploy_hint": {LANGUAGE_EN: "Drag to merge · Right-click to sell", LANGUAGE_ZH: "拖动合成 · 右键出售"},
	"random_hero_hint": {LANGUAGE_EN: "Random Heroes: %s", LANGUAGE_ZH: "随机英雄：%s"},
	"gold_label": {LANGUAGE_EN: "Current Gold", LANGUAGE_ZH: "当前金币"},
	"summon_cost": {LANGUAGE_EN: "Summon Cost %d", LANGUAGE_ZH: "召唤成本 %d"},
	"core_status": {LANGUAGE_EN: "Core Stability · Totem Lv.%d · Upgrade %d", LANGUAGE_ZH: "核心稳定度 · 图腾 Lv.%d · 强化 %d"},
	"wave_badge": {LANGUAGE_EN: "Wave %d / %d", LANGUAGE_ZH: "波次 %d / %d"},
	"enemy_badge": {LANGUAGE_EN: "Enemies %d", LANGUAGE_ZH: "敌人 %d"},
	"trait_badge": {LANGUAGE_EN: "Traits %d", LANGUAGE_ZH: "词条 %d"},
	"action_ready": {LANGUAGE_EN: "Ready", LANGUAGE_ZH: "可用"},
	"select_action": {LANGUAGE_EN: "Select", LANGUAGE_ZH: "选择"}
}

var _role_texts := {
	"striker": {LANGUAGE_EN: "Striker", LANGUAGE_ZH: "输出"},
	"control": {LANGUAGE_EN: "Control", LANGUAGE_ZH: "控制"},
	"vanguard": {LANGUAGE_EN: "Vanguard", LANGUAGE_ZH: "前排"}
}

func _ready() -> void:
	if SaveService.language_code == LANGUAGE_EN:
		current_language = LANGUAGE_EN
	else:
		current_language = LANGUAGE_ZH

func is_chinese() -> bool:
	return current_language == LANGUAGE_ZH

func text(key: String) -> String:
	if not _texts.has(key):
		return key
	var bucket: Dictionary = _texts[key]
	return str(bucket.get(current_language, bucket.get(LANGUAGE_EN, key)))

func format_text(key: String, args: Array) -> String:
	return text(key) % args

func role_name(role_id: String) -> String:
	if not _role_texts.has(role_id):
		return role_id
	var bucket: Dictionary = _role_texts[role_id]
	return str(bucket.get(current_language, bucket.get(LANGUAGE_EN, role_id)))

func set_language(language_code: String) -> void:
	if language_code != LANGUAGE_EN and language_code != LANGUAGE_ZH:
		language_code = LANGUAGE_ZH
	if current_language == language_code:
		return
	current_language = language_code
	SaveService.set_language_code(language_code)
	language_changed.emit(current_language)
