class_name DailyFirstWinCheckinConfig
extends AbConfigBase


const VALUE_DISABLED: int = 0
const VALUE_REWARDS_300_500_1000: int = 1
const VALUE_REWARDS_0_800_1000: int = 2

func _init() -> void :
	key = "daily_first_win_checkin"
	version = "1.0.8"
	default_value = VALUE_DISABLED
	group_count = 3
	timing = ABManager.TIMING_DAILY_FIRST_WIN_CHECKIN

func _fetch_from_sdk() -> int:
	match ABManager.get_ab_string(key, ""):
		"300_500_1000": return VALUE_REWARDS_300_500_1000
		"0_800_1000": return VALUE_REWARDS_0_800_1000
	return VALUE_DISABLED

func is_checkin_enabled() -> bool:
	return value() in [VALUE_REWARDS_300_500_1000, VALUE_REWARDS_0_800_1000]

func reward_coins_for_day(day: int) -> int:
	return int(rewards_for_group(value()).get(day, 0))


func checkin_policy() -> Dictionary:
	var group: int = value()
	return {"group": group, "enabled": group in [VALUE_REWARDS_300_500_1000, VALUE_REWARDS_0_800_1000], 
		"rewards": rewards_for_group(group)}

static func rewards_for_group(group: int) -> Dictionary:
	match group:
		VALUE_REWARDS_300_500_1000: return {2: 300, 4: 500, 7: 1000}
		VALUE_REWARDS_0_800_1000: return {4: 800, 7: 1000}
	return {}

func cheat_label() -> String:
	return "每日首胜打卡 (0=关闭 1=300/500/1000 2=0/800/1000)"
