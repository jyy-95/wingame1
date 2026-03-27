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
var _shine: ColorRect
var _bottom_ribbon: PanelContainer

func _ready() -> void:
	custom_minimum_size = Vector2(68, 82)
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
	_icon.offset_left = 3
	_icon.offset_top = 3
	_icon.offset_right = -3
	_icon.offset_bottom = -3
	body.add_child(_icon)

	_shine = ColorRect.new()
	_shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shine.anchor_right = 1.0
	_shine.anchor_bottom = 0.0
	_shine.offset_left = 4
	_shine.offset_top = 4
	_shine.offset_right = -4
	_shine.offset_bottom = 30
	_shine.color = Color(1, 1, 1, 0.05)
	body.add_child(_shine)

	_star_badge = PanelContainer.new()
	_star_badge.anchor_left = 1.0
	_star_badge.anchor_top = 0.0
	_star_badge.anchor_right = 1.0
	_star_badge.anchor_bottom = 0.0
	_star_badge.offset_left = -24
	_star_badge.offset_top = 3
	_star_badge.offset_right = -3
	_star_badge.offset_bottom = 16
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.11, 0.17, 0.24, 0.88)
	badge_style.border_color = Color(1, 1, 1, 0.22)
	badge_style.border_width_left = 1
	badge_style.border_width_top = 1
	badge_style.border_width_right = 1
	badge_style.border_width_bottom = 1
	badge_style.corner_radius_top_left = 10
	badge_style.corner_radius_top_right = 10
	badge_style.corner_radius_bottom_left = 10
	badge_style.corner_radius_bottom_right = 10
	badge_style.shadow_color = Color(0, 0, 0, 0.22)
	badge_style.shadow_size = 5
	badge_style.shadow_offset = Vector2(0, 2)
	badge_style.anti_aliasing = true
	badge_style.anti_aliasing_size = 1.1
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

	_bottom_ribbon = PanelContainer.new()
	_bottom_ribbon.anchor_left = 0.0
	_bottom_ribbon.anchor_top = 1.0
	_bottom_ribbon.anchor_right = 1.0
	_bottom_ribbon.anchor_bottom = 1.0
	_bottom_ribbon.offset_left = 4
	_bottom_ribbon.offset_top = -20
	_bottom_ribbon.offset_right = -4
	_bottom_ribbon.offset_bottom = -4
	_bottom_ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(_bottom_ribbon)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_name_label.add_theme_font_size_override("font_size", 10)
	_name_label.add_theme_color_override("font_color", Color("f8fbff"))
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom_ribbon.add_child(_name_label)

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
	preview.modulate = Color(1, 1, 1, 0.94)
	var preview_style := StyleBoxFlat.new()
	preview_style.bg_color = Color(0.09, 0.15, 0.21, 0.92)
	preview_style.border_color = Color("f0c47a")
	preview_style.border_width_left = 2
	preview_style.border_width_top = 2
	preview_style.border_width_right = 2
	preview_style.border_width_bottom = 2
	preview_style.corner_radius_top_left = 22
	preview_style.corner_radius_top_right = 22
	preview_style.corner_radius_bottom_left = 22
	preview_style.corner_radius_bottom_right = 22
	preview_style.shadow_color = Color(0, 0, 0, 0.24)
	preview_style.shadow_size = 10
	preview_style.shadow_offset = Vector2(0, 4)
	preview.add_theme_stylebox_override("panel", preview_style)
	var preview_body := MarginContainer.new()
	preview_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_body.add_theme_constant_override("margin_left", 4)
	preview_body.add_theme_constant_override("margin_top", 4)
	preview_body.add_theme_constant_override("margin_right", 4)
	preview_body.add_theme_constant_override("margin_bottom", 4)
	preview.add_child(preview_body)
	var preview_box := VBoxContainer.new()
	preview_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_box.add_theme_constant_override("separation", 4)
	preview_body.add_child(preview_box)
	var preview_icon := IconBadge.new()
	preview_icon.custom_minimum_size = Vector2(58, 58)
	preview_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_box.add_child(preview_icon)
	var label := Label.new()
	label.text = _name_label.text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color("f8fbff"))
	preview_box.add_child(label)
	var preview_color: Color = hero_def.color if hero_def != null else Color("4e6983")
	var hero_id: String = str(hero_def.id) if hero_def != null else ""
	var animation_frames := ArtCatalog.get_hero_animation_frames(hero_id)
	if not animation_frames.is_empty():
		preview_icon.configure_with_animation(animation_frames, 12.0, preview_color, hero_id)
	else:
		var texture := ArtCatalog.get_hero_texture(hero_id)
		if texture != null:
			preview_icon.configure_with_texture(texture, preview_color, true, hero_id)
		else:
			preview_icon.configure(preview_color.lightened(0.18), preview_color.darkened(0.24), Color("f5e4d1"), "avatar")
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
	style.bg_color = Color(base_color.r, base_color.g, base_color.b, 0.24)
	style.border_color = base_color.lightened(0.72)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.shadow_color = Color(0, 0, 0, 0.24)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.2
	add_theme_stylebox_override("panel", style)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = base_color.darkened(0.28)
	badge_style.border_color = base_color.lightened(0.78)
	badge_style.border_width_left = 1
	badge_style.border_width_top = 1
	badge_style.border_width_right = 1
	badge_style.border_width_bottom = 1
	badge_style.corner_radius_top_left = 10
	badge_style.corner_radius_top_right = 10
	badge_style.corner_radius_bottom_left = 10
	badge_style.corner_radius_bottom_right = 10
	badge_style.shadow_color = Color(0, 0, 0, 0.22)
	badge_style.shadow_size = 5
	badge_style.shadow_offset = Vector2(0, 2)
	badge_style.anti_aliasing = true
	badge_style.anti_aliasing_size = 1.1
	_star_badge.add_theme_stylebox_override("panel", badge_style)
	if _bottom_ribbon != null:
		var ribbon_color := base_color.darkened(0.44)
		var ribbon_style := StyleBoxFlat.new()
		ribbon_style.bg_color = Color(ribbon_color.r, ribbon_color.g, ribbon_color.b, 0.92)
		ribbon_style.border_color = base_color.lightened(0.30)
		ribbon_style.border_width_top = 1
		ribbon_style.corner_radius_top_left = 10
		ribbon_style.corner_radius_top_right = 10
		ribbon_style.corner_radius_bottom_left = 12
		ribbon_style.corner_radius_bottom_right = 12
		ribbon_style.shadow_color = Color(0, 0, 0, 0.18)
		ribbon_style.shadow_size = 4
		ribbon_style.shadow_offset = Vector2(0, 1)
		ribbon_style.anti_aliasing = true
		ribbon_style.anti_aliasing_size = 1.1
		_bottom_ribbon.add_theme_stylebox_override("panel", ribbon_style)
	if _shine != null:
		var shine_color := base_color.lightened(0.55)
		_shine.color = Color(shine_color.r, shine_color.g, shine_color.b, 0.08)
	var hero_id: String = str(hero_def.id) if hero_def != null else ""
	var animation_frames := ArtCatalog.get_hero_animation_frames(hero_id)
	if not animation_frames.is_empty():
		_icon.configure_with_animation(animation_frames, 12.0, base_color, hero_id)
		return
	var texture := ArtCatalog.get_hero_texture(hero_id)
	if texture != null:
		_icon.configure_with_texture(texture, base_color, true, hero_id)
	else:
		_icon.configure(base_color.lightened(0.18), base_color.darkened(0.24), Color("f5e4d1"), "avatar")

func _short_name(text: String) -> String:
	if Localization.is_chinese():
		return text.substr(0, mini(4, text.length()))
	var parts := text.split(" ", false)
	if not parts.is_empty():
		return parts[0].substr(0, mini(8, parts[0].length()))
	return text.substr(0, mini(8, text.length()))
