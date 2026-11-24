extends Node


signal snapshot_changed(snap: RankSnapshot)

const SEASON_DAYS: int = 2
const BOT_COUNT: int = 49
const CLOCK_ROLLBACK_TOLERANCE_MS: int = 5 * 60 * 1000

const NICKNAME_MAX_LENGTH: int = 16

const UNLOCK_LEVEL: int = 20

const SCORING_TARGET_COUNT: String = "target_count"

const ELEMENT_TITLE_KEY_FIXED: String = "RANK_TITLE_ELEMENT_PHOTO"





const CHALLENGE_ITEM_NAME: String = "flower"



const COLLECT_TEXTURE_PATH: String = "res://assets/sprites/common_rank_collect_item.png"
const COLLECTIBLE_NAMES: PackedStringArray = ["elk", "tree", "snow", "gingerbread", "bell"]



var _cached_snapshot: RankSnapshot = null
var _snapshot_dirty: bool = true
var _collectible_index_loaded: bool = false
var _cached_collectible_index: int = -1
var _clock_rolled_back: bool = false
var _last_round_result: Dictionary = {}



func _notification(what: int) -> void :
	if what == NOTIFICATION_APPLICATION_RESUMED and OS.has_feature("android"):
		_reupload_collect_texture()



func _reupload_collect_texture() -> void :
	_reupload_texture_if_cached(COLLECT_TEXTURE_PATH)
	var index: int = get_collectible_index()
	if index >= 0:
		_reupload_texture_if_cached("res://assets/sprites/juice_sort/rank_collectible/%s.png" % COLLECTIBLE_NAMES[index])
		_reupload_texture_if_cached("res://assets/sprites/juice_sort/rank_collectible/gift_%s.png" % COLLECTIBLE_NAMES[index])

func _reupload_texture_if_cached(path: String) -> void :
	var texture: CompressedTexture2D = ResourceLoader.get_cached_ref(path) as CompressedTexture2D
	if texture == null:
		return
	var err: Error = texture.load(texture.load_path)
	if err != OK:
		SortLogger.error("[Rank] 回前台重传收集物贴图失败 err=%d path=%s" % [err, texture.load_path])
		return
	SortLogger.info("[Rank] 回前台已重传收集物贴图")


func get_current_snapshot() -> RankSnapshot:
	if not is_enabled():
		return RankSnapshot.new()
	if _snapshot_dirty or _cached_snapshot == null:
		_cached_snapshot = _build_snapshot()
		_snapshot_dirty = false
		snapshot_changed.emit(_cached_snapshot)
	return _cached_snapshot


func invalidate_snapshot() -> void :
	_snapshot_dirty = true
	_collectible_index_loaded = false


func _build_snapshot() -> RankSnapshot:
	var entity: Dictionary = UserState.get_rank_current_entity()
	var now_ms: int = _now_ms()
	if _prepare_bot_collect_rules(entity, now_ms) and not UserState.commit_rank_entity(entity):
		SortLogger.error("[Rank] 假用户收集规则升级保存失败")
		entity = UserState.get_rank_current_entity()
	return RankSnapshotBuilder.build(
		entity, 
		now_ms, 
		get_display_nickname(), 
		get_display_avatar_index()
	)


func _prepare_bot_collect_rules(entity: Dictionary, now_ms: int) -> bool:
	if entity.is_empty() or is_update_activity(entity) or now_ms >= int(entity.get("end_time", 0)):
		return false
	var elapsed_seconds: int = RankSnapshotBuilder.bot_elapsed_seconds(entity, now_ms)
	var event_id: String = String(entity.get("event_id", ""))
	var tier: int = int(entity.get("start_tier", 1))
	var bots: Array = entity.get("bots", [])
	var changed: bool = false
	for i in bots.size():
		var bot: Dictionary = bots[i]
		var seed_value: int = 0 if bot.has("collect_seed") else RankFakeUserGenerator.derive_seed(event_id, tier, i)
		changed = RankFakeUserGenerator.prepare_collect_rules(bot, seed_value, elapsed_seconds) or changed
	changed = RankFakeUserGenerator.prepare_activity_rules(bots, event_id, tier, elapsed_seconds) or changed
	return changed


func is_valid_rank_in_game() -> bool:
	if not is_unlocked():
		return false
	if not _refresh_clock_state():
		return false
	var entity: Dictionary = UserState.get_rank_current_entity()
	if entity.is_empty():
		return false
	if not bool(entity.get("has_guide", false)):
		return false
	return not bool(entity.get("update_pending_start", false)) and _now_ms() < int(entity.get("end_time", 0))


func is_enabled() -> bool:
	return not UserState.is_rank_disabled()


func is_unlocked() -> bool:
	if not is_enabled():
		return false
	if UserState.is_rank_unlocked():
		return true
	var gate: int = get_unlock_level()
	if UserState.get_current_level() > gate:
		UserState.mark_rank_unlocked()
		SortLogger.info("[Rank] 排行榜解锁(已完成第 %d 关)" % gate)
		return UserState.is_rank_unlocked()
	return false



func has_pending_session() -> bool:
	if not is_unlocked() or not _refresh_clock_state():
		return false
	ensure_profile()
	ensure_season()
	var entity: Dictionary = UserState.get_rank_current_entity()
	return not entity.is_empty() and (is_season_ended() or not bool(entity.get("has_guide", false)))


func is_rank_disabled() -> bool:
	return UserState.is_rank_disabled()


func set_rank_disabled(disabled: bool) -> void :
	UserState.set_rank_disabled(disabled)
	SortLogger.info("[Rank] %s排行榜" % ("强制关闭" if disabled else "恢复"))
	invalidate_snapshot()
	get_current_snapshot()


func get_unlock_level() -> int:
	if ABManager.rank_unlock_timing.is_level_15_unlock_enabled():
		return 15
	elif ABManager.rank_unlock_timing.is_level_10_unlock_enabled():
		return 10

	return UNLOCK_LEVEL


func get_scoring_mode() -> String:
	if not is_valid_rank_in_game():
		return ""
	return SCORING_TARGET_COUNT


func is_tier_browsing_enabled() -> bool:
	return true


func is_rankup_celebration_enabled() -> bool:
	return true


func is_clock_rolled_back() -> bool:
	return _clock_rolled_back


func get_collect_num() -> int:
	var entity: Dictionary = UserState.get_rank_current_entity()
	if entity.is_empty():
		return 0
	return int(entity.get("collect_num", 0))


func get_current_tier() -> int:
	var entity: Dictionary = UserState.get_rank_current_entity()
	if entity.is_empty():
		return RankSettleLogic.TIER_MIN
	return int(entity.get("start_tier", RankSettleLogic.TIER_MIN))


func get_my_rank_pos() -> int:
	return maxi(get_current_snapshot().my_rank_pos, 0)


func get_remain_seconds() -> int:
	var entity: Dictionary = UserState.get_rank_current_entity()
	if entity.is_empty():
		return 0
	if bool(entity.get("update_pending_start", false)):
		return int((int(entity.end_time) - int(entity.start_time)) / 1000)
	return maxi(int(entity.get("end_time", 0)) - _now_ms(), 0) / 1000






func get_challenge_info_params() -> Dictionary:
	var snap: RankSnapshot = get_current_snapshot()
	if not snap.is_valid():
		return {}
	return {
		TrackingEvents.K_EVENT_ID: snap.event_id, 

		TrackingEvents.K_LEVEL_NUM: UserState.get_current_level(), 
		TrackingEvents.K_LEFT_TIME: get_remain_seconds(), 
		TrackingEvents.K_CHALLENGE_ITEM: CHALLENGE_ITEM_NAME, 
		TrackingEvents.K_ITEM_NUM: get_collect_num(), 
		TrackingEvents.K_CHALLENGE_RANK: snap.my_rank_pos, 
		TrackingEvents.K_CHALLENGE_LEVEL: get_current_tier(), 
		TrackingEvents.K_START_DT: Time.get_datetime_string_from_unix_time(
			int(snap.start_time / 1000.0), true), 
		TrackingEvents.K_END_DT: Time.get_datetime_string_from_unix_time(
			int(snap.end_time / 1000.0), true), 
	}


func is_season_ended() -> bool:
	var entity: Dictionary = UserState.get_rank_current_entity()
	if entity.is_empty():
		return false
	return not bool(entity.get("update_pending_start", false)) and _now_ms() >= int(entity.get("end_time", 0))


func format_remaining(total_seconds: int) -> String:
	var s: int = maxi(total_seconds, 0)
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]





func ensure_profile() -> void :
	if not is_enabled():
		return
	var nickname: String = UserState.get_rank_nickname()
	var avatar: int = UserState.get_rank_avatar_index()
	var avatar_stale: bool = avatar >= 0 and not RankFakeUserGenerator.VISIBLE_AVATARS.has(avatar)
	if not nickname.is_empty() and not avatar_stale and avatar >= 1:
		return
	var rng: = RandomNumberGenerator.new()
	rng.randomize()
	if nickname.is_empty():
		nickname = "Player_%s" % RankFakeUserGenerator.random_nickname_suffix(rng)
	if avatar < 0:
		avatar = RankFakeUserGenerator.random_avatar_index(rng)
	elif avatar_stale:
		SortLogger.info("[Rank] 玩家头像 index=%d 已不在可用清单,回落 1 号" % avatar)
		avatar = 1
	UserState.set_rank_profile(nickname, avatar)
	invalidate_snapshot()


func set_profile(nickname: String, avatar_index: int) -> bool:
	var trimmed: String = nickname.strip_edges().substr(0, NICKNAME_MAX_LENGTH)
	if trimmed.is_empty():
		return false
	var avatar: int = avatar_index
	if not RankFakeUserGenerator.VISIBLE_AVATARS.has(avatar):
		avatar = get_display_avatar_index()
	if not UserState.set_rank_profile(trimmed, avatar):
		return false
	invalidate_snapshot()
	return true


func get_display_nickname() -> String:
	var saved: String = UserState.get_rank_nickname()
	return saved if not saved.is_empty() else "Player"


func get_display_avatar_index() -> int:
	var avatar: int = UserState.get_rank_avatar_index()
	return avatar if RankFakeUserGenerator.VISIBLE_AVATARS.has(avatar) else 1


func get_display_title() -> String:
	return tr(ELEMENT_TITLE_KEY_FIXED)



func _next_update_mode() -> String:
	if ABManager.rank_update.is_24_hour_activity_enabled():
		return "new_24"
	elif ABManager.rank_update.is_48_hour_activity_enabled():
		return "new_48"
	return "old"


func is_update_activity(entity: Dictionary) -> bool:
	return String(entity.get("update_mode", "old")) in ["new_24", "new_48"]


func _season_parameters(tier: int) -> Dictionary:
	var mode: String = _next_update_mode()
	var start_ms: int = _today_start_ms() if mode == "old" else _now_ms()
	var duration_ms: int = (24 if mode == "new_24" else 48) * 3600 * 1000
	return {"mode": mode, "start_ms": start_ms, "end_ms": start_ms + duration_ms, 
		"event_id": _today_event_id() if mode == "old" else "rank_%d_%d" % [start_ms, tier]}



func activate_update_activity() -> bool:
	var entity: Dictionary = UserState.get_rank_current_entity()
	var start_clock: bool = is_update_activity(entity) and bool(entity.get("update_pending_start", false))
	var freeze_collectible: bool = bool(entity.get("collectible_pending_start", false))
	if not start_clock and not freeze_collectible:
		return true
	if freeze_collectible:
		ABManager.dye_at_rank_collectible_activity()
		entity["collectible_index"] = -1
		entity["collectible_column_count"] = ABManager.rank_collectible_fx.is_column_count_enabled()
		if ABManager.rank_collectible_fx.is_collectible_replacement_enabled():
			var index: int = posmod(int(entity.get("collectible_cycle", -1)) + 1, COLLECTIBLE_NAMES.size())
			entity["collectible_index"] = index
			entity["collectible_cycle"] = index
		for bot: Dictionary in entity.get("bots", []):
			bot["collectible_column_count"] = bool(entity.collectible_column_count)
		entity["collectible_pending_start"] = false
	if start_clock:
		var duration_ms: int = int(entity.end_time) - int(entity.start_time)
		var now_ms: int = _now_ms()
		entity["start_time"] = now_ms
		entity["end_time"] = now_ms + duration_ms
		entity["bot_start_time"] = now_ms
		entity["update_pending_start"] = false
	if not UserState.commit_rank_entity(entity):
		SortLogger.error("[Rank] 新实验活动起点保存失败")
		return false
	invalidate_snapshot()
	return true


func get_collectible_index() -> int:

	if not _collectible_index_loaded:
		var index: int = int(UserState.get_rank_current_entity().get("collectible_index", -1))
		_cached_collectible_index = index if index >= 0 and index < COLLECTIBLE_NAMES.size() else -1
		_collectible_index_loaded = true
	return _cached_collectible_index

func _prepare_collectible_activity(entity: Dictionary, previous: Dictionary) -> void :
	entity["collectible_pending_start"] = true
	entity["collectible_index"] = -1
	entity["collectible_cycle"] = int(previous.get("collectible_cycle", -1))



func prepare_update_round(round_id: String, my_delta: int) -> bool:
	if round_id.is_empty():
		return true
	var entity: Dictionary = UserState.get_rank_current_entity()
	if not is_update_activity(entity) or not is_valid_rank_in_game():
		return true
	var now_ms: int = _now_ms()
	var rows: Array = RankSnapshotBuilder.build(entity, now_ms, 
		get_display_nickname(), get_display_avatar_index()).rows
	if not RankUpdateRule.prepare_round(entity, rows, 
			RankSnapshotBuilder.bot_elapsed_seconds(entity, now_ms), round_id, my_delta):
		return true
	if not UserState.commit_rank_entity(entity):
		SortLogger.error("[Rank] 对局竞争计划保存失败")
		return false
	invalidate_snapshot()
	return true


func ensure_season() -> bool:
	if not is_unlocked() or not _refresh_clock_state():
		return false

	var entity: Dictionary = UserState.get_rank_current_entity()

	if entity.is_empty():
		return _create_season(RankSettleLogic.TIER_MIN)


	var now: int = _now_ms()
	var ended: bool = not bool(entity.get("update_pending_start", false)) and now >= int(entity.get("end_time", 0))
	if not ended:
		return false

	if not bool(entity.get("has_receive_bonus", false)):
		return false

	return _create_season(int(entity.get("end_tier", RankSettleLogic.TIER_MIN)))



func prepare_startup_session(active: Callable) -> bool:
	if not active.call():
		return false
	if not is_unlocked():
		return true
	var profile_started: int = Time.get_ticks_usec()
	ensure_profile()
	if UserState.get_rank_nickname().is_empty() or UserState.get_rank_avatar_index() < 1:
		SortLogger.error("[StartupRank] 玩家资料未成功保存")
		return false
	SortLogger.info("[StartupRank] profile_commit_ms=%.2f" % ((Time.get_ticks_usec() - profile_started) / 1000.0))
	await get_tree().process_frame
	if not active.call():
		return false
	if not _refresh_clock_state():
		return true
	var previous: Dictionary = UserState.get_rank_current_entity()
	if not previous.is_empty() and (bool(previous.get("update_pending_start", false)) or _now_ms() < int(previous.get("end_time", 0))
			or not bool(previous.get("has_receive_bonus", false))):
		return true
	var tier: int = int(previous.get("end_tier", RankSettleLogic.TIER_MIN))
	var parameters: Dictionary = _season_parameters(tier)
	var event_id: String = parameters.event_id
	var start_ms: int = parameters.start_ms

	var seed_bot: Dictionary = RankFakeUserGenerator.generate_bot(event_id, tier, 0, {})
	RankFakeUserGenerator.get_collect_progress_at(seed_bot, 0)
	var worker: = Thread.new()
	var started: int = Time.get_ticks_usec()
	var error: Error = worker.start(RankSnapshotBuilder.create_entity.bind(
		event_id, start_ms, int(parameters.end_ms), tier, BOT_COUNT, String(parameters.mode)))
	if error != OK:
		SortLogger.error("[StartupRank] 赛季工作线程启动失败 error=%d" % error)
		return false

	await get_tree().process_frame
	while worker.is_alive():
		await get_tree().process_frame
	var entity: Dictionary = worker.wait_to_finish()
	SortLogger.info("[StartupRank] entity_worker_ms=%.2f" % ((Time.get_ticks_usec() - started) / 1000.0))
	if not active.call():
		return false
	if not is_enabled() or not _refresh_clock_state():
		return true
	if UserState.get_rank_current_entity() != previous:
		SortLogger.error("[StartupRank] 等待期间赛季已改变，丢弃旧结果")
		return false
	if String(parameters.mode) == "old" and _today_event_id() != event_id:
		return await prepare_startup_session(active)
	var commit_started: int = Time.get_ticks_usec()
	_prepare_collectible_activity(entity, previous)
	var saved: bool = UserState.commit_rank_entity(entity)
	SortLogger.info("[StartupRank] entity_commit_ms=%.2f saved=%s" % [
		(Time.get_ticks_usec() - commit_started) / 1000.0, saved])
	if saved:
		invalidate_snapshot()
		SortLogger.info("[Rank] 新赛季 %s tier=%d 机器人=%d" % [event_id, tier, BOT_COUNT])
	return saved


func _create_season(start_tier: int) -> bool:
	var previous: Dictionary = UserState.get_rank_current_entity()
	var parameters: Dictionary = _season_parameters(start_tier)
	var event_id: String = parameters.event_id
	var entity: Dictionary = RankSnapshotBuilder.create_entity(
		event_id, int(parameters.start_ms), int(parameters.end_ms), start_tier, BOT_COUNT, String(parameters.mode)
	)
	_prepare_collectible_activity(entity, previous)
	if not UserState.commit_rank_entity(entity):
		return false
	invalidate_snapshot()
	SortLogger.info("[Rank] 新赛季 %s tier=%d 机器人=%d" % [event_id, start_tier, BOT_COUNT])
	return true


func is_first_time_rank_ever() -> bool:
	return not UserState.is_rank_ever_played()


func mark_rank_ever_played() -> void :
	UserState.mark_rank_ever_played()


func mark_guide_shown() -> void :
	var entity: Dictionary = UserState.get_rank_current_entity()
	if entity.is_empty() or bool(entity.get("has_guide", false)):
		return
	entity["has_guide"] = true
	UserState.commit_rank_entity(entity)
	invalidate_snapshot()


func commit_round_score(delta: int, rank_before: int, round_id: String, season_id: String) -> Dictionary:
	var entity: Dictionary = UserState.get_rank_current_entity()
	if String(entity.get("last_round_id", "")) == round_id and not round_id.is_empty():
		return {"ok": true, "applied": false}
	if delta <= 0 or season_id.is_empty() or String(entity.get("event_id", "")) != season_id or not is_valid_rank_in_game():
		return {"ok": true, "applied": false}
	if round_id.is_empty():
		return {"ok": false, "applied": false}

	var now_ms: int = _now_ms()
	_prepare_bot_collect_rules(entity, now_ms)

	if entity.has("bot_start_time") and int(entity.bot_start_time) == 0:
		entity["bot_start_time"] = now_ms
	if is_update_activity(entity):
		RankUpdateRule.materialize(entity.get("bots", []), RankSnapshotBuilder.bot_elapsed_seconds(entity, now_ms), true)
	entity["last_round_id"] = round_id
	entity["collect_num"] = int(entity.get("collect_num", 0)) + delta
	var scored_round_count: int = int(entity.get("scored_round_count", 0)) + 1
	entity["scored_round_count"] = scored_round_count

	var picks: Array[Dictionary] = []
	var bots: Array = entity.get("bots", [])
	var net_rank_before: int = rank_before
	if is_update_activity(entity):
		net_rank_before = int(entity.get("update_last_finish_rank", rank_before))
	elif not bots.is_empty():
		var snap: RankSnapshot = RankSnapshotBuilder.build(
			entity, now_ms, get_display_nickname(), get_display_avatar_index())
		var rng: = RandomNumberGenerator.new()
		rng.seed = (season_id + round_id).hash()
		var elapsed_seconds: int = RankSnapshotBuilder.bot_elapsed_seconds(entity, now_ms)
		var catch_up: Dictionary = RankCatchUpRule.resolve(snap.rows, rank_before, delta, rng, bots, 
			elapsed_seconds, scored_round_count, entity.get("catch_up_wave", {}))
		picks.assign(catch_up.picks)
		if catch_up.wave.is_empty():
			entity.erase("catch_up_wave")
		else:
			entity["catch_up_wave"] = catch_up.wave
		for bot_index: int in catch_up.growth_rounds:
			bots[bot_index]["last_catch_up_growth_round"] = int(catch_up.growth_rounds[bot_index])
		for pick: Dictionary in picks:
			var idx: int = int(pick.get("bot_index", -1))
			if idx < 0 or idx >= bots.size():
				continue
			var bot: Dictionary = bots[idx]
			var before: int = int(bot.get("bonus", 0))
			bot["bonus"] = before + int(pick.get("bonus", 0))
			bot["bonus_budget"] = int(bot.get("bonus_budget", 0)) + int(pick.get("budget_delta", 0))
			SortLogger.info("[RankBoost] bot[%d] %s bonus %d -> %d(+%d), budget +%d, levels +%d" % [
				idx, String(bot.get("nickname", "")), before, int(bot["bonus"]), 
				int(pick.get("bonus", 0)), int(pick.get("budget_delta", 0)), int(pick.completed_levels)])

	if is_update_activity(entity):
		var rank_after: int = RankSnapshotBuilder.build(entity, now_ms, get_display_nickname(), get_display_avatar_index()).my_rank_pos
		entity["update_last_finish_rank"] = rank_after
		entity["update_stalled_rounds"] = int(entity.get("update_stalled_rounds", 0)) + 1 if rank_after >= net_rank_before else 0
	if not UserState.commit_rank_entity(entity):
		return {"ok": false, "applied": false}
	invalidate_snapshot()
	report_round_result(net_rank_before, get_my_rank_pos(), delta)
	return {"ok": true, "applied": true, "rank_before": rank_before, "my_delta": delta, "picks": picks}


func report_round_result(rank_before: int, rank_after: int, collect_delta: int) -> void :
	if collect_delta <= 0 or not is_valid_rank_in_game():
		return
	var snap: RankSnapshot = get_current_snapshot()
	_last_round_result = {
		"rank_before": rank_before, 
		"rank_after": rank_after, 
		"collect_delta": collect_delta, 
		"tier": snap.start_tier, 
		"event_id": snap.event_id, 
		"upgrade_end_rank": snap.upgrade_end_rank, 
		"downgrade_start_rank": snap.downgrade_start_rank, 
	}


func take_last_round_result() -> Dictionary:
	var result: Dictionary = _last_round_result
	_last_round_result = {}
	return result


func check_rank_end() -> Dictionary:
	var result: Dictionary = {
		"has_ended": false, 
		"rank_pos": -1, 
		"start_tier": RankSettleLogic.TIER_MIN, 
		"end_tier": RankSettleLogic.TIER_MIN, 
		"reward_hint": 0, 
		"reward_coin": 0, 
	}
	var entity: Dictionary = UserState.get_rank_current_entity()
	if not is_unlocked() or entity.is_empty() or not _refresh_clock_state():
		return result
	if bool(entity.get("update_pending_start", false)) or _now_ms() < int(entity.get("end_time", 0)):
		return result
	if bool(entity.get("has_receive_bonus", false)):
		return result

	invalidate_snapshot()
	var snap: RankSnapshot = get_current_snapshot()
	var rank_pos: int = snap.my_rank_pos
	var start_tier: int = snap.start_tier
	var end_tier: int = RankSettleLogic.compute_tier_after(
		rank_pos, start_tier, snap.upgrade_end_rank, snap.downgrade_start_rank
	)
	var reward: Dictionary = RankSettleLogic.get_reward(rank_pos, start_tier)
	var reward_hint: int = int(reward.get("hint", 0))
	var reward_coin: int = int(reward.get("coin", 0))

	if String(entity.get("settle_state", "")) != "computed"\
	or int(entity.get("rank_pos", -1)) != rank_pos\
	or not entity.has("reward_coin"):
		entity["settle_state"] = "computed"
		entity["rank_pos"] = rank_pos
		entity["end_tier"] = end_tier
		entity["reward_hint"] = reward_hint
		entity["reward_coin"] = reward_coin
		if not UserState.commit_rank_entity(entity):
			return result
		invalidate_snapshot()

	result["event_id"] = String(entity.get("event_id", ""))
	result["has_ended"] = true
	result["rank_pos"] = rank_pos
	result["start_tier"] = start_tier
	result["end_tier"] = end_tier
	result["reward_hint"] = reward_hint
	result["reward_coin"] = reward_coin
	return result


func get_reward_preview(rank_pos: int) -> Dictionary:
	return RankSettleLogic.get_reward(rank_pos, get_current_tier())





func cheat_adjust_collect_num(delta: int) -> void :
	var entity: Dictionary = UserState.get_rank_current_entity()
	if entity.is_empty():
		return
	entity["collect_num"] = maxi(int(entity.get("collect_num", 0)) + delta, 0)
	UserState.commit_rank_entity(entity)
	invalidate_snapshot()


func cheat_set_tier(tier: int) -> void :
	var entity: Dictionary = UserState.get_rank_current_entity()
	if entity.is_empty():
		return
	entity["start_tier"] = clampi(tier, RankSettleLogic.TIER_MIN, RankSettleLogic.TIER_MAX)
	UserState.commit_rank_entity(entity)
	invalidate_snapshot()


func cheat_force_end_season() -> void :
	var entity: Dictionary = UserState.get_rank_current_entity()
	if entity.is_empty():
		return
	entity["end_time"] = mini(int(entity.get("end_time", 0)), _now_ms())
	entity["update_pending_start"] = false
	UserState.commit_rank_entity(entity)
	invalidate_snapshot()


func cheat_force_new_season() -> void :
	var entity: Dictionary = UserState.get_rank_current_entity()
	var start_tier: int = int(entity.get("end_tier", RankSettleLogic.TIER_MIN)) if not entity.is_empty() else RankSettleLogic.TIER_MIN
	_create_season(start_tier)


func cheat_set_remaining_seconds(sec: int) -> bool:
	var entity: Dictionary = UserState.get_rank_current_entity()
	if entity.is_empty():
		return false
	entity["end_time"] = _now_ms() + maxi(sec, 0) * 1000
	entity["update_pending_start"] = false
	if not is_update_activity(entity):
		entity["event_id"] = _event_id_days_ago(SEASON_DAYS)
	UserState.commit_rank_entity(entity)
	invalidate_snapshot()
	return true


func _now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)


func _refresh_clock_state() -> bool:
	var now: int = _now_ms()
	var watermark: int = UserState.get_rank_clock_watermark()
	if watermark > 0 and now < watermark - CLOCK_ROLLBACK_TOLERANCE_MS:
		if not _clock_rolled_back:
			SortLogger.warn("[Rank] 检测到设备时钟回拨(now=%d < watermark=%d),暂停排行榜" % [now, watermark])
		_clock_rolled_back = true
		return false
	_clock_rolled_back = false
	UserState.advance_rank_clock_watermark(now)
	return true


func _today_start_ms() -> int:
	var local: Dictionary = Time.get_datetime_dict_from_system(false)
	local["hour"] = 0
	local["minute"] = 0
	local["second"] = 0
	var as_if_utc: int = int(Time.get_unix_time_from_datetime_dict(local))
	var bias_minutes: int = int(Time.get_time_zone_from_system().get("bias", 0))
	return (as_if_utc - bias_minutes * 60) * 1000


func _today_event_id() -> String:
	var d: Dictionary = Time.get_date_dict_from_system(false)
	return "local_%04d%02d%02d" % [int(d.get("year", 1970)), int(d.get("month", 1)), int(d.get("day", 1))]


func _event_id_days_ago(days: int) -> String:
	var local: Dictionary = Time.get_date_dict_from_system(false)
	var as_if_utc: int = int(Time.get_unix_time_from_datetime_dict(local))
	var d: Dictionary = Time.get_datetime_dict_from_unix_time(as_if_utc - days * 86400)
	return "local_%04d%02d%02d" % [int(d.get("year", 1970)), int(d.get("month", 1)), int(d.get("day", 1))]






func claim_season_reward(event_id: String) -> bool:
	var claimed: bool = UserState.claim_rank_season_reward(event_id)
	if claimed:
		invalidate_snapshot()
	return claimed
