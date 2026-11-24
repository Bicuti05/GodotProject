class_name GpuParticleLifecycle
extends RefCounted



var _particles: Array[GPUParticles2D] = []
var _render_ready: Callable
var _update_frames: int = 0
var _generation: int = 0
var _playing: bool = false
var _tailing: bool = false
var _revealed: bool = false
var _has_played: bool = false
var _opacity: float = 1.0
var _manual: bool = false
var _manual_queue: Array[Dictionary] = []
var _preprocess_restore: PackedFloat32Array = PackedFloat32Array()



func prepare(particles: Array[GPUParticles2D], update_frames: int, render_ready: Callable) -> void :
	assert (_particles.is_empty() and not particles.is_empty())
	assert (update_frames > 0 and render_ready.is_valid())
	_particles.assign(particles)
	_update_frames = update_frames
	_render_ready = render_ready
	for emitter: GPUParticles2D in _particles:
		assert (emitter.process_material is ParticleProcessMaterial)
		assert ((emitter.process_material as ParticleProcessMaterial).particle_flag_disable_z)
		emitter.hide()
		emitter.emitting = false


func play(manual: bool = false) -> void :
	if _playing or _tailing:
		reset_immediate()
	_generation += 1
	var generation: int = _generation
	_manual = manual
	_playing = true
	_tailing = false
	_revealed = not _has_played
	for emitter: GPUParticles2D in _particles:
		if not is_instance_valid(emitter):
			reset_immediate()
			return
		emitter.self_modulate.a = _opacity if _revealed else 0.0
		emitter.show()
		if _has_played:
			emitter.restart()
		else:
			emitter.emitting = not _manual
		if _manual:
			emitter.emitting = false
	_has_played = true
	if not _revealed:
		_reveal_after_updates(generation)



func set_opacity(opacity: float) -> void :
	_opacity = clampf(opacity, 0.0, 1.0)
	if _revealed:
		for emitter: GPUParticles2D in _particles:
			if is_instance_valid(emitter):
				emitter.self_modulate.a = _opacity



func stop_with_tail() -> void :
	_restore_preprocess()
	_tailing = _playing or _tailing
	_playing = false
	for emitter: GPUParticles2D in _particles:
		if is_instance_valid(emitter):
			emitter.emitting = false


func reset_immediate() -> void :
	_restore_preprocess()
	_generation += 1
	_manual_queue.clear()
	_playing = false
	_tailing = false
	_revealed = false
	_has_played = true
	for emitter: GPUParticles2D in _particles:
		if is_instance_valid(emitter):
			emitter.hide()
			emitter.restart()
			emitter.emitting = false
			emitter.self_modulate.a = 0.0



func reconfigure(configuration: Callable) -> void :
	reset_immediate()
	configuration.call()


func _is_current(generation: int) -> bool:
	return generation == _generation and (_playing or _tailing)


func _reveal_after_updates(generation: int) -> void :
	var _keep_alive: RefCounted = self
	var frames: int = 0
	while _is_current(generation) and frames < _update_frames:
		if not _can_render():
			frames = 0
			if not is_instance_valid(_particles[0]) or not _particles[0].is_inside_tree():
				return
			await _particles[0].get_tree().process_frame
			continue
		await _wait_for_draw()
		if not _is_current(generation):
			return
		frames = frames + 1 if _can_render() else 0
	if not _is_current(generation):
		return
	_revealed = true
	set_opacity(_opacity)
	for event: Dictionary in _manual_queue:
		_emit_manual(event)
	_manual_queue.clear()


func _wait_for_draw() -> void :
	if DisplayServer.get_name() == "headless":
		await _particles[0].get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw


func _can_render() -> bool:
	if not _render_ready.call():
		return false
	for emitter: GPUParticles2D in _particles:
		if not is_instance_valid(emitter) or not emitter.is_inside_tree() or not emitter.is_visible_in_tree():
			return false
		var alpha: float = 1.0
		var ancestor: Node = emitter
		while ancestor != null:
			if ancestor is CanvasItem:
				alpha *= (ancestor as CanvasItem).modulate.a
			elif ancestor is CanvasLayer and not (ancestor as CanvasLayer).visible:
				return false
			ancestor = ancestor.get_parent()
		if alpha < 0.01:
			return false
		var bounds: Rect2 = emitter.get_global_transform_with_canvas() * emitter.visibility_rect
		if not bounds.intersects(emitter.get_viewport_rect()):
			return false
	return true



func pre_render(active: Callable, preprocess_seconds: float = 0.55) -> bool:
	if DisplayServer.get_name() == "headless" or not active.is_valid() or not active.call():
		return false
	reset_immediate()
	for emitter: GPUParticles2D in _particles:
		_preprocess_restore.append(emitter.preprocess)
		emitter.preprocess = preprocess_seconds
	play()
	var _keep_alive: RefCounted = self
	var generation: int = _generation
	while _is_current(generation) and active.is_valid() and active.call() and not _revealed:
		await _particles[0].get_tree().process_frame
	var rendered: bool = _is_current(generation) and active.is_valid() and active.call() and _can_render()
	if rendered:
		await RenderingServer.frame_post_draw
		rendered = _is_current(generation) and active.is_valid() and active.call() and _can_render()

	if generation == _generation:
		reset_immediate()
	return rendered


func _restore_preprocess() -> void :
	for i: int in _preprocess_restore.size():
		if is_instance_valid(_particles[i]):
			_particles[i].preprocess = _preprocess_restore[i]
	_preprocess_restore.clear()



func emit_manual(emitter: GPUParticles2D, particle_transform: Transform2D, velocity: Vector2, 
		color: Color, custom: Color, flags: int) -> void :
	if not _manual or not _playing or not _particles.has(emitter):
		return
	var event: Dictionary = {"emitter": emitter, "transform": particle_transform, 
		"velocity": velocity, "color": color, "custom": custom, "flags": flags}
	if _revealed:
		_emit_manual(event)
	else:
		_manual_queue.append(event)

func _emit_manual(event: Dictionary) -> void :
	var emitter: Variant = event["emitter"]
	if is_instance_valid(emitter):
		emitter.emit_particle(event["transform"], event["velocity"], event["color"], event["custom"], event["flags"])
