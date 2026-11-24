












class_name SafeAreaSim
extends RefCounted



const DEFAULT_TOP_PX: int = 177
const DEFAULT_BOTTOM_PX: int = 102

static var _enabled: bool = false
static var _top_px: int = 0
static var _bottom_px: int = 0



static func get_safe_area(win_size: Vector2i) -> Rect2i:
	if not _enabled:
		return DisplayServer.get_display_safe_area()
	var top: int = clampi(_top_px, 0, win_size.y)
	var bottom: int = clampi(_bottom_px, 0, win_size.y - top)
	return Rect2i(0, top, win_size.x, win_size.y - top - bottom)


static func set_notch(top_px: int, bottom_px: int) -> void :
	_enabled = true
	_top_px = maxi(top_px, 0)
	_bottom_px = maxi(bottom_px, 0)


static func disable() -> void :
	_enabled = false
	_top_px = 0
	_bottom_px = 0

static func is_enabled() -> bool:
	return _enabled

static func get_top_px() -> int:
	return _top_px

static func get_bottom_px() -> int:
	return _bottom_px
