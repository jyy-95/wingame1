class_name ArtCatalog
extends RefCounted

const HERO_TEXTURE_BY_ID := {
	"ember_mage": "res://assets/generated/heroes/ember_mage.svg",
	"frost_oracle": "res://assets/generated/heroes/frost_oracle.svg",
	"tide_guard": "res://assets/generated/heroes/tide_guard.svg",
	"blade_dancer": "res://assets/generated/heroes/blade_dancer.svg",
	"venom_sage": "res://assets/generated/heroes/venom_sage.svg",
	"storm_caller": "res://assets/generated/heroes/storm_caller.svg",
	"iron_warden": "res://assets/generated/heroes/iron_warden.svg",
	"solar_priest": "res://assets/generated/heroes/solar_priest.svg"
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

const BACKGROUND_BATTLEFIELD := "res://assets/generated/backgrounds/whimsy_forest_lane.svg"
const FALLBACK_HERO := "res://assets/generated/heroes/frost_oracle.svg"
const FALLBACK_ENEMY := "res://assets/generated/enemies/scout.svg"
const FALLBACK_EFFECT := "res://assets/generated/effects/impact_spark.svg"

static var _texture_cache: Dictionary = {}

static func get_hero_texture(hero_id: String) -> Texture2D:
	return _load_texture(HERO_TEXTURE_BY_ID.get(hero_id, FALLBACK_HERO))

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
