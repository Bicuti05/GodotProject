class_name BonusPigIdleFx
extends Node2D


@export var shine_shader: Shader
@export var point_texture: Texture2D
@export var star_texture: Texture2D
var _target: JuiceBlender
var _board: JuiceBoardView
var _material: ShaderMaterial
var _motes: CPUParticles2D
var _star: CPUParticles2D
var _clock: float = 0.0
var _star_beat: int = -1
var _active: bool = false
var _background: bool = false

func _ready() -> void :
	_material = ShaderMaterial.new()
	_material.shader = shine_shader
	_material.set_shader_parameter("intensity", 0.1)
	_material.set_shader_parameter("band_width", 0.14)
	var additive: = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var fade: = Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.15, 0.6, 1.0])
	fade.colors = PackedColorArray([Color(1, 0.9529, 0.7, 0), Color(1, 0.9529, 0.7, 0.75), Color(1, 0.9529, 0.7, 0.5), Color(1, 0.9529, 0.7, 0)])
	_motes = CPUParticles2D.new()
	_motes.texture = point_texture
	_motes.material = additive
	_motes.amount = 4
	_motes.lifetime = 2.0
	_motes.preprocess = 1.2
	_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
	_motes.emission_points = PackedVector2Array([Vector2(-55, 30), Vector2(55, 30)])
	_motes.direction = Vector2(0, -1)
	_motes.spread = 10.0
	_motes.gravity = Vector2.ZERO
	_motes.initial_velocity_min = 24.0
	_motes.initial_velocity_max = 40.0
	_motes.scale_amount_min = 0.14
	_motes.scale_amount_max = 0.2
	_motes.color_ramp = fade
	_motes.emitting = false
	add_child(_motes)
	_star = CPUParticles2D.new()
	_star.texture = star_texture
	_star.material = additive
	_star.amount = 1
	_star.one_shot = true
	_star.explosiveness = 1.0
	_star.lifetime = 0.5
	_star.gravity = Vector2.ZERO
	_star.initial_velocity_min = 0.0
	_star.initial_velocity_max = 0.0
	_star.scale_amount_min = 0.24
	_star.scale_amount_max = 0.34
	_star.color_ramp = fade
	_star.emitting = false
	add_child(_star)
	stop()

func bind_target(board: JuiceBoardView, target: JuiceBlender) -> void :
	if _target == target and _board == board:
		return
	stop()
	_board = board
	_target = target
	_clock = 0.0
	_star_beat = -1

func stop() -> void :
	if is_instance_valid(_target):
		var body: Sprite2D = _target.get_node("Body") as Sprite2D
		if body.material == _material:
			body.material = null
	_material.set_shader_parameter("progress", 0.0)
	for particle: CPUParticles2D in [_motes, _star]:
		particle.emitting = false
		particle.amount = particle.amount
	_active = false
	hide()

func _process(delta: float) -> void :
	if _background or not is_instance_valid(_target) or not is_instance_valid(_board)\
	or not _target.is_visible_in_tree() or not _board.is_visible_in_tree()\
	or _target.want_type != _board.bonus_type() or _board.bonus_type() < 0\
	or _board.is_busy() or not _board.get("_blender_nodes").values().has(_target):
		if _active:
			stop()
		return
	var body: Sprite2D = _target.get_node("Body") as Sprite2D

	if body.material != null and body.material != _material:
		if _active:
			stop()
		return
	var rect: Rect2 = body.get_global_transform() * body.get_rect()
	global_position = rect.get_center()
	var factor: float = rect.size.x / 180.0
	_motes.emission_points = PackedVector2Array([Vector2( - rect.size.x * 0.36, rect.size.y * 0.25), Vector2(rect.size.x * 0.36, rect.size.y * 0.25)])
	_motes.initial_velocity_min = 24.0 * factor
	_motes.initial_velocity_max = 40.0 * factor
	_motes.scale_amount_min = 0.14 * factor
	_motes.scale_amount_max = 0.2 * factor
	if not _active:
		_active = true
		_clock = 0.0
		_star_beat = -1
		body.material = _material
		_motes.restart()
		_motes.emitting = true
		show()
	_clock += delta
	var phase: float = fposmod(_clock, 4.8)
	_material.set_shader_parameter("progress", clampf((phase - 0.3) / 0.9, 0.0, 1.0))
	var beat: int = floori(_clock / 4.8)
	if phase >= 1.55 and _star_beat != beat:
		_star_beat = beat
		_star.position = Vector2(rect.size.x * (0.31 if beat % 2 == 0 else -0.31), - rect.size.y * 0.32)
		_star.scale_amount_min = 0.24 * factor
		_star.scale_amount_max = 0.34 * factor
		_star.restart()
		_star.emitting = true

func _notification(what: int) -> void :
	if is_node_ready() and (what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED):
		_background = true
		stop()
	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		_background = false

func _exit_tree() -> void :
	if _material != null:
		stop()
