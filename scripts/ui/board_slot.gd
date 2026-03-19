class_name BoardSlot
extends PanelContainer

var board_manager
var slot_index := -1

func _ready() -> void:
	custom_minimum_size = Vector2(120, 40)
	mouse_filter = Control.MOUSE_FILTER_STOP
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
	style.bg_color = Color("2f4357") if not filled else Color("49687f")
	style.border_color = Color("d7e6ef") if filled else Color("97c1de")
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.shadow_color = Color(0, 0, 0, 0.16)
	style.shadow_size = 4
	add_theme_stylebox_override("panel", style)
