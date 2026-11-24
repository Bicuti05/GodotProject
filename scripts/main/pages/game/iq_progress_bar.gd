class_name IqProgressBar
extends Control


const DESIGN_WIDTH: float = 432.0
const DESIGN_HEIGHT: float = 135.0
const MARK_VALUES: Array[float] = [40.0, 90.0, 140.0, 180.0]
const BOOSTED_MARK_VALUES: Array[float] = [60.0, 110.0, 160.0, 200.0]
const MARK_X: Array[float] = [25.5, 178.5, 284.4, 399.0]
const FILL_STOPS: Array[float] = [0.0, 16.5, 171.0, 277.0, 414.0]
const PROGRESS_DURATION: float = 0.4
const COUNTDOWN_DESIGN_SIZE: Vector2 = Vector2(413.0, 25.0)
const COUNTDOWN_LEAD_GROW: float = 0.28
const COUNTDOWN_LEAD_FADE: float = 0.22
@export var new_track_texture: Texture2D
var _rules_layout_enabled: bool = false
var _original_track_texture: Texture2D

@onready var _track: TextureRect = $Track
@onready var _new_track_frame: TextureRect = $NewTrackFrame
@onready var _fill_clip: Control = $FillClip
@onready var _fill: TextureRect = $FillClip / Fill
@onready var _countdown_fill: TextureRect = $CountdownFill
@onready var _countdown_lead: TextureRect = $CountdownLead
@onready var _countdown_material: ShaderMaterial = _countdown_fill.material as ShaderMaterial
@onready var _glow: TextureRect = $FillClip / Glow
@onready var _glow_material: ShaderMaterial = _glow.material as ShaderMaterial
@onready var _markers: Array[Control] = [$Marks / Iq40, $Marks / Iq90, $Marks / Iq140, $Marks / Iq180]
@onready var _dividers: Array[TextureRect] = [$Divider90, $Divider140]

var _trail_lifecycles: Array[GpuParticleLifecycle] = [GpuParticleLifecycle.new(), GpuParticleLifecycle.new()]
@onready var _trails: Array[GPUParticles2D] = [$TrailDots, $TrailStars]
var motion_enabled: bool = true
var _moving: bool = false
var _star_active: bool = false
var _breath_time: float = 0.0
var _glow_strength: float = 0.7
var _full_accent: float = 0.0

@onready var _badge: TextureRect = $Marks / Iq140
@onready var _badge_material: ShaderMaterial = _badge.material as ShaderMaterial
@onready var _badge_impact: GPUParticles2D = $BadgeImpact
var _impact_lifecycle: GpuParticleLifecycle = GpuParticleLifecycle.new()
var _badge_tween: Tween
var _badge_unlocked: bool = false
var _badge_offset: Vector2 = Vector2.ZERO

var _iq: float = 40.0
var _mark_values: Array[float] = MARK_VALUES
var _display_width: float = 16.5
var _progress_tween: Tween = null
var _countdown_mode: bool = false
var _countdown_fraction: float = 1.0
var _lead_tween: Tween
var _lead_active: bool = false
var _lead_pending: bool = false
var _lead_from: float = 0.0
var _lead_generation: int = 0


func _ready() -> void :
	_glow.material = _glow.material.duplicate()
	_glow_material = _glow.material as ShaderMaterial
	_badge.material = _badge.material.duplicate()
	_badge_material = _badge.material as ShaderMaterial
	_original_track_texture = _track.texture
	resized.connect(_layout_progress)
	_display_width = FILL_STOPS[-1] * _countdown_fraction if _countdown_mode else _fill_width(_iq)
	_set_countdown_visibility()
	_layout_progress()
	_update_badge(false)
	for i: int in _trails.size():
		_trail_lifecycles[i].prepare([_trails[i]], 2, _can_render_motion)
	_impact_lifecycle.prepare([_badge_impact], 2, _can_render_impact)



func set_rules_layout_enabled(enabled: bool) -> void :
	if _rules_layout_enabled == enabled:
		return
	_rules_layout_enabled = enabled
	if is_node_ready():
		_update_badge(false)
		_layout_progress()


func _badge_rest_y() -> float:
	return 0.0 if _rules_layout_enabled else -13.0



func set_score_boost_enabled(enabled: bool) -> void :
	var marks: Array[float] = BOOSTED_MARK_VALUES if enabled else MARK_VALUES
	if _mark_values == marks:
		return
	_mark_values = marks
	if is_node_ready():
		_cancel_progress_tween()
		_reset_motion()
		if not _countdown_mode:
			_set_display_width(_fill_width(_iq))
			_update_badge(false)


func set_iq(iq: float, animate: bool = true) -> void :
	if _countdown_mode:
		_countdown_mode = false
		animate = false
		_cancel_countdown_lead()
		if is_node_ready():
			_set_countdown_visibility()
	var previous_width: float = _fill_width(_iq)
	var target_width: float = _fill_width(iq)
	_iq = iq
	if not is_node_ready():
		_display_width = target_width
		return
	if not animate or not is_visible_in_tree() or target_width <= _display_width:
		_cancel_progress_tween()
		_reset_motion()
		_set_display_width(target_width)
		_update_badge(false)
		return

	if is_equal_approx(target_width, previous_width):
		_layout_progress()
		return
	var continuing: bool = _moving
	_cancel_progress_tween(false)
	_moving = true
	if motion_enabled:
		var distance: float = target_width - _display_width
		_trail_lifecycles[0].set_opacity(clampf(distance / 35.0, 0.25, 1.0))
		if not continuing:
			_trail_lifecycles[0].play()
		if distance >= 8.0:
			_trail_lifecycles[1].set_opacity(clampf(distance / 35.0, 0.25, 1.0))
			if not continuing or not _star_active:
				_trail_lifecycles[1].play()
			_star_active = true
		else:
			_trail_lifecycles[1].stop_with_tail()
			_star_active = false
	_progress_tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	_progress_tween.tween_method(_set_display_width, _display_width, target_width, PROGRESS_DURATION)
	_progress_tween.tween_callback(_finish_growth)


func _notification(what: int) -> void :
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready() and not is_visible_in_tree():
		_cancel_progress_tween()
		_reset_motion()
		if _countdown_mode:
			_apply_countdown_progress()
		else:
			_set_display_width(_fill_width(_iq))
			_update_badge(false)


func _exit_tree() -> void :
	_cancel_progress_tween()
	_reset_motion()


func _cancel_progress_tween(stop_particles: bool = true) -> void :
	if stop_particles and is_node_ready():
		_moving = false
		for lifecycle: GpuParticleLifecycle in _trail_lifecycles:
			lifecycle.stop_with_tail()
	if _progress_tween != null and _progress_tween.is_valid():
		_progress_tween.kill()
	_progress_tween = null


func _set_display_width(width: float) -> void :
	_display_width = width
	_layout_progress()
	_update_badge(_moving and motion_enabled)



func _fill_width(iq: float) -> float:
	var clamped: float = clampf(iq, 0.0, _mark_values[-1])
	var previous_iq: float = 0.0
	for i: int in _mark_values.size():
		if clamped <= _mark_values[i]:
			return lerpf(FILL_STOPS[i], FILL_STOPS[i + 1], 
				(clamped - previous_iq) / (_mark_values[i] - previous_iq))
		previous_iq = _mark_values[i]
	return FILL_STOPS[-1]


func _layout_progress() -> void :
	var ratio: float = size.x / DESIGN_WIDTH
	var track_y: float = 83.0

	_track.texture = new_track_texture if _rules_layout_enabled else _original_track_texture
	_track.position = Vector2(0.0, track_y) if _rules_layout_enabled else Vector2(-4.32 * ratio, 79.76)
	_track.size = Vector2(432.0 * ratio, 43.2) if _rules_layout_enabled else Vector2(440.64 * ratio, 51.84)
	_new_track_frame.visible = _rules_layout_enabled
	_new_track_frame.position = Vector2(0.0, track_y)
	_new_track_frame.size = Vector2(432.0 * ratio, 43.2)
	_fill_clip.position = Vector2(9.0 * ratio, 92.0)
	_fill_clip.size = Vector2(_display_width * ratio, 26.0)
	_fill.size = Vector2(414.0 * ratio, 26.0)
	if _countdown_mode:
		var image_scale: float = minf(FILL_STOPS[-1] * ratio / COUNTDOWN_DESIGN_SIZE.x, 
			26.0 / COUNTDOWN_DESIGN_SIZE.y)
		_countdown_fill.size = COUNTDOWN_DESIGN_SIZE * image_scale
		_countdown_fill.position = Vector2(9.0 * ratio, 92.0 + (26.0 - _countdown_fill.size.y) * 0.5)
		_apply_countdown_progress()
		_sync_countdown_lead_layout()
		return

	_glow.position = Vector2(_fill_clip.size.x - _glow.size.x, (26.0 - _glow.size.y) * 0.5)
	var mask_size: Vector2 = Vector2(maxf(1.0, _fill.size.x), _fill.size.y)
	var mask_origin: Vector2 = _glow.position / mask_size
	var mask_scale: Vector2 = _glow.size / mask_size
	_glow_material.set_shader_parameter("mask_uv_rect", Vector4(
		mask_origin.x, mask_origin.y, mask_scale.x, mask_scale.y))
	_glow.visible = _fill_clip.size.x > 0.0
	for trail: GPUParticles2D in _trails:
		trail.position = _fill_clip.position + Vector2(maxf(9.0, _fill_clip.size.x - 12.0), 13.0)
	_badge_impact.position = Vector2(MARK_X[2] * ratio, _badge.size.y * 0.5)
	for i: int in _dividers.size():
		_dividers[i].position = Vector2((175.0 if i == 0 else 281.0) * ratio, 92.0)
		_dividers[i].size = Vector2(5.0 * ratio, 26.0)
	for i: int in _markers.size():
		var marker: Control = _markers[i]
		marker.position.x = MARK_X[i] * ratio - marker.size.x * 0.5
		if marker is Label:
			var label: Label = marker as Label
			label.text = str(int(_mark_values[i]))
			var font: Font = label.get_theme_font("font")
			var font_size: int = label.get_theme_font_size("font_size")
			var line: = TextLine.new()
			line.add_string("0", font, font_size)
			var server: TextServer = TextServerManager.get_primary_interface()
			var rid: RID = font.get_rids()[0]
			var glyph: int = server.font_get_glyph_index(rid, font_size, 48, 0)
			var ink_center: float = line.get_line_ascent() + server.font_get_glyph_offset(rid, Vector2i(font_size, 0), glyph).y + server.font_get_glyph_size(rid, Vector2i(font_size, 0), glyph).y * 0.5
			label.size.y = maxf(74.0, label.get_minimum_size().y)
			label.position.y = 43.0 - ink_center - (label.size.y - line.get_size().y) * 0.5
		else:
			var badge_size: float = 86.4 if _rules_layout_enabled else 96.0
			marker.size = Vector2.ONE * badge_size
			marker.position = Vector2(MARK_X[i] * ratio - badge_size * 0.5, _badge_rest_y())
	_badge.position.y = _badge_rest_y() + _badge_offset.y
	_badge_impact.position = Vector2(MARK_X[2] * ratio, _badge_rest_y() + _badge.size.y * 0.5)
	var impact_material: ParticleProcessMaterial = _badge_impact.process_material
	impact_material.emission_sphere_radius = _badge.size.x * 0.42


func set_motion_enabled(enabled: bool) -> void :
	motion_enabled = enabled
	_reset_motion()
	_update_badge(false)

func _reset_motion() -> void :
	if not is_node_ready():
		return
	for lifecycle: GpuParticleLifecycle in _trail_lifecycles:
		lifecycle.reset_immediate()
	_impact_lifecycle.reset_immediate()
	_breath_time = 0.0
	_full_accent = 0.0
	if is_instance_valid(_badge_tween):
		_badge_tween.kill()
	_badge_tween = null
	_badge.scale = Vector2.ONE
	_badge_offset = Vector2.ZERO
	_badge.position.y = _badge_rest_y()
	_glow_strength = 0.7 if motion_enabled else 1.0
	_glow_material.set_shader_parameter("glow_strength", _glow_strength)

func _finish_growth() -> void :
	_moving = false
	_star_active = false
	for lifecycle: GpuParticleLifecycle in _trail_lifecycles:
		lifecycle.stop_with_tail()
	if motion_enabled and _display_width >= FILL_STOPS[-1] - 0.01:
		_full_accent = 0.22

func _process(delta: float) -> void :
	if _countdown_mode or not motion_enabled or not is_visible_in_tree():
		return
	_breath_time = fposmod(_breath_time + delta, 2.0)
	_full_accent = maxf(0.0, _full_accent - delta)
	var breath: float = 0.65 + 0.2 * (0.5 - 0.5 * cos(TAU * _breath_time / 2.0))
	var target: float = 1.0 if _moving or _full_accent > 0.0 else breath
	_glow_strength = move_toward(_glow_strength, target, delta * (4.0 if _moving else 1.4))
	_glow_material.set_shader_parameter("glow_strength", _glow_strength)


func _can_render_motion() -> bool:
	return not _countdown_mode and motion_enabled and _moving and is_inside_tree() and is_visible_in_tree()


func _update_badge(animate: bool) -> void :
	if _countdown_mode:
		return
	var reached: bool = _display_width >= FILL_STOPS[3] - 0.001
	if not animate:
		if is_instance_valid(_badge_tween):
			_badge_tween.kill()
		_badge.scale = Vector2.ONE
		_badge_offset = Vector2.ZERO
		_badge.position.y = _badge_rest_y()
		_badge_unlocked = reached
		_badge_material.set_shader_parameter("unlock_progress", 1.0 if reached else 0.0)
		return
	if not reached or _badge_unlocked:
		return
	_badge_unlocked = true
	_badge.pivot_offset = _badge.size * 0.5
	_badge_tween = create_tween()

	_badge_tween.tween_method(_set_badge_offset, Vector2.ZERO, Vector2(0, 3), 0.04)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_badge_tween.parallel().tween_property(_badge, "scale", Vector2(1.04, 0.94), 0.04)
	_badge_tween.tween_callback(_impact_lifecycle.play)
	_badge_tween.tween_method(_set_badge_offset, Vector2(0, 3), Vector2(0, -2), 0.07)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_badge_tween.parallel().tween_property(_badge, "scale", Vector2(1.04, 1.07), 0.07)
	_badge_tween.parallel().tween_method(_set_badge_red, 0.0, 1.0, 0.14)
	_badge_tween.tween_method(_set_badge_offset, Vector2(0, -2), Vector2.ZERO, 0.11)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_badge_tween.parallel().tween_property(_badge, "scale", Vector2.ONE, 0.11)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _set_badge_offset(value: Vector2) -> void :
	_badge_offset = value
	_badge.position.y = _badge_rest_y() + value.y

func _set_badge_red(value: float) -> void :
	_badge_material.set_shader_parameter("unlock_progress", value)


func _can_render_impact() -> bool:
	return not _countdown_mode and motion_enabled and is_inside_tree() and is_visible_in_tree() and _badge_unlocked



func begin_countdown_lead() -> void :
	if not _countdown_mode or not is_node_ready():
		return
	_lead_from = _countdown_lead.scale.x if _lead_active and _countdown_lead.visible else _countdown_fill.scale.x
	_lead_pending = true
	_lead_active = true


func set_countdown_progress(fraction: float) -> void :
	var entering: bool = not _countdown_mode
	var clamped: float = clampf(fraction, 0.0, 1.0)
	if _lead_pending and is_node_ready():
		_countdown_mode = true
		_countdown_fraction = clamped
		_display_width = FILL_STOPS[-1] * clamped
		_lead_pending = false
		_play_countdown_lead(clamped)
		return
	if _lead_active and not entering:
		_countdown_fraction = clamped
		_display_width = FILL_STOPS[-1] * clamped
		return
	if not entering and clamped == _countdown_fraction:
		return
	_countdown_mode = true
	_countdown_fraction = clamped
	_display_width = FILL_STOPS[-1] * clamped
	if not is_node_ready():
		return
	if entering:
		_cancel_countdown_lead()
		_cancel_progress_tween()
		_reset_motion()
		_set_countdown_visibility()
		_layout_progress()
	else:
		_apply_countdown_progress()


func _apply_countdown_progress() -> void :
	if not _lead_active:
		_countdown_fill.scale = Vector2(_countdown_fraction, 1.0)
		_countdown_material.set_shader_parameter("color_weights", _countdown_color_weights(_countdown_fraction))
	var shown: float = _countdown_fill.scale.x if _lead_active else _countdown_fraction
	_countdown_fill.visible = _countdown_mode and shown > 0.0


func _play_countdown_lead(target: float) -> void :
	_lead_generation += 1
	var generation: int = _lead_generation
	var start: float = clampf(_lead_from, 0.0, 1.0)
	_sync_countdown_lead_layout()
	_countdown_fill.scale = Vector2(start, 1.0)
	_countdown_fill.visible = _countdown_mode and start > 0.0
	_countdown_material.set_shader_parameter("color_weights", _countdown_color_weights(target))
	_countdown_lead.modulate.a = 1.0
	_set_countdown_lead_span(start, start)
	_countdown_lead.visible = target > start
	if _lead_tween != null and _lead_tween.is_valid():
		_lead_tween.kill()
	if target <= start:
		_finish_countdown_lead(generation)
		return
	_lead_tween = create_tween()
	_lead_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_lead_tween.tween_method(_set_countdown_lead_span.bind(start), start, target, COUNTDOWN_LEAD_GROW)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_lead_tween.tween_callback(_reveal_countdown_under_lead.bind(generation, target))
	_lead_tween.tween_property(_countdown_lead, "modulate:a", 0.0, COUNTDOWN_LEAD_FADE)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_lead_tween.tween_callback(_finish_countdown_lead.bind(generation))



func _set_countdown_lead_span(shown: float, start: float) -> void :
	_countdown_lead.scale = Vector2(shown, 1.0)
	var clip: float = 1.0 if shown <= start else start / shown
	(_countdown_lead.material as ShaderMaterial).set_shader_parameter("clip_u", clip)


func _reveal_countdown_under_lead(generation: int, target: float) -> void :
	if generation != _lead_generation or not is_instance_valid(_countdown_fill):
		return
	_countdown_fill.scale = Vector2(target, 1.0)
	_countdown_fill.visible = _countdown_mode and target > 0.0


func _finish_countdown_lead(generation: int) -> void :
	if generation != _lead_generation:
		return
	_lead_active = false
	_lead_pending = false
	_lead_tween = null
	if is_instance_valid(_countdown_lead):
		_countdown_lead.hide()
		_countdown_lead.modulate.a = 1.0
	if _countdown_mode and is_node_ready():
		_apply_countdown_progress()


func _cancel_countdown_lead() -> void :
	_lead_generation += 1
	_lead_active = false
	_lead_pending = false
	if _lead_tween != null and _lead_tween.is_valid():
		_lead_tween.kill()
	_lead_tween = null
	if is_instance_valid(_countdown_lead):
		_countdown_lead.hide()
		_countdown_lead.modulate.a = 1.0


func _sync_countdown_lead_layout() -> void :
	if not is_instance_valid(_countdown_lead) or not is_instance_valid(_countdown_fill):
		return
	_countdown_lead.position = _countdown_fill.position
	_countdown_lead.size = _countdown_fill.size
	_countdown_lead.pivot_offset = Vector2.ZERO
	_countdown_fill.pivot_offset = Vector2.ZERO



static func _countdown_color_weights(fraction: float) -> Vector3:
	if fraction >= 0.75:
		return Vector3(1.0, 0.0, 0.0)
	if fraction > 0.5:
		var yellow: float = _countdown_ease((0.75 - fraction) * 4.0)
		return Vector3(1.0 - yellow, yellow, 0.0)
	if fraction >= 0.25:
		return Vector3(0.0, 1.0, 0.0)
	var red: float = _countdown_ease((0.25 - fraction) * 4.0)
	return Vector3(0.0, 1.0 - red, red)



static func _countdown_ease(progress: float) -> float:
	var x: float = clampf(progress, 0.0, 1.0)
	var t: float = x
	for _iteration: int in 3:
		var curve_x: float = t * (0.99 + t * (0.03 - 0.02 * t))
		var derivative: float = 0.99 + t * (0.06 - 0.06 * t)
		t -= (curve_x - x) / derivative
	return t * t * (3.0 - 2.0 * t)


func _set_countdown_visibility() -> void :
	_fill_clip.visible = not _countdown_mode
	_countdown_fill.visible = _countdown_mode and _countdown_fraction > 0.0
	if not _countdown_mode and is_instance_valid(_countdown_lead):
		_countdown_lead.hide()
	$Marks.visible = not _countdown_mode
	for divider: TextureRect in _dividers:
		divider.visible = not _countdown_mode
