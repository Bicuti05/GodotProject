class_name JuiceQuotaBar
extends Control

var _skin_visuals: Dictionary[Texture2D, JuiceSkinVisual] = {}
var _skin_resources: JuiceSkinResolver
var _target_empty_icon: JuiceSkinVisual
var _rank_gift_texture: Texture2D
var _rank_gift_height_reference: JuiceSkinVisual
var _rank_gift_height_ratio: float = 1.0
var _skin_ring_center: Vector2 = Vector2(0.5, 0.5)
var _skin_ring_shape: Vector2 = Vector2.ONE

signal progress_transform_changed













const RULES_ENTRANCE_DUR: = 1.8335
const RULES_ENTRANCE_FADE_START: = 0.3596
const RULES_ENTRANCE_FADE_END: = 0.5787
const RULES_ENTRANCE_SCALE_TIMES: Array[float] = [0.7538, 1.0148, 1.2839, 1.5501, 1.818]
const RULES_ENTRANCE_SCALE_VALUES: Array[float] = [1.0, 1.05, 1.0, 1.05, 1.0]

const RULES_ENTRANCE_GLOW_TIMES: Array[float] = [0.7517, 1.0142, 1.2839, 1.5512, 1.8167]
const RULES_ENTRANCE_GLOW_VALUES: Array[float] = [0.0, 1.0, 0.4706, 1.0, 0.0]

const ELEMENT_SCALE: = 1.3
var _sunlight_collector_texture: Texture2D
var _sunlight_icon_texture: Texture2D
var _arrived_sunlight_round_cups: Dictionary = {}

func set_sunlight_textures(collector: Texture2D, icon: Texture2D) -> void :
	_sunlight_collector_texture = collector
	_sunlight_icon_texture = icon
const SLOT_SCALE: = 1.18 * ELEMENT_SCALE * 0.9 * 0.9
const HEIGHT: = 274.0
const PANEL_Y: = 62.0
const PANEL_H: = 169.0
const TAB_W: = 220.0
const TAB_H: = 62.0 * ELEMENT_SCALE

const PANEL_BORDER: = 11.0
const TAB_Y: = PANEL_Y + PANEL_BORDER - TAB_H
const BOARD_Y: = 204.0
const POT_VISIBLE_BOTTOM_RATIO: = 250.0 / 261.0
const SUNLIGHT_VISIBLE_BOTTOM_RATIO: = 163.0 / 198.0
const BOARD_H: = 52.0
const CARD_SIDE: = 24.0

const PANEL_CLIP_SIDE: = 15.0
const MIN_W: = 252.0
const MAX_W: = 1056.0
const WIDTH_PER_EXTRA_SLOT: = 100.0

const SLOT_W: = 108.0
const BASE_VISIBLE_COUNT: int = 10
const BASE_SLOT_PITCH: float = (MAX_W - CARD_SIDE * 2.0 - SLOT_W) / float(BASE_VISIBLE_COUNT - 1)
const RELAXED_SLOT_PITCH: = 118.0
var _max_visible_count: int = BASE_VISIBLE_COUNT
var _target_layout_scale: float = 1.0



const ROW_LIFT: = 18.0
const ROW_BOTTOM: = 70.0 + 108.0 * 1.18 * ELEMENT_SCALE - ROW_LIFT
const ROW_H: = 108.0 * SLOT_SCALE
const ROW_Y: = ROW_BOTTOM - ROW_H
const COUNT_SIZE: = Vector2(TAB_W - 24.0, TAB_H - 12.0)
const COUNT_Y: = TAB_Y + 2.0
const COUNT_FONT_SIZE: = 56

const IQ_MIN_W: = 524.0
const IQ_HEIGHT: = 282.0
const IQ_COUNT_SIZE: = Vector2(188.5, 54.6)
const IQ_COUNT_FONT_SIZE: = 46
const IQ_COUNT_Y: = BOARD_Y + 30.0







const PROGRESS_IMPACT_DIP: = 1.0
const PROGRESS_IMPACT_REBOUND: = -1.0
const PROGRESS_IMPACT_DURATION: = 0.305
const PROGRESS_IMPACT_SQUASH: = Vector2(0.94, 0.94)
const PROGRESS_IMPACT_STRETCH: = Vector2(1.025, 1.025)

const POP_SCALE: = 1.5

const POP_DIP: = 0.9

const POP_RISE_DUR: = 0.12

const POP_DUR: = 0.5

const AUTO_REVEAL_DUR: = 0.2

const AUTO_PREVIEW_UNFINISHED_COUNT: = 3

const AUTO_PREVIEW_DELAY: = POP_RISE_DUR


const HIDDEN_COLLAPSE_DUR: = 0.24




const CUP_RING_SCALE_FROM: = 0.1
const CUP_RING_APPEAR_DUR: = 0.15


const CUP_RING_ROT_SPEED_DEG: = 54.0


const CUP_RING_HOLD_DUR: = 0.5


const CUP_RING_FADE_DUR: = 1.0



const CUP_RING_SIZE_RATIO: = 1.3824


const CUP_RING_ALPHA_MAX: = 0.5





const CUP_RING_COLOR_FALLBACK: = Color(1.0, 0.9529, 0.7)

@export var tab_style: StyleBoxTexture
@export var panel_style: StyleBoxTexture

@export var slot_empty_texture: Texture2D

@export var cup_ring_texture: Texture2D

@onready var _count: Label = $Count
@onready var _board: NinePatchRect = $ProgressPotBoard
@onready var _iq_tab: TextureRect = $IqTab
@onready var _bottom_count_tab: TextureRect = $BottomCountTab
@onready var _rules_bar: JuiceRulesBar = $RulesBar

signal width_changed()

var _total: int = 0
var _endless_mode: bool = false
const ENDLESS_HISTORY_LIMIT: int = 32
var _endless_first_slot: int = 0
var _endless_reserved_end: int = 0
var _collected_count: int = 0
var _iq_layout_enabled: bool = false
var _rules_layout_enabled: bool = false
var _rules_entrance_active: bool = false
var _rules_entrance_rest_scale: = Vector2.ONE
var _rules_entrance_rest_pivot: = Vector2.ZERO
var _rules_entrance_rest_color: = Color.WHITE

var _texs: Array[Texture2D] = []

var _tints: PackedColorArray = PackedColorArray()




var _pops: Dictionary = {}

var _pop_tweens: Dictionary = {}
var _progress_impact_tween: Tween
var _progress_impact_phase: float = 0.0
var _progress_impact_active: bool = false
var _progress_impact_rest_position: Vector2
var _progress_impact_rest_scale: = Vector2.ONE
var _progress_impact_rest_pivot: Vector2
var _preview_cup_slot: int = -1
var _preview_cup_texture: Texture2D
var _preview_cup_tint: = Color.WHITE



var _rings: Dictionary = {}


var _ring_tweens: Dictionary = {}


var _scroll: float = 0.0
var _dragging: bool = false
var _scroll_tween: Tween = null


func _ready() -> void :
	panel_style = panel_style.duplicate() as StyleBoxTexture
	tab_style = tab_style.duplicate() as StyleBoxTexture
	_count.size = COUNT_SIZE
	_count.add_theme_font_size_override("font_size", COUNT_FONT_SIZE)
	resized.connect(_layout_visual)
	_layout_visual()
	_apply_mouse_filter()


func _exit_tree() -> void :
	reset_rules_entrance()



func desired_width() -> float:
	if _rules_layout_enabled:
		return JuiceRulesBar.DESIGN_SIZE.x
	if _total <= 0:
		return MAX_W
	var visible_slots: int = clampi(_total, 1, _max_visible_count)
	var base_width: float = MIN_W + WIDTH_PER_EXTRA_SLOT * float(visible_slots - 1)
	var width: float = clampf((base_width - CARD_SIDE * 2.0) * _target_layout_scale + CARD_SIDE * 2.0, MIN_W, MAX_W)
	if _total >= _max_visible_count:
		width = MAX_W
	return maxf(width, IQ_MIN_W) if _iq_layout_enabled else width


func desired_height() -> float:
	if _rules_layout_enabled:
		return JuiceRulesBar.DESIGN_SIZE.y
	return IQ_HEIGHT if _iq_layout_enabled else HEIGHT



func slot_row_height() -> float:
	return ROW_H * _target_layout_scale


func _slot_width() -> float:
	return SLOT_W * _target_layout_scale



func _row_top_y() -> float:
	return ROW_BOTTOM - slot_row_height()


func layout_pivot() -> Vector2:
	return Vector2(size.x * 0.5, JuiceRulesBar.DESIGN_SIZE.y * 0.5 if _rules_layout_enabled\
	else PANEL_Y + PANEL_H * 0.5)



func view_global_rect() -> Rect2:
	return get_global_transform() * _view_rect()



func set_rules_layout_enabled(enabled: bool) -> void :
	_rules_layout_enabled = enabled
	if not is_node_ready():
		return
	_dragging = false
	_kill_all_pops()
	_kill_all_rings()
	_kill_scroll_tween()
	reset_rules_entrance()
	_rules_bar.set_active_rule(-1)
	_layout_visual()
	_apply_mouse_filter()
	_refresh()
	width_changed.emit()


func set_active_rule(index: int) -> void :
	_rules_bar.set_active_rule(index)



func begin_rules_entrance() -> void :
	reset_rules_entrance()
	if not _rules_layout_enabled:
		return
	stop_progress_impact()
	_rules_entrance_rest_scale = scale
	_rules_entrance_rest_pivot = pivot_offset
	_rules_entrance_rest_color = modulate
	_rules_entrance_active = true
	pivot_offset = Vector2(size.x * 0.5, JuiceRulesBar.DESIGN_SIZE.y * 0.5)
	set_rules_entrance_time(0.0)


func set_rules_entrance_time(time: float) -> void :
	if not _rules_entrance_active:
		return
	if time >= RULES_ENTRANCE_DUR:
		reset_rules_entrance()
		return
	var color: Color = _rules_entrance_rest_color
	color.a *= clampf((time - RULES_ENTRANCE_FADE_START) / (RULES_ENTRANCE_FADE_END - RULES_ENTRANCE_FADE_START), 0.0, 1.0)
	modulate = color
	var factor: float = 1.0
	for i: int in RULES_ENTRANCE_SCALE_TIMES.size() - 1:
		if time >= RULES_ENTRANCE_SCALE_TIMES[i] and time < RULES_ENTRANCE_SCALE_TIMES[i + 1]:
			var u: float = (time - RULES_ENTRANCE_SCALE_TIMES[i]) / (RULES_ENTRANCE_SCALE_TIMES[i + 1] - RULES_ENTRANCE_SCALE_TIMES[i])
			factor = lerpf(RULES_ENTRANCE_SCALE_VALUES[i], RULES_ENTRANCE_SCALE_VALUES[i + 1], _rules_entrance_bezier_ease(u))
			break
	scale = _rules_entrance_rest_scale * factor
	_rules_bar.set_entrance_glow_alpha(_rules_entrance_glow_alpha(time))


func _rules_entrance_glow_alpha(time: float) -> float:
	for i: int in RULES_ENTRANCE_GLOW_TIMES.size() - 1:
		if time >= RULES_ENTRANCE_GLOW_TIMES[i] and time < RULES_ENTRANCE_GLOW_TIMES[i + 1]:
			var u: float = (time - RULES_ENTRANCE_GLOW_TIMES[i]) / (RULES_ENTRANCE_GLOW_TIMES[i + 1] - RULES_ENTRANCE_GLOW_TIMES[i])
			return lerpf(RULES_ENTRANCE_GLOW_VALUES[i], RULES_ENTRANCE_GLOW_VALUES[i + 1], u)
	return 0.0



func _rules_entrance_bezier_ease(u: float) -> float:
	var low: float = 0.0
	var high: float = 1.0
	for i: int in 16:
		var t: float = (low + high) * 0.5
		var inverse: float = 1.0 - t
		var x: float = 3.0 * inverse * inverse * t * 0.42 + 3.0 * inverse * t * t * 0.58 + t * t * t
		if x < u:
			low = t
		else:
			high = t
	var t: float = (low + high) * 0.5
	return t * t * (3.0 - 2.0 * t)



func reset_rules_entrance() -> void :
	if is_instance_valid(_rules_bar):
		_rules_bar.set_entrance_glow_alpha(0.0)
	if not _rules_entrance_active:
		return
	_rules_entrance_active = false
	scale = _rules_entrance_rest_scale
	pivot_offset = _rules_entrance_rest_pivot
	modulate = _rules_entrance_rest_color



func set_iq_layout_enabled(enabled: bool) -> void :
	if _iq_layout_enabled == enabled:
		return
	_iq_layout_enabled = enabled
	_layout_visual()
	width_changed.emit()


func _layout_visual() -> void :
	_rules_bar.set_iq_tab_enabled(_iq_layout_enabled)
	_rules_bar.visible = _rules_layout_enabled
	_count.visible = not _rules_layout_enabled
	_board.visible = not _rules_layout_enabled
	if _rules_layout_enabled:
		_iq_tab.hide()
		_bottom_count_tab.hide()
		_rules_bar.position = Vector2((size.x - JuiceRulesBar.DESIGN_SIZE.x) * 0.5, 0.0)
		if _rules_entrance_active:
			pivot_offset = Vector2(size.x * 0.5, JuiceRulesBar.DESIGN_SIZE.y * 0.5)
		queue_redraw()
		return
	_count.size = IQ_COUNT_SIZE if _iq_layout_enabled else COUNT_SIZE
	_count.position = Vector2((size.x - _count.size.x) * 0.5 - (12.0 if _iq_layout_enabled else 0.0), 
		IQ_COUNT_Y if _iq_layout_enabled else COUNT_Y)
	_count.add_theme_font_size_override("font_size", IQ_COUNT_FONT_SIZE if _iq_layout_enabled else COUNT_FONT_SIZE)
	if _iq_layout_enabled:
		var font: Font = _count.get_theme_font("font")
		var line: = TextLine.new()
		line.add_string("0", font, IQ_COUNT_FONT_SIZE)
		var server: TextServer = TextServerManager.get_primary_interface()
		var rid: RID = font.get_rids()[0]
		var glyph: int = server.font_get_glyph_index(rid, IQ_COUNT_FONT_SIZE, 48, 0)
		var ink_center: float = line.get_line_ascent() + server.font_get_glyph_offset(rid, Vector2i(IQ_COUNT_FONT_SIZE, 0), glyph).y + server.font_get_glyph_size(rid, Vector2i(IQ_COUNT_FONT_SIZE, 0), glyph).y * 0.5
		_count.size.y = maxf(IQ_COUNT_SIZE.y, _count.get_minimum_size().y)
		_count.position.y = BOARD_Y + 24.0 + IQ_COUNT_SIZE.y * 0.5 - ink_center - (_count.size.y - line.get_size().y) * 0.5

	_iq_tab.visible = _iq_layout_enabled
	_iq_tab.position = Vector2((size.x - 492.0) * 0.5, PANEL_Y - 53.0)
	_bottom_count_tab.visible = _iq_layout_enabled
	_bottom_count_tab.size = IQ_COUNT_SIZE
	_bottom_count_tab.position = Vector2((size.x - IQ_COUNT_SIZE.x) * 0.5 - 12.0, BOARD_Y + 24.0)
	_board.position = Vector2(-4.0, BOARD_Y)
	if _progress_impact_active:
		pivot_offset = layout_pivot()
	_board.size = Vector2(size.x + 8.0, BOARD_H)

	_rebuild_slot_offsets()
	_clamp_scroll()
	_apply_mouse_filter()
	queue_redraw()



var _hidden_completed_slots: Array[int] = []



var _hidden_collapse: Dictionary = {}

var _hidden_collapse_tweens: Dictionary = {}

var _slot_offsets: PackedFloat32Array = PackedFloat32Array()

func setup(total: int) -> void :
	_endless_mode = false
	_endless_first_slot = 0
	_endless_reserved_end = 0
	_collected_count = 0
	_arrived_sunlight_round_cups.clear()
	_hidden_completed_slots.clear()
	_hidden_collapse.clear()
	_kill_all_hidden_collapse()
	_kill_all_pops()
	_kill_all_rings()
	_kill_scroll_tween()
	_total = maxi(0, total)
	_texs.clear()
	_tints = PackedColorArray()
	_scroll = 0.0
	_rebuild_slot_offsets()
	width_changed.emit()
	_apply_mouse_filter()
	_refresh()




func push_cup(tex: Texture2D, tint: Color, hide_content: bool = false, completed_slot: int = -1) -> void :
	if _endless_mode:
		var absolute_slot: int = completed_slot if completed_slot >= 0 else _endless_first_slot + _texs.size()
		if absolute_slot < _endless_first_slot:
			return
		reserve_endless_slot(absolute_slot)
	if _texs.size() >= _total:
		return
	var slot_index: int = _texs.size()
	if hide_content:
		_hidden_completed_slots.append(slot_index)
	_texs.append(tex)
	_tints.append(tint)
	if _rules_layout_enabled:
		_refresh()
		return
	if hide_content:


		_refresh()
		_start_hidden_collapse(slot_index)
		return


	_reveal(maxi(slot_index, 0))
	_refresh()

	_start_pop(slot_index)

	_start_ring(slot_index)
	_auto_preview_unfinished_slots()


func push_sunlight_round_cup(slot: int, tex: Texture2D, tint: Color, hide_content: bool = false) -> void :
	if slot < _texs.size() or slot >= _total:
		return
	_arrived_sunlight_round_cups[slot] = {"texture": tex, "tint": tint, "hide_content": hide_content}
	if slot > _texs.size() and not hide_content and (tex == _sunlight_collector_texture or tex == _rank_gift_texture):
		_preview_cup_slot = slot
		_preview_cup_texture = tex
		_preview_cup_tint = tint
		queue_redraw()
	while _arrived_sunlight_round_cups.has(_texs.size()):
		var next: int = _texs.size()
		var arrived: Dictionary = _arrived_sunlight_round_cups[next]
		_arrived_sunlight_round_cups.erase(next)
		if _preview_cup_slot == next:
			clear_preview_cup()
		push_cup(arrived["texture"] as Texture2D, arrived["tint"] as Color, bool(arrived.get("hide_content", false)))





func set_cups(texs: Array[Texture2D], tints: PackedColorArray, hidden_slots: Array[int] = []) -> void :
	_arrived_sunlight_round_cups.clear()
	clear_preview_cup()
	_hidden_completed_slots = hidden_slots.duplicate()


	_kill_all_pops()
	_kill_all_rings()

	_kill_all_hidden_collapse()
	_hidden_collapse.clear()
	for i: int in _hidden_completed_slots:
		_hidden_collapse[i] = 1.0
	_texs = texs.duplicate()
	_tints = tints.duplicate()
	if _texs.size() > _total:
		_texs.resize(_total)
	if _tints.size() > _total:
		_tints.resize(_total)
	_rebuild_slot_offsets()
	var next_slot: int = mini(_texs.size(), maxi(_total - 1, 0))
	_reveal(_auto_reveal_target(next_slot))
	_refresh()


func filled_count() -> int:
	return _texs.size()



func count_global_rect() -> Rect2:
	if _rules_layout_enabled:
		return _rules_bar.count_global_rect()
	return _count.get_global_rect()



func cup_global_rect(i: int, tex: Texture2D) -> Rect2:
	if _rules_layout_enabled:
		return _rules_bar.target_global_rect()
	return get_global_transform() * _cup_rect(tex, i - _endless_first_slot if _endless_mode else i)





func cell_global_rect(i: int) -> Rect2:
	if _rules_layout_enabled:
		return _rules_bar.target_global_rect()
	return get_global_transform() * _slot_rect(i)



func reveal_slot(i: int) -> void :
	if _endless_mode:
		i -= _endless_first_slot
	if not _scrollable() or i < 0 or i >= _total:
		return
	_tween_reveal(i)



func _auto_preview_unfinished_slots() -> void :
	if _dragging or not _scrollable() or _texs.size() >= _total:
		return
	var first_unfinished: int = _texs.size()
	if _is_slot_fully_visible(first_unfinished):
		return
	_tween_reveal(_auto_reveal_target(first_unfinished), AUTO_PREVIEW_DELAY)


func _tween_reveal(i: int, delay: float = 0.0) -> void :
	var target: float = _revealed_scroll(i)
	if is_equal_approx(target, _scroll):
		return
	_kill_scroll_tween()
	_scroll_tween = create_tween()
	if delay > 0.0:
		_scroll_tween.tween_interval(delay)
	_scroll_tween.tween_method(_set_scroll, _scroll, target, AUTO_REVEAL_DUR)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_scroll_tween.finished.connect(_on_scroll_tween_finished, CONNECT_ONE_SHOT)






func preview_slot_index() -> int:
	if _rules_layout_enabled:
		return mini(_texs.size(), maxi(0, _total - 1))
	var result: int = -1
	var best: float = INF
	for i: int in range(_total):

		if _hidden_completed_slots.has(i):
			continue
		if not _is_slot_fully_visible(i):
			continue
		var score: float = absf(_slot_rect(i).get_center().x - size.x * 0.5)
		if i < _texs.size():
			score += size.x
		if score < best:
			result = i
			best = score
	return result



func show_preview_cup(tex: Texture2D, tint: Color, slot: int) -> void :
	if _rules_layout_enabled:
		return
	clear_preview_cup()
	_preview_cup_slot = slot
	_preview_cup_texture = tex
	_preview_cup_tint = tint
	_start_pop(slot)
	_start_ring(slot)
	queue_redraw()


func clear_preview_cup() -> void :
	if _preview_cup_slot >= 0:
		_kill_pop(_preview_cup_slot)
		_kill_ring(_preview_cup_slot)
	_preview_cup_slot = -1
	_preview_cup_texture = null
	queue_redraw()




func play_progress_impact() -> void :
	stop_progress_impact()
	_progress_impact_rest_position = position
	_progress_impact_rest_scale = scale
	_progress_impact_rest_pivot = pivot_offset
	pivot_offset = layout_pivot()
	_progress_impact_active = true
	_progress_impact_tween = create_tween()
	_progress_impact_tween.tween_method(_set_progress_impact, 0.0, PROGRESS_IMPACT_DIP, 0.045).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_progress_impact_tween.tween_interval(0.025)
	_progress_impact_tween.tween_method(_set_progress_impact, PROGRESS_IMPACT_DIP, PROGRESS_IMPACT_REBOUND, 0.085).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_progress_impact_tween.tween_method(_set_progress_impact, PROGRESS_IMPACT_REBOUND, 0.15, 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_progress_impact_tween.tween_method(_set_progress_impact, 0.15, 0.0, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_progress_impact_tween.finished.connect(stop_progress_impact, CONNECT_ONE_SHOT)


func stop_progress_impact() -> void :
	if _progress_impact_tween != null and _progress_impact_tween.is_valid():
		_progress_impact_tween.kill()
	_progress_impact_tween = null
	_progress_impact_phase = 0.0
	if _progress_impact_active:
		position = _progress_impact_rest_position
		scale = _progress_impact_rest_scale
		pivot_offset = _progress_impact_rest_pivot
		_progress_impact_active = false
		progress_transform_changed.emit()


func _set_progress_impact(phase: float) -> void :
	_progress_impact_phase = phase
	if not _progress_impact_active:
		return
	position = _progress_impact_rest_position
	var shape_scale: Vector2
	if phase >= 0.0:
		shape_scale = Vector2.ONE.lerp(PROGRESS_IMPACT_SQUASH, phase / PROGRESS_IMPACT_DIP)
	else:
		shape_scale = Vector2.ONE.lerp(PROGRESS_IMPACT_STRETCH, phase / PROGRESS_IMPACT_REBOUND)
	scale = _progress_impact_rest_scale * shape_scale
	progress_transform_changed.emit()


func _start_pop(i: int) -> void :
	if i < 0 or i >= _total:
		return
	_kill_pop(i)

	_pops[i] = 1.0
	queue_redraw()

	var back: float = maxf(0.0, POP_DUR - POP_RISE_DUR) * 0.5
	var tw: Tween = create_tween()
	tw.tween_method(_set_pop.bind(i), 1.0, POP_SCALE, POP_RISE_DUR)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(_set_pop.bind(i), POP_SCALE, POP_DIP, back)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(_set_pop.bind(i), POP_DIP, 1.0, back)\
	.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.finished.connect(_kill_pop.bind(i), CONNECT_ONE_SHOT)
	_pop_tweens[i] = tw


func _set_pop(k: float, i: int) -> void :
	_pops[i] = k
	queue_redraw()



func _kill_pop(i: int) -> void :
	var tw: Tween = _pop_tweens.get(i) as Tween
	if tw != null and tw.is_valid():
		tw.kill()
	_pop_tweens.erase(i)
	_pops.erase(i)
	queue_redraw()


func _kill_all_pops() -> void :
	clear_preview_cup()
	stop_progress_impact()
	for i: int in _pop_tweens.keys():
		var tw: Tween = _pop_tweens[i] as Tween
		if tw != null and tw.is_valid():
			tw.kill()
	_pop_tweens.clear()
	_pops.clear()
	queue_redraw()






func _start_ring(i: int) -> void :
	if i < 0 or i >= _total or cup_ring_texture == null:
		return
	_kill_ring(i)
	var color: Color = _tints[i] if i < _tints.size() else CUP_RING_COLOR_FALLBACK
	_rings[i] = {"scale": CUP_RING_SCALE_FROM, "rot_deg": 0.0, "alpha": CUP_RING_ALPHA_MAX, "color": color}
	queue_redraw()
	var tw: Tween = create_tween()
	tw.tween_method(_set_ring_scale.bind(i), CUP_RING_SCALE_FROM, 1.0, CUP_RING_APPEAR_DUR)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(_start_ring_spin.bind(i))
	tw.tween_interval(CUP_RING_HOLD_DUR)
	tw.tween_method(_set_ring_alpha.bind(i), CUP_RING_ALPHA_MAX, 0.0, CUP_RING_FADE_DUR)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(_kill_ring.bind(i))
	_ring_tweens[i] = [tw]





func _start_ring_spin(i: int) -> void :
	if not _rings.has(i):
		return
	var dur: float = CUP_RING_HOLD_DUR + CUP_RING_FADE_DUR
	var spin_tw: Tween = create_tween()
	spin_tw.tween_method(_set_ring_rot.bind(i), 0.0, CUP_RING_ROT_SPEED_DEG * dur, dur)\
	.set_trans(Tween.TRANS_LINEAR)
	if _ring_tweens.has(i):
		(_ring_tweens[i] as Array).append(spin_tw)


func _set_ring_scale(k: float, i: int) -> void :
	if _rings.has(i):
		_rings[i]["scale"] = k
		queue_redraw()


func _set_ring_rot(deg: float, i: int) -> void :
	if _rings.has(i):
		_rings[i]["rot_deg"] = deg
		queue_redraw()


func _set_ring_alpha(a: float, i: int) -> void :
	if _rings.has(i):
		_rings[i]["alpha"] = a
		queue_redraw()



func _kill_ring(i: int) -> void :
	var tweens: Variant = _ring_tweens.get(i)
	if tweens != null:
		for tw in (tweens as Array):
			if tw != null and (tw as Tween).is_valid():
				(tw as Tween).kill()
	_ring_tweens.erase(i)
	_rings.erase(i)
	queue_redraw()


func _kill_all_rings() -> void :
	for i: int in _ring_tweens.keys():
		for tw in (_ring_tweens[i] as Array):
			if tw != null and (tw as Tween).is_valid():
				(tw as Tween).kill()
	_ring_tweens.clear()
	_rings.clear()
	queue_redraw()



func _scaled_about_center(r: Rect2, k: float) -> Rect2:
	var c: Vector2 = r.position + r.size * 0.5
	var sz: Vector2 = r.size * k
	return Rect2(c - sz * 0.5, sz)


func _refresh() -> void :
	if _count != null:
		_count.text = str(_collected_count) if _endless_mode else "%d/%d" % [_texs.size(), _total]
		_rules_bar.set_count(_count.text)
	queue_redraw()


func setup_endless() -> void :
	setup(_endless_initial_slot_count())
	_endless_mode = true
	_refresh()


func _endless_initial_slot_count() -> int:
	return mini(_max_visible_count, ENDLESS_HISTORY_LIMIT) + AUTO_PREVIEW_UNFINISHED_COUNT


func set_collected_count(value: int) -> void :
	var count: int = maxi(0, value)
	if count == _collected_count:
		return
	_collected_count = count
	_refresh()


func set_endless_cups(texs: Array[Texture2D], tints: PackedColorArray, count: int) -> void :
	_collected_count = maxi(0, count)
	var start: int = maxi(0, texs.size() - ENDLESS_HISTORY_LIMIT)
	var recent: Array[Texture2D] = texs.slice(start)
	_endless_first_slot = maxi(0, count - recent.size())
	_endless_reserved_end = count
	_total = maxi(_endless_initial_slot_count(), recent.size() + AUTO_PREVIEW_UNFINISHED_COUNT)
	_apply_mouse_filter()
	set_cups(recent, tints.slice(start))



func is_endless_slot_retained(index: int) -> bool:
	return index >= _endless_first_slot and index < _endless_reserved_end


func reserve_endless_slot(index: int) -> void :
	if not _endless_mode or index < _endless_first_slot:
		return
	_endless_reserved_end = maxi(_endless_reserved_end, index + 1)
	var first: int = maxi(0, _endless_reserved_end - ENDLESS_HISTORY_LIMIT)
	if first > _endless_first_slot:
		var removed: int = first - _endless_first_slot
		_kill_all_pops()
		_kill_all_rings()
		_kill_scroll_tween()
		_texs = _texs.slice(mini(removed, _texs.size()))
		_tints = _tints.slice(mini(removed, _tints.size()))
		_scroll += float(removed) * _slot_pitch()
		_endless_first_slot = first
	var total: int = maxi(_endless_initial_slot_count(), 
		_endless_reserved_end - _endless_first_slot + AUTO_PREVIEW_UNFINISHED_COUNT)
	if total != _total:
		_total = total
	_rebuild_slot_offsets()
	_clamp_scroll()
	_apply_mouse_filter()





func _view_rect() -> Rect2:
	return Rect2(CARD_SIDE, _row_top_y(), size.x - CARD_SIDE * 2.0, slot_row_height())



func _slot_clip_rect() -> Rect2:
	return Rect2(PANEL_CLIP_SIDE, PANEL_Y, size.x - PANEL_CLIP_SIDE * 2.0, BOARD_Y - PANEL_Y)



func _slot_weight(i: int) -> float:
	if not _hidden_completed_slots.has(i):
		return 1.0
	return 1.0 - clampf(float(_hidden_collapse.get(i, 1.0)), 0.0, 1.0)



func _visible_weight() -> float:
	var weight: float = 0.0
	for i: int in _total:
		weight += _slot_weight(i)
	return weight



func _content_w() -> float:
	return _slot_width() + _slot_pitch() * maxf(_visible_weight() - 1.0, 0.0)




func _slot_pitch() -> float:
	var weight: float = _visible_weight()
	if weight <= 1.0:
		return 0.0
	if _max_visible_count == 1:
		return _view_rect().size.x
	if weight <= float(_max_visible_count):
		return minf(RELAXED_SLOT_PITCH * _target_layout_scale, (_view_rect().size.x - _slot_width()) / (weight - 1.0))
	return (_view_rect().size.x - _slot_width()) / float(_max_visible_count - 1)



func _rebuild_slot_offsets() -> void :
	_slot_offsets.resize(_total)
	var pitch: float = _slot_pitch()
	var acc: float = 0.0
	for i: int in _total:
		_slot_offsets[i] = pitch * acc
		acc += _slot_weight(i)
	queue_redraw()



func _slot_offset(i: int) -> float:
	return _slot_offsets[i] if i >= 0 and i < _slot_offsets.size() else 0.0


func _scrollable() -> bool:
	return not _rules_layout_enabled and _total > _max_visible_count\
	and _content_w() > _view_rect().size.x + 0.5




func _auto_reveal_target(fallback_slot: int) -> int:
	if not _scrollable() or _texs.size() >= _total:
		return fallback_slot
	var first_unfinished: int = _texs.size()
	if _is_slot_fully_visible(first_unfinished):
		return fallback_slot
	var preview_end: int = mini(
		first_unfinished + AUTO_PREVIEW_UNFINISHED_COUNT - 1, _total - 1)
	return maxi(fallback_slot, preview_end)



func is_cup_fully_visible(slot: int) -> bool:
	return _is_slot_fully_visible(slot)

func _is_slot_fully_visible(i: int) -> bool:
	if i < 0 or i >= _total:
		return false
	var view: Rect2 = _view_rect()
	var left: float = _content_x() + _slot_offset(i)
	var right: float = left + _slot_width()
	return left >= view.position.x - 0.5 and right <= view.position.x + view.size.x + 0.5




func _content_x() -> float:
	var view: Rect2 = _view_rect()
	if not _scrollable():
		return view.position.x + (view.size.x - _content_w()) * 0.5
	return view.position.x + _scroll



func _slot_rect(i: int) -> Rect2:
	var aspect: float = 1.0
	if slot_empty_texture != null and slot_empty_texture.get_height() > 0:
		aspect = float(slot_empty_texture.get_width()) / float(slot_empty_texture.get_height())
	var height: float = slot_row_height()
	var w: float = height * aspect
	var cx: float = _content_x() + _slot_offset(i) + _slot_width() * 0.5
	return Rect2(cx - w * 0.5, _row_top_y(), w, height)



func _reveal(i: int) -> void :
	if not _scrollable() or i < 0 or i >= _total:
		return
	_kill_scroll_tween()
	_scroll = _revealed_scroll(i)
	queue_redraw()


func _revealed_scroll(i: int) -> float:
	var view: Rect2 = _view_rect()
	var left: float = _slot_offset(i)

	var target: float = clampf(_scroll, - left, view.size.x - (left + _slot_width()))
	return clampf(target, minf(view.size.x - _content_w(), 0.0), 0.0)


func _set_scroll(value: float) -> void :
	_scroll = value
	queue_redraw()


func _kill_scroll_tween() -> void :
	if _scroll_tween != null and _scroll_tween.is_valid():
		_scroll_tween.kill()
	_scroll_tween = null


func _on_scroll_tween_finished() -> void :
	_scroll_tween = null


func _clamp_scroll() -> void :
	_scroll = clampf(_scroll, minf(_view_rect().size.x - _content_w(), 0.0), 0.0)



func _start_hidden_collapse(i: int) -> void :
	_kill_hidden_collapse(i)
	_hidden_collapse[i] = 0.0
	_rebuild_slot_offsets()
	_clamp_scroll()
	var tw: Tween = create_tween()
	tw.tween_method(_set_hidden_collapse.bind(i), 0.0, 1.0, HIDDEN_COLLAPSE_DUR)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.finished.connect(_kill_hidden_collapse.bind(i), CONNECT_ONE_SHOT)
	_hidden_collapse_tweens[i] = tw


func _set_hidden_collapse(k: float, i: int) -> void :
	_hidden_collapse[i] = k
	_rebuild_slot_offsets()
	_clamp_scroll()

	_apply_mouse_filter()


func _kill_hidden_collapse(i: int) -> void :
	var tw: Tween = _hidden_collapse_tweens.get(i) as Tween
	if tw != null and tw.is_valid():
		tw.kill()
	_hidden_collapse_tweens.erase(i)


func _kill_all_hidden_collapse() -> void :
	for i: int in _hidden_collapse_tweens.keys():
		var tw: Tween = _hidden_collapse_tweens[i] as Tween
		if tw != null and tw.is_valid():
			tw.kill()
	_hidden_collapse_tweens.clear()





func _apply_mouse_filter() -> void :
	mouse_filter = Control.MOUSE_FILTER_STOP if _scrollable() else Control.MOUSE_FILTER_IGNORE



func _gui_input(e: InputEvent) -> void :
	if not _scrollable():
		return
	if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_dragging = (e as InputEventMouseButton).pressed
		if _dragging:
			_kill_scroll_tween()
	elif e is InputEventMouseMotion and _dragging:
		var mm: InputEventMouseMotion = e


		if (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			_dragging = false
			return
		_scroll += mm.relative.x
		_clamp_scroll()
		queue_redraw()




func _draw() -> void :
	if _rules_layout_enabled:
		return

	if panel_style != null:
		draw_style_box(panel_style, Rect2(0.0, PANEL_Y, size.x, PANEL_H))
	if tab_style != null and not _iq_layout_enabled:
		draw_style_box(tab_style, Rect2((size.x - TAB_W) * 0.5, TAB_Y, TAB_W, TAB_H))
	if _total <= 0:
		return
	var view: Rect2 = _slot_clip_rect()
	var empty_texture: Texture2D = _target_empty_icon.texture if _target_empty_icon != null else slot_empty_texture

	var popped: Array[int] = []
	for i in _total:
		if _hidden_completed_slots.has(i):
			continue
		var got: bool = i < _texs.size()
		var tex: Texture2D = _texs[i] if got else null
		var tint: = Color.WHITE
		if i == _preview_cup_slot and _preview_cup_texture != null:
			tex = _preview_cup_texture
			tint = _preview_cup_tint
		if tex == null:

			tex = empty_texture
			if got and i < _tints.size():
				tint = _tints[i]
		if tex == null:
			continue

		_draw_ring(i, _cup_rect(tex, i))
		if _pops.has(i):
			popped.append(i)
			continue
		_draw_slot_clipped(tex, _cup_rect(tex, i), view, tint)


	var pop_view: = Rect2(view.position.x, 0.0, view.size.x, view.end.y)
	for i: int in popped:
		var got: bool = i < _texs.size()
		var tex: Texture2D = _texs[i] if got else null
		var tint: = Color.WHITE
		if i == _preview_cup_slot and _preview_cup_texture != null:
			tex = _preview_cup_texture
			tint = _preview_cup_tint
		if tex == null:
			tex = empty_texture
			if got and i < _tints.size():
				tint = _tints[i]
		if tex == null:
			continue
		_draw_slot_clipped(tex, _scaled_about_center(_cup_rect(tex, i), float(_pops[i])), 
			pop_view, tint)



func _cup_rect(tex: Texture2D, i: int) -> Rect2:
	var rect: Rect2 = _slot_rect(i)
	if tex != null and tex == _sunlight_collector_texture:
		rect.position.y += rect.size.y * (POT_VISIBLE_BOTTOM_RATIO - SUNLIGHT_VISIBLE_BOTTOM_RATIO)
	if tex != null and _skin_visuals.has(tex):
		var visual: JuiceSkinVisual = _skin_visuals[tex]
		if tex == _rank_gift_texture and _rank_gift_height_reference != null\
		and visual.source_bounds.has_area() and _rank_gift_height_reference.source_bounds.has_area():

			var original: Rect2 = _rank_gift_height_reference.display_rect(rect)
			var original_scale: float = original.size.y / _rank_gift_height_reference.texture.get_height()
			var gift_scale: float = _rank_gift_height_reference.source_bounds.size.y * original_scale\
			* _rank_gift_height_ratio / visual.source_bounds.size.y
			var bottom_y: float = original.position.y + _rank_gift_height_reference.source_bounds.end.y * original_scale
			var gift_position: Vector2 = Vector2(rect.get_center().x - visual.source_bounds.get_center().x * gift_scale, 
				bottom_y - visual.source_bounds.end.y * gift_scale)
			return Rect2(gift_position, visual.texture.get_size() * gift_scale)
		rect = visual.display_rect(rect)
	return rect




func _draw_ring(i: int, cup_rect: Rect2) -> void :
	var st: Variant = _rings.get(i)
	if st == null or cup_ring_texture == null:
		return
	var alpha: float = float((st as Dictionary)["alpha"])
	if alpha <= 0.001:
		return
	var color: Color = (st as Dictionary).get("color", CUP_RING_COLOR_FALLBACK)
	var geometry: Dictionary = _clipped_ring_geometry(cup_rect, 
		deg_to_rad(float((st as Dictionary)["rot_deg"])), float((st as Dictionary)["scale"]))
	var vertices: PackedVector2Array = geometry["vertices"]
	if vertices.size() < 3:
		return
	draw_polygon(vertices, PackedColorArray([Color(color.r, color.g, color.b, alpha)]), 
		geometry["uvs"], cup_ring_texture)


func _clipped_ring_geometry(cup_rect: Rect2, angle: float, scale_value: float) -> Dictionary:
	var center: Vector2 = cup_rect.position + cup_rect.size * _skin_ring_center
	var shape: Vector2 = _skin_ring_shape * scale_value

	var transform: Transform2D = Transform2D(
		Vector2(cos(angle) * shape.x, sin(angle) * shape.y), 
		Vector2( - sin(angle) * shape.x, cos(angle) * shape.y), center)
	var half: float = slot_row_height() * CUP_RING_SIZE_RATIO * 0.5
	var vertices: PackedVector2Array = PackedVector2Array([
		transform * Vector2( - half, - half), transform * Vector2(half, - half), 
		transform * Vector2(half, half), transform * Vector2( - half, half)])
	var uvs: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN])
	var view: Rect2 = _slot_clip_rect()

	view.position.y += PANEL_BORDER
	view.size.y -= PANEL_BORDER
	for edge: int in 4:
		if vertices.is_empty():
			break
		var axis: int = 0 if edge < 2 else 1
		var lower: bool = edge % 2 == 0
		var boundary: float = view.position[axis] if lower else view.end[axis]
		var clipped: PackedVector2Array = PackedVector2Array()
		var clipped_uvs: PackedVector2Array = PackedVector2Array()
		var previous: Vector2 = vertices[-1]
		var previous_uv: Vector2 = uvs[-1]
		var previous_inside: bool = previous[axis] >= boundary if lower else previous[axis] <= boundary
		for j: int in vertices.size():
			var current: Vector2 = vertices[j]
			var current_uv: Vector2 = uvs[j]
			var current_inside: bool = current[axis] >= boundary if lower else current[axis] <= boundary
			if current_inside != previous_inside:
				var fraction: float = (boundary - previous[axis]) / (current[axis] - previous[axis])
				clipped.append(previous.lerp(current, fraction))
				clipped_uvs.append(previous_uv.lerp(current_uv, fraction))
			if current_inside:
				clipped.append(current)
				clipped_uvs.append(current_uv)
			previous = current
			previous_uv = current_uv
			previous_inside = current_inside
		vertices = clipped
		uvs = clipped_uvs
	return {"vertices": vertices, "uvs": uvs}




func _draw_slot_clipped(tex: Texture2D, dst: Rect2, view: Rect2, tint: Color) -> void :
	var vis: Rect2 = dst.intersection(view)
	if vis.size.x <= 0.5 or vis.size.y <= 0.5:
		return
	var k: = Vector2(tex.get_width() / dst.size.x, tex.get_height() / dst.size.y)
	var src: = Rect2((vis.position - dst.position) * k, vis.size * k)
	var brightness: float = JuiceFruit.get_debug_flower_brightness()
	tint *= Color(brightness, brightness, brightness, 1.0)
	draw_texture_rect_region(tex, vis, src, tint)
	if tex == _sunlight_collector_texture and _sunlight_icon_texture != null:
		var icon_rect: Rect2 = Rect2(dst.get_center() - dst.size * 0.17, dst.size * 0.34)
		var icon_visible: Rect2 = icon_rect.intersection(view)
		if icon_visible.size.x > 0.5 and icon_visible.size.y > 0.5:
			var icon_scale: Vector2 = _sunlight_icon_texture.get_size() / icon_rect.size
			var icon_source: Rect2 = Rect2((icon_visible.position - icon_rect.position) * icon_scale, 
				icon_visible.size * icon_scale)
			draw_texture_rect_region(_sunlight_icon_texture, icon_visible, icon_source, tint)


func apply_skin(resources: JuiceSkinResolver) -> void :
	var max_visible_count: int = resources.target_bar_max_visible_count()
	var layout_changed: bool = max_visible_count != _max_visible_count
	if layout_changed:
		stop_progress_impact()
		_kill_scroll_tween()
		_dragging = false
		_max_visible_count = max_visible_count

		_target_layout_scale = (MAX_W - CARD_SIDE * 2.0)\
		/ (SLOT_W + BASE_SLOT_PITCH * float(_max_visible_count - 1))
	_skin_ring_center = resources.quota_ring_center()
	_skin_ring_shape = resources.quota_ring_shape()
	_skin_resources = resources
	cup_ring_texture = resources.effect_texture(&"quota_ring", cup_ring_texture)
	_skin_visuals.clear()
	var gift: JuiceSkinVisual = resources.rank_collectible_visual(&"target_icon")
	_rank_gift_texture = gift.texture if gift != null else null
	_rank_gift_height_reference = resources.original_color_visual(resources.rank_collectible_color, &"target_icon") if gift != null else null
	_rank_gift_height_ratio = resources.rank_collectible_target_height_ratio() if gift != null else 1.0
	_target_empty_icon = resources.single_visual(&"target_empty_icon")
	_rules_bar.apply_skin(resources)
	_skin_visuals[_target_empty_icon.texture] = _target_empty_icon
	for key: String in JuiceTheme.COLOR_KEYS:
		var visual: JuiceSkinVisual = resources.color_visual(key, &"target_icon")
		_skin_visuals[visual.texture] = visual
	if layout_changed:
		if _endless_mode:
			_total = maxi(_endless_initial_slot_count(), 
				_endless_reserved_end - _endless_first_slot + AUTO_PREVIEW_UNFINISHED_COUNT)
		_layout_visual()
		width_changed.emit()
		_clamp_scroll()
		_apply_mouse_filter()
	queue_redraw()

func icon_bottom_ratio(texture: Texture2D) -> float:
	return _skin_visuals[texture].bottom_anchor.y if _skin_visuals.has(texture) else POT_VISIBLE_BOTTOM_RATIO
