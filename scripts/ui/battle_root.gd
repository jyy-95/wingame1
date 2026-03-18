extends Control

const RunState = preload("res://scripts/core/run_state.gd")
const SummonEconomySystem = preload("res://scripts/core/summon_economy_system.gd")
const TraitDraftSystem = preload("res://scripts/core/trait_draft_system.gd")
const TotemSystem = preload("res://scripts/core/totem_system.gd")
const EventDirector = preload("res://scripts/core/event_director.gd")
const WaveDirector = preload("res://scripts/core/wave_director.gd")
const CombatResolver = preload("res://scripts/core/combat_resolver.gd")
const PieceStats = preload("res://scripts/core/piece_stats.gd")
const BoardManager = preload("res://scripts/ui/board_manager.gd")
const EnemyActor = preload("res://scripts/ui/enemy_actor.gd")

const LANE_SIZE := Vector2(640, 520)
const LEAK_LINE_Y := 486.0

var run_state: RunState
var economy_system := SummonEconomySystem.new()
var trait_draft_system := TraitDraftSystem.new()
var totem_system := TotemSystem.new()
var event_director := EventDirector.new()
var wave_director := WaveDirector.new()
var combat_resolver := CombatResolver.new()
var board_manager := BoardManager.new()

var stages: Array[StageDef] = []
var current_stage_index := 0
var current_stage: StageDef
var summon_preview_ids: Array[String] = []
var boss_spawned := false
var bonus_elite_spawned := false
var wave_bombard_applied := false
var battle_paused := true
var run_finished := false
var current_wave_reward_processed := false
var log_lines: Array[String] = []

var modal_mode := ""
var modal_choices: Array = []
var modal_context: Dictionary = {}

var stage_label: Label
var gold_label: Label
var hp_label: Label
var wave_label: Label
var totem_label: RichTextLabel
var trait_label: RichTextLabel
var damage_label: RichTextLabel
var preview_box: VBoxContainer
var log_label: RichTextLabel
var summon_button: Button
var refresh_button: Button
var enemy_layer: Control
var board_grid: GridContainer
var overlay: ColorRect
var modal_title: Label
var modal_subtitle: RichTextLabel
var modal_options_box: VBoxContainer
var modal_reroll_button: Button
var prev_button: Button
var restart_button: Button
var next_button: Button
var language_title_label: Label
var language_option: OptionButton
var controls_title_label: Label
var preview_title_label: Label
var log_title_label: Label
var run_info_title_label: Label
var traits_title_label: Label
var damage_title_label: Label
var core_title_label: Label
var board_title_label: Label

func _ready() -> void:
	add_child(board_manager)
	board_manager.evolution_ready.connect(_on_evolution_ready)
	board_manager.board_changed.connect(_refresh_sidebar_panels)
	board_manager.piece_sold.connect(_on_piece_sold)
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)
	_build_layout()
	_apply_localization()
	stages = GameData.get_stage_list()
	current_stage_index = clampi(SaveService.unlocked_stage_index, 0, max(0, stages.size() - 1))
	_setup_stage(current_stage_index)
	set_process(true)

func _exit_tree() -> void:
	if Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.disconnect(_on_language_changed)

func _process(delta: float) -> void:
	if run_finished:
		_refresh_sidebar_panels()
		return
	if not battle_paused:
		wave_director.update(delta, self)
		for enemy in get_active_enemies():
			enemy.tick(delta, LEAK_LINE_Y)
		combat_resolver.process(delta, self)
		if wave_director.is_wave_complete(self) and not current_wave_reward_processed:
			current_wave_reward_processed = true
			_on_wave_cleared()
	_refresh_sidebar_panels()

func _apply_localization() -> void:
	controls_title_label.text = Localization.text("controls")
	preview_title_label.text = Localization.text("summon_preview")
	log_title_label.text = Localization.text("battle_log")
	run_info_title_label.text = Localization.text("run_info")
	traits_title_label.text = Localization.text("traits")
	damage_title_label.text = Localization.text("damage")
	summon_button.text = Localization.text("summon_hero")
	refresh_button.text = Localization.text("refresh_preview")
	prev_button.text = Localization.text("prev_stage")
	restart_button.text = Localization.text("restart_stage")
	next_button.text = Localization.text("next_stage")
	language_title_label.text = Localization.text("language")
	core_title_label.text = Localization.text("core")
	board_title_label.text = Localization.text("board")
	modal_reroll_button.text = Localization.text("reroll")
	_sync_language_option()
	if run_state != null and current_stage != null:
		_refresh_summon_preview()
		_refresh_sidebar_panels()

func _sync_language_option() -> void:
	if language_option == null:
		return
	for index in range(language_option.get_item_count()):
		var code: String = str(language_option.get_item_metadata(index))
		if code == Localization.current_language:
			language_option.select(index)
			return

func _on_language_selected(index: int) -> void:
	var language_code: String = str(language_option.get_item_metadata(index))
	Localization.set_language(language_code)

func _on_language_changed(_language_code: String) -> void:
	GameData.rebuild()
	stages = GameData.get_stage_list()
	_setup_stage(current_stage_index)
	add_log(Localization.text("language_changed"))
	_apply_localization()
	_refresh_sidebar_panels()

func _build_layout() -> void:
	var background := ColorRect.new()
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.color = Color("0d1624")
	add_child(background)

	var root := HBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 16
	root.offset_top = 16
	root.offset_right = -16
	root.offset_bottom = -16
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	var left_panel := _make_card_panel(Vector2(280, 0))
	root.add_child(left_panel)
	var left_box := _make_full_box(left_panel)
	controls_title_label = _make_section_title("")
	left_box.add_child(controls_title_label)
	gold_label = Label.new()
	hp_label = Label.new()
	left_box.add_child(gold_label)
	left_box.add_child(hp_label)
	summon_button = Button.new()
	summon_button.text = ""
	summon_button.pressed.connect(_on_summon_pressed)
	left_box.add_child(summon_button)
	refresh_button = Button.new()
	refresh_button.text = ""
	refresh_button.pressed.connect(_on_refresh_pressed)
	left_box.add_child(refresh_button)
	preview_title_label = _make_section_title("")
	left_box.add_child(preview_title_label)
	preview_box = VBoxContainer.new()
	preview_box.add_theme_constant_override("separation", 6)
	left_box.add_child(preview_box)
	log_title_label = _make_section_title("")
	left_box.add_child(log_title_label)
	log_label = RichTextLabel.new()
	log_label.fit_content = true
	log_label.scroll_active = true
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_box.add_child(log_label)

	var center_panel := _make_card_panel(Vector2(0, 0))
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(center_panel)
	var center_box := _make_full_box(center_panel)
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 10)
	center_box.add_child(top_bar)
	prev_button = Button.new()
	prev_button.text = ""
	prev_button.pressed.connect(_change_stage.bind(-1))
	top_bar.add_child(prev_button)
	stage_label = Label.new()
	stage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_bar.add_child(stage_label)
	restart_button = Button.new()
	restart_button.text = ""
	restart_button.pressed.connect(_restart_current_stage)
	top_bar.add_child(restart_button)
	next_button = Button.new()
	next_button.text = ""
	next_button.pressed.connect(_change_stage.bind(1))
	top_bar.add_child(next_button)
	language_title_label = Label.new()
	top_bar.add_child(language_title_label)
	language_option = OptionButton.new()
	language_option.add_item("简体中文")
	language_option.set_item_metadata(0, Localization.LANGUAGE_ZH)
	language_option.add_item("English")
	language_option.set_item_metadata(1, Localization.LANGUAGE_EN)
	language_option.item_selected.connect(_on_language_selected)
	top_bar.add_child(language_option)

	var battle_frame := PanelContainer.new()
	battle_frame.custom_minimum_size = Vector2(720, 830)
	battle_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_box.add_child(battle_frame)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color("13263d")
	frame_style.corner_radius_top_left = 14
	frame_style.corner_radius_top_right = 14
	frame_style.corner_radius_bottom_left = 14
	frame_style.corner_radius_bottom_right = 14
	battle_frame.add_theme_stylebox_override("panel", frame_style)

	var battle_canvas := Control.new()
	battle_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_canvas.custom_minimum_size = Vector2(720, 830)
	battle_frame.add_child(battle_canvas)
	var lane_bg := ColorRect.new()
	lane_bg.position = Vector2(40, 38)
	lane_bg.size = LANE_SIZE
	lane_bg.color = Color("17324f")
	battle_canvas.add_child(lane_bg)
	var lane_path := ColorRect.new()
	lane_path.position = Vector2(300, 38)
	lane_path.size = Vector2(120, LANE_SIZE.y)
	lane_path.color = Color("264d73")
	battle_canvas.add_child(lane_path)
	enemy_layer = Control.new()
	enemy_layer.position = lane_bg.position
	enemy_layer.custom_minimum_size = LANE_SIZE
	enemy_layer.size = LANE_SIZE
	battle_canvas.add_child(enemy_layer)
	var leak_line := ColorRect.new()
	leak_line.position = lane_bg.position + Vector2(0, LEAK_LINE_Y)
	leak_line.size = Vector2(LANE_SIZE.x, 3)
	leak_line.color = Color("ef476f")
	battle_canvas.add_child(leak_line)
	core_title_label = Label.new()
	core_title_label.text = ""
	core_title_label.position = lane_bg.position + Vector2(290, LEAK_LINE_Y + 8)
	battle_canvas.add_child(core_title_label)
	board_title_label = Label.new()
	board_title_label.text = ""
	board_title_label.position = Vector2(320, 572)
	battle_canvas.add_child(board_title_label)
	board_grid = GridContainer.new()
	board_grid.columns = 5
	board_grid.position = Vector2(54, 606)
	board_grid.custom_minimum_size = Vector2(612, 180)
	board_grid.add_theme_constant_override("h_separation", 8)
	board_grid.add_theme_constant_override("v_separation", 8)
	battle_canvas.add_child(board_grid)
	board_manager.setup(board_grid, self)

	var right_panel := _make_card_panel(Vector2(310, 0))
	root.add_child(right_panel)
	var right_box := _make_full_box(right_panel)
	run_info_title_label = _make_section_title("")
	right_box.add_child(run_info_title_label)
	wave_label = Label.new()
	right_box.add_child(wave_label)
	totem_label = RichTextLabel.new()
	totem_label.fit_content = true
	right_box.add_child(totem_label)
	traits_title_label = _make_section_title("")
	right_box.add_child(traits_title_label)
	trait_label = RichTextLabel.new()
	trait_label.fit_content = true
	trait_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_box.add_child(trait_label)
	damage_title_label = _make_section_title("")
	right_box.add_child(damage_title_label)
	damage_label = RichTextLabel.new()
	damage_label.fit_content = true
	damage_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_box.add_child(damage_label)

	overlay = ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0, 0, 0, 0.62)
	overlay.visible = false
	add_child(overlay)
	var modal_panel := PanelContainer.new()
	modal_panel.custom_minimum_size = Vector2(680, 420)
	modal_panel.position = Vector2(460, 190)
	overlay.add_child(modal_panel)
	var modal_style := StyleBoxFlat.new()
	modal_style.bg_color = Color("102338")
	modal_style.corner_radius_top_left = 16
	modal_style.corner_radius_top_right = 16
	modal_style.corner_radius_bottom_left = 16
	modal_style.corner_radius_bottom_right = 16
	modal_panel.add_theme_stylebox_override("panel", modal_style)
	var modal_box := _make_full_box(modal_panel)
	modal_title = Label.new()
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_title.add_theme_font_size_override("font_size", 24)
	modal_box.add_child(modal_title)
	modal_subtitle = RichTextLabel.new()
	modal_subtitle.fit_content = true
	modal_subtitle.bbcode_enabled = true
	modal_box.add_child(modal_subtitle)
	modal_options_box = VBoxContainer.new()
	modal_options_box.add_theme_constant_override("separation", 10)
	modal_options_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_box.add_child(modal_options_box)
	modal_reroll_button = Button.new()
	modal_reroll_button.text = ""
	modal_reroll_button.visible = false
	modal_reroll_button.pressed.connect(_on_modal_reroll_pressed)
	modal_box.add_child(modal_reroll_button)

func _setup_stage(index: int) -> void:
	current_stage_index = clampi(index, 0, max(0, stages.size() - 1))
	current_stage = stages[current_stage_index]
	if overlay.visible:
		_close_modal()
	run_state = RunState.new(_make_seed(), current_stage.id, current_stage_index)
	wave_director.setup(current_stage)
	board_manager.clear_board()
	for enemy in get_active_enemies():
		enemy_layer.remove_child(enemy)
		enemy.queue_free()
	boss_spawned = false
	bonus_elite_spawned = false
	wave_bombard_applied = false
	battle_paused = true
	run_finished = false
	current_wave_reward_processed = false
	run_state.gold = 35
	run_state.base_hp = 10
	run_state.max_base_hp = 10
	run_state.rerolls = 1
	summon_preview_ids.clear()
	log_lines.clear()
	_refresh_summon_preview()
	add_log(Localization.format_text("entered_stage", [current_stage.display_name, run_state.seed]))
	_show_totem_selection()

func _make_seed() -> int:
	return int(Time.get_unix_time_from_system()) + current_stage_index * 97

func _on_summon_pressed() -> void:
	if battle_paused and modal_mode == "":
		return
	if not board_manager.has_empty_slot():
		add_log(Localization.text("board_full"))
		return
	var cost := economy_system.pay_for_summon(run_state)
	if cost < 0:
		add_log(Localization.text("not_enough_gold"))
		return
	if summon_preview_ids.is_empty():
		_refresh_summon_preview()
	var hero_id := summon_preview_ids[run_state.rng.randi_range(0, summon_preview_ids.size() - 1)]
	var piece = board_manager.spawn_hero(hero_id, cost)
	if piece == null:
		if cost > 0:
			run_state.add_gold(cost)
		add_log(Localization.text("no_free_slot"))
		return
	add_log(Localization.format_text("summoned", [piece.get_display_label()]))
	_refresh_summon_preview()

func _on_refresh_pressed() -> void:
	if not economy_system.pay_for_refresh(run_state):
		add_log(Localization.text("cannot_refresh"))
		return
	_refresh_summon_preview()
	add_log(Localization.text("preview_refreshed"))

func _refresh_summon_preview() -> void:
	summon_preview_ids.clear()
	var selected: Array[String] = []
	while summon_preview_ids.size() < 3:
		var hero_id := _pick_weighted_hero(selected)
		summon_preview_ids.append(hero_id)
		selected.append(hero_id)
	for child in preview_box.get_children():
		child.queue_free()
	for hero_id in summon_preview_ids:
		var hero_def: HeroDef = GameData.heroes[hero_id]
		var card := Label.new()
		card.text = "%s | %s" % [hero_def.display_name, Localization.role_name(hero_def.role)]
		preview_box.add_child(card)

func _pick_weighted_hero(excluded: Array[String]) -> String:
	var total_weight := 0
	for hero_id in GameData.heroes.keys():
		if excluded.has(hero_id):
			continue
		total_weight += GameData.heroes[hero_id].weight
	var roll := run_state.rng.randi_range(1, total_weight)
	var cursor := 0
	for hero_id in GameData.heroes.keys():
		if excluded.has(hero_id):
			continue
		cursor += GameData.heroes[hero_id].weight
		if roll <= cursor:
			return hero_id
	return GameData.heroes.keys()[0]

func spawn_enemy(enemy_id: String, force_boss: bool = false) -> void:
	var enemy_def: EnemyDef = GameData.enemies[enemy_id]
	var hp_scale := 1.0 + current_stage.difficulty * 0.12 + maxf(0.0, float(run_state.current_wave_index)) * 0.08
	if enemy_def.is_boss or force_boss:
		hp_scale *= 1.55
	var speed_scale := 1.0 + current_stage.chapter * 0.03
	var reward_bonus := 0
	if enemy_def.tags.has("elite") or enemy_def.tags.has("boss"):
		reward_bonus += int(wave_director.modifiers.get("bonus_elite_reward", 0))
	var enemy := EnemyActor.new()
	enemy.setup(enemy_def, hp_scale, speed_scale, reward_bonus)
	enemy.position = Vector2((LANE_SIZE.x * 0.5) + run_state.rng.randf_range(-120.0, 120.0), -30.0)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.leaked.connect(_on_enemy_leaked)
	enemy_layer.add_child(enemy)
	if enemy_def.is_boss or force_boss:
		boss_spawned = true

func apply_wave_bombard(amount: float) -> void:
	for enemy in get_active_enemies():
		enemy.apply_damage(amount)
	add_log(Localization.text("bombard_triggered"))

func get_active_enemies() -> Array[EnemyActor]:
	var result: Array[EnemyActor] = []
	for child in enemy_layer.get_children():
		if child is EnemyActor:
			result.append(child)
	return result

func get_active_enemy_count() -> int:
	return get_active_enemies().size()

func _on_enemy_defeated(enemy: EnemyActor) -> void:
	if not is_instance_valid(enemy):
		return
	run_state.add_gold(enemy.reward)
	if run_state.has_trait("bounty_chain") and (enemy.enemy_def.tags.has("elite") or enemy.enemy_def.tags.has("boss")):
		run_state.add_gold(15)
	run_state.register_kill()
	add_log(Localization.format_text("defeated_enemy", [enemy.enemy_def.display_name]))
	if enemy.get_parent() != null:
		enemy.get_parent().remove_child(enemy)
	enemy.queue_free()

func _on_enemy_leaked(enemy: EnemyActor) -> void:
	if not is_instance_valid(enemy):
		return
	var damage := enemy.enemy_def.contact_damage
	if board_manager.get_piece_count_for_role("vanguard") >= 2:
		damage = maxi(1, damage - 1)
	run_state.lose_base_hp(damage)
	add_log(Localization.format_text("leak_damage", [damage]))
	if enemy.get_parent() != null:
		enemy.get_parent().remove_child(enemy)
	enemy.queue_free()
	if run_state.base_hp <= 0:
		_end_run(false)

func _on_wave_cleared() -> void:
	battle_paused = true
	var wave := current_stage.wave_defs[run_state.current_wave_index]
	var reward := wave.reward + int(_get_numeric_modifier("wave_bonus_gold"))
	run_state.add_gold(reward)
	add_log(Localization.format_text("wave_clear", [wave.label]))
	if run_state.current_wave_index >= current_stage.wave_defs.size() - 1:
		_end_run(true)
		return
	var followup := "next_wave"
	if run_state.current_wave_index == 1 or run_state.current_wave_index == 3:
		followup = "event_then_next_wave"
	_show_global_trait_draft(followup)

func _start_wave(index: int) -> void:
	if index >= current_stage.wave_defs.size():
		_end_run(true)
		return
	run_state.current_wave_index = index
	boss_spawned = false
	bonus_elite_spawned = false
	wave_bombard_applied = false
	current_wave_reward_processed = false
	wave_director.start_wave(index, run_state)
	battle_paused = false
	add_log(Localization.format_text("start_wave", [index + 1]))

func _show_totem_selection() -> void:
	var choices: Array = []
	for totem in GameData.get_totem_choices_for_stage(current_stage):
		choices.append({"title": totem.display_name, "description": totem.description, "payload": totem})
	_open_modal(Localization.text("pick_totem"), Localization.text("pick_totem_desc"), choices, "totem", {}, false)

func _show_global_trait_draft(followup: String) -> void:
	var choices := trait_draft_system.build_global_choices(run_state)
	if choices.is_empty():
		if followup == "event_then_next_wave":
			_show_event()
		else:
			_start_wave(run_state.current_wave_index + 1)
		return
	var modal_entries: Array = []
	for trait_def in choices:
		modal_entries.append({"title": trait_def.display_name, "description": trait_def.description, "payload": trait_def})
	_open_modal(Localization.text("pick_trait"), Localization.text("pick_trait_desc"), modal_entries, "global_trait", {"followup": followup}, true)

func _show_evolution_draft(hero_id: String, star_level: int) -> void:
	var choices := trait_draft_system.build_evolution_choices(run_state, hero_id)
	if choices.is_empty():
		run_state.mark_evolution_breakpoint(hero_id, star_level)
		battle_paused = false
		return
	var modal_entries: Array = []
	for trait_def in choices:
		modal_entries.append({"title": trait_def.display_name, "description": trait_def.description, "payload": trait_def})
	var hero_def: HeroDef = GameData.heroes[hero_id]
	_open_modal(Localization.text("evolution_trait"), Localization.format_text("evolution_reached", [hero_def.display_name, star_level]), modal_entries, "evolution_trait", {"hero_id": hero_id, "star_level": star_level}, true)

func _show_event() -> void:
	var event_def := event_director.pick_event(run_state)
	var modal_entries: Array = []
	for option in event_def.options:
		modal_entries.append({"title": option.get("label", Localization.text("option_default")), "description": option.get("description", ""), "payload": option})
	_open_modal(event_def.display_name, event_def.description, modal_entries, "event", {}, false)

func _open_modal(title: String, subtitle: String, choices: Array, mode: String, context: Dictionary, allow_reroll: bool) -> void:
	modal_mode = mode
	modal_choices = choices
	modal_context = context
	battle_paused = true
	overlay.visible = true
	modal_title.text = title
	modal_subtitle.clear()
	modal_subtitle.append_text(subtitle)
	for child in modal_options_box.get_children():
		child.queue_free()
	for index in range(modal_choices.size()):
		var entry = modal_choices[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 72)
		button.text = "%s\n%s" % [entry["title"], entry["description"]]
		button.pressed.connect(_on_modal_option_pressed.bind(index))
		modal_options_box.add_child(button)
	modal_reroll_button.visible = allow_reroll and run_state.rerolls > 0

func _close_modal() -> void:
	overlay.visible = false
	modal_mode = ""
	modal_choices.clear()
	modal_context.clear()

func _on_modal_option_pressed(index: int) -> void:
	var entry = modal_choices[index]
	match modal_mode:
		"run_end":
			var action: String = str(entry["payload"].get("action", "restart"))
			_close_modal()
			if action == "next_stage":
				_setup_stage(current_stage_index + 1)
			else:
				_setup_stage(current_stage_index)
		"totem":
			var totem: TotemDef = entry["payload"]
			run_state.totem_id = totem.id
			add_log(Localization.format_text("totem_selected", [totem.display_name]))
			_close_modal()
			_start_wave(0)
		"global_trait":
			var trait_def: TraitDef = entry["payload"]
			run_state.add_global_trait(trait_def)
			_apply_immediate_trait_effects(trait_def)
			add_log(Localization.format_text("trait_selected", [trait_def.display_name]))
			var followup: String = str(modal_context.get("followup", "next_wave"))
			_close_modal()
			if followup == "event_then_next_wave":
				_show_event()
			else:
				_start_wave(run_state.current_wave_index + 1)
		"evolution_trait":
			var evo_trait: TraitDef = entry["payload"]
			var hero_id: String = str(modal_context.get("hero_id", ""))
			var star_level: int = int(modal_context.get("star_level", 3))
			run_state.add_evolution_trait(hero_id, star_level, evo_trait)
			add_log(Localization.format_text("evolution_selected", [evo_trait.display_name]))
			_close_modal()
			battle_paused = false
		"event":
			var option: Dictionary = entry["payload"]
			event_director.apply_option(run_state, option, self)
			_close_modal()
			_start_wave(run_state.current_wave_index + 1)

func _on_modal_reroll_pressed() -> void:
	if run_state.rerolls <= 0:
		return
	run_state.rerolls -= 1
	match modal_mode:
		"global_trait":
			_show_global_trait_draft(str(modal_context.get("followup", "next_wave")))
		"evolution_trait":
			_show_evolution_draft(str(modal_context.get("hero_id", "")), int(modal_context.get("star_level", 3)))

func _apply_immediate_trait_effects(trait_def: TraitDef) -> void:
	if trait_def.modifiers.has("starting_gold"):
		run_state.add_gold(int(trait_def.modifiers["starting_gold"]))
	if trait_def.modifiers.has("core_hp"):
		var bonus_hp := int(trait_def.modifiers["core_hp"])
		run_state.max_base_hp += bonus_hp
		run_state.base_hp += bonus_hp

func _on_evolution_ready(hero_id: String, star_level: int) -> void:
	if run_state.needs_evolution_draft(hero_id, star_level):
		_show_evolution_draft(hero_id, star_level)

func _on_piece_sold(refund: int) -> void:
	run_state.add_gold(refund)
	add_log(Localization.format_text("sold_piece", [refund]))

func _end_run(victory: bool) -> void:
	run_finished = true
	battle_paused = true
	if victory:
		SaveService.register_stage_clear(current_stage_index, run_state.seed)
		_open_modal(Localization.text("stage_clear_title"), Localization.text("stage_clear_desc"), [{"title": Localization.text("restart_stage"), "description": Localization.text("restart_desc"), "payload": {"action": "restart"}}, {"title": Localization.text("next_stage"), "description": Localization.text("next_stage_desc"), "payload": {"action": "next_stage"}}], "run_end", {}, false)
	else:
		_open_modal(Localization.text("defeat_title"), Localization.text("defeat_desc"), [{"title": Localization.text("restart_stage"), "description": Localization.text("retry_desc"), "payload": {"action": "restart"}}], "run_end", {}, false)
	add_log(Localization.text("run_ended"))

func get_piece_combat_stats(piece) -> PieceStats:
	var stats := PieceStats.new()
	stats.damage = piece.hero_def.get_damage_for_star(piece.star_level)
	stats.attack_interval = piece.hero_def.get_interval_for_star(piece.star_level)
	stats.attack_range = piece.hero_def.get_range_for_star(piece.star_level)
	stats.splash_radius = piece.hero_def.splash_radius
	stats.mode = piece.hero_def.attack_mode
	_apply_hero_identity(piece, stats)
	var modifiers := _collect_piece_modifiers(piece)
	for key in modifiers.keys():
		var value = modifiers[key]
		match key:
			"damage_flat":
				stats.damage += float(value)
			"damage_pct":
				stats.damage *= 1.0 + float(value)
			"attack_speed_pct":
				stats.attack_interval /= maxf(0.2, 1.0 + float(value))
			"range_flat":
				stats.attack_range += float(value)
			"crit_chance":
				stats.crit_chance += float(value)
			"crit_damage":
				stats.crit_damage_bonus += float(value)
			"freeze_chance":
				stats.freeze_chance += float(value)
			"freeze_duration_pct":
				stats.freeze_duration_pct += float(value)
			"poison_dps":
				stats.poison_dps += float(value)
			"poison_splash_radius":
				stats.poison_splash_radius = maxf(stats.poison_splash_radius, float(value))
			"execute_threshold":
				stats.execute_threshold += float(value)
			"healthy_damage_pct":
				stats.healthy_damage_pct += float(value)
			"bonus_vs_frozen":
				stats.bonus_vs_frozen += float(value)
			"bonus_vs_armor":
				stats.bonus_vs_armor += float(value)
			"slow_chance":
				stats.slow_chance += float(value)
			"slow_pct":
				stats.slow_pct += float(value)
			"push_chance":
				stats.push_chance += float(value)
			"push_distance":
				stats.push_distance += float(value)
			"chain_hits":
				stats.chain_hits += int(value)
			"pierce_targets":
				stats.pierce_targets += int(value)
			"combo_pct":
				stats.combo_pct += float(value)
			"totem_charge_on_hit":
				stats.totem_charge_on_hit += float(value)
			"crit_splash_radius":
				stats.crit_splash_radius = maxf(stats.crit_splash_radius, float(value))
			"crit_splash_pct":
				stats.crit_splash_pct += float(value)
			"mode_override":
				stats.mode = str(value)
			"splash_flat":
				stats.splash_radius += float(value)
	if stats.splash_radius <= 0.0 and stats.mode == "splash":
		stats.splash_radius = 60.0
	stats.crit_chance = clampf(stats.crit_chance, 0.0, 0.8)
	stats.execute_threshold = clampf(stats.execute_threshold, 0.0, 0.65)
	return stats

func _apply_hero_identity(piece, stats: PieceStats) -> void:
	match piece.hero_def.id:
		"ember_mage":
			stats.crit_chance += 0.08
		"frost_oracle":
			stats.freeze_chance += 0.16
		"tide_guard":
			stats.slow_chance += 0.15
			stats.slow_pct += 0.18
		"blade_dancer":
			stats.execute_threshold += 0.06
		"venom_sage":
			stats.poison_dps += 4.0
		"storm_caller":
			stats.chain_hits += 1
		"iron_warden":
			stats.slow_chance += 0.2
			stats.slow_pct += 0.15
		"solar_priest":
			stats.pierce_targets += 1
			stats.attack_range += 20.0

func _collect_piece_modifiers(piece) -> Dictionary:
	var merged: Dictionary = {}
	for trait_def in run_state.active_global_traits:
		_merge_modifiers(merged, trait_def.modifiers, piece)
	for trait_def in run_state.get_traits_for_hero(piece.hero_def.id):
		_merge_modifiers(merged, trait_def.modifiers, piece)
	_merge_modifiers(merged, totem_system.get_passive_modifiers(run_state), piece)
	var role_counts := {
		"control": board_manager.get_piece_count_for_role("control"),
		"striker": board_manager.get_piece_count_for_role("striker"),
		"vanguard": board_manager.get_piece_count_for_role("vanguard")
	}
	if role_counts.control >= 2:
		_merge_modifiers(merged, {"freeze_duration_pct": 0.35}, piece)
	if role_counts.striker >= 3:
		_merge_modifiers(merged, {"execute_threshold": 0.12}, piece)
	if float(wave_director.modifiers.get("wave_haste", 0.0)) > 0.0:
		_merge_modifiers(merged, {"attack_speed_pct": float(wave_director.modifiers.get("wave_haste", 0.0))}, piece)
	if float(wave_director.modifiers.get("wave_damage", 0.0)) > 0.0:
		_merge_modifiers(merged, {"damage_pct": float(wave_director.modifiers.get("wave_damage", 0.0))}, piece)
	if run_state.kill_haste_stacks > 0:
		_merge_modifiers(merged, {"attack_speed_pct": run_state.kill_haste_stacks * 0.02}, piece)
	return merged

func _merge_modifiers(target: Dictionary, source: Dictionary, piece) -> void:
	for key in source.keys():
		var value = source[key]
		if key.begins_with("tag_damage:"):
			var tag: String = str(key.get_slice(":", 1))
			if piece.hero_def.tags.has(tag):
				target["damage_pct"] = target.get("damage_pct", 0.0) + float(value)
			continue
		if key.begins_with("mode_damage:"):
			var mode: String = str(key.get_slice(":", 1))
			if piece.hero_def.attack_mode == mode:
				target["damage_pct"] = target.get("damage_pct", 0.0) + float(value)
			continue
		if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
			target[key] = target.get(key, 0.0) + value
		else:
			target[key] = value
	if source.has("damage_per_core_loss_pct"):
		target["damage_pct"] = target.get("damage_pct", 0.0) + ((run_state.max_base_hp - run_state.base_hp) * float(source["damage_per_core_loss_pct"]))

func _get_numeric_modifier(key: String) -> float:
	var total := 0.0
	for trait_def in run_state.active_global_traits:
		total += float(trait_def.modifiers.get(key, 0.0))
	return total

func _refresh_sidebar_panels() -> void:
	stage_label.text = Localization.format_text("stage_seed", [current_stage.display_name, run_state.seed])
	gold_label.text = Localization.format_text("gold_line", [run_state.gold, economy_system.current_cost(run_state)])
	hp_label.text = Localization.format_text("hp_line", [run_state.base_hp, run_state.max_base_hp, run_state.rerolls])
	wave_label.text = Localization.format_text("wave_line", [maxi(0, run_state.current_wave_index + 1), current_stage.wave_defs.size(), get_active_enemy_count()])
	_refresh_rich_text_panels()
	summon_button.disabled = battle_paused or run_finished
	refresh_button.disabled = run_finished

func _refresh_rich_text_panels() -> void:
	totem_label.clear()
	var totem: TotemDef = GameData.totems.get(run_state.totem_id) as TotemDef
	if totem != null:
		totem_label.append_text(Localization.format_text("totem_info", [totem.display_name, run_state.totem_level, totem.description]))
	else:
		totem_label.append_text(Localization.text("totem_none"))
	trait_label.clear()
	if run_state.active_global_traits.is_empty() and run_state.active_evolution_traits.is_empty():
		trait_label.append_text(Localization.text("no_traits_yet"))
	else:
		for trait_def in run_state.active_global_traits:
			trait_label.append_text("- %s\n" % trait_def.display_name)
		for hero_id in run_state.active_evolution_traits.keys():
			for trait_def in run_state.active_evolution_traits[hero_id]:
				trait_label.append_text("- %s - %s\n" % [GameData.heroes[hero_id].display_name, trait_def.display_name])
	damage_label.clear()
	if run_state.damage_stats.is_empty():
		damage_label.append_text(Localization.text("no_damage_stats_yet"))
	else:
		var entries: Array = []
		for key in run_state.damage_stats.keys():
			entries.append({"name": key, "value": run_state.damage_stats[key]})
		entries.sort_custom(func(a, b): return a["value"] > b["value"])
		for entry in entries:
			damage_label.append_text("%s: %d\n" % [entry["name"], int(round(entry["value"]))])
	log_label.clear()
	for line in log_lines:
		log_label.append_text("%s\n" % line)

func add_log(text: String) -> void:
	log_lines.append(text)
	if log_lines.size() > 12:
		log_lines.pop_front()

func _change_stage(offset: int) -> void:
	_setup_stage(current_stage_index + offset)

func _restart_current_stage() -> void:
	_setup_stage(current_stage_index)

func _make_card_panel(min_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color("15283d")
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _make_full_box(parent: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 16
	box.offset_top = 16
	box.offset_right = -16
	box.offset_bottom = -16
	box.add_theme_constant_override("separation", 10)
	parent.add_child(box)
	return box

func _make_section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	return label
