class_name DailyCheckinRules
extends RefCounted

const UNLOCK_LEVEL: int = 15
const CYCLE_DAYS: int = 7


static func date_serial(date: Dictionary) -> int:
	var year: int = int(date["year"])
	var month: int = int(date["month"])
	var day: int = int(date["day"])
	if month <= 2:
		year -= 1
	var era: int = year / 400
	var year_of_era: int = year - era * 400
	var adjusted_month: int = month - 3 if month > 2 else month + 9
	var day_of_year: int = (153 * adjusted_month + 2) / 5 + day - 1
	return era * 146097 + year_of_era * 365 + year_of_era / 4 - year_of_era / 100 + day_of_year

static func completion(state: Dictionary, serial: int, date: String, unlocked: bool, 
		policy: Dictionary, settlement_id: String) -> Dictionary:
	if not unlocked or serial <= int(state.get("last_win_serial", 0)):
		return {}
	var after: Dictionary = state.duplicate(true)
	after["unlocked"] = true
	after["last_win_serial"] = serial
	after["last_settlement_id"] = settlement_id
	var enabled: bool = bool(policy["enabled"])
	var rewards: Dictionary = policy["rewards"]
	var day: int = 0
	var before_days: int = 0
	if enabled:
		if serial == int(state.get("last_checkin_serial", 0)) + 1:
			before_days = int(state.get("completed_days", 0))
		day = before_days + 1 if before_days < CYCLE_DAYS else 1
		if day == 1:
			before_days = 0
		after["last_checkin_serial"] = serial
		after["completed_days"] = day
	return {"state": after, "date": date, "date_serial": serial, "settlement_id": settlement_id, 
		"enabled": enabled, "group": int(policy["group"]), "day_index": day, "completed_days_before": before_days, 
		"reward_coins": int(rewards.get(day, 0)) if enabled else 0, "reward_by_day": rewards.duplicate()}
