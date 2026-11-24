class_name ZtimeTag
extends RefCounted







const TAG_KEY: = "ztime_v1"

const START_AT_LEVEL_NUM: = 2






static func on_level_completed(won_level: int, targets: int, capacity: int) -> void :
	on_level_completed_scaled(won_level, targets * capacity)



static func on_level_completed_scaled(won_level: int, normalizer: int) -> void :
	if won_level < START_AT_LEVEL_NUM:
		return
	var st: Dictionary = LevelManager.get_ztime_stats(won_level)
	if st.is_empty():
		SortLogger.error("[ZtimeTag] 关 %d 没有存档行，不打标签" % won_level)
		return
	var play_time_ms: int = int(st["play_time_ms"])
	var hint_used: int = int(st["hint_used"])
	var undo_used: int = int(st["undo_used"])
	var rope_used: int = int(st["rope_used"])
	var dead_times: int = int(st["dead_times"])
	var raw: float = ZtimeCalc.raw_score_scaled(play_time_ms, hint_used, undo_used, rope_used, 
		dead_times, normalizer)
	var value: int = ZtimeCalc.bucket(raw)

	var sec: float = float(play_time_ms) / 1000.0
	var hint_part: float = hint_used * ZtimeCalc.HINT_WEIGHT
	var undo_part: float = undo_used * ZtimeCalc.UNDO_WEIGHT
	var rope_part: float = rope_used * ZtimeCalc.ROPE_WEIGHT
	var dead_part: float = dead_times * ZtimeCalc.DEAD_WEIGHT
	var total: float = sec + hint_part + undo_part + rope_part + dead_part
	SortLogger.info(("[ZtimeTag] 关 %d 结算：(用时 %.2fs + hint %d×%d=%d + 撤回 %d×%d=%d + 绳子 %d×%d=%d"
		+ " + 死亡 %d×%d=%d) = %.2f / 规模 %d"
		+ " = 原值 %.2f → 档位 %d") % [
		won_level, sec, 
		hint_used, int(ZtimeCalc.HINT_WEIGHT), int(hint_part), 
		undo_used, int(ZtimeCalc.UNDO_WEIGHT), int(undo_part), 
		rope_used, int(ZtimeCalc.ROPE_WEIGHT), int(rope_part), 
		dead_times, int(ZtimeCalc.DEAD_WEIGHT), int(dead_part), 
		total, normalizer, raw, value])
	UniKitManager.add_local_tag(TAG_KEY, str(value))
