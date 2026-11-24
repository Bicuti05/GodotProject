class_name IqScoreBoostConfig
extends AbConfigBase


const VALUE_CONTROL: int = 0
const VALUE_A_GRADE_GUARANTEE: int = 1
const VALUE_S_GRADE_GUARANTEE: int = 2


func _init() -> void :
	key = "iq_score_boost"
	version = "1.0.10"
	default_value = VALUE_CONTROL
	group_count = 3
	timing = ABManager.TIMING_IQ_SCORE_BOOST



func _fetch_from_sdk() -> int:
	match ABManager.get_ab_string(key, ""):
		"exp_1":
			return VALUE_A_GRADE_GUARANTEE
		"exp_2":
			return VALUE_S_GRADE_GUARANTEE
	return VALUE_CONTROL


func is_score_boost_enabled() -> bool:
	return value() in [VALUE_A_GRADE_GUARANTEE, VALUE_S_GRADE_GUARANTEE]


func should_use_s_grade_guarantee() -> bool:
	return value() == VALUE_S_GRADE_GUARANTEE


func cheat_label() -> String:
	return "IQ提分 (0=现状 1=A档间隔保底 2=S档免间隔保底)"
