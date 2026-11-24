class_name StreakTierBanner
extends Control





const DURATION: float = 2.6
const EXIT_START: float = 2.25
const ENTER_DURATION: float = 0.24
const ROLL_DELAY: float = 0.55
const TITLE_START: float = 0.26
const SOUND_DELAY: float = 0.36
const BACKDROP_ALPHA: float = 0.8
const DESIGN_SIZE: = Vector2(1080.0, 2340.0)

const TIER_LV1: int = 1
const TIER_LV2: int = 2
const TIER_LV3: int = 3
const SPINE_ANIMATIONS: Array[StringName] = [&"001", &"002", &"003"]
const SPINE_SHIELD_SLOTS: Array[String] = ["dp1_1", "dp2_2", "dp3_2"]
const SPINE_ORIGINS: Array[Vector2] = [
	Vector2(539.725, 1106.2), Vector2(540.6, 1090.2), Vector2(538.46, 1071.9), 
]
const SPINE_REFERENCE_TIME: float = 1.0
const GLOW_COLORS: Array[Color] = [Color("FFB67E"), Color("35C2FF"), Color("A135FF")]


const TITLE_CENTER_Y: Array[float] = [1395.0, 1399.0, 1403.9]
const SUBTITLE_CENTER_Y: Array[float] = [1504.1, 1508.1, 1513.0]

const TITLE_INK_HEIGHT: float = 172.0
const SUBTITLE_INK_HEIGHT: float = 95.0


const TITLE_SHADOW_OFFSET_Y: float = 4.8
const SUBTITLE_SHADOW_OFFSET_Y: float = 2.52


const TITLE_BASE_OFFSET_Y: float = 1.0
const TITLE_ORANGE_OFFSET_Y: float = 6.0




const BODY_CENTER_Y: Array[float] = [1233.9, 1221.7, 1183.1]




const LV1_NUMBER_COLOR: = Color(1.0, 0.402799, 0.11859, 1.0)
const LV1_NUMBER_SHADOW: = Color(0.737255, 0.427451, 0.180392, 1.0)
const LV2_NUMBER_COLORS: Array[Color] = [
	Color(0.0, 0.551321, 0.972919, 1.0), 
	Color(0.0, 0.20393, 0.873986, 1.0), 
]
const LV2_NUMBER_SHADOW: = Color(0.179888, 0.476702, 0.719551, 1.0)
const LV3_NUMBER_COLORS: Array[Color] = [
	Color(0.745098, 0.015686, 0.964706, 1.0), 
	Color(0.972549, 0.203922, 0.603922, 1.0), 
]
const LV3_NUMBER_SHADOW: = Color(0.382618, 0.179888, 0.719551, 1.0)


const LV1_NUMBER_GRADIENT_ANGLE: float = 180.0
const LV1_NUMBER_GRADIENT_SPAN: = Vector2(0.0, 1.0)
const LV2_NUMBER_GRADIENT_ANGLE: float = 154.0036
const LV2_NUMBER_GRADIENT_SPAN: = Vector2(0.214366, 0.825575)
const LV3_NUMBER_GRADIENT_ANGLE: float = -49.1055
const LV3_NUMBER_GRADIENT_SPAN: = Vector2(0.12683, 0.861363)

@onready var _backdrop: ColorRect = $Backdrop
@onready var _stage: CanvasGroup = $Stage
@onready var _glow: TextureRect = $Stage / Glow
@onready var _burst_particles: StreakBurstParticles = $Stage / BurstParticles
@onready var _content: Control = $Stage / Content
@onready var _spine: SpineSprite = $Stage / Spine
@onready var _tiers: Array[Control] = [
	$Stage / Content / Lv1, $Stage / Content / Lv2, $Stage / Content / Lv3, 
]
@onready var _numbers: Array[StreakRollNumber] = [
	$Stage / Content / Lv1 / NumberRoll, $Stage / Content / Lv2 / NumberRoll, $Stage / Content / Lv3 / NumberRoll, 
]
@onready var _titles: Array[Label] = [
	$Stage / Content / Lv1 / Title, $Stage / Content / Lv2 / Title, $Stage / Content / Lv3 / Title, 
]
@onready var _title_bases: Array[Label] = [
	$Stage / Content / Lv1 / TitleBase, $Stage / Content / Lv2 / TitleBase, $Stage / Content / Lv3 / TitleBase, 
]
@onready var _title_inners: Array[Control] = [
	$Stage / Content / Lv1 / TitleInner, $Stage / Content / Lv2 / TitleInner, $Stage / Content / Lv3 / TitleInner, 
]
@onready var _inner_viewports: Array[SubViewport] = [
	$Stage / Content / Lv1 / TitleInner / GlyphViewport, 
	$Stage / Content / Lv2 / TitleInner / GlyphViewport, 
	$Stage / Content / Lv3 / TitleInner / GlyphViewport, 
]
@onready var _inner_glyphs: Array[Label] = [
	$Stage / Content / Lv1 / TitleInner / GlyphViewport / Glyph, 
	$Stage / Content / Lv2 / TitleInner / GlyphViewport / Glyph, 
	$Stage / Content / Lv3 / TitleInner / GlyphViewport / Glyph, 
]
@onready var _subtitle_shadows: Array[Label] = [
	$Stage / Content / Lv1 / SubtitleShadow, 
	$Stage / Content / Lv2 / SubtitleShadow, 
	$Stage / Content / Lv3 / SubtitleShadow, 
]
@onready var _inner_layers: Array[TextureRect] = [
	$Stage / Content / Lv1 / TitleInner / InnerShadow, 
	$Stage / Content / Lv2 / TitleInner / InnerShadow, 
	$Stage / Content / Lv3 / TitleInner / InnerShadow, 
]
@onready var _subtitles: Array[Label] = [
	$Stage / Content / Lv1 / Subtitle, $Stage / Content / Lv2 / Subtitle, $Stage / Content / Lv3 / Subtitle, 
]


@onready var _title_base_shadows: Array[Label] = [
	$Stage / Content / Lv1 / TitleBaseShadow, 
	$Stage / Content / Lv2 / TitleBaseShadow, 
	$Stage / Content / Lv3 / TitleBaseShadow, 
]

@onready var _title_oranges: Array[Label] = [
	$Stage / Content / Lv1 / TitleOrange, 
	$Stage / Content / Lv2 / TitleOrange, 
	$Stage / Content / Lv3 / TitleOrange, 
]

var _elapsed: float = 0.0
var _playing: bool = false
var _generation: int = 0
var _on_exit: Callable
var _exit_notified: bool = false
var _roll_started: bool = false
var _landed_sound: bool = false
var _count: int = 2
var _tier: int = TIER_LV1
var _last_subtitle_key: String = ""
var _spine_track: SpineTrackEntry
var _spine_duration: float = 0.0
var _number_bone: SpineBone
var _number_reference_transform: Transform2D
var _number_base_positions: Array[Vector2] = []


func _ready() -> void :
	mouse_filter = MOUSE_FILTER_IGNORE
	_backdrop.mouse_filter = MOUSE_FILTER_IGNORE
	_spine.set_update_mode(SpineConstant.UpdateMode_Manual)
	for number: StreakRollNumber in _numbers:
		_number_base_positions.append(number.position)
	for index: int in _inner_viewports.size():
		_inner_layers[index].texture = _inner_viewports[index].get_texture()
	_layout()
	get_viewport().size_changed.connect(_layout)
	hide_now()



static func tier_for_count(count: int) -> int:
	if count >= 11:
		return TIER_LV3
	if count >= 6:
		return TIER_LV2
	return TIER_LV1


func play(count: int, _overlay: bool, on_exit: Callable = Callable(), percentile: float = -1.0, personal_best: bool = false) -> void :
	hide_now()
	_count = maxi(count, 2)
	_tier = tier_for_count(_count)
	_on_exit = on_exit
	_exit_notified = false
	_elapsed = 0.0
	_roll_started = false
	_landed_sound = false
	_playing = true
	var picked: Dictionary = StreakCopy.pick_lines(_count, percentile, personal_best, _last_subtitle_key)
	_last_subtitle_key = String(picked["key"])
	var lines: PackedStringArray = picked["lines"]
	_show_tier(_tier)
	_configure_number(_tier)
	_glow.modulate = GLOW_COLORS[_tier - 1]
	_numbers[_tier - 1].prepare(_count - 1, _count)
	_apply_text(_tier, lines)
	_layout()
	visible = true
	_start_spine(_tier)
	if _tier == TIER_LV3:
		_burst_particles.play()
	_backdrop.visible = true
	_backdrop.color.a = 0.0
	_content.scale = Vector2.ONE * 0.82
	_content.modulate.a = 0.0
	_sample(0.0)
	var generation: int = _generation
	while _playing and generation == _generation:
		await get_tree().process_frame


func hide_now() -> void :
	_generation += 1
	_playing = false
	_on_exit = Callable()
	visible = false
	if _landed_sound:
		AudioManager.stop_sfx(&"streak_celebration")
	_landed_sound = false
	if is_node_ready():
		_reset_spine()
		_stage.self_modulate = Color.WHITE
		_glow.modulate.a = 0.0
		_glow.scale = Vector2.ONE
		_burst_particles.reset()
		_backdrop.visible = false
		_backdrop.color.a = 0.0
		_content.scale = Vector2.ONE
		_content.modulate.a = 1.0
		for tier: Control in _tiers:
			tier.visible = false
		for index: int in _numbers.size():
			_numbers[index].hide_now()
			_numbers[index].position = _number_base_positions[index]
			_numbers[index].scale = Vector2.ONE
			_numbers[index].rotation = 0.0
		for title: Label in _titles:
			title.modulate.a = 1.0
		for title_base: Label in _title_bases:
			title_base.modulate.a = 1.0
		for title_base_shadow: Label in _title_base_shadows:
			title_base_shadow.modulate.a = 1.0
		for title_orange: Label in _title_oranges:
			title_orange.modulate.a = 1.0
		for title_inner: Control in _title_inners:
			title_inner.modulate.a = 1.0
		for subtitle: Label in _subtitles:
			subtitle.modulate.a = 1.0
		for subtitle_shadow: Label in _subtitle_shadows:
			subtitle_shadow.modulate.a = 1.0


func _process(delta: float) -> void :
	if not _playing:
		return
	_elapsed += delta
	if _elapsed >= ROLL_DELAY and not _roll_started:
		_roll_started = true
		_numbers[_tier - 1].play(_count - 1, _count)
	if _elapsed >= SOUND_DELAY and not _landed_sound:
		_landed_sound = true
		AudioManager.play_sfx(&"streak_celebration")
	if _elapsed >= EXIT_START and not _exit_notified:
		_exit_notified = true
		if _on_exit.is_valid():
			_on_exit.call()
		if not _playing:
			return
	_sample(_elapsed)
	_sync_text_gradients()
	if _elapsed >= DURATION:
		hide_now()


func _sample(t: float) -> void :
	var enter: float = _smooth(t / ENTER_DURATION)
	var pop: float = _keys(t, [0.0, 0.18, 0.3], [0.82, 1.06, 1.0])
	_content.scale = Vector2.ONE * pop
	_glow.scale = Vector2.ONE * pop
	_glow.modulate.a = enter
	_burst_particles.sample(t)
	_burst_particles.modulate.a *= enter
	var exit: float = _smooth((t - EXIT_START) / (DURATION - EXIT_START))
	_content.modulate.a = enter
	_stage.self_modulate.a = 1.0 - exit
	var index: int = _tier - 1
	var text_alpha: float = _smooth((t - TITLE_START) / 0.18)
	_titles[index].modulate.a = text_alpha
	_title_bases[index].modulate.a = text_alpha
	_title_base_shadows[index].modulate.a = text_alpha
	_title_oranges[index].modulate.a = text_alpha
	_title_inners[index].modulate.a = text_alpha
	_subtitles[index].modulate.a = text_alpha
	_subtitle_shadows[index].modulate.a = text_alpha
	_sample_spine(t * _spine_duration / DURATION)
	_sync_number_transform()
	_backdrop.color.a = BACKDROP_ALPHA * enter * (1.0 - exit)


func _start_spine(tier: int) -> void :
	var index: int = tier - 1
	_spine.position = SPINE_ORIGINS[index]
	_spine.modulate = Color.WHITE
	_spine.show()
	var skeleton: SpineSkeleton = _spine.get_skeleton()
	var state: SpineAnimationState = _spine.get_animation_state()
	state.clear_tracks()
	skeleton.set_to_setup_pose()
	_spine_track = state.set_animation(SPINE_ANIMATIONS[index], false, 0)
	_spine_duration = _spine_track.get_animation().get_duration()
	_number_bone = skeleton.find_slot(SPINE_SHIELD_SLOTS[index]).get_bone()
	_sample_spine(SPINE_REFERENCE_TIME)
	_number_reference_transform = _number_bone.get_global_transform().affine_inverse()\
	* _numbers[index].get_global_transform()


func _sample_spine(time: float) -> void :
	if _spine_track == null:
		return
	_spine_track.set_track_time(clampf(time, 0.0, _spine_duration))
	_spine.get_skeleton().set_to_setup_pose()
	_spine.get_animation_state().apply(_spine.get_skeleton())
	_spine.get_skeleton().update_world_transform(SpineConstant.Physics_Update)
	_spine.update_skeleton(0.0)


func _sync_number_transform() -> void :
	var number: StreakRollNumber = _numbers[_tier - 1]
	var parent: CanvasItem = number.get_parent() as CanvasItem
	var transform: Transform2D = parent.get_global_transform().affine_inverse()\
	* _number_bone.get_global_transform()\
	* _number_reference_transform
	number.position = transform.origin
	number.rotation = transform.get_rotation()
	number.scale = transform.get_scale().max(Vector2.ONE * 0.0001)


func _reset_spine() -> void :
	_spine.hide()
	_spine.get_animation_state().clear_tracks()
	_spine.get_skeleton().set_to_setup_pose()
	_spine.modulate = Color.WHITE
	_spine_track = null
	_number_bone = null
	_spine_duration = 0.0


func _layout() -> void :
	var viewport_size: Vector2 = UiMetrics.viewport_size()
	var fit_scale: float = minf(1.0, viewport_size.x / DESIGN_SIZE.x)
	_stage.scale = Vector2.ONE * fit_scale


	var body_center: Vector2 = Vector2(DESIGN_SIZE.x * 0.5, BODY_CENTER_Y[_tier - 1])
	_stage.position = viewport_size * 0.5 - body_center * fit_scale


func _show_tier(tier: int) -> void :
	for index: int in _tiers.size():
		_tiers[index].visible = index == tier - 1


func _configure_number(tier: int) -> void :
	match tier:
		TIER_LV2:
			_numbers[1].configure(
				228, LV2_NUMBER_COLORS[0], LV2_NUMBER_COLORS[1], LV2_NUMBER_SHADOW, 
				_gradient_dir(LV2_NUMBER_GRADIENT_ANGLE), LV2_NUMBER_GRADIENT_SPAN
			)
		TIER_LV3:
			_numbers[2].configure(
				228, LV3_NUMBER_COLORS[0], LV3_NUMBER_COLORS[1], LV3_NUMBER_SHADOW, 
				_gradient_dir(LV3_NUMBER_GRADIENT_ANGLE), LV3_NUMBER_GRADIENT_SPAN
			)
		_:
			_numbers[0].configure(
				228, LV1_NUMBER_COLOR, LV1_NUMBER_COLOR, LV1_NUMBER_SHADOW, 
				_gradient_dir(LV1_NUMBER_GRADIENT_ANGLE), LV1_NUMBER_GRADIENT_SPAN
			)



static func _gradient_dir(angle_deg: float) -> Vector2:
	var rad: float = deg_to_rad(angle_deg)
	return Vector2(sin(rad), - cos(rad))


func _apply_text(tier: int, lines: PackedStringArray) -> void :
	var index: int = tier - 1
	var title: Label = _titles[index]
	var title_base: Label = _title_bases[index]
	var title_orange: Label = _title_oranges[index]
	var subtitle: Label = _subtitles[index]
	title.text = lines[0] if lines.size() > 0 else ""
	title_base.text = title.text
	title_orange.text = title.text
	subtitle.text = lines[1] if lines.size() > 1 else ""
	subtitle.visible = not subtitle.text.is_empty()
	_fit_label(title, 700.0, 144, 64)

	for label: Label in [title_base, title_orange]:
		label.add_theme_font_size_override("font_size", title.get_theme_font_size("font_size"))
	var title_box_height: float = maxf(
		title.get_combined_minimum_size().y, title_base.get_combined_minimum_size().y
	)
	for label: Label in [title_base, title_orange, title]:
		label.size.y = title_box_height
		label.position.y = TITLE_CENTER_Y[index] - title_box_height * 0.5

	title_base.position.y += TITLE_BASE_OFFSET_Y
	title_orange.position.y += TITLE_ORANGE_OFFSET_Y
	_apply_title_inner(index, title, title_box_height)
	_apply_shadow_layer(_title_base_shadows[index], title_base, TITLE_SHADOW_OFFSET_Y)
	_fit_label(subtitle, 700.0, 79, 40)
	subtitle.position.y = SUBTITLE_CENTER_Y[index] - subtitle.get_combined_minimum_size().y * 0.5
	_apply_shadow_layer(_subtitle_shadows[index], subtitle, SUBTITLE_SHADOW_OFFSET_Y)




func _apply_shadow_layer(shadow: Label, source: Label, offset_y: float) -> void :
	shadow.text = source.text
	shadow.visible = source.visible
	shadow.add_theme_font_size_override("font_size", source.get_theme_font_size("font_size"))
	shadow.size = source.size
	shadow.position = Vector2(source.position.x, source.position.y + offset_y)



func _apply_title_inner(index: int, title: Label, box_height: float) -> void :
	var inner: Control = _title_inners[index]
	inner.position = Vector2(title.position.x, title.position.y)
	inner.size = Vector2(title.size.x, box_height)
	var viewport: SubViewport = _inner_viewports[index]
	viewport.size = Vector2i(roundi(inner.size.x), roundi(inner.size.y))
	var glyph: Label = _inner_glyphs[index]
	glyph.text = title.text
	glyph.add_theme_font_size_override("font_size", title.get_theme_font_size("font_size"))
	glyph.size = inner.size
	glyph.position = Vector2.ZERO
	var layer: TextureRect = _inner_layers[index]
	layer.size = inner.size
	layer.position = Vector2.ZERO
	var mat: ShaderMaterial = layer.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("tex_size", inner.size)
		mat.set_shader_parameter("shadow_color", Color(1, 1, 1, 0.61))



func _fit_label(label: Label, max_width: float, max_size: int, min_size: int) -> void :
	var font: Font = label.get_theme_font("font")
	if font == null:
		return
	var font_size: int = max_size
	while font_size > min_size:
		var width: float = font.get_string_size(
			label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size
		).x
		if width <= max_width:
			break
		font_size -= 2
	label.add_theme_font_size_override("font_size", font_size)



func _sync_text_gradients() -> void :
	var viewport_h: float = maxf(get_viewport_rect().size.y, 1.0)
	var index: int = _tier - 1
	_apply_gradient_uv(_titles[index], viewport_h, TITLE_INK_HEIGHT)
	_apply_gradient_uv(_subtitles[index], viewport_h, SUBTITLE_INK_HEIGHT)


func _apply_gradient_uv(label: Label, viewport_h: float, ink_height: float) -> void :
	var mat: ShaderMaterial = label.material as ShaderMaterial
	if mat == null:
		return
	var rect: Rect2 = label.get_global_rect()
	var center_y: float = rect.position.y + rect.size.y * 0.5
	mat.set_shader_parameter("ink_top_uv", (center_y - ink_height * 0.5) / viewport_h)
	mat.set_shader_parameter("ink_bottom_uv", (center_y + ink_height * 0.5) / viewport_h)


func _smooth(value: float) -> float:
	var p: float = clampf(value, 0.0, 1.0)
	return p * p * (3.0 - 2.0 * p)


func _keys(t: float, times: Array[float], values: Array[float]) -> float:
	if t <= float(times[0]):
		return float(values[0])
	for i: int in range(1, times.size()):
		if t <= float(times[i]):
			return lerpf(
				float(values[i - 1]), 
				float(values[i]), 
				_smooth((t - float(times[i - 1])) / (float(times[i]) - float(times[i - 1])))
			)
	return float(values[-1])


func _exit_tree() -> void :
	_playing = false
	if is_instance_valid(_spine):
		_reset_spine()
	if _landed_sound:
		AudioManager.stop_sfx(&"streak_celebration")
