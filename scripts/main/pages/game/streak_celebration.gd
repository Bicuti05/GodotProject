class_name StreakCelebration
extends Control



const DURATION: float = 2.6
const EXIT_START: float = 2.25
const WORD_EXIT_DURATION: float = 0.18
const BACKDROP_ALPHA: float = 0.6
const STAR_COUNT: int = 16
const PARTICLE_DIRECTION_SPREAD: float = 20.0
const PARTICLE_INITIAL_ROTATION_SPREAD: float = 90.0
const PARTICLE_SPEED_RANDOMNESS: float = 0.5
const PARTICLE_SPIN_RANDOMNESS: float = 0.5
const TITLE_Y: float = 130.0
const SUBTITLE_Y: float = 304.0

const TOP_INK_Y_RANGE: Vector2 = Vector2(7.0, 140.0)
const BOTTOM_INK_Y_RANGE: Vector2 = Vector2(7.0, 69.0)
const BONE_DELAYS: Array[float] = [0.24, 0.28, 0.18, 0.22, 0.26]
const BONE_ANGLES: Array[float] = [-8.0, 8.0, -6.0, 7.0, -7.0]
@export var playback_speed: float = 1.0
@onready var _backdrop: ColorRect = $Backdrop
@onready var _stage: Node2D = $Stage
@onready var _trophy: Node2D = $Stage / Trophy
@onready var _words: CanvasGroup = $Stage / Words

@onready var _top_group: Control = $Stage / Words / TopGroup
@onready var _top_text: CurveLabel = $Stage / Words / TopGroup / TextTop
@onready var _top_layers: Array[CurveLabel] = [
	$Stage / Words / TopGroup / TextTopShadow, 
	$Stage / Words / TopGroup / TextTopBase, 
	$Stage / Words / TopGroup / TextTop, 
	$Stage / Words / TopGroup / TextTopInnerViewport / Glyph, 
]

@onready var _bottom_group: Control = $Stage / Words / BottomGroup
@onready var _bottom_text: CurveLabel = $Stage / Words / BottomGroup / TextBottom
@onready var _bottom_layers: Array[CurveLabel] = [
	$Stage / Words / BottomGroup / TextBottomShadow, 
	$Stage / Words / BottomGroup / TextBottom, 
]
@onready var _inner_viewport: SubViewport = $Stage / Words / TopGroup / TextTopInnerViewport
@onready var _inner_layer: TextureRect = $Stage / Words / TopGroup / TextTopInner
@onready var _radial: Sprite2D = $Stage / Effects / Radial
@onready var _glow: Sprite2D = $Stage / Effects / Glow
@onready var _glow_inner: Sprite2D = $Stage / Effects / GlowInner
@onready var _cloud: Sprite2D = $Stage / Effects / Cloud
@onready var _foot_glow: Sprite2D = $Stage / Effects / FootGlow
@onready var _particles: Node2D = $Stage / Particles
@onready var _bones: Array[Bone2D] = [
	$Stage / Trophy / Skeleton / LeavesLeft, $Stage / Trophy / Skeleton / LeavesRight, 
	$Stage / Trophy / Skeleton / Blue, $Stage / Trophy / Skeleton / Orange, $Stage / Trophy / Skeleton / Pink, 
]
var _elapsed: float = 0.0
var _particle_direction_offsets: PackedFloat32Array = PackedFloat32Array()
var _particle_speed_factors: PackedFloat32Array = PackedFloat32Array()
var _particle_rotation_offsets: PackedFloat32Array = PackedFloat32Array()
var _particle_spin_factors: PackedFloat32Array = PackedFloat32Array()

var _title_y: float = TITLE_Y
var _playing: bool = false
var _landed_sound: bool = false
var _generation: int = 0
var _on_exit: Callable
var _exit_notified: bool = false
var _last_subtitle_key: String = ""

func _ready() -> void :
	_top_group.pivot_offset = _top_group.size * 0.5
	_bottom_group.pivot_offset = _bottom_group.size * 0.5

	_inner_layer.texture = _inner_viewport.get_texture()
	var inner_mat: ShaderMaterial = _inner_layer.material as ShaderMaterial
	if inner_mat != null:
		inner_mat.set_shader_parameter("tex_size", Vector2(_inner_viewport.size))
	_layout()
	get_viewport().size_changed.connect(_layout)
	hide_now()

func _layout() -> void :
	_stage.position = UiMetrics.viewport_size() * 0.5 + Vector2(0.0, -90.0)

	_stage.scale = Vector2.ONE * 1.05 * minf(1.0, (UiMetrics.viewport_size().x - 48.0) / 940.0)

func play(count: int, on_exit: Callable = Callable(), percentile: float = -1.0, personal_best: bool = false) -> void :
	hide_now()
	_on_exit = on_exit
	_exit_notified = false
	var picked: Dictionary = StreakCopy.pick_lines(count, percentile, personal_best, _last_subtitle_key)
	_last_subtitle_key = String(picked["key"])
	var lines: PackedStringArray = picked["lines"]
	var subtitle: String = lines[1] if lines.size() > 1 else ""
	for layer: CurveLabel in _top_layers:
		layer.text = lines[0]
	for layer: CurveLabel in _bottom_layers:
		layer.text = subtitle
	_bottom_group.visible = not subtitle.is_empty()
	_title_y = TITLE_Y if not subtitle.is_empty() else TITLE_Y + 50.0
	_top_group.position.y = _title_y
	_elapsed = 0.0
	_landed_sound = false
	_playing = true
	visible = true
	_prepare_particle_randomness()
	_sample(0.0)
	var generation: int = _generation
	while _playing and generation == _generation:
		await get_tree().process_frame

func _prepare_particle_randomness() -> void :
	var particle_count: int = _particles.get_child_count()
	_particle_direction_offsets.resize(particle_count)
	_particle_speed_factors.resize(particle_count)
	_particle_rotation_offsets.resize(particle_count)
	_particle_spin_factors.resize(particle_count)
	for particle_index: int in particle_count:
		_particle_direction_offsets[particle_index] = deg_to_rad(randf_range( - PARTICLE_DIRECTION_SPREAD, PARTICLE_DIRECTION_SPREAD))
		_particle_speed_factors[particle_index] = randf_range(1.0 - PARTICLE_SPEED_RANDOMNESS, 1.0 + PARTICLE_SPEED_RANDOMNESS)
		_particle_rotation_offsets[particle_index] = deg_to_rad(randf_range( - PARTICLE_INITIAL_ROTATION_SPREAD, PARTICLE_INITIAL_ROTATION_SPREAD))
		_particle_spin_factors[particle_index] = randf_range(1.0 - PARTICLE_SPIN_RANDOMNESS, 1.0 + PARTICLE_SPIN_RANDOMNESS)

func hide_now() -> void :
	_generation += 1
	_playing = false
	_on_exit = Callable()
	visible = false
	_backdrop.color.a = 0.0
	if _landed_sound:
		AudioManager.stop_sfx(&"streak_celebration")
	_landed_sound = false
	for bone: Bone2D in _bones:
		bone.rotation = 0.0
		bone.scale = Vector2.ONE

func _process(delta: float) -> void :
	if not _playing:
		return
	_elapsed += delta * maxf(0.05, playback_speed)
	if _elapsed >= EXIT_START and not _exit_notified:
		_exit_notified = true
		if _on_exit.is_valid():
			_on_exit.call()
		if not _playing:
			return
	if _elapsed >= 0.36 and not _landed_sound:
		_landed_sound = true
		AudioManager.play_sfx(&"streak_celebration")
	_sample(minf(_elapsed, DURATION))
	_sync_gradient_uv()
	if _elapsed >= DURATION:
		_playing = false
		visible = false

func _sample(t: float) -> void :
	var exit: float = _smooth((t - EXIT_START) / (DURATION - EXIT_START))
	_backdrop.color.a = BACKDROP_ALPHA * _smooth(t / 0.12) * (1.0 - exit)
	_stage.modulate.a = 1.0 - exit

	_words.self_modulate.a = 1.0 - _smooth((t - EXIT_START) / WORD_EXIT_DURATION)

	var cup_scale: float = _keys(t, [0.06, 0.25, 0.38, 0.43, 0.51, 0.6], [0.75, 1.06, 1.0, 1.0, 1.025, 1.0])
	var press: float = sin(clampf((t - 0.36) / 0.11, 0.0, 1.0) * PI)
	_trophy.position = Vector2(0.0, 255.0 + 40.0 * (1.0 - _smooth((t - 0.06) / 0.32)) - exit * 24.0)
	_trophy.scale = Vector2(cup_scale * (1.0 + press * 0.02), cup_scale * (1.0 - press * 0.03)) * (1.0 - exit * 0.08)
	_trophy.rotation = deg_to_rad(_keys(t, [0.06, 0.3, 0.43, 0.6], [-3.0, 1.5, -0.6, 0.0]))
	_trophy.modulate.a = _smooth((t - 0.06) / 0.1)
	for i: int in _bones.size():
		var age: float = maxf(0.0, t - BONE_DELAYS[i])
		var reveal: float = _smooth(age / 0.16)
		var overshoot: float = sin(clampf(age / 0.28, 0.0, 1.0) * PI) * 0.08
		_bones[i].scale = Vector2.ONE * (lerpf(0.88, 1.0, reveal) + overshoot)
		_bones[i].rotation = deg_to_rad(BONE_ANGLES[i] * exp( - age * 6.0) * cos(age * 19.0) + sin(t * 2.8 + float(i) * 1.9) * 1.2 * _smooth((t - 0.65) / 0.3))
		_bones[i].modulate.a = reveal
	_word(_top_group, t, 0.3, _title_y)
	_word(_bottom_group, t, 0.37, SUBTITLE_Y)
	_glow.modulate.a = _smooth(t / 0.12) * (0.75 + 0.2 * exp( - pow((t - 0.4) / 0.1, 2.0)))
	_glow_inner.modulate.a = _glow.modulate.a * 0.85
	_radial.rotation = t * TAU / 12.0
	_radial.modulate.a = _smooth(t / 0.18) * 0.8

	_cloud.modulate.a = _smooth((t - 0.1) / 0.22)
	_foot_glow.modulate.a = _smooth((t - 0.18) / 0.2) * 0.7
	for i: int in _particles.get_child_count():
		var particle: Sprite2D = _particles.get_child(i) as Sprite2D
		var is_star: bool = i < STAR_COUNT

		var wave: int = i / 8 if is_star else (i - STAR_COUNT) / 4
		var slot: int = i % 8 if is_star else 8 + (i - STAR_COUNT) % 4
		var start: float = 0.09 + float(wave) * 0.3 + float(slot) * 0.014
		var age: float = t - start
		var life: float = 1.0 + float(slot % 3) * 0.09 if is_star else 1.35
		var p: float = clampf(age / life, 0.0, 1.0)
		var side: float = -1.0 if slot % 2 == 0 else 1.0
		var lane: int = slot / 2 if is_star else 1 + (slot - 8) / 2
		var angle: float = deg_to_rad(-68.0 + float(lane) * 27.0 + float(wave) * 7.0) + _particle_direction_offsets[i]
		var travel: float = (155.0 + float(slot % 3) * 28.0) * _particle_speed_factors[i] * 1.3
		var burst: float = 1.0 - pow(1.0 - p, 3.0)
		var origin: Vector2 = Vector2(side * (225.0 + float(wave) * 18.0), -285.0 + float(lane) * 75.0) * 0.5 + Vector2(0.0, -15.0)
		var outward: Vector2 = Vector2(side * cos(angle), sin(angle)) * travel * burst

		var drift: float = p * p * (38.0 if is_star else 85.0)
		particle.position = origin + outward + Vector2(0.0, drift)
		particle.rotation = side * float(slot) * 0.24 + _particle_rotation_offsets[i] + side * p * (2.8 if is_star else 4.2) * _particle_spin_factors[i]
		var width: float = (42.0 + float(slot % 4) * 8.0) * 0.5 if is_star else (82.0 + float(slot % 3) * 12.0) * 0.7
		var pop: float = _keys(age, [0.0, 0.07, 0.17], [0.35, 1.22, 1.0])
		var shrink: float = 1.0 - _smooth((p - 0.65) / 0.35) * 0.38
		particle.scale = Vector2.ONE * width / float(particle.texture.get_width()) * pop * shrink
		particle.modulate.a = _smooth(age / 0.045) * (1.0 - _smooth((p - 0.6) / 0.4)) if age >= 0.0 else 0.0


func _word(target: Control, t: float, start: float, y: float) -> void :
	var age: float = t - start
	var s: float = _keys(age, [0.0, 0.12, 0.22], [0.9, 1.05, 1.0])
	target.scale = Vector2.ONE * s
	target.position.y = y + 12.0 * (1.0 - _smooth(age / 0.18))
	target.modulate.a = _smooth(age / 0.1)




func _sync_gradient_uv() -> void :
	var viewport_h: float = maxf(get_viewport_rect().size.y, 1.0)
	_apply_gradient_uv(_top_text, viewport_h, TOP_INK_Y_RANGE)
	_apply_gradient_uv(_bottom_text, viewport_h, BOTTOM_INK_Y_RANGE)



func _apply_gradient_uv(label: CurveLabel, viewport_h: float, ink_y_range: Vector2) -> void :
	var mat: ShaderMaterial = label.material as ShaderMaterial
	if mat == null:
		return
	var rect_top: float = label.get_global_rect().position.y
	mat.set_shader_parameter("ink_top_uv", 
		(rect_top + ink_y_range.x) / viewport_h)
	mat.set_shader_parameter("ink_bottom_uv", 
		(rect_top + ink_y_range.y) / viewport_h)

func _smooth(value: float) -> float:
	var p: float = clampf(value, 0.0, 1.0)
	return p * p * (3.0 - 2.0 * p)

func _keys(t: float, times: Array[float], values: Array[float]) -> float:
	if t <= float(times[0]):
		return float(values[0])
	for i: int in range(1, times.size()):
		if t <= float(times[i]):
			return lerpf(float(values[i - 1]), float(values[i]), _smooth((t - float(times[i - 1])) / (float(times[i]) - float(times[i - 1]))))
	return float(values[-1])


func _exit_tree() -> void :
	_playing = false
	if _landed_sound:
		AudioManager.stop_sfx(&"streak_celebration")
