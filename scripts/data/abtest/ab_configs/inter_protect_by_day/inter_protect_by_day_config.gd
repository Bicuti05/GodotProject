class_name InterProtectByDayConfig
extends AbConfigBase



const FALLBACK_RAW: String = "[1_inf:0]"
const FALLBACK_VALUE: int = 0
var _raw_sdk_value: String = ""
var _segments: Array = []
var _debug_override_str: String = ""
var _debug_segments: Array = []


func _init() -> void :
	key = "inter_protect_by_day"
	version = "1.0.10"
	default_value = FALLBACK_VALUE
	group_count = 0
	timing = ABManager.TIMING_APP_START


func init_default() -> void :
	super.init_default()
	_raw_sdk_value = ""
	_segments.clear()


func load_value_silent() -> void :
	_raw_sdk_value = ABManager.get_ab_string(key, "")
	_segments = _parse_segments(_raw_sdk_value)
	_value_loaded = true
	if not _raw_sdk_value.is_empty() and _segments.is_empty():
		SortLogger.warn("%s：非法生命周期段表，使用客户端兜底" % key)


func reload_value() -> void :
	load_value_silent()
	if not _segments.is_empty():
		ABManager.dye_ab(key)



static func _parse_segments(raw: String) -> Array:
	if raw.strip_edges().is_empty():
		return []
	var parts: PackedStringArray = raw.strip_edges().split(",", true)
	var segments: Array = AbValueParser.parse_day_segments(raw)
	if segments.size() != parts.size():
		return []
	for part: String in parts:
		if not part.strip_edges().begins_with("[") or not part.strip_edges().ends_with("]"):
			return []
	for segment: Dictionary in segments:
		if int(segment.lo) < 0 or int(segment.hi) < int(segment.lo) or int(segment.val) < 0:
			return []
	return segments


func get_protect_rounds(lifecycle_day: int) -> int:

	if lifecycle_day < 1:
		return 0
	if not _value_loaded and ABManager.is_ab_init_done():
		load_value_silent()
	var segments: Array = _debug_segments if is_debug_overridden() else _segments
	return AbValueParser.lookup_segment(segments, lifecycle_day, FALLBACK_VALUE)


func should_allow_interstitial(lifecycle_day: int, completed_today: int, 
		after_completion: bool = true) -> bool:
	var count: int = get_protect_rounds(lifecycle_day)
	if count <= 0:
		return true
	return completed_today > count if after_completion else completed_today >= count



func get_log_snapshot(lifecycle_day: int = 0) -> Dictionary:
	var overridden: bool = is_debug_overridden()
	var segments: Array = _debug_segments if overridden else _segments
	var effective: int = AbValueParser.lookup_segment(segments, lifecycle_day, FALLBACK_VALUE)
	var source: String = "调试强制覆盖" if overridden else "SDK已加载配置"
	var rule: String = "当前安装天数没有匹配区间，使用客户端兜底"
	for segment: Dictionary in segments:
		if lifecycle_day >= int(segment["lo"]) and lifecycle_day <= int(segment["hi"]):
			var upper: String = "inf" if int(segment["hi"]) == AbValueParser.INF else str(segment["hi"])
			rule = "[%d_%s:%d]（区间包含两端）" % [int(segment["lo"]), upper, int(segment["val"])]
			break
	if not overridden and not _value_loaded:
		source = "SDK尚未读取，暂用客户端兜底；日志不会主动拉取配置"
	elif segments.is_empty():
		source = "客户端兜底（SDK配置为空或格式非法）"
	if lifecycle_day < 1:
		effective = 0
		rule = "安装第0天不启用每日额外保护，忽略段表保护值"
	return {"effective": effective, "fallback": FALLBACK_VALUE, "source": source, 
		"raw": _debug_override_str if overridden else (_raw_sdk_value if not _raw_sdk_value.is_empty() else FALLBACK_RAW), 
		"rule": rule, "loaded": _value_loaded or overridden}



func peek_value() -> int:
	return get_protect_rounds(UserState.get_install_days()) if is_debug_overridden() else peek_sdk_value()


func peek_sdk_value() -> int:
	var day: int = UserState.get_install_days()
	if day < 1:
		return 0
	var raw: String = ABManager.get_ab_string(key, "")
	return AbValueParser.lookup_segment(_parse_segments(raw), day, FALLBACK_VALUE)


func set_debug_override_str(raw: String) -> bool:
	var parsed: Array = _parse_segments(raw)
	if parsed.is_empty():
		return false
	_debug_override_str = raw.strip_edges()
	_debug_segments = parsed
	return true


func clear_debug_override() -> void :
	_debug_override_str = ""
	_debug_segments.clear()


func is_debug_overridden() -> bool:
	return not _debug_override_str.is_empty()


func get_debug_input_value_str() -> String:
	if is_debug_overridden():
		return _debug_override_str
	return _raw_sdk_value if not _segments.is_empty() else FALLBACK_RAW


func cheat_label() -> String:
	return "插屏每日保护局数 (格式 [day1_day2:n]；客户端兜底 [1_inf:0]，字符串覆盖重启失效)"


func cheat_value_str() -> String:
	var day: int = UserState.get_install_days()
	var effective: int = get_protect_rounds(day)
	var source: String = "强制" if is_debug_overridden() else ("SDK" if not _segments.is_empty() else "客户端兜底")
	return "day%d=%d局 · %s" % [day, effective, source]
