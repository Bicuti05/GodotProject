class_name IqRoundModel
extends RefCounted


const INITIAL_IQ: float = 40.0
const BOOSTED_INITIAL_IQ: float = 60.0
const BASE_POINTS: float = 60.0
const GENIUS_IQ: float = 140.0
const BOOSTED_GENIUS_IQ: float = 160.0
const GUARANTEE_MAX: int = 160
const BOOSTED_GUARANTEE_MAX: int = 180
const GUARANTEE_INTERVAL: int = 4

var enabled: bool = false
var score_boost_enabled: bool = false
var s_grade_guarantee: bool = false
var _target_cups: int = 0
var _last_done: int = 0
var _base_awarded_done: int = 0
var _combo_points: int = 0
var _finalized: bool = false
var _final_iq: float = INITIAL_IQ
var _guarantee_triggered: bool = false


static func is_round_eligible(level_id: int, special: bool, bonus: bool) -> bool:
	return level_id >= 4 and not special and not bonus


func reset(active: bool, target_cups: int, done: int = 0, saved: Dictionary = {}, 
		score_boost: bool = false, use_s_grade: bool = false) -> void :
	var before: float = value()
	var was_enabled: bool = enabled
	enabled = active and bool(saved.get("enabled", active)) and target_cups > 0
	score_boost_enabled = enabled and bool(saved.get("score_boost_enabled", score_boost))
	s_grade_guarantee = score_boost_enabled and bool(saved.get("s_grade_guarantee", use_s_grade))
	_target_cups = maxi(0, target_cups)
	_last_done = clampi(done, 0, _target_cups)

	_base_awarded_done = clampi(maxi(_last_done, int(saved.get("base_awarded_done", _last_done))), 0, _target_cups)
	_combo_points = maxi(0, int(saved.get("combo_points", 0)))
	_finalized = false
	_final_iq = initial_iq()
	_guarantee_triggered = false
	if enabled or was_enabled:
		var reason: String = "新局/重开重置"
		if not saved.is_empty() or done > 0:
			reason = "续局恢复（已计基础分列数=%d，累计combo分=%d）" % [_base_awarded_done, _combo_points]
		_log_change(before, reason)


func sync_done(done: int) -> void :
	_last_done = clampi(done, 0, _target_cups)


func on_move(done: int, combos: Array[int]) -> void :
	if not enabled or _finalized:
		return
	var before: float = value()
	var previous_base_done: int = _base_awarded_done
	var reasons: Array[String] = []
	var current_done: int = clampi(done, 0, _target_cups)
	var new_cups: int = maxi(0, current_done - _last_done)
	_last_done = current_done
	_base_awarded_done = maxi(_base_awarded_done, current_done)
	var awarded_cups: int = _base_awarded_done - previous_base_done
	if awarded_cups > 0:
		var per_cup: float = BASE_POINTS / float(_target_cups)
		reasons.append("消除%d列 +%s（每列+%s）" % [awarded_cups, str(per_cup * awarded_cups), str(per_cup)])

	for i: int in mini(new_cups, combos.size()):
		var bonus: int = combo_bonus(combos[i])
		_combo_points += bonus
		if bonus > 0:
			reasons.append("combo*%d +%d" % [combos[i], bonus])
	_log_change(before, "；".join(reasons))


static func combo_bonus(streak: int) -> int:
	if streak < 2:
		return 0
	if streak <= 3:
		return 3
	return 4


func value() -> float:
	if _finalized:
		return _final_iq
	var base: float = BASE_POINTS * float(_base_awarded_done) / float(_target_cups) if _target_cups > 0 else 0.0
	return initial_iq() + base + float(_combo_points)


func initial_iq() -> float:
	return BOOSTED_INITIAL_IQ if score_boost_enabled else INITIAL_IQ


func genius_iq() -> float:
	return BOOSTED_GENIUS_IQ if score_boost_enabled else GENIUS_IQ


func _log_change(before: float, reason: String) -> void :
	var after: float = value()
	if after == before:
		return
	var delta: float = after - before
	SortLogger.info("[IQ] %s | 总变化=%s%s | 变化前=%s -> 变化后=%s" % [
		reason, "+" if delta > 0.0 else "", str(delta), str(before), str(after)])


func snapshot() -> Dictionary:
	return {"enabled": enabled, "score_boost_enabled": score_boost_enabled, 
		"s_grade_guarantee": s_grade_guarantee, 
		"base_awarded_done": _base_awarded_done, "combo_points": _combo_points}


func restore_completion(saved: Dictionary) -> void :
	var before: float = value()
	_final_iq = float(saved["final_iq"])
	_guarantee_triggered = bool(saved.get("guarantee_triggered", false))
	_finalized = true
	if enabled:
		_log_change(before, "恢复已保存的通关结算%s" % ["（含通关保底）" if _guarantee_triggered else ""])



func finalize(used_prop: bool, time_percentile: float, hard: bool, 
		rounds_since_guarantee: int, random_iq: Callable = Callable(), step_percentile: float = -1.0) -> Dictionary:
	if not _finalized:
		var before: float = value()
		_final_iq = before
		var grade_met: bool = maxf(time_percentile, step_percentile) >= 80.0 if s_grade_guarantee else time_percentile >= 60.0
		_guarantee_triggered = enabled and _last_done == _target_cups and _final_iq < genius_iq()\
		and not used_prop and grade_met\
		and (s_grade_guarantee or hard or rounds_since_guarantee >= GUARANTEE_INTERVAL)
		if _guarantee_triggered:
			var minimum: int = int(genius_iq())
			var maximum: int = BOOSTED_GUARANTEE_MAX if score_boost_enabled else GUARANTEE_MAX
			var roll: int = int(random_iq.call()) if random_iq.is_valid() else randi_range(minimum, maximum)
			_final_iq = float(clampi(roll, minimum, maximum))
		_finalized = true
		if _guarantee_triggered:
			_log_change(before, "通关保底（%s，未使用道具，时间百分位=%s，步数百分位=%s，保底IQ=%s）" % [
				"S档免间隔" if s_grade_guarantee else ("困难关" if hard else "距上次保底已通关%d局" % rounds_since_guarantee), 
				str(time_percentile), str(step_percentile), str(_final_iq)])
	return {"participated": enabled, "guarantee_triggered": _guarantee_triggered, "final_iq": _final_iq}
