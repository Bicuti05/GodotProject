class_name SpecialChallengeChest
extends Button


@export var opened: bool = false:
	set(value):
		opened = value
		queue_redraw()

func _draw() -> void :
	var unit: Vector2 = size / Vector2(120.0, 100.0)
	draw_style_box(_box(Color("d58c29")), Rect2(Vector2(8, 38) * unit, Vector2(104, 54) * unit))
	draw_style_box(_box(Color("ffd45a")), Rect2(Vector2(4, 8 if opened else 25) * unit, Vector2(112, 28) * unit))
	draw_rect(Rect2(Vector2(51, 36) * unit, Vector2(18, 27) * unit), Color("fff0a0"))
	draw_circle(Vector2(60, 49) * unit, 4.0 * minf(unit.x, unit.y), Color("683c24"))

func _box(color: Color) -> StyleBoxFlat:
	var box: = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = Color("683c24")
	box.set_border_width_all(3)
	box.set_corner_radius_all(8)
	return box
