class_name BonusLevelBanner
extends Control



const IN_DURATION: float = 0.28
const HOLD_DURATION: float = 1.65
const OUT_DURATION: float = 0.25
const TITLE_FONT_SIZE: int = 115
const TITLE_MIN_FONT_SIZE: int = 56
const TITLE_MAX_WIDTH: float = 950.0
const SHINE_START: float = 0.32
const SHINE_DURATION: float = 0.85
const STAR_BEATS: Array[float] = [0.4, 0.72, 1.04, 1.36, 1.63, 1.86]
const STAR_POSITIONS: Array[Vector2] = [Vector2(180, 286), Vector2(705, 149), Vector2(900, 282), Vector2(370, 153), Vector2(231, 408), Vector2(870, 420)]
@onready var _art: Control = $Art
@onready var _title: Control = $Art / Title
@onready var _title_face: Label = $Art / Title / CompositeCache / GlyphSource / Glyph
@onready var _title_layers: Array[Label] = [
	$Art / Title / CompositeCache / GlowCache / HorizontalCache / PinkSource / PinkOutline, 
	$Art / Title / CompositeCache / GlowCache / HorizontalCache / PinkSource / PinkDepth, 
	$Art / Title / CompositeCache / WhiteOutline, 
	$Art / Title / CompositeCache / BrownShadow, 
	$Art / Title / CompositeCache / OrangeOutline, 
	$Art / Title / CompositeCache / GlyphSource / Glyph, 
]
@onready var _title_caches: Array[SubViewport] = [
	$Art / Title / CompositeCache / GlowCache / HorizontalCache / PinkSource, 
	$Art / Title / CompositeCache / GlowCache / HorizontalCache, 
	$Art / Title / CompositeCache / GlowCache, 
	$Art / Title / CompositeCache / GlyphSource, 
	$Art / Title / CompositeCache, 
]
@onready var _title_gradient: ShaderMaterial = $Art / Title / CompositeCache / OrangeOutline.material
@onready var _float_host: Node2D = $Art / FloatHost
@onready var _pig: Sprite2D = $Art / FloatHost / Pig
@onready var _motes: CPUParticles2D = $Art / RiseMotes
var _stars: Array[CPUParticles2D] = []
var _generation: int = 0
var _tween: Tween = null
var _float_origin: Vector2
var _next_star: int = 0
var _title_cache_dirty: bool = true
var playback_speed: float = 1.0

@export var base_art_only: bool = false

func _ready() -> void :
	_float_origin = _float_host.position
	_pig.scale = Vector2.ONE * (464.1 / float(_pig.texture.get_width()))
	for i: int in range(STAR_BEATS.size()):
		_stars.append(_art.get_node("Sparkle%d" % i) as CPUParticles2D)
	_fit_title()
	cancel()

func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_fit_title()
	if (what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED) and is_node_ready():
		cancel()

func play() -> void :
	cancel()
	var generation: int = _generation
	visible = true
	AudioManager.play_sfx(&"bonus_level_banner_appear")
	_refresh_title_cache()
	_next_star = 0
	if not base_art_only:
		_motes.restart()
		_motes.emitting = true
	_tween = create_tween()
	_tween.set_speed_scale(playback_speed)
	_tween.tween_method(_sample_motion, 0.0, IN_DURATION + HOLD_DURATION + OUT_DURATION, 
		IN_DURATION + HOLD_DURATION + OUT_DURATION)
	var tw: Tween = _tween
	while generation == _generation and tw.is_valid() and tw.is_running():
		await get_tree().process_frame
	if generation == _generation:
		cancel()

func set_playback_speed(speed: float) -> void :
	playback_speed = maxf(speed, 0.01)
	for particle: CPUParticles2D in _stars:
		particle.speed_scale = playback_speed
	_motes.speed_scale = playback_speed
	if _tween != null and _tween.is_valid():
		_tween.set_speed_scale(playback_speed)

func _sample_motion(age: float) -> void :
	var alpha: float = clampf(age / 0.18, 0.0, 1.0)
	var scale_value: float = 1.0
	if age < 0.18:
		var t: float = age / 0.18
		scale_value = lerpf(0.9, 1.03, 1.0 - pow(1.0 - t, 3.0))
	elif age < IN_DURATION:
		scale_value = lerpf(1.03, 1.0, smoothstep(0.18, IN_DURATION, age))
	elif age > IN_DURATION + HOLD_DURATION:
		var t: float = clampf((age - IN_DURATION - HOLD_DURATION) / OUT_DURATION, 0.0, 1.0)
		alpha = 1.0 - t
		scale_value = lerpf(1.0, 0.97, t)
	_art.scale = Vector2.ONE * scale_value
	_art.modulate.a = alpha
	_title.modulate.a = clampf((age - 0.06) / 0.18, 0.0, 1.0)

	var envelope: float = smoothstep(0.0, IN_DURATION, age)
	_float_host.position = _float_origin + Vector2(0.0, sin(age * TAU / 2.4) * 6.0 * envelope * (0.0 if base_art_only else 1.0))
	var shine: ShaderMaterial = _pig.material as ShaderMaterial
	var progress: float = clampf((age - SHINE_START) / SHINE_DURATION, 0.0, 1.0)
	shine.set_shader_parameter("progress", 0.0 if base_art_only else smoothstep(0.0, 1.0, progress))
	while not base_art_only and _next_star < STAR_BEATS.size() and age >= STAR_BEATS[_next_star]:
		var star: CPUParticles2D = _stars[_next_star]
		star.position = STAR_POSITIONS[_next_star] + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		star.restart()
		star.emitting = true
		_next_star += 1

func cancel() -> void :
	AudioManager.stop_sfx(&"bonus_level_banner_appear")
	_generation += 1
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	visible = false
	if not is_node_ready():
		return
	_float_host.position = _float_origin
	_art.scale = Vector2.ONE
	_art.modulate.a = 0.0
	_title.modulate.a = 0.0
	(_pig.material as ShaderMaterial).set_shader_parameter("progress", 0.0)
	_next_star = 0
	_clear_particles(_motes)
	for star: CPUParticles2D in _stars:
		_clear_particles(star)

func _clear_particles(particle: CPUParticles2D) -> void :
	particle.emitting = false

	particle.amount = particle.amount

func _fit_title() -> void :
	var font: Font = _title_face.get_theme_font(&"font")
	var text: String = tr(&"BONUS_LEVEL_TITLE")
	var font_size: int = TITLE_FONT_SIZE
	while font_size > TITLE_MIN_FONT_SIZE and font.get_string_size(text, 
			HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size).x > TITLE_MAX_WIDTH:
		font_size -= 1
	for layer: Label in _title_layers:
		layer.add_theme_font_size_override(&"font_size", font_size)
		if layer.label_settings != null:
			layer.label_settings.font_size = font_size

	var line_height: float = maxf(126.0, _title_face.get_minimum_size().y)
	for layer: Label in _title_layers:
		layer.size.y = line_height
	var gradient_top: float = (line_height - float(font_size)) * 0.5
	_title_gradient.set_shader_parameter("gradient_top_y", gradient_top)
	_title_gradient.set_shader_parameter("gradient_height", float(font_size))
	_title_cache_dirty = true
	if visible:
		_refresh_title_cache()

func _refresh_title_cache() -> void :
	if not _title_cache_dirty:
		return
	_title_cache_dirty = false

	for cache: SubViewport in _title_caches:
		cache.render_target_update_mode = SubViewport.UPDATE_ONCE

func _exit_tree() -> void :
	AudioManager.stop_sfx(&"bonus_level_banner_appear")
