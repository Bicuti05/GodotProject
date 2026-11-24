class_name EffectWarmupPolicy
extends RefCounted



const MANIFEST_JSON: String = "{\n  \"format\": 2,\n  \"groups\": {\n    \"ad_particles\": \"eec6962a9f0ab7df95ff36074e052c0c3c48b3e39f5a55711349831b40498599\",\n    \"confetti_fall\": \"32e3712cfcbd2d15d2f5975b8ed08168ec803e9017d6adb5a955572b228e8395\",\n    \"confetti_sides\": \"32e3712cfcbd2d15d2f5975b8ed08168ec803e9017d6adb5a955572b228e8395\",\n    \"connection\": \"adb5514a1813d18b590e3821ccf0954ee9a8609a5c8a110ab3cce778e68fff70\",\n    \"fireworks\": \"5400951e31c0522dbff19d7fc08cbb6a8269a15dc5d5e205fe9b4a2b91b76eba\",\n    \"game_data_cards\": \"d8b3b3ed74293a66da1a1b1c862fd0a21b77c9df1a6ce83568b78538194ec912\",\n    \"ice_unlock\": \"adb5514a1813d18b590e3821ccf0954ee9a8609a5c8a110ab3cce778e68fff70\",\n    \"mystery_reveal\": \"4750f97ad81153ca15f63bcbb23e0cb701bbef42f427d7e89c87be3b1af439c5\",\n    \"reward_particles\": \"abcf4e86966875eea2ffdb89cb43609d134304c1df55ea636e1d8c0cd7f9afca\"\n  },\n  \"scene_contracts\": {\n    \"res://assets/spine/effect_bird_container/effect_bird_container.tscn\": \"0316ebceacff1d464a1af9c6fc96941669e4f6622590c818dcb999bc6236fb31\",\n    \"res://assets/spine/effect_butterfly_bigoringe/effect_butterfly_bigoringe.tscn\": \"a1dc1b5bec6244c2e0533d47ecfda7fd3175715b1b3fa1996708c306705670b9\",\n    \"res://assets/spine/effect_butterfly_caise/effect_butterfly_caise.tscn\": \"6188eb414e597bebc89c13ab6593f89d0c895dda3536b921b82c8deaaac0265c\",\n    \"res://assets/spine/effect_butterfly_green/effect_butterfly_green.tscn\": \"08017c7364fcee9946479c7dc19c77efe25c42f0ca0fb9682b856db1cf35a8bc\",\n    \"res://assets/spine/effect_butterfly_oringe/effect_butterfly_oringe.tscn\": \"ca1b9b3868db3a4a308095a8f665f30497b53bfe4852a94435953e2d84fa65ca\",\n    \"res://assets/spine/effect_butterfly_red/effect_butterfly_red.tscn\": \"c85d6767b299926ac816a593dc7e0d6f28aa4b1c2f0f066bdfd7eb8bf1af92e2\",\n    \"res://assets/spine/effect_cat_container/effect_cat_container.tscn\": \"dee40a9e2f08159419300ad5e21a2b347acd3c942cc7f84d8a2492ac9f86b786\",\n    \"res://assets/spine/effect_flowerpot_big/effect_flowerpot_big.tscn\": \"65fbe0115c31a8eadb1af64f8002689d8c6ab76b9c9b0ac73e028320cfac4013\"\n  },\n  \"skin_effects\": {\n    \"bird\": {\n      \"connection\": {\n        \"resources\": [\n          \"res://assets/effect/texture/point/ef_point_008.png\",\n          \"res://assets/effect/texture/point/ef_point_004.png\"\n        ],\n        \"signature\": \"07e6c86fda6a9c5ec97592fc691ef0b115ec584b4251b48ba9d6b1e5e70d0342\"\n      },\n      \"ice_unlock\": {\n        \"resources\": [\n          \"res://assets/effect/texture/point/ef_point_009a.png\",\n          \"res://assets/effect/texture/glow/ef_glow_002.png\"\n        ],\n        \"signature\": \"04d2f506597834989a7052ccb4655b39791d82249b7f4cd4296d0ff9087d24d3\"\n      },\n      \"mystery_reveal\": {\n        \"resources\": [\n          \"res://assets/effect/texture/point/ef_point_009.png\",\n          \"res://assets/effect/texture/glow/ef_ring_001.png\",\n          \"res://assets/effect/texture/glow/ef_glow_002.png\",\n          \"res://assets/effect/texture/point/ef_point_004.png\",\n          \"res://assets/sprites/juice_sort/bird/Image_feather_red.png\",\n          \"res://assets/sprites/juice_sort/bird/Image_feather_purple.png\",\n          \"res://assets/sprites/juice_sort/bird/Image_feather_pink.png\",\n          \"res://assets/sprites/juice_sort/bird/Image_feather_light_blue.png\",\n          \"res://assets/sprites/juice_sort/bird/Image_feather_yellow.png\",\n          \"res://assets/sprites/juice_sort/bird/Image_feather_green.png\",\n          \"res://assets/sprites/juice_sort/bird/Image_feather_blue.png\",\n          \"res://assets/sprites/juice_sort/bird/Image_feather_light_green.png\",\n          \"res://assets/sprites/juice_sort/bird/Image_feather_orange.png\",\n          \"res://assets/sprites/juice_sort/bird/Image_feather_light_purple.png\"\n        ],\n        \"signature\": \"1bbe656c9174679dca7026985fbab0b5884c92a0deb7a8d636a83355354a45d2\"\n      }\n    },\n    \"cat\": {\n      \"connection\": {\n        \"resources\": [\n          \"res://assets/effect/texture/point/ef_point_008.png\",\n          \"res://assets/effect/texture/point/ef_point_004.png\"\n        ],\n        \"signature\": \"07e6c86fda6a9c5ec97592fc691ef0b115ec584b4251b48ba9d6b1e5e70d0342\"\n      },\n      \"ice_unlock\": {\n        \"resources\": [\n          \"res://assets/effect/texture/point/ef_point_009a.png\",\n          \"res://assets/effect/texture/glow/ef_glow_002.png\"\n        ],\n        \"signature\": \"04d2f506597834989a7052ccb4655b39791d82249b7f4cd4296d0ff9087d24d3\"\n      },\n      \"mystery_reveal\": {\n        \"resources\": [\n          \"res://assets/effect/texture/point/ef_point_009.png\",\n          \"res://assets/effect/texture/glow/ef_ring_001.png\",\n          \"res://assets/effect/texture/glow/ef_glow_002.png\",\n          \"res://assets/effect/texture/point/ef_point_004.png\",\n          \"res://assets/effect/texture/cat_paw/paw_red.png\",\n          \"res://assets/effect/texture/cat_paw/paw_purple.png\",\n          \"res://assets/effect/texture/cat_paw/paw_pink.png\",\n          \"res://assets/effect/texture/cat_paw/paw_cyan.png\",\n          \"res://assets/effect/texture/cat_paw/paw_yellow.png\",\n          \"res://assets/effect/texture/cat_paw/paw_green.png\",\n          \"res://assets/effect/texture/cat_paw/paw_blue.png\",\n          \"res://assets/effect/texture/cat_paw/paw_teal.png\",\n          \"res://assets/effect/texture/cat_paw/paw_orange.png\",\n          \"res://assets/effect/texture/cat_paw/paw_lavender.png\"\n        ],\n        \"signature\": \"297c6bd34ec78f1f0b47403cdd557a6464e8f946f3231e9a38aad29dbc82b02b\"\n      }\n    },\n    \"default\": {\n      \"connection\": {\n        \"resources\": [\n          \"res://assets/effect/texture/point/ef_point_008.png\",\n          \"res://assets/effect/texture/point/ef_point_004.png\"\n        ],\n        \"signature\": \"07e6c86fda6a9c5ec97592fc691ef0b115ec584b4251b48ba9d6b1e5e70d0342\"\n      },\n      \"ice_unlock\": {\n        \"resources\": [\n          \"res://assets/effect/texture/point/ef_point_009a.png\",\n          \"res://assets/effect/texture/glow/ef_glow_002.png\"\n        ],\n        \"signature\": \"04d2f506597834989a7052ccb4655b39791d82249b7f4cd4296d0ff9087d24d3\"\n      },\n      \"mystery_reveal\": {\n        \"resources\": [\n          \"res://assets/effect/texture/point/ef_point_009.png\",\n          \"res://assets/effect/texture/glow/ef_ring_001.png\",\n          \"res://assets/effect/texture/glow/ef_glow_002.png\",\n          \"res://assets/effect/texture/point/ef_point_004.png\",\n          \"-\",\n          \"-\",\n          \"-\",\n          \"-\",\n          \"-\",\n          \"-\",\n          \"-\",\n          \"-\",\n          \"-\",\n          \"-\"\n        ],\n        \"signature\": \"83cf64795c4050c1e5c2ec3228c8627c3d8dd2ccaeff4286124927db89a50e92\"\n      }\n    }\n  },\n  \"skin_revisions\": {\n    \"bird\": 19,\n    \"cat\": 21,\n    \"default\": 23\n  },\n  \"skins\": {\n    \"bird\": \"8f417ca8cef3d97e736b85fd6d98ff3476175149a6ba015af9b8511370586159\",\n    \"cat\": \"d449b8f64dc6842bc0287fc262538d1f4c7096de6c188dbb069d6335cd87ba71\",\n    \"default\": \"c27dde4d00495842e7d098dd35d4a70a254aacd6e6abc4327181bc975dfbe32c\"\n  }\n}"













































































































































const GAME_GROUPS: PackedStringArray = ["ice_unlock", "mystery_reveal", "connection"]
const FINISH_GROUPS: PackedStringArray = ["fireworks", "reward_particles", "game_data_cards", "confetti_fall", "confetti_sides", "ad_particles"]
static var _manifest: Dictionary = {}
static var _cache_identity: String = ""
static var _cache_checked: bool = false
static var _process_rendered: Dictionary = {}


static func environment_identity() -> PackedStringArray:
	var version: Dictionary = Engine.get_version_info()
	return PackedStringArray([
		str(version.get("hash", "")), str(version.get("string", "")), 
		RenderingServer.get_current_rendering_method(), 
		RenderingServer.get_video_adapter_vendor(), RenderingServer.get_video_adapter_name(), 
		RenderingServer.get_video_adapter_api_version(), 
	])


static func signature(group: String, skin: JuiceSkinResolver = null) -> String:
	_load_manifest()
	var recipes: Dictionary = _manifest.get("groups", {})
	if not recipes.has(group):
		return ""
	var parts: PackedStringArray = environment_identity()
	parts.append(str(recipes[group]))
	if group in GAME_GROUPS:
		var skin_id: String = String(skin.active_skin.id) if skin != null else "default"
		var revisions: Dictionary = _manifest.get("skin_revisions", {})
		var materials: Dictionary = _manifest.get("skin_effects", {}).get(skin_id, {}).get(group, {})
		if materials.is_empty() or (skin != null and (skin.active_skin.revision != int(revisions.get(skin_id, -1))
				or skin.default_skin.revision != int(revisions.get("default", -1)))):
			return ""
		if skin != null and skin.warmup_asset_paths(group) != PackedStringArray(materials.get("resources", [])):
			return ""
		parts.append(str(materials["signature"]))
	return "|".join(parts).sha256_text()


static func record_key(group: String, skin: JuiceSkinResolver = null) -> String:
	if group in GAME_GROUPS:
		_load_manifest()
		var paths: PackedStringArray = skin.warmup_asset_paths(group) if skin != null else PackedStringArray(
			_manifest.get("skin_effects", {}).get("default", {}).get(group, {}).get("resources", []))

		return group + ":" + "|".join(paths).sha256_text()
	return group + ":" + (String(skin.active_skin.id) if skin != null else "default")



static func scene_contract_signature(scene: PackedScene) -> String:
	_load_manifest()
	return str(_manifest.get("scene_contracts", {}).get(scene.resource_path, ""))


static func needs_full_warmup(group: String, skin: JuiceSkinResolver = null) -> bool:
	var key: String = signature(group, skin)
	if key.is_empty():
		return true

	if _process_rendered.get(record_key(group, skin), "") == key:
		return false
	var cache: String = shader_cache_identity()
	if cache.is_empty():
		return true
	var record: Dictionary = UserState.get_effect_warmup_record(record_key(group, skin))
	return record.get("signature", "") != key or record.get("cache", "") != cache


static func needs_process_particle_warmup() -> bool:

	var adapter: String = " ".join(environment_identity()).to_lower()
	return RenderingServer.get_current_rendering_method() == "gl_compatibility" and "powervr" in adapter


static func needs_render(group: String, skin: JuiceSkinResolver = null) -> bool:
	var key: String = signature(group, skin)
	var rendered: bool = not key.is_empty() and _process_rendered.get(record_key(group, skin), "") == key
	return needs_full_warmup(group, skin) or ( not rendered and needs_process_particle_warmup())


static func needs_any(groups: PackedStringArray, skin: JuiceSkinResolver = null) -> bool:
	for group: String in groups:
		if needs_render(group, skin):
			return true
	return false



static func mark_rendered(group: String, active: Callable, skin: JuiceSkinResolver = null) -> void :
	if DisplayServer.get_name() == "headless" or (active.is_valid() and not active.call()):
		return
	var key: String = signature(group, skin)
	if key.is_empty():
		return
	_process_rendered[record_key(group, skin)] = key
	var cache: String = shader_cache_identity()
	if not cache.is_empty():
		UserState.mark_effect_warmup_record(record_key(group, skin), {"signature": key, "cache": cache})


static func _load_manifest() -> void :
	if not _manifest.is_empty():
		return
	var parsed: Variant = JSON.parse_string(MANIFEST_JSON)
	if parsed is Dictionary and parsed.get("format", 0) == 2:
		_manifest = parsed




static func shader_cache_identity() -> String:
	if _cache_checked:
		return _cache_identity
	_cache_checked = true
	if not bool(ProjectSettings.get_setting("rendering/shader_compiler/shader_cache/enabled", true)):
		return ""
	var base: String = str(Engine.call("get_shader_cache_path")) if Engine.has_method("get_shader_cache_path") else ""
	if base.is_empty() and OS.has_feature("editor"):
		base = ProjectSettings.globalize_path("res://.godot")
	if base.is_empty():
		base = ProjectSettings.globalize_path("user://")
	var cache_path: String = base.path_join("shader_cache")
	if not DirAccess.dir_exists_absolute(cache_path):
		return ""

	var marker: String = cache_path.path_join("pocketsort_warmup_identity")
	if not FileAccess.file_exists(marker):
		var file: = FileAccess.open(marker, FileAccess.WRITE)
		if file == null:
			return ""
		file.store_string("%s:%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()])
		file.close()
	_cache_identity = cache_path + ":" + FileAccess.get_file_as_string(marker)
	return _cache_identity
