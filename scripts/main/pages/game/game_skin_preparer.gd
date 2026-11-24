class_name GameSkinPreparer
extends RefCounted

const SKIN_CATALOG: JuiceSkinCatalog = preload("res://scripts/gameplay/juice_sort/view/skin/skin_catalog.tres")


static var contract_checks: Dictionary[String, bool] = {}
static var _resource_checks: Dictionary[String, bool] = {}
static var _validation_requests: Dictionary[String, Dictionary] = {}
static var _validation_generation: int = 0

static func prepare_resources(catalog: JuiceSkinCatalog, id: StringName, tree: SceneTree, 
		active: Callable, source: String = "enter") -> JuiceSkinResolver:
	var loader: = JuiceSkinLoader.new()
	var started: int = Time.get_ticks_usec()
	var resources: JuiceSkinResolver = await loader.load_skin(catalog, id, tree, active)
	_log_stage(id, "load", started, source)
	if resources == null:
		if active.call():
			SortLogger.error("Skin: " + loader.error)
		return null
	_watch_skin_contract_resource(resources.default_skin)
	_watch_skin_contract_resource(resources.active_skin)
	_watch_skin_contract_resource(resources.animation())
	for pack: JuiceSkinDefinition in [resources.default_skin, resources.active_skin]:
		if pack.effects != null:
			_watch_skin_contract_resource(pack.effects)
	var key: String = "%s:%s" % [resources.default_skin.get_instance_id(), resources.active_skin.get_instance_id()]
	while active.call():
		if _resource_checks.has(key):
			SortLogger.info("[SkinPrepare] skin=%s source=%s stage=validate cache=hit" % [id, source])
			return resources
		var request: Dictionary = _validation_requests.get(key, {})
		if request.is_empty():
			request = {"done": false, "error": "", "generation": _validation_generation}
			_validation_requests[key] = request
			_validate_request(resources, tree, key, request, _validation_generation)
		while not request["done"] and active.call():
			await tree.process_frame
		if not active.call():
			return null
		if not String(request["error"]).is_empty():
			SortLogger.error("Skin: " + String(request["error"]))
			return null
		if int(request["generation"]) == _validation_generation:
			return resources
	return null

static func _validate_request(resources: JuiceSkinResolver, tree: SceneTree, key: String, 
		request: Dictionary, generation: int) -> void :
	var started: int = Time.get_ticks_usec()
	var alive: Callable = func() -> bool: return is_instance_valid(tree.root)
	var error: String = await _validate_skin_resources(resources, tree, alive)
	request["error"] = error
	if error.is_empty() and generation == _validation_generation and _can_cache_resources(resources):
		_resource_checks[key] = true
	if generation != _validation_generation:
		contract_checks.clear()
	request["done"] = true
	_validation_requests.erase(key)
	_log_stage(resources.active_skin.id, "validate", started, "shared")

static func _can_cache_resources(resources: JuiceSkinResolver) -> bool:
	if resources.active_skin.resource_path != String(SKIN_CATALOG.paths.get(resources.active_skin.id, ""))\
	or resources.default_skin.resource_path != String(SKIN_CATALOG.paths[&"default"])\
	or _skin_animation_contract_key(resources.animation()).is_empty():
		return false
	if resources.collection_butterflies_enabled():
		for pack: JuiceSkinDefinition in [resources.default_skin, resources.active_skin]:
			if pack.effects != null:
				for scene: PackedScene in pack.effects.butterflies:
					if scene != null and _skin_scene_contract_key(scene).is_empty():
						return false
	return true

static func _log_stage(id: StringName, stage: String, started: int, source: String) -> void :
	SortLogger.info("[SkinPrepare] skin=%s source=%s stage=%s elapsed_ms=%.2f" % [id, source, stage, 
		(Time.get_ticks_usec() - started) / 1000.0])


static func preview_skin(descriptor: Dictionary, tree: SceneTree, active: Callable) -> Dictionary:
	if bool(descriptor.get("is_timed_endless", false)):
		return {"skin_id": "default"}
	var frozen_id: String = ""
	var blob: String = String(descriptor.get("raw_level_info", "{}"))
	if blob not in ["", "{}"]:
		var worker: = Thread.new()
		var error: Error = worker.start(_read_frozen_id.bind(blob))
		if error != OK:
			SortLogger.error("Skin preview worker failed: %d" % error)
			return {}
		while worker.is_alive():
			await tree.process_frame
		frozen_id = String(worker.wait_to_finish())
	if not active.call():
		return {}
	var level: int = int(descriptor["level"])
	var special: bool = bool(descriptor["is_special"])
	var instance_id: String = String(descriptor["instance_id"])
	var kind: String = "special_challenge" if special else "level"
	var key: String = instance_id if special else "level:%d" % level
	return JuiceSpecialThemeResolver.resolve(level, special, instance_id, frozen_id, 
		level == JuiceTutorialScript.LEVEL and not UserState.is_tutorial_done(), 
		bool(descriptor["reward_pending"]), ABManager.special_theme.should_use_theme(level, special), 
		UserState.get_special_theme_assignment(kind, key), UserState.get_special_theme_next_sequence())

static func _read_frozen_id(blob: String) -> String:
	var parsed: Variant = JSON.parse_string(blob)
	return String(parsed.get("special_theme_skin_id", "")) if parsed is Dictionary else ""

const CUP_BUTTERFLY_ANIMS: Array[String] = ["animation", "animation", "animation", "animation", "animation"]

const CUP_FLY_SPINE_END_DUR: = 4.0 / 60.0

static func _skin_scene_contract_key(scene: PackedScene) -> String:
	var shipped: String = EffectWarmupPolicy.scene_contract_signature(scene)
	if shipped.is_empty():
		return ""
	_watch_skin_contract_resource(scene)
	var state: SceneState = scene.get_state()
	var parts: PackedStringArray = [shipped, scene.resource_path]
	for index: int in state.get_node_count():
		parts.append(str(state.get_node_type(index)))
		for property: int in state.get_node_property_count(index):
			parts.append(str(state.get_node_property_name(index, property)))
			var value: Variant = state.get_node_property_value(index, property)
			if value is Resource:
				if value.resource_path.is_empty():
					return ""
				parts.append(value.resource_path)
				_watch_skin_contract_resource(value)
				if value is SpineSkeletonDataResource:
					for source: Resource in [value.atlas_res, value.skeleton_file_res]:
						if source == null or source.resource_path.is_empty():
							return ""
						parts.append(source.resource_path)
						_watch_skin_contract_resource(source)
			else:
				parts.append(str(value))
	return "|".join(parts).sha256_text()


static func _watch_skin_contract_resource(resource: Resource) -> void :
	if not resource.changed.is_connected(_invalidate_skin_contract_checks):
		resource.changed.connect(_invalidate_skin_contract_checks)


static func _invalidate_skin_contract_checks() -> void :
	contract_checks.clear()
	_resource_checks.clear()
	_validation_generation += 1


static func _skin_animation_contract_key(profile: JuiceSkinAnimationAssets) -> String:
	var scene_key: String = _skin_scene_contract_key(profile.scene)
	return (scene_key + str(profile.color_keys) + str(profile.slot_prefixes)
		+ str([profile.get_animation, profile.idle_animation, profile.end_animation])).sha256_text() if not scene_key.is_empty() else ""


static func _validate_skin_animation(profile: JuiceSkinAnimationAssets) -> String:
	var contract_key: String = _skin_animation_contract_key(profile)
	if not contract_key.is_empty() and contract_checks.has(contract_key):
		return ""
	var node: Node = profile.scene.instantiate()
	if not node is SpineSprite:
		node.free()
		return "收集动画必须使用兼容的SpineSprite场景"
	var skeleton: SpineSkeleton = (node as SpineSprite).get_skeleton()
	if skeleton == null:
		node.free()
		return "收集动画缺少骨架"
	var data: SpineSkeletonDataResource = skeleton.get_data()
	var slot_names: PackedStringArray = PackedStringArray()
	for slot: SpineSlot in skeleton.get_slots():
		slot_names.append(slot.get_data().get_name().to_lower())
	for key: String in profile.color_keys:
		var found: bool = false
		for prefix: String in profile.slot_prefixes:
			found = found or slot_names.has((prefix + key).to_lower())
		if not found:
			node.free()
			return "收集动画缺少颜色附件：%s" % key
	var names: Array[StringName] = [profile.get_animation, profile.idle_animation, profile.end_animation]
	var durations: Array[float] = [0.667, -1.0, CUP_FLY_SPINE_END_DUR]
	for index: int in names.size():
		var animation: SpineAnimation = data.find_animation(names[index])
		if animation == null or (durations[index] > 0.0 and absf(animation.get_duration() - durations[index]) > 0.025):
			node.free()
			return "收集动画缺少动作或时长不符合现有播放契约：%s" % names[index]
	node.free()
	if not contract_key.is_empty():
		contract_checks[contract_key] = true
	return ""


static func _validate_skin_resources(resources: JuiceSkinResolver, tree: SceneTree, active: Callable) -> String:
	var packs: Array[JuiceSkinDefinition] = [resources.default_skin]
	if resources.active_skin != resources.default_skin:
		packs.append(resources.active_skin)
	for pack: JuiceSkinDefinition in packs:
		for semantic: StringName in pack.sounds:
			var sound: StringName = pack.sounds[semantic]
			if sound != &"" and ( not AudioManager.SFX_PATHS.has(sound) or not AudioManager.SFX_PATHS.has(semantic)):
				return "皮肤音效未登记：%s → %s" % [semantic, sound]
		if resources.collection_butterflies_enabled() and pack.effects != null:
			for index: int in pack.effects.butterflies.size():
				var scene: PackedScene = pack.effects.butterflies[index]
				if scene == null:
					continue
				var key: String = _skin_scene_contract_key(scene)
				if not key.is_empty():
					key += ":" + String(CUP_BUTTERFLY_ANIMS[index])
					if contract_checks.has(key):
						continue
				await tree.process_frame
				if not active.call():
					return ""
				var node: Node = scene.instantiate()
				var valid: bool = node is SpineSprite
				if valid:
					var skeleton: SpineSkeleton = (node as SpineSprite).get_skeleton()
					valid = skeleton != null and skeleton.get_data().find_animation(CUP_BUTTERFLY_ANIMS[index]) != null
				node.free()
				if not valid:
					return "蝴蝶第%d槽必须使用含%s动作的SpineSprite场景" % [index, CUP_BUTTERFLY_ANIMS[index]]
				if not key.is_empty():
					contract_checks[key] = true
	var animation_key: String = _skin_animation_contract_key(resources.animation())
	if not animation_key.is_empty() and contract_checks.has(animation_key):
		return ""
	await tree.process_frame
	if not active.call():
		return ""
	return _validate_skin_animation(resources.animation())
