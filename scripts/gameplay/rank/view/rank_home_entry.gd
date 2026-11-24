class_name RankHomeEntry
extends TextureButton


signal season_expired

const LOCKED_TIER: int = RankBadgeView.TIER_MIN

const _LOCK_BASE_FONT_SIZE: int = 27
const _LOCK_MIN_FONT_SIZE: int = 20

@export var subscript_bgs: Array[Texture2D] = []

@onready var _badge: RankBadgeView = $Badge
@onready var _countdown: TextureRect = $Countdown
@onready var _time_label: Label = $Countdown / Time
@onready var _lock_area: TextureRect = $LockArea
@onready var _lock_icon: TextureRect = $LockIcon
@onready var _lock_label: Label = $LockArea / Text
@onready var _subscript: TextureRect = $Subscript
@onready var _subscript_label: Label = $Subscript / Number
@onready var _tick: Timer = $Tick

var _locked: bool = false
var _expired_reported: bool = false
var _refreshing: bool = false


func _ready() -> void :
	_tick.timeout.connect(_on_tick)


func refresh() -> void :
	if _refreshing:
		return
	_refreshing = true
	_refresh_impl()
	_refreshing = false


func _refresh_impl() -> void :
	visible = true
	if not RankManager.is_unlocked():
		_apply_locked()
		return
	RankManager.ensure_season()
	if RankManager.is_clock_rolled_back():
		visible = false
		_locked = false
		_stop_badge_idle()
		_hide_rank_subscript()
		return
	_apply_unlocked()


func is_locked() -> bool:
	return visible and _locked


func _apply_locked() -> void :
	_locked = true
	_stop_badge_idle()
	_badge.set_tier(LOCKED_TIER, true)
	_countdown.visible = false
	_lock_area.visible = true
	_lock_icon.visible = true
	_lock_label.text = "Lv.%d" % RankManager.get_unlock_level()
	_fit_lock_label()
	_tick.stop()
	_hide_rank_subscript()


func _fit_lock_label() -> void :
	var font: Font = _lock_label.get_theme_font("font")
	if font == null or _lock_label.text.is_empty():
		return
	var outline: float = float(_lock_label.get_theme_constant("outline_size"))
	var avail_w: float = (_lock_label.offset_right - _lock_label.offset_left) - outline * 2.0
	if avail_w <= 0.0:
		return
	var font_size: int = _LOCK_BASE_FONT_SIZE
	while font_size > _LOCK_MIN_FONT_SIZE:
		var w: float = font.get_string_size(
			_lock_label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
		if w <= avail_w:
			break
		font_size -= 2
	_lock_label.add_theme_font_size_override("font_size", font_size)


func _apply_unlocked() -> void :
	_locked = false
	var tier: int = RankManager.get_current_tier()
	_badge.set_tier(tier)
	_lock_area.visible = false
	_lock_icon.visible = false
	_countdown.visible = true
	_on_tick()
	if _tick.is_stopped():
		_tick.start()
	_badge.start_idle_fx()
	_apply_rank_subscript(tier)


func _apply_rank_subscript(tier: int) -> void :
	var pos: int = RankManager.get_my_rank_pos()
	if pos <= 0:
		_hide_rank_subscript()
		return
	if not subscript_bgs.is_empty():
		_subscript.texture = subscript_bgs[clampi(tier - 1, 0, subscript_bgs.size() - 1)]
	_subscript_label.text = str(pos)
	_subscript.visible = true


func _hide_rank_subscript() -> void :
	if _subscript == null:
		return
	_subscript.visible = false


func _notification(what: int) -> void :
	if what != NOTIFICATION_VISIBILITY_CHANGED or _tick == null:
		return
	if is_visible_in_tree() and not _locked:
		if _tick.is_stopped():
			_tick.start()
		if _badge != null:
			_badge.start_idle_fx()
	else:
		_tick.stop()
		_stop_badge_idle()


func _stop_badge_idle() -> void :
	if _badge != null:
		_badge.reset_motion()


func _on_tick() -> void :
	_time_label.text = RankManager.format_remaining(RankManager.get_remain_seconds())
	if not RankManager.is_season_ended():
		_expired_reported = false
		return
	if _expired_reported:
		return
	_expired_reported = true
	season_expired.emit()
