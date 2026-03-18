class_name HeroPiece
extends PanelContainer

signal sell_requested(piece: HeroPiece)

var hero_def: HeroDef
var star_level: int = 1
var purchase_value: int = 0
var cooldown_remaining: float = 0.0
var board_manager: Node
var last_target_instance_id: int = 0
var combo_stacks: int = 0

var _name_label: Label
var _star_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(110, 72)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(box)
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_name_label)
	_star_label = Label.new()
	_star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_star_label)
	_update_visuals()

func setup(in_hero_def: HeroDef, in_star_level: int, in_purchase_value: int, in_board_manager: Node) -> void:
	hero_def = in_hero_def
	star_level = in_star_level
	purchase_value = in_purchase_value
	board_manager = in_board_manager
	cooldown_remaining = hero_def.get_interval_for_star(star_level)
	_update_visuals()

func get_display_label() -> String:
	var display_name: String = hero_def.display_name if hero_def != null else Localization.text("option_default")
	if hero_def != null:
		var localized_hero: HeroDef = GameData.get_hero(hero_def.id)
		if localized_hero != null:
			display_name = localized_hero.display_name
	if Localization.is_chinese():
		return "%s %d星" % [display_name, star_level]
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
	var preview: PanelContainer = PanelContainer.new()
	preview.custom_minimum_size = custom_minimum_size
	preview.modulate = Color(1, 1, 1, 0.85)
	var label: Label = Label.new()
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
	var display_name: String = hero_def.display_name if hero_def != null else "Unit"
	if hero_def != null:
		var localized_hero: HeroDef = GameData.get_hero(hero_def.id)
		if localized_hero != null:
			display_name = localized_hero.display_name
	_name_label.text = display_name
	_star_label.text = "*".repeat(star_level)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = hero_def.color.darkened(0.1) if hero_def != null else Color("445566")
	style.border_color = Color.WHITE
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	add_theme_stylebox_override("panel", style)