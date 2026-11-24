class_name LevelSource
extends RefCounted

signal chapter_data_changed(chapter_index: int)

















const BUILTIN_DEFAULT_PATH: = "res://assets/builtin/chapter_default_1_5.json"
const BUILTIN_BASELINE_PATH: = "res://assets/builtin/chapter_baseline_1_5.json"
const BUILTIN_COVERED_CHAPTERS: = [1, 2, 3, 4, 5]

var _downloader: LevelDownloader
var _experiment_resolver: ContentLevelExperimentResolver

var _chapter_channel: String = LevelDownloader.CHAPTER_CHANNEL_DEFAULT



var _chapters: Dictionary = {}

var _exhausted_chapters: Dictionary = {}

var _last_ab_info: Dictionary = {}


var _debug_csv_candidates: Dictionary = {}
var _debug_csv_chapters: Dictionary = {}
var _debug_csv_title: String = ""













var _experiment_patches: Dictionary = {}
var _experiment_patches_by_key: Dictionary = {}
var _experiment_values: Dictionary = {}
var _experiment_selection_initialized: bool = false
var _experiment_selection_from_sdk: bool = false
var _experiment_restore_loading: bool = false
var _experiment_done: Dictionary = {}
var _experiment_latches: Dictionary = {}
var _experiment_scanned: bool = false






var _experiment_epoch: int = 0
var cold_start_optimized: bool = false
var _memory_epoch: int = 0
var _patch_merge_generation: int = 0
var local_load_failed: bool = false




class _Latch extends RefCounted:
	signal done
	var finished: bool = false


func set_debug_csv_candidates(candidates: Dictionary, title: String) -> void :
	if not OS.has_feature("editor") or OS.has_feature("rel"):
		return
	_debug_csv_candidates = candidates
	_debug_csv_title = title if not candidates.is_empty() else ""
	_debug_csv_chapters = {}
	for level_id: int in candidates:
		var chapter_index: int = LevelIndex.chapter_of(level_id)
		var chapter: ChapterModel = _debug_csv_chapters.get(chapter_index)
		if chapter == null:
			chapter = ChapterModel.new()
			chapter.chapter_index = chapter_index
			_debug_csv_chapters[chapter_index] = chapter
		chapter.level_total = maxi(chapter.level_total, LevelIndex.index_of(level_id))


func debug_csv_level_ids() -> Array:
	return _debug_csv_candidates.keys() if OS.has_feature("editor") and not OS.has_feature("rel") else []


func has_debug_csv_level(level_id: int) -> bool:
	return OS.has_feature("editor") and not OS.has_feature("rel") and _debug_csv_candidates.has(level_id)


func debug_csv_title() -> String:
	return _debug_csv_title


func _init(downloader: LevelDownloader, experiment_resolver: ContentLevelExperimentResolver) -> void :
	_downloader = downloader
	_experiment_resolver = experiment_resolver



func set_chapter_channel(channel: String) -> void :
	if channel == LevelDownloader.CHAPTER_CHANNEL_BASELINE:
		_chapter_channel = LevelDownloader.CHAPTER_CHANNEL_BASELINE
	else:
		_chapter_channel = LevelDownloader.CHAPTER_CHANNEL_DEFAULT


func is_baseline_chapter_channel() -> bool:
	return _chapter_channel == LevelDownloader.CHAPTER_CHANNEL_BASELINE


func _builtin_chapter_path() -> String:
	if _chapter_channel == LevelDownloader.CHAPTER_CHANNEL_BASELINE:
		return BUILTIN_BASELINE_PATH
	return BUILTIN_DEFAULT_PATH












func get_level_model(chapter_index: int, level_index: int) -> LevelModel:
	if level_index < 1 or level_index > LevelIndex.CHAPTER_SIZE:
		return null
	var resolved: Dictionary = _resolve_entry(chapter_index, level_index)
	if not bool(resolved["ok"]):


		var chapter: Dictionary = _chapters.get(chapter_index, {})
		if chapter.is_empty():
			return null
		var by_index: Dictionary = chapter.get("level_candidates_by_index", {})
		if by_index.has(level_index):
			return null
		var fallback_meta: LevelModel = LevelParser.build_level_meta(chapter_index, level_index, {})
		fallback_meta.use_fallback_pool = true
		return fallback_meta
	return LevelParser.build_level_meta(chapter_index, level_index, resolved["merged"] as Dictionary)







func get_downgraded_level_model(chapter_index: int, level_index: int) -> Dictionary:
	var level_id: int = LevelIndex.level_id_of(chapter_index, level_index)
	var candidates: Array[Dictionary] = []
	var patch_candidates: Array[Dictionary] = []
	if has_debug_csv_level(level_id):
		candidates = _debug_csv_candidates[level_id]
	else:
		var chapter: Dictionary = _chapters.get(chapter_index, {})
		if chapter.is_empty():
			return {}
		var candidates_by_index: Dictionary = chapter.get("level_candidates_by_index", {})
		candidates = candidates_by_index.get(level_index, [] as Array[Dictionary])
		patch_candidates = _experiment_patches.get(level_id, [] as Array[Dictionary])
	if candidates.is_empty():
		return {}
	var picked: Dictionary = LevelProvider.pick_downgrade(
		candidates, patch_candidates, _downgrade_tag_chain())
	if picked.is_empty():
		return {}
	var merged: Dictionary = picked["merged"] as Dictionary
	return {
		"model": LevelParser.build_level_meta(chapter_index, level_index, merged), 
		"base_tags": String((picked["base"] as Dictionary).get("levelUserTags", "")), 
		"tags": String(merged.get("levelUserTags", "")), 
	}




func _downgrade_tag_chain() -> Array[Dictionary]:
	var chain: Array[Dictionary] = []
	if not _current_user_tags().is_empty():
		for level: int in range(UserState.get_user_level(), UserLevelLadder.LEVEL_MIN - 1, -1):
			chain.append({UserLevelTag.TAG_KEY: UserLevelLadder.tag_value(level)})
	chain.append({})
	return chain



func get_chapter_cover_url(chapter_index: int, thumbnail: bool) -> String:
	var chapter: Dictionary = _chapters.get(chapter_index, {})
	return String(chapter.get("thumbnail_image_url" if thumbnail else "cover_image_url", ""))



func get_chapter_model(chapter_index: int) -> ChapterModel:
	var chapter: Dictionary = _chapters.get(chapter_index, {})
	if not chapter.is_empty():
		return chapter.get("chapter_meta") as ChapterModel
	return _debug_csv_chapters.get(chapter_index) as ChapterModel




















func _resolve_entry(chapter_index: int, level_index: int) -> Dictionary:
	var miss: Dictionary = {"ok": false, "base": {}, "patch": {}, "merged": {}, 
		"candidates": 0, "patch_candidates": 0}
	var debug_level_id: int = LevelIndex.level_id_of(chapter_index, level_index)
	if has_debug_csv_level(debug_level_id):
		var debug_candidates: Array[Dictionary] = _debug_csv_candidates[debug_level_id]
		var debug_winner: Dictionary = LevelProvider.pick(debug_candidates, _current_user_tags())
		return {"ok": not debug_winner.is_empty(), "base": debug_winner, "patch": {}, 
			"merged": debug_winner, "candidates": debug_candidates.size(), "patch_candidates": 0, 
			"debug_csv": true}
	var chapter: Dictionary = _chapters.get(chapter_index, {})
	if chapter.is_empty():
		return miss
	var candidates_by_index: Dictionary = chapter.get("level_candidates_by_index", {})
	var candidates: Array[Dictionary] = candidates_by_index.get(level_index, [] as Array[Dictionary])
	if candidates.is_empty():
		return miss
	miss["candidates"] = candidates.size()
	var tags: Dictionary = _current_user_tags()
	var base: Dictionary = LevelProvider.pick(candidates, tags)
	if base.is_empty():
		return miss
	var level_id: int = LevelIndex.level_id_of(chapter_index, level_index)
	var patch_candidates: Array[Dictionary] = _experiment_patches.get(
		level_id, [] as Array[Dictionary])
	var patch: Dictionary = {}
	if not patch_candidates.is_empty():
		patch = LevelProvider.pick(patch_candidates, tags)
	return {
		"ok": true, 
		"base": base, 
		"patch": patch, 
		"merged": base if patch.is_empty() else ContentLevelExperimentResolver.merge_entry(base, patch), 
		"candidates": candidates.size(), 
		"patch_candidates": patch_candidates.size(), 
	}











func log_level_resolution(chapter_index: int, level_index: int) -> void :
	var level_id: int = LevelIndex.level_id_of(chapter_index, level_index)
	var head: String = "[LevelSource] 开局取数 关号 %d(第 %d 章第 %d 关)" % [
		level_id, chapter_index, level_index]
	var resolved: Dictionary = _resolve_entry(chapter_index, level_index)
	var base: Dictionary = resolved["base"] as Dictionary
	var patch: Dictionary = resolved["patch"] as Dictionary
	if bool(resolved.get("debug_csv", false)):
		SortLogger.info("%s CSV试玩：%s，候选 %d 份，当前能力 lv%d，levelUserTags=\"%s\"，levelUniqueId=\"%s\"，difficulty=%d" % [
			head, _debug_csv_title, int(resolved["candidates"]), UserState.get_user_level(), 
			String(base.get("levelUserTags", "")), String(base.get("levelUniqueId", "")), 
			int(base.get("difficulty", 1))])
		return

	SortLogger.info("%s ① default：候选 %d 份，levelDataSource=\"%s\" | %s" % [
		head, int(resolved["candidates"]), 
		String(base.get("levelDataSource", "")), _format_entry(base)])

	if patch.is_empty():
		SortLogger.info("%s ② 策略池：无 patch(未配实验 / 尚未到货 / 该用户不适用)，本关走 default"
			%head)
	else:
		var patch_keys: Array = patch.keys()
		patch_keys.sort()
		SortLogger.info("%s ② 策略池 patch：候选 %d 份，levelDataSource=\"%s\"，覆盖字段 %s | %s" % [
			head, int(resolved["patch_candidates"]), 
			String(patch.get("levelDataSource", "")), str(patch_keys), _format_entry(patch)])

	if not bool(resolved["ok"]):
		SortLogger.info("%s ③ 最终选中：%s" % [head, 
			"已发布章节缺关，走玩法兜底池" if get_level_model(chapter_index, level_index) != null
			else "无（章节未装载或候选不可用）"])
		return
	var merged: Dictionary = resolved["merged"] as Dictionary
	var origin: String = "default 原样"
	if not patch.is_empty():
		origin = "default + 策略池 patch(题面已被替换)" if patch.has("initialLayout")\
		else "default + 策略池 patch(题面未变)"
	var layout_note: String = "" if merged.has("initialLayout")\
	else "，章数据无题面(将回落随包兜底池)"
	SortLogger.info("%s ③ 最终选中：%s，levelDataSource=\"%s\"%s | %s" % [
		head, origin, String(merged.get("levelDataSource", "")), 
		layout_note, _format_entry(merged)])








static func _format_entry(entry: Dictionary) -> String:
	if entry.is_empty():
		return "<空>"
	var keys: Array = entry.keys()
	keys.sort()
	var parts: PackedStringArray = PackedStringArray()
	for raw_key: Variant in keys:
		var key: String = str(raw_key)
		if key == "initialLayout":
			parts.append("initialLayout(明文)=%s" % _format_layout(String(entry[raw_key])))
		else:
			parts.append("%s=%s" % [key, str(entry[raw_key])])
	return ", ".join(parts)


static func _format_layout(cipher: String) -> String:
	if cipher.is_empty():
		return "<空>"
	var plain: String = AESDecryptor.decrypt(cipher)
	return plain if not plain.is_empty() else "<解密失败,密文 %d 字符>" % cipher.length()




func is_chapter_resolved(chapter_index: int) -> bool:
	return _debug_csv_chapters.has(chapter_index) or _chapters.has(chapter_index)\
	or bool(_exhausted_chapters.get(chapter_index, false))




func ensure_chapter_loaded(chapter_index: int, total_timeout_sec: float = -1.0) -> Dictionary:
	if _debug_csv_chapters.has(chapter_index):
		return {"ok": true}
	if _exhausted_chapters.get(chapter_index, false):
		SortLogger.info("[LevelSource] ensure_chapter_loaded(%d): 已知到顶，直接返回" % chapter_index)
		return {"ok": true, "exhausted": true}
	if await ensure_local_loaded(chapter_index):
		return {"ok": true}
	SortLogger.info("[LevelSource] ensure_chapter_loaded(%d): 缓存/内置均未命中，强拉网络" % chapter_index)
	return await _refresh_from_network(chapter_index, total_timeout_sec)





func ensure_local_loaded(chapter_index: int) -> bool:
	if _debug_csv_chapters.has(chapter_index):
		return true
	if cold_start_optimized:
		return await ensure_local_loaded_optimized(chapter_index)
	if _chapters.has(chapter_index):
		return true
	if _exhausted_chapters.get(chapter_index, false):
		return false

	var cached: Dictionary = await _downloader.read_cached_bucket(chapter_index)

	if _chapters.has(chapter_index):
		return true
	if _exhausted_chapters.get(chapter_index, false):
		return false
	if bool(cached.get("ok", false)) and not bool(cached.get("exhausted", false)):
		_ingest(cached)
		if _chapters.has(chapter_index):
			SortLogger.info("[LevelSource] ensure_local_loaded(%d): 命中磁盘缓存" % chapter_index)
			return true

	if chapter_index in BUILTIN_COVERED_CHAPTERS:
		_ingest_builtin()
		if _chapters.has(chapter_index):
			SortLogger.info("[LevelSource] ensure_local_loaded(%d): 命中内置兜底" % chapter_index)
			return true
	return false
























func restore_cached_experiments(sdk_ready: bool, group_id: String) -> void :
	if cold_start_optimized:
		await restore_cached_experiments_optimized(sdk_ready, group_id)
		return

	if is_baseline_chapter_channel():
		_experiment_epoch += 1
		_experiment_values.clear()
		_experiment_selection_initialized = true
		_experiment_selection_from_sdk = sdk_ready
		_experiment_restore_loading = false
		_experiment_patches_by_key.clear()
		_experiment_patches.clear()
		_experiment_done.clear()
		_experiment_latches.clear()
		_experiment_scanned = true
		SortLogger.info("[LevelSource] 基线章节渠道：跳过关卡实验恢复与策略池")
		return
	var selected: Dictionary = {}
	if sdk_ready:
		for h: Dictionary in ContentLevelExperimentResolver.collect_keys(_experiment_resolver.all_keys()):
			var key: String = str(h.key)
			selected[key] = _experiment_resolver.value_of(key)
		if not _downloader.save_confirmed_experiment_selection(group_id, selected):
			SortLogger.warn("[LevelSource] 关卡实验分组落盘失败，本次仍使用 SDK 当前分组")
	else:
		var saved: Dictionary = _downloader.read_cached_experiment_selection(group_id)
		for h: Dictionary in ContentLevelExperimentResolver.collect_keys(saved.keys()):
			var key: String = str(h.key)
			if saved[key] is String:
				selected[key] = String(saved[key])
	SortLogger.info("[LevelSource] 关卡实验分组来源=%s，命中 %d 个 key" % [
		"SDK" if sdk_ready else "上次确认缓存", selected.size()])

	if _experiment_selection_initialized and selected == _experiment_values:
		if sdk_ready and not _experiment_selection_from_sdk:
			_experiment_selection_from_sdk = true
			if not _experiment_restore_loading:
				_refresh_selected_experiments()
		return

	if _experiment_selection_initialized:
		SortLogger.info("[LevelSource] 关卡实验分组变化：%s" % _format_selection_diff(
			_experiment_values, selected))

		_experiment_scanned = false



	_experiment_epoch += 1
	var epoch: int = _experiment_epoch
	_experiment_values = selected
	_experiment_selection_initialized = true
	_experiment_selection_from_sdk = sdk_ready
	_experiment_restore_loading = true
	_experiment_patches_by_key.clear()
	_experiment_patches.clear()
	_experiment_done.clear()
	_experiment_latches.clear()

	var restored_by_key: Dictionary = {}
	for h: Dictionary in ContentLevelExperimentResolver.collect_keys(selected.keys()):
		var key: String = str(h.key)
		var value: String = String(selected[key])
		if not ContentLevelExperimentResolver.needs_fetch(value):
			continue
		var cached: Dictionary = await _downloader.read_cached_strategy_pool(value)
		if epoch != _experiment_epoch:
			return
		if bool(cached.get("ok", false)):
			restored_by_key[key] = await _index_strategy_patches(
				cached.get("levels", []) as Array, int(h.start), int(h.end))
			if epoch != _experiment_epoch:
				return
			SortLogger.info("[LevelSource] 关卡实验 %s（value=%s）从磁盘恢复策略池" % [key, value])

	_experiment_patches_by_key = restored_by_key
	_rebuild_experiment_patches()
	_experiment_restore_loading = false
	if _experiment_selection_from_sdk:
		_refresh_selected_experiments()

static func _format_selection_diff(old_values: Dictionary, new_values: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for key: Variant in new_values.keys():
		if not old_values.has(key):
			parts.append("+%s=\"%s\"" % [key, new_values[key]])
		elif String(old_values[key]) != String(new_values[key]):
			parts.append("%s: \"%s\"→\"%s\"" % [key, old_values[key], new_values[key]])
	for key: Variant in old_values.keys():
		if not new_values.has(key):
			parts.append("-%s=\"%s\"" % [key, old_values[key]])
	return ", ".join(parts)



func _refresh_selected_experiments() -> void :
	if not _experiment_selection_from_sdk:
		return
	_dispatch_experiments(1, 2147483647)


func dispatch_experiments_for_chapter(chapter_index: int) -> void :
	if chapter_index <= 0 or is_baseline_chapter_channel():
		return
	await _dispatch_experiments(chapter_index, chapter_index)




func refresh_experiments_after_level(chapter_index: int) -> void :
	if chapter_index <= 0 or is_baseline_chapter_channel()\
	or not _experiment_selection_initialized\
	or not _experiment_selection_from_sdk or _experiment_restore_loading:
		return
	for key: String in ContentLevelExperimentResolver.match_keys_for_chapter(
			_experiment_values.keys(), chapter_index):
		if ContentLevelExperimentResolver.needs_fetch(String(_experiment_values[key])):
			_experiment_done.erase(key)
	await _dispatch_experiments(chapter_index, chapter_index)



func _dispatch_experiments_for_bucket(bucket: Vector2i) -> void :
	await _dispatch_experiments(bucket.x, bucket.y)




func _dispatch_experiments(start: int, end: int) -> void :
	if is_baseline_chapter_channel() or not _experiment_selection_initialized\
	or not _experiment_selection_from_sdk or _experiment_restore_loading:
		return
	var all_keys: Array = _experiment_values.keys()
	if not _experiment_scanned:
		_log_experiment_scan_once(_experiment_resolver.all_keys())
	for key: String in ContentLevelExperimentResolver.match_keys_overlapping(all_keys, start, end):
		await _apply_one_experiment(key)






func _log_experiment_scan_once(all_keys: Array) -> void :
	if _experiment_scanned:
		return

	if all_keys.is_empty():
		_experiment_scanned = true
		SortLogger.info("[LevelSource] 关卡实验扫描 —— SDK 当前无实验，本次运行不启用")
		return
	_experiment_scanned = true
	var hits: Array[Dictionary] = ContentLevelExperimentResolver.collect_keys(all_keys)
	if hits.is_empty():
		SortLogger.info("[LevelSource] 关卡实验扫描 —— %d 个实验里没有 %s* 前缀的，本次运行不启用"
			%[all_keys.size(), ContentLevelExperimentResolver.KEY_PREFIX])
		return
	var lines: PackedStringArray = PackedStringArray()
	for h: Dictionary in hits:
		lines.append("ch%d_%d=\"%s\"" % [int(h.start), int(h.end), 
			String(_experiment_values.get(str(h.key), ""))])
	SortLogger.info("[LevelSource] 关卡实验扫描 —— %d 个实验里命中 %d 个：%s"
		%[all_keys.size(), hits.size(), ", ".join(lines)])



func _apply_one_experiment(key: String) -> void :
	if cold_start_optimized:
		await _apply_one_experiment_optimized(key)
		return
	if _experiment_done.has(key):
		return
	if _experiment_latches.has(key):
		var pending: _Latch = _experiment_latches[key]
		if not pending.finished:
			await pending.done
		return

	var r: Dictionary = ContentLevelExperimentResolver.parse_key(key)
	if not bool(r.ok):
		return





	var value: String = String(_experiment_values.get(key, ""))
	if not ContentLevelExperimentResolver.needs_fetch(value):
		_experiment_done[key] = true
		SortLogger.info("[LevelSource] 关卡实验 %s 无需拉策略池（value=\"%s\"）" % [key, value])
		return

	var latch: = _Latch.new()
	_experiment_latches[key] = latch
	var epoch: int = _experiment_epoch

	var result: Dictionary = await _downloader.fetch_strategy_pool(value)
	if epoch != _experiment_epoch:

		SortLogger.info("[LevelSource] 关卡实验 %s 的响应跨了 clear_cache，丢弃本次结果" % key)
		_release_latch(key, latch)
		return
	if bool(result.get("ok", false)):
		var cached: Dictionary = await _downloader.read_cached_strategy_pool(value)
		if epoch != _experiment_epoch:
			_release_latch(key, latch)
			return
		if bool(cached.get("ok", false)):
			var raw_levels: Array = cached.get("levels", []) as Array
			var patches: Dictionary = await _index_strategy_patches(raw_levels, int(r.start), int(r.end))
			if epoch != _experiment_epoch:
				_release_latch(key, latch)
				return
			_experiment_patches_by_key[key] = patches
			_rebuild_experiment_patches()
			_experiment_done[key] = true
			SortLogger.info("[LevelSource] 关卡实验 %s（value=%s）从缓存采纳 %d/%d 关，区间 %d_%d"
				%[key, value, patches.size(), raw_levels.size(), int(r.start), int(r.end)])
		else:
			SortLogger.warn("[LevelSource] 关卡实验 %s（value=%s）刷新成功但磁盘缓存不可读，下次重试"
				%[key, value])
	elif bool(result.get("not_found", false)):


		_downloader.forget_cached_strategy_pool(value)
		for other_key: Variant in _experiment_values.keys():
			if String(_experiment_values[other_key]) == value:
				_experiment_patches_by_key.erase(other_key)
				_experiment_done[other_key] = true
		_rebuild_experiment_patches()
		SortLogger.info("[LevelSource] 关卡实验 %s 的 config_type 不存在（404，value=%s），本轮不再重试"
			%[key, value])
	else:

		SortLogger.warn("[LevelSource] 关卡实验 %s（value=%s）拉取失败，沿用缓存（如有），下次触发重试"
			%[key, value])

	_release_latch(key, latch)


func _release_latch(key: String, latch: _Latch) -> void :
	latch.finished = true
	if _experiment_latches.get(key) == latch:
		_experiment_latches.erase(key)
	latch.done.emit()




func _rebuild_experiment_patches() -> void :
	if cold_start_optimized:
		await _rebuild_experiment_patches_optimized()
		return
	var rebuilt: Dictionary = {}
	for h: Dictionary in ContentLevelExperimentResolver.collect_keys(_experiment_values.keys()):
		var key: String = str(h.key)
		var patches: Dictionary = _experiment_patches_by_key.get(key, {}) as Dictionary
		for level_id: Variant in patches.keys():
			rebuilt[level_id] = patches[level_id]
	_experiment_patches = rebuilt

func _index_strategy_patches(raw_levels: Array, start: int, end: int) -> Dictionary:
	if cold_start_optimized:
		return await _index_strategy_patches_optimized(raw_levels, start, end)
	const CHUNK_SIZE: int = 100
	var merged: Dictionary = {}
	for offset: int in range(0, raw_levels.size(), CHUNK_SIZE):
		var part: Dictionary = ContentLevelExperimentResolver.index_patches(
			raw_levels.slice(offset, mini(offset + CHUNK_SIZE, raw_levels.size())), start, end)
		for level_id: Variant in part.keys():
			var candidates: Array[Dictionary] = merged.get(level_id, [] as Array[Dictionary])
			candidates.append_array(part[level_id] as Array[Dictionary])
			merged[level_id] = candidates
		if offset + CHUNK_SIZE < raw_levels.size():
			await Engine.get_main_loop().process_frame
	return merged





func force_refresh(chapter_index: int, total_timeout_sec: float = -1.0) -> Dictionary:
	await ensure_local_loaded(chapter_index)
	return await _refresh_from_network(chapter_index, total_timeout_sec)





func _refresh_from_network(chapter_index: int, total_timeout_sec: float) -> Dictionary:
	if cold_start_optimized:
		return await _refresh_from_network_optimized(chapter_index, total_timeout_sec)
	var result: Dictionary = await _downloader.fetch_chapter_bucket(chapter_index, total_timeout_sec)

	var net_info: Dictionary = {
		"url": String(result.get("url", "")), 
		"cost_time": int(result.get("cost_time", 0)), 
	}
	if not bool(result.get("ok", false)):
		SortLogger.info("[LevelSource] force_refresh(%d): 网络请求失败" % chapter_index)

		return result
	if bool(result.get("exhausted", false)):
		var bucket: Vector2i = LevelDownloader.bucket_of(chapter_index)
		if not _downloader.forget_cached_bucket(chapter_index):
			SortLogger.error("[LevelSource] 整批 404 后撤销第 %d_%d 章磁盘缓存索引失败" % [bucket.x, bucket.y])

		for c in range(bucket.x, bucket.y + 1):
			_chapters.erase(c)
		if bucket.x in BUILTIN_COVERED_CHAPTERS:
			_ingest_builtin()
		for c in range(bucket.x, bucket.y + 1):
			if not _chapters.has(c):
				_exhausted_chapters[c] = true
				chapter_data_changed.emit(c)
		SortLogger.info("[LevelSource] force_refresh(%d): 服务端答复批次未配置，内置章继续可用" % chapter_index)
		var exhausted_out: Dictionary = net_info.duplicate()
		exhausted_out["ok"] = true
		exhausted_out["exhausted"] = not _chapters.has(chapter_index)
		return exhausted_out

	if bool(result.get("unchanged", false)) and _chapters.has(chapter_index):
		SortLogger.info("[LevelSource] force_refresh(%d): 强拉成功，内容未变，沿用内存索引" % chapter_index)
	else:
		_ingest(result)
		SortLogger.info("[LevelSource] force_refresh(%d): 强拉成功，已覆盖内存索引" % chapter_index)

	var bucket: Vector2i = LevelDownloader.bucket_of(chapter_index)
	var received: Dictionary = {}
	for raw_chapter: Variant in result.get("chapters", []) as Array:
		if raw_chapter is Dictionary:
			received[int((raw_chapter as Dictionary).get("chapterIndex", 0))] = true
	var builtin_envelopes: Dictionary = {}
	for c in range(bucket.x, bucket.y + 1):
		if received.has(c):
			continue

		if c != chapter_index and not _chapters.has(c):
			continue
		_chapters.erase(c)
		if c in BUILTIN_COVERED_CHAPTERS:
			if builtin_envelopes.is_empty():
				builtin_envelopes = _build_chapter_envelopes(_read_builtin_chapters())
			if builtin_envelopes.has(c):
				_chapters[c] = builtin_envelopes[c]
				_exhausted_chapters.erase(c)
		if not _chapters.has(c):
			_exhausted_chapters[c] = true
		chapter_data_changed.emit(c)
	var missing_chapter: bool = bool(result.get("requested_chapter_missing", false))\
	and not _chapters.has(chapter_index)
	if missing_chapter:
		SortLogger.info("[LevelSource] force_refresh(%d): 服务端批次缺目标章且无内置兜底，确认到顶" % chapter_index)


	_dispatch_experiments_for_bucket(LevelDownloader.bucket_of(chapter_index))
	var ok_out: Dictionary = net_info.duplicate()
	ok_out["ok"] = true
	if missing_chapter:
		ok_out["exhausted"] = true
	return ok_out
func _ingest(result: Dictionary, local_only: bool = false) -> void :
	if cold_start_optimized:
		await _ingest_optimized(result, local_only)
		return
	var envelopes: Dictionary = _build_chapter_envelopes(result.get("chapters", []) as Array)
	var ingested_chapters: Array[int] = []
	for raw_chapter_index: Variant in envelopes.keys():
		var envelope: Dictionary = envelopes[raw_chapter_index] as Dictionary
		var meta: ChapterModel = envelope.get("chapter_meta") as ChapterModel
		_chapters[meta.chapter_index] = envelope
		_exhausted_chapters.erase(meta.chapter_index)
		ingested_chapters.append(meta.chapter_index)
		chapter_data_changed.emit(meta.chapter_index)
	if not ingested_chapters.is_empty():
		SortLogger.info("[LevelSource] _ingest: 第 %s 章已加入内存索引" % [str(ingested_chapters)])
	var raw_ab: Variant = result.get("ab_info")
	if raw_ab is Dictionary:
		_last_ab_info = raw_ab
static func _build_chapter_envelopes(chapters: Array) -> Dictionary:
	var envelopes: Dictionary = {}
	for raw_chapter_variant: Variant in chapters:
		if not (raw_chapter_variant is Dictionary):
			continue
		var envelope: Dictionary = LevelParser.parse_chapter_envelope(raw_chapter_variant)
		var meta: ChapterModel = envelope.get("chapter_meta") as ChapterModel
		if meta == null or meta.chapter_index <= 0:
			continue
		envelopes[meta.chapter_index] = envelope
	return envelopes


func _ingest_builtin() -> void :
	if cold_start_optimized:
		await _ingest_builtin_optimized()
		return
	var chapters: Array = _read_builtin_chapters()
	if not chapters.is_empty():
		_ingest({"chapters": chapters})
func _read_builtin_chapters() -> Array:
	var path: String = _builtin_chapter_path()
	if not FileAccess.file_exists(path):
		SortLogger.error("LevelSource: 内置兜底章节数据不存在 %s（渠道=%s）"
			%[path, _chapter_channel])
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		SortLogger.error("LevelSource: 内置兜底章节数据不是 JSON 对象 %s" % path)
		return []
	var chapters: Variant = (parsed as Dictionary).get("data", [])
	if not (chapters is Array):
		SortLogger.error("LevelSource: 内置兜底章节数据 data 不是数组 %s" % path)
		return []
	return chapters as Array







func _current_user_tags() -> Dictionary:
	var user_level: String = UserLevelLadder.tag_value(UserState.get_user_level())
	if user_level.is_empty():
		return {}
	return {UserLevelTag.TAG_KEY: user_level}



func clear_memory() -> void :
	if cold_start_optimized:
		_memory_epoch += 1
	_chapters.clear()
	_debug_csv_candidates = {}
	_debug_csv_chapters = {}
	_debug_csv_title = ""
	_exhausted_chapters.clear()
	_experiment_patches.clear()
	_experiment_patches_by_key.clear()
	_experiment_values.clear()
	_experiment_selection_initialized = false
	_experiment_selection_from_sdk = false
	_experiment_restore_loading = false
	_experiment_done.clear()
	_experiment_latches.clear()
	_experiment_epoch += 1
	_experiment_scanned = false



func reseed_builtin() -> void :
	if cold_start_optimized:
		await reseed_builtin_optimized()
		return
	_ingest_builtin()
func ensure_local_loaded_optimized(chapter_index: int) -> bool:
	if _chapters.has(chapter_index):
		return true
	if _exhausted_chapters.get(chapter_index, false):
		return false

	var cached: Dictionary = await _downloader.read_cached_bucket(chapter_index)

	if _chapters.has(chapter_index):
		return true
	if _exhausted_chapters.get(chapter_index, false):
		return false
	if bool(cached.get("ok", false)) and not bool(cached.get("exhausted", false)):
		await _ingest(cached, true)
		if _chapters.has(chapter_index):
			SortLogger.info("[LevelSource] ensure_local_loaded(%d): 命中磁盘缓存" % chapter_index)
			return true

	if chapter_index in BUILTIN_COVERED_CHAPTERS:
		await _ingest_builtin()
		if _chapters.has(chapter_index):
			SortLogger.info("[LevelSource] ensure_local_loaded(%d): 命中内置兜底" % chapter_index)
			return true
	return false


func restore_cached_experiments_optimized(sdk_ready: bool, group_id: String) -> void :

	if is_baseline_chapter_channel():
		_experiment_epoch += 1
		_experiment_values.clear()
		_experiment_selection_initialized = true
		_experiment_selection_from_sdk = sdk_ready
		_experiment_restore_loading = false
		_experiment_patches_by_key.clear()
		_experiment_patches.clear()
		_experiment_done.clear()
		_experiment_latches.clear()
		_experiment_scanned = true
		SortLogger.info("[LevelSource] 基线章节渠道：跳过关卡实验恢复与策略池")
		return
	var selected: Dictionary = {}
	if sdk_ready:
		for h: Dictionary in ContentLevelExperimentResolver.collect_keys(_experiment_resolver.all_keys()):
			var key: String = str(h.key)
			selected[key] = _experiment_resolver.value_of(key)
		if not _downloader.save_confirmed_experiment_selection(group_id, selected):
			SortLogger.warn("[LevelSource] 关卡实验分组落盘失败，本次仍使用 SDK 当前分组")
	else:
		var saved: Dictionary = _downloader.read_cached_experiment_selection(group_id)
		for h: Dictionary in ContentLevelExperimentResolver.collect_keys(saved.keys()):
			var key: String = str(h.key)
			if saved[key] is String:
				selected[key] = String(saved[key])
	SortLogger.info("[LevelSource] 关卡实验分组来源=%s，命中 %d 个 key" % [
		"SDK" if sdk_ready else "上次确认缓存", selected.size()])

	if _experiment_selection_initialized and selected == _experiment_values:
		if sdk_ready and not _experiment_selection_from_sdk:
			_experiment_selection_from_sdk = true
			if not _experiment_restore_loading:
				_refresh_selected_experiments()
		return

	if _experiment_selection_initialized:
		SortLogger.info("[LevelSource] 关卡实验分组变化：%s" % _format_selection_diff(
			_experiment_values, selected))

		_experiment_scanned = false



	_experiment_epoch += 1
	var epoch: int = _experiment_epoch
	_experiment_values = selected
	_experiment_selection_initialized = true
	_experiment_selection_from_sdk = sdk_ready
	_experiment_restore_loading = true
	_experiment_patches_by_key.clear()
	_experiment_patches.clear()
	_experiment_done.clear()
	_experiment_latches.clear()

	var restored_by_key: Dictionary = {}
	for h: Dictionary in ContentLevelExperimentResolver.collect_keys(selected.keys()):
		var key: String = str(h.key)
		var value: String = String(selected[key])
		if not ContentLevelExperimentResolver.needs_fetch(value):
			continue
		var cached: Dictionary = await _downloader.read_cached_strategy_pool(value)
		if epoch != _experiment_epoch:
			return
		if bool(cached.get("ok", false)):
			restored_by_key[key] = await _index_strategy_patches(
				cached.get("levels", []) as Array, int(h.start), int(h.end))
			if epoch != _experiment_epoch:
				return
			SortLogger.info("[LevelSource] 关卡实验 %s（value=%s）从磁盘恢复策略池" % [key, value])

	_experiment_patches_by_key = restored_by_key
	await _rebuild_experiment_patches()
	if epoch != _experiment_epoch:
		return
	_experiment_restore_loading = false
	if _experiment_selection_from_sdk:
		_refresh_selected_experiments()


func _apply_one_experiment_optimized(key: String) -> void :
	if _experiment_done.has(key):
		return
	if _experiment_latches.has(key):
		var pending: _Latch = _experiment_latches[key]
		if not pending.finished:
			await pending.done
		return

	var r: Dictionary = ContentLevelExperimentResolver.parse_key(key)
	if not bool(r.ok):
		return





	var value: String = String(_experiment_values.get(key, ""))
	if not ContentLevelExperimentResolver.needs_fetch(value):
		_experiment_done[key] = true
		SortLogger.info("[LevelSource] 关卡实验 %s 无需拉策略池（value=\"%s\"）" % [key, value])
		return

	var latch: = _Latch.new()
	_experiment_latches[key] = latch
	var epoch: int = _experiment_epoch

	var result: Dictionary = await _downloader.fetch_strategy_pool(value)
	if epoch != _experiment_epoch:

		SortLogger.info("[LevelSource] 关卡实验 %s 的响应跨了 clear_cache，丢弃本次结果" % key)
		_release_latch(key, latch)
		return
	if bool(result.get("ok", false)):
		var cached: Dictionary = await _downloader.read_cached_strategy_pool(value)
		if epoch != _experiment_epoch:
			_release_latch(key, latch)
			return
		if bool(cached.get("ok", false)):
			var raw_levels: Array = cached.get("levels", []) as Array
			var patches: Dictionary = await _index_strategy_patches(raw_levels, int(r.start), int(r.end))
			if epoch != _experiment_epoch:
				_release_latch(key, latch)
				return
			_experiment_patches_by_key[key] = patches
			await _rebuild_experiment_patches()
			if epoch != _experiment_epoch:
				_release_latch(key, latch)
				return
			_experiment_done[key] = true
			SortLogger.info("[LevelSource] 关卡实验 %s（value=%s）从缓存采纳 %d/%d 关，区间 %d_%d"
				%[key, value, patches.size(), raw_levels.size(), int(r.start), int(r.end)])
		else:
			SortLogger.warn("[LevelSource] 关卡实验 %s（value=%s）刷新成功但磁盘缓存不可读，下次重试"
				%[key, value])
	elif bool(result.get("not_found", false)):


		_downloader.forget_cached_strategy_pool(value)
		for other_key: Variant in _experiment_values.keys():
			if String(_experiment_values[other_key]) == value:
				_experiment_patches_by_key.erase(other_key)
				_experiment_done[other_key] = true
		await _rebuild_experiment_patches()
		if epoch != _experiment_epoch:
			_release_latch(key, latch)
			return
		SortLogger.info("[LevelSource] 关卡实验 %s 的 config_type 不存在（404，value=%s），本轮不再重试"
			%[key, value])
	else:

		SortLogger.warn("[LevelSource] 关卡实验 %s（value=%s）拉取失败，沿用缓存（如有），下次触发重试"
			%[key, value])

	_release_latch(key, latch)


func _rebuild_experiment_patches_optimized() -> void :
	_patch_merge_generation += 1
	var generation: int = _patch_merge_generation
	var epoch: int = _experiment_epoch
	var by_key: Dictionary = _experiment_patches_by_key.duplicate()
	var headers: Array[Dictionary] = ContentLevelExperimentResolver.collect_keys(_experiment_values.keys())
	var rebuilt: Dictionary = {}
	var started: int = Time.get_ticks_usec()
	for h: Dictionary in headers:
		var key: String = str(h.key)
		var patches: Dictionary = by_key.get(key, {}) as Dictionary
		for level_id: Variant in patches:
			rebuilt[level_id] = patches[level_id]
			if Time.get_ticks_usec() - started >= 2000:
				await Engine.get_main_loop().process_frame
				if epoch != _experiment_epoch or generation != _patch_merge_generation:
					return
				started = Time.get_ticks_usec()
	if epoch == _experiment_epoch and generation == _patch_merge_generation:
		_experiment_patches = rebuilt


func _index_strategy_patches_optimized(raw_levels: Array, start: int, end: int) -> Dictionary:
	var epoch: int = _experiment_epoch
	var merged: Dictionary = {}
	var started: int = Time.get_ticks_usec()
	for entry: Variant in raw_levels:
		var part: Dictionary = ContentLevelExperimentResolver.index_patches([entry], start, end)
		for level_id: Variant in part:
			var candidates: Array[Dictionary] = merged.get(level_id, [] as Array[Dictionary])
			candidates.append_array(part[level_id] as Array[Dictionary])
			merged[level_id] = candidates
		if Time.get_ticks_usec() - started >= 2000:
			await Engine.get_main_loop().process_frame
			if epoch != _experiment_epoch:
				return {}
			started = Time.get_ticks_usec()
	return merged

func _refresh_from_network_optimized(chapter_index: int, total_timeout_sec: float) -> Dictionary:
	var memory_epoch: int = _memory_epoch
	var result: Dictionary = await _downloader.fetch_chapter_bucket(chapter_index, total_timeout_sec)
	if memory_epoch != _memory_epoch:
		return {"ok": false, "stale": true}

	var net_info: Dictionary = {
		"url": String(result.get("url", "")), 
		"cost_time": int(result.get("cost_time", 0)), 
	}
	if not bool(result.get("ok", false)):
		SortLogger.info("[LevelSource] force_refresh(%d): 网络请求失败" % chapter_index)

		return result
	if bool(result.get("exhausted", false)):
		var bucket: Vector2i = LevelDownloader.bucket_of(chapter_index)
		if not _downloader.forget_cached_bucket(chapter_index):
			SortLogger.error("[LevelSource] 整批 404 后撤销第 %d_%d 章磁盘缓存索引失败" % [bucket.x, bucket.y])

		for c in range(bucket.x, bucket.y + 1):
			_chapters.erase(c)
		if bucket.x in BUILTIN_COVERED_CHAPTERS:
			await _ingest_builtin()
			if memory_epoch != _memory_epoch:
				return {"ok": false, "stale": true}
		for c in range(bucket.x, bucket.y + 1):
			if not _chapters.has(c):
				_exhausted_chapters[c] = true
				chapter_data_changed.emit(c)
		SortLogger.info("[LevelSource] force_refresh(%d): 服务端答复批次未配置，内置章继续可用" % chapter_index)
		var exhausted_out: Dictionary = net_info.duplicate()
		exhausted_out["ok"] = true
		exhausted_out["exhausted"] = not _chapters.has(chapter_index)
		return exhausted_out

	if bool(result.get("unchanged", false)) and _chapters.has(chapter_index):
		SortLogger.info("[LevelSource] force_refresh(%d): 强拉成功，内容未变，沿用内存索引" % chapter_index)
	else:
		await _ingest(result)
		if memory_epoch != _memory_epoch:
			return {"ok": false, "stale": true}
		SortLogger.info("[LevelSource] force_refresh(%d): 强拉成功，已覆盖内存索引" % chapter_index)

	var bucket: Vector2i = LevelDownloader.bucket_of(chapter_index)
	var received: Dictionary = {}
	for raw_chapter: Variant in result.get("chapters", []) as Array:
		if raw_chapter is Dictionary:
			received[int((raw_chapter as Dictionary).get("chapterIndex", 0))] = true
	var builtin_envelopes: Dictionary = {}
	for c in range(bucket.x, bucket.y + 1):
		if received.has(c):
			continue

		if c != chapter_index and not _chapters.has(c):
			continue
		_chapters.erase(c)
		if c in BUILTIN_COVERED_CHAPTERS:
			if builtin_envelopes.is_empty():
				builtin_envelopes = await _load_builtin_envelopes()
				if memory_epoch != _memory_epoch:
					return {"ok": false, "stale": true}
			if builtin_envelopes.has(c):
				_chapters[c] = builtin_envelopes[c]
				_exhausted_chapters.erase(c)
		if not _chapters.has(c):
			_exhausted_chapters[c] = true
		chapter_data_changed.emit(c)
	var missing_chapter: bool = bool(result.get("requested_chapter_missing", false))\
	and not _chapters.has(chapter_index)
	if missing_chapter:
		SortLogger.info("[LevelSource] force_refresh(%d): 服务端批次缺目标章且无内置兜底，确认到顶" % chapter_index)


	_dispatch_experiments_for_bucket(LevelDownloader.bucket_of(chapter_index))
	var ok_out: Dictionary = net_info.duplicate()
	ok_out["ok"] = true
	if missing_chapter:
		ok_out["exhausted"] = true
	return ok_out


func _ingest_optimized(result: Dictionary, local_only: bool = false) -> void :
	var epoch: int = _memory_epoch
	var envelopes: Dictionary = await _run_envelope_worker(_build_chapter_envelopes.bind(result.get("chapters", []) as Array))
	if epoch != _memory_epoch:
		return
	_commit_envelopes(envelopes, local_only)
	var raw_ab: Variant = result.get("ab_info")
	if raw_ab is Dictionary:
		_last_ab_info = raw_ab


func _ingest_builtin_optimized() -> void :
	var epoch: int = _memory_epoch
	var envelopes: Dictionary = await _load_builtin_envelopes()
	if epoch == _memory_epoch:
		_commit_envelopes(envelopes, true)


func reseed_builtin_optimized() -> void :
	await _ingest_builtin()


func _commit_envelopes(envelopes: Dictionary, local_only: bool = false) -> void :
	var ingested_chapters: Array[int] = []
	for raw_chapter_index: Variant in envelopes.keys():
		var envelope: Dictionary = envelopes[raw_chapter_index] as Dictionary
		var meta: ChapterModel = envelope.get("chapter_meta") as ChapterModel
		if local_only and (_chapters.has(meta.chapter_index) or _exhausted_chapters.has(meta.chapter_index)):
			continue
		_chapters[meta.chapter_index] = envelope
		_exhausted_chapters.erase(meta.chapter_index)
		ingested_chapters.append(meta.chapter_index)
		chapter_data_changed.emit(meta.chapter_index)
	if not ingested_chapters.is_empty():
		SortLogger.info("[LevelSource] _ingest: 第 %s 章已加入内存索引" % [str(ingested_chapters)])


func _run_envelope_worker(work: Callable) -> Dictionary:
	var worker: = Thread.new()
	if worker.start(work) != OK:
		SortLogger.error("LevelSource: 章节索引线程启动失败")
		local_load_failed = true
		return {}
	while worker.is_alive():
		await Engine.get_main_loop().process_frame
	var result: Dictionary = worker.wait_to_finish()
	if result.has("error"):
		local_load_failed = true
		SortLogger.error("LevelSource: %s" % result["error"])
		return {}
	return result


func _load_builtin_envelopes() -> Dictionary:
	return await _run_envelope_worker(_read_builtin_envelopes.bind(_builtin_chapter_path()))


static func _read_builtin_envelopes(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or not parsed.get("data", []) is Array:
		return {"error": "内置章节无效: " + path}
	return _build_chapter_envelopes(parsed.get("data", []))
