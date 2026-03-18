class_name EnemyActor
extends PanelContainer

signal defeated(enemy: EnemyActor)
signal leaked(enemy: EnemyActor)

var enemy_def: EnemyDef
var current_hp := 1.0
var max_hp := 1.0
var speed := 80.0
var armor := 0.0
var reward := 0
var poison_dps := 0.0
var poison_time := 0.0
var freeze_time := 0.0
var slow_pct := 0.0
var slow_time := 0.0
var resolved := false

var _name_label: Label
var _hp_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(72, 42)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(box)
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_name_label)
	_hp_label = Label.new()
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_hp_label)
	_update_visuals()

func setup(in_enemy_def: EnemyDef, hp_scale: float, speed_scale: float, reward_bonus: int = 0) -> void:
	enemy_def = in_enemy_def
	max_hp = enemy_def.max_hp * hp_scale
	current_hp = max_hp
	speed = enemy_def.speed * speed_scale
	armor = enemy_def.armor
	reward = enemy_def.reward + reward_bonus
	_update_visuals()

func tick(delta: float, leak_line_y: float) -> void:
	if resolved:
		return
	if poison_time > 0.0:
		poison_time -= delta
		var poison_damage := apply_damage(poison_dps * delta)
		if poison_damage > 0.0:
			_hp_label.text = "%d / %d" % [ceili(current_hp), ceili(max_hp)]
	if slow_time > 0.0:
		slow_time -= delta
	else:
		slow_pct = 0.0
	if freeze_time > 0.0:
		freeze_time -= delta
	else:
		position.y += speed * maxf(0.15, 1.0 - slow_pct) * delta
	if position.y >= leak_line_y and not resolved:
		resolved = true
		leaked.emit(self)

func apply_damage(raw_damage: float) -> float:
	if resolved:
		return 0.0
	var actual_damage := maxf(1.0, raw_damage - armor)
	current_hp -= actual_damage
	_update_visuals()
	if current_hp <= 0.0 and not resolved:
		resolved = true
		defeated.emit(self)
	return actual_damage

func apply_poison(dps: float, duration: float) -> void:
	poison_dps = maxf(poison_dps, dps)
	poison_time = maxf(poison_time, duration)

func apply_freeze(duration: float) -> void:
	freeze_time = maxf(freeze_time, duration)

func apply_slow(percent: float, duration: float) -> void:
	slow_pct = maxf(slow_pct, percent)
	slow_time = maxf(slow_time, duration)

func apply_push(distance: float) -> void:
	position.y -= distance

func get_health_ratio() -> float:
	return current_hp / maxf(1.0, max_hp)

func _update_visuals() -> void:
	if _name_label == null:
		return
	var display_name: String = enemy_def.display_name if enemy_def != null else Localization.text("event_default")
	if enemy_def != null:
		var localized_enemy: EnemyDef = GameData.get_enemy(enemy_def.id)
		if localized_enemy != null:
			display_name = localized_enemy.display_name
	_name_label.text = display_name
	_hp_label.text = "%d / %d" % [ceili(current_hp), ceili(max_hp)]
	var style := StyleBoxFlat.new()
	style.bg_color = enemy_def.color.darkened(0.15) if enemy_def != null else Color("7a1c1c")
	style.border_color = Color.WHITE
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	add_theme_stylebox_override("panel", style)