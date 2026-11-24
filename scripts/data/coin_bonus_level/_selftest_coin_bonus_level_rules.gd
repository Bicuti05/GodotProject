extends Node

const RULES = preload("res://scripts/data/coin_bonus_level/coin_bonus_level_rules.gd")
var _checks: int = 0
var _failures: int = 0

func _ready() -> void :
	call_deferred("_run")

func _check(value: bool, label: String) -> void :
	_checks += 1
	if not value:
		_failures += 1
		printerr("COIN_BONUS FAIL: ", label)

func _run() -> void :
	_test_rules()
	print("COIN_BONUS %s checks=%d" % ["PASS" if _failures == 0 else "FAIL", _checks])
	get_tree().quit(0 if _failures == 0 else 1)

func _test_rules() -> void :
	var custom: Dictionary = RULES.parse_rule("{\"mode\":\"hard\",\"every\":7,\"max_per_day\":9}")
	_check(custom == {"mode": "hard", "every": 7, "max_per_day": 9}, "arbitrary valid structure")
	for raw: String in ["default", "", "{}", "[]", "{bad}", "{\"mode\":\"normal\",\"every\":3,\"max_per_day\":4}", 
		"{\"mode\":\"all\",\"every\":0,\"max_per_day\":4}", "{\"mode\":\"all\",\"every\":-1,\"max_per_day\":4}", 
		"{\"mode\":\"all\",\"every\":1.5,\"max_per_day\":4}", "{\"mode\":\"all\",\"every\":true,\"max_per_day\":4}", 
		"{\"mode\":\"all\",\"every\":\"3\",\"max_per_day\":4}", "{\"mode\":\"all\",\"every\":3,\"max_per_day\":0}", 
		"{\"mode\":\"all\",\"every\":3}", "{\"mode\":\"all\",\"every\":1e999,\"max_per_day\":4}"]:
		_check(RULES.parse_rule(raw).is_empty(), "reject " + raw)
	_test_min_level()
	var state: Dictionary = {}
	var doubles: Array[int] = []
	for level: int in range(1, 34):
		var before: Dictionary = state.duplicate(true)
		var assignment: Dictionary = RULES.preview(state, "2030-01-01", level, "normal", RULES.ALL_PRESET)
		_check(state == before, "readonly home preview")
		state = RULES.enter(state, assignment)
		_check(RULES.enter(state, assignment) == state, "same level enters once")
		if assignment.double_coins:
			doubles.append(level)
		state = RULES.complete(state, assignment, level)
		_check(RULES.complete(state, assignment, level) == state, "completion once")
	_check(doubles == [13, 17, 21, 25], "N=3: first eligible13, N intervening, daily cap4")
	state = {}
	doubles.clear()
	var hard_index: int = 0
	for level: int in range(1, 29):
		var difficulty: String = ["normal", "hard", "super_hard", "hard"][level % 4]
		if level >= RULES.MIN_LEVEL and difficulty == "hard":
			hard_index += 1
		var assignment: Dictionary = RULES.preview(state, "2030-01-01", level, difficulty, RULES.HARD_PRESET)
		state = RULES.enter(state, assignment)
		if assignment.double_coins:
			doubles.append(hard_index)
		state = RULES.complete(state, assignment, level)
	_check(doubles == [1, 4, 7], "exact Hard only, N=2, cap3")
	var frozen: Dictionary = RULES.preview({}, "2030-01-01", 30, "hard", RULES.HARD_PRESET)
	state = RULES.enter({}, frozen)
	_check(int(state.rewarded) == 0, "failed attempts do not consume cap")
	_check(RULES.preview(state, "2030-01-02", 30, "normal", {}) == frozen, "same level frozen through midnight/config/difficulty")
	var next: Dictionary = RULES.preview(state, "2030-01-02", 31, "hard", RULES.HARD_PRESET)
	_check(next.double_coins and next.hard_index == 1, "new day first eligible")
	state = RULES.enter(state, next)
	state = RULES.complete(state, frozen, 30)
	_check(int(state.rewarded) == 0, "old day reward does not consume new cap")
	_check(RULES.preview({}, "2030-01-01", 13, "normal", {}, true).expose, "control union all candidate")
	var control_state: Dictionary = {}
	var c1: Dictionary = RULES.preview(control_state, "2030-01-01", 13, "normal", {}, true)
	control_state = RULES.enter(control_state, c1)
	var c2: Dictionary = RULES.preview(control_state, "2030-01-01", 14, "hard", {}, true)
	_check(c2.expose and c2.hard_candidate and not c2.all_candidate, "control union hard candidate")
	_check( not RULES.preview({}, "2030-01-01", 13, "normal", {}, false).expose, "missing source not control exposure")

func _test_min_level() -> void :
	for rule: Dictionary in [RULES.ALL_PRESET, RULES.HARD_PRESET, {}]:
		var state: Dictionary = {}
		for level: int in range(1, RULES.MIN_LEVEL):
			var assignment: Dictionary = RULES.preview(state, "2030-01-01", level, "hard", rule, rule.is_empty())
			_check( not assignment.double_coins and not assignment.expose and not assignment.all_candidate
				and not assignment.hard_candidate, "pre13 no double or candidate exposure")
			state = RULES.enter(state, assignment)
			state = RULES.complete(state, assignment, level)
			_check(state.all_count == 0 and state.hard_count == 0 and state.rewarded == 0
				and state.control_all_rewarded == 0 and state.control_hard_rewarded == 0, "pre13 no interval or quota")
		var first: Dictionary = RULES.preview(state, "2030-01-01", 13, "hard", rule, rule.is_empty())
		_check(first.all_index == 1 and first.hard_index == 1 and first.expose
			and first.double_coins == not rule.is_empty(), "12 to13 first eligible")
	var hard_state: Dictionary = {}
	for level: int in [13, 14]:
		var normal: Dictionary = RULES.preview(hard_state, "2030-01-01", level, "normal", RULES.HARD_PRESET)
		_check( not normal.double_coins and normal.hard_index == 0, "hard mode skips eligible normal")
		hard_state = RULES.enter(hard_state, normal)
	_check(RULES.preview(hard_state, "2030-01-01", 15, "hard", RULES.HARD_PRESET).double_coins, "first Hard after13 doubles")
	var legacy: Dictionary = {"level": 12, "date": "2030-01-01", "rule": RULES.ALL_PRESET, 
		"double_coins": true, "expose": true, "all_index": 1, "hard_index": 0}
	var legacy_state: Dictionary = RULES.enter({}, legacy)
	_check(RULES.preview(legacy_state, "2030-01-02", 12, "normal", {}) == legacy, "pre13 saved double promise preserved")
	_check(RULES.complete(legacy_state, legacy, 12).rewarded == 1, "pre13 saved double claim preserved")
