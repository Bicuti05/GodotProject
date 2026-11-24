class_name JuiceSkin
extends RefCounted

















const ID_BEAD: = "bead"

const DEFAULT_ID: = ID_BEAD


var id: String = DEFAULT_ID




var blender_tex_size: = Vector2(180.0, 184.0)

var blender_w_column_overrides: Dictionary = {}

var fruit_tex_size: = Vector2(200.0, 200.0)


var fruit_visual_center_offset_y_ratio: float = 0.0

var fruit_group_offset_y: float = 0.0


var pitch_ratios: Dictionary = {}


var pot_overlap_ratio: float = 0.0778

var plank_h_ratio: float = 0.5


var plank_top_pot_ratio: float = 0.641


var rope_top_plank_ratio: float = 0.222


var rope_extra_gap_ratio: float = 1.889

var rope_bottom_gap_scale: float = 1.0




var rope_tex_w_ratio: float = 0.375




var fruit_d_design: float = 180.0
var gap_design: float = 176.0

var fruit_d_col_ratio: float = 0.964
var fruit_d_gap_ratio: float = 1.081

var fruit_d_column_overrides: Dictionary = {}

var fruit_gap_column_scales: Dictionary = {}


var high_row_fruit_gap_ratio: float = 1.2
var high_row_bottom_clearance: float = 64.0

var gap_col_ratio: float = 0.892



var colors: PackedColorArray = PackedColorArray()


func blender_ar() -> float:
	return blender_tex_size.x / maxf(1.0, blender_tex_size.y)



func pitch_ratio_for(slots: int) -> float:
	if pitch_ratios.has(slots):
		return maxf(float(pitch_ratios[slots]), 0.05)
	return maxf(1.0 - pot_overlap_ratio, 0.05)









static func bead() -> JuiceSkin:
	var s: = JuiceSkin.new()
	s.id = ID_BEAD
	s.blender_tex_size = Vector2(180.0, 184.0)




	s.blender_w_column_overrides = {5: 190.0, 6: 198.0, 7: 171.0, 8: 150.0}
	s.fruit_tex_size = Vector2(200.0, 200.0)
	s.fruit_visual_center_offset_y_ratio = 0.0575
	s.fruit_group_offset_y = -10.0

	s.pitch_ratios = {3: 1.6, 4: 1.4166667, 5: 1.0, 6: 0.9222, 7: 0.7925926}
	s.pot_overlap_ratio = 0.0778
	s.plank_h_ratio = 0.5
	s.plank_top_pot_ratio = 0.641
	s.rope_top_plank_ratio = 0.222
	s.rope_extra_gap_ratio = 1.889
	s.rope_bottom_gap_scale = 1.25





	s.rope_tex_w_ratio = 0.2935
	s.fruit_d_design = 230.0
	s.gap_design = 194.0
	s.fruit_d_col_ratio = 1.62
	s.fruit_d_gap_ratio = 1.19
	s.fruit_d_column_overrides = {6: 207.0, 7: 180.0, 8: 168.0}

	s.fruit_gap_column_scales = {6: 0.9, 7: 180.0 / 230.0, 8: 180.0 / 230.0}
	s.high_row_fruit_gap_ratio = 1.24
	s.gap_col_ratio = 1.36
	s.colors = PackedColorArray([
		Color("#FA2C2E"), 
		Color("#A94CF3"), 
		Color("#FB72B2"), 
		Color("#72C3FB"), 
		Color("#FDDB2D"), 
		Color("#36C041"), 
		Color("#145EF6"), 
		Color("#53D9B3"), 
		Color("#FD9232"), 
		Color("#D2ADE3"), 
	])
	return s
