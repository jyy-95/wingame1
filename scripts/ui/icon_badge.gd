class_name IconBadge
extends Control

var primary_color := Color("76d4ff")
var secondary_color := Color("2a6b9a")
var accent_color := Color("ecf7ff")
var frame_color := Color(1, 1, 1, 0.55)
var variant := "avatar"
var emblem := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(72, 72)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func configure(in_primary: Color, in_secondary: Color, in_accent: Color, in_variant: String = "avatar", in_emblem: String = "") -> void:
	primary_color = in_primary
	secondary_color = in_secondary
	accent_color = in_accent
	variant = in_variant
	emblem = in_emblem
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var radius := int(round(minf(size.x, size.y) * 0.28))
	var inner := rect.grow(-6.0)
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

func _draw_totem(inner: Rect2) -> void:
	var center := inner.position + (inner.size * 0.5)
	draw_circle(center, inner.size.x * 0.26, primary_color)
	draw_circle(center, inner.size.x * 0.16, Color("f4fbff"))
	draw_circle(center, inner.size.x * 0.08, secondary_color.darkened(0.25))
	draw_arc(center, inner.size.x * 0.34, 0.0, TAU, 36, Color(accent_color.r, accent_color.g, accent_color.b, 0.36), 4.0)
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
