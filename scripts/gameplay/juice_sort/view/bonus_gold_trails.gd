class_name BonusGoldTrails
extends FireworkTrails



func _emit_ribbon(r: Ribbon) -> void :
	var original_width: float = r.head_width
	var width: float = original_width * 0.65
	var color: Color = r.rgb
	var alpha: float = r.head_alpha
	r.head_width = width * SpiralLightFx.TRAIL_GLOW_RATIO
	r.rgb = SpiralLightFx.GOLD
	r.head_alpha = alpha * SpiralLightFx.TRAIL_GLOW_ALPHA * 0.55
	super._emit_ribbon(r)
	r.head_width = width
	r.head_alpha = alpha
	super._emit_ribbon(r)
	r.head_width = width * SpiralLightFx.TRAIL_CORE_RATIO
	r.rgb = SpiralLightFx.CORE
	super._emit_ribbon(r)
	r.head_width = original_width
	r.rgb = color
	r.head_alpha = alpha


const DUST_TEXTURE: Texture2D = preload("res://assets/effect/texture/point/ef_point_004.png")
var _dust_emitters: Array[CPUParticles2D] = []
var _dust_targets: Array[Node2D] = []

func _ready() -> void :
	super._ready()
	var material: = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var fade: = Gradient.new()
	fade.colors = PackedColorArray([Color(1, 0.9529, 0.7, 0.75), Color(1, 0.9529, 0.7, 0)])
	for i: int in range(6):
		var dust: = CPUParticles2D.new()
		dust.texture = DUST_TEXTURE
		dust.material = material
		dust.emitting = false
		dust.amount = 6
		dust.lifetime = 0.18
		dust.local_coords = false
		dust.gravity = Vector2.ZERO
		dust.initial_velocity_min = 0.0
		dust.initial_velocity_max = 8.0
		dust.spread = 180.0
		dust.scale_amount_min = 22.0 / 128.0
		dust.scale_amount_max = 32.0 / 128.0
		dust.color_ramp = fade
		add_child(dust)
		_dust_emitters.append(dust)
		_dust_targets.append(null)

func _process(delta: float) -> void :
	super._process(delta)
	update_dust_targets()

func update_dust_targets() -> void :
	for i: int in range(_dust_emitters.size()):
		var target: Node2D = _dust_targets[i]
		var following: bool = false
		for ribbon: Ribbon in _ribbons:
			if is_instance_valid(target) and target.visible and ribbon.target == target and ribbon.head_alpha > 0.08:
				following = true
		_dust_emitters[i].emitting = following
		if following:
			_dust_emitters[i].global_position = target.global_position
		elif not _dust_emitters[i].emitting:
			_dust_targets[i] = null

func add_ribbon(target: Node2D, head_width: float, rgb: Color, head_alpha: float, lifetime: float) -> Ribbon:
	for i: int in range(_dust_targets.size()):
		if _dust_targets[i] == null:
			_dust_targets[i] = target
			_dust_emitters[i].global_position = target.global_position
			_dust_emitters[i].emitting = true
			break
	return super.add_ribbon(target, head_width, rgb, head_alpha, lifetime)

func clear_all() -> void :
	super.clear_all()
	for i: int in range(_dust_emitters.size()):
		_dust_emitters[i].emitting = false
		_dust_emitters[i].amount = _dust_emitters[i].amount
		_dust_targets[i] = null


func absorb_into_slot(ribbon: Ribbon, progress: float, initial_alpha: float) -> void :
	if ribbon == null:
		return
	var t: float = clampf(progress, 0.0, 1.0)
	ribbon.head_alpha = initial_alpha * (1.0 - t)
	ribbon.lifetime = lerpf(0.16, 0.025, t)
	if t > 0.25:
		_stop_target_dust(ribbon.target)
	if t >= 1.0:
		ribbon.reset()
		_rebuild()

func _stop_target_dust(target: Node2D) -> void :
	for i: int in range(_dust_targets.size()):
		if target != null and _dust_targets[i] == target:
			_dust_emitters[i].emitting = false
			_dust_emitters[i].amount = _dust_emitters[i].amount
			_dust_targets[i] = null
