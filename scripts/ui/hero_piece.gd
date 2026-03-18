class_name HeroPiece
extends PanelContainer

const IconBadge = preload("res://scripts/ui/icon_badge.gd")

signal sell_requested(piece: HeroPiece)

var hero_def
var star_level: int = 1
var purchase_value: int = 0
var cooldown_remaining: float = 0.0
var board_manager: Node
var last_target_instance_id: int = 0
var combo_stacks: int = 0

var _icon: IconBadge
var _name_label: Label
var _star_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(78, 58)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_bottom", 4)
	add_child(margin)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)
	_icon = IconBadge.new()
	_icon.custom_minimum_size = Vector2(40, 40)
	row.add_child(_icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 2)
	row.add_child(copy)
	_name_label = Label.new()
	_name_label.clip_text = true
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name_label.add_theme_font_size_override("font_size", 11)
	copy.add_child(_name_label)
	_star_label = Label.new()
	_star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_star_label.add_theme_font_size_override("font_size", 12)
	copy.add_child(_star_label)
	_update_visuals()

func setup(in_hero_def, in_star_level: int, in_purchase_value: int, in_board_manager: Node) -> void:
	hero_def = in_hero_def
	star_level = in_star_level
	purchase_value = in_purchase_value
	board_manager = in_board_manager
	cooldown_remaining = hero_def.get_interval_for_star(star_level)
	_update_visuals()

func get_display_label() -> String:
	var display_name: String = Localization.text("option_default")
	if hero_def != null:
		display_name = str(hero_def.display_name)
		var localized_hero = GameData.get_hero(hero_def.id)
		if localized_hero != null:
			display_name = str(localized_hero.display_name)
	if Localization.is_chinese():
		return "%s Lv.%d" % [display_name, star_level]
	return "%s %d-star" % [display_name, star_level]

func can_merge_with(other: HeroPiece) -> bool:
	return other != null and other.hero_def.id == hero_def.id and other.star_level == star_level and star_level < 5

func upgrade_to(new_star_level: int, added_value: int) -> void:
	star_level = mini(5, new_star_level)
	purchase_value += added_value
	cooldown_remaining = hero_def.get_interval_for_star(star_level)
	_update_visuals()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if board_manager == null:
		return null
	var preview := PanelContainer.new()
	preview.custom_minimum_size = custom_minimum_size
	preview.modulate = Color(1, 1, 1, 0.88)
	var label := Label.new()
	label.text = get_display_label()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.add_child(label)
	set_drag_preview(preview)
	return {"piece": self}

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		sell_requested.emit(self)
		accept_event()

func _update_visuals() -> void:
	if _name_label == null:
		return
	var display_name: String = "Unit"
	if hero_def != null:
		display_name = str(hero_def.display_name)
		var localized_hero = GameData.get_hero(hero_def.id)
		if localized_hero != null:
			display_name = str(localized_hero.display_name)
	_name_label.text = _short_name(display_name)
	_star_label.text = "*".repeat(star_level)
	_star_label.add_theme_color_override("font_color", Color("fff0a8"))
	var base_color: Color = Color("4e6983")
	if hero_def != null:
		base_color = hero_def.color
	var style := StyleBoxFlat.new()
	style.bg_color = Color(base_color.r, base_color.g, base_color.b, 0.22)
	style.border_color = base_color.lightened(0.55)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	add_theme_stylebox_override("panel", style)
	_icon.configure(base_color.lightened(0.18), base_color.darkened(0.24), Color("f5e4d1"), "avatar")

func _short_name(text: String) -> String:
	if Localization.is_chinese():
		return text.substr(0, mini(4, text.length()))
	var parts := text.split(" ", false)
	if not parts.is_empty():
		return parts[0].substr(0, mini(8, parts[0].length()))
	return text.substr(0, mini(8, text.length()))
