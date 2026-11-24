class_name LevelTargetCoinsConfig
extends AbConfigBase


const VALUE_ORIGINAL_REWARD: int = 0
const VALUE_REDUCED_REWARD: int = 1
const ORIGINAL_COINS: int = 10
const REDUCED_COINS: int = 5


func _init() -> void :
	key = "level_target_coins"
	version = "1.0.10"
	default_value = VALUE_ORIGINAL_REWARD
	timing = ABManager.TIMING_LEVEL_TARGET_COINS



func _fetch_from_sdk() -> int:
	return VALUE_REDUCED_REWARD if ABManager.get_ab_int(key, ORIGINAL_COINS) == REDUCED_COINS\
	else VALUE_ORIGINAL_REWARD


func is_reduced_reward_enabled() -> bool:
	return value() == VALUE_REDUCED_REWARD


func coins_per_target() -> int:
	return REDUCED_COINS if is_reduced_reward_enabled() else ORIGINAL_COINS


func cheat_label() -> String:
	return "关卡目标金币 (0=每盆10金币 1=每盆5金币)"


func cheat_value_str() -> String:
	return "%d（每盆%d金币）" % [value(), coins_per_target()]
