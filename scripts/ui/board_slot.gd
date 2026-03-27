class_name BoardSlot
extends PanelContainer

var board_manager
var slot_index := -1
var _frame: ColorRect
var _glow: ColorRect

func _ready() -> void:
	custom_minimum_size = Vector2(68, 82)
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = true
	_frame = ColorRect.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame.offset_left = 7
	_frame.offset_top = 7
	_frame.offset_right = -7
	_frame.offset_bottom = -7
	_frame.color = Color(1, 1, 1, 0.04)
	add_child(_frame)
	_glow = ColorRect.new()
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glow.offset_left = 16
	_glow.offset_top = 12
	_glow.offset_right = -16
	_glow.offset_bottom = -18
	add_child(_glow)
	_update_visual(false)

func bind(in_board_manager, in_slot_index: int) -> void:
	board_manager = in_board_manager
	slot_index = in_slot_index
	name = "Slot%d" % slot_index

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("piece")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if board_manager == null:
		return
	board_manager.handle_drop(data["piece"], self)

func has_piece() -> bool:
	return get_piece() != null

func get_piece() -> HeroPiece:
	for child in get_children():
		if child is HeroPiece:
			return child as HeroPiece
	return null

func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		_update_visual(has_piece())

func _update_visual(filled: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b2b37") if not filled else Color(0.13, 0.20, 0.27, 0.54)
	style.border_color = Color("84bcd7") if not filled else Color(1.0, 0.93, 0.75, 0.26)
	style.border_width_left = 1 if not filled else 2
	style.border_width_top = 1 if not filled else 2
	style.border_width_right = 1 if not filled else 2
	style.border_width_bottom = 1 if not filled else 2
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.shadow_color = Color(0, 0, 0, 0.20)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.1
	add_theme_stylebox_override("panel", style)
	if _frame != null:
		_frame.visible = not filled
		_frame.color = Color(0.72, 0.88, 0.98, 0.08)
	if _glow != null:
		_glow.color = Color(0.56, 0.83, 0.98, 0.10) if not filled else Color(0.98, 0.78, 0.43, 0.08)