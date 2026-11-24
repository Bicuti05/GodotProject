class_name FinishParticleCache
extends RefCounted

const CONTROL_SCENES: Dictionary = {
	"confetti": "res://scripts/main/dialogs/finish/effects/finish_confetti_effects.tscn", 
	"reward": "res://scripts/main/dialogs/finish/effects/finish_reward_particles.tscn", 
	"ad": "res://scripts/main/dialogs/finish/effects/finish_ad_particles.tscn", 
	"card0": "res://scripts/main/dialogs/finish/effects/finish_card_burst.tscn", 
	"card1": "res://scripts/main/dialogs/finish/effects/finish_card_burst.tscn", 
	"card2": "res://scripts/main/dialogs/finish/effects/finish_card_burst.tscn", 
	"fireworks": "res://scripts/main/dialogs/finish/view/firework_show.tscn", 
}
static var SCENES: Dictionary = CONTROL_SCENES.duplicate()
static var _cold_start_optimized: bool = false
static var _groups_ready: bool = false
static var _point_data_job: FinishParticlePointDataJob
static var _resources: Dictionary = {}
static var _groups: Dictionary = {}
static var _viewport: SubViewport
static var _preparing: bool = false
static var _ready: bool = false
static var _render_ready: bool = false

static var _policy_ready: bool = false
static var _rendered_groups: Dictionary = {}


static func request_resources() -> void :
	if _cold_start_optimized:
		_request_point_data()
	for path: String in SCENES.values():
		_request_resource(path)


static func _request_resource(path: String) -> bool:
	if _resources.has(path):
		return true
	if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		return true
	var error: Error = ResourceLoader.load_threaded_request(path, "PackedScene", false)
	if error != OK:
		SortLogger.error("FinishParticleCache: 请求失败 %s" % path)
	return error == OK


static func request_resources_spread(host: Node, progress: Callable = Callable()) -> bool:
	if _cold_start_optimized:
		_request_point_data()
	var started: int = Time.get_ticks_usec()
	var requested: int = 0
	var success: bool = true
	for path: String in SCENES.values():
		success = _request_resource(path) and success
		requested += 1
		_report_progress(progress, requested, SCENES.size())
		if Time.get_ticks_usec() - started >= 2000:
			await host.get_tree().process_frame
			started = Time.get_ticks_usec()
	return success


static func _report_progress(progress: Callable, completed: int, total: int) -> void :
	if progress.is_valid():
		progress.call(float(completed) / total)



static func pre_render_startup(host: Node, active: Callable) -> bool:
	while _preparing and active.call():
		await host.get_tree().process_frame
	if not active.call():
		return false
	if DisplayServer.get_name() == "headless":
		return true
	if _policy_ready or not EffectWarmupPolicy.needs_any(EffectWarmupPolicy.FINISH_GROUPS):
		_policy_ready = true
		return true
	_preparing = true
	var prepared: bool = await _prepare_groups(host, active)
	if prepared:
		_policy_ready = await _pre_render_groups(active)
	_disable_viewport()
	_preparing = false
	return _policy_ready and active.call()



static func prepare(host: Node, progress: Callable = Callable(), guard: Callable = Callable()) -> bool:
	var active: Callable = func() -> bool:
		return is_instance_valid(host) and host.is_inside_tree() and ( not guard.is_valid() or guard.call())
	while _preparing and active.call():
		await host.get_tree().process_frame
	if not active.call():
		return false
	if _ready:
		_report_progress(progress, 1, 1)
		return true
	_preparing = true
	_ready = await _prepare(host, active, progress)
	_disable_viewport()
	_preparing = false
	return _ready


static func _disable_viewport() -> void :
	if is_instance_valid(_viewport):
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


static func _prepare(host: Node, active: Callable, progress: Callable) -> bool:
	if _cold_start_optimized:
		return await _prepare_optimized(host, active, progress)
	var already_rendered: bool = _policy_ready
	if _groups.size() != SCENES.size():
		if not await _prepare_groups(host, active):
			return false

		if progress.is_valid():
			progress.call(0.25)
	var fireworks: FireworkShow = _groups["fireworks"] as FireworkShow
	var pool_started: int = Time.get_ticks_usec()
	var pool_progress: Callable = func(ratio: float) -> void :
		if progress.is_valid():
			progress.call(ratio if already_rendered else 0.25 + ratio * 0.25)
	await fireworks.prepare_pool_spread(pool_progress)
	SortLogger.info("[FinishParticlePool] elapsed_ms=%.2f reused_render=%s" % [
		(Time.get_ticks_usec() - pool_started) / 1000.0, already_rendered])
	if not active.call():
		return false
	if DisplayServer.get_name() != "headless" and not _policy_ready:
		_policy_ready = await _pre_render_groups(active)
		if not _policy_ready:
			return false
	(_groups["fireworks"] as FireworkShow).stop()
	_report_progress(progress, 1, 1)
	return active.call()
static func _prepare_groups(host: Node, active: Callable) -> bool:
	if not await request_resources_spread(host):
		return false
	if not is_instance_valid(_viewport):
		_viewport = SubViewport.new()
		_viewport.name = "FinishParticleCacheViewport"
		_viewport.size = Vector2i(UiMetrics.viewport_size())
		_viewport.disable_3d = true
		_viewport.transparent_bg = true
		_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		host.add_child(_viewport)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var tree: SceneTree = host.get_tree()

	for key: String in SCENES:
		if not active.call():
			return false
		var path: String = SCENES[key]
		var wait_started: int = Time.get_ticks_usec()
		if not _resources.has(path):
			while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				await tree.process_frame
				if not active.call():
					return false
			if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_LOADED:
				SortLogger.error("FinishParticleCache: 加载失败 %s" % path)
				return false
			_resources[path] = ResourceLoader.load_threaded_get(path)
		var loaded_at: int = Time.get_ticks_usec()
		var group: Node2D = _groups.get(key) as Node2D
		if not is_instance_valid(group):
			group = (_resources[path] as PackedScene).instantiate() as Node2D
			group.visible = false
			if key not in ["fireworks", "confetti"]:
				group.position = UiMetrics.viewport_size() * 0.5
			_viewport.add_child(group)
			_groups[key] = group
		SortLogger.info("[FinishParticleLoad] group=%s resource_wait_ms=%.2f create_ms=%.2f" % [
			key, (loaded_at - wait_started) / 1000.0, (Time.get_ticks_usec() - loaded_at) / 1000.0])
		await tree.process_frame
	return active.call()


static func _pre_render_groups(active: Callable) -> bool:
	if not active.call():
		return false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if EffectWarmupPolicy.needs_render("fireworks"):
		var fireworks: FireworkShow = _groups["fireworks"] as FireworkShow
		var render_started: int = Time.get_ticks_usec()
		fireworks.show()
		await fireworks.warm_render_pipeline(true)
		if is_instance_valid(fireworks):
			fireworks.stop()
			fireworks.hide()
		if not active.call():
			return false
		_rendered_groups["fireworks"] = true
		EffectWarmupPolicy.mark_rendered("fireworks", active)
		SortLogger.info("[FinishParticleRender] stage=fireworks elapsed_ms=%.2f" % ((Time.get_ticks_usec() - render_started) / 1000.0))
	if not await _warm_stage("reward_particles", [_groups["reward"]], active):
		return false
	if not await _warm_stage("game_data_cards", [_groups["card0"], _groups["card1"], _groups["card2"]], active):
		return false
	if not await _warm_stage("confetti_fall", [_groups["confetti"]], active, [&"ConfettiFall"]):
		return false
	if not await _warm_stage("confetti_sides", [_groups["confetti"]], active, 
			[&"Confetti", &"ConfettiRight", &"Sparkle", &"SparkleRight"]):
		return false
	if not await _warm_stage("ad_particles", [_groups["ad"]], active):
		return false
	_render_ready = _rendered_groups.size() == EffectWarmupPolicy.FINISH_GROUPS.size()
	return active.call()


static func _warm_stage(stage: String, groups: Array[FinishParticleGroup], active: Callable, 
		names: Array[StringName] = []) -> bool:
	if not active.call():
		return false
	if not EffectWarmupPolicy.needs_render(stage):
		return true
	NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:" + stage)
	var started: int = Time.get_ticks_usec()
	for group: FinishParticleGroup in groups:
		group.show()
	var rendered: bool
	if EffectWarmupPolicy.needs_full_warmup(stage):
		rendered = await FinishParticleGroup.warm_groups(groups, active, names)
	else:

		rendered = await _warm_minimal_groups(groups, active, names)
	for group: FinishParticleGroup in groups:
		if is_instance_valid(group):
			group.hide()
	if rendered and active.call():
		_rendered_groups[stage] = true
		EffectWarmupPolicy.mark_rendered(stage, active)
		NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:" + stage)
	else:
		SortLogger.error("FinishParticleCache: 预渲染失败 %s" % stage)
	SortLogger.info("[FinishParticleRender] stage=%s elapsed_ms=%.2f success=%s" % [
		stage, (Time.get_ticks_usec() - started) / 1000.0, rendered])
	return rendered


static func _warm_minimal_groups(groups: Array[FinishParticleGroup], active: Callable, 
		names: Array[StringName]) -> bool:
	for group: FinishParticleGroup in groups:
		for name: StringName in group._lifecycles:
			if not names.is_empty() and not names.has(name):
				continue
			var lifecycle: GpuParticleLifecycle = group._lifecycles[name]
			if not await lifecycle.pre_render(active, 0.0):
				return false
	return active.call()


static func inject(key: String, parent: Node, names: Array[String]) -> void :
	var group: FinishParticleGroup = _groups.get(key) as FinishParticleGroup
	if not is_instance_valid(group):

		group = (load(SCENES[key]) as PackedScene).instantiate() as FinishParticleGroup
		group.initialize()
		parent.add_child(group)
	for name: String in names:
		group.take(name, parent)
	if group.get_parent() == parent:
		group.queue_free()
	_groups.erase(key)


static func inject_fireworks(parent: Node) -> void :
	var group: FireworkShow = _groups.get("fireworks") as FireworkShow
	if not is_instance_valid(group):
		group = (load(SCENES["fireworks"]) as PackedScene).instantiate() as FireworkShow
	group.stop()
	group.hide()
	var placeholder: Node = parent.get_node("FireworkLayer")
	var index: int = placeholder.get_index()
	parent.remove_child(placeholder)
	placeholder.free()
	group.name = "FireworkLayer"
	if group.get_parent() != null:
		group.reparent(parent, false)
	else:
		parent.add_child(group)
	parent.move_child(group, index)
	_groups.erase("fireworks")


static func set_startup_mode(optimized: bool) -> void :
	_cold_start_optimized = optimized
	SCENES = CONTROL_SCENES.duplicate()
	if optimized:
		for key: String in SCENES:
			if key != "fireworks":
				SCENES[key] = String(SCENES[key]).replace(".tscn", "_optimized.tscn")
	SortLogger.info("[FinishParticleMode] optimized=%s groups=%s" % [optimized, SCENES.keys()])


static func _request_point_data() -> void :
	if _point_data_job == null:
		_point_data_job = FinishParticlePointDataJob.new()
		_point_data_job.request(Time.get_ticks_usec())


static func _prepare_optimized(host: Node, active: Callable, progress: Callable) -> bool:
	var budget: = StartupWarmupBudget.new(host, active)
	if not _groups_ready:
		var group_progress: Callable = func(ratio: float) -> void :
			if progress.is_valid():
				progress.call(ratio * 0.35)
		if not await _prepare_groups_optimized(host, active, budget, group_progress):
			budget.close()
			return false
	if progress.is_valid():
		progress.call(0.35)
	if DisplayServer.get_name() != "headless" and not _policy_ready:
		var render_progress: Callable = func(ratio: float) -> void :
			if progress.is_valid():
				progress.call(0.35 + ratio * 0.25)
		_policy_ready = await _pre_render_groups_optimized(active, budget, render_progress)
	budget.close()
	_disable_viewport()
	if not active.call() or (DisplayServer.get_name() != "headless" and not _policy_ready):
		return false
	if progress.is_valid():
		progress.call(0.6)
	var fireworks: FireworkShow = _groups["fireworks"] as FireworkShow
	var pool_started: int = Time.get_ticks_usec()
	var pool_progress: Callable = func(ratio: float) -> void :
		if progress.is_valid() and active.call():
			progress.call(0.6 + ratio * 0.4)
	await fireworks.prepare_pool_spread(pool_progress, active)
	SortLogger.info("[FinishParticlePool] elapsed_ms=%.2f viewport_disabled=%s" % [
		(Time.get_ticks_usec() - pool_started) / 1000.0, 
		_viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED])
	if not active.call():
		return false
	fireworks.stop()
	_report_progress(progress, 1, 1)
	return active.call()

static func _prepare_groups_optimized(host: Node, active: Callable, budget: StartupWarmupBudget, progress: Callable) -> bool:
	if not await request_resources_spread(host):
		return false
	if not is_instance_valid(_viewport):
		_viewport = SubViewport.new()
		_viewport.name = "FinishParticleCacheViewport"
		_viewport.size = Vector2i(UiMetrics.viewport_size())
		_viewport.disable_3d = true
		_viewport.transparent_bg = true
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		host.add_child(_viewport)
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var tree: SceneTree = host.get_tree()

	while not _point_data_job.is_ready():
		await tree.process_frame
	var point_data: Array[PackedByteArray] = _point_data_job.collect()
	if not active.call():
		return false
	var completed: int = 0
	var total_emitters: int = 16

	for key: String in SCENES:
		if not active.call():
			return false
		var path: String = SCENES[key]
		var wait_started: int = Time.get_ticks_usec()
		if not _resources.has(path):
			while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				await tree.process_frame
				if not active.call():
					return false
			if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_LOADED:
				SortLogger.error("FinishParticleCache: 加载失败 %s" % path)
				return false
			_resources[path] = ResourceLoader.load_threaded_get(path)
		var loaded_at: int = Time.get_ticks_usec()
		var create_started: int = loaded_at
		var group: Node2D = _groups.get(key) as Node2D
		if not is_instance_valid(group):
			if not await budget.begin_preparation(_viewport, "finish/%s/root" % key, true):
				return false
			create_started = Time.get_ticks_usec()
			group = (_resources[path] as PackedScene).instantiate() as Node2D
			group.visible = false
			if group is FinishParticleGroup:
				(group as FinishParticleGroup).defer_initialize = true
				if key.begins_with("card"):
					(group as FinishParticleGroup).set_preparation_data(point_data[int(key.trim_prefix("card"))])
			if key not in ["fireworks", "confetti"]:
				group.position = UiMetrics.viewport_size() * 0.5
			_viewport.add_child(group)
			_groups[key] = group
		SortLogger.info("[FinishParticleLoad] group=%s resource_wait_ms=%.2f create_ms=%.2f" % [
			key, (loaded_at - wait_started) / 1000.0, (Time.get_ticks_usec() - create_started) / 1000.0])
		if group is FinishParticleGroup:
			var particles: FinishParticleGroup = group as FinishParticleGroup
			var checkpoint: Callable = func(stage: String, force_frame: bool) -> bool:
				return await budget.begin_preparation(_viewport, "finish/%s/%s" % [key, stage], force_frame)
			var group_progress: Callable = func(ratio: float) -> void :
				if progress.is_valid():
					progress.call(float(completed + ratio * particles.emitter_scenes.size()) / total_emitters)
			if not await particles.prepare_spread(active, checkpoint, group_progress):
				return false
			completed += particles.emitter_scenes.size()
		else:
			completed += 1
		_report_progress(progress, completed, total_emitters)
	_groups_ready = active.call()
	return _groups_ready


static func _pre_render_groups_optimized(active: Callable, budget: StartupWarmupBudget, progress: Callable) -> bool:
	if not active.call():
		return false
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if EffectWarmupPolicy.needs_render("fireworks"):
		var fireworks: FireworkShow = _groups["fireworks"] as FireworkShow
		var render_started: int = Time.get_ticks_usec()
		fireworks.show()
		var checkpoint: Callable = func(stage: String) -> bool: return await budget.begin_batch(_viewport, stage)
		var rendered: bool = await fireworks.warm_render_pipeline(true, active, checkpoint)
		if is_instance_valid(fireworks):
			fireworks.stop()
			fireworks.hide()
		if not rendered or not active.call():
			return false
		_rendered_groups["fireworks"] = true
		EffectWarmupPolicy.mark_rendered("fireworks", active)
		SortLogger.info("[FinishParticleRender] stage=fireworks elapsed_ms=%.2f" % ((Time.get_ticks_usec() - render_started) / 1000.0))

	var completed_stages: int = 1
	var total_stages: int = EffectWarmupPolicy.FINISH_GROUPS.size()
	_report_progress(progress, completed_stages, total_stages)
	var stages: Array[String] = ["reward_particles", "game_data_cards"]
	var stage_groups: Array = [[_groups["reward"]], [_groups["card0"], _groups["card1"], _groups["card2"]]]
	var stage_names: Array = [[], []]
	stages.append_array(["confetti_fall", "confetti_sides"])
	stage_groups.append_array([[_groups["confetti"]], [_groups["confetti"]]])
	stage_names.append_array([[&"ConfettiFall"], [&"Confetti", &"ConfettiRight", &"Sparkle", &"SparkleRight"]])
	stages.append("ad_particles")
	stage_groups.append([_groups["ad"]])
	stage_names.append([])
	for i: int in stages.size():
		var groups: Array[FinishParticleGroup] = []
		groups.assign(stage_groups[i])
		var names: Array[StringName] = []
		names.assign(stage_names[i])
		var stage_progress: Callable = func(ratio: float) -> void :
			if progress.is_valid():
				progress.call((float(completed_stages + i) + ratio) / total_stages)
		if not await _warm_stage_optimized(stages[i], groups, active, names, budget, stage_progress):
			return false
		_report_progress(progress, completed_stages + i + 1, total_stages)
	_render_ready = _rendered_groups.size() == EffectWarmupPolicy.FINISH_GROUPS.size()
	return active.call()


static func _warm_stage_optimized(stage: String, groups: Array[FinishParticleGroup], active: Callable, 
		names: Array[StringName], budget: StartupWarmupBudget, progress: Callable) -> bool:
	if not active.call():
		return false
	if not EffectWarmupPolicy.needs_render(stage):
		return true
	NativeUtilManager.set_crashlytics_key("boot_step", "WarmFinishRender:" + stage)
	var started: int = Time.get_ticks_usec()
	for group: FinishParticleGroup in groups:
		group.show()
	var total: int = 0
	for group: FinishParticleGroup in groups:
		for name: StringName in group._lifecycles:
			if names.is_empty() or names.has(name):
				total += 1
	var work: Dictionary = {"submitted": 0}
	var checkpoint: Callable = func(name: String) -> bool:
		if progress.is_valid():
			progress.call(float(work.submitted) / maxi(1, total))
		if not await budget.begin_batch(_viewport, "WarmFinishRender:%s/%s" % [stage, name]):
			return false
		work.submitted += 1
		return true
	var rendered: bool
	if EffectWarmupPolicy.needs_full_warmup(stage):
		rendered = await FinishParticleGroup.warm_groups(groups, active, names, checkpoint)
	else:

		rendered = await _warm_minimal_groups_optimized(groups, active, names, checkpoint)
	for group: FinishParticleGroup in groups:
		if is_instance_valid(group):
			group.hide()
	if rendered and active.call():
		_rendered_groups[stage] = true
		EffectWarmupPolicy.mark_rendered(stage, active)
		NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmFinishRender:" + stage)
	else:
		SortLogger.error("FinishParticleCache: 预渲染失败 %s" % stage)
	SortLogger.info("[FinishParticleRender] stage=%s elapsed_ms=%.2f success=%s" % [
		stage, (Time.get_ticks_usec() - started) / 1000.0, rendered])
	return rendered


static func _warm_minimal_groups_optimized(groups: Array[FinishParticleGroup], active: Callable, 
		names: Array[StringName], checkpoint: Callable) -> bool:
	for group: FinishParticleGroup in groups:
		for name: StringName in group._lifecycles:
			if not names.is_empty() and not names.has(name):
				continue
			if not active.call() or not await checkpoint.call(String(name)):
				return false
			var lifecycle: GpuParticleLifecycle = group._lifecycles[name]
			if not await lifecycle.pre_render(active, 0.0):
				return false
	return active.call()
