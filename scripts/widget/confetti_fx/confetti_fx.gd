class_name ConfettiFx
extends Node2D


const SOURCE_TEX: Texture2D = preload("res://assets/sprites/common_rank_et_ribbon_007.png")

const PARTICLES_PER_EMITTER: int = 8
const LIFETIME: float = 2.5
const EXPLOSIVENESS: float = 0.0

var _emitters: Array[CPUParticles2D] = []
var _fade_tween: Tween = null


func _ready() -> void :
	visible = false
	_build_emitters()


func _build_emitters() -> void :
	var src: Texture2D = SOURCE_TEX
	var w: int = src.get_width()
	var h: int = src.get_height()
	var qw: int = w / 2
	var qh: int = h / 2
	var regions: Array[Rect2] = [
		Rect2(0, 0, qw, qh), 
		Rect2(qw, 0, qw, qh), 
		Rect2(0, qh, qw, qh), 
		Rect2(qw, qh, qw, qh), 
	]
	for r in regions:
		var atlas: = AtlasTexture.new()
		atlas.atlas = src
		atlas.region = r
		var p: = CPUParticles2D.new()
		p.texture = atlas
		p.amount = PARTICLES_PER_EMITTER
		p.lifetime = LIFETIME
		p.one_shot = false
		p.explosiveness = EXPLOSIVENESS
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.direction = Vector2(0, 1)
		p.spread = 30.0
		p.gravity = Vector2(0, 190.0)
		p.initial_velocity_min = 22.5
		p.initial_velocity_max = 55.0
		p.angular_velocity_min = -240.0
		p.angular_velocity_max = 240.0
		p.scale_amount_min = 0.5
		p.scale_amount_max = 2.0
		p.damping_min = 0.4
		p.damping_max = 1.4
		var grad: = Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.08, 0.8, 1.0])
		grad.colors = PackedColorArray([
			Color(1, 1, 1, 0), 
			Color(1, 1, 1, 1), 
			Color(1, 1, 1, 1), 
			Color(1, 1, 1, 0), 
		])
		p.color_ramp = grad
		p.emitting = false
		add_child(p)
		_emitters.append(p)


func reset() -> void :
	_kill_fade_tween()
	modulate.a = 1.0
	visible = false
	for p in _emitters:
		p.emitting = false
		p.amount = p.amount


func play() -> void :
	reset()
	visible = true
	modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 1.0, 0.4)
	var vp: Vector2 = UiMetrics.viewport_size()
	for p in _emitters:
		p.global_position = Vector2(vp.x * 0.5, -200.0)
		p.emission_rect_extents = Vector2(vp.x * 0.5, 30.0)
		p.emitting = true


func fade_out(dur: float = 0.3) -> void :
	if not visible:
		return
	_kill_fade_tween()
	for p in _emitters:
		p.emitting = false
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, dur)
	_fade_tween.tween_callback( func() -> void : visible = false)


func _kill_fade_tween() -> void :
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null
