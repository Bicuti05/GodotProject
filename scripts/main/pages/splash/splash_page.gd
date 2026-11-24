class_name SplashPage
extends PageScene



signal loading_complete

const _PROGRESS_SPEED: float = 2.5

const _FINISH_TWEEN_DURATION: float = 0.1

const _SLOGAN_COUNT: int = 67
const _QUOTE_KEY_PREFIX: String = "SLOGAN_CONTENT_"
const _AUTHOR_KEY_PREFIX: String = "SLOGAN_AUTHOR_"
const _QUOTE_FONT_MAX_SIZE: int = 64
const _QUOTE_FONT_MIN_SIZE: int = 44
const _QUOTE_SHRINK_START_LENGTH: int = 80
const _QUOTE_SHRINK_END_LENGTH: int = 188

const _NEW_QUOTE_FONT_MAX_SIZE: int = 74

const _NEW_QUOTE_SAFE_RECT: Rect2 = Rect2(-432.0, 193.0, 889.0, 400.0)
const _NEW_QUOTE_DEFAULT_TOP: float = 242.0
const _NEW_QUOTE_SAFE_TOP_GAP: float = 32.0
const _NEW_QUOTE_COLOR: Color = Color(0.485670835, 0.300473571, 0.088819534, 1.0)
const _NEW_PROGRESS_SCALE: float = 1.2
const _NEW_PROGRESS_SIZE: Vector2 = Vector2(830.4, 115.2)
const _NEW_PROGRESS_BOTTOM: float = 301.8
const _NEW_PROGRESS_FILL_WIDTH: float = 768.0
const _NEW_BUTTERFLY_SIZE_MULTIPLIER: float = 0.65
const _NEW_BUTTERFLY_SCALE: float = 128.0 / 566.0 / _NEW_PROGRESS_SCALE * _NEW_BUTTERFLY_SIZE_MULTIPLIER

const _NEW_BUTTERFLY_CENTER_Y: float = -30.6 - 12.0
const _NEW_BIRD_PATH: String = "res://assets/spine/effect_splash_birdie01/effect_splash_birdie01.tres"
const _NEW_BIRD_POSITION: Vector2 = Vector2(648.0, 1035.0)
const _NEW_BIRD_SCALE: float = 1.5



const _LOGO_ANIM_INTO: String = "into"
const _LOGO_ANIM_IDLE: String = "idle_01"
const _LOGO_ANIM_IDLE_ALT: String = "idle_02"

const _LOGO_IDLE_PER_ALT: int = 4


const _LOGO_SCALE: float = 0.40002

const _LOGO_CENTER_Y_RATIO: float = 0.9316
const _LOGO_CENTER_Y_OFFSET_PX: float = -30.0

const _LOGO_BBOX_CENTER_Y: float = -9.804
const _ORIGINAL_LOGO_PATH: String = "res://assets/spine/effect_game_logo/effect_game_logo.tres"

const _PROGRESS_FILL_WIDTH: float = 640.0






const _BUTTERFLY_ANIM: String = "animation"



const _BUTTERFLY_SCALE: float = 128.0 / 566.0 * 0.7



const _BUTTERFLY_BBOX_CENTER: Vector2 = Vector2(-16.5044, -179.8294)
const _BUTTERFLY_BOB_AMPLITUDE: float = 5.0
const _BUTTERFLY_PETALS: Script = preload("res://scripts/main/pages/splash/splash_butterfly_petals.gd")

var _progress_petals: Node2D
var _splash_bird: SpineSprite
@export var christmas_theme_skin: JuiceSkinDefinition
var _christmas_theme_enabled: bool = false
@onready var _christmas_theme: JuiceSkinPageTheme = JuiceSkinResolver.resolve_page_theme(christmas_theme_skin)
@onready var _christmas_background: ColorRect = $ChristmasBackground
@onready var _christmas_illustration: TextureRect = $ChristmasBackground / Illustration
@onready var _christmas_snowflakes: Array[TextureRect] = [
	$ChristmasBackground / Snowflake1, $ChristmasBackground / Snowflake2, 
	$ChristmasBackground / Snowflake3, $ChristmasBackground / Snowflake4, 
]
@onready var _christmas_track: NinePatchRect = $ProgressBar / ChristmasTrack
@onready var _christmas_fill: NinePatchRect = $ProgressBar / ChristmasFill
@onready var _christmas_icon: TextureRect = $ProgressBar / ChristmasIcon
@onready var _christmas_quote_root: Control = $ChristmasQuote
@onready var _christmas_quote_label: Label = $ChristmasQuote / QuoteLabel
@onready var _christmas_author_label: Label = $ChristmasQuote / AuthorLabel


@onready var _progress_bar: TextureProgressBar = $ProgressBar
@onready var _background: TextureRect = $Background
@onready var _new_background: TextureRect = $NewBackground
@onready var _new_background_fill: ColorRect = $NewBackgroundFill
@onready var _progress_fill: NinePatchRect = $ProgressBar / Fill
@onready var _new_progress_track: TextureRect = $ProgressBar / NewTrack
@onready var _new_progress_fill: NinePatchRect = $ProgressBar / NewFill
@onready var _progress_butterfly: SpineSprite = $ProgressBar / Butterfly
@onready var _static_butterfly: Sprite2D = $ProgressBar / StaticButterfly
@onready var _ambient_light: Node2D = $AmbientLight
@onready var _ambient_foliage: Node2D = $AmbientFoliage
@onready var _logo: SpineSprite = $Logo
@onready var _quote_label: Label = $QuoteAuthor / QuoteLabel
@onready var _author_label: Label = $QuoteAuthor / AuthorLabel
@onready var _quote_root: VBoxContainer = $QuoteAuthor
@onready var _original_track: Texture2D = _progress_bar.texture_under
@onready var _original_quote_offsets: Vector4 = Vector4(_quote_root.offset_left, _quote_root.offset_top, _quote_root.offset_right, _quote_root.offset_bottom)
@onready var _original_bar_offsets: Vector4 = Vector4(_progress_bar.offset_left, _progress_bar.offset_top, _progress_bar.offset_right, _progress_bar.offset_bottom)
@onready var _original_quote_color: Color = _quote_label.get_theme_color("font_color")
@onready var _original_author_color: Color = _author_label.get_theme_color("font_color")
@onready var _original_quote_shadow: Color = _quote_label.get_theme_color("font_shadow_color")
@onready var _original_author_shadow: Color = _author_label.get_theme_color("font_shadow_color")
@onready var _original_quote_font: Font = _quote_label.get_theme_font("font")
@onready var _new_quote_font: FontVariation = _original_quote_font.duplicate() as FontVariation
@onready var _christmas_quote_font: FontVariation = _original_quote_font.duplicate() as FontVariation
@onready var _original_line_spacing: int = _quote_label.get_theme_constant("line_spacing")
@onready var _original_separation: int = _quote_root.get_theme_constant("separation")
@onready var _original_author_size: int = _author_label.get_theme_font_size("font_size")
@onready var _original_quote_minimum: Vector2 = _quote_label.custom_minimum_size
@onready var _original_author_minimum: Vector2 = _author_label.custom_minimum_size
@onready var _original_static_scale: Vector2 = _static_butterfly.scale

var _cold_start_optimized: bool = false
var _current_progress: float = 0.0
var _elapsed_time: float = 0.0
var _target_progress: float = 0.0
var _stage_end_progress: float = 0.0
var _loading_stage: String = ""
var _progress_generation: int = 0
var _running: bool = false
var _force_complete_requested: bool = false
var _completed: bool = false
var _finish_tween: Tween = null
var _next_perf_progress_mark: int = 25
var _progress_started_msec: int = 0
var _last_perf_process_msec: int = 0
var _butterfly_age: float = 0.0
var _new_splash_enabled: bool = false


func _ready() -> void :

	if not _logo.animation_completed.is_connected(_on_logo_animation_completed):
		_logo.animation_completed.connect(_on_logo_animation_completed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_layout_logo()


func _on_show(_params: Dictionary = {}) -> void :
	if not is_node_ready():
		await ready
	set_cold_start_optimized(bool(_params.get("cold_start_optimized", _cold_start_optimized)))
	ABManager.dye_at_enter_splash()

	Tracker.track_scr_show(TrackingEvents.SCR_SPLASH)

	_set_content_alpha(1.0)
	ABManager.dye_at_splash_enter()
	_new_splash_enabled = ABManager.splash.is_new_splash_enabled()
	_christmas_theme_enabled = ABManager.christmas_theme.is_christmas_theme_enabled()
	_apply_splash_style()
	_layout_logo()
	_play_logo()
	_play_butterfly()
	_play_splash_bird()
	_setup_quote(_params)
	if _new_splash_enabled and not _christmas_theme_enabled:
		_play_new_splash_enter_sfx()
	_progress_generation += 1
	if _finish_tween != null and _finish_tween.is_valid():
		_finish_tween.kill()
	_finish_tween = null
	_target_progress = 0.0
	_stage_end_progress = 0.0
	_loading_stage = ""
	_current_progress = 0.0
	_elapsed_time = 0.0
	_butterfly_age = 0.0
	_force_complete_requested = false
	_completed = false
	_next_perf_progress_mark = 25
	_progress_started_msec = Time.get_ticks_msec()
	_last_perf_process_msec = _progress_started_msec
	_running = true
	_apply_progress(0.0)
	set_process(true)



func _setup_quote(params: Dictionary) -> void :
	if _new_splash_enabled:
		var country: String = SplashQuoteSelector.resolve_country(String(params.get("system_locale", "")))
		if not country.is_empty():
			var key: String = SplashQuoteSelector.quote_key(country, randi_range(1, SplashQuoteSelector.QUOTE_COUNT))
			var quote: String = tr(key)
			if not quote.is_empty() and quote != key:
				_quote_label.text = quote
				_author_label.text = ""
				_author_label.hide()
				_apply_quote_font_size(quote.length())
				SortLogger.info("SplashQuote: key=%s locale=%s" % [key, TranslationServer.get_locale()])
				return
	_setup_quote_for_today()



func _apply_splash_style() -> void :
	_quote_root.show()
	_christmas_quote_root.hide()
	_christmas_background.hide()
	_christmas_track.hide()
	_christmas_fill.hide()
	_christmas_icon.hide()
	_background.show()
	_new_background.hide()
	_new_background_fill.hide()
	_new_progress_track.hide()
	_new_progress_fill.hide()
	_progress_bar.texture_under = _original_track
	_quote_label.add_theme_color_override("font_color", _original_quote_color)
	_author_label.add_theme_color_override("font_color", _original_author_color)
	_quote_label.add_theme_color_override("font_shadow_color", _original_quote_shadow)
	_author_label.add_theme_color_override("font_shadow_color", _original_author_shadow)
	_quote_label.add_theme_font_override("font", _original_quote_font)
	_quote_label.add_theme_constant_override("line_spacing", _original_line_spacing)
	_quote_root.add_theme_constant_override("separation", _original_separation)
	_author_label.add_theme_font_size_override("font_size", _original_author_size)
	_quote_label.custom_minimum_size = _original_quote_minimum
	_author_label.custom_minimum_size = _original_author_minimum
	_static_butterfly.scale = _original_static_scale
	if _new_splash_enabled:
		_apply_new_splash_style()
	if _christmas_theme_enabled:
		_apply_christmas_splash_style()
	_layout_splash_style()
	_update_ambient_visibility()


func _apply_new_splash_style() -> void :
	_background.hide()
	_new_background.show()
	_new_background_fill.show()
	_progress_bar.texture_under = null
	_new_progress_track.show()
	_quote_label.add_theme_color_override("font_color", _NEW_QUOTE_COLOR)
	_author_label.add_theme_color_override("font_color", _NEW_QUOTE_COLOR)
	_quote_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	_author_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	_quote_label.add_theme_font_override("font", _new_quote_font)
	_quote_root.add_theme_constant_override("separation", 50)
	_author_label.add_theme_font_size_override("font_size", 60)
	_quote_label.custom_minimum_size.y = 224.0
	_author_label.custom_minimum_size.y = 77.0
	_static_butterfly.scale = Vector2.ONE * (103.68 / _static_butterfly.texture.get_width() / _NEW_PROGRESS_SCALE * _NEW_BUTTERFLY_SIZE_MULTIPLIER)


func _on_viewport_size_changed() -> void :
	_layout_logo()
	_layout_splash_style()
	if is_node_ready() and _new_splash_enabled and not _christmas_theme_enabled:
		_fit_new_quote_to_safe_area()


func _layout_splash_style() -> void :
	if not is_node_ready():
		return
	if _christmas_theme_enabled:
		_layout_christmas_splash()
	elif _new_splash_enabled:
		_set_offsets(_quote_root, Vector4(_NEW_QUOTE_SAFE_RECT.position.x, 
			_NEW_QUOTE_DEFAULT_TOP, _NEW_QUOTE_SAFE_RECT.end.x, _NEW_QUOTE_SAFE_RECT.end.y))
		_progress_bar.scale = Vector2.ONE * _NEW_PROGRESS_SCALE
		_progress_bar.size = Vector2(692.0, 96.0)
		_progress_bar.position = Vector2(UiMetrics.center_left(_NEW_PROGRESS_SIZE.x) - 7.8, 
			UiMetrics.viewport_size().y - _NEW_PROGRESS_BOTTOM - _NEW_PROGRESS_SIZE.y)
	else:
		_set_offsets(_quote_root, _original_quote_offsets)
		_progress_bar.scale = Vector2.ONE
		_set_offsets(_progress_bar, _original_bar_offsets)
	_layout_splash_bird()


func _layout_splash_bird() -> void :
	if _splash_bird == null:
		return
	var texture_size: Vector2 = _new_background.texture.get_size()
	var background_scale: float = minf(_new_background.size.x / texture_size.x, 
		_new_background.size.y / texture_size.y)
	_splash_bird.position = (_new_background.size - texture_size * background_scale) * 0.5\
	+ _NEW_BIRD_POSITION * background_scale
	_splash_bird.scale = Vector2.ONE * _NEW_BIRD_SCALE * background_scale


func _set_offsets(control: Control, offsets: Vector4) -> void :
	control.offset_left = offsets.x
	control.offset_top = offsets.y
	control.offset_right = offsets.z
	control.offset_bottom = offsets.w


func _play_new_splash_enter_sfx() -> void :

	SortLogger.info("[Splash] TODO splash_enter_sfx_resource")



func _setup_quote_for_today() -> void :
	_author_label.show()
	var today_str: String = Time.get_date_string_from_system()
	var idx: int
	if UserState.get_last_splash_date() != today_str:
		idx = 1
		UserState.set_last_splash_date(today_str)
	else:
		idx = randi_range(2, _SLOGAN_COUNT)
	var quote: String = tr("%s%d" % [_QUOTE_KEY_PREFIX, idx])
	_quote_label.text = quote
	_author_label.text = "- " + tr("%s%d" % [_AUTHOR_KEY_PREFIX, idx])
	_apply_quote_font_size(quote.length())
	SortLogger.info("SplashQuote: key=%s%d locale=%s" % [
		_QUOTE_KEY_PREFIX, idx, TranslationServer.get_locale(), 
	])



func _apply_quote_font_size(text_length: int) -> void :
	if _christmas_theme_enabled:
		_sync_christmas_quote()
		return
	if _new_splash_enabled:
		_fit_new_quote_to_safe_area()
		return
	var ratio: float = inverse_lerp(
		float(_QUOTE_SHRINK_START_LENGTH), float(_QUOTE_SHRINK_END_LENGTH), float(text_length))
	var font_size: int = roundi(lerpf(
		float(_QUOTE_FONT_MAX_SIZE), float(_QUOTE_FONT_MIN_SIZE), clampf(ratio, 0.0, 1.0)))
	_quote_label.add_theme_font_size_override("font_size", font_size)



func _fit_new_quote_to_safe_area() -> void :
	var width: float = _NEW_QUOTE_SAFE_RECT.size.x

	var top_inset: float = UiMetrics.safe_insets(1.0).x
	var safe_top: float = maxf(_NEW_QUOTE_DEFAULT_TOP, 
		top_inset + (_NEW_QUOTE_SAFE_TOP_GAP if top_inset > 0.0 else 0.0))
	var available_height: float = _NEW_QUOTE_SAFE_RECT.end.y - safe_top
	_set_new_quote_font_size(_NEW_QUOTE_FONT_MAX_SIZE)

	_quote_label.size.x = width
	_author_label.size.x = width
	var minimum: Vector2 = _new_quote_minimum_size()
	if minimum.x > width or minimum.y > available_height:

		var low: int = 1
		var high: int = _NEW_QUOTE_FONT_MAX_SIZE - 1
		var fitted_size: int = 1
		while low <= high:
			var candidate: int = (low + high) / 2
			_set_new_quote_font_size(candidate)
			minimum = _new_quote_minimum_size()
			if minimum.x <= width and minimum.y <= available_height:
				fitted_size = candidate
				low = candidate + 1
			else:
				high = candidate - 1
		_set_new_quote_font_size(fitted_size)
		minimum = _new_quote_minimum_size()
	_author_label.size.x = width

	_quote_root.update_minimum_size()
	_set_offsets(_quote_root, Vector4(_NEW_QUOTE_SAFE_RECT.position.x, safe_top, 
		_NEW_QUOTE_SAFE_RECT.end.x, safe_top + minimum.y))


func _set_new_quote_font_size(font_size: int) -> void :
	var scale_ratio: float = float(font_size) / float(_NEW_QUOTE_FONT_MAX_SIZE)
	_quote_label.add_theme_font_size_override("font_size", font_size)

	_new_quote_font.spacing_glyph = roundi(float(font_size) * 0.02)
	_quote_label.add_theme_constant_override("line_spacing", 
		roundi(float(font_size) * 1.06 - _new_quote_font.get_height(font_size)))
	_quote_label.custom_minimum_size.y = 224.0 * scale_ratio
	_author_label.add_theme_font_size_override("font_size", maxi(1, roundi(60.0 * scale_ratio)))
	_author_label.custom_minimum_size.y = 77.0 * scale_ratio


func _new_quote_minimum_size() -> Vector2:
	var minimum: Vector2 = _quote_label.get_combined_minimum_size()
	if _author_label.visible:
		var author_minimum: Vector2 = _author_label.get_combined_minimum_size()
		minimum.x = maxf(minimum.x, author_minimum.x)
		minimum.y += float(_quote_root.get_theme_constant("separation")) + author_minimum.y
	return minimum




func _layout_logo() -> void :
	if _logo == null or not is_instance_valid(_logo):
		return
	var vp: Vector2 = UiMetrics.viewport_size()
	_logo.scale = Vector2.ONE * _LOGO_SCALE

	_logo.position = Vector2(vp.x * 0.5, 
		vp.y * _LOGO_CENTER_Y_RATIO + _LOGO_CENTER_Y_OFFSET_PX - _LOGO_BBOX_CENTER_Y * _LOGO_SCALE)



func _play_logo() -> void :
	if _new_splash_enabled or _christmas_theme_enabled:
		_logo.hide()
		_logo.process_mode = Node.PROCESS_MODE_DISABLED
		return
	_play_logo_design()



func prepare_logo_for_display(active: Callable) -> bool:
	if ABManager.christmas_theme.is_christmas_theme_enabled():
		return active.call()

	if ABManager.splash.is_new_splash_enabled():
		return await _ensure_splash_bird(active)
	return await _ensure_original_logo(active)


func _ensure_splash_bird(active: Callable) -> bool:
	if not active.call():
		return false
	if _splash_bird != null:
		return true
	var status: int = ResourceLoader.load_threaded_get_status(_NEW_BIRD_PATH)
	if not ResourceLoader.has_cached(_NEW_BIRD_PATH) and status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		if ResourceLoader.load_threaded_request(_NEW_BIRD_PATH, "SpineSkeletonDataResource", false) != OK:
			SortLogger.error("SplashPage: 小鸟骨架资源请求失败")
			return false
	while active.call() and ResourceLoader.load_threaded_get_status(_NEW_BIRD_PATH) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	if not active.call():
		return false
	var data: SpineSkeletonDataResource
	if ResourceLoader.load_threaded_get_status(_NEW_BIRD_PATH) == ResourceLoader.THREAD_LOAD_LOADED:
		data = ResourceLoader.load_threaded_get(_NEW_BIRD_PATH) as SpineSkeletonDataResource
	elif ResourceLoader.has_cached(_NEW_BIRD_PATH):
		data = load(_NEW_BIRD_PATH) as SpineSkeletonDataResource
	if data == null:
		SortLogger.error("SplashPage: 小鸟骨架资源加载失败")
		return false
	_splash_bird = SpineSprite.new()
	_splash_bird.name = "SplashBird"
	_splash_bird.visible = false
	_splash_bird.process_mode = Node.PROCESS_MODE_DISABLED
	_splash_bird.skeleton_data_res = data
	_new_background.add_child(_splash_bird)
	_layout_splash_bird()
	return true


func _play_splash_bird() -> void :
	_stop_splash_bird()
	if not _new_splash_enabled or _christmas_theme_enabled:
		return
	if _splash_bird == null:
		SortLogger.error("SplashPage: 展示前未准备小鸟骨架资源")
		return
	var state: Object = _splash_bird.get_animation_state()
	if state == null:
		SortLogger.error("SplashPage: 小鸟Spine动画状态不可用")
		return
	_layout_splash_bird()
	state.call("set_animation", "animation", true, 0)
	_splash_bird.process_mode = Node.PROCESS_MODE_INHERIT
	_splash_bird.show()


func _stop_splash_bird() -> void :
	if _splash_bird == null:
		return
	_splash_bird.hide()
	_splash_bird.process_mode = Node.PROCESS_MODE_DISABLED
	var state: Object = _splash_bird.get_animation_state()
	if state != null:
		state.call("clear_tracks")


func _ensure_original_logo(active: Callable) -> bool:
	if not active.call():
		return false
	if _logo.skeleton_data_res == null:
		var status: int = ResourceLoader.load_threaded_get_status(_ORIGINAL_LOGO_PATH)
		if not ResourceLoader.has_cached(_ORIGINAL_LOGO_PATH) and status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			if ResourceLoader.load_threaded_request(_ORIGINAL_LOGO_PATH, "SpineSkeletonDataResource", false) != OK:
				SortLogger.error("SplashPage: 原 Logo 骨架资源请求失败")
				return false
		while active.call() and ResourceLoader.load_threaded_get_status(_ORIGINAL_LOGO_PATH) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		if not active.call():
			return false

		if ResourceLoader.load_threaded_get_status(_ORIGINAL_LOGO_PATH) == ResourceLoader.THREAD_LOAD_LOADED:
			_logo.skeleton_data_res = ResourceLoader.load_threaded_get(_ORIGINAL_LOGO_PATH) as SpineSkeletonDataResource
		elif ResourceLoader.has_cached(_ORIGINAL_LOGO_PATH):
			_logo.skeleton_data_res = load(_ORIGINAL_LOGO_PATH) as SpineSkeletonDataResource
		if _logo.skeleton_data_res == null:
			SortLogger.error("SplashPage: 原 Logo 骨架加载失败")
			return false
	_logo.process_mode = Node.PROCESS_MODE_INHERIT
	_logo.show()
	return true


func _play_logo_design() -> void :
	ABManager.dye_at_logo_design()
	if ABManager.logo_design.is_new_logo_enabled():
		_play_new_logo()
	else:
		_play_original_logo()


func _play_new_logo() -> void :

	SortLogger.info("[LogoDesign] TODO new_logo_resources; playing original logo")
	_play_original_logo()



func _play_original_logo() -> void :
	if _new_splash_enabled or _christmas_theme_enabled:
		return
	if _logo.skeleton_data_res == null:
		_play_original_after_prepare()
		return
	var st: Object = _logo.get_animation_state()
	if st == null:
		return

	st.call("clear_tracks")
	st.call("set_animation", _LOGO_ANIM_INTO, false, 0)
	_queue_logo_idle_batch(st)



func _play_original_after_prepare() -> void :
	var generation: int = _progress_generation
	var active: Callable = func() -> bool:
		return is_instance_valid(self) and is_visible_in_tree() and generation == _progress_generation and not _new_splash_enabled and not _christmas_theme_enabled
	if await _ensure_original_logo(active):
		_play_original_logo()




func _queue_logo_idle_batch(st: Object) -> void :
	for _i in _LOGO_IDLE_PER_ALT:
		st.call("add_animation", _LOGO_ANIM_IDLE, 0.0, false, 0)
	st.call("add_animation", _LOGO_ANIM_IDLE_ALT, 0.0, false, 0)




func _on_logo_animation_completed(_sprite: Object, state: Object, entry: Object) -> void :
	if _new_splash_enabled or _christmas_theme_enabled or entry == null or state == null:
		return
	var anim: Object = entry.call("get_animation")
	if anim != null and String(anim.call("get_name")) == _LOGO_ANIM_IDLE_ALT:
		_queue_logo_idle_batch(state)





func _play_butterfly() -> void :
	if _christmas_theme_enabled:
		_static_butterfly.hide()
		_progress_butterfly.hide()
		_progress_butterfly.process_mode = Node.PROCESS_MODE_DISABLED
		var state: Object = _progress_butterfly.get_animation_state()
		if state != null:
			state.call("clear_tracks")
		return
	if _cold_start_optimized:
		return
	if _progress_butterfly == null:
		return
	_progress_butterfly.scale = Vector2.ONE * (_NEW_BUTTERFLY_SCALE if _new_splash_enabled else _BUTTERFLY_SCALE)
	var st: Object = _progress_butterfly.get_animation_state()
	if st == null:
		return
	st.call("clear_tracks")
	st.call("set_animation", _BUTTERFLY_ANIM, true, 0)


func _on_hide() -> void :
	_stop_splash_bird()
	if _progress_petals != null:
		_progress_petals.call("set_emitting", false)
	_progress_generation += 1
	_running = false
	set_process(false)
	if _finish_tween != null and _finish_tween.is_valid():
		_finish_tween.kill()
		_finish_tween = null
	visible = false






func fade_out_content(dur: float) -> void :
	var t: = create_tween()
	t.tween_method(_set_content_alpha, 1.0, 0.0, dur)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


var _content_base_alpha: Dictionary = {}


func _set_content_alpha(factor: float) -> void :
	for child in get_children():
		if child is CanvasItem and child.name not in [&"Background", &"NewBackground", &"NewBackgroundFill", &"ChristmasBackground"]:
			var ci: = child as CanvasItem
			if not _content_base_alpha.has(ci):
				_content_base_alpha[ci] = ci.modulate.a
			ci.modulate.a = float(_content_base_alpha[ci]) * factor


func _process(delta: float) -> void :
	var now_msec: int = Time.get_ticks_msec()
	var wall_gap_msec: int = now_msec - _last_perf_process_msec
	_last_perf_process_msec = now_msec
	if _running and not _completed and wall_gap_msec >= 33:
		SortLogger.warn("StartupPerf: frame_stall owner=splash stage=%s wall_gap=%dms delta=%dms progress=%d%% elapsed=%dms" % [
			_loading_stage, wall_gap_msec, roundi(delta * 1000.0), roundi(_current_progress * 100.0), roundi(_elapsed_time * 1000.0)
		])


	if not _running or _completed:
		return

	_elapsed_time += delta
	_butterfly_age += delta
	_update_progress_butterfly()
	if not _force_complete_requested and _current_progress < _target_progress:
		_apply_progress(move_toward(_current_progress, _target_progress, _PROGRESS_SPEED * delta))
		var progress_percent: int = floori(_current_progress * 100.0)
		while progress_percent >= _next_perf_progress_mark:
			SortLogger.mark("StartupPerf: splash crossed=%d%% actual=%d%% elapsed=%dms" % [
				_next_perf_progress_mark, progress_percent, roundi(_elapsed_time * 1000.0)
			])
			_next_perf_progress_mark += 25



func get_progress_generation() -> int:
	return _progress_generation


func is_progress_active(generation: int) -> bool:
	return generation == _progress_generation and _running and not _completed and visible


func begin_loading_stage(stage: String, start_percent: float, end_percent: float, generation: int) -> void :
	if not is_progress_active(generation):
		return
	_loading_stage = stage
	_stage_end_progress = clampf(end_percent / 100.0, 0.0, 0.99)
	set_loading_progress(start_percent, generation)


func set_loading_progress(percent: float, generation: int) -> void :
	if not is_progress_active(generation) or _force_complete_requested:
		return
	_target_progress = maxf(_target_progress, clampf(percent / 100.0, 0.0, _stage_end_progress))


func wait_loading_progress(percent: float, generation: int) -> void :
	var target: float = minf(percent / 100.0, 0.99)
	while is_progress_active(generation) and _current_progress < target:
		await get_tree().process_frame



func force_complete() -> void :
	if not _running or _completed or _force_complete_requested:
		return
	_force_complete_requested = true

	if _current_progress >= 1.0:
		_finalize()
		return



	if _finish_tween == null:
		_start_finish_tween()


func _start_finish_tween() -> void :
	var generation: int = _progress_generation
	_finish_tween = create_tween()
	_finish_tween.tween_method(_apply_progress, _current_progress, 1.0, _FINISH_TWEEN_DURATION)
	_finish_tween.finished.connect( func() -> void :
		if generation == _progress_generation and _running:
			_finalize()
	)


func _apply_progress(value: float) -> void :
	_current_progress = clampf(value, 0.0, 1.0)
	if _progress_bar != null:
		_progress_bar.value = _current_progress * 100.0
	if _progress_fill != null:
		_progress_fill.visible = _current_progress > 0.0 and not _new_splash_enabled and not _christmas_theme_enabled
		_progress_fill.size.x = _PROGRESS_FILL_WIDTH * _current_progress
	if _new_progress_fill != null:
		_new_progress_fill.visible = _current_progress > 0.0 and _new_splash_enabled and not _christmas_theme_enabled
		_new_progress_fill.size.x = _NEW_PROGRESS_FILL_WIDTH * _current_progress
	_update_progress_butterfly()




func _update_progress_butterfly() -> void :
	if _christmas_theme_enabled:
		var fill_width: float = _christmas_theme.progress_fill_rect.size.x * _current_progress
		_christmas_fill.visible = _current_progress > 0.0

		var cap_width: float = float(_christmas_fill.patch_margin_left + _christmas_fill.patch_margin_right)
		_christmas_fill.size.x = maxf(fill_width, cap_width)
		_christmas_fill.scale.x = minf(fill_width / cap_width, 1.0)
		_christmas_icon.position = Vector2(_christmas_theme.progress_fill_rect.position.x + fill_width, 0.0)\
		+ _christmas_theme.progress_icon_offset
		return
	if _cold_start_optimized:
		_static_butterfly.position = Vector2(26.0 + _PROGRESS_FILL_WIDTH * _current_progress, -44.0)
		if _new_splash_enabled:
			_static_butterfly.position.x -= 11.84 / _NEW_PROGRESS_SCALE
			_static_butterfly.position.y = _NEW_BUTTERFLY_CENTER_Y / _NEW_PROGRESS_SCALE
		if _progress_petals != null:
			_progress_petals.set("emission_position", _static_butterfly.position)
		return
	if _progress_butterfly == null:
		return


	var center: Vector2 = Vector2(
		26.0 + _PROGRESS_FILL_WIDTH * _current_progress, 
		-44.0 + sin(_butterfly_age * 4.2) * _BUTTERFLY_BOB_AMPLITUDE)
	var butterfly_scale: float = _BUTTERFLY_SCALE
	if _new_splash_enabled:

		center.x -= 11.84 / _NEW_PROGRESS_SCALE
		center.y = _NEW_BUTTERFLY_CENTER_Y / _NEW_PROGRESS_SCALE + sin(_butterfly_age * 4.2) * _BUTTERFLY_BOB_AMPLITUDE
		butterfly_scale = _NEW_BUTTERFLY_SCALE

	_progress_butterfly.position = center - _BUTTERFLY_BBOX_CENTER * butterfly_scale
	if _progress_petals != null:
		_progress_petals.set("emission_position", center)


func _finalize() -> void :
	if _completed:
		return
	_completed = true
	_running = false
	set_process(false)
	_apply_progress(1.0)
	var elapsed_msec: int = Time.get_ticks_msec() - _progress_started_msec
	SortLogger.info("StartupPerf: splash progress_complete elapsed=%dms (%.3fs)" % [elapsed_msec, elapsed_msec / 1000.0])
	loading_complete.emit()



func set_cold_start_optimized(optimized: bool) -> void :
	_cold_start_optimized = optimized
	if not is_node_ready():
		return
	_static_butterfly.visible = optimized and not _christmas_theme_enabled
	_progress_butterfly.visible = not optimized and not _christmas_theme_enabled
	_progress_butterfly.process_mode = Node.PROCESS_MODE_DISABLED if optimized or _christmas_theme_enabled else Node.PROCESS_MODE_INHERIT
	if optimized:
		var state: Object = _progress_butterfly.get_animation_state()
		if state != null:
			state.call("clear_tracks")
	_update_ambient_visibility()
	_update_progress_butterfly()


func _update_ambient_visibility() -> void :
	var disabled: bool = _christmas_theme_enabled or (_cold_start_optimized and not _new_splash_enabled)
	for ambient: Node2D in [_ambient_light, _ambient_foliage]:
		ambient.visible = not disabled
		ambient.process_mode = Node.PROCESS_MODE_DISABLED if disabled else Node.PROCESS_MODE_INHERIT
	_ambient_light.set("beam_alpha_multiplier", 1.5 if _new_splash_enabled else 1.0)
	if _new_splash_enabled:
		_ambient_foliage.hide()
		_ambient_foliage.process_mode = Node.PROCESS_MODE_DISABLED
	if _new_splash_enabled and not _christmas_theme_enabled and _progress_petals == null:
		_progress_petals = _BUTTERFLY_PETALS.new()
		_progress_petals.name = "ButterflyPetals"
		_progress_petals.set("atlas", _ambient_foliage.get("petal_atlas"))
		_progress_bar.add_child(_progress_petals)
	if _progress_petals != null:
		_progress_petals.set("size_multiplier", _NEW_BUTTERFLY_SIZE_MULTIPLIER)
		_progress_petals.call("set_emitting", _new_splash_enabled and not _christmas_theme_enabled)



func _apply_christmas_splash_style() -> void :
	_background.hide()
	_new_background.hide()
	_new_background_fill.hide()
	_new_progress_track.hide()
	_new_progress_fill.hide()
	_progress_bar.texture_under = null
	_quote_root.hide()
	_christmas_quote_root.show()
	_christmas_background.color = _christmas_theme.background_color
	_christmas_background.show()
	_christmas_illustration.texture = _christmas_theme.illustration
	for i: int in _christmas_snowflakes.size():
		_christmas_snowflakes[i].texture = _christmas_theme.decoration_textures[i]
	_christmas_track.texture = _christmas_theme.progress_track
	_christmas_fill.texture = _christmas_theme.progress_fill
	_christmas_icon.texture = _christmas_theme.progress_icon
	_christmas_track.show()
	_christmas_icon.show()
	_christmas_quote_label.add_theme_font_override("font", _christmas_quote_font)
	for label: Label in [_christmas_quote_label, _christmas_author_label]:
		label.add_theme_color_override("font_color", _christmas_theme.quote_color)
		label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)


func _layout_christmas_splash() -> void :
	var vp: Vector2 = UiMetrics.viewport_size()
	var rect: Rect2 = _christmas_theme.illustration_rect
	_christmas_illustration.position = Vector2(UiMetrics.center_x() + rect.position.x, 
		rect.position.y + maxf(vp.y - _christmas_theme.reference_size.y, 0.0) * 0.5)
	_christmas_illustration.size = rect.size
	for i: int in _christmas_snowflakes.size():
		_christmas_snowflakes[i].position = vp * _christmas_theme.decoration_anchors[i]\
		+ _christmas_theme.decoration_rects[i].position
		_christmas_snowflakes[i].size = _christmas_theme.decoration_rects[i].size
	_progress_bar.scale = Vector2.ONE
	_progress_bar.size = _christmas_theme.progress_size
	_progress_bar.position = Vector2(UiMetrics.center_left(_christmas_theme.progress_size.x), 
		vp.y - _christmas_theme.progress_bottom_margin - _christmas_theme.progress_size.y - UiMetrics.safe_insets().y)
	_christmas_track.position = Vector2.ZERO
	_christmas_track.size = _christmas_theme.progress_size
	_christmas_fill.position = _christmas_theme.progress_fill_rect.position
	_christmas_fill.size.y = _christmas_theme.progress_fill_rect.size.y
	_christmas_icon.size = _christmas_theme.progress_icon_size
	_layout_christmas_quote()
	_update_progress_butterfly()


func _sync_christmas_quote() -> void :
	_christmas_quote_label.text = _quote_label.text
	_christmas_author_label.text = _author_label.text
	_christmas_author_label.visible = _author_label.visible
	_layout_christmas_quote()


func _layout_christmas_quote() -> void :
	var rect: Rect2 = _christmas_theme.quote_rect
	var safe_top: float = UiMetrics.safe_insets(1.0).x
	_christmas_quote_root.position = Vector2(UiMetrics.center_x() + rect.position.x, 
		maxf(rect.position.y, safe_top + (32.0 if safe_top > 0.0 else 0.0)))
	_christmas_quote_root.size = rect.size
	_christmas_quote_label.position = Vector2.ZERO
	_christmas_quote_label.size = _christmas_theme.quote_text_size
	_christmas_author_label.position = _christmas_theme.author_rect.position
	_christmas_author_label.size = _christmas_theme.author_rect.size
	_fit_christmas_label(_christmas_quote_label, _christmas_theme.quote_font_size, _christmas_theme.quote_text_size)
	if _christmas_author_label.visible:
		_fit_christmas_label(_christmas_author_label, _christmas_theme.author_font_size, _christmas_theme.author_rect.size)



func _fit_christmas_label(label: Label, maximum: int, area: Vector2) -> void :
	var low: int = 1
	var high: int = maximum
	var fitted: int = 1
	while low <= high:
		var candidate: int = (low + high) / 2
		_set_christmas_label_font_size(label, candidate)
		var minimum: Vector2 = label.get_minimum_size()
		if minimum.x <= area.x and minimum.y <= area.y:
			fitted = candidate
			low = candidate + 1
		else:
			high = candidate - 1
	_set_christmas_label_font_size(label, fitted)

	label.size = area


func _set_christmas_label_font_size(label: Label, font_size: int) -> void :
	label.add_theme_font_size_override("font_size", font_size)
	if label == _christmas_quote_label:
		_christmas_quote_font.spacing_glyph = roundi(float(font_size) * 0.02)
		label.add_theme_constant_override("line_spacing", 
			roundi(float(font_size) * 1.06 - _christmas_quote_font.get_height(font_size)))
