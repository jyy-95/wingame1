class_name IconBadge
extends Control

var primary_color := Color("76d4ff")
var secondary_color := Color("2a6b9a")
var accent_color := Color("ecf7ff")
var frame_color := Color(1, 1, 1, 0.55)
var variant := "avatar"
var emblem := ""
var icon_texture: Texture2D = null
var icon_frames: Array[Texture2D] = []
var animation_fps: float = 0.0
var texture_motion_enabled := false
var _frame_progress: float = 0.0
var _frame_index: int = 0
var _display_time: float = 0.0
var _motion_phase: float = 0.0
var animation_crop_profile := ""
static var _opaque_source_cache: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(32, 32)
	_motion_phase = fposmod(float(get_instance_id() % 997) * 0.173, TAU)
	_sync_process_state()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func configure(in_primary: Color, in_secondary: Color, in_accent: Color, in_variant: String = "avatar", in_emblem: String = "") -> void:
	icon_texture = null
	icon_frames.clear()
	animation_fps = 0.0
	texture_motion_enabled = false
	_frame_progress = 0.0
	_frame_index = 0
	_display_time = 0.0
	primary_color = in_primary
	secondary_color = in_secondary
	accent_color = in_accent
	variant = in_variant
	emblem = in_emblem
	animation_crop_profile = ""
	_sync_process_state()
	queue_redraw()

func configure_with_texture(in_texture: Texture2D, in_primary: Color = Color.WHITE, in_animate: bool = false, in_profile: String = "") -> void:
	icon_frames.clear()
	animation_fps = 0.0
	texture_motion_enabled = in_animate
	_frame_progress = 0.0
	_frame_index = 0
	_display_time = 0.0
	icon_texture = in_texture
	primary_color = in_primary
	secondary_color = in_primary.darkened(0.22)
	accent_color = Color(1, 1, 1, 0.92)
	variant = "texture"
	animation_crop_profile = in_profile
	_sync_process_state()
	queue_redraw()

func configure_with_animation(in_frames: Array[Texture2D], in_fps: float = 12.0, in_primary: Color = Color.WHITE, in_profile: String = "") -> void:
	icon_texture = null
	icon_frames = in_frames
	animation_fps = maxf(1.0, in_fps)
	texture_motion_enabled = true
	_frame_progress = 0.0
	_frame_index = 0
	_display_time = 0.0
	primary_color = in_primary
	secondary_color = in_primary.darkened(0.22)
	accent_color = Color(1, 1, 1, 0.92)
	variant = "animated_texture"
	animation_crop_profile = in_profile
	_sync_process_state()
	queue_redraw()

func _process(delta: float) -> void:
	var should_redraw := false
	if variant == "texture" and icon_texture != null and texture_motion_enabled:
		_display_time += delta
		should_redraw = true
	elif variant == "animated_texture" and not icon_frames.is_empty():
		_display_time += delta
		should_redraw = true
		if icon_frames.size() > 1:
			_frame_progress = fposmod(_frame_progress + delta * animation_fps, float(icon_frames.size()))
			var next_index := int(floor(_frame_progress))
			if next_index != _frame_index:
				_frame_index = next_index
	if should_redraw:
		queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var radius := int(round(minf(size.x, size.y) * 0.28))
	var inner := rect.grow(-1.0)

	var display_texture: Texture2D = null
	var animate_display := false
	var use_portrait_frame := not animation_crop_profile.is_empty()
	if variant == "texture":
		display_texture = icon_texture
		animate_display = texture_motion_enabled
	elif variant == "animated_texture" and not icon_frames.is_empty():
		display_texture = icon_frames[clampi(_frame_index, 0, icon_frames.size() - 1)]
		animate_display = true

	if display_texture != null:
		_draw_texture_badge(rect, inner, radius, display_texture, animate_display, use_portrait_frame)
		return

	if variant == "avatar":
		var base_style := StyleBoxFlat.new()
		base_style.bg_color = secondary_color.darkened(0.08)
		base_style.border_color = frame_color
		base_style.border_width_left = 2
		base_style.border_width_top = 2
		base_style.border_width_right = 2
		base_style.border_width_bottom = 2
		base_style.corner_radius_top_left = radius
		base_style.corner_radius_top_right = radius
		base_style.corner_radius_bottom_left = radius
		base_style.corner_radius_bottom_right = radius
		draw_style_box(base_style, rect)
		draw_circle(Vector2(inner.position.x + inner.size.x * 0.5, inner.position.y + inner.size.y * 0.24), inner.size.x * 0.34, primary_color.lightened(0.22))

	match variant:
		"totem":
			_draw_totem(inner)
		"button":
			_draw_button_rune(inner)
		"threat":
			_draw_threat(inner)
		_:
			_draw_avatar(inner)
func _draw_texture_badge(rect: Rect2, inner: Rect2, radius: int, display_texture: Texture2D, animate_display: bool, use_portrait_frame: bool = false) -> void:
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = secondary_color.darkened(0.08)
	base_style.border_color = frame_color
	base_style.border_width_left = 2
	base_style.border_width_top = 2
	base_style.border_width_right = 2
	base_style.border_width_bottom = 2
	base_style.corner_radius_top_left = radius
	base_style.corner_radius_top_right = radius
	base_style.corner_radius_bottom_left = radius
	base_style.corner_radius_bottom_right = radius
	base_style.shadow_color = Color(0, 0, 0, 0.18)
	base_style.shadow_size = 6
	base_style.shadow_offset = Vector2(0, 2)
	base_style.anti_aliasing = true
	base_style.anti_aliasing_size = 1.2
	var texture_size := display_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var effect_rect := inner
	var crop_settings := _get_animation_crop_settings()
	draw_style_box(base_style, rect)
	var source := _get_profiled_texture_source_rect(display_texture, effect_rect.size.x / maxf(1.0, effect_rect.size.y), crop_settings) if use_portrait_frame else _get_texture_source_rect(texture_size, effect_rect.size.x / maxf(1.0, effect_rect.size.y))
	var target_rect := effect_rect if not animate_display else _get_animated_texture_rect(effect_rect, inner)
	draw_texture_rect_region(display_texture, target_rect, source, Color.WHITE, false)
	var effect_radius := minf(effect_rect.size.x, effect_rect.size.y) * 0.46
	draw_arc(effect_rect.position + (effect_rect.size * 0.5), effect_radius, PI * 1.02, PI * 1.98, 32, Color(1, 1, 1, 0.10), 2.0)
	if not animate_display:
		return
	var shimmer_x := effect_rect.position.x + effect_rect.size.x * (0.5 + sin(_display_time * 1.15 + _motion_phase) * 0.18)
	var shimmer_width := effect_rect.size.x * 0.22
	draw_rect(Rect2(Vector2(shimmer_x - (shimmer_width * 0.5), effect_rect.position.y), Vector2(shimmer_width, effect_rect.size.y)), Color(1, 1, 1, 0.055))
	var center := effect_rect.position + (effect_rect.size * 0.5)
	var halo_alpha := 0.12 + (0.04 * sin(_display_time * 2.0 + _motion_phase))
	draw_arc(center, effect_radius, 0.0, TAU, 48, Color(accent_color.r, accent_color.g, accent_color.b, halo_alpha), 2.0)
	draw_arc(center, effect_radius * 0.76, PI * 0.1, PI * 0.9, 24, Color(1, 1, 1, 0.08), 1.5)

func _get_texture_source_rect(texture_size: Vector2, target_ratio: float) -> Rect2:
	var source := Rect2(Vector2.ZERO, texture_size)
	var texture_ratio := texture_size.x / texture_size.y
	if texture_ratio > target_ratio:
		var crop_width := texture_size.y * target_ratio
		source.position.x = (texture_size.x - crop_width) * 0.5
		source.size.x = crop_width
	else:
		var crop_height := texture_size.x / target_ratio
		source.position.y = (texture_size.y - crop_height) * 0.5
		source.size.y = crop_height
	return source

func _get_texture_source_rect_within(bounds_rect: Rect2, target_ratio: float) -> Rect2:
	var source := bounds_rect
	var texture_ratio := bounds_rect.size.x / maxf(1.0, bounds_rect.size.y)
	if texture_ratio > target_ratio:
		var crop_width := bounds_rect.size.y * target_ratio
		source.position.x = bounds_rect.position.x + ((bounds_rect.size.x - crop_width) * 0.5)
		source.size.x = crop_width
	else:
		var crop_height := bounds_rect.size.x / target_ratio
		source.position.y = bounds_rect.position.y + ((bounds_rect.size.y - crop_height) * 0.5)
		source.size.y = crop_height
	return source

func _get_texture_visible_rect(display_texture: Texture2D) -> Rect2:
	var cache_key := display_texture.resource_path
	if cache_key.is_empty():
		cache_key = "%s:%s" % [str(display_texture.get_instance_id()), str(display_texture.get_size())]
	if _opaque_source_cache.has(cache_key):
		return _opaque_source_cache[cache_key]
	var full_rect := Rect2(Vector2.ZERO, display_texture.get_size())
	var image := display_texture.get_image()
	if image == null or image.is_empty():
		_opaque_source_cache[cache_key] = full_rect
		return full_rect
	if image.is_compressed():
		image.decompress()
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.04:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	var visible_rect := full_rect
	if max_x >= min_x and max_y >= min_y:
		visible_rect = Rect2(min_x, min_y, (max_x - min_x) + 1, (max_y - min_y) + 1)
	_opaque_source_cache[cache_key] = visible_rect
	return visible_rect

func _get_profiled_texture_source_rect(display_texture: Texture2D, target_ratio: float, crop_settings: Dictionary) -> Rect2:
	var visible_rect := _get_texture_visible_rect(display_texture)
	var source := _get_texture_source_rect_within(visible_rect, target_ratio)
	var crop_zoom := maxf(1.0, float(crop_settings.get("crop_zoom", 1.0)))
	if crop_zoom <= 1.001:
		return source
	var focus: Vector2 = crop_settings.get("focus", Vector2(0.5, 0.5))
	var cropped_size := source.size / crop_zoom
	var min_pos := source.position
	var max_pos := source.position + source.size - cropped_size
	var desired_pos := source.position + Vector2(
		(source.size.x - cropped_size.x) * clampf(focus.x, 0.0, 1.0),
		(source.size.y - cropped_size.y) * clampf(focus.y, 0.0, 1.0)
	)
	desired_pos.x = clampf(desired_pos.x, min_pos.x, max_pos.x)
	desired_pos.y = clampf(desired_pos.y, min_pos.y, max_pos.y)
	return Rect2(desired_pos, cropped_size)

func _get_animation_crop_settings() -> Dictionary:
	match animation_crop_profile:
		"iron_warden":
			return {"frame_width_pct": 0.76, "crop_zoom": 1.04, "focus": Vector2(0.54, 0.46)}
		"blade_dancer":
			return {"frame_width_pct": 0.74, "crop_zoom": 1.68, "focus": Vector2(0.50, 0.28)}
		"venom_sage":
			return {"frame_width_pct": 0.72, "crop_zoom": 1.18, "focus": Vector2(0.53, 0.42)}
		"ember_mage":
			return {"frame_width_pct": 0.70, "crop_zoom": 1.10, "focus": Vector2(0.50, 0.46)}
		_:
			return {"frame_width_pct": 0.70, "crop_zoom": 1.0, "focus": Vector2(0.5, 0.5)}

func _get_portrait_frame_rect(inner: Rect2, crop_settings: Dictionary) -> Rect2:
	var frame_width_pct := float(crop_settings.get("frame_width_pct", 0.70))
	var frame_size := Vector2(minf(inner.size.x * frame_width_pct, inner.size.y * 0.92), inner.size.y - 2.0)
	var position := Vector2(
		inner.position.x + ((inner.size.x - frame_size.x) * 0.5),
		inner.position.y + 1.0
	)
	return Rect2(position, frame_size)

func _get_animated_texture_rect(base_rect: Rect2, bounds_rect: Rect2) -> Rect2:
	var pulse := sin(_display_time * 1.8 + _motion_phase)
	var sway := cos(_display_time * 1.25 + (_motion_phase * 0.7))
	var zoom := 1.018 + (pulse * 0.012)
	var render_size := base_rect.size * zoom
	var offset := Vector2(sway * bounds_rect.size.x * 0.01, pulse * bounds_rect.size.y * 0.008)
	var position := base_rect.position - ((render_size - base_rect.size) * 0.5) + offset
	position.x = clampf(position.x, bounds_rect.position.x - 1.0, bounds_rect.end.x - render_size.x + 1.0)
	position.y = clampf(position.y, bounds_rect.position.y - 1.0, bounds_rect.end.y - render_size.y + 1.0)
	return Rect2(position, render_size)


func _sync_process_state() -> void:
	var has_dynamic_texture := (variant == "texture" and icon_texture != null and texture_motion_enabled) or (variant == "animated_texture" and not icon_frames.is_empty())
	set_process(has_dynamic_texture)

func _draw_avatar(inner: Rect2) -> void:
	var hood := PackedVector2Array([
		Vector2(inner.position.x + inner.size.x * 0.18, inner.position.y + inner.size.y * 0.85),
		Vector2(inner.position.x + inner.size.x * 0.28, inner.position.y + inner.size.y * 0.34),
		Vector2(inner.position.x + inner.size.x * 0.50, inner.position.y + inner.size.y * 0.18),
		Vector2(inner.position.x + inner.size.x * 0.72, inner.position.y + inner.size.y * 0.34),
		Vector2(inner.position.x + inner.size.x * 0.82, inner.position.y + inner.size.y * 0.85),
	])
	draw_colored_polygon(hood, primary_color)
	draw_circle(Vector2(inner.position.x + inner.size.x * 0.5, inner.position.y + inner.size.y * 0.46), inner.size.x * 0.18, accent_color)
	draw_circle(Vector2(inner.position.x + inner.size.x * 0.5, inner.position.y + inner.size.y * 0.31), inner.size.x * 0.16, primary_color.lightened(0.36))
	draw_circle(Vector2(inner.position.x + inner.size.x * 0.43, inner.position.y + inner.size.y * 0.45), inner.size.x * 0.016, Color("15212d"))
	draw_circle(Vector2(inner.position.x + inner.size.x * 0.57, inner.position.y + inner.size.y * 0.45), inner.size.x * 0.016, Color("15212d"))
	draw_line(Vector2(inner.position.x + inner.size.x * 0.35, inner.position.y + inner.size.y * 0.72), Vector2(inner.position.x + inner.size.x * 0.65, inner.position.y + inner.size.y * 0.72), accent_color.lightened(0.1), 3.0)
	draw_arc(Vector2(inner.position.x + inner.size.x * 0.5, inner.position.y + inner.size.y * 0.16), inner.size.x * 0.28, PI * 1.04, PI * 1.96, 18, Color(1, 1, 1, 0.10), 3.0)
	draw_arc(Vector2(inner.position.x + inner.size.x * 0.5, inner.position.y + inner.size.y * 0.88), inner.size.x * 0.18, PI, TAU, 18, Color(1, 1, 1, 0.08), 2.0)

func _draw_totem(inner: Rect2) -> void:
	var center := inner.position + (inner.size * 0.5)
	draw_circle(center, inner.size.x * 0.30, Color(primary_color.r, primary_color.g, primary_color.b, 0.18))
	draw_circle(center, inner.size.x * 0.26, primary_color)
	draw_circle(center, inner.size.x * 0.16, Color("f4fbff"))
	draw_circle(center, inner.size.x * 0.08, secondary_color.darkened(0.25))
	draw_arc(center, inner.size.x * 0.34, 0.0, TAU, 36, Color(accent_color.r, accent_color.g, accent_color.b, 0.36), 4.0)
	draw_arc(center, inner.size.x * 0.42, PI * 0.1, PI * 1.05, 32, Color(1, 1, 1, 0.12), 2.0)
	draw_line(Vector2(center.x, inner.position.y + inner.size.y * 0.14), Vector2(center.x, inner.position.y + inner.size.y * 0.86), Color(1, 1, 1, 0.18), 2.0)
	draw_line(Vector2(inner.position.x + inner.size.x * 0.14, center.y), Vector2(inner.position.x + inner.size.x * 0.86, center.y), Color(1, 1, 1, 0.18), 2.0)

func _draw_button_rune(inner: Rect2) -> void:
	var center := inner.position + (inner.size * 0.5)
	draw_circle(center, inner.size.x * 0.34, primary_color)
	match emblem:
		"summon":
			draw_line(Vector2(center.x, inner.position.y + inner.size.y * 0.22), Vector2(center.x, inner.position.y + inner.size.y * 0.78), Color("fff4d7"), 4.0)
			draw_line(Vector2(inner.position.x + inner.size.x * 0.22, center.y), Vector2(inner.position.x + inner.size.x * 0.78, center.y), Color("fff4d7"), 4.0)
		"stats":
			draw_rect(Rect2(Vector2(inner.position.x + inner.size.x * 0.28, inner.position.y + inner.size.y * 0.52), Vector2(inner.size.x * 0.08, inner.size.y * 0.18)), Color("fff4d7"))
			draw_rect(Rect2(Vector2(inner.position.x + inner.size.x * 0.46, inner.position.y + inner.size.y * 0.38), Vector2(inner.size.x * 0.08, inner.size.y * 0.32)), Color("fff4d7"))
			draw_rect(Rect2(Vector2(inner.position.x + inner.size.x * 0.64, inner.position.y + inner.size.y * 0.28), Vector2(inner.size.x * 0.08, inner.size.y * 0.42)), Color("fff4d7"))
		"log":
			for line_index in range(3):
				var y := inner.position.y + inner.size.y * (0.33 + (line_index * 0.16))
				draw_line(Vector2(inner.position.x + inner.size.x * 0.26, y), Vector2(inner.position.x + inner.size.x * 0.74, y), Color("fff4d7"), 3.0)
		"speed":
			draw_polygon(PackedVector2Array([
				Vector2(inner.position.x + inner.size.x * 0.34, inner.position.y + inner.size.y * 0.28),
				Vector2(inner.position.x + inner.size.x * 0.72, inner.position.y + inner.size.y * 0.50),
				Vector2(inner.position.x + inner.size.x * 0.34, inner.position.y + inner.size.y * 0.72),
			]), PackedColorArray([Color("fff4d7"), Color("fff4d7"), Color("fff4d7")]))
		_:
			draw_line(Vector2(center.x, inner.position.y + inner.size.y * 0.22), Vector2(center.x, inner.position.y + inner.size.y * 0.78), Color("fff4d7"), 4.0)
			draw_line(Vector2(inner.position.x + inner.size.x * 0.22, center.y), Vector2(inner.position.x + inner.size.x * 0.78, center.y), Color("fff4d7"), 4.0)

func _draw_threat(inner: Rect2) -> void:
	var top := Vector2(inner.position.x + inner.size.x * 0.5, inner.position.y + inner.size.y * 0.18)
	var right := Vector2(inner.position.x + inner.size.x * 0.78, inner.position.y + inner.size.y * 0.48)
	var bottom := Vector2(inner.position.x + inner.size.x * 0.5, inner.position.y + inner.size.y * 0.82)
	var left := Vector2(inner.position.x + inner.size.x * 0.22, inner.position.y + inner.size.y * 0.48)
	draw_colored_polygon(PackedVector2Array([top, right, bottom, left]), primary_color)
	draw_line(Vector2(inner.position.x + inner.size.x * 0.5, inner.position.y + inner.size.y * 0.34), Vector2(inner.position.x + inner.size.x * 0.5, inner.position.y + inner.size.y * 0.58), Color("fff7e8"), 5.0)
	draw_circle(Vector2(inner.position.x + inner.size.x * 0.5, inner.position.y + inner.size.y * 0.70), inner.size.x * 0.035, Color("fff7e8"))

