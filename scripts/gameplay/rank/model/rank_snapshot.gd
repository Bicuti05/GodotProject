class_name RankSnapshot
extends RefCounted


var event_id: String = ""
var start_time: int = 0
var end_time: int = 0
var is_ended: bool = false
var remain_seconds: int = 0

var my_collect_num: int = 0
var my_rank_pos: int = -1
var start_tier: int = 1
var end_tier: int = 1
var participant_count: int = 0

var upgrade_end_rank: int = 0
var downgrade_start_rank: int = 0

var settle_state: String = "not_settled"
var has_receive_bonus: bool = false
var reward_hint: int = 0
var reward_coin: int = 0
var has_guide: bool = false
var rows: Array[Dictionary] = []


func is_valid() -> bool:
	return not event_id.is_empty() and not rows.is_empty()


func get_my_row() -> Dictionary:
	for row in rows:
		if row.get("is_me", false):
			return row
	return {}


func get_tier_direction() -> int:
	if my_rank_pos < 1:
		return 0
	if upgrade_end_rank > 0 and my_rank_pos <= upgrade_end_rank:
		return 1
	if downgrade_start_rank > 0 and my_rank_pos >= downgrade_start_rank:
		return -1
	return 0
