class_name HeroPiece
extends PanelContainer

const IconBadge = preload("res://scripts/ui/icon_badge.gd")
const ArtCatalog = preload("res://scripts/ui/art_catalog.gd")
const BoardSlot = preload("res://scripts/ui/board_slot.gd")

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
var _star_badge: PanelContainer

func _ready() -> void:
	custom_minimum_size = Vector2(80, 40)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	tooltip_text = ""

	var body := Control.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)

	_icon = IconBadge.new()
	_icon.anchor_right = 1.0
	_icon.anchor_bottom = 1.0
	_icon.offset_left = 2
	_icon.offset_top = 2
	_icon.offset_right = -2
	_icon.offset_bottom = -2
	body.add_child(_icon)

	_star_badge = PanelContainer.new()
	_star_badge.anchor_left = 1.0
	_star_badge.anchor_top = 0.0
	_star_badge.anchor_right = 1.0
	_star_badge.anchor_bottom = 0.0
	_star_badge.offset_left = -22
	_star_badge.offset_top = 2
	_star_badge.offset_right = -2
	_star_badge.offset_bottom = 14
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.10, 0.16, 0.22, 0.82)
	badge_style.border_color = Color(1, 1, 1, 0.18)
	badge_style.border_width_left = 1
	badge_style.border_width_top = 1
	badge_style.border_width_right = 1
	badge_style.border_width_bottom = 1
	badge_style.corner_radius_top_left = 9
	badge_style.corner_radius_top_right = 9
	badge_style.corner_radius_bottom_left = 9
	badge_style.corner_radius_bottom_right = 9
	_star_badge.add_theme_stylebox_override("panel", badge_style)
	_star_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(_star_badge)

	_star_label = Label.new()
	_star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_star_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_star_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_star_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_star_label.add_theme_font_size_override("font_size", 8)
	_star_badge.add_child(_star_label)

	_name_label = Label.new()
	_name_label.visible = false
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)

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
	if other == null or hero_def == null or other.hero_def == null:
		return false
	if star_level >= 5 or other.star_level != star_level:
		return false
	var self_id := str(hero_def.id).strip_edges()
	var other_id := str(other.hero_def.id).strip_edges()
	if self_id != "" and self_id == other_id:
		return true
	var self_name := str(hero_def.display_name).strip_edges()
	var other_name := str(other.hero_def.display_name).strip_edges()
	return self_name != "" and self_name == other_name

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

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("piece"):
		return false
	var dragged_piece = data["piece"] as HeroPiece
	if dragged_piece == null or dragged_piece == self:
		return false
	return get_parent() is BoardSlot

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var slot := get_parent() as BoardSlot
	if slot == null or board_manager == null:
		return
	var dragged_piece = data.get("piece") as HeroPiece
	if dragged_piece == null or dragged_piece == self:
		return
	board_manager.handle_drop(dragged_piece, slot)

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
	tooltip_text = get_display_label()
	_star_label.text = "*".repeat(star_level)
	_star_label.add_theme_color_override("font_color", Color("fff0a8"))
	_star_badge.visible = star_level > 0
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
	var texture := ArtCatalog.get_hero_texture(hero_def.id if hero_def != null else "")
	if texture != null:
		_icon.configure_with_texture(texture, base_color)
	else:
		_icon.configure(base_color.lightened(0.18), base_color.darkened(0.24), Color("f5e4d1"), "avatar")

func _short_name(text: String) -> String:
	if Localization.is_chinese():
		return text.substr(0, mini(4, text.length()))
	var parts := text.split(" ", false)
	if not parts.is_empty():
		return parts[0].substr(0, mini(8, parts[0].length()))
	return text.substr(0, mini(8, text.length()))
