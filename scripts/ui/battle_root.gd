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
const IconBadge = preload("res://scripts/ui/icon_badge.gd")
const ArtCatalog = preload("res://scripts/ui/art_catalog.gd")

const LANE_COUNT := 4
const MAX_LOG_LINES := 14
const TOTEM_BASE_COST := 60
const TOTEM_COST_STEP := 20
const BOARD_BASE_SIZE := Vector2(1600, 900)
const DEPLOY_PANEL_TOP := 588.0
const DEPLOY_PANEL_BOTTOM_GAP := 8.0
const BOTTOM_BAR_HEIGHT := 60.0
const BOTTOM_BAR_BOTTOM_MARGIN := 18.0

var run_state: RunState
var economy_system := SummonEconomySystem.new()
var trait_draft_system := TraitDraftSystem.new()
var totem_system := TotemSystem.new()
var event_director := EventDirector.new()
var wave_director := WaveDirector.new()
var combat_resolver := CombatResolver.new()
var board_manager := BoardManager.new()

var stages: Array = []
var current_stage_index := 0
var current_stage
var random_hint_ids: Array[String] = []
var boss_spawned := false
var bonus_elite_spawned := false
var wave_bombard_applied := false
var battle_paused := true
var run_finished := false
var current_wave_reward_processed := false
var log_lines: Array[String] = []
var battle_speed := 1.0

var modal_mode := ""
var modal_choices: Array = []
var modal_context: Dictionary = {}

var stage_kicker_label: Label
var stage_label: Label
var wave_badge_label: Label
var enemy_badge_label: Label
var trait_badge_label: Label
var gold_value_label: Label
var summon_cost_label: Label
var core_meta_label: Label
var core_value_label: Label
var core_fill: ColorRect
var totem_icon: IconBadge
var totem_name_label: Label
var totem_desc_label: RichTextLabel
var totem_charge_label: Label
var random_hint_label: Label
var deploy_title_label: Label
var deploy_hint_label: Label
var summon_button: Button
var summon_button_cost_label: Label
var totem_button: Button
var totem_button_cost_label: Label
var prev_button: Button
var restart_button: Button
var next_button: Button
var language_title_label: Label
var language_option: OptionButton
var quick_speed_button: Button
var quick_speed_label: Label
var quick_stats_button: Button
var quick_stats_label: Label
var quick_log_button: Button
var quick_log_label: Label
var wave_status_label: Label
var trait_label: RichTextLabel
var damage_label: RichTextLabel
var log_label: RichTextLabel
var enemy_layer: Control
var effect_layer: Control
var lane_guides: Array[PanelContainer] = []
var leak_line: ColorRect
var board_grid: GridContainer
var overlay: ColorRect
var modal_title: Label
var modal_subtitle: RichTextLabel
var modal_options_box: GridContainer
var modal_reroll_button: Button
var threat_badge: IconBadge
var stats_panel: PanelContainer
var log_panel: PanelContainer
var shell_root: Control
var board_backdrop: PanelContainer
var top_row: Control
var top_stage_stack: VBoxContainer
var top_utility_box: HBoxContainer
var left_rail: VBoxContainer
var right_rail: VBoxContainer
var totem_card: PanelContainer
var threat_wrap: PanelContainer
var battlefield_frame: PanelContainer
var deploy_panel: PanelContainer
var bottom_bar: HBoxContainer
var money_panel: PanelContainer
var core_panel: PanelContainer
var actions_panel: PanelContainer

func _ready() -> void:
	add_child(board_manager)
	board_manager.evolution_ready.connect(_on_evolution_ready)
	board_manager.board_changed.connect(_refresh_status_panels)
	board_manager.piece_sold.connect(_on_piece_sold)
	if not Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.connect(_on_language_changed)
	_build_layout()
	_apply_responsive_layout()
	_apply_localization()
	stages = GameData.get_stage_list()
	current_stage_index = clampi(SaveService.unlocked_stage_index, 0, max(0, stages.size() - 1))
	_setup_stage(current_stage_index)
	set_process(true)
	call_deferred("_update_lane_guides")

func _exit_tree() -> void:
	Engine.time_scale = 1.0
	if Localization.language_changed.is_connected(_on_language_changed):
		Localization.language_changed.disconnect(_on_language_changed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and shell_root != null:
		call_deferred("_apply_responsive_layout")
func _process(delta: float) -> void:
	if run_finished:
		_refresh_status_panels()
		return
	if not battle_paused:
		wave_director.update(delta, self)
		for enemy in get_active_enemies():
			enemy.tick(delta, get_leak_line_y())
		combat_resolver.process(delta, self)
		if wave_director.is_wave_complete(self) and not current_wave_reward_processed:
			current_wave_reward_processed = true
			_on_wave_cleared()
	_refresh_status_panels()

func _build_layout() -> void:
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = _make_gradient_texture(
		[Color("071018"), Color("112131"), Color("081018")],
		PackedFloat32Array([0.0, 0.38, 1.0]),
		Vector2(0.18, 0.0),
		Vector2(0.82, 1.0),
		Vector2i(1200, 1200)
	)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(background)
	var top_glow := TextureRect.new()
	top_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_glow.texture = _make_radial_texture(
		[Color(0.48, 0.78, 1.0, 0.22), Color(0.48, 0.78, 1.0, 0.0)],
		PackedFloat32Array([0.0, 1.0]),
		Vector2(0.5, 0.0),
		Vector2(1.2, 0.62),
		Vector2i(1200, 720)
	)
	top_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_glow.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(top_glow)
	shell_root = Control.new()
	shell_root.size = BOARD_BASE_SIZE
	add_child(shell_root)
	board_backdrop = PanelContainer.new()
	board_backdrop.position = Vector2.ZERO
	board_backdrop.size = BOARD_BASE_SIZE
	board_backdrop.clip_contents = true
	board_backdrop.add_theme_stylebox_override("panel", _make_surface_style(Color("0c1822"), Color("bfd8e8"), 34))
	shell_root.add_child(board_backdrop)
	var board_sheen := TextureRect.new()
	board_sheen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_sheen.texture = _make_gradient_texture(
		[
			Color(0.76, 0.90, 1.0, 0.18),
			Color(0.76, 0.90, 1.0, 0.05),
			Color(0.04, 0.08, 0.12, 0.0)
		],
		PackedFloat32Array([0.0, 0.28, 1.0]),
		Vector2(0.0, 0.0),
		Vector2(1.0, 1.0),
		Vector2i(900, 900)
	)
	board_sheen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board_sheen.stretch_mode = TextureRect.STRETCH_SCALE
	board_backdrop.add_child(board_sheen)
	var board_side_vignette := TextureRect.new()
	board_side_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_side_vignette.texture = _make_gradient_texture(
		[
			Color(0.14, 0.25, 0.33, 0.68),
			Color(0.14, 0.25, 0.33, 0.0),
			Color(0.14, 0.25, 0.33, 0.0),
			Color(0.14, 0.25, 0.33, 0.64)
		],
		PackedFloat32Array([0.0, 0.14, 0.86, 1.0]),
		Vector2(0.0, 0.5),
		Vector2(1.0, 0.5),
		Vector2i(900, 900)
	)
	board_side_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board_side_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	board_backdrop.add_child(board_side_vignette)
	var floor_glow := TextureRect.new()
	floor_glow.size = Vector2(920, 210)
	floor_glow.position = Vector2((BOARD_BASE_SIZE.x - floor_glow.size.x) * 0.5, BOARD_BASE_SIZE.y - 240.0)
	floor_glow.texture = _make_radial_texture(
		[Color(0.93, 0.73, 0.46, 0.16), Color(0.93, 0.73, 0.46, 0.0)],
		PackedFloat32Array([0.0, 1.0]),
		Vector2(0.5, 0.5),
		Vector2(1.0, 0.55),
		Vector2i(820, 280)
	)
	floor_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	floor_glow.stretch_mode = TextureRect.STRETCH_SCALE
	board_backdrop.add_child(floor_glow)
	_build_top_row(shell_root)
	_build_side_rails(shell_root)
	_build_info_panels(shell_root)
	_build_battlefield(shell_root)
	_build_bottom(shell_root)
	effect_layer = Control.new()
	effect_layer.anchor_right = 1.0
	effect_layer.anchor_bottom = 1.0
	effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell_root.add_child(effect_layer)
	_build_modal(shell_root)
	board_backdrop.z_index = 0
	battlefield_frame.z_index = 1
	deploy_panel.z_index = 2
	bottom_bar.z_index = 3
	left_rail.z_index = 4
	right_rail.z_index = 4
	top_row.z_index = 4
	stats_panel.z_index = 5
	log_panel.z_index = 5
	effect_layer.z_index = 6
	overlay.z_index = 10
	call_deferred("_apply_responsive_layout")

func _build_top_row(shell: Control) -> void:
	top_row = Control.new()
	top_row.position = Vector2.ZERO
	top_row.size = BOARD_BASE_SIZE
	shell.add_child(top_row)

	top_stage_stack = VBoxContainer.new()
	top_stage_stack.position = Vector2(585, 42)
	top_stage_stack.custom_minimum_size = Vector2(430, 116)
	top_stage_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	top_stage_stack.add_theme_constant_override("separation", 12)
	top_row.add_child(top_stage_stack)

	var stage_card := PanelContainer.new()
	stage_card.custom_minimum_size = Vector2(444, 84)
	stage_card.add_theme_stylebox_override("panel", _make_surface_style(Color("132330"), Color("b8d3e3"), 999))
	top_stage_stack.add_child(stage_card)
	var stage_box := _make_panel_box(stage_card, 12)
	stage_kicker_label = Label.new()
	stage_kicker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_kicker_label.add_theme_font_size_override("font_size", 12)
	stage_kicker_label.add_theme_color_override("font_color", Color("c3d9e7"))
	stage_box.add_child(stage_kicker_label)
	stage_label = Label.new()
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.add_theme_font_size_override("font_size", 32)
	stage_label.add_theme_color_override("font_color", Color("f7fbff"))
	stage_box.add_child(stage_label)

	var hud_row := HBoxContainer.new()
	hud_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hud_row.add_theme_constant_override("separation", 10)
	top_stage_stack.add_child(hud_row)
	wave_badge_label = _make_hud_pill(hud_row)
	enemy_badge_label = _make_hud_pill(hud_row)
	trait_badge_label = _make_hud_pill(hud_row)

	var utility_panel := PanelContainer.new()
	utility_panel.position = Vector2(1064, 40)
	utility_panel.custom_minimum_size = Vector2(474, 46)
	utility_panel.add_theme_stylebox_override("panel", _make_surface_style(Color(0.09, 0.15, 0.20, 0.56), Color(1, 1, 1, 0.18), 999))
	top_row.add_child(utility_panel)
	top_utility_box = HBoxContainer.new()
	top_utility_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_utility_box.offset_left = 10
	top_utility_box.offset_top = 5
	top_utility_box.offset_right = -10
	top_utility_box.offset_bottom = -5
	top_utility_box.alignment = BoxContainer.ALIGNMENT_END
	top_utility_box.add_theme_constant_override("separation", 8)
	utility_panel.add_child(top_utility_box)
	prev_button = _make_utility_button()
	prev_button.pressed.connect(_change_stage.bind(-1))
	top_utility_box.add_child(prev_button)
	restart_button = _make_utility_button()
	restart_button.pressed.connect(_restart_current_stage)
	top_utility_box.add_child(restart_button)
	next_button = _make_utility_button()
	next_button.pressed.connect(_change_stage.bind(1))
	top_utility_box.add_child(next_button)
	language_title_label = Label.new()
	language_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	language_title_label.add_theme_color_override("font_color", Color("c7dae7"))
	top_utility_box.add_child(language_title_label)
	language_option = OptionButton.new()
	language_option.custom_minimum_size = Vector2(120, 36)
	language_option.add_theme_stylebox_override("normal", _make_surface_style(Color("1a2b39"), Color("9ab9cc"), 18))
	language_option.add_theme_stylebox_override("hover", _make_surface_style(Color("213747"), Color("cfe3ef"), 18))
	language_option.add_theme_stylebox_override("pressed", _make_surface_style(Color("182735"), Color("f3fbff"), 18))
	language_option.add_theme_color_override("font_color", Color("eff8ff"))
	language_option.item_selected.connect(_on_language_selected)
	top_utility_box.add_child(language_option)

func _build_side_rails(shell: Control) -> void:
	left_rail = VBoxContainer.new()
	left_rail.position = Vector2(34, 160)
	left_rail.custom_minimum_size = Vector2(82, 290)
	left_rail.add_theme_constant_override("separation", 14)
	shell.add_child(left_rail)
	quick_speed_button = _make_quick_button("speed")
	quick_speed_button.pressed.connect(_toggle_speed)
	quick_speed_label = quick_speed_button.get_meta("title_label") as Label
	left_rail.add_child(quick_speed_button)
	quick_stats_button = _make_quick_button("stats")
	quick_stats_button.pressed.connect(_toggle_stats_panel)
	quick_stats_label = quick_stats_button.get_meta("title_label") as Label
	left_rail.add_child(quick_stats_button)
	quick_log_button = _make_quick_button("log")
	quick_log_button.pressed.connect(_toggle_log_panel)
	quick_log_label = quick_log_button.get_meta("title_label") as Label
	left_rail.add_child(quick_log_button)

	right_rail = VBoxContainer.new()
	right_rail.position = Vector2(1352, 160)
	right_rail.custom_minimum_size = Vector2(214, 244)
	right_rail.alignment = BoxContainer.ALIGNMENT_END
	right_rail.add_theme_constant_override("separation", 12)
	shell.add_child(right_rail)

	totem_card = PanelContainer.new()
	totem_card.custom_minimum_size = Vector2(214, 182)
	totem_card.size_flags_horizontal = Control.SIZE_SHRINK_END
	totem_card.add_theme_stylebox_override("panel", _make_surface_style(Color("132331"), Color("b2d0e1"), 24))
	right_rail.add_child(totem_card)
	var totem_box := _make_panel_box(totem_card, 14)
	var totem_icon_wrap := CenterContainer.new()
	totem_icon_wrap.custom_minimum_size = Vector2(0, 80)
	totem_box.add_child(totem_icon_wrap)
	totem_icon = IconBadge.new()
	totem_icon.custom_minimum_size = Vector2(68, 68)
	totem_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	totem_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	totem_icon_wrap.add_child(totem_icon)
	totem_name_label = Label.new()
	totem_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	totem_name_label.add_theme_font_size_override("font_size", 18)
	totem_name_label.add_theme_color_override("font_color", Color("f4fbff"))
	totem_box.add_child(totem_name_label)
	totem_charge_label = Label.new()
	totem_charge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	totem_charge_label.add_theme_color_override("font_color", Color("9ed7f2"))
	totem_charge_label.add_theme_font_size_override("font_size", 11)
	totem_box.add_child(totem_charge_label)
	totem_desc_label = RichTextLabel.new()
	totem_desc_label.fit_content = true
	totem_desc_label.scroll_active = false
	totem_desc_label.bbcode_enabled = false
	totem_desc_label.add_theme_font_size_override("normal_font_size", 12)
	totem_desc_label.add_theme_color_override("default_color", Color("dbe9f3"))
	totem_box.add_child(totem_desc_label)

	threat_wrap = PanelContainer.new()
	threat_wrap.custom_minimum_size = Vector2(82, 82)
	threat_wrap.size_flags_horizontal = Control.SIZE_SHRINK_END
	threat_wrap.add_theme_stylebox_override("panel", _make_surface_style(Color("72281f"), Color("ffd6ca"), 22))
	right_rail.add_child(threat_wrap)
	var threat_center := CenterContainer.new()
	threat_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	threat_wrap.add_child(threat_center)
	threat_badge = IconBadge.new()
	threat_badge.custom_minimum_size = Vector2(52, 52)
	threat_badge.configure(Color("ff976f"), Color("a34334"), Color("fff1df"), "threat")
	threat_center.add_child(threat_badge)

func _build_info_panels(shell: Control) -> void:
	stats_panel = _make_info_panel(Vector2(134, 182), Vector2(312, 288))
	shell.add_child(stats_panel)
	stats_panel.visible = false
	var stats_box := _make_panel_box(stats_panel, 14)
	var stats_title := Label.new()
	stats_title.set_meta("copy_key", "run_intel")
	stats_title.add_theme_font_size_override("font_size", 16)
	stats_title.add_theme_color_override("font_color", Color("f4fbff"))
	stats_box.add_child(stats_title)
	wave_status_label = Label.new()
	wave_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wave_status_label.add_theme_color_override("font_color", Color("cfe0eb"))
	stats_box.add_child(wave_status_label)
	var trait_title := Label.new()
	trait_title.set_meta("copy_key", "traits")
	trait_title.add_theme_color_override("font_color", Color("f4fbff"))
	stats_box.add_child(trait_title)
	trait_label = RichTextLabel.new()
	trait_label.fit_content = true
	trait_label.bbcode_enabled = false
	trait_label.scroll_active = true
	trait_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	trait_label.add_theme_color_override("default_color", Color("d5e6f2"))
	stats_box.add_child(trait_label)
	var damage_title := Label.new()
	damage_title.set_meta("copy_key", "damage")
	damage_title.add_theme_color_override("font_color", Color("f4fbff"))
	stats_box.add_child(damage_title)
	damage_label = RichTextLabel.new()
	damage_label.fit_content = true
	damage_label.bbcode_enabled = false
	damage_label.scroll_active = true
	damage_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	damage_label.add_theme_color_override("default_color", Color("d5e6f2"))
	stats_box.add_child(damage_label)
	log_panel = _make_info_panel(Vector2(134, 182), Vector2(312, 288))
	shell.add_child(log_panel)
	log_panel.visible = false
	var log_box := _make_panel_box(log_panel, 14)
	var log_title := Label.new()
	log_title.set_meta("copy_key", "battle_log")
	log_title.add_theme_font_size_override("font_size", 16)
	log_title.add_theme_color_override("font_color", Color("f4fbff"))
	log_box.add_child(log_title)
	log_label = RichTextLabel.new()
	log_label.fit_content = true
	log_label.bbcode_enabled = false
	log_label.scroll_active = true
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.add_theme_color_override("default_color", Color("d5e6f2"))
	log_box.add_child(log_label)

func _build_battlefield(shell: Control) -> void:
	battlefield_frame = PanelContainer.new()
	battlefield_frame.position = Vector2(180, 150)
	battlefield_frame.size = Vector2(1240, 430)
	battlefield_frame.add_theme_stylebox_override("panel", _make_surface_style(Color(0.09, 0.14, 0.20, 0.24), Color(0.90, 0.96, 0.99, 0.24), 40))
	shell.add_child(battlefield_frame)
	var battlefield_canvas := Control.new()
	battlefield_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battlefield_frame.add_child(battlefield_canvas)
	var arena_back := PanelContainer.new()
	arena_back.position = Vector2(18, 18)
	arena_back.size = Vector2(1204, 394)
	arena_back.clip_contents = true
	arena_back.add_theme_stylebox_override("panel", _make_surface_style(Color("253847"), Color(1, 1, 1, 0.08), 26))
	battlefield_canvas.add_child(arena_back)
	var arena_background := TextureRect.new()
	arena_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena_background.texture = ArtCatalog.get_battlefield_background()
	arena_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arena_background.stretch_mode = TextureRect.STRETCH_SCALE
	arena_background.modulate = Color(1, 1, 1, 0.56)
	arena_back.add_child(arena_background)
	var arena_spotlight := TextureRect.new()
	arena_spotlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena_spotlight.texture = _make_radial_texture(
		[Color(0.95, 0.98, 1.0, 0.24), Color(0.95, 0.98, 1.0, 0.0)],
		PackedFloat32Array([0.0, 1.0]),
		Vector2(0.5, 0.08),
		Vector2(1.2, 0.78),
		Vector2i(900, 520)
	)
	arena_spotlight.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arena_spotlight.stretch_mode = TextureRect.STRETCH_SCALE
	arena_back.add_child(arena_spotlight)
	var arena_floor_haze := TextureRect.new()
	arena_floor_haze.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena_floor_haze.texture = _make_gradient_texture(
		[
			Color(0.05, 0.08, 0.12, 0.0),
			Color(0.05, 0.08, 0.12, 0.0),
			Color(0.72, 0.84, 0.94, 0.10),
			Color(0.95, 0.82, 0.62, 0.18)
		],
		PackedFloat32Array([0.0, 0.54, 0.80, 1.0]),
		Vector2(0.5, 0.0),
		Vector2(0.5, 1.0),
		Vector2i(900, 520)
	)
	arena_floor_haze.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arena_floor_haze.stretch_mode = TextureRect.STRETCH_SCALE
	arena_back.add_child(arena_floor_haze)
	var arena_vignette := ColorRect.new()
	arena_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena_vignette.color = Color(0.07, 0.11, 0.16, 0.30)
	arena_back.add_child(arena_vignette)
	enemy_layer = Control.new()
	enemy_layer.position = Vector2(102, 20)
	enemy_layer.size = Vector2(1000, 348)
	battlefield_canvas.add_child(enemy_layer)
	for lane_index in range(LANE_COUNT):
		var lane_panel := PanelContainer.new()
		lane_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lane_panel.add_theme_stylebox_override("panel", _make_surface_style(Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.08), 30))
		enemy_layer.add_child(lane_panel)
		var lane_top_glow := TextureRect.new()
		lane_top_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lane_top_glow.texture = _make_gradient_texture(
			[Color(1, 1, 1, 0.12), Color(1, 1, 1, 0.02), Color(1, 1, 1, 0.0)],
			PackedFloat32Array([0.0, 0.18, 1.0]),
			Vector2(0.5, 0.0),
			Vector2(0.5, 1.0),
			Vector2i(240, 320)
		)
		lane_top_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lane_top_glow.stretch_mode = TextureRect.STRETCH_SCALE
		lane_panel.add_child(lane_top_glow)
		var lane_marker := ColorRect.new()
		lane_marker.anchor_left = 0.12
		lane_marker.anchor_top = 1.0
		lane_marker.anchor_right = 0.88
		lane_marker.anchor_bottom = 1.0
		lane_marker.offset_top = -14
		lane_marker.offset_bottom = -8
		lane_marker.color = Color(0.96, 0.76, 0.46, 0.24)
		lane_panel.add_child(lane_marker)
		lane_guides.append(lane_panel)
	leak_line = ColorRect.new()
	leak_line.color = Color(0.96, 0.75, 0.44, 0.92)
	enemy_layer.add_child(leak_line)
	_update_lane_guides()

func _build_bottom(shell: Control) -> void:
	deploy_panel = PanelContainer.new()
	deploy_panel.position = Vector2(150, DEPLOY_PANEL_TOP)
	deploy_panel.size = Vector2(1300, BOARD_BASE_SIZE.y - BOTTOM_BAR_HEIGHT - BOTTOM_BAR_BOTTOM_MARGIN - DEPLOY_PANEL_TOP - DEPLOY_PANEL_BOTTOM_GAP)
	deploy_panel.add_theme_stylebox_override("panel", _make_surface_style(Color("4b5b68"), Color("e2eef5"), 30))
	shell.add_child(deploy_panel)
	var deploy_box := _make_panel_box(deploy_panel, 12)
	var deploy_head := HBoxContainer.new()
	deploy_head.add_theme_constant_override("separation", 6)
	deploy_box.add_child(deploy_head)
	var deploy_meta := VBoxContainer.new()
	deploy_meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deploy_meta.add_theme_constant_override("separation", 3)
	deploy_head.add_child(deploy_meta)
	deploy_title_label = Label.new()
	deploy_title_label.add_theme_font_size_override("font_size", 16)
	deploy_title_label.add_theme_color_override("font_color", Color("f4f9fd"))
	deploy_meta.add_child(deploy_title_label)
	random_hint_label = Label.new()
	random_hint_label.add_theme_color_override("font_color", Color("c9deec"))
	random_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	random_hint_label.add_theme_font_size_override("font_size", 11)
	deploy_meta.add_child(random_hint_label)
	deploy_hint_label = Label.new()
	deploy_hint_label.add_theme_color_override("font_color", Color("edf6fb"))
	deploy_hint_label.add_theme_font_size_override("font_size", 12)
	deploy_head.add_child(deploy_hint_label)
	board_grid = GridContainer.new()
	board_grid.columns = 10
	board_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_grid.add_theme_constant_override("h_separation", 8)
	board_grid.add_theme_constant_override("v_separation", 8)
	deploy_box.add_child(board_grid)
	board_manager.setup(board_grid, self)

	bottom_bar = HBoxContainer.new()
	bottom_bar.size = Vector2(1300, BOTTOM_BAR_HEIGHT)
	bottom_bar.position = Vector2(150, BOARD_BASE_SIZE.y - bottom_bar.size.y - BOTTOM_BAR_BOTTOM_MARGIN)
	bottom_bar.add_theme_constant_override("separation", 10)
	shell.add_child(bottom_bar)
	money_panel = PanelContainer.new()
	money_panel.custom_minimum_size = Vector2(178, 60)
	money_panel.add_theme_stylebox_override("panel", _make_surface_style(Color("efe4d3"), Color("fff9f0"), 20))
	bottom_bar.add_child(money_panel)
	var money_box := _make_panel_box(money_panel, 8)
	var money_caption := Label.new()
	money_caption.set_meta("copy_key", "gold_label")
	money_caption.add_theme_color_override("font_color", Color("687a86"))
	money_caption.add_theme_font_size_override("font_size", 9)
	money_box.add_child(money_caption)
	gold_value_label = Label.new()
	gold_value_label.add_theme_font_size_override("font_size", 28)
	gold_value_label.add_theme_color_override("font_color", Color("1c3749"))
	money_box.add_child(gold_value_label)
	summon_cost_label = Label.new()
	summon_cost_label.add_theme_color_override("font_color", Color("6f8190"))
	summon_cost_label.add_theme_font_size_override("font_size", 11)
	money_box.add_child(summon_cost_label)

	core_panel = PanelContainer.new()
	core_panel.custom_minimum_size = Vector2(730, 60)
	core_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	core_panel.add_theme_stylebox_override("panel", _make_surface_style(Color("132330"), Color("b1d0e3"), 20))
	bottom_bar.add_child(core_panel)
	var core_box := _make_panel_box(core_panel, 8)
	core_meta_label = Label.new()
	core_meta_label.add_theme_font_size_override("font_size", 11)
	core_meta_label.add_theme_color_override("font_color", Color("a9c6d8"))
	core_box.add_child(core_meta_label)
	core_value_label = Label.new()
	core_value_label.add_theme_font_size_override("font_size", 22)
	core_value_label.add_theme_color_override("font_color", Color("f5fbff"))
	core_box.add_child(core_value_label)
	var core_bar_frame := PanelContainer.new()
	core_bar_frame.custom_minimum_size = Vector2(0, 14)
	core_bar_frame.add_theme_stylebox_override("panel", _make_surface_style(Color(1, 1, 1, 0.10), Color(1, 1, 1, 0.06), 999))
	core_box.add_child(core_bar_frame)
	var core_fill_root := Control.new()
	core_fill_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	core_bar_frame.add_child(core_fill_root)
	core_fill = ColorRect.new()
	core_fill.anchor_right = 1.0
	core_fill.anchor_bottom = 1.0
	core_fill.color = Color("79e16f")
	core_fill_root.add_child(core_fill)

	actions_panel = PanelContainer.new()
	actions_panel.custom_minimum_size = Vector2(356, 60)
	actions_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	actions_panel.add_theme_stylebox_override("panel", _make_surface_style(Color("132330"), Color("b1d0e3"), 20))
	bottom_bar.add_child(actions_panel)
	var actions_box := HBoxContainer.new()
	actions_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	actions_box.offset_left = 6
	actions_box.offset_top = 6
	actions_box.offset_right = -6
	actions_box.offset_bottom = -6
	actions_box.add_theme_constant_override("separation", 6)
	actions_panel.add_child(actions_box)
	totem_button = Button.new()
	totem_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	totem_button.pressed.connect(_on_totem_upgrade_pressed)
	totem_button_cost_label = _build_action_button(totem_button, "totem", Color("5cc3ac"), Color("2b7773"))
	actions_box.add_child(totem_button)
	summon_button = Button.new()
	summon_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summon_button.pressed.connect(_on_summon_pressed)
	summon_button_cost_label = _build_action_button(summon_button, "summon", Color("f1b55d"), Color("bc6526"))
	actions_box.add_child(summon_button)

func _build_modal(shell: Control) -> void:
	overlay = ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0, 0, 0, 0.58)
	overlay.visible = false
	shell.add_child(overlay)
	var modal_center := CenterContainer.new()
	modal_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(modal_center)
	var modal_panel := PanelContainer.new()
	modal_panel.custom_minimum_size = Vector2(930, 468)
	modal_panel.add_theme_stylebox_override("panel", _make_surface_style(Color("f2eee2"), Color("ffffff"), 34))
	modal_center.add_child(modal_panel)
	var modal_box := _make_panel_box(modal_panel, 24)
	modal_title = Label.new()
	modal_title.add_theme_color_override("font_color", Color("274152"))
	modal_title.add_theme_font_size_override("font_size", 30)
	modal_box.add_child(modal_title)
	modal_subtitle = RichTextLabel.new()
	modal_subtitle.fit_content = true
	modal_subtitle.bbcode_enabled = false
	modal_subtitle.scroll_active = false
	modal_subtitle.add_theme_color_override("default_color", Color("597080"))
	modal_box.add_child(modal_subtitle)
	modal_options_box = GridContainer.new()
	modal_options_box.columns = 3
	modal_options_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_options_box.add_theme_constant_override("h_separation", 16)
	modal_options_box.add_theme_constant_override("v_separation", 16)
	modal_box.add_child(modal_options_box)
	modal_reroll_button = Button.new()
	modal_reroll_button.custom_minimum_size = Vector2(0, 46)
	modal_reroll_button.add_theme_stylebox_override("normal", _make_button_style(Color("58778f"), Color("6f8ca5"), 18))
	modal_reroll_button.add_theme_stylebox_override("hover", _make_button_style(Color("6a89a0"), Color("7e9bb3"), 18))
	modal_reroll_button.add_theme_color_override("font_color", Color("f6fbff"))
	modal_reroll_button.visible = false
	modal_reroll_button.pressed.connect(_on_modal_reroll_pressed)
	modal_box.add_child(modal_reroll_button)

func _apply_responsive_layout() -> void:
	if shell_root == null:
		return
	var scale_factor := minf(size.x / BOARD_BASE_SIZE.x, size.y / BOARD_BASE_SIZE.y)
	scale_factor = maxf(scale_factor, 0.6)
	var scaled_board_size := BOARD_BASE_SIZE * scale_factor
	shell_root.position = (size - scaled_board_size) * 0.5
	shell_root.size = BOARD_BASE_SIZE
	shell_root.scale = Vector2.ONE * scale_factor
	board_backdrop.position = Vector2.ZERO
	board_backdrop.size = BOARD_BASE_SIZE
	stats_panel.position = Vector2(104, 204)
	stats_panel.size = Vector2(302, 286)
	log_panel.position = Vector2(104, 204)
	log_panel.size = Vector2(302, 286)
	battlefield_frame.position = Vector2(180, 150)
	battlefield_frame.size = Vector2(1240, 430)
	deploy_panel.position = Vector2(150, DEPLOY_PANEL_TOP)
	deploy_panel.size = Vector2(1300, BOARD_BASE_SIZE.y - BOTTOM_BAR_HEIGHT - BOTTOM_BAR_BOTTOM_MARGIN - DEPLOY_PANEL_TOP - DEPLOY_PANEL_BOTTOM_GAP)
	bottom_bar.size = Vector2(1300, BOTTOM_BAR_HEIGHT)
	bottom_bar.position = Vector2(150, BOARD_BASE_SIZE.y - bottom_bar.size.y - BOTTOM_BAR_BOTTOM_MARGIN)
	effect_layer.position = Vector2.ZERO
	effect_layer.size = BOARD_BASE_SIZE
	_update_lane_guides()

func _apply_localization() -> void:
	stage_kicker_label.text = Localization.text("stage_overview")
	prev_button.text = Localization.text("prev_stage")
	restart_button.text = Localization.text("restart_stage")
	next_button.text = Localization.text("next_stage")
	language_title_label.text = Localization.text("language")
	language_option.clear()
	language_option.add_item(Localization.text("language_zh"))
	language_option.set_item_metadata(0, Localization.LANGUAGE_ZH)
	language_option.add_item(Localization.text("language_en"))
	language_option.set_item_metadata(1, Localization.LANGUAGE_EN)
	_sync_language_option()
	deploy_title_label.text = Localization.text("deploy_strip")
	deploy_hint_label.text = Localization.text("deploy_hint")
	quick_stats_label.text = Localization.text("quick_stats")
	quick_log_label.text = Localization.text("quick_log")
	_update_speed_button()
	var totem_title := totem_button.get_meta("title_label") as Label
	if totem_title != null:
		totem_title.text = Localization.text("totem_upgrade")
	var totem_caption := totem_button.get_meta("caption_label") as Label
	if totem_caption != null:
		totem_caption.text = Localization.text("action_ready")
	var summon_title := summon_button.get_meta("title_label") as Label
	if summon_title != null:
		summon_title.text = Localization.text("summon_hero")
	var summon_caption := summon_button.get_meta("caption_label") as Label
	if summon_caption != null:
		summon_caption.text = Localization.text("action_ready")
	for panel in [stats_panel, log_panel]:
		for child in panel.find_children("*", "Label"):
			if child.has_meta("copy_key"):
				child.text = Localization.text(str(child.get_meta("copy_key")))
	modal_reroll_button.text = Localization.text("reroll")
	if run_state != null and current_stage != null:
		_refresh_random_hint()
		_refresh_status_panels()
func _sync_language_option() -> void:
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
	_refresh_status_panels()

func _setup_stage(index: int) -> void:
	current_stage_index = clampi(index, 0, max(0, stages.size() - 1))
	current_stage = stages[current_stage_index]
	if overlay.visible:
		_close_modal()
	run_state = RunState.new(_make_seed(), current_stage.id, current_stage_index)
	wave_director.setup(current_stage)
	board_manager.clear_board()
	for enemy in get_active_enemies():
		if enemy.get_parent() != null:
			enemy.get_parent().remove_child(enemy)
		enemy.queue_free()
	for node in effect_layer.get_children():
		node.queue_free()
	boss_spawned = false
	bonus_elite_spawned = false
	wave_bombard_applied = false
	battle_paused = true
	run_finished = false
	current_wave_reward_processed = false
	run_state.gold = 40
	run_state.base_hp = 24
	run_state.max_base_hp = 24
	run_state.rerolls = 1
	random_hint_ids.clear()
	log_lines.clear()
	stats_panel.visible = false
	log_panel.visible = false
	_refresh_random_hint()
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
	var hero_id := _pick_weighted_hero([])
	var piece = board_manager.spawn_hero(hero_id, cost)
	if piece == null:
		if cost > 0:
			run_state.add_gold(cost)
		add_log(Localization.text("no_free_slot"))
		return
	add_log(Localization.format_text("summoned", [piece.get_display_label()]))
	_refresh_random_hint()

func _on_totem_upgrade_pressed() -> void:
	if run_state.totem_id == "":
		add_log(Localization.text("totem_upgrade_locked"))
		return
	var cost := _get_totem_upgrade_cost()
	if not run_state.spend_gold(cost):
		add_log(Localization.text("not_enough_gold"))
		return
	run_state.totem_level += 1
	add_log(Localization.format_text("totem_upgraded", [run_state.totem_level]))

func _refresh_random_hint() -> void:
	if run_state == null:
		return
	random_hint_ids.clear()
	var selected: Array[String] = []
	while random_hint_ids.size() < 3:
		var hero_id := _pick_weighted_hero(selected)
		random_hint_ids.append(hero_id)
		selected.append(hero_id)

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
	var enemy_def = GameData.enemies[enemy_id]
	var hp_scale: float = 1.0 + current_stage.difficulty * 0.10 + maxf(0.0, float(run_state.current_wave_index)) * 0.06
	if enemy_def.is_boss or force_boss:
		hp_scale *= 1.55
	var speed_scale: float = 1.0 + current_stage.chapter * 0.015
	var reward_bonus: int = 0
	if enemy_def.tags.has("elite") or enemy_def.tags.has("boss"):
		reward_bonus += int(wave_director.modifiers.get("bonus_elite_reward", 0))
	var enemy := EnemyActor.new()
	enemy.setup(enemy_def, hp_scale, speed_scale, reward_bonus)
	var lane_width: float = enemy_layer.size.x / float(LANE_COUNT) if enemy_layer.size.x > 0.0 else 260.0
	var lane_index := run_state.rng.randi_range(0, LANE_COUNT - 1)
	var lane_center: float = lane_width * (lane_index + 0.5)
	var jitter: float = minf(lane_width * 0.16, 26.0)
	enemy.position = Vector2(lane_center + run_state.rng.randf_range(-jitter, jitter) - (enemy.custom_minimum_size.x * 0.5), -40.0)
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

func get_leak_line_y() -> float:
	return leak_line.position.y

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
	var damage: int = maxi(1, enemy.enemy_def.contact_damage - 1)
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
	var wave = current_stage.wave_defs[run_state.current_wave_index]
	var reward: int = wave.reward + int(_get_numeric_modifier("wave_bonus_gold"))
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
	var hero_def = GameData.heroes[hero_id]
	_open_modal(Localization.text("evolution_trait"), Localization.format_text("evolution_reached", [hero_def.display_name, star_level]), modal_entries, "evolution_trait", {"hero_id": hero_id, "star_level": star_level}, true)

func _show_event() -> void:
	var event_def = event_director.pick_event(run_state)
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
	modal_options_box.columns = mini(3, max(1, modal_choices.size()))
	for index in range(modal_choices.size()):
		modal_options_box.add_child(_make_modal_choice_card(index, modal_choices[index]))
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
			var totem = entry["payload"]
			run_state.totem_id = totem.id
			add_log(Localization.format_text("totem_selected", [totem.display_name]))
			_close_modal()
			_start_wave(0)
		"global_trait":
			var trait_def = entry["payload"]
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
			var evo_trait = entry["payload"]
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

func _apply_immediate_trait_effects(trait_def) -> void:
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

func _refresh_status_panels() -> void:
	if run_state == null or current_stage == null:
		return
	stage_label.text = Localization.format_text("stage_seed", [current_stage.display_name, run_state.seed])
	wave_badge_label.text = Localization.format_text("wave_badge", [maxi(0, run_state.current_wave_index + 1), current_stage.wave_defs.size()])
	enemy_badge_label.text = Localization.format_text("enemy_badge", [get_active_enemy_count()])
	trait_badge_label.text = Localization.format_text("trait_badge", [_get_active_trait_count()])
	gold_value_label.text = str(run_state.gold)
	summon_cost_label.text = Localization.format_text("summon_cost", [economy_system.current_cost(run_state)])
	core_meta_label.text = Localization.format_text("core_status", [run_state.totem_level, _get_totem_upgrade_cost()])
	core_value_label.text = "%d / %d" % [run_state.base_hp, run_state.max_base_hp]
	core_value_label.visible = true
	core_fill.anchor_right = clampf(float(run_state.base_hp) / maxf(1.0, float(run_state.max_base_hp)), 0.0, 1.0)
	random_hint_label.text = Localization.format_text("random_hero_hint", [_format_random_hint()])
	wave_status_label.text = Localization.format_text("wave_line", [maxi(0, run_state.current_wave_index + 1), current_stage.wave_defs.size(), get_active_enemy_count()])
	totem_button_cost_label.text = str(_get_totem_upgrade_cost())
	summon_button_cost_label.text = str(economy_system.current_cost(run_state))
	_refresh_rich_panels()
	summon_button.disabled = battle_paused or run_finished
	totem_button.disabled = run_finished or run_state.totem_id == ""

func _refresh_rich_panels() -> void:
	var totem = GameData.totems.get(run_state.totem_id)
	if totem != null:
		totem_name_label.text = totem.display_name
		totem_desc_label.clear()
		totem_desc_label.append_text(totem.description)
		totem_charge_label.text = _describe_totem_charge(totem)
		var totem_texture := ArtCatalog.get_totem_texture(totem.id)
		if totem_texture != null:
			totem_icon.configure_with_texture(totem_texture, Color(totem.color))
		else:
			_apply_palette(totem_icon, Color(totem.color), "totem")
	else:
		totem_name_label.text = Localization.text("totem_none")
		totem_desc_label.clear()
		totem_desc_label.append_text(Localization.text("totem_none_desc"))
		totem_charge_label.text = Localization.text("totem_none_charge")
		totem_icon.configure(Color("75d6ff"), Color("2c78af"), Color("f4fbff"), "totem")
	trait_label.clear()
	if run_state.active_global_traits.is_empty() and run_state.active_evolution_traits.is_empty():
		trait_label.append_text(Localization.text("no_traits_yet"))
	else:
		for trait_def in run_state.active_global_traits:
			trait_label.append_text("- %s\n" % trait_def.display_name)
		for hero_id in run_state.active_evolution_traits.keys():
			for trait_def in run_state.active_evolution_traits[hero_id]:
				trait_label.append_text("- %s / %s\n" % [GameData.heroes[hero_id].display_name, trait_def.display_name])
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
	if log_lines.is_empty():
		log_label.append_text(Localization.text("no_logs_yet"))
	else:
		for line in log_lines:
			log_label.append_text("%s\n" % line)

func add_log(text: String) -> void:
	log_lines.append(text)
	if log_lines.size() > MAX_LOG_LINES:
		log_lines.pop_front()

func _change_stage(offset: int) -> void:
	_setup_stage(current_stage_index + offset)

func _restart_current_stage() -> void:
	_setup_stage(current_stage_index)

func show_hit_feedback(piece, enemy, dealt: float, meta: Dictionary) -> void:
	if piece == null or enemy == null:
		return
	var start := _to_effect_local(piece.get_global_rect().get_center())
	var finish := _to_effect_local(enemy.get_global_rect().get_center())
	var color: Color = piece.hero_def.color.lightened(0.18) if piece.hero_def != null else Color("89d8ff")
	var hero_id := str(piece.hero_def.id) if piece.hero_def != null else ""
	var beam_effect := ""
	if hero_id == "storm_caller":
		beam_effect = "chain_arc"
	elif hero_id == "frost_oracle" or bool(meta.get("freeze", false)):
		beam_effect = "frost_beam"
	_spawn_beam(start, finish, color, beam_effect)

	var burst_effect := "impact_spark"
	if bool(meta.get("poison", false)) or hero_id == "venom_sage":
		burst_effect = "venom_cloud"
	elif hero_id == "solar_priest":
		burst_effect = "solar_flare"
	elif bool(meta.get("crit", false)) or str(meta.get("mode", "single")) == "splash":
		burst_effect = "arcane_burst"
	_spawn_burst(finish, color, 42.0 if str(meta.get("mode", "single")) != "splash" else 56.0, burst_effect)

	if bool(meta.get("freeze", false)):
		_spawn_ring(finish, Color("82d8ff"), 92.0, "freeze_ring")
	elif bool(meta.get("poison", false)):
		_spawn_ring(finish, Color("89dc9a"), 96.0, "venom_cloud")

	if bool(meta.get("crit", false)):
		var spark_effect := "solar_flare" if hero_id == "solar_priest" else "impact_spark"
		_spawn_spark(finish, Color("ffdc7a"), spark_effect)
	_spawn_damage_number(finish, dealt, bool(meta.get("crit", false)))

func _toggle_speed() -> void:
	battle_speed = 1.5 if is_equal_approx(battle_speed, 1.0) else 1.0
	Engine.time_scale = battle_speed
	_update_speed_button()

func _toggle_stats_panel() -> void:
	stats_panel.visible = not stats_panel.visible
	if stats_panel.visible:
		log_panel.visible = false

func _toggle_log_panel() -> void:
	log_panel.visible = not log_panel.visible
	if log_panel.visible:
		stats_panel.visible = false

func _update_speed_button() -> void:
	quick_speed_label.text = Localization.format_text("speed_mode", [battle_speed, Localization.text("quick_speed")])

func _format_random_hint() -> String:
	var names: Array[String] = []
	for hero_id in random_hint_ids:
		var hero_def = GameData.heroes[hero_id]
		names.append(hero_def.display_name)
	return " / ".join(names)

func _get_active_trait_count() -> int:
	var total := run_state.active_global_traits.size()
	for hero_id in run_state.active_evolution_traits.keys():
		total += run_state.active_evolution_traits[hero_id].size()
	return total

func _get_totem_upgrade_cost() -> int:
	return TOTEM_BASE_COST + ((maxi(1, run_state.totem_level) - 1) * TOTEM_COST_STEP)

func _describe_totem_charge(totem) -> String:
	match str(totem.effect_id):
		"freeze":
			return Localization.format_text("totem_charge_line", [run_state.totem_hit_counter, 8])
		"poison":
			return Localization.format_text("totem_charge_line", [run_state.totem_hit_counter, 6])
		_:
			return Localization.text("totem_passive")

func _update_lane_guides() -> void:
	if enemy_layer == null or lane_guides.is_empty():
		return
	var gap := 18.0
	var lane_width := (enemy_layer.size.x - (gap * float(LANE_COUNT - 1))) / float(LANE_COUNT)
	var lane_height := enemy_layer.size.y - 48.0
	for lane_index in range(lane_guides.size()):
		var lane_panel := lane_guides[lane_index]
		lane_panel.position = Vector2((lane_width + gap) * lane_index, 6)
		lane_panel.size = Vector2(lane_width, lane_height)
	leak_line.position = Vector2(0, enemy_layer.size.y - 28)
	leak_line.size = Vector2(enemy_layer.size.x, 4)

func _to_effect_local(global_point: Vector2) -> Vector2:
	var effect_rect := effect_layer.get_global_rect()
	var transform_scale := effect_layer.get_global_transform_with_canvas().get_scale()
	return Vector2((global_point.x - effect_rect.position.x) / maxf(transform_scale.x, 0.001), (global_point.y - effect_rect.position.y) / maxf(transform_scale.y, 0.001))

func _spawn_beam(start: Vector2, finish: Vector2, color: Color, effect_id: String = "") -> void:
	var distance := start.distance_to(finish)
	if effect_id != "" and _spawn_effect_sprite((start + finish) * 0.5, Vector2(distance, 52), effect_id, Color.WHITE, start.angle_to_point(finish), 0.34, Vector2(1.0, 0.92), Vector2(1.08, 1.02)):
		return
	var beam := ColorRect.new()
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beam.color = Color(color.r, color.g, color.b, 0.9)
	beam.size = Vector2(distance, 5)
	beam.pivot_offset = Vector2(0, 2.5)
	beam.position = start - Vector2(0, 2.5)
	beam.rotation = start.angle_to_point(finish)
	effect_layer.add_child(beam)
	var tween := create_tween()
	tween.parallel().tween_property(beam, "modulate:a", 0.0, 0.32)
	tween.parallel().tween_property(beam, "scale:x", 1.14, 0.32)
	tween.finished.connect(beam.queue_free)

func _spawn_burst(center: Vector2, color: Color, radius: float = 28.0, effect_id: String = "") -> void:
	if effect_id != "" and _spawn_effect_sprite(center, Vector2.ONE * radius * 2.5, effect_id, Color.WHITE, 0.0, 0.34, Vector2(0.72, 0.72), Vector2(1.28, 1.28)):
		return
	var burst := PanelContainer.new()
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.position = center - Vector2.ONE * (radius * 0.5)
	burst.size = Vector2.ONE * radius
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.36)
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_left = 999
	style.corner_radius_bottom_right = 999
	burst.add_theme_stylebox_override("panel", style)
	effect_layer.add_child(burst)
	burst.scale = Vector2(0.55, 0.55)
	var tween := create_tween()
	tween.parallel().tween_property(burst, "scale", Vector2(1.38, 1.38), 0.30)
	tween.parallel().tween_property(burst, "modulate:a", 0.0, 0.30)
	tween.finished.connect(burst.queue_free)

func _spawn_ring(center: Vector2, color: Color, radius: float = 70.0, effect_id: String = "") -> void:
	if effect_id != "" and _spawn_effect_sprite(center, Vector2.ONE * radius * 1.18, effect_id, Color.WHITE, 0.0, 0.42, Vector2(0.62, 0.62), Vector2(1.16, 1.16)):
		return
	var ring := PanelContainer.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.position = center - Vector2.ONE * (radius * 0.5)
	ring.size = Vector2.ONE * radius
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(color.r, color.g, color.b, 0.72)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_left = 999
	style.corner_radius_bottom_right = 999
	ring.add_theme_stylebox_override("panel", style)
	effect_layer.add_child(ring)
	ring.scale = Vector2(0.45, 0.45)
	var tween := create_tween()
	tween.parallel().tween_property(ring, "scale", Vector2(1.16, 1.16), 0.38)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.38)
	tween.finished.connect(ring.queue_free)

func _spawn_spark(center: Vector2, color: Color, effect_id: String = "impact_spark") -> void:
	if effect_id != "" and _spawn_effect_sprite(center, Vector2(54, 54), effect_id, Color.WHITE, PI * 0.08, 0.28, Vector2(0.82, 0.82), Vector2(1.45, 1.45)):
		return
	var spark := ColorRect.new()
	spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spark.color = color
	spark.position = center - Vector2(9, 9)
	spark.size = Vector2(18, 18)
	spark.rotation = PI * 0.25
	spark.pivot_offset = Vector2(9, 9)
	effect_layer.add_child(spark)
	var tween := create_tween()
	tween.parallel().tween_property(spark, "scale", Vector2(2.1, 2.1), 0.26)
	tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.26)
	tween.finished.connect(spark.queue_free)

func _spawn_effect_sprite(center: Vector2, size_value: Vector2, effect_id: String, tint: Color = Color.WHITE, rotation_value: float = 0.0, fade_time: float = 0.32, start_scale: Vector2 = Vector2.ONE, end_scale: Vector2 = Vector2.ONE) -> bool:
	var texture := ArtCatalog.get_effect_texture(effect_id)
	if texture == null:
		return false
	var sprite := TextureRect.new()
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture = texture
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.position = center - (size_value * 0.5)
	sprite.size = size_value
	sprite.pivot_offset = size_value * 0.5
	sprite.rotation = rotation_value
	sprite.modulate = tint
	effect_layer.add_child(sprite)
	sprite.scale = start_scale
	var tween := create_tween()
	tween.parallel().tween_property(sprite, "scale", end_scale, fade_time)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, fade_time)
	tween.finished.connect(sprite.queue_free)
	return true

func _spawn_damage_number(center: Vector2, dealt: float, did_crit: bool) -> void:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = _format_damage_number(dealt)
	label.add_theme_font_size_override("font_size", 20 if not did_crit else 24)
	label.add_theme_color_override("font_color", Color("fff6e0") if did_crit else Color("ffffff"))
	label.position = center - Vector2(24, 28)
	effect_layer.add_child(label)
	var tween := create_tween()
	tween.parallel().tween_property(label, "position", label.position + Vector2(0, -18), 0.34)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.34)
	tween.finished.connect(label.queue_free)

func _format_damage_number(value: float) -> String:
	if value >= 1000.0:
		return "%.1fK" % [value / 1000.0]
	return str(int(round(value)))

func _make_hud_pill(parent: Node) -> Label:
	var pill := Label.new()
	pill.custom_minimum_size = Vector2(146, 38)
	pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_theme_stylebox_override("normal", _make_surface_style(Color("203446"), Color("9fc2d7"), 999))
	pill.add_theme_color_override("font_color", Color("edf8ff"))
	parent.add_child(pill)
	return pill

func _make_utility_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(74, 36)
	button.add_theme_stylebox_override("normal", _make_button_style(Color("182936"), Color("90b5cb"), 18))
	button.add_theme_stylebox_override("hover", _make_button_style(Color("203545"), Color("b4d3e3"), 18))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color("243d50"), Color("d3ebf7"), 18))
	button.add_theme_color_override("font_color", Color("edf7ff"))
	return button

func _make_quick_button(emblem: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(82, 82)
	button.add_theme_stylebox_override("normal", _make_button_style(Color("162735"), Color("8db6cb"), 24))
	button.add_theme_stylebox_override("hover", _make_button_style(Color("203546"), Color("d9e7ef"), 24))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color("274151"), Color("edf8ff"), 24))
	button.add_theme_color_override("font_color", Color("edf7ff"))
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 5)
	button.add_child(content)
	var icon := IconBadge.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.configure(Color("f3bc69"), Color("91562a"), Color("fff4d7"), "button", emblem)
	content.add_child(icon)
	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 11)
	content.add_child(title)
	button.set_meta("title_label", title)
	return button

func _build_action_button(button: Button, emblem: String, primary: Color, secondary: Color) -> Label:
	button.add_theme_stylebox_override("normal", _make_button_style(primary, secondary, 18))
	button.add_theme_stylebox_override("hover", _make_button_style(primary.lightened(0.08), secondary.lightened(0.08), 18))
	button.add_theme_stylebox_override("pressed", _make_button_style(primary.darkened(0.06), secondary.darkened(0.06), 18))
	button.add_theme_color_override("font_color", Color("fff8ef"))
	button.custom_minimum_size = Vector2(154, 46)
	var content := HBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 6
	content.offset_top = 6
	content.offset_right = -6
	content.offset_bottom = -6
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 5)
	button.add_child(content)
	var icon_slot := CenterContainer.new()
	icon_slot.custom_minimum_size = Vector2(28, 28)
	content.add_child(icon_slot)
	var icon := IconBadge.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.configure(primary.lightened(0.1), secondary.darkened(0.05), Color("fff4dd"), "button", emblem)
	icon_slot.add_child(icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(copy)
	var title := Label.new()
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("fffaf0"))
	copy.add_child(title)
	var caption := Label.new()
	caption.add_theme_font_size_override("font_size", 10)
	caption.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
	caption.visible = true
	copy.add_child(caption)
	var cost := Label.new()
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost.add_theme_font_size_override("font_size", 16)
	cost.add_theme_color_override("font_color", Color("fff7de"))
	content.add_child(cost)
	button.set_meta("title_label", title)
	button.set_meta("caption_label", caption)
	return cost

func _make_info_panel(position_value: Vector2, size_value: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position_value
	panel.custom_minimum_size = size_value
	panel.add_theme_stylebox_override("panel", _make_surface_style(Color("142432"), Color("a9cde0"), 24))
	return panel

func _make_panel_box(panel: Control, margin: int) -> VBoxContainer:
	var holder := MarginContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_theme_constant_override("margin_left", margin)
	holder.add_theme_constant_override("margin_top", margin)
	holder.add_theme_constant_override("margin_right", margin)
	holder.add_theme_constant_override("margin_bottom", margin)
	panel.add_child(holder)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 8)
	holder.add_child(box)
	return box

func _make_modal_choice_card(index: int, entry: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 230)
	card.add_theme_stylebox_override("panel", _make_surface_style(Color("ffffff"), Color("d8e4eb"), 28))
	var box := _make_panel_box(card, 16)
	var crest := IconBadge.new()
	crest.custom_minimum_size = Vector2(56, 56)
	crest.configure(_modal_primary_color(index), _modal_secondary_color(index), Color("fff9eb"), "button", "summon" if index % 2 == 0 else "stats")
	box.add_child(crest)
	var title := Label.new()
	title.text = str(entry.get("title", ""))
	title.add_theme_color_override("font_color", Color("203a4b"))
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	var desc := Label.new()
	desc.text = str(entry.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", Color("607582"))
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(desc)
	var choose := Button.new()
	choose.text = Localization.text("select_action")
	choose.custom_minimum_size = Vector2(0, 44)
	choose.add_theme_stylebox_override("normal", _make_button_style(_modal_primary_color(index), _modal_secondary_color(index), 18))
	choose.add_theme_stylebox_override("hover", _make_button_style(_modal_primary_color(index).lightened(0.08), _modal_secondary_color(index).lightened(0.08), 18))
	choose.add_theme_color_override("font_color", Color("fffaf1"))
	choose.pressed.connect(_on_modal_option_pressed.bind(index))
	box.add_child(choose)
	return card

func _make_surface_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0, 0, 0, clampf(bg.a * 0.34, 0.08, 0.26))
	style.shadow_size = 12 if radius >= 24 else 8
	style.shadow_offset = Vector2(0, 4)
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.2
	return style

func _make_button_style(top_color: Color, bottom_color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = top_color.lerp(bottom_color, 0.42)
	style.border_color = top_color.lightened(0.16)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 3)
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.2
	return style

func _make_gradient_texture(colors: Array[Color], offsets: PackedFloat32Array, from_point: Vector2, to_point: Vector2, texture_size: Vector2i = Vector2i(512, 512)) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray(colors)
	gradient.offsets = offsets
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = from_point
	texture.fill_to = to_point
	texture.width = texture_size.x
	texture.height = texture_size.y
	return texture

func _make_radial_texture(colors: Array[Color], offsets: PackedFloat32Array, center: Vector2, radius: Vector2, texture_size: Vector2i = Vector2i(512, 512)) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray(colors)
	gradient.offsets = offsets
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = center
	texture.fill_to = radius
	texture.width = texture_size.x
	texture.height = texture_size.y
	return texture

func _apply_palette(icon: IconBadge, base_color: Color, variant_name: String = "avatar", emblem_name: String = "") -> void:
	icon.configure(base_color.lightened(0.18), base_color.darkened(0.26), Color("f4e2cf"), variant_name, emblem_name)

func _modal_primary_color(index: int) -> Color:
	var palette := [Color("8cd69a"), Color("f0b15c"), Color("77d2f8")]
	return palette[index % palette.size()]

func _modal_secondary_color(index: int) -> Color:
	var palette := [Color("549c63"), Color("c7722b"), Color("3a7db4")]
	return palette[index % palette.size()]
