extends Node

signal level_data_changed(chapter_index: int)

signal special_challenge_completed(instance_id: String)































const NEAR_CHAPTER_END_THRESHOLD: = 3

const FOREGROUND_LOAD_TIMEOUT: = 9.0
const UNAVAILABLE_RETRY_INTERVAL: = 10.0

const STALE_RESUME_MS: int = 12 * 60 * 60 * 1000
const SUNLIGHT_BANK_SCRIPT: = preload("res://scripts/data/level_data/juice_sunlight_level_bank.gd")
const SUNLIGHT_POT_BANK_SCRIPT: = preload("res://scripts/data/level_data/juice_sunlight_pot_recipe_bank.gd")

var _chapter_art: Dictionary = {}
var _chapter_textures: Dictionary = {}
var _chapter_cover_paths: Dictionary = {}
var _chapter_cover_loads: Dictionary = {}

var _chapter_cover_files: Dictionary = {}
var _chapter_cover_downloads: Dictionary = {}
var _chapter_cover_prefetches: Dictionary = {}
var _chapter_cover_download_toasts: Array[Dictionary] = []
var _chapter_cover_download_toast_running: bool = false
var _chapter_cover_epoch: int = 0
var _parsers: Dictionary = {}
var _downloader: LevelDownloader
var _startup_optimized: bool = false
var _startup_chapter: int = 0
var _startup_refresh_started: bool = false
var _source: LevelSource
var _saver: LevelSaver
var _content_level_experiment_resolver: ContentLevelExperimentResolver
var _experiment_restore_done: bool = false
var _experiment_restore_running: bool = false
var _ab_changed_during_restore: bool = false
var _special_bank: SpecialChallengeBank = SpecialChallengeBank.new()
var _sunlight_bank: RefCounted
var _sunlight_pot_bank: RefCounted
var _special_saver: SpecialChallengeSaver = SpecialChallengeSaver.new()
var _cheat_hard_level_id: int = 0

var _cheat_hard_difficulty_type: String = "Hard"
var _retrying_chapters: Dictionary = {}
var _debug_csv_switching: bool = false


func read_sunlight_level(source_id: int) -> Dictionary:
	return _get_sunlight_bank().call("read_case", source_id) as Dictionary


func read_sunlight_pot_recipe(level: int, source_uid: String, tags: String) -> Dictionary:
	if _sunlight_pot_bank == null:
		_sunlight_pot_bank = SUNLIGHT_POT_BANK_SCRIPT.new()
	return _sunlight_pot_bank.call("read_recipe", level, source_uid, tags) as Dictionary


func read_sunlight_level_by_difficulty(difficulty: int, sequence: int) -> Dictionary:
	return _get_sunlight_bank().call("read_by_difficulty", difficulty, sequence) as Dictionary


func _get_sunlight_bank() -> RefCounted:
	if _sunlight_bank == null:
		_sunlight_bank = SUNLIGHT_BANK_SCRIPT.new()
	return _sunlight_bank


func _ready() -> void :
	_downloader = LevelDownloader.new()
	add_child(_downloader)
	_saver = LevelSaver.new()
	_content_level_experiment_resolver = ContentLevelExperimentResolver.new(ABManager)
	_source = LevelSource.new(_downloader, _content_level_experiment_resolver)
	_source.chapter_data_changed.connect(_on_chapter_data_changed)


	ABManager.init_done.connect(_on_ab_changed)
	ABManager.params_updated.connect( func(_update_type: String, _user_info: Dictionary) -> void :
		_on_ab_changed())
	ABManager.remote_config_ready.connect(_on_ab_changed)

	UniKitManager.usertag_ready.connect(_on_usertag_ready)
	UniKitManager.usertag_data_updated.connect(_on_usertag_data_updated)


func _on_chapter_data_changed(chapter_index: int) -> void :
	level_data_changed.emit(chapter_index)







func register_parser(parser: LevelParser) -> void :
	_parsers[parser.gameplay_type()] = parser


func _parser_for(gameplay_type: String) -> LevelParser:
	if _parsers.has(gameplay_type):
		return _parsers[gameplay_type]
	if gameplay_type.is_empty():
		SortLogger.error("LevelManager: 默认 parser（空 gameplay_type）未注册")
		return null
	SortLogger.error("LevelManager: 玩法类型 '%s' 没有注册对应 parser" % gameplay_type)
	return null






func init(optimized: bool = false) -> bool:
	_startup_optimized = optimized
	_source.cold_start_optimized = optimized
	await _load_at_launch()
	return not _source.local_load_failed



func bind_chapter_channel() -> void :
	var sdk_domain: String = _save_sdk_flow_domain()
	if _downloader.is_chapter_channel_bound():
		return
	var domain: String = ""
	var cheat: String = ABManager.get_flow_domain_cheat_mode()
	if cheat == ABManager.FLOW_DOMAIN_CHEAT_BASELINE:
		domain = ABManager.FLOW_DOMAIN_BASELINE
	elif cheat == ABManager.FLOW_DOMAIN_CHEAT_EXPERIMENT:
		domain = "experiment"
	elif not sdk_domain.is_empty():
		domain = sdk_domain
	else:
		domain = _downloader.read_confirmed_flow_domain()
		if domain.is_empty():
			domain = "experiment"
	var channel: String = LevelDownloader.CHAPTER_CHANNEL_BASELINE\
	if domain == ABManager.FLOW_DOMAIN_BASELINE\
	else LevelDownloader.CHAPTER_CHANNEL_DEFAULT
	_downloader.bind_chapter_channel(channel)
	_source.set_chapter_channel(channel)
	SortLogger.info("[LevelManager] 章节渠道冻结为 %s（域=%s, cheat=%s）"
		%[channel, domain, cheat])



func _save_sdk_flow_domain() -> String:
	var sdk_domain: String = ABManager.read_sdk_flow_domain()
	if not sdk_domain.is_empty():
		_downloader.save_confirmed_flow_domain(sdk_domain)
	return sdk_domain


func _on_usertag_ready(_data: Dictionary) -> void :
	_save_sdk_flow_domain()


func _on_usertag_data_updated(_json: String) -> void :
	_save_sdk_flow_domain()



func _load_at_launch() -> void :
	if _startup_optimized:
		await _load_at_launch_optimized()
		return
	bind_chapter_channel()

	var current_chapter: int = LevelIndex.chapter_of(UserState.get_current_level())

	await _source.ensure_chapter_loaded(current_chapter)

	_refresh_chapter_after_launch(current_chapter)








func _refresh_chapter_after_launch(current_chapter: int) -> void :
	await get_tree().create_timer(2.0).timeout
	await _source.force_refresh(current_chapter)
	var bucket: Vector2i = LevelDownloader.bucket_of(current_chapter)
	if current_chapter >= bucket.y - 1:

		var next_result: Dictionary = await _source.force_refresh(bucket.y + 1)
		_report_chapter_unlock(bucket.y + 1, next_result)




func restore_cached_experiments() -> void :
	bind_chapter_channel()
	_load_chapter_art_if_needed()
	_experiment_restore_running = true
	await _source.restore_cached_experiments(ABManager.is_ab_init_done(), ABManager.get_ab_group_id())
	_experiment_restore_running = false
	_experiment_restore_done = true
	if _ab_changed_during_restore and ABManager.is_ab_init_done():
		_ab_changed_during_restore = false
		await _source.restore_cached_experiments(true, ABManager.get_ab_group_id())




func _on_ab_changed() -> void :
	if not ABManager.is_ab_init_done():
		return
	_save_sdk_flow_domain()
	if not _experiment_restore_done or _experiment_restore_running:
		_ab_changed_during_restore = true
		return
	_source.restore_cached_experiments(true, ABManager.get_ab_group_id())






func waiting_load_data(chapter_index: int, 
		timeout_sec: float = FOREGROUND_LOAD_TIMEOUT) -> Dictionary:
	return await _source.ensure_chapter_loaded(chapter_index, timeout_sec)




func chapter_data_url(chapter_index: int) -> String:
	return _downloader.chapter_bucket_url(chapter_index)




func retry_unavailable_level(level_id: int) -> void :
	var chapter_index: int = LevelIndex.chapter_of(level_id)
	if _retrying_chapters.has(chapter_index):
		return
	_retrying_chapters[chapter_index] = true
	await _source.force_refresh(chapter_index, FOREGROUND_LOAD_TIMEOUT)
	_retrying_chapters.erase(chapter_index)









func apply_content_level_experiments(level_id: int) -> void :
	if _source.is_baseline_chapter_channel():
		return
	var chapter_index: int = LevelIndex.chapter_of(level_id)
	_content_level_experiment_resolver.dye_for_chapter(chapter_index)
	_source.dispatch_experiments_for_chapter(chapter_index)



func get_level_model(chapter_index: int, level_index: int) -> LevelModel:
	var model: LevelModel = _source.get_level_model(chapter_index, level_index)
	_apply_cheat_hard(model)
	return model





func load_level_content(level_id: int) -> LevelModel:
	var meta: LevelModel = get_level_model(LevelIndex.chapter_of(level_id), LevelIndex.index_of(level_id))
	if meta == null:
		return null
	var parser: LevelParser = _parser_for(meta.gameplay_type)
	if parser == null:
		return null
	var content: LevelModel = parser.parse_level(meta)

	_apply_cheat_hard(content)
	return content




func cheat_set_csv_levels(candidates: Dictionary, title: String = "") -> bool:
	if not OS.has_feature("editor") or OS.has_feature("rel") or _debug_csv_switching:
		return false
	_debug_csv_switching = true
	var affected_levels: Dictionary = {}
	for level_id: int in _source.debug_csv_level_ids():
		affected_levels[level_id] = true
	for level_id: int in candidates:
		affected_levels[level_id] = true
	var levels: Array = affected_levels.keys()
	for level_id: int in levels:
		if not _saver.clear_state(level_id):
			_debug_csv_switching = false
			SortLogger.error("[LevelManager] 清除 CSV 测试旧盘面失败，第 %d 关未切换题库" % level_id)
			return false
		_log_save(str(level_id), "", "clear_csv_test", -1)
		await get_tree().process_frame
	_source.set_debug_csv_candidates(candidates, title)
	_debug_csv_switching = false
	var changed_chapters: Dictionary = {}
	for level_id: int in levels:
		changed_chapters[LevelIndex.chapter_of(level_id)] = true
	for chapter_index: int in changed_chapters:
		level_data_changed.emit(chapter_index)
	return true


func cheat_csv_level_status() -> Dictionary:
	var levels: Array = _source.debug_csv_level_ids()
	levels.sort()
	return {"active": not levels.is_empty(), "title": _source.debug_csv_title(), "levels": levels, 
		"current_is_test": _source.has_debug_csv_level(UserState.get_current_level()), 
		"switching": _debug_csv_switching}




func cheat_force_hard_level(level_id: int, difficulty_type: String = "Hard") -> void :
	if OS.has_feature("rel"):
		return
	_cheat_hard_level_id = level_id
	_cheat_hard_difficulty_type = difficulty_type


func _apply_cheat_hard(model: LevelModel) -> void :
	if not OS.has_feature("rel") and model != null and model.level_id == _cheat_hard_level_id:
		model.difficulty_type = _cheat_hard_difficulty_type



func get_chapter_model(chapter_index: int) -> ChapterModel:
	return _source.get_chapter_model(chapter_index)



func check_level_exist(level_id: int) -> bool:
	return get_level_model(LevelIndex.chapter_of(level_id), LevelIndex.index_of(level_id)) != null



func is_level_state_resolved(level_id: int) -> bool:
	return _source.is_chapter_resolved(LevelIndex.chapter_of(level_id))




func has_completed_coming_soon_before(level_id: int) -> bool:
	if not LevelIndex.is_coming_soon_boundary(level_id - 1):
		return false
	var previous: LevelEntity = _saver.load_entity(level_id - 1)
	return previous != null and previous.completed






func is_end_reached(level: int = 0) -> bool:
	if level <= 0:
		level = UserState.get_current_level()
	if _is_special_cursor(level):
		return false
	var meta: LevelModel = get_level_model(LevelIndex.chapter_of(level), LevelIndex.index_of(level))
	if meta == null:
		return true
	var parser: LevelParser = _parser_for(meta.gameplay_type)

	return parser != null and not parser.has_level_content(meta)







func load_resumed_level(level_id: int) -> Dictionary:
	if _is_special_cursor(level_id):
		return load_special_challenge()
	var entity: LevelEntity = _saver.load_entity(level_id)
	if entity == null or entity.current_state.is_empty():
		return {}

	var saved_source: String = String(entity.raw_level_info.get("level_data_source", ""))
	if saved_source.begins_with(LevelModel.DEBUG_CSV_SOURCE_PREFIX) and not _source.has_debug_csv_level(level_id):
		clear_game_state(level_id, "clear_csv_test", entity.game_id)
		return {}

	var saved_gameplay_type: String = String(entity.raw_level_info.get("gameplay_type", ""))
	var parser: LevelParser = _parser_for(saved_gameplay_type)
	if parser != null:
		var model: LevelModel = parser.model_from_dict(entity.raw_level_info)
		if model != null:
			_apply_cheat_hard(model)

			SortLogger.info("[LevelManager] 进关命中(续局): 当前用户等级=%d, 关号=%d(第%d章第%d关), levelUserTags=\"%s\", levelUniqueId=\"%s\", levelDataSource=\"%s\", game_id=%s" % [
				UserState.get_user_level(), model.level_id, model.chapter_index, 
				model.level_index, model.level_user_tags, model.level_unique_id, 
				model.level_data_source, entity.game_id])
			return {"model": model, "resumed": true, "current_state": entity.current_state, 
				"updated_at": entity.updated_at, "game_id": entity.game_id}

	clear_game_state(level_id, "clear_discard", entity.game_id)
	return {}





func is_resume_stale(resumed: Dictionary) -> bool:
	var updated_at: int = int(resumed.get("updated_at", 0))
	if updated_at <= 0:
		return false
	var now_ms: int = int(Time.get_unix_time_from_system() * 1000.0)
	return now_ms - updated_at > STALE_RESUME_MS





func load_fresh_level(level_id: int) -> Dictionary:
	var chapter_index: int = LevelIndex.chapter_of(level_id)
	var level_index: int = LevelIndex.index_of(level_id)


	_source.log_level_resolution(chapter_index, level_index)
	var fresh_meta: LevelModel = get_level_model(chapter_index, level_index)
	if fresh_meta == null:
		SortLogger.info("[LevelManager] start_level(%d): 关卡元数据未命中，新开局失败" % level_id)
		return {"model": null, "resumed": false, "current_state": {}}
	var fresh_parser: LevelParser = _parser_for(fresh_meta.gameplay_type)
	if fresh_parser == null:
		SortLogger.info("[LevelManager] start_level(%d): 玩法类型 '%s' 无对应 parser，新开局失败" % [level_id, fresh_meta.gameplay_type])
		return {"model": null, "resumed": false, "current_state": {}}
	var fallback_result: Dictionary = {}
	var content: LevelModel = fresh_parser.parse_level(fresh_meta, fallback_result)
	if fallback_result.get("triggered", false):







		var backup_id: String = content.level_unique_id if content != null else ""
		var origin_id: String = fresh_meta.level_unique_id
		var params: Dictionary = {
			TrackingEvents.K_BACKUP_ID: backup_id if not backup_id.is_empty() else str(level_id), 
			TrackingEvents.K_ORIGIN_ID: origin_id if not origin_id.is_empty() else str(level_id), 
			TrackingEvents.K_CURRENT_CHAPTER_LEVEL: "%d-%d" % [chapter_index, level_index], 
		}
		if level_id > 1:
			var previous: LevelEntity = _saver.load_entity(level_id - 1)
			if previous != null and previous.completed:
				params[TrackingEvents.K_COMPLETED_CHAPTER_LEVEL] = str(LevelIndex.chapter_of(level_id - 1))
		Tracker.send_event(TrackingEvents.EV_BACKUP_TRIGGERED, params)



	_apply_cheat_hard(content)
	if content == null:
		SortLogger.info("[LevelManager] start_level(%d): 题面解析失败，新开局未命中" % level_id)
	else:
		SortLogger.info("[LevelManager] 进关命中(新开局): 当前用户等级=%d, 关号=%d(第%d章第%d关), levelUserTags=\"%s\", levelUniqueId=\"%s\", levelDataSource=\"%s\"" % [
			UserState.get_user_level(), content.level_id, content.chapter_index, 
			content.level_index, content.level_user_tags, content.level_unique_id, 
			content.level_data_source])
	return {"model": content, "resumed": false, "current_state": {}}





const REPEAT_RESTART_DOWNGRADE_COUNT: int = 4










func resolve_restart_model(level_id: int, current_model: LevelModel, allow_downgrade: bool = true) -> LevelModel:
	var count: int = UserState.inc_repeat_restart(level_id)
	SortLogger.info("[LevelManager] 关号 %d 连续重开第 %d 次" % [level_id, count])
	if current_model == null or not allow_downgrade:
		return current_model
	if count < REPEAT_RESTART_DOWNGRADE_COUNT:
		return current_model
	var downgraded: LevelModel = load_downgraded_level(level_id)
	if downgraded != null:
		downgraded.special_challenge_schedule = current_model.special_challenge_schedule.duplicate()
	return downgraded if downgraded != null else current_model











func resolve_daily_downgrade_model(level_id: int, fresh_model: LevelModel) -> LevelModel:
	var count: int = UserState.inc_daily_round_count()
	SortLogger.info("[LevelManager] 降级换题: 关号 %d 是今日第 %d 个全新开局" % [level_id, count])
	if count == 1:
		ABManager.dye_at_daily_first_round()
	var downgrade_rounds: int = ABManager.daily_first_round_downgrade.downgrade_rounds_per_day()

	SortLogger.info("[LevelManager] 降级换题: 每日降难度分组: 当前为%s, 每天前 %d 关降级" % [
		"对照组" if downgrade_rounds == 0 else "实验组%d" % downgrade_rounds, downgrade_rounds])
	var downgraded: LevelModel = null

	var can_downgrade: bool = UserState.get_user_level() > UserLevelLadder.LEVEL_MIN
	if fresh_model != null and downgrade_rounds > 0 and count <= downgrade_rounds and can_downgrade:
		downgraded = load_downgraded_level(level_id)

	UserState.set_daily_downgrade_level(level_id if downgraded != null else 0)
	return downgraded if downgraded != null else fresh_model









func load_downgraded_level(level_id: int) -> LevelModel:
	var chapter_index: int = LevelIndex.chapter_of(level_id)
	var level_index: int = LevelIndex.index_of(level_id)
	var resolved: Dictionary = _source.get_downgraded_level_model(chapter_index, level_index)
	if resolved.is_empty():
		SortLogger.info("[LevelManager] 降级换题(%d): 低档位到 default 都与原题同题，保持原题, 当前用户等级=%d" % [
			level_id, UserState.get_user_level()])
		return null
	var meta: LevelModel = resolved["model"] as LevelModel
	var parser: LevelParser = _parser_for(meta.gameplay_type)
	if parser == null:
		return null
	var fallback_result: Dictionary = {}
	var content: LevelModel = parser.parse_level(meta, fallback_result)
	if content == null or fallback_result.get("triggered", false):
		SortLogger.info("[LevelManager] 降级换题(%d): 降级题解析失败，保持原题, levelUniqueId=\"%s\"" % [
			level_id, meta.level_unique_id])
		return null
	_apply_cheat_hard(content)
	SortLogger.info("[LevelManager] 降级换题(%d): 原题 levelUserTags=\"%s\" → 降级题 levelUserTags=\"%s\", levelUniqueId=\"%s\", levelDataSource=\"%s\", 当前用户等级=%d" % [
		level_id, resolved["base_tags"], resolved["tags"], content.level_unique_id, 
		content.level_data_source, UserState.get_user_level()])
	return content




func start_level(level_id: int) -> Dictionary:
	var resumed: Dictionary = load_resumed_level(level_id)
	if not resumed.is_empty():
		return resumed
	return load_fresh_level(level_id)





func save_initial(level_id: int, model: LevelModel, snapshot: Dictionary, 
		timing: String = "initial") -> void :
	if model != null and model.is_special_challenge():

		var special_game_id: String = LevelEntity.new_game_id()
		if not _special_saver.save_initial(model.challenge_instance_id, model, snapshot, special_game_id):
			SortLogger.error("Special Challenge 开局快照写入失败")
			return
		_log_save("special", special_game_id, timing, 0)
		return
	if model == null:
		return
	var game_id: String = _saver.save_initial(level_id, _raw_level_info_for_save(level_id, model), snapshot)
	_log_save(str(level_id), game_id, timing, 0)




func _log_save(level_label: String, game_id: String, timing: String, cost_time: int) -> void :
	SortLogger.info("[SaveData] level=%s game_id=%s timing=%s cost_time=%d" % [
		level_label, game_id, timing, cost_time])




func configure_special_challenge_schedule(model: LevelModel, resumed: bool) -> void :
	if model == null or model.is_special_challenge():
		return
	if not model.special_challenge_schedule.is_empty():
		return
	model.special_challenge_schedule = SpecialChallengeRules.default_schedule() if resumed\
	else SpecialChallengeRules.current_schedule()
	SortLogger.info("[SpecialChallenge] 本局投放配置：(level=%d, first_anchor=%d, interval=%d, resumed=%s)" % [
		model.level_id, int(model.special_challenge_schedule.first_anchor), int(model.special_challenge_schedule.interval), resumed])


func _raw_level_info_for_save(level_id: int, model: LevelModel) -> Dictionary:
	var raw_level_info: Dictionary = model.to_dict()
	if not OS.has_feature("rel") and level_id == _cheat_hard_level_id:

		var original: LevelModel = _source.get_level_model(model.chapter_index, model.level_index)
		if original != null:
			raw_level_info["difficulty_type"] = original.difficulty_type
		else:
			raw_level_info["difficulty_type"] = ""
	return raw_level_info








func get_game_id(level_id: int) -> String:
	if _is_special_cursor(level_id):
		return String(_special_saver.load_session(_special_instance_id()).get("game_id", ""))
	var entity: LevelEntity = _saver.load_entity(level_id)
	return entity.game_id if entity != null else ""







func new_transient_game_id() -> String:
	return LevelEntity.new_game_id()






func save_game_state(level_id: int, current_state: Dictionary, play_time_delta_ms: int = 0, 
		round_ms: int = -1, timing: String = "", game_id: String = "") -> void :
	if _is_special_cursor(level_id):
		var instance_id: String = _special_instance_id()
		if not _special_saver.save_state(instance_id, current_state, round_ms):
			SortLogger.error("Special Challenge 当前盘面写入失败")
			return
		_log_save("special", game_id, timing, round_ms)
		return
	_saver.save_state(level_id, current_state, play_time_delta_ms, round_ms)
	_log_save(str(level_id), game_id, timing, round_ms)






func add_play_time(level_id: int, delta_ms: int, round_ms: int = -1, 
		timing: String = "", game_id: String = "") -> void :
	if _is_special_cursor(level_id):
		if _special_saver.add_play_time(_special_instance_id(), round_ms):
			_log_save("special", game_id, timing, round_ms)
		return
	if _saver.add_play_time(level_id, delta_ms, round_ms):
		_log_save(str(level_id), game_id, timing, round_ms)




func get_round_play_time_ms(level_id: int) -> int:
	if _is_special_cursor(level_id):
		return int(_special_saver.load_session(_special_instance_id()).get("round_ms", 0))
	return _saver.load_round_play_time_ms(level_id)




func inc_level_counter(level_id: int, column: String, game_id: String = "") -> void :
	if _is_special_cursor(level_id):
		return
	if _saver.inc_counter(level_id, column):
		_log_save(str(level_id), game_id, "counter:%s" % column, -1)



func get_ztime_stats(level_id: int) -> Dictionary:
	return _saver.load_ztime_stats(level_id)



func get_level_start_times(level_id: int) -> int:
	return _saver.load_start_times(level_id)





func clear_game_state(level_id: int, timing: String = "clear", game_id: String = "") -> void :
	if _is_special_cursor(level_id):
		if _special_saver.save_state(_special_instance_id(), {}):
			_log_save("special", game_id, timing, -1)
		return
	if _saver.clear_state(level_id):
		_log_save(str(level_id), game_id, timing, -1)



func flush() -> void :
	_saver.flush()




func mark_pending_completed(level_id: int, statistics: Dictionary, 
		timing: String = "win", game_id: String = "") -> bool:
	if not _saver.mark_completed(level_id, statistics):
		return false
	_log_save(str(level_id), game_id, timing, -1)
	return true




func after_level_advance(level: int) -> void :
	_source.refresh_experiments_after_level(LevelIndex.chapter_of(level))
	_advance_chapter_data(level)


func _advance_chapter_data(level: int) -> void :
	var chapter_index: int = LevelIndex.chapter_of(level)
	var level_index: int = LevelIndex.index_of(level)
	var near_chapter_end: bool = LevelIndex.CHAPTER_SIZE - level_index <= NEAR_CHAPTER_END_THRESHOLD

	if near_chapter_end:
		await _source.ensure_local_loaded(chapter_index + 1)
	await _source.force_refresh(chapter_index)
	if near_chapter_end:

		var next_result: Dictionary = await _source.force_refresh(chapter_index + 1)
		_report_chapter_unlock(chapter_index + 1, next_result)






func _report_chapter_unlock(chapter_index: int, result: Dictionary) -> void :
	var ok: bool = bool(result.get("ok", false))
	Tracker.send_event(TrackingEvents.EV_CHAPTER_UNLOCK_MONITOR, {
		TrackingEvents.K_TOTAL_URL: String(result.get("url", "")), 
		TrackingEvents.K_CHAPTER_INDEX: chapter_index, 
		TrackingEvents.K_STATE: TrackingEvents.REQ_STATE_SUCCESS if ok else TrackingEvents.REQ_STATE_FAIL, 
		TrackingEvents.K_NET_TYPE: Tracker.net_type(), 
		TrackingEvents.K_COST_TIME: int(result.get("cost_time", 0)), 
		TrackingEvents.K_ERR_MSG: String(result.get("err_msg", "")), 
	})






func clear_cache() -> int:
	_chapter_cover_epoch += 1
	_chapter_cover_paths.clear()
	_chapter_textures.clear()
	_chapter_cover_files.clear()
	_chapter_cover_downloads.clear()
	_chapter_cover_prefetches.clear()
	_source.clear_memory()


	AESDecryptor.clear_cache()
	var removed: int = LevelDownloader.clear_disk_cache()
	_source.reseed_builtin()

	_source.restore_cached_experiments(ABManager.is_ab_init_done(), ABManager.get_ab_group_id())
	return removed



func reset_all_progress() -> void :
	DbManager.reset_all_levels()



func _load_chapter_art_if_needed() -> void :
	if not _chapter_art.is_empty():
		return
	var art: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/builtin/outer_loop/chapters.json"))
	if art is Dictionary:
		_chapter_art = art




func prefetch_next_chapter_covers(chapter: int, retry_failed: bool = false) -> void :
	if chapter < 1:
		return
	for offset: int in [1, 2]:
		var target_chapter: int = chapter + offset
		var kind: String = "image" if offset == 1 else "thumbnail"
		var key: String = "%d_%s" % [target_chapter, kind]
		if _chapter_cover_files.has(key):
			continue
		if _chapter_cover_prefetches.has(key):
			var pending: Dictionary = _chapter_cover_prefetches[key]
			if not retry_failed or not bool(pending.done):
				var download: Dictionary = _chapter_cover_downloads.get(key, {})
				if retry_failed and bool(download.get("started", false)):
					_queue_chapter_cover_download_toast("继续下载", target_chapter, kind)
				continue
		var state: Dictionary = {"done": false}
		_chapter_cover_prefetches[key] = state
		_prefetch_chapter_cover.call_deferred(target_chapter, kind, key, _chapter_cover_epoch, state)


func _prefetch_chapter_cover(chapter: int, kind: String, key: String, epoch: int, state: Dictionary) -> void :
	var active: Callable = func() -> bool:
		return epoch == _chapter_cover_epoch
	if active.call():
		_load_chapter_art_if_needed()
		await _ensure_chapter_cover_file(chapter, kind, active, true)
	state.done = true
	if not active.call() and _chapter_cover_prefetches.get(key) == state:
		_chapter_cover_prefetches.erase(key)



func ensure_chapter_cover_async(chapter: int, want_image: bool, want_thumb: bool, active: Callable = Callable()) -> void :
	if not _cover_request_active(active):
		return
	_load_chapter_art_if_needed()
	for kind: String in (["image"] if want_image else []) + (["thumbnail"] if want_thumb else []):
		if not _cover_request_active(active):
			return
		await _ensure_chapter_texture(chapter, kind, active)


func _cover_request_active(active: Callable) -> bool:
	return not active.is_valid() or bool(active.call())



func wait_chapter_covers_idle() -> void :
	while not _chapter_cover_loads.is_empty():
		await get_tree().process_frame


func _ensure_chapter_texture(chapter: int, kind: String, active: Callable) -> void :
	var key: String = "%d_%s" % [chapter, kind]
	if _chapter_cover_loads.has(key):
		var pending: Dictionary = _chapter_cover_loads[key]
		while not bool(pending.done) and _cover_request_active(active):
			await get_tree().process_frame
		if not _cover_request_active(active):
			return
	var loaded_path: String = String(_chapter_cover_paths.get(key, ""))
	if _chapter_textures.has(loaded_path):
		return
	var epoch: int = _chapter_cover_epoch
	var valid: Callable = func() -> bool:
		return epoch == _chapter_cover_epoch and _cover_request_active(active)
	var state: Dictionary = {"done": false}
	_chapter_cover_loads[key] = state
	await _prepare_chapter_texture(chapter, kind, key, epoch, valid)
	state.done = true

	if _chapter_cover_loads.get(key) == state:
		_chapter_cover_loads.erase(key)


func _prepare_chapter_texture(chapter: int, kind: String, key: String, epoch: int, active: Callable) -> void :
	var path: String = await _ensure_chapter_cover_file(chapter, kind, active)
	if not active.call() or path.is_empty():
		return
	if not _chapter_textures.has(path):
		await _load_chapter_texture(path, epoch, active)
	if active.call() and _chapter_textures.has(path):
		_chapter_cover_paths[key] = path


func _cover_download_active(state: Dictionary, epoch: int) -> bool:
	var active: bool = epoch == _chapter_cover_epoch\
	and (bool(state.persistent) or _cover_request_active(state.active))
	if not active:
		state.canceled = true
	return active



func _ensure_chapter_cover_file(chapter: int, kind: String, active: Callable, persistent: bool = false) -> String:
	if not _cover_request_active(active):
		return ""
	var key: String = "%d_%s" % [chapter, kind]
	if _chapter_cover_files.has(key):
		return String(_chapter_cover_files[key])
	var pending: Dictionary
	if _chapter_cover_downloads.has(key):
		pending = _chapter_cover_downloads[key]
		if not persistent and bool(pending.started):
			_queue_chapter_cover_download_toast("继续下载", chapter, kind)
	else:
		pending = {"done": false, "path": "", "persistent": persistent, "active": active, "canceled": false, "started": false}
		_chapter_cover_downloads[key] = pending
		_run_chapter_cover_download(chapter, kind, key, _chapter_cover_epoch, pending)
	if persistent:
		pending.persistent = true

	while not bool(pending.done) and _cover_request_active(active):
		await get_tree().process_frame
	if not _cover_request_active(active):
		return ""

	if bool(pending.canceled):
		return await _ensure_chapter_cover_file(chapter, kind, active, persistent)
	return String(pending.path)


func _run_chapter_cover_download(chapter: int, kind: String, key: String, epoch: int, state: Dictionary) -> void :
	var valid: Callable = func() -> bool: return _cover_download_active(state, epoch)
	var started: Callable = func() -> void :
		state.started = true
		_queue_chapter_cover_download_toast("开始下载", chapter, kind)
	var path: String = await _download_chapter_cover_file(chapter, kind, valid, started)
	if valid.call() and not path.is_empty():
		_chapter_cover_files[key] = path
		state.path = path
		if bool(state.started):
			_queue_chapter_cover_download_toast("下载完成", chapter, kind)
	state.done = true
	if _chapter_cover_downloads.get(key) == state:
		_chapter_cover_downloads.erase(key)


func _download_chapter_cover_file(chapter: int, kind: String, active: Callable, started: Callable) -> String:
	var entry: Dictionary = _chapter_art.get(str(chapter), {})
	var path: String = String(entry.get(kind, ""))
	if path.is_empty():
		var url: String = _source.get_chapter_cover_url(chapter - 1, kind == "thumbnail")
		if url.is_empty():
			url = String(entry.get(kind + "_url", ""))
		if url.is_empty() and chapter > 1:

			var metadata: Dictionary = {"done": false}
			_load_cover_metadata(chapter - 1, metadata)
			while not metadata.done and active.call():
				await get_tree().process_frame
			if not active.call():
				return ""
			url = _source.get_chapter_cover_url(chapter - 1, kind == "thumbnail")
		if not url.is_empty() and active.call():
			path = await _downloader.fetch_chapter_cover(url, 1024 if kind == "image" else 1080, active, started)
	return path if active.call() else ""



func _queue_chapter_cover_download_toast(action: String, chapter: int, kind: String) -> void :
	if not (OS.is_debug_build() or OS.has_feature("editor")):
		return
	var label: String = "%d章%s" % [chapter, "大背景" if kind == "image" else "缩略图"]
	if not _chapter_cover_download_toasts.is_empty():
		var last: Dictionary = _chapter_cover_download_toasts.back()
		if last.action == action and int(last.epoch) == _chapter_cover_epoch:
			if not last.labels.has(label):
				last.labels.append(label)
			return
	_chapter_cover_download_toasts.append({"action": action, "labels": [label], "epoch": _chapter_cover_epoch})
	if not _chapter_cover_download_toast_running:
		_chapter_cover_download_toast_running = true
		_drain_chapter_cover_download_toasts.call_deferred()


func _drain_chapter_cover_download_toasts() -> void :
	while not _chapter_cover_download_toasts.is_empty():
		var message: Dictionary = _chapter_cover_download_toasts.pop_front()
		if int(message.epoch) != _chapter_cover_epoch:
			continue
		SceneManager.show_toast(String(message.action) + "、".join(message.labels), 2.0)
		await get_tree().create_timer(2.4).timeout
	_chapter_cover_download_toast_running = false


func _load_cover_metadata(chapter: int, state: Dictionary) -> void :
	await _source.ensure_chapter_loaded(chapter, FOREGROUND_LOAD_TIMEOUT)
	state.done = true


func _load_chapter_texture(path: String, epoch: int, active: Callable = Callable()) -> void :
	if path.begins_with("res://"):
		var status: int = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			if ResourceLoader.load_threaded_request(path, "Texture2D") != OK:
				return
		while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
			var texture: Texture2D = ResourceLoader.load_threaded_get(path) as Texture2D
			if epoch == _chapter_cover_epoch and _cover_request_active(active):
				_chapter_textures[path] = texture
		return

	var worker: = Thread.new()
	if worker.start( func() -> Image: return Image.load_from_file(path)) != OK:
		return
	while worker.is_alive():
		await get_tree().process_frame
	var decoded: Image = worker.wait_to_finish() as Image
	if epoch == _chapter_cover_epoch and _cover_request_active(active) and decoded != null and not decoded.is_empty():
		_chapter_textures[path] = ImageTexture.create_from_image(decoded)


func get_chapter_image_path(chapter: int) -> String:
	return String(_chapter_cover_paths.get("%d_image" % chapter, ""))


func get_chapter_thumbnail_path(chapter: int) -> String:
	return String(_chapter_cover_paths.get("%d_thumbnail" % chapter, ""))



func load_local_texture(path: String) -> Texture2D:
	return _chapter_textures.get(path) as Texture2D



func get_chapter_title(chapter: int) -> String:
	var title: Dictionary = (_chapter_art.get(str(chapter), {}) as Dictionary).get("title", {})
	if title.is_empty():
		var meta: ChapterModel = _source.get_chapter_model(chapter - 1)
		if meta != null:
			title = meta.title
	var locale: String = TranslationServer.get_locale()
	var aliases: Dictionary = {"zh_CN": "zh-rCN", "zh_TW": "zh-rTW", "pt_BR": "pt", "id": "in", "he": "iw", "fi": "fi-rFI", "nl": "nl-rNL", "ar": "ar-rSA"}
	var key: String = String(aliases.get(locale, locale))
	return String(title.get(key, title.get(locale.get_slice("_", 0), title.get("en", str(chapter)))))


func release_unused_chapter_textures(chapter: int) -> void :
	var keep: Array[String] = []
	for n: int in range(chapter, chapter + 3):
		keep.append(get_chapter_image_path(n))
		keep.append(get_chapter_thumbnail_path(n))
	for path: Variant in _chapter_textures.keys():
		if not keep.has(String(path)):
			_chapter_textures.erase(path)


func _special_instance_id() -> String:
	return String(UserState.get_special_challenge().get("instance_id", ""))

func _is_special_cursor(level: int) -> bool:
	return level == UserState.get_current_level() and UserState.has_special_challenge()



func preview_next_round_descriptor() -> Dictionary:
	var current: int = UserState.get_current_level()
	var timed: Dictionary = UserState.get_timed_endless_offer()
	if not timed.is_empty():
		return {"is_special": false, "is_timed_endless": true, "level": current, 
			"instance_id": timed["instance_id"], "reward_pending": timed.get("status", "") == "reward_pending", 
			"raw_level_info": "{}"}
	var preview: Dictionary = UserState.get_special_challenge_preview_state()
	var challenge: Dictionary = preview["challenge"]
	var ordinary: Dictionary = _saver.load_resume_preview(current)
	var anchor_id: int = int(preview["offer_after"])
	if challenge.is_empty() and anchor_id > 0 and anchor_id + 1 == current:
		var has_normal_resume: bool = bool(ordinary["has_resume"])
		if has_normal_resume:
			var anchor: Dictionary = _saver.load_resume_preview(anchor_id)
			if bool(anchor["completed"]) and int(anchor["updated_at"]) > 0 and int(ordinary["updated_at"]) > 0:
				has_normal_resume = int(ordinary["updated_at"]) >= int(anchor["updated_at"])
		if not has_normal_resume:
			challenge = {"instance_id": "special:%d:%d" % [anchor_id, int(preview["completed"]) + 1], 
				"status": "playing"}
	var instance_id: String = String(challenge.get("instance_id", ""))
	var resumed: Dictionary = _special_saver.load_resume_preview(instance_id) if not instance_id.is_empty() else ordinary
	return {"is_special": not challenge.is_empty(), "is_timed_endless": false, "level": current, 
		"instance_id": instance_id, "reward_pending": challenge.get("status", "") in ["win_pending", "reward_pending"], 
		"raw_level_info": resumed["raw_level_info"] if not challenge.is_empty() or bool(ordinary["has_resume"]) else "{}"}


func get_next_round_descriptor(expose: bool = true) -> Dictionary:
	var current: int = UserState.get_current_level()
	var timed: Dictionary = UserState.get_timed_endless_offer()
	if not timed.is_empty():
		return {"is_special": false, "is_timed_endless": true, "timed_endless": timed, 
			"level": current, "instance_id": timed["instance_id"], "case_number": 0, 
			"reward_pending": timed.get("status", "") == "reward_pending"}
	if expose and UserState.get_special_challenge_offer_after() > 0:

		var ordinary: LevelEntity = _saver.load_entity(current)
		var has_normal_resume: bool = ordinary != null and not ordinary.current_state.is_empty()
		if has_normal_resume:
			var anchor: LevelEntity = _saver.load_entity(UserState.get_special_challenge_offer_after())
			if anchor != null and anchor.completed and anchor.updated_at > 0 and ordinary.updated_at > 0:
				has_normal_resume = ordinary.updated_at >= anchor.updated_at
				if not has_normal_resume:
					SortLogger.info("[SpecialChallenge] 第 %d 关历史盘面早于本次前置关通关，不阻断特殊关入口" % current)
		UserState.resolve_special_challenge_offer( not has_normal_resume)
	var challenge: Dictionary = UserState.get_special_challenge()
	return {"is_special": not challenge.is_empty(), "is_timed_endless": false, "level": current, 
		"instance_id": String(challenge.get("instance_id", "")), 
		"case_number": int(challenge.get("case_number", 0)), 
		"reward_pending": challenge.get("status", "") in ["win_pending", "reward_pending"]}

func load_special_challenge() -> Dictionary:
	var challenge: Dictionary = UserState.get_special_challenge()
	if challenge.is_empty():
		return {}
	var instance_id: String = String(challenge["instance_id"])
	var old_challenge: bool = not challenge.has("level2_slot")\
	or bool(challenge.get("level2_legacy", false))
	if old_challenge:

		UserState.migrate_special_challenge_to_level2(instance_id, int(challenge.get("case_number", 0)))
		challenge = UserState.get_special_challenge()
	var saved: Dictionary = _special_saver.load_session(instance_id)
	var envelope: Dictionary = saved.get("raw_level_info", {}) as Dictionary
	var resumed: bool = not envelope.is_empty()
	if not resumed:
		var case_number: int = int(challenge["case_number"])
		var bank: int = 0
		if not old_challenge:
			var slot: int = int(challenge.get("level2_slot", 0))

			if slot == 1:
				ABManager.dye_at_special_level()
			if ABManager.special_level2.is_special_level_v2_enabled():
				var picked: Dictionary = UserState.advance_special_level2_case(instance_id, slot)
				if not picked.is_empty():
					bank = int(picked["bank"])
					case_number = int(picked["case_number"])
		envelope = _special_bank.read_case(case_number, bank)
		if envelope.is_empty():
			return {}
		var current: int = UserState.get_current_level()
		envelope["level_id"] = current
		envelope["chapter_index"] = LevelIndex.chapter_of(current)
		envelope["level_index"] = LevelIndex.index_of(current)
		envelope["round_kind"] = "special_challenge"
		envelope["challenge_instance_id"] = instance_id

	var parser: LevelParser = _parser_for(String(envelope.get("gameplay_type", "")))
	var model: LevelModel = parser.model_from_dict(envelope) if parser != null else null
	if model == null:
		SortLogger.error("Special Challenge 题面解析失败: %s" % instance_id)
		return {}
	var state: Dictionary = saved.get("current_state", {}) as Dictionary
	var pending: bool = challenge.get("status", "") in ["win_pending", "reward_pending"]
	if pending:
		state = saved.get("initial_state", {}) as Dictionary
	return {"model": model, "current_state": state, "resumed": resumed, 
		"reward_pending": pending, "updated_at": int(saved.get("updated_at", 0)), 
		"game_id": String(saved.get("game_id", ""))}


func complete_special_challenge(instance_id: String, notify_success: bool = true, 
		daily_checkin_completion: Dictionary = {}, timing: String = "win", 
		game_id: String = "") -> bool:

	var was_reward_pending: bool = String(UserState.get_special_challenge().get("status", "")) == "reward_pending"
	if not UserState.begin_special_challenge_completion(instance_id, daily_checkin_completion):
		return false
	if not _special_saver.complete(instance_id):
		SortLogger.error("Special Challenge 完成记录写入失败，保留 journal")
		return false
	_log_save("special", game_id, timing, -1)
	if not UserState.finalize_special_challenge_completion():
		return false

	if notify_success and not was_reward_pending\
	and String(UserState.get_special_challenge().get("status", "")) == "reward_pending":
		special_challenge_completed.emit(instance_id)
	return true


func recover_special_challenge_completion(notify_success: bool = true) -> bool:
	var challenge: Dictionary = UserState.get_special_challenge()
	if challenge.get("status", "") != "win_pending":
		return true
	var instance_id: String = String(challenge["instance_id"])
	var game_id: String = String(_special_saver.load_session(instance_id).get("game_id", ""))
	return complete_special_challenge(instance_id, notify_success, {}, "recover_win", game_id)


func _load_at_launch_optimized() -> void :
	bind_chapter_channel()

	var current_chapter: int = LevelIndex.chapter_of(UserState.get_current_level())

	await _source.ensure_local_loaded(current_chapter)

	_startup_chapter = current_chapter


func first_page_entered() -> void :
	if _startup_refresh_started or _startup_chapter <= 0:
		return
	_startup_refresh_started = true
	_refresh_chapter_after_launch(_startup_chapter)
