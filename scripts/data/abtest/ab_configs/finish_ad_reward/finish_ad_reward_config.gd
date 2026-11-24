class_name FinishAdRewardConfig
extends AbConfigBase


const VALUE_CONTROL: int = 0
const VALUE_EXPERIMENT: int = 1

func _init() -> void :
	key = "finish_ad_reward2.0"
	version = "1.0.7"
	default_value = VALUE_CONTROL
	timing = ABManager.TIMING_FINISH_AD_REWARD

func _fetch_from_sdk() -> int:
	var raw_value: String = ABManager.get_ab_string(key, "no")
	return VALUE_EXPERIMENT if raw_value == "yes" else VALUE_CONTROL

func is_reward_enabled() -> bool:
	return value() == VALUE_EXPERIMENT

func cheat_label() -> String:
	return "困难／超级困难关完成页广告奖励 (0=关闭 1=开启)"
