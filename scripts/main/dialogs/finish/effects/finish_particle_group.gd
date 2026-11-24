class_name FinishParticleGroup
extends Node2D

@export var emitter_scenes: Dictionary[StringName, PackedScene] = {}
var defer_initialize: bool = false
var _lifecycles: Dictionary = {}
var _initialized: bool = false


func _ready() -> void :
	if not defer_initialize:
		initialize()


func initialize() -> void :
	if _initialized:
		return
	if emitter_scenes.is_empty():
		configure()
	for name: StringName in emitter_scenes:
		if get_node_or_null(NodePath(name)) == null:
			var emitter: GPUParticles2D = _instantiate_emitter(name)
			configure_emitter(name, emitter)
			add_child(emitter)
	for node: Node in get_children():
		if node is GPUParticles2D:
			_register_emitter(node as GPUParticles2D)
	_initialized = true



func prepare_spread(active: Callable, checkpoint: Callable, progress: Callable) -> bool:
	if _initialized:
		return active.call()
	var completed: int = 0
	for name: StringName in emitter_scenes:
		if _lifecycles.has(name):
			completed += 1
			continue
		if not active.call() or not await checkpoint.call("%s/create" % name, true) or not active.call():
			return false
		var started: int = Time.get_ticks_usec()
		var emitter: GPUParticles2D = _instantiate_emitter(name)
		_log_preparation(name, "create", started)
		if not await checkpoint.call("%s/configure" % name, configuration_uploads_texture(name)) or not active.call():
			emitter.free()
			return false
		started = Time.get_ticks_usec()
		configure_emitter(name, emitter)
		_log_preparation(name, "configure", started)
		if not await checkpoint.call("%s/attach" % name, false) or not active.call():
			emitter.free()
			return false
		started = Time.get_ticks_usec()
		_register_emitter(emitter)
		add_child(emitter)
		_log_preparation(name, "attach", started)
		completed += 1
		if progress.is_valid():
			progress.call(float(completed) / emitter_scenes.size())
	_initialized = active.call()
	return _initialized


func _instantiate_emitter(name: StringName) -> GPUParticles2D:
	var emitter: GPUParticles2D = emitter_scenes[name].instantiate() as GPUParticles2D
	assert (emitter != null and not emitter.visible and not emitter.emitting)
	emitter.name = name
	return emitter


func _register_emitter(emitter: GPUParticles2D) -> void :
	if _lifecycles.has(emitter.name):
		return
	var lifecycle: = GpuParticleLifecycle.new()
	lifecycle.prepare([emitter], 2, func() -> bool: return is_instance_valid(self) and is_visible_in_tree())
	_lifecycles[emitter.name] = lifecycle


func _log_preparation(name: StringName, phase: String, started: int) -> void :
	SortLogger.info("[ParticlePrepare] group=%s emitter=%s phase=%s cpu_ms=%.2f" % [
		self.name, name, phase, (Time.get_ticks_usec() - started) / 1000.0])


func set_preparation_data(_pixels: PackedByteArray) -> void :
	return


func configuration_uploads_texture(_name: StringName) -> bool:
	return false


func configure_emitter(_name: StringName, _emitter: GPUParticles2D) -> void :
	return




static func warm_groups(groups: Array[FinishParticleGroup], active: Callable, 
		names: Array[StringName] = [], checkpoint: Callable = Callable()) -> bool:
	if groups.is_empty() or not active.call():
		return false

	if checkpoint.is_valid():
		for group: FinishParticleGroup in groups:
			for name: StringName in group._lifecycles:
				if not names.is_empty() and not names.has(name):
					continue
				if not active.call() or not await checkpoint.call(String(name)):
					return false
				if not await (group._lifecycles[name] as GpuParticleLifecycle).pre_render(active, 0.55):
					return false
		return active.call()
	var tree: SceneTree = groups[0].get_tree()
	var state: Dictionary = {"pending": 0, "success": true}
	for group: FinishParticleGroup in groups:
		for name: StringName in group._lifecycles:
			if not names.is_empty() and not names.has(name):
				continue
			state.pending += 1
			group._warm_emitter(name, active, state)
	while state.pending > 0:
		await tree.process_frame
	return state.success and active.call()


func _warm_emitter(name: StringName, active: Callable, state: Dictionary) -> void :
	var rendered: bool = await (_lifecycles[name] as GpuParticleLifecycle).pre_render(active, 0.55)
	state.success = state.success and rendered
	state.pending -= 1


func take(name: String, parent: Node) -> GPUParticles2D:
	var emitter: GPUParticles2D = get_node_or_null(name) as GPUParticles2D
	if emitter == null:
		return null
	(_lifecycles[emitter.name] as GpuParticleLifecycle).reset_immediate()
	var placeholder: Node = parent.get_node_or_null(name)
	var index: int = placeholder.get_index() if placeholder != null else parent.get_child_count()
	if placeholder != null:
		parent.remove_child(placeholder)
		placeholder.free()
	emitter.reparent(parent, false)
	parent.move_child(emitter, index)
	_lifecycles.erase(emitter.name)
	return emitter


func configure() -> void :
	return
