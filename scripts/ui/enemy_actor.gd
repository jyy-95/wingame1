class_name EnemyActor
extends PanelContainer

const IconBadge = preload("res://scripts/ui/icon_badge.gd")
const ArtCatalog = preload("res://scripts/ui/art_catalog.gd")

signal defeated(enemy: EnemyActor)
signal leaked(enemy: EnemyActor)

var enemy_def
var current_hp: float = 1.0
var max_hp: float = 1.0
var speed: float = 80.0
var armor: float = 0.0
var reward: int = 0
var poison_dps: float = 0.0
var poison_time: float = 0.0
var freeze_time: float = 0.0
var slow_pct: float = 0.0
var slow_time: float = 0.0
var resolved: bool = false

var _icon: IconBadge
var _name_label: Label
var _hp_fill: ColorRect

func _ready() -> void:
	custom_minimum_size = Vector2(88, 86)
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = true
	tooltip_text = ""

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 3)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_right", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	add_child(margin)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)

	_icon = IconBadge.new()
	_icon.custom_minimum_size = Vector2(72, 72)
	_icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_icon)

	_name_label = Label.new()
	_name_label.visible = false
	box.add_child(_name_label)

	var hp_wrap := CenterContainer.new()
	hp_wrap.custom_minimum_size = Vector2(0, 8)
	box.add_child(hp_wrap)

	var hp_frame := PanelContainer.new()
	hp_frame.custom_minimum_size = Vector2(64, 8)
	var hp_style := StyleBoxFlat.new()
	hp_style.bg_color = Color(1, 1, 1, 0.14)
	hp_style.corner_radius_top_left = 999
	hp_style.corner_radius_top_right = 999
	hp_style.corner_radius_bottom_left = 999
	hp_style.corner_radius_bottom_right = 999
	hp_frame.add_theme_stylebox_override("panel", hp_style)
	hp_wrap.add_child(hp_frame)

	var hp_root := Control.new()
	hp_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hp_frame.add_child(hp_root)
	_hp_fill = ColorRect.new()
	_hp_fill.anchor_right = 1.0
	_hp_fill.anchor_bottom = 1.0
	_hp_fill.color = Color("7be26e")
	hp_root.add_child(_hp_fill)

	_update_visuals()

func setup(in_enemy_def, hp_scale: float, speed_scale: float, reward_bonus: int = 0) -> void:
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
		apply_damage(poison_dps * delta)
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
	var actual_damage: float = maxf(1.0, raw_damage - armor)
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
	var display_name: String = Localization.text("event_default")
	if enemy_def != null:
		display_name = str(enemy_def.display_name)
		var localized_enemy = GameData.get_enemy(enemy_def.id)
		if localized_enemy != null:
			display_name = str(localized_enemy.display_name)
	_name_label.text = _short_name(display_name)
	tooltip_text = display_name
	_hp_fill.anchor_right = clampf(get_health_ratio(), 0.0, 1.0)
	_hp_fill.color = Color("8ddf73") if freeze_time <= 0.0 else Color("84d7ff")
	var base_color: Color = Color("7a1c1c")
	if enemy_def != null:
		base_color = enemy_def.color
	var style := StyleBoxFlat.new()
	style.bg_color = Color(base_color.r, base_color.g, base_color.b, 0.18)
	style.border_color = base_color.lightened(0.42)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	add_theme_stylebox_override("panel", style)
	var texture := ArtCatalog.get_enemy_texture(enemy_def.id if enemy_def != null else "")
	if texture != null:
		_icon.configure_with_texture(texture, base_color)
	else:
		_icon.configure(base_color.lightened(0.1), base_color.darkened(0.3), Color("f3d8c7"), "avatar")

func _short_name(text: String) -> String:
	if Localization.is_chinese():
		return text.substr(0, mini(4, text.length()))
	return text.substr(0, mini(8, text.length()))
