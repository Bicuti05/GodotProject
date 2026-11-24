extends GPUParticles2D


var _recipe_scale: Vector2 = Vector2.ZERO
var _particle_material: ParticleProcessMaterial
var _shader_material: ShaderMaterial


func _enter_tree() -> void :
	set_notify_transform(true)
	if _shader_material == null:
		_prepare_scale_guard()
	_sync_scale_guard()


func _exit_tree() -> void :
	if _shader_material != null:
		_shader_material.set_shader_parameter("particle_scale_max", 0.0)


func _notification(what: int) -> void :
	if what in [NOTIFICATION_TRANSFORM_CHANGED, NOTIFICATION_VISIBILITY_CHANGED, NOTIFICATION_DRAW]\
	and is_inside_tree():
		_sync_scale_guard()


func _prepare_scale_guard() -> void :
	_particle_material = process_material as ParticleProcessMaterial
	_shader_material = material as ShaderMaterial
	if _particle_material == null or _shader_material == null:
		SortLogger.error("ConfettiFall: 缺少配方粒子材质或防护 ShaderMaterial")
		return
	_recipe_scale = Vector2(_particle_material.scale_min, _particle_material.scale_max)
	if not _recipe_scale.is_finite() or _recipe_scale.x <= 0.0 or _recipe_scale.y < _recipe_scale.x\
	or _particle_material.get_param_texture(ParticleProcessMaterial.PARAM_SCALE) != null:
		_recipe_scale = Vector2.ZERO
		SortLogger.error("ConfettiFall: 无效缩放配方，或存在未纳入防护上限的缩放曲线")



func _sync_scale_guard() -> void :
	if _shader_material == null:
		return
	_shader_material.set_shader_parameter("particle_scale_max", 0.0)
	if _recipe_scale.y <= 0.0 or _particle_material == null:
		return

	_particle_material.scale_min = _recipe_scale.x
	_particle_material.scale_max = _recipe_scale.y
	var emitter_transform: Transform2D = get_global_transform()
	var determinant: float = emitter_transform.determinant()
	if not emitter_transform.x.is_finite() or not emitter_transform.y.is_finite()\
	or not is_finite(determinant) or is_zero_approx(determinant):
		return

	var inverse: Transform2D = emitter_transform.affine_inverse() if local_coords else Transform2D.IDENTITY
	if not inverse.x.is_finite() or not inverse.y.is_finite():
		return
	_shader_material.set_shader_parameter("inverse_emitter_basis", 
		Vector4(inverse.x.x, inverse.x.y, inverse.y.x, inverse.y.y))
	_shader_material.set_shader_parameter("particle_scale_max", _recipe_scale.y)
