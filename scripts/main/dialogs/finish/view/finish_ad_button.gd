class_name FinishAdButton
extends CommonBtn

const APPEAR_DURATION: float = 0.25

const INITIAL_HOLD_DURATION: float = 0.15
const SPIN_UP_DURATION: float = 0.2
const CRUISE_DURATION: float = 1.25
const BRAKE_DURATION: float = 0.7
const REVEAL_RECOVER_DURATION: float = 0.23
const RESULT_HOLD_DURATION: float = 0.05
const SCROLL_START: float = APPEAR_DURATION + INITIAL_HOLD_DURATION
const SCROLL_DURATION: float = SPIN_UP_DURATION + CRUISE_DURATION + BRAKE_DURATION
const RECOVER_END: float = SCROLL_START + SCROLL_DURATION
const ROLL_DURATION: float = RECOVER_END + RESULT_HOLD_DURATION
const ROW_HEIGHT: float = 132.0
const ROLL_ROWS: int = 9

const PREVIEW_ORDER: Array[int] = [0, 1, 3, 6, 9, 2, 4, 7, 10]

const SCROLL_SPEED: float = ROLL_ROWS / (SPIN_UP_DURATION * 0.5 + CRUISE_DURATION + BRAKE_DURATION * 0.5)

const BUTTON_PEAK_TIME: float = RECOVER_END - REVEAL_RECOVER_DURATION
const UPGRADE_DURATION: float = 0.12
const UPGRADE_START: float = BUTTON_PEAK_TIME - UPGRADE_DURATION
const BUTTON_INFLATE_START: float = BUTTON_PEAK_TIME - 0.16
const BUTTON_PEAK_SCALE: float = 1.2
const BADGE_APPEAR_START: float = UPGRADE_START
const BADGE_APPEAR_END: float = BADGE_APPEAR_START + 0.04
const BADGE_PEAK_TIME: float = BUTTON_PEAK_TIME
const BADGE_PEAK_SCALE: float = 2.0
const BADGE_RISE: float = 29.3
const BADGE_FLASH_START: float = BADGE_APPEAR_START
const BADGE_FLASH_HOLD_END: float = BUTTON_PEAK_TIME + 0.04
const BADGE_FLASH_END: float = RECOVER_END
const GLOW_START: float = 61.0 / 30.0
const BURST_START: float = BUTTON_PEAK_TIME
const GLOW_END: float = 2.5
const RAYS_SPIN_PERIOD: float = 24.0
const RAYS_FADE_DURATION: float = 0.3
const AD_ICON_REWARD_GAP: float = 26.0

@export var coin_icon: Texture2D
@export var undo_icon: Texture2D
@export var hint_icon: Texture2D
@export var rope_icon: Texture2D
@export var nice_badge: Texture2D
@export var great_badge: Texture2D
@export var lucky_badge: Texture2D
@export var great_face: Texture2D
@export var lucky_face: Texture2D
@export var nice_rays: Texture2D
@export var great_rays: Texture2D
@export var lucky_rays: Texture2D

@onready var _row_a: Control = $RewardClip / RowA
@onready var _row_b: Control = $RewardClip / RowB
@onready var _ad_icon: TextureRect = $AdIcon
@onready var _reward_clip: Control = $RewardClip
@onready var _tier_badge: TextureRect = $TierBadge
@onready var _outline: NinePatchRect = $Outline
@onready var _glow: TextureRect = $TierGlow
var _sparkles: GPUParticles2D
@onready var _rays: Sprite2D = $TierRays
@onready var _burst_glow: TextureRect = $TierBurstGlow
var _burst_stars: GPUParticles2D
@onready var _badge_base_y: float = _tier_badge.position.y
@onready var _badge_flash_material: ShaderMaterial = _tier_badge.material as ShaderMaterial

var _reward: Dictionary = {}
var _preview_rewards: Array[Dictionary] = []
var _roll_tween: Tween
var _settled: bool = false
var _claim_busy: bool = false
var _ad_available: bool = true
var _tier_style: String = ""
var _fx_tween: Tween
var _rays_spin_tween: Tween
var _rays_fade_tween: Tween
var _content_reward_width: float = 364.0
var _burst_started: bool = false
var _roll_sound_started: bool = false

func _ready() -> void :
	prepare_cached_dependencies()
	_sparkles = $TierSparkles
	_burst_stars = $TierBurstStars
	_tier_particles.prepare([_sparkles, _burst_stars], 2, func() -> bool: return is_visible_in_tree())
	super._ready()
	$Contents.hide()
	reset_reward()
	_layout_tier_effects()
	resized.connect(_layout_tier_effects)


func _exit_tree() -> void :
	_stop_roll_sound()



func warm_render_pipeline() -> void :
	visible = true
	modulate.a = 1.0
	await _start_tier_particles()
	_sparkles.request_particles_process(0.1)
	_burst_stars.request_particles_process(0.1)
	await RenderingServer.frame_post_draw
	reset_reward()



func _layout_tier_effects() -> void :
	_rays.position = Vector2(size.x * 0.5, -12.0)
	_sparkles.position = Vector2(size.x * 0.5, -36.0)
	_burst_stars.position = Vector2(size.x * 0.5, -12.0)
	_layout_reward_contents(_content_reward_width)



func _layout_reward_contents(reward_width: float) -> void :
	_content_reward_width = reward_width
	var total_width: float = _ad_icon.size.x + AD_ICON_REWARD_GAP + reward_width
	_ad_icon.position.x = (size.x - total_width) * 0.5
	_reward_clip.position.x = _ad_icon.position.x + _ad_icon.size.x + AD_ICON_REWARD_GAP

	_reward_clip.size.x = maxf(_row_a.size.x, _row_b.size.x)


func start_roll(reward: Dictionary) -> void :
	reset_reward()
	var available: Array[Dictionary] = FinishAdRewardTable.available_entries()
	for index: int in PREVIEW_ORDER:
		var entry: Dictionary = FinishAdRewardTable.ENTRIES[index]
		if available.has(entry):
			_preview_rewards.append(entry)
	_reward = reward.duplicate()
	_set_row(_row_a, _reward)
	_layout_reward_contents(_row_a.size.x)
	_tier_style = String(_reward["tier"])
	if _tier_style == "nice":
		_tier_style = "nice" if randi_range(0, 1) == 0 else "great"
	visible = true
	SceneManager.set_button_feedback_enabled(self, false)
	_prepare_tier_visuals()
	_set_presentation_time(0.0)
	_roll_tween = create_tween()
	_roll_tween.tween_method(_set_presentation_time, 0.0, ROLL_DURATION, ROLL_DURATION).set_trans(Tween.TRANS_LINEAR)
	_roll_tween.tween_callback(_finish_roll)



func _set_presentation_time(elapsed: float) -> void :

	if elapsed >= SCROLL_START and elapsed < RECOVER_END\
	and not _roll_sound_started and _roll_tween != null:
		_roll_sound_started = true
		AudioManager.play_sfx(&"finish_ad_reward_btn")
	modulate.a = smoothstep(0.0, APPEAR_DURATION, elapsed)
	pivot_offset = size * 0.5
	_tier_badge.pivot_offset = _tier_badge.size * 0.5
	var upgrade: float = _reveal_attack(UPGRADE_START, UPGRADE_START + UPGRADE_DURATION, elapsed)
	var inflate: float = _reveal_attack(BUTTON_INFLATE_START, BUTTON_PEAK_TIME, elapsed)
	var recover: float = _reveal_recover(BUTTON_PEAK_TIME, RECOVER_END, elapsed)
	_tex.modulate.a = upgrade
	_outline.modulate.a = 1.0 - upgrade
	scale = Vector2.ONE * lerpf(1.0, BUTTON_PEAK_SCALE, inflate * (1.0 - recover))
	var badge_grow: float = _reveal_attack(BADGE_APPEAR_START, BADGE_PEAK_TIME, elapsed)
	var badge_scale: float = lerpf(1.0, 0.91, smoothstep(0.0, BADGE_APPEAR_START, elapsed))
	badge_scale = lerpf(badge_scale, BADGE_PEAK_SCALE, badge_grow)
	badge_scale = lerpf(badge_scale, 1.0, recover)

	_tier_badge.scale = Vector2.ONE * badge_scale / scale.x
	var badge_center_y: float = _badge_base_y + _tier_badge.size.y * 0.5
	var rise: float = BADGE_RISE * badge_grow * (1.0 - recover)
	_tier_badge.position.y = pivot_offset.y + (badge_center_y - rise - pivot_offset.y) / scale.y - _tier_badge.size.y * 0.5
	_tier_badge.modulate.a = _reveal_attack(BADGE_APPEAR_START, BADGE_APPEAR_END, elapsed)
	_set_reveal_effects(elapsed)
	_set_scroll_position(_scroll_rows_at(elapsed))


func _set_reveal_effects(elapsed: float) -> void :
	if _tier_style == "normal":
		return
	var flash: float = _reveal_attack(BADGE_FLASH_START, BUTTON_PEAK_TIME, elapsed)
	flash *= 1.0 - smoothstep(BADGE_FLASH_HOLD_END, BADGE_FLASH_END, elapsed)
	_badge_flash_material.set_shader_parameter("flash_strength", flash * 0.604)
	_burst_glow.visible = elapsed >= GLOW_START and elapsed < GLOW_END
	var expand: float = smoothstep(GLOW_START, BURST_START, elapsed)
	var fade: float = smoothstep(BURST_START, GLOW_END, elapsed)
	_burst_glow.scale = Vector2.ONE * lerpf(lerpf(0.2, 1.45, expand), 1.99, fade)
	_burst_glow.modulate.a = expand * (1.0 - fade)
	if elapsed >= BURST_START and not _burst_started:
		_burst_started = true
		_start_tier_particles()



var _tier_particles: = GpuParticleLifecycle.new()
var _particle_dependencies_injected: bool = false


func prepare_cached_dependencies() -> void :
	if _particle_dependencies_injected:
		return
	FinishParticleCache.inject("ad", self, ["TierSparkles", "TierBurstStars"])
	_particle_dependencies_injected = true


func _start_tier_particles() -> void :
	_tier_particles.play()



static func _reveal_attack(start: float, end: float, elapsed: float) -> float:
	var progress: float = clampf((elapsed - start) / (end - start), 0.0, 1.0)
	return 1.0 - pow(1.0 - progress, 3.0)



static func _reveal_recover(start: float, end: float, elapsed: float) -> float:
	var progress: float = clampf((elapsed - start) / (end - start), 0.0, 1.0)
	return (1.0 - cos(progress * PI)) * 0.5


func _scroll_rows_at(elapsed: float) -> float:
	if elapsed >= RECOVER_END:
		return float(ROLL_ROWS)
	var time: float = clampf(elapsed - SCROLL_START, 0.0, SCROLL_DURATION)
	if time < SPIN_UP_DURATION:
		return SCROLL_SPEED * time * time / (2.0 * SPIN_UP_DURATION)
	var first_rows: float = SCROLL_SPEED * SPIN_UP_DURATION * 0.5
	if time < SPIN_UP_DURATION + CRUISE_DURATION:
		return first_rows + SCROLL_SPEED * (time - SPIN_UP_DURATION)
	var brake_time: float = time - SPIN_UP_DURATION - CRUISE_DURATION
	return minf(float(ROLL_ROWS), first_rows + SCROLL_SPEED * CRUISE_DURATION
		+ SCROLL_SPEED * (brake_time - brake_time * brake_time / (2.0 * BRAKE_DURATION)))


func _prepare_tier_visuals() -> void :
	var tint: Color = Color(0.35, 0.75, 1.0)
	match _tier_style:
		"nice":
			_tier_badge.texture = nice_badge
			_rays.texture = nice_rays
			_rays.self_modulate = Color(1, 1, 1, 0.7)
		"great":
			_tier_badge.texture = great_badge
			_rays.texture = great_rays
			_rays.self_modulate = Color.WHITE
			face_override = great_face
			tint = Color(0.9, 0.35, 1.0)
		"lucky":
			_tier_badge.texture = lucky_badge
			_rays.texture = lucky_rays
			_rays.self_modulate = Color.WHITE
			face_override = lucky_face
			tint = Color(1.0, 0.8, 0.25)
	_tier_badge.visible = _tier_style != "normal"
	_glow.self_modulate = tint
	_sparkles.modulate = tint
	_burst_glow.self_modulate = tint
	_burst_stars.modulate = tint


func _set_scroll_position(value: float) -> void :

	if value >= float(ROLL_ROWS):
		_set_row(_row_a, _reward)
		_row_a.position.y = 0.0
		_set_row_depth(_row_a, 1.0)
		_row_b.hide()
		_reward_clip.size.x = _row_a.size.x
		return
	_row_b.show()
	var row_index: int = int(floor(value))
	var offset: float = (value - float(row_index)) * ROW_HEIGHT
	_set_row(_row_a, _visual_reward(row_index))
	_set_row(_row_b, _visual_reward(row_index + 1))
	_row_a.position.y = - offset
	_row_b.position.y = ROW_HEIGHT - offset
	var progress: float = value - float(row_index)
	_reward_clip.size.x = maxf(_row_a.size.x, _row_b.size.x)
	_set_row_depth(_row_a, 1.0 - progress)
	_set_row_depth(_row_b, progress)


func _set_row_depth(row: Control, center_weight: float) -> void :
	row.pivot_offset = row.size * 0.5
	row.scale.y = lerpf(0.84, 1.0, center_weight)
	row.modulate.a = lerpf(0.35, 1.0, center_weight)

func _visual_reward(row_index: int) -> Dictionary:
	if row_index >= ROLL_ROWS:
		return _reward
	return _preview_rewards[row_index % _preview_rewards.size()]

func _set_row(row: Control, reward: Dictionary) -> void :
	var icon: Texture2D = coin_icon
	match String(reward["kind"]):
		"undo": icon = undo_icon
		"hint": icon = hint_icon
		"rope": icon = rope_icon
	(row.get_node("Icon") as TextureRect).texture = icon
	var count: Label = row.get_node("Count") as Label
	count.text = "x%d" % int(reward["count"])
	count.size.x = count.get_minimum_size().x
	row.size.x = count.position.x + count.size.x

func _finish_roll() -> void :
	_roll_tween = null
	_set_presentation_time(ROLL_DURATION)
	_settled = true
	_refresh_click_state()
	SceneManager.set_button_feedback_enabled(self, true)
	if _tier_style != "normal":
		_rays.show()
		_rays_spin_tween = create_tween().set_loops()
		_rays_spin_tween.tween_property(_rays, "rotation", TAU, RAYS_SPIN_PERIOD).from(0.0).set_trans(Tween.TRANS_LINEAR)
		_rays_fade_tween = create_tween()
		_rays_fade_tween.tween_property(_rays, "modulate:a", 1.0, RAYS_FADE_DURATION).set_trans(Tween.TRANS_SINE)
		_glow.show()
		_fx_tween = create_tween().set_loops()
		_fx_tween.tween_property(_glow, "modulate:a", 0.55, 0.5).set_trans(Tween.TRANS_SINE)
		_fx_tween.tween_property(_glow, "modulate:a", 0.3, 0.75).set_trans(Tween.TRANS_SINE)


func get_settled_reward() -> Dictionary:
	return _reward.duplicate() if _settled else {}

func set_claim_busy(busy: bool) -> void :
	if busy:
		_stop_roll_sound()
	_claim_busy = busy
	_refresh_click_state()


func set_ad_available(available: bool) -> void :
	_ad_available = available
	_refresh_click_state()



func _refresh_click_state() -> void :
	disabled = _claim_busy or not _settled or not _ad_available
	CommonBtn.apply_disabled_gray(self, not _ad_available)
	CommonBtn.apply_disabled_gray(_ad_icon, not _ad_available)
	for row: Control in [_row_a, _row_b]:
		for child: CanvasItem in row.get_children():
			CommonBtn.apply_disabled_gray(child, not _ad_available)

func cancel_roll() -> void :
	_stop_roll_sound()
	if _roll_tween != null and _roll_tween.is_valid():
		_roll_tween.kill()
	_roll_tween = null
	_reward.clear()
	_preview_rewards.clear()
	_settled = false
	_claim_busy = false
	_ad_available = true
	_refresh_click_state()
	_tier_style = ""
	_tier_badge.hide()
	_tier_badge.texture = null
	_tier_badge.scale = Vector2.ONE
	_tier_badge.position.y = _badge_base_y
	_tier_badge.modulate.a = 0.0
	_badge_flash_material.set_shader_parameter("flash_strength", 0.0)
	_burst_started = false
	_burst_glow.hide()
	_burst_glow.scale = Vector2.ONE
	_burst_glow.modulate.a = 0.0
	_tier_particles.reset_immediate()
	face_override = null
	_tex.modulate.a = 0.0
	_outline.modulate.a = 1.0
	if _fx_tween != null and _fx_tween.is_valid():
		_fx_tween.kill()
	_fx_tween = null
	if _rays_spin_tween != null and _rays_spin_tween.is_valid():
		_rays_spin_tween.kill()
	if _rays_fade_tween != null and _rays_fade_tween.is_valid():
		_rays_fade_tween.kill()
	_rays_spin_tween = null
	_rays_fade_tween = null
	_rays.hide()
	_rays.rotation = 0.0
	_rays.modulate.a = 0.0
	_rays.self_modulate = Color.WHITE
	_rays.texture = null
	_glow.hide()
	_glow.modulate.a = 0.0

	_tier_particles.reset_immediate()
	SceneManager.reset_button_feedback(self)
	SceneManager.set_button_feedback_enabled(self, true)


func _stop_roll_sound() -> void :
	if not _roll_sound_started:
		return
	AudioManager.stop_sfx(&"finish_ad_reward_btn")
	_roll_sound_started = false


func reset_reward() -> void :
	cancel_roll()
	visible = false
	_row_a.position.y = 0.0
	_row_b.position.y = ROW_HEIGHT
	_row_b.show()
	_set_row_depth(_row_a, 1.0)
	_set_row_depth(_row_b, 1.0)
