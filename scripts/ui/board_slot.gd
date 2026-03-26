class_name BoardSlot
extends PanelContainer

var board_manager
var slot_index := -1

func _ready() -> void:
	custom_minimum_size = Vector2(68, 82)
	mouse_filter = Control.MOUSE_FILTER_PASS
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
	return get_child_count() > 0 and get_child(0) is HeroPiece

func get_piece() -> HeroPiece:
	if has_piece():
		return get_child(0) as HeroPiece
	return null

func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		_update_visual(has_piece())

func _update_visual(filled: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("314658") if not filled else Color(0.20, 0.29, 0.37, 0.42)
	style.border_color = Color(0.85, 0.90, 0.94, 0.26) if filled else Color("9fc7de")
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.1
	add_theme_stylebox_override("panel", style)



