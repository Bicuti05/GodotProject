extends Node



const SFX_POOL_SIZE: int = 12
const SILENT_DB: float = -80.0
const _BUTTON_SOUND_BOUND_META: StringName = &"_btn_sound_bound"


const MUSIC_STREAMS: Dictionary = {
	&"bgm1": "res://assets/audio/music/bgm1.mp3", 
	&"bgm2": "res://assets/audio/music/bgm2.mp3", 
	&"bgm3": "res://assets/audio/music/bgm3.mp3", 
}


const _BUTTON_CLICK_STREAM: AudioStream = preload("res://assets/audio/sfx/btn_click_2.mp3")
const _RESOURCE_CONSUME_BUDGET_USEC: int = 2000

const SFX_PATHS: Dictionary = {
	&"timed_endless_open": "res://assets/audio/sfx/special_level_banner_appear.mp3", 
	&"timed_endless_result": "res://assets/audio/sfx/juice_dead.mp3", 
	&"checkin_transform": "res://assets/audio/sfx/checkin_transform.mp3", 
	&"checkin_celebration_phrase": "res://assets/audio/sfx/checkin_celebration_phrase.mp3", 
	&"checkin_confetti": "res://assets/audio/sfx/checkin_confetti.mp3", 
	&"checkin_settle": "res://assets/audio/sfx/checkin_settle.mp3", 
	&"checkin_gift_open": "res://assets/audio/sfx/checkin_gift_open.mp3", 
	&"rank_promote": "res://assets/audio/sfx/rank_level_up.mp3", 
	&"rank_demote": "res://assets/audio/sfx/rank_level_down.mp3", 
	&"rank_unchanged": "res://assets/audio/sfx/rank_level_unchange.mp3", 
	&"rank_collect": "res://assets/audio/sfx/rank_collect.mp3", 
	&"rank_over_item_1": "res://assets/audio/sfx/rank_over_item_level_1.mp3", 
	&"rank_over_item_2": "res://assets/audio/sfx/rank_over_item_level_2.mp3", 
	&"rank_over_item_3": "res://assets/audio/sfx/rank_over_item_level_3.mp3", 
	&"rank_over_item_4": "res://assets/audio/sfx/rank_over_item_level_4.mp3", 
	&"rank_over_item_5": "res://assets/audio/sfx/rank_over_item_level_5.mp3", 
	&"rank_over_item_6": "res://assets/audio/sfx/rank_over_item_level_6.mp3", 
	&"rank_over_item_7": "res://assets/audio/sfx/rank_over_item_level_7.mp3", 
	&"rank_over_item_8": "res://assets/audio/sfx/rank_over_item_level_8.mp3", 
	&"rank_over_item_9": "res://assets/audio/sfx/rank_over_item_level_9.mp3", 
	&"rank_over_item_10": "res://assets/audio/sfx/rank_over_item_level_10.mp3", 
	&"rank_item_expand": "res://assets/audio/sfx/rank_item_exp1_expand.mp3", 
	&"rank_item_shrink": "res://assets/audio/sfx/rank_item_exp1_shrink.mp3", 
	&"rank_finish_rise": "res://assets/audio/sfx/rankfinish_rise_down.ogg", 
	&"iq_genius_feedback": "res://assets/audio/sfx/iq_genius_feedback.ogg", 
	&"rank_rise_begin": "res://assets/audio/sfx/rankfinish_rise_begin.ogg", 
	&"rank_rise_landed": "res://assets/audio/sfx/rank_rise_touch_target_rank.mp3", 
	&"rank_podium_landed": "res://assets/audio/sfx/rank_level_up.mp3", 
	&"rank_season_win": "res://assets/audio/sfx/rank_up_animation.mp3", 
	&"combo_nice": "res://assets/audio/sfx/combo_nice.mp3", 
	&"combo_great": "res://assets/audio/sfx/combo_great.mp3", 
	&"combo_excellent": "res://assets/audio/sfx/combo_excellent.mp3", 
	&"combo_amazing": "res://assets/audio/sfx/combo_amazing.mp3", 
	&"combo_incredible": "res://assets/audio/sfx/combo_incredible.mp3", 
	&"combo_unstoppable": "res://assets/audio/sfx/combo_unstoppable.mp3", 
	&"combo_legendary": "res://assets/audio/sfx/combo_legendary.mp3", 
	&"smart_move": "res://assets/audio/sfx/smart_move.mp3", 
	&"empty_rope_light": "res://assets/audio/sfx/empty_rope_light.mp3", 
	&"empty_rope_applaud": "res://assets/audio/sfx/empty_rope_applaud.mp3", 
	&"long_link_emoji_2": "res://assets/audio/sfx/PuzzleLinkEmoji2.mp3", 
	&"long_link_emoji_3": "res://assets/audio/sfx/PuzzleLinkEmoji3.mp3", 
	&"long_link_emoji_5": "res://assets/audio/sfx/PuzzleLinkEmoji5.mp3", 

	&"outerloop_pieces_unlock": "res://assets/audio/sfx/outerloop_pieces_unlock.mp3", 
	&"outerloop_chapter_bg_unlock": "res://assets/audio/sfx/outerloop_chapter_bg_unlock.mp3", 
	&"outerloop_chapter_bg_claim": "res://assets/audio/sfx/outerloop_chapter_bg_claim.mp3", 

	&"button_click": "res://assets/audio/sfx/btn_click_2.mp3", 
	&"move_rejected": "res://assets/audio/sfx/merge_reject.mp3", 
	&"level_complete": "res://assets/audio/sfx/game_completed.mp3", 
	&"level_complete_simple": "res://assets/audio/sfx/level_complete_simple.mp3", 
	&"level_complete_rich": "res://assets/audio/sfx/level_complete_rich.mp3", 
	&"special_challenge_chest_open": "res://assets/audio/sfx/special_challenge_chest_open.mp3", 
	&"special_challenge_chest_fly": "res://assets/audio/sfx/special_challenge_chest_fly.ogg", 
	&"bonus_pig_fly": "res://assets/audio/sfx/special_challenge_chest_fly.ogg", 
	&"bonus_pig_shatter": "res://assets/audio/sfx/bonus_pig_shatter.mp3", 
	&"bonus_hammer_swing": "res://assets/audio/sfx/bonus_hammer_swing.mp3", 
	&"prop_reward_arrive": "res://assets/audio/sfx/prop_reward_arrive.mp3", 
	&"bonus_coin_impact": "res://assets/audio/sfx/prop_reward_arrive.mp3", 
	&"special_challenge_banner_appear": "res://assets/audio/sfx/special_level_banner_appear.mp3", 
	&"bonus_level_banner_appear": "res://assets/audio/sfx/special_level_banner_appear.mp3", 
	&"coin_fly": "res://assets/audio/sfx/coin_fly.ogg", 
	&"finish_cart_appear": "res://assets/audio/sfx/finish_cart_appear.mp3", 
	&"finish_cart_appear_iterated": "res://assets/audio/sfx/finish_cart_appear_iterated.mp3", 
	&"finish_cart_exit": "res://assets/audio/sfx/finish_cart_exit.mp3", 
	&"finish_reward": "res://assets/audio/sfx/finish_reward.mp3", 
	&"finish_ad_reward_btn": "res://assets/audio/sfx/finish_ad_reward_btn_edited.mp3", 
	&"finish_data_time": "res://assets/audio/sfx/finish_data_time.ogg", 
	&"finish_data_steps": "res://assets/audio/sfx/finish_data_steps.ogg", 
	&"finish_data_streak": "res://assets/audio/sfx/finish_data_streak.ogg", 
	&"streak_celebration": "res://assets/audio/sfx/finish_data_streak.ogg", 
	&"juice_pick": "res://assets/audio/sfx/juice_pick.mp3", 
	&"juice_move": "res://assets/audio/sfx/juice_move.mp3", 
	&"juice_merge_set1": "res://assets/audio/sfx/juice_merge_set1.mp3", 
	&"juice_merge_set2": "res://assets/audio/sfx/juice_merge_set2.mp3", 
	&"juice_slam_1": "res://assets/audio/sfx/juice_slam_1.mp3", 
	&"juice_slam_2": "res://assets/audio/sfx/juice_slam_2.mp3", 
	&"juice_slam_3": "res://assets/audio/sfx/juice_slam_3.mp3", 
	&"juice_slam_4": "res://assets/audio/sfx/juice_slam_4.mp3", 
	&"juice_slam_5": "res://assets/audio/sfx/juice_slam_5.mp3", 
	&"juice_whoosh": "res://assets/audio/sfx/juice_whoosh.mp3", 
	&"combo_set1_level1": "res://assets/audio/sfx/combo_set1_level1.mp3", 
	&"combo_set1_level2": "res://assets/audio/sfx/combo_set1_level2.mp3", 
	&"combo_set1_level3": "res://assets/audio/sfx/combo_set1_level3.mp3", 
	&"combo_set1_level4": "res://assets/audio/sfx/combo_set1_level4.mp3", 
	&"combo_set1_level5": "res://assets/audio/sfx/combo_set1_level5.mp3", 
	&"combo_set1_level6": "res://assets/audio/sfx/combo_set1_level6.mp3", 
	&"combo_set1_level7": "res://assets/audio/sfx/combo_set1_level7.mp3", 
	&"combo_set1_level8": "res://assets/audio/sfx/combo_set1_level8.mp3", 
	&"juice_burst_set1": "res://assets/audio/sfx/juice_burst_set1.mp3", 
	&"juice_burst": "res://assets/audio/sfx/juice_burst.mp3", 
	&"juice_quota": "res://assets/audio/sfx/juice_quota.mp3", 
	&"juice_dead": "res://assets/audio/sfx/juice_dead.mp3", 
	&"wood_unlock": "res://assets/audio/sfx/wood_unlock.mp3", 
	&"wood_break": "res://assets/audio/sfx/wood_break.mp3", 
	&"ice_shatter": "res://assets/audio/sfx/ice_shatter.mp3", 
}


const SFX_CONFIG: Dictionary = {
	&"timed_endless_open": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"timed_endless_result": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"checkin_transform": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"checkin_celebration_phrase": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"checkin_confetti": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"checkin_settle": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"checkin_gift_open": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_promote": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_demote": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_unchanged": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_collect": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_over_item_1": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_over_item_2": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_over_item_3": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_over_item_4": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_over_item_5": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_over_item_6": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_over_item_7": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_over_item_8": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_over_item_9": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_over_item_10": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_item_expand": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_item_shrink": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_finish_rise": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"iq_genius_feedback": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_rise_begin": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_rise_landed": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_podium_landed": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"rank_season_win": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"combo_nice": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"combo_great": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"combo_excellent": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"combo_amazing": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"combo_incredible": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"combo_unstoppable": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"combo_legendary": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"smart_move": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"empty_rope_light": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"empty_rope_applaud": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"long_link_emoji_2": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"long_link_emoji_3": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"long_link_emoji_5": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 

	&"outerloop_pieces_unlock": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"outerloop_chapter_bg_unlock": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"outerloop_chapter_bg_claim": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 

	&"button_click": {"priority": 10, "max_concurrent": 4, "cooldown_msec": 35}, 
	&"move_rejected": {"priority": 40, "max_concurrent": 1, "cooldown_msec": 80}, 
	&"level_complete": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"level_complete_simple": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"level_complete_rich": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"special_challenge_chest_open": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"special_challenge_chest_fly": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"bonus_pig_fly": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"bonus_pig_shatter": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"bonus_hammer_swing": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"prop_reward_arrive": {"priority": 100, "max_concurrent": 6, "cooldown_msec": 0}, 
	&"bonus_coin_impact": {"priority": 100, "max_concurrent": 8, "cooldown_msec": 0}, 
	&"special_challenge_banner_appear": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"bonus_level_banner_appear": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"coin_fly": {"priority": 100, "max_concurrent": 5, "cooldown_msec": 0}, 
	&"finish_cart_appear": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"finish_cart_appear_iterated": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"finish_cart_exit": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"finish_reward": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"finish_ad_reward_btn": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"finish_data_time": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"finish_data_steps": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"finish_data_streak": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"streak_celebration": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 





	&"juice_pick": {"priority": 20, "max_concurrent": 4, "cooldown_msec": 0}, 
	&"juice_move": {"priority": 20, "max_concurrent": 4, "cooldown_msec": 0}, 
	&"juice_merge_set1": {"priority": 20, "max_concurrent": 4, "cooldown_msec": 0}, 
	&"juice_merge_set2": {"priority": 20, "max_concurrent": 4, "cooldown_msec": 0}, 
	&"juice_slam_1": {"priority": 20, "max_concurrent": 8, "cooldown_msec": 0}, 
	&"juice_slam_2": {"priority": 20, "max_concurrent": 8, "cooldown_msec": 0}, 
	&"juice_slam_3": {"priority": 20, "max_concurrent": 8, "cooldown_msec": 0}, 
	&"juice_slam_4": {"priority": 20, "max_concurrent": 8, "cooldown_msec": 0}, 
	&"juice_slam_5": {"priority": 20, "max_concurrent": 8, "cooldown_msec": 0}, 
	&"juice_whoosh": {"priority": 20, "max_concurrent": 2, "cooldown_msec": 0}, 
	&"combo_set1_level1": {"priority": 40, "max_concurrent": 3, "cooldown_msec": 0}, 
	&"combo_set1_level2": {"priority": 40, "max_concurrent": 3, "cooldown_msec": 0}, 
	&"combo_set1_level3": {"priority": 40, "max_concurrent": 3, "cooldown_msec": 0}, 
	&"combo_set1_level4": {"priority": 40, "max_concurrent": 3, "cooldown_msec": 0}, 
	&"combo_set1_level5": {"priority": 40, "max_concurrent": 3, "cooldown_msec": 0}, 
	&"combo_set1_level6": {"priority": 40, "max_concurrent": 3, "cooldown_msec": 0}, 
	&"combo_set1_level7": {"priority": 40, "max_concurrent": 3, "cooldown_msec": 0}, 
	&"combo_set1_level8": {"priority": 40, "max_concurrent": 3, "cooldown_msec": 0}, 
	&"juice_burst_set1": {"priority": 40, "max_concurrent": 3, "cooldown_msec": 0}, 
	&"juice_burst": {"priority": 40, "max_concurrent": 3, "cooldown_msec": 0}, 
	&"juice_quota": {"priority": 40, "max_concurrent": 3, "cooldown_msec": 0}, 
	&"juice_dead": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"wood_unlock": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"wood_break": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
	&"ice_shatter": {"priority": 100, "max_concurrent": 1, "cooldown_msec": 0}, 
}

@onready var _music_a: AudioStreamPlayer = $MusicA
@onready var _music_b: AudioStreamPlayer = $MusicB
@onready var _sfx_root: Node = $SfxPool

var _sfx_streams: Dictionary = {&"button_click": _BUTTON_CLICK_STREAM}
var _sfx_load_requests: Dictionary = {}
var _resource_request_usec: int = 0
var _warming_resources: bool = false
var _music_players: Array[AudioStreamPlayer] = []
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_ids: Array[StringName] = []
var _sfx_priorities: Array[int] = []
var _sfx_started_msec: Array[int] = []
var _last_played_msec: Dictionary = {}
var _missing_music_warned: Dictionary = {}
var _music_player_index: int = -1
var _music_id: StringName = &""
var _music_tween: Tween = null
var _music_streams: Dictionary = {}
var _music_load_requests: Dictionary = {}
var _music_playlist: Array[StringName] = []
var _music_playlist_index: int = 0
var _music_generation: int = 0
var _music_pause_reasons: Dictionary = {}
var _music_fade_sec: float = 0.3
var _music_loading: bool = false


func _ready() -> void :
	_music_players = [_music_a, _music_b]
	for index: int in _music_players.size():
		_music_players[index].finished.connect(_on_music_finished.bind(index))
	for child: Node in _sfx_root.get_children():
		var player: AudioStreamPlayer = child as AudioStreamPlayer
		if player == null:
			continue
		var index: int = _sfx_players.size()
		_sfx_players.append(player)
		_sfx_ids.append(&"")
		_sfx_priorities.append(0)
		_sfx_started_msec.append(0)
		player.finished.connect(_on_sfx_finished.bind(index))
	if _sfx_players.size() != SFX_POOL_SIZE:
		push_error("AudioManager: SFX 播放池应为 %d 路，实际为 %d 路" % [
			SFX_POOL_SIZE, _sfx_players.size()])
	UserState.audio_settings_changed.connect(_apply_saved_settings)
	get_tree().node_added.connect(_on_node_added)
	_apply_saved_settings()



func request_startup_resources() -> void :
	for id: StringName in SFX_PATHS:
		_request_startup_resource(id)


func _request_startup_resource(id: StringName) -> bool:
	if _resource_request_usec == 0:
		_resource_request_usec = Time.get_ticks_usec()
	if _sfx_streams.has(id) or _sfx_load_requests.has(id):
		return true
	var path: String = SFX_PATHS[id]
	var error: Error = ResourceLoader.load_threaded_request(path, "AudioStream", false)
	if error != OK:
		SortLogger.error("AudioManager: 音效请求失败 id=%s error=%d" % [id, error])
		return false
	_sfx_load_requests[id] = path
	return true



func request_startup_resources_spread(progress: Callable = Callable()) -> bool:
	var slice_started: int = Time.get_ticks_usec()
	var requested: int = 0
	var success: bool = true
	for id: StringName in SFX_PATHS:
		success = _request_startup_resource(id) and success
		requested += 1
		if progress.is_valid():
			progress.call(float(requested) / SFX_PATHS.size())
		if Time.get_ticks_usec() - slice_started >= _RESOURCE_CONSUME_BUDGET_USEC:
			await get_tree().process_frame
			slice_started = Time.get_ticks_usec()
	return success



func warm_startup_resources(progress: Callable = Callable()) -> bool:
	if _warming_resources:
		while _warming_resources:
			await get_tree().process_frame
		_report_resource_progress(progress)
		return _sfx_streams.size() == SFX_PATHS.size()
	_warming_resources = true
	await request_startup_resources_spread()
	var started_usec: int = Time.get_ticks_usec()
	var slice_started_usec: int = started_usec
	_report_resource_progress(progress)
	for id: StringName in _sfx_load_requests.keys():
		if not _sfx_load_requests.has(id):
			continue
		var path: String = _sfx_load_requests[id]
		while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
			slice_started_usec = Time.get_ticks_usec()
		if not _sfx_load_requests.has(id):
			continue
		var consume_started: int = Time.get_ticks_usec()
		var stream: AudioStream = null
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
			stream = ResourceLoader.load_threaded_get(path) as AudioStream
		_sfx_load_requests.erase(id)
		if stream == null:
			SortLogger.error("AudioManager: 音效加载失败 id=%s" % id)
		else:
			_sfx_streams[id] = stream
		var consume_usec: int = Time.get_ticks_usec() - consume_started
		if consume_usec >= _RESOURCE_CONSUME_BUDGET_USEC:
			SortLogger.warn("[Startup] audio_consume id=%s elapsed_ms=%.2f" % [id, consume_usec / 1000.0])
		_report_resource_progress(progress)
		if Time.get_ticks_usec() - slice_started_usec >= _RESOURCE_CONSUME_BUDGET_USEC:
			await get_tree().process_frame
			slice_started_usec = Time.get_ticks_usec()
	_warming_resources = false
	SortLogger.info("[Startup] audio_resource_elapsed_ms=%.2f audio_resource_wait_ms=%.2f audio_ready=%d/%d" % [
		float(Time.get_ticks_usec() - _resource_request_usec) / 1000.0, 
		float(Time.get_ticks_usec() - started_usec) / 1000.0, 
		_sfx_streams.size(), SFX_PATHS.size()])
	return _sfx_streams.size() == SFX_PATHS.size()


func _report_resource_progress(progress: Callable) -> void :
	if progress.is_valid():
		progress.call(float(_sfx_streams.size()) / SFX_PATHS.size())


func _get_sfx_stream(id: StringName) -> AudioStream:
	var stream: AudioStream = _sfx_streams.get(id, null) as AudioStream
	if stream != null or not SFX_PATHS.has(id):
		return stream


	if _sfx_load_requests.has(id):
		stream = ResourceLoader.load_threaded_get(_sfx_load_requests[id]) as AudioStream
		_sfx_load_requests.erase(id)
	else:
		stream = load(SFX_PATHS[id]) as AudioStream
	if stream != null:
		_sfx_streams[id] = stream
	return stream


func has_music(id: StringName) -> bool:
	return MUSIC_STREAMS.has(id)



func play_music(id: StringName, fade_sec: float = 0.3) -> void :
	var ids: Array[StringName] = [id]
	play_music_playlist(ids, fade_sec)



func play_music_playlist(ids: Array[StringName], fade_sec: float = 0.3) -> void :
	if ids.is_empty():
		stop_music(fade_sec)
		return
	for id: StringName in ids:
		if not has_music(id):
			if not _missing_music_warned.has(id):
				_missing_music_warned[id] = true
				SortLogger.warn("AudioManager: 未登记音乐 '%s'" % id)
			return
	if ids == _music_playlist:
		return
	_music_playlist.assign(ids)
	_music_playlist_index = 0
	_music_fade_sec = maxf(fade_sec, 0.0)
	_start_music_track(_music_playlist[0], _music_fade_sec)



func pause_music(reason: StringName = &"manual") -> void :
	_music_pause_reasons[reason] = true
	_sync_music_paused()


func resume_music(reason: StringName = &"manual") -> void :
	_music_pause_reasons.erase(reason)
	_sync_music_paused()


func replay_music() -> void :
	if _music_playlist.is_empty():
		return
	_start_music_track(_music_playlist[_music_playlist_index], 0.0)


func _sync_music_paused() -> void :
	var paused: bool = not _music_pause_reasons.is_empty()

	if paused and _music_playlist.is_empty():
		_kill_music_tween()
		_stop_music_players()
	for player: AudioStreamPlayer in _music_players:
		player.stream_paused = paused
	if _music_tween != null and _music_tween.is_valid():
		if paused:
			_music_tween.pause()
		else:
			_music_tween.play()



func _load_music_stream(id: StringName) -> AudioStream:
	if _music_streams.has(id):
		return _music_streams[id] as AudioStream
	var path: String = MUSIC_STREAMS[id]
	if not _music_load_requests.has(id):
		var error: Error = ResourceLoader.load_threaded_request(path, "AudioStream", false)
		if error != OK:
			SortLogger.error("AudioManager: 音乐请求失败 id=%s error=%d" % [id, error])
			return null
		_music_load_requests[id] = path
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	if _music_streams.has(id):
		return _music_streams[id] as AudioStream
	var stream: AudioStream = null
	if _music_load_requests.has(id):
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
			stream = ResourceLoader.load_threaded_get(path) as AudioStream
		_music_load_requests.erase(id)
	if stream == null:
		SortLogger.error("AudioManager: 音乐加载失败 id=%s" % id)
		return null

	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = false
	_music_streams[id] = stream
	return stream


func _start_music_track(id: StringName, fade_sec: float) -> void :
	_music_generation += 1
	var generation: int = _music_generation
	_music_id = id
	_music_loading = true
	_kill_music_tween()

	for index: int in _music_players.size():
		if index != _music_player_index:
			_music_players[index].stop()
	var stream: AudioStream = await _load_music_stream(id)
	if generation != _music_generation or _music_playlist.is_empty():
		return
	_music_loading = false
	if stream == null:
		stop_music(0.0)
		return

	var next_index: int = 0 if _music_player_index != 0 else 1
	var incoming: AudioStreamPlayer = _music_players[next_index]
	var outgoing: AudioStreamPlayer = _music_players[_music_player_index]\
	if _music_player_index >= 0 else null
	incoming.stop()
	incoming.stream = stream
	incoming.volume_db = SILENT_DB if fade_sec > 0.0 else 0.0
	incoming.play()
	_music_player_index = next_index
	_music_id = id
	incoming.stream_paused = not _music_pause_reasons.is_empty()

	if fade_sec <= 0.0:
		if outgoing != null:
			outgoing.stop()
		return
	_music_tween = create_tween().set_parallel(true)
	_music_tween.tween_property(incoming, "volume_db", 0.0, fade_sec)
	if outgoing != null and outgoing.playing:
		_music_tween.tween_property(outgoing, "volume_db", SILENT_DB, fade_sec)
		_music_tween.chain().tween_callback(outgoing.stop)
	_sync_music_paused()


func _on_music_finished(index: int) -> void :
	if _music_playlist.is_empty() or _music_loading or index != _music_player_index:
		return
	_music_playlist_index = (_music_playlist_index + 1) % _music_playlist.size()
	_start_music_track(_music_playlist[_music_playlist_index], _music_fade_sec)


func stop_music(fade_sec: float = 0.3) -> void :
	_music_generation += 1
	_kill_music_tween()
	_music_playlist.clear()
	_music_loading = false
	_music_playlist_index = 0
	_music_id = &""
	_music_player_index = -1
	for player: AudioStreamPlayer in _music_players:
		if fade_sec <= 0.0 or player.stream_paused or not player.playing:
			player.stop()
			continue
		if _music_tween == null:
			_music_tween = create_tween().set_parallel(true)
		_music_tween.tween_property(player, "volume_db", SILENT_DB, fade_sec)
	if _music_tween != null:
		_music_tween.chain().tween_callback(_stop_music_players)


func _stop_music_players() -> void :
	for player: AudioStreamPlayer in _music_players:
		player.stop()


func _notification(what: int) -> void :
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		pause_music(&"application_focus")
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		resume_music(&"application_focus")
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		pause_music(&"application_paused")
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		resume_music(&"application_paused")


func play_sfx(id: StringName, volume_scale: float = 1.0, pitch_scale: float = 1.0) -> void :
	if not UserState.is_sfx_enabled():
		return
	var stream: AudioStream = _get_sfx_stream(id)
	if stream == null:
		push_warning("AudioManager: 未登记音效 '%s'" % id)
		return
	var config: Dictionary = SFX_CONFIG.get(id, {})
	var now: int = Time.get_ticks_msec()
	var cooldown_msec: int = int(config.get("cooldown_msec", 0))
	if now - int(_last_played_msec.get(id, - cooldown_msec)) < cooldown_msec:
		return
	var max_concurrent: int = int(config.get("max_concurrent", 1))
	var priority: int = int(config.get("priority", 0))


	var index: int = _oldest_playing_slot(id) if _playing_count(id) >= max_concurrent\
	else _find_sfx_slot(priority)
	if index < 0:
		return
	var player: AudioStreamPlayer = _sfx_players[index]
	player.stop()
	player.stream = stream
	player.volume_db = linear_to_db(clampf(volume_scale, 0.0, 2.0))\
	if volume_scale > 0.0 else SILENT_DB
	player.pitch_scale = clampf(pitch_scale, 0.25, 4.0)
	_sfx_ids[index] = id
	_sfx_priorities[index] = priority
	_sfx_started_msec[index] = now
	_last_played_msec[id] = now
	player.play()


func stop_sfx(id: StringName) -> void :
	for index: int in range(_sfx_players.size()):
		if _sfx_ids[index] == id:
			_sfx_players[index].stop()
			_clear_sfx_slot(index)


func stop_all_sfx() -> void :
	for index: int in range(_sfx_players.size()):
		_sfx_players[index].stop()
		_clear_sfx_slot(index)


func set_music_enabled(enabled: bool) -> void :
	UserState.set_music_enabled(enabled)


func set_sfx_enabled(enabled: bool) -> void :
	UserState.set_sfx_enabled(enabled)


func is_music_enabled() -> bool:
	return UserState.is_music_enabled()


func is_sfx_enabled() -> bool:
	return UserState.is_sfx_enabled()



func claim_button_sound(button: Node) -> void :
	if not is_instance_valid(button):
		return
	button.set_meta(_BUTTON_SOUND_BOUND_META, true)


func _on_node_added(node: Node) -> void :
	if node is BaseButton:
		call_deferred("_bind_button_sound", node)



func _bind_button_sound(node: Variant) -> void :
	if node == null or not is_instance_valid(node) or not node is BaseButton:
		return
	var button: BaseButton = node as BaseButton
	if button.has_meta(_BUTTON_SOUND_BOUND_META):
		return
	button.set_meta(_BUTTON_SOUND_BOUND_META, true)
	button.button_down.connect( func() -> void :
		play_sfx(&"button_click")
	)


func _apply_saved_settings() -> void :
	_set_bus_muted(&"Music", not UserState.is_music_enabled())
	if UserState.is_music_enabled():
		resume_music(&"music_setting")
	else:
		pause_music(&"music_setting")
	_set_bus_muted(&"SFX", not UserState.is_sfx_enabled())


func _set_bus_muted(bus_name: StringName, muted: bool) -> void :
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0:
		push_error("AudioManager: 找不到 Audio Bus '%s'" % bus_name)
		return
	AudioServer.set_bus_mute(index, muted)


func _playing_count(id: StringName) -> int:
	var count: int = 0
	for index: int in range(_sfx_players.size()):
		if _sfx_ids[index] == id and _sfx_players[index].playing:
			count += 1
	return count


func _oldest_playing_slot(id: StringName) -> int:
	var candidate: int = -1
	for index: int in range(_sfx_players.size()):
		if _sfx_ids[index] != id or not _sfx_players[index].playing:
			continue
		if candidate < 0 or _sfx_started_msec[index] < _sfx_started_msec[candidate]:
			candidate = index
	return candidate



func _find_sfx_slot(priority: int) -> int:
	for index: int in range(_sfx_players.size()):
		if not _sfx_players[index].playing:
			return index
	var candidate: int = -1
	for index: int in range(_sfx_players.size()):
		if _sfx_priorities[index] > priority:
			continue
		if candidate < 0 or _sfx_priorities[index] < _sfx_priorities[candidate]\
		or (_sfx_priorities[index] == _sfx_priorities[candidate]\
		and _sfx_started_msec[index] < _sfx_started_msec[candidate]):
			candidate = index
	return candidate


func _on_sfx_finished(index: int) -> void :
	_clear_sfx_slot(index)


func _clear_sfx_slot(index: int) -> void :
	_sfx_ids[index] = &""
	_sfx_priorities[index] = 0
	_sfx_started_msec[index] = 0


func _kill_music_tween() -> void :
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = null
