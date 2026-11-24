extends Node








class FakeAbGateway extends RefCounted:
	var published: Dictionary = {}
	var values: Dictionary = {}
	var ready: bool = true

	func is_ab_init_done() -> bool:
		return ready

	func get_all_ab_experiments() -> Dictionary:
		return published

	func get_ab_string(key: String, default_value: String = "") -> String:
		return String(values.get(key, default_value))

	func dye_ab(_key: String) -> void :
		pass


class FakeLevelDownloader extends LevelDownloader:
	signal strategy_released

	var default_result: Dictionary = {"ok": false}
	var strategy_results: Dictionary = {}
	var strategy_cache: Dictionary = {}
	var saved_selection: Dictionary = {}
	var saved_group_id: String = ""
	var fallback_strategy_result: Dictionary = {"ok": false}
	var requested: Array[String] = []
	var defer_strategy: bool = false
	var cached_bucket_result: Dictionary = {"ok": false}
	var forgotten_buckets: Array[int] = []

	func read_cached_bucket(_chapter_index: int) -> Dictionary:
		return cached_bucket_result.duplicate(true)

	func forget_cached_bucket(chapter_index: int) -> bool:
		forgotten_buckets.append(chapter_index)
		cached_bucket_result = {"ok": false}
		return true

	func fetch_chapter_bucket(_chapter_index: int, _total_timeout_sec: float = -1.0) -> Dictionary:
		return default_result

	func fetch_strategy_pool(strategy: String) -> Dictionary:
		requested.append(strategy)
		if defer_strategy:
			await strategy_released
		var result: Dictionary = strategy_results.get(strategy, fallback_strategy_result) as Dictionary
		if bool(result.get("ok", false)):
			strategy_cache[strategy] = result.duplicate(true)
		return result

	func read_cached_strategy_pool(strategy: String) -> Dictionary:
		return (strategy_cache.get(strategy, {"ok": false}) as Dictionary).duplicate(true)

	func read_cached_experiment_selection(current_group_id: String) -> Dictionary:
		if not saved_group_id.is_empty() and not current_group_id.is_empty()\
		and saved_group_id != current_group_id:
			return {}
		return saved_selection.duplicate(true)

	func save_confirmed_experiment_selection(group_id: String, values: Dictionary) -> bool:
		saved_group_id = group_id
		saved_selection = values.duplicate(true)
		return true

	func forget_cached_strategy_pool(strategy: String) -> void :
		strategy_cache.erase(strategy)



class FakeBucketFetchDownloader extends LevelDownloader:
	var result: Dictionary = {"ok": false}
	var last_config_type: String = ""
	var last_cache_key: String = ""


	func read_cached_bucket(_chapter_index: int) -> Dictionary:
		return {"ok": false}

	func _fetch_config(config_type: String, cache_key: String, _is_default_bucket: bool, 
			_deadline_msec: int) -> Dictionary:
		last_config_type = config_type
		last_cache_key = cache_key
		return result.duplicate(true)



class FakeLevelSource extends LevelSource:
	var tags: Dictionary = {}

	func _current_user_tags() -> Dictionary:
		return tags


class RecordingLevelSource extends LevelSource:
	var requested_chapters: Array[int] = []

	func force_refresh(chapter_index: int, _total_timeout_sec: float = -1.0) -> Dictionary:
		requested_chapters.append(chapter_index)
		return {"ok": true}

	func get_chapter_model(_chapter_index: int) -> ChapterModel:
		var meta: = ChapterModel.new()
		meta.level_total = 0
		return meta


class FakeLevelSaver extends LevelSaver:
	var completed_levels: Dictionary = {}
	var saved_entities: Dictionary = {}

	func load_entity(level_id: int) -> LevelEntity:
		if saved_entities.has(level_id):
			return saved_entities[level_id] as LevelEntity
		if not completed_levels.has(level_id):
			return null
		var entity: LevelEntity = LevelEntity.for_level(level_id)
		entity.completed = bool(completed_levels[level_id])
		return entity


class FakeResumeParser extends LevelParser:
	var parser_type: String = ""
	var calls: int = 0

	func gameplay_type() -> String:
		return parser_type

	func model_from_dict(d: Dictionary) -> LevelModel:
		calls += 1
		var model: = LevelModel.new()
		model.from_dict(d)
		return model


var _ok: bool = true
var _checks: int = 0


func _ready() -> void :
	_test_chapter_end_gate()
	_test_completed_chapter_proof()
	_test_resumed_parser_uses_snapshot()
	await _test_empty_chapter_prefetch_boundary()
	await _test_field_level_merge()
	await _test_patch_with_user_tag_routing()
	await _test_patch_never_joins_candidates()
	await _test_range_and_cross_chapter_gate()
	await _test_pool_multi_candidate_by_tag()
	await _test_patch_does_not_extend_default()
	await _test_partial_bucket_end()
	await _test_missing_middle_level_recovery()
	await _test_empty_chapter_fallback()
	await _test_survives_default_refresh()
	await _test_idempotent_and_failure_modes()
	await _test_refresh_after_level()
	await _test_local_first_refresh()
	await _test_confirmed_missing_replaces_cache()
	await _test_chunked_patch_index()
	await _test_cold_restart_cache()
	await _test_session_follows_sdk()
	await _test_clear_memory()
	await _test_baseline_chapter_channel()
	_finish()


func _test_chapter_end_gate() -> void :
	_chk("15 不是章末关", not LevelIndex.is_chapter_end(15))
	_chk("24 不是章末关", not LevelIndex.is_chapter_end(24))
	_chk("25 是章末关", LevelIndex.is_chapter_end(25))
	_chk("124 不是章末关", not LevelIndex.is_chapter_end(124))
	_chk("125 是章末关", LevelIndex.is_chapter_end(125))
	_chk("0 和负数不是有效章末关", not LevelIndex.is_chapter_end(0)
		and not LevelIndex.is_chapter_end(-25))
	_chk("每 25 关都是 Coming Soon 门槛", 
		LevelIndex.is_coming_soon_boundary(25)
		and LevelIndex.is_coming_soon_boundary(50)
		and LevelIndex.is_coming_soon_boundary(100)
		and LevelIndex.is_coming_soon_boundary(125))
	_chk("章内关不是 Coming Soon 门槛", 
		not LevelIndex.is_coming_soon_boundary(24)
		and not LevelIndex.is_coming_soon_boundary(26))
	_chk("非正数不满足 Coming Soon 门槛", 
		not LevelIndex.is_coming_soon_boundary(0)
		and not LevelIndex.is_coming_soon_boundary(-25))


func _test_completed_chapter_proof() -> void :
	var original: LevelSaver = LevelManager._saver
	var fake: = FakeLevelSaver.new()
	LevelManager._saver = fake
	_chk("跳到 26 但没有第 25 关通关行不算 Coming Soon 证据", 
		not LevelManager.has_completed_coming_soon_before(26))
	fake.completed_levels[25] = false
	_chk("第 25 关未完成行也不算 Coming Soon 证据", 
		not LevelManager.has_completed_coming_soon_before(26))
	fake.completed_levels[25] = true
	fake.completed_levels[50] = true
	fake.completed_levels[125] = true
	_chk("第 25/50/125 关有完成行才有 Coming Soon 证据", 
		LevelManager.has_completed_coming_soon_before(26)
		and LevelManager.has_completed_coming_soon_before(51)
		and LevelManager.has_completed_coming_soon_before(126))
	_chk("完成第 15 关不能把缺第 16 关视作 Coming Soon", 
		not LevelManager.has_completed_coming_soon_before(16))
	LevelManager._saver = original


func _test_resumed_parser_uses_snapshot() -> void :
	var original_saver: LevelSaver = LevelManager._saver
	var original_source: LevelSource = LevelManager._source
	var original_parsers: Dictionary = LevelManager._parsers
	var saver: = FakeLevelSaver.new()
	var level_id: int = LevelIndex.level_id_of(6, 1)
	var entity: LevelEntity = LevelEntity.for_level(level_id)
	entity.current_state = {"cols": [1]}
	entity.raw_level_info = {"level_id": level_id, "gameplay_type": "legacy"}
	saver.saved_entities[level_id] = entity
	var legacy: = FakeResumeParser.new()
	legacy.parser_type = "legacy"
	var newer: = FakeResumeParser.new()
	newer.parser_type = "new"
	var default_parser: = FakeResumeParser.new()
	LevelManager._saver = saver
	LevelManager._parsers = {"legacy": legacy, "new": newer, "": default_parser}
	var dl: = FakeLevelDownloader.new()
	add_child(dl)
	var source: = FakeLevelSource.new(dl, 
		ContentLevelExperimentResolver.new(FakeAbGateway.new()))
	var current_entry: Dictionary = _level(1, "uid-new", "default", "LAYOUT")
	current_entry["gameplayType"] = "new"
	source._ingest({"chapters": [_chapter(6, [current_entry])]})
	LevelManager._source = source
	var resumed: Dictionary = LevelManager.load_resumed_level(level_id)
	_chk("续局忽略刷新后的玩法类型，使用冻结快照的 parser", 
		bool(resumed.get("resumed", false)) and legacy.calls == 1 and newer.calls == 0)
	source.clear_memory()
	resumed = LevelManager.load_resumed_level(level_id)
	_chk("当前章完全缺失时仍能用快照续局", 
		bool(resumed.get("resumed", false)) and legacy.calls == 2
		and default_parser.calls == 0)
	LevelManager._saver = original_saver
	LevelManager._source = original_source
	LevelManager._parsers = original_parsers


func _test_empty_chapter_prefetch_boundary() -> void :
	var original: LevelSource = LevelManager._source
	var downloader: = FakeLevelDownloader.new()
	add_child(downloader)
	var recording: = RecordingLevelSource.new(downloader, 
		ContentLevelExperimentResolver.new(FakeAbGateway.new()))
	LevelManager._source = recording
	await LevelManager._advance_chapter_data(15)
	_chk("空章第 15 关不会提前预取下一章", recording.requested_chapters == [1])
	recording.requested_chapters.clear()
	await LevelManager._advance_chapter_data(22)
	_chk("空章依固定 25 关章末阈值预取下一章", recording.requested_chapters == [1, 2])
	LevelManager._source = original



func _test_field_level_merge() -> void :
	var ctx: Dictionary = _make({"content_sg||level||6_6": "pool_a"}, 
		{"pool_a": {"ok": true, "levels": [_patch(6, 1, {
			"initialLayout": "LAYOUT-POOL", "levelDataSource": "pool", "difficultyType": "Hard", 
		})]}})
	var src: LevelSource = ctx.source
	await src.force_refresh(6)
	await get_tree().process_frame

	var m: LevelModel = src.get_level_model(6, 1)
	_chk("patch 生效: level_data_source", m != null and m.level_data_source == "pool")
	_chk("patch 生效: difficulty_type", m != null and m.difficulty_type == "Hard")
	_chk("patch 生效: 题面换成策略池的", 
		m != null and String(m.raw_entry.get("initialLayout", "")) == "LAYOUT-POOL")

	_chk("保留 default: level_unique_id", m != null and m.level_unique_id == "uid-6-1")
	_chk("保留 default: level_user_tags", m != null and m.level_user_tags == "default")
	_chk("保留 default: stepLimit", m != null and int(m.raw_entry.get("stepLimit", -1)) == 7)
	_chk("保留 default: imageUrl", 
		m != null and String(m.raw_entry.get("imageUrl", "")) == "img-6-1")

	var cm: ChapterModel = src.get_chapter_model(6)
	_chk("章 title 不受实验影响", cm != null and not cm.title.is_empty())



	_chk("章 level_total 只由 default 决定（含既存的候选重复计数）", 
		cm != null and cm.level_total == 3)

	var base: Dictionary = (src._chapters[6]["level_candidates_by_index"][1] as Array)[0]
	_chk("default 基线未被原地污染", String(base.get("levelDataSource", "")) == "full")



func _test_patch_with_user_tag_routing() -> void :
	var ctx: Dictionary = _make({"content_sg||level||6_6": "pool_a"}, 
		{"pool_a": {"ok": true, "levels": [_patch(6, 2, {"levelDataSource": "pool"})]}})
	var src: FakeLevelSource = ctx.source
	await src.force_refresh(6)
	await get_tree().process_frame

	src.tags = {}
	var m_default: LevelModel = src.get_level_model(6, 2)
	_chk("无标签 → 选中 default 候选", 
		m_default != null and m_default.level_unique_id == "uid-6-2-default")
	_chk("无标签 → patch 仍生效", m_default != null and m_default.level_data_source == "pool")

	src.tags = {"country": "US"}
	var m_us: LevelModel = src.get_level_model(6, 2)
	_chk("命中标签 → 选中人群候选", 
		m_us != null and m_us.level_unique_id == "uid-6-2-us")
	_chk("命中标签 → patch 跟到新 winner 身上", 
		m_us != null and m_us.level_data_source == "pool")
	_chk("命中标签 → winner 的 levelUserTags 保留", 
		m_us != null and m_us.level_user_tags == "country:US")



func _test_patch_never_joins_candidates() -> void :
	var ctx: Dictionary = _make({"content_sg||level||6_6": "pool_a"}, 
		{"pool_a": {"ok": true, "levels": [
			_patch(6, 1, {"levelUserTags": "country:JP", "levelDataSource": "pool"}), 
		]}})
	var src: FakeLevelSource = ctx.source
	await src.force_refresh(6)
	await get_tree().process_frame
	src.tags = {}
	var m: LevelModel = src.get_level_model(6, 1)
	_chk("patch 不命中标签时仍能取到关卡", m != null)
	_chk("patch 不命中标签时回落 default 数据", m != null and m.level_data_source == "full")


func _test_range_and_cross_chapter_gate() -> void :
	var ctx: Dictionary = _make({"content_sg||level||6_6": "pool_a"}, 
		{"pool_a": {"ok": true, "levels": [
			_patch(7, 1, {"levelDataSource": "out-of-range"}), 
			_patch(6, 30, {"levelDataSource": "cross-chapter"}), 
		]}})
	var src: LevelSource = ctx.source
	await src.force_refresh(6)
	await get_tree().process_frame
	var m7: LevelModel = src.get_level_model(7, 1)
	_chk("区间外章的 patch 被丢弃", m7 != null and m7.level_data_source == "full")
	_chk("跨章闸门：越界条目没落进 patch 表", src._experiment_patches.is_empty())



func _test_pool_multi_candidate_by_tag() -> void :
	var ctx: Dictionary = _make({"content_sg||level||6_6": "pool_a"}, 
		{"pool_a": {"ok": true, "levels": [
			_patch(6, 1, {"levelUserTags": "country:US", "levelDataSource": "pool-us"}), 
			_patch(6, 1, {"levelUserTags": "default", "levelDataSource": "pool-default"}), 
		]}})
	var src: FakeLevelSource = ctx.source
	await src.force_refresh(6)
	await get_tree().process_frame

	src.tags = {}
	var m_default: LevelModel = src.get_level_model(6, 1)
	_chk("策略池多候选 无标签 → 取 default 那份 patch", 
		m_default != null and m_default.level_data_source == "pool-default")
	src.tags = {"country": "US"}
	var m_us: LevelModel = src.get_level_model(6, 1)
	_chk("策略池多候选 命中标签 → 取人群那份 patch", 
		m_us != null and m_us.level_data_source == "pool-us")



func _test_patch_does_not_extend_default() -> void :
	var ctx: Dictionary = _make({"content_sg||level||6_11": "pool_a"}, 
		{"pool_a": {"ok": true, "levels": [
			_patch(6, 5, {"levelDataSource": "pool"}), 
			_patch(11, 1, {"levelDataSource": "pool"}), 
		]}})
	var src: LevelSource = ctx.source
	await src.force_refresh(6)
	await get_tree().process_frame
	var fallback_meta: LevelModel = src.get_level_model(6, 5)
	_chk("default 缺该关 → 仅用运行期兜底标记，不采纳 patch", 
		fallback_meta != null and fallback_meta.use_fallback_pool
		and fallback_meta.level_data_source != "pool" and fallback_meta.raw_entry.is_empty())
	_chk("default 缺该章 → patch 不生效", src.get_level_model(11, 1) == null)
	_chk("default 缺该章 → 不误报章元数据", src.get_chapter_model(11) == null)
	_chk("patch 已落表但未生效（说明拦在查询侧而非落表侧）", 
		src._experiment_patches.has(LevelIndex.level_id_of(6, 5)))



func _test_local_first_refresh() -> void :
	var dl: = FakeLevelDownloader.new()
	add_child(dl)
	var src: = FakeLevelSource.new(dl, ContentLevelExperimentResolver.new(FakeAbGateway.new()))
	var changed: Array[int] = []
	src.chapter_data_changed.connect( func(chapter_index: int) -> void :
		changed.append(chapter_index))
	dl.default_result = {"ok": false}
	await src.force_refresh(6)
	_chk("本地与网络都没有 → 仍未知、不置到顶、不通知", 
		not src.is_chapter_resolved(6) and changed.is_empty())

	dl.cached_bucket_result = {"ok": true, "chapters": [
		_chapter(6, [_level(1, "uid-6-1-disk", "default", "LAYOUT-DISK")])]}
	var result: Dictionary = await src.force_refresh(6)
	var disk_meta: LevelModel = src.get_level_model(6, 1)
	_chk("弱网强拉失败 → 直接使用磁盘缓存", not bool(result.get("ok", false))
		and disk_meta != null and disk_meta.level_unique_id == "uid-6-1-disk")
	_chk("本地装入后通知页面恢复", 6 in changed)

	var before_unchanged: int = changed.size()
	dl.default_result = {"ok": true, "unchanged": true, "chapters": [
		_chapter(6, [_level(1, "uid-6-1-disk", "default", "LAYOUT-DISK")])]}
	await src.force_refresh(6)
	_chk("远端内容未变 → 不重复 ingest", changed.size() == before_unchanged)

	dl.default_result = {"ok": true, "chapters": [
		_chapter(6, [_level(1, "uid-6-1-new", "default", "LAYOUT-NEW")])]}
	await src.force_refresh(6)
	_chk("远端内容变化 → 覆盖内存并通知", 
		src.get_level_model(6, 1).level_unique_id == "uid-6-1-new"
		and changed.size() > before_unchanged)

	var exhausted_src: = FakeLevelSource.new(dl, ContentLevelExperimentResolver.new(FakeAbGateway.new()))
	dl.cached_bucket_result = {"ok": false}
	dl.default_result = {"ok": true, "exhausted": true}
	await exhausted_src.force_refresh(6)
	dl.cached_bucket_result = {"ok": true, "chapters": [
		_chapter(6, [_level(1, "uid-6-1-disk", "default", "LAYOUT-DISK")])]}
	var loaded: bool = await exhausted_src.ensure_local_loaded(6)
	_chk("本进程已确认到顶 → 旧磁盘缓存不得翻回", 
		not loaded and exhausted_src.get_level_model(6, 1) == null)


func _test_confirmed_missing_replaces_cache() -> void :
	var dl: = FakeLevelDownloader.new()
	add_child(dl)
	dl.cached_bucket_result = {"ok": true, "chapters": [
		_chapter(6, [_level(1, "old-six", "default", "LAYOUT")])]}
	dl.default_result = {"ok": true, "exhausted": true}
	var src: = FakeLevelSource.new(dl, ContentLevelExperimentResolver.new(FakeAbGateway.new()))
	await src.force_refresh(6)
	_chk("整批 404 撤销第 6 章内存缓存", src.get_level_model(6, 1) == null
		and src.is_chapter_resolved(6))
	_chk("整批 404 撤销磁盘批次索引", dl.forgotten_buckets == [6])
	var restarted: = FakeLevelSource.new(dl, ContentLevelExperimentResolver.new(FakeAbGateway.new()))
	var restored: bool = await restarted.ensure_local_loaded(6)
	_chk("冷启动不会把明确撤销的下载章读回来", not restored)
	dl.default_result = {"ok": true, "chapters": [
		_chapter(6, [_level(1, "republished-six", "default", "LAYOUT")])]}
	await src.force_refresh(6)
	_chk("服务端重新发布后本进程可恢复第 6 章", 
		src.get_level_model(6, 1) != null and not src._exhausted_chapters.has(6))

	var builtin_dl: = FakeLevelDownloader.new()
	add_child(builtin_dl)
	builtin_dl.cached_bucket_result = {"ok": true, "chapters": [
		_chapter(1, [_level(1, "old-one", "default", "LAYOUT")])]}
	builtin_dl.default_result = {"ok": true, "exhausted": true}
	var builtin_src: = FakeLevelSource.new(builtin_dl, 
		ContentLevelExperimentResolver.new(FakeAbGateway.new()))
	await builtin_src.force_refresh(1)
	var builtin_meta: LevelModel = builtin_src.get_level_model(1, 1)
	_chk("整批 404 仍可玩随包内置章，不再用旧下载关", builtin_meta != null
		and builtin_meta.level_unique_id != "old-one")
	var partial_builtin_dl: = FakeLevelDownloader.new()
	add_child(partial_builtin_dl)
	partial_builtin_dl.default_result = {"ok": true, "chapters": [
		_chapter(1, [_level(1, "remote-one", "default", "LAYOUT")])]}
	var partial_builtin: = FakeLevelSource.new(partial_builtin_dl, 
		ContentLevelExperimentResolver.new(FakeAbGateway.new()))
	await partial_builtin.force_refresh(2)
	_chk("成功批次缺第 2 章时只补内置第 2 章，不覆盖远端第 1 章", 
		partial_builtin.get_level_model(2, 1) != null
		and partial_builtin.get_level_model(1, 1).level_unique_id == "remote-one")

	var partial_dl: = FakeLevelDownloader.new()
	add_child(partial_dl)
	partial_dl.default_result = {"ok": true, "chapters": [
		_chapter(7, [_level(1, "old-seven", "default", "LAYOUT")]), 
		_chapter(8, [_level(1, "eight", "default", "LAYOUT")])]}
	var partial_src: = FakeLevelSource.new(partial_dl, 
		ContentLevelExperimentResolver.new(FakeAbGateway.new()))
	await partial_src.force_refresh(7)
	partial_dl.default_result = {"ok": true, "chapters": [
		_chapter(8, [_level(1, "eight", "default", "LAYOUT")])]}
	await partial_src.force_refresh(7)
	_chk("成功批次缺第 7 章时清旧章，不误删第 8 章", 
		partial_src.get_level_model(7, 1) == null
		and partial_src.get_level_model(8, 1) != null)



func _test_partial_bucket_end() -> void :
	var dl: = FakeBucketFetchDownloader.new()
	dl.result = {"ok": true, "chapters": [
		_chapter(6, [_level(1, "uid-6-1", "default", "LAYOUT")]), 
		_chapter(7, [_level(1, "uid-7-1", "default", "LAYOUT")]), 
	]}
	add_child(dl)
	var src: = FakeLevelSource.new(dl, ContentLevelExperimentResolver.new(FakeAbGateway.new()))
	var changed: Array[int] = []
	src.chapter_data_changed.connect( func(chapter_index: int) -> void :
		changed.append(chapter_index))
	_chk("下载层只将成功但缺目标章判为缺章", 
		LevelDownloader._requested_chapter_missing(dl.result, 8)
		and not LevelDownloader._requested_chapter_missing(dl.result, 7)
		and not LevelDownloader._requested_chapter_missing({"ok": false}, 8)
		and not LevelDownloader._requested_chapter_missing({"ok": true, "exhausted": true}, 8))
	var result: Dictionary = await src.force_refresh(8)
	_chk("成功批次缺目标章 → 明确到顶", bool(result.get("exhausted", false))
		and src.is_chapter_resolved(8) and src.get_level_model(8, 1) == null)
	_chk("同批次现有章仍可用", src.get_level_model(6, 1) != null
		and src.get_level_model(7, 1) != null)
	_chk("没请求过的第 9 章仍未知", not src.is_chapter_resolved(9))

	dl.result = {"ok": false}
	var changes_before_failure: int = changed.size()
	await src.force_refresh(8)
	_chk("本次会话后续网络失败不抹掉已确认结果", src.is_chapter_resolved(8))
	_chk("网络失败不发送数据到货通知", changed.size() == changes_before_failure)
	src.clear_memory()
	changes_before_failure = changed.size()
	await src.force_refresh(8)
	_chk("到顶状态不落盘，清内存后断网仍未知", not src.is_chapter_resolved(8))
	_chk("断网不伪装到顶也不通知可用", changed.size() == changes_before_failure)

	dl.result = {"ok": true, "chapters": [
		_chapter(8, [_level(1, "uid-8-1", "default", "LAYOUT-NEW")]), 
	]}
	var changes_before_recovery: int = changed.size()
	await src.force_refresh(8)
	_chk("服务端上新目标章后可恢复", src.is_chapter_resolved(8)
		and src.get_level_model(8, 1) != null)
	_chk("上新章通知 UI 恢复按钮", changed.size() > changes_before_recovery
		and 8 in changed.slice(changes_before_recovery))



func _test_missing_middle_level_recovery() -> void :
	var dl: = FakeBucketFetchDownloader.new()
	dl.result = {"ok": true, "chapters": [
		_chapter(8, [_level(15, "uid-8-15", "default", "LAYOUT-15")]), 
	]}
	add_child(dl)
	var src: = FakeLevelSource.new(dl, ContentLevelExperimentResolver.new(FakeAbGateway.new()))
	var changed: Array[int] = []
	src.chapter_data_changed.connect( func(chapter_index: int) -> void :
		changed.append(chapter_index))
	await src.force_refresh(8)
	var missing_meta: LevelModel = src.get_level_model(8, 16)
	_chk("章内缺 16 仍能出兜底关，不等于章末", src.is_chapter_resolved(8)
		and src.get_level_model(8, 15) != null
		and missing_meta != null and missing_meta.use_fallback_pool
		and missing_meta.level_id == LevelIndex.level_id_of(8, 16)
		and not LevelIndex.is_chapter_end(LevelIndex.level_id_of(8, 15)))
	dl.result = {"ok": false}
	await src.force_refresh(8)
	_chk("缺关后断网继续使用已装载章节的兜底", src.get_level_model(8, 16).use_fallback_pool)
	dl.result = {"ok": true, "chapters": [
		_chapter(8, [
			_level(15, "uid-8-15", "default", "LAYOUT-15"), 
			_level(16, "uid-8-16", "default", "LAYOUT-16"), 
		]), 
	]}
	var before_recovery: int = changed.size()
	await src.force_refresh(8)
	_chk("章内第 16 关补回后优先正式关并通知", src.get_level_model(8, 16) != null
		and not src.get_level_model(8, 16).use_fallback_pool
		and src.get_level_model(8, 16).level_unique_id == "uid-8-16"
		and 8 in changed.slice(before_recovery))



func _test_empty_chapter_fallback() -> void :
	var dl: = FakeBucketFetchDownloader.new()
	dl.result = {"ok": true, "chapters": [_chapter(8, [])]}
	add_child(dl)
	var src: = FakeLevelSource.new(dl, ContentLevelExperimentResolver.new(FakeAbGateway.new()))
	var result: Dictionary = await src.force_refresh(8)
	var first: LevelModel = src.get_level_model(8, 1)
	var last: LevelModel = src.get_level_model(8, LevelIndex.CHAPTER_SIZE)
	_chk("空章已发布，不判内容到顶", bool(result.get("ok", false))
		and not bool(result.get("exhausted", false)) and src.is_chapter_resolved(8))
	_chk("空章首关至末关逐关兜底", first != null and first.use_fallback_pool
		and last != null and last.use_fallback_pool
		and last.level_id == LevelIndex.level_id_of(8, LevelIndex.CHAPTER_SIZE))
	var original_source: LevelSource = LevelManager._source
	var original_parsers: Dictionary = LevelManager._parsers
	LevelManager._source = src
	LevelManager._parsers = {"": JuiceLevelParser.new()}
	_chk("空章兜底关不是到顶，未发布下一章仍到顶", 
		not LevelManager.is_end_reached(LevelIndex.level_id_of(8, LevelIndex.CHAPTER_SIZE))
		and LevelManager.is_end_reached(LevelIndex.level_id_of(9, 1)))
	LevelManager._source = original_source
	LevelManager._parsers = original_parsers
	_chk("兜底元数据标记只活在运行期，不进入副本或存档", first != null
		and not first.duplicate_model().use_fallback_pool
		and not first.to_dict().has("use_fallback_pool"))
	_chk("兜底元数据不扩张到非法序号或未发布章", 
		src.get_level_model(8, 0) == null
		and src.get_level_model(8, LevelIndex.CHAPTER_SIZE + 1) == null
		and src.get_level_model(9, 1) == null)
	dl.result = {"ok": true, "chapters": [_chapter(8, [_level(1, "uid-8-1", "default", "LAYOUT")])]}
	await src.force_refresh(8)
	_chk("空章补配置后正式关优先，仍缺的关继续兜底", 
		not src.get_level_model(8, 1).use_fallback_pool
		and src.get_level_model(8, 2).use_fallback_pool)



func _test_survives_default_refresh() -> void :
	var ctx: Dictionary = _make({"content_sg||level||6_6": "pool_a"}, 
		{"pool_a": {"ok": true, "levels": [_patch(6, 1, {"levelDataSource": "pool"})]}})
	var src: LevelSource = ctx.source
	var dl: FakeLevelDownloader = ctx.downloader
	await src.force_refresh(6)
	await get_tree().process_frame
	_chk("刷新前 patch 生效", src.get_level_model(6, 1).level_data_source == "pool")


	dl.default_result = {"ok": true, "chapters": [
		_chapter(6, [_level(1, "uid-6-1-NEW", "default", "LAYOUT-NEW")]), 
	]}
	await src.force_refresh(6)
	await get_tree().process_frame
	var m: LevelModel = src.get_level_model(6, 1)
	_chk("刷新后 patch 仍生效（冲不掉）", m != null and m.level_data_source == "pool")
	_chk("刷新后新基线可见（patch 遮不住刷新结果）", 
		m != null and m.level_unique_id == "uid-6-1-NEW")


func _test_idempotent_and_failure_modes() -> void :

	var ctx: Dictionary = _make({"content_sg||level||6_6": "pool_a"}, 
		{"pool_a": {"ok": true, "levels": [_patch(6, 1, {"levelDataSource": "pool"})]}})
	var src: LevelSource = ctx.source
	var dl: FakeLevelDownloader = ctx.downloader
	await src.force_refresh(6)
	await get_tree().process_frame
	for _i in range(3):
		await src.dispatch_experiments_for_chapter(6)
	_chk("重复触发只发一次请求", dl.requested == ["pool_a"])
	_chk("重复触发后 patch 仍在", src.get_level_model(6, 1).level_data_source == "pool")


	var c404: Dictionary = _make({"content_sg||level||6_6": "pool_a"}, 
		{"pool_a": {"ok": false, "not_found": true}})
	await (c404.source as LevelSource).force_refresh(6)
	await get_tree().process_frame
	await (c404.source as LevelSource).dispatch_experiments_for_chapter(6)
	_chk("404 不重试", (c404.downloader as FakeLevelDownloader).requested == ["pool_a"])
	_chk("404 回落 default", 
		(c404.source as LevelSource).get_level_model(6, 1).level_data_source == "full")


	var cfail: Dictionary = _make({"content_sg||level||6_6": "pool_a"}, {"pool_a": {"ok": false}})
	var fsrc: LevelSource = cfail.source
	var fdl: FakeLevelDownloader = cfail.downloader
	await fsrc.force_refresh(6)
	await get_tree().process_frame
	await fsrc.dispatch_experiments_for_chapter(6)
	_chk("真失败下次触发重试", fdl.requested == ["pool_a", "pool_a"])
	fdl.strategy_results["pool_a"] = {
		"ok": true, "levels": [_patch(6, 1, {"levelDataSource": "pool-late"})]}
	await fsrc.dispatch_experiments_for_chapter(6)
	_chk("重试成功后 patch 补上", fsrc.get_level_model(6, 1).level_data_source == "pool-late")


	for value: String in ["default", ""]:
		var cc: Dictionary = _make({"content_sg||level||6_6": value}, {})
		await (cc.source as LevelSource).force_refresh(6)
		await get_tree().process_frame
		_chk("value=\"%s\" 不发请求" % value, 
			(cc.downloader as FakeLevelDownloader).requested.is_empty())


	var co: Dictionary = _make(
		{"content_sg||level||5_6": "pool_a", "content_sg||level||6_7": "pool_b"}, 
		{
			"pool_a": {"ok": true, "levels": [_patch(6, 1, {"levelDataSource": "pool-a"})]}, 
			"pool_b": {"ok": true, "levels": [_patch(6, 1, {"levelDataSource": "pool-b"})]}, 
		})
	await (co.source as LevelSource).force_refresh(6)
	await get_tree().process_frame
	_chk("重叠实验按区间起点顺序请求", 
		(co.downloader as FakeLevelDownloader).requested == ["pool_a", "pool_b"])
	_chk("重叠实验后者整份取代前者", 
		(co.source as LevelSource).get_level_model(6, 1).level_data_source == "pool-b")


	_chk("解析裸数组", bool(LevelDownloader._parse_strategy_pool("[{\"levelIndex\":1}]").get("ok")))
	_chk("解析信封", bool(LevelDownloader._parse_strategy_pool(
		"{\"status\":{\"code\":0},\"data\":[{\"levelIndex\":1}]}").get("ok")))
	_chk("信封 code!=0 判失败", not bool(LevelDownloader._parse_strategy_pool(
		"{\"status\":{\"code\":1},\"data\":[]}").get("ok")))
	_chk("空数组是成功", bool(LevelDownloader._parse_strategy_pool("[]").get("ok")))
	_chk("根是数字判失败", not bool(LevelDownloader._parse_strategy_pool("42").get("ok")))
	_chk("config_type 拼了固定前缀", 
		LevelDownloader._config_url("sortparade_abtest_level_zhouaicaiceshi1_1").ends_with(
		"config_type=sortparade_abtest_level_zhouaicaiceshi1_1"))


func _test_refresh_after_level() -> void :
	var key: String = "content_sg||level||6_6"
	var ctx: Dictionary = _make({key: "pool_a"}, 
		{"pool_a": {"ok": true, "levels": [_patch(6, 1, {"levelDataSource": "pool-old"})]}})
	var src: LevelSource = ctx.source
	var dl: FakeLevelDownloader = ctx.downloader
	await src.force_refresh(6)
	await get_tree().process_frame


	dl.default_result = {"ok": false}
	dl.strategy_results["pool_a"] = {"ok": true, "levels": [
		_patch(6, 1, {"levelDataSource": "pool-new"})]}
	await src.force_refresh(6)
	await src.refresh_experiments_after_level(6)
	_chk("通关后 default 失败仍重新请求策略池", dl.requested == ["pool_a", "pool_a"])
	_chk("通关后从磁盘缓存应用新策略池", 
		src.get_level_model(6, 1).level_data_source == "pool-new")

	dl.strategy_results["pool_a"] = {"ok": false}
	await src.refresh_experiments_after_level(6)
	_chk("下一关通关再次请求，失败保留旧 patch", 
		dl.requested.size() == 3 and src.get_level_model(6, 1).level_data_source == "pool-new")

	dl.strategy_results["pool_a"] = {"ok": false, "not_found": true}
	await src.refresh_experiments_after_level(6)
	_chk("通关刷新收到 404 后撤销缓存 patch", 
		dl.requested.size() == 4 and not dl.strategy_cache.has("pool_a")
		and src.get_level_model(6, 1).level_data_source == "full")
	dl.strategy_results["pool_a"] = {"ok": true, "levels": [
		_patch(6, 1, {"levelDataSource": "pool-republished"})]}
	await src.refresh_experiments_after_level(6)
	_chk("下次通关可重新探测 404 后发布的策略池", 
		dl.requested.size() == 5
		and src.get_level_model(6, 1).level_data_source == "pool-republished")


	dl.defer_strategy = true
	src.refresh_experiments_after_level(6)
	src.refresh_experiments_after_level(6)
	dl.default_result = {"ok": true, "chapters": [
		_chapter(6, [_level(1, "uid-6-1", "default", "LAYOUT-DEFAULT")])]}
	await src.force_refresh(6)
	_chk("同一次通关的并发触发只发一次策略池请求", dl.requested.size() == 6)
	dl.strategy_released.emit()
	await get_tree().process_frame
	_chk("并发刷新后单飞闩已释放", src._experiment_latches.is_empty())

	var control: Dictionary = _make({key: "default"}, {})
	await (control.source as LevelSource).refresh_experiments_after_level(6)
	_chk("对照组通关后不发策略池请求", 
		(control.downloader as FakeLevelDownloader).requested.is_empty())

	var scoped: Dictionary = _make({
		"content_sg||level||6_6": "pool_a", "content_sg||level||7_7": "pool_b"}, {
		"pool_a": {"ok": true, "levels": [_patch(6, 1, {"levelDataSource": "a"})]}, 
		"pool_b": {"ok": true, "levels": [_patch(7, 1, {"levelDataSource": "b"})]}, 
	})
	var scoped_source: LevelSource = scoped.source
	var scoped_downloader: FakeLevelDownloader = scoped.downloader
	await scoped_source.force_refresh(6)
	await get_tree().process_frame
	await scoped_source.refresh_experiments_after_level(6)
	_chk("通关只刷新覆盖刚通关章的实验", 
		scoped_downloader.requested == ["pool_a", "pool_b", "pool_a"])


func _test_clear_memory() -> void :
	var ctx: Dictionary = _make({"content_sg||level||6_6": "pool_a"}, 
		{"pool_a": {"ok": true, "levels": [_patch(6, 1, {"levelDataSource": "pool"})]}})
	var src: LevelSource = ctx.source
	var dl: FakeLevelDownloader = ctx.downloader
	await src.force_refresh(6)
	await get_tree().process_frame
	_chk("清缓存前 patch 在", not src._experiment_patches.is_empty())

	src.clear_memory()
	_chk("clear_memory 清掉 patch 表", src._experiment_patches.is_empty())
	_chk("clear_memory 清掉 latch 表", src._experiment_latches.is_empty())
	_chk("clear_memory 清掉确定答案缓存", src._experiment_done.is_empty())

	await src.restore_cached_experiments(true, "")
	await src.force_refresh(6)
	await get_tree().process_frame
	_chk("清缓存后会重新拉一次", dl.requested == ["pool_a", "pool_a"])
	_chk("清缓存后 patch 重建", src.get_level_model(6, 1).level_data_source == "pool")



func _test_cold_restart_cache() -> void :
	var key: String = "content_sg||level||6_6"
	var ctx: Dictionary = _make({key: "pool_a"}, {
		"pool_a": {"ok": true, "levels": [_patch(6, 1, {"levelDataSource": "pool"})]}})
	var online: LevelSource = ctx.source
	var dl: FakeLevelDownloader = ctx.downloader
	await online.force_refresh(6)
	await get_tree().process_frame
	await online.restore_cached_experiments(true, "group-a")
	_chk("在线时保存已确认分组", dl.saved_selection.get(key) == "pool_a")
	_chk("在线时已有策略池缓存", dl.strategy_cache.has("pool_a"))

	var gateway: FakeAbGateway = ctx.gateway
	gateway.ready = false
	dl.strategy_results["pool_a"] = {"ok": false}
	var offline: = FakeLevelSource.new(dl, ContentLevelExperimentResolver.new(gateway))
	await offline.restore_cached_experiments(false, "group-a")
	var requested_before: int = dl.requested.size()
	await offline.dispatch_experiments_for_chapter(6)
	_chk("冷启动断网仍从缓存恢复替换池", 
		offline.get_level_model(6, 1) == null)
	await offline.force_refresh(6)
	_chk("离线恢复不发策略池请求", dl.requested.size() == requested_before)
	_chk("default 基线就绪后叠加缓存 patch", 
		offline.get_level_model(6, 1).level_data_source == "pool")


	gateway.ready = true
	var weak_network: = FakeLevelSource.new(dl, ContentLevelExperimentResolver.new(gateway))
	await weak_network.restore_cached_experiments(true, "group-a")
	await weak_network.force_refresh(6)
	await get_tree().process_frame
	_chk("SDK 已就绪而策略池刷新失败时沿用缓存", 
		weak_network.get_level_model(6, 1).level_data_source == "pool")
	dl.strategy_results["pool_a"] = {"ok": false, "not_found": true}
	await weak_network.dispatch_experiments_for_chapter(6)
	_chk("服务端确认 404 后删除旧缓存 patch", 
		weak_network.get_level_model(6, 1).level_data_source == "full"
		and not dl.strategy_cache.has("pool_a"))

	gateway.values[key] = "default"
	await offline.restore_cached_experiments(true, "group-a")
	_chk("SDK 切到 default 后清除旧 patch", 
		offline.get_level_model(6, 1).level_data_source == "full")
	_chk("不同 group_id 不复用旧分组", dl.read_cached_experiment_selection("group-b").is_empty())




func _test_session_follows_sdk() -> void :
	var key: String = "content_sg||level||6_6"
	var ctx: Dictionary = _make({}, {
		"pool_a": {"ok": true, "levels": [_patch(6, 1, {"levelDataSource": "pool-a"})]}, 
		"pool_b": {"ok": true, "levels": [_patch(6, 1, {"levelDataSource": "pool-b"})]}})
	var src: LevelSource = ctx.source
	var dl: FakeLevelDownloader = ctx.downloader
	var gateway: FakeAbGateway = ctx.gateway
	await src.force_refresh(6)
	await src.restore_cached_experiments(true, "g")
	_chk("本地配置无实验时走 default", src.get_level_model(6, 1).level_data_source == "full")

	gateway.published[key] = "x"
	gateway.values[key] = "pool_a"
	await src.restore_cached_experiments(true, "g")
	await get_tree().process_frame
	_chk("远端新开实验后同进程生效", 
		dl.requested == ["pool_a"] and src.get_level_model(6, 1).level_data_source == "pool-a")

	var epoch: int = src._experiment_epoch
	await src.restore_cached_experiments(true, "g")
	await get_tree().process_frame
	_chk("相同选择重复回调无副作用", 
		dl.requested.size() == 1 and src._experiment_epoch == epoch)

	dl.defer_strategy = true
	gateway.values[key] = "pool_b"
	await src.restore_cached_experiments(true, "g")
	_chk("改 value 后旧 patch 立刻撤掉", 
		src.get_level_model(6, 1).level_data_source == "full")
	dl.defer_strategy = false
	dl.strategy_released.emit()
	await get_tree().process_frame
	_chk("改 value 后新策略池到货生效", 
		dl.requested == ["pool_a", "pool_b"]
		and src.get_level_model(6, 1).level_data_source == "pool-b")

	gateway.published.erase(key)
	gateway.values.erase(key)
	await src.restore_cached_experiments(true, "g")
	await get_tree().process_frame
	_chk("远端关闭实验后同进程回到 default", 
		dl.requested.size() == 2 and src.get_level_model(6, 1).level_data_source == "full")


func _test_chunked_patch_index() -> void :
	var ctx: Dictionary = _make({}, {})
	var entries: Array = []
	for n: int in range(101):
		entries.append(_patch(6, 1, {"levelDataSource": "candidate-%d" % n}))
	var indexed: Dictionary = await (ctx.source as LevelSource)._index_strategy_patches(entries, 6, 6)
	var candidates: Array = indexed.get(LevelIndex.level_id_of(6, 1), []) as Array
	_chk("跨分帧批次仍保留同关全部候选与顺序", 
		candidates.size() == 101 and candidates[100]["levelDataSource"] == "candidate-100")



func _test_baseline_chapter_channel() -> void :
	var dl: = FakeBucketFetchDownloader.new()
	add_child(dl)
	dl.result = {"ok": true, "chapters": [_chapter(1, [_level(1, "uid-1", "default", "L")])]}
	dl.bind_chapter_channel(LevelDownloader.CHAPTER_CHANNEL_DEFAULT)
	await dl.fetch_chapter_bucket(1)
	_chk("default 渠道 config_type", 
		dl.last_config_type == "sortparade_v1_chapter_1_5")
	_chk("default 渠道 cache_key", dl.last_cache_key == "1_5")

	var baseline_dl: = FakeBucketFetchDownloader.new()
	add_child(baseline_dl)
	baseline_dl.result = {"ok": true, "exhausted": true}
	baseline_dl.bind_chapter_channel(LevelDownloader.CHAPTER_CHANNEL_BASELINE)
	await baseline_dl.fetch_chapter_bucket(1)
	_chk("baseline 渠道 config_type", 
		baseline_dl.last_config_type == "sortparade_v1_chapter_baseline_1_5")
	_chk("baseline 渠道 cache_key 隔离", baseline_dl.last_cache_key == "baseline:1_5")
	_chk("chapter_bucket_url 跟渠道", 
		baseline_dl.chapter_bucket_url(1).contains("sortparade_v1_chapter_baseline_1_5"))

	var gateway: = FakeAbGateway.new()
	gateway.published["content_sg||level||1_5"] = "x"
	gateway.values["content_sg||level||1_5"] = "pool-a"
	var exp_dl: = FakeLevelDownloader.new()
	add_child(exp_dl)
	exp_dl.strategy_results = {"pool-a": {"ok": true, "levels": [
		_patch(1, 1, {"initialLayout": "PATCH"})]}}
	var src: = FakeLevelSource.new(exp_dl, ContentLevelExperimentResolver.new(gateway))
	src.set_chapter_channel(LevelDownloader.CHAPTER_CHANNEL_BASELINE)
	await src.restore_cached_experiments(true, "g1")
	_chk("基线渠道不拉策略池", exp_dl.requested.is_empty())
	_chk("基线内置路径", src._builtin_chapter_path()
		== LevelSource.BUILTIN_BASELINE_PATH)
	src.dispatch_experiments_for_chapter(1)
	await get_tree().process_frame
	_chk("基线渠道 dispatch 仍不请求", exp_dl.requested.is_empty())


	_chk("流量域从 Map 取值", 
		ABManager.parse_flow_domain({"pm_flow_domain_data": {"pm_flow_domain": "baseline"}})
		== "baseline")
	_chk("流量域 Map 优先于顶层标量", ABManager.parse_flow_domain({
		"pm_flow_domain": "experiment", 
		"pm_flow_domain_data": {"pm_flow_domain": "baseline"}}) == "baseline")
	_chk("流量域顶层标量兜底", 
		ABManager.parse_flow_domain({"pm_flow_domain": " baseline "}) == "baseline")
	_chk("流量域缺失为空", ABManager.parse_flow_domain({"pm_flow_domain_data": {}}) == "")
	_chk("流量域非字符串为空", 
		ABManager.parse_flow_domain({"pm_flow_domain_data": {"pm_flow_domain": null}}) == "")




func _make(values: Dictionary, pools: Dictionary) -> Dictionary:
	var gateway: = FakeAbGateway.new()
	for key: String in values.keys():
		gateway.published[key] = "SDK 列表值不作为最终分组值"
		gateway.values[key] = values[key]
	var downloader: = FakeLevelDownloader.new()
	downloader.default_result = {"ok": true, "chapters": [
		_chapter(6, [
			_level(1, "uid-6-1", "default", "LAYOUT-DEFAULT"), 
			_level(2, "uid-6-2-us", "country:US", "LAYOUT-US"), 
			_level(2, "uid-6-2-default", "default", "LAYOUT-DEFAULT"), 
		]), 
		_chapter(7, [_level(1, "uid-7-1", "default", "LAYOUT-DEFAULT")]), 
	]}
	downloader.strategy_results = pools
	add_child(downloader)
	var source: = FakeLevelSource.new(downloader, ContentLevelExperimentResolver.new(gateway))

	source._experiment_values = values.duplicate()
	source._experiment_selection_initialized = true
	source._experiment_selection_from_sdk = true
	return {"source": source, "downloader": downloader, "gateway": gateway}


func _chapter(chapter_index: int, levels: Array) -> Dictionary:
	return {
		"chapterIndex": chapter_index, 
		"title": {"en": "Chapter %d" % chapter_index}, 
		"cardImageUrl": "cover-%d" % chapter_index, 
		"levels": levels, 
	}



func _level(level_index: int, uid: String, tags: String, layout: String) -> Dictionary:
	return {
		"levelIndex": level_index, 
		"levelUniqueId": uid, 
		"levelUserTags": tags, 
		"stepLimit": 7, 
		"imageUrl": "img-6-%d" % level_index, 
		"animation": "", 
		"difficulty": 12, 
		"difficultyType": "Normal", 
		"initialLayout": layout, 
		"levelDataSource": "full", 
	}



func _patch(chapter_index: int, level_index: int, fields: Dictionary) -> Dictionary:
	var out: Dictionary = {"chapterIndex": chapter_index, "levelIndex": level_index}
	for k: Variant in fields.keys():
		out[k] = fields[k]
	return out


func _chk(name: String, condition: bool) -> void :
	_checks += 1
	if condition:
		return
	_ok = false
	print("  ✗ %s" % name)


func _finish() -> void :
	print("—— %d 项断言 ——" % _checks)
	print("PASS" if _ok else "FAIL")
	get_tree().quit(0 if _ok else 1)
