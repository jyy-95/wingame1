class_name TotemDef
extends Resource

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var color := Color.WHITE
@export var effect_id := ""
@export var base_value := 0.0
@export var level_step := 0.0
@export var banned_stage_tags: Array[String] = []