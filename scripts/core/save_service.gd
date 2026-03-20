extends Node

const SAVE_PATH := "user://savegame.json"

var unlocked_stage_index := 0
var best_stage_cleared := 0
var last_seed := 0
var language_code := "zh_CN"

func _ready() -> void:
	load_data()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	unlocked_stage_index = int(parsed.get("unlocked_stage_index", 0))
	best_stage_cleared = int(parsed.get("best_stage_cleared", 0))
	last_seed = int(parsed.get("last_seed", 0))
	language_code = str(parsed.get("language_code", "zh_CN"))

func save_data() -> void:
	var payload: Dictionary = {
		"unlocked_stage_index": unlocked_stage_index,
		"best_stage_cleared": best_stage_cleared,
		"last_seed": last_seed,
		"language_code": language_code
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload, "\t"))

func set_language_code(value: String) -> void:
	language_code = value
	save_data()

func register_stage_clear(stage_index: int, run_seed: int) -> void:
	best_stage_cleared = maxi(best_stage_cleared, stage_index)
	unlocked_stage_index = maxi(unlocked_stage_index, stage_index + 1)
	last_seed = run_seed
	save_data()
