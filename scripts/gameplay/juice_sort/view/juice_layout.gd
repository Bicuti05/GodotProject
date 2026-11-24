class_name JuiceLayout
extends RefCounted




















































const SIDE_MARGIN: = 22.0

const HORIZONTAL_REFERENCE_SLOTS: = 7

const VERTICAL_REFERENCE_CAPACITY: = 5


const ROPE_Y_OFFSET: = -8.0










const TRACK_TOP_FRUIT_RATIO: = 0.62


const TRACK_BOTTOM_FRUIT_RATIO: = 0.28



const TRACK_WIDTH_FRUIT_RATIO: = 232.0 / 230.0
const FRUIT_VISIBLE_WIDTH_RATIO: = 0.68
const FRUIT_VERTICAL_OVERLAP_MAX: = 1.3

var view_position: = Vector2.ZERO
var view_size: = Vector2.ZERO

var slots_total: int = 0
var base_slots_total: int = 0
var rows: int = 1
var row_pitch: float = 0.0
var columns_per_row: int = 5
var top_extra_rope: bool = false

var capacity: int = 0

var skin: JuiceSkin = null


var col_w: float = 0.0
var x0: float = 0.0
var pot_w: float = 0.0
var blender_w: float = 0.0
var blender_h: float = 0.0
var blender_display_w: float = 0.0
var blender_display_h: float = 0.0
var plank_h: float = 0.0

var content_top: float = 0.0
var blender_top: float = 0.0
var plank_top: float = 0.0
var hang_top: float = 0.0
var rope_visible_top: float = 0.0
var gap: float = 0.0
var fruit_d: float = 0.0
var rope_scale_d: float = 0.0
var first_fruit_y: float = 0.0
var rope_bottom: float = 0.0









func solve(rect: Rect2, slots: int, cap: int, sk: JuiceSkin = null, base_slots: int = 0) -> void :
	rows = 1
	top_extra_rope = false
	row_pitch = 0.0
	view_position = rect.position
	view_size = rect.size
	slots_total = maxi(1, slots)
	capacity = maxi(1, cap)
	skin = sk if sk != null else JuiceSkin.bead()


	base_slots_total = base_slots if base_slots > 0 else slots_total
	var span_budget: float = _span_budget(rect, skin)
	var reference_span_factor: float = _span_factor(HORIZONTAL_REFERENCE_SLOTS, skin)
	pot_w = minf(skin.blender_tex_size.x, span_budget / reference_span_factor)
	var blender_size_slots: int = slots_total\
	if skin.blender_w_column_overrides.has(slots_total) else base_slots_total
	blender_display_w = pot_w
	if skin.blender_w_column_overrides.has(blender_size_slots):
		blender_display_w = float(skin.blender_w_column_overrides[blender_size_slots])\
		* pot_w / skin.blender_tex_size.x
	var base_pitch: float = pot_w
	if base_slots_total > 1:
		base_pitch = maxf((span_budget - pot_w) / float(base_slots_total - 1), 1.0)
	var content_pitch: float = base_pitch
	col_w = blender_display_w
	if skin.id == JuiceSkin.ID_BEAD and slots_total == 4:

		col_w = pot_w * skin.pitch_ratio_for(slots_total)
	elif slots_total > 1:
		col_w = maxf((span_budget - blender_display_w) / float(slots_total - 1), 1.0)

	x0 = rect.position.x + (rect.size.x - span()) * 0.5

	blender_w = pot_w
	blender_h = pot_w / skin.blender_ar()
	blender_display_h = blender_display_w / skin.blender_ar()
	plank_h = pot_w * skin.plank_h_ratio





	content_top = rect.position.y
	blender_top = content_top
	plank_top = content_top + blender_h * skin.plank_top_pot_ratio
	hang_top = plank_top + plank_h * skin.rope_top_plank_ratio + ROPE_Y_OFFSET
	rope_visible_top = plank_top + plank_h + ROPE_Y_OFFSET



	var hang_avail: float = maxf(rect.size.y - (hang_top - rect.position.y), 1.0)
	var reference_rope_slots: float = maxf(float(VERTICAL_REFERENCE_CAPACITY) - 1.0
		+ skin.rope_extra_gap_ratio, 0.001)
	var rope_unit: float = minf(hang_avail / reference_rope_slots, 
		content_pitch * skin.gap_col_ratio)
	if skin.gap_design > 0.0:
		rope_unit = minf(rope_unit, skin.gap_design)
	rope_unit = maxf(rope_unit, 8.0)
	var reference_rope_span: float = rope_unit * reference_rope_slots
	var reference_end_gap: float = reference_rope_span\
	/ float(VERTICAL_REFERENCE_CAPACITY + 1)\
	- (rope_visible_top - hang_top)
	var bottom_end_gap: float = reference_end_gap * skin.rope_bottom_gap_scale
	var reference_rope_bottom: float = hang_top + reference_rope_span
	gap = (reference_rope_bottom - rope_visible_top - reference_end_gap - bottom_end_gap)\
	/ float(VERTICAL_REFERENCE_CAPACITY - 1)
	fruit_d = minf(content_pitch * skin.fruit_d_col_ratio, 
		rope_unit * skin.fruit_d_gap_ratio)
	if skin.fruit_d_design > 0.0:
		fruit_d = minf(fruit_d, skin.fruit_d_design)
	fruit_d = maxf(fruit_d, 4.0)
	rope_scale_d = fruit_d
	var fruit_size_slots: int = slots_total\
	if skin.fruit_d_column_overrides.has(slots_total) else base_slots_total
	if skin.fruit_d_column_overrides.has(fruit_size_slots):
		fruit_d = minf(fruit_d, 
			float(skin.fruit_d_column_overrides[fruit_size_slots]))
	if skin.fruit_gap_column_scales.has(fruit_size_slots):
		gap *= float(skin.fruit_gap_column_scales[fruit_size_slots])
	if capacity >= 6:


		var high_row_gap_limit: float = (rect.end.y - skin.high_row_bottom_clearance
			- rope_visible_top - reference_end_gap - bottom_end_gap)\
			/ float(capacity - 1)
		gap = minf(gap, high_row_gap_limit)
		fruit_d = minf(fruit_d, gap * skin.high_row_fruit_gap_ratio)



	var visual_offset_y: float = fruit_d * skin.fruit_visual_center_offset_y_ratio
	var first_layout_y: float = rope_visible_top + reference_end_gap
	first_fruit_y = first_layout_y + visual_offset_y + skin.fruit_group_offset_y
	var last_layout_y: float = first_layout_y + float(capacity - 1) * gap
	rope_bottom = last_layout_y + bottom_end_gap



func solve_two_rows(rect: Rect2, cap: int, sk: JuiceSkin = null, extra_rope: bool = false, pots_per_row: int = 5) -> void :

	var base_height: float = rect.size.y - 100.0
	var row_rect: Rect2 = Rect2(rect.position, Vector2(rect.size.x, base_height * 0.5 - 16.0))
	solve(row_rect, pots_per_row + 1, cap, sk, pots_per_row + 1)

	var original_d: float = fruit_d
	var original_gap: float = gap
	var old_rope_top: float = rope_visible_top
	x0 += blender_display_w * 0.15 * 0.5
	blender_display_w *= 0.85
	blender_display_h *= 0.85
	blender_w *= 0.85
	blender_h *= 0.85
	plank_h *= 0.8
	plank_top = content_top + blender_h * skin.plank_top_pot_ratio
	hang_top = plank_top + plank_h * skin.rope_top_plank_ratio + ROPE_Y_OFFSET
	rope_visible_top = plank_top + plank_h + ROPE_Y_OFFSET
	first_fruit_y += rope_visible_top - old_rope_top
	rope_bottom += rope_visible_top - old_rope_top
	var flower_limit: float = (row_rect.end.y - first_fruit_y + original_d * skin.fruit_visual_center_offset_y_ratio - 8.0) / (float(maxi(1, capacity - 1)) * 0.72 + 0.5 + skin.fruit_visual_center_offset_y_ratio)

	fruit_d = minf(original_d * 1.9, flower_limit) * 0.88
	first_fruit_y += (fruit_d - original_d) * skin.fruit_visual_center_offset_y_ratio

	first_fruit_y += 60.0

	var rope_tail: float = 24.0
	var gap_limit: float = (row_rect.end.y - first_fruit_y - fruit_d * 0.5 - rope_tail - 8.0) / float(maxi(1, capacity - 1))
	gap = minf(maxf(original_gap * 1.35, fruit_d * 0.7), gap_limit)
	rope_bottom = first_fruit_y + gap * float(capacity - 1) + fruit_d * 0.5 + rope_tail
	gap *= 1.15
	rope_bottom = hang_top + (rope_bottom - hang_top) * 1.1
	rows = 2
	top_extra_rope = extra_rope
	columns_per_row = pots_per_row
	row_pitch = base_height * 0.5 + 48.0



func fruit_y(idx: int) -> float:
	return first_fruit_y + float(idx) * gap




func fit_rope_bottom(bottom_limit: float) -> void :
	if rope_bottom <= bottom_limit or capacity <= 1:
		return
	var old_gap: float = gap
	gap = maxf(1.0, gap - (rope_bottom - bottom_limit) / float(capacity - 1))
	rope_bottom -= (old_gap - gap) * float(capacity - 1)

	var old_fruit_d: float = fruit_d
	fruit_d = minf(fruit_d, gap * FRUIT_VERTICAL_OVERLAP_MAX)
	first_fruit_y += (fruit_d - old_fruit_d) * skin.fruit_visual_center_offset_y_ratio


func slot_offset_y(slot: int) -> float:
	if rows == 1:
		return 0.0
	return row_pitch if (slot >= 5 and slot < 10) or slot == 11 else 0.0



static func _span_factor(n: int, sk: JuiceSkin) -> float:
	return maxf(1.0 + sk.pitch_ratio_for(n) * float(n - 1), 0.001)



static func _span_budget(rect: Rect2, sk: JuiceSkin) -> float:
	var avail: float = maxf(rect.size.x - SIDE_MARGIN * 2.0, 1.0)
	return minf(avail, sk.blender_tex_size.x * _span_factor(HORIZONTAL_REFERENCE_SLOTS, sk))



func span() -> float:
	return blender_display_w + col_w * float(slots_total - 1)





func slot_center_x(slot: int) -> float:
	if rows == 2 and top_extra_rope and (slot < 5 or slot == 10 or slot == 12):
		var top_slot: int = slot + 2 if slot < 5 else 1 if slot == 10 else 0
		return x0 + blender_display_w * 0.5 + col_w * float(columns_per_row) / float(columns_per_row + 1) * float(top_slot)
	var horizontal_slot: int = slot
	if rows == 2:
		horizontal_slot = slot % 5 + 1 if slot < 10 else 0
	return x0 + blender_display_w * 0.5 + col_w * horizontal_slot



func fruit_pos(slot: int, idx: int) -> Vector2:
	return Vector2(slot_center_x(slot), fruit_y(idx) + slot_offset_y(slot))



func blender_rect(slot: int) -> Rect2:
	var display_top: float = blender_top + slot_offset_y(slot)
	if blender_display_h < blender_h:
		display_top += blender_h - blender_display_h
	return Rect2(slot_center_x(slot) - blender_display_w * 0.5, 
		display_top, 
		blender_display_w, blender_display_h)







func track_rect(slot: int, cap: int = -1) -> Rect2:
	var center_x: float = slot_center_x(slot)
	var desired_w: float = fruit_d * TRACK_WIDTH_FRUIT_RATIO
	var max_half_w: float = minf(
		center_x - view_position.x, 
		view_position.x + view_size.x - center_x
	)
	var slot_pitch: float = col_w * float(columns_per_row) / float(columns_per_row + 1) if rows == 2 and top_extra_rope and (slot < 5 or slot == 10 or slot == 12) else col_w
	var w: float = minf(minf(desired_w, slot_pitch), maxf(max_half_w * 2.0, 1.0))
	var top: float = track_top()
	var bottom: float = track_bottom() if cap < 0 else track_bottom_for(cap)
	return Rect2(center_x - w * 0.5, top + slot_offset_y(slot), w, maxf(bottom - top, 1.0))



func rope_bottom_for(cap: int) -> float:
	return rope_bottom - float(maxi(0, capacity - cap)) * gap



func track_bottom_for(cap: int) -> float:
	return minf(rope_bottom_for(cap) + fruit_d * TRACK_BOTTOM_FRUIT_RATIO, content_top + view_size.y)



func track_top() -> float:
	return maxf(first_fruit_y - fruit_d * TRACK_TOP_FRUIT_RATIO, content_top)




func track_bottom() -> float:
	return minf(rope_bottom + fruit_d * TRACK_BOTTOM_FRUIT_RATIO, content_top + view_size.y)






func problems(rect: Rect2) -> Array[String]:
	var errs: Array[String] = []
	const HORIZONTAL_OVERLAP_MAX: = 1.62


	var horizontal_overlap_max: float = 1.89 if slots_total > base_slots_total\
	else HORIZONTAL_OVERLAP_MAX
	if fruit_d > col_w * horizontal_overlap_max:
		errs.append("花朵画布 %.1f > 步长 %.1f 的 %.2f 倍(横向会压到隔壁列)"
			%[fruit_d, col_w, horizontal_overlap_max])
	if fruit_d > gap * FRUIT_VERTICAL_OVERLAP_MAX:
		errs.append("花朵画布 %.1f > 间距 %.1f 的 %.2f 倍(竖向相邻的会互相压住)"
			%[fruit_d, gap, FRUIT_VERTICAL_OVERLAP_MAX])
	if blender_display_w > col_w * horizontal_overlap_max:
		errs.append("花盆画布 %.1f > 步长 %.1f 的 %.2f 倍(盆会挨在一起)"
			%[blender_display_w, col_w, horizontal_overlap_max])
	if rope_bottom > rect.position.y + rect.size.y + 1.0:
		errs.append("绳尾 %.1f 超出可用区下沿 %.1f" % [rope_bottom, rect.position.y + rect.size.y])
	if content_top < rect.position.y - 1.0:
		errs.append("内容顶 %.1f 超出可用区上沿 %.1f" % [content_top, rect.position.y])
	if x0 < rect.position.x - 1.0:
		errs.append("最左列 %.1f 超出可用区左沿 %.1f" % [x0, rect.position.x])
	if x0 + span() > rect.position.x + rect.size.x + 1.0:
		errs.append("整排右沿 %.1f 超出可用区右沿 %.1f"
			%[x0 + span(), rect.position.x + rect.size.x])
	var first_track: Rect2 = track_rect(0)
	var last_track: Rect2 = track_rect(slots_total - 1)
	if first_track.size.x < fruit_d * FRUIT_VISIBLE_WIDTH_RATIO:
		errs.append("胶囊宽 %.1f 兜不住花朵可见宽 %.1f"
			%[first_track.size.x, fruit_d * FRUIT_VISIBLE_WIDTH_RATIO])
	if first_track.position.x < rect.position.x - 1.0\
	or last_track.end.x > rect.end.x + 1.0:
		errs.append("胶囊超出盘面横向范围:%.1f..%.1f"
			%[first_track.position.x, last_track.end.x])
	if slots_total > 1:
		var second_track: Rect2 = track_rect(1)
		if first_track.end.x > second_track.position.x + 0.01:
			errs.append("相邻胶囊横向重叠 %.1fpx"
				%(first_track.end.x - second_track.position.x))
	var want_x0: float = rect.position.x + (rect.size.x - span()) * 0.5
	if absf(x0 - want_x0) > 1.0:
		errs.append("整排没居中:左沿 %.1f,居中应为 %.1f" % [x0, want_x0])
	return errs
