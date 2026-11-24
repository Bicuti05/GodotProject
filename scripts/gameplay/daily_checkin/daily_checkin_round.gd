class_name DailyCheckinRound
extends RefCounted

var _prepared: bool = false
var _completion: Dictionary = {}
var _presented: bool = false

func reset() -> void :
	_prepared = false
	_completion = {}
	_presented = false


func prepare_win(level: int, special: bool, settlement_id: String) -> Dictionary:
	if _prepared:
		return _completion.duplicate(true)
	_prepared = true
	_completion = UserState.get_pending_daily_checkin_completion(level, special)
	if not _completion.is_empty():
		return _completion.duplicate(true)
	var state: Dictionary = UserState.get_daily_checkin_state()
	var unlocked: bool = bool(state.get("unlocked", false)) or level >= DailyCheckinRules.UNLOCK_LEVEL

	if special and not bool(state.get("unlocked", false)):
		unlocked = UserState.get_current_level() > DailyCheckinRules.UNLOCK_LEVEL
	var date: Dictionary = Time.get_date_dict_from_system(false)
	var date_text: String = "%04d-%02d-%02d" % [date.year, date.month, date.day]
	var policy: Dictionary = ABManager.daily_first_win_checkin.checkin_policy()
	_completion = DailyCheckinRules.completion(state, DailyCheckinRules.date_serial(date), date_text, 
		unlocked, policy, settlement_id)
	return _completion.duplicate(true)

func is_committed() -> bool:
	return not _completion.is_empty() and String(UserState.get_daily_checkin_state().get(
		"last_settlement_id", "")) == String(_completion["settlement_id"])

func completion() -> Dictionary:
	return _completion.duplicate(true) if is_committed() and not _presented else {}

func pending_coin_display() -> int:
	return int(_completion.get("reward_coins", 0)) if is_committed() and not _presented else 0

func mark_presented() -> void :
	_presented = true
