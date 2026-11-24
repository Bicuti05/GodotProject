





























class_name UiMetrics
extends RefCounted


const DESIGN: = Vector2(1080.0, 2340.0)


const TABLET_MIN_SHORTEST_SIDE_DP: float = 600.0
const MOBILE_BASE_DPI: float = 160.0
const TABLET_FALLBACK_ASPECT_RATIO: float = 0.6



const SAFE_INSET_RATIO: float = 0.5
const HOME_RANK_TOP_INSET_RATIO: float = 0.7




static func viewport_size() -> Vector2:
	var loop: = Engine.get_main_loop() as SceneTree
	if loop == null or loop.root == null:
		return DESIGN
	var vs: Vector2 = loop.root.get_visible_rect().size
	if vs.x <= 0.0 or vs.y <= 0.0:
		return DESIGN
	return vs



static func is_tablet() -> bool:
	if OS.has_feature("android") or OS.has_feature("ios"):
		var dpi: int = DisplayServer.screen_get_dpi()
		var screen_size: Vector2i = DisplayServer.screen_get_size()
		if dpi > 0 and screen_size.x > 0 and screen_size.y > 0:
			var shortest_side_dp: float = float(mini(screen_size.x, screen_size.y))\
			* MOBILE_BASE_DPI / float(dpi)
			return shortest_side_dp >= TABLET_MIN_SHORTEST_SIDE_DP
	var vs: Vector2 = viewport_size()
	var shortest_side: float = minf(vs.x, vs.y)
	var longest_side: float = maxf(vs.x, vs.y)
	return shortest_side / longest_side >= TABLET_FALLBACK_ASPECT_RATIO



static func center_x() -> float:
	return viewport_size().x * 0.5



static func center_left(w: float) -> float:
	return (viewport_size().x - w) * 0.5



static func extra_width() -> float:
	return maxf(viewport_size().x - DESIGN.x, 0.0)



static func extra_height() -> float:
	return maxf(viewport_size().y - DESIGN.y, 0.0)



static func content_scale() -> float:
	var logical_h: float = viewport_size().y
	if logical_h <= 0.0:
		return 1.0
	var win_h: float = float(DisplayServer.window_get_size().y)
	if win_h <= 0.0:
		return 1.0
	return win_h / logical_h







static func system_insets() -> Vector2:
	var win: Vector2i = DisplayServer.window_get_size()
	var safe: Rect2i = SafeAreaSim.get_safe_area(win)
	var top: float = float(safe.position.y)
	var bottom: float = float(win.y - (safe.position.y + safe.size.y))
	var scale: float = content_scale()
	if scale > 0.0:
		top /= scale
		bottom /= scale
	return Vector2(maxf(top, 0.0), maxf(bottom, 0.0))





static func safe_insets(top_ratio: float = SAFE_INSET_RATIO) -> Vector2:
	var insets: Vector2 = system_insets()
	if OS.has_feature("ios") or OS.has_feature("android"):
		insets.x *= top_ratio
		insets.y *= SAFE_INSET_RATIO
	return insets
