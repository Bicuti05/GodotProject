class_name JuiceCapsuleRect
extends Control













const SOURCE_CENTER_WIDTH: = 8.0


@export var texture: Texture2D = null:
	set(value):
		texture = value
		queue_redraw()


func _notification(what: int) -> void :
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void :
	if texture == null:
		return
	var tex_w: float = float(texture.get_width())
	var tex_h: float = float(texture.get_height())
	var source_center_w: float = minf(SOURCE_CENTER_WIDTH, tex_w)
	var source_side_w: float = (tex_w - source_center_w) * 0.5
	var source_cap_h: float = tex_w * 0.5
	var source_center_h: float = tex_h - source_cap_h * 2.0
	if source_side_w <= 0.0 or source_center_h <= 0.0\
	or size.x <= 0.0 or size.y <= 0.0:
		draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
		return

	var corner_scale: float = minf(1.0, size.x / tex_w)
	corner_scale = minf(corner_scale, size.y / (source_cap_h * 2.0))
	var dst_side_w: float = source_side_w * corner_scale
	var dst_cap_h: float = source_cap_h * corner_scale
	var source_x: = PackedFloat32Array([
		0.0, source_side_w, source_side_w + source_center_w, tex_w, 
	])
	var source_y: = PackedFloat32Array([
		0.0, source_cap_h, source_cap_h + source_center_h, tex_h, 
	])
	var dst_x: = PackedFloat32Array([
		0.0, dst_side_w, size.x - dst_side_w, size.x, 
	])
	var dst_y: = PackedFloat32Array([
		0.0, dst_cap_h, size.y - dst_cap_h, size.y, 
	])
	for row in range(3):
		for col in range(3):
			_draw_patch(
				Rect2(dst_x[col], dst_y[row], 
					dst_x[col + 1] - dst_x[col], dst_y[row + 1] - dst_y[row]), 
				Rect2(source_x[col], source_y[row], 
					source_x[col + 1] - source_x[col], source_y[row + 1] - source_y[row])
			)


func _draw_patch(dst_rect: Rect2, source_rect: Rect2) -> void :
	if dst_rect.size.x <= 0.01 or dst_rect.size.y <= 0.01:
		return
	draw_texture_rect_region(texture, dst_rect, source_rect)
