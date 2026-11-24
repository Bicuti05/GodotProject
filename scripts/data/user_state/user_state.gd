extends Node





signal audio_settings_changed()
signal help_center_badge_changed(visible: bool)

const SAVE_PATH: = "user://save.cfg"


const SAVE_PASSWORD: = "qd_x9K3mPv7RtN2sLwH8jFcZyA5eBkM1n"




func _resolve_save_path() -> String:
	if not OS.has_feature("editor"):
		return SAVE_PATH
	var project_hash: = ProjectSettings.globalize_path("res://").md5_text()
	return "user://save_%s.cfg" % project_hash


var _rank_unlocked: bool = false
var _rank_nickname: String = ""
var _rank_avatar_index: int = -1
var _rank_current_entity: Dictionary = {}
var _rank_clock_watermark: int = 0
var _rank_clock_saved: int = 0
var _rank_ever_played: bool = false
var _rank_avatar_dialog_ever_shown: bool = false
var _rank_disabled: bool = false

var _current_level: int = 1
var _outer_loop_pending_level: int = 0
var _hex_board_chapter: int = 0
var _hex_board_revealed: Array[int] = []

var _pending_level_completion: int = 0

var _pending_outer_loop_enabled: bool = true

var _pending_special_challenge_offer: bool = false
var _pending_timed_endless_offer: Dictionary = {}
var _timed_endless_state: Dictionary = {}

var _pending_iq_completion: Dictionary = {}

var _daily_checkin_state: Dictionary = {}
var _pending_daily_checkin_completion: Dictionary = {}

var _coin_bonus_state: Dictionary = {}

var _pending_coin_bonus_completion: Dictionary = {}

var _daily_challenge_day: String = ""
var _daily_challenge_elapsed_ms: int = 0
var _daily_challenge_percentile: float = 0.0
var _daily_challenge_sequence: int = 0
var _daily_challenge_assigned_day: String = ""
var _daily_challenge_assigned_date: String = ""

var _iq_rounds_since_guarantee: int = 4

var _completed_level_count: int = 0

var _interstitial_unlocked: bool = false
var _banner_unlocked: bool = false

var _ad_daily_completed_date: String = ""
var _ad_daily_completed_count: int = 0

var _pending_ad_completion_date: String = ""

var _review_request_sent: bool = false
var _tutorial_done: bool = false




var _mystery_guide_shown: bool = false

var _root_swap_guide_done: bool = false

var _root_swap_guide_shown: bool = false

var _root_swap_guide_pending: Dictionary = {}




var _lock_guide_shown: bool = false

var _sunlight_guide_shown: bool = false



var _effects_warmed: bool = false

var _rope_shader_warmed_key: String = ""
var _effect_warmup_records: Dictionary = {}


var _has_agreed_privacy: bool = false



var _push_ask_count: int = 0

var _current_strategy: int = 1

var _daily_completed_date: String = ""
var _prop_hint: int = 3



var _prop_undo: int = 3

var _prop_rope: int = 1

var _prop_fill_pot: int = 0

var _prop_reward_ads_count: Dictionary = {}


var _prop_unlock_shown: Dictionary = {}
var _prop_early_unlocked: Dictionary = {}


var _prop_free_available: Dictionary = {}
var _prop_free_granted: Dictionary = {}

var _prop_free_get_reported: Dictionary = {}



var _cliff_hint_granted: Dictionary = {}

var _last_splash_date: String = ""

var _music_enabled: bool = true
var _sfx_enabled: bool = true

var _haptic_enabled: bool = true


var _help_center_unread_count: int = 0


var _help_center_badge: bool = false



var _is_first_session: bool = true




var _first_install_date: String = ""


var _debug_install_days_override: int = -1



var _first_app_version: String = ""

var _session_num: int = 0


var _grt_new_install_anchors: Dictionary = {}

var _grt_sent_events: Dictionary = {}

var _grt_inter_show_count: int = 0

var _grt_reward_show_count: int = 0


var _coins: int = 0
var _special_challenge: Dictionary = {}
var _special_challenge_completed: int = 0
var _special_challenge_offer_after: int = 0

var _special_level2_next_slot: int = 0
var _special_level2_control_turns: int = 0
var _special_level2_new_turns: int = 0
var _special_level2_seeded: bool = false

var _special_theme_next_sequence: int = 0
var _special_theme_assignments: Dictionary = {}


var _moves_intro_shown: bool = false


var _sticker_tutorial_shown: bool = false



var _order_zoom_guide_shown: bool = false


var _wireframe_level_intro_shown: bool = false




var _recent_round_coefs: Array = []
const RECENT_ROUND_COEFS_LIMIT: = 2





enum RoundOutcome{WON, DIED, ABANDONED}





var _rounds_since_last_death: int = ROUNDS_SINCE_DEATH_NEVER

const DEATH_WINDOW_ROUNDS: = 5

const ROUNDS_SINCE_DEATH_NEVER: = 9999





var _win_streak_count: int = 0

var _finish_best_results: Dictionary = {}
var _finish_best_streak: int = 0
var _last_streak_record_count: int = 0



var _streak_word_shown: Dictionary = {}

var _hard_banner_shown: Dictionary = {}







var _current_level_dirty: bool = false


var _user_level: int = 0

var _user_level_reached_3: bool = false

var _user_level_reached_4: bool = false

var _user_level_clean_streak: int = 0


var _user_level_recent_dirty: Array = []



var _repeat_restart_level: int = 0
var _repeat_restart_count: int = 0



var _daily_round_date: String = ""
var _daily_round_count: int = 0


var _daily_downgrade_level: int = 0

var _daily_attempt_key: int = 0
var _daily_attempt_count: int = 0


var _has_restarted: bool = false





var _debug_proxy_host: String = ""
var _debug_proxy_port: int = -1


var _debug_ab_overrides: Dictionary = {}


var _mock_unikit_config: Dictionary = {}


var _debug_no_ads: bool = false


var _debug_mode: bool = false


var _current_level_retried: bool = false






var _first_session_runtime: bool = true



var _first_app_version_saved: bool = false

var _first_app_version_init_attempted: bool = false


var _first_app_version_init_allowed: bool = false
var _ads_legacy_migration_pending: bool = false


func _init() -> void :

	MainPackPath.register_absolute()


func _ready() -> void :
	var save_path: String = _resolve_save_path()
	var save_existed: bool = FileAccess.file_exists(save_path)
	var load_result: Error = _load_data()
	_first_session_runtime = _is_first_session


	_first_app_version_init_allowed = not save_existed and load_result == ERR_FILE_NOT_FOUND
	var install_date_missing: bool = _first_install_date.is_empty()
	if install_date_missing:

		_first_install_date = _today_str()
	if _first_app_version_init_allowed:

		initialize_first_app_version(String(ProjectSettings.get_setting("application/config/version", "")))
	elif install_date_missing or _ads_legacy_migration_pending:
		_save_data()



func get_current_level() -> int:
	return _current_level

func set_current_level(value: int) -> void :
	_current_level = value
	_save_data()


func get_outer_loop_pending_level() -> int:
	return _outer_loop_pending_level



func consume_outer_loop_pending_level() -> int:
	var level: int = _outer_loop_pending_level
	if level > 0:
		_outer_loop_pending_level = 0
		_save_data()
	return level


func get_hex_board_revealed(chapter: int) -> Array[int]:
	if chapter == _hex_board_chapter:
		return _hex_board_revealed.duplicate()
	var empty: Array[int] = []
	return empty


func commit_hex_board_revealed(chapter: int, revealed: Array) -> void :
	_hex_board_chapter = chapter
	_hex_board_revealed.clear()
	for value: Variant in revealed:
		var idx: int = int(value)
		if idx >= 0 and idx < LevelIndex.CHAPTER_SIZE and not _hex_board_revealed.has(idx):
			_hex_board_revealed.append(idx)
	_save_data()


func get_pending_level_completion() -> int:
	return _pending_level_completion


func get_completed_level_count() -> int:
	return _completed_level_count


func is_interstitial_unlocked() -> bool:
	return _interstitial_unlocked


func is_banner_unlocked() -> bool:
	return _banner_unlocked



func unlock_ads(interstitial_reached: bool, banner_reached: bool) -> bool:
	var previous_inter: bool = _interstitial_unlocked
	var previous_banner: bool = _banner_unlocked
	_interstitial_unlocked = _interstitial_unlocked or interstitial_reached
	_banner_unlocked = _banner_unlocked or banner_reached
	if previous_inter == _interstitial_unlocked and previous_banner == _banner_unlocked:
		return true
	if _save_data() != OK:
		_interstitial_unlocked = previous_inter
		_banner_unlocked = previous_banner
		return false
	return true



func get_daily_completed_level_count() -> int:
	return _ad_daily_completed_count if _ad_daily_completed_date == _today_str() else 0


func has_sent_review_request() -> bool:
	return _review_request_sent


func mark_review_request_sent() -> void :
	if _review_request_sent:
		return
	_review_request_sent = true
	_save_data()







func get_help_center_unread_count() -> int:
	return _help_center_unread_count


func set_help_center_unread_count(value: int) -> void :
	if _help_center_unread_count == value:
		return
	_help_center_unread_count = value
	_save_data()



func should_show_help_center_badge() -> bool:
	return _help_center_badge


func set_help_center_badge(visible: bool) -> void :
	if _help_center_badge == visible:
		return
	_help_center_badge = visible
	_save_data()
	help_center_badge_changed.emit(visible)



func get_iq_rounds_since_guarantee() -> int:
	return _iq_rounds_since_guarantee



func get_pending_iq_completion(level: int) -> Dictionary:
	return _pending_iq_completion.duplicate() if _pending_level_completion == level else {}



func get_pending_special_challenge_offer(level: int) -> bool:
	return _pending_level_completion == level and _pending_special_challenge_offer



func get_coin_bonus_state() -> Dictionary:
	return _coin_bonus_state.duplicate(true)

func get_coin_bonus_assignment(level: int) -> Dictionary:
	var assignment: Dictionary = _coin_bonus_state.get("last_assignment", {}) as Dictionary
	return assignment.duplicate(true) if int(assignment.get("level", 0)) == level else {}


func commit_coin_bonus_assignment(assignment: Dictionary) -> bool:
	if int(assignment.get("level", 0)) <= 0:
		return false
	if not get_coin_bonus_assignment(int(assignment.level)).is_empty():
		return true
	var previous: Dictionary = _coin_bonus_state
	_coin_bonus_state = CoinBonusLevelRules.enter(_coin_bonus_state, assignment)
	if _save_data() != OK:
		_coin_bonus_state = previous
		return false
	return true

func get_pending_coin_bonus_completion(level: int) -> Dictionary:
	return _pending_coin_bonus_completion.duplicate(true) if _pending_level_completion == level else {}

func get_daily_checkin_state() -> Dictionary:
	return _daily_checkin_state.duplicate(true)

func get_pending_daily_checkin_completion(level: int, special: bool) -> Dictionary:
	if special:
		return (_special_challenge.get("daily_checkin_completion", {}) as Dictionary).duplicate(true)
	return _pending_daily_checkin_completion.duplicate(true) if _pending_level_completion == level else {}


func _apply_daily_checkin_completion(completion: Dictionary) -> void :
	if completion.is_empty() or int(completion.get("date_serial", 0)) <= int(_daily_checkin_state.get("last_win_serial", 0)):
		return
	_coins += maxi(int(completion.get("reward_coins", 0)), 0)
	_daily_checkin_state = (completion["state"] as Dictionary).duplicate(true)



func begin_level_completion(level: int, iq_completion: Dictionary = {}, outer_loop_enabled: bool = true, 
		special_schedule: Dictionary = {}, daily_checkin_completion: Dictionary = {}, 
		coin_bonus_completion: Dictionary = {}, timed_endless_offer: Dictionary = {}) -> bool:
	if level <= 0:
		return false
	if _pending_level_completion == level:
		return true
	if not coin_bonus_completion.is_empty() and (level < _current_level\
	or level <= int(_coin_bonus_state.get("last_claimed_level", 0))):
		return false
	var previous_coin_bonus: Dictionary = _coin_bonus_state
	var previous_coin_pending: Dictionary = _pending_coin_bonus_completion
	var previous_coins: int = _coins
	_pending_coin_bonus_completion = coin_bonus_completion.duplicate(true)
	if not coin_bonus_completion.is_empty():
		_coins += maxi(0, int(coin_bonus_completion.get("coins", 0)))\
		+ maxi(0, int(coin_bonus_completion.get("bonus_coins", 0)))
		_coin_bonus_state = CoinBonusLevelRules.complete(_coin_bonus_state, 
			coin_bonus_completion.get("assignment", {}) as Dictionary, level, 
			int(coin_bonus_completion.get("coins", 0)) > 0)
	var previous_checkin: Dictionary = _pending_daily_checkin_completion
	var previous_level: int = _pending_level_completion
	var previous_ad_date: String = _pending_ad_completion_date
	var previous_iq: Dictionary = _pending_iq_completion
	var previous_outer_loop: bool = _pending_outer_loop_enabled
	var previous_special_offer: bool = _pending_special_challenge_offer
	var previous_timed_offer: Dictionary = _pending_timed_endless_offer
	_pending_timed_endless_offer = timed_endless_offer.duplicate(true)
	_pending_level_completion = level
	_pending_ad_completion_date = _today_str()
	_pending_daily_checkin_completion = daily_checkin_completion.duplicate(true)
	_pending_iq_completion = iq_completion.duplicate()
	_pending_outer_loop_enabled = outer_loop_enabled
	_pending_special_challenge_offer = SpecialChallengeRules.is_anchor(level, 
		int(special_schedule.get("first_anchor", SpecialChallengeRules.FIRST_ANCHOR)), 
		int(special_schedule.get("interval", SpecialChallengeRules.INTERVAL)))\
		and not bool(_pending_timed_endless_offer.get("enabled", false))
	if _save_data() != OK:
		_coin_bonus_state = previous_coin_bonus
		_pending_coin_bonus_completion = previous_coin_pending
		_coins = previous_coins
		_pending_daily_checkin_completion = previous_checkin
		_pending_level_completion = previous_level
		_pending_ad_completion_date = previous_ad_date
		_pending_iq_completion = previous_iq
		_pending_outer_loop_enabled = previous_outer_loop
		_pending_special_challenge_offer = previous_special_offer
		_pending_timed_endless_offer = previous_timed_offer
		return false
	return true




func finalize_level_completion(level: int) -> bool:
	if level <= 0 or _pending_level_completion != level:
		return false
	var previous: Array[int] = [_current_level, _completed_level_count, _outer_loop_pending_level, _special_challenge_offer_after]
	var previous_ad_date: String = _ad_daily_completed_date
	var previous_ad_count: int = _ad_daily_completed_count
	var previous_timed_state: Dictionary = _timed_endless_state.duplicate(true)
	var previous_timed_offer: Dictionary = _pending_timed_endless_offer
	var previous_pending_ad_date: String = _pending_ad_completion_date
	var previous_checkin: Dictionary = _pending_daily_checkin_completion
	var previous_checkin_state: Dictionary = _daily_checkin_state
	var previous_coins: int = _coins
	var previous_coin_pending: Dictionary = _pending_coin_bonus_completion
	_apply_daily_checkin_completion(_pending_daily_checkin_completion)
	_pending_daily_checkin_completion = {}
	var previous_iq: Dictionary = _pending_iq_completion
	var previous_interval: int = _iq_rounds_since_guarantee
	var previous_outer_loop: bool = _pending_outer_loop_enabled
	var previous_special_offer: bool = _pending_special_challenge_offer
	_current_level = maxi(_current_level, level + 1)
	_completed_level_count += 1
	var completed_date: String = _pending_ad_completion_date if not _pending_ad_completion_date.is_empty() else _today_str()

	if completed_date >= _ad_daily_completed_date:
		if completed_date != _ad_daily_completed_date:
			_ad_daily_completed_date = completed_date
			_ad_daily_completed_count = 0
		_ad_daily_completed_count += 1
	_pending_ad_completion_date = ""
	_outer_loop_pending_level = level if _pending_outer_loop_enabled else 0
	if _pending_special_challenge_offer:
		_special_challenge_offer_after = level
	var participated: bool = bool(_pending_iq_completion.get("participated", false))
	if participated and bool(_pending_iq_completion.get("guarantee_triggered", false)):
		_iq_rounds_since_guarantee = 0
	elif bool(_pending_iq_completion.get("mainline", participated)):
		_iq_rounds_since_guarantee = mini(4, _iq_rounds_since_guarantee + 1)
	var timed_anchor: int = int(_pending_timed_endless_offer.get("after_level", 0))
	if timed_anchor == level and timed_anchor > get_timed_endless_last_anchor():
		_timed_endless_state["last_anchor"] = timed_anchor
		if bool(_pending_timed_endless_offer.get("enabled", false)):
			_timed_endless_state["offer"] = {"instance_id": "timed_endless:%d" % timed_anchor, 
				"after_level": timed_anchor, "status": "offered", "cups": 0}
			if _special_challenge_offer_after == timed_anchor:
				_special_challenge_offer_after = 0
	_pending_timed_endless_offer = {}
	_pending_level_completion = 0
	_pending_coin_bonus_completion = {}
	_pending_iq_completion = {}
	_pending_outer_loop_enabled = true
	_pending_special_challenge_offer = false
	if _save_data() != OK:
		_pending_coin_bonus_completion = previous_coin_pending
		_pending_daily_checkin_completion = previous_checkin
		_daily_checkin_state = previous_checkin_state
		_coins = previous_coins
		_current_level = previous[0]
		_completed_level_count = previous[1]
		_ad_daily_completed_date = previous_ad_date
		_ad_daily_completed_count = previous_ad_count
		_pending_ad_completion_date = previous_pending_ad_date
		_outer_loop_pending_level = previous[2]
		_special_challenge_offer_after = previous[3]
		_pending_level_completion = level
		_timed_endless_state = previous_timed_state
		_pending_timed_endless_offer = previous_timed_offer
		_pending_iq_completion = previous_iq
		_pending_outer_loop_enabled = previous_outer_loop
		_pending_special_challenge_offer = previous_special_offer
		_iq_rounds_since_guarantee = previous_interval
		return false
	return true








func recover_pending_level_completion() -> bool:
	var level: int = get_pending_level_completion()
	if level <= 0:
		return true
	if not LevelManager.mark_pending_completed(level, {}, "recover_win", LevelManager.get_game_id(level)):
		SortLogger.error("UserState: pending 通关恢复写 SQLite 失败 lv=%d" % level)
		return false
	if not finalize_level_completion(level):
		SortLogger.error("UserState: pending 通关恢复 finalize 失败 lv=%d" % level)
		return false
	SortLogger.mark("UserState: pending 通关已恢复 lv=%d" % level)
	return true

func is_tutorial_done() -> bool:
	return _tutorial_done

func set_tutorial_done(value: bool) -> void :
	_tutorial_done = value
	_save_data()


func is_mystery_guide_shown() -> bool:
	return _mystery_guide_shown



func is_root_swap_guide_done() -> bool:
	return _root_swap_guide_done



func mark_root_swap_guide_done() -> void :
	if _root_swap_guide_done:
		return
	_root_swap_guide_done = true
	if _save_data() != OK:
		_root_swap_guide_done = false


func is_root_swap_guide_shown() -> bool:
	return _root_swap_guide_shown


func mark_root_swap_guide_shown() -> void :
	if _root_swap_guide_shown and _root_swap_guide_pending.is_empty():
		return
	var previous_shown: bool = _root_swap_guide_shown
	var previous_pending: Dictionary = _root_swap_guide_pending.duplicate(true)
	_root_swap_guide_shown = true
	_root_swap_guide_pending = {}
	if _save_data() != OK:
		_root_swap_guide_shown = previous_shown
		_root_swap_guide_pending = previous_pending


func get_root_swap_guide_pending() -> Dictionary:
	return _root_swap_guide_pending.duplicate(true)


func set_root_swap_guide_pending(value: Dictionary) -> bool:
	if _root_swap_guide_pending == value:
		return true
	var previous_pending: Dictionary = _root_swap_guide_pending.duplicate(true)
	_root_swap_guide_pending = value.duplicate(true)
	if _save_data() != OK:
		_root_swap_guide_pending = previous_pending
		return false
	return true



func discard_root_swap_guide_pending() -> void :
	if _root_swap_guide_pending.is_empty():
		return
	_root_swap_guide_pending = {}
	_save_data()


func set_mystery_guide_shown(value: bool) -> void :
	_mystery_guide_shown = value
	_save_data()


func is_lock_guide_shown() -> bool:
	return _lock_guide_shown


func is_sunlight_guide_shown() -> bool:
	return _sunlight_guide_shown


func set_sunlight_guide_shown(value: bool) -> void :
	_sunlight_guide_shown = value
	_save_data()


func set_lock_guide_shown(value: bool) -> void :
	_lock_guide_shown = value
	_save_data()


func is_effects_warmed() -> bool:
	return _effects_warmed


func get_rope_shader_warmed_key() -> String:
	return _rope_shader_warmed_key




func mark_effects_warmed(rope_shader_key: String = "") -> void :
	if _effects_warmed and (rope_shader_key.is_empty() or rope_shader_key == _rope_shader_warmed_key):
		return
	var previous_warmed: bool = _effects_warmed
	var previous_key: String = _rope_shader_warmed_key
	_effects_warmed = true
	if not rope_shader_key.is_empty():
		_rope_shader_warmed_key = rope_shader_key

	if _save_data() != OK:
		_effects_warmed = previous_warmed
		_rope_shader_warmed_key = previous_key


func is_music_enabled() -> bool:
	return _music_enabled


func set_music_enabled(value: bool) -> void :
	if _music_enabled == value:
		return
	_music_enabled = value
	_save_data()
	audio_settings_changed.emit()


func is_sfx_enabled() -> bool:
	return _sfx_enabled


func set_sfx_enabled(value: bool) -> void :
	if _sfx_enabled == value:
		return
	_sfx_enabled = value
	_save_data()
	audio_settings_changed.emit()


func is_haptic_enabled() -> bool:
	return _haptic_enabled


func set_haptic_enabled(value: bool) -> void :
	if _haptic_enabled == value:
		return
	_haptic_enabled = value
	_save_data()





func has_died_within_recent_rounds() -> bool:
	return _rounds_since_last_death < DEATH_WINDOW_ROUNDS




func cheat_set_rounds_since_death(n: int) -> void :
	_rounds_since_last_death = clampi(n, 0, ROUNDS_SINCE_DEATH_NEVER)
	_save_data()


func get_recent_round_coefs() -> Array:
	return _recent_round_coefs.duplicate()




func cheat_set_last_round_coef(coef: float) -> void :
	if _recent_round_coefs.is_empty():
		_recent_round_coefs.append(coef)
	else:
		_recent_round_coefs[-1] = coef
	_save_data()








func get_win_streak_count() -> int:
	return _win_streak_count


func is_current_streak_record(count: int) -> bool:
	return count > 0 and count == _win_streak_count and count == _last_streak_record_count




func on_win_streak_won(target_flower_count: int, elapsed_ms: int, move_attempt_count: int) -> Dictionary:
	_win_streak_count += 1

	var key: String = "target_flowers:%d" % target_flower_count
	var previous: Dictionary = _finish_best_results.get(key, {})
	var improved: Dictionary = {
		"time": previous.has("elapsed_ms") and elapsed_ms < int(previous["elapsed_ms"]), 
		"step": previous.has("move_attempt_count") and move_attempt_count < int(previous["move_attempt_count"]), 
		"streak": _finish_best_streak > 0 and _win_streak_count > _finish_best_streak, 
	}
	_finish_best_results[key] = {
		"elapsed_ms": mini(elapsed_ms, int(previous.get("elapsed_ms", elapsed_ms))), 
		"move_attempt_count": mini(move_attempt_count, int(previous.get("move_attempt_count", move_attempt_count))), 
	}
	_last_streak_record_count = _win_streak_count if bool(improved["streak"]) else 0
	_finish_best_streak = maxi(_finish_best_streak, _win_streak_count)
	_save_data()
	return improved



func reset_win_streak() -> void :
	if _win_streak_count == 0:
		return
	_win_streak_count = 0
	_last_streak_record_count = 0
	_save_data()


func is_streak_word_shown(level_key: String) -> bool:
	return _streak_word_shown.get(level_key, false)


func mark_streak_word_shown(level_key: String) -> void :
	if level_key.is_empty() or _streak_word_shown.get(level_key, false):
		return
	_streak_word_shown[level_key] = true
	_save_data()


func is_hard_banner_shown(level_key: String) -> bool:
	return _hard_banner_shown.get(level_key, false)


func mark_hard_banner_shown(level_key: String) -> void :
	if level_key.is_empty() or _hard_banner_shown.get(level_key, false):
		return
	_hard_banner_shown[level_key] = true
	_save_data()



func cheat_set_win_streak(count: int) -> void :
	_win_streak_count = maxi(count, 0)
	_last_streak_record_count = 0
	_save_data()


func clear_streak_word_state() -> void :
	_streak_word_shown.clear()
	_win_streak_count = 0
	_last_streak_record_count = 0
	_save_data()











func get_install_days() -> int:
	if _debug_install_days_override >= 0:
		return _debug_install_days_override
	if _first_install_date.is_empty():
		return 0
	var today: String = _today_str()
	var t_install: int = int(Time.get_unix_time_from_datetime_string(_first_install_date + "T00:00:00"))
	var t_today: int = int(Time.get_unix_time_from_datetime_string(today + "T00:00:00"))
	if t_today < t_install:
		return 0
	return int((t_today - t_install) / 86400)




func has_agreed_privacy() -> bool:
	return _has_agreed_privacy


func set_agreed_privacy() -> void :
	if _has_agreed_privacy:
		return
	_has_agreed_privacy = true
	_save_data()



func get_push_ask_count() -> int:
	return _push_ask_count


func inc_push_ask_count() -> void :
	_push_ask_count += 1
	_save_data()



func reset_moves_intro_shown() -> void :
	if not _moves_intro_shown:
		return
	_moves_intro_shown = false
	_save_data()



func reset_mystery_guide_shown() -> void :
	if not _mystery_guide_shown:
		return
	_mystery_guide_shown = false
	_save_data()



func reset_lock_guide_shown() -> void :
	if not _lock_guide_shown:
		return
	_lock_guide_shown = false
	_save_data()



func reset_sticker_tutorial_shown() -> void :
	if not _sticker_tutorial_shown:
		return
	_sticker_tutorial_shown = false
	_save_data()



func reset_order_zoom_guide_shown() -> void :
	if not _order_zoom_guide_shown:
		return
	_order_zoom_guide_shown = false
	_save_data()



func reset_wireframe_level_intro_shown() -> void :
	if not _wireframe_level_intro_shown:
		return
	_wireframe_level_intro_shown = false
	_save_data()

func get_current_strategy() -> int:
	return _current_strategy


func get_daily_completed_date() -> String:
	return _daily_completed_date


func get_prop_count(kind: String) -> int:
	match kind:
		"hint": return _prop_hint
		"undo": return _prop_undo
		"rope": return _prop_rope
		"fill_pot": return _prop_fill_pot
		_: return 0


func get_prop_reward_ads_count(kind: String) -> int:
	return mini(maxi(int(_prop_reward_ads_count.get(kind, 0)), 0), get_prop_count(kind))


func get_session_num() -> int:
	return _session_num

func inc_session_num() -> void :
	_session_num += 1
	_save_data()




func get_first_app_version() -> String:
	if not _first_app_version_saved:
		return ""
	return _first_app_version





func initialize_first_app_version(version: String) -> void :
	if _first_app_version_init_attempted or not _first_app_version_init_allowed:
		return
	_first_app_version_init_attempted = true
	if not _is_valid_version(version):
		return
	_first_app_version = version

	_save_data()



func _is_valid_version(version: String) -> bool:
	return GrtEventDefinition.anchor_for_version(version, "0") != GrtEventDefinition.ANCHOR_UNSET



func get_grt_new_install_anchor(batch_id: String) -> int:
	return int(_grt_new_install_anchors.get(batch_id, 0))



func set_grt_new_install_anchor(batch_id: String, anchor: int) -> bool:
	if int(_grt_new_install_anchors.get(batch_id, 0)) == anchor:
		return true
	var previous: Dictionary = _grt_new_install_anchors.duplicate()
	_grt_new_install_anchors[batch_id] = anchor
	if _save_data() != OK:
		_grt_new_install_anchors = previous
		return false
	return true


func get_grt_new_install_anchors() -> Dictionary:
	return _grt_new_install_anchors.duplicate()



func get_grt_sent_events() -> Dictionary:
	return _grt_sent_events.duplicate()


func is_grt_event_sent(batch_id: String, event_name: String) -> bool:
	return _grt_sent_events.has(batch_id + ":" + event_name)



func mark_grt_events_sent(keys: Array[String]) -> void :
	if keys.is_empty():
		return
	var changed: bool = false
	for key in keys:
		if not _grt_sent_events.has(key):
			_grt_sent_events[key] = true
			changed = true
	if changed:
		_save_data()


func get_grt_inter_show_count() -> int:
	return _grt_inter_show_count


func get_grt_reward_show_count() -> int:
	return _grt_reward_show_count



func record_grt_ad_show(is_reward: bool) -> void :
	if is_reward:
		_grt_reward_show_count += 1
	else:
		_grt_inter_show_count += 1
	_save_data()



func cheat_set_grt_show_counts(inter_count: int, reward_count: int) -> void :
	_grt_inter_show_count = maxi(0, inter_count)
	_grt_reward_show_count = maxi(0, reward_count)
	_save_data()



func cheat_clear_grt_state() -> void :
	_grt_new_install_anchors.clear()
	_grt_sent_events.clear()
	_grt_inter_show_count = 0
	_grt_reward_show_count = 0
	_save_data()



func get_coins() -> int:
	return _coins


func add_coins(amount: int) -> void :
	_coins = maxi(_coins + amount, 0)
	_save_data()


func spend_coins(amount: int) -> bool:
	if _coins < amount:
		return false
	_coins -= amount
	_save_data()
	return true


func set_coins(value: int) -> void :
	_coins = maxi(value, 0)
	_save_data()




func set_prop_count(kind: String, count: int) -> void :
	match kind:
		"hint": _prop_hint = count
		"undo": _prop_undo = count
		"rope": _prop_rope = count
		"fill_pot": _prop_fill_pot = count
		_: return

	_prop_reward_ads_count[kind] = mini(get_prop_reward_ads_count(kind), maxi(count, 0))
	_save_data()



func add_prop_reward_ads(kind: String, amount: int) -> void :
	if amount <= 0 or (kind != "hint" and kind != "undo" and kind != "rope"
			and kind != "fill_pot"):
		return
	var ads_count: int = get_prop_reward_ads_count(kind)
	match kind:
		"hint": _prop_hint += amount
		"undo": _prop_undo += amount
		"rope": _prop_rope += amount
		"fill_pot": _prop_fill_pot += amount
	_prop_reward_ads_count[kind] = ads_count + amount
	_save_data()



func consume_prop_stock(kind: String) -> Dictionary:
	var count: int = get_prop_count(kind)
	if count <= 0 or (kind != "hint" and kind != "undo" and kind != "rope"
			and kind != "fill_pot"):
		return {}
	var ads_count: int = get_prop_reward_ads_count(kind)
	var from_reward_ads: bool = count <= ads_count
	match kind:
		"hint": _prop_hint -= 1
		"undo": _prop_undo -= 1
		"rope": _prop_rope -= 1
		"fill_pot": _prop_fill_pot -= 1
	if from_reward_ads:
		_prop_reward_ads_count[kind] = ads_count - 1
	_save_data()
	return {"from_reward_ads": from_reward_ads, "left": count - 1}



func is_prop_early_unlocked(prop_id: String) -> bool:
	return bool(_prop_early_unlocked.get(prop_id, false))


func is_prop_unlock_shown(prop_id: String) -> bool:
	return bool(_prop_unlock_shown.get(prop_id, false))



func mark_prop_unlock_shown(prop_id: String) -> void :
	if _prop_unlock_shown.get(prop_id, false):
		return
	_prop_unlock_shown[prop_id] = true
	_save_data()


func clear_prop_unlock_shown() -> void :
	if _prop_early_unlocked.is_empty() and _prop_unlock_shown.is_empty() and _prop_free_available.is_empty()\
	and _prop_free_granted.is_empty() and _prop_free_get_reported.is_empty():
		return
	_prop_early_unlocked.clear()
	_prop_unlock_shown.clear()
	_prop_free_available.clear()
	_prop_free_granted.clear()
	_prop_free_get_reported.clear()
	_save_data()


func is_prop_free_available(prop_id: String) -> bool:
	return bool(_prop_free_available.get(prop_id, false))


func is_prop_free_get_reported(prop_id: String) -> bool:
	return bool(_prop_free_get_reported.get(prop_id, false))


func mark_prop_free_get_reported(prop_id: String) -> void :
	if bool(_prop_free_get_reported.get(prop_id, false)):
		return
	_prop_free_get_reported[prop_id] = true
	_save_data()



func grant_prop_free_use(prop_id: String) -> void :
	var prop_ids: Array[String] = [prop_id]
	grant_prop_free_uses(prop_ids)



func grant_prop_free_uses(prop_ids: Array[String]) -> Array[String]:
	var granted: Array[String] = []
	for prop_id: String in prop_ids:
		if bool(_prop_free_granted.get(prop_id, false)):
			continue
		_prop_free_granted[prop_id] = true
		_prop_free_available[prop_id] = true
		granted.append(prop_id)
	if not granted.is_empty():
		_save_data()
	return granted


func consume_prop_free_use(prop_id: String) -> void :
	if not bool(_prop_free_available.get(prop_id, false)):
		return
	_prop_free_available[prop_id] = false
	_save_data()



func clear_cliff_hint_granted() -> void :
	if _cliff_hint_granted.is_empty():
		return
	_cliff_hint_granted.clear()
	_save_data()


func get_last_splash_date() -> String:
	return _last_splash_date


func set_last_splash_date(value: String) -> void :
	_last_splash_date = value
	_save_data()

func is_first_session() -> bool:
	return _first_session_runtime











func consume_first_session() -> void :
	if not _is_first_session:
		return
	_is_first_session = false
	_save_data()






func is_debug_mode() -> bool:
	return _debug_mode or not OS.has_feature("rel")


func is_current_level_dirty() -> bool:
	return _current_level_dirty




func mark_current_level_dirty() -> void :
	if _current_level_dirty:
		return
	_current_level_dirty = true
	_save_data()



func has_restarted() -> bool:
	return _has_restarted



func mark_restarted() -> void :
	if _has_restarted:
		return
	_has_restarted = true
	_save_data()



func get_repeat_restart_count(level_id: int) -> int:
	return _repeat_restart_count if _repeat_restart_level == level_id else 0




func inc_repeat_restart(level_id: int) -> int:
	if _repeat_restart_level != level_id:
		_repeat_restart_level = level_id
		_repeat_restart_count = 0
	_repeat_restart_count += 1
	_save_data()
	return _repeat_restart_count




func inc_daily_round_count() -> int:
	var today: String = _today_str()
	if _daily_round_date != today:
		_daily_round_date = today
		_daily_round_count = 0
	_daily_round_count += 1
	_save_data()
	return _daily_round_count



func cheat_reset_daily_round_count() -> void :
	_daily_round_date = _today_str()
	_daily_round_count = 0
	_save_data()




func set_daily_downgrade_level(level_id: int) -> void :
	if _daily_downgrade_level == level_id:
		return
	_daily_downgrade_level = level_id
	_save_data()


func is_daily_downgrade_level(level_id: int) -> bool:
	return _daily_downgrade_level != 0 and _daily_downgrade_level == level_id





func settle_downgraded_level_win() -> void :
	_current_level_dirty = false
	_daily_downgrade_level = 0
	_save_data()


func is_current_level_retried() -> bool:
	return _current_level_retried




func get_user_level() -> int:
	return _user_level


func get_user_level_clean_streak() -> int:
	return _user_level_clean_streak


func has_reached_user_level_4() -> bool:
	return _user_level_reached_4


func has_reached_user_level_3() -> bool:
	return _user_level_reached_3



func get_user_level_recent_dirty() -> Array:
	return _user_level_recent_dirty.duplicate()





func settle_user_level(level: int, clean_streak: int, recent_dirty: Array) -> void :
	_user_level = level
	_user_level_reached_3 = _user_level_reached_3 or _user_level >= 3
	_user_level_reached_4 = _user_level_reached_4 or _user_level >= 4
	_user_level_clean_streak = clean_streak
	_user_level_recent_dirty = recent_dirty.duplicate()
	_current_level_dirty = false
	_daily_downgrade_level = 0
	_save_data()




func cheat_set_user_level(level: int) -> void :
	_user_level = clampi(level, 0, UserLevelLadder.LEVEL_MAX)
	_user_level_reached_3 = _user_level_reached_3 or _user_level >= 3
	_user_level_reached_4 = _user_level_reached_4 or _user_level >= 4
	_user_level_clean_streak = 0
	_user_level_recent_dirty = []
	_save_data()





func get_debug_proxy_host() -> String:
	return _debug_proxy_host

func get_debug_proxy_port() -> int:
	return _debug_proxy_port

func has_debug_proxy() -> bool:
	return _debug_proxy_host != "" and _debug_proxy_port > 0

func set_debug_proxy(host: String, port: int) -> void :
	if OS.has_feature("rel"):
		return
	_debug_proxy_host = host
	_debug_proxy_port = port
	_save_data()

func clear_debug_proxy() -> void :
	_debug_proxy_host = ""
	_debug_proxy_port = -1
	_save_data()




func get_debug_ab_override(key: String) -> int:
	return int(_debug_ab_overrides.get(key, -1))

func set_debug_ab_override(key: String, value: int) -> void :
	if OS.has_feature("rel"):
		return
	_debug_ab_overrides[key] = value
	_save_data()

func clear_debug_ab_override(key: String) -> void :
	if not _debug_ab_overrides.has(key):
		return
	_debug_ab_overrides.erase(key)
	_save_data()




func get_mock_unikit_value(key: String, default: Variant) -> Variant:
	return _mock_unikit_config.get(key, default)

func set_mock_unikit_value(key: String, value: Variant) -> void :
	if OS.has_feature("rel"):
		return
	_mock_unikit_config[key] = value
	_save_data()




func is_debug_no_ads() -> bool:
	return _debug_no_ads and not OS.has_feature("rel")

func set_debug_no_ads(v: bool) -> void :
	if OS.has_feature("rel"):
		return
	_debug_no_ads = v
	_save_data()




func set_debug_install_days(days: int) -> void :
	if OS.has_feature("rel"):
		return
	_debug_install_days_override = maxi(-1, days)






func cheat_jump_to_level(level: int) -> void :
	level = max(1, level)
	var max_strategy: int
	if level <= 5:
		max_strategy = 1
	elif level <= 20:
		max_strategy = 2
	elif level <= 50:
		max_strategy = 3
	elif level <= 100:
		max_strategy = 4
	elif level <= 200:
		max_strategy = 5
	else:
		max_strategy = 6
	var min_strategy: int
	if level <= 5: min_strategy = 1
	elif level <= 50: min_strategy = 1
	else: min_strategy = 2
	_current_strategy = clampi(_current_strategy, min_strategy, max_strategy)


	if OS.has_feature("editor") and not OS.has_feature("rel")\
	and level <= int(_coin_bonus_state.get("last_claimed_level", 0)):
		_coin_bonus_state = _coin_bonus_state.duplicate(true)
		_coin_bonus_state["last_claimed_level"] = level - 1
	_current_level = level
	_current_level_retried = false
	_current_level_dirty = false
	_save_data()



func _save_data() -> Error:
	var cfg: = ConfigFile.new()
	cfg.set_value("progress", "rank_unlocked", _rank_unlocked)
	cfg.set_value("progress", "rank_nickname", _rank_nickname)
	cfg.set_value("progress", "rank_avatar_index", _rank_avatar_index)
	cfg.set_value("progress", "rank_current_entity", _rank_current_entity)
	cfg.set_value("progress", "rank_clock_watermark", _rank_clock_watermark)
	cfg.set_value("progress", "rank_ever_played", _rank_ever_played)
	cfg.set_value("progress", "rank_avatar_dialog_ever_shown", _rank_avatar_dialog_ever_shown)
	cfg.set_value("progress", "rank_disabled", _rank_disabled)
	cfg.set_value("special_challenge", "active", _special_challenge)
	cfg.set_value("special_challenge", "completed", _special_challenge_completed)
	cfg.set_value("special_challenge", "offer_after", _special_challenge_offer_after)
	cfg.set_value("special_challenge", "level2_next_slot", _special_level2_next_slot)
	cfg.set_value("special_challenge", "level2_control_turns", _special_level2_control_turns)
	cfg.set_value("special_challenge", "level2_new_turns", _special_level2_new_turns)
	cfg.set_value("special_challenge", "level2_seeded", _special_level2_seeded)
	cfg.set_value("special_theme", "next_sequence", _special_theme_next_sequence)
	cfg.set_value("special_theme", "assignments", _special_theme_assignments)
	cfg.set_value("progress", "outer_loop_pending_level", _outer_loop_pending_level)
	cfg.set_value("progress", "hex_board_chapter", _hex_board_chapter)
	cfg.set_value("progress", "hex_board_revealed", _hex_board_revealed)
	cfg.set_value("progress", "current_level", _current_level)
	cfg.set_value("progress", "pending_level_completion", _pending_level_completion)
	cfg.set_value("progress", "pending_outer_loop_enabled", _pending_outer_loop_enabled)
	cfg.set_value("timed_endless", "state", _timed_endless_state)
	cfg.set_value("progress", "pending_timed_endless_offer", _pending_timed_endless_offer)
	cfg.set_value("progress", "pending_special_challenge_offer", _pending_special_challenge_offer)
	cfg.set_value("progress", "pending_iq_completion", _pending_iq_completion)
	cfg.set_value("daily_checkin", "state", _daily_checkin_state)
	cfg.set_value("daily_checkin", "pending_completion", _pending_daily_checkin_completion)
	cfg.set_value("coin_bonus_level", "state", _coin_bonus_state)
	cfg.set_value("coin_bonus_level", "pending_completion", _pending_coin_bonus_completion)
	cfg.set_value("daily_challenge", "day", _daily_challenge_day)
	cfg.set_value("daily_challenge", "elapsed_ms", _daily_challenge_elapsed_ms)
	cfg.set_value("daily_challenge", "percentile", _daily_challenge_percentile)
	cfg.set_value("daily_challenge", "sequence", _daily_challenge_sequence)
	cfg.set_value("daily_challenge", "assigned_day", _daily_challenge_assigned_day)
	cfg.set_value("daily_challenge", "assigned_date", _daily_challenge_assigned_date)
	cfg.set_value("progress", "iq_rounds_since_guarantee", _iq_rounds_since_guarantee)
	cfg.set_value("progress", "completed_level_count", _completed_level_count)
	cfg.set_value("ads", "interstitial_unlocked", _interstitial_unlocked)
	cfg.set_value("ads", "banner_unlocked", _banner_unlocked)
	cfg.set_value("ads", "daily_completed_date", _ad_daily_completed_date)
	cfg.set_value("ads", "daily_completed_count", _ad_daily_completed_count)
	cfg.set_value("ads", "pending_completion_date", _pending_ad_completion_date)
	cfg.set_value("progress", "review_request_sent", _review_request_sent)
	cfg.set_value("progress", "tutorial_done", _tutorial_done)
	cfg.set_value("progress", "current_strategy", _current_strategy)
	cfg.set_value("progress", "has_agreed_privacy", _has_agreed_privacy)
	cfg.set_value("progress", "push_ask_count", _push_ask_count)
	cfg.set_value("progress", "daily_completed_date", _daily_completed_date)
	cfg.set_value("progress", "prop_hint", _prop_hint)
	cfg.set_value("progress", "prop_undo", _prop_undo)
	cfg.set_value("progress", "prop_extra_rope", _prop_rope)
	cfg.set_value("progress", "prop_fill_pot", _prop_fill_pot)
	cfg.set_value("progress", "prop_reward_ads_count", _prop_reward_ads_count)
	cfg.set_value("progress", "prop_unlock_shown", _prop_unlock_shown)
	cfg.set_value("progress", "prop_early_unlocked", _prop_early_unlocked)
	cfg.set_value("progress", "prop_free_available", _prop_free_available)
	cfg.set_value("progress", "prop_free_granted", _prop_free_granted)
	cfg.set_value("progress", "prop_free_get_reported", _prop_free_get_reported)
	cfg.set_value("progress", "cliff_hint_granted", _cliff_hint_granted)
	cfg.set_value("progress", "last_splash_date", _last_splash_date)
	cfg.set_value("settings", "music_enabled", _music_enabled)
	cfg.set_value("settings", "sfx_enabled", _sfx_enabled)
	cfg.set_value("settings", "haptic_enabled", _haptic_enabled)
	cfg.set_value("help_center", "unread_count", _help_center_unread_count)
	cfg.set_value("help_center", "badge", _help_center_badge)
	cfg.set_value("progress", "is_first_session", _is_first_session)
	cfg.set_value("progress", "session_num", _session_num)
	cfg.set_value("progress", "grt_new_install_anchors", _grt_new_install_anchors)
	cfg.set_value("progress", "grt_sent_events", _grt_sent_events)
	cfg.set_value("progress", "grt_inter_show_count", _grt_inter_show_count)
	cfg.set_value("progress", "grt_reward_show_count", _grt_reward_show_count)
	cfg.set_value("progress", "coins", _coins)
	cfg.set_value("progress", "moves_intro_shown", _moves_intro_shown)
	cfg.set_value("progress", "mystery_guide_shown", _mystery_guide_shown)
	cfg.set_value("progress", "root_swap_guide_done", _root_swap_guide_done)
	cfg.set_value("progress", "root_swap_guide_shown", _root_swap_guide_shown)
	cfg.set_value("progress", "root_swap_guide_pending", _root_swap_guide_pending)
	cfg.set_value("progress", "lock_guide_shown", _lock_guide_shown)
	cfg.set_value("progress", "sunlight_guide_shown", _sunlight_guide_shown)
	cfg.set_value("progress", "effect_warmup_records", _effect_warmup_records)
	cfg.set_value("progress", "effects_warmed", _effects_warmed)
	cfg.set_value("progress", "rope_shader_warmed_key", _rope_shader_warmed_key)
	cfg.set_value("progress", "sticker_tutorial_shown", _sticker_tutorial_shown)
	cfg.set_value("progress", "order_zoom_guide_shown", _order_zoom_guide_shown)
	cfg.set_value("progress", "wireframe_level_intro_shown", _wireframe_level_intro_shown)
	cfg.set_value("progress", "first_install_date", _first_install_date)
	cfg.set_value("progress", "first_app_version", _first_app_version)
	cfg.set_value("progress", "recent_round_coefs", _recent_round_coefs)
	cfg.set_value("progress", "rounds_since_last_death", _rounds_since_last_death)
	cfg.set_value("progress", "win_streak_count", _win_streak_count)
	cfg.set_value("progress", "finish_best_results", _finish_best_results)
	cfg.set_value("progress", "finish_best_streak", _finish_best_streak)
	cfg.set_value("progress", "last_streak_record_count", _last_streak_record_count)
	cfg.set_value("progress", "streak_word_shown", _streak_word_shown)
	cfg.set_value("progress", "hard_banner_shown", _hard_banner_shown)
	cfg.set_value("progress", "current_level_dirty", _current_level_dirty)
	cfg.set_value("progress", "user_level", _user_level)
	cfg.set_value("progress", "user_level_reached_3", _user_level_reached_3)
	cfg.set_value("progress", "user_level_reached_4", _user_level_reached_4)
	cfg.set_value("progress", "user_level_clean_streak", _user_level_clean_streak)
	cfg.set_value("progress", "user_level_recent_dirty", _user_level_recent_dirty)
	cfg.set_value("progress", "has_restarted", _has_restarted)
	cfg.set_value("progress", "repeat_restart_level", _repeat_restart_level)
	cfg.set_value("progress", "repeat_restart_count", _repeat_restart_count)
	cfg.set_value("progress", "daily_round_date", _daily_round_date)
	cfg.set_value("progress", "daily_round_count", _daily_round_count)
	cfg.set_value("progress", "daily_downgrade_level", _daily_downgrade_level)
	cfg.set_value("progress", "daily_attempt_key", _daily_attempt_key)
	cfg.set_value("progress", "daily_attempt_count", _daily_attempt_count)
	cfg.set_value("progress", "debug_proxy_host", _debug_proxy_host)
	cfg.set_value("progress", "debug_proxy_port", _debug_proxy_port)
	cfg.set_value("progress", "debug_ab_overrides", _debug_ab_overrides)
	cfg.set_value("progress", "mock_unikit_config", _mock_unikit_config)
	cfg.set_value("progress", "debug_no_ads", _debug_no_ads)

	var path: String = _resolve_save_path()
	var result: Error = cfg.save_encrypted_pass(path + ".tmp", SAVE_PASSWORD)
	if result == OK:
		result = DirAccess.rename_absolute(path + ".tmp", path)
	if result != OK:
		SortLogger.error("UserState 保存失败: %s" % error_string(result))
	if result == OK:
		_rank_clock_saved = _rank_clock_watermark

		if not _first_app_version.is_empty():
			_first_app_version_saved = true
	return result

func _load_data() -> Error:

	_first_app_version = ""
	_first_app_version_saved = false
	var cfg: = ConfigFile.new()
	var load_result: Error = cfg.load_encrypted_pass(_resolve_save_path(), SAVE_PASSWORD)
	if load_result != OK:
		return load_result
	_special_challenge = cfg.get_value("special_challenge", "active", {}) as Dictionary
	_special_challenge_completed = int(cfg.get_value("special_challenge", "completed", 0))
	_special_challenge_offer_after = int(cfg.get_value("special_challenge", "offer_after", 0))
	_special_level2_next_slot = int(cfg.get_value("special_challenge", "level2_next_slot", 0))
	_special_level2_control_turns = int(cfg.get_value("special_challenge", "level2_control_turns", 0))
	_special_level2_new_turns = int(cfg.get_value("special_challenge", "level2_new_turns", 0))
	_special_level2_seeded = bool(cfg.get_value("special_challenge", "level2_seeded", false))
	_special_theme_next_sequence = maxi(0, int(cfg.get_value("special_theme", "next_sequence", 0)))
	_special_theme_assignments = cfg.get_value("special_theme", "assignments", {}) as Dictionary
	_outer_loop_pending_level = int(cfg.get_value("progress", "outer_loop_pending_level", 0))
	_hex_board_chapter = int(cfg.get_value("progress", "hex_board_chapter", 0))
	_hex_board_revealed.clear()
	var raw_revealed: Variant = cfg.get_value("progress", "hex_board_revealed", [])
	if raw_revealed is Array:
		for value: Variant in raw_revealed:
			var idx: int = int(value)
			if idx >= 0 and idx < LevelIndex.CHAPTER_SIZE and not _hex_board_revealed.has(idx):
				_hex_board_revealed.append(idx)
	_rank_unlocked = bool(cfg.get_value("progress", "rank_unlocked", false))
	_rank_nickname = String(cfg.get_value("progress", "rank_nickname", ""))
	_rank_avatar_index = int(cfg.get_value("progress", "rank_avatar_index", -1))
	_rank_current_entity = cfg.get_value("progress", "rank_current_entity", {})
	_rank_clock_watermark = int(cfg.get_value("progress", "rank_clock_watermark", 0))
	_rank_clock_saved = _rank_clock_watermark
	_rank_ever_played = bool(cfg.get_value("progress", "rank_ever_played", false))
	_rank_avatar_dialog_ever_shown = bool(cfg.get_value("progress", "rank_avatar_dialog_ever_shown", false))
	_rank_disabled = bool(cfg.get_value("progress", "rank_disabled", false))
	_current_level = cfg.get_value("progress", "current_level", 1)
	_pending_level_completion = int(cfg.get_value("progress", "pending_level_completion", 0))
	_pending_outer_loop_enabled = bool(cfg.get_value("progress", "pending_outer_loop_enabled", true))

	_pending_special_challenge_offer = bool(cfg.get_value("progress", "pending_special_challenge_offer", 
		SpecialChallengeRules.is_anchor(_pending_level_completion)))
	_timed_endless_state = cfg.get_value("timed_endless", "state", {}) as Dictionary
	_pending_timed_endless_offer = cfg.get_value("progress", "pending_timed_endless_offer", {}) as Dictionary
	_pending_iq_completion = cfg.get_value("progress", "pending_iq_completion", {}) as Dictionary
	_daily_checkin_state = cfg.get_value("daily_checkin", "state", {}) as Dictionary
	_pending_daily_checkin_completion = cfg.get_value("daily_checkin", "pending_completion", {}) as Dictionary
	_coin_bonus_state = cfg.get_value("coin_bonus_level", "state", {}) as Dictionary
	_pending_coin_bonus_completion = cfg.get_value("coin_bonus_level", "pending_completion", {}) as Dictionary
	_daily_challenge_day = String(cfg.get_value("daily_challenge", "day", ""))
	_daily_challenge_elapsed_ms = maxi(0, int(cfg.get_value("daily_challenge", "elapsed_ms", 0)))
	_daily_challenge_percentile = clampf(float(cfg.get_value("daily_challenge", "percentile", 0.0)), 0.0, 100.0)
	_daily_challenge_sequence = maxi(0, int(cfg.get_value("daily_challenge", "sequence", 0)))
	_daily_challenge_assigned_day = String(cfg.get_value("daily_challenge", "assigned_day", ""))
	_daily_challenge_assigned_date = String(cfg.get_value("daily_challenge", "assigned_date", ""))
	_iq_rounds_since_guarantee = clampi(int(cfg.get_value("progress", "iq_rounds_since_guarantee", 4)), 0, 4)

	_completed_level_count = maxi(0, int(cfg.get_value("progress", "completed_level_count", 
		_current_level - 1)))
	_interstitial_unlocked = bool(cfg.get_value("ads", "interstitial_unlocked", false))
	_banner_unlocked = bool(cfg.get_value("ads", "banner_unlocked", false))
	_ad_daily_completed_date = String(cfg.get_value("ads", "daily_completed_date", ""))
	_ad_daily_completed_count = maxi(0, int(cfg.get_value("ads", "daily_completed_count", 0)))
	_pending_ad_completion_date = String(cfg.get_value("ads", "pending_completion_date", ""))
	_review_request_sent = bool(cfg.get_value("progress", "review_request_sent", false))
	_tutorial_done = cfg.get_value("progress", "tutorial_done", false)
	_current_strategy = cfg.get_value("progress", "current_strategy", 1)
	_has_agreed_privacy = cfg.get_value("progress", "has_agreed_privacy", false)
	_push_ask_count = int(cfg.get_value("progress", "push_ask_count", 0))
	_daily_completed_date = cfg.get_value("progress", "daily_completed_date", "")
	_prop_hint = cfg.get_value("progress", "prop_hint", 3)
	_prop_undo = cfg.get_value("progress", "prop_undo", 3)
	_prop_rope = cfg.get_value("progress", "prop_extra_rope", 1)
	_prop_fill_pot = int(cfg.get_value("progress", "prop_fill_pot", 0))
	_prop_reward_ads_count = cfg.get_value("progress", "prop_reward_ads_count", {})
	for kind: String in ["hint", "undo", "rope", "fill_pot"]:
		_prop_reward_ads_count[kind] = get_prop_reward_ads_count(kind)
	_prop_unlock_shown = cfg.get_value("progress", "prop_unlock_shown", {})
	_prop_early_unlocked = cfg.get_value("progress", "prop_early_unlocked", {})
	_prop_free_available = cfg.get_value("progress", "prop_free_available", {})
	_prop_free_granted = cfg.get_value("progress", "prop_free_granted", {})
	_prop_free_get_reported = cfg.get_value("progress", "prop_free_get_reported", {})
	_cliff_hint_granted = cfg.get_value("progress", "cliff_hint_granted", {})
	_last_splash_date = str(cfg.get_value("progress", "last_splash_date", ""))
	_music_enabled = bool(cfg.get_value("settings", "music_enabled", true))
	_sfx_enabled = bool(cfg.get_value("settings", "sfx_enabled", true))

	_haptic_enabled = bool(cfg.get_value("settings", "haptic_enabled", 
		cfg.get_value("progress", "vibration_on", true)))
	_help_center_unread_count = int(cfg.get_value("help_center", "unread_count", 0))
	_help_center_badge = bool(cfg.get_value("help_center", "badge", false))
	_is_first_session = cfg.get_value("progress", "is_first_session", true)
	_session_num = cfg.get_value("progress", "session_num", 0)
	_grt_new_install_anchors = cfg.get_value("progress", "grt_new_install_anchors", {})
	_grt_sent_events = cfg.get_value("progress", "grt_sent_events", {})
	_grt_inter_show_count = int(cfg.get_value("progress", "grt_inter_show_count", 0))
	_grt_reward_show_count = int(cfg.get_value("progress", "grt_reward_show_count", 0))
	_coins = cfg.get_value("progress", "coins", 0)
	_moves_intro_shown = cfg.get_value("progress", "moves_intro_shown", false)
	_mystery_guide_shown = cfg.get_value("progress", "mystery_guide_shown", false)
	_root_swap_guide_done = cfg.get_value("progress", "root_swap_guide_done", false)
	_root_swap_guide_shown = cfg.get_value("progress", "root_swap_guide_shown", false)
	var root_swap_pending: Variant = cfg.get_value("progress", "root_swap_guide_pending", {})
	_root_swap_guide_pending = root_swap_pending.duplicate(true) if root_swap_pending is Dictionary else {}
	_lock_guide_shown = cfg.get_value("progress", "lock_guide_shown", false)
	_sunlight_guide_shown = cfg.get_value("progress", "sunlight_guide_shown", false)
	var warmup_records: Variant = cfg.get_value("progress", "effect_warmup_records", {})
	_effect_warmup_records = warmup_records if warmup_records is Dictionary else {}
	_effects_warmed = cfg.get_value("progress", "effects_warmed", false)
	_rope_shader_warmed_key = str(cfg.get_value("progress", "rope_shader_warmed_key", ""))
	_sticker_tutorial_shown = cfg.get_value("progress", "sticker_tutorial_shown", false)
	_order_zoom_guide_shown = cfg.get_value("progress", "order_zoom_guide_shown", false)
	_wireframe_level_intro_shown = cfg.get_value("progress", "wireframe_level_intro_shown", false)
	_first_install_date = cfg.get_value("progress", "first_install_date", "")

	var raw_first_app_version: Variant = cfg.get_value("progress", "first_app_version", "")
	if raw_first_app_version is String and _is_valid_version(raw_first_app_version):
		_first_app_version = raw_first_app_version
		_first_app_version_saved = true
	_recent_round_coefs = cfg.get_value("progress", "recent_round_coefs", [])
	_rounds_since_last_death = cfg.get_value("progress", "rounds_since_last_death", ROUNDS_SINCE_DEATH_NEVER)
	_win_streak_count = cfg.get_value("progress", "win_streak_count", 0)
	_finish_best_results = cfg.get_value("progress", "finish_best_results", {})
	_finish_best_streak = int(cfg.get_value("progress", "finish_best_streak", 0))
	_last_streak_record_count = int(cfg.get_value("progress", "last_streak_record_count", 0))
	_streak_word_shown = cfg.get_value("progress", "streak_word_shown", {})
	_hard_banner_shown = cfg.get_value("progress", "hard_banner_shown", {})
	_current_level_dirty = bool(cfg.get_value("progress", "current_level_dirty", false))
	_user_level = int(cfg.get_value("progress", "user_level", 0))

	_user_level_reached_4 = bool(cfg.get_value("progress", "user_level_reached_4", false)) or _user_level >= 4

	_user_level_reached_3 = bool(cfg.get_value("progress", "user_level_reached_3", false)) or _user_level >= 3 or _user_level_reached_4
	_user_level_clean_streak = int(cfg.get_value("progress", "user_level_clean_streak", 0))
	_user_level_recent_dirty = cfg.get_value("progress", "user_level_recent_dirty", [])
	_has_restarted = bool(cfg.get_value("progress", "has_restarted", false))
	_repeat_restart_level = int(cfg.get_value("progress", "repeat_restart_level", 0))
	_repeat_restart_count = int(cfg.get_value("progress", "repeat_restart_count", 0))
	_daily_round_date = String(cfg.get_value("progress", "daily_round_date", ""))
	_daily_round_count = int(cfg.get_value("progress", "daily_round_count", 0))
	_daily_downgrade_level = int(cfg.get_value("progress", "daily_downgrade_level", 0))
	_daily_attempt_key = int(cfg.get_value("progress", "daily_attempt_key", 0))
	_daily_attempt_count = int(cfg.get_value("progress", "daily_attempt_count", 0))
	_debug_proxy_host = cfg.get_value("progress", "debug_proxy_host", "")
	_debug_proxy_port = cfg.get_value("progress", "debug_proxy_port", -1)
	_debug_ab_overrides = cfg.get_value("progress", "debug_ab_overrides", {})
	_mock_unikit_config = cfg.get_value("progress", "mock_unikit_config", {})
	_debug_no_ads = bool(cfg.get_value("progress", "debug_no_ads", false))

	_ads_legacy_migration_pending = not cfg.has_section_key("ads", "interstitial_unlocked")\
	or not cfg.has_section_key("ads", "banner_unlocked")
	if not cfg.has_section_key("ads", "interstitial_unlocked"):
		_interstitial_unlocked = _current_level >= 11
	if not cfg.has_section_key("ads", "banner_unlocked"):
		_banner_unlocked = _current_level >= 21 and get_install_days() >= 2
	return OK

func _today_str() -> String:
	var dt: Dictionary = Time.get_date_dict_from_system()
	return "%d-%02d-%02d" % [dt.year, dt.month, dt.day]


func reset_all() -> void :
	_special_challenge.clear()
	_special_challenge_completed = 0
	_special_challenge_offer_after = 0
	_special_level2_next_slot = 0
	_special_level2_control_turns = 0
	_special_level2_new_turns = 0
	_special_level2_seeded = false
	_special_theme_next_sequence = 0
	_special_theme_assignments.clear()
	_outer_loop_pending_level = 0
	_hex_board_chapter = 0
	_hex_board_revealed.clear()
	_rank_unlocked = false
	_rank_nickname = ""
	_rank_avatar_index = -1
	_rank_current_entity = {}
	_rank_clock_watermark = 0
	_rank_clock_saved = 0
	_rank_ever_played = false
	_rank_avatar_dialog_ever_shown = false
	_rank_disabled = false
	_current_level = 1
	_pending_level_completion = 0
	_pending_outer_loop_enabled = true
	_pending_special_challenge_offer = false
	_pending_timed_endless_offer = {}
	_timed_endless_state = {}
	_pending_iq_completion = {}
	_daily_checkin_state = {}
	_pending_daily_checkin_completion = {}
	_coin_bonus_state = {}
	_pending_coin_bonus_completion = {}
	_daily_challenge_day = ""
	_daily_challenge_elapsed_ms = 0
	_daily_challenge_percentile = 0.0
	_daily_challenge_sequence = 0
	_daily_challenge_assigned_day = ""
	_daily_challenge_assigned_date = ""
	_daily_attempt_key = 0
	_daily_attempt_count = 0
	_iq_rounds_since_guarantee = 4
	_completed_level_count = 0
	_interstitial_unlocked = false
	_banner_unlocked = false
	_ad_daily_completed_date = ""
	_ad_daily_completed_count = 0
	_pending_ad_completion_date = ""
	_ads_legacy_migration_pending = false
	_review_request_sent = false
	_tutorial_done = false
	_has_agreed_privacy = false
	_push_ask_count = 0
	_current_strategy = 1
	_current_level_dirty = false
	_current_level_retried = false
	_user_level = 0
	_user_level_reached_3 = false
	_user_level_reached_4 = false
	_user_level_clean_streak = 0
	_user_level_recent_dirty = []
	_has_restarted = false
	_repeat_restart_level = 0
	_repeat_restart_count = 0
	_daily_round_date = ""
	_daily_round_count = 0
	_daily_downgrade_level = 0
	_daily_completed_date = ""
	_prop_hint = 3
	_prop_undo = 3
	_prop_rope = 1
	_prop_fill_pot = 0
	_prop_reward_ads_count = {}
	_prop_unlock_shown = {}
	_prop_early_unlocked = {}
	_prop_free_available = {}
	_prop_free_granted = {}
	_prop_free_get_reported = {}
	_cliff_hint_granted = {}
	_last_splash_date = ""
	_music_enabled = true
	_sfx_enabled = true
	_haptic_enabled = true
	_help_center_unread_count = 0
	_help_center_badge = false
	_is_first_session = true
	_first_session_runtime = true
	_session_num = 0
	_grt_new_install_anchors.clear()
	_grt_sent_events.clear()
	_grt_inter_show_count = 0
	_grt_reward_show_count = 0
	_coins = 0
	_moves_intro_shown = false
	_mystery_guide_shown = false
	_root_swap_guide_done = false
	_root_swap_guide_shown = false
	_root_swap_guide_pending = {}
	_lock_guide_shown = false
	_sunlight_guide_shown = false
	_sticker_tutorial_shown = false
	_order_zoom_guide_shown = false
	_wireframe_level_intro_shown = false
	_recent_round_coefs = []
	_rounds_since_last_death = ROUNDS_SINCE_DEATH_NEVER
	_win_streak_count = 0
	_finish_best_results = {}
	_finish_best_streak = 0
	_last_streak_record_count = 0
	_streak_word_shown = {}
	_hard_banner_shown = {}



	_debug_proxy_host = ""
	_debug_proxy_port = -1
	_debug_ab_overrides = {}
	_mock_unikit_config = {}
	_debug_no_ads = false
	_save_data()
	audio_settings_changed.emit()



func get_special_challenge() -> Dictionary:
	return _special_challenge.duplicate(true)


func get_special_theme_assignment(round_kind: String, round_key: String) -> Dictionary:
	var assignment: Dictionary = _special_theme_assignments.get(round_kind, {}) as Dictionary
	return assignment.duplicate() if String(assignment.get("round_key", "")) == round_key else {}

func get_special_theme_next_sequence() -> int:
	return _special_theme_next_sequence


func commit_special_theme_assignment(round_kind: String, round_key: String, skin_id: String, sequence: int) -> bool:
	if round_kind not in ["level", "special_challenge"] or round_key.is_empty() or skin_id.is_empty():
		return false
	var existing: Dictionary = get_special_theme_assignment(round_kind, round_key)
	if not existing.is_empty():
		return String(existing.get("skin_id", "")) == skin_id
	if sequence != _special_theme_next_sequence:
		return false
	var previous: Dictionary = _special_theme_assignments.duplicate(true)
	_special_theme_assignments[round_kind] = {"round_key": round_key, "skin_id": skin_id, "sequence": sequence}
	_special_theme_next_sequence += 1
	if _save_data() != OK:
		_special_theme_next_sequence = sequence
		_special_theme_assignments = previous
		SortLogger.error("SpecialTheme: 轮换分配保存失败：(round=%s)" % round_key)
		return false
	return true



func get_special_challenge_tracking(instance_id: String) -> Dictionary:
	if instance_id.is_empty() or String(_special_challenge.get("instance_id", "")) != instance_id:
		return {}
	return (_special_challenge.get("tracking", {}) as Dictionary).duplicate(true)


func update_special_challenge_tracking(instance_id: String, tracking: Dictionary) -> bool:
	if instance_id.is_empty() or String(_special_challenge.get("instance_id", "")) != instance_id:
		return false
	var previous: Dictionary = _special_challenge.duplicate(true)
	_special_challenge["tracking"] = tracking.duplicate(true)
	if _save_data() != OK:
		_special_challenge = previous
		SortLogger.error("Special Challenge 埋点统计保存失败: %s" % instance_id)
		return false
	return true

func has_special_challenge() -> bool:
	return not _special_challenge.is_empty()

func get_special_challenge_offer_after() -> int:
	return _special_challenge_offer_after



func get_special_challenge_preview_state() -> Dictionary:
	return {"challenge": _special_challenge.duplicate(true), "offer_after": _special_challenge_offer_after, 
		"completed": _special_challenge_completed}

func resolve_special_challenge_offer(enabled: bool) -> bool:
	if _special_challenge_offer_after <= 0 or has_special_challenge():
		return false
	var anchor: int = _special_challenge_offer_after
	if anchor + 1 != _current_level:
		enabled = false
	var previous: Dictionary = _special_challenge.duplicate(true)
	var previous_slot: int = _special_level2_next_slot
	_special_challenge_offer_after = 0
	if enabled:
		_special_challenge = {"instance_id": "special:%d:%d" % [anchor, _special_challenge_completed + 1], 
			"after_level": anchor, "case_number": SpecialChallengeRules.case_number(_special_challenge_completed), 

			"level2_slot": _special_level2_next_slot, 
			"status": "playing", "reward": {}}
		_special_level2_next_slot = 1 - _special_level2_next_slot
	if _save_data() != OK:
		_special_challenge = previous
		_special_challenge_offer_after = anchor
		_special_level2_next_slot = previous_slot
		return false
	return enabled





func migrate_special_challenge_to_level2(instance_id: String, case_number: int) -> bool:
	if instance_id.is_empty() or String(_special_challenge.get("instance_id", "")) != instance_id:
		return false
	if _special_challenge.is_empty() or _special_challenge.has("level2_slot"):
		return false
	var previous: Dictionary = _special_challenge.duplicate(true)
	var previous_slot: int = _special_level2_next_slot
	var previous_control: int = _special_level2_control_turns
	var previous_new: int = _special_level2_new_turns
	var previous_seeded: bool = _special_level2_seeded
	_special_challenge["level2_slot"] = 0
	_special_challenge["level2_bank"] = 0

	_special_challenge["level2_legacy"] = true
	_special_level2_next_slot = 1
	_special_level2_control_turns = posmod(case_number, SpecialChallengeRules.BANK_SIZE)
	_special_level2_new_turns = 0
	_special_level2_seeded = true
	if _save_data() != OK:
		_special_challenge = previous
		_special_level2_next_slot = previous_slot
		_special_level2_control_turns = previous_control
		_special_level2_new_turns = previous_new
		_special_level2_seeded = previous_seeded
		SortLogger.error("Special Challenge 2.0 旧实例迁移保存失败: %s" % instance_id)
		return false
	return true




func advance_special_level2_case(instance_id: String, slot: int) -> Dictionary:
	if instance_id.is_empty() or String(_special_challenge.get("instance_id", "")) != instance_id:
		return {}
	var previous: Dictionary = _special_challenge.duplicate(true)
	var previous_control: int = _special_level2_control_turns
	var previous_new: int = _special_level2_new_turns
	var previous_seeded: bool = _special_level2_seeded
	if not _special_level2_seeded:

		_special_level2_control_turns = posmod(_special_challenge_completed, SpecialChallengeRules.BANK_SIZE)
		_special_level2_new_turns = 0
		_special_level2_seeded = true
	var picked: Dictionary = SpecialChallengeRules.level2_case_for_slot(
		slot, _special_level2_control_turns, _special_level2_new_turns)
	if slot == 1:
		_special_level2_new_turns += 1
	else:
		_special_level2_control_turns += 1
	_special_challenge["case_number"] = int(picked["case_number"])
	_special_challenge["level2_bank"] = int(picked["bank"])
	_special_challenge["level2_slot"] = slot
	if _save_data() != OK:
		_special_challenge = previous
		_special_level2_control_turns = previous_control
		_special_level2_new_turns = previous_new
		_special_level2_seeded = previous_seeded
		SortLogger.error("Special Challenge 2.0 选题保存失败: %s" % instance_id)
	return picked


func begin_special_challenge_completion(instance_id: String, daily_checkin_completion: Dictionary = {}) -> bool:
	if String(_special_challenge.get("instance_id", "")) != instance_id:
		return false
	if _special_challenge.get("status") != "playing":
		return true
	var previous: Dictionary = _special_challenge.duplicate(true)
	var previous_streak: int = _win_streak_count
	var previous_best_streak: int = _finish_best_streak
	var previous_record_count: int = _last_streak_record_count
	_special_challenge["reward"] = SpecialChallengeRules.reward_for_roll(randi_range(0, 99))
	_special_challenge["status"] = "win_pending"
	_special_challenge["daily_checkin_completion"] = daily_checkin_completion.duplicate(true)
	_win_streak_count += 1
	_last_streak_record_count = _win_streak_count if _finish_best_streak > 0 and _win_streak_count > _finish_best_streak else 0
	_finish_best_streak = maxi(_finish_best_streak, _win_streak_count)
	if _save_data() != OK:
		_special_challenge = previous
		_win_streak_count = previous_streak
		_finish_best_streak = previous_best_streak
		_last_streak_record_count = previous_record_count
		return false
	return true

func finalize_special_challenge_completion() -> bool:
	if _special_challenge.get("status") == "reward_pending":
		return true
	if _special_challenge.get("status") != "win_pending":
		return false
	var previous_checkin: Dictionary = _daily_checkin_state
	var previous_coins: int = _coins
	_apply_daily_checkin_completion(_special_challenge.get("daily_checkin_completion", {}))
	_special_challenge["status"] = "reward_pending"
	if _save_data() != OK:
		_daily_checkin_state = previous_checkin
		_coins = previous_coins
		_special_challenge["status"] = "win_pending"
		return false
	return true


func claim_special_challenge(instance_id: String, multiplier: int) -> Dictionary:
	if String(_special_challenge.get("instance_id", "")) != instance_id\
	or _special_challenge.get("status") != "reward_pending" or multiplier not in [1, 2]:
		return {}
	var reward: Dictionary = SpecialChallengeRules.multiplied_reward(_special_challenge["reward"], multiplier)
	var previous: Dictionary = _special_challenge.duplicate(true)
	var before: Dictionary = {"coins": _coins, "hint": _prop_hint, "undo": _prop_undo, "rope": _prop_rope}
	_coins += int(reward["coins"])
	_prop_hint += int(reward["hint"])
	_prop_undo += int(reward["undo"])
	_prop_rope += int(reward["rope"])
	_special_challenge_completed += 1
	_special_challenge = {}
	if _save_data() != OK:
		_special_challenge = previous
		_special_challenge_completed -= 1
		_coins = int(before["coins"])
		_prop_hint = int(before["hint"])
		_prop_undo = int(before["undo"])
		_prop_rope = int(before["rope"])
		return {}
	return {"reward": reward, "before": before}



func get_rank_current_entity() -> Dictionary:
	return _rank_current_entity.duplicate(true)

func commit_rank_entity(entity: Dictionary) -> bool:
	var same_event: bool = not _rank_current_entity.is_empty() and String(entity.get("event_id", "")) == String(_rank_current_entity.get("event_id", ""))
	var received: bool = bool(entity.get("has_receive_bonus", false))
	if (same_event and received != bool(_rank_current_entity.get("has_receive_bonus", false))) or ( not same_event and received):
		SortLogger.error("[Rank] 领取标记只能由原子领奖入口修改")
		return false
	var previous: Dictionary = _rank_current_entity
	_rank_current_entity = entity.duplicate(true)
	if _save_data() != OK:
		_rank_current_entity = previous
		return false
	return true


func claim_rank_season_reward(event_id: String) -> bool:
	if event_id.is_empty() or String(_rank_current_entity.get("event_id", "")) != event_id:
		return false
	if String(_rank_current_entity.get("settle_state", "")) != "computed" or bool(_rank_current_entity.get("has_receive_bonus", false)):
		return false
	var previous: Dictionary = _rank_current_entity.duplicate(true)
	var previous_hint: int = _prop_hint
	var previous_coins: int = _coins
	_prop_hint += maxi(int(previous.get("reward_hint", 0)), 0)
	_coins += maxi(int(previous.get("reward_coin", 0)), 0)
	_rank_current_entity["has_receive_bonus"] = true
	_rank_current_entity["settle_state"] = "received"
	if _save_data() != OK:
		_rank_current_entity = previous
		_prop_hint = previous_hint
		_coins = previous_coins
		return false
	return true

func set_rank_profile(nickname: String, avatar_index: int) -> bool:
	var previous_name: String = _rank_nickname
	var previous_avatar: int = _rank_avatar_index
	_rank_nickname = nickname
	_rank_avatar_index = avatar_index
	if _save_data() != OK:
		_rank_nickname = previous_name
		_rank_avatar_index = previous_avatar
		return false
	return true

func get_rank_clock_watermark() -> int:
	return _rank_clock_watermark

func advance_rank_clock_watermark(now_ms: int) -> void :

	if now_ms <= _rank_clock_watermark:
		return
	var previous: int = _rank_clock_watermark
	_rank_clock_watermark = now_ms
	if now_ms - _rank_clock_saved >= 60000 and _save_data() != OK:
		_rank_clock_watermark = previous

func set_rank_disabled(value: bool) -> void :
	var previous: bool = _rank_disabled
	_rank_disabled = value
	if _save_data() != OK:
		_rank_disabled = previous

func is_rank_unlocked() -> bool:
	return _rank_unlocked

func mark_rank_unlocked() -> void :
	if _rank_unlocked:
		return
	_rank_unlocked = true
	if _save_data() != OK:
		_rank_unlocked = false

func is_rank_ever_played() -> bool:
	return _rank_ever_played

func mark_rank_ever_played() -> void :
	if _rank_ever_played:
		return
	_rank_ever_played = true
	if _save_data() != OK:
		_rank_ever_played = false

func is_rank_avatar_dialog_ever_shown() -> bool:
	return _rank_avatar_dialog_ever_shown

func mark_rank_avatar_dialog_shown() -> void :
	if _rank_avatar_dialog_ever_shown:
		return
	_rank_avatar_dialog_ever_shown = true
	if _save_data() != OK:
		_rank_avatar_dialog_ever_shown = false

func get_rank_nickname() -> String:
	return _rank_nickname

func get_rank_avatar_index() -> int:
	return _rank_avatar_index

func is_rank_disabled() -> bool:
	return _rank_disabled


func get_effect_warmup_record(key: String) -> Dictionary:
	return (_effect_warmup_records.get(key, {}) as Dictionary).duplicate()


func mark_effect_warmup_record(key: String, record: Dictionary) -> bool:
	if _effect_warmup_records.get(key, {}) == record:
		return true
	var previous: Dictionary = _effect_warmup_records.duplicate()
	_effect_warmup_records[key] = record.duplicate()
	if _save_data() != OK:
		_effect_warmup_records = previous
		return false
	return true


func get_pending_timed_endless_offer() -> Dictionary:
	return _pending_timed_endless_offer.duplicate(true)


func get_timed_endless_last_anchor() -> int:
	return int(_timed_endless_state.get("last_anchor", 0))


func get_timed_endless_offer() -> Dictionary:
	return (_timed_endless_state.get("offer", {}) as Dictionary).duplicate(true)


func begin_timed_endless(instance_id: String, coins_per_pot: int) -> bool:
	var offer: Dictionary = get_timed_endless_offer()
	if instance_id.is_empty() or offer.get("instance_id", "") != instance_id or coins_per_pot not in [5, 10]:
		return false
	if offer.get("status") == "playing":
		return true
	if offer.get("status") != "offered":
		return false
	var previous: Dictionary = _timed_endless_state.duplicate(true)
	offer["status"] = "playing"
	offer["coins_per_pot"] = coins_per_pot
	offer["cups"] = 0
	_timed_endless_state["offer"] = offer
	if _save_data() != OK:
		_timed_endless_state = previous
		return false
	return true


func checkpoint_timed_endless(instance_id: String, cups: int) -> bool:
	var offer: Dictionary = get_timed_endless_offer()
	if offer.get("instance_id", "") != instance_id or offer.get("status") != "playing":
		return false
	if int(offer.get("cups", 0)) == maxi(0, cups):
		return true
	var previous: Dictionary = _timed_endless_state.duplicate(true)
	offer["cups"] = maxi(0, cups)
	_timed_endless_state["offer"] = offer
	if _save_data() != OK:
		_timed_endless_state = previous
		return false
	return true



func prepare_timed_endless_reward(instance_id: String, cups: int, reason: String, presentation: Dictionary = {}) -> Dictionary:
	var offer: Dictionary = get_timed_endless_offer()
	if instance_id.is_empty() or offer.get("instance_id", "") != instance_id:
		return {}
	if offer.get("status") == "reward_pending":
		return (offer.get("result", {}) as Dictionary).duplicate(true)
	if offer.get("status") != "playing":
		return {}
	var previous: Dictionary = _timed_endless_state.duplicate(true)
	var result: Dictionary = _timed_endless_reward_result(offer, cups, reason, presentation)
	offer["status"] = "reward_pending"
	offer["cups"] = maxi(0, cups)
	offer["result"] = result
	_timed_endless_state["offer"] = offer
	if _save_data() != OK:
		_timed_endless_state = previous
		return {}
	return result.duplicate(true)



func claim_timed_endless_reward(instance_id: String) -> Dictionary:
	var offer: Dictionary = get_timed_endless_offer()
	if instance_id.is_empty() or offer.get("instance_id", "") != instance_id or offer.get("status") != "reward_pending":
		return {}
	var result: Dictionary = (offer.get("result", {}) as Dictionary).duplicate(true)
	if result.is_empty():
		return {}
	var previous: Dictionary = _timed_endless_state.duplicate(true)
	var before: int = _coins
	var reward: int = int(result["coins"])
	_coins += reward
	_timed_endless_state.erase("offer")
	if _save_data() != OK:
		_timed_endless_state = previous
		_coins = before
		return {}
	result["before"] = before
	return result



func complete_timed_endless(instance_id: String, cups: int, reason: String) -> Dictionary:
	var offer: Dictionary = get_timed_endless_offer()
	if instance_id.is_empty() or offer.get("instance_id", "") != instance_id:
		return {}
	if offer.get("status", "") == "reward_pending":
		return claim_timed_endless_reward(instance_id)
	if offer.get("status", "") != "playing":
		return {}

	var previous: Dictionary = _timed_endless_state.duplicate(true)
	offer["status"] = "reward_pending"
	offer["result"] = _timed_endless_reward_result(offer, cups, reason, {})
	_timed_endless_state["offer"] = offer
	var result: Dictionary = claim_timed_endless_reward(instance_id)
	if result.is_empty():
		_timed_endless_state = previous
	return result


func _timed_endless_reward_result(offer: Dictionary, cups: int, reason: String, presentation: Dictionary) -> Dictionary:
	var result: Dictionary = presentation.duplicate(true)
	result.merge({"instance_id": offer["instance_id"], "after_level": int(offer["after_level"]), 
		"cups": maxi(0, cups), "coins": maxi(0, cups) * int(offer["coins_per_pot"]), 
		"coins_per_pot": int(offer["coins_per_pot"]), "reason": reason}, true)
	return result


func recover_interrupted_timed_endless() -> bool:
	var offer: Dictionary = get_timed_endless_offer()
	if offer.get("status", "") == "reward_pending":
		return not claim_timed_endless_reward(String(offer["instance_id"])).is_empty()
	if offer.get("status", "") != "playing":
		return true
	return not complete_timed_endless(String(offer["instance_id"]), int(offer.get("cups", 0)), "interrupted").is_empty()
