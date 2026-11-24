class_name StreakCopy
extends RefCounted







static func pick_lines(count: int, percentile: float = -1.0, personal_best: bool = false, last_key: String = "") -> Dictionary:

	var valid_percentile: bool = percentile >= 60.0 and percentile <= 99.0
	var praise: Array[String] = [
		"GAME_STREAK_SUBTITLE", "GAME_STREAK_ON_FIRE", "GAME_STREAK_BLOOMING", 
		"GAME_STREAK_WHAT_A_STREAK", "GAME_STREAK_FLOW", "GAME_STREAK_CHAIN", 
		"GAME_STREAK_GROWING", "GAME_STREAK_BRILLIANT", "GAME_STREAK_PETAL_POWER", 
		"GAME_STREAK_RHYTHM", "GAME_STREAK_LOOK_AT_YOU", "GAME_STREAK_NEXT_WIN", 
	]
	if count >= 10:
		praise.append_array(["GAME_STREAK_UNSTOPPABLE", "GAME_STREAK_REMEMBER", "GAME_STREAK_EASY"])
	var pools: Array = [praise]

	var last_category: String = subtitle_category(last_key)
	if personal_best and last_category != "record":
		var record: Array[String] = [
			"GAME_STREAK_PERSONAL_BEST", "GAME_STREAK_BEST_YET", "GAME_STREAK_OUTDONE", 
			"GAME_STREAK_NEW_HIGH", "GAME_STREAK_RAISED_BAR", "GAME_STREAK_BEST_BLOOM", 
			"GAME_STREAK_RECORD_BROKEN", 
		]
		if valid_percentile and percentile >= 90.0:
			record.append("GAME_STREAK_RECORD_TOP")
		pools.append(record)
	if valid_percentile and last_category != "ranking":
		var ranking: Array[String] = [
			"GAME_STREAK_AHEAD", "GAME_STREAK_TOP", "GAME_STREAK_TOP_ELITE", 
			"GAME_STREAK_RANK_BEATS", "GAME_STREAK_RANK_WELL_PLAYED", 
			"GAME_STREAK_RANK_ROLL", "GAME_STREAK_RANK_BLOOM", 
		]
		pools.append(ranking)
	var keys: Array[String] = pools[randi_range(0, pools.size() - 1)]
	keys.erase(last_key)

	if not last_key.is_empty():
		var previous_text: String = localized_subtitle(last_key)
		for i: int in range(keys.size() - 1, -1, -1):
			if localized_subtitle(keys[i]) == previous_text:
				keys.remove_at(i)
	var key: String = keys[randi_range(0, keys.size() - 1)]
	var subtitle: String = localized_subtitle(key)
	if key in ["GAME_STREAK_AHEAD", "GAME_STREAK_RANK_BEATS"]:
		subtitle = subtitle % int(percentile)
	elif key in [
		"GAME_STREAK_TOP", "GAME_STREAK_TOP_ELITE", "GAME_STREAK_RECORD_TOP", 
		"GAME_STREAK_RANK_WELL_PLAYED", "GAME_STREAK_RANK_ROLL", "GAME_STREAK_RANK_BLOOM", 
	]:
		subtitle = subtitle % (100 - int(percentile))
	return {
		"lines": PackedStringArray([TranslationServer.translate("GAME_STREAK_TITLE") % maxi(2, count), subtitle]), 
		"key": key, 
	}


static func subtitle_category(key: String) -> String:
	if key in [
		"GAME_STREAK_PERSONAL_BEST", "GAME_STREAK_BEST_YET", "GAME_STREAK_OUTDONE", 
		"GAME_STREAK_RECORD_TOP", "GAME_STREAK_NEW_HIGH", "GAME_STREAK_RAISED_BAR", 
		"GAME_STREAK_BEST_BLOOM", "GAME_STREAK_RECORD_BROKEN", 
	]:
		return "record"
	if key in [
		"GAME_STREAK_AHEAD", "GAME_STREAK_TOP", "GAME_STREAK_TOP_ELITE", 
		"GAME_STREAK_RANK_BEATS", "GAME_STREAK_RANK_WELL_PLAYED", 
		"GAME_STREAK_RANK_ROLL", "GAME_STREAK_RANK_BLOOM", 
	]:
		return "ranking"
	return "praise"


static func localized_subtitle(key: String) -> String:
	var translated: String = TranslationServer.translate(key)
	if translated != key and not translated.is_empty():
		return translated
	var english: Dictionary = {
		"GAME_STREAK_SUBTITLE": "You're on a roll!", 
		"GAME_STREAK_BLOOMING": "Keep blooming!", 
		"GAME_STREAK_WHAT_A_STREAK": "What a streak!", 
		"GAME_STREAK_UNSTOPPABLE": "Simply unstoppable!", 
		"GAME_STREAK_AHEAD": "Ahead of %d%% of players!", 
		"GAME_STREAK_TOP": "Top %d%% in win streaks!", 
		"GAME_STREAK_ON_FIRE": "You're on fire!", 
		"GAME_STREAK_REMEMBER": "A streak to remember!", 
		"GAME_STREAK_EASY": "You make it look easy!", 
		"GAME_STREAK_PERSONAL_BEST": "A new personal best!", 
		"GAME_STREAK_BEST_YET": "Your best streak yet!", 
		"GAME_STREAK_OUTDONE": "You've outdone yourself!", 
		"GAME_STREAK_TOP_ELITE": "Among the top %d%%!", 
		"GAME_STREAK_RECORD_TOP": "A new best! Top %d%%!", 
		"GAME_STREAK_FLOW": "You've found your flow!", 
		"GAME_STREAK_CHAIN": "One win leads to another!", 
		"GAME_STREAK_GROWING": "Watch your streak grow!", 
		"GAME_STREAK_BRILLIANT": "Brilliant sorting!", 
		"GAME_STREAK_PETAL_POWER": "Petal power!", 
		"GAME_STREAK_RHYTHM": "Keep that winning rhythm!", 
		"GAME_STREAK_LOOK_AT_YOU": "Look at you go!", 
		"GAME_STREAK_NEXT_WIN": "Ready for another win?", 
		"GAME_STREAK_NEW_HIGH": "A new high for you!", 
		"GAME_STREAK_RAISED_BAR": "You've raised your own bar!", 
		"GAME_STREAK_BEST_BLOOM": "Your best bloom yet!", 
		"GAME_STREAK_RECORD_BROKEN": "Personal record broken!", 
		"GAME_STREAK_RANK_BEATS": "Your streak beats %d%%!", 
		"GAME_STREAK_RANK_WELL_PLAYED": "Top %d%%! Well played!", 
		"GAME_STREAK_RANK_ROLL": "Top %d%% and on a roll!", 
		"GAME_STREAK_RANK_BLOOM": "Blooming in the top %d%%!", 
	}
	return String(english[key])
