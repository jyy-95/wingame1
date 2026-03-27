class_name ArtCatalog
extends RefCounted

const HERO_TEXTURE_BY_ID := {
	"ember_mage": "res://assets/generated/heroes/ember_mage.png",
	"frost_oracle": "res://assets/generated/heroes/frost_oracle.png",
	"tide_guard": "res://assets/generated/heroes/tide_guard.png",
	"blade_dancer": "res://assets/generated/heroes/blade_dancer.png",
	"venom_sage": "res://assets/generated/heroes/venom_sage.png",
	"storm_caller": "res://assets/generated/heroes/storm_caller.png",
	"iron_warden": "res://assets/generated/heroes/iron_warden.png",
	"solar_priest": "res://assets/generated/heroes/solar_priest.png"
}

const ENEMY_TEXTURE_BY_ID := {
	"slime": "res://assets/generated/enemies/slime.svg",
	"scout": "res://assets/generated/enemies/scout.svg",
	"shell": "res://assets/generated/enemies/shell.svg",
	"mender": "res://assets/generated/enemies/mender.svg",
	"spitter": "res://assets/generated/enemies/spitter.svg",
	"crusher": "res://assets/generated/enemies/crusher.svg",
	"phantom": "res://assets/generated/enemies/phantom.svg",
	"healer": "res://assets/generated/enemies/healer.svg",
	"juggernaut": "res://assets/generated/enemies/juggernaut.svg",
	"wyrm_boss": "res://assets/generated/enemies/wyrm_boss.svg",
	"lich_boss": "res://assets/generated/enemies/lich_boss.svg",
	"forge_boss": "res://assets/generated/enemies/forge_boss.svg"
}


const TOTEM_TEXTURE_BY_ID := {
	"poison_totem": "res://assets/generated/totems/poison_totem.svg",
	"crit_totem": "res://assets/generated/totems/crit_totem.svg",
	"frost_totem": "res://assets/generated/totems/frost_totem.svg"
}

const EFFECT_TEXTURE_BY_ID := {
	"frost_beam": "res://assets/generated/effects/frost_beam.svg",
	"arcane_burst": "res://assets/generated/effects/arcane_burst.svg",
	"impact_spark": "res://assets/generated/effects/impact_spark.svg",
	"freeze_ring": "res://assets/generated/effects/freeze_ring.svg",
	"venom_cloud": "res://assets/generated/effects/venom_cloud.svg",
	"solar_flare": "res://assets/generated/effects/solar_flare.svg",
	"chain_arc": "res://assets/generated/effects/chain_arc.svg"
}

const BACKGROUND_BATTLEFIELD := "res://assets/generated/backgrounds/forge_hall_lane.jpg"
const FALLBACK_HERO := "res://assets/generated/heroes/frost_oracle.png"
const FALLBACK_ENEMY := "res://assets/generated/enemies/scout.svg"
const FALLBACK_EFFECT := "res://assets/generated/effects/impact_spark.svg"
const HERO_ANIMATION_DIR_BY_ID := {}

static var _texture_cache: Dictionary = {}
static var _animation_cache: Dictionary = {}
static var _animation_path_cache: Dictionary = {}

static func get_hero_texture(hero_id: String) -> Texture2D:
	return _load_texture(HERO_TEXTURE_BY_ID.get(hero_id, FALLBACK_HERO))

static func get_hero_animation_frames(hero_id: String) -> Array[Texture2D]:
	var paths := _get_hero_animation_paths(hero_id)
	if paths.is_empty():
		return []
	var cache_key := "|".join(paths)
	if not _animation_cache.has(cache_key):
		var frames: Array[Texture2D] = []
		for path in paths:
			var texture := _load_texture(path)
			if texture != null:
				frames.append(texture)
		_animation_cache[cache_key] = frames
	var cached: Array[Texture2D] = _animation_cache.get(cache_key, [])
	return cached

static func get_enemy_texture(enemy_id: String) -> Texture2D:
	return _load_texture(ENEMY_TEXTURE_BY_ID.get(enemy_id, FALLBACK_ENEMY))

static func get_effect_texture(effect_id: String) -> Texture2D:
	return _load_texture(EFFECT_TEXTURE_BY_ID.get(effect_id, FALLBACK_EFFECT))

static func get_totem_texture(totem_id: String) -> Texture2D:
	return _load_texture(TOTEM_TEXTURE_BY_ID.get(totem_id, FALLBACK_HERO))

static func get_battlefield_background() -> Texture2D:
	return _load_texture(BACKGROUND_BATTLEFIELD)

static func _load_texture(path: String) -> Texture2D:
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path] as Texture2D

static func _get_hero_animation_paths(hero_id: String) -> PackedStringArray:
	if _animation_path_cache.has(hero_id):
		return _animation_path_cache[hero_id]
	var paths := PackedStringArray()
	var directory_path: String = HERO_ANIMATION_DIR_BY_ID.get(hero_id, "")
	if directory_path.is_empty():
		return paths
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return paths
	var file_names: Array[String] = []
	directory.list_dir_begin()
	while true:
		var file_name := directory.get_next()
		if file_name.is_empty():
			break
		if directory.current_is_dir():
			continue
		if file_name.get_extension().to_lower() != "png":
			continue
		file_names.append(file_name)
	directory.list_dir_end()
	file_names.sort()
	for file_name in file_names:
		paths.append("%s/%s" % [directory_path, file_name])
	_animation_path_cache[hero_id] = paths
	return paths



