class_name RankDebugPage
extends PageScene

@onready var _status: Label = $Panel / Margin / Rows / Status

func _on_show(_params: Dictionary = {}) -> void :
	if OS.has_feature("rel"):
		visible = false
		return
	RankManager.ensure_profile()
	RankManager.ensure_season()
	_refresh()

func _refresh() -> void :
	var snap: RankSnapshot = RankManager.get_current_snapshot()
	_status.text = "第%d关 / 段位%d / 第%d名 / 积分%d\n剩余%s" % [UserState.get_current_level(), snap.start_tier, snap.my_rank_pos, snap.my_collect_num, RankManager.format_remaining(RankManager.get_remain_seconds())]

func _on_add_pressed() -> void :
	RankManager.cheat_adjust_collect_num(100)
	_refresh()

func _on_subtract_pressed() -> void :
	RankManager.cheat_adjust_collect_num(-100)
	_refresh()

func _on_tier_selected(index: int) -> void :
	RankManager.cheat_set_tier(index + 1)
	_refresh()

func _on_countdown_pressed() -> void :
	RankManager.cheat_set_remaining_seconds(5)
	_refresh()
	_close()

func _on_rank_pressed() -> void :
	_close()
	await SceneManager.warm_page_threaded("rank")
	SceneManager.show_page("rank")

func _on_intro_pressed() -> void :
	_close()
	await SceneManager.warm_page_threaded("rank_introduction")
	SceneManager.show_dlg("rank_introduction")

func _on_close_pressed() -> void :
	_close()

func _on_back_request() -> void :
	_close()

func _close() -> void :
	SceneManager.hide_dlg("rank_debug")
