class_name RankRoundTracker
extends RefCounted

signal presentation_stage_changed(stage: String)
var _motion_preview: bool = false

var season_id: String = ""
var collectible_index: int = -1
var rank_before: int = 0
var score_before: int = 0
var delta: int = 0
var committed: bool = false
var applied: bool = false
var score_after: int = 0
var awarded: int = 0
var _eligible: bool = false
var _playing: bool = false
var _presented: bool = false
var _bar: RankCollectBar
var _fly: RankCollectFlyLayer
var _generation: int = 0
var _texture: Texture2D

func begin(restore: Dictionary, count: int, bar: RankCollectBar, fly: RankCollectFlyLayer, round_id: String = "") -> void :
	cancel()
	_motion_preview = false
	_bar = bar
	_fly = fly
	season_id = ""
	collectible_index = -1
	delta = count
	committed = false
	applied = false
	awarded = 0
	score_after = 0
	_presented = false
	_texture = null
	rank_before = 0
	score_before = 0
	_eligible = false
	if not RankManager.is_unlocked():
		return
	var saved: Dictionary = restore.get("rank_round", {})
	var entity: Dictionary = UserState.get_rank_current_entity()

	collectible_index = RankManager.get_collectible_index()
	var update_activity: bool = RankManager.is_update_activity(entity)
	var saved_season_id: String = String(saved.get("season_id", ""))
	if not saved.is_empty() and ( not update_activity or saved_season_id == String(entity.get("event_id", ""))):
		season_id = String(saved.get("season_id", ""))
		rank_before = int(saved.get("rank_before", 0))
		score_before = int(saved.get("score_before", 0))
	elif RankManager.is_valid_rank_in_game():
		season_id = String(entity.get("event_id", ""))
		RankManager.invalidate_snapshot()
		rank_before = RankManager.get_my_rank_pos()
		score_before = RankManager.get_collect_num()
	_eligible = not season_id.is_empty() and season_id == String(entity.get("event_id", ""))
	if _eligible and update_activity:

		RankManager.prepare_update_round(round_id, count)
		RankManager.invalidate_snapshot()
		rank_before = RankManager.get_my_rank_pos()
		score_before = RankManager.get_collect_num()
	if _eligible:
		var pool: PackedScene = load("res://scripts/gameplay/rank/view/rank_collect_element_pool.tscn")
		var node: RankCollectElementPool = pool.instantiate()
		_texture = node.get_texture_for_index(collectible_index)
		node.free()
		_bar.bind_element(_texture)
		_bar.set_count(score_before)

func snapshot() -> Dictionary:
	return {"season_id": season_id, "rank_before": rank_before, "score_before": score_before, 
		"collectible_index": collectible_index}

func is_collectible_activity() -> bool:
	return _eligible and collectible_index >= 0 and RankManager.is_valid_rank_in_game()

func commit(round_id: String) -> bool:
	if committed:
		return true
	var result: Dictionary = RankManager.commit_round_score(delta, rank_before, round_id, season_id)
	committed = bool(result.get("ok", false))
	applied = bool(result.get("applied", false))
	if applied:
		awarded = int(result.get("my_delta", delta))
		score_after = RankManager.get_collect_num()
	return committed




func will_present_collect() -> bool:
	return applied and _texture != null and _eligible and not _presented and not _playing


func play_collect(owner: Node, source_provider: Callable, burst_collect: bool = false, 
		burst_motion: Dictionary = {}) -> bool:
	if not applied or _texture == null or not _eligible or _presented:
		return true
	if _playing:
		return false
	_playing = true
	var generation: int = _generation
	var active: Callable = func() -> bool:
		return generation == _generation and is_instance_valid(owner) and owner.visible
	var before: int = score_after - awarded
	_bar.set_count(before)
	if _motion_preview:
		presentation_stage_changed.emit("临时收集栏入场")
	if not await _bar.show_bar() or not active.call():
		return _cancel_if_current(generation)
	var fly_count: int = mini(awarded, RankCollectFlyLayer.MAX_FLY_ITEMS) if burst_collect else awarded
	var shown: Dictionary = {"arrived": 0}
	var callback: Callable = func(_index: int) -> void :
		if not active.call():
			return
		shown.arrived = int(shown.arrived) + 1
		var collected: int = int(shown.arrived)
		if burst_collect:
			collected = awarded * int(shown.arrived) / fly_count
		_bar.set_count(before + collected)
		_bar.punch_icon()
		AudioManager.play_sfx(&"rank_collect")
	_fly.item_arrived.connect(callback)
	var dst_provider: Callable = func() -> Vector2: return _bar.get_icon_global_rect().get_center()
	var completed: bool = false
	if _motion_preview:
		presentation_stage_changed.emit("礼盒逐枚飞出 → 图标回弹与到账")
	if burst_collect:
		completed = await _fly.play_from_source(fly_count, _texture, source_provider, 
			dst_provider, active, burst_motion)
	else:
		completed = await _fly.play_from_sources(awarded, _texture, source_provider, dst_provider, active)
	if _fly.item_arrived.is_connected(callback):
		_fly.item_arrived.disconnect(callback)
	if not completed or not active.call():
		return _cancel_if_current(generation)
	_bar.set_count(score_after)
	if _motion_preview:
		presentation_stage_changed.emit("收集完成 → 增量文字上浮")
	if not await _bar.float_delta(awarded) or not active.call():
		return _cancel_if_current(generation)
	if _motion_preview:
		presentation_stage_changed.emit("临时收集栏退场")
	if not await _bar.hide_bar() or not active.call():
		return _cancel_if_current(generation)
	_presented = true
	_playing = false
	return true

func _cancel_if_current(generation: int) -> bool:
	if generation == _generation:
		cancel()
	return false

func cancel() -> void :
	_generation += 1
	_playing = false
	if is_instance_valid(_bar):
		_bar.reset_now()
	if is_instance_valid(_fly):
		_fly.cancel_all()



func prepare_motion_preview(count: int, before: int, index: int, texture: Texture2D, 
		bar: RankCollectBar, fly: RankCollectFlyLayer) -> void :
	cancel()
	_motion_preview = true
	_bar = bar
	_fly = fly
	season_id = "motion-preview"
	collectible_index = index
	delta = count
	awarded = count
	score_before = before
	score_after = before + count
	committed = false
	applied = true
	_eligible = true
	_presented = false
	_texture = texture
	_bar.bind_element(texture)
	_bar.set_count(before)
