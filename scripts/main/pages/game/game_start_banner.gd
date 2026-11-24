class_name GameStartBanner
extends Control

enum HardStyle{ORIGINAL, NEW, FLOWER_CHARACTER}

@export var super_title_curve: Curve
@export var super_title_outline_material: ShaderMaterial
@export var flower_title_curve: Curve
@export var flower_super_title_curve: Curve
@export var flower_title_outline_material: ShaderMaterial
@export var flower_super_title_outline_material: ShaderMaterial





const HOLD_DURATION: float = 1.8
const TIMED_HOLD_DURATION: float = 1.1
const TIMED_OUT_DURATION: float = 0.22
const TIMED_BG_DURATION: float = 0.18
const TIMED_CLOCK_CAPTURE_ORIGIN: Vector2 = Vector2(402.0, 12.0)
const OUT_DURATION: float = 0.28

const TEXT_FADE_IN_DURATION: float = 0.25
const TIMED_PANEL_SIZE: Vector2 = Vector2(1000.0, 700.0)
const TIMED_DESIGN_SIZE: Vector2 = Vector2(824.0, 564.0)
const TIMED_TITLE_RECT: Rect2 = Rect2(147.5, 162.0, 527.0, 64.0)
const TIMED_BODY_RECT: Rect2 = Rect2(94.0, 313.0, 634.0, 190.0)
const TIMED_TITLE_KEY: StringName = &"TIMED_CHALLENGE_TITLE"
const TIMED_BODY_KEY: StringName = &"TIMED_CHALLENGE_BANNER_DESCRIPTION"
const SPINE_APPEAR_ANIM: String = "appear"
const SPINE_IDLE_ANIM: String = "idle"



const SPINE_ORIGIN_OFFSET_Y: float = -82.5

const SPINE_DESIGN_WIDTH: float = 1316.0
const HARD_TITLE_FONT_SIZE_MAX: int = 88
const HARD_TITLE_FONT_SIZE_MIN: int = 44
const HARD_TITLE_TEXT_MAX_WIDTH: float = 640.0
const HARD_SUBTITLE_FONT_SIZE_MAX: int = 56
const HARD_SUBTITLE_FONT_SIZE_MIN: int = 38
const HARD_SUBTITLE_LINE_HEIGHT_RATIO: float = 1.2

const NEW_TITLE_FONT_SIZE_MIN: int = 18
const NEW_SUBTITLE_FONT_SIZE_MIN: int = 18

const NEW_SPINE_SCALE: float = 1.1
const NEW_SHRINK_START_TIME: float = 96.0 / 30.0
const NEW_SHRINK_END_TIME: float = 105.0 / 30.0

const FIGMA_TITLE_FONT_SIZE_MAX: int = 80
const FIGMA_TITLE_INK_SIZE: = Vector2(198.766572, 51.983695)
const FIGMA_TITLE_REFERENCE_SIZE: = Vector2(210.0, 66.0)
const FIGMA_TITLE_REFERENCE_INK_CENTER: = Vector2(-0.020674027, -2.6191581435)
const FIGMA_TITLE_LAYOUT_WIDTH: float = 204.2

const FIGMA_TITLE_BASELINE_ORIGIN: = Vector2(1.8972316523, 56.0873626405)
const FIGMA_TITLE_GRADIENT_START: = Vector2(84.3457, -4.57438)
const FIGMA_TITLE_GRADIENT_END: = Vector2(84.3457, 65.9256)
const FIGMA_TITLE_SHADOW_OFFSET: = Vector2(0.0, 3.12848)
const FIGMA_BODY_FONT_SIZE: int = 50
const FIGMA_PERCENT_FONT_SIZE: int = 60
const FIGMA_SPACE_FONT_SIZE: int = 46
const FIGMA_BODY_SIZE: = Vector2(590.0, 169.0)

const FIGMA_BODY_LINE_COUNT: int = 3

const FIGMA_BODY_CENTER: = Vector2(0.9054545455, 13.2381818182)

const SUPER_TITLE_REFERENCE_SIZE: = Vector2(465.0, 73.0)
const SUPER_TITLE_INK_SIZE: = Vector2(453.4623862744, 59.0272692684)
const SUPER_TITLE_INK_CENTER: = Vector2(-0.1731180576, -2.597364233)
const SUPER_TITLE_LAYOUT_WIDTH: float = 454.8
const SUPER_TITLE_BASELINE_ORIGIN: = Vector2(4.9267005243, 63.8708847709)
const SUPER_TITLE_GRADIENT_START: = Vector2(645.448, 93.3379)
const SUPER_TITLE_GRADIENT_END: = Vector2(648.711, 17.2924)
const SUPER_TITLE_AMPLITUDE: float = 9.7315573174

const SUPER_BODY_CENTER: = Vector2(1.36, 9.8290909091)

const FLOWER_APPEAR_ANIM: String = "apear"
const FLOWER_SHRINK_START_TIME: float = 81.0 / 30.0
const FLOWER_TITLE_FONT_SIZE: int = 95
const FLOWER_TITLE_REFERENCE_SIZE: = Vector2(255.0, 82.0)
const FLOWER_TITLE_INK_SIZE: = Vector2(236.6212452876, 62.005070836)
const FLOWER_TITLE_INK_CENTER: = Vector2(-0.4427373562, -2.3974709809)
const FLOWER_TITLE_LAYOUT_WIDTH: float = 242.4875
const FLOWER_TITLE_BASELINE_ORIGIN: = Vector2(4.744087655, 69.5574256461)
const FLOWER_TITLE_AMPLITUDE: float = 2.845121336
const FLOWER_TITLE_GRADIENT_START: = Vector2(126.825, -8.49858)
const FLOWER_TITLE_GRADIENT_END: = Vector2(126.825, 80.1044)
const FLOWER_SUPER_TITLE_REFERENCE_SIZE: = Vector2(558.0, 93.0)
const FLOWER_SUPER_TITLE_INK_SIZE: = Vector2(539.7569180903, 72.7092904107)
const FLOWER_SUPER_TITLE_INK_CENTER: = Vector2(-0.375843724, -2.5453728169)
const FLOWER_SUPER_TITLE_LAYOUT_WIDTH: float = 540.075
const FLOWER_SUPER_TITLE_BASELINE_ORIGIN: = Vector2(8.7191323151, 81.1791384168)
const FLOWER_SUPER_TITLE_AMPLITUDE: float = 14.495886451
const FLOWER_SUPER_TITLE_GRADIENT_START: = Vector2(278.912, 145.449)
const FLOWER_SUPER_TITLE_GRADIENT_END: = Vector2(278.912, -93.4764)
const FLOWER_TITLE_OUTLINE_RADIUS: float = 7.6
const FLOWER_TITLE_SHADOW_OFFSET: = Vector2(0.0, 2.97206)
const FLOWER_BODY_FONT_SIZE: int = 57
const FLOWER_BODY_SIZE: = Vector2(712.5, 204.0)

const FLOWER_BODY_CENTER: = Vector2(0.0, 0.3)

const FLOWER_HARD_ORIGIN_OFFSET_Y: float = 1.0
const EARLY_CHAPTER_MAX: int = 2
const EARLY_PERCENT_RANGE: = Vector2(40.0, 60.0)
const LATE_PASS_PERCENT_RANGE: = Vector2(15.0, 40.0)
const LATE_FAIL_PERCENT_RANGE: = Vector2(60.0, 85.0)
const HARD_BODY_KEYS: PackedStringArray = [
	"GAME_HARD_BANNER_PASS_CHALLENGE", 
	"GAME_HARD_BANNER_FAIL_TRY", 
	"GAME_HARD_BANNER_LEGENDS", 
	"GAME_HARD_BANNER_FINISH", 
]

@onready var _anim: Control = $Root / Anim
@onready var _hard: Control = $Root / Anim / Hard
@onready var _hard_title: Label = $Root / Anim / Hard / Title
@onready var _hard_subtitle: RichTextLabel = $Root / Anim / Hard / Subtitle
@onready var _hard_spine: SpineSprite = $Root / Anim / Hard / Spine
@onready var _super_hard: Control = $Root / Anim / SuperHard
@onready var _super_hard_spine: SpineSprite = $Root / Anim / SuperHard / Spine
@onready var _super_hard_title: Label = $Root / Anim / SuperHard / Title
@onready var _super_hard_subtitle: RichTextLabel = $Root / Anim / SuperHard / Subtitle
@onready var _new_hard: Control = $Root / Anim / NewHard
@onready var _new_hard_spine: SpineSprite = $Root / Anim / NewHard / Spine
@onready var _new_hard_subtitle: RichTextLabel = $Root / Anim / NewHard / Spine / SubtitleSlot / Subtitle
@onready var _figma_title: Control = $Root / Anim / NewHard / Spine / TitleSlot / FigmaTitle
@onready var _figma_title_face: CurveLabel = $Root / Anim / NewHard / Spine / TitleSlot / FigmaTitle / Face
@onready var _figma_title_outline: CurveLabel = $Root / Anim / NewHard / Spine / TitleSlot / FigmaTitle / Outline
@onready var _figma_title_shadow: CurveLabel = $TitleShadowViewport / Shadow
@onready var _figma_shadow_viewport: SubViewport = $TitleShadowViewport
@onready var _figma_shadow_display: TextureRect = $Root / Anim / NewHard / Spine / TitleSlot / FigmaTitle / Shadow
@onready var _hard_title_curve: Curve = _figma_title_face.curve
@onready var _hard_title_outline_material: ShaderMaterial = _figma_title_outline.material as ShaderMaterial
@onready var _new_figma_title: Control = _figma_title
@onready var _new_figma_title_face: CurveLabel = _figma_title_face
@onready var _new_figma_title_outline: CurveLabel = _figma_title_outline
@onready var _new_figma_shadow_display: TextureRect = _figma_shadow_display
@onready var _flower_hard: Control = $Root / Anim / FlowerHard
@onready var _flower_hard_spine: SpineSprite = $Root / Anim / FlowerHard / Spine
@onready var _flower_hard_subtitle: RichTextLabel = $Root / Anim / FlowerHard / Spine / SubtitleSlot / Subtitle
@onready var _flower_figma_title: Control = $Root / Anim / FlowerHard / Spine / TitleSlot / FigmaTitle
@onready var _flower_figma_title_face: CurveLabel = $Root / Anim / FlowerHard / Spine / TitleSlot / FigmaTitle / Face
@onready var _flower_figma_title_outline: CurveLabel = $Root / Anim / FlowerHard / Spine / TitleSlot / FigmaTitle / Outline
@onready var _flower_figma_shadow_display: TextureRect = $Root / Anim / FlowerHard / Spine / TitleSlot / FigmaTitle / Shadow
@onready var _streak: StreakCelebration = $Root / Streak
@onready var _tier_streak: StreakTierBanner = $Root / StreakTier
@onready var _timed: Control = $Root / Timed
@onready var _timed_panel: Control = $Root / Timed / Panel
@onready var _timed_composite: CanvasGroup = $Root / Timed / Panel / Composite
@onready var _timed_clock_viewport: SubViewport = $TimedClockViewport
@onready var _timed_capture_clock: TimedChallengeClock = $TimedClockViewport / ClockRig
@onready var _timed_design: Control = $Root / Timed / Panel / Composite / Design
@onready var _timed_title: Label = $Root / Timed / Panel / Composite / Design / RibbonText / Title
@onready var _timed_outline: Label = $Root / Timed / Panel / Composite / Design / RibbonText / TitleOutline
@onready var _timed_body: Label = $Root / Timed / Panel / Composite / Design / Body
@onready var _timed_shadow: TextureRect = $Root / Timed / Panel / Composite / Design / RibbonText / TitleShadow
@onready var _timed_shadow_viewport: SubViewport = $TimedShadowViewport
@onready var _timed_shadow_mask: Label = $TimedShadowViewport / Mask
@onready var _timed_clock: TimedChallengeClock = $Root / Timed / Panel / Composite / Design / ClockRig


var _title: Label = null
var _subtitle: RichTextLabel = null
var _spine: SpineSprite = null
var _tween: Tween = null
var _generation: int = 0
var _timed_motion: PopupMotion = PopupMotion.new()
var _timed_carrier: TimedClockFlight = null
var _timed_bg_tween: Tween = null
var _timed_capture_enabled: bool = false
var _timed_capture_bones: Array[Bone2D] = []
var _timed_capture_targets: Array[Bone2D] = []
var _figma_hard_style: bool = false
var _figma_body_source: String = ""
var _figma_percent_text: String = ""
var _title_reference_size: Vector2 = FIGMA_TITLE_REFERENCE_SIZE
var _title_ink_size: Vector2 = FIGMA_TITLE_INK_SIZE
var _title_reference_center: Vector2 = FIGMA_TITLE_REFERENCE_INK_CENTER
var _title_layout_width: float = FIGMA_TITLE_LAYOUT_WIDTH
var _title_baseline_origin: Vector2 = FIGMA_TITLE_BASELINE_ORIGIN
var _title_gradient_start: Vector2 = FIGMA_TITLE_GRADIENT_START
var _title_gradient_end: Vector2 = FIGMA_TITLE_GRADIENT_END
var _title_source_text: String = "HARD"
var _title_font_size_max: int = FIGMA_TITLE_FONT_SIZE_MAX
var _title_shadow_offset: Vector2 = FIGMA_TITLE_SHADOW_OFFSET
var _title_slot_origin: Vector2 = Vector2.ZERO
var _title_gradient_offset: Vector2 = Vector2.ZERO
var _body_font_size: int = FIGMA_BODY_FONT_SIZE
var _percent_font_size: int = FIGMA_PERCENT_FONT_SIZE
var _space_font_size: int = FIGMA_SPACE_FONT_SIZE
var _flower_origin_offset_y: float = 0.0


func _ready() -> void :
	visible = false
	_hard_spine.visible = false
	_super_hard_spine.visible = false
	_new_hard_spine.visible = false
	_flower_hard_spine.visible = false
	_figma_shadow_display.texture = _figma_shadow_viewport.get_texture()
	_flower_figma_shadow_display.texture = _figma_shadow_viewport.get_texture()
	_tier_streak.hide_now()
	_timed_shadow.texture = _timed_shadow_viewport.get_texture()
	resized.connect(_layout_timed)
	_timed_clock.bind_ribbon_text($Root / Timed / Panel / Composite / Design / RibbonText)
	_prepare_timed_clock_capture()
	if not RenderingServer.frame_pre_draw.is_connected(_sync_timed_clock_capture):
		RenderingServer.frame_pre_draw.connect(_sync_timed_clock_capture)



func show_hard(chapter_index: int, super_hard: bool = false, style: HardStyle = HardStyle.ORIGINAL) -> void :
	hide_now()
	var new_style: bool = style == HardStyle.NEW
	var flower_style: bool = style == HardStyle.FLOWER_CHARACTER
	_figma_hard_style = new_style or flower_style
	_figma_title = _flower_figma_title if flower_style else _new_figma_title
	_figma_title_face = _flower_figma_title_face if flower_style else _new_figma_title_face
	_figma_title_outline = _flower_figma_title_outline if flower_style else _new_figma_title_outline
	_figma_shadow_display = _flower_figma_shadow_display if flower_style else _new_figma_shadow_display
	_title = _figma_title_face if _figma_hard_style else (_super_hard_title if super_hard else _hard_title)
	_subtitle = _flower_hard_subtitle if flower_style else\
	(_new_hard_subtitle if new_style else (_super_hard_subtitle if super_hard else _hard_subtitle))
	_spine = _flower_hard_spine if flower_style else\
	(_new_hard_spine if new_style else (_super_hard_spine if super_hard else _hard_spine))
	if _figma_hard_style:
		_figma_title.visible = _figma_hard_style
		_title_reference_size = SUPER_TITLE_REFERENCE_SIZE if super_hard else FIGMA_TITLE_REFERENCE_SIZE
		_title_ink_size = SUPER_TITLE_INK_SIZE if super_hard else FIGMA_TITLE_INK_SIZE
		_title_reference_center = SUPER_TITLE_INK_CENTER if super_hard else FIGMA_TITLE_REFERENCE_INK_CENTER
		_title_layout_width = SUPER_TITLE_LAYOUT_WIDTH if super_hard else FIGMA_TITLE_LAYOUT_WIDTH
		_title_baseline_origin = SUPER_TITLE_BASELINE_ORIGIN if super_hard else FIGMA_TITLE_BASELINE_ORIGIN
		_title_gradient_start = SUPER_TITLE_GRADIENT_START if super_hard else FIGMA_TITLE_GRADIENT_START
		_title_gradient_end = SUPER_TITLE_GRADIENT_END if super_hard else FIGMA_TITLE_GRADIENT_END
		_title_source_text = "SUPER HARD" if super_hard else "HARD"
		var curve: Curve = super_title_curve if super_hard else _hard_title_curve
		var amplitude: float = SUPER_TITLE_AMPLITUDE if super_hard else 1.8858744831
		var outline_radius: float = 4.389
		var outline_material: ShaderMaterial = super_title_outline_material if super_hard else _hard_title_outline_material
		_title_font_size_max = FIGMA_TITLE_FONT_SIZE_MAX
		_title_shadow_offset = FIGMA_TITLE_SHADOW_OFFSET
		_title_slot_origin = Vector2.ZERO
		_body_font_size = FIGMA_BODY_FONT_SIZE
		_percent_font_size = FIGMA_PERCENT_FONT_SIZE
		_space_font_size = FIGMA_SPACE_FONT_SIZE
		var body_size: Vector2 = FIGMA_BODY_SIZE
		var body_center: Vector2 = SUPER_BODY_CENTER if super_hard else FIGMA_BODY_CENTER
		if flower_style:
			_title_reference_size = FLOWER_SUPER_TITLE_REFERENCE_SIZE if super_hard else FLOWER_TITLE_REFERENCE_SIZE
			_title_ink_size = FLOWER_SUPER_TITLE_INK_SIZE if super_hard else FLOWER_TITLE_INK_SIZE
			_title_reference_center = FLOWER_SUPER_TITLE_INK_CENTER if super_hard else FLOWER_TITLE_INK_CENTER
			_title_layout_width = FLOWER_SUPER_TITLE_LAYOUT_WIDTH if super_hard else FLOWER_TITLE_LAYOUT_WIDTH
			_title_baseline_origin = FLOWER_SUPER_TITLE_BASELINE_ORIGIN if super_hard else FLOWER_TITLE_BASELINE_ORIGIN
			_title_gradient_start = FLOWER_SUPER_TITLE_GRADIENT_START if super_hard else FLOWER_TITLE_GRADIENT_START
			_title_gradient_end = FLOWER_SUPER_TITLE_GRADIENT_END if super_hard else FLOWER_TITLE_GRADIENT_END
			_title_font_size_max = FLOWER_TITLE_FONT_SIZE
			_title_shadow_offset = FLOWER_TITLE_SHADOW_OFFSET
			_title_slot_origin = Vector2.ZERO
			curve = flower_super_title_curve if super_hard else flower_title_curve
			amplitude = FLOWER_SUPER_TITLE_AMPLITUDE if super_hard else FLOWER_TITLE_AMPLITUDE
			outline_radius = FLOWER_TITLE_OUTLINE_RADIUS
			outline_material = flower_super_title_outline_material if super_hard else flower_title_outline_material
			_body_font_size = FLOWER_BODY_FONT_SIZE
			_percent_font_size = FLOWER_BODY_FONT_SIZE
			_space_font_size = FLOWER_BODY_FONT_SIZE
			body_size = FLOWER_BODY_SIZE
			body_center = FLOWER_BODY_CENTER
			_flower_origin_offset_y = 0.0 if super_hard else FLOWER_HARD_ORIGIN_OFFSET_Y
		for label: CurveLabel in [_figma_title_face, _figma_title_outline, _figma_title_shadow]:
			label.curve = curve
			label.amplitude = amplitude
		_figma_title_outline.outline_stamp_radius = outline_radius
		_figma_title_shadow.outline_stamp_radius = outline_radius
		_figma_title_outline.material = outline_material
		_figma_shadow_viewport.size = Vector2i(_title_reference_size)
		_figma_shadow_display.size = _title_reference_size
		_subtitle.size = body_size
		_subtitle.position = - body_size * 0.5 + body_center
		_spine.get_skeleton().set_skin_by_name("super_hard" if super_hard else "hard")
	var generation: int = _generation
	var body_index: int = 0 if _figma_hard_style else randi_range(0, HARD_BODY_KEYS.size() - 1)
	var percent_range: Vector2 = _hard_percent_range(chapter_index, body_index)
	var percent_value: float = randf_range(percent_range.x, percent_range.y)
	var percent_text: String = "%.2f%%" % percent_value

	_title.text = tr("GAME_SUPER_HARD_BANNER_TITLE") if super_hard else tr("HOME_HARD_BADGE")
	if _figma_hard_style:
		_title.text = _title.text.to_upper()
		_fit_figma_hard_title()
	else:
		_fit_hard_title_font_size()
	var subtitle: String
	if _figma_hard_style:
		var percent: int = int(percent_value)
		_figma_percent_text = "%d%%" % percent
		subtitle = tr("GAME_HARD_BANNER_BODY") % percent
	else:
		subtitle = tr(HARD_BODY_KEYS[body_index]) % percent_text
	var escaped_subtitle: String = subtitle.replace("[", "[lb]")
	if _figma_hard_style:
		_figma_body_source = escaped_subtitle
	else:
		_subtitle.text = "[center]%s[/center]" % escaped_subtitle.replace(
			percent_text, 
			"[color=#EF6400]%s[/color]" % percent_text
		)
	await _fit_hard_subtitle_font_size(generation, _figma_hard_style)
	if generation != _generation:
		return
	if _figma_hard_style:

		_figma_shadow_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		if DisplayServer.get_name() == "headless":
			await get_tree().process_frame
		else:
			await RenderingServer.frame_post_draw
		if generation != _generation:
			return
		_figma_shadow_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_hard.visible = not _figma_hard_style and not super_hard
	_super_hard.visible = not _figma_hard_style and super_hard
	_new_hard.visible = new_style
	_flower_hard.visible = flower_style
	_streak.visible = false
	match style:
		HardStyle.NEW:
			await _play_new_hard()
		HardStyle.FLOWER_CHARACTER:
			await _play_flower_character_hard()
		_:
			await _play_hard()


func _play_new_hard() -> void :
	await _play_experiment_hard(_new_hard_spine, SPINE_APPEAR_ANIM, NEW_SPINE_SCALE, 0.0)


func _play_flower_character_hard() -> void :
	if not RenderingServer.frame_pre_draw.is_connected(_sync_flower_before_draw):
		RenderingServer.frame_pre_draw.connect(_sync_flower_before_draw)
	await _play_experiment_hard(_flower_hard_spine, FLOWER_APPEAR_ANIM, 1.0, _flower_origin_offset_y)



func _sync_flower_before_draw() -> void :
	if not visible or _spine != _flower_hard_spine:
		return
	_anim.position.y = _centered_y()
	_flower_hard_spine.position = _anim.size * 0.5 + Vector2(0.0, _flower_origin_offset_y)
	_sync_figma_title_gradient()


func _play_experiment_hard(sprite: SpineSprite, animation: String, scale_factor: float, origin_offset_y: float) -> void :
	_kill_tween()
	var generation: int = _generation
	_anim.position.y = _centered_y()
	_anim.modulate.a = 1.0
	sprite.position = _anim.size * 0.5 + Vector2(0.0, origin_offset_y)
	sprite.scale = Vector2.ONE * scale_factor
	var skeleton: SpineSkeleton = sprite.get_skeleton()
	var state: SpineAnimationState = sprite.get_animation_state()
	state.clear_tracks()
	skeleton.set_to_setup_pose()
	state.set_animation(animation, false, 0)
	state.update(0.0)
	state.apply(skeleton)

	visible = true
	sprite.visible = true
	sprite.update_skeleton(0.0)
	_tween = create_tween()
	if sprite == _new_hard_spine:
		_tween.tween_interval(NEW_SHRINK_START_TIME)
		_tween.tween_property(_anim, "modulate:a", 0.0, NEW_SHRINK_END_TIME - NEW_SHRINK_START_TIME)
	else:
		var appear_duration: float = skeleton.get_data().find_animation(animation).get_duration()
		_tween.tween_interval(FLOWER_SHRINK_START_TIME)
		_tween.tween_property(_anim, "modulate:a", 0.0, appear_duration - FLOWER_SHRINK_START_TIME)
	await _finish_tween(generation, _anim.position.y)



func _on_new_spine_world_transforms_changed(sprite: SpineSprite) -> void :
	if not is_node_ready() or _spine != sprite:
		return
	var skeleton: SpineSkeleton = sprite.get_skeleton()
	var title_slot: SpineSlot = skeleton.find_slot("text01")
	var subtitle_slot: SpineSlot = skeleton.find_slot("text02")
	title_slot.set_attachment(null)
	subtitle_slot.set_attachment(null)
	_figma_title.modulate = title_slot.get_color()
	_subtitle.modulate = subtitle_slot.get_color()
	if _figma_hard_style:
		_sync_figma_title_gradient()


func _on_flower_spine_world_transforms_changed(sprite: SpineSprite) -> void :
	if not is_node_ready() or _spine != sprite:
		return
	var skeleton: SpineSkeleton = sprite.get_skeleton()
	var title_slot: SpineSlot = skeleton.find_slot("title")
	var subtitle_slot: SpineSlot = skeleton.find_slot("body")
	title_slot.set_attachment(null)
	subtitle_slot.set_attachment(null)
	_figma_title.modulate = title_slot.get_color()
	_subtitle.modulate = subtitle_slot.get_color()


func _hard_percent_range(chapter_index: int, body_index: int) -> Vector2:
	if chapter_index >= 1 and chapter_index <= EARLY_CHAPTER_MAX:
		return EARLY_PERCENT_RANGE
	if body_index == 0 or body_index == 3:
		return LATE_PASS_PERCENT_RANGE
	return LATE_FAIL_PERCENT_RANGE


func _fit_hard_title_font_size() -> void :
	var font: Font = _title.get_theme_font("font")
	if font == null:
		return
	var font_size: int = HARD_TITLE_FONT_SIZE_MAX
	var minimum_size: int = HARD_TITLE_FONT_SIZE_MIN
	var maximum_width: float = HARD_TITLE_TEXT_MAX_WIDTH
	while font_size > minimum_size:
		var text_width: float = font.get_string_size(
			_title.text, 
			HORIZONTAL_ALIGNMENT_LEFT, 
			-1.0, 
			font_size
		).x
		if text_width <= maximum_width:
			break
		font_size -= 2
	_title.add_theme_font_size_override("font_size", font_size)



func _fit_figma_hard_title() -> void :
	var font: Font = _title.get_theme_font("font")
	for label: CurveLabel in [_figma_title_shadow, _figma_title_outline, _figma_title_face]:
		label.text = _title.text
		label.language = TranslationServer.get_locale()
	var lower: int = NEW_TITLE_FONT_SIZE_MIN
	var upper: int = _title_font_size_max
	var font_size: int = lower

	while _title.text != _title_source_text and lower <= upper:
		var candidate: int = (lower + upper) / 2
		var metrics: Dictionary = _title_glyph_metrics(font, candidate)
		var ink: Rect2 = metrics["ink"]
		if ink.size.x <= _title_ink_size.x and ink.size.y <= _title_ink_size.y\
		and float(metrics["advance"]) <= _title_layout_width:
			font_size = candidate
			lower = candidate + 1
		else:
			upper = candidate - 1
	if _title.text == _title_source_text:
		font_size = _title_font_size_max
	var final_metrics: Dictionary = _title_glyph_metrics(font, font_size)
	var text_size: Vector2 = final_metrics["size"]
	var face_position: = Vector2(_title_baseline_origin.x - _title_reference_size.x * 0.5, 
		_title_baseline_origin.y - _title_reference_size.y * 0.5 - text_size.y * 0.5)
	var correction: = Vector2.ZERO
	var flower_title: bool = _spine == _flower_hard_spine
	_title_gradient_offset = Vector2.ZERO
	if _title.text != _title_source_text or flower_title:
		var ink: Rect2 = final_metrics["ink"]
		var actual_center: Vector2 = face_position + ink.get_center()

		correction = (Vector2.ZERO if flower_title else _title_reference_center) - actual_center
		if flower_title:

			_title_gradient_offset = actual_center - _title_reference_center

	_figma_title.position = _title_slot_origin + correction.rotated(_figma_title.rotation)
	for label: CurveLabel in [_figma_title_shadow, _figma_title_outline, _figma_title_face]:
		label.add_theme_font_size_override("font_size", font_size)
		label.size = text_size
		label.position = face_position
	_figma_title_shadow.position += _title_reference_size * 0.5
	_figma_shadow_display.position = - _title_reference_size * 0.5 + _title_shadow_offset



func _sync_figma_title_gradient() -> void :
	var outline_material: ShaderMaterial = _figma_title_outline.material as ShaderMaterial
	var transform: Transform2D = _figma_title.get_global_transform_with_canvas()
	var viewport_size: Vector2 = _figma_title_outline.get_viewport_rect().size
	outline_material.set_shader_parameter("screen_start", 
		(transform * (_title_gradient_start - _title_reference_size * 0.5 + _title_gradient_offset)) / viewport_size)
	outline_material.set_shader_parameter("screen_end", 
		(transform * (_title_gradient_end - _title_reference_size * 0.5 + _title_gradient_offset)) / viewport_size)


func _title_glyph_metrics(font: Font, font_size: int) -> Dictionary:
	var line: = TextLine.new()
	line.add_string(_title.text, font, font_size, TranslationServer.get_locale())
	var ts: TextServer = TextServerManager.get_primary_interface()
	var line_size: Vector2 = line.get_size()
	var text_size: = Vector2(_title_layout_width, line_size.y)

	for label: CurveLabel in [_figma_title_shadow, _figma_title_outline, _figma_title_face]:
		label.add_theme_font_size_override("font_size", font_size)
		var minimum: Vector2 = label.get_minimum_size()
		text_size.y = maxf(text_size.y, minimum.y)
	var curve: Curve = _figma_title_face.curve
	var amplitude: float = _figma_title_face.amplitude
	var ink: Rect2
	var advance: float = (_title_layout_width - line_size.x) * 0.5
	for glyph: Dictionary in ts.shaped_text_get_glyphs(line.get_rid()):
		var key: = Vector2i(int(glyph.font_size), 0)
		var font_rid: RID = glyph.font_rid
		var index: int = glyph.index
		ts.font_render_glyph(font_rid, key, index)
		for _repeat: int in int(glyph.repeat):
			var glyph_offset: Vector2 = glyph["offset"]
			var width: float = glyph.advance
			var x: float = advance + width * 0.5
			var t: float = clampf(x / text_size.x, 0.0, 1.0)
			var y: float = text_size.y * 0.5 - (curve.sample(t) - 0.5) * amplitude * 2.0
			var t0: float = clampf(t - 0.01, 0.0, 1.0)
			var t1: float = clampf(t + 0.01, 0.0, 1.0)
			var tangent: = Vector2(text_size.x * (t1 - t0), - (curve.sample(t1) - curve.sample(t0)) * amplitude * 2.0)
			var local_bounds: = Rect2(ts.font_get_glyph_offset(font_rid, key, index) - Vector2(width * 0.5, 0.0), 
				ts.font_get_glyph_size(font_rid, key, index))
			var bounds: Rect2 = Transform2D(tangent.angle(), Vector2(x, y) + glyph_offset) * local_bounds
			if bounds.has_area():
				ink = ink.merge(bounds) if ink.has_area() else bounds
			advance += glyph.advance
	return {"ink": ink, "size": text_size, "advance": line_size.x}


func _fit_hard_subtitle_font_size(generation: int, new_style: bool = false) -> void :
	var design_center: Vector2 = _subtitle.position + _subtitle.size * 0.5
	var font_size: int = HARD_SUBTITLE_FONT_SIZE_MAX
	if _figma_hard_style:
		font_size = _body_font_size
	var minimum_size: int = NEW_SUBTITLE_FONT_SIZE_MIN if new_style else HARD_SUBTITLE_FONT_SIZE_MIN
	_set_hard_subtitle_font_size(font_size)
	await get_tree().process_frame
	while font_size > minimum_size:
		if generation != _generation:
			return
		var content_height: float = _subtitle.get_content_height()
		var fits_design_lines: bool = _figma_hard_style and _subtitle.get_line_count() <= FIGMA_BODY_LINE_COUNT
		if content_height <= 0.0 or content_height <= _subtitle.size.y or fits_design_lines:
			break
		font_size -= 2
		_set_hard_subtitle_font_size(font_size)
		await get_tree().process_frame
	if _figma_hard_style and generation == _generation:

		_subtitle.size.y = maxf(_subtitle.size.y, _subtitle.get_content_height())
		_subtitle.position.y = design_center.y - _subtitle.size.y * 0.5


func _set_hard_subtitle_font_size(font_size: int) -> void :
	_subtitle.add_theme_font_size_override("normal_font_size", font_size)
	var line_separation: int
	if _figma_hard_style:
		var font: Font = _subtitle.get_theme_font("normal_font")
		var percent_size: int = roundi(_percent_font_size * float(font_size) / _body_font_size)
		var space_size: int = roundi(_space_font_size * float(font_size) / _body_font_size)
		var emphasized: String = "[font_size=%d][color=#EF6400]%s[/color][/font_size]"\
		%[percent_size, _figma_percent_text]

		var body: String = _figma_body_source.replace(" ", "[font_size=%d] [/font_size]" % space_size)
		_subtitle.text = "[center]%s[/center]" % body.replace(_figma_percent_text, emphasized)

		var line: = TextLine.new()
		line.add_string(_subtitle.get_parsed_text(), font, font_size, TranslationServer.get_locale())
		line_separation = roundi(font_size * HARD_SUBTITLE_LINE_HEIGHT_RATIO - line.get_size().y)
	else:
		line_separation = roundi(font_size * (HARD_SUBTITLE_LINE_HEIGHT_RATIO - 1.0))
	_subtitle.add_theme_constant_override("line_separation", line_separation)



func show_streak(count: int, group: int = 0, on_exit: Callable = Callable(), percentile: float = -1.0, personal_best: bool = false) -> void :
	hide_now()
	var generation: int = _generation
	_hard.visible = false
	_super_hard.visible = false
	visible = true
	if group == 1 or group == 2:
		await _tier_streak.play(count, group == 1, on_exit, percentile, personal_best)
	else:
		await _streak.play(count, on_exit, percentile, personal_best)
	if generation == _generation:
		visible = false


func hide_now() -> void :
	_generation += 1
	if _timed_bg_tween != null and _timed_bg_tween.is_valid():
		_timed_bg_tween.kill()
	_timed_bg_tween = null
	AudioManager.stop_sfx(&"timed_endless_open")
	if is_instance_valid(_timed_carrier):
		_timed_carrier.reset_now()
	_timed_carrier = null
	($Root / Timed / Panel / Composite / Design / Background as CanvasItem).modulate.a = 1.0
	_timed_body.modulate.a = 1.0
	($Root / Timed / Scrim as CanvasItem).modulate.a = 1.0
	_reset_timed_clock_capture()
	_timed_clock.reset_now()
	_timed.hide()
	_timed.modulate.a = 1.0
	_timed_panel.modulate.a = 1.0
	_timed_motion.reset(_timed_panel)
	_timed_shadow_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_anim.show()
	_figma_shadow_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_kill_tween()
	_stop_spines()
	_streak.hide_now()
	_tier_streak.hide_now()
	_anim.position.y = _centered_y()
	_anim.modulate.a = 1.0
	_hard_title.modulate.a = 1.0
	_hard_subtitle.modulate.a = 1.0
	_super_hard_title.modulate.a = 1.0
	_super_hard_subtitle.modulate.a = 1.0
	_new_hard.visible = false
	_new_hard_subtitle.modulate.a = 1.0
	_flower_hard.visible = false
	_flower_hard_subtitle.modulate.a = 1.0
	visible = false



func show_timed_challenge(carrier: TimedClockFlight = null, target: TextureRect = null, 
		active: Callable = Callable(), motion_audio: bool = true) -> bool:
	hide_now()
	_timed_carrier = carrier
	var carry: bool = is_instance_valid(carrier) and is_instance_valid(target)
	if carry and not carrier.prepare_target(target):
		return false
	var generation: int = _generation
	_refresh_timed_text()
	_layout_timed()
	_anim.hide()
	($Root / Timed / Scrim as CanvasItem).modulate.a = 0.0
	_timed.show()
	_timed_bg_tween = create_tween()
	_timed_bg_tween.tween_property($Root / Timed / Scrim, "modulate:a", 1.0, TIMED_BG_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	visible = true
	_timed_clock.play_enter()
	_timed_capture_enabled = carry
	_sync_timed_clock_capture()
	if motion_audio:
		AudioManager.play_sfx(&"timed_endless_open", 0.65)
	if not await _timed_motion.appear(_timed_panel, _timed_composite) or generation != _generation:
		return false
	_tween = create_tween()
	_tween.tween_interval(TIMED_HOLD_DURATION)
	var hold: Tween = _tween
	while generation == _generation and hold.is_valid() and hold.is_running() and ( not active.is_valid() or bool(active.call())):
		await get_tree().process_frame
	if generation != _generation:
		return false
	if active.is_valid() and not bool(active.call()):
		hide_now()
		return false
	_tween = null
	var valid: Callable = func() -> bool:
		return generation == _generation and visible and ( not active.is_valid() or bool(active.call()))

	if not await _timed_motion.disappear_composited(_timed_panel, _timed, 
			_timed_composite, $Root / Timed / Scrim, TIMED_OUT_DURATION, carry, valid):
		if generation == _generation:
			hide_now()
		return false
	if carry:

		_timed_composite.hide()
		_reset_timed_clock_capture()
		if not await carrier.fly_from(_timed_clock, valid):
			return false
		_timed_carrier = null
	_timed_motion.reset(_timed_panel)
	_reset_timed_clock_capture()
	_tween = null
	_timed_clock.reset_now()
	_timed.hide()
	_timed.modulate.a = 1.0
	_timed_shadow_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	visible = false
	return true



func _prepare_timed_clock_capture() -> void :
	var material: ShaderMaterial = _timed_composite.material as ShaderMaterial
	material.set_shader_parameter("retained_clock_texture", _timed_clock_viewport.get_texture())
	var source: Bone2D = _timed_clock.get_node("Stage/Skeleton/Clock")
	var target: Bone2D = _timed_capture_clock.get_node("Stage/Skeleton/Clock")
	_timed_capture_bones.append(source)
	_timed_capture_targets.append(target)
	for child: Node in source.find_children("*", "Bone2D", true, false):
		_timed_capture_bones.append(child as Bone2D)
		_timed_capture_targets.append(target.get_node(source.get_path_to(child)) as Bone2D)


func _sync_timed_clock_capture() -> void :
	if not _timed_capture_enabled or not visible or not _timed_composite.visible:
		return

	for index: int in range(_timed_capture_bones.size()):
		_timed_capture_targets[index].transform = _timed_capture_bones[index].transform
		_timed_capture_targets[index].modulate = _timed_capture_bones[index].modulate
		_timed_capture_targets[index].visible = _timed_capture_bones[index].visible
	_timed_capture_clock.modulate = _timed_clock.modulate
	_timed_capture_clock.show()
	_timed_clock_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var pose: Transform2D = _timed_clock.get_global_transform_with_canvas()
	var begin: Vector2 = pose * TIMED_CLOCK_CAPTURE_ORIGIN
	var end: Vector2 = pose * (TIMED_CLOCK_CAPTURE_ORIGIN + Vector2(_timed_clock_viewport.size))
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var normalized_rect: Vector4 = Vector4(begin.x / viewport_size.x, begin.y / viewport_size.y, 
		(end.x - begin.x) / viewport_size.x, (end.y - begin.y) / viewport_size.y)
	(_timed_composite.material as ShaderMaterial).set_shader_parameter("retained_clock_rect", normalized_rect)


func _reset_timed_clock_capture() -> void :
	_timed_capture_enabled = false
	if is_instance_valid(_timed_clock_viewport):
		_timed_clock_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if is_instance_valid(_timed_capture_clock):
		_timed_capture_clock.reset_now()


func _layout_timed() -> void :
	if not is_node_ready():
		return
	_timed_panel.size = TIMED_PANEL_SIZE
	_timed_panel.position = Vector2(UiMetrics.center_left(TIMED_PANEL_SIZE.x), 
		(UiMetrics.viewport_size().y - TIMED_PANEL_SIZE.y) * 0.5)
	var design_scale: float = TIMED_PANEL_SIZE.x / TIMED_DESIGN_SIZE.x
	_timed_design.scale = Vector2.ONE * design_scale
	_timed_design.position = Vector2(0.0, (TIMED_PANEL_SIZE.y - TIMED_DESIGN_SIZE.y * design_scale) * 0.5)


func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and _timed.visible:
		_refresh_timed_text()


func _refresh_timed_text() -> void :
	_timed_title.text = tr(TIMED_TITLE_KEY)
	_timed_body.text = tr(TIMED_BODY_KEY)
	_fit_timed_label(_timed_title, TIMED_TITLE_RECT, 80, 1, 1.0, 
		float(_timed_outline.get_theme_constant("outline_size")) * 2.0)
	for label: Label in [_timed_outline, _timed_shadow_mask]:
		label.text = _timed_title.text
		label.add_theme_font_size_override("font_size", _timed_title.get_theme_font_size("font_size"))
		label.get_minimum_size()
		label.size = TIMED_TITLE_RECT.size
	_timed_outline.position = TIMED_TITLE_RECT.get_center() - _timed_outline.size * 0.5
	_timed_shadow_mask.position = (Vector2(_timed_shadow_viewport.size) - _timed_shadow_mask.size) * 0.5
	_fit_timed_label(_timed_body, TIMED_BODY_RECT, 54, 24, 1.2)
	_timed_shadow_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE



func _fit_timed_label(label: Label, rect: Rect2, maximum: int, minimum: int, line_ratio: float, 
		horizontal_padding: float = 0.0) -> void :
	var font: FontVariation = label.get_theme_font("font") as FontVariation
	label.clip_text = false
	for font_size: int in range(maximum, minimum - 1, -1):
		var excess: int = maxi(0, roundi(font.base_font.get_height(font_size) - font_size * line_ratio))
		font.spacing_top = - int(excess / 2)
		font.spacing_bottom = - (excess - int(excess / 2))
		label.add_theme_font_size_override("font_size", font_size)
		label.size = rect.size
		var measured: Vector2 = label.get_minimum_size()
		var fits_width: bool = label.autowrap_mode != TextServer.AUTOWRAP_OFF\
		or font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x\
		+ horizontal_padding <= rect.size.x
		if measured.y <= rect.size.y + 1.0 and fits_width:
			break
	label.size = rect.size
	label.position = rect.position
	label.clip_text = true




func _play_hard() -> void :
	_kill_tween()
	var generation: int = _generation
	_anim.position.y = _centered_y()
	_anim.modulate.a = 1.0
	_title.modulate.a = 0.0
	_subtitle.modulate.a = 0.0
	var appear_duration: float = _start_spine()
	visible = true
	_tween = create_tween()
	_tween.tween_interval(appear_duration)
	_tween.tween_property(_title, "modulate:a", 1.0, TEXT_FADE_IN_DURATION)
	_tween.parallel().tween_property(_subtitle, "modulate:a", 1.0, TEXT_FADE_IN_DURATION)
	_tween.tween_interval(HOLD_DURATION)
	_tween.tween_property(_anim, "modulate:a", 0.0, OUT_DURATION)
	await _finish_tween(generation, _anim.position.y)



func _start_spine() -> float:
	var width: float = _anim.size.x
	_spine.position = Vector2(width * 0.5, _anim.size.y * 0.5 + SPINE_ORIGIN_OFFSET_Y)
	_spine.scale = Vector2.ONE * maxf(1.0, width / SPINE_DESIGN_WIDTH)
	var skeleton: SpineSkeleton = _spine.get_skeleton()
	var state: SpineAnimationState = _spine.get_animation_state()

	state.clear_tracks()
	skeleton.set_to_setup_pose()
	state.set_animation(SPINE_APPEAR_ANIM, false, 0)
	state.add_animation(SPINE_IDLE_ANIM, 0.0, true, 0)
	state.update(0.0)
	state.apply(skeleton)
	skeleton.update_world_transform(SpineConstant.Physics_Update)
	_spine.visible = true
	return skeleton.get_data().find_animation(SPINE_APPEAR_ANIM).get_duration()



func _stop_spines() -> void :
	for spine: SpineSprite in [_hard_spine, _super_hard_spine, _new_hard_spine, _flower_hard_spine]:
		spine.get_animation_state().clear_tracks()
		spine.visible = false



func _finish_tween(generation: int, target_y: float) -> void :
	var tw: Tween = _tween
	while generation == _generation and tw.is_valid() and tw.is_running():
		await get_tree().process_frame
	if generation != _generation or _tween != tw:
		return
	_tween = null
	_stop_spines()
	_anim.position.y = target_y
	visible = false


func _centered_y() -> float:
	var parent_control: = _anim.get_parent() as Control
	if parent_control == null:
		return _anim.position.y
	return (parent_control.size.y - _anim.size.y) * 0.5


func _kill_tween() -> void :
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _exit_tree() -> void :
	if RenderingServer.frame_pre_draw.is_connected(_sync_timed_clock_capture):
		RenderingServer.frame_pre_draw.disconnect(_sync_timed_clock_capture)
	_reset_timed_clock_capture()
	if is_instance_valid(_timed_panel):
		_timed_motion.reset(_timed_panel)
	_generation += 1
	if _timed_bg_tween != null and _timed_bg_tween.is_valid():
		_timed_bg_tween.kill()
	AudioManager.stop_sfx(&"timed_endless_open")
	_kill_tween()
