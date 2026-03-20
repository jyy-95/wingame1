class_name BoardManager
extends Node

signal evolution_ready(hero_id: String, star_level: int)
signal board_changed
signal piece_sold(refund: int)

const BoardSlot = preload("res://scripts/ui/board_slot.gd")
const HeroPiece = preload("res://scripts/ui/hero_piece.gd")

var grid: GridContainer
var battle_root
var slots: Array[BoardSlot] = []

func setup(in_grid: GridContainer, in_battle_root) -> void:
	grid = in_grid
	battle_root = in_battle_root
	_clear_slots()
	for index in range(20):
		var slot: BoardSlot = BoardSlot.new()
		slot.bind(self, index)
		grid.add_child(slot)
		slots.append(slot)

func clear_board() -> void:
	for slot in slots:
		if slot.has_piece():
			var piece: HeroPiece = slot.get_piece()
			slot.remove_child(piece)
			piece.queue_free()
	board_changed.emit()

func get_active_pieces() -> Array[HeroPiece]:
	var result: Array[HeroPiece] = []
	for slot in slots:
		if slot.has_piece():
			result.append(slot.get_piece())
	return result

func has_empty_slot() -> bool:
	for slot in slots:
		if not slot.has_piece():
			return true
	return false

func spawn_hero(hero_id: String, purchase_value: int) -> HeroPiece:
	if not has_empty_slot():
		return null
	var hero_def: HeroDef = GameData.heroes.get(hero_id)
	var piece: HeroPiece = HeroPiece.new()
	piece.setup(hero_def, 1, purchase_value, self)
	piece.sell_requested.connect(_on_piece_sell_requested)

	# 随机选择一个空槽位
	var empty_slots: Array[int] = []
	for index in range(slots.size()):
		if not slots[index].has_piece():
			empty_slots.append(index)

	if empty_slots.is_empty():
		return null

	var random_index = battle_root.run_state.rng.randi_range(0, empty_slots.size() - 1)
	var target_slot = slots[empty_slots[random_index]]
	target_slot.add_child(piece)
	board_changed.emit()
	return piece

func handle_drop(piece: HeroPiece, target_slot: BoardSlot) -> void:
	var source_slot := piece.get_parent() as BoardSlot
	if source_slot == target_slot:
		return
	if not target_slot.has_piece():
		source_slot.remove_child(piece)
		target_slot.add_child(piece)
		board_changed.emit()
		return
	var target_piece: HeroPiece = target_slot.get_piece()
	if piece.can_merge_with(target_piece):
		source_slot.remove_child(piece)
		piece.queue_free()
		target_piece.upgrade_to(target_piece.star_level + 1, piece.purchase_value)

		# 播放合并音效
		if AudioManager != null:
			AudioManager.play_merge()

		board_changed.emit()
		evolution_ready.emit(target_piece.hero_def.id, target_piece.star_level)
		return
	# Swap to keep desktop interaction forgiving.
	source_slot.remove_child(piece)
	target_slot.remove_child(target_piece)
	source_slot.add_child(target_piece)
	target_slot.add_child(piece)
	board_changed.emit()

func get_piece_count_for_role(role_name: String) -> int:
	var total: int = 0
	for piece in get_active_pieces():
		if piece.hero_def.role == role_name:
			total += 1
	return total

func _on_piece_sell_requested(piece: HeroPiece) -> void:
	var slot := piece.get_parent() as BoardSlot
	if slot == null:
		return
	var refund: int = battle_root.economy_system.sell_refund(battle_root.run_state, piece.purchase_value)
	slot.remove_child(piece)
	piece.queue_free()
	piece_sold.emit(refund)
	board_changed.emit()

func _clear_slots() -> void:
	for child in grid.get_children():
		child.queue_free()
	slots.clear()
