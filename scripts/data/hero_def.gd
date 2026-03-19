class_name HeroDef
extends Resource

@export var id := ""
@export var display_name := ""
@export var role := ""
@export var attack_mode := "single"
@export var color := Color.WHITE
@export var weight := 100
@export var base_damage := 12.0
@export var attack_interval := 1.0
@export var attack_range := 2000.0
@export var splash_radius := 0.0
@export var projectile_speed := 0.0
@export var status_power := 0.0
@export var star_damage_multipliers: Array[float] = [1.0, 1.75, 2.8, 4.2, 6.4]
@export var star_interval_multipliers: Array[float] = [1.0, 0.92, 0.85, 0.78, 0.7]
@export var star_range_bonus: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
@export var trait_pool: Array[String] = []
@export var tags: Array[String] = []

func get_damage_for_star(star: int) -> float:
	var index := clampi(star - 1, 0, star_damage_multipliers.size() - 1)
	return base_damage * star_damage_multipliers[index]

func get_interval_for_star(star: int) -> float:
	var index := clampi(star - 1, 0, star_interval_multipliers.size() - 1)
	return attack_interval * star_interval_multipliers[index]

func get_range_for_star(star: int) -> float:
	var index := clampi(star - 1, 0, star_range_bonus.size() - 1)
	return attack_range + star_range_bonus[index]