extends Node

signal language_changed(language_code: String)

const LANGUAGE_ZH := "zh_CN"
const LANGUAGE_EN := "en"

var current_language: String = LANGUAGE_ZH

var _texts := {
	"controls": {LANGUAGE_EN: "Controls", LANGUAGE_ZH: "操作"},
	"summon_hero": {LANGUAGE_EN: "Summon Hero", LANGUAGE_ZH: "召唤英雄"},
	"refresh_preview": {LANGUAGE_EN: "Refresh Preview", LANGUAGE_ZH: "刷新预览"},
	"summon_preview": {LANGUAGE_EN: "Summon Preview", LANGUAGE_ZH: "召唤预览"},
	"battle_log": {LANGUAGE_EN: "Battle Log", LANGUAGE_ZH: "战斗日志"},
	"prev_stage": {LANGUAGE_EN: "Prev", LANGUAGE_ZH: "上一关"},
	"restart_stage": {LANGUAGE_EN: "Restart", LANGUAGE_ZH: "重开"},
	"next_stage": {LANGUAGE_EN: "Next", LANGUAGE_ZH: "下一关"},
	"run_info": {LANGUAGE_EN: "Run Info", LANGUAGE_ZH: "局内信息"},
	"traits": {LANGUAGE_EN: "Traits", LANGUAGE_ZH: "词条"},
	"damage": {LANGUAGE_EN: "Damage", LANGUAGE_ZH: "伤害统计"},
	"language": {LANGUAGE_EN: "Language", LANGUAGE_ZH: "语言"},
	"reroll": {LANGUAGE_EN: "Reroll", LANGUAGE_ZH: "重随"},
	"core": {LANGUAGE_EN: "Core", LANGUAGE_ZH: "核心"},
	"board": {LANGUAGE_EN: "Board", LANGUAGE_ZH: "棋盘"},
	"pick_totem": {LANGUAGE_EN: "Pick Totem", LANGUAGE_ZH: "选择图腾"},
	"pick_totem_desc": {LANGUAGE_EN: "Choose one core totem for this run.", LANGUAGE_ZH: "为本局选择一个核心图腾。"},
	"pick_trait": {LANGUAGE_EN: "Pick Trait", LANGUAGE_ZH: "选择词条"},
	"pick_trait_desc": {LANGUAGE_EN: "Choose one run modifier.", LANGUAGE_ZH: "选择一个本局增益。"},
	"evolution_trait": {LANGUAGE_EN: "Evolution Trait", LANGUAGE_ZH: "进化词条"},
	"evolution_reached": {LANGUAGE_EN: "%s reached %d stars.", LANGUAGE_ZH: "%s 达到 %d 星。"},
	"stage_clear_title": {LANGUAGE_EN: "Stage Clear", LANGUAGE_ZH: "关卡完成"},
	"stage_clear_desc": {LANGUAGE_EN: "You survived all 5 waves.", LANGUAGE_ZH: "你成功撑过了 5 波敌人。"},
	"defeat_title": {LANGUAGE_EN: "Defeat", LANGUAGE_ZH: "战斗失败"},
	"defeat_desc": {LANGUAGE_EN: "The core was destroyed.", LANGUAGE_ZH: "核心被摧毁了。"},
	"restart_desc": {LANGUAGE_EN: "Play again with a new seed.", LANGUAGE_ZH: "用新的种子重新开始。"},
	"retry_desc": {LANGUAGE_EN: "Retry this stage.", LANGUAGE_ZH: "重新挑战当前关卡。"},
	"next_stage_desc": {LANGUAGE_EN: "Move to the next stage.", LANGUAGE_ZH: "前往下一关。"},
	"entered_stage": {LANGUAGE_EN: "Entered %s with seed %d.", LANGUAGE_ZH: "进入 %s，种子 %d。"},
	"board_full": {LANGUAGE_EN: "Board full.", LANGUAGE_ZH: "棋盘已满。"},
	"not_enough_gold": {LANGUAGE_EN: "Not enough gold.", LANGUAGE_ZH: "金币不足。"},
	"no_free_slot": {LANGUAGE_EN: "No free slot.", LANGUAGE_ZH: "没有空位。"},
	"summoned": {LANGUAGE_EN: "Summoned %s.", LANGUAGE_ZH: "已召唤 %s。"},
	"cannot_refresh": {LANGUAGE_EN: "Cannot refresh.", LANGUAGE_ZH: "无法刷新。"},
	"preview_refreshed": {LANGUAGE_EN: "Preview refreshed.", LANGUAGE_ZH: "预览已刷新。"},
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
	"stage_seed": {LANGUAGE_EN: "%s | Seed %d", LANGUAGE_ZH: "%s | 种子 %d"},
	"gold_line": {LANGUAGE_EN: "Gold: %d | Summon Cost: %d", LANGUAGE_ZH: "金币：%d | 召唤花费：%d"},
	"hp_line": {LANGUAGE_EN: "Core: %d / %d | Free Rerolls: %d", LANGUAGE_ZH: "核心：%d / %d | 免费重随：%d"},
	"wave_line": {LANGUAGE_EN: "Wave: %d / %d | Enemies: %d", LANGUAGE_ZH: "波次：%d / %d | 场上敌人：%d"},
	"totem_none": {LANGUAGE_EN: "Totem: none", LANGUAGE_ZH: "图腾：未选择"},
	"totem_info": {LANGUAGE_EN: "Totem: %s Lv.%d\n%s", LANGUAGE_ZH: "图腾：%s Lv.%d\n%s"},
	"no_traits_yet": {LANGUAGE_EN: "No traits yet.", LANGUAGE_ZH: "暂无词条。"},
	"no_damage_stats_yet": {LANGUAGE_EN: "No damage stats yet.", LANGUAGE_ZH: "暂无伤害数据。"},
	"event_default": {LANGUAGE_EN: "Event", LANGUAGE_ZH: "事件"},
	"option_default": {LANGUAGE_EN: "Option", LANGUAGE_ZH: "选项"},
	"language_changed": {LANGUAGE_EN: "Language changed. Stage restarted.", LANGUAGE_ZH: "语言已切换，当前关卡已重开。"}
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