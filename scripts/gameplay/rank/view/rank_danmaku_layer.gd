class_name RankDanmakuLayer
extends Control


const MAX_ITEMS: int = 8
const SPAWN_GAP_MIN_SEC: float = 0.5
const SPAWN_GAP_MAX_SEC: float = 0.75
const DRIFT_SEC_MIN: float = 4.6
const DRIFT_SEC_MAX: float = 5.8
const LANE_TOP_Y: PackedFloat32Array = [301.0, 442.0, 592.0]
const FADE_SEC: float = 0.35

const AVATAR_KEYS: PackedStringArray = [
	"RANK_SEASON_WIN_CHEER_AVATAR_1", 
	"RANK_SEASON_WIN_CHEER_AVATAR_2", 
	"RANK_SEASON_WIN_CHEER_AVATAR_3", 
	"RANK_SEASON_WIN_CHEER_AVATAR_4", 
	"RANK_SEASON_WIN_CHEER_AVATAR_5", 
	"RANK_SEASON_WIN_CHEER_AVATAR_6", 
]

const BADGE_KEYS: PackedStringArray = [
	"RANK_SEASON_WIN_CHEER_BADGE_1", 
	"RANK_SEASON_WIN_CHEER_BADGE_2", 
	"RANK_SEASON_WIN_CHEER_BADGE_3", 
	"RANK_SEASON_WIN_CHEER_BADGE_4", 
	"RANK_SEASON_WIN_CHEER_BADGE_5", 
	"RANK_SEASON_WIN_CHEER_BADGE_6", 
]

const _ITEM_SCENE: PackedScene = preload("res://scripts/gameplay/rank/view/rank_danmaku_item.tscn")

@onready var _pool: RankAvatarPool = $AvatarPool

var _rng: = RandomNumberGenerator.new()
var _running: bool = false
var _loop_token: int = 0
var _spawn_index: int = 0
var _end_tier: int = RankBadgeView.TIER_MIN
var _used_avatar: Array[String] = []
var _used_badge: Array[String] = []
var _items: Array[RankDanmakuItem] = []


func _ready() -> void :
	_rng.randomize()


func start(end_tier: int) -> void :
	_loop_token += 1
	var token: int = _loop_token
	_end_tier = clampi(end_tier, RankBadgeView.TIER_MIN, RankBadgeView.TIER_MAX)
	_spawn_index = 0
	_used_avatar.clear()
	_used_badge.clear()
	_clear_items()
	_running = true
	_run_loop(token)


func stop() -> void :
	_loop_token += 1
	_running = false
	_clear_items()


func _run_loop(token: int) -> void :
	while _running and token == _loop_token and _spawn_index < MAX_ITEMS:
		_spawn_one()
		_spawn_index += 1
		await get_tree().create_timer(
			_rng.randf_range(SPAWN_GAP_MIN_SEC, SPAWN_GAP_MAX_SEC)).timeout


func _spawn_one() -> void :
	var item: RankDanmakuItem = _ITEM_SCENE.instantiate()
	add_child(item)
	_items.append(item)
	if _spawn_index % 2 == 0:
		var key: String = _take_from(AVATAR_KEYS, _used_avatar)
		var avatar_index: int = RankFakeUserGenerator.random_avatar_index(_rng)
		item.bind_avatar(key, avatar_index, _pool.get_texture(avatar_index))
	else:
		item.bind_badge(_take_from(BADGE_KEYS, _used_badge), _end_tier)
	_drift(item)


func _take_from(pool: PackedStringArray, used: Array[String]) -> String:
	var candidates: Array[String] = []
	for k in pool:
		if not used.has(k):
			candidates.append(k)
	if candidates.is_empty():
		used.clear()
		for k in pool:
			candidates.append(k)
	var picked: String = candidates[_rng.randi_range(0, candidates.size() - 1)]
	used.append(picked)
	return picked


func _drift(item: RankDanmakuItem) -> void :
	var lane: int = _spawn_index % LANE_TOP_Y.size()
	var pill_w: float = item.get_pill_width()
	var from_x: float = UiMetrics.viewport_size().x
	var to_x: float = - pill_w
	item.position = Vector2(from_x, LANE_TOP_Y[lane])
	item.modulate.a = 0.0
	var drift_sec: float = _rng.randf_range(DRIFT_SEC_MIN, DRIFT_SEC_MAX)
	var move: = item.create_tween()
	move.tween_property(item, "position:x", to_x, drift_sec).set_trans(Tween.TRANS_LINEAR)
	var fade: = item.create_tween()
	fade.tween_property(item, "modulate:a", 1.0, FADE_SEC)
	fade.tween_interval(maxf(drift_sec - FADE_SEC * 2.0, 0.0))
	fade.tween_property(item, "modulate:a", 0.0, FADE_SEC)
	move.finished.connect( func() -> void : _recycle(item))


func _recycle(item: RankDanmakuItem) -> void :
	if not is_instance_valid(item):
		return
	_items.erase(item)
	item.queue_free()


func _clear_items() -> void :
	for item in _items:
		if is_instance_valid(item):
			item.queue_free()
	_items.clear()
