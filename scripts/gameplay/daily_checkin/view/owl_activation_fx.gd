extends Node2D
signal expression_swap_requested
signal slam_landed
signal activation_settled
const SLAM_AT: = 0.5
var _slam_pending: = false
const EXPRESSION_SWAP_AT: = 0.65
var expression_swapped: = false
var _swap_pending: = false


const PARTICLE_SCENE = preload("res://scripts/gameplay/daily_checkin/view/checkin_activation_particle.tscn")
@export var expand_texture: Texture2D
@export var star_texture: Texture2D
@export var soft_star_texture: Texture2D
@export var dot_texture: Texture2D
@export var noise_texture: Texture2D
const RIM_SHADER = preload("res://assets/shaders/daily_checkin/pics_subject_rim.gdshader")
const FLASH_SHADER = preload("res://assets/shaders/daily_checkin/owl_local_flash.gdshader")
const REVEAL_SHADER = preload("res://assets/shaders/daily_checkin/owl_reveal.gdshader")
var particle_curves: Dictionary
var native_rays: Node2D
var curves: Dictionary
var playing: = false
var paused: = false
var clock: = 0.0
var width: = 618.0
var halos: Array[Sprite2D] = []
var particles: Array[Dictionary] = []
var _particle_pool: Array[Sprite2D] = []
var hero_rig: Node2D
var stage_rig: Node2D
var halo_anchor: = Transform2D.IDENTITY
var rim: Sprite2D
var rim_material: ShaderMaterial
var flash: Sprite2D
var colored: Sprite2D
var old_expression: Sprite2D
var base_expression: Sprite2D
var reveal_material: ShaderMaterial
var flash_material: ShaderMaterial
var events: Array[Dictionary] = []
var rng: = RandomNumberGenerator.new()

func _ready() -> void :
	particle_curves = JSON.parse_string(FileAccess.get_file_as_string("res://assets/effect/owl_activation/particle_curves.json"))
	curves = JSON.parse_string(FileAccess.get_file_as_string("res://assets/effect/owl_activation/native_curves.json"))
	halos = [$Halo0, $Halo1, $Halo2, $Halo3]
	native_rays = $OriginalUnityParticleTrails
	rng.seed = 81732
	reset()

func bind_expression(target: Sprite2D) -> void :
	base_expression = target
	hero_rig = target.get_parent()
	stage_rig = hero_rig.get_parent()
	old_expression = $PreviousExpressionUnderDissolve
	old_expression.name = "PreviousExpressionUnderDissolve"
	colored = $PicsAlphaNoiseColorReveal
	colored.name = "PicsAlphaNoiseColorReveal"
	reveal_material = ShaderMaterial.new()
	reveal_material.shader = REVEAL_SHADER
	reveal_material.set_shader_parameter("noise_texture", noise_texture)
	colored.material = reveal_material
	colored.z_index = 3
	rim = $SubjectHuggingGlow
	rim.name = "SubjectHuggingGlow"
	rim_material = ShaderMaterial.new()
	rim_material.shader = RIM_SHADER
	rim.material = rim_material
	rim.z_index = 2
	flash = $AnticipationFlash
	flash.name = "SubjectMaskedLocalFlash"
	flash_material = ShaderMaterial.new()
	flash_material.shader = FLASH_SHADER
	flash.material = flash_material
	flash.z_index = 4

func begin_reveal() -> void :
	reset()
	clock = 0.0
	playing = true
	show()
	halo_anchor = Transform2D(stage_rig.global_transform.x, stage_rig.global_transform.y, hero_rig.global_position)
	old_expression.texture = base_expression.texture
	old_expression.position = base_expression.position
	old_expression.scale = base_expression.scale
	old_expression.hide()
	base_expression.show()
	_swap_pending = true
	_slam_pending = true
	expression_swapped = false

	for halo in halos:
		halo.global_transform = halo_anchor
		halo.modulate.a = 0.0
	sample(0.0)
	for halo in halos: halo.show()
	colored.hide()

	flash.texture = base_expression.texture
	flash.position = base_expression.position
	flash.scale = base_expression.scale
	flash_material.set_shader_parameter("strength", 0.0)
	flash.show()
	rim.texture = base_expression.texture
	rim.position = base_expression.position
	rim.scale = base_expression.scale
	rim_material.set_shader_parameter("subject_texture", base_expression.texture)
	rim_material.set_shader_parameter("strength", 0.0)
	rim.show()
	events = []

	native_rays.begin(width, stage_rig.global_transform)

	events.append({"time": 0.55, "count": 1, "kind": "kuosan"})
	events.append({"time": 0.55, "count": 1, "kind": "kuosan2"})


func swap_expression() -> void :
	expression_swapped = true
	_swap_pending = false
	old_expression.hide()
	colored.texture = base_expression.texture
	colored.position = base_expression.position
	colored.scale = base_expression.scale
	rim.texture = base_expression.texture
	rim.position = base_expression.position
	rim.scale = base_expression.scale
	rim_material.set_shader_parameter("subject_texture", base_expression.texture)
	rim.show()
	flash.texture = base_expression.texture
	flash.position = base_expression.position
	flash.scale = base_expression.scale
	reveal_material.set_shader_parameter("noise_aspect", Vector2(1.0, 0.95))
	reveal_material.set_shader_parameter("transition", 0.0)
	reveal_material.set_shader_parameter("reveal_alpha", 1.0)
	colored.show()
	flash.show()
	base_expression.hide()

func play_feedback(object_size: Vector2, _hero_mode: bool = true, _speed: float = 1.0) -> void :
	width = object_size.x

	swap_expression()

func _process(delta: float) -> void :
	if not playing or paused: return
	clock += delta
	sample(clock)
	native_rays.sample(clock)
	for event in events:
		if not event.get("fired", false) and clock >= float(event.time):
			event.fired = true
			for index in int(event.count): _spawn(String(event.kind), index)
	for index in range(particles.size() - 1, -1, -1):
		var p: = particles[index]
		var age: = clock - float(p.birth)
		var life: = float(p.life)
		var sprite: Sprite2D = p.sprite
		if age >= life:
			_release_particle(sprite)
			particles.remove_at(index)
			continue
		var t: = age / life
		if p.kind in ["kuosan", "kuosan2"]:
			var preset: Dictionary = particle_curves[p.kind]
			sprite.scale = Vector2.ONE * float(preset.size) * width / 500.0 * _sample_keys(preset.size_curve, t, "") / expand_texture.get_width()
			var alpha_keys: Array = preset.alpha
			var alpha: = float(alpha_keys[-1].value)
			for k in range(1, alpha_keys.size()):
				if t <= float(alpha_keys[k].time):
					alpha = lerpf(float(alpha_keys[k - 1].value), float(alpha_keys[k].value), inverse_lerp(float(alpha_keys[k - 1].time), float(alpha_keys[k].time), t))
					break
			sprite.modulate.a = alpha * (0.18 if p.kind == "kuosan" else 0.1)
		else:
			sprite.position = p.origin + p.direction * age * 24.0
			sprite.modulate.a = sin(t * PI) * (1.0 if p.kind == "star" else 0.65)
			sprite.scale = Vector2.ONE * float(p.size) / sprite.texture.get_width() * (0.65 + 0.35 * sin(t * PI))
	if clock > 2.85:
		reset()
		activation_settled.emit()

func sample(time: float) -> void :

	if is_instance_valid(hero_rig):
		var body_scale: = curve("EffectRoot/BadgeInactive/scale", time, "x")
		var tilt_x: = deg_to_rad(curve("EffectRoot/BadgeInactive/_rotationX", time))
		var tilt_y: = deg_to_rad(curve("EffectRoot/BadgeInactive/_rotationY", time))
		hero_rig.scale = Vector2(body_scale * cos(tilt_y), body_scale * cos(tilt_x))
		hero_rig.rotation = - deg_to_rad(curve("EffectRoot/BadgeInactive/euler", time, "z"))
	if _slam_pending and time >= SLAM_AT:
		_slam_pending = false
		slam_landed.emit()

	var prefixes: = ["glow00", "glow01", "glow03", "glow04"]
	var sizes: = [98.0, 256.0, 256.0, 256.0]
	var tints: = [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]
	for index in halos.size():
		var sprite: = halos[index]
		var path: String = "EffectRoot/" + prefixes[index]
		var factor: = absf(curve(path + "/scale", time, "x"))
		var pixels: float = float(sizes[index]) * factor * width / 500.0
		if index == 0: pixels = width * 3.0 * factor / 28.82
		if index == 2: pixels = width * 2.6 * factor / 13.87
		var opacity: = curve(path + "/m_Alpha", time)
		if index == 0: opacity *= 0.18
		else: opacity *= 0.85
		if sprite.material is ShaderMaterial:
			(sprite.material as ShaderMaterial).set_shader_parameter("color_phase", 0.25)
		sprite.modulate = tints[index] * Color(1, 1, 1, opacity)
		var k: float = pixels / sprite.texture.get_width()
		sprite.global_transform = Transform2D(halo_anchor.x * k, halo_anchor.y * k, halo_anchor.origin)
	if is_instance_valid(colored):
		if expression_swapped:
			reveal_material.set_shader_parameter("transition", 0.0)
			reveal_material.set_shader_parameter("reveal_alpha", 1.0)
		old_expression.hide()

		var local_flash: = smoothstep(0.5, 0.62, time) * (1.0 - smoothstep(0.68, 0.9, time))
		var swap_this_frame: = _swap_pending and time >= EXPRESSION_SWAP_AT

		if swap_this_frame: local_flash = 1.0
		flash_material.set_shader_parameter("strength", local_flash * 0.92)
		if swap_this_frame:
			_swap_pending = false
			expression_swap_requested.emit()

		var contour: = maxf(curve("EffectRoot/glow04/m_Alpha", time) * 1.5, curve("EffectRoot/glow01/m_Alpha", time) * 1.5)
		contour = maxf(contour, curve("EffectRoot/glow03/m_Alpha", time) * 0.45)
		rim_material.set_shader_parameter("strength", contour * 0.65)

func curve(path: String, time: float, axis: String = "") -> float:
	return _sample_keys(curves.get(path, []), time, axis)

func _sample_keys(keys: Array, time: float, axis: String) -> float:
	if keys.is_empty(): return 0.0
	if time <= float(keys[0].time): return _value(keys[0].value, axis)
	for index in range(1, keys.size()):
		var b: Dictionary = keys[index]
		if time > float(b.time): continue
		var a: Dictionary = keys[index - 1]
		var duration: = float(b.time) - float(a.time)
		var t: = (time - float(a.time)) / duration
		var v0: = _value(a.value, axis)
		var v1: = _value(b.value, axis)
		var m0: = _value(a.outSlope, axis)
		var m1: = _value(b.inSlope, axis)
		if not is_finite(m0) or not is_finite(m1): return v0
		if int(a.get("weightedMode", 0)) & 2 or int(b.get("weightedMode", 0)) & 1:
			var w0: = _value(a.outWeight, axis) if int(a.get("weightedMode", 0)) & 2 else 1.0 / 3.0
			var w1: = _value(b.inWeight, axis) if int(b.get("weightedMode", 0)) & 1 else 1.0 / 3.0
			var low: = 0.0
			var high: = 1.0
			for iteration in 16:
				var u: = (low + high) * 0.5
				var bx: = 3 * pow(1 - u, 2) * u * w0 + 3 * (1 - u) * u * u * (1 - w1) + u * u * u
				if bx < t: low = u
				else: high = u
			var u: = (low + high) * 0.5
			return pow(1 - u, 3) * v0 + 3 * pow(1 - u, 2) * u * (v0 + m0 * duration * w0) + 3 * (1 - u) * u * u * (v1 - m1 * duration * w1) + u * u * u * v1
		return (2 * t * t * t - 3 * t * t + 1) * v0 + (t * t * t - 2 * t * t + t) * duration * m0 + (-2 * t * t * t + 3 * t * t) * v1 + (t * t * t - t * t) * duration * m1
	return _value(keys[-1].value, axis)

func _value(value: Variant, axis: String) -> float:
	return float(value[axis]) if value is Dictionary else float(value)

func _spawn(kind: String, index: int) -> void :
	var angle: = rng.randf_range(0, TAU)
	var direction: = Vector2.from_angle(angle)
	var sprite: Sprite2D = _particle_pool.pop_back() if not _particle_pool.is_empty() else PARTICLE_SCENE.instantiate()
	sprite.texture = expand_texture if kind in ["kuosan", "kuosan2"] else (star_texture if kind == "star" else (soft_star_texture if index % 3 == 0 else dot_texture))
	var add: = CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = add
	sprite.z_index = 0 if kind in ["kuosan", "kuosan2"] else 5
	if sprite.get_parent() == null:
		add_child(sprite)
	sprite.show()
	if kind in ["kuosan", "kuosan2"]:
		var preset: Dictionary = particle_curves[kind]
		sprite.position = Vector2.ZERO
		sprite.modulate = Color(1, 1, 1, 0)
		particles.append({"sprite": sprite, "kind": kind, "birth": clock, "life": preset.life})
		return
	var radius: = width * (rng.randf_range(0.56, 0.7) if kind == "star" else rng.randf_range(0.52, 0.85))
	var origin: = direction * radius
	sprite.position = origin
	sprite.modulate = Color(1, 1, 1, 0)
	sprite.rotation = 0.0
	particles.append({"sprite": sprite, "kind": kind, "birth": clock, "life": rng.randf_range(0.5, 1.1), "direction": direction, "origin": origin, "radius": radius, "size": rng.randf_range(50, 78) if kind == "star" else rng.randf_range(10, 16)})

func reset() -> void :
	playing = false
	paused = false
	clock = 0.0
	expression_swapped = false
	_swap_pending = false
	_slam_pending = false
	if is_instance_valid(hero_rig):
		hero_rig.scale = Vector2.ONE
		hero_rig.rotation = 0.0
	events.clear()
	if is_instance_valid(native_rays): native_rays.reset()
	for p in particles:
		if is_instance_valid(p.sprite): _release_particle(p.sprite)
	particles.clear()
	for halo in halos:
		halo.hide()
		halo.modulate.a = 0.0
	if is_instance_valid(base_expression): base_expression.show()
	if is_instance_valid(old_expression): old_expression.hide()
	if is_instance_valid(colored): colored.hide()
	if is_instance_valid(flash):
		flash.hide()
		flash_material.set_shader_parameter("strength", 0.0)
	if is_instance_valid(rim): rim.hide()
	hide()

func suspend(value: bool) -> void :
	paused = value

func _exit_tree() -> void :
	reset()

func _release_particle(sprite: Sprite2D) -> void :
	sprite.hide()
	_particle_pool.append(sprite)
