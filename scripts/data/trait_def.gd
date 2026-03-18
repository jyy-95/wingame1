class_name TraitDef
extends Resource

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var category := "global"
@export var rarity := 1
@export var hero_ids: Array[String] = []
@export var target_tags: Array[String] = []
@export var modifiers: Dictionary = {}
@export var mutually_exclusive: Array[String] = []
@export var effect_id := ""

func applies_to_hero(hero_id: String, hero_tags: Array[String]) -> bool:
	if category == "global":
		return true
	if hero_ids.size() > 0 and not hero_ids.has(hero_id):
		return false
	if target_tags.is_empty():
		return true
	for tag in target_tags:
		if hero_tags.has(tag):
			return true
	return false